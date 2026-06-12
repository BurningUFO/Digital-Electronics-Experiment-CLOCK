"""消息业务服务封装。"""

from .client import ClockLinkClient


class MessageService:
    """发送、读取和清除 ClockLink 消息。"""

    def __init__(self, client: ClockLinkClient) -> None:
        self.client = client

    def send(self, text: str):
        return self.client.send_message(text)

    def get(self, slot: int):
        return self.client.get_message(slot)

    def clear(self, slot: int | str = "all"):
        return self.client.clear_message(slot)
