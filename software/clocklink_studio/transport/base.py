"""ClockLink 传输层抽象接口。"""

from abc import ABC, abstractmethod


class BaseTransport(ABC):
    """所有 transport 的最小公共契约。

    transact 用于 PC 主动命令的同步请求-响应；
    poll_event 用于真实串口下接收 FPGA 主动 REPLY/EVENT。
    """

    @abstractmethod
    def transact(self, frame_line: str) -> str:
        """发送完整帧文本并返回响应帧文本。"""
        raise NotImplementedError

    def poll_event(self) -> str | None:
        """轮询 FPGA 主动帧；不支持主动事件的 transport 返回 None。"""
        return None

    def close(self) -> None:
        """释放底层资源。Mock 没有资源时可为空实现。"""
        return None
