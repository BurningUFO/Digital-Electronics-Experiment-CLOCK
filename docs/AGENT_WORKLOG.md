# AGENT_WORKLOG

本文件用于记录 agent 每次工作的阶段、修改内容、验证结果和下一步计划。

## 当前状态

- 当前阶段：Phase 9 显示/UI 资源与时序优化已完成首轮
- 当前目标：等待生成 bitstream 和 Nexys A7 板级 USB-UART/COMM 实测
- 设计文档状态：原始 `docs/ClockLink_Studio_PC_Software_Design.md` 缺失，已在 Phase 0 按任务要求重建为基线草案

## 工作记录模板

### YYYY-MM-DD HHMM - Phase X - 标题

本次目标：

完成内容：

修改文件：

新增文件：

运行检查：

检查结果：

已知问题：

下一步建议：

是否需要人工确认：

### 2026-06-05 1503 - Phase 0 - 工程理解与代码地图

本次目标：

- 执行基础检查。
- 阅读必读文档、现有协作文件和关键 HDL。
- 补齐 `docs/CODEBASE_MAP.md`。
- 记录缺失设计文档和当前风险。

完成内容：

- 已运行 `pwd`、`git status` 和前三层文件枚举；PowerShell 首次模拟 `find` 时路径拆分转义错误，随后用 `Get-ChildItem -File -Recurse -Depth 2` 完成等价检查。
- 已确认关键 HDL、XDC、Vivado 工程文件存在。
- 已确认 `docs/ClockLink_Studio_PC_Software_Design.md` 原始文件缺失。
- 已切换到新分支 `feature/clocklink-uart-comm`。
- 已阅读 `README.md`、`HANDOFF.md`、`docs/工程模块使用说明.md`、`AGENTS.md`、`docs/AGENT_WORKFLOW.md`、`docs/AGENT_TASKS.md`、`docs/AGENT_WORKLOG.md`、关键 HDL 和 XDC。
- 已补全工程结构、模式状态机、显示路径、模块接口、COMM/UART 接入点和风险建议。
- 已按任务要求和现有 workflow 重建 PC 软件设计基线草案。

修改文件：

- `docs/CODEBASE_MAP.md`
- `docs/AGENT_WORKLOG.md`

新增文件：

- `docs/ClockLink_Studio_PC_Software_Design.md`

删除文件：

- 无

运行检查：

- `pwd`
- `git status`
- `Get-ChildItem -File -Recurse -Depth 2 | Resolve-Path -Relative | Sort-Object | Select-Object -First 200`
- 关键文件存在性检查

检查结果：

- 工作区已有用户/历史未提交改动，未回退。
- 关键 HDL 文件均存在。
- `docs/ClockLink_Studio_PC_Software_Design.md` 原始文件缺失，已重建为草案并在本文档记录。

已知问题：

- 原始 PC 软件总体设计文档缺失；如后续找回，需与当前草案对照合并。
- 当前 `CODEBASE_MAP.md` 是基于静态阅读，尚未跑 Vivado 验证。

下一步建议：

- 进入 Phase 1，冻结 UART 协议，先完善命令表、payload、校验、ACK/NACK、错误码和示例。

是否需要人工确认：

- 不需要；缺失非关键文档已记录并重建基线，可继续。

### 2026-06-05 1503 - Phase 1 - UART 协议冻结

本次目标：

- 完善 `docs/UART_PROTOCOL.md`。
- 固定帧格式、校验、payload 编码、序号、ACK/NACK、错误码、命令表和示例。
- 不修改 HDL、XDC 或 PC 软件代码。

完成内容：

- 冻结 UART 参数为 `115200, 8N1`。
- 固定帧格式为 `#SEQ|CMD|PAYLOAD*CS\n`。
- 固定 `CS` 为 BODY，即 `SEQ|CMD|PAYLOAD` 的逐字节 XOR，两位大写 HEX。
- 固定 payload 为 `key=value;key=value`，消息正文使用 HEX，单条消息解码后不超过 100 ASCII 字符。
- 定义 PC 到 FPGA 命令表和 FPGA 到 PC 回复/事件表。
- 定义 `ACK/NACK`、错误码、PC 重发策略、FPGA 重复帧建议。
- 增加示例帧，并用 PowerShell 计算示例校验值。
- 增加 FPGA 解析状态机建议和 PC command queue 建议。

修改文件：

- `docs/UART_PROTOCOL.md`
- `docs/AGENT_WORKLOG.md`

新增文件：

- 无

删除文件：

- 无

运行检查：

- `PowerShell` 示例校验计算

检查结果：

- 示例 `HELLO/PING/TIME_SET/MSG_TX/MSG_STORED/ACK/NACK` 校验值已计算并写入协议文档。

已知问题：

- 本阶段未跑 HDL/PC 测试，因为只改协议文档。
- `MSG_CLEAR` 第一版清除语义在协议中保留为“清除未读标记或清空消息”，Phase 5 实现时需在文档中进一步收窄。

下一步建议：

- 进入 Phase 2，按协议实现 Python `FrameCodec`、command builders、mock transport、CLI demo 和 pytest。

是否需要人工确认：

- 不需要；协议已覆盖任务要求命令，可进入 Phase 2。

### 2026-06-05 1514 - Phase 2 - PC 协议库与 mock 模式

本次目标：

- 创建 `software/clocklink_studio/` Python 项目骨架。
- 实现协议 encode/decode、XOR 校验、command builders、mock FPGA、CLI demo 和 pytest。
- 保持 HDL/XDC 不变。

完成内容：

- 新增 `protocol/`：`Frame`、checksum、帧编解码、payload 解析、ASCII 消息 HEX 编码和命令构造。
- 新增 `transport/`：mock transport 和 serial transport。serial transport 依赖 `pyserial`，尚未接真实 FPGA 实测。
- 新增 `services/`：时间、消息、闹钟、日程、倒计时服务封装。
- 新增 `ui/main_window.py`：Tkinter GUI 骨架。
- 新增 `main.py`：CLI 支持 mock demo、ping、status、sync-time、send-message、alarm-set、sched-set、count-set/start/stop/status。
- 新增 pytest 单元测试：codec、commands、mock transport。
- 更新 `software/clocklink_studio/README.md`。

修改文件：

- `software/clocklink_studio/README.md`
- `docs/AGENT_WORKLOG.md`

新增文件：

- `software/clocklink_studio/requirements.txt`
- `software/clocklink_studio/main.py`
- `software/clocklink_studio/protocol/__init__.py`
- `software/clocklink_studio/protocol/checksum.py`
- `software/clocklink_studio/protocol/frame.py`
- `software/clocklink_studio/protocol/codec.py`
- `software/clocklink_studio/protocol/commands.py`
- `software/clocklink_studio/transport/__init__.py`
- `software/clocklink_studio/transport/base.py`
- `software/clocklink_studio/transport/mock_transport.py`
- `software/clocklink_studio/transport/serial_transport.py`
- `software/clocklink_studio/services/__init__.py`
- `software/clocklink_studio/services/client.py`
- `software/clocklink_studio/services/time_service.py`
- `software/clocklink_studio/services/message_service.py`
- `software/clocklink_studio/services/alarm_service.py`
- `software/clocklink_studio/services/schedule_service.py`
- `software/clocklink_studio/services/countdown_service.py`
- `software/clocklink_studio/ui/__init__.py`
- `software/clocklink_studio/ui/main_window.py`
- `software/clocklink_studio/tests/test_codec.py`
- `software/clocklink_studio/tests/test_commands.py`
- `software/clocklink_studio/tests/test_mock_transport.py`

删除文件：

- 无

运行检查：

- `python -m pytest`
- `python main.py --mock`
- `python main.py --mock send-message "Hello FPGA"`
- `python main.py --mock sync-time`
- `python main.py --mock alarm-set --slot 0 --time 07:30:00 --enable 1`
- `python main.py --mock count-set --time 00:05:00`

检查结果：

- 初次运行 `python -m pytest` 失败，原因是环境缺少 `pytest`。
- 已按 `requirements.txt` 安装 `pytest` 和 `pyserial`。
- 重新运行 `python -m pytest`：12 个测试全部通过。
- `python main.py --mock` 通过，输出 `HELLO/ACK`、`PING/PONG`、`STATUS`。
- `send-message` 通过，mock 返回 `MSG_STORED` 并可读回 slot0。
- `sync-time`、`alarm-set`、`count-set` mock 命令通过。
- 一次 `count-set` 并行运行时出现 Windows sandbox setup refresh 失败，重跑同一命令通过，判定为执行环境瞬时问题。

已知问题：

- serial transport 尚未接真实 FPGA 实测。
- GUI 目前是骨架，完整可视化控制留到 Phase 9。
- `ALARM_DUMP/SCHED_DUMP` mock 目前只返回首槽，占位满足接口；完整多帧 dump 后续增强。

下一步建议：

- 进入 Phase 3，新增 `uart_rx.v`、`uart_tx.v` 和 `sim/comm` testbench，并同步综合脚本。

是否需要人工确认：

- 不需要；Phase 2 mock 可运行并通过测试。

### 2026-06-05 1526 - Phase 3 - FPGA UART RX/TX 与仿真

本次目标：

- 新增独立 UART RX/TX 模块。
- 支持 100 MHz 主时钟、115200 8N1，并通过参数化支持其他时钟/波特率。
- 新增通信 testbench。
- 暂不接入 `clock.v`、OLED、协议解析和消息缓存。

完成内容：

- 新增 `uart_rx.v`：双触发同步 RX 输入，检测 start bit，按位采样 8 数据位和 stop bit，输出 `rx_valid/rx_data/rx_busy`。
- 新增 `uart_tx.v`：发送 start bit、8 数据位、stop bit，输出 `tx_busy/tx_done`。
- 新增 `tb_uart_rx.v`：模拟发送单字节 `8'hA5`，检查 RX 输出。
- 新增 `tb_uart_tx.v`：启动发送单字节 `8'hA5`，逐 bit 检查 TX 线。
- 更新 `sim/comm/README.md`，说明 testbench 和如何把新增 HDL 加入 Vivado 工程。
- 更新 `scripts/run_phase_synth_check.tcl`，把 `uart_rx.v`、`uart_tx.v` 纳入 read_verilog 检查。

修改文件：

- `scripts/run_phase_synth_check.tcl`
- `sim/comm/README.md`
- `docs/AGENT_WORKLOG.md`

新增文件：

- `clock_amd.srcs/sources_1/new/uart_rx.v`
- `clock_amd.srcs/sources_1/new/uart_tx.v`
- `sim/comm/tb_uart_rx.v`
- `sim/comm/tb_uart_tx.v`

删除文件：

- 无

运行检查：

- `xvlog clock_amd.srcs/sources_1/new/uart_rx.v sim/comm/tb_uart_rx.v`
- `xelab tb_uart_rx -s tb_uart_rx_sim`
- `xsim tb_uart_rx_sim -runall`
- `xvlog clock_amd.srcs/sources_1/new/uart_tx.v sim/comm/tb_uart_tx.v`
- `xelab tb_uart_tx -s tb_uart_tx_sim`
- `xsim tb_uart_tx_sim -runall`
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`

检查结果：

- 初次 RX `xelab` 失败，原因是 UART DUT 无 `timescale` 而 testbench 有 `timescale`；已给 `uart_rx.v` 和 `uart_tx.v` 补 `timescale 1ns / 1ps` 后重跑通过。
- 初次 RX `xsim` 超时，原因是 testbench 在发送完成后才等待单周期 `rx_valid`，可能错过脉冲；已改为时钟沿捕获 `rx_valid` 标志后重跑通过。
- `tb_uart_rx` 输出 `PASS tb_uart_rx`。
- `tb_uart_tx` 输出 `PASS tb_uart_tx`。
- Vivado 综合脚本通过；timing summary：`WNS=1.409ns`，`TNS=0.000ns`，失败端点 `0`，并显示 `All user specified timing constraints are met.`

已知问题：

- UART 模块尚未加入 `clock.v` 功能路径，Phase 4/5 才接入顶层和协议层。
- XSim 运行生成了 `xsim*.log/jou` 等未跟踪工具日志，后续不要加入源码管理。
- 当前 UART 使用整数分频 `CLK_FREQ / BAUD_RATE`，115200 下为 868 个 100 MHz 周期，误差在可接受范围内。

下一步建议：

- 进入 Phase 4，新增 `MODE_COMM`、数码管 `COMM DISC` 骨架、OLED COMM 标题页、顶层 UART 端口和 XDC 约束。

是否需要人工确认：

- 不需要；Phase 3 UART 基础模块已通过仿真和综合检查。

### 2026-06-05 1539 - Phase 4 - COMM 模式骨架

本次目标：

- 增加 `MODE_COMM`。
- 修改模式顺序为 `CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM -> CLOCK`。
- COMM 模式数码管显示 `COMM DISC/WAIT/CONN/MSG!/ERR ` 状态。
- COMM 模式 OLED 显示通信专用标题页。
- 顶层接出 Nexys A7 J6 USB-UART 端口。
- 暂不实现消息缓存、回复、时间同步或协议解析。

完成内容：

- `ui_ctrl.v` 新增 `MODE_COMM = 3'b110`，SCHED 后进入 COMM，COMM 后回到 CLOCK；COMM 下强制 `setting_active=0`，为后续 `SW0-SW15` 消息选择预留。
- `seg_7.v` 增加 `M/I/G/W/!` 等近似字符译码，支持 COMM 和状态文本。
- `display_ctrl.v` 增加 `comm_status` 输入，COMM 模式下左四位显示 `COMM`，右四位按状态显示 `DISC/WAIT/CONN/MSG!/ERR `。
- `clock.v` 增加 `uart_rx/uart_tx/comm_status` 接口；当前 `UART_TXD` 保持 idle 高电平，`comm_status` 固定为 `DISC`，协议接入留到 Phase 5。
- `clock_amd_top.v` 增加 `UART_RXD/UART_TXD` 顶层端口，并把 `comm_status` 传给 OLED。
- `oled_ui_display.v` 增加 COMM 专用页面，显示 `CLOCKLINK`、`USB UART`、`COMM`、状态和 `NO MSG`；提醒弹窗仍保持覆盖优先级。
- `clock_amd.xdc` 增加 J6 USB-UART 约束：`UART_RXD=C4`、`UART_TXD=D4`，`LVCMOS33`。
- `docs/COMM_MODE_FPGA_PLAN.md` 更新 Phase 4 状态、状态编码、接线、验证重点和 Phase 5 接入计划。

