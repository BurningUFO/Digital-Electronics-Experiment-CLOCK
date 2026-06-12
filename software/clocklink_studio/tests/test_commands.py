"""命令构造器测试。

这些测试不仅检查命令存在，还保护 payload 字段顺序，因为 FPGA 第一版
解析器按固定顺序逐字符解析部分命令。
"""

from datetime import datetime

import pytest

from protocol.codec import FrameError, decode_frame, parse_payload
from protocol.commands import CommandBuilder


def test_msg_tx_builder_payload():
    builder = CommandBuilder()
    line = builder.msg_tx("Hello", datetime(2026, 6, 5, 15, 3, 0))
    frame = decode_frame(line)
    payload = parse_payload(frame.payload)
    assert frame.cmd == "MSG_TX"
    assert payload["ts"] == "2026-06-05T15:03:00"
    assert payload["len"] == "5"
    assert payload["text"] == "48656C6C6F"


def test_time_set_builder_payload():
    builder = CommandBuilder()
    frame = decode_frame(builder.time_set(datetime(2026, 6, 5, 15, 3, 0)))
    payload = parse_payload(frame.payload)
    assert frame.cmd == "TIME_SET"
    assert frame.payload == "date=2026-06-05;time=15:03:00;weekday=5"
    assert payload == {"date": "2026-06-05", "time": "15:03:00", "weekday": "5"}


def test_phase8_control_payload_order():
    builder = CommandBuilder()

    alarm = decode_frame(builder.alarm_set(1, "07:30:00", True))
    sched = decode_frame(builder.sched_set(2, "08:45:10", 3, False))
    count = decode_frame(builder.count_set("00:05:30"))
    alarm_get = decode_frame(builder.alarm_get(1))
    sched_get = decode_frame(builder.sched_get(2))

    assert alarm.cmd == "ALARM_SET"
    assert alarm.payload == "slot=1;time=07:30:00;enable=1"
    assert alarm_get.payload == "slot=1"
    assert sched.cmd == "SCHED_SET"
    assert sched.payload == "slot=2;time=08:45:10;type=3;enable=0"
    assert sched_get.payload == "slot=2"
    assert count.cmd == "COUNT_SET"
    assert count.payload == "time=00:05:30"


def test_builder_rejects_long_message():
    builder = CommandBuilder()
    with pytest.raises(FrameError):
        builder.msg_tx("A" * 101)
