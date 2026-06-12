"""ClockLink 帧 BODY 的 XOR 校验工具。"""

def _ascii_bytes(text: str) -> bytes:
    """协议只允许 ASCII；这里集中把编码错误转换为 ValueError。"""
    try:
        return text.encode("ascii")
    except UnicodeEncodeError as exc:
        raise ValueError("protocol fields must be ASCII") from exc


def xor_checksum(body: str) -> int:
    """计算 BODY 中所有 ASCII 字节的逐字节 XOR。"""
    value = 0
    for byte in _ascii_bytes(body):
        value ^= byte
    return value


def checksum_hex(body: str) -> str:
    """返回两位大写十六进制校验字符串。"""
    return f"{xor_checksum(body):02X}"
