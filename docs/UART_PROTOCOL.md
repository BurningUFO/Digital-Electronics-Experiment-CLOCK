# UART_PROTOCOL

状态：Phase 1 冻结版；Phase 8 已记录 FPGA 实现子集。

所有 PC 上位机与 FPGA 的 USB-UART 通信命令必须以本文档为准。未写入本文档的命令不得直接实现。

## 1. 物理链路

| 项 | 定义 |
| --- | --- |
| 物理接口 | Nexys A7 J6 USB-UART |
| 波特率 | `115200` |
| 数据位 | `8` |
| 校验 | `N` |
| 停止位 | `1` |
| 流控 | 无 |
| 编码 | ASCII |
| 行结束 | `\n`，即 `0x0A` |

第一版限制：

- 单条 PC 消息正文不超过 100 个 ASCII 可打印字符。
- 消息正文支持 `0x20` 到 `0x7E`。
- 中文、换行、富文本和二进制文件不属于第一版目标。
- FPGA 接收缓冲建议至少 320 字节，超过长度立即丢弃本帧并返回 `NACK/RX_OVERFLOW`。

## 2. 帧格式

```text
#SEQ|CMD|PAYLOAD*CS\n
```

其中 `SEQ|CMD|PAYLOAD` 称为 BODY。

示例：

```text
#01|HELLO|role=pc;ver=0.1;caps=mock*3C
```

字段说明：

| 字段 | 长度 | 说明 |
| --- | --- | --- |
| `#` | 1 | 帧起始符 |
| `SEQ` | 2 | 两位大写十六进制序号，`00` 到 `FF` 循环 |
| `|` | 1 | 字段分隔符 |
| `CMD` | 1 到 16 | 大写命令名，只允许 `A-Z0-9_` |
| `PAYLOAD` | 0 到约 260 | ASCII key-value 字段，可为空 |
| `*` | 1 | 校验字段起始符 |
| `CS` | 2 | 两位大写十六进制 XOR 校验 |
| `\n` | 1 | 帧结束符 |

空 payload 必须保留第二个 `|`：

```text
#10|STATUS_GET|*35
```

## 3. 校验

`CS` 为 BODY 中所有 ASCII 字节的逐字节 XOR，计算范围不包含起始 `#`、不包含 `*CS`、不包含结尾 `\n`。

伪代码：

```text
xor = 0
for byte in ascii("SEQ|CMD|PAYLOAD"):
    xor = xor ^ byte
CS = uppercase_hex2(xor)
```

收到端必须先校验 `CS`，再解析命令和 payload。校验失败返回：

```text
#SEQ|NACK|ack=SEQ;err=BAD_CHECKSUM*CS
```

## 4. Payload 规则

payload 使用分号分隔的 `key=value` 字段：

```text
key=value;key=value
```

规则：

1. key 只允许 `a-z0-9_`。
2. value 第一版只允许 `A-Z a-z 0-9 _ - . : , / +`；消息正文例外，必须用 HEX。
3. 空 payload 长度为 0，不写 `-`。
4. 字段顺序建议按命令表顺序发送；接收端不依赖顺序时更好。
5. 未识别 key 可忽略，但不能影响必要字段校验。

FPGA 第一版为了节省资源，对已实现写命令采用固定字段顺序解析：

- `TIME_SET` 必须为 `date=YYYY-MM-DD;time=HH:MM:SS;weekday=N`。
- `MSG_TX` 必须为 `ts=YYYY-MM-DDTHH:MM:SS;len=N;text=HEX`。
- `ALARM_SET` 必须为 `slot=N;time=HH:MM:SS;enable=0|1`。
- `ALARM_GET` 必须为 `slot=N`。
- `SCHED_SET` 必须为 `slot=N;time=HH:MM:SS;type=N;enable=0|1`。
- `SCHED_GET` 必须为 `slot=N`。
- `COUNT_SET` 必须为 `time=HH:MM:SS`。

