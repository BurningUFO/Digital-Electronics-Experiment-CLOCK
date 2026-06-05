# COMM_MODE_FPGA_PLAN

本文档记录 FPGA 端 COMM 模式改造计划和阶段状态。

## Phase 4 状态

已完成 COMM 骨架：

- `MODE_COMM = 3'b110`。
- 模式顺序：`CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM -> CLOCK`。
- COMM 模式下 `setting_active=0`，`SW0-SW15` 不再触发设置层，为 Phase 5 消息选择预留。
- 数码管左四位显示 `COMM`，右四位显示通信状态。
- 当前通信状态硬连为 `DISC`。
- OLED 在 COMM 模式显示通信专用标题页，不复用普通状态主页。
- 顶层新增 `UART_RXD/UART_TXD`，XDC 约束到 Nexys A7 J6 USB-UART。
- `UART_TXD` 当前保持 idle 高电平，协议接入留到 Phase 5。

## 模式编码

| 模式 | 编码 |
| --- | --- |
| CLOCK | `3'b000` |
| TIME | `3'b001` |
| ALARM | `3'b010` |
| HOUR | `3'b011` |
| COUNT | `3'b100` |
| SCHED | `3'b101` |
| COMM | `3'b110` |
| 保留 | `3'b111` |

## 通信状态编码

| 编码 | 数码管文本 | 含义 |
| --- | --- | --- |
| `3'd0` | `DISC` | 未连接或协议未握手 |
| `3'd1` | `WAIT` | 等待 PC 响应或等待命令 |
| `3'd2` | `CONN` | 已握手连接 |
| `3'd3` | `MSG!` | 有未读消息 |
| `3'd4` | `ERR ` | 通信错误 |

七段管对 `M/W/G/!` 为近似显示，OLED 使用 8x 字形正常显示。

## 已修改模块

| 文件 | Phase 4 改动 |
| --- | --- |
| `ui_ctrl.v` | 新增 COMM 模式和顺序；COMM 下禁用设置层 |
| `seg_7.v` | 扩展 `M/I/G/W/!` 近似七段字符 |
| `display_ctrl.v` | 新增 `comm_status` 输入和 COMM 显示分支 |
| `clock.v` | 新增 UART 端口、`comm_status` 输出、COMM dp 屏蔽 |
| `clock_amd_top.v` | 新增 UART 顶层端口并向下连接；OLED 增加 COMM 状态输入 |
| `oled_ui_display.v` | 新增 COMM 专用页面和 COMM 状态文本 |
| `clock_amd.xdc` | 新增 J6 USB-UART C4/D4 约束 |

## SW 和按键策略

Phase 4：

- COMM 下 `SW0-SW15` 不触发设置层。
- COMM 下按键仍由 `ui_ctrl` 输出原始按键脉冲，但当前未被 COMM 逻辑消费。

Phase 5：

- `SW0-SW15` 选择最近 16 条消息，低位优先。
- 多个 SW 同时开启时，选择最低位。
- `BTNU/BTND` 滚动消息正文。
- `BTNC` 在查看消息和回复选择之间切换。
- `BTNR` 在回复选择模式下发送预设回复。

Phase 6：

- 只有在 COMM 模式且当前选择 slot 有有效消息时，`BTNC` 才会进入或退出回复模式。
- 回复模式下 `BTNU/BTND` 在 8 条固定回复之间循环选择。
- 回复模式下 `BTNR` 通过 UART 发送 `REPLY` 帧；发送期间若 builder 正忙，本次按键会被忽略，用户可再次按 `BTNR`。
- 回复模式下 `ui_ctrl` 锁定左右模式导航，避免 `BTNR` 发送回复时同时切换到下一模式。

## UART 接入策略

Phase 4：

- 顶层端口和 XDC 已准备。
- `UART_TXD` 保持 idle 高电平。
- `UART_RXD` 暂未解析。

Phase 5 起：

1. 在 `clock.v` 或独立 `comm_ctrl.v` 中实例化 `uart_rx/uart_tx`。
2. 接入 `protocol_parser.v` 和 `protocol_builder.v`。
3. `comm_ctrl` 输出 `comm_status`，替代当前硬连 `DISC`。
4. PC `HELLO/PING/STATUS_GET/MSG_TX` 驱动状态和消息缓存。

## Phase 5 状态

已完成并通过 XSim 验证：

