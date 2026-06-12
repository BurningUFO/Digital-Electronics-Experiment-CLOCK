from .codec import (
    FrameError,
    ascii_text_to_hex,
    decode_frame,
    encode_frame,
    hex_to_ascii_text,
    parse_payload,
    serialize_payload,
)
from .frame import Frame

__all__ = [
    "Frame",
    "FrameError",
    "ascii_text_to_hex",
    "decode_frame",
    "encode_frame",
    "hex_to_ascii_text",
    "parse_payload",
    "serialize_payload",
]
"""ClockLink 协议层包。

包含帧结构、XOR 校验、编解码和 PC 命令构造器。
"""