消息正文统一使用 HEX：

```text
text=48656C6C6F
```

`len` 表示 HEX 解码后的 ASCII 字符数，而不是 HEX 字符数。`len` 最大 100。

## 5. 序号、ACK/NACK 与重发

### 5.1 序号

- PC 发起命令时递增 `SEQ`。
- FPGA 对 PC 命令的直接回复复用请求 `SEQ`。
- FPGA 主动事件 `EVENT` 使用 FPGA 本地递增 `SEQ`。
- PC 对 FPGA 主动事件如需确认，发送同 `SEQ` 的 `ACK`。

### 5.2 ACK/NACK

通用 ACK：

```text
#SEQ|ACK|ack=SEQ;cmd=CMD*CS
```

通用 NACK：

```text
#SEQ|NACK|ack=SEQ;err=ERR_CODE;detail=short_text*CS
```

规则：

1. 有业务返回的命令不需要额外 ACK。例如 `TIME_GET` 直接返回 `TIME`。
2. 写操作成功且无专用返回时返回 `ACK`。
3. `MSG_TX` 成功后返回 `MSG_STORED`，不是普通 ACK。
4. 校验失败、payload 非法、命令不支持、资源忙时返回 `NACK`。

### 5.3 重发

PC command queue 第一版采用单 outstanding 命令：

- 发送后等待同 `SEQ` 回复。
- 默认超时 `500 ms`。
- 最多重发 3 次。
- 重发必须使用原 `SEQ` 和原 BODY。

FPGA 建议保存上一条已执行 PC 命令的 `SEQ`、BODY 校验和响应帧。若收到完全相同的重复帧，直接重发上一响应，不重复执行写操作，避免 `MSG_TX` 被重复存储。

## 6. 错误码

| 错误码 | 含义 |
| --- | --- |
| `BAD_FRAME` | 帧结构错误 |
| `BAD_CHECKSUM` | 校验失败 |
| `BAD_SEQ` | 序号或重复处理异常 |
| `UNKNOWN_CMD` | 未知命令 |
| `BAD_PAYLOAD` | payload 缺字段或格式非法 |
| `BAD_LEN` | 长度超限 |
| `BAD_HEX` | HEX 正文非法 |
| `BAD_SLOT` | 槽位超范围 |
| `BAD_TIME` | 时间/日期字段非法 |
| `BAD_MODE` | 模式名非法 |
| `UNSUPPORTED` | 当前 FPGA 阶段尚未实现 |
| `BUSY` | FPGA 暂时忙，PC 可重试 |
| `RX_OVERFLOW` | 接收缓冲溢出 |
| `TX_BUSY` | 发送器忙 |
| `INTERNAL` | 内部错误 |

## 7. 命令表：PC 到 FPGA

### 7.1 连接与状态

| CMD | Payload | 成功回复 | 说明 |
| --- | --- | --- | --- |
| `HELLO` | `role=pc;ver=x.y;caps=mock,serial` | `ACK` | 建立会话，FPGA 可在 ACK 中返回版本 |
| `PING` | `ts=YYYY-MM-DDTHH:MM:SS` 或空 | `PONG` | 连通性检测 |
| `PONG` | `ts=...` 或空 | `ACK` | PC 响应 FPGA 主动 ping，第一版可选 |
| `STATUS_GET` | 空 | `STATUS` | 查询模式、连接、未读、倒计时等摘要 |
| `MODE_SET` | `mode=CLOCK|TIME|ALARM|HOUR|COUNT|SCHED|COMM` | `ACK` | 请求 FPGA 切换 UI 模式；Phase 4 后实现 |

### 7.2 时间日期

| CMD | Payload | 成功回复 | 说明 |
| --- | --- | --- | --- |
| `TIME_SET` | `date=YYYY-MM-DD;time=HH:MM:SS;weekday=1..7` | `ACK` | 直接加载日期时间，不允许模拟按键 |
| `TIME_GET` | 空 | `TIME` | 查询 FPGA 当前时间 |

