# ClockLink 验收报告事实证据清单

生成时间：2026-06-09
用途：作为《ClockLink 智能电子钟系统》验收介绍文档的事实审查底稿。正式报告中的功能、指标和验证结论均应能回溯到本表或当前用户确认。

## 1. 功能事实表

| 功能/结论 | 证据来源文件 | 相关模块/代码/报告 | 是否已经实测 | 是否可写入正式报告 | 写法边界 |
| --- | --- | --- | --- | --- | --- |
| 项目运行平台为 Nexys A7-100T / XC7A100T-1CSG324C | `clock_amd.xpr`、`clock_amd.runs/impl_1/*rpt`、README | Vivado part `xc7a100tcsg324-1`，timing report device `7a100t-csg324` | 已用于 bitstream 生成和用户上板验证 | 是 | 写作时统一称 Nexys A7-100T / XC7A100T-1CSG324C |
| 板载主时钟为 100MHz | `clock_amd.xdc`、`clock_amd_top.v` | `CLK100MHZ`，`create_clock -period 10.000` | 已综合/实现 | 是 | 说明 10ns 周期约束 |
| 基础时分秒显示与走时 | README、`time_core.v`、`display_ctrl.v` | `CLOCK/TIME`，BCD `HH:MM:SS`，`tick_1k` 和走时脉冲 | 用户确认上板 OK | 是 | 不写为原子钟精度，只写为课程电子钟走时 |
| 复位功能 | `clock_amd_top.v`、XDC、docs | `CPU_RESETN=C12`，低有效复位 | 用户确认上板 OK | 是 | 明确低有效 |
| 校时功能 | README、`ui_ctrl.v`、`time_core.v` | `SW0=1` 设置层，左右切字段，上下调整 | 用户确认上板 OK | 是 | COMM 模式例外，不把 SW0 当设置层 |
| 七模式 UI | README、`ui_ctrl.v`、`CODEBASE_MAP.md` | `CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM -> CLOCK` | 用户确认上板 OK | 是 | 模式顺序必须按代码写 |
| 12/24 小时显示 | README、`hour_format_ctrl.v`、`hour_format_display.v` | 内部 24 小时，显示层切换 12/24 | 用户确认上板 OK | 是 | 不写成内部时间格式切换 |
| 8 槽位闹钟 | README、`alarm_ctrl.v` | 8 slot、LED mask、pending、snooze、PC 直接写槽 | 用户确认上板 OK | 是 | 写“8 槽位”；不要写成无限闹钟 |
| 8 槽位日程提醒 | README、`schedule_ctrl.v` | 8 fixed schedule slots、type、enable、pending、PC 写槽 | 用户确认上板 OK | 是 | 写“首版 8 个计划点/槽位” |
| 倒计时 | README、`countdown_ctrl.v` | `HH:MM:SS` 编辑、启动/停止、到零提醒、PC 直接控制 | 用户确认上板 OK | 是 | `COUNT_SET` 加载后停止，需要 `COUNT_START` 启动 |
| 统一提醒系统 | README、`notification_ctrl.v` | 仲裁 COUNT/ALARM/SCHED，统一蜂鸣器和 OLED 弹窗 | 用户确认上板 OK | 是 | 强调避免多个模块直接抢蜂鸣器 |
| 蜂鸣器低电平触发 | `clock_amd_top.v`、`工程模块使用说明.md` | `assign BUZZER_IO = ~buzzer_on`，`BUZZER_IO=C17` | 用户确认上板 OK | 是 | 写外置有源蜂鸣器低电平触发 |
| LED 槽位指示 | `clock_amd_top.v`、`clock.v`、XDC | `assign LED={8'b0, slot_led_mask}`，LED0-7 用于 ALARM/SCHED | 用户确认上板 OK | 是 | 高 8 位当前保持 0 |
| 八位七段数码管动态扫描 | `nexys_seg_scan.v`、`seg_7.v`、docs | 共阳极、位选/段选低有效，动态扫描 | 用户确认上板 OK | 是 | 写作时强调显示内容生成和扫描驱动分层 |
| OLED 状态副屏 | `oled_ui_display.v`、README、docs | 日期、温度、最近日程、最近闹钟、倒计时、提醒弹窗、COMM 页面 | 用户确认上板 OK；截图缺失 | 是 | 报告保留图占位，建议验收前补实物图 |
| ADT7420 温度链路 | `adt7420_reader.v`、`clock_amd_top.v`、XDC、README | `TMP_SCL=C14`、`TMP_SDA=C15`，OLED 可显示温度 | 旧文档称温度读数未单独实测；用户已确认整体上板 OK | 可写“链路已接入，建议补温度截图” | 不单独夸大为长期稳定温度采集已验证 |
| USB-UART 物理链路 | `UART_PROTOCOL.md`、XDC、`uart_rx.v`、`uart_tx.v` | J6 USB-UART，`UART_RXD=C4`，`UART_TXD=D4`，115200 8N1 | 用户确认上板 OK；长期稳定性截图缺失 | 是 | 写“当前验收准备阶段上板验证 OK”，建议补 GUI/串口截图 |
| ClockLink ASCII 协议 | `UART_PROTOCOL.md`、`protocol_parser.v`、`protocol_builder.v` | `#SEQ|CMD|PAYLOAD*CS\n`，XOR 校验 | XSim/pytest/上板确认 | 是 | `MSG_GET/MSG_DATA` 不写成 FPGA 已完整支持 |
| 16 条消息缓存 | `message_store.v`、`comm_ctrl.v`、`sim/comm/README.md` | slot0 最新，SW0-SW15 低位优先选择 | XSim/用户上板确认 | 是 | 消息正文第一版限 100 ASCII 字符 |
| 8 条预设回复 | `preset_reply_rom.v`、`comm_ctrl.v`、`tb_comm_ctrl_reply.v` | `OK, received.`、`Busy now.` 等 8 条，`REPLY` 帧 | XSim/pytest/用户上板确认 | 是 | 写“预设回复”，不要写自由文本板端输入 |
| PC 时间同步 | `UART_PROTOCOL.md`、`comm_ctrl.v`、`time_core.v`、`date_core.v` | `TIME_SET/TIME_GET` 直接加载日期时间 | XSim/pytest/用户上板确认 | 是 | 日期自动跨年/闰年按首版限制说明 |
| PC 闹钟/日程/倒计时控制 | `UART_PROTOCOL.md`、`comm_ctrl.v`、`alarm_ctrl.v`、`schedule_ctrl.v`、`countdown_ctrl.v` | `ALARM_SET/GET`、`SCHED_SET/GET`、`COUNT_SET/START/STOP/STATUS` | XSim/pytest/用户上板确认 | 是 | `ALARM_DUMP/SCHED_DUMP` 暂不写成 FPGA 已实现 |
| ClockLink Studio PC 软件 | `software/clocklink_studio/README.md`、源码、pytest | mock/serial transport、CLI、Tkinter GUI、服务层、中文/英文界面 | 当前实跑 pytest 17 passed | 是 | 真实 GUI 截图建议补充 |