修改文件：

- `clock_amd.srcs/sources_1/new/ui_ctrl.v`
- `clock_amd.srcs/sources_1/new/seg_7.v`
- `clock_amd.srcs/sources_1/new/display_ctrl.v`
- `clock_amd.srcs/sources_1/new/clock.v`
- `clock_amd.srcs/sources_1/new/clock_amd_top.v`
- `clock_amd.srcs/sources_1/new/oled_ui_display.v`
- `clock_amd.srcs/constrs_1/new/clock_amd.xdc`
- `docs/COMM_MODE_FPGA_PLAN.md`
- `docs/AGENT_WORKLOG.md`

新增文件：

- 无

删除文件：

- 无

运行检查：

- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`
- `git diff --check`
- `git status -sb`

检查结果：

- Vivado 综合检查通过。
- Timing summary：`WNS=0.344ns`，`TNS=0.000ns`，失败端点 `0`，并显示 `All user specified timing constraints are met.`。
- Vivado 报告 `uart_rx` 暂无负载，符合 Phase 4 骨架状态；Phase 5 接入协议解析后应消除。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换警告。
- `git status -sb` 显示工作区存在历史/用户未提交改动和工具日志，未回退无关改动。

已知问题：

- `UART_RXD` 尚未解析，`UART_TXD` 仅保持 idle 高电平。
- COMM 状态当前固定为 `DISC`。
- OLED COMM 页面尚未显示真实消息内容。
- 新增顶层 UART 端口后需要在 Vivado 工程中确认端口和 XDC 约束匹配，当前已通过综合脚本静态检查，尚未板测。

下一步建议：

- 进入 Phase 5，新增 `protocol_parser.v`、`protocol_builder.v`、`comm_ctrl.v`、`message_store.v` 和 COMM 消息 OLED 数据路径，接入 `MSG_TX`、16 条缓存、SW 选择、滚动和 `MSG_STORED` 回复。

是否需要人工确认：

- 不需要；Phase 4 骨架已综合通过，可继续 Phase 5。

### 2026-06-05 1635 - Phase 5 - 协议解析与消息缓存

本次目标：

- 接入 UART 字节流到通信控制层。
- 解析 PC 的 `MSG_TX`，保存最近 16 条消息。
- 新消息进入 slot0，旧消息后移。
- `SW0-SW15` 低位优先选择消息。
- OLED 显示消息时间戳和正文，`BTNU/BTND` 滚动。
- 成功接收消息后通过 UART 返回 `MSG_STORED`。

完成内容：

- 新增 `protocol_parser.v`：解析 `HELLO/PING/STATUS_GET/MSG_TX/MSG_CLEAR`，校验 `#SEQ|CMD|PAYLOAD*CS\n`，对暂未实现命令返回 `NACK/UNSUPPORTED`。
- 新增 `protocol_builder.v`：构造 `ACK/PONG/STATUS/MSG_STORED/NACK`，修复 TX builder 与 `uart_tx` 的寄存握手，避免隔字节发送。
- 新增 `message_store.v`：保存 16 条消息，每条含 19 字符时间戳、100 字符 ASCII 正文、长度、valid/unread。
- 新增 `comm_ctrl.v`：连接 UART RX/TX、parser、builder、message store、COMM 状态、SW 选择和滚动控制。
- 修改 `clock.v`：接入 `comm_ctrl`，把 COMM 消息显示数据输出到顶层。
- 修改 `clock_amd_top.v`：把 COMM 消息显示数据传给 OLED。
- 修改 `oled_ui_display.v`：COMM 有消息时显示 `[YYYY-MM-DD]`、`[HH:MM:SS]` 和四行正文窗口；无消息时保留 Phase 4 标题页。
- 新增 `tb_comm_ctrl_msg.v`：通过 UART 输入 `MSG_TX Hello`，检查 slot0 缓存和 `MSG_STORED` 响应。
- 更新 `scripts/run_phase_synth_check.tcl`、`sim/comm/README.md`、`docs/UART_PROTOCOL.md`、`docs/COMM_MODE_FPGA_PLAN.md`。

修改文件：

- `clock_amd.srcs/sources_1/new/clock.v`
- `clock_amd.srcs/sources_1/new/clock_amd_top.v`
- `clock_amd.srcs/sources_1/new/oled_ui_display.v`
- `scripts/run_phase_synth_check.tcl`
- `sim/comm/README.md`
- `docs/UART_PROTOCOL.md`
- `docs/COMM_MODE_FPGA_PLAN.md`
- `docs/AGENT_WORKLOG.md`

新增文件：

- `clock_amd.srcs/sources_1/new/protocol_parser.v`
- `clock_amd.srcs/sources_1/new/protocol_builder.v`
- `clock_amd.srcs/sources_1/new/message_store.v`
- `clock_amd.srcs/sources_1/new/comm_ctrl.v`
- `sim/comm/tb_comm_ctrl_msg.v`

删除文件：

- 无

运行检查：

- `xvlog` Phase 5 通信模块和 `tb_comm_ctrl_msg.v`
- `xelab tb_comm_ctrl_msg -s tb_comm_ctrl_msg_sim`
- `xsim tb_comm_ctrl_msg_sim -runall`
- `xvlog` 全源语法检查
- `xelab clock_amd_top -s clock_amd_top_elab`
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`

检查结果：

- `xvlog` Phase 5 通信模块通过。
- `tb_comm_ctrl_msg` 通过，输出 `PASS tb_comm_ctrl_msg`。
- 全源 `xvlog` 通过。
- 顶层 `xelab` 失败，原因是旧有多个模块缺少 `timescale`，而新增 UART/COMM/testbench 模块带 `timescale`；这是 XSim 一致性检查问题，不是端口连接错误。
- Vivado 综合脚本分别以 5 分钟、10 分钟、再次 5 分钟预算运行，均未返回；已停止后台 Vivado 进程。
- Vivado 日志显示 RTL 展开阶段峰值内存约 8.3GB，存在大量宽 mux，综合资源/时间未收敛。

已知问题：

- `MSG_GET/MSG_DATA` 已在协议中保留，但 FPGA Phase 5 暂返回 `NACK/UNSUPPORTED`，需要后续改成流式读缓存和流式构帧。
- 当前 COMM 消息显示/缓存功能通过仿真，但未通过顶层综合验收，不能继续堆 Phase 6 功能。
- `protocol_parser` 仍有 `body_mem` 综合警告；后续应改为更彻底的命令流式解析。
- OLED 和构帧不应继续传递/消费 800-bit 正文宽总线，后续需改为字符读口。

下一步建议：

- 先做 Phase 5b 资源收敛：BRAM/分时消息读口、OLED 16 字符窗口读口、流式 `MSG_DATA` 构帧、协议 parser 流式化。
- 收敛后重新运行 `vivado -mode batch -source scripts/run_phase_synth_check.tcl`，综合通过后再进入 Phase 6 预设回复。

是否需要人工确认：

- 当前不需要功能方向确认；但后续阶段必须先解决综合收敛问题。

### 2026-06-05 1729 - Phase 5b - COMM 消息路径资源与时序收敛

本次目标：

- 接续 Phase 5，先解决 Vivado 综合资源/时序问题。
- 不进入 Phase 6，不新增预设回复功能。
- 保持 `MSG_TX`、16 条消息缓存、SW 选择、OLED 消息显示和 `MSG_STORED` 回复行为不退化。

完成内容：

- 重新阅读必读文档、Phase 5 工作记录、`COMM_MODE_FPGA_PLAN.md` 和相关 HDL。
- 确认最新综合 violation 来自 `u_oled_ui_display/step_index -> ll_cmd_data` 的 OLED page data 字模组合路径。
- 在 `oled_ui_display.v` 的 `ST_PAGE_DATA` 中加入 `COL -> RENDER -> SEND` 三步流水：
  - 先寄存当前 page/column/edit。
  - 再寄存 `page_data(...)` 生成的 OLED 数据字节。
  - 最后把寄存后的数据字节发送给底层 I2C command。
- 保持 COMM 页面内容、提醒覆盖优先级和 I2C 命令顺序不变；代价是每个 OLED 数据字节多 2 个 100 MHz 周期，远小于 I2C 字节传输时间。

修改文件：

- `clock_amd.srcs/sources_1/new/oled_ui_display.v`
- `docs/AGENT_WORKLOG.md`
- `docs/COMM_MODE_FPGA_PLAN.md`
- `sim/comm/README.md`

新增文件：

- 无

删除文件：

- 无

运行检查：

- `$files = Get-ChildItem -LiteralPath clock_amd.srcs/sources_1/new -Filter *.v | Sort-Object Name | ForEach-Object { $_.FullName }; xvlog @files`
- `xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_msg.v`
- `xelab tb_comm_ctrl_msg -s tb_comm_ctrl_msg_sim`
- `xsim tb_comm_ctrl_msg_sim -runall`
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`
- `rg -n "Timing constraints are not met|All user specified timing constraints are met|Slack \(VIOLATED\)|Slack \(MET\)|WNS|TNS|msg_char_buf_reg\[0\]" vivado.log`

检查结果：

- 全源 `xvlog` 通过。
- Phase 5 通信模块 `xvlog` 通过。
- `tb_comm_ctrl_msg` 展开通过。
- `xsim tb_comm_ctrl_msg_sim -runall` 通过，输出 `PASS tb_comm_ctrl_msg`。
- Vivado 综合检查完成，用时约 4 分 31 秒；timing summary：`WNS=+1.345ns`、`TNS=0.000ns`、失败端点 `0`，日志显示 `All user specified timing constraints are met.`。
- OLED worst path 变为 `page_data_col/page_data_byte` 相关寄存器，最差路径 `Slack (MET): +1.345ns`。

已知问题：

- Vivado 仍提示 `protocol_parser.v:365` 中 `msg_char_buf_reg[0..99]` 有同优先级 set/reset 警告；当前仿真通过，综合 timing clean，但后续进入更多协议功能前建议改写本地消息暂存方式以消除 warning。
- `MSG_GET/MSG_DATA` 协议仍保留但 FPGA Phase 5 暂返回 `NACK/UNSUPPORTED`。
- 本阶段只做综合和仿真检查，尚未生成 bitstream，尚未板级实测 USB-UART。
- Vivado 进程结束时 stdout 曾出现 `ERROR: [Common 17-354] Could not open 'C' for writing.`，`vivado.log` 中 timing 报告完整且命令退出码为 0；按工具日志写入问题记录，不作为 timing 失败。

下一步建议：

- 可以进入 Phase 6 预设回复：新增固定回复 ROM、COMM 查看/回复状态切换、`BTNU/BTND` 选择、`BTNR` 发送 `REPLY`，并同步 PC mock/CLI 日志显示。
- Phase 6 后必须重新运行 `tb_comm_ctrl_msg` 或新增回复 testbench，并再次运行 Vivado 综合 timing。

是否需要人工确认：

- 不需要；Phase 5b 前置阻塞已解除。

建议提交信息：

- `fix(fpga): pipeline OLED COMM page rendering path`

### 2026-06-05 1935 - Phase 6 - 预设回复

Phase:

- Phase 6：预设回复

完成内容:

- 新增固定预设回复 ROM，包含 8 条 ASCII 回复。
- `comm_ctrl.v` 增加回复模式、回复索引、BTNC 查看/回复切换、BTNU/BTND 选择、BTNR 发送。
- FPGA 发送 `REPLY` 帧，payload 为 `slot=0..15;reply=0..7;ts=YYYY-MM-DDTHH:MM:SS;text=HEX`。
- `protocol_builder.v` 增加 `RESP_REPLY`，并增加一拍本地请求锁存和 `ST_BUILD`，修复初版 Phase 6 构帧路径的 timing violation。
- `ui_ctrl.v` 增加 `mode_nav_lock`，COMM 回复模式下锁住左右模式切换，避免 BTNR 发送回复时同时切换模式。
- `oled_ui_display.v` 增加回复模式页面，显示 `REPLY MODE`、`R0..R7`、当前回复文本和消息时间。
- PC mock 增加 FPGA 主动 `REPLY` 事件生成；CLI 增加 `mock-reply`，可打印 HEX 解码后的回复正文。
- 新增 `tb_comm_ctrl_reply.v`，验证从消息接收、进入回复模式、选择 `Busy now.` 到 UART 发送 `REPLY` 的完整路径。
- 更新通信协议、FPGA 计划、仿真说明和 PC 软件 README。

修改文件:

- `clock_amd.srcs/sources_1/new/comm_ctrl.v`
- `clock_amd.srcs/sources_1/new/protocol_builder.v`
- `clock_amd.srcs/sources_1/new/oled_ui_display.v`
- `clock_amd.srcs/sources_1/new/ui_ctrl.v`
- `clock_amd.srcs/sources_1/new/clock.v`
- `clock_amd.srcs/sources_1/new/clock_amd_top.v`
- `scripts/run_phase_synth_check.tcl`
- `sim/comm/tb_comm_ctrl_msg.v`
- `sim/comm/README.md`
- `software/clocklink_studio/main.py`
- `software/clocklink_studio/transport/mock_transport.py`
- `software/clocklink_studio/tests/test_mock_transport.py`
- `software/clocklink_studio/README.md`
- `docs/UART_PROTOCOL.md`
- `docs/COMM_MODE_FPGA_PLAN.md`
- `docs/AGENT_WORKLOG.md`

新增文件:

- `clock_amd.srcs/sources_1/new/preset_reply_rom.v`
- `sim/comm/tb_comm_ctrl_reply.v`

删除文件:

- 无

运行检查:

