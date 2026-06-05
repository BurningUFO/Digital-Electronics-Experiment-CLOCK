# CODEBASE_MAP

本文档记录 `clock_amd` 当前 Vivado 工程结构，以及 ClockLink Studio / COMM 模式已接入后的接口边界。

生成时间：2026-06-05

## 0. 基础检查结论

已确认存在的关键文件：

- `clock_amd.xpr`
- `README.md`
- `HANDOFF.md`
- `docs/工程模块使用说明.md`
- `clock_amd.srcs/sources_1/new/clock_amd_top.v`
- `clock_amd.srcs/sources_1/new/clock.v`
- `clock_amd.srcs/sources_1/new/ui_ctrl.v`
- `clock_amd.srcs/sources_1/new/display_ctrl.v`
- `clock_amd.srcs/sources_1/new/oled_ui_display.v`
- `clock_amd.srcs/sources_1/new/alarm_ctrl.v`
- `clock_amd.srcs/sources_1/new/schedule_ctrl.v`
- `clock_amd.srcs/sources_1/new/countdown_ctrl.v`
- `clock_amd.srcs/constrs_1/new/clock_amd.xdc`

缺失文件：

- `docs/ClockLink_Studio_PC_Software_Design.md` 原始文件缺失。本次 Phase 0 已按任务说明和现有 workflow 重建为设计基线草案；如后续找到原始版本，需要人工对照合并。

## 1. 顶层 `clock_amd_top.v` 端口说明

`clock_amd_top` 是 Nexys A7 100T 板级顶层。

输入端口：

| 端口 | 宽度 | 当前用途 |
| --- | --- | --- |
| `CLK100MHZ` | 1 | 100 MHz 主时钟；顶层内分频生成 `tick_1k` |
| `CPU_RESETN` | 1 | 低有效复位，传给多数模块时保持低有效语义 |
| `BTNL` | 1 | 左键，浏览层切上一模式或设置层上一字段 |
| `BTNR` | 1 | 右键，浏览层切下一模式或设置层下一字段 |
| `BTNU` | 1 | 上键，设置增量；COUNT 浏览层启动 |
| `BTND` | 1 | 下键，设置减量；COUNT 浏览层停止 |
| `BTNC` | 1 | 确认键；提醒激活时确认/消音 |
| `SW[15:0]` | 16 | 非 COMM 模式保留原设置/槽位逻辑；COMM 模式低位优先选择最近 16 条消息 |
| `UART_RXD` | 1 | Nexys A7 J6 USB-UART RX，PC 到 FPGA，115200 8N1 |

输出端口：

| 端口 | 宽度 | 当前用途 |
| --- | --- | --- |
| `AN[7:0]` | 8 | 八位数码管位选，低有效 |
| `CA..CG` | 7 个单线 | 七段码段选，低有效 |
| `DP` | 1 | 小数点，低有效 |
| `LED[15:0]` | 16 | 低 8 位显示 ALARM/SCHED 槽位状态，高 8 位保持 0 |
| `BUZZER_IO` | 1 | 外置低电平触发有源蜂鸣器 |
| `UART_TXD` | 1 | Nexys A7 J6 USB-UART TX，FPGA 到 PC，115200 8N1 |

双向端口：

| 端口 | 当前用途 |
| --- | --- |
| `OLED_SCL/OLED_SDA` | 外接 SSD1306 OLED I2C |
| `TMP_SCL/TMP_SDA` | Nexys A7 板载 ADT7420 I2C |

顶层已声明 USB-UART `UART_RXD/UART_TXD` 端口，`clock_amd.xdc` 已约束 J6 USB-UART 引脚：`UART_RXD=C4`、`UART_TXD=D4`。

## 2. `clock.v` 内部模块连接关系

`clock.v` 是功能主线集成模块，外部只接按键、开关、时钟、复位和显示/状态输出。主要连接如下：

