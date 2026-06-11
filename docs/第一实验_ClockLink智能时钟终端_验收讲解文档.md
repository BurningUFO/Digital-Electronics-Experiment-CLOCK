# 第一个数电实验验收讲解文档：从基础 Verilog 到 ClockLink 智能时钟终端

> 主题关键词：**练**
> 项目名称：**ClockLink：基于 Nexys A7 的智能桌面时间管理终端**
> 目标板卡：**Nexys A7-100T / XC7A100T-1CSG324C**
> 仓库分支：`Digital-Electronics-Experiment-CLOCK/feature/clocklink-uart-comm`
> 汇报定位：**产品介绍 + 系统设计 + 数电能力沉淀 + 工程验证**

---

## 0. 文档使用说明

这份文档不是传统实验报告，而是面向验收汇报的**讲解稿 + 技术说明 + 代码导览**。它的目标是帮助我把第一个实验讲成一个完整的 FPGA 产品，而不是零散地解释若干 Verilog 文件。

本项目我用一个字概括：**练**。

这个“练”不是简单重复写计数器，而是把之前学过的 Verilog、状态机、分频、按键、开关、数码管动态扫描、BCD 计数、模块化设计、UART 通信和 Vivado 综合检查能力，练成一个更完整、更接近产品的 FPGA 桌面时间管理终端。

验收时建议按下面这条主线讲：

```text
先讲它是什么产品
    ↓
再演示用户怎么操作
    ↓
再讲七个模式如何统一组织
    ↓
再讲关键系统设计：统一 UI、统一显示、统一提醒、PC 通信
    ↓
最后讲工程验证和自己真正练到了什么
```

---

## 1. 项目一句话定位

这个项目最终做成的是一个运行在 Nexys A7-100T 上的 **ClockLink 智能桌面时间管理终端**。

它不是一个只会显示 `HH:MM:SS` 的普通电子钟，而是一个集成了以下能力的硬件产品：

```text
时间显示
日期与星期显示
本地校时
12/24 小时制切换
8 槽位闹钟
8 槽位日程提醒
倒计时
OLED 状态副屏
蜂鸣提醒
LED 槽位状态提示
USB-UART 上位机通信
PC 端 ClockLink Studio 控制
消息接收与预设回复
```

验收开场可以这样说：

> 我的第一个实验是 ClockLink 智能时钟终端，我把它的主题概括为“练”。
> 因为这个项目不是单纯做一个电子钟，而是把数电课里已经学过的计数器、状态机、按键输入、开关输入、数码管扫描、BCD 时间、模块化设计这些基础能力，练成一个完整的 FPGA 时间管理产品。
> 从用户角度看，它可以显示时间、设置闹钟、设置日程、运行倒计时，还可以通过 PC 上位机同步时间、发送消息、控制闹钟/日程/倒计时。
> 从工程角度看，它把 UI、显示、提醒、通信、PC 软件和综合时序检查都组织进了一个统一系统。

---

## 2. 推荐汇报结构

如果只讲第一个实验，建议控制在 **12 到 16 分钟**。如果两个项目一起验收，第一个实验可以压缩到 **7 到 9 分钟**，重点讲产品化和系统组织。

| 汇报部分 | 建议时间 | 核心目的 |
| --- | ---: | --- |
| 项目定位 | 1 分钟 | 说明它不是普通电子钟，而是时间管理终端 |
| 用户演示 | 2 分钟 | 让老师先看到产品可用性 |
| 七模式功能地图 | 1-2 分钟 | 讲清 CLOCK/TIME/ALARM/HOUR/COUNT/SCHED/COMM |
| 统一交互设计 | 2 分钟 | 突出 SW0 浏览/设置双层 UI |
| 系统架构 | 2-3 分钟 | 讲清顶层、主线集成和功能模块分层 |
| 核心亮点 | 3-4 分钟 | 讲提醒仲裁、双显示系统、ClockLink Studio |
| 工程验证 | 1-2 分钟 | 讲仿真、pytest、综合时序 WNS/TNS |
| 学习收获 | 1 分钟 | 回扣“练”这个主题 |

---

## 3. 现场演示顺序设计

现场演示不要一开始就打开代码，而要先让老师从产品视角看到它“能被使用”。建议按下面顺序：

```text
1. 板卡上电，显示 CLOCK 主界面
2. 使用 BTNR / BTNL 切换七个模式
3. SW0=1 进入设置层，演示字段选择和数值修改
4. 设置一个 COUNT 倒计时，启动后等待触发提醒
5. 展示蜂鸣器 / OLED 弹窗 / BTNC 消音
6. 切换 ALARM 或 SCHED，说明 8 槽位和 LED 状态提示
7. 切换 COMM 模式，展示 PC 端 ClockLink Studio 发送消息
8. 板上查看消息、滚动消息、选择预设回复
9. 展示 Vivado 综合检查结果：WNS 为正、TNS 为 0
```

现场可以这样讲：

> 现在板子上运行的是我的 ClockLink 智能时钟终端。
> 首先主界面显示当前时间。通过左右键可以在 CLOCK、TIME、ALARM、HOUR、COUNT、SCHED、COMM 七个模式之间切换。
> `SW0=0` 时是浏览层，主要负责模式切换和普通操作；`SW0=1` 时是设置层，左右键选择字段，上下键修改数值，中键确认。
> 当倒计时、闹钟或日程触发时，系统会进入提醒状态，普通操作被锁定，`BTNC` 优先作为确认和消音键。
> 最后这个项目还接入了 ClockLink Studio，上位机可以通过 USB-UART 同步时间、发送消息、设置闹钟、设置日程和控制倒计时。

---

## 4. 产品功能地图：七个模式讲成一个完整产品

### 4.1 七模式总览

项目主界面由七个模式组成：

```text
CLOCK  →  TIME  →  ALARM  →  HOUR  →  COUNT  →  SCHED  →  COMM
主界面    校时     闹钟      制式      倒计时     日程      PC 通信
```

不要把这七个模式讲成“七段代码”，要讲成一个产品的信息架构。

| 模式 | 用户看到的功能 | 背后的数电能力 |
| --- | --- | --- |
| `CLOCK` | 显示当前时间、日期、星期 | BCD 计数、时钟使能、显示复用 |
| `TIME` | 本地校时，调整时分秒 | 字段选择、加减脉冲、状态机 |
| `ALARM` | 8 槽位闹钟、开关、pending、贪睡 | 多槽寄存器组、时间匹配、事件锁存 |
| `HOUR` | 12/24 小时制切换 | 显示转换与内部计时解耦 |
| `COUNT` | 倒计时编辑、启动、停止、到零提醒 | 向下计数、借位、运行状态控制 |
| `SCHED` | 8 槽位日程提醒、类型、最近日程 | 多事件表、最近事件扫描、类型编码 |
| `COMM` | PC 消息、预设回复、远程控制 | UART、协议解析、消息缓存、PC-FPGA 联动 |

### 4.2 汇报讲法

可以这样讲：

> 这个项目的功能不是堆叠起来的，而是被统一组织成七个模式。
> 用户在板上只需要通过左右键切换模式，再通过 `SW0` 决定是浏览还是设置。
> 对老师来说，我想展示的不只是“这些功能我都写了”，而是这些功能被组织成一个统一的时间管理产品。

---

## 5. 系统总体架构

### 5.1 一张图讲清系统

```text
clock_amd_top.v    Nexys A7 板级顶层
│
├─ 100 MHz 主时钟输入
├─ CPU_RESETN 低有效复位
├─ tick_1k 产生
├─ UART_RXD / UART_TXD
├─ 七段数码管 AN / CA~CG / DP
├─ LED[15:0]
├─ BUZZER_IO
├─ OLED_SCL / OLED_SDA
├─ TMP_SCL / TMP_SDA
│
└─ clock.v         功能主线集成
    │
    ├─ ui_ctrl              统一按键、模式、字段、闪烁
    ├─ comm_ctrl            USB-UART、协议、消息、PC 控制
    ├─ time_core            当前 HH:MM:SS
    ├─ date_core            日期、星期、年份缓存
    ├─ hour_format_ctrl     12/24 小时制设置
    ├─ hour_format_display  24h 到 12h 显示转换
    ├─ alarm_ctrl           8 槽闹钟、pending、贪睡、最近闹钟
    ├─ schedule_ctrl        8 槽日程、类型、pending、最近日程
    ├─ countdown_ctrl       倒计时编辑、运行、到零事件
    ├─ notification_ctrl    三类提醒统一仲裁、蜂鸣器驱动
    └─ display_ctrl         统一生成八位数码管字符码
```

### 5.2 汇报讲法

> 这个项目的架构分成三层。
> 第一层是 `clock_amd_top.v`，它是板级顶层，负责把 Nexys A7 上的真实外设接进来。
> 第二层是 `clock.v`，它是项目主线，负责把 UI、计时、闹钟、日程、倒计时、提醒、通信和显示组织起来。
> 第三层是各个子模块，每个模块只负责一类清晰职责。
> 这种结构让我在功能变多之后仍然能维护项目，而不是把所有逻辑堆在一个顶层 always 块里。

---

## 6. 板级顶层：从 Nexys A7 真实引脚进入系统

### 6.1 讲解重点

板级顶层的作用不是写业务功能，而是完成真实硬件资源和内部逻辑的连接。

项目使用的主要板上资源包括：

```text
CLK100MHZ        100 MHz 主时钟
CPU_RESETN       低有效复位
BTNL/BTNR/BTNU/BTND/BTNC  五个按键
SW[15:0]         拨码开关
AN[7:0] + CA~CG + DP      八位七段数码管
LED[15:0]        槽位状态 / 调试状态
BUZZER_IO        外接低电平触发有源蜂鸣器
UART_RXD/TXD     J6 USB-UART
OLED_SCL/SDA     外接 SSD1306 OLED
TMP_SCL/SDA      板载 ADT7420 温度传感器
```

### 6.2 核心代码摘录：顶层端口和 1ms tick

文件位置：

```text
clock_amd.srcs/sources_1/new/clock_amd_top.v
```

核心代码摘录：

```verilog
module clock_amd_top(
    input        CLK100MHZ,
    input        CPU_RESETN,
    input        BTNL,
    input        BTNR,
    input        BTNU,
    input        BTND,
    input        BTNC,
    input [15:0] SW,
    input        UART_RXD,
    output       UART_TXD,
    output [7:0] AN,
    output       CA, CB, CC, CD, CE, CF, CG, DP,
    output [15:0] LED,
    output       BUZZER_IO,
    inout        OLED_SCL,
    inout        OLED_SDA,
    inout        TMP_SCL,
    inout        TMP_SDA
);

localparam integer TICK_1K_DIV = 17'd100000;
reg [16:0] tick_1k_cnt;
reg        tick_1k;

always @(posedge CLK100MHZ or negedge CPU_RESETN) begin
    if (!CPU_RESETN) begin
        tick_1k_cnt <= 17'd0;
        tick_1k     <= 1'b0;
    end else if (tick_1k_cnt == TICK_1K_DIV - 1'b1) begin
        tick_1k_cnt <= 17'd0;
        tick_1k     <= 1'b1;
    end else begin
        tick_1k_cnt <= tick_1k_cnt + 1'b1;
        tick_1k     <= 1'b0;
    end
end
```