- `comm_ctrl.v` 接入 `uart_rx/uart_tx`。
- `protocol_parser.v` 解析 `HELLO/PING/STATUS_GET/MSG_TX/MSG_CLEAR`，并对暂未实现命令返回 `NACK/UNSUPPORTED`。
- `protocol_builder.v` 构造 `ACK/PONG/STATUS/MSG_STORED/NACK`。
- `message_store.v` 保存最近 16 条消息，新消息进入 slot0，旧消息后移。
- COMM 模式下 `SW0-SW15` 低位优先选择消息；无开关时默认 slot0。
- COMM OLED 有消息时显示：
  - `[YYYY-MM-DD]`
  - `[HH:MM:SS]`
  - 四行 16 字符正文窗口
- `BTNU/BTND` 调整正文滚动行。

Phase 5 初始限制：

- `MSG_GET/MSG_DATA` 协议保持定义，但 FPGA Phase 5 暂返回 `NACK/UNSUPPORTED`。
- Vivado 综合脚本未能在 5 分钟和 10 分钟工具预算内完成；日志显示大量宽 mux，峰值内存约 8.3GB。
- 下一次 HDL 工作必须先做资源收敛，不应直接进入预设回复功能。

已执行的 Phase 5b 收敛：

1. `message_store.v` 改为环形 slot 指针，避免每次新消息移动 16 x 100 字符。
2. `message_store.v` 仅输出当前选中消息的 64 字符窗口，不再跨模块输出 800-bit 完整正文。
3. `protocol_parser.v` 改为流式解析，不再保存完整 BODY；`MSG_TX` 正文只在校验通过后逐字符提交给 `message_store`。
4. `protocol_builder.v` 暂不构造 `MSG_DATA` 宽帧，`MSG_GET` 第一版返回 `NACK/UNSUPPORTED`。
5. `oled_ui_display.v` 的 `ST_PAGE_DATA` 增加 `COL -> RENDER -> SEND` 三步流水，切断 `step_index -> page_data -> ll_cmd_data` 同周期关键路径。

Phase 5b 验证结果：

