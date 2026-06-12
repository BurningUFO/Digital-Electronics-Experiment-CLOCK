"""ClockLink 协议帧的轻量数据结构。"""

from dataclasses import dataclass


@dataclass(frozen=True)
class Frame:
    """解码后的单帧数据。

    seq 使用整数保存，seq_hex/body 属性用于重新展示协议中的 ASCII 形式。
    """

    seq: int
    cmd: str
    payload: str = ""

    @property
    def seq_hex(self) -> str:
        return f"{self.seq & 0xFF:02X}"

    @property
    def body(self) -> str:
        return f"{self.seq_hex}|{self.cmd}|{self.payload}"
