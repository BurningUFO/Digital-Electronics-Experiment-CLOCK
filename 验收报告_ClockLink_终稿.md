---
title: "ClockLink：基于 Nexys A7 的多功能智能电子钟系统"
subtitle: "从基础数字时钟到 PC 联动时间管理终端的 FPGA 实现"
author: "课程验收介绍文档"
date: "2026-06-09"
---

# 封面

**项目名称：ClockLink 智能电子钟系统**
**开发平台：Vivado 2025.2 / Nexys A7-100T**
**核心器件：XC7A100T-1CSG324C**
**主时钟：100 MHz**
**工程入口：`clock_amd.xpr`**
**顶层模块：`clock_amd_top.v`**
**验收状态：已生成 bitstream，用户已确认 Nexys A7 上板验证 OK**

ClockLink 不是一块只会显示时间的电子钟，而是一个集时间显示、校时、闹钟、倒计时、日程提醒、OLED 状态副屏和 PC 通信控制于一体的 FPGA 时间管理终端。它从数字电路课程中的基础电子钟要求出发，进一步把板上按键、拨码开关、数码管、LED、蜂鸣器、OLED、温度传感器和 USB-UART 上位机联动整合成一个完整的产品原型。

【图 0-1 ClockLink 系统封面图：此处插入 Nexys A7 开发板实物、数码管主显示区、OLED 副屏、蜂鸣器、USB-UART 连接和 PC 端 ClockLink Studio 界面的组合照片】

# 摘要

本项目完成了基于 Nexys A7-100T 的多功能智能电子钟系统。基础功能方面，系统能够在八位七段数码管上稳定显示时、分、秒，支持低有效复位、手动校时、100 MHz 主时钟下的分频走时和动态扫描显示，满足数字电子钟课程验收的核心要求。扩展功能方面，系统加入了 12/24 小时制显示、8 槽位闹钟、倒计时、8 槽位日程提醒、统一提醒仲裁、外置蜂鸣器、OLED 状态副屏和 ADT7420 温度读取链路，使电子钟从单一计时工具扩展为面向学习、作息和课堂展示的时间管理终端。

项目的主要亮点是 ClockLink Studio。FPGA 端新增 COMM 通信模式，通过 Nexys A7 J6 USB-UART 以 `115200 8N1` 与 PC 通信；PC 端提供 Python 协议库、mock 板卡、真实串口传输层、CLI 和 Tkinter GUI。上位机可以发送消息、同步时间、读取时间、设置闹钟、设置日程、设置并启动倒计时；FPGA 端能够缓存最近 16 条消息，在 OLED 上显示消息窗口，并通过 8 条预设回复向 PC 主动发送 `REPLY` 帧。

工程验证方面，当前 PC 软件 `pytest` 共 17 项测试全部通过；通信相关 XSim testbench 覆盖 UART 收发、消息缓存、预设回复、时间同步、闹钟/日程/倒计时直接控制等链路；Vivado `impl_1` routed timing report 显示 `WNS=+0.325ns`、`TNS=0.000ns`、失败端点为 0，所有用户指定时序约束满足；`clock_amd_top.bit` 已生成，用户已确认 Nexys A7 上板验证 OK。报告中对 `MSG_GET/MSG_DATA` 宽帧读回、ADT7420 温度长期截图、真实串口长期稳定性等边界保持如实说明。

# 1. 项目概述：从电子钟实验到智能时间管理终端

## 1.1 项目背景

数字电子钟是数字电路与 FPGA 课程中非常典型的综合题目。它看似只是“显示当前时间”，实际包含了计数器、分频器、BCD 编码、同步时序、状态机、按键处理、动态扫描显示和板级约束等多个知识点。一个能稳定运行的电子钟，必须把高速 FPGA 时钟转换为人能感知的秒级走时，把内部二进制或 BCD 状态转换为可读的数码管显示，还要处理真实按键抖动和复位后的确定状态。

本项目最初目标是完成基本数字电子钟：时、分、秒显示，系统时钟分频，计数控制，复位和校时。在基础功能完成后，项目继续向“可展示、可交互、可扩展”的方向迭代：加入多槽位闹钟、倒计时、课程/日程提醒、OLED 状态副屏、蜂鸣器提醒和 PC 上位机通信，最终形成 ClockLink 智能电子钟系统。它既能独立在 FPGA 板上运行，也能通过 PC 端软件进行更直观的管理。

## 1.2 产品定位

ClockLink 的第一层定位是一块独立可运行的 FPGA 电子钟。即使不连接 PC，它也能完成基本走时、显示、复位、校时、模式切换、闹钟、倒计时和日程提醒。数码管负责高可见度主显示，LED 与蜂鸣器提供直接反馈，OLED 负责更丰富的状态表达。

第二层定位是一套多模式时间管理工具。系统不是把多个小功能随意堆在一起，而是统一组织为 `CLOCK / TIME / ALARM / HOUR / COUNT / SCHED / COMM` 七个模式。用户使用左右键在模式之间切换，使用 `SW0` 区分浏览层和设置层，使用上下键完成数值修改，使用中心键完成确认、开关或提醒消音。统一交互让功能增加后仍然保持可理解。

第三层定位是一套软硬件联动系统。通过 USB-UART，PC 端 ClockLink Studio 可以向 FPGA 发送消息、同步时间、读取当前时间、设置闹钟、设置日程、控制倒计时；FPGA 也可以把板上选择的预设回复发送回 PC。这个设计让电子钟不再是孤立硬件，而成为一个可以被上位机管理的时间终端。

## 1.3 使用场景

在课堂验收场景下，ClockLink 可以先展示传统电子钟要求：复位后时间正常显示，秒位稳定递增，进入设置层后可以修改小时、分钟、秒，退出设置层后继续走时。之后逐步展示扩展能力：切换 12/24 小时制，设置一个接近当前时间的闹钟，设置短倒计时，展示日程提醒和 OLED 状态副屏。

在学习和作息场景下，8 槽位闹钟可以用于早起、上课、实验、休息等多个提醒点；倒计时可以用于实验计时、课堂演示倒数或番茄钟；日程模式可以映射课程表或固定作息；OLED 副屏可以承担日期、温度、最近提醒和通信消息状态显示。

在软硬件联动演示场景下，PC 端 ClockLink Studio 可以作为“控制台”。演示者可以在 GUI 中点击 HELLO、PING、SYNC、GET，发送消息 `Hello FPGA`，在板上进入 COMM 模式查看 `MSG!` 提示和 OLED 消息窗口，再通过板上按键选择 `Busy now.` 等预设回复，使 PC 日志收到 FPGA 主动 `REPLY` 帧。这一过程能直观体现 UART 协议、帧解析、消息缓存和上位机服务层的闭环。

## 1.4 平台与资源概述

本项目运行在 Nexys A7-100T 开发板上，Vivado 工程器件为 `xc7a100tcsg324-1`。板载输入时钟为 `CLK100MHZ`，XDC 中使用 `create_clock -period 10.000` 建立 100 MHz 时序约束。项目使用的主要板级资源包括五个方向/中心按键、16 个拨码开关、16 个 LED、八位七段数码管、外接有源蜂鸣器、外接 SSD1306 I2C OLED、板载 ADT7420 温度传感器接口，以及 Nexys A7 J6 USB-UART。

表 1-1 给出了主要输入输出资源。