| 子模块 | 当前连接/职责 |
| --- | --- |
| `clk_ring` | 基于 `tick_1k` 生成 `tick_1h`，当前工程中该信号实际作为 1 Hz 走时脉冲使用 |
| `ui_ctrl` | 接收按键和 `SW`，输出 `mode_state`、`setting_active`、`field_index`、增减/确认脉冲和原始按键脉冲 |
| `comm_ctrl` | 接入 UART、协议解析、消息缓存、预设回复、时间同步和 PC 对闹钟/日程/倒计时的直接控制 |
| `protocol_parser/protocol_builder` | 解析 `#SEQ|CMD|PAYLOAD*CS\n`，构造 ACK/NACK/STATUS/TIME/ALARM/SCHED/COUNT/REPLY 等回复 |
| `message_store/preset_reply_rom` | 保存最近 16 条消息并提供固定 8 条预设回复 |
| `time_core` | 保存当前 `HH:MM:SS` BCD，响应 TIME 设置层增减脉冲和正常走时 |
| `date_core` | 保存 `MM/DD/weekday`，响应 CLOCK 设置层增减脉冲和跨天脉冲 |
| `hour_format_ctrl` | 保存 12/24 小时显示格式 |
| `hour_format_display` | 将内部 24 小时制转换为显示小时 |
| `alarm_ctrl` | 管理 8 槽位闹钟、pending、贪睡和最近闹钟扫描 |
| `countdown_ctrl` | 管理倒计时编辑、运行、停止和到零事件 |
| `schedule_ctrl` | 管理 8 槽日程、槽位开关、类型、pending 和最近日程扫描 |
| `notification_ctrl` | 仲裁 COUNT/ALARM/SCHED 提醒，驱动蜂鸣器和 OLED 弹窗状态 |
| `display_ctrl` | 根据模式和各功能状态生成 8 个 6-bit 字符码 |

`clock.v` 输出 `digit_code_bus[47:0]`，位序为 `{D7,D6,D5,D4,D3,D2,D1,D0}`，最终由顶层 `nexys_seg_scan` 扫描显示。

## 3. `ui_ctrl.v` 模式状态机

当前模式编码：

| 模式 | 编码 | 显示名 |
| --- | --- | --- |
| `MODE_NORMAL` | `3'b000` | CLOCK |
| `MODE_TIME_SET` | `3'b001` | TIME |
| `MODE_ALARM` | `3'b010` | ALARM |
| `MODE_HOUR_FORMAT` | `3'b011` | HOUR |
| `MODE_COUNTDOWN` | `3'b100` | COUNT |
| `MODE_SCHEDULE` | `3'b101` | SCHED |
| `MODE_COMM` | `3'b110` | COMM |
| 保留 | `3'b111` | 未使用 |

当前浏览层顺序：

`CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM -> CLOCK`

当前 `setting_active` 规则：

- 非 SCHED 模式：`SW0=1` 为设置层。
- SCHED 模式：`(|SW[7:0]) | SW15` 为设置层。
- COMM 模式：`setting_active=0`，`SW0-SW15` 用于消息选择。

COMM 回复选择由 `comm_ctrl` 内部 `comm_reply_mode` 管理；进入回复模式时 `ui_ctrl` 的 `mode_nav_lock` 锁定左右模式导航，避免 `BTNR` 发送回复时同时切换模式。

## 4. `display_ctrl.v` 数码管显示路径

当前数码管路径：

`clock.v` 采集功能状态 -> `display_ctrl` 输出 8 个 6-bit 字符码 -> `clock.v` 拼成 `digit_code_bus` -> `clock_amd_top` -> `nexys_seg_scan` -> `seg_7` -> Nexys A7 七段管。

当前位含义：

| 数码管位 | `digit_code_bus` 片段 | 当前含义 |
| --- | --- | --- |
| D0 / AN0 | `[5:0]` | 秒个位或最右字符 |
| D1 / AN1 | `[11:6]` | 秒十位 |
| D2 / AN2 | `[17:12]` | 分个位 |
| D3 / AN3 | `[23:18]` | 分十位 |
| D4 / AN4 | `[29:24]` | 时个位/模式数据 |
| D5 / AN5 | `[35:30]` | 时十位/模式数据 |
| D6 / AN6 | `[41:36]` | 状态字符 |
| D7 / AN7 | `[47:42]` | 模式字符 |

`seg_7.v` 已扩展 `M/I/G/W/!` 等近似字符。`display_ctrl` 在 `MODE_COMM` 下用左四位显示 `COMM`，右四位显示 `DISC/WAIT/CONN/MSG!/ERR `。

## 5. `oled_ui_display.v` OLED 显示路径

当前 OLED 路径：

`clock_amd_top` 直接实例化 `oled_ui_display`，并把 `mode_state`、编辑状态、温度、日期、最近闹钟、最近日程、倒计时和提醒状态传入。

`oled_ui_display` 内部特点：

- 自带 SSD1306 初始化和分页刷新状态机。
- 通过 `page_data(page,col,edit_flag)` 生成每一页每一列的像素。
- 内置 8x 字体 `glyph_row/glyph_column`。
- 普通页面显示日期/温度/最近日程/最近闹钟/倒计时/当前模式标签。
- 提醒激活时用弹窗覆盖普通页面。
- 当前 `mode_label_ascii` 对未知模式默认显示 `SCHED`。

COMM 模式不复用普通主页。当前 `oled_ui_display.v` 已显示 ClockLink 通信页面、消息日期/时间/正文窗口和预设回复选择页面；提醒弹窗仍保持覆盖优先级。

