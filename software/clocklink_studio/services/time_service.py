"""时间同步业务服务封装。"""

from datetime import datetime

from .client import ClockLinkClient


class TimeService:
    """同步 PC 当前时间或读取 FPGA 当前时间。"""

    def __init__(self, client: ClockLinkClient) -> None:
        self.client = client

    def sync_now(self):
        return self.client.sync_time(datetime.now())

    def get_time(self):
        return self.client.time_get()