| 资源 | 端口/引脚 | 当前用途 |
| --- | --- | --- |
| 100 MHz 时钟 | `CLK100MHZ=E3` | 系统唯一主时钟，生成 `tick_1k` 和秒级走时使能 |
| 复位 | `CPU_RESETN=C12` | 低有效系统复位 |
| 按键 | `BTNL/BTNR/BTNU/BTND/BTNC` | 模式切换、字段切换、数值增减、确认、消音、回复 |
| 拨码开关 | `SW[15:0]` | 浏览/设置层选择、槽位选择、COMM 消息选择 |
| 七段数码管 | `AN[7:0]`、`CA..CG`、`DP` | 主时间和模式状态显示，低有效动态扫描 |
| LED | `LED[15:0]` | 低 8 位用于闹钟/日程槽位状态，高 8 位保持 0 |
| 蜂鸣器 | `BUZZER_IO=C17` | 外置低电平触发有源蜂鸣器 |
| OLED | `OLED_SCL=D14`、`OLED_SDA=F16` | I2C 状态副屏 |
| 温度传感器 | `TMP_SCL=C14`、`TMP_SDA=C15` | 板载 ADT7420 温度读取链路 |
| USB-UART | `UART_RXD=C4`、`UART_TXD=D4` | ClockLink Studio 通信，115200 8N1 |

# 2. 验收要求对照

验收报告首先需要回答最核心的问题：这个项目是否完成了数字电子钟的基础要求。ClockLink 的扩展功能很多，但基础时钟、分频、计数、复位、校时和稳定显示仍然是整个项目的根。表 2-1 按课程常见验收要求列出对应实现和展示方式。

| 基础/扩展要求 | 本项目对应实现 | 证据来源 | 验收展示方式 |
| --- | --- | --- | --- |
| 时/分/秒显示 | `CLOCK/TIME` 模式显示 `HH:MM:SS`，八位七段数码管作为主显示区 | `time_core.v`、`display_ctrl.v`、README | 复位后观察秒位递增，切换到 TIME 查看时间 |
| 系统时钟分频与计数 | `CLK100MHZ` 下生成 `tick_1k`，再由走时脉冲驱动秒、分、小时计数 | `clock_amd_top.v`、`clk_ring.v`、`time_core.v` | 展示时钟分频框图和代码，观察 1 秒节奏 |
| 复位功能 | `CPU_RESETN` 低有效复位，系统回到确定初始状态 | XDC、`clock_amd_top.v` | 按下复位键后观察显示和状态恢复 |
| 校时功能 | 非 COMM 模式下 `SW0=1` 进入设置层，左右切字段，上下调整数值 | `ui_ctrl.v`、`time_core.v` | 修改小时、分钟、秒并退出设置层 |
| 显示稳定性 | 共阳极低有效数码管动态扫描，显示内容和扫描驱动分层 | `nexys_seg_scan.v`、`seg_7.v` | 观察八位数码管无明显错位和混乱 |
| 结构清晰 | 顶层、主线集成、UI、时间、显示、提醒、通信等模块分层 | `CODEBASE_MAP.md`、源码 | 展示系统架构图和核心模块表 |
| 工程实现 | Vivado routed timing 满足约束，bitstream 已生成 | `clock_amd_top_timing_summary_routed.rpt`、`runme.log` | 展示 WNS/TNS 和 bitgen 成功记录 |
| 扩展加分 | 12/24 小时制、8 槽位闹钟、倒计时、8 槽位日程、OLED、USB-UART、PC 上位机 | README、docs、HDL、PC 软件 | 按现场演示流程逐项展示 |

从这张表可以看出，本项目没有因为加入 PC 通信和 OLED 等扩展而偏离基础要求。相反，扩展功能都围绕“时间显示、时间管理、提醒反馈”展开，与基础电子钟形成连续的产品逻辑。

# 3. 系统整体架构

## 3.1 硬件组成

ClockLink 的硬件侧可以分成四个层次。第一层是输入交互层，包括 `CPU_RESETN`、五个按键和 16 个拨码开关。它们是用户直接操作 FPGA 的入口。第二层是核心逻辑层，包括时钟分频、时间核心、日期核心、模式控制、闹钟、倒计时、日程、提醒仲裁和 COMM 通信控制。第三层是显示反馈层，包括八位数码管、LED、OLED 和蜂鸣器。第四层是 PC 通信层，由 Nexys A7 J6 USB-UART 和 PC 端 ClockLink Studio 构成。

这种分层的好处是每个外设都有明确责任。数码管只承担主显示，不需要显示长文本；OLED 负责状态说明和消息窗口，不承担秒级主显示；蜂鸣器只由统一提醒模块驱动，不被多个功能直接抢占；PC 通信只通过协议接口写入时间、闹钟、日程和倒计时，不模拟大量按键脉冲。

## 3.2 RTL 模块组成

表 3-1 列出核心 RTL 模块职责。

| 文件/模块 | 职责 |
| --- | --- |
| `clock_amd_top.v / clock_amd_top` | Nexys A7 板级顶层，连接时钟、按键、开关、LED、数码管、OLED、温度、蜂鸣器和 USB-UART |
| `clock.v / clock` | 主线集成模块，连接 UI、时间、日期、闹钟、倒计时、日程、提醒、COMM 和显示 |
| `ui_ctrl.v / ui_ctrl` | 七模式状态机、浏览/设置层、字段选择、增减脉冲、确认脉冲、提醒锁定 |
| `button_pulse.v / button_pulse` | 按键同步、消抖和单周期脉冲生成 |
| `clk_ring.v / clk_ring` | 基于 `tick_1k` 产生秒级走时使能 |
| `time_core.v / time_core` | 当前时间保存、正常走时、手动校时、PC 时间直接加载 |
| `date_core.v / date_core` | 日期、星期和年份 BCD 保存，支持手动调整与 PC 同步 |
| `hour_format_ctrl.v`、`hour_format_display.v` | 12/24 小时显示格式保存与转换 |
| `alarm_ctrl.v / alarm_ctrl` | 8 槽位闹钟、LED mask、pending 队列、贪睡、PC 直接读写 |
| `countdown_ctrl.v / countdown_ctrl` | 倒计时编辑、启动、停止、到零事件、PC 直接加载/启停 |
| `schedule_ctrl.v / schedule_ctrl` | 8 槽位日程、类型、开关、pending、最近日程、PC 直接读写 |
| `notification_ctrl.v / notification_ctrl` | 统一仲裁倒计时、闹钟和日程提醒，输出蜂鸣器和 OLED 弹窗状态 |
| `display_ctrl.v / display_ctrl` | 生成八位数码管字符码和字段闪烁效果 |
| `nexys_seg_scan.v`、`seg_7.v` | Nexys A7 共阳极七段数码管动态扫描和字符译码 |
| `oled_ui_display.v / oled_ui_display` | OLED 状态副屏、提醒弹窗、COMM 消息页和回复页 |
| `adt7420_reader.v / adt7420_reader` | 读取板载 ADT7420 温度传感器链路 |
| `uart_rx.v`、`uart_tx.v` | 100 MHz 下 115200 8N1 UART 字节收发 |
| `protocol_parser.v`、`protocol_builder.v` | ClockLink ASCII 帧解析和回复构造 |
| `comm_ctrl.v / comm_ctrl` | COMM 模式通信控制、消息缓存、预设回复、PC 直接控制接口 |
| `message_store.v / message_store` | 最近 16 条 PC 消息缓存和 OLED 窗口输出 |
| `preset_reply_rom.v / preset_reply_rom` | 固定 8 条预设回复文本 |

## 3.3 数据流与控制流

系统的数据流从输入事件开始。按键经过 `button_pulse` 消抖后进入 `ui_ctrl`，`ui_ctrl` 根据当前模式和设置层状态生成字段选择、增量、减量、确认等控制脉冲。时间、闹钟、倒计时和日程模块根据这些脉冲更新自身状态，同时把当前可显示数据送给 `display_ctrl` 和 OLED 页面。