这段代码可以这样讲：

> 板上主时钟是 100 MHz，很多 UI、按键消抖、蜂鸣节奏和 OLED 刷新都不适合直接按 100 MHz 操作。
> 所以顶层先生成 `tick_1k`，也就是 1ms 级别的时钟使能信号。
> 注意这里没有新建一个真正的低频时钟，而是仍然用 `CLK100MHZ` 做同步时钟，用 `tick_1k` 作为 clock enable，这样更符合 FPGA 同步设计习惯。

### 6.3 核心代码摘录：主线模块实例化

文件位置：

```text
clock_amd.srcs/sources_1/new/clock_amd_top.v
```

核心代码摘录：

```verilog
clock u_clock(
    .clk(CLK100MHZ),
    .tick_1k(tick_1k),
    .rst(CPU_RESETN),

    .btn_left(BTNL),
    .btn_right(BTNR),
    .btn_up(BTNU),
    .btn_down(BTND),
    .btn_center(BTNC),
    .sw(SW),

    .uart_rx(UART_RXD),
    .uart_tx(UART_TXD),

    .buzzer_on(buzzer_on),
    .countdown_run(countdown_run),
    .mode_state(mode_state),
    .setting_active(setting_active),

    .comm_status(comm_status),
    .comm_reply_mode(comm_reply_mode),
    .comm_reply_index(comm_reply_index),
    .comm_selected_slot(comm_selected_slot),
    .comm_message_valid(comm_message_valid),
    .comm_scroll_line(comm_scroll_line),
    .comm_timestamp_ascii(comm_timestamp_ascii),
    .comm_message_len(comm_message_len),
    .comm_message_window_ascii(comm_message_window_ascii),

    .digit_code_bus(digit_code_bus),
    .dp_mask(dp_mask),
    .slot_led_mask(slot_led_mask)
);
```

讲解重点：

> `clock_amd_top` 不直接处理业务，只负责把板上的真实端口接入 `clock.v` 主线。
> 这样板级逻辑和功能逻辑分离，后续如果换显示器、换蜂鸣器、换上位机接口，不会影响每个功能模块的内部状态机。

---

## 7. 统一 UI：让七个模式使用同一套操作规则

### 7.1 为什么要设计统一 UI

这个项目有七个模式，如果每个模式都单独设计一套按键规则，用户很难记住，代码也会非常混乱。

所以我设计了统一交互规则：

```text
SW0 = 0：浏览层
    BTNL / BTNR：切换模式
    BTNU / BTND：当前模式上下文操作，例如 COUNT 启动/停止
    BTNC：上下文确认

SW0 = 1：设置层
    BTNL / BTNR：切换字段或槽位
    BTNU / BTND：修改当前字段
    BTNC：确认、开关切换、格式切换

提醒激活时：
    普通切换和设置被锁定
    BTNC 优先作为提醒确认/消音
```

### 7.2 核心代码摘录：模式编码与设置层判定

文件位置：

```text
clock_amd.srcs/sources_1/new/ui_ctrl.v
```

核心代码摘录：

```verilog
localparam MODE_NORMAL      = 3'b000;  // CLOCK
localparam MODE_TIME_SET    = 3'b001;  // TIME
localparam MODE_ALARM       = 3'b010;  // ALARM
localparam MODE_HOUR_FORMAT = 3'b011;  // HOUR
localparam MODE_COUNTDOWN   = 3'b100;  // COUNT
localparam MODE_SCHEDULE    = 3'b101;  // SCHED
localparam MODE_COMM        = 3'b110;  // COMM

assign setting_active = (mode_state == MODE_COMM) ? 1'b0 :
                        (mode_state == MODE_SCHEDULE) ? ((|sw[7:0]) | sw[15]) :
                                                         sw[0];

assign blink_active = interaction_lock |
                      setting_active   |
                      (mode_state == MODE_ALARM) |
                      (mode_state == MODE_SCHEDULE);
```

这段代码可以这样讲：

> 七个模式都用 `mode_state` 管理。
> 大多数模式下，`SW0=1` 代表设置层；但是 COMM 模式要用 `SW0-SW15` 选择消息，所以 COMM 模式强制不是设置层。
> SCHED 模式比较特殊，因为它使用 `SW[7:0]` 选择日程槽位，`SW15` 进入类型页，因此设置层规则也单独处理。

### 7.3 核心代码摘录：模式环形切换

文件位置：

```text
clock_amd.srcs/sources_1/new/ui_ctrl.v
```

核心代码摘录：

```verilog
function [2:0] next_mode;
    input [2:0] mode_in;
    begin
        case (mode_in)
            MODE_NORMAL:      next_mode = MODE_TIME_SET;
            MODE_TIME_SET:    next_mode = MODE_ALARM;
            MODE_ALARM:       next_mode = MODE_HOUR_FORMAT;
            MODE_HOUR_FORMAT: next_mode = MODE_COUNTDOWN;
            MODE_COUNTDOWN:   next_mode = MODE_SCHEDULE;
            MODE_SCHEDULE:    next_mode = MODE_COMM;
            default:          next_mode = MODE_NORMAL;
        endcase
    end
endfunction

function [2:0] prev_mode;
    input [2:0] mode_in;
    begin
        case (mode_in)
            MODE_TIME_SET:    prev_mode = MODE_NORMAL;
            MODE_ALARM:       prev_mode = MODE_TIME_SET;
            MODE_HOUR_FORMAT: prev_mode = MODE_ALARM;
            MODE_COUNTDOWN:   prev_mode = MODE_HOUR_FORMAT;
            MODE_SCHEDULE:    prev_mode = MODE_COUNTDOWN;
            MODE_COMM:        prev_mode = MODE_SCHEDULE;
            default:          prev_mode = MODE_COMM;
        endcase
    end
endfunction
```

讲解重点：

> 这里把七个模式做成环形浏览。
> 用户按右键向后走，按左键向前走，这样所有模式都处在一个一致的导航模型里。

### 7.4 核心代码摘录：浏览层和设置层分流

文件位置：

```text
clock_amd.srcs/sources_1/new/ui_ctrl.v
```

核心代码摘录：

```verilog
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        mode_state      <= MODE_NORMAL;
        field_index     <= 3'd0;
        value_inc_pulse <= 1'b0;
        value_dec_pulse <= 1'b0;
        confirm_pulse   <= 1'b0;
    end else begin
        value_inc_pulse <= 1'b0;
        value_dec_pulse <= 1'b0;
        confirm_pulse   <= 1'b0;

        if (!interaction_lock && btn_center_pulse)
            confirm_pulse <= 1'b1;

        if (interaction_lock) begin
            // 提醒激活时锁住普通 UI 操作
        end else if (setting_active) begin
            if (btn_left_pulse)
                field_index <= (field_index == 3'd0) ? max_field_index(mode_state)
                                                      : field_index - 1'b1;
            else if (btn_right_pulse)
                field_index <= (field_index >= max_field_index(mode_state)) ? 3'd0
                                                                             : field_index + 1'b1;

            if (btn_up_pulse)       value_inc_pulse <= 1'b1;
            else if (btn_down_pulse)value_dec_pulse <= 1'b1;
        end else begin
            field_index <= 3'd0;
            if (!mode_nav_lock && btn_left_pulse)
                mode_state <= prev_mode(mode_state);
            else if (!mode_nav_lock && btn_right_pulse)
                mode_state <= next_mode(mode_state);
            else if (mode_state == MODE_COUNTDOWN) begin
                if (btn_up_pulse)        value_inc_pulse <= 1'b1;
                else if (btn_down_pulse) value_dec_pulse <= 1'b1;
            end
        end
    end
end
```

讲解话术：

> 这里体现了我对“产品交互”的练习。
> UI 不是每个模块各管各的，而是先由 `ui_ctrl` 把按键变成统一的模式、字段、增减和确认脉冲。
> 后面的时间、闹钟、日程、倒计时模块只需要消费这些脉冲，不需要自己关心按键消抖和模式切换。

---

## 8. 时间核心：用 BCD 计数组织 HH:MM:SS

### 8.1 讲解重点

时间核心 `time_core` 的职责是保存当前时间，并处理三类更新来源：

```text
1. 正常走时：tick_1h 触发秒加一
2. 本地设置：TIME 模式下对时、分、秒加减
3. PC 同步：COMM 协议 TIME_SET 直接加载时间
```

这里要重点讲一个设计选择：**内部时间始终用 24 小时制 BCD 保存，12/24 小时制只影响显示，不影响事件比较。**

### 8.2 核心代码摘录：走时使能和进位

文件位置：

```text
clock_amd.srcs/sources_1/new/time_core.v
```

核心代码摘录：

```verilog
assign tick_en = tick_1h & ~freeze_run & ~pc_time_load_valid &
                 ~add_sec_pulse & ~dec_sec_pulse &
                 ~add_hour_pulse & ~dec_hour_pulse &
                 ~add_min_pulse & ~dec_min_pulse;

assign sec_wrap = tick_en &
                  (sec_ten_bcd == 4'd5) &
                  (sec_unit_bcd == 4'd9);

assign min_wrap = sec_wrap &
                  (min_ten_bcd == 4'd5) &
                  (min_unit_bcd == 4'd9);
```

讲解重点：

> `tick_en` 用来决定当前是否允许正常走时。
> 当用户正在设置、PC 正在同步时间、或者有手动加减脉冲时，自动走时会被暂停，避免同一个周期出现多来源同时修改时间。
> `sec_wrap` 和 `min_wrap` 分别表示秒进位和分进位，用它们驱动分钟和小时更新。

### 8.3 核心代码摘录：PC 同步优先级高于本地走时

文件位置：

```text
clock_amd.srcs/sources_1/new/time_core.v
```

核心代码摘录：

```verilog
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        sec_unit_bcd <= 4'd0;
        sec_ten_bcd  <= 4'd0;
    end else if (pc_time_load_valid) begin
        sec_unit_bcd <= pc_sec_unit_bcd;
        sec_ten_bcd  <= pc_sec_ten_bcd;
    end else if (add_sec_pulse) begin
        // 手动秒加一，59 后回到 00
    end else if (dec_sec_pulse) begin
        // 手动秒减一，00 前回到 59
    end else if (tick_1k && tick_en) begin
        if (sec_ten_bcd == 4'd5 && sec_unit_bcd == 4'd9) begin
            sec_ten_bcd  <= 4'd0;
            sec_unit_bcd <= 4'd0;
        end else if (sec_unit_bcd == 4'd9) begin
            sec_ten_bcd  <= sec_ten_bcd + 1'b1;
            sec_unit_bcd <= 4'd0;
        end else begin
            sec_unit_bcd <= sec_unit_bcd + 1'b1;
        end
    end
end
```

讲解话术：

> 这里我学到的是多来源写寄存器必须有优先级。
> PC 同步时间应该优先级最高，因为它是一次完整加载；其次是用户手动设置；最后才是自动走时。
> 这样可以避免同一个时间寄存器在一个周期内被多个逻辑同时试图修改。

