# ClockLink Studio PC Software Design

状态：Phase 9 实现版。

原始 `docs/ClockLink_Studio_PC_Software_Design.md` 在 2026-06-05 Phase 0 基础检查中未找到。本文档根据本轮任务要求、`docs/AGENT_WORKFLOW.md` 和现有工程接口重建，用作 ClockLink Studio PC 软件开发的最小设计基线。若后续找回原始设计文档，需要人工对照合并。

## 1. 目标

ClockLink Studio 是 `clock_amd` 的 PC 上位机，用 USB-UART 与 Nexys A7 FPGA 通信。

第一版目标与当前实现状态：

1. 支持 mock 模式，不连接 FPGA 也能开发和测试。
2. 支持真实串口模式，默认 UART 参数为 `115200, 8N1`。
3. 提供协议库，严格遵循 `docs/UART_PROTOCOL.md`。
4. 提供命令行 demo，覆盖连接、时间同步、消息发送、预设回复接收、闹钟/日程/倒计时控制。
5. 提供 Tkinter GUI 演示面板，最终演示时可视化显示状态并操作核心功能。

## 2. 软件结构

建议目录：

```text
software/clocklink_studio/
├── README.md
├── requirements.txt
├── main.py
├── protocol/
│   ├── __init__.py
│   ├── frame.py
│   ├── codec.py
│   ├── checksum.py
│   └── commands.py
├── transport/
│   ├── __init__.py
│   ├── base.py
│   ├── mock_transport.py
│   └── serial_transport.py
├── services/
│   ├── __init__.py
│   ├── time_service.py
│   ├── message_service.py
│   ├── alarm_service.py
│   ├── schedule_service.py
│   └── countdown_service.py
├── ui/
│   ├── __init__.py
│   └── main_window.py
└── tests/
    ├── test_codec.py
    ├── test_commands.py
    └── test_mock_transport.py
```

## 3. 分层职责

| 层 | 职责 |
| --- | --- |
| `protocol` | 编码/解码帧、校验、payload 编码、命令 builder |
| `transport` | 抽象发送/接收；mock transport 和 serial transport 共享接口 |
| `services` | 面向业务的时间、消息、闹钟、日程、倒计时操作 |
| `ui` | Tkinter GUI 演示面板 |
| `main.py` | CLI 入口和 demo 流程 |

## 4. Mock 模式

Mock FPGA 必须先实现。最小行为：

| PC 命令 | Mock 响应 |
| --- | --- |
| `HELLO` | `ACK`，payload 含 mock 版本 |
| `PING` | `PONG` |
| `STATUS_GET` | `STATUS` |
| `TIME_SET` | `ACK` 并更新 mock 时间 |
| `TIME_GET` | `TIME` |
| `MSG_TX` | 保存最近消息，返回 `MSG_STORED` |
| `MSG_GET` | 返回 `MSG_DATA` |
| `MSG_CLEAR` | 清空消息或指定 slot，返回 `ACK` |
| `ALARM_SET/SCHED_SET/COUNT_SET` | 更新 mock 状态并返回 `ACK` |
| `COUNT_START/COUNT_STOP` | 更新 mock 运行状态并返回 `ACK` |

Mock 模式应可用单元测试覆盖，不依赖 `pyserial`。

## 5. 串口模式

真实串口通过 `pyserial` 实现。串口层只负责字节收发和超时，不解析业务命令。

默认参数：

- baudrate: `115200`
- data bits: `8`
- parity: `N`
- stop bits: `1`
- read timeout: `0.2s`
- command timeout: `1.0s`

## 6. CLI 最小命令

建议第一版 CLI：

```bash
python main.py --mock ping
python main.py --mock status
python main.py --mock sync-time
python main.py --mock send-message "Hello FPGA"
python main.py --mock alarm-set --slot 0 --time 07:30:00 --enable 1
python main.py --mock sched-set --slot 0 --time 08:00:00 --type 0 --enable 1
python main.py --mock count-set --time 00:05:00
```

真实串口模式：

```bash
python main.py --port COM5 ping
```

## 7. GUI 目标

GUI 第一版已使用 Tkinter 实现，避免增加大型依赖。当前视觉层采用浅色桌面应用风格：顶部品牌栏、白色功能卡片、现代化标签页、类似 Telegram 的聊天气泡和深色底部日志控制台。

当前核心区域：

1. `Connect` 页：左侧为连接测试、时间同步和消息槽工具，右侧为聊天式消息区和发送框。
2. `Control` 页：闹钟槽读写、日程槽读写、倒计时设置/启动/停止/查询，按功能卡片分组。
3. 全局底部 `通信日志`：固定显示在窗口下半部分，显示每次请求的回复帧、消息正文解码结果和错误信息，并提供缩小、默认、放大三档高度控制。
4. `Connect` 页聊天记录：PC 发送显示为右侧蓝色气泡，FPGA/mock 回复显示为左侧白色气泡，系统提示居中显示，便于演示消息交互历史。

## 8. 验收

Phase 2 验收：

```bash
cd software/clocklink_studio
python -m pytest
python main.py --mock ping
python main.py --mock send-message "Hello FPGA"
```

最终验收：

1. mock 模式完整可运行。
2. CLI 和 GUI 能演示时间同步、消息发送、预设回复 mock 事件、闹钟/日程/倒计时控制。
3. 真实串口 transport 已实现，尚未完成 Nexys A7 板级 USB-UART 实测。
4. 协议实现和 `docs/UART_PROTOCOL.md` 一致。
