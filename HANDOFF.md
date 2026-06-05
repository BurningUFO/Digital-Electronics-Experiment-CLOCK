# HANDOFF

## 你接手时必须先知道的约定

1. 本目录 `clock_amd` 是唯一最终工作区。
2. 以后只修改本目录内文件。
3. Vivado 工程入口固定为 `clock_amd.xpr`。
4. 当前没有 `.docx/.doc` 文件，项目书和日志都在 `docs/*.md`。

## 允许修改的核心目录

- `clock_amd.srcs/sources_1/new/`
- `clock_amd.srcs/constrs_1/new/`
- `scripts/`
- `docs/`
- 根目录下的 `README.md / HANDOFF.md`

## 不建议直接碰的内容

- `.Xil/`
- `clock_amd.cache/`
- `clock_amd.hw/`
- `clock_amd.ip_user_files/`
- `clock_amd.runs/`
- `clock_amd.sim/`
- `vivado*.log`
- `vivado*.jou`
- `xvlog.log / xvlog.pb`
- `xelab.log / xelab.pb`
- `xsim.dir/`
- `dfx_runtime.txt`
- `artifacts/tool-runs/`

这些基本都是工具生成物，不是主线源码。

## 接手时建议先读

1. `README.md`
2. `docs/AGENT_WORKLOG.md`
3. `docs/COMM_MODE_FPGA_PLAN.md`
4. `docs/UART_PROTOCOL.md`
5. `docs/FINAL_DEMO_GUIDE.md`
6. `docs/工程模块使用说明.md`

## 当前主线重点模块

- `clock.v`：系统主线集成。
- `clock_amd_top.v`：顶层板级接线，含 OLED、ADT7420、蜂鸣器、LED、数码管和 USB-UART。
- `ui_ctrl.v`：统一 UI 控制和提醒激活时的交互冻结。
- `display_ctrl.v`：八位数码管显示与闪烁。
- `oled_ui_display.v`：OLED 状态副屏和提醒弹窗。
- `comm_ctrl.v`：ClockLink USB-UART 通信控制，连接 UART、协议解析、消息缓存、回复和 PC 直接控制接口。
- `protocol_parser.v / protocol_builder.v`：ClockLink ASCII UART 帧解析和回复构造。
- `message_store.v / preset_reply_rom.v`：COMM 消息缓存和固定预设回复。
- `adt7420_reader.v`：板载 ADT7420 温度读取。
- `notification_ctrl.v`：倒计时、闹钟、计划提醒统一仲裁。
- `alarm_ctrl.v`：8 槽位闹钟、pending 队列、贪睡、最近闹钟分时扫描。
- `schedule_ctrl.v`：8 固定计划点、pending 队列、最近计划分时扫描。
- `countdown_ctrl.v`：倒计时。
- `date_core.v`：软日期和星期。
- `hour_format_ctrl.v / hour_format_display.v`：12/24 显示格式。

## 当前已知背景

1. 原有 `CLOCK / TIME / ALARM / HOUR / COUNT / SCHED` 功能已经主线集成。
2. ClockLink Studio 已新增第七个 `COMM` 模式，模式顺序为 `CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM -> CLOCK`。
3. COMM 模式已接入 UART、协议解析、16 条消息缓存、OLED 消息页面、预设回复、时间同步、闹钟/日程/倒计时 PC 直接控制。
4. PC 软件位于 `software/clocklink_studio/`，支持 mock/serial transport、CLI、Tkinter GUI 演示面板和 pytest。
5. 最新综合检查已通过，`WNS=+1.232ns`，`TNS=0.000ns`，失败端点 `0`。
6. 尚未生成 bitstream，尚未进行 Nexys A7 板级 USB-UART/COMM 实测。
