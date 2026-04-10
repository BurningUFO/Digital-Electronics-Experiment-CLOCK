# Digital Electronics Experiment CLOCK

## 项目简介

本项目为数字逻辑与数字系统课程设计中的电子钟实验工程，基于 TEC-8 实验平台和 `EPM7128SLC84-15` CPLD 实现。

当前基础版本已完成：

1. 24 小时制电子钟计时
2. 时、分、秒三级正确进位
3. 低电平复位清零
4. TEC-8 实验箱基础显示与引脚分配
5. `LG1` 七段译码显示
6. `LG2` 到 `LG6` 的 `8421` 码输出
7. 校时模式下的小时/分钟调整
8. 倒计时基础版接入主线，支持 `MM:SS` 设置、启动、暂停和到零自动停止

当前主线最近一次本地验证状态：

1. Quartus 全编译通过
2. `0 errors`
3. Fitter 成功，Timing 通过
4. 资源占用约 `121 / 128` macrocells

后续将在此基础上继续补充闹钟、12/24 小时制切换、课程作息提醒和其他扩展功能。

## 最近一次资源优化说明

为适配 `EPM7128SLC84-15` 仅有 `128` 个宏单元的限制，主线最近完成了一轮本地面积优化，当前版本相比倒计时刚接入主线时的 `124 / 128` macrocells，进一步压缩到 `121 / 128`。

本轮优化重点如下：

1. 在 `clock.qsf` 中启用 `AREA` 优化和 `AUTO_RESOURCE_SHARING`
2. 在 `mode_ctrl.v` 中删去一组长期导出的模式使能信号，只保留 `mode_state`
3. 在 `clock.v` 中仅对当前实际使用的模式做按需顶层解码
4. 在 `display_ctrl.v` 中将显示选择逻辑改写为更紧凑的连续赋值
5. 在 `key_ctrl.v` 中缩小按键消抖计数器位宽和门限

本轮文档记录的贡献人按全组统计：

1. 杨龙驹
2. 蒲佳鑫
3. 樊逸晨
4. 方睿锦

## 项目成员

当前组员名单如下：

1. 杨龙驹
2. 蒲佳鑫
3. 樊逸晨
4. 方睿锦

如后续成员信息有调整，请同步修改 [功能与修改日志.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/功能与修改日志.md) 和本文件。

## 仓库使用提醒

所有组员在开始协作前，请先阅读：

1. [组员Git协作指南.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/组员Git协作指南.md)
2. [功能与修改日志.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/功能与修改日志.md)

请务必遵守以下规则：

1. 不要直接在 `main` 分支上开发新功能。
2. 每次开发前先从最新 `main` 创建自己的分支。
3. 提交前先本地检查或编译，避免把明显错误推上仓库。
4. 每次完成功能后，及时补充 `功能与修改日志.md`。
5. 修改涉及公共模块时，要在日志里写清楚影响范围。
6. 不要把 Quartus 自动生成的中间文件和缓存文件重新加入仓库。

## 主要文件说明

1. [clock.v](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/clock.v)：主 Verilog 工程代码
2. [clock.qsf](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/clock.qsf)：Quartus 引脚与工程配置
3. [clock.qpf](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/clock.qpf)：Quartus 工程文件
4. [countdown_ctrl.v](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/countdown_ctrl.v)：倒计时主线模块
5. [工程模块使用说明.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/工程模块使用说明.md)：当前主线模块和交互说明
6. [inf.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/inf.md)：实验平台与硬件信息整理
7. [管脚.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/管脚.md)：当前工程引脚对应说明
8. [功能与修改日志.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/功能与修改日志.md)：功能和修改记录
9. [组员Git协作指南.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/组员Git协作指南.md)：Git 使用与协作流程指南

## 维护说明

本仓库用于组内协作开发和课程设计维护。请所有成员保持提交规范、日志规范和分支规范，确保后续整合、验收和答辩材料整理不会失控。