COMM 模式的数据流与普通按键流并行存在。PC 通过 USB-UART 发送 ASCII 帧，`uart_rx` 转为字节流，`protocol_parser` 校验并解析命令，`comm_ctrl` 决定是否写入 `time_core`、`date_core`、`alarm_ctrl`、`schedule_ctrl` 或 `countdown_ctrl`。回复方向上，`protocol_builder` 将 ACK、NACK、TIME、ALARM、SCHED、COUNT_STATUS、MSG_STORED 或 REPLY 构造成 UART 字节序列，再由 `uart_tx` 发回 PC。

提醒控制流由 `notification_ctrl` 汇总。倒计时到零、闹钟到点、日程到点都会产生事件，但这些事件不直接驱动蜂鸣器。统一提醒模块负责选择当前提醒类型、输出提醒槽位、控制蜂鸣器、要求 OLED 弹窗覆盖，并在提醒激活时让 `ui_ctrl` 锁定普通交互。这样可以避免多个功能在同一时间争用反馈资源。

## 3.4 系统框图

```text
Nexys A7-100T / XC7A100T
|
+-- 输入交互层
|   +-- CPU_RESETN
|   +-- BTNL / BTNR / BTNU / BTND / BTNC
|   +-- SW[15:0]
|
+-- 时钟与同步层
|   +-- CLK100MHZ 100MHz
|   +-- tick_1k
|   +-- 1Hz 走时使能
|
+-- 核心功能层
|   +-- ui_ctrl 七模式状态机
|   +-- time_core / date_core
|   +-- alarm_ctrl / countdown_ctrl / schedule_ctrl
|   +-- notification_ctrl
|   +-- comm_ctrl
|
+-- 显示反馈层
|   +-- display_ctrl -> nexys_seg_scan -> 八位七段数码管
|   +-- oled_ui_display -> SSD1306 OLED
|   +-- LED[7:0] 槽位状态
|   +-- BUZZER_IO 有源蜂鸣器
|
+-- PC 通信层
    +-- UART_RXD / UART_TXD 115200 8N1
    +-- protocol_parser / protocol_builder
    +-- ClockLink Studio GUI / CLI / mock / serial
```

【图 3-1 系统整体架构图：此处插入 FPGA 输入层、时钟与同步层、核心功能层、显示反馈层、PC 通信层的结构图】

# 4. 基础电子钟功能

## 4.1 时/分/秒显示

基础电子钟最重要的体验是打开板子后能看到稳定、连续、可读的时间显示。ClockLink 在 `CLOCK` 模式下显示当前 `HH:MM:SS`，内部时间使用 BCD 形式保存，数码管作为主显示区域。用户不需要先连接 PC，也不需要打开软件，复位后即可看到板上电子钟独立运行。

八位数码管的显示结构不是简单把 6 个数字直接接到七段管上。项目把显示路径拆成三层：功能模块输出时间、模式和状态；`display_ctrl` 根据当前模式生成 8 个 6-bit 字符码；`nexys_seg_scan` 以动态扫描方式轮流选通八个数码管，再由 `seg_7` 把字符码翻译为七段码。这样的设计便于不同模式复用同一套显示硬件。

## 4.2 100MHz 时钟分频与 1Hz 走时

Nexys A7 的输入时钟是 100 MHz，而电子钟的秒级走时需要 1 Hz 的可见节奏。项目没有在内部随意生成多个派生时钟，而是以 `CLK100MHZ` 为唯一主时钟，在顶层生成 `tick_1k`，再用走时使能驱动秒、分、小时计数。所有功能模块仍工作在同一个 100 MHz 同步时钟域内，只在需要低速更新时响应使能信号。

这种做法体现了 FPGA 同步时序设计的基本原则。多个真实时钟域会引入跨时钟域同步问题，也会增加时序分析复杂度；而统一主时钟加时钟使能的方式更适合课程项目和中等规模 FPGA 设计。它既能让秒级逻辑按人的时间尺度更新，也能让 Vivado 以清晰的 10ns 周期约束分析整套设计。

## 4.3 复位功能

`CPU_RESETN` 是低有效复位，XDC 中约束到 Nexys A7 的 `C12` 引脚。复位不仅是把显示清零，更是保证产品可恢复性的入口。无论系统当前处于哪个模式、是否正在提醒、是否正在通信，用户都可以通过复位让系统回到确定状态，便于课堂演示和异常恢复。

项目中需要注意复位极性。`clock` 主线模块接收低有效 `CPU_RESETN` 语义，而 OLED、ADT7420 等部分模块使用高有效复位输入时由顶层传入 `~CPU_RESETN`。这类处理虽然增加了一点连线复杂度，但在顶层集中完成，避免各功能模块对板级复位按钮做重复解释。

## 4.4 校时功能

ClockLink 把校时纳入统一交互体系。非 COMM 模式下，`SW0=0` 表示浏览层，用户主要查看当前状态并用左右键切换模式；`SW0=1` 表示设置层，用户用左右键切换字段，用上下键调整字段数值。`TIME` 模式下字段顺序为小时、分钟、秒，设置层使用内部 24 小时制编辑，退出设置层后时间继续正常递增。

这种“浏览层/设置层”设计可以减少误触。平时用户只浏览时间和模式，不会因为按了上下键而修改核心数据；真正需要校时时，先拨动 `SW0` 明确进入设置层。相同的交互规则也被闹钟、倒计时、日程和 12/24 小时制复用，降低了用户学习成本。

## 4.5 数码管动态扫描显示

Nexys A7 的八位七段数码管为共阳极结构，位选和段选均为低有效。由于八位数码管共享段线，系统必须高速轮流选通每一位，让人眼看到稳定的整体显示。`nexys_seg_scan.v` 中设置扫描分频，并用寄存化输出驱动 `AN[7:0]`、`CA..CG` 和 `DP`。

动态扫描是本项目中非常典型的数字电路知识点。它把“同时显示多个数字”的视觉效果转化为“高速分时复用”的硬件实现，既节省 IO 资源，又能保持显示稳定。项目后期还将数码管扫描输出寄存化，减少扫描译码后的直接组合输出路径，有助于最终实现时序收敛。

# 5. 统一交互设计

## 5.1 七模式状态机

ClockLink 当前有七个工作模式，顺序为：

```text
CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM -> CLOCK
```

表 5-1 给出每个模式的产品含义。

| 模式 | 产品含义 | 用户看到/操作的重点 |
| --- | --- | --- |
| `CLOCK` | 主时钟和日期入口 | 当前时间，设置层可调整月、日、星期 |
| `TIME` | 校时模式 | 编辑小时、分钟、秒 |
| `ALARM` | 闹钟模式 | 管理 8 个闹钟槽位、开关、触发提醒和贪睡 |
| `HOUR` | 显示格式模式 | 切换 12/24 小时制显示 |
| `COUNT` | 倒计时模式 | 设置 `HH:MM:SS`，启动、停止和到零提醒 |
| `SCHED` | 日程/课程提醒模式 | 管理 8 个固定计划点和槽位开关 |
| `COMM` | PC 通信模式 | ClockLink 连接状态、消息查看、滚动和预设回复 |

七模式状态机的价值在于清晰边界。每个模式都有自己的用户目标，但按键规则和显示出口仍然统一。老师验收时可以从 `CLOCK` 开始，按 `BTNR` 依次进入所有功能，再按回 `CLOCK`，直观看到系统不是临时拼接，而是有完整导航结构。

## 5.2 浏览层与设置层

系统使用 `SW0` 区分浏览层和设置层。`SW0=0` 时，左右键用于模式切换；`COUNT` 模式下上键启动或继续倒计时，下键停止倒计时；普通模式下上下键不会修改核心数据。`SW0=1` 时，系统进入当前模式的设置层，左右键切字段或槽位，上下键增减数值，中心键执行开关切换或上下文确认。

COMM 模式是特例。因为 COMM 模式需要 `SW0-SW15` 选择最近 16 条消息，所以 `SW0` 在 COMM 中不再解释为设置层开关。多个开关同时打开时，系统选择最低位；`SW0` 表示最新消息，`SW1` 表示上一条消息，以此类推。这一规则避免了 SCHED 模式和 COMM 模式同时解释拨码开关造成冲突。

