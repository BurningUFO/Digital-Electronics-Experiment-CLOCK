# ClockLink Studio

ClockLink Studio 是 `clock_amd` 的 PC 上位机软件。当前已实现协议库、mock FPGA、服务层、CLI demo、Tkinter GUI 演示面板、预设回复 mock 事件和 pytest 单元测试；真实串口 transport 已提供接口，尚未在真实 Nexys A7 上板实测。

## 运行

```bash
cd software/clocklink_studio
python main.py --mock
python main.py --mock ping
python main.py --mock sync-time
python main.py --mock time-get
python main.py --mock send-message "Hello FPGA"
python main.py --mock mock-reply --slot 0 --reply 1
python main.py --mock alarm-set --slot 0 --time 07:30:00 --enable 1
python main.py --mock alarm-get --slot 0
python main.py --mock sched-set --slot 0 --time 08:00:00 --type 0 --enable 1
python main.py --mock sched-get --slot 0
python main.py --mock count-set --time 00:05:00
python main.py --mock count-start
python main.py --mock count-status
python main.py --mock gui
```

真实串口模式示例：

```bash
python main.py --port COM5 ping
python main.py --port COM5 gui
```

## 测试

```bash
python -m pytest
```

## 预设回复 mock

Phase 6 增加了 FPGA 主动 `REPLY` 事件的 mock 入口：

```bash
python main.py --mock mock-reply --slot 0 --reply 1
```

该命令会生成并解析一条 `REPLY` 帧，输出 payload 和解码后的回复正文，例如 `Busy now.`。真实串口异步监听还未完整实现，后续 GUI/serial 阶段需要增加持续读串口和事件日志窗口。

## 时间同步

Phase 7 已对齐 FPGA `TIME_SET/TIME_GET/TIME` 子集：

- `python main.py --mock sync-time` 发送当前 PC 日期时间，mock 返回 `ACK ... cmd=TIME_SET`。
- `python main.py --mock time-get` 返回 mock 板子当前日期时间。
- `TIME_SET` payload 固定为 `date=YYYY-MM-DD;time=HH:MM:SS;weekday=N`，该顺序由测试保护，用于匹配 FPGA 第一版资源受限解析器。

## 闹钟、日程和倒计时控制

Phase 8 已对齐 FPGA 直接写入/读取接口：

- `alarm-set/alarm-get` 读写 8 个闹钟槽，payload 顺序为 `slot=N;time=HH:MM:SS;enable=0|1`。
- `sched-set/sched-get` 读写 8 个日程槽，payload 顺序为 `slot=N;time=HH:MM:SS;type=N;enable=0|1`。
- `count-set` 直接加载倒计时初值并停止倒计时；需要运行时再发送 `count-start`。
- `count-stop/count-status` 直接控制和查询倒计时，不要求 FPGA 当前处于 COUNT 模式。

## GUI

```bash
python main.py --mock gui
python main.py --port COM5 gui
```

GUI 使用 Tkinter，不增加额外依赖。当前面板包含：

- `Connect`：HELLO、PING、STATUS、同步时间、读取时间、发送消息、读取 mock 消息槽。
- `Control`：闹钟槽读写、日程槽读写、倒计时设置/启动/停止/查询。
- `Log`：显示每次请求的回复帧，mock 下可用于完整演示；真实串口异步 `REPLY/EVENT` 持续监听仍是后续增强项。

## Windows EXE

已提供桌面入口 `desktop.py`，可双击启动后选择串口或 mock 模式：

```bash
python desktop.py
```

当前已用 PyInstaller 生成：

```text
software/clocklink_studio/dist/ClockLinkStudio.exe
```

重新打包命令：

```bash
python -m PyInstaller --noconfirm ClockLinkStudio.spec
```

打包产物 `dist/ClockLinkStudio.exe` 可以直接拷到 Windows 电脑运行。`build/` 是 PyInstaller 中间目录，不需要提交。

## 当前模块

- `protocol/`：帧编解码、XOR 校验、命令构造。
- `transport/mock_transport.py`：不接 FPGA 的 mock 板子。
- `transport/serial_transport.py`：真实串口接口，依赖 `pyserial`。
- `services/`：时间、消息、闹钟、日程、倒计时服务封装。
- `ui/main_window.py`：Tkinter GUI 演示面板。
