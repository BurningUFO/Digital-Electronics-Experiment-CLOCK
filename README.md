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
9. 闹铃已支持时间设置、开关控制、实时到点比较和 `LG1.dp` 提醒输出

当前主线最近一次本地验证状态：

1. Quartus 全编译通过
2. `0 errors`
3. Fitter 成功，Timing 通过
4. 资源占用约 `124 / 128` macrocells

后续将在此基础上继续补充 12/24 小时制切换、课程作息提醒、闹铃消音/保持策略和其他扩展功能。

## 最近一次交互与结构重构说明

为解决“当前模式不可见、按 `QD` 循环切换后容易忘记自己处于哪一态”的现实问题，主线最近将模式控制从“按键循环状态机”重构为“独立模式开关优先级选择”。当前模式由 `K1~K5` 直接决定，`QD` 只负责执行当前模式内的动作。

本轮重构重点如下：

1. 在 `mode_ctrl.v` 中把“由 `QD` 驱动的寄存器状态机”改为“由 `K1~K5` 高位优先解码得到 `mode_state`”
2. 在 `key_ctrl.v` 中删除 `key_mode_pulse`，让 `QD` 不再负责模式轮换
3. 在 `clock.v` 中新增五路独立模式选择输入，并把它们送入 `mode_ctrl`
4. 在 `clock.qsf` 中新增五路模式选择输入的管脚约束
5. 在文档中同步改写了所有“连续按模式切换”的操作说明

本轮文档记录的贡献人按全组统计：

1. 杨龙驹
2. 蒲佳鑫
3. 樊逸晨
4. 方睿锦

## 当前模式选择规则

当前工程的模式不再通过 `QD` 轮流切换，而是通过五个独立模式选择信号直接决定：

1. `K1`：校时模式
2. `K2`：闹铃模式
3. `K3`：12/24 小时制模式
4. `K4`：倒计时模式
5. `K5`：作息提醒模式

当前闹铃提醒方式说明：

1. 在闹铃模式下通过 `001 + QD` 调小时、`010 + QD` 调分钟、`011 + QD` 开关闹铃
2. 闹铃开启后，只要当前时间的小时和分钟与设定闹铃一致，`LG1.dp` 会点亮作为提醒输出
3. 为节省宏单元，当前采用“当前时分持续比较”的提醒方式，因此提醒会在匹配的整个分钟内保持有效

优先级规则为：

`K5 > K4 > K3 > K2 > K1 > 默认正常模式`

也就是说：

1. 所有模式开关都关闭时，系统处于正常时钟模式
2. 若多个模式开关同时打开，则高位模式优先
3. 进入倒计时模式时，直接打开 `K4` 即可，不需要再按很多次 `QD`

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
