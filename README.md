# ClockLink Smart Clock Terminal

ClockLink Smart Clock Terminal is a Nexys A7 FPGA smart clock system with a dedicated Windows PC companion app. It extends a traditional multi-function digital clock into a UART-connected terminal that can display messages, synchronize time, and control alarms, schedules, and countdowns from ClockLink Studio.

This repository contains the complete Vivado hardware project, the ClockLink Studio Python/Tkinter application, protocol documentation, simulation assets, and release packaging workflow.

## Overview

| Item | Description |
| --- | --- |
| FPGA platform | Digilent Nexys A7 100T |
| FPGA toolchain | AMD Vivado |
| PC application | ClockLink Studio for Windows |
| Communication link | USB-UART, `115200 8N1` |
| Clock modes | `CLOCK / TIME / ALARM / HOUR / COUNT / SCHED / COMM` |
| Display outputs | 8-digit seven-segment display, LEDs, buzzer, external SSD1306 OLED |
| Release version | `v1.0.0` |

## Download

The Windows package is distributed through GitHub Releases rather than committed as a binary file.

- Release page: <https://github.com/BurningUFO/Digital-Electronics-Experiment-CLOCK/releases/tag/v1.0.0>
- Windows ZIP: <https://github.com/BurningUFO/Digital-Electronics-Experiment-CLOCK/releases/download/v1.0.0/ClockLinkStudio-v1.0.0-win64.zip>

After extracting the ZIP, run `ClockLinkStudio.exe`. Mock mode works without FPGA hardware. Serial mode requires a Nexys A7 programmed with the ClockLink UART firmware.

## Highlights

- Seven-mode FPGA clock UI with unified browsing and setting layers.
- `CLOCK` date and weekday editing for the OLED status panel.
- `TIME` manual time setting and PC-driven time synchronization.
- `ALARM` with 8 slots, LED state indication, pending alerts, and snooze flow.
- `COUNT` countdown editing, start/stop control, and completion notification.
- `SCHED` with 8 fixed schedule points and schedule reminders.
- `HOUR` mode for 12/24-hour display switching while internal time stays 24-hour.
- `COMM` mode for USB-UART messaging, message browsing, OLED display, and preset replies.
- ClockLink Studio GUI for connection testing, message sending, time sync, alarm control, schedule control, and countdown control.
- Mock transport for software demos and tests without hardware.

## System Architecture

```text
ClockLink Studio
  |  USB-UART, 115200 8N1
  v
comm_ctrl.v
  |-- protocol_parser.v / protocol_builder.v
  |-- message_store.v / preset_reply_rom.v
  |-- uart_rx.v / uart_tx.v
  v
clock.v
  |-- time_core.v / date_core.v
  |-- alarm_ctrl.v / schedule_ctrl.v / countdown_ctrl.v
  |-- notification_ctrl.v
  |-- display_ctrl.v / oled_ui_display.v
  v
Nexys A7 display, LED, buzzer, OLED, ADT7420
```

The FPGA side keeps the original clock feature set and adds a resource-conscious communication layer. The PC side uses the same ClockLink frame format in mock and serial modes, so software functions can be validated before connecting real hardware.

## ClockLink Studio

ClockLink Studio is the PC control surface for the FPGA clock terminal.

| Area | Capability |
| --- | --- |
| Connect | `HELLO`, `PING`, `STATUS`, time sync, time query, serial/mock connection |
| Messaging | Send printable ASCII messages to FPGA, display communication log, receive preset replies |
| Alarm | Read/write 8 alarm slots |
| Schedule | Read/write 8 schedule slots |
| Countdown | Set, start, stop, and query countdown state |
| Demo mode | Full mock transport for presentation and automated tests |

Run from source:

```powershell
cd software\clocklink_studio
python main.py --mock gui
python main.py --port COM5 gui
```

Run tests:

```powershell
cd software\clocklink_studio
python -m pytest
```

