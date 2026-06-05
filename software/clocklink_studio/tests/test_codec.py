import pytest

from protocol.codec import (
    FrameError,
    ascii_text_to_hex,
    decode_frame,
    encode_frame,
    hex_to_ascii_text,
    parse_payload,
)


def test_known_hello_checksum():
    assert encode_frame(0x01, "HELLO", {"role": "pc", "ver": "0.1", "caps": "mock"}) == (
        "#01|HELLO|role=pc;ver=0.1;caps=mock*3C\n"
    )


def test_decode_round_trip():
    line = encode_frame(0x04, "MSG_TX", "ts=2026-06-05T15:03:00;len=5;text=48656C6C6F")
    frame = decode_frame(line)
    assert frame.seq == 4
    assert frame.cmd == "MSG_TX"
    payload = parse_payload(frame.payload)
    assert payload["len"] == "5"


def test_bad_checksum_rejected():
    with pytest.raises(FrameError):
        decode_frame("#01|HELLO|role=pc*00\n")


def test_message_hex_helpers():
    assert ascii_text_to_hex("Hello") == "48656C6C6F"
    assert hex_to_ascii_text("48656C6C6F") == "Hello"


def test_message_limit():
    with pytest.raises(FrameError):
        ascii_text_to_hex("A" * 101)
