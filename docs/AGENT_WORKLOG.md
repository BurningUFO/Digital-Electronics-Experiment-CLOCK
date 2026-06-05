# AGENT_WORKLOG

本文件用于记录 agent 每次工作的阶段、修改内容、验证结果和下一步计划。

## 当前状态

- 当前阶段：Phase 9 GUI 完整化、验收文档完成
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