- `xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/preset_reply_rom.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_reply.v`
- `xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/preset_reply_rom.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_msg.v`
- `xelab tb_comm_ctrl_msg -s tb_comm_ctrl_msg_sim`
- `xsim tb_comm_ctrl_msg_sim -runall`
- `xelab tb_comm_ctrl_reply -s tb_comm_ctrl_reply_sim`
- `xsim tb_comm_ctrl_reply_sim -runall`
- `$files = Get-ChildItem -LiteralPath clock_amd.srcs/sources_1/new -Filter *.v | Sort-Object Name | ForEach-Object { $_.FullName }; xvlog @files`
- `cd software/clocklink_studio; python -m pytest`
- `cd software/clocklink_studio; python main.py --mock mock-reply --slot 0 --reply 1`
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`
- `rg -n "Timing constraints are not met|All user specified timing constraints are met|WNS\(ns\)|Slack \(VIOLATED\)|Slack \(MET\)|msg_char_buf_reg\[0\]|Could not open 'C'" vivado.log`
- `git diff --check`
- `git status -sb`

检查结果:

- `tb_comm_ctrl_msg` 通过，输出 `PASS tb_comm_ctrl_msg`，确认 Phase 5 消息接收和 `MSG_STORED` 未退化。
- `tb_comm_ctrl_reply` 通过，输出 `PASS tb_comm_ctrl_reply`，捕获 `#F0|REPLY|slot=0;reply=1;ts=2026-06-05T15:03:00;text=42757379206E6F772E*5C`。
- 全源 `xvlog` 通过。
- `python -m pytest` 通过，13 个测试全部通过。
- `python main.py --mock mock-reply --slot 0 --reply 1` 通过，输出 `reply-text: Busy now.`。
- 初次 Phase 6 Vivado 综合完成但 timing 失败，`WNS=-0.084ns`，路径在 `protocol_builder` 一拍构造 REPLY 宽帧。
- 已修复为本地请求锁存 + `ST_BUILD` 后重跑 Vivado 综合，最终 `WNS=+0.092ns`、`TNS=0.000ns`、失败端点 `0`，日志显示 `All user specified timing constraints are met.`。
- `git diff --check` 未发现空白错误，只输出 Git CRLF 转换警告。
- `git status -sb` 显示工作区仍有大量历史/用户未提交改动和工具日志，未回退、未清理。

未完成/阻塞:

- 无硬性阻塞，可进入 Phase 7。
- 真实串口异步事件监听尚未完整实现；Phase 6 PC 侧已用 mock `REPLY` 事件覆盖日志显示路径。
- 尚未生成 bitstream，尚未上板实测 USB-UART 预设回复。

风险:

- Phase 6 当前 `REPLY.ts` 使用被回复消息的原始时间戳，不是回复发送时刻；Phase 7 时间同步后建议改为 FPGA 当前时间或新增协议字段。
- OLED 回复文本和 `preset_reply_rom.v` 当前有两份固定文本映射，后续可统一为单一字符读口减少维护风险。
- `protocol_parser.v:365` 仍有 `msg_char_buf_reg[0..99]` 同优先级 set/reset 综合 warning；当前仿真和综合 timing 通过，后续扩展协议前建议改写。

下一阶段计划:

- 进入 Phase 7：给 `time_core.v`、`date_core.v`、`clock.v`、`comm_ctrl.v` 和 PC 软件接入 `TIME_SET/TIME_GET/TIME`，使用直接写入接口，不模拟按键。

建议提交信息:

- `feat(fpga): add COMM preset replies over UART`
- `feat(pc): add mock reply event for ClockLink`

### 2026-06-05 2005 - Phase 7 - 时间同步

Phase:

- Phase 7：时间同步

完成内容:

- `time_core.v` 增加 PC 直接时间加载端口，`pc_time_load_valid` 优先于按键编辑和自动走时。
- `date_core.v` 增加 PC 直接日期加载端口和 4 位年份 BCD 保存/输出。
- `clock.v` 将 `comm_ctrl` 的时间/日期加载脉冲接入 `time_core/date_core`，并把当前日期时间反馈给 `comm_ctrl` 用于 `TIME_GET`。
- `protocol_parser.v` 接入 `TIME_SET/TIME_GET` 固定顺序 payload 解析：`date=YYYY-MM-DD;time=HH:MM:SS;weekday=N`。
- `protocol_builder.v` 增加 `RESP_TIME`、`ACK_TIME_SET` 和 `BAD_TIME` 错误名映射。
- `comm_ctrl.v` 对合法 `TIME_SET` 输出一拍 `pc_time_load_valid/pc_date_load_valid` 并返回 `ACK cmd=TIME_SET`；对 `TIME_GET` 返回 `TIME`。
- `comm_ctrl.v` 将 TX busy 检查提前，避免返回 `TX_BUSY` 时仍修改板上时间。
- PC 软件测试增加 `TIME_SET` payload 顺序断言，保护 FPGA 第一版固定顺序解析器。
- 新增 `tb_comm_ctrl_time.v`，覆盖合法同步、查询、非法月份、非法日期和非法 weekday 错误。
- 更新协议、FPGA 计划、代码地图、仿真说明和 PC README。

修改文件:

- `clock_amd.srcs/sources_1/new/time_core.v`
- `clock_amd.srcs/sources_1/new/date_core.v`
- `clock_amd.srcs/sources_1/new/protocol_parser.v`
- `clock_amd.srcs/sources_1/new/protocol_builder.v`
- `clock_amd.srcs/sources_1/new/comm_ctrl.v`
- `clock_amd.srcs/sources_1/new/clock.v`
- `sim/comm/tb_comm_ctrl_msg.v`
- `sim/comm/tb_comm_ctrl_reply.v`
- `software/clocklink_studio/tests/test_commands.py`
- `software/clocklink_studio/README.md`
- `docs/UART_PROTOCOL.md`
- `docs/COMM_MODE_FPGA_PLAN.md`
- `docs/CODEBASE_MAP.md`
- `sim/comm/README.md`
- `docs/AGENT_WORKLOG.md`

新增文件:

- `sim/comm/tb_comm_ctrl_time.v`

删除文件:

- 无

运行检查:

- `xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/preset_reply_rom.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_time.v`
- `xelab tb_comm_ctrl_time -s tb_comm_ctrl_time_sim`
- `xsim tb_comm_ctrl_time_sim -runall`
- `xvlog ... sim/comm/tb_comm_ctrl_msg.v`
- `xelab tb_comm_ctrl_msg -s tb_comm_ctrl_msg_sim`
- `xsim tb_comm_ctrl_msg_sim -runall`
- `xvlog ... sim/comm/tb_comm_ctrl_reply.v`
- `xelab tb_comm_ctrl_reply -s tb_comm_ctrl_reply_sim`
- `xsim tb_comm_ctrl_reply_sim -runall`
- `$files = Get-ChildItem -LiteralPath clock_amd.srcs/sources_1/new -Filter *.v | Sort-Object Name | ForEach-Object { $_.FullName }; xvlog @files`
- `cd software/clocklink_studio; python -m pytest`
- `cd software/clocklink_studio; python main.py --mock sync-time`
- `cd software/clocklink_studio; python main.py --mock time-get`
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`
- `rg -n "All user specified timing constraints are met|WNS\(ns\)|Slack \(MET\)|msg_char_buf_reg\[0\]" vivado.log`
- `git diff --check`
- `git status -sb`

检查结果:

- `tb_comm_ctrl_time` 通过，输出 `PASS tb_comm_ctrl_time`。
- `tb_comm_ctrl_msg` 通过，输出 `PASS tb_comm_ctrl_msg`，确认消息接收和 `MSG_STORED` 未退化。
- `tb_comm_ctrl_reply` 通过，输出 `PASS tb_comm_ctrl_reply`，确认预设回复未退化。
- 全源 `xvlog` 通过。
- `python -m pytest` 通过，13 个测试全部通过。
- `python main.py --mock sync-time` 通过，输出 `sync-time: 01 ACK ack=01;cmd=TIME_SET`。
- `python main.py --mock time-get` 通过，输出 `TIME date=...;time=...;weekday=...`。
- Vivado 综合检查通过；`WNS=+0.879ns`、`TNS=0.000ns`、失败端点 `0`，日志显示 `All user specified timing constraints are met.`。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换警告。
- `git status -sb` 显示工作区仍有历史/用户未提交改动、未跟踪工具日志和本阶段新增文件，未回退或清理无关内容。

未完成/阻塞:

- 无硬性阻塞，可进入 Phase 8。
- 尚未生成 bitstream，尚未在真实 Nexys A7 上实测 USB-UART 时间同步。

风险:

- `date_core.v` 当前自动跨天只更新月/日/星期，不自动递增年份；PC 可通过 `TIME_SET` 重新同步年份。
- 第一版不实现闰年，2 月最大 28 天；非法日期会返回 `NACK BAD_TIME`。
- `REPLY.ts` 仍使用被回复消息的原始时间戳，没有改为发送时刻，避免 Phase 7 变更协议字段。
- Vivado 仍提示 `protocol_parser.v:508` 中 `msg_char_buf_reg[0..99]` 有同优先级 set/reset warning；当前仿真和综合通过，后续扩展协议前建议改写。
- Vivado 进程结尾仍出现已知 stdout 问题 `ERROR: [Common 17-354] Could not open 'C' for writing.`；命令退出码为 0，timing 报告完整。

下一阶段计划:

- 进入 Phase 8：给 `alarm_ctrl.v`、`schedule_ctrl.v`、`countdown_ctrl.v` 增加 PC 直接写入/读取接口，接入 `ALARM_* / SCHED_* / COUNT_*` 协议和 PC CLI/GUI 控制。

建议提交信息:

- `feat(fpga): add ClockLink time sync protocol`
- `test(fpga): cover COMM TIME_SET and TIME_GET`

### 2026-06-05 2155 - Phase 8 - 闹钟、日程、倒计时直接控制

Phase:

- Phase 8：闹钟、日程、倒计时可视化控制

完成内容:

- `alarm_ctrl.v` 增加 PC 直接写入接口和独立读槽接口，PC 写入优先于手动编辑，并清除该槽 pending、snooze 和 match 状态。
- `schedule_ctrl.v` 增加 PC 直接写入/读取接口，支持时间、类型和开关，PC 写入优先于手动编辑，并清除该槽 pending 和 match 状态。
- `countdown_ctrl.v` 增加 PC 直接加载、启动、停止接口；`COUNT_SET` 加载新值后停止倒计时。
- `protocol_parser.v` 增加固定顺序解析：`ALARM_SET/GET`、`SCHED_SET/GET`、`COUNT_SET/START/STOP/STATUS`。
- `protocol_builder.v` 增加 `ALARM`、`SCHED`、`COUNT_STATUS` 回复和 Phase 8 ACK 命令名。
- `comm_ctrl.v` 接入 Phase 8 命令，发送器 busy 时返回 `NACK TX_BUSY` 且不产生副作用。
- `clock.v` 将 PC 控制脉冲接入闹钟/日程/倒计时，并将 `schedule_slot_switches` 限定在 SCHED 模式，避免 COMM 开关查看消息影响 SCHED 槽位。
- 新增 `tb_comm_ctrl_control.v`，覆盖控制链路和非法输入。
- PC CLI 增加 `alarm-get` 和 `sched-get`；mock 修正为 `COUNT_SET` 后停止倒计时。
- 修复 Phase 8 综合中 `protocol_builder.v` 一拍宽构帧 timing violation：将通用构帧拆为分类型 `ST_BUILD_*` 状态，保持帧内容不变。

修改文件:

- `clock_amd.srcs/sources_1/new/alarm_ctrl.v`
- `clock_amd.srcs/sources_1/new/schedule_ctrl.v`
- `clock_amd.srcs/sources_1/new/countdown_ctrl.v`
- `clock_amd.srcs/sources_1/new/protocol_parser.v`
- `clock_amd.srcs/sources_1/new/protocol_builder.v`
- `clock_amd.srcs/sources_1/new/comm_ctrl.v`
- `clock_amd.srcs/sources_1/new/clock.v`
- `software/clocklink_studio/main.py`
- `software/clocklink_studio/transport/mock_transport.py`
- `software/clocklink_studio/tests/test_commands.py`
- `software/clocklink_studio/tests/test_mock_transport.py`
- `software/clocklink_studio/README.md`
- `docs/UART_PROTOCOL.md`
- `docs/COMM_MODE_FPGA_PLAN.md`
- `docs/CODEBASE_MAP.md`
- `sim/comm/README.md`
- `docs/AGENT_WORKLOG.md`

新增文件:

- `sim/comm/tb_comm_ctrl_control.v`

删除文件:

- 无

运行检查:

- `xvlog ... sim/comm/tb_comm_ctrl_control.v`
- `xelab tb_comm_ctrl_control -s tb_comm_ctrl_control_sim`
- `xsim tb_comm_ctrl_control_sim -runall`
- `xsim tb_comm_ctrl_time_sim -runall`
- `xsim tb_comm_ctrl_msg_sim -runall`
- `xsim tb_comm_ctrl_reply_sim -runall`
- 全源 `xvlog`
- `cd software/clocklink_studio; python -m pytest`
- `cd software/clocklink_studio; python main.py --mock alarm-get --slot 1`
- `cd software/clocklink_studio; python main.py --mock sched-get --slot 2`
- `cd software/clocklink_studio; python main.py --mock count-set --time 00:03:00`
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`
- `git diff --check`

检查结果:

- `tb_comm_ctrl_control` 通过，输出 `PASS tb_comm_ctrl_control`。
- `tb_comm_ctrl_time`、`tb_comm_ctrl_msg`、`tb_comm_ctrl_reply` 均通过。
- 全源 `xvlog` 通过。
- `python -m pytest` 通过，15 个测试全部通过。
- mock CLI 读写命令通过。
- 初次 Phase 8 综合出现 `protocol_builder` 构帧路径 timing violation，最差约 `-0.388ns`；已拆分构帧状态后重跑。
- 最终 Vivado 综合检查通过；`WNS=+1.232ns`、`TNS=0.000ns`、失败端点 `0`，日志显示 `All user specified timing constraints are met.`。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换警告。

未完成/阻塞:

- 无硬性阻塞。
- 尚未生成 bitstream，尚未真实板级验证 USB-UART/COMM。

风险:

- `ALARM_DUMP/SCHED_DUMP` 第一版未在 FPGA 端实现宽多帧 dump，PC 读取全部槽应循环 `GET 0..7`。
- `protocol_parser.v:815` 仍有 `msg_char_buf_reg[0..99]` 同优先级 set/reset 综合 warning；当前仿真和综合通过，后续可重构暂存结构。

下一阶段计划:

- 进入 Phase 9，完成 GUI 演示面板、最终 README/HANDOFF/演示流程文档和验收记录。

建议提交信息:

- `feat(fpga): add ClockLink direct control for alarm schedule countdown`
- `test(fpga): cover ClockLink direct control commands`

### 2026-06-05 2155 - Phase 9 - GUI 完整化与最终验收文档

Phase:

- Phase 9：GUI 完整化、验收与文档

完成内容:

