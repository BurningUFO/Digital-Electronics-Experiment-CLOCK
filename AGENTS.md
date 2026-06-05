# AGENTS.md

本仓库是 Nexys A7 Vivado 多功能时钟工程 `clock_amd`。

当前目标是在原有 `CLOCK / TIME / ALARM / HOUR / COUNT / SCHED` 功能基础上，扩展一个基于 USB-UART 的 PC 上位机通信系统 ClockLink Studio。

## 必须先读

每次开始任务前，必须先阅读：

1. `README.md`
2. `HANDOFF.md`
3. `docs/工程模块使用说明.md`
4. `docs/ClockLink_Studio_PC_Software_Design.md`
5. `docs/AGENT_WORKFLOW.md`
6. `docs/AGENT_TASKS.md`
7. `docs/AGENT_WORKLOG.md`
8. 当前任务涉及的 HDL / Python 源码

## 可修改范围

可以修改：

- `clock_amd.srcs/sources_1/new/`
- `clock_amd.srcs/constrs_1/new/clock_amd.xdc`
- `docs/`
- `scripts/`
- `software/`
- `sim/`
- `HANDOFF.md`
- `README.md`

不要主动修改 Vivado 生成目录：

- `.Xil/`
- `clock_amd.cache/`
- `clock_amd.hw/`
- `clock_amd.runs/`
- `clock_amd.sim/`

## 开发原则

1. 每次只做一个 Phase，不要一次性完成全部功能。
2. 修改前先理解现有模块接口，不要凭空重构。
3. 新增命令必须先写入 `docs/UART_PROTOCOL.md`。
4. 新增 HDL 模块后必须说明如何加入 Vivado 工程。
5. 修改顶层端口时必须同步检查 `clock_amd.xdc`。
6. 修改 UI 模式时必须保证原有 6 个模式不退化。
7. PC 软件必须先支持 mock 模式，再接真实串口。
8. 每次任务结束必须更新 `docs/AGENT_WORKLOG.md`。
9. 每次任务结束必须列出修改文件、验证命令、是否通过、已知问题和下一步。

## 禁止事项

1. 不要删除原有功能。
2. 不要把 Vivado 生成目录加入源码管理。
3. 不要大范围重构无关模块。
4. 不要绕过协议文档临时新增通信命令。
5. 不要通过“模拟按键加很多次”的方式实现 PC 同步时间、闹钟、日程，应新增直接写入接口。