---

## 9. 日期与 12/24 小时制：内部逻辑和显示逻辑解耦

### 9.1 日期模块怎么讲

日期模块 `date_core` 负责保存：

```text
年份：YYYY，用于 PC 同步和 OLED 显示
月份：MM
日期：DD
星期：weekday
```

它有两类更新来源：

```text
1. CLOCK 设置层：手动调整月、日、星期
2. PC TIME_SET：同步完整日期和星期
```

跨天逻辑由 `day_tick_pulse` 触发，当前首版不实现闰年自动处理。汇报时可以诚实地说：

> 日期模块第一版重点服务 OLED 状态副屏和 PC 时间同步，跨天会更新月/日/星期；闰年和复杂日历规则不是这次课程实验的重点，所以没有扩展成完整万年历。

### 9.2 12/24 小时制核心代码

文件位置：

```text
clock_amd.srcs/sources_1/new/hour_format_ctrl.v
clock_amd.srcs/sources_1/new/hour_format_display.v
```

`hour_format_ctrl.v` 核心代码：

```verilog
module hour_format_ctrl(
    input  clk,
    input  rst,
    input  toggle_pulse,
    input  inc_format_pulse,
    input  dec_format_pulse,
    output hour_format_12h
);

reg format_12h_reg;
assign hour_format_12h = format_12h_reg;

always @(posedge clk or negedge rst) begin
    if (!rst)
        format_12h_reg <= 1'b0;   // 默认 24 小时制
    else if (toggle_pulse || inc_format_pulse || dec_format_pulse)
        format_12h_reg <= ~format_12h_reg;
end
endmodule
```

`hour_format_display.v` 核心逻辑摘录：

```verilog
always @(*) begin
    display_hour_ten_reg  = hour_ten_24;
    display_hour_unit_reg = hour_unit_24;
    is_pm_reg             = 1'b0;

    if (hour_format_12h) begin
        case ({hour_ten_24, hour_unit_24})
            8'h00: begin
                display_hour_ten_reg  = 4'd1;  // 00:xx -> 12:xx AM
                display_hour_unit_reg = 4'd2;
                is_pm_reg = 1'b0;
            end
            8'h12: begin
                display_hour_ten_reg  = 4'd1;  // 12:xx -> 12:xx PM
                display_hour_unit_reg = 4'd2;
                is_pm_reg = 1'b1;
            end
            8'h13: begin display_hour_ten_reg = 4'd0; display_hour_unit_reg = 4'd1; is_pm_reg = 1'b1; end
            // 14~23 依次转换成 02~11 PM
            default: begin
                display_hour_ten_reg  = hour_ten_24;
                display_hour_unit_reg = hour_unit_24;
            end
        endcase
    end
end
```

讲解重点：

> 内部计时和闹钟、日程比较始终用 24 小时制，这样比较逻辑简单可靠。
> 12 小时制只是显示层转换，这体现了“内部状态”和“用户显示”解耦的思想。

---

## 10. 闹钟系统：8 槽位、pending、贪睡和最近闹钟扫描

### 10.1 产品讲法

闹钟不是一个单独时间点，而是 8 个槽位组成的事件表。

```text
ALARM 槽位 0~7
    ├─ 每个槽有 HH:MM:SS
    ├─ 每个槽有 enable 开关
    ├─ 到点后进入 pending
    ├─ LED0~LED7 显示槽位状态
    ├─ 支持 BTNC 确认
    └─ 支持方向键贪睡 1/3/5/10 分钟
```

汇报时可以这样讲：

> 闹钟模块练习的是多槽位状态管理。
> 单个闹钟只需要保存一个时间，但 8 槽闹钟需要保存 8 组时间、8 个 enable、8 个 pending，还要在当前时间匹配时产生事件。
> 到点后不是直接控制蜂鸣器，而是产生 `alarm_event_valid` 和 `alarm_event_slot`，交给统一提醒模块处理。

### 10.2 核心代码摘录：端口与 PC 写入接口

文件位置：

```text
clock_amd.srcs/sources_1/new/alarm_ctrl.v
```

核心代码摘录：

```verilog
module alarm_ctrl(
    input clk,
    input tick_1k,
    input rst,

    input alarm_slot_inc_pulse,
    input alarm_slot_dec_pulse,
    input alarm_hour_inc_pulse,
    input alarm_hour_dec_pulse,
    input alarm_min_inc_pulse,
    input alarm_min_dec_pulse,
    input alarm_sec_inc_pulse,
    input alarm_sec_dec_pulse,
    input alarm_enable_toggle_pulse,
    input alarm_event_ack_pulse,

    input snooze_set_pulse,
    input [3:0] snooze_add_min,
    input [2:0] snooze_slot_index,

    input [3:0] cur_sec_ten_bcd,
    input [3:0] cur_sec_unit_bcd,
    input [3:0] cur_min_ten_bcd,
    input [3:0] cur_min_unit_bcd,
    input [3:0] cur_hour_unit_bcd,
    input [3:0] cur_hour_ten_bcd,

    input       pc_alarm_write_valid,
    input [2:0] pc_alarm_write_slot,
    input [3:0] pc_alarm_write_hour_ten_bcd,
    input [3:0] pc_alarm_write_hour_unit_bcd,
    input [3:0] pc_alarm_write_min_ten_bcd,
    input [3:0] pc_alarm_write_min_unit_bcd,
    input [3:0] pc_alarm_write_sec_ten_bcd,
    input [3:0] pc_alarm_write_sec_unit_bcd,
    input       pc_alarm_write_enable,

    output [7:0] alarm_slot_enable_mask,
    output [7:0] alarm_slot_selected_mask,
    output [7:0] alarm_pending_mask,
    output       alarm_event_valid,
    output [2:0] alarm_event_slot
);
```

讲解重点：

> 这里可以看到，闹钟模块既接收本地按键设置，也接收 PC 直接写入。
> PC 写入不是模拟按键，而是通过专门的写端口直接更新某个槽位，这样更稳定、更容易验证。

### 10.3 核心代码摘录：时间匹配与 pending 事件

文件位置：

```text
clock_amd.srcs/sources_1/new/alarm_ctrl.v
```

核心代码摘录，部分变量名保留真实源码结构，局部做了删节：

```verilog
always @(*) begin
    normal_match_mask_reg = 8'b0000_0000;
    snooze_match_mask_reg = 8'b0000_0000;

    for (i = 0; i < 8; i = i + 1) begin
        if (alarm_enable_reg[i] &&
            (alarm_hour_ten_reg[i]  == cur_hour_ten_bcd[1:0]) &&
            (alarm_hour_unit_reg[i] == cur_hour_unit_bcd)      &&
            (alarm_min_ten_reg[i]   == cur_min_ten_bcd[2:0])  &&
            (alarm_min_unit_reg[i]  == cur_min_unit_bcd)      &&
            (alarm_sec_ten_reg[i]   == cur_sec_ten_bcd[2:0])  &&
            (alarm_sec_unit_reg[i]  == cur_sec_unit_bcd)) begin
            normal_match_mask_reg[i] = 1'b1;
        end

        // snooze_match_mask_reg[i] 用于贪睡目标时间匹配，逻辑类似
    end
end

assign match_mask          = normal_match_mask_reg | snooze_match_mask_reg;
assign trigger_mask        = match_mask & ~match_d;
assign alarm_event_valid   = |pending_mask_reg;
assign alarm_event_slot    = first_set_index(pending_mask_reg);
assign alarm_pending_mask  = pending_mask_reg;
```

这段代码可以这样讲：

> 每个 tick 周期，闹钟模块会扫描 8 个槽位，比较当前时间和槽位时间。
> `match_d` 用来记录上一拍匹配状态，所以 `trigger_mask = match_mask & ~match_d` 可以避免同一秒内重复触发。
> 触发后事件会进入 `pending_mask_reg`，等待统一提醒系统处理。

### 10.4 核心代码摘录：PC 写入优先级

文件位置：

```text
clock_amd.srcs/sources_1/new/alarm_ctrl.v
```

核心代码摘录：

```verilog
if (pc_alarm_write_valid) begin
    alarm_hour_ten_reg [pc_alarm_write_slot] <= pc_alarm_write_hour_ten_bcd[1:0];
    alarm_hour_unit_reg[pc_alarm_write_slot] <= pc_alarm_write_hour_unit_bcd;
    alarm_min_ten_reg  [pc_alarm_write_slot] <= pc_alarm_write_min_ten_bcd[2:0];
    alarm_min_unit_reg [pc_alarm_write_slot] <= pc_alarm_write_min_unit_bcd;
    alarm_sec_ten_reg  [pc_alarm_write_slot] <= pc_alarm_write_sec_ten_bcd[2:0];
    alarm_sec_unit_reg [pc_alarm_write_slot] <= pc_alarm_write_sec_unit_bcd;
    alarm_enable_reg   [pc_alarm_write_slot] <= pc_alarm_write_enable;

    pending_mask_reg   [pc_alarm_write_slot] <= 1'b0;
    snooze_active_reg  [pc_alarm_write_slot] <= 1'b0;
    match_d            [pc_alarm_write_slot] <= 1'b0;
end
```

讲解重点：

> PC 写入某个闹钟槽位时，会同时清除该槽位 pending、snooze 和 match 状态。
> 这样可以避免一个已经被 PC 改掉的闹钟继续保留旧提醒事件，这是产品逻辑里很重要的一致性处理。

---

## 11. 日程系统：从“闹钟”扩展到“计划表”

### 11.1 产品讲法

日程系统和闹钟类似，但更偏向计划管理。

```text
SCHED 槽位 0~7
    ├─ 每个槽有 HH:MM:SS
    ├─ 每个槽有 type，例如 CLASS / CONF / LAB / TEST 等
    ├─ 每个槽有 enable 开关
    ├─ 到点后进入 pending
    ├─ 支持最近日程扫描
    └─ 支持 PC 直接写入和读取
```

可以这样讲：

> 日程模块本质上是事件表。
> 它和闹钟的区别是除了时间和开关，还多了一个类型字段。
> OLED 和数码管可以根据这个类型显示更有语义的信息，让项目从“响铃”变成“提醒我下一件事是什么”。

### 11.2 核心代码摘录：日程槽位接口

文件位置：

```text
clock_amd.srcs/sources_1/new/schedule_ctrl.v
```

核心代码摘录：