- `ui/main_window.py` 从最小骨架扩展为 Tkinter 演示面板，包含连接/状态、时间同步、消息发送/读取、闹钟槽读写、日程槽读写、倒计时设置/启动/停止/查询和日志页。
- 新增 `docs/FINAL_DEMO_GUIDE.md`，覆盖连接 PC 和 Nexys A7、进入 COMM、同步时间、发送消息、SW 查看、滚动、预设回复、PC 控制闹钟/日程/倒计时、回归原模式的完整演示流程。
- 更新 `README.md`、`HANDOFF.md`、`software/clocklink_studio/README.md`、`docs/COMM_MODE_FPGA_PLAN.md`、`sim/comm/README.md`，同步 Phase 8/9 最终状态。
- 明确当前验证边界：mock/仿真/综合已通过，bitstream 和真实板级 USB-UART/COMM 尚未实测。

修改文件:

- `software/clocklink_studio/ui/main_window.py`
- `software/clocklink_studio/README.md`
- `README.md`
- `HANDOFF.md`
- `docs/COMM_MODE_FPGA_PLAN.md`
- `sim/comm/README.md`
- `docs/AGENT_WORKLOG.md`

新增文件:

- `docs/FINAL_DEMO_GUIDE.md`

删除文件:

- 无

运行检查:

- `cd software/clocklink_studio; python -m pytest`
- `cd software/clocklink_studio; python -m py_compile main.py ui/main_window.py transport/mock_transport.py`
- `xvlog` 全源语法检查
- `tb_comm_ctrl_control/time/msg/reply` XSim 回归
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`
- `git diff --check`

检查结果:

- `python -m pytest` 通过，15 个测试全部通过。
- GUI 和 mock transport Python 编译检查通过。
- 全源 `xvlog` 通过。
- `tb_comm_ctrl_control/time/msg/reply` 均输出 `PASS`。
- Vivado 综合检查通过；`WNS=+1.232ns`、`TNS=0.000ns`、失败端点 `0`。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换警告。

未完成/阻塞:

- 无代码侧硬性阻塞。
- 未生成 bitstream，未进行 Nexys A7 板级实测。
- 真实串口异步 `REPLY/EVENT` 持续监听尚未完整实现；当前 GUI 以同步命令日志和 mock 事件为演示路径。

风险:

- 板级验证前仍需确认 Vivado 工程 Sources 中包含新增 HDL 文件，并重新生成 bitstream。
- USB-UART 真实串口连接、OLED 实机显示、按键回复和蜂鸣/提醒共存仍需上板确认。

下一阶段计划:

- 生成 bitstream 并按 `docs/FINAL_DEMO_GUIDE.md` 执行真实 Nexys A7 演示。
- 后续增强真实串口异步事件监听和 `MSG_GET/ALARM_DUMP/SCHED_DUMP` 流式实现。

建议提交信息:

- `feat(pc): add ClockLink Studio GUI demo panel`
- `docs: add ClockLink final demo guide`

### 2026-06-05 2207 - Phase 9 - QA 收尾检查

Phase:

- Phase 9：最终 QA 收尾

完成内容:

- 重新阅读 `AGENTS.md`、`README.md`、`HANDOFF.md`、`docs/工程模块使用说明.md`、`docs/ClockLink_Studio_PC_Software_Design.md`、`docs/AGENT_WORKFLOW.md`、`docs/AGENT_TASKS.md`、`docs/AGENT_WORKLOG.md` 和当前 PC/协议相关源码。
- 检查最终文档中是否残留旧状态表述，确认 `MSG_GET/MSG_DATA`、`ALARM_DUMP/SCHED_DUMP` 均以已知限制或协议保留项记录。
- 更新 `.gitignore`，忽略 XSim 日志、Vivado/JVM crash 日志、Python cache 和本地虚拟环境，避免后续提交工具产物。

修改文件:

- `.gitignore`
- `docs/AGENT_WORKLOG.md`

新增文件:

- 无

删除文件:

- 无

运行检查:

- `rg -n "PROJECT_STATUS|GUI 骨架|六个模式|6 个模式|尚未获得最终|尚未通过|Phase 9.*未|DISC 固定|固定为 \`DISC\`|ALARM_DUMP|SCHED_DUMP|MSG_GET|MSG_DATA" README.md HANDOFF.md docs software sim clock_amd.srcs/sources_1/new`
- `git status -sb`
- `cd software/clocklink_studio; python -m pytest`
- `cd software/clocklink_studio; python -m py_compile main.py ui/main_window.py transport/mock_transport.py`
- `git diff --check`

检查结果:

- 文档旧表述检查未发现需要修改的 Phase 9 阻塞项。
- `MSG_GET/MSG_DATA`、`ALARM_DUMP/SCHED_DUMP` 均已在协议、计划和演示文档中记录为当前 FPGA 第一版限制或后续增强项。
- `python -m pytest` 通过，15 个测试全部通过。
- Python GUI、CLI 和 mock transport 编译检查通过。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换警告。
- 当前未重新运行 Vivado 综合，因为本次只修改 `.gitignore` 和工作日志；沿用 Phase 9 已通过综合结果：`WNS=+1.232ns`、`TNS=0.000ns`、失败端点 `0`。

未完成/阻塞:

- 无代码侧硬性阻塞。
- 尚未生成 bitstream，尚未完成 Nexys A7 板级 USB-UART/COMM 实测。

风险:

- 工作区仍存在 `PROJECT_STATUS.md` 和旧中文日志删除、`任务.txt` 等不确定来源的历史状态；本次不主动回退，也不把它们单独作为收尾提交。

下一阶段计划:

- 生成 bitstream，并按 `docs/FINAL_DEMO_GUIDE.md` 执行真实板级演示。

建议提交信息:

- `chore: ignore local simulation and Python artifacts`

### 2026-06-06 0147 - Phase 9 - PC 软件 EXE 打包

Phase:

- Phase 9：PC 软件打包交付

完成内容:

- 新增 `software/clocklink_studio/desktop.py`，提供双击启动入口。
- 桌面入口启动后可选择自动枚举到的串口或 mock 模式，再打开现有 Tkinter GUI。
- 使用 PyInstaller 打包生成 `software/clocklink_studio/dist/ClockLinkStudio.exe`。
- 新增 `software/clocklink_studio/ClockLinkStudio.spec`，用于后续稳定重建 exe。
- 更新 `software/clocklink_studio/README.md`，补充 exe 路径和重新打包命令。
- 更新 `.gitignore`，忽略 PyInstaller `build/` 中间目录。

修改文件:

- `.gitignore`
- `software/clocklink_studio/README.md`
- `docs/AGENT_WORKLOG.md`

新增文件:

- `software/clocklink_studio/desktop.py`
- `software/clocklink_studio/ClockLinkStudio.spec`
- `software/clocklink_studio/dist/ClockLinkStudio.exe`

删除文件:

- 无

运行检查:

- `python -m PyInstaller --version`
- `python -c "import serial; print(serial.__version__)"`
- `cd software/clocklink_studio; python -m py_compile main.py desktop.py ui/main_window.py transport/mock_transport.py transport/serial_transport.py`
- `cd software/clocklink_studio; python desktop.py --self-test`
- `cd software/clocklink_studio; python -m pytest`
- `cd software/clocklink_studio; python -m PyInstaller --noconfirm --onefile --windowed --name ClockLinkStudio desktop.py`
- `cd software/clocklink_studio; Start-Process .\dist\ClockLinkStudio.exe --self-test ...`

检查结果:

- PyInstaller 可用，版本 `6.19.0`。
- pyserial 可用，版本 `3.5`。
- Python 编译检查通过。
- `desktop.py --self-test` 通过。
- `python -m pytest` 通过，15 个测试全部通过。
- PyInstaller 成功生成 `dist/ClockLinkStudio.exe`，大小约 `11 MB`。
- exe 自测退出码为 `0`。
- 本阶段未重新运行 Vivado，因为只修改 PC 启动器、打包配置和文档。

未完成/阻塞:

- 未对真实 Nexys A7 USB-UART 做板级串口实测。
- `dist/ClockLinkStudio.exe` 是本地二进制交付产物，当前不强制提交进 Git。

风险:

- Windows 首次运行未签名 exe 可能出现安全提示。
- 真实串口异步 `REPLY/EVENT` 持续监听仍是后续增强项，当前 GUI 以同步命令日志为主。

下一阶段计划:

- 生成 bitstream，连接 Nexys A7 后运行 `dist/ClockLinkStudio.exe`，选择对应 COM 口并按 `docs/FINAL_DEMO_GUIDE.md` 实测。

建议提交信息:

- `feat(pc): add Windows desktop launcher for ClockLink Studio`

### 2026-06-06 0156 - Phase 9 - PC GUI 中文友好化

Phase:

- Phase 9：PC 软件界面本地化

完成内容:

- `desktop.py` 启动窗口默认中文，增加 `中文 / English` 语言选择。
- `ui/main_window.py` 主界面默认中文，右上角增加 `中文 / English` 切换。
- 主界面标签、页签、按钮、错误前缀、日志中的消息正文提示均支持中英文。
- 日程类型下拉框支持中文名称和英文名称切换，底层仍传递协议要求的数字 `type`。
- 更新 `software/clocklink_studio/README.md`，说明中文默认界面和中英文切换。

修改文件:

- `software/clocklink_studio/desktop.py`
- `software/clocklink_studio/ui/main_window.py`
- `software/clocklink_studio/README.md`
- `docs/AGENT_WORKLOG.md`

新增文件:

- 无

删除文件:

- 无

运行检查:

- `cd software/clocklink_studio; python -m py_compile main.py desktop.py ui/main_window.py transport/mock_transport.py transport/serial_transport.py`
- `cd software/clocklink_studio; python desktop.py --self-test`
- `cd software/clocklink_studio; python -m pytest`

检查结果:

- Python 编译检查通过。
- `desktop.py --self-test` 通过。
- `python -m pytest` 通过，15 个测试全部通过。
- 本阶段未重新运行 Vivado，因为只修改 PC GUI 文本和启动器。

未完成/阻塞:

- 尚未在真实板卡上验证串口模式。

风险:

- Tkinter 字体由 Windows 系统决定，极少数精简系统若缺中文字体，中文显示可能退回到系统替代字体。

下一阶段计划:

- 重新打包 `dist/ClockLinkStudio.exe`，并在板级演示时使用中文界面。

建议提交信息:

- `feat(pc): add bilingual ClockLink Studio UI`

### 2026-06-06 0214 - Phase 9 - PC GUI 体验优化

Phase:

- Phase 9：PC 软件界面体验优化

完成内容:

- 将通信日志从独立页签改为窗口底部全局日志区域，操作 `连接与消息` 和 `功能控制` 时都能实时看到请求和回复。
- 为底部日志新增 `缩小日志 / 默认大小 / 放大日志` 三档按钮，便于在演示操作和调试日志之间切换空间。
- 在 `连接与消息` 页中部新增聊天式互动记录，PC 发送内容右侧显示，FPGA/mock 回复左侧显示，系统提示居中显示。
- 聊天记录增加时间戳、浅色背景区分和回车发送消息。
- 更新 PC 软件 README 和设计文档，说明新 GUI 布局。
- 重新打包 `software/clocklink_studio/dist/ClockLinkStudio.exe`。

修改文件:

- `software/clocklink_studio/ui/main_window.py`
- `software/clocklink_studio/README.md`
- `docs/ClockLink_Studio_PC_Software_Design.md`
- `docs/AGENT_WORKLOG.md`

新增文件:

- 无

删除文件:

- 无

运行检查:

- `cd software/clocklink_studio; python -m py_compile main.py desktop.py ui/main_window.py transport/mock_transport.py transport/serial_transport.py`
- `cd software/clocklink_studio; python desktop.py --self-test`
- `cd software/clocklink_studio; python -m pytest`
- `cd software/clocklink_studio; python -m PyInstaller --noconfirm ClockLinkStudio.spec`
- `cd software/clocklink_studio; Start-Process .\dist\ClockLinkStudio.exe --self-test ...`
- `git diff --check`

检查结果:

- Python 编译检查通过。
- `desktop.py --self-test` 通过。
- `python -m pytest` 通过，15 个测试全部通过。
- PyInstaller 成功重建 `dist/ClockLinkStudio.exe`。
- exe 自测退出码为 `0`。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换提示。
- 本阶段未运行 Vivado，因为只修改 PC GUI 和文档，不涉及 HDL、XDC 或综合路径。

未完成/阻塞:

- 尚未在真实 Nexys A7 上验证串口模式和异步 `REPLY/EVENT` 持续监听体验。

风险:

- 当前聊天记录以同步命令返回为主；真实串口主动事件的后台监听仍是后续增强项。
- `dist/ClockLinkStudio.exe` 是本地打包产物，当前仍不强制纳入 Git 提交。

下一阶段计划:

- 连接真实板卡后，用新版 exe 验证聊天记录、底部日志和 COMM 模式消息链路。

建议提交信息:

- `feat(pc): improve ClockLink Studio chat and log layout`

### 2026-06-06 0229 - Phase 9 - PC GUI 现代化美化

Phase:

- Phase 9：PC 软件界面视觉优化

完成内容:

- 将主窗口改为现代浅色桌面应用风格：顶部品牌栏、状态胶囊、白色功能卡片、现代标签页和统一按钮样式。
- 将 `连接与消息` 页重排为左侧工具区、右侧聊天区，减少控件堆叠感。
- 将聊天记录从 `ScrolledText` 文本列表升级为类似 Telegram 的气泡式消息流：PC 右侧蓝色气泡，FPGA/mock 左侧白色气泡，系统提示居中。
- 聊天气泡支持时间戳、长文本自动换行和滚动到底部。
- 将 `功能控制` 页按闹钟、日程、倒计时分成独立功能卡片。
- 将底部日志改成深色控制台风格，保留三档日志高度控制。
- 将启动选择窗口轻量美化为同一套浅色卡片风格。
- 更新 PC 软件 README 和设计文档，说明新版视觉结构。
- 重新打包 `software/clocklink_studio/dist/ClockLinkStudio.exe`。

修改文件:

- `software/clocklink_studio/ui/main_window.py`
- `software/clocklink_studio/desktop.py`
- `software/clocklink_studio/README.md`
- `docs/ClockLink_Studio_PC_Software_Design.md`
- `docs/AGENT_WORKLOG.md`

新增文件:

- 无

删除文件:

- 无

运行检查:

- `cd software/clocklink_studio; python -m py_compile main.py desktop.py ui/main_window.py transport/mock_transport.py transport/serial_transport.py`
- `cd software/clocklink_studio; python desktop.py --self-test`
- `cd software/clocklink_studio; python -m pytest`
- `cd software/clocklink_studio; python -c "... ClockLinkWindow(c).run() ..."` GUI 构造 smoke 测试
- `cd software/clocklink_studio; python -m PyInstaller --noconfirm ClockLinkStudio.spec`
- `cd software/clocklink_studio; Start-Process .\dist\ClockLinkStudio.exe --self-test ...`
- `git diff --check`

检查结果:

- Python 编译检查通过。
- `desktop.py --self-test` 通过。
- `python -m pytest` 通过，15 个测试全部通过。
- GUI 构造 smoke 测试输出 `GUI_SMOKE_OK`。
- PyInstaller 成功重建 `dist/ClockLinkStudio.exe`。
- exe 自测退出码为 `0`。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换提示。
- 本阶段未运行 Vivado，因为只修改 PC GUI 和文档，不涉及 HDL、XDC 或综合路径。

未完成/阻塞:

- 尚未在真实 Nexys A7 上验证串口模式下的新界面操作体验。

风险:

- 仍使用 Tkinter 原生控件实现现代视觉，圆角和阴影能力有限，但不增加依赖，便于继续打包单文件 exe。
- 真实串口主动 `REPLY/EVENT` 后台监听仍是后续增强项，当前聊天记录以同步命令返回为主。

下一阶段计划:

- 用新版 exe 连接真实板卡，验证聊天气泡、底部日志、时间同步和 COMM 消息链路的实际演示效果。

建议提交信息:

- `feat(pc): modernize ClockLink Studio interface`

### 2026-06-06 1255 - Vivado 工程源文件修复

Phase:

- Phase 9：Vivado 工程交付修复

完成内容:

- 修复 Vivado 工程模式综合报错 `[Synth 8-439] module 'comm_ctrl' not found [clock.v:429]`。
- 确认 `comm_ctrl.v` 文件本身存在，根因是 `clock_amd.xpr` 的 `sources_1` 文件集未包含 ClockLink 新增 HDL。
- 在 `clock_amd.xpr` 中补入 `comm_ctrl.v`、`message_store.v`、`preset_reply_rom.v`、`protocol_builder.v`、`protocol_parser.v`、`uart_rx.v`、`uart_tx.v`。
- 新增 `scripts/check_xpr_clocklink_sources.tcl`，用于打开 `clock_amd.xpr` 并检查 ClockLink 相关 HDL 是否进入 Vivado 工程文件集。

修改文件:

- `clock_amd.xpr`
- `docs/AGENT_WORKLOG.md`

新增文件:

- `scripts/check_xpr_clocklink_sources.tcl`

删除文件:

- 无

运行检查:

- `Select-String -Path clock_amd.xpr -Pattern "comm_ctrl|message_store|preset_reply_rom|protocol_builder|protocol_parser|uart_rx|uart_tx"`
- `git diff --check`
- `vivado -mode batch -source scripts/check_xpr_clocklink_sources.tcl`
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`

