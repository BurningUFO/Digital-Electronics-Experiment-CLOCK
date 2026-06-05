from .client import ClockLinkClient


class MessageService:
    def __init__(self, client: ClockLinkClient) -> None:
        self.client = client

    def send(self, text: str):
        return self.client.send_message(text)

    def get(self, slot: int):
        return self.client.get_message(slot)

    def clear(self, slot: int | str = "all"):
        return self.client.clear_message(slot)