## 5.3 按键与拨码开关规则

统一按键规则可以归纳为四类动作：模式切换、字段切换、数值增减和上下文确认。`BTNL/BTNR` 在浏览层切模式，在设置层切字段；`BTNU/BTND` 在设置层修改数值，在 COUNT 浏览层控制运行；`BTNC` 用于确认、开关切换、提醒消音或 COMM 回复模式切换。物理按键信号先经过同步、消抖和单周期脉冲生成，避免一次按下被识别为多次操作。

拨码开关承担“状态选择”职责。非 COMM 模式下，`SW0` 是设置层开关；ALARM 和 SCHED 使用低位 LED/开关表达槽位状态；COMM 模式下 `SW0-SW15` 则变成消息槽选择。项目在 `clock.v` 中将 `schedule_slot_switches` 限定为 `mode_schedule ? sw[7:0] : 8'd0`，避免用户在 COMM 中查看消息时意外改变 SCHED 槽位。

## 5.4 提醒激活时的交互锁定

当倒计时、闹钟或日程提醒触发时，系统会进入提醒激活状态。此时普通模式切换和设置操作被锁定，`BTNC` 优先作为提醒确认或消音，闹钟提醒下方向键可提交贪睡请求。OLED 普通页面也会被提醒弹窗覆盖，蜂鸣器由统一提醒模块驱动。

这种锁定逻辑非常接近真实产品体验。提醒发生时，用户最关心的是“发生了什么”和“如何处理”，而不是继续编辑某个字段。如果不锁定 UI，用户可能一边切模式一边修改数值，导致提醒状态和显示状态互相干扰。统一提醒锁定让系统行为更确定，也让课堂演示更稳定。

# 6. 扩展功能设计

## 6.1 12/24 小时制

`HOUR` 模式用于切换全局显示格式。项目内部始终以 24 小时制保存时间，闹钟比较、日程比较和 PC 协议也都按 24 小时制处理；12 小时制只影响外部显示。这样既保证内部逻辑统一，又允许用户选择更符合习惯的显示方式。

这个功能体现了“内部数据”和“外部呈现”的分层思想。如果为了显示 12 小时制而改变内部计时格式，闹钟和日程比较逻辑就会变复杂，还要额外处理上午/下午边界。当前设计把格式转换放在 `hour_format_display.v` 中，让核心时间模块保持简单、稳定。

## 6.2 多槽位闹钟

ClockLink 的闹钟不是单个固定提醒点，而是 8 槽位闹钟系统。每个槽位可以保存独立时间和开关状态，LED0-LED7 用于提示槽位状态和当前选中槽。闹钟到点后产生 pending 事件，由 `notification_ctrl` 接管蜂鸣器和 OLED 弹窗。闹钟提醒还支持确认和贪睡，使它更接近真实电子钟产品。

8 槽位设计适合真实使用场景。例如用户可以设置早起、出门、上课、实验、晚自习和休息等多个提醒点。PC 端也可以通过 `ALARM_SET` 和 `ALARM_GET` 直接读写指定槽位，不需要通过“模拟按键加很多次”的方式同步，符合本项目协议化扩展原则。

## 6.3 倒计时

倒计时让系统从“看时间”扩展到“管理时间”。用户可以在 `COUNT` 模式下设置一个 `HH:MM:SS` 时长，在浏览层用上键启动或继续，用下键停止。倒计时运行到 `00:00:00` 时自动停止并产生到零事件，由统一提醒系统触发蜂鸣器和 OLED 弹窗。

倒计时与普通走时不同。普通时间是按秒递增并处理 59 到 00 的进位，倒计时则按秒递减并处理到零边界。项目把倒计时封装为 `countdown_ctrl.v`，让它独立保存剩余时间和运行状态，同时向 `notification_ctrl` 输出 `countdown_done_pulse`。PC 端可以通过 `COUNT_SET` 加载新倒计时值，通过 `COUNT_START/COUNT_STOP` 直接启动和停止。

## 6.4 日程/课程提醒

`SCHED` 模式面向课程表和固定作息提醒。首版系统提供 8 个计划点，每个计划点有固定编号、时间、类型和开关状态。文档中的默认计划包括 `08:00 CLASS 1`、`09:40 BREAK`、`10:00 CLASS 2`、`11:40 LUNCH`、`14:00 CLASS 3`、`15:40 BREAK`、`19:00 STUDY`、`21:30 REST`。用户可以开启或关闭槽位，到点后系统进入统一提醒。

相比闹钟，日程更强调“固定计划列表”。闹钟适合用户临时设置多个提醒点，日程适合课程表、作息表和实验安排。OLED 可以显示最近一个已开启计划点，让用户不需要进入设置层也能知道下一项安排。

## 6.5 统一提醒系统

倒计时、闹钟和日程都会产生提醒。如果让每个模块直接驱动蜂鸣器和 OLED，就会出现输出争用，也很难处理同一时刻多个事件。ClockLink 设计了 `notification_ctrl` 作为统一提醒仲裁模块，集中接收三类提醒事件，输出当前提醒类型、槽位、蜂鸣器开关、OLED 弹窗和确认/贪睡请求。

统一提醒系统是项目从“功能堆叠”走向“产品架构”的关键。它把提醒反馈从各功能模块中抽出来，使闹钟模块只关心闹钟状态，倒计时模块只关心剩余时间，日程模块只关心计划到点，而最终对用户如何响铃、如何显示、如何确认，由一个中心模块统一处理。

## 6.6 OLED 状态副屏

数码管适合显示大而清晰的主时间，但不适合显示长文本、日期和状态说明。因此项目加入外接 SSD1306 I2C OLED 作为状态副屏。普通页面显示日期/星期、温度、最近日程、最近闹钟、倒计时运行状态和当前模式标签；提醒发生时显示 `COUNT DONE`、`ALARM N` 或 `SCHED N` 弹窗；COMM 模式下切换为通信专用页面，显示 ClockLink 状态、消息时间戳、正文窗口或预设回复列表。

OLED 副屏让系统更像真实产品。用户可以在数码管上快速读取时间，在 OLED 上了解“为什么响铃”“下一项日程是什么”“当前是否有未读消息”。这也让课堂展示更直观：老师不仅能看到时间，还能看到系统状态说明。

【图 6-1 OLED 状态副屏页面：此处插入普通状态页，包含日期、温度、最近日程、最近闹钟和倒计时状态】

## 6.7 温度显示

Nexys A7 板载 ADT7420 温度传感器接口已接入顶层，`TMP_SCL=C14`，`TMP_SDA=C15`。项目提供 `adt7420_reader.v` 读取链路，OLED 可显示温度状态。若温度读取成功，OLED 显示整数摄氏度；读取失败时显示 `--C` 形式的占位。

温度功能在本报告中按“链路已接入、建议补充实拍证据”描述。仓库旧文档曾记录温度读数稳定性未单独确认，虽然当前用户已确认整体上板 OK，但正式验收前仍建议补一张 OLED 温度读数照片，以便把温度功能从“工程接入”升级为“独立截图证据完整”。

# 7. ClockLink Studio 与 COMM 模式

## 7.1 PC 上位机定位

ClockLink Studio 是本项目的 PC 上位机软件。它让 FPGA 电子钟不再只是板上一套独立逻辑，而是可以被电脑端可视化控制的时间管理终端。PC 端支持 mock 模式和真实串口模式，mock 模式便于在没有开发板时测试协议和 UI，真实串口模式通过 Nexys A7 J6 USB-UART 与 FPGA 连接。

