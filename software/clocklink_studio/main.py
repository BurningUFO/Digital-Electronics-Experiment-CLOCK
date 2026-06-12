"""ClockLink Studio 命令行入口。

该文件只负责解析命令行参数并调用服务层，不直接拼接协议字符串。
协议帧由 protocol.commands.CommandBuilder 生成，收发由 transport 层负责。
"""

from __future__ import annotations

import argparse
import sys

from protocol.codec import decode_frame, hex_to_ascii_text, parse_payload
from services.client import ClockLinkClient
from transport.mock_transport import MockTransport
from transport.serial_transport import SerialTransport


def make_client(args: argparse.Namespace) -> ClockLinkClient:
    """根据命令行参数创建 mock 或真实串口客户端。"""
    if args.mock or not args.port:
        return ClockLinkClient(MockTransport())
    return ClockLinkClient(SerialTransport(args.port))


def print_frame(label: str, frame) -> None:
    print(f"{label}: {frame.seq_hex} {frame.cmd} {frame.payload}")


def run_demo(client: ClockLinkClient) -> None:
    """无子命令时执行最小连通性演示。"""
    print_frame("hello", client.hello())
    print_frame("ping", client.ping())
    print_frame("status", client.status())


def build_parser() -> argparse.ArgumentParser:
    """定义 CLI 命令表；命令名与 UART_PROTOCOL.md 中的协议能力对应。"""
    parser = argparse.ArgumentParser(description="ClockLink Studio CLI")
    parser.add_argument("--mock", action="store_true", help="use mock FPGA transport")
    parser.add_argument("--port", help="serial port such as COM5")
    sub = parser.add_subparsers(dest="command")

    sub.add_parser("ping")
    sub.add_parser("status")
    sub.add_parser("sync-time")
    sub.add_parser("time-get")

    msg = sub.add_parser("send-message")
    msg.add_argument("text")

    get_msg = sub.add_parser("message-get")
    get_msg.add_argument("--slot", type=int, default=0)

    mock_reply = sub.add_parser("mock-reply")
    mock_reply.add_argument("--slot", type=int, default=0)
    mock_reply.add_argument("--reply", type=int, default=0)

    alarm = sub.add_parser("alarm-set")
    alarm.add_argument("--slot", type=int, required=True)
    alarm.add_argument("--time", required=True)
    alarm.add_argument("--enable", type=int, choices=[0, 1], required=True)

    alarm_get = sub.add_parser("alarm-get")
    alarm_get.add_argument("--slot", type=int, required=True)

    sched = sub.add_parser("sched-set")
    sched.add_argument("--slot", type=int, required=True)
    sched.add_argument("--time", required=True)
    sched.add_argument("--type", type=int, required=True)
    sched.add_argument("--enable", type=int, choices=[0, 1], required=True)

    sched_get = sub.add_parser("sched-get")
    sched_get.add_argument("--slot", type=int, required=True)

    count = sub.add_parser("count-set")
    count.add_argument("--time", required=True)
    sub.add_parser("count-start")
    sub.add_parser("count-stop")
    sub.add_parser("count-status")
    sub.add_parser("gui")
    return parser


def main(argv: list[str] | None = None) -> int:
    """CLI 主流程。每个分支只做一类业务操作，结束时统一关闭 transport。"""
    parser = build_parser()
    args = parser.parse_args(argv)
    client = make_client(args)

    try:
        if args.command is None:
            run_demo(client)
        elif args.command == "ping":
            print_frame("ping", client.ping())
        elif args.command == "status":
            print_frame("status", client.status())
        elif args.command == "sync-time":
            print_frame("sync-time", client.sync_time())
        elif args.command == "time-get":
            print_frame("time", client.time_get())
        elif args.command == "send-message":
            stored = client.send_message(args.text)
            print_frame("message", stored)
            payload = parse_payload(stored.payload)
            if payload.get("slot") == "0":
                print_frame("slot0", client.get_message(0))
        elif args.command == "message-get":
            print_frame("message", client.get_message(args.slot))
        elif args.command == "mock-reply":
            if not isinstance(client.transport, MockTransport):
                parser.error("mock-reply requires --mock or no --port")
            reply_frame = decode_frame(client.transport.mock_reply(args.slot, args.reply))
            print_frame("reply", reply_frame)
            payload = parse_payload(reply_frame.payload)
            if "text" in payload:
                print(f"reply-text: {hex_to_ascii_text(payload['text'])}")
        elif args.command == "alarm-set":
            print_frame("alarm", client.alarm_set(args.slot, args.time, bool(args.enable)))
        elif args.command == "alarm-get":
            print_frame("alarm", client.alarm_get(args.slot))
        elif args.command == "sched-set":
            print_frame("schedule", client.sched_set(args.slot, args.time, args.type, bool(args.enable)))
        elif args.command == "sched-get":
            print_frame("schedule", client.sched_get(args.slot))
        elif args.command == "count-set":
            print_frame("count", client.count_set(args.time))
        elif args.command == "count-start":
            print_frame("count", client.count_start())
        elif args.command == "count-stop":
            print_frame("count", client.count_stop())
        elif args.command == "count-status":
            print_frame("count", client.count_status())
        elif args.command == "gui":
            from ui.main_window import ClockLinkWindow

            ClockLinkWindow(client).run()
        else:
            parser.error(f"unknown command {args.command}")
    finally:
        client.transport.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