字段合法范围：

- `date` 月份为 `01..12`
- `date` 日期为 `01..31`，按月份限制；第一版不实现闰年，2 月最大 28 天
- `HH=00..23`
- `time` 分钟为 `00..59`
- `SS=00..59`
- `weekday=1..7`，约定 `1=Mon`，`7=Sun`

### 7.3 闹钟

| CMD | Payload | 成功回复 | 说明 |
| --- | --- | --- | --- |
| `ALARM_SET` | `slot=0..7;time=HH:MM:SS;enable=0|1` | `ACK` | 直接写指定闹钟槽 |
| `ALARM_GET` | `slot=0..7` | `ALARM` | 查询指定槽 |
| `ALARM_DUMP` | 空 | 8 条 `ALARM` + `ACK` | 逐条返回所有槽；最后 ACK 表示结束 |

### 7.4 日程

| CMD | Payload | 成功回复 | 说明 |
| --- | --- | --- | --- |
| `SCHED_SET` | `slot=0..7;time=HH:MM:SS;type=0..7;enable=0|1` | `ACK` | 直接写指定日程槽 |
| `SCHED_GET` | `slot=0..7` | `SCHED` | 查询指定槽 |
| `SCHED_DUMP` | 空 | 8 条 `SCHED` + `ACK` | 逐条返回所有槽；最后 ACK 表示结束 |

`type` 第一版沿用 FPGA 固定类型编号；PC 可在 UI 中显示映射名。

### 7.5 倒计时

| CMD | Payload | 成功回复 | 说明 |
| --- | --- | --- | --- |
| `COUNT_SET` | `time=HH:MM:SS` | `ACK` | 直接加载倒计时初值 |
| `COUNT_START` | 空 | `ACK` | 启动或继续倒计时 |
| `COUNT_STOP` | 空 | `ACK` | 停止倒计时 |
| `COUNT_STATUS` | 空 | `COUNT_STATUS` | 查询倒计时状态 |

Phase 8 FPGA 首版语义：

- `ALARM_SET/SCHED_SET/COUNT_SET` 使用直接写入接口，不模拟按键。
- `ALARM_SET/SCHED_SET` 的 PC 写入脉冲优先级高于同周期手动编辑脉冲。
- `ALARM_GET/SCHED_GET` 通过独立读槽口读取指定 slot，不依赖 UI 当前选中槽。
- `COUNT_SET` 会加载新倒计时值并停止倒计时；PC 如需立即运行，需要随后发送 `COUNT_START`。
- `COUNT_START/COUNT_STOP` 使用直接控制脉冲，不要求 FPGA 当前处于 `COUNT` 模式。
- FPGA 发送器忙时返回 `NACK err=TX_BUSY`，且不得产生写入或启动/停止副作用。

### 7.6 消息

| CMD | Payload | 成功回复 | 说明 |
| --- | --- | --- | --- |
| `MSG_TX` | `ts=YYYY-MM-DDTHH:MM:SS;len=0..100;text=HEX` | `MSG_STORED` | PC 发送消息给 FPGA |
| `MSG_GET` | `slot=0..15` | `MSG_DATA` | 查询 FPGA 消息缓存 |
| `MSG_CLEAR` | `slot=0..15` 或 `slot=all` | `ACK` | 清除未读标记或清空消息，具体语义由 Phase 5 固定实现 |

`MSG_TX` 存储规则：

- 新消息写入 slot 0。
- 旧消息向高 slot 后移。
- 超出 16 条时丢弃最老消息。
- FPGA OLED 时间戳来自 `ts`。

## 8. 命令表：FPGA 到 PC

