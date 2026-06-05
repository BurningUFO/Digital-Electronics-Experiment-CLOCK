from datetime import datetime
from typing import Optional

from .codec import ascii_text_to_hex, encode_frame


def _iso_timestamp(value: Optional[datetime] = None) -> str:
    value = value or datetime.now()
    return value.replace(microsecond=0).isoformat()


def _date_time_payload(value: Optional[datetime] = None) -> dict[str, object]:
    value = value or datetime.now()
    value = value.replace(microsecond=0)
    return {
        "date": value.date().isoformat(),
        "time": value.time().isoformat(),
        "weekday": value.isoweekday(),
    }


class Sequence:
    def __init__(self, start: int = 0) -> None:
        self._value = start & 0xFF

    def next(self) -> int:
        self._value = (self._value + 1) & 0xFF
        return self._value


class CommandBuilder:
    def __init__(self, start_seq: int = 0) -> None:
        self.sequence = Sequence(start_seq)

    def frame(self, cmd: str, payload=None, seq: Optional[int] = None) -> str:
        return encode_frame(self.sequence.next() if seq is None else seq, cmd, payload)

    def hello(self, version: str = "0.1", caps: str = "mock,serial") -> str:
        return self.frame("HELLO", {"role": "pc", "ver": version, "caps": caps})

    def ping(self, timestamp: Optional[datetime] = None) -> str:
        return self.frame("PING", {"ts": _iso_timestamp(timestamp)})

    def status_get(self) -> str:
        return self.frame("STATUS_GET")

    def mode_set(self, mode: str) -> str:
        return self.frame("MODE_SET", {"mode": mode.upper()})

    def time_set(self, value: Optional[datetime] = None) -> str:
        return self.frame("TIME_SET", _date_time_payload(value))

    def time_get(self) -> str:
        return self.frame("TIME_GET")

    def alarm_set(self, slot: int, time_text: str, enable: bool) -> str:
        return self.frame("ALARM_SET", {"slot": slot, "time": time_text, "enable": enable})

    def alarm_get(self, slot: int) -> str:
        return self.frame("ALARM_GET", {"slot": slot})

    def alarm_dump(self) -> str:
        return self.frame("ALARM_DUMP")

    def sched_set(self, slot: int, time_text: str, schedule_type: int, enable: bool) -> str:
        return self.frame(
            "SCHED_SET",
            {"slot": slot, "time": time_text, "type": schedule_type, "enable": enable},
        )

    def sched_get(self, slot: int) -> str:
        return self.frame("SCHED_GET", {"slot": slot})

    def sched_dump(self) -> str:
        return self.frame("SCHED_DUMP")

    def count_set(self, time_text: str) -> str:
        return self.frame("COUNT_SET", {"time": time_text})

    def count_start(self) -> str:
        return self.frame("COUNT_START")

    def count_stop(self) -> str:
        return self.frame("COUNT_STOP")

    def count_status(self) -> str:
        return self.frame("COUNT_STATUS")

    def msg_tx(self, text: str, timestamp: Optional[datetime] = None) -> str:
        return self.frame(
            "MSG_TX",
            {
                "ts": _iso_timestamp(timestamp),
                "len": len(text),
                "text": ascii_text_to_hex(text),
            },
        )

    def msg_get(self, slot: int) -> str:
        return self.frame("MSG_GET", {"slot": slot})

    def msg_clear(self, slot: int | str = "all") -> str:
        return self.frame("MSG_CLEAR", {"slot": slot})
