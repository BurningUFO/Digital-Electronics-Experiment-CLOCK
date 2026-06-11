# ClockLink 验收报告最终质量检查清单

检查时间：2026-06-09

## 1. 交付文件

| 检查项 | 结果 | 说明 |
| --- | --- | --- |
| 终稿 Markdown 已生成 | 通过 | `验收报告_ClockLink_终稿.md` |
| 终稿 DOCX 已生成 | 通过 | `验收报告_ClockLink_终稿.docx`，pandoc 生成，python-docx 可打开 |
| 写作工作记录已生成 | 通过 | `artifacts/report-writing/agent_report_worklog.md` |
| 事实证据清单已生成 | 通过 | `artifacts/report-writing/fact_check_table.md` |
| 最终质量检查清单已生成 | 通过 | 本文件 |
| PDF 导出 | 未生成 | 当前环境缺少 `xelatex`，`pandoc --pdf-engine=xelatex` 失败 |

## 2. 内容覆盖

| 检查项 | 结果 | 说明 |
| --- | --- | --- |
| 覆盖基础验收要求 | 通过 | 时/分/秒显示、分频、复位、校时、动态扫描、稳定性均已独立成节 |
| 体现扩展功能加分价值 | 通过 | 12/24 小时制、8 槽位闹钟、倒计时、8 槽位日程、统一提醒、OLED、温度链路、USB-UART、ClockLink Studio |
| 把项目讲成产品 | 通过 | 正文以“时间管理终端”和用户场景组织，不是代码清单堆砌 |
| 课程知识点完整 | 通过 | 同步时序、计数分频、状态机、消抖、动态扫描、UART/I2C、XDC、Vivado 时序均有对应项目实现 |
| 表格数量满足要求 | 通过 | 文档包含验收对照、资源、模块、七模式、时序、验证体系、演示流程、完成度边界等表格 |
| 图占位规范 | 通过 | 使用正式图占位，如“此处插入……截图/结构图”，未使用粗糙 TODO |
| 现场演示脚本 | 通过 | 第 10 章给出基础功能、扩展功能和 ClockLink Studio 演示流程 |
| 当前不足与后续计划 | 通过 | 第 11 章列出完成度、边界和后续迭代方向 |

## 3. 事实准确性

| 检查项 | 结果 | 说明 |
| --- | --- | --- |
| 平台与器件 | 通过 | Nexys A7-100T / `xc7a100tcsg324-1` |
| 主时钟与约束 | 通过 | `CLK100MHZ`，`create_clock -period 10.000` |
| 复位极性 | 通过 | `CPU_RESETN` 低有效 |
| 数码管特性 | 通过 | 共阳极、位选/段选低有效、动态扫描 |
| 七模式顺序 | 通过 | `CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM -> CLOCK` |
| 闹钟数量 | 通过 | 8 槽位 |
| 日程数量 | 通过 | 8 槽位/固定计划点 |
| 消息缓存数量 | 通过 | 最近 16 条消息 |
| 预设回复数量 | 通过 | 8 条固定回复 |
| UART 参数与引脚 | 通过 | `115200 8N1`，`UART_RXD=C4`，`UART_TXD=D4` |
| OLED/ADT7420 引脚 | 通过 | OLED `D14/F16`，ADT7420 `C14/C15` |
| WNS/TNS 指标 | 通过 | 使用 `impl_1` routed report：`WNS=+0.325ns`，`TNS=0.000ns`，失败端点 0 |
| 资源利用 | 通过 | LUT 8184、寄存器 8161、RAMB18 1、DSP 0、IOB 62 |
| PC 测试数量 | 通过 | 本次实跑 `17 passed` |
| 上板状态 | 通过 | 写为“用户已确认 Nexys A7 上板验证 OK”，同时建议补实拍截图 |

## 4. 边界诚实性

| 边界项 | 处理结果 |
| --- | --- |
| README/HANDOFF 旧状态仍写未生成 bitstream | 报告说明旧记录已落后于当前 `impl_1` 和用户上板确认 |
| `MSG_GET/MSG_DATA` | 写为协议预留/当前 FPGA 返回 unsupported，不写成已完整实现 |
| `ALARM_DUMP/SCHED_DUMP` | 写为协议预留，当前通过循环单槽 GET |
| ADT7420 温度稳定性 | 写为链路已接入，建议补 OLED 温度实拍 |
| 真实串口长期稳定性 | 写为当前验收前上板 OK，长期压力测试作为后续迭代 |
| DRC/methodology warning | 写为无实现错误但存在 warning，后续工程规范优化 |

## 5. 格式与可读性

| 检查项 | 结果 | 说明 |
| --- | --- | --- |
| Markdown 可读 | 通过 | 章节层级清楚，表格可读 |
| DOCX 可打开 | 通过 | python-docx 检查：221 个段落，13 张表 |
| 自动目录条件 | 通过 | pandoc 生成时使用 `--toc --toc-depth=3` |
| DOCX 基础格式整理 | 通过 | 已运行 `artifacts/report-writing/format_report_docx.py`，设置页边距、标题/正文字体和表格线框 |
| 未留下粗糙未完成标记 | 通过 | 未发现 `TODO`、`随便`、`以后补` 等粗糙标记 |
| 正文长度 | 通过 | Markdown 约 28,244 字符，其中中文字符约 12,128 |