Build the Windows ZIP locally:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\package_clocklink_studio.ps1 -Version v1.0.0
```

## FPGA Project

Open the Vivado project:

```text
clock_amd.xpr
```

Key files:

| Path | Purpose |
| --- | --- |
| `clock_amd.srcs/sources_1/new/clock_amd_top.v` | Nexys A7 top-level integration |
| `clock_amd.srcs/sources_1/new/clock.v` | Main clock system integration |
| `clock_amd.srcs/sources_1/new/comm_ctrl.v` | ClockLink UART communication controller |
| `clock_amd.srcs/constrs_1/new/clock_amd.xdc` | Nexys A7 pin constraints |
| `scripts/run_phase_synth_check.tcl` | Batch synthesis check script |

Run the synthesis check:

```powershell
vivado -mode batch -source scripts\run_phase_synth_check.tcl
```

Generate a bitstream in Vivado before programming the Nexys A7. The repository records synthesis and simulation status, but the latest ClockLink build still needs final bitstream generation and board-level validation.

## Hardware Connections

| Interface | Nexys A7 signal | Usage |
| --- | --- | --- |
| USB-UART J6 | `UART_RXD=C4`, `UART_TXD=D4` | ClockLink Studio communication |
| External OLED | `JB1/D14=SCL`, `JB2/F16=SDA` | SSD1306 status panel |
| Temperature sensor | `TMP_SCL=C14`, `TMP_SDA=C15` | ADT7420 reading |
| Buzzer | `JA1/C17` | Unified notifications and hourly chime |
| Buttons/switches | Nexys A7 standard controls | Mode navigation and local setting |

See `docs/工程模块使用说明.md` for the complete interaction and wiring reference.

## Protocol Compatibility

ClockLink uses ASCII frames:

```text
#SEQ|CMD|PAYLOAD*CS\n
```

Current implementation boundary:

- UART: `115200, 8N1`.
- Checksum: XOR over `SEQ|CMD|PAYLOAD`.
- Message text: printable ASCII `0x20..0x7E`.
- Unicode and Chinese message display are not part of the current FPGA protocol or OLED font set.
- FPGA currently acknowledges the implemented command subset. `MSG_GET/MSG_DATA` remains unsupported on the FPGA side and returns `NACK`; the PC mock implements it for software demonstration.

Protocol details are documented in `docs/UART_PROTOCOL.md`.

## Verification Status

| Area | Status |
| --- | --- |
| PC unit tests | `python -m pytest`: 17 tests passed |
| PC release packaging | `ClockLinkStudio-v1.0.0-win64.zip` built and released |
| COMM XSim regressions | `tb_comm_ctrl_control`, `tb_comm_ctrl_time`, `tb_comm_ctrl_msg`, `tb_comm_ctrl_reply` passed |
| Focused XSim tests | `tb_notification_hourly_chime`, `tb_oled_glyph` passed |
| Vivado synthesis check | Passed, `WNS=+1.779ns`, `TNS=0.000ns`, failed endpoints `0` |
| Bitstream | Not regenerated after the latest ClockLink changes |
| Board-level validation | Nexys A7 USB-UART/COMM, OLED, ADT7420, buzzer, and full alert flow still need physical validation |

## Repository Layout

```text
clock_amd.srcs/                 Vivado HDL sources and constraints
docs/                           Protocol, module, workflow, and release documents
scripts/                        Synthesis and packaging scripts
sim/                            XSim testbenches
software/clocklink_studio/      ClockLink Studio source code and tests
.github/workflows/              GitHub Actions release workflow
artifacts/                      Local generated outputs, ignored by Git
```

Generated Vivado directories such as `.Xil/`, `clock_amd.cache/`, `clock_amd.hw/`, `clock_amd.runs/`, and `clock_amd.sim/` are not source files and should not be committed.

## Documentation

- `docs/工程模块使用说明.md` - module usage, UI rules, hardware mapping, and board test checklist.
- `docs/UART_PROTOCOL.md` - ClockLink frame format and command reference.
- `docs/ClockLink_Studio_PC_Software_Design.md` - PC software design.
- `software/clocklink_studio/README.md` - ClockLink Studio developer guide.
- `docs/ClockLink_Studio_Release_Guide.md` - packaging and GitHub Release workflow.
- `docs/FINAL_DEMO_GUIDE.md` - final demonstration flow.
- `HANDOFF.md` - project handoff notes for future maintainers.
