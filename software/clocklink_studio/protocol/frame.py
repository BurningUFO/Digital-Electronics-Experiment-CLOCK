from dataclasses import dataclass


@dataclass(frozen=True)
class Frame:
    seq: int
    cmd: str
    payload: str = ""

    @property
    def seq_hex(self) -> str:
        return f"{self.seq & 0xFF:02X}"

    @property
    def body(self) -> str:
        return f"{self.seq_hex}|{self.cmd}|{self.payload}"