```verilog
module schedule_ctrl(
    input clk,
    input rst,

    input schedule_slot_inc_pulse,
    input schedule_slot_dec_pulse,
    input [7:0] schedule_slot_switches,

    input schedule_hour_inc_pulse,
    input schedule_hour_dec_pulse,
    input schedule_min_inc_pulse,
    input schedule_min_dec_pulse,
    input schedule_sec_inc_pulse,
    input schedule_sec_dec_pulse,
    input schedule_type_inc_pulse,
    input schedule_type_dec_pulse,
    input schedule_enable_toggle_pulse,
    input schedule_event_ack_pulse,

    input [3:0] cur_sec_ten_bcd,
    input [3:0] cur_sec_unit_bcd,
    input [3:0] cur_min_ten_bcd,
    input [3:0] cur_min_unit_bcd,
    input [3:0] cur_hour_ten_bcd,
    input [3:0] cur_hour_unit_bcd,

    input       pc_sched_write_valid,
    input [2:0] pc_sched_write_slot,
    input [3:0] pc_sched_write_hour_ten_bcd,
    input [3:0] pc_sched_write_hour_unit_bcd,
    input [3:0] pc_sched_write_min_ten_bcd,
    input [3:0] pc_sched_write_min_unit_bcd,
    input [3:0] pc_sched_write_sec_ten_bcd,
    input [3:0] pc_sched_write_sec_unit_bcd,
    input [2:0] pc_sched_write_type,
    input       pc_sched_write_enable,

    output [7:0] schedule_slot_enable_mask,
    output [7:0] schedule_pending_mask,
    output       schedule_event_valid,
    output [2:0] schedule_event_slot
);
```

### 11.3 核心代码摘录：日程匹配和 pending

文件位置：

```text
clock_amd.srcs/sources_1/new/schedule_ctrl.v
```

核心代码摘录：

```verilog
always @(*) begin
    match_mask_reg = 8'b0000_0000;

    for (i = 0; i < 8; i = i + 1) begin
        if (enable_mask_reg[i] &&
            (hour_ten_reg[i]  == cur_hour_ten_bcd[1:0]) &&
            (hour_unit_reg[i] == cur_hour_unit_bcd)      &&
            (min_ten_reg[i]   == cur_min_ten_bcd[2:0])  &&
            (min_unit_reg[i]  == cur_min_unit_bcd)      &&
            (sec_ten_reg[i]   == cur_sec_ten_bcd[2:0])  &&
            (sec_unit_reg[i]  == cur_sec_unit_bcd)) begin
            match_mask_reg[i] = 1'b1;
        end
    end
end

always @(*) begin
    pending_next = pending_mask_reg;

    if (schedule_event_ack_pulse)
        pending_next = pending_next & ~current_event_mask;

    pending_next = pending_next | trigger_mask;
end

assign schedule_event_valid = |pending_mask_reg;
assign schedule_event_slot  = first_set_index(pending_mask_reg);
```

讲解重点：

> 日程不是到点立刻消失，而是进入 pending。
> pending 的好处是提醒事件不会因为用户一瞬间没看见就丢掉，必须确认后才清除。
> 这比简单的组合输出更接近实际产品的提醒逻辑。

### 11.4 核心代码摘录：PC 直接写入日程

文件位置：

```text
clock_amd.srcs/sources_1/new/schedule_ctrl.v
```

核心代码摘录：

```verilog
if (pc_sched_write_valid) begin
    hour_ten_reg [pc_sched_write_slot] <= pc_sched_write_hour_ten_bcd[1:0];
    hour_unit_reg[pc_sched_write_slot] <= pc_sched_write_hour_unit_bcd;
    min_ten_reg  [pc_sched_write_slot] <= pc_sched_write_min_ten_bcd[2:0];
    min_unit_reg [pc_sched_write_slot] <= pc_sched_write_min_unit_bcd;
    sec_ten_reg  [pc_sched_write_slot] <= pc_sched_write_sec_ten_bcd[2:0];
    sec_unit_reg [pc_sched_write_slot] <= pc_sched_write_sec_unit_bcd;
    type_reg     [pc_sched_write_slot] <= pc_sched_write_type;
    enable_mask_reg[pc_sched_write_slot] <= pc_sched_write_enable;

    pending_mask_reg[pc_sched_write_slot] <= 1'b0;
    match_d         [pc_sched_write_slot] <= 1'b0;
end
```

讲解重点：

> PC 写入日程时，不仅写入时间，还写入日程类型和开关。
> 写入后清除旧 pending 和 match 状态，保证上位机看到的日程状态和 FPGA 内部一致。

---

## 12. 倒计时系统：编辑、运行、停止和到零事件

### 12.1 产品讲法

倒计时模式 `COUNT` 支持：

```text
设置 HH:MM:SS
BTNU 启动 / 继续
BTND 停止
运行时每秒递减
到 00:00:00 产生 countdown_done_pulse
提醒交给 notification_ctrl 统一处理
```

汇报时可以这样讲：

> 倒计时模块训练的是反向计数和借位逻辑。
> 与普通时钟向上计数不同，倒计时要处理秒从 00 借位到 59，分钟从 00 借位到 59，小时递减，还要在最后 1 秒产生到零事件。

### 12.2 核心代码摘录：运行条件和到零事件

文件位置：

```text
clock_amd.srcs/sources_1/new/countdown_ctrl.v
```

核心代码摘录：

```verilog
assign countdown_nonzero = (|hour_ten_bcd) | (|hour_unit_bcd) |
                           (|min_ten_bcd)  | (|min_unit_bcd)  |
                           (|sec_ten_bcd)  | (|sec_unit_bcd);

assign countdown_one = (hour_ten_bcd == 4'd0) &&
                       (hour_unit_bcd == 4'd0) &&
                       (min_ten_bcd  == 4'd0) &&
                       (min_unit_bcd == 4'd0) &&
                       (sec_ten_bcd  == 4'd0) &&
                       (sec_unit_bcd == 4'd1);

assign run_tick         = countdown_run & tick_1h;
assign run_tick_nonzero = run_tick & countdown_nonzero;
assign borrow_minute    = run_tick_nonzero &
                          (sec_ten_bcd == 4'd0) &
                          (sec_unit_bcd == 4'd0);
assign borrow_hour      = borrow_minute &
                          (min_ten_bcd == 4'd0) &
                          (min_unit_bcd == 4'd0);

assign countdown_done_pulse = countdown_run & tick_1h & countdown_one;
```

讲解重点：

> `countdown_one` 表示当前还剩 1 秒。
> 当运行状态下遇到这一秒，模块会产生 `countdown_done_pulse`，同时停止运行。
> 这个到零事件不会直接响蜂鸣器，而是交给统一提醒模块。

### 12.3 核心代码摘录：PC 控制优先级

文件位置：

```text
clock_amd.srcs/sources_1/new/countdown_ctrl.v
```

核心代码摘录：

```verilog
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        countdown_run <= 1'b0;
    end else if (pc_count_load_valid) begin
        countdown_run <= 1'b0;             // PC 加载新值后默认停止
    end else if (pc_count_stop_pulse) begin
        countdown_run <= 1'b0;
    end else if (pc_count_start_pulse && countdown_nonzero) begin
        countdown_run <= 1'b1;
    end else if (countdown_run) begin
        if (countdown_stop_pulse)
            countdown_run <= 1'b0;
        else if (tick_1h && countdown_one)
            countdown_run <= 1'b0;
    end else if (countdown_start_pulse && countdown_nonzero) begin
        countdown_run <= 1'b1;
    end
end
```

讲解重点：

> PC 加载倒计时时，先把运行状态清零；如果 PC 希望它运行，再单独发送 `COUNT_START`。
> 这样协议语义更清楚：`COUNT_SET` 只负责设置值，`COUNT_START` 才负责启动。

---

## 13. 统一提醒仲裁：这个项目最值得重点讲的系统设计

### 13.1 为什么需要 notification_ctrl

闹钟、日程和倒计时都会触发提醒。如果每个模块都直接控制蜂鸣器，会出现三个问题：

```text
1. 多个模块同时驱动蜂鸣器，外设控制权冲突
2. OLED 弹窗不知道显示哪个提醒
3. 用户按 BTNC 时不知道确认的是哪个事件
```

所以我设计了 `notification_ctrl` 作为统一提醒仲裁层。

```text
countdown_done_pulse ─┐
alarm_event_valid ────┼──> notification_ctrl ──> buzzer_out
schedule_event_valid ─┘              │
                                      ├──> notify_type / notify_slot
                                      ├──> OLED 提醒弹窗
                                      ├──> alarm_event_ack_pulse
                                      └──> schedule_event_ack_pulse
```

### 13.2 核心代码摘录：提醒优先级

文件位置：

```text
clock_amd.srcs/sources_1/new/notification_ctrl.v
```

核心代码摘录：

```verilog
localparam [1:0] TYPE_NONE      = 2'd0;
localparam [1:0] TYPE_COUNTDOWN = 2'd1;
localparam [1:0] TYPE_ALARM     = 2'd2;
localparam [1:0] TYPE_SCHEDULE  = 2'd3;

function [1:0] highest_type;
    input countdown_pending;
    input alarm_pending;
    input schedule_pending;
    begin
        if (countdown_pending)
            highest_type = TYPE_COUNTDOWN;
        else if (alarm_pending)
            highest_type = TYPE_ALARM;
        else if (schedule_pending)
            highest_type = TYPE_SCHEDULE;
        else
            highest_type = TYPE_NONE;
    end
endfunction

function [2:0] highest_slot;
    input countdown_pending;
    input alarm_pending;
    input [2:0] alarm_slot;
    input schedule_pending;
    input [2:0] schedule_slot;
    begin
        if (countdown_pending)
            highest_slot = 3'd0;
        else if (alarm_pending)
            highest_slot = alarm_slot;
        else if (schedule_pending)
            highest_slot = schedule_slot;
        else
            highest_slot = 3'd0;
    end
endfunction
```

讲解重点：

> 这里我把提醒优先级显式写出来。
> 当前优先级是倒计时高于闹钟，闹钟高于日程。
> 这不是功能需求里的死规则，而是系统设计必须给出的仲裁策略。

### 13.3 核心代码摘录：确认、贪睡和蜂鸣节奏

文件位置：

```text
clock_amd.srcs/sources_1/new/notification_ctrl.v
```

核心代码摘录：

```verilog
assign selected_type   = highest_type(countdown_pending_reg,
                                      alarm_event_valid,
                                      schedule_event_valid);
assign selected_slot   = highest_slot(countdown_pending_reg,
                                      alarm_event_valid,
                                      alarm_event_slot,
                                      schedule_event_valid,
                                      schedule_event_slot);
assign selected_active = (selected_type != TYPE_NONE);
assign event_changed   = (selected_type != notify_type_reg) ||
                         (selected_slot != notify_slot_reg);

assign snooze_current  = selected_active &&
                         (selected_type == TYPE_ALARM) &&
                         (btn_up_pulse | btn_right_pulse | btn_down_pulse | btn_left_pulse);

assign dismiss_current = selected_active &&
                         (btn_center_pulse | timeout_due | snooze_current);
```

蜂鸣器节奏按不同提醒类型区分：

```verilog
function [10:0] beep_period_ms;
    input [1:0] event_type;
    begin
        case (event_type)
            TYPE_COUNTDOWN: beep_period_ms = 11'd200;
            TYPE_ALARM:     beep_period_ms = 11'd1000;
            TYPE_SCHEDULE:  beep_period_ms = 11'd2000;
            default:        beep_period_ms = 11'd1;
        endcase
    end
endfunction

function [10:0] beep_on_ms;
    input [1:0] event_type;
    begin
        case (event_type)
            TYPE_COUNTDOWN: beep_on_ms = 11'd80;
            TYPE_ALARM:     beep_on_ms = 11'd400;
            TYPE_SCHEDULE:  beep_on_ms = 11'd250;
            default:        beep_on_ms = 11'd0;
        endcase
    end
endfunction
```

