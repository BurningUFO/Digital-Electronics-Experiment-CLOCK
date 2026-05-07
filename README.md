# CLOCK to AMD

这个仓库现在只保留两类核心内容：

1. `clock_amd/`
   当前开发主线，Vivado / Nexys A7 100T 工程
2. `docs/`
   使用说明、修改日志和外设资料

## 当前主线

主线工程位于 `clock_amd/`，入口如下：

- 工程文件：`clock_amd/clock_amd.xpr`
- 顶层文件：`clock_amd/clock_amd.srcs/sources_1/new/clock_amd_top.v`
- 主线集成：`clock_amd/clock_amd.srcs/sources_1/new/clock.v`

当前已经接入的功能：

1. `CLOCK` 正常走时
2. `TIME` 时分秒编辑
3. `ALARM` 时分秒与使能编辑
4. `ALARM` 到秒匹配与蜂鸣器提醒
5. `COUNT` `HH:MM:SS` 倒计时
6. OLED 模式显示、编辑边框和滑动切换

## 当前交互

模式顺序：

`CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> CLOCK`

按键规则：

1. `BTNL / BTNR`：切换模式或切换字段
2. `BTNC`：进入或退出编辑
3. `BTNU / BTND`：修改当前字段
4. `COUNT` 非编辑态下：`BTNU = RUN`，`BTND = STOP`

## 仓库结构

```text
CLOCK/
├─ README.md
├─ clock_amd/
└─ docs/
```

说明：

1. 根目录不再保留旧平台散落的 `.v`、`.qpf`、`.qsf`
2. Quartus 的缓存、报告和评审快照不再留在仓库主视图
3. 后续新增功能只基于 `clock_amd/` 主线继续开发

## 文档入口

- `docs/工程模块使用说明.md`
- `docs/功能与修改日志.md`
- `docs/OLED模块上手文档.md`
- `docs/有源蜂鸣器模块上手文档.md`

## 使用方式

1. 打开 `clock_amd/clock_amd.xpr`
2. 运行 `Synthesis`
3. 运行 `Implementation`
4. 生成 `Bitstream`
5. 下载到板子

如果改了 HDL 或 `.xdc`，需要重新生成 bitstream 后再下载。
