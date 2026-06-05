from .client import ClockLinkClient


class CountdownService:
    def __init__(self, client: ClockLinkClient) -> None:
        self.client = client

    def set_time(self, time_text: str):
        return self.client.count_set(time_text)

    def start(self):
        return self.client.count_start()

    def stop(self):
        return self.client.count_stop()

    def status(self):
        return self.client.count_status()