讲解话术：

> 这个模块体现的是“事件产生”和“外设驱动”解耦。
> 闹钟、日程和倒计时只负责产生事件；蜂鸣器、OLED 弹窗和确认键由 `notification_ctrl` 统一管理。
> 这样以后如果再加番茄钟、课间提醒等新事件，只需要接入这个仲裁模块，不需要每个地方都改蜂鸣器逻辑。

---

## 14. 数码管显示系统：内容层和扫描层分离

### 14.1 产品讲法

八位数码管是主显示设备，用来显示模式、状态和时间数据。

显示路径是：

```text
time / alarm / schedule / countdown / comm 状态
        ↓
display_ctrl
        ↓
digit_code_bus[47:0]
        ↓
nexys_seg_scan
        ↓
seg_7
        ↓
AN[7:0] + CA~CG + DP
        ↓
八位数码管
```

这个路径可以这样讲：

> 我没有让每个功能模块直接控制数码管。
> 各模块只输出自己的状态，`display_ctrl` 统一决定八个数码管显示什么字符。
> `nexys_seg_scan` 只负责动态扫描，`seg_7` 只负责字符码到七段码转换。
> 这就是显示内容层和底层扫描层的分离。

### 14.2 核心代码摘录：display_ctrl 的模式显示逻辑

文件位置：

```text
clock_amd.srcs/sources_1/new/display_ctrl.v
```

核心代码摘录，长 case 做了删节：

```verilog
always @(*) begin
    mode_reg      = DISP_N;
    status_reg    = DISP_BLANK;
    sec_unit_reg  = {2'b00, sec_unit_time_bcd};
    sec_ten_reg   = {2'b00, sec_ten_time_bcd};
    min_unit_reg  = {2'b00, min_unit_time_bcd};
    min_ten_reg   = {2'b00, min_ten_time_bcd};
    hour_unit_reg = {2'b00, disp_hour_unit_time_bcd};
    hour_ten_reg  = {2'b00, disp_hour_ten_time_bcd};

    case (mode_state)
        MODE_NORMAL: begin
            mode_reg   = DISP_N;
            status_reg = setting_active ? DISP_D : DISP_BLANK;
            if (setting_active) begin
                hour_ten_reg  = {2'b00, date_month_ten_bcd};
                hour_unit_reg = {2'b00, date_month_unit_bcd};
                min_ten_reg   = {2'b00, date_day_ten_bcd};
                min_unit_reg  = {2'b00, date_day_unit_bcd};
                sec_ten_reg   = DISP_0;
                sec_unit_reg  = {3'b000, date_weekday};
            end
        end

        MODE_ALARM: begin
            mode_reg = DISP_A;
            if (setting_active) begin
                status_reg    = selected_alarm_enable ? DISP_O : DISP_F;
                hour_ten_reg  = {2'b00, alarm_hour_ten_bcd};
                hour_unit_reg = {2'b00, alarm_hour_unit_bcd};
                min_ten_reg   = {2'b00, alarm_min_ten_bcd};
                min_unit_reg  = {2'b00, alarm_min_unit_bcd};
                sec_ten_reg   = {2'b00, alarm_sec_ten_bcd};
                sec_unit_reg  = {2'b00, alarm_sec_unit_bcd};
            end else if (next_alarm_valid) begin
                status_reg    = DISP_O;
                // 显示最近闹钟时间
            end else begin
                status_reg    = DISP_F;
            end
        end

        MODE_COUNTDOWN: begin
            mode_reg      = DISP_C;
            status_reg    = countdown_run ? DISP_R : DISP_P;
            hour_ten_reg  = {2'b00, countdown_hour_ten_bcd};
            hour_unit_reg = {2'b00, countdown_hour_unit_bcd};
            min_ten_reg   = {2'b00, countdown_min_ten_bcd};
            min_unit_reg  = {2'b00, countdown_min_unit_bcd};
            sec_ten_reg   = {2'b00, countdown_sec_ten_bcd};
            sec_unit_reg  = {2'b00, countdown_sec_unit_bcd};
        end

        MODE_COMM: begin
            mode_reg      = DISP_C;
            status_reg    = DISP_O;
            hour_ten_reg  = DISP_M;
            hour_unit_reg = DISP_M;
            min_ten_reg   = comm_status_char(comm_status, 2'd0);
            min_unit_reg  = comm_status_char(comm_status, 2'd1);
            sec_ten_reg   = comm_status_char(comm_status, 2'd2);
            sec_unit_reg  = comm_status_char(comm_status, 2'd3);
        end
    endcase
end
```

讲解重点：

> 这里每个模式只需要决定八位数码管应该显示哪些字符码。
> 真正的低有效段选、位选扫描不在这里做，而是在下一层 `nexys_seg_scan` 里做。

### 14.3 核心代码摘录：七段动态扫描

文件位置：

```text
clock_amd.srcs/sources_1/new/nexys_seg_scan.v
```

核心代码摘录：

```verilog
localparam integer SCAN_DIV = 14'd12500;
reg [13:0] scan_div_cnt;
reg [2:0]  scan_idx;
reg [7:0]  seg_active_high;
reg [5:0]  digit_code;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        scan_div_cnt <= 14'd0;
        scan_idx     <= 3'd0;
    end else if (scan_div_cnt == SCAN_DIV - 1'b1) begin
        scan_div_cnt <= 14'd0;
        scan_idx     <= scan_idx + 1'b1;
    end else begin
        scan_div_cnt <= scan_div_cnt + 1'b1;
    end
end

always @(*) begin
    seg_active_high = 8'b0000_0000;
    an              = 8'hFF;
    digit_code      = 6'd10;

    case (scan_idx)
        3'd0: begin
            digit_code      = digit_code_bus[5:0];
            seg_active_high = {dp_mask[0], digit_seg_raw};
            an[0]           = 1'b0;
        end
        3'd1: begin
            digit_code      = digit_code_bus[11:6];
            seg_active_high = {dp_mask[1], digit_seg_raw};
            an[1]           = 1'b0;
        end
        // D2 ~ D6 类似
        default: begin
            digit_code      = digit_code_bus[47:42];
            seg_active_high = {dp_mask[7], digit_seg_raw};
            an[7]           = 1'b0;
        end
    endcase
end

always @(*) begin
    CA = ~seg_active_high[0];
    CB = ~seg_active_high[1];
    CC = ~seg_active_high[2];
    CD = ~seg_active_high[3];
    CE = ~seg_active_high[4];
    CF = ~seg_active_high[5];
    CG = ~seg_active_high[6];
    DP = ~seg_active_high[7];
end
```

讲解重点：

> Nexys A7 的八位七段数码管是低有效动态扫描。
> 所以逻辑里先用 `seg_active_high` 表示“想点亮哪些段”，最后再取反输出到 `CA~CG/DP`。
> 位选 `AN` 同样低有效，每次只拉低一个 `AN[i]`，高速轮流刷新八位。

### 14.4 核心代码摘录：字符码到七段码

文件位置：

```text
clock_amd.srcs/sources_1/new/seg_7.v
```

核心代码摘录：

```verilog
module seg_7(
    input [5:0] A,
    output reg [6:0] seg
);

// seg[6:0] maps to {g,f,e,d,c,b,a};
// 1 表示取反前“希望点亮”该段。
always @(*) begin
    case (A)
        6'd0: seg = 7'b011_1111; // 0
        6'd1: seg = 7'b000_0110; // 1
        6'd2: seg = 7'b101_1011; // 2
        6'd3: seg = 7'b100_1111; // 3
        6'd4: seg = 7'b110_0110; // 4
        6'd5: seg = 7'b110_1101; // 5 / S
        6'd6: seg = 7'b111_1101; // 6
        6'd7: seg = 7'b000_0111; // 7
        6'd8: seg = 7'b111_1111; // 8
        6'd9: seg = 7'b110_1111; // 9

        SEG_CHAR_BLANK: seg = 7'b000_0000;
        SEG_CHAR_A:     seg = 7'b111_0111;
        SEG_CHAR_C:     seg = 7'b011_1001;
        SEG_CHAR_E:     seg = 7'b111_1001;
        SEG_CHAR_M:     seg = 7'b001_0101; // 七段管近似显示 M
        SEG_CHAR_W:     seg = 7'b011_1110; // 七段管近似显示 W
        SEG_CHAR_EXCL:  seg = 7'b000_0110; // ! 近似为 1
        default:        seg = 7'b000_0000;
    endcase
end
endmodule
```

讲解重点：

> 七段管不能像 OLED 一样显示任意文字，所以我对 `M/W/G/!` 这类字符做了近似显示。
> 这也是产品实现中的折中：硬件资源有限，但通过近似字符仍然能表达 COMM、MSG、WAIT、ERR 等状态。

---

## 15. OLED 状态副屏：让产品从“数字钟”变成“信息终端”

### 15.1 产品讲法

数码管适合显示短数字和短状态，但不适合显示完整信息。所以项目增加了 OLED 状态副屏。

OLED 显示内容包括：

```text
日期
星期
温度
最近日程
最近闹钟
倒计时状态
当前模式标签
提醒弹窗
COMM 通信页面
消息时间戳
消息正文窗口
预设回复选择
```

汇报时可以这样讲：

> 数码管负责快速显示核心数字，OLED 负责显示更完整的状态信息。
> 这让项目不再像普通电子钟，而更像一个桌面时间管理终端。
> 当提醒激活时，OLED 弹窗会覆盖普通页面，显示当前提醒类型和槽位；当进入 COMM 模式时，OLED 会变成通信页面，显示消息和回复选项。

### 15.2 核心代码摘录：OLED 输入接口

文件位置：

```text
clock_amd.srcs/sources_1/new/oled_ui_display.v
```

核心代码摘录：

```verilog
module oled_ui_display (
    input wire clk,
    input wire rst,

    input wire [2:0] mode_state,
    input wire       edit_active,
    input wire       countdown_run,
    input wire       hour_format_12h,

    input wire       temp_valid,
    input wire       temp_negative,
    input wire [7:0] temp_c_abs,

    input wire       notify_active,
    input wire [1:0] notify_type,
    input wire [2:0] notify_slot,

    input wire [3:0] date_month_ten_bcd,
    input wire [3:0] date_month_unit_bcd,
    input wire [3:0] date_day_ten_bcd,
    input wire [3:0] date_day_unit_bcd,
    input wire [2:0] date_weekday,

    // 省略：最近闹钟、最近日程、倒计时、COMM 消息窗口等输入

    inout wire oled_scl,
    inout wire oled_sda
);
```

### 15.3 核心代码摘录：模式标签生成

文件位置：

```text
clock_amd.srcs/sources_1/new/oled_ui_display.v
```

核心代码摘录：

