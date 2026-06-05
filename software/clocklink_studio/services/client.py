from datetime import datetime

from protocol.codec import decode_frame
from protocol.commands import CommandBuilder
from protocol.frame import Frame
from transport.base import BaseTransport


class ClockLinkClient:
    def __init__(self, transport: BaseTransport, builder: CommandBuilder | None = None) -> None:
        self.transport = transport
        self.builder = builder or CommandBuilder()

    def request(self, frame_line: str) -> Frame:
        response_line = self.transport.transact(frame_line)
        return decode_frame(response_line)

    def hello(self) -> Frame:
        return self.request(self.builder.hello())

    def ping(self) -> Frame:
        return self.request(self.builder.ping())

    def status(self) -> Frame:
        return self.request(self.builder.status_get())

    def sync_time(self, value: datetime | None = None) -> Frame:
        return self.request(self.builder.time_set(value))

    def time_get(self) -> Frame:
        return self.request(self.builder.time_get())

    def send_message(self, text: str) -> Frame:
        return self.request(self.builder.msg_tx(text))

    def get_message(self, slot: int) -> Frame:
        return self.request(self.builder.msg_get(slot))

    def clear_message(self, slot: int | str = "all") -> Frame:
        return self.request(self.builder.msg_clear(slot))

    def alarm_set(self, slot: int, time_text: str, enable: bool) -> Frame:
        return self.request(self.builder.alarm_set(slot, time_text, enable))

    def alarm_get(self, slot: int) -> Frame:
        return self.request(self.builder.alarm_get(slot))

    def sched_set(self, slot: int, time_text: str, schedule_type: int, enable: bool) -> Frame:
        return self.request(self.builder.sched_set(slot, time_text, schedule_type, enable))

    def sched_get(self, slot: int) -> Frame:
        return self.request(self.builder.sched_get(slot))

    def count_set(self, time_text: str) -> Frame:
        return self.request(self.builder.count_set(time_text))

    def count_start(self) -> Frame:
        return self.request(self.builder.count_start())

    def count_stop(self) -> Frame:
        return self.request(self.builder.count_stop())

    def count_status(self) -> Frame:
        return self.request(self.builder.count_status())
