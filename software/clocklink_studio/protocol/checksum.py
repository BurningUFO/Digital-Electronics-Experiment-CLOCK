def _ascii_bytes(text: str) -> bytes:
    try:
        return text.encode("ascii")
    except UnicodeEncodeError as exc:
        raise ValueError("protocol fields must be ASCII") from exc


def xor_checksum(body: str) -> int:
    value = 0
    for byte in _ascii_bytes(body):
        value ^= byte
    return value


def checksum_hex(body: str) -> str:
    return f"{xor_checksum(body):02X}"