检查结果:

- 文本检查确认 `clock_amd.xpr` 已包含 7 个 ClockLink HDL 文件。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换提示。
- `check_xpr_clocklink_sources.tcl` 输出 `PASS: ClockLink source files are present in clock_amd.xpr`。
- `run_phase_synth_check.tcl` 一开始超过 180 秒工具超时，但后台 Vivado 综合自然完成。
- `vivado.log` 显示 `synth_design completed successfully`，未再出现 `Synth 8-439` 或 `module 'comm_ctrl' not found`。
- 综合结果：`WNS=+1.232ns`、`TNS=0.000ns`、失败端点 `0`，所有用户约束满足。
- Vivado 打开工程时仍输出一批 Board Store board part 警告，属于当前 Vivado 板卡库环境提示，不影响本次源文件缺失修复。

未完成/阻塞:

- 尚未生成 bitstream，尚未进行真实 Nexys A7 板级验证。

风险:

- `clock_amd.xpr` 是 Vivado 工程入口文件；本次必须修改它才能让 GUI 工程模式综合看到新增 HDL。
- 工作区仍存在不属于本次修复的历史脏文件和一个 Vivado 生成的 `vivado_pid18336.str`，本次不处理。

下一阶段计划:

- 在 Vivado GUI 中重新打开 `clock_amd.xpr`，确认 `sources_1` 可见 ClockLink 通信模块，再执行 Generate Bitstream。

建议提交信息:

- `fix(fpga): add ClockLink HDL sources to Vivado project`

### 2026-06-06 1308 - Vivado GUI 旧工程覆盖排查

Phase:

- Phase 9：Vivado 工程使用排查

完成内容:

- 针对用户反馈“仍然显示找不到 `comm_ctrl`”继续排查。
- 发现当前磁盘上的 `clock_amd.xpr` 曾被正在运行的 Vivado 进程改回旧 source 列表，Git diff 显示刚加入的 7 个 ClockLink HDL 条目被删除。
- 再次恢复 `clock_amd.xpr` 中的 ClockLink HDL 条目。
- 确认上一级还存在旧工程 `../CLOCK/clock_amd/clock_amd.xpr`，该旧工程不包含 ClockLink 通信模块；若打开旧工程也会继续报 `comm_ctrl` 找不到。
- 新增 `scripts/add_clocklink_sources_to_project.tcl`，可在当前 Vivado Tcl Console 中执行，用当前 GUI 内存工程直接 `add_files`、`update_compile_order`、`save_project`，避免外部修改 `.xpr` 后被已打开的 GUI 工程覆盖。

修改文件:

- `clock_amd.xpr`
- `docs/AGENT_WORKLOG.md`

新增文件:

- `scripts/add_clocklink_sources_to_project.tcl`

删除文件:

- 无

运行检查:

- `Select-String -Path clock_amd.xpr -Pattern "comm_ctrl|message_store|preset_reply_rom|protocol_builder|protocol_parser|uart_rx|uart_tx"`
- `Get-ChildItem -Path .. -Recurse -Filter clock_amd.xpr`
- `git diff --check`

检查结果:

- 当前 `clock_amd.xpr` 文本检查已包含 `comm_ctrl.v`、`message_store.v`、`preset_reply_rom.v`、`protocol_builder.v`、`protocol_parser.v`、`uart_rx.v`、`uart_tx.v`。
- 确认存在两个工程入口：当前最终工程 `clock_amd/clock_amd.xpr` 和旧副本 `CLOCK/clock_amd/clock_amd.xpr`。
- `git diff --check` 未发现空白错误，仅输出 CRLF 提示。
- 未再次运行 Vivado batch 打开工程，因为当前已有 Vivado 进程运行，继续并行打开同一工程可能造成 source 列表再次被 GUI 内存状态覆盖。

未完成/阻塞:

- 需要用户在当前已打开的 Vivado GUI 中执行 `source scripts/add_clocklink_sources_to_project.tcl`，或关闭 Vivado 后重新打开最终工程 `clock_amd/clock_amd.xpr`。

风险:

- 如果 Vivado GUI 仍保持旧内存工程并保存项目，它可能继续覆盖磁盘上的 `clock_amd.xpr`。
- 如果打开的是旧副本 `CLOCK/clock_amd/clock_amd.xpr`，无论当前最终工程如何修复，旧工程仍会报找不到 ClockLink 模块。

下一阶段计划:

- 在 Vivado Tcl Console 中执行修复脚本后重新 Run Synthesis。

建议提交信息:

- `fix(fpga): add Vivado GUI source repair script`

### 2026-06-06 1525 - COMM OLED 小写消息显示修复

Phase:

- Phase 9：板级体验问题修复

完成内容:

- 针对用户上板反馈“发送 `hello fpga` 和 `hello` 后，`SW0` 正文空白、`SW1` 只显示 `H     FPGA` / `H`”进行排查。
- 确认协议解析、消息缓存 slot 顺序和窗口重建不是主要问题；`message_store` 在连续保存 `hello fpga` 与 `hello` 后，`slot0`/`slot1` 数据正确。
- 根因定位为 `oled_ui_display.v` 的 8x7 字库原先只覆盖部分大写字母和数字，消息正文里的小写 `e/l/o/f/p/g/a` 没有字形，OLED 绘制为空白。
- 修改 OLED 字形函数：小写 `a-z` 映射为对应大写字形显示，协议和缓存仍保留原始 ASCII；同时补齐 `B/J/Q/V/Z` 和 `.`，避免预设回复 `Busy now.` 等文本缺字。
- 新增 `tb_message_store.v`，覆盖两条连续消息和 `SW0/SW1` slot 选择。
- 新增 `tb_oled_glyph.v`，覆盖小写映射和新增字形。
- 更新 `sim/comm/README.md` 的通信仿真说明。

修改文件:

- `clock_amd.srcs/sources_1/new/oled_ui_display.v`
- `sim/comm/README.md`
- `docs/AGENT_WORKLOG.md`

新增文件:

- `sim/comm/tb_message_store.v`
- `sim/comm/tb_oled_glyph.v`

删除文件:

- 无

运行检查:

- `xvlog clock_amd.srcs/sources_1/new/message_store.v sim/comm/tb_message_store.v; xelab tb_message_store -s tb_message_store_sim; xsim tb_message_store_sim -runall`
- `xvlog clock_amd.srcs/sources_1/new/i2c_master_simple.v clock_amd.srcs/sources_1/new/oled_date_status.v clock_amd.srcs/sources_1/new/oled_countdown_status.v clock_amd.srcs/sources_1/new/oled_notify_status.v clock_amd.srcs/sources_1/new/oled_ui_display.v sim/comm/tb_oled_glyph.v; xelab tb_oled_glyph -s tb_oled_glyph_sim; xsim tb_oled_glyph_sim -runall`
- `xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/preset_reply_rom.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_msg.v; xelab tb_comm_ctrl_msg -s tb_comm_ctrl_msg_sim; xsim tb_comm_ctrl_msg_sim -runall`
- `git diff --check`
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`

检查结果:

- `tb_message_store` 输出 `PASS tb_message_store`。
- `tb_oled_glyph` 首次因 testbench timescale 与 OLED 源文件不一致失败；去掉 testbench timescale 后输出 `PASS tb_oled_glyph`。
- `tb_comm_ctrl_msg` 输出 `PASS tb_comm_ctrl_msg`。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换提示。
- Vivado 综合通过，`vivado.log` 显示 `synth_design completed successfully`。
- 综合时序满足约束：`WNS=+0.119ns`，`TNS=0.000ns`，失败端点 `0`，日志显示 `All user specified timing constraints are met.`。

未完成/阻塞:

- 需要重新综合、生成 bitstream 并重新下载到 Nexys A7 后，板上 OLED 才会显示修复后的字形。

风险:

- 当前小写采用映射为大写字形显示，OLED 上会显示为 `HELLO FPGA`，但协议、缓存和 PC 日志仍保留用户原始大小写。
- OLED 仍不是完整 ASCII 字库，后续若要显示更多符号，可继续扩展 `glyph_row`。

下一阶段计划:

- 重新生成 bitstream 并下载到 Nexys A7，复测 `hello fpga`、`hello`、预设回复和 SW0/SW1 消息查看。

建议提交信息:

- `fix(fpga): render lowercase ClockLink OLED messages`

### 2026-06-06 1605 - PC 串口主动 REPLY 监听修复

Phase:

- Phase 9：真实串口体验问题修复

完成内容:

- 针对用户反馈“COMM 回复模式按 `BTNR` 后电脑没有接收到”排查板端和 PC 端链路。
- 确认 FPGA 端 `comm_ctrl` 发送 `REPLY` 的触发条件为：处于 COMM 模式、当前选中消息有效、已按 `BTNC` 进入回复模式、`BTNR` 产生脉冲且协议发送器不忙。
- 确认 PC 端原 `SerialTransport` 只在 `transact()` 请求-响应期间读一行串口数据，GUI 没有后台监听，所以板子主动发出的 `REPLY` 不会自动显示。
- 修改 `SerialTransport`：新增后台读取线程、接收队列和主动帧事件队列；`transact()` 会按请求 `SEQ` 匹配当前命令响应，遇到其他 `SEQ` 的主动帧先放入事件队列。
- 修改 GUI：每 100ms 轮询串口主动帧；收到 `REPLY` 后在底部日志显示原始帧，并在聊天框显示 HEX 解码后的预设回复文本。
- 新增串口传输层单元测试，覆盖“主动 `REPLY` 先到、命令响应后到”的队列分流场景。
- 更新 PC 软件 README 和设计文档。
- 重新打包 `software/clocklink_studio/dist/ClockLinkStudio.exe`。

修改文件:

- `software/clocklink_studio/transport/base.py`
- `software/clocklink_studio/transport/serial_transport.py`
- `software/clocklink_studio/ui/main_window.py`
- `software/clocklink_studio/README.md`
- `docs/ClockLink_Studio_PC_Software_Design.md`
- `docs/AGENT_WORKLOG.md`

新增文件:

- `software/clocklink_studio/tests/test_serial_transport.py`

删除文件:

- 无

运行检查:

- `cd software/clocklink_studio; python -m pytest`
- `cd software/clocklink_studio; python -m PyInstaller --noconfirm ClockLinkStudio.spec`
- `cd software/clocklink_studio; .\dist\ClockLinkStudio.exe --self-test`
- `xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/preset_reply_rom.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_reply.v; xelab tb_comm_ctrl_reply -s tb_comm_ctrl_reply_sim; xsim tb_comm_ctrl_reply_sim -runall`
- `git diff --check`

检查结果:

- `python -m pytest` 通过，17 个测试全部通过。
- PyInstaller 打包成功，输出目录为 `software/clocklink_studio/dist`。
- `ClockLinkStudio.exe --self-test` 退出码为 0。
- `tb_comm_ctrl_reply` 输出 `PASS tb_comm_ctrl_reply`，确认 FPGA 端在回复模式下按 `BTNR` 可构造并发送 `REPLY`。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换提示。

未完成/阻塞:

- 尚未在真实 Nexys A7 串口上验证 `BTNR -> REPLY -> GUI 聊天气泡` 的完整链路。
- 若板子端未进入回复模式或当前无有效消息，`BTNR` 仍不会发送 `REPLY`，这是 HDL 的预期保护条件。

风险:

- PC GUI 后台监听会把非当前请求 `SEQ` 的帧归类为主动帧；这符合当前协议的单 outstanding 命令模型。
- 工作区仍存在不属于本次任务的历史脏文件和未跟踪文档，本次未处理。

下一阶段计划:

- 使用新版 `ClockLinkStudio.exe` 打开真实串口，按完整 COMM 流程复测预设回复。

建议提交信息:

- `fix(pc): listen for FPGA reply frames in serial GUI`

### 2026-06-06 1625 - 显示/UI 组合路径优化

Phase:

- Phase 9：FPGA 显示/UI 资源与时序优化

本次目标:

- 针对当前资源占比中 LUT 偏高但不危险的情况，优先降低显示/UI/多模式选择带来的组合逻辑复杂度。
- 缩短数码管显示链路组合路径，减小扫描模块 mux，降低下游扇出，让时序更容易收敛。
- 保持 `CLOCK / TIME / ALARM / HOUR / COUNT / SCHED / COMM` 七个模式行为不退化。

完成内容:

- `display_ctrl` 新增 `clk/rst`，将 8 个显示字符输出改为寄存输出，在多模式显示选择之后建立一级寄存边界。
- 保留 `display_ctrl` 原有模式内容、字段闪烁和 COMM 状态显示逻辑，只把组合结果从 `*_next` 寄存到输出端。
- `nexys_seg_scan` 删除未使用的旧 BCD/`full_display_en` 接口和 5 个冗余 `seg_7` 译码实例，只保留当前实际使用的 `digit_code_bus + dp_mask` 全 8 位字符扫描接口。
- `nexys_seg_scan` 将 `AN/CA..CG/DP` 板级输出寄存化，减少扫描译码后的直接组合输出路径。
- `clock.v` 同步更新 `display_ctrl` 实例端口。
- `clock_amd_top.v` 同步删除 `nexys_seg_scan` 实例中恒为 0 或恒为 1 的旧接口连接。
- `oled_ui_display` 删除未使用的 `render_comm_message_window_ascii` 512-bit 副本寄存器，保留实际渲染使用的四行 16 字符寄存器。
- 未新增 UART 协议命令，未修改 PC 软件行为，未改变顶层板级端口和 `.xdc` 约束。

修改文件:

- `clock_amd.srcs/sources_1/new/display_ctrl.v`
- `clock_amd.srcs/sources_1/new/clock.v`
- `clock_amd.srcs/sources_1/new/nexys_seg_scan.v`
- `clock_amd.srcs/sources_1/new/clock_amd_top.v`
- `clock_amd.srcs/sources_1/new/oled_ui_display.v`
- `docs/AGENT_WORKLOG.md`

新增文件:

- 无

删除文件:

- 无

运行检查:

- `xvlog` 全源 Verilog 语法检查
- `xelab --timescale 1ns/1ps --override_timeunit --override_timeprecision clock_amd_top -s clock_amd_top_elab`
- `xvlog clock_amd.srcs/sources_1/new/message_store.v sim/comm/tb_message_store.v; xelab tb_message_store -s tb_message_store_sim; xsim tb_message_store_sim -runall`
- `xvlog clock_amd.srcs/sources_1/new/i2c_master_simple.v clock_amd.srcs/sources_1/new/oled_date_status.v clock_amd.srcs/sources_1/new/oled_countdown_status.v clock_amd.srcs/sources_1/new/oled_notify_status.v clock_amd.srcs/sources_1/new/oled_ui_display.v sim/comm/tb_oled_glyph.v; xelab --timescale 1ns/1ps --override_timeunit --override_timeprecision tb_oled_glyph -s tb_oled_glyph_sim; xsim tb_oled_glyph_sim -runall`
- `xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/preset_reply_rom.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_msg.v; xelab tb_comm_ctrl_msg -s tb_comm_ctrl_msg_sim; xsim tb_comm_ctrl_msg_sim -runall`
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`
- `git diff --check`

