# HANDOFF

## 你接手时必须先知道的约定

1. 本目录 `clock_amd` 是唯一最终工作区
2. 以后只修改本目录内文件
3. 不要把 `CLOCK/` 里的旧副本当主线继续开发
4. Vivado 工程入口固定为 `clock_amd.xpr`

## 允许修改的核心目录

- `clock_amd.srcs/sources_1/new/`
- `clock_amd.srcs/constrs_1/new/`
- `docs/`
- 根目录下的 `README.md / PROJECT_STATUS.md / HANDOFF.md`

## 不建议直接碰的内容

- `.Xil/`
- `clock_amd.cache/`
- `clock_amd.hw/`
- `clock_amd.ip_user_files/`
- `clock_amd.runs/`
- `clock_amd.sim/`
- `vivado*.log`
- `vivado*.jou`
- `dfx_runtime.txt`

这些基本都是工具生成物，不是主线源码。

## 接手时建议先读

1. `README.md`
2. `PROJECT_STATUS.md`
3. `docs/工程模块使用说明.md`
4. `docs/功能与修改日志.md`

## 当前主线重点模块

- `clock.v`：系统主线集成
- `clock_amd_top.v`：顶层板级接线
- `ui_ctrl.v`：统一 UI 控制
- `display_ctrl.v`：数码管显示与闪烁
- `oled_ui_display.v`：OLED UI
- `alarm_ctrl.v`：闹钟与蜂鸣器
- `countdown_ctrl.v`：倒计时
- `time_core.v`：当前时间内核

## 当前已知背景

1. 闹钟蜂鸣器已经可以正常工作
2. 倒计时结束提醒链路已经接入，但仍需要继续实板验证
3. 用户希望后续所有开发都以本目录为唯一工作区
4. 后续还要把 Git 仓库根正式迁到本目录