软件目录位于 `software/clocklink_studio/`，采用分层结构：`protocol` 负责帧编解码、XOR 校验和命令构造；`transport` 提供 mock 和 serial 两类传输；`services` 封装时间、消息、闹钟、日程、倒计时操作；`ui` 提供 Tkinter GUI；`main.py` 提供 CLI 入口；`desktop.py` 提供 Windows 桌面启动入口。当前 PC 测试 17 项全部通过。

## 7.2 USB-UART 通信链路

通信链路使用 Nexys A7 J6 USB-UART，参数为 `115200 8N1`，无流控，ASCII 编码，行结束为 `\n`。XDC 中 `UART_RXD=C4` 表示 PC 到 FPGA，`UART_TXD=D4` 表示 FPGA 到 PC。协议帧格式为：

```text
#SEQ|CMD|PAYLOAD*CS\n
```

其中 `SEQ|CMD|PAYLOAD` 作为 BODY，`CS` 是 BODY 所有 ASCII 字节逐字节 XOR 的两位十六进制校验。这个帧格式简单、可读、便于串口调试，也足够覆盖时间同步、消息、闹钟、日程和倒计时等命令。

通信数据流如下：

```text
ClockLink Studio GUI/CLI
    -> USB-UART 115200 8N1
    -> uart_rx
    -> protocol_parser
    -> comm_ctrl
    -> time_core / date_core / alarm_ctrl / schedule_ctrl / countdown_ctrl / message_store
    -> protocol_builder
    -> uart_tx
    -> ClockLink Studio 日志与聊天窗口
```

【图 7-1 USB-UART 通信链路图：此处插入 PC、USB-UART、UART RX/TX、协议解析/构帧、核心功能模块之间的数据流示意图】

## 7.3 消息收发与预设回复

PC 可以通过 `MSG_TX` 向 FPGA 发送消息。第一版消息正文限制为 100 个 ASCII 可打印字符，正文在 payload 中使用 HEX 编码，避免分号、等号等字符破坏 key-value 结构。FPGA 收到合法消息后写入 `message_store`，最新消息进入 slot0，旧消息向高 slot 推进，最多保存最近 16 条。

COMM 模式下，数码管左四位显示近似 `COMM`，右四位显示 `DISC / WAIT / CONN / MSG! / ERR`。当有未读消息时显示 `MSG!`。用户可以用 `SW0-SW15` 选择消息槽，`SW0` 为最新消息，多个开关同时打开时选择最低位。OLED 显示消息日期、时间和 4 行正文窗口，长消息用 `BTNU/BTND` 滚动。

查看有效消息时，用户按 `BTNC` 进入回复模式，再用 `BTNU/BTND` 在 8 条预设回复中选择，按 `BTNR` 发送 `REPLY` 帧给 PC。预设回复包括 `OK, received.`、`Busy now.`、`Will check later.`、`Please sync time.`、`System normal.`、`Alarm noted.`、`Schedule noted.`、`Need help.`。这种交互让 FPGA 板子不仅能接收 PC 消息，也能主动表达状态。

【图 7-2 ClockLink Studio 消息收发界面：此处插入 PC 端发送 `Hello FPGA`、FPGA 端 COMM 模式显示 `MSG!`、OLED 显示消息正文的截图】

## 7.4 PC 端时间同步

PC 时间同步通过 `TIME_SET` 实现，payload 固定为 `date=YYYY-MM-DD;time=HH:MM:SS;weekday=N`。FPGA 端解析成功后直接向 `time_core` 和 `date_core` 输出一拍加载脉冲，更新当前日期和时间。这个设计遵循项目规则：PC 同步时间不能通过模拟按键反复加减实现，必须新增直接写入接口。

`TIME_GET` 可以读取 FPGA 当前日期和时间，返回 `TIME date=...;time=...;weekday=...`。第一版软日期不自动处理跨年，闰年也不是当前目标；PC 可以通过再次 `TIME_SET` 重新同步年份和日期。报告中如实说明这一边界，体现工程设计对版本范围的控制。

## 7.5 PC 端闹钟/日程/倒计时控制

ClockLink Studio 可以直接控制闹钟、日程和倒计时。`ALARM_SET` 写入指定闹钟槽，`ALARM_GET` 读取指定闹钟槽；`SCHED_SET` 写入指定日程槽，`SCHED_GET` 读取指定日程槽；`COUNT_SET` 加载倒计时初值，`COUNT_START` 启动或继续，`COUNT_STOP` 停止，`COUNT_STATUS` 读取剩余时间和运行状态。

这些命令的意义不只是“PC 能改板子状态”，更重要的是它们保持了硬件结构清晰。PC 写入脉冲优先级高于同周期手动编辑，并清除对应槽位 pending/match 状态；`COUNT_SET` 加载新值后停止倒计时，如果 PC 希望立即运行，需要随后发送 `COUNT_START`。这样的语义避免了隐含副作用。

需要说明的是，协议中保留了 `ALARM_DUMP/SCHED_DUMP`，但当前 FPGA 第一版没有实现一次性宽帧 dump。PC 如需读取全部槽位，应循环发送 `ALARM_GET slot=0..7` 或 `SCHED_GET slot=0..7`。这属于资源和时序收敛后的工程取舍。

## 7.6 GUI 与 CLI 演示

ClockLink Studio GUI 使用 Tkinter，不引入大型 GUI 依赖。界面默认中文，支持中英文切换。主要页面包括连接与消息、功能控制和底部通信日志。连接与消息页提供 HELLO、PING、STATUS、同步时间、读取时间、发送消息等操作，并用聊天气泡展示 PC 与 FPGA/mock 的消息交互。功能控制页提供闹钟槽读写、日程槽读写、倒计时设置、启动、停止和状态查询。

CLI 适合快速演示和调试，例如：

```bash
python main.py --mock ping
python main.py --mock sync-time
python main.py --mock send-message "Hello FPGA"
python main.py --mock alarm-set --slot 0 --time 07:30:00 --enable 1
python main.py --mock sched-set --slot 0 --time 08:00:00 --type 0 --enable 1
python main.py --mock count-set --time 00:05:00
python main.py --port COM5 gui
```

【图 7-3 ClockLink Studio GUI 主界面：此处插入连接与消息页截图，展示 HELLO/PING/SYNC/GET、聊天气泡和通信日志】

# 8. 技术实现与课程知识体现

## 8.1 同步时序与时钟使能

本项目始终围绕 100 MHz 单主时钟域组织。`CLK100MHZ` 经过顶层 BUFG 后驱动主要寄存器，低速行为通过 `tick_1k` 和走时使能实现。这样可以避免大量内部派生时钟导致的时序约束困难和跨时钟域问题。

从课程知识角度看，这对应同步时序电路、计数器分频、时钟使能和静态时序分析。最终 routed report 中 `sys_clk` 的周期约束为 10ns，`WNS=+0.325ns` 表示最差建立时间路径仍有正裕量；`TNS=0.000ns` 表示不存在累积建立时间违例。这说明系统在 100 MHz 目标下完成了实现级时序收敛。

## 8.2 状态机设计

项目中有多类状态机。`ui_ctrl` 管理七模式状态、设置层和字段索引；`protocol_parser` 解析 UART 帧，经历等待帧头、接收 BODY、校验、派发等状态；`protocol_builder` 按响应类型分阶段构造回复帧；`oled_ui_display` 包含 OLED 初始化和分页刷新状态机；`adt7420_reader` 使用 I2C 读温度状态机。

状态机设计让复杂流程变得可控。以 COMM 为例，如果没有状态机，UART 字节流、校验、命令识别、消息写入和回复构造会混在大量组合逻辑中。当前工程把接收、解析、执行、响应分开，使每一步都有明确时序边界，也便于 testbench 覆盖。

## 8.3 按键消抖与脉冲生成

真实按键不是理想数字信号，按下和释放时可能产生抖动。如果直接把按键电平接入状态机，系统可能把一次按下识别为多次操作。`button_pulse.v` 负责按键同步、消抖和单周期脉冲输出，把物理输入转换为可靠事件。

