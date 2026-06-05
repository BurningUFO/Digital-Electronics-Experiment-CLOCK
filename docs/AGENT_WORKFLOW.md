# AGENT_WORKFLOW

本文档定义 ClockLink Studio + FPGA COMM 扩展项目的 agent 工作流。

## 总目标

在现有 `clock_amd` 多功能时钟工程中增加：

1. 第七个 `COMM` 通信模式，位于 `SCHED` 之后。
2. COMM 模式下数码管左四位显示 `COMM`，右四位显示连接状态。
3. COMM 模式下 OLED 显示通信专用页面。
4. PC 上位机通过 USB-UART 向 FPGA 发送 100 字符以内消息。
5. FPGA 保存最近 16 条消息，`SW0` 表示最新消息，低位优先。
6. OLED 显示消息时间戳和正文，支持 `BTNU / BTND` 滚动。
7. `BTNC` 在查看消息和回复消息之间切换。
8. 回复模式下 `BTNU / BTND` 选择预设回复，`BTNR` 发送。
9. PC 软件可以同步时间到 FPGA。
10. PC 软件可以可视化修改时间、闹钟、日程、倒计时等功能。

## 推荐阶段

### Phase 0：工程理解，不改功能

目标：

- 阅读现有 HDL 和文档。
- 生成 `docs/CODEBASE_MAP.md`。
- 不修改任何 HDL。
- 不修改 XDC。
- 不写 PC 软件。

验收：

- `CODEBASE_MAP.md` 包含顶层端口、模块连接、模式状态机、显示路径、闹钟日程倒计时接口、COMM 改造点。

### Phase 1：冻结 UART 协议

目标：

- 完善 `docs/UART_PROTOCOL.md`。
- 定义帧格式、命令表、ACK/NACK、错误码、校验、示例。
- 不修改 HDL。

验收：

- 协议覆盖 `HELLO`、`PING`、`TIME_SET`、`MSG_TX`、`REPLY`、`ALARM_SET`、`SCHED_SET`、`COUNT_SET`、`STATUS_GET`。
- PC agent 和 HDL agent 都能基于此文档并行工作。

### Phase 2：PC 协议库与 mock 板子

目标：

- 创建 `software/clocklink_studio/`。
- 实现协议编码解码。
- 实现 mock FPGA。
- 先不依赖真实串口。

验收：

- 可以在电脑上运行单元测试。
- 可以生成并解析主要命令。
- mock 板子能返回 `ACK / PONG / REPLY`。

### Phase 3：FPGA UART RX/TX

目标：

- 新增 `uart_rx.v`、`uart_tx.v`。
- 新增 testbench。
- 支持 115200 8N1。

验收：

- testbench 通过。
- Vivado 综合不报错。
- 暂不接入复杂协议和 OLED。

### Phase 4：COMM 模式骨架

目标：

- 增加 `MODE_COMM`。
- 修改模式顺序为 `CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM -> CLOCK`。
- COMM 模式数码管显示 `COMM DISC/CONN`。
- OLED 显示通信专用标题页。

验收：

- 原有 6 个模式可用。
- SCHED 后能进入 COMM。
- COMM 后能回到 CLOCK。
- COMM 显示不复用普通主页。

### Phase 5：消息接收与 16 条缓存

目标：

- 实现 `MSG_TX` 接收。
- 保存最近 16 条消息。
- `SW0-SW15` 查看消息，低位优先。
- OLED 显示时间戳和正文。
- `BTNU / BTND` 滚动长消息。

验收：

- PC 连续发 3 条消息。
- `SW0` 显示第 3 条，`SW1` 显示第 2 条，`SW2` 显示第 1 条。
- 新消息触发未读提示。

### Phase 6：预设回复

目标：

- 实现预设回复 ROM。
- `BTNC` 在查看消息和回复模式之间切换。
- 回复模式下 `BTNU / BTND` 选择。
- `BTNR` 发送 `REPLY` 到 PC。

验收：

- PC 能收到 FPGA 回复。
- 软件日志能显示回复内容和时间。

### Phase 7：时间同步

目标：

- PC 发送 `TIME_SET`。
- FPGA 直接加载日期时间。
- 不使用模拟按键方式。

验收：

- PC 一键同步后，FPGA 时间立即更新。
- `TIME_GET` 能返回当前时间。

### Phase 8：闹钟、日程、倒计时可视化控制

目标：

- PC GUI 可读写闹钟槽。
- PC GUI 可读写日程槽。
- PC GUI 可设置倒计时并启动停止。

验收：

- GUI 修改后 FPGA 对应功能生效。
- 原有按键设置方式不退化。

### Phase 9：GUI 完整化与演示流程

目标：

- 完成图形界面。
- 完成 README。
- 完成演示脚本。
- 清理临时代码。

验收：

- 能完成完整演示链路：连接、同步时间、发送消息、SW 查看、预设回复、修改闹钟日程。

## 每次任务结束必须更新

每次 agent 完成任务后，必须更新：

- `docs/AGENT_WORKLOG.md`
- 如涉及协议，更新 `docs/UART_PROTOCOL.md`
- 如涉及工程结构，更新 `docs/CODEBASE_MAP.md`
- 如涉及 FPGA 改造，更新 `docs/COMM_MODE_FPGA_PLAN.md`
- 如涉及软件，更新 `software/clocklink_studio/README.md`

## 建议检查命令

基础检查：

```bash
git status
git diff --check
```

Python 软件检查：

```bash
cd software/clocklink_studio
python -m pytest
```

Vivado 综合检查：

```bash
vivado -mode batch -source scripts/run_phase_synth_check.tcl
```

如果某个命令无法运行，必须在 `docs/AGENT_WORKLOG.md` 记录原因。