| CMD | Payload | 方向 | 说明 |
| --- | --- | --- | --- |
| `ACK` | `ack=SEQ;cmd=CMD`，可加 `ver=...;caps=...` | FPGA -> PC | 通用成功确认 |
| `NACK` | `ack=SEQ;err=ERR_CODE;detail=short_text` | FPGA -> PC | 通用失败确认 |
| `PONG` | `ts=YYYY-MM-DDTHH:MM:SS` 或空 | FPGA -> PC | 响应 `PING` |
| `STATUS` | `mode=...;conn=DISC|WAIT|CONN|MSG|ERR;unread=n;count_run=0|1` | FPGA -> PC | 状态摘要 |
| `TIME` | `date=YYYY-MM-DD;time=HH:MM:SS;weekday=1..7` | FPGA -> PC | 当前 FPGA 时间 |
| `ALARM` | `slot=0..7;time=HH:MM:SS;enable=0|1` | FPGA -> PC | 闹钟槽状态 |
| `SCHED` | `slot=0..7;time=HH:MM:SS;type=0..7;enable=0|1` | FPGA -> PC | 日程槽状态 |
| `COUNT_STATUS` | `time=HH:MM:SS;run=0|1` | FPGA -> PC | 倒计时状态 |
| `MSG_STORED` | `slot=0;count=n;unread=n` | FPGA -> PC | `MSG_TX` 成功存储 |
| `MSG_DATA` | `slot=0..15;valid=0|1;ts=YYYY-MM-DDTHH:MM:SS;len=n;text=HEX` | FPGA -> PC | 消息缓存数据 |
| `REPLY` | `slot=0..15;reply=0..7;ts=YYYY-MM-DDTHH:MM:SS;text=HEX` | FPGA -> PC | 用户在 FPGA 上选择预设回复 |
| `EVENT` | `type=...;slot=n;detail=...` | FPGA -> PC | 异步事件，例如未读、闹钟、日程、倒计时结束 |
| `PING` | `ts=...` 或空 | FPGA -> PC | FPGA 主动 ping，第一版可选 |

`EVENT.type` 建议值：

- `MSG_UNREAD`
- `MSG_CLEARED`
- `REPLY_SENT`
- `ALARM_EVENT`
- `SCHED_EVENT`
- `COUNT_DONE`
- `MODE_CHANGED`
- `ERROR`

## 9. 示例帧

以下示例均按本协议 XOR 规则计算。

HELLO：

```text
#01|HELLO|role=pc;ver=0.1;caps=mock*3C
```

PING：

```text
#02|PING|ts=2026-06-05T15:03:00*7E
```

TIME_SET：

```text
#03|TIME_SET|date=2026-06-05;time=15:03:00;weekday=5*60
```

MSG_TX，正文 `Hello`：

```text
#04|MSG_TX|ts=2026-06-05T15:03:00;len=5;text=48656C6C6F*52
```

MSG_STORED：

```text
#04|MSG_STORED|slot=0;count=1*44
```

ACK：

```text
#05|ACK|ack=04;cmd=MSG_TX*7A
```

NACK：

```text
#06|NACK|ack=04;err=BAD_LEN;detail=msg_gt_100*21
```

## 10. FPGA 解析状态机建议

建议状态：

1. `ST_IDLE`：等待 `#`。
2. `ST_BODY`：累计 BODY，同时 XOR。遇到 `*` 转入校验。
3. `ST_CS_HI`：读取校验高位。
4. `ST_CS_LO`：读取校验低位。
5. `ST_EOL`：等待 `\n`。
6. `ST_DISPATCH`：解析 `SEQ/CMD/PAYLOAD` 并派发。
7. `ST_ERROR`：丢弃直到下一帧起始。

实现建议：

