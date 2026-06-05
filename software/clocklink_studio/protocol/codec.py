import re
from typing import Mapping, Union

from .checksum import checksum_hex
from .frame import Frame

MAX_BODY_LENGTH = 320
MAX_MESSAGE_LENGTH = 100
CMD_RE = re.compile(r"^[A-Z0-9_]{1,16}$")
KEY_RE = re.compile(r"^[a-z0-9_]+$")
HEX_RE = re.compile(r"^[0-9A-Fa-f]*$")


class FrameError(ValueError):
    pass


PayloadValue = Union[str, int, bool]
PayloadInput = Union[str, Mapping[str, PayloadValue], None]


def _validate_ascii(text: str, what: str) -> None:
    try:
        text.encode("ascii")
    except UnicodeEncodeError as exc:
        raise FrameError(f"{what} must be ASCII") from exc


def _validate_payload_text(payload: str) -> None:
    _validate_ascii(payload, "payload")
    for bad in ("|", "*", "\n", "\r"):
        if bad in payload:
            raise FrameError(f"payload contains forbidden character {bad!r}")


def serialize_payload(payload: PayloadInput) -> str:
    if payload is None:
        return ""
    if isinstance(payload, str):
        _validate_payload_text(payload)
        return payload

    parts = []
    for key, value in payload.items():
        key_text = str(key)
        if not KEY_RE.match(key_text):
            raise FrameError(f"bad payload key: {key_text}")
        if isinstance(value, bool):
            value_text = "1" if value else "0"
        else:
            value_text = str(value)
        _validate_payload_text(value_text)
        if ";" in value_text or "=" in value_text:
            raise FrameError(f"bad payload value for key: {key_text}")
        parts.append(f"{key_text}={value_text}")
    return ";".join(parts)


def parse_payload(payload: str) -> dict[str, str]:
    if payload == "":
        return {}
    _validate_payload_text(payload)

    result: dict[str, str] = {}
    for field in payload.split(";"):
        if "=" not in field:
            raise FrameError(f"payload field has no '=': {field}")
        key, value = field.split("=", 1)
        if not KEY_RE.match(key):
            raise FrameError(f"bad payload key: {key}")
        result[key] = value
    return result


def encode_frame(seq: int, cmd: str, payload: PayloadInput = None) -> str:
    if not 0 <= seq <= 0xFF:
        raise FrameError("seq must be 0..255")
    cmd_text = cmd.upper()
    if not CMD_RE.match(cmd_text):
        raise FrameError(f"bad command: {cmd}")

    payload_text = serialize_payload(payload)
    body = f"{seq:02X}|{cmd_text}|{payload_text}"
    if len(body) > MAX_BODY_LENGTH:
        raise FrameError("frame body too long")
    return f"#{body}*{checksum_hex(body)}\n"


def decode_frame(data: Union[str, bytes]) -> Frame:
    if isinstance(data, bytes):
        try:
            text = data.decode("ascii")
        except UnicodeDecodeError as exc:
            raise FrameError("frame is not ASCII") from exc
    else:
        text = data
    _validate_ascii(text, "frame")

    if text.endswith("\n"):
        text = text[:-1]
    if text.endswith("\r"):
        text = text[:-1]
    if not text.startswith("#"):
        raise FrameError("frame must start with #")
    if "*" not in text:
        raise FrameError("frame missing checksum separator")

    body, cs_text = text[1:].rsplit("*", 1)
    if len(body) > MAX_BODY_LENGTH:
        raise FrameError("frame body too long")
    if len(cs_text) != 2 or not HEX_RE.match(cs_text):
        raise FrameError("checksum must be two hex digits")
    expected = checksum_hex(body)
    if cs_text.upper() != expected:
        raise FrameError(f"bad checksum: got {cs_text.upper()}, expected {expected}")

    parts = body.split("|", 2)
    if len(parts) != 3:
        raise FrameError("body must contain seq, cmd, payload")
    seq_text, cmd, payload = parts
    if len(seq_text) != 2 or not HEX_RE.match(seq_text):
        raise FrameError("seq must be two hex digits")
    if not CMD_RE.match(cmd):
        raise FrameError(f"bad command: {cmd}")
    _validate_payload_text(payload)
    return Frame(seq=int(seq_text, 16), cmd=cmd, payload=payload)


def ascii_text_to_hex(text: str) -> str:
    _validate_ascii(text, "message text")
    if len(text) > MAX_MESSAGE_LENGTH:
        raise FrameError("message text exceeds 100 characters")
    for ch in text:
        code = ord(ch)
        if code < 0x20 or code > 0x7E:
            raise FrameError("message text must be printable ASCII")
    return text.encode("ascii").hex().upper()


def hex_to_ascii_text(hex_text: str) -> str:
    if len(hex_text) % 2 != 0 or not HEX_RE.match(hex_text):
        raise FrameError("message text is not valid HEX")
    raw = bytes.fromhex(hex_text)
    try:
        text = raw.decode("ascii")
    except UnicodeDecodeError as exc:
        raise FrameError("decoded message text is not ASCII") from exc
    ascii_text_to_hex(text)
    return text