这部分对应课程中的同步输入处理和边沿检测。消抖后的脉冲再由 `ui_ctrl` 根据当前模式解释。例如同样一个 `BTNR` 脉冲，在浏览层可能表示下一模式，在设置层可能表示下一字段，在 COMM 回复模式下则可能发送预设回复并锁定导航。可靠的输入事件是复杂交互可用的基础。

## 8.4 动态扫描显示

七段数码管动态扫描体现了分时复用思想。系统在快速周期内轮流驱动 `AN0` 到 `AN7`，同时输出对应段码。由于人眼暂留，每一位看起来像是同时点亮。项目中 `display_ctrl` 只关心“这一位应该显示什么字符”，`nexys_seg_scan` 只关心“什么时候点亮哪一位”，`seg_7` 只关心“字符如何映射成段码”。

这种分层让后续扩展更容易。新增 COMM 模式时，只需要在 `display_ctrl` 中增加 `COMM` 和状态文本，在 `seg_7` 中补充 `M/I/G/W/!` 等近似字符，不需要重写扫描驱动。后期将输出寄存化也能局部完成，不影响上层功能模块。

## 8.5 UART / I2C 外设接口

本项目同时使用了 UART 和 I2C 两类串行接口。UART 用于 PC 和 FPGA 的点对点通信，参数固定为 `115200 8N1`，上层协议使用 ASCII 帧和 XOR 校验。I2C 用于 OLED 和 ADT7420。OLED 是外接 SSD1306 IIC 模块，ADT7420 是板载温度传感器，二者使用不同的引脚组，避免总线冲突。

UART 部分体现串行通信、波特率分频、帧格式、校验和协议状态机；I2C 部分体现开漏信号、SCL/SDA 时序和外设初始化。它们让电子钟从单纯的内部逻辑扩展到真实外设系统。

## 8.6 模块化工程组织

ClockLink 的功能规模已经超过一个简单实验文件。如果把所有逻辑写在一个 `always` 块中，维护和验证都会非常困难。项目采用模块化组织：顶层只负责板级接线，`clock.v` 负责主线集成，各功能模块各自保存状态，显示模块统一输出，通信模块通过协议接口直接写入核心状态。

这种组织方式也方便分阶段开发。COMM 模式从协议冻结、PC mock、UART RX/TX、COMM 骨架、消息缓存、预设回复、时间同步、闹钟/日程/倒计时控制逐步推进，每个阶段都有对应仿真、pytest 或综合检查。模块化让功能扩展可以被拆成可验证的小步。

# 9. 工程优化与质量保障

## 9.1 时序优化思路

随着 OLED、COMM、消息缓存、预设回复、PC 直接控制等功能加入，组合逻辑路径明显变长。项目在工作日志中记录过多次时序压力和收敛过程，例如宽消息返回帧、OLED 页面组合渲染、协议构帧宽 mux 等路径都曾成为风险点。最终工程通过多种方式降低时序压力。

主要优化思路包括：保持单主时钟域；使用时钟使能而不是生成多个内部时钟；消息缓存从全量移动改为环形 slot 指针；只输出当前消息窗口而不是跨模块输出完整 16 条长消息；OLED 页面渲染增加流水步骤；`protocol_builder` 按响应类型拆分构帧状态；最近闹钟/最近计划选择采用分时扫描并寄存输出；数码管扫描和显示输出寄存化。这些优化都没有改变产品功能，但显著降低了组合路径复杂度。

## 9.2 WNS / TNS 结果

当前最终采用 Vivado `impl_1` routed timing report 中的数据，而不是旧 README 中的综合阶段数据。报告信息如下：

| 指标 | 当前结果 | 含义 |
| --- | ---: | --- |
| Design State | Routed | 设计已完成布局布线 |
| WNS | `+0.325ns` | 最差建立时间路径仍有 0.325ns 正裕量 |
| TNS | `0.000ns` | 无建立时间违例累积负裕量 |
| TNS Failing Endpoints | `0` | 无建立时间失败端点 |
| WHS | `+0.024ns` | 最差保持时间路径仍有正裕量 |
| THS | `0.000ns` | 无保持时间违例累积负裕量 |
| 结论 | All user specified timing constraints are met | 所有用户指定时序约束满足 |

`WNS` 为正、`TNS` 为 0 的意义是：在当前 100 MHz 时钟约束和实现结果下，Vivado 没有发现建立时间违例。对于课堂 FPGA 项目而言，这说明功能扩展后并未牺牲工程可实现性。需要注意的是，时序通过不等于所有外部 IO 时序都做了完整板级接口建模，timing methodology 中仍有部分 input/output delay 缺失 warning，这属于后续工程规范化空间。

## 9.3 XDC 约束与板级适配

XDC 是 Verilog 逻辑和真实硬件之间的桥梁。没有 XDC，`BTNR` 只是一个端口名，Vivado 不知道它对应 Nexys A7 的哪个管脚；没有时钟约束，Vivado 也无法按 100 MHz 目标进行静态时序分析。本项目的 `clock_amd.xdc` 明确约束了 `CLK100MHZ`、`CPU_RESETN`、按键、拨码开关、数码管、LED、蜂鸣器、OLED、ADT7420 和 USB-UART。

表 9-1 列出关键板级约束。

| 资源 | 约束摘录 | 说明 |
| --- | --- | --- |
| 主时钟 | `create_clock -period 10.000 -name sys_clk [get_ports CLK100MHZ]` | 100 MHz 时钟约束 |
| 复位 | `CPU_RESETN=C12` | 低有效复位 |
| USB-UART | `UART_RXD=C4`、`UART_TXD=D4` | Nexys A7 J6 USB-UART |
| OLED | `OLED_SCL=D14`、`OLED_SDA=F16` | 外接 SSD1306 I2C |
| ADT7420 | `TMP_SCL=C14`、`TMP_SDA=C15` | 板载温度传感器 |
| 蜂鸣器 | `BUZZER_IO=C17` | 外置低电平触发有源蜂鸣器 |

当前 routed DRC 报告没有错误，但存在若干 warning，包括 CFGBVS/CONFIG_VOLTAGE 未设置、RAMB18 async control check、IO port buffering incomplete 等。它们没有阻止实现和 bitstream 生成，但应作为后续工程规范化优化项记录。

## 9.4 仿真、综合与软件测试

ClockLink 的验证不是只依赖“上板看起来能跑”。项目建立了多层验证体系：

| 验证层次 | 验证内容 | 当前结果 | 作用 |
| --- | --- | --- | --- |
| HDL 语法/展开 | 全源 `xvlog`、顶层 `xelab` | 工作日志记录通过 | 确认源文件和顶层连接可编译 |
| UART 单元仿真 | `tb_uart_rx`、`tb_uart_tx` | PASS 记录 | 验证 8N1 字节收发 |
| COMM 消息仿真 | `tb_comm_ctrl_msg`、`tb_message_store` | PASS 记录 | 验证 `MSG_TX`、消息缓存和 OLED 窗口 |
| COMM 回复仿真 | `tb_comm_ctrl_reply` | PASS 记录 | 验证 `REPLY` 主动帧 |
| 时间同步仿真 | `tb_comm_ctrl_time` | PASS 记录 | 验证 `TIME_SET/TIME_GET` |
| PC 控制仿真 | `tb_comm_ctrl_control` | PASS 记录 | 验证闹钟/日程/倒计时直接控制 |
| PC 软件测试 | `python -m pytest` | 本次实跑 17 passed | 验证协议库、mock、serial transport 和服务层 |
| Vivado 实现 | `impl_1` routed report | WNS/TNS 均满足 | 验证布局布线后时序 |
| bitstream | `clock_amd_top.bit` 生成 | Bitgen Completed Successfully | 支持下载上板 |
| 板级验证 | 用户确认 Nexys A7 上板 OK | 当前验收准备状态 | 确认真实硬件行为 |