## 6. 现有功能模块接口

### 6.1 `time_core.v`

输入：

- `tick_1h`：走时脉冲。
- `freeze_run`：TIME 设置层暂停走时。
- `add_sec_pulse/dec_sec_pulse`
- `add_min_pulse/dec_min_pulse`
- `add_hour_pulse/dec_hour_pulse`

输出：

- `sec_ten_bcd/sec_unit_bcd`
- `min_ten_bcd/min_unit_bcd`
- `hour_ten_bcd/hour_unit_bcd`

Phase 7 已新增 PC 直接加载接口：

- `pc_time_load_valid`
- `pc_hour_ten_bcd/pc_hour_unit_bcd`
- `pc_min_ten_bcd/pc_min_unit_bcd`
- `pc_sec_ten_bcd/pc_sec_unit_bcd`

加载脉冲优先级高于按键增减和自动走时；`clock.v` 由 `comm_ctrl` 直接驱动这些端口，不通过模拟按键同步时间。

### 6.2 `date_core.v`

输入：

- `day_tick_pulse`
- `month_inc_pulse/month_dec_pulse`
- `day_inc_pulse/day_dec_pulse`
- `weekday_inc_pulse/weekday_dec_pulse`

输出：

- `month_ten_bcd/month_unit_bcd`
- `day_ten_bcd/day_unit_bcd`
- `weekday`

Phase 7 已新增 PC 日期直接加载接口和年份保存：

- `pc_date_load_valid`
- `pc_year_thousand_bcd/pc_year_hundred_bcd/pc_year_ten_bcd/pc_year_unit_bcd`
- `pc_month_ten_bcd/pc_month_unit_bcd`
- `pc_day_ten_bcd/pc_day_unit_bcd`
- `pc_weekday`
- 输出 `year_thousand_bcd/year_hundred_bcd/year_ten_bcd/year_unit_bcd`

限制：日期自动跨天仍只更新月/日/星期，不自动递增年份；第一版不实现闰年。

### 6.3 `alarm_ctrl.v`

输入：

- 槽位选择：`alarm_slot_inc_pulse/alarm_slot_dec_pulse`
- 时间编辑：`alarm_hour/min/sec_inc/dec_pulse`
- 开关：`alarm_enable_inc/dec/toggle_pulse`
- 提醒确认和贪睡：`alarm_event_ack_pulse`、`snooze_*`
- 当前时间 BCD：`cur_*`

输出：

- 当前选中槽时间和开关。
- `alarm_slot_enable_mask`、`alarm_slot_selected_mask`、`alarm_pending_mask`
- 最近闹钟 `next_alarm_*`
- `alarm_event_valid/alarm_event_slot`

Phase 8 已新增 PC 直接控制接口：

- 写槽口：`pc_alarm_write_valid`、`pc_alarm_write_slot`、`pc_alarm_write_*_bcd`、`pc_alarm_write_enable`。
- 独立读槽口：`pc_alarm_read_slot`、`pc_alarm_read_*_bcd`、`pc_alarm_read_enable`。
- PC 写入优先级高于同周期手动编辑，并清除该槽 pending、snooze 和 match 状态。

### 6.4 `schedule_ctrl.v`

输入：

- `schedule_slot_switches[7:0]`：当前通过开关选择槽位，低位优先。
- 时间编辑脉冲：`schedule_hour/min/sec_inc/dec_pulse`
- 类型编辑：`schedule_type_inc/dec_pulse`
- 开关：`schedule_enable_*`
- 当前时间 BCD：`cur_*`

输出：

- 当前选中槽时间、类型和开关。
- `schedule_slot_enable_mask`、`schedule_slot_selected_mask`、`schedule_pending_mask`
- 最近日程 `next_schedule_*`
- `schedule_event_valid/schedule_event_slot`

SCHED 已占用 `SW[7:0]` 做槽位选择。COMM 中也要用 `SW0-SW15` 做消息选择，因此 `clock.v` 已将 `schedule_slot_switches` 限定为 `mode_schedule ? sw[7:0] : 8'd0`，避免 COMM 模式下查看消息时改变 SCHED 选中槽。

Phase 8 已新增 PC 直接控制接口：

- 写槽口：`pc_sched_write_valid`、`pc_sched_write_slot`、`pc_sched_write_*_bcd`、`pc_sched_write_type`、`pc_sched_write_enable`。
- 独立读槽口：`pc_sched_read_slot`、`pc_sched_read_*_bcd`、`pc_sched_read_type`、`pc_sched_read_enable`。
- PC 写入优先级高于同周期手动编辑，并清除该槽 pending 和 match 状态。

### 6.5 `countdown_ctrl.v`

输入：

