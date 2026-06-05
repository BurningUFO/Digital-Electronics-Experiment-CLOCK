# FINAL_DEMO_GUIDE

本文档给出 ClockLink Studio + Nexys A7 COMM 模式的最终演示流程。

## 1. 前置条件

- Vivado 工程入口：`clock_amd.xpr`。
- 顶层：`clock_amd.srcs/sources_1/new/clock_amd_top.v`。
- USB-UART：Nexys A7 J6，`UART_RXD=C4`、`UART_TXD=D4`，`115200 8N1`。
- PC 软件目录：`software/clocklink_studio/`。
- 第一版消息正文只支持 100 字符以内 ASCII。

当前验证边界：

- mock PC 软件、协议库、XSim 通信 testbench 已验证。
- `python -m pytest` 已通过，15 个测试全部通过。
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl` 已通过，最新综合时序 `WNS=+1.232ns`、`TNS=0.000ns`、失败端点 `0`。
- 尚未生成 bitstream，尚未完成真实 Nexys A7 板级 USB-UART 演示。

## 2. PC 软件启动

mock 模式：

```bash
cd software/clocklink_studio
python main.py --mock gui
```

真实串口模式：

```bash
cd software/clocklink_studio
python main.py --port COM5 gui
```

把 `COM5` 替换为 Windows 设备管理器中 Nexys A7 USB-UART 对应端口。

## 3. 板上模式切换

1. 下载 bitstream 后复位开发板。
2. 使用 `BTNR` 按顺序切换：

```text
CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM
```

3. COMM 模式下，数码管左四位应显示近似 `COMM`。
4. 右四位状态应显示 `DISC / WAIT / CONN / MSG! / ERR ` 之一。
5. OLED 应显示 ClockLink 通信页面，而不是普通状态主页。

## 4. 演示流程

1. PC 打开 ClockLink Studio。
2. 点击 `HELLO` 或运行：

```bash
python main.py --port COM5
```

3. 点击 `PING`，确认 PC 收到 `PONG`。
4. 点击 `SYNC`，或运行：

```bash
python main.py --port COM5 sync-time
```

5. 点击 `GET` 读取 FPGA 时间，确认返回 `TIME date=...;time=...;weekday=...`。
6. 在消息框输入 `Hello FPGA`，点击 `SEND`，确认 PC 收到 `MSG_STORED`。
7. 板上 COMM 模式应进入未读消息状态，数码管右四位显示 `MSG!`。
8. 打开 `SW0` 查看最新消息；`SW1` 查看上一条消息，以此类推。
9. 长消息用 `BTNU/BTND` 滚动正文。
10. 查看有效消息时按 `BTNC` 进入回复选择。
11. 用 `BTNU/BTND` 选择预设回复。
12. 按 `BTNR` 发送回复，PC 应收到 `REPLY` 帧并在日志中显示。
13. 在 GUI `Control` 页设置闹钟槽，例如 slot 0、`07:30:00`、enable。
14. 点击 `GET` 验证返回 `ALARM slot=0;time=07:30:00;enable=1`。
15. 设置日程槽，例如 slot 0、`08:00:00`、type 0、enable。
16. 点击 `GET` 验证返回 `SCHED slot=0;time=08:00:00;type=0;enable=1`。
17. 设置倒计时 `00:05:00`，点击 `SET`，再点击 `START`。
18. 点击 `STATUS` 验证 `COUNT_STATUS time=...;run=1`。
19. 使用 `BTNL/BTNR` 离开 COMM，回到原有 CLOCK/TIME/ALARM/HOUR/COUNT/SCHED 模式，确认原功能仍可进入和操作。

## 5. CLI 快速演示

```bash
python main.py --mock
python main.py --mock sync-time
python main.py --mock send-message "Hello FPGA"
python main.py --mock mock-reply --slot 0 --reply 1
python main.py --mock alarm-set --slot 0 --time 07:30:00 --enable 1
python main.py --mock alarm-get --slot 0
python main.py --mock sched-set --slot 0 --time 08:00:00 --type 0 --enable 1
python main.py --mock sched-get --slot 0
python main.py --mock count-set --time 00:05:00
python main.py --mock count-start
python main.py --mock count-status
```

## 6. 已知限制

- 真实串口异步 `REPLY/EVENT` 持续监听尚未完整实现；当前 GUI 以同步命令日志为主。
- FPGA `MSG_GET/MSG_DATA` 协议已冻结，但 Phase 5 后 FPGA 端为了资源收敛暂返回 `NACK/UNSUPPORTED`。
- FPGA `ALARM_DUMP/SCHED_DUMP` 保留为协议能力，当前 PC 应循环 `GET 0..7`。
- 日期自动跨天不自动递增年份，PC 可通过 `TIME_SET` 重新同步。
- 第一版不支持中文消息、换行和富文本。
