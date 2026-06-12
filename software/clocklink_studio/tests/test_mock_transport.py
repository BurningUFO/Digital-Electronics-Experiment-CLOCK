from datetime import datetime

"""MockTransport 行为测试。

覆盖 mock FPGA 对连接、时间、消息、主动回复和倒计时语义的模拟结果。
"""

from protocol.codec import decode_frame, hex_to_ascii_text, parse_payload
from protocol.commands import CommandBuilder
from services.client import ClockLinkClient
from transport.mock_transport import MockTransport


def make_client() -> ClockLinkClient:
    return ClockLinkClient(MockTransport(), CommandBuilder())


def test_mock_ping():
    frame = make_client().ping()
    assert frame.cmd == "PONG"


def test_mock_time_set_get():
    client = make_client()
    response = client.sync_time(datetime(2026, 6, 5, 15, 3, 0))
    assert response.cmd == "ACK"
    time_frame = client.time_get()
    assert parse_payload(time_frame.payload) == {
        "date": "2026-06-05",
        "time": "15:03:00",
        "weekday": "5",
    }


def test_mock_message_store_and_get():
    client = make_client()
    stored = client.send_message("Hello")
    assert stored.cmd == "MSG_STORED"
    assert parse_payload(stored.payload)["slot"] == "0"
    msg = client.get_message(0)
    payload = parse_payload(msg.payload)
    assert msg.cmd == "MSG_DATA"
    assert payload["valid"] == "1"
    assert hex_to_ascii_text(payload["text"]) == "Hello"


def test_mock_raw_transport_response_is_decodable():
    transport = MockTransport()
    line = CommandBuilder().status_get()
    response = transport.transact(line)
    assert decode_frame(response).cmd == "STATUS"


def test_mock_reply_event_is_decodable():
    transport = MockTransport()
    frame = decode_frame(transport.mock_reply(slot=0, reply=1, timestamp=datetime(2026, 6, 5, 15, 3, 0)))
    payload = parse_payload(frame.payload)
    assert frame.seq_hex == "F0"
    assert frame.cmd == "REPLY"
    assert payload["slot"] == "0"
    assert payload["reply"] == "1"
    assert payload["ts"] == "2026-06-05T15:03:00"
    assert hex_to_ascii_text(payload["text"]) == "Busy now."


def test_mock_count_set_stops_countdown():
    client = make_client()
    client.count_set("00:05:00")
    client.count_start()
    assert parse_payload(client.count_status().payload)["run"] == "1"
    client.count_set("00:03:00")
    payload = parse_payload(client.count_status().payload)
    assert payload == {"time": "00:03:00", "run": "0"}