```verilog
function [39:0] mode_label_ascii;
    input [2:0] mode;
    begin
        case (mode)
            3'b000: mode_label_ascii = {"C","L","O","C","K"};
            3'b001: mode_label_ascii = {"T","I","M","E"," "};
            3'b010: mode_label_ascii = {"A","L","A","R","M"};
            3'b011: mode_label_ascii = {"H","O","U","R"," "};
            3'b100: mode_label_ascii = {"C","O","U","N","T"};
            3'b101: mode_label_ascii = {"S","C","H","E","D"};
            3'b110: mode_label_ascii = {"C","O","M","M"," "};
            default: mode_label_ascii = {"C","O","M","M"," "};
        endcase
    end
endfunction
```

### 15.4 OLED 页面生成伪代码

`oled_ui_display.v` 体量很大，不适合在汇报中整段展示。建议只讲其结构：

```verilog
// 文件：clock_amd.srcs/sources_1/new/oled_ui_display.v
// 伪代码：OLED 页面优先级
if (notify_active) begin
    // 最高优先级：提醒弹窗
    render_notify_popup(notify_type, notify_slot);
end else if (mode_state == MODE_COMM) begin
    // COMM 专用页面：连接状态、消息窗口、回复选择
    render_comm_page(comm_status,
                     comm_message_valid,
                     comm_timestamp_ascii,
                     comm_message_window_ascii,
                     comm_reply_mode,
                     comm_reply_index);
end else begin
    // 普通状态页面：日期、温度、最近日程、最近闹钟、倒计时、当前模式
    render_dashboard(date,
                     weekday,
                     temperature,
                     next_alarm,
                     next_schedule,
                     countdown,
                     mode_label);
end
```

讲解重点：

> OLED 显示的关键不只是“能亮”，而是信息优先级。
> 提醒弹窗优先级最高，其次是 COMM 页面，最后是普通状态面板。
> 这和产品界面设计类似：重要事件要抢占普通信息。

---

## 16. ClockLink Studio：让 FPGA 时钟从孤立设备变成可联动终端

### 16.1 产品讲法

如果只能通过板上按键设置时间、闹钟和日程，这个项目仍然比较像传统电子钟。加入 ClockLink Studio 后，它变成了 PC + FPGA 联动的桌面终端。

```text
ClockLink Studio PC GUI / CLI
        │
        │ USB-UART 115200 8N1
        ▼
Nexys A7 J6 USB-UART
        │
        ▼
uart_rx / uart_tx
        │
        ▼
protocol_parser / protocol_builder
        │
        ▼
comm_ctrl
        │
        ├─ TIME_SET：同步时间日期
        ├─ MSG_TX：发送消息到板子
        ├─ ALARM_SET/GET：设置或读取闹钟
        ├─ SCHED_SET/GET：设置或读取日程
        └─ COUNT_SET/START/STOP/STATUS：控制倒计时
```

汇报时可以这样讲：

> FPGA 端负责实时显示、提醒和本地交互；PC 端负责更方便的输入和管理。
> 例如输入长消息、设置多个闹钟和日程，用板上按键很不方便，但用 PC GUI 就很自然。
> 这就是我把它叫 ClockLink 的原因：它不只是 clock，而是能和 PC link 的 clock。

---

## 17. UART 物理层：115200 8N1 字节收发

### 17.1 协议链路

物理链路参数：

```text
接口：Nexys A7 J6 USB-UART
波特率：115200
数据位：8
校验位：无
停止位：1
流控：无
编码：ASCII
```

### 17.2 核心代码摘录：UART RX 状态机

文件位置：

```text
clock_amd.srcs/sources_1/new/uart_rx.v
```

核心代码摘录：

```verilog
module uart_rx #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg        rx_valid,
    output reg [7:0]  rx_data,
    output reg        rx_busy
);

localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam integer HALF_BIT     = CLKS_PER_BIT / 2;

localparam [2:0] ST_IDLE  = 3'd0;
localparam [2:0] ST_START = 3'd1;
localparam [2:0] ST_DATA  = 3'd2;
localparam [2:0] ST_STOP  = 3'd3;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state    <= ST_IDLE;
        rx_valid <= 1'b0;
        rx_busy  <= 1'b0;
    end else begin
        rx_valid <= 1'b0;
        case (state)
            ST_IDLE: begin
                rx_busy <= 1'b0;
                if (!rx_sync) begin
                    rx_busy   <= 1'b1;
                    clk_count <= HALF_BIT;
                    state     <= ST_START;
                end
            end

            ST_START: begin
                if (clk_count == 0) begin
                    if (!rx_sync) begin
                        clk_count <= CLKS_PER_BIT - 1;
                        state     <= ST_DATA;
                    end else begin
                        state <= ST_IDLE;
                    end
                end
            end

            ST_DATA: begin
                if (clk_count == 0) begin
                    rx_data[bit_index] <= rx_sync;
                    clk_count <= CLKS_PER_BIT - 1;
                    if (bit_index == 3'd7)
                        state <= ST_STOP;
                    else
                        bit_index <= bit_index + 1'b1;
                end
            end

            ST_STOP: begin
                if (clk_count == 0) begin
                    rx_busy <= 1'b0;
                    state   <= ST_IDLE;
                    if (rx_sync)
                        rx_valid <= 1'b1;
                end
            end
        endcase
    end
end
endmodule
```

讲解重点：

> UART 接收模块本质是一个状态机。
> 它先检测起始位，再在每个 bit 的中心采样 8 位数据，最后确认停止位。
> 收到一个完整字节后输出 `rx_valid` 和 `rx_data`，再交给协议解析模块。

### 17.3 核心代码摘录：UART TX 状态机

文件位置：

```text
clock_amd.srcs/sources_1/new/uart_tx.v
```

核心代码摘录：

```verilog
module uart_tx #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 115_200
)(
    input  wire      clk,
    input  wire      rst,
    input  wire      tx_start,
    input  wire [7:0]tx_data,
    output reg       tx,
    output reg       tx_busy,
    output reg       tx_done
);

localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

localparam [2:0] ST_IDLE  = 3'd0;
localparam [2:0] ST_START = 3'd1;
localparam [2:0] ST_DATA  = 3'd2;
localparam [2:0] ST_STOP  = 3'd3;
localparam [2:0] ST_DONE  = 3'd4;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state   <= ST_IDLE;
        tx      <= 1'b1;
        tx_busy <= 1'b0;
        tx_done <= 1'b0;
    end else begin
        tx_done <= 1'b0;
        case (state)
            ST_IDLE: begin
                tx <= 1'b1;
                if (tx_start) begin
                    tx_shift  <= tx_data;
                    tx_busy   <= 1'b1;
                    tx        <= 1'b0;              // start bit
                    clk_count <= CLKS_PER_BIT - 1;
                    state     <= ST_START;
                end
            end

            ST_DATA: begin
                tx <= tx_shift[bit_index];
                if (clk_count == 0) begin
                    if (bit_index == 3'd7) begin
                        tx    <= 1'b1;              // stop bit
                        state <= ST_STOP;
                    end else begin
                        bit_index <= bit_index + 1'b1;
                    end
                end
            end

            ST_DONE: begin
                tx_done <= 1'b1;
                tx_busy <= 1'b0;
                tx      <= 1'b1;
                state   <= ST_IDLE;
            end
        endcase
    end
end
endmodule
```

---

## 18. 通信协议：不是随便发字符串，而是轻量可扩展协议

### 18.1 帧格式

ClockLink 使用 ASCII 帧：

```text
#SEQ|CMD|PAYLOAD*CS\n
BODY = SEQ|CMD|PAYLOAD
CS   = BODY 中所有 ASCII 字节 XOR 后的两位十六进制
```

示例：

```text
#01|HELLO|role=pc;ver=0.1;caps=mock*3C
#03|TIME_SET|date=2026-06-05;time=15:03:00;weekday=5*60
#04|MSG_TX|ts=2026-06-05T15:03:00;len=5;text=48656C6C6F*52
#05|COUNT_SET|time=00:01:30*CS
```

### 18.2 为什么要这样设计

可以这样讲：

> 我没有直接让 PC 随便发字符串，而是设计了一个带序号、命令、payload 和校验的轻量协议。
> `SEQ` 用来匹配请求和回复，`CMD` 表示命令类型，`PAYLOAD` 传具体参数，`CS` 用 XOR 校验发现传输错误。
> 这样 PC 和 FPGA 之间有清晰边界，后续扩展新命令时也比较容易。

### 18.3 核心代码摘录：协议解析状态机

文件位置：

```text
clock_amd.srcs/sources_1/new/protocol_parser.v
```

核心代码摘录：

```verilog
// Streaming parser for #SEQ|CMD|PAYLOAD*CS\n frames.
// MSG_TX text is decoded while the frame body is received and only committed
// after checksum validation, avoiding a wide dynamic BODY buffer.

localparam [2:0] ST_IDLE  = 3'd0;
localparam [2:0] ST_BODY  = 3'd1;
localparam [2:0] ST_CS_HI = 3'd2;
localparam [2:0] ST_CS_LO = 3'd3;
localparam [2:0] ST_EOL   = 3'd4;
localparam [2:0] ST_DROP  = 3'd5;
localparam [2:0] ST_EMIT  = 3'd6;

localparam [3:0] CMD_HELLO        = 4'd0;
localparam [3:0] CMD_PING         = 4'd1;
localparam [3:0] CMD_STATUS_GET   = 4'd2;
localparam [3:0] CMD_MSG_TX       = 4'd3;
localparam [3:0] CMD_MSG_GET      = 4'd4;
localparam [3:0] CMD_MSG_CLEAR    = 4'd5;
localparam [3:0] CMD_TIME_SET     = 4'd6;
localparam [3:0] CMD_TIME_GET     = 4'd7;
localparam [3:0] CMD_ALARM_SET    = 4'd8;
localparam [3:0] CMD_ALARM_GET    = 4'd9;
localparam [3:0] CMD_SCHED_SET    = 4'd10;
localparam [3:0] CMD_SCHED_GET    = 4'd11;
localparam [3:0] CMD_COUNT_SET    = 4'd12;
localparam [3:0] CMD_COUNT_START  = 4'd13;
localparam [3:0] CMD_COUNT_STOP   = 4'd14;
localparam [3:0] CMD_COUNT_STATUS = 4'd15;
```

协议解析流程可以讲成伪代码：

```verilog
// 文件：protocol_parser.v
// 伪代码：流式解析
on each rx_valid byte:
    if state == ST_IDLE:
        wait '#'
    if state == ST_BODY:
        update calc_xor
        parse SEQ / CMD / fixed-order PAYLOAD
        if byte == '*': go ST_CS_HI
        if body too long: go ST_DROP
    if state == ST_CS_HI/ST_CS_LO:
        collect two checksum hex chars
    if state == ST_EOL:
        require '\n'
        if checksum ok and payload valid: emit cmd_xxx_valid pulse
        else: emit nack_valid with error code
    if state == ST_DROP:
        discard until '\n'
```

讲解重点：

> 这里我学到的是，通信协议不能只看“能收到字符串”，还要考虑帧边界、长度限制、校验失败、非法 payload 和命令分发。
> FPGA 端资源有限，所以第一版对部分命令采用固定字段顺序解析，避免实现过于复杂的通用字符串字典。

