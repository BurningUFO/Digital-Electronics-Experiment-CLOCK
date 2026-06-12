import queue
import sys
import types
"""SerialTransport 队列分流测试。

真实串口会同时收到 PC 请求响应和 FPGA 主动 REPLY/EVENT，本测试用 FakeSerial
验证非当前 SEQ 的帧会进入事件队列，而不会打断当前命令响应。
"""

import time

from protocol.codec import encode_frame
from protocol.commands import CommandBuilder
from transport.serial_transport import SerialTransport


class FakeSerial:
    def __init__(self, *_, **kwargs):
        self.timeout = kwargs.get("timeout", 0.1)
        self.writes = []
        self.rx = queue.Queue()
        self.closed = False

    def write(self, data: bytes) -> int:
        self.writes.append(data)
        return len(data)

    def flush(self) -> None:
        return None

    def readline(self) -> bytes:
        if self.closed:
            return b""
        try:
            return self.rx.get(timeout=self.timeout)
        except queue.Empty:
            return b""

    def close(self) -> None:
        self.closed = True
        self.rx.put(b"")


def install_fake_serial(monkeypatch, fake: FakeSerial) -> None:
    module = types.SimpleNamespace(Serial=lambda **_kwargs: fake)
    monkeypatch.setitem(sys.modules, "serial", module)


def wait_for_event(transport: SerialTransport, timeout: float = 0.5) -> str | None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        line = transport.poll_event()
        if line is not None:
            return line
        time.sleep(0.01)
    return None


def test_serial_transport_keeps_unsolicited_reply_for_poll(monkeypatch):
    fake = FakeSerial(timeout=0.01)
    install_fake_serial(monkeypatch, fake)
    transport = SerialTransport("COM_TEST", timeout=0.5)
    request = CommandBuilder(start_seq=3).ping()

    try:
        fake.rx.put(encode_frame(0xF0, "REPLY", {"slot": 0, "reply": 1, "ts": "2026-06-05T15:03:00", "text": "42757379206E6F772E"}).encode("ascii"))
        fake.rx.put(encode_frame(4, "PONG").encode("ascii"))

        response = transport.transact(request)
        assert response.startswith("#04|PONG|")

        event = wait_for_event(transport)
        assert event is not None
        assert event.startswith("#F0|REPLY|")
    finally:
        transport.close()


def test_serial_transport_poll_event_reads_unsolicited_line(monkeypatch):
    fake = FakeSerial(timeout=0.01)
    install_fake_serial(monkeypatch, fake)
    transport = SerialTransport("COM_TEST", timeout=0.5)

    try:
        fake.rx.put(encode_frame(0xF0, "REPLY", {"slot": 0, "reply": 0, "ts": "2026-06-05T15:03:00", "text": "4F4B2C2072656365697665642E"}).encode("ascii"))
        event = wait_for_event(transport)
        assert event is not None
        assert event.startswith("#F0|REPLY|")
    finally:
        transport.close()
