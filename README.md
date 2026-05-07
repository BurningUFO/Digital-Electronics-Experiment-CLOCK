# CLOCK to AMD

本仓库是数字逻辑课程设计 `CLOCK` 项目的 Nexys A7 100T / Vivado 迁移版本。

当前主线工程位于 `clock_amd/`，已经完成从旧 Quartus / 实验箱平台向 AMD Vivado / Nexys A7 100T 的迁移，并在此基础上补入了统一按键 UI、OLED 模式界面、闹铃蜂鸣器和倒计时等功能。

## 当前状态

当前版本已经可用的主功能：

1. 24 小时制正常走时
2. `TIME` 模式支持时、分、秒三级编辑
3. `ALARM` 模式支持时、分、秒、使能编辑
4. `ALARM` 按 `HH:MM:SS` 精确到秒比较，并触发蜂鸣器报警
5. `COUNT` 模式支持 `HH:MM:SS` 倒计时编辑
6. `COUNT` 模式下非编辑态可直接启动和停止
7. Nexys A7 八位数码管动态扫描显示
8. SSD1306 I2C OLED 三模式布局显示、编辑边框和滑动动画

当前仍为占位态的功能：

1. `HOUR` 12/24 小时制模式
2. `SCHED` 作息提醒模式

## 工程位置

- Vivado 工程：`clock_amd/clock_amd.xpr`
- 顶层文件：`clock_amd/clock_amd.srcs/sources_1/new/clock_amd_top.v`
- 主线集成：`clock_amd/clock_amd.srcs/sources_1/new/clock.v`

## 当前交互规则

模式顺序：

`CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> CLOCK`

非编辑态：

1. `BTNL`：切换到上一模式
2. `BTNR`：切换到下一模式
3. `BTNC`：进入当前模式编辑
4. 在 `COUNT` 模式下：
   `BTNU` 直接启动倒计时
   `BTND` 直接停止倒计时

编辑态：

1. `BTNL / BTNR`：切换字段
2. `BTNU / BTND`：修改当前字段
3. `BTNC`：退出编辑

各模式字段规则：

1. `TIME`：`时 -> 分 -> 秒`
2. `ALARM`：`时 -> 分 -> 秒 -> 使能`
3. `COUNT`：`时 -> 分 -> 秒`

## 显示说明

数码管：

1. 当前主线统一显示 `HH:MM:SS`
2. 编辑态下当前字段闪烁
3. `DP` 在闹铃相关状态下承担提示作用

OLED：

1. 中间显示当前模式的大字标题
2. 左右显示相邻模式的小字标题
3. 编辑态下当前模式外围出现边框
4. 左右切换模式时带滑动动画
5. 在 `COUNT` 模式下，OLED 底部会显示 `RUN / STOP`

## 板级接口

按键映射：

1. `CPU_RESETN`：系统复位，低有效
2. `BTNL`：左切换
3. `BTNR`：右切换
4. `BTNU`：加一 / 倒计时启动
5. `BTND`：减一 / 倒计时停止
6. `BTNC`：进入 / 退出编辑

外设：

1. OLED：SSD1306 I2C
2. 蜂鸣器：有源蜂鸣器，低电平触发

更详细接线说明见 `docs/工程模块使用说明.md`。

## 建议使用流程

1. 打开 `clock_amd/clock_amd.xpr`
2. 运行 `Synthesis`
3. 运行 `Implementation`
4. 生成 `Bitstream`
5. 下载到 Nexys A7 100T 开发板

如果改动了 HDL 逻辑或 `.xdc` 约束，必须重新生成 bitstream 后再下载到板子。

## 文档入口

- `docs/工程模块使用说明.md`
  当前主线功能、按键规则、板级接线、OLED 规则和上板测试步骤
- `docs/功能与修改日志.md`
  当前功能清单、历史修改记录、迁移与适配过程说明
- `docs/OLED模块上手文档.md`
  OLED 模块基础资料和最小验证工程说明
- `docs/有源蜂鸣器模块上手文档.md`
  蜂鸣器接线和基础使用说明

## 当前仓库重点

这不是旧 Quartus 单文件工程的简单复制版本，而是已经在 Vivado / Nexys A7 平台上重构过交互层、显示层和板级接口的主线工程。后续如果继续开发新功能，建议直接基于当前 `clock_amd` 主线扩展，不要回到旧平台接口上继续加逻辑。