## 9.5 当前验证边界

本报告尽量把“已实现”“已仿真”“已实现时序通过”“已上板确认”和“建议补充截图”区分清楚。当前可以写入正式报告的结论包括：七模式主线集成、基础电子钟功能、闹钟/倒计时/日程、统一提醒、OLED 页面、USB-UART COMM、PC 时间同步和 PC 直接控制已经在工程中实现；PC 软件测试 17 项通过；Vivado routed timing 满足约束；bitstream 已生成；用户已确认上板验证 OK。

仍建议验收前补充的证据包括：板上实物图、OLED 普通状态页和 COMM 消息页照片、ClockLink Studio 真实串口 GUI 截图、Vivado timing summary 截图、pytest 17 passed 截图、ADT7420 温度读数照片。`MSG_GET/MSG_DATA` 和 `ALARM_DUMP/SCHED_DUMP` 属于协议预留或资源折中项，不应写成 FPGA 已完整实现。真实串口长期稳定性和压力测试可以作为后续迭代，而不是当前课堂验收必须项。

# 10. 现场演示流程

## 10.1 演示准备

现场演示前建议完成以下准备：

| 步骤 | 操作 | 预期结果 |
| --- | --- | --- |
| 1 | 打开 Vivado 工程 `clock_amd.xpr` | 顶层为 `clock_amd_top.v` |
| 2 | 确认约束文件 `clock_amd.xdc` | `CLK100MHZ`、UART、OLED、蜂鸣器等约束存在 |
| 3 | 使用已生成 bitstream 或重新 Generate Bitstream | `clock_amd_top.bit` 可下载 |
| 4 | 连接 Nexys A7、OLED、蜂鸣器和 USB-UART | 外设供电和线序正确 |
| 5 | 打开 ClockLink Studio | mock 或真实串口模式可启动 |
| 6 | 准备截图材料 | Vivado timing、pytest、GUI、OLED、板卡实物 |

## 10.2 基础功能演示

基础功能演示建议先完成，确保老师一眼看到课程要求已经覆盖。

1. 按下 `CPU_RESETN` 复位，观察系统回到初始状态。
2. 进入 `CLOCK` 模式，观察八位数码管显示 `HH:MM:SS`，秒位按 1 秒节奏递增。
3. 按 `BTNR` 切换到 `TIME` 模式。
4. 拨 `SW0=1` 进入设置层，使用 `BTNL/BTNR` 选择小时、分钟、秒字段。
5. 使用 `BTNU/BTND` 修改数值，观察选中字段闪烁和数值变化。
6. 拨回 `SW0=0`，确认修改后的时间继续正常走时。

## 10.3 扩展功能演示

扩展功能展示 ClockLink 从基础电子钟升级为时间管理终端的过程。

| 演示项 | 操作 | 预期现象 |
| --- | --- | --- |
| 12/24 小时制 | 切到 `HOUR` 模式并在设置层切换 | 显示格式变化，内部计时不受影响 |
| 多槽位闹钟 | 切到 `ALARM`，选择槽位，设置接近当前时间并开启 | LED 指示槽位，到点后蜂鸣/OLED 弹窗 |
| 闹钟贪睡/确认 | 闹钟响起后用方向键提交贪睡或 `BTNC` 消音 | 提醒状态被统一处理 |
| 倒计时 | 切到 `COUNT`，设置 `00:00:10`，启动、停止、继续 | 到零后进入统一提醒 |
| 日程提醒 | 切到 `SCHED`，开启某个固定计划点 | OLED 显示最近计划，到点后提醒 |
| OLED 副屏 | 切换不同模式 | OLED 显示日期、温度、最近提醒、模式状态 |

## 10.4 ClockLink Studio 演示

ClockLink Studio 演示建议按通信链路由浅入深进行。

1. 打开 GUI，选择真实串口，例如 `COM5`。
2. 点击 `HELLO` 建立会话，观察日志中的 `ACK`。
3. 点击 `PING`，观察 PC 收到 `PONG`。
4. 点击 `SYNC`，将 PC 时间同步到 FPGA。
5. 点击 `GET`，读取 FPGA 当前时间并展示 `TIME` 返回帧。
6. 在消息框发送 `Hello FPGA`，PC 收到 `MSG_STORED`。
7. 板上切换到 COMM 模式，数码管右侧显示 `MSG!`。
8. 打开 `SW0` 查看最新消息，OLED 显示时间戳和正文。
9. 用 `BTNU/BTND` 滚动长消息。
10. 按 `BTNC` 进入回复选择，用 `BTNU/BTND` 选择预设回复，按 `BTNR` 发送。
11. PC GUI 聊天窗口和日志显示 FPGA 主动 `REPLY`。
12. 在 Control 页设置闹钟、日程和倒计时，再回到板上确认对应功能状态更新。

【图 10-1 ClockLink Studio 真实串口演示截图：此处插入 HELLO/PING/SYNC/MSG_TX/REPLY 的完整日志或聊天窗口截图】

## 10.5 异常情况与备用演示方案

如果现场串口端口号不确定，先在 Windows 设备管理器确认 Nexys A7 USB-UART 对应 COM 号，再在 GUI 或 CLI 中替换 `COM5`。如果真实串口暂时无法连接，可以先用 mock 模式展示 PC 软件和协议流程，再切回板上独立展示基础电子钟、闹钟、倒计时、日程和 OLED。

如果 OLED 图片拍摄不清晰，可以用数码管、LED、蜂鸣器和 PC 日志作为主要证据，并在报告中保留 OLED 页面图占位。若温度读数暂时不稳定，不影响基础电子钟和 ClockLink 主线验收，可如实说明温度链路已接入，后续补充传感器稳定性测试。

# 11. 当前不足与后续迭代

## 11.1 已知限制

表 11-1 汇总当前完成度和边界。

| 项目 | 当前状态 | 报告写法 |
| --- | --- | --- |
| 基础电子钟 | 已实现，用户确认上板 OK | 可写“完成并通过板级验证” |
| 七模式 UI | 已实现，用户确认上板 OK | 可写“统一七模式交互已接入” |
| 闹钟/倒计时/日程 | 已实现，用户确认上板 OK | 可写“核心提醒功能已完成” |
| OLED 状态副屏 | 已实现，用户确认上板 OK，截图待补 | 可写“已接入并建议补图” |
| ADT7420 温度 | HDL/XDC 已接入，独立温度截图待补 | 写“温度链路已接入，稳定性截图建议补充” |
| USB-UART/COMM | 已实现，用户确认上板 OK | 可写“验收前上板验证 OK”，建议补真实串口日志 |
| PC 软件 | mock/serial/CLI/GUI 已实现，pytest 17 passed | 可写“软件测试通过” |
| `MSG_GET/MSG_DATA` | 协议预留，FPGA 当前返回 unsupported | 写“后续流式读回扩展” |
| `ALARM_DUMP/SCHED_DUMP` | 协议预留，当前循环单槽 GET | 写“首版通过单槽 GET 完成读取” |
| 日期闰年/跨年 | 首版限制 | 写“PC 可重新同步，后续完善日历” |
| DRC/methodology warning | 实现无错误，但存在 warning | 写“后续工程规范优化项” |

## 11.2 后续优化方向

后续可以从四个方向继续迭代。第一，完善协议读回能力，将 `MSG_GET/MSG_DATA` 改成流式构帧，避免一次性宽总线路径，同时恢复 PC 读取 FPGA 消息正文的完整能力。第二，完善日历系统，加入年份自动递增、闰年和月份天数完整处理。第三，增加配置保存能力，例如将闹钟、日程和显示格式保存到非易失存储，避免复位后丢失。第四，进一步整理 DRC warning，尤其是 RAMB18 地址控制寄存器复位方式和配置电压属性，使工程更接近规范产品项目。

