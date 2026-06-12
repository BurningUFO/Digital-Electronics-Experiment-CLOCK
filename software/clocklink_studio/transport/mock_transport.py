"""ClockLink mock FPGA。

不连接开发板时，MockTransport 在本地模拟 FPGA 对协议命令的响应，
用于 CLI、GUI 和单元测试。mock 行为尽量贴近当前 FPGA 已实现子集；
少量软件演示功能（如 MSG_GET）会比 FPGA 当前实现更完整。
"""

from __future__ import annotations

from datetime import datetime

from protocol.codec import (
    FrameError,
    ascii_text_to_hex,
    decode_frame,
    encode_frame,
    hex_to_ascii_text,
    parse_payload,
)
from protocol.frame import Frame

from .base import BaseTransport


PRESET_REPLIES = [
    "OK, received.",
    "Busy now.",
    "Will check later.",
    "Please sync time.",
    "System normal.",
    "Alarm noted.",
    "Schedule noted.",
    "Need help.",
]


class MockTransport(BaseTransport):
    """内存版 FPGA 状态机。

    保存时间、消息、闹钟、日程和倒计时状态，并按命令名分派到 _handle_xxx。
    """

    def __init__(self) -> None:
        now = datetime.now().replace(microsecond=0)
        self.mode = "CLOCK"
        self.conn = "CONN"
        self.current_date = now.date().isoformat()
        self.current_time = now.time().isoformat()
        self.weekday = str(now.isoweekday())
        self.messages: list[dict[str, str | bool]] = []
        self.alarms = [
            {"slot": str(i), "time": "00:00:00", "enable": "0"} for i in range(8)
        ]
        self.schedules = [
            {
                "slot": str(i),
                "time": default,
                "type": str(i),
                "enable": "1",
            }
            for i, default in enumerate(
                [
                    "08:00:00",
                    "09:40:00",
                    "10:00:00",
                    "11:40:00",
                    "14:00:00",
                    "15:40:00",
                    "19:00:00",
                    "21:30:00",
                ]
            )
        ]
        self.count_time = "00:00:00"
        self.count_run = "0"
        self.fpga_seq = 0xF0

    def transact(self, frame_line: str) -> str:
        """解码 PC 帧、调用对应 handler，并返回一条完整响应帧。"""
        try:
            frame = decode_frame(frame_line)
        except FrameError as exc:
            return encode_frame(0, "NACK", {"ack": "00", "err": "BAD_FRAME", "detail": str(exc)[:24]})

        handler = getattr(self, f"_handle_{frame.cmd}", None)
        if handler is None:
            return self._nack(frame, "UNKNOWN_CMD", frame.cmd.lower())
        return handler(frame)

    def _payload(self, frame: Frame) -> dict[str, str]:
        return parse_payload(frame.payload)

    def _ack(self, frame: Frame, **extra: object) -> str:
        payload: dict[str, object] = {"ack": frame.seq_hex, "cmd": frame.cmd}
        payload.update(extra)
        return encode_frame(frame.seq, "ACK", payload)

    def _nack(self, frame: Frame, err: str, detail: str = "") -> str:
        payload = {"ack": frame.seq_hex, "err": err}
        if detail:
            payload["detail"] = detail[:32]
        return encode_frame(frame.seq, "NACK", payload)

    def _validate_slot(self, frame: Frame, payload: dict[str, str], key: str = "slot") -> int | None:
        try:
            slot = int(payload[key])
        except (KeyError, ValueError):
            return None
        if 0 <= slot <= 7:
            return slot
        return None

    def _validate_msg_slot(self, payload: dict[str, str]) -> int | None:
        try:
            slot = int(payload["slot"])
        except (KeyError, ValueError):
            return None
        if 0 <= slot <= 15:
            return slot
        return None

    def _validate_time(self, time_text: str) -> bool:
        try:
            datetime.strptime(time_text, "%H:%M:%S")
        except ValueError:
            return False
        return True

    def mock_reply(self, slot: int = 0, reply: int = 0, timestamp: datetime | None = None) -> str:
        """生成一条 FPGA 主动 REPLY 帧，用于演示/测试后台监听路径。"""
        if not 0 <= slot <= 15:
            raise ValueError("reply slot must be 0..15")
        if not 0 <= reply < len(PRESET_REPLIES):
            raise ValueError("reply index must be 0..7")
        seq = self.fpga_seq
        self.fpga_seq = (self.fpga_seq + 1) & 0xFF
        value = timestamp or datetime.now().replace(microsecond=0)
        return encode_frame(
            seq,
            "REPLY",
            {
                "slot": slot,
                "reply": reply,
                "ts": value.isoformat(),
                "text": ascii_text_to_hex(PRESET_REPLIES[reply]),
            },
        )

    def _handle_HELLO(self, frame: Frame) -> str:
        return self._ack(frame, ver="mock-0.1", caps="mock,serial")

    def _handle_PING(self, frame: Frame) -> str:
        return encode_frame(frame.seq, "PONG", {"ts": datetime.now().replace(microsecond=0).isoformat()})

    def _handle_PONG(self, frame: Frame) -> str:
        return self._ack(frame)

    def _handle_STATUS_GET(self, frame: Frame) -> str:
        unread = sum(1 for item in self.messages if item.get("unread"))
        return encode_frame(
            frame.seq,
            "STATUS",
            {
                "mode": self.mode,
                "conn": "MSG" if unread else self.conn,
                "unread": unread,
                "count_run": self.count_run,
            },
        )

    def _handle_MODE_SET(self, frame: Frame) -> str:
        payload = self._payload(frame)
        mode = payload.get("mode", "")
        if mode not in {"CLOCK", "TIME", "ALARM", "HOUR", "COUNT", "SCHED", "COMM"}:
            return self._nack(frame, "BAD_MODE", mode.lower())
        self.mode = mode
        return self._ack(frame)

    def _handle_TIME_SET(self, frame: Frame) -> str:
        payload = self._payload(frame)
        try:
            datetime.strptime(f"{payload['date']}T{payload['time']}", "%Y-%m-%dT%H:%M:%S")
            weekday = int(payload["weekday"])
        except (KeyError, ValueError):
            return self._nack(frame, "BAD_TIME", "bad_time")
        if not 1 <= weekday <= 7:
            return self._nack(frame, "BAD_TIME", "bad_weekday")
        self.current_date = payload["date"]
        self.current_time = payload["time"]
        self.weekday = str(weekday)
        return self._ack(frame)

    def _handle_TIME_GET(self, frame: Frame) -> str:
        return encode_frame(
            frame.seq,
            "TIME",
            {"date": self.current_date, "time": self.current_time, "weekday": self.weekday},
        )

    def _handle_MSG_TX(self, frame: Frame) -> str:
        """保存 PC 消息；新消息插入 slot0，旧消息后移。"""
        payload = self._payload(frame)
        try:
            text = hex_to_ascii_text(payload["text"])
            expected_len = int(payload["len"])
            timestamp = payload["ts"]
        except (KeyError, ValueError, FrameError):
            return self._nack(frame, "BAD_PAYLOAD", "bad_msg")
        if expected_len != len(text) or expected_len > 100:
            return self._nack(frame, "BAD_LEN", "msg_len")
        item = {
            "ts": timestamp,
            "len": str(expected_len),
            "text": payload["text"].upper(),
            "unread": True,
        }
        self.messages.insert(0, item)
        self.messages = self.messages[:16]
        unread = sum(1 for msg in self.messages if msg.get("unread"))
        return encode_frame(frame.seq, "MSG_STORED", {"slot": 0, "count": len(self.messages), "unread": unread})

    def _handle_MSG_GET(self, frame: Frame) -> str:
        payload = self._payload(frame)
        slot = self._validate_msg_slot(payload)
        if slot is None:
            return self._nack(frame, "BAD_SLOT", "msg_slot")
        if slot >= len(self.messages):
            return encode_frame(frame.seq, "MSG_DATA", {"slot": slot, "valid": 0})
        msg = self.messages[slot]
        return encode_frame(
            frame.seq,
            "MSG_DATA",
            {
                "slot": slot,
                "valid": 1,
                "ts": msg["ts"],
                "len": msg["len"],
                "text": msg["text"],
            },
        )

    def _handle_MSG_CLEAR(self, frame: Frame) -> str:
        payload = self._payload(frame)
        slot_text = payload.get("slot", "")
        if slot_text == "all":
            self.messages.clear()
            return self._ack(frame)
        slot = self._validate_msg_slot(payload)
        if slot is None:
            return self._nack(frame, "BAD_SLOT", "msg_slot")
        if slot < len(self.messages):
            self.messages[slot]["unread"] = False
        return self._ack(frame)

    def _handle_ALARM_SET(self, frame: Frame) -> str:
        payload = self._payload(frame)
        slot = self._validate_slot(frame, payload)
        enable = payload.get("enable")
        time_text = payload.get("time", "")
        if slot is None or enable not in {"0", "1"} or not self._validate_time(time_text):
            return self._nack(frame, "BAD_PAYLOAD", "alarm")
        self.alarms[slot] = {"slot": str(slot), "time": time_text, "enable": enable}
        return self._ack(frame)

    def _handle_ALARM_GET(self, frame: Frame) -> str:
        payload = self._payload(frame)
        slot = self._validate_slot(frame, payload)
        if slot is None:
            return self._nack(frame, "BAD_SLOT", "alarm_slot")
        return encode_frame(frame.seq, "ALARM", self.alarms[slot])

    def _handle_ALARM_DUMP(self, frame: Frame) -> str:
        return encode_frame(frame.seq, "ALARM", self.alarms[0])

    def _handle_SCHED_SET(self, frame: Frame) -> str:
        payload = self._payload(frame)
        slot = self._validate_slot(frame, payload)
        enable = payload.get("enable")
        time_text = payload.get("time", "")
        try:
            schedule_type = int(payload["type"])
        except (KeyError, ValueError):
            schedule_type = -1
        if (
            slot is None
            or enable not in {"0", "1"}
            or not 0 <= schedule_type <= 7
            or not self._validate_time(time_text)
        ):
            return self._nack(frame, "BAD_PAYLOAD", "sched")
        self.schedules[slot] = {
            "slot": str(slot),
            "time": time_text,
            "type": str(schedule_type),
            "enable": enable,
        }
        return self._ack(frame)

    def _handle_SCHED_GET(self, frame: Frame) -> str:
        payload = self._payload(frame)
        slot = self._validate_slot(frame, payload)
        if slot is None:
            return self._nack(frame, "BAD_SLOT", "sched_slot")
        return encode_frame(frame.seq, "SCHED", self.schedules[slot])

    def _handle_SCHED_DUMP(self, frame: Frame) -> str:
        return encode_frame(frame.seq, "SCHED", self.schedules[0])

    def _handle_COUNT_SET(self, frame: Frame) -> str:
        payload = self._payload(frame)
        time_text = payload.get("time", "")
        if not self._validate_time(time_text):
            return self._nack(frame, "BAD_TIME", "count")
        self.count_time = time_text
        self.count_run = "0"
        return self._ack(frame)

    def _handle_COUNT_START(self, frame: Frame) -> str:
        self.count_run = "1"
        return self._ack(frame)

    def _handle_COUNT_STOP(self, frame: Frame) -> str:
        self.count_run = "0"
        return self._ack(frame)

    def _handle_COUNT_STATUS(self, frame: Frame) -> str:
        return encode_frame(frame.seq, "COUNT_STATUS", {"time": self.count_time, "run": self.count_run})
