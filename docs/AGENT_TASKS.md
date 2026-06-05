# AGENT_TASKS

本文档保存可以直接复制给 Codex agent 的阶段任务 prompt。

## Phase 0 Prompt：工程理解

当前只做 Phase 0：工程理解与代码地图。

请阅读：

1. `README.md`
2. `HANDOFF.md`
3. `docs/工程模块使用说明.md`
4. `docs/ClockLink_Studio_PC_Software_Design.md`
5. `AGENTS.md`
6. `docs/AGENT_WORKFLOW.md`
7. `clock_amd.srcs/sources_1/new/` 下的主要 HDL 文件

任务：

- 生成 `docs/CODEBASE_MAP.md`。
- 不要修改任何 HDL。
- 不要修改 XDC。
- 不要写 PC 软件。
- 不要新增功能代码。

`CODEBASE_MAP.md` 至少包含：

1. 顶层 `clock_amd_top.v` 端口说明。
2. `clock.v` 内部模块连接关系。
3. `ui_ctrl.v` 的模式状态机。
4. `display_ctrl.v` 的数码管显示路径。
5. `oled_ui_display.v` 的 OLED 显示路径。
6. `alarm_ctrl.v`、`schedule_ctrl.v`、`countdown_ctrl.v` 的现有接口。
7. 为接入 PC 通信需要新增的接口点。
8. 新增 `COMM` 模式的风险点。
9. 下一阶段建议。

结束时更新 `docs/AGENT_WORKLOG.md`。

## Phase 1 Prompt：冻结 UART 协议

当前只做 Phase 1：冻结 PC 与 FPGA 的 USB-UART 协议。

请阅读：

1. `docs/ClockLink_Studio_PC_Software_Design.md`
2. `docs/CODEBASE_MAP.md`
3. `docs/AGENT_WORKFLOW.md`

任务：

- 完善 `docs/UART_PROTOCOL.md`。
- 不要修改 HDL。
- 不要写 PC 软件。
- 不要修改 XDC。

协议必须覆盖：

- `HELLO`
- `PING / PONG`
- `STATUS_GET / STATUS`
- `MODE_SET`
- `TIME_SET / TIME_GET`
- `ALARM_SET / ALARM_GET / ALARM_DUMP`
- `SCHED_SET / SCHED_GET / SCHED_DUMP`
- `COUNT_SET / COUNT_START / COUNT_STOP`
- `MSG_TX / MSG_GET / MSG_CLEAR`
- `REPLY`
- `EVENT`
- `ACK / NACK`

必须包含：

1. 帧格式。
2. 字段说明。
3. 校验方式。
4. 序号与重发规则。
5. 错误码。
6. PC 到 FPGA 命令表。
7. FPGA 到 PC 回复表。
8. 示例帧。
9. FPGA 解析建议。
10. PC 软件解析建议。

结束时更新 `docs/AGENT_WORKLOG.md`。

## Phase 2 Prompt：PC 协议库和 mock 模式

当前只做 Phase 2：PC 软件协议库与 mock FPGA。

请阅读：

1. `docs/UART_PROTOCOL.md`
2. `docs/ClockLink_Studio_PC_Software_Design.md`
3. `docs/AGENT_WORKFLOW.md`

任务：

- 在 `software/clocklink_studio/` 下建立 Python 项目骨架。
- 实现协议编码解码。
- 实现 mock FPGA transport。
- 实现命令行 demo。
- 实现基本单元测试。
- 不要修改 HDL。
- 不要修改 XDC。

建议结构：

```text
software/clocklink_studio/
├── README.md
├── requirements.txt
├── main.py
├── protocol/
│   ├── __init__.py
│   ├── frame.py
│   ├── codec.py
│   └── commands.py
├── transport/
│   ├── __init__.py
│   ├── mock_transport.py
│   └── serial_transport.py
└── tests/
    └── test_codec.py
```

验收：

- `python -m pytest` 通过。
- demo 可以发送 `HELLO`、`PING`、`TIME_SET`、`MSG_TX` 到 mock FPGA。
- mock FPGA 可以返回 `ACK`、`PONG`、`MSG_STORED`、`REPLY`。

结束时更新 `docs/AGENT_WORKLOG.md` 和 `software/clocklink_studio/README.md`。

## Phase 3 Prompt：FPGA UART RX/TX

当前只做 Phase 3：实现 FPGA UART RX/TX。

请阅读：

1. `docs/UART_PROTOCOL.md`
2. `docs/CODEBASE_MAP.md`
3. `docs/AGENT_WORKFLOW.md`

任务：

- 新增 `uart_rx.v`。
- 新增 `uart_tx.v`。
- 新增 UART testbench 到 `sim/comm/`。
- 支持 115200, 8N1。
- 暂时不要接入 `clock.v`。
- 暂时不要修改 OLED、消息缓存、闹钟、日程。

验收：

- testbench 能验证单字节收发。
- 说明如何加入 Vivado 工程。
- 如果运行了 Vivado 综合，记录结果。

结束时更新 `docs/AGENT_WORKLOG.md`。

## Phase 4 Prompt：COMM 模式骨架

当前只做 Phase 4：新增 COMM 模式骨架。

任务：

- 增加 `MODE_COMM`。
- 修改模式顺序：`CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM -> CLOCK`。
- COMM 模式数码管左四位显示 `COMM`。
- COMM 模式右四位显示 `DISC / CONN / WAIT / ERR` 等状态之一。
- OLED 在 COMM 模式显示通信专用标题页。
- 暂不实现消息存储。
- 暂不实现预设回复。
- 暂不实现时间同步。

验收：

- 原有 6 个模式不退化。
- COMM 模式可以进入和退出。
- 修改文件列表清晰。
- 更新 `docs/COMM_MODE_FPGA_PLAN.md`。
- 更新 `docs/AGENT_WORKLOG.md`。