PC 软件侧可以增加自动串口发现、连接状态图标、历史日志导出、批量读取 8 个闹钟/日程槽位、消息中文编码和更完善的异常提示。板端 UI 可以继续优化 OLED 页面排版，使其从功能演示页面进一步接近真实桌面设备 UI。

## 11.3 产品化展望

如果把 ClockLink 继续产品化，它可以成为一个面向学习桌面的时间管理终端：板上显示当前时间和提醒，PC 端负责更复杂的配置和消息输入，OLED 显示状态摘要，蜂鸣器和 LED 提供即时提醒。未来还可以接入课程表导入、PC 通知转发、会议提醒、番茄钟统计和多语言消息显示。

从课程项目角度看，ClockLink 的价值不在于追求商业产品完整度，而在于把数字电路知识与软硬件系统思维连接起来。它展示了一个 FPGA 项目如何从基础计时逻辑逐步演进为有交互、有外设、有协议、有上位机、有验证闭环的完整系统。

# 12. 项目总结

## 12.1 功能完成情况

本项目完成了数字电子钟基础验收所需的时、分、秒显示，100 MHz 时钟分频，秒级走时，低有效复位，手动校时和数码管动态扫描显示。在此基础上，系统进一步实现 12/24 小时制、8 槽位闹钟、倒计时、8 槽位日程提醒、统一提醒仲裁、OLED 状态副屏、温度读取链路、USB-UART COMM 模式和 PC 上位机 ClockLink Studio。

当前工程已生成 `clock_amd_top.bit`，Vivado routed timing 满足约束，PC 软件 17 项测试通过，用户已确认 Nexys A7 上板验证 OK。报告对仍需补充的截图和长期稳定性测试也进行了明确标注，便于验收前最后整理材料。

## 12.2 课程知识收获

ClockLink 覆盖了数字电路和 FPGA 课程中的多个核心知识点：同步时序设计、计数器分频、时钟使能、BCD 计数、状态机、按键消抖、单脉冲生成、七段数码管动态扫描、UART 串口通信、I2C 外设、XDC 管脚约束、Vivado 综合、布局布线和时序收敛。每个知识点都不是孤立存在，而是服务于一个可操作的系统功能。

例如，动态扫描解决数码管显示，状态机解决七模式交互，按键消抖保证用户操作可靠，UART 协议连接 PC 与 FPGA，XDC 让逻辑端口落到真实开发板，WNS/TNS 让设计是否能在 100 MHz 下运行有了定量依据。这些内容共同构成了从课堂理论到板级工程的完整链条。

## 12.3 工程实践收获

本项目也体现了工程实践中的取舍。为了让消息缓存和协议构帧通过时序，项目没有盲目实现所有宽帧读回，而是先保证消息接收、板端显示和预设回复闭环；为了避免复杂交互混乱，项目引入统一 UI 和统一提醒仲裁；为了降低验证风险，PC 软件先支持 mock 模式，再接真实串口；为了保证报告可信，功能完成度、时序指标、上板状态和待补证据被分开说明。

最终，ClockLink 从一个电子钟实验演进为一个软硬件联动的智能时间管理终端。它能完成课程基础要求，也展示了 FPGA 项目在功能扩展、模块化设计、外设接口、协议通信和工程验证方面的综合能力。

# 附录 A. 核心模块列表

| 类别 | 模块 | 说明 |
| --- | --- | --- |
| 顶层 | `clock_amd_top` | 板级端口、tick_1k、外设实例化 |
| 主线 | `clock` | 功能集成和模块连线 |
| UI | `ui_ctrl`、`button_pulse` | 模式、设置层、按键事件 |
| 时间 | `time_core`、`date_core`、`clk_ring` | 时间、日期和走时 |
| 显示 | `display_ctrl`、`nexys_seg_scan`、`seg_7` | 数码管显示 |
| 扩展功能 | `alarm_ctrl`、`countdown_ctrl`、`schedule_ctrl` | 闹钟、倒计时、日程 |
| 提醒 | `notification_ctrl` | 蜂鸣器和 OLED 弹窗仲裁 |
| OLED/温度 | `oled_ui_display`、`i2c_master_simple`、`adt7420_reader` | 状态副屏和温度链路 |
| 通信 | `uart_rx`、`uart_tx`、`protocol_parser`、`protocol_builder`、`comm_ctrl` | USB-UART 和协议控制 |
| 消息 | `message_store`、`preset_reply_rom` | 16 条消息缓存和 8 条预设回复 |

# 附录 B. 主要引脚与外设连接

| 外设 | 端口 | 引脚 | 备注 |
| --- | --- | --- | --- |
| 时钟 | `CLK100MHZ` | E3 | 100 MHz，10ns 约束 |
| 复位 | `CPU_RESETN` | C12 | 低有效 |
| USB-UART RX | `UART_RXD` | C4 | PC 到 FPGA |
| USB-UART TX | `UART_TXD` | D4 | FPGA 到 PC |
| OLED SCL | `OLED_SCL` | D14 | 外接 SSD1306 |
| OLED SDA | `OLED_SDA` | F16 | 外接 SSD1306 |
| ADT7420 SCL | `TMP_SCL` | C14 | 板载温度传感器 |
| ADT7420 SDA | `TMP_SDA` | C15 | 板载温度传感器 |
| 蜂鸣器 | `BUZZER_IO` | C17 | 外置低电平触发有源蜂鸣器 |

# 附录 C. Vivado 综合/实现报告截图

【图 C-1 Vivado Timing Summary 截图：此处插入 `clock_amd_top_timing_summary_routed.rpt` 或 Vivado GUI Timing Summary，重点标出 `WNS=+0.325ns`、`TNS=0.000ns`、失败端点 0】

【图 C-2 Vivado Utilization 截图：此处插入 `clock_amd_top_utilization_placed.rpt` 或 GUI Utilization，重点标出 LUT 8184、寄存器 8161、RAMB18 1、DSP 0、IOB 62】

【图 C-3 Bitstream 生成截图：此处插入 `runme.log` 中 Bitgen Completed Successfully 或 Vivado Generate Bitstream 成功界面】

# 附录 D. XSim / pytest 测试截图

【图 D-1 PC pytest 截图：此处插入 `software/clocklink_studio` 下 `python -m pytest` 输出，显示 17 passed】

【图 D-2 COMM XSim 回归截图：此处插入 `tb_comm_ctrl_msg`、`tb_comm_ctrl_reply`、`tb_comm_ctrl_time`、`tb_comm_ctrl_control` PASS 日志】

【图 D-3 OLED 字库/消息缓存测试截图：此处插入 `tb_message_store` 和 `tb_oled_glyph` PASS 日志】

# 附录 E. 演示操作速查表

| 目标 | 操作 |
| --- | --- |
| 切换模式 | 浏览层 `BTNL/BTNR` |
| 进入设置层 | 非 COMM 模式拨 `SW0=1` |
| 切换字段 | 设置层 `BTNL/BTNR` |
| 增减数值 | 设置层 `BTNU/BTND` |
| 确认/开关 | `BTNC` |
| 启动倒计时 | COUNT 浏览层 `BTNU` |
| 停止倒计时 | COUNT 浏览层 `BTND` |
| 查看最新消息 | COMM 模式打开 `SW0` |
| 查看上一条消息 | COMM 模式打开 `SW1` |
| 滚动消息 | COMM 模式 `BTNU/BTND` |
| 进入/退出回复模式 | COMM 模式查看有效消息时按 `BTNC` |
| 选择预设回复 | 回复模式 `BTNU/BTND` |
| 发送预设回复 | 回复模式 `BTNR` |
| 提醒消音 | 提醒激活时 `BTNC` |