- BODY 缓冲长度建议 320 字节。
- 只接受 ASCII 可打印字符、`|`、`;`、`=`、`*` 和 `\n`。
- `*` 只能作为校验起始符；payload 中禁止出现 `*`。
- 按第一个和第二个 `|` 切分字段，避免 payload 中额外字符破坏 CMD。
- 先实现 `HELLO/PING/STATUS_GET/MSG_TX`，其余命令可返回 `NACK/UNSUPPORTED`，但命令名必须保留。
- 每个写操作输出一个单周期直接写入脉冲，脉冲优先级高于手动按键编辑。

## 11. PC command queue 建议

PC 软件建议结构：

1. `FrameCodec` 负责 `encode/decode/checksum`。
2. `CommandBuilder` 负责构造 payload。
3. `Transport` 负责收发字节流，mock/serial 共享接口。
4. `CommandQueue` 保持单 outstanding 命令，匹配同 `SEQ` 响应。
5. `EventDispatcher` 处理 FPGA 主动 `EVENT/REPLY/PING`。

PC 超时策略：

- 普通命令超时 `500 ms`。
- `ALARM_DUMP/SCHED_DUMP` 可用 `1500 ms`。
- 最大重试 3 次。
- 收到 `NACK/BUSY` 可等待 `200 ms` 后重试一次。

## 12. 阶段实现范围

| Phase | 需要实现的协议子集 |
| --- | --- |
| Phase 2 PC mock | `HELLO/PING/STATUS_GET/TIME_SET/TIME_GET/MSG_TX/REPLY` mock 闭环 |
| Phase 3 FPGA UART | 只验证字节收发，不解析协议 |
| Phase 5 FPGA 消息 | 已实现并仿真 `MSG_TX/MSG_STORED/MSG_CLEAR/STATUS_GET/HELLO/PING`；`MSG_GET/MSG_DATA` 因综合资源收敛问题暂返回 `NACK/UNSUPPORTED`，后续需改为流式读缓存再恢复 |
| Phase 6 预设回复 | 已实现 FPGA 主动 `REPLY`；`EVENT` 仍保留待后续阶段 |
| Phase 7 时间同步 | 已实现并仿真 `TIME_SET/TIME_GET/TIME` |
| Phase 8 可视化控制 | `ALARM_SET/ALARM_GET/SCHED_SET/SCHED_GET/COUNT_SET/COUNT_START/COUNT_STOP/COUNT_STATUS`；`ALARM_DUMP/SCHED_DUMP` 保留给 PC 循环 GET 或后续多帧 FSM |

## 13. Phase 5 FPGA 实现说明

截至 2026-06-05 Phase 5：

- FPGA UART 收发已接入 `comm_ctrl`。
- FPGA 能解析 PC canonical payload 顺序的 `MSG_TX` 帧：`ts=...;len=...;text=HEX`。
- FPGA 能把最新消息写入 slot0，并把旧消息向高 slot 移动，缓存 16 条。
- COMM OLED 能按 `SW0-SW15` 低位优先选择消息，显示日期、时间和正文窗口，`BTNU/BTND` 调整滚动行。
- `MSG_CLEAR slot=all` 清空缓存；`MSG_CLEAR slot=n` 只清除该 slot 的未读标记。
- `MSG_GET/MSG_DATA` 在协议中保持冻结，但当前 FPGA 端返回 `NACK/UNSUPPORTED`。原因是直接构造包含 100 字符消息的宽总线返回路径会生成大量 mux，Vivado 综合时间和内存不可接受。后续应改为“消息缓存逐字节读口 + 协议构帧逐字节取数”的流式实现。

## 14. Phase 6 FPGA 实现说明

截至 2026-06-05 Phase 6：