- 设置脉冲：`hour/min/sec_inc/dec_pulse`
- 运行控制：`countdown_start_pulse/countdown_stop_pulse`
- `tick_1h`

输出：

- `countdown_run`
- `countdown_done_pulse`
- 剩余时间 BCD

Phase 8 已新增 PC 直接控制接口：

- `pc_count_load_valid` 和 `pc_count_*_bcd` 直接加载倒计时初值。
- `pc_count_start_pulse` 和 `pc_count_stop_pulse` 直接启动/停止倒计时。
- PC load 优先于手动编辑，并按协议固定为“加载新值且停止倒计时”；需要运行时由 PC 再发送 `COUNT_START`。

## 7. PC 通信接入点

当前 PC 通信接入点：

- `uart_rx.v`：100 MHz 下 115200 8N1，输出 `rx_valid/rx_data`。
- `uart_tx.v`：100 MHz 下 115200 8N1，输入 `tx_start/tx_data`，输出 `tx_busy/tx_done`。
- `protocol_parser.v`：基于 `UART_PROTOCOL.md` 解析 ASCII 帧。
- `protocol_builder.v`：构造 ACK/NACK/STATUS/TIME/ALARM/SCHED/COUNT/MSG_STORED/REPLY 等帧；Phase 8 已拆成分类型构帧状态以满足 timing。
- `comm_ctrl.v`：连接 UART、协议、消息缓存、COMM UI 状态和 PC 直接写入接口。
- `message_store.v`：16 条消息缓存，输出当前选择消息的 64 字符 OLED 窗口。
- `oled_ui_display.v`：直接消费 COMM 页面输入。

## 8. 新增 COMM 模式可能影响的模块

必须修改：

- `ui_ctrl.v`：增加 `MODE_COMM`，修改 next/prev 顺序和 `setting_active` 规则。
- `display_ctrl.v`：增加 COMM 数码管显示。
- `seg_7.v`：扩展 `M/I/G/W/!` 等显示字符。
- `oled_ui_display.v`：增加 COMM 专用页面。
- `clock.v`：增加 `mode_comm`、COMM 控制层和显示/状态转发。
- `clock_amd_top.v`：增加 UART 顶层端口并向下连接。
- `clock_amd.xdc`：增加 USB-UART 引脚约束。
- `scripts/run_phase_synth_check.tcl`：新增 HDL 文件后同步纳入综合检查。

后续直接写入功能还会修改：

- `time_core.v`
- `date_core.v`
- `alarm_ctrl.v`
- `schedule_ctrl.v`
- `countdown_ctrl.v`

## 9. 风险和建议

1. `docs/ClockLink_Studio_PC_Software_Design.md` 原始文件缺失。已重建基线草案，但后续若找到原文需核对协议和 PC 软件结构。
2. OLED 模块体量大且时序敏感。COMM 页面应先做简单文本页，再逐步增加消息滚动，不要一次加入复杂组合逻辑。
3. 七段字符集不足。COMM 状态显示前必须扩展 `seg_7.v`，并接受七段管对 `M/W/G/!` 的近似显示。
4. SCHED 和 COMM 都要解释 `SW`。必须只在 COMM 模式下使用 `SW0-SW15` 选消息，避免破坏 SCHED 当前槽位选择。
5. 时间/日期/闹钟/日程/倒计时目前没有直接写入接口。PC 同步不能通过重复按键脉冲实现，必须新增写端口。
6. `clock_amd_top.v` 当前复位语义混合：传给 `clock` 是低有效 `CPU_RESETN`，传给 OLED/ADT7420 是高有效 `~CPU_RESETN`。新增模块时要明确复位极性。
7. `tick_1h` 命名与实际 1 Hz 用法不一致。后续不建议在本项目内重命名，避免无关重构；文档中按“走时脉冲”解释。
8. 协议解析在 FPGA 中处理 ASCII/HEX 会增加资源和状态机复杂度。第一版应限制最大帧长、消息 ASCII 100 字符、payload 结构固定。

## 10. 下一阶段建议

当前 ClockLink 首版代码、仿真、PC mock 测试和 Vivado 综合已完成。下一阶段建议：

1. 生成 bitstream，并按 `docs/FINAL_DEMO_GUIDE.md` 进行 Nexys A7 板级演示。
2. 上板确认 USB-UART、OLED COMM 页面、SW 消息选择、BTNU/BTND 滚动、BTNC/BTNR 回复链路。
3. 后续增强真实串口异步事件监听、`MSG_GET/MSG_DATA` FPGA 流式返回、`ALARM_DUMP/SCHED_DUMP` 多帧 dump。
4. 重构 `protocol_parser.v` 的 `msg_char_buf_reg[0..99]` 暂存结构，消除同优先级 set/reset 综合 warning。
