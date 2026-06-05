from .client import ClockLinkClient


class AlarmService:
    def __init__(self, client: ClockLinkClient) -> None:
        self.client = client

    def set_slot(self, slot: int, time_text: str, enable: bool):
        return self.client.alarm_set(slot, time_text, enable)

    def get_slot(self, slot: int):
        return self.client.alarm_get(slot)