检查结果:

- 全源 `xvlog` 通过。
- 顶层 `xelab` 通过；由于工程中仍混有带/不带 `timescale` 的旧模块，本次使用 XSim override 参数完成展开检查。
- `tb_message_store` 输出 `PASS tb_message_store`。
- `tb_oled_glyph` 输出 `PASS tb_oled_glyph`。
- `tb_comm_ctrl_msg` 输出 `PASS tb_comm_ctrl_msg`。
- Vivado 综合通过，`synth_design completed successfully`。
- 综合时序满足约束：`WNS=+0.119ns`、`TNS=0.000ns`、失败端点 `0`，日志显示 `All user specified timing constraints are met.`。
- 本次综合报告中的主要单元计数：`LUT6 11178`、`MUXF7 2606`、`MUXF8 1132`、`FDRE 15212`。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换提示。

未完成/阻塞:

- 尚未生成 bitstream，尚未进行 Nexys A7 板级复测。
- 本阶段只做显示/UI 结构性降复杂度，未做 OLED 字库/文本渲染深度重构。

已知问题:

- 当前最差路径仍在 `u_oled_ui_display/page_data...`、`render_comm_msg_line... -> page_data_byte_reg` 一类 OLED 文本/字模组合路径，七段数码管链路已被寄存边界隔离。
- Vivado batch 在报告输出后出现一次 `ERROR: [Common 17-354] Could not open 'C' for writing`，但命令退出码为 0，且日志确认综合和时序均已通过；若后续自动化脚本依赖报告文件，需要继续观察该输出路径问题。
- `protocol_parser` 既有综合警告未在本阶段处理。
- 工作区仍存在不属于本次任务的历史脏文件和未跟踪文件，本次未回退。

下一阶段计划:

- 生成 bitstream 并上板回归七个模式、数码管扫描、OLED COMM 消息显示和 USB-UART 链路。
- 若需要继续增加时序裕量，下一阶段单独优化 OLED：把 `page_data()` 的文本/字模查表拆成更明确的流水或 ROM/table 结构，避免在一个周期内完成宽文本选择和字模译码。

建议提交信息:

- `perf(fpga): register display path and simplify seven-seg scan`

### 2026-06-07 1659 - 全面时序优化与 routed 收敛

Phase:

- Phase 9：FPGA 时序优化收尾，重点处理 routed 后真实违例路径。

本次目标:

- 针对 routed 实现报告中的严重负时序 `WNS=-1.432ns`、`TNS=-387.338ns`、失败端点 515 个，继续降低 UI/通信显示路径的组合复杂度和布线压力。
- 优先处理真实最差路径：`u_clock/u_comm_ctrl/u_message_store/window_build_index... -> selected_window_ascii_reg[...]`，该路径数据延迟 11.129ns，其中布线 7.593ns，占 68%。
- 保持 `CLOCK / TIME / ALARM / HOUR / COUNT / SCHED / COMM` 行为不退化，不新增 UART 协议命令。

完成内容:

- `message_store` 将 1600 字节消息正文存储显式约束为 Block RAM，并把 64 字节窗口输出拆为 `selected_window_mem[0:63]` 字节寄存数组，再通过 generate 打包为原有 `selected_window_ascii` 总线。
- `message_store` 将窗口重建从“一周期宽总线读/写 mux”改为 3 阶段流水：发起 BRAM 地址、同步读出、写入窗口字节，消除对 `selected_window_ascii[511:0]` 的大组合选择。
- `message_store` 拆分正文 RAM 写入和窗口读取 always 块，Vivado 已将 `text_mem_reg` 推断为 `RAMB18E1`。
- `oled_ui_display` 将 OLED 字节生成从“页面选择 + 文本选择 + 字模译码同周期完成”拆成 4 阶段：锁存坐标、计算页面/文本信息、字模列译码、发送 I2C 数据字节。
- `oled_ui_display` 保留原页面内容逻辑，同时把渲染路径中的宽文本选择和 `glyph_column()` 断开，缩短 OLED 页数据组合路径。
- 修正 `tb_message_store` 中测试激励和 DUT 在同一 `posedge clk` 采样的竞争问题，并按新窗口重建流水增加等待周期。
- 新增 `scripts/run_phase_impl_timing_check.tcl`，用于非工程模式执行 synth/opt/place/phys_opt/route/phys_opt 并输出 routed timing，避免只看综合时序。

修改文件:

- `clock_amd.srcs/sources_1/new/message_store.v`
- `clock_amd.srcs/sources_1/new/oled_ui_display.v`
- `sim/comm/tb_message_store.v`
- `docs/AGENT_WORKLOG.md`

新增文件:

- `scripts/run_phase_impl_timing_check.tcl`

删除文件:

- 无

运行检查:

