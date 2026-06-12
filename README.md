# CLOCK AMD Workspace

这个目录是当前 `CLOCK` 项目的唯一最终工作区。

今后所有代码修改、Vivado 打开、上板验证和文档同步，都以本目录为准，不再把外层旧副本或其他平行目录当作主线。

## 工程入口

- Vivado 工程：`clock_amd.xpr`
- 顶层文件：`clock_amd.srcs/sources_1/new/clock_amd_top.v`
- 主线集成：`clock_amd.srcs/sources_1/new/clock.v`
- 约束文件：`clock_amd.srcs/constrs_1/new/clock_amd.xdc`
- 综合检查脚本：`scripts/run_phase_synth_check.tcl`

## 当前功能

1. `CLOCK / TIME / ALARM / HOUR / COUNT / SCHED / COMM` 七个模式已接入统一 UI。
2. `SW0=0` 为浏览层，`SW0=1` 为设置层。
3. 八位数码管按 `模式 / 状态 / HH / MM / SS` 或当前模式数据统一显示。
4. `CLOCK + SW0` 支持月、日、星期设置，供 OLED 状态副屏使用。
5. `HOUR` 支持 12/24 小时显示格式切换，不改变内部 24 小时计时和事件比较。
6. `ALARM` 支持 8 槽位、LED0~LED7 状态提示、pending 事件和闹钟贪睡。
7. `COUNT` 支持 `HH:MM:SS` 编辑、启动、停止和到零提醒。
8. `SCHED` 支持 8 个固定计划点、槽位开关、LED 指示和计划提醒。
9. `notification_ctrl` 统一仲裁倒计时、闹钟和计划提醒，并作为蜂鸣器唯一驱动源。
10. 整点报时已接入蜂鸣器链路，在正常走时进入 `HH:00:00` 时输出两段短蜂鸣；不占用 OLED 提醒弹窗。
11. OLED 为状态副屏基础版，显示日期、温度、最近计划、最近闹钟、倒计时状态和提醒弹窗；旧三模式滑动动画已移除。
12. OLED 字库已覆盖完整可打印 ASCII `0x20..0x7E`，COMM 消息小写字母和常见标点可独立显示；Unicode/中文仍不属于当前 UART 协议和 FPGA 字库范围。
13. ADT7420 温度读取模块已接入顶层 `TMP_SCL / TMP_SDA`，板级温度读数尚未实测。
14. ClockLink Studio USB-UART 通信扩展已完成协议库、mock PC 软件、COMM 模式、UART、消息缓存、预设回复、时间同步、闹钟/日程/倒计时直接控制的首版集成。

## 当前交互规则

模式顺序：

`CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM -> CLOCK`

浏览层，`SW0=0`：

1. `BTNL / BTNR`：切换模式。
2. `COUNT` 模式下 `BTNU` 启动或继续倒计时，`BTND` 停止倒计时。
3. `COMM` 模式下 `SW0-SW15` 查看最近 16 条消息，`BTNU/BTND` 滚动消息，`BTNC` 切换查看/回复，`BTNR` 发送预设回复。
4. `BTNC` 不再负责进入编辑层，普通状态下只作为当前模式的上下文确认键。

设置层，`SW0=1`：

1. `BTNL / BTNR`：切换字段或槽位。
2. `BTNU / BTND`：修改当前字段、槽位或开关值。
3. `BTNC`：用于上下文确认或开关切换，例如 ALARM/SCHED 使能切换、HOUR 格式切换。

提醒激活时：

1. 普通模式切换和设置操作会被锁定。
2. `BTNC` 优先作为提醒确认 / 消音。
3. 闹钟提醒下，方向键用于贪睡选择。

## 当前验证结果

1. `xvlog` 全源语法检查通过。
2. `xelab clock_amd_top` 顶层展开通过。
3. `xvlog` 全源语法检查通过。
4. Phase 8 通信回归通过：`tb_comm_ctrl_control/time/msg/reply` 均输出 `PASS`。
5. `tb_notification_hourly_chime` 和 `tb_oled_glyph` 针对整点报时与 OLED ASCII 字库通过聚焦仿真。
6. PC 软件 `python -m pytest` 最近记录通过，17 个测试全部通过。
7. 最新 `vivado -mode batch -source scripts/run_phase_synth_check.tcl` 综合检查通过，时序：`WNS=+1.779ns`，`TNS=0.000ns`，失败端点 `0`。
8. 尚未生成 bitstream。
9. 尚未进行 Nexys A7 100T 板级 USB-UART/COMM 实测。

## 目录约定

- `clock_amd.srcs/sources_1/new/`：唯一有效 HDL 源文件目录
- `clock_amd.srcs/constrs_1/new/`：唯一有效约束目录
- `scripts/`：工程维护和检查脚本
- `docs/`：当前有效说明文档
- `software/clocklink_studio/`：ClockLink Studio 上位机源码、测试、PyInstaller 配置和软件说明
- `artifacts/tool-runs/`：本地 Vivado/XSim 运行产物归档，不作为主线源码
- `artifacts/releases/`：本地软件发行 ZIP 输出目录，不作为源码提交
- `HANDOFF.md`：给新 agent 的接手说明
- `docs/AGENT_WORKLOG.md`：当前 ClockLink 阶段状态、检查结果和下一步
- `docs/FINAL_DEMO_GUIDE.md`：ClockLink 最终演示流程
- `docs/ClockLink_Studio_Release_Guide.md`：ClockLink Studio 打包和 GitHub Release 发行流程

## ClockLink Studio 软件发行

ClockLink Studio 采用“源码进 Git、构建产物进 GitHub Release”的方式管理。

本地构建 Windows 发行包：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\package_clocklink_studio.ps1 -Version v1.0.0
```

构建结果：

```text
artifacts/releases/ClockLinkStudio-v1.0.0-win64.zip
```

推送 `v*` 标签会触发 GitHub Actions 自动构建并上传 Release 附件：

```bash
git tag v1.0.0
git push origin v1.0.0
```

## 使用方式

1. 打开 `clock_amd.xpr`
2. 小改逻辑时先跑 `Run Synthesis` 或 `vivado -mode batch -source scripts/run_phase_synth_check.tcl`
3. 需要上板时再跑 `Generate Bitstream`
4. 下载到 Nexys A7 100T 验证

如果修改了 HDL 或 `.xdc`，必须重新生成 bitstream 后再下载。
