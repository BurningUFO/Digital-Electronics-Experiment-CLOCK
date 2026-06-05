# sim/comm

本目录用于保存通信相关 Verilog testbench。

当前包括：

- `tb_uart_rx.v`
- `tb_uart_tx.v`
- `tb_comm_ctrl_msg.v`
- `tb_comm_ctrl_reply.v`
- `tb_comm_ctrl_time.v`
- `tb_comm_ctrl_control.v`

计划包括：

- `tb_message_store.v`
- `tb_protocol_parser.v`

## Phase 3 使用说明

`tb_uart_rx.v` 和 `tb_uart_tx.v` 使用 100 MHz 时钟、115200 baud 参数，验证单字节 `8'hA5` 的 8N1 接收和发送。

Vivado/XSim 命令示例：

```tcl
read_verilog clock_amd.srcs/sources_1/new/uart_rx.v
read_verilog sim/comm/tb_uart_rx.v
set_property top tb_uart_rx [current_fileset]
launch_simulation
```

也可以在 Vivado Tcl 中使用 `xvlog/xelab/xsim` 分别运行两个 testbench。

新增 HDL 文件加入 Vivado 工程时，将以下文件加入 Sources：

- `clock_amd.srcs/sources_1/new/uart_rx.v`
- `clock_amd.srcs/sources_1/new/uart_tx.v`

## Phase 5 使用说明

`tb_comm_ctrl_msg.v` 使用 1 MHz 测试时钟和 100000 baud 加速仿真，向 `comm_ctrl` 的 UART RX 输入一条 `MSG_TX` 帧，检查：

- slot0 是否保存 `Hello` 消息。
- 时间戳是否保存。
- 未读计数是否为 1。
- UART TX 是否返回 `MSG_STORED` 帧。

XSim 命令示例：

```bash
xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/preset_reply_rom.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_msg.v
xelab tb_comm_ctrl_msg -s tb_comm_ctrl_msg_sim
xsim tb_comm_ctrl_msg_sim -runall
```

## Phase 6 使用说明

`tb_comm_ctrl_reply.v` 使用同样的 1 MHz 测试时钟和 100000 baud 加速仿真。流程为：

- 先通过 UART 输入 `MSG_TX Hello`，等待 `MSG_STORED`。
- 模拟 `BTNC` 进入回复模式。
- 模拟 `BTND` 选择回复 1：`Busy now.`。
- 模拟 `BTNR` 发送回复。
- 检查 UART TX 输出 `#F0|REPLY|slot=0;reply=1;ts=2026-06-05T15:03:00;text=42757379206E6F772E*5C`。

XSim 命令示例：

```bash
xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/preset_reply_rom.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_reply.v
xelab tb_comm_ctrl_reply -s tb_comm_ctrl_reply_sim
xsim tb_comm_ctrl_reply_sim -runall
```

## Phase 7 使用说明

`tb_comm_ctrl_time.v` 使用同样的 1 MHz 测试时钟和 100000 baud 加速仿真。流程为：

- 发送合法 `TIME_SET`：`date=2026-06-05;time=15:03:00;weekday=5`。
- 检查 `pc_time_load_valid` 和 `pc_date_load_valid` 同周期只打一拍。
- 检查输出到 `time_core/date_core` 的 BCD 字段。
- 捕获 UART `ACK`，确认 `cmd=TIME_SET`。
- 发送 `TIME_GET`，确认返回 `TIME` 帧。
- 发送非法月份、非法日期和非法 weekday，确认返回 `NACK BAD_TIME` 且不产生加载脉冲。

XSim 命令示例：

```bash
xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/preset_reply_rom.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_time.v
xelab tb_comm_ctrl_time -s tb_comm_ctrl_time_sim
xsim tb_comm_ctrl_time_sim -runall
```

## Phase 5b 综合收敛说明

Phase 5b 在 `oled_ui_display.v` 的 OLED page data 发送路径中增加 `COL -> RENDER -> SEND` 三步流水，用于切断 `step_index -> page_data -> ll_cmd_data` 的同周期组合路径。

复跑综合 timing：

```bash
vivado -mode batch -source scripts/run_phase_synth_check.tcl
```

2026-06-05 检查结果：

- `tb_comm_ctrl_msg` 仍输出 `PASS tb_comm_ctrl_msg`。
- Vivado timing clean：`WNS=+1.345ns`，`TNS=0.000ns`，失败端点 `0`。
- `protocol_parser.v:365` 仍有 `msg_char_buf_reg[0..99]` 综合 warning，当前不影响 testbench 和 timing，后续协议扩展时建议处理。

## Phase 8 使用说明

`tb_comm_ctrl_control.v` 使用同样的 1 MHz 测试时钟和 100000 baud 加速仿真。流程为：

- 发送 `ALARM_SET`，检查 `pc_alarm_write_valid` 和写入字段。
- 发送 `ALARM_GET`，检查返回 `ALARM slot=N;time=HH:MM:SS;enable=...`。
- 发送 `SCHED_SET`，检查 `pc_sched_write_valid`、时间、类型和开关字段。
- 发送 `SCHED_GET`，检查返回 `SCHED slot=N;time=HH:MM:SS;type=N;enable=...`。
- 发送 `COUNT_SET/COUNT_START/COUNT_STOP/COUNT_STATUS`，检查直接加载、启动/停止脉冲和状态返回。
- 发送非法闹钟槽位和非法倒计时时间，检查返回 `NACK` 且没有写入/加载副作用。

XSim 命令示例：

```bash
xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/preset_reply_rom.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_control.v
xelab tb_comm_ctrl_control -s tb_comm_ctrl_control_sim
xsim tb_comm_ctrl_control_sim -runall
```

2026-06-05 Phase 8 检查结果：

- `tb_comm_ctrl_control` 输出 `PASS tb_comm_ctrl_control`。
- `tb_comm_ctrl_time`、`tb_comm_ctrl_msg`、`tb_comm_ctrl_reply` 回归均通过。
- 初次 Vivado 综合脚本在 10 分钟工具预算内超时；随后修复 `protocol_builder.v` 分类型构帧状态后重跑通过。
- 最终综合 timing clean：`WNS=+1.232ns`、`TNS=0.000ns`、失败端点 `0`，日志显示 `All user specified timing constraints are met.`。