## 2. 验证与指标证据表

| 验证/指标 | 当前结果 | 证据来源 | 可写入方式 |
| --- | --- | --- | --- |
| PC 单元测试 | `17 passed in 0.06s` | 本次执行 `python -m pytest`，目录 `software/clocklink_studio` | 写“当前 PC 软件 pytest 17 项全部通过” |
| UART RX/TX 仿真 | `tb_uart_rx`、`tb_uart_tx` PASS 记录 | `sim/comm/README.md`、`docs/AGENT_WORKLOG.md` | 写“UART 单字节收发 testbench 已覆盖” |
| COMM 消息仿真 | `tb_comm_ctrl_msg` PASS | `sim/comm/README.md`、`docs/AGENT_WORKLOG.md` | 写“消息接收、缓存、MSG_STORED 回归通过” |
| COMM 回复仿真 | `tb_comm_ctrl_reply` PASS | `sim/comm/README.md`、`docs/AGENT_WORKLOG.md` | 写“预设回复 REPLY 帧构造通过” |
| PC 直接控制仿真 | `tb_comm_ctrl_control` PASS | `sim/comm/README.md`、`docs/AGENT_WORKLOG.md` | 写“闹钟/日程/倒计时直接写入接口仿真通过” |
| 顶层展开 | 顶层 `xelab` 通过记录 | `docs/AGENT_WORKLOG.md` | 写“顶层展开检查通过”，注明曾使用 timescale override |
| 当前实现时序 | `WNS=+0.325ns`、`TNS=0.000ns`、失败端点 0、所有用户约束满足 | `clock_amd.runs/impl_1/clock_amd_top_timing_summary_routed.rpt` | 报告采用此值作为最终 routed timing |
| Hold 时序 | `WHS=+0.024ns`、`THS=0.000ns`、失败端点 0 | 同上 | 可作为补充指标 |
| 资源利用 | LUT 8184/63400=12.91%；Registers 8161/126800=6.44%；RAMB18 1；DSP 0；IOB 62/210=29.52% | `clock_amd_top_utilization_placed.rpt` | 写入资源利用表 |
| Route 状态 | routable nets 14545，fully routed 14545，routing errors 0 | `clock_amd_top_route_status.rpt` | 写“布线完成且无 routing error” |
| bitstream | `clock_amd_top.bit` / `.bin` 已生成，Bitgen Completed Successfully | `clock_amd.runs/impl_1/runme.log`、文件时间 2026-06-07 17:10:30 | 写“bitstream 已生成” |
| 上板验证 | 用户确认 Nexys A7 上板验证 OK；工作日志记录用户确认 | 本轮用户消息、`docs/AGENT_WORKLOG.md` | 写“当前验收准备阶段已上板验证 OK”，同时建议补截图 |

## 3. 不可夸大项

| 项目 | 当前证据 | 正式报告建议写法 |
| --- | --- | --- |
| `MSG_GET/MSG_DATA` | 协议冻结但 FPGA 为资源收敛暂返回 `NACK/UNSUPPORTED` | 写“协议预留，当前 PC 可发送消息到 FPGA；FPGA 端宽帧读回后续以流式方式扩展” |
| `ALARM_DUMP/SCHED_DUMP` | 协议预留，当前 FPGA 以单槽 `GET` 支持读取 | 写“PC 如需读取全部槽位，当前通过循环 `GET slot=0..7` 实现” |
| ADT7420 温度长期稳定读数 | HDL/XDC 已接入，缺少独立温度截图 | 写“温度读取链路已接入，建议验收前补 OLED 温度读数实拍” |
| 真实串口长期稳定性 | 用户确认上板 OK，仓库缺少长时间日志截图 | 写“已完成验收前板级验证，长期压力测试可作为后续迭代” |
| 日期跨年/闰年 | `UART_PROTOCOL.md` 明确第一版限制 | 写“软日期首版不处理闰年和自动跨年，PC 可重新同步” |
| DRC/methodology warnings | routed DRC 有 CFGBVS、RAMB18 async control、IO buffering 等 warning；timing methodology 有 missing I/O delay warning | 写“实现通过且无时序/布线错误；warning 作为后续工程规范优化项” |