- FPGA 已实现 COMM 模式下预设回复。
- 用户在查看有效消息时按 `BTNC` 进入回复模式，再按 `BTNC` 回到查看模式。
- 回复模式下 `BTNU/BTND` 选择 `reply=0..7`。
- 回复模式下 `BTNR` 发送 `REPLY` 帧。
- FPGA 主动 `REPLY` 序号使用本地计数，当前起始为 `F0`，每次发送后递增。
- `REPLY` payload 为 `slot=0..15;reply=0..7;ts=YYYY-MM-DDTHH:MM:SS;text=HEX`。
- 当前 `ts` 为被回复消息原始时间戳，不是回复发送时刻。Phase 7 接入 PC 时间同步后，可改为 FPGA 当前时间或增加 `reply_ts` 字段，但字段变更必须先更新本文档。
- 第一版 `REPLY` 正文固定来自 FPGA ROM，最长 17 个 ASCII 字符，使用 HEX 编码。

Phase 6 已验证示例：

```text
#F0|REPLY|slot=0;reply=1;ts=2026-06-05T15:03:00;text=42757379206E6F772E*5C
```

其中 `text=42757379206E6F772E` 解码为 `Busy now.`。

## 15. Phase 7 FPGA 实现说明

截至 2026-06-05 Phase 7：

- FPGA 已实现 `TIME_SET`，payload 固定为 `date=YYYY-MM-DD;time=HH:MM:SS;weekday=N`。
- `TIME_SET` 成功后直接向 `time_core.v` 和 `date_core.v` 输出一拍加载脉冲，不模拟按键。
- `TIME_SET` 成功返回 `ACK`，payload 为 `ack=SEQ;cmd=TIME_SET`。
- FPGA 已实现 `TIME_GET`，直接返回 `TIME`，payload 为 `date=YYYY-MM-DD;time=HH:MM:SS;weekday=N`。
- `BAD_TIME` 已映射到 `NACK err=BAD_TIME`。
- `date_core.v` 已保存 4 位年份 BCD 并可由 PC 加载，`TIME_GET` 可返回完整年份。
- 日期自动跨天仍只更新月/日/星期；跨年时年份不会自动递增。这是第一版限制，PC 可通过 `TIME_SET` 重新同步年份。
- 第一版不实现闰年，`2026-02-29` 这类日期会返回 `NACK BAD_TIME`。

Phase 7 已验证示例：

```text
#03|TIME_SET|date=2026-06-05;time=15:03:00;weekday=5*60
#03|ACK|ack=03;cmd=TIME_SET*79
#04|TIME_GET|*18
#04|TIME|date=2026-06-05;time=15:03:00;weekday=5*7A
#05|TIME_SET|date=2026-13-05;time=15:03:00;weekday=5*62
#05|NACK|ack=05;err=BAD_TIME*3D
```

## 16. Phase 8 FPGA 实现说明

截至 2026-06-05 Phase 8：

- FPGA 已实现 `ALARM_SET/ALARM_GET/SCHED_SET/SCHED_GET/COUNT_SET/COUNT_START/COUNT_STOP/COUNT_STATUS`。
- FPGA 第一版只实现单槽 `ALARM_GET/SCHED_GET`，不实现一次性宽帧 `ALARM_DUMP/SCHED_DUMP`。
- 闹钟和日程 slot 范围为 `0..7`；倒计时时间范围为 `00:00:00..23:59:59`。
- `ALARM` 回复 payload 固定为 `slot=N;time=HH:MM:SS;enable=0|1`。
- `SCHED` 回复 payload 固定为 `slot=N;time=HH:MM:SS;type=N;enable=0|1`。
- `COUNT_STATUS` 回复 payload 固定为 `time=HH:MM:SS;run=0|1`。
- PC 软件如果需要读取全部闹钟或日程，应循环发送 `ALARM_GET slot=0..7` 或 `SCHED_GET slot=0..7`。
- `ALARM_SET/SCHED_SET/COUNT_SET` 使用直接写入接口，不模拟按键。
- `COUNT_SET` 加载新值并停止倒计时；PC 如需立即运行，应随后发送 `COUNT_START`。
- 发送器正忙时返回 `NACK err=TX_BUSY`，且不产生写入、启动或停止副作用。
