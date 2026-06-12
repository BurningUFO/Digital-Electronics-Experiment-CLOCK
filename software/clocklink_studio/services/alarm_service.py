"""闹钟业务服务封装。"""

from .client import ClockLinkClient


class AlarmService:
    """给 GUI 使用的闹钟槽读写接口。"""

    def __init__(self, client: ClockLinkClient) -> None:
        self.client = client

    def set_slot(self, slot: int, time_text: str, enable: bool):
        return self.client.alarm_set(slot, time_text, enable)

    def get_slot(self, slot: int):
        return self.client.alarm_get(slot)
