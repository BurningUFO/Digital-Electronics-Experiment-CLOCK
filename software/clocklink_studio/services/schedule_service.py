from .client import ClockLinkClient


class ScheduleService:
    def __init__(self, client: ClockLinkClient) -> None:
        self.client = client

    def set_slot(self, slot: int, time_text: str, schedule_type: int, enable: bool):
        return self.client.sched_set(slot, time_text, schedule_type, enable)

    def get_slot(self, slot: int):
        return self.client.sched_get(slot)
