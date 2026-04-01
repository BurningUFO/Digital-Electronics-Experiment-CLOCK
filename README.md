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

后续将在此基础上继续补充校时、整点报时、闹钟和其他扩展功能。

## 项目成员

当前组员名单如下：

1. BurningUFO
2. 杨龙驹
3. 蒲佳鑫
4. 樊逸晨
5. 方睿锦

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
4. [inf.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/inf.md)：实验平台与硬件信息整理
5. [管脚.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/管脚.md)：当前工程引脚对应说明
6. [功能与修改日志.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/功能与修改日志.md)：功能和修改记录
7. [组员Git协作指南.md](/C:/Users/YOUNG/Desktop/workplace/2025_2026_2/SDSY/CLOCK/组员Git协作指南.md)：Git 使用与协作流程指南

## 维护说明

本仓库用于组内协作开发和课程设计维护。请所有成员保持提交规范、日志规范和分支规范，确保后续整合、验收和答辩材料整理不会失控。