---

## 19. COMM 模式与消息系统

### 19.1 产品讲法

COMM 模式让板子可以作为一个小型消息终端：

```text
PC 发送消息
    ↓
FPGA 接收 MSG_TX
    ↓
message_store 保存最近 16 条消息
    ↓
COMM 模式下 SW0-SW15 选择消息
    ↓
OLED 显示时间戳和正文窗口
    ↓
BTNU / BTND 滚动消息
    ↓
BTNC 进入回复选择
    ↓
BTNR 发送预设回复
```

现场讲法：

> 板子上的按键不适合输入长文本，所以我设计成 PC 发送消息，FPGA 保存并显示。
> FPGA 端提供预设回复，用户在板上选择后通过 UART 发回 PC。
> 这体现了 FPGA 和 PC 的分工：PC 负责复杂输入，板子负责实时显示和轻量交互。

### 19.2 COMM 模式数码管状态

文件位置：

```text
clock_amd.srcs/sources_1/new/display_ctrl.v
```

核心代码摘录：

```verilog
function [5:0] comm_status_char;
    input [2:0] status;
    input [1:0] char_index;
    begin
        case (status)
            3'd1: begin // WAIT
                case (char_index)
                    2'd0: comm_status_char = DISP_W;
                    2'd1: comm_status_char = DISP_A;
                    2'd2: comm_status_char = DISP_I;
                    default: comm_status_char = DISP_T;
                endcase
            end
            3'd2: begin // CONN
                case (char_index)
                    2'd0: comm_status_char = DISP_C;
                    2'd1: comm_status_char = DISP_O;
                    2'd2: comm_status_char = DISP_N;
                    default: comm_status_char = DISP_N;
                endcase
            end
            3'd3: begin // MSG!
                case (char_index)
                    2'd0: comm_status_char = DISP_M;
                    2'd1: comm_status_char = DISP_S;
                    2'd2: comm_status_char = DISP_G;
                    default: comm_status_char = DISP_EXCL;
                endcase
            end
            3'd4: begin // ERR
                case (char_index)
                    2'd0: comm_status_char = DISP_E;
                    2'd1: comm_status_char = DISP_R;
                    2'd2: comm_status_char = DISP_R;
                    default: comm_status_char = DISP_BLANK;
                endcase
            end
            default: begin // DISC
                case (char_index)
                    2'd0: comm_status_char = DISP_D;
                    2'd1: comm_status_char = DISP_I;
                    2'd2: comm_status_char = DISP_S;
                    default: comm_status_char = DISP_C;
                endcase
            end
        endcase
    end
endfunction
```

讲解重点：

> COMM 模式下，数码管左侧显示 `COMM` 的近似字符，右侧显示 `DISC / WAIT / CONN / MSG! / ERR` 状态。
> OLED 则承担消息正文显示，二者形成主副显示分工。

---

## 20. PC 端 ClockLink Studio：软件配套让项目更像产品

### 20.1 软件分层讲法

PC 端可以这样讲，不要展开每个 Python 文件：

```text
software/clocklink_studio/
│
├─ protocol      帧编解码、XOR 校验、命令构造
├─ transport     mock transport / serial transport
├─ services      时间、消息、闹钟、日程、倒计时服务
├─ gui           Tkinter GUI 面板
├─ cli           命令行 demo
└─ tests         pytest 单元测试
```

讲解话术：

> 我给 FPGA 端做上位机，不是为了炫软件，而是为了让这个硬件项目更像真实产品。
> 对用户来说，用 PC 设置复杂内容比用几个按键方便很多。
> 对工程来说，上位机也能作为 mock 测试工具，帮助验证通信协议和 FPGA 命令响应。

### 20.2 可以演示的 PC 操作

```text
HELLO / PING       建立通信和心跳
TIME_SET           同步 PC 时间到板子
MSG_TX             发送消息到板子
ALARM_SET / GET    设置和读取闹钟槽位
SCHED_SET / GET    设置和读取日程槽位
COUNT_SET          设置倒计时初值
COUNT_START        启动倒计时
COUNT_STOP         停止倒计时
COUNT_STATUS       查询倒计时状态
```

---

## 21. 工程验证：从“能写”到“可信”

### 21.1 当前验证结果怎么讲

这个项目的验证结果可以讲成四层：

```text
HDL 语法层：xvlog 全源语法检查通过
顶层整合层：xelab clock_amd_top 顶层展开通过
通信仿真层：tb_comm_ctrl_control / time / msg / reply 均 PASS
PC 软件层：pytest 15 个测试全部通过
综合时序层：WNS=+1.232ns，TNS=0.000ns，失败端点 0
```

### 21.2 WNS/TNS 通俗解释

汇报时可以这样解释：

> WNS 是 Worst Negative Slack，可以理解为最差路径还剩多少时间余量。
> 如果 WNS 为正，说明最慢路径也能在时钟周期内完成。
> TNS 是 Total Negative Slack，是所有失败路径负 slack 的总和。
> TNS 为 0 表示没有失败路径。
> 所以当前综合检查中 WNS 为正、TNS 为 0，说明综合层面时序满足当前约束。

### 21.3 诚实边界

仓库当前状态记录中也有两个边界：

```text
1. 尚未生成 bitstream
2. 尚未进行 Nexys A7 100T 板级 USB-UART/COMM 实测
```

如果老师问到，可以这样回答：

> 当前仓库记录的是 RTL、通信仿真、PC mock、pytest 和综合时序已经通过；真实板级 USB-UART 是最后实物验证环节。
> 如果现场已经完成上板，我会用现场演示结果补充这一点；如果现场还没做串口实测，我会如实说明通信链路已经完成仿真和 mock 验证，但真实板级串口还需要最后验证。

这句话很重要，因为验收时诚实比硬撑更可信。

---

## 22. 汇报时最推荐强调的五个亮点

### 22.1 亮点一：不是普通电子钟，而是时间管理终端

一句话：

> 它不是只显示时间，而是把时间、日期、闹钟、日程、倒计时和 PC 通信组织在一起。

### 22.2 亮点二：统一 UI 降低用户学习成本

一句话：

> `SW0=0` 浏览，`SW0=1` 设置，所有模式遵循同一套操作逻辑。

### 22.3 亮点三：提醒仲裁体现系统设计能力

一句话：

> 倒计时、闹钟和日程都只产生事件，最终由 `notification_ctrl` 统一决定蜂鸣器、弹窗和确认逻辑。

### 22.4 亮点四：双显示系统提升产品表达力

一句话：

> 数码管显示核心数字和短状态，OLED 显示日期、温度、最近事件、消息和提醒弹窗。

### 22.5 亮点五：ClockLink Studio 让 FPGA 变成可联动终端

一句话：

> PC 通过 USB-UART 同步时间、发送消息、设置闹钟和日程，板上负责实时显示和提醒。

---

## 23. 推荐 PPT 结构

### 第 1 页：标题页

```text
“练”：基于 Nexys A7 的 ClockLink 智能时钟终端
—— 从基础 Verilog 到产品化时间管理系统
```

讲解重点：

> 这个项目体现的是把基础数电能力练成完整产品。

### 第 2 页：项目定位

```text
不是普通电子钟
而是桌面时间管理终端
```

内容：

```text
时间 / 日期 / 闹钟 / 日程 / 倒计时 / 12-24小时
OLED 状态副屏 / 蜂鸣提醒 / PC 上位机通信
```

### 第 3 页：七模式功能地图

```text
CLOCK → TIME → ALARM → HOUR → COUNT → SCHED → COMM
```

讲解重点：

> 七个模式被统一接入一个产品结构，不是功能堆叠。

### 第 4 页：统一交互设计

```text
SW0=0 浏览层
SW0=1 设置层
提醒激活时 BTNC 优先确认/消音
```

讲解重点：

> 用户只要记住一套操作规则，就能使用所有功能。

### 第 5 页：系统总体架构

```text
clock_amd_top
 ├─ clock.v
 │   ├─ ui_ctrl
 │   ├─ time/date/hour
 │   ├─ alarm/schedule/countdown
 │   ├─ notification_ctrl
 │   ├─ display_ctrl
 │   └─ comm_ctrl
 ├─ nexys_seg_scan
 ├─ oled_ui_display
 └─ adt7420_reader
```

### 第 6 页：时间与事件核心

```text
time_core：HH:MM:SS
alarm_ctrl：8 槽闹钟
schedule_ctrl：8 槽日程
countdown_ctrl：倒计时
notification_ctrl：统一提醒
```

讲解重点：

> 时间系统不是一个计数器，而是一组事件模块协同工作。

### 第 7 页：显示系统

```text
display_ctrl → digit_code_bus → nexys_seg_scan → 七段管
oled_ui_display → 日期 / 温度 / 日程 / 闹钟 / 倒计时 / COMM
```

### 第 8 页：统一提醒仲裁

```text
alarm_ctrl
schedule_ctrl  → notification_ctrl → buzzer / OLED popup / ack
countdown_ctrl
```

### 第 9 页：ClockLink Studio

```text
PC GUI / CLI
    ↓ USB-UART
FPGA COMM 模式
    ↓
消息 / 时间同步 / 闹钟 / 日程 / 倒计时控制
```

### 第 10 页：UART 协议

```text
#SEQ|CMD|PAYLOAD*CS\n
SEQ：请求序号
CMD：命令类型
PAYLOAD：参数
CS：XOR 校验
```

### 第 11 页：验证结果

```text
xvlog PASS
xelab clock_amd_top PASS
COMM testbench PASS
pytest 15/15 PASS
WNS = +1.232 ns
TNS = 0.000 ns
Failing endpoints = 0
```

### 第 12 页：我练到了什么

```text
1. 模块化设计
2. 状态机组织
3. 统一 UI 交互
4. 数码管动态扫描
5. BCD 时间系统
6. 多事件提醒仲裁
7. UART 协议通信
8. PC + FPGA 联动
9. Vivado 综合与时序报告阅读
```

结尾：

> 这个项目让我从“能写 Verilog 模块”，练到了“能设计一个可交互、可扩展、可验证的 FPGA 产品”。

---

## 24. 完整验收讲稿

下面是一段可以直接作为口头汇报底稿的版本。