- 全源 `xvlog` 通过。
- `tb_comm_ctrl_msg` 通过，输出 `PASS tb_comm_ctrl_msg`。
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl` 完成；`WNS=+1.345ns`、`TNS=0.000ns`、失败端点 `0`，日志显示 `All user specified timing constraints are met.`。

当前限制：

- `MSG_GET/MSG_DATA` 协议保持定义，但 FPGA Phase 5 暂返回 `NACK/UNSUPPORTED`。
- `protocol_parser.v:365` 仍有 `msg_char_buf_reg[0..99]` 同优先级 set/reset 综合 warning；当前仿真和综合 timing 通过，后续扩展协议功能时建议改写本地消息暂存结构。
- 尚未生成 bitstream，尚未在 Nexys A7 上实测 USB-UART/OLED 消息路径。

## Phase 6 状态

已完成预设回复首版：

- 新增 `preset_reply_rom.v`，固定 8 条 ASCII 回复：
  - `OK, received.`
  - `Busy now.`
  - `Will check later.`
  - `Please sync time.`
  - `System normal.`
  - `Alarm noted.`
  - `Schedule noted.`
  - `Need help.`
- `comm_ctrl.v` 增加回复模式状态、回复索引、BTNC/BTNU/BTND/BTNR 控制和 FPGA 本地 `REPLY` 序号计数。首个主动回复序号为 `F0`，之后递增。
- `protocol_builder.v` 增加 `RESP_REPLY`，输出 payload：
  - `slot=0..15;reply=0..7;ts=YYYY-MM-DDTHH:MM:SS;text=HEX`
- Phase 6 当前 `ts` 使用被回复消息的原始时间戳；Phase 7 时间同步完成后，可改为 FPGA 当前发送时间。
- `protocol_builder.v` 对请求参数增加一拍本地锁存和 `ST_BUILD` 状态，避免 REPLY 宽构帧路径造成 timing violation。
- `oled_ui_display.v` 在回复模式显示 `REPLY MODE`、`R0..R7`、当前预设回复文本和消息时间。
- `ui_ctrl.v` 增加 `mode_nav_lock`，COMM 回复模式下锁住左右模式切换。
- `clock.v` 和 `clock_amd_top.v` 已把回复模式和回复索引传到 OLED。
- `scripts/run_phase_synth_check.tcl` 已包含 `preset_reply_rom.v`。

Phase 6 验证结果：

- `tb_comm_ctrl_msg` 仍通过，输出 `PASS tb_comm_ctrl_msg`。
- `tb_comm_ctrl_reply` 通过，输出 `PASS tb_comm_ctrl_reply`，捕获 `#F0|REPLY|slot=0;reply=1;ts=2026-06-05T15:03:00;text=42757379206E6F772E*5C`。
- 全源 `xvlog` 通过。
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl` 完成；`WNS=+0.092ns`、`TNS=0.000ns`、失败端点 `0`，日志显示 `All user specified timing constraints are met.`。

Phase 6 限制：

- OLED 回复文本目前在 `preset_reply_rom.v` 和 `oled_ui_display.v` 中各有一份映射；本阶段保持功能稳定，后续可统一为单一 ROM/字符读口减少维护重复。
- PC 真实串口异步事件监听尚未完整实现；Phase 6 PC 侧提供 mock `REPLY` 事件生成和日志打印，真实串口事件日志留到 GUI/serial 完整化阶段。
- `protocol_parser.v:365` 的 `msg_char_buf_reg[0..99]` 同优先级 set/reset warning 仍存在，沿用 Phase 5b 已知问题。

## Phase 7 状态

已完成时间同步首版：

- `time_core.v` 新增 `pc_time_load_valid` 和 `HH:MM:SS` BCD 直接加载端口。
- `date_core.v` 新增 `pc_date_load_valid`、年份/月/日/星期 BCD 直接加载端口，并保存 4 位年份 BCD。
- `clock.v` 把 `comm_ctrl` 的 PC 加载脉冲接入 `time_core/date_core`，并把当前日期时间反馈给 `comm_ctrl` 用于 `TIME_GET`。
- `protocol_parser.v` 解析固定顺序 `TIME_SET` payload：`date=YYYY-MM-DD;time=HH:MM:SS;weekday=N`。
- `protocol_builder.v` 增加 `RESP_TIME`、`ACK_TIME_SET` 和 `BAD_TIME` 错误名映射。
- `comm_ctrl.v` 对 `TIME_SET` 输出一拍 `pc_time_load_valid/pc_date_load_valid`，成功返回 `ACK cmd=TIME_SET`；对 `TIME_GET` 返回 `TIME`。
- 发送器正忙时，`TIME_SET/TIME_GET` 返回 `NACK TX_BUSY`，不会在返回 busy 的同时修改板上时间。
- PC 软件已增加 `TIME_SET` payload 顺序断言，保护 FPGA 第一版固定顺序解析要求。

Phase 7 验证结果：

- `tb_comm_ctrl_time` 通过，覆盖合法 `TIME_SET` 一拍加载、`TIME_GET` 返回 `TIME`、非法月份和非法日期返回 `NACK BAD_TIME`。
- `tb_comm_ctrl_msg` 仍通过，确认消息接收和 `MSG_STORED` 未退化。
- `tb_comm_ctrl_reply` 仍通过，确认预设回复 `REPLY` 未退化。
- 全源 `xvlog` 通过。
- `python -m pytest` 通过，13 个测试全部通过。
- `python main.py --mock sync-time` 返回 `ACK ack=01;cmd=TIME_SET`。
- `python main.py --mock time-get` 返回 `TIME date=...;time=...;weekday=...`。
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl` 通过；`WNS=+0.879ns`、`TNS=0.000ns`、失败端点 `0`，日志显示 `All user specified timing constraints are met.`。

Phase 7 限制：

- 日期自动跨天仍只更新月/日/星期，不自动递增年份；PC 可通过 `TIME_SET` 重新同步年份。
- 第一版不实现闰年，2 月最大 28 天。
- 主动 `REPLY` 的 `ts` 仍沿用被回复消息原始时间戳，未改为当前发送时间；这避免协议字段变化，后续如要改字段需先更新 `UART_PROTOCOL.md`。

## Phase 8 状态

已完成闹钟、日程和倒计时的 PC 直接控制首版：

- `alarm_ctrl.v` 新增 PC 写槽口和独立读槽口：
  - `pc_alarm_write_valid`
  - `pc_alarm_write_slot`
  - `pc_alarm_write_*_bcd`
  - `pc_alarm_write_enable`
  - `pc_alarm_read_slot`
  - `pc_alarm_read_*_bcd`
  - `pc_alarm_read_enable`