- `xvlog clock_amd.srcs/sources_1/new/message_store.v sim/comm/tb_message_store.v`
- `xelab tb_message_store -s tb_message_store_sim; xsim tb_message_store_sim -runall`
- `xvlog clock_amd.srcs/sources_1/new/uart_rx.v clock_amd.srcs/sources_1/new/uart_tx.v clock_amd.srcs/sources_1/new/protocol_parser.v clock_amd.srcs/sources_1/new/protocol_builder.v clock_amd.srcs/sources_1/new/message_store.v clock_amd.srcs/sources_1/new/preset_reply_rom.v clock_amd.srcs/sources_1/new/comm_ctrl.v sim/comm/tb_comm_ctrl_msg.v`
- `xelab tb_comm_ctrl_msg -s tb_comm_ctrl_msg_sim; xsim tb_comm_ctrl_msg_sim -runall`
- `xvlog clock_amd.srcs/sources_1/new/i2c_master_simple.v clock_amd.srcs/sources_1/new/oled_date_status.v clock_amd.srcs/sources_1/new/oled_countdown_status.v clock_amd.srcs/sources_1/new/oled_notify_status.v clock_amd.srcs/sources_1/new/oled_ui_display.v sim/comm/tb_oled_glyph.v`
- `xelab --timescale 1ns/1ps --override_timeunit --override_timeprecision tb_oled_glyph -s tb_oled_glyph_sim; xsim tb_oled_glyph_sim -runall`
- 全源 `xvlog`
- `xelab --timescale 1ns/1ps --override_timeunit --override_timeprecision clock_amd_top -s clock_amd_top_elab`
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`
- `vivado -mode batch -source scripts/run_phase_impl_timing_check.tcl`
- `git diff --check`

检查结果:

- `tb_message_store` 输出 `PASS tb_message_store`。
- `tb_comm_ctrl_msg` 输出 `PASS tb_comm_ctrl_msg`。
- `tb_oled_glyph` 输出 `PASS tb_oled_glyph`。
- 全源 `xvlog` 通过，顶层 `xelab` 通过。
- Vivado 综合通过并满足约束，最新综合检查显示 `Slack (MET): 1.779ns`。
- 最新综合主要单元计数：`LUT6 5453`、`MUXF7 597`、`MUXF8 136`、`FDRE 2426`、`RAMB18E1 1`。相对上一阶段综合记录的 `LUT6 11178`、`MUXF7 2606`、`MUXF8 1132`、`FDRE 15212`，大 mux 和寄存器占用明显下降。
- 非工程 routed 实现检查通过：`WNS=+0.525ns`、`TNS=0.000ns`、失败端点 `0`，日志显示 `All user specified timing constraints are met.`。
- routed 最差路径已从 `message_store selected_window_ascii` 转移到 `u_clock/u_comm_ctrl/u_protocol_builder/req_reply_text_ascii_reg[9] -> tx_buf_reg[69][0]`，Slack 为 `+0.525ns`，该路径布线占比约 78%，但已满足 100MHz 约束。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换提示。

未完成/阻塞:

- 尚未生成 bitstream，尚未进行 Nexys A7 板级复测。
- 本次只做时序结构优化，未改变顶层端口和 `.xdc` 约束。

已知问题:

- `protocol_parser` 既有 `msg_char_buf_reg` set/reset priority 综合警告仍存在，本阶段未处理。
- `message_store/text_mem_reg` 推断为 Block RAM 后 Vivado 仍提示可选输出寄存器未合入 RAMB，当前 routed 时序已满足，暂不继续加深该读路径。
- 当前 routed 最差路径在 `protocol_builder` 回复文本到 TX buffer 的写入逻辑，仍是布线占比较高的路径；由于已有 `+0.525ns` 裕量，本阶段不继续扩大改动面。
- 工作区仍存在不属于本次任务的历史脏文件和未跟踪文件，本次未回退。

下一阶段计划:

- 生成 bitstream 并上板回归七个模式、数码管扫描、OLED COMM 消息显示和 USB-UART 链路。
- 若后续约束提高或新增功能再次压缩裕量，优先单独优化 `protocol_builder` 的 TX buffer 构造路径，把回复帧拼接拆成更明确的多周期写入流程。

建议提交信息:

- `perf(fpga): pipeline message display paths for timing closure`

### 2026-06-07 1759 - ClockLink Studio 聊天界面美化

Phase:

- Phase 9：PC GUI 完整化与演示体验优化

本次目标:

- 在不增加 GUI 依赖、不修改 UART 协议和服务层行为的前提下，优化 ClockLink Studio 软件界面观感。
- 重点改善 `连接与消息 / Connect` 页聊天界面，让 PC 与 FPGA 的消息互动更适合演示。

完成内容:

- 调整 `ui/main_window.py` 全局视觉参数：窗口默认尺寸、浅色背景、主按钮颜色、边框色和聊天区配色。
- 聊天消息从普通圆角气泡升级为带头像、时间戳、轻量阴影和左右尾部的气泡布局。
- PC 消息保持右侧蓝色气泡，FPGA/mock 回复保持左侧白色气泡，系统消息居中显示。
- 聊天标题区新增 `USB-UART` 状态标签和绿色状态点，强化通信场景识别。
- 聊天画布增加边框层次，输入区改为独立浅色输入栏，减少表单感。
- 同步更新 `software/clocklink_studio/README.md` 和 `docs/ClockLink_Studio_PC_Software_Design.md` 的 GUI 说明。
- 未新增协议命令，未修改 FPGA HDL，未修改串口 transport 和服务层业务逻辑。

修改文件:

- `software/clocklink_studio/ui/main_window.py`
- `software/clocklink_studio/README.md`
- `docs/ClockLink_Studio_PC_Software_Design.md`
- `docs/AGENT_WORKLOG.md`

新增文件:

- 无

删除文件:

- 无

运行检查:

- `cd software/clocklink_studio; python -m py_compile ui\main_window.py`
- `cd software/clocklink_studio; python -m pytest`
- `cd software/clocklink_studio; python desktop.py --self-test`
- `git diff --check`

检查结果:

- `py_compile` 通过。
- `python -m pytest` 通过，17 个测试全部通过。
- `python desktop.py --self-test` 退出码为 0。
- `git diff --check` 未发现空白错误，仅输出 Git CRLF 转换提示。

未完成/阻塞:

- 未启动真实 GUI 进行人工视觉截图验收。
- 尚未在真实 Nexys A7 串口环境下复测聊天收发链路。

已知问题:

- Tkinter 气泡在窗口 resize 后不会重排历史消息宽度；新消息会按当前窗口宽度生成。
- 工作区仍存在不属于本次任务的历史脏文件和未跟踪文件，本次未回退。

下一阶段计划:

- 打开 `python main.py --mock gui` 做人工视觉检查；如需要分发，再重新运行 PyInstaller 打包。

建议提交信息:

- `style(pc): polish clocklink chat interface`

### 2026-06-09 0100 - ClockLink Studio 代码与可执行文件上传准备

Phase:

- Phase 9：PC 软件发布与 Git 远端同步

本次目标:

- 将 ClockLink Studio 相关源码、测试、文档说明和 Windows 可执行程序提交并推送到 GitHub 仓库。
- 只处理 PC 上位机相关文件，避免把当前工作区中的无关 HDL、Vivado 产物或其他历史脏文件带入提交。

完成内容:

- 检查当前 Git 分支为 `feature/clocklink-uart-comm`，远端为 `origin`。
- 执行 `git fetch --all --prune`，确认远端访问正常；当前远端尚无 `feature/clocklink-uart-comm` 分支，后续推送需要设置 upstream。
- 重新运行 PyInstaller，生成最新 `software/clocklink_studio/dist/ClockLinkStudio.exe`，确保 exe 包含当前聊天界面美化和串口主动帧监听逻辑。
- 保持 `software/clocklink_studio/build/`、`__pycache__/`、`.pytest_cache/` 等中间产物忽略，仅准备强制纳入 `dist/ClockLinkStudio.exe`。
- 未修改 FPGA HDL、`.xdc` 或 UART 协议。

准备提交文件:

- `software/clocklink_studio/README.md`
- `software/clocklink_studio/transport/base.py`
- `software/clocklink_studio/transport/serial_transport.py`
- `software/clocklink_studio/ui/main_window.py`
- `software/clocklink_studio/tests/test_serial_transport.py`
- `software/clocklink_studio/dist/ClockLinkStudio.exe`
- `docs/ClockLink_Studio_PC_Software_Design.md`
- `docs/AGENT_WORKLOG.md`

运行检查:

- `cd software/clocklink_studio; python -m PyInstaller --noconfirm ClockLinkStudio.spec`
- `cd software/clocklink_studio; python -m pytest`
- `cd software/clocklink_studio; python desktop.py --self-test`
- `cd software/clocklink_studio; .\dist\ClockLinkStudio.exe --self-test`

检查结果:

- PyInstaller 打包成功，输出 `software/clocklink_studio/dist/ClockLinkStudio.exe`，大小约 11.36 MB。
- `python -m pytest` 通过，17 个测试全部通过。
- `python desktop.py --self-test` 退出码为 0。
- `ClockLinkStudio.exe --self-test` 退出码为 0。

未完成/阻塞:

- 尚未在真实 Nexys A7 串口环境下复测 exe 与 FPGA 的完整链路。
- 尚未完成本条记录后的 commit/push；后续操作将单独 stage 相关文件并推送。

已知问题:

- GitHub 仓库中提交 exe 会增加仓库体积；当前 exe 小于 GitHub 100 MB 单文件限制，因此按用户要求纳入仓库。
- 工作区仍存在不属于本次任务的历史脏文件和未跟踪文件，本次不会回退或提交。

下一阶段计划:

- stage 上述文件，提交 `feat(pc): publish clocklink studio app`，并推送到 `origin/feature/clocklink-uart-comm`。

建议提交信息:

- `feat(pc): publish clocklink studio app`

### 2026-06-09 0125 - 脏文件清理

Phase:

- Phase 9：上板验证后仓库清理

本次目标:

- 用户已确认 Nexys A7 上板验证 OK。
- 清理明显无用的 Vivado/XSim/JVM 工具产物和早期临时草稿。
- 保留已经验证 OK 的 HDL、仿真、脚本和交付文档改动，不误删主线资产。

完成内容:

- 删除根目录下 Vivado/XSim 运行日志、backup 日志、`.pb` 文件、JVM 崩溃 dump/log、`dfx_runtime.txt` 和 `clockInfo.txt`。
- 删除早期初始化草稿 `任务.txt`，其内容已被正式 `AGENTS.md`、`docs/AGENT_WORKFLOW.md`、`docs/AGENT_TASKS.md` 等文档替代。
- `.gitignore` 增加 `clockInfo.txt`，避免 Vivado clock routing debug 文件再次进入未跟踪列表。
- 保留 `scripts/run_phase_impl_timing_check.tcl`、`sim/comm/tb_message_store.v`、`sim/comm/tb_oled_glyph.v` 和未跟踪中文交付文档，后续由人工确认是否纳入提交。

修改文件:

- `.gitignore`
- `docs/AGENT_WORKLOG.md`

删除文件:

- `clockInfo.txt`
- `dfx_runtime.txt`
- `hs_err_pid28816.dmp`
- `hs_err_pid28816.log`
- `hs_err_pid31616.dmp`
- `hs_err_pid31616.log`
- `vivado*.jou`
- `vivado*.log`
- `xelab.log`
- `xelab.pb`
- `xsim*.jou`
- `xsim*.log`
- `xvlog.log`
- `xvlog.pb`
- `任务.txt`

运行检查:

- `git status --short`
- `git ls-files -o --exclude-standard`
- `git diff -- .gitignore`

检查结果:

- 明显工具产物和早期草稿已清理。
- 剩余脏项均为源码/文档/脚本/仿真相关改动或删除记录，未自动回退。

已知问题:

- 工作区仍有 `PROJECT_STATUS.md` 和旧 `docs/功能与修改日志.md` 的删除记录。
- 工作区仍有 HDL 显示/时序优化改动、`sim/comm/README.md` 修改、3 个未跟踪中文文档、实现 timing 脚本和 2 个新增 testbench。

下一步建议:

- 人工确认剩余未跟踪文档和删除记录是否属于交付内容，然后再分组 stage/commit。

建议提交信息:

- `chore: clean generated tool artifacts`

### 2026-06-09 0148 - ClockLink 验收报告终稿整理

Phase:

- 验收报告写作与交付整理

本次目标:

- 在当前 `clock_amd` 项目目录内，基于已有验收报告骨架、README、docs、HDL、XDC、PC 软件、仿真记录和 Vivado 实现报告，产出一份可直接提交和用于课堂验收展示的 ClockLink 智能电子钟系统验收介绍文档。

完成内容:

- 阅读并核验 `README.md`、`HANDOFF.md`、`docs/工程模块使用说明.md`、`docs/ClockLink_Studio_PC_Software_Design.md`、`docs/AGENT_WORKFLOW.md`、`docs/AGENT_TASKS.md`、`docs/AGENT_WORKLOG.md`、`docs/UART_PROTOCOL.md`、`docs/CODEBASE_MAP.md`、`docs/COMM_MODE_FPGA_PLAN.md`、`docs/FINAL_DEMO_GUIDE.md`。
- 阅读核心 HDL、XDC、PC 软件目录、仿真目录和 `clock_amd.runs/impl_1` Vivado routed 报告。
- 建立事实证据清单，区分已实现、已仿真、已生成 bitstream、用户已上板确认和仍建议补截图的内容。
- 生成完整中文验收介绍文档 `验收报告_ClockLink_终稿.md`，按产品展示、技术验收和课程知识总结组织。
- 使用 pandoc 生成 `验收报告_ClockLink_终稿.docx`，并运行格式整理脚本设置页边距、标题/正文字体和表格线框。
- 生成写作工作记录、事实证据清单和最终质量检查清单。

修改/新增文件:

- `验收报告_ClockLink_终稿.md`
- `验收报告_ClockLink_终稿.docx`
- `artifacts/report-writing/agent_report_worklog.md`
- `artifacts/report-writing/fact_check_table.md`
- `artifacts/report-writing/final_quality_checklist.md`
- `artifacts/report-writing/format_report_docx.py`
- `docs/AGENT_WORKLOG.md`

运行检查:

- `python -m pytest`，工作目录 `software/clocklink_studio`
- `pandoc 验收报告_ClockLink_终稿.md -o 验收报告_ClockLink_终稿.docx --toc --toc-depth=3`
- `python artifacts/report-writing/format_report_docx.py`
- `python -c "from docx import Document; ..."` 检查 DOCX 可读取
- `pandoc 验收报告_ClockLink_终稿.md -o 验收报告_ClockLink_终稿.pdf --toc --toc-depth=3 --pdf-engine=xelatex`

检查结果:

- PC 软件 pytest 当前结果：17 项全部通过。
- DOCX 已生成并可由 python-docx 打开；检查到 221 个段落、13 张表。
- Markdown 正文约 28,244 字符，其中中文字符约 12,128。
- PDF 未生成，原因是当前环境缺少 `xelatex`。
- 正式报告采用当前 Vivado `impl_1` routed timing 指标：`WNS=+0.325ns`、`TNS=0.000ns`、失败端点 0，来源为 `clock_amd.runs/impl_1/clock_amd_top_timing_summary_routed.rpt`。
- 资源利用采用 `clock_amd_top_utilization_placed.rpt`：LUT 8184、寄存器 8161、RAMB18 1、DSP 0、IOB 62。

已知边界:

- `MSG_GET/MSG_DATA` 在协议中保留，但 FPGA 当前资源收敛版本返回 unsupported，报告中已写为后续流式读回扩展。
- `ALARM_DUMP/SCHED_DUMP` 当前不写成 FPGA 已实现；报告中说明可通过循环单槽 `GET` 读取。
- ADT7420 温度链路已接入，但仍建议验收前补 OLED 温度读数实拍。
- 真实串口长期稳定性截图、OLED 实拍、Vivado GUI 截图和 pytest 截图建议验收前补充。

下一步建议:

- 在正式提交前补充板卡实物、OLED 页面、ClockLink Studio 真实串口 GUI、Vivado timing/utilization、pytest 17 passed 等截图。
- 如需 PDF，安装 LaTeX/XeLaTeX 或使用 Word/WPS/LibreOffice 从 DOCX 导出。

建议提交信息:

- `docs: add ClockLink acceptance report final draft`

### 2026-06-11 1730 - 整点报时与 OLED ASCII 字库补齐

Phase:

- Phase 9：功能补全与显示资源收口

本次目标:

- 实现整点报时短蜂鸣。
- 补齐 OLED 字库在当前 FPGA/ClockLink 协议可承载范围内的完整可打印 ASCII。
- 明确记录 Unicode/中文显示不属于当前 ASCII UART 协议和 8-bit 消息缓存范围。

完成内容:

- 在 `clock.v` 中新增 `hourly_chime_pulse`，正常自动走时从 `MM:SS=59:59` 滚入下一小时 `HH:00:00` 时触发。
- 在 `notification_ctrl.v` 中新增整点报时输入，输出两段 100 ms 短蜂鸣，中间间隔 100 ms。
- 整点报时不改变 `notify_active/notify_type/notify_slot`，不触发 OLED 弹窗，不锁定 UI；倒计时、闹钟和日程提醒优先覆盖整点报时。
- 将 `oled_ui_display.v` 的字形表整理为 7 行位图，覆盖可打印 ASCII `0x20..0x7E`；空格保持空白，小写 `a-z` 使用独立字形。
- 扩展 `tb_oled_glyph.v`，逐个检查 `0x21..0x7E` 至少有像素，并检查小写与大写区分。
- 新增 `tb_notification_hourly_chime.v`，验证整点短蜂鸣、不产生 notify 状态以及闹钟覆盖整点报时。
- 更新 `README.md`、`docs/工程模块使用说明.md`、`docs/UART_PROTOCOL.md` 和 `sim/comm/README.md`。

修改文件:

- `README.md`
- `clock_amd.srcs/sources_1/new/clock.v`
- `clock_amd.srcs/sources_1/new/notification_ctrl.v`
- `clock_amd.srcs/sources_1/new/oled_ui_display.v`
- `docs/工程模块使用说明.md`
- `docs/UART_PROTOCOL.md`
- `sim/comm/README.md`
- `sim/comm/tb_oled_glyph.v`
- `docs/AGENT_WORKLOG.md`

新增文件:

- `sim/comm/tb_notification_hourly_chime.v`

运行检查:

- `xvlog clock_amd.srcs/sources_1/new/notification_ctrl.v sim/comm/tb_notification_hourly_chime.v`
- `xelab tb_notification_hourly_chime -s tb_notification_hourly_chime_sim`
- `xsim tb_notification_hourly_chime_sim -runall`
- `xvlog clock_amd.srcs/sources_1/new/i2c_master_simple.v clock_amd.srcs/sources_1/new/oled_date_status.v clock_amd.srcs/sources_1/new/oled_countdown_status.v clock_amd.srcs/sources_1/new/oled_notify_status.v clock_amd.srcs/sources_1/new/oled_ui_display.v sim/comm/tb_oled_glyph.v`
- `xelab --timescale 1ns/1ps --override_timeunit --override_timeprecision tb_oled_glyph -s tb_oled_glyph_sim`
- `xsim tb_oled_glyph_sim -runall`
- 全源 `xvlog`
- `xelab --timescale 1ns/1ps --override_timeunit --override_timeprecision clock_amd_top -s clock_amd_top_elab`
- `vivado -mode batch -source scripts/run_phase_synth_check.tcl`

检查结果:

- `tb_notification_hourly_chime` 输出 `PASS tb_notification_hourly_chime`。
- `tb_oled_glyph` 输出 `PASS tb_oled_glyph`。
- 全源 `xvlog` 通过。
- 顶层 `xelab` 通过。
- Vivado 综合通过，日志显示 `synth_design completed successfully` 和 `All user specified timing constraints are met.`。
- 最新综合时序：`WNS=+1.779ns`、`TNS=0.000ns`、失败端点 `0`。

已知问题:

- 尚未重新生成 bitstream，尚未完成 Nexys A7 上板实测。
- Unicode/中文仍不支持；当前 UART 协议、PC 编码器和 FPGA 消息缓存均限制为可打印 ASCII。若后续需要中文，需要单独设计 UTF-8/码点解析、字体 ROM/外部字库和 OLED 渲染流程。
- `protocol_parser` 既有 `msg_char_buf_reg` set/reset priority 综合 warning 仍存在，本次未处理。
- 工作区仍存在本次任务之外的历史脏文件和未跟踪交付文档，本次未回退。

下一步建议:

- 重新生成 bitstream 并上板验证整点蜂鸣、闹钟覆盖整点蜂鸣、COMM 消息大小写和标点显示。
- 若需要真正 Unicode/中文显示，先冻结新的文本编码和字库架构，不应直接在现有 ASCII 帧里发送 UTF-8。

建议提交信息:

- `feat(fpga): add hourly chime and printable ascii oled font`

### 2026-06-11 2007 - 远端同步检查与本地改动发布

Phase:

- Phase 9：Git 远端同步

本次目标:

- 检查 `origin/feature/clocklink-uart-comm` 是否包含本地最新代码。
- 若远端未包含本地改动，则提交并推送本地代码。

完成内容:

- 使用 `git fetch --all --prune` 更新远端引用。
- 确认当前分支为 `feature/clocklink-uart-comm`，跟踪 `origin/feature/clocklink-uart-comm`。
- 确认本地 HEAD 与 upstream 提交计数为 `0/0`，即已提交历史相同。
- 发现工作区仍有未提交源码、文档、仿真和报告改动，因此准备以新提交同步到远端。
- 将 `vivado_pid*.str` 加入 `.gitignore`，避免 Vivado 临时字符串文件进入源码管理。

修改/新增文件范围:

- FPGA HDL：显示路径时序优化、整点报时、OLED ASCII 字库。
- 仿真：消息缓存、OLED 字库、整点报时 testbench。
- 脚本：实现后 timing 检查脚本。
- 文档：README、工程说明、UART 协议、AGENT 工作日志、验收报告和相关写作材料。
- 清理：删除旧状态/旧日志文档，保留当前 `README.md`、`docs/AGENT_WORKLOG.md` 和新报告体系。

运行检查:

- `git fetch --all --prune`
- `git rev-list --left-right --count HEAD...origin/feature/clocklink-uart-comm`
- `git status -sb`
- `git diff --check`

检查结果:

- 远端可访问，fetch 成功。
- 本地 HEAD 与远端 HEAD 起点一致，但远端缺少工作区未提交改动。
- `git diff --check` 未发现空白错误，仅有 LF/CRLF 转换提示。

已知问题:

- 本记录写入时尚未完成 commit/push；提交与推送结果将在命令执行后由本次对话最终回复说明。

下一步建议:

- 完成 commit 后推送到 `origin/feature/clocklink-uart-comm`。

建议提交信息:

- `feat: finalize clocklink fpga features and docs`

### 2026-06-11 2132 - PPT 字体替换

Phase:

- 交付材料整理

本次目标:

- 将当前 `PPT/` 文件夹内 PPTX 文档中的 `Noto Sans CJK SC` 字体替换为更清楚大气且 Windows/PPT 常见的字体。

完成内容:

- 扫描 `PPT/` 下 `.pptx` 文件。
- 将 `ClockLink智能时钟终端_验收讲解PPT_优化讲解版.pptx` 内部 OpenXML 中的 `Noto Sans CJK SC` 字体声明替换为 `Microsoft YaHei`。
- 保持幻灯片文字内容和页面结构不变。

修改文件:

- `PPT/ClockLink智能时钟终端_验收讲解PPT_优化讲解版.pptx`
- `docs/AGENT_WORKLOG.md`

新增文件:

- 无

运行检查:

- Python 扫描 PPTX ZIP/XML 中 `Noto Sans CJK SC` 出现次数。
- Python 重写 PPTX ZIP 包并替换字体声明。
- Python `zipfile.testzip()` 检查 PPTX 压缩包完整性。
- Python `xml.etree.ElementTree.fromstring()` 检查 PPTX 内 XML 可解析。
- Python 复查 `Noto Sans CJK SC` 和 `Microsoft YaHei` 出现次数。

检查结果:

- 替换前：`Noto Sans CJK SC` 共 590 处，分布在 28 个幻灯片 XML 文件中。
- 替换后：`Noto Sans CJK SC` 为 0 处，`Microsoft YaHei` 为 590 处。
- `zipfile.testzip()` 通过。
- XML 解析错误数为 0。

已知问题:

- 未打开 PowerPoint 做人工视觉检查；建议最终提交前用 PowerPoint/WPS 快速翻页确认页面观感。

下一步建议:

- 若需要更强的正式演示风格，可再统一替换为 `Microsoft YaHei UI` 或 `DengXian` 并人工对比版式。

### 2026-06-12 1133 - 项目阅读与状态理解

Phase:

- 项目交接阅读 / 当前状态梳理

本次目标:

- 阅读当前 `clock_amd` 项目，了解 Vivado 工程、ClockLink 通信扩展、PC 上位机和验证状态。

完成内容:

- 已按 `AGENTS.md` 要求阅读 `README.md`、`HANDOFF.md`、`docs/工程模块使用说明.md`、`docs/ClockLink_Studio_PC_Software_Design.md`、`docs/AGENT_WORKFLOW.md`、`docs/AGENT_TASKS.md`、`docs/AGENT_WORKLOG.md`。
- 已补充阅读 `docs/UART_PROTOCOL.md`、`docs/CODEBASE_MAP.md`、`clock_amd.xdc`、`sim/comm/README.md` 和综合检查脚本。
- 已阅读关键 HDL：`clock_amd_top.v`、`clock.v`、`ui_ctrl.v`、`display_ctrl.v`、`comm_ctrl.v`、`protocol_parser.v`、`protocol_builder.v`、`message_store.v`、`time_core.v`、`date_core.v`、`countdown_ctrl.v`、`notification_ctrl.v`、`alarm_ctrl.v`、`schedule_ctrl.v`。
- 已阅读关键 PC 软件源码：`main.py`、`protocol/commands.py`、`protocol/codec.py`、`services/client.py`、`transport/mock_transport.py`、`transport/serial_transport.py`。

修改文件:

- `docs/AGENT_WORKLOG.md`

新增文件:

- 无

运行检查:

- `rg --files`
- `git status -sb`
- 多个 `Get-Content` / `rg` 源码与文档阅读命令

检查结果:

- 当前项目是 Nexys A7 Vivado 多功能时钟工程，已集成 `CLOCK / TIME / ALARM / HOUR / COUNT / SCHED / COMM` 七模式。
- ClockLink Studio 通信链路已包含 UART、ASCII 帧协议、消息缓存、预设回复、时间同步、闹钟/日程/倒计时 PC 直接控制和 Tkinter 上位机。
- 当前协议限制仍为可打印 ASCII；Unicode/中文消息不属于第一版 FPGA 协议和字库范围。
- `MSG_GET/MSG_DATA` 在协议中保留，但当前 FPGA 端仍以 unsupported/NACK 处理；PC mock 支持该功能用于软件演示。
- 本次未运行 Vivado、XSim 或 pytest，因为任务仅为项目阅读和状态理解。

已知问题:

- 工作区已有未提交改动：`docs/AGENT_WORKLOG.md`，以及未跟踪 `PPT/`、`贡献表/`；本次未回退或清理。
- 最新文档记录显示整点报时和 OLED ASCII 字库补齐后尚未重新生成 bitstream，也尚未完成对应 Nexys A7 上板实测。

下一步建议:

- 若继续开发，优先明确下一阶段是生成 bitstream/板级复测、修复 `protocol_parser` warning，还是实现 FPGA 流式 `MSG_GET/MSG_DATA`。

### 2026-06-12 1137 - 贡献表阅读与比例建议

Phase:

- 交付材料阅读 / 贡献度建议

本次目标:

- 阅读 `贡献表/` 目录下的 Word 贡献表内容，判断在尽量均分前提下各成员贡献度填写的大致合理范围。

完成内容:

- 已读取 `贡献表/课程设计贡献度表1.docx`，确认是空白模板。
- 已读取 `贡献表/课程设计贡献度表1_CLOCK项目分工负责表.docx`，确认包含 CLOCK/ClockLink 四名成员分工说明，贡献度栏未填写。
- 已读取 `贡献表/课程设计贡献度表1_工程项目二VGA游戏集合机贡献表.docx`，确认 VGA 表当前贡献度为杨龙驹 40%、樊逸晨 20%、蒲佳鑫 20%、方睿锦 20%。
- 已读取 `贡献表/课程设计贡献度表1_实验一CLOCK与自主项目VGA合并版.docx`，确认合并表包含 CLOCK 与 VGA 两部分分工说明，贡献度栏未填写。

修改文件:

- `docs/AGENT_WORKLOG.md`

新增文件:

- 无

运行检查:

- `Get-ChildItem -LiteralPath .\贡献表`
- 使用 `python-docx` 读取 4 个 `.docx` 的段落和表格内容

检查结果:

- 若严格均分，四人可写 25% / 25% / 25% / 25%。
- 若保持分工描述可信且尽量接近均分，CLOCK 表建议杨龙驹略高，其他三人接近：28% / 24% / 24% / 24%。
- VGA 表当前 40% / 20% / 20% / 20% 偏向组长；若希望更均衡，可改为 31% / 23% / 23% / 23%，或更接近均分的 28% / 24% / 24% / 24%。
- CLOCK+VGA 合并表建议使用 28% / 24% / 24% / 24% 或 31% / 23% / 23% / 23%，取决于是否强调组长承担公共架构、集成和验收材料。

已知问题:

- 本次只阅读并给出比例建议，未修改任何 `.docx` 文件。

下一步建议:

- 若需要直接填写贡献度，建议先选定“严格均分”还是“组长略高但接近均分”的口径，再批量修改对应 Word 表格。

### 2026-06-12 1202 - 源代码中文注释补充

Phase:

- 源码可读性整理 / 中文注释补充

本次目标:

- 在不修改功能逻辑、不重构代码的前提下，为当前项目 HDL 和 PC 软件源代码补充较详细的中文注释，便于课程验收、交接和后续维护。

完成内容:

- 为 `clock_amd.srcs/sources_1/new/` 下全部 Verilog 源文件补充中文模块头注释，说明模块职责、接口边界、复位/时序约定和当前限制。
- 为核心 HDL 增加关键路径注释：`clock.v` 主线集成、`ui_ctrl.v` 模式/设置层规则、`display_ctrl.v` 数码管字符选择、`comm_ctrl.v` 命令分发、`protocol_parser.v` 固定顺序解析、`protocol_builder.v` 构帧、`message_store.v` 环形缓存和 OLED 窗口重建、`notification_ctrl.v` 统一提醒和整点报时。
- 为 PC 上位机 Python 源码补充中文模块 docstring、类说明和关键函数注释，覆盖 CLI、桌面启动器、协议编解码、命令构造、client、mock/serial transport、服务层、GUI 和测试文件。
- 未修改 UART 协议、功能逻辑、顶层端口或约束文件。

修改文件:

- HDL：`clock_amd.srcs/sources_1/new/*.v`
- PC 软件：`software/clocklink_studio/**/*.py`
- 工作日志：`docs/AGENT_WORKLOG.md`

新增文件:

- 无

运行检查:

- `python -m compileall -q software\clocklink_studio`
- `cd software/clocklink_studio; python -m pytest`
- `xvlog clock_amd.srcs\sources_1\new\protocol_parser.v`
- `vivado -mode batch -source scripts\run_phase_synth_check.tcl`
- `git diff --check`
- `git status -sb`

检查结果:

- Python 编译检查通过。
- PC 软件 pytest 通过，17 项全部通过。
- `protocol_parser.v` 单文件 `xvlog` 通过。
- 全源单独 `xvlog` 和个别单文件 `xvlog` 曾在工具时间预算内未返回且没有有效错误日志；随后使用项目综合脚本完成更完整 HDL 验证。
- Vivado 综合检查通过，日志显示 `synth_design completed successfully` 和 `All user specified timing constraints are met.`。
- 最新综合时序仍为 `Slack (MET): 1.779ns`，`TNS=0.000ns`，失败端点 0。
- `git diff --check` 未发现空白错误，仅有 Git LF/CRLF 转换提示。

已知问题:

- 本次只补充注释，没有生成 bitstream，也没有做板级复测。
- Vivado 仍保留既有 `protocol_parser msg_char_buf_reg` set/reset priority warning；本次未改逻辑，因此未处理该 warning。
- 工作区仍有历史未跟踪目录 `PPT/` 和 `贡献表/`，本次未清理。

下一步建议:

- 若后续需要提交，可按“注释整理”单独提交，建议提交信息：`docs(code): add Chinese source comments`。
- 若后续继续做功能增强，优先处理 `protocol_parser` 暂存结构 warning 或 FPGA 流式 `MSG_GET/MSG_DATA`。

### 2026-06-12 1448 - 最新功能分支并入 main

Phase:

- Git 远端同步 / main 分支更新

本次目标:

- 将当前最新分支 `feature/clocklink-uart-comm` 并入 `main`。
- 保留已有未跟踪交付材料目录，不把无关文件误加入本次提交。

完成内容:

- 已按仓库要求阅读 README、HANDOFF、工程说明、PC 软件设计、AGENT 工作流、任务列表和工作日志。
- 已使用 `git fetch --all --prune` 更新远端引用。
- 确认当前最新提交分支为 `feature/clocklink-uart-comm`。
- 确认本地 `main` 是 `feature/clocklink-uart-comm` 的祖先，可执行快进合并，无需冲突解决。
- 先提交当前 feature 分支上已跟踪的中文注释整理和本记录，再快进 `main`。
- 未跟踪目录 `PPT/` 和 `贡献表/` 不纳入本次提交。

修改文件:

- HDL：`clock_amd.srcs/sources_1/new/*.v`
- PC 软件：`software/clocklink_studio/**/*.py`
- 工作日志：`docs/AGENT_WORKLOG.md`

新增文件:

- 无

运行检查:

- `git fetch --all --prune`
- `git branch -a --sort=-committerdate`
- `git log --oneline --decorate --graph --all -n 25`
- `git merge-base --is-ancestor main feature/clocklink-uart-comm`
- `git diff --check`

检查结果:

- `feature/clocklink-uart-comm` 是当前最近更新的功能分支。
- 本地 `main` 可以快进到该功能分支。
- `git diff --check` 未发现空白错误，仅有 Git LF/CRLF 转换提示。

已知问题:

- 本次 Git 合并不重新运行 Vivado/XSim/pytest；沿用上一条记录中的注释整理验证结果。
- `PPT/` 和 `贡献表/` 仍为未跟踪目录，按当前任务范围保持不变。

下一步建议:

- 快进 `main` 后推送到远端 `origin/main`，再检查本地与远端提交一致性。