> 我的第一个实验是 ClockLink 智能时钟终端，我把它的主题概括为“练”。
> 这个“练”不是简单重复写一个电子钟，而是把数电课程中学到的计数器、状态机、按键、开关、数码管扫描、BCD 时间、模块化设计这些基础能力，练成一个完整的 FPGA 时间管理产品。
>
> 从用户角度看，它包含七个模式：CLOCK、TIME、ALARM、HOUR、COUNT、SCHED 和 COMM。CLOCK 是主时钟界面，TIME 用于本地校时，ALARM 支持 8 槽位闹钟，HOUR 支持 12/24 小时制切换，COUNT 是倒计时，SCHED 是日程提醒，COMM 则负责和 PC 上位机通信。
>
> 在交互上，我设计了统一 UI：`SW0=0` 是浏览层，用左右键切换模式；`SW0=1` 是设置层，用左右键切换字段，用上下键修改数值，用中键确认或切换开关。这样七个模式不需要各自记一套操作规则，用户只需要理解浏览层和设置层。提醒触发时，普通操作会被锁定，`BTNC` 优先作为确认和消音键。
>
> 在系统架构上，顶层 `clock_amd_top` 负责连接 Nexys A7 的时钟、按键、开关、数码管、LED、蜂鸣器、OLED、温度传感器和 USB-UART；主线 `clock.v` 负责集成 UI、时间、日期、闹钟、日程、倒计时、提醒和通信；各个子模块只负责自己的功能。
>
> 我认为这个项目最重要的设计点有两个。第一个是统一提醒仲裁：倒计时、闹钟和日程都会触发提醒，所以我没有让它们直接控制蜂鸣器，而是统一交给 `notification_ctrl` 决定当前提醒类型、槽位、蜂鸣器输出和确认逻辑。第二个是 ClockLink Studio：PC 可以通过 USB-UART 同步时间、发送消息、设置闹钟、设置日程和控制倒计时，让 FPGA 时钟从一个孤立设备变成一个可联动的桌面终端。
>
> 在显示上，数码管负责显示核心时间和模式状态，OLED 负责显示日期、温度、最近闹钟、最近日程、倒计时状态、提醒弹窗和 COMM 消息页面。这样主显示和副屏各有职责，产品表达能力更强。
>
> 在工程验证上，我做了 Verilog 全源语法检查、顶层展开、通信 testbench、PC 端 pytest 和 Vivado 综合时序检查。当前综合检查中 WNS 为正、TNS 为 0，说明综合层面没有失败路径。
>
> 所以这个项目对我最大的意义，是让我从“会写一些 Verilog 模块”，练到了“能把多个模块组织成一个可操作、可显示、可提醒、可通信、可验证的硬件产品”。这就是我把它概括为“练”的原因。

---

## 25. 老师可能会问的问题与推荐回答

### 25.1 为什么你把这个项目叫“练”？

推荐回答：

> 因为它主要不是依赖一个全新的复杂外设，而是把数电课里已经学过的基础能力练到系统级。
> 比如计数器、状态机、按键、开关、数码管扫描、BCD 时间、模块化设计，这些单独看都不难，但把它们组织成一个稳定的时间管理终端，就需要系统设计能力。

### 25.2 这个项目和普通电子钟有什么区别？

推荐回答：

> 普通电子钟主要是显示时间和设置闹钟。
> 我的项目做成了一个时间管理终端，有七个模式：时间、日期、闹钟、日程、倒计时、12/24 小时制和 COMM 通信。
> 它还有 OLED 状态副屏、统一提醒仲裁、蜂鸣器反馈和 PC 上位机联动，所以更接近完整产品。

### 25.3 为什么要设计统一 UI？

推荐回答：

> 因为功能变多以后，如果每个功能都定义一套按键，用户很难记，代码也难维护。
> 所以我把交互分成浏览层和设置层：`SW0=0` 浏览，`SW0=1` 设置。
> 这样所有模式都遵循类似规则，用户学习成本低，代码结构也更清晰。

### 25.4 为什么要有 notification_ctrl？

推荐回答：

> 因为闹钟、日程和倒计时都可能触发提醒。
> 如果它们都直接控制蜂鸣器和 OLED 弹窗，就会有冲突。
> 所以我让各模块只产生事件，由 `notification_ctrl` 统一仲裁当前提醒类型、槽位和蜂鸣器输出。
> 这体现了模块分工：事件产生和外设驱动解耦。

### 25.5 ClockLink Studio 有什么意义？

推荐回答：

> 它让 FPGA 时钟从孤立设备变成可以和 PC 联动的终端。
> 板上按键适合简单操作，但输入长消息、设置多个闹钟和日程时 PC 更方便。
> 所以我用 USB-UART 连接 PC 和 FPGA，让 PC 负责更友好的输入管理，FPGA 负责实时显示和硬件反馈。

### 25.6 为什么协议要带序号和校验？

推荐回答：

> 序号用于匹配请求和回复，避免 PC 不知道哪条命令得到了响应。
> 校验用于发现串口传输中的错误。
> 这样协议更稳定，也方便后续扩展更多命令。

### 25.7 为什么内部用 24 小时制，但还支持 12 小时制？

推荐回答：

> 因为内部计时和闹钟、日程比较用 24 小时制最简单可靠。
> 12 小时制只是显示习惯，所以我把它放在显示转换层处理，不改变内部时间和事件比较逻辑。
> 这体现了内部状态和用户显示解耦。

### 25.8 WNS/TNS 说明了什么？

推荐回答：

> WNS 表示最差路径的时序余量，TNS 表示失败路径负 slack 的总和。
> 当前综合检查中 WNS 为正、TNS 为 0，说明综合层面没有失败路径，设计满足当前时序约束。

### 25.9 如果老师问“有没有上板验证 UART”？

推荐回答：

> 仓库当前记录中，RTL、通信 testbench、PC mock、pytest 和综合时序已经通过；真实板级 USB-UART/COMM 实测是最后验证环节。
> 如果现场已经完成，我会以现场演示为准；如果现场没有完成，我会如实说明当前通信链路完成了仿真和 mock 验证，但真实串口还需要最后上板确认。

---

## 26. 代码路径速查表

| 讲解点 | 文件位置 | 讲解重点 |
| --- | --- | --- |
| 板级顶层 | `clock_amd.srcs/sources_1/new/clock_amd_top.v` | 100MHz、tick_1k、按键/开关/数码管/OLED/UART/温度连接 |
| 主线集成 | `clock_amd.srcs/sources_1/new/clock.v` | 各功能模块如何接入统一主线 |
| 统一 UI | `clock_amd.srcs/sources_1/new/ui_ctrl.v` | 七模式状态机、SW0 浏览/设置层、字段选择、按键脉冲 |
| 按键消抖 | `clock_amd.srcs/sources_1/new/button_pulse.v` | 按键同步、消抖、单脉冲化 |
| 当前时间 | `clock_amd.srcs/sources_1/new/time_core.v` | BCD 时分秒、自动走时、本地设置、PC 时间加载 |
| 日期星期 | `clock_amd.srcs/sources_1/new/date_core.v` | 月/日/星期、PC 日期加载、OLED 状态副屏 |
| 12/24 小时制 | `hour_format_ctrl.v`、`hour_format_display.v` | 内部 24 小时制，显示层转换成 12 小时制 |
| 闹钟 | `clock_amd.srcs/sources_1/new/alarm_ctrl.v` | 8 槽位、enable、pending、贪睡、最近闹钟、PC 写入 |
| 日程 | `clock_amd.srcs/sources_1/new/schedule_ctrl.v` | 8 槽位、type、enable、pending、最近日程、PC 写入 |
| 倒计时 | `clock_amd.srcs/sources_1/new/countdown_ctrl.v` | 编辑、启动、停止、借位、到零事件、PC 控制 |
| 提醒仲裁 | `clock_amd.srcs/sources_1/new/notification_ctrl.v` | COUNT/ALARM/SCHED 三类提醒统一仲裁 |
| 数码管内容 | `clock_amd.srcs/sources_1/new/display_ctrl.v` | 根据模式和状态生成 8 个 6-bit 字符码 |
| 数码管扫描 | `clock_amd.srcs/sources_1/new/nexys_seg_scan.v` | 动态扫描、位选低有效、段选低有效 |
| 七段码 | `clock_amd.srcs/sources_1/new/seg_7.v` | 数字和近似字符到七段码转换 |
| OLED | `clock_amd.srcs/sources_1/new/oled_ui_display.v` | SSD1306 初始化、分页刷新、状态页、COMM 页、提醒弹窗 |
| 温度 | `clock_amd.srcs/sources_1/new/adt7420_reader.v` | ADT7420 I2C 读取，作为 OLED 温度数据源 |
| UART RX | `clock_amd.srcs/sources_1/new/uart_rx.v` | 115200 8N1 接收状态机 |
| UART TX | `clock_amd.srcs/sources_1/new/uart_tx.v` | 115200 8N1 发送状态机 |
| 协议解析 | `clock_amd.srcs/sources_1/new/protocol_parser.v` | `#SEQ|CMD|PAYLOAD*CS\n` 流式解析、校验、命令脉冲 |
| 协议构帧 | `clock_amd.srcs/sources_1/new/protocol_builder.v` | ACK/NACK/STATUS/TIME/ALARM/SCHED/COUNT/REPLY 构造 |
| 通信总控 | `clock_amd.srcs/sources_1/new/comm_ctrl.v` | UART、协议、消息缓存、PC 控制脉冲整合 |
| 消息缓存 | `clock_amd.srcs/sources_1/new/message_store.v` | 最近 16 条消息保存、OLED 窗口输出 |
| 预设回复 | `clock_amd.srcs/sources_1/new/preset_reply_rom.v` | 8 条固定回复文本 |
| 约束 | `clock_amd.srcs/constrs_1/new/clock_amd.xdc` | Nexys A7 引脚约束、UART 引脚、显示引脚 |
| 综合脚本 | `scripts/run_phase_synth_check.tcl` | Vivado batch 综合时序检查 |
| 上位机软件 | `software/clocklink_studio/` | GUI、CLI、mock、serial transport、services、pytest |
| 演示流程 | `docs/FINAL_DEMO_GUIDE.md` | 最终演示步骤和 COMM 演示建议 |
| 协议文档 | `docs/UART_PROTOCOL.md` | 帧格式、命令表、校验和错误处理 |
| 代码地图 | `docs/CODEBASE_MAP.md` | 顶层、主线模块、显示路径、通信接入点 |

---

## 27. 最后一页总结

最后一页可以放这段：

> 第一个实验我用“练”来概括。
> 它让我把数电课程里学过的计数器、状态机、BCD、按键、数码管扫描、显示复用、UART 和模块化设计，练成了一个完整的 FPGA 桌面时间管理终端。
> ClockLink 的重点不只是功能数量多，而是这些功能被统一 UI、统一显示、统一提醒和 PC 通信组织成了一个系统。
> 通过这个项目，我对 Verilog 的理解从“写一个模块”提升到了“设计一个可操作、可扩展、可验证的硬件产品”。

---

## 28. 汇报时的表达原则

验收时建议一直坚持这个表达顺序：

```text
用户看到什么
    ↓
背后电路怎么做到
    ↓
我从中练到了什么
```

例如不要这样讲：

> 我写了 `ui_ctrl.v`、`display_ctrl.v`、`notification_ctrl.v`。

要这样讲：

> 用户只需要记住一套按键规则，就能操作七个模式。为了做到这一点，我设计了 `ui_ctrl`，把按键先转成统一的模式状态、字段索引、增减脉冲和确认脉冲。

也不要这样讲：

> 我写了 UART 接收和协议解析。

要这样讲：

> 为了让 FPGA 不只是孤立运行，我让它通过 USB-UART 和 PC 上位机通信。UART 负责字节收发，协议层负责把字节流变成有序号、有命令、有参数、有校验的控制帧，这样 PC 可以同步时间、发送消息和远程设置提醒。

这样老师听到的是“设计能力”，而不是“代码堆叠”。