- `schedule_ctrl.v` 新增 PC 写槽口和独立读槽口，包含 `type` 和 `enable`。
- `countdown_ctrl.v` 新增 `pc_count_load_valid`、BCD 直接加载端口、`pc_count_start_pulse` 和 `pc_count_stop_pulse`。
- PC 写入脉冲优先级高于同周期手动编辑，并会清除对应槽位 pending/match 状态；闹钟写入还会清除对应 snooze 状态。
- `COUNT_SET` 直接加载新值并停止倒计时；PC 如需立即运行应随后发送 `COUNT_START`。
- `clock.v` 已把 `comm_ctrl` 的 PC 控制脉冲接入 `alarm_ctrl/schedule_ctrl/countdown_ctrl`，并把读回数据反馈给 `comm_ctrl`。
- `clock.v` 已把 `schedule_slot_switches` 限定为 `mode_schedule ? sw[7:0] : 8'd0`，避免 COMM 模式下 `SW0-SW15` 查看消息时改变 SCHED 选中槽。
- `protocol_parser.v` 已实现固定顺序解析：
  - `ALARM_SET slot=N;time=HH:MM:SS;enable=0|1`
  - `ALARM_GET slot=N`
  - `SCHED_SET slot=N;time=HH:MM:SS;type=N;enable=0|1`
  - `SCHED_GET slot=N`
  - `COUNT_SET time=HH:MM:SS`
  - `COUNT_START/COUNT_STOP/COUNT_STATUS`
- `protocol_builder.v` 已实现 `ALARM`、`SCHED` 和 `COUNT_STATUS` 返回帧。
- `comm_ctrl.v` 发送器正忙时返回 `NACK TX_BUSY`，并在 busy 场景下不产生写入、启动或停止副作用。

Phase 8 验证结果：

- `tb_comm_ctrl_control` 通过，覆盖 `ALARM_SET/GET`、`SCHED_SET/GET`、`COUNT_SET/START/STOP/STATUS`，并覆盖非法槽位/非法时间不会产生写入副作用。
- `tb_comm_ctrl_time`、`tb_comm_ctrl_msg`、`tb_comm_ctrl_reply` 回归通过。
- 全源 `xvlog` 通过。
- `python -m pytest` 通过，14 个测试全部通过。
- mock CLI 已验证 `alarm-get`、`sched-get`、`count-set`。
- 初次 10 分钟 Vivado 综合检查超时，随后定位并修复 `protocol_builder.v` 一拍宽构帧 timing violation：
  - 将通用 `ST_BUILD` 构帧拆成 `ST_BUILD_ACK/PONG/STATUS/MSG_STORED/REPLY/TIME/ALARM/SCHED/COUNT_STATUS/NACK` 分类型构帧状态。
  - 保持 UART 帧内容不变，降低 `response_kind -> tx_buf` 的组合扇出和路径层级。
- 最终 `vivado -mode batch -source scripts/run_phase_synth_check.tcl` 通过；`WNS=+1.232ns`、`TNS=0.000ns`、失败端点 `0`，日志显示 `All user specified timing constraints are met.`。

Phase 8 限制：

- FPGA 第一版不实现宽帧 `ALARM_DUMP/SCHED_DUMP`；PC 如需读取全部槽，循环发送 `ALARM_GET 0..7` 或 `SCHED_GET 0..7`。
- `protocol_parser.v:815` 仍有 `msg_char_buf_reg[0..99]` 同优先级 set/reset 综合 warning；当前 XSim 回归和综合 timing 通过，后续可重构本地暂存结构消除 warning。
- 尚未生成 bitstream，尚未在 Nexys A7 上实测 USB-UART、COMM OLED 和预设回复。

## 兼容性检查点

- 原有 6 模式的编码未改变。
- CLOCK 左切应进入 COMM，COMM 右切应回到 CLOCK。
- SCHED 中 `SW[7:0]` 选择槽位的行为必须只在 SCHED 模式解释。
- COMM 中 `SW0` 不得进入设置层。
- 提醒激活时 `notification_ctrl` 仍锁定 UI，OLED 提醒弹窗仍覆盖 COMM 页面。
- 顶层端口变化后必须更新 Vivado block/project source，重新综合和生成 bitstream。

## Vivado 工程加入说明

Phase 4 后需要在 Vivado 工程中确认以下新增/修改文件：

- 新增 Sources：`uart_rx.v`、`uart_tx.v`、`protocol_parser.v`、`protocol_builder.v`、`message_store.v`、`comm_ctrl.v`、`preset_reply_rom.v`。
- 修改 Sources：`ui_ctrl.v`、`seg_7.v`、`display_ctrl.v`、`clock.v`、`clock_amd_top.v`、`oled_ui_display.v`。
- 修改 Constraints：`clock_amd.xdc`。

若使用 Tcl 脚本检查，`scripts/run_phase_synth_check.tcl` 已包含 Phase 6 所需通信源文件。
