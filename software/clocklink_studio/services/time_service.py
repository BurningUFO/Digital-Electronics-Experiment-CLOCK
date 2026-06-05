from datetime import datetime

from .client import ClockLinkClient


class TimeService:
    def __init__(self, client: ClockLinkClient) -> None:
        self.client = client

    def sync_now(self):
        return self.client.sync_time(datetime.now())

    def get_time(self):
        return self.client.time_get()
