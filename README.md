# CLOCK AMD Workspace

这个目录是当前 `CLOCK` 项目的唯一最终工作区。

今后所有代码修改、Vivado 打开、上板验证和文档同步，都以本目录为准，不再把外层旧副本或其他平行目录当作主线。

## 工程入口

- Vivado 工程：`clock_amd.xpr`
- 顶层文件：`clock_amd.srcs/sources_1/new/clock_amd_top.v`
- 主线集成：`clock_amd.srcs/sources_1/new/clock.v`
- 约束文件：`clock_amd.srcs/constrs_1/new/clock_amd.xdc`

## 当前功能

1. `CLOCK` 正常走时
2. `TIME` 模式支持时、分、秒编辑
3. `ALARM` 模式支持时、分、秒、使能编辑
4. 闹钟按 `HH:MM:SS` 精确比较并触发蜂鸣器
5. `COUNT` 模式支持 `HH:MM:SS` 编辑、启动、停止和到零停止
6. OLED 支持三模式布局、编辑边框和左右切换动画
7. 蜂鸣器已经接入闹钟链路，倒计时结束提醒正在本工作区继续验证

## 当前交互规则

模式顺序：

`CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> CLOCK`

非编辑态：

1. `BTNL / BTNR`：切换模式
2. `BTNC`：进入编辑
3. `COUNT` 模式下：`BTNU = RUN`，`BTND = STOP`

编辑态：

1. `BTNL / BTNR`：切换字段
2. `BTNU / BTND`：修改当前字段
3. `BTNC`：退出编辑

## 目录约定

- `clock_amd.srcs/sources_1/new/`：唯一有效 HDL 源文件目录
- `clock_amd.srcs/constrs_1/new/`：唯一有效约束目录
- `docs/`：当前仍有效的说明文档
- `PROJECT_STATUS.md`：当前状态和下一步
- `HANDOFF.md`：给新 agent 的接手说明

## 使用方式

1. 打开 `clock_amd.xpr`
2. 小改逻辑时先跑 `Run Synthesis`
3. 需要上板时再跑 `Generate Bitstream`
4. 下载到 Nexys A7 100T 验证

如果修改了 HDL 或 `.xdc`，必须重新生成 bitstream 后再下载。
