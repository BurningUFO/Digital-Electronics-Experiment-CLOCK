from __future__ import annotations

import sys

from services.client import ClockLinkClient
from transport.mock_transport import MockTransport
from transport.serial_transport import SerialTransport
from ui.main_window import ClockLinkWindow


TEXT = {
    "zh": {
        "title": "ClockLink Studio 启动",
        "connection": "连接方式",
        "serial": "串口模式",
        "mock": "Mock 模式",
        "language": "界面语言",
        "refresh": "刷新串口",
        "open": "打开",
        "select_port": "请选择串口。",
        "error_title": "ClockLink Studio",
    },
    "en": {
        "title": "ClockLink Studio",
        "connection": "Connection",
        "serial": "Serial",
        "mock": "Mock",
        "language": "Language",
        "refresh": "Refresh",
        "open": "Open",
        "select_port": "Select a serial port.",
        "error_title": "ClockLink Studio",
    },
}

LANGUAGE_OPTIONS = {
    "中文": "zh",
    "English": "en",
}

LANGUAGE_NAMES = {value: key for key, value in LANGUAGE_OPTIONS.items()}


def available_ports() -> list[str]:
    try:
        from serial.tools import list_ports
    except Exception:
        return []
    return [port.device for port in list_ports.comports()]


def self_test() -> int:
    client = ClockLinkClient(MockTransport())
    try:
        response = client.ping()
        return 0 if response.cmd == "PONG" else 1
    finally:
        client.transport.close()


def choose_client() -> ClockLinkClient | None:
    import tkinter as tk
    from tkinter import messagebox, ttk

    ports = available_ports()
    root = tk.Tk()
    root.resizable(False, False)

    mode_var = tk.StringVar(value="serial" if ports else "mock")
    port_var = tk.StringVar(value=ports[0] if ports else "COM5")
    language_display_var = tk.StringVar(value=LANGUAGE_NAMES["zh"])
    selected: dict[str, ClockLinkClient | None] = {"client": None}
    selected_language = {"value": "zh"}

    def tr(key: str) -> str:
        return TEXT[current_language()][key]

    def current_language() -> str:
        return LANGUAGE_OPTIONS.get(language_display_var.get(), "zh")

    frame = ttk.Frame(root, padding=12)
    frame.grid(row=0, column=0, sticky="nsew")
    frame.columnconfigure(1, weight=1)

    language_label = ttk.Label(frame)
    language_label.grid(row=0, column=0, sticky="w")
    language_box = ttk.Combobox(
        frame,
        textvariable=language_display_var,
        values=list(LANGUAGE_OPTIONS.keys()),
        state="readonly",
        width=18,
    )
    language_box.grid(row=0, column=1, sticky="ew", padx=(8, 0))

    connection_label = ttk.Label(frame)
    connection_label.grid(row=1, column=0, sticky="w", columnspan=2, pady=(12, 0))
    serial_button = ttk.Radiobutton(frame, value="serial", variable=mode_var)
    serial_button.grid(
        row=2, column=0, sticky="w", pady=(8, 2)
    )
    port_box = ttk.Combobox(frame, textvariable=port_var, values=ports, width=18)
    port_box.grid(row=2, column=1, sticky="ew", padx=(8, 0), pady=(8, 2))
    mock_button = ttk.Radiobutton(frame, value="mock", variable=mode_var)
    mock_button.grid(row=3, column=0, sticky="w")

    def refresh_ports() -> None:
        new_ports = available_ports()
        port_box.configure(values=new_ports)
        if new_ports and (not port_var.get() or port_var.get() not in new_ports):
            port_var.set(new_ports[0])

    def connect() -> None:
        selected_language["value"] = current_language()
        if mode_var.get() == "mock":
            selected["client"] = ClockLinkClient(MockTransport())
            root.destroy()
            return

        port = port_var.get().strip()
        if not port:
            messagebox.showerror(tr("error_title"), tr("select_port"))
            return
        selected["client"] = ClockLinkClient(SerialTransport(port))
        root.destroy()

    def apply_language(*_args) -> None:
        root.title(tr("title"))
        language_label.configure(text=tr("language"))
        connection_label.configure(text=tr("connection"))
        serial_button.configure(text=tr("serial"))
        mock_button.configure(text=tr("mock"))
        refresh_button.configure(text=tr("refresh"))
        open_button.configure(text=tr("open"))

    buttons = ttk.Frame(frame)
    buttons.grid(row=4, column=0, columnspan=2, sticky="ew", pady=(12, 0))
    buttons.columnconfigure(0, weight=1)
    buttons.columnconfigure(1, weight=1)
    refresh_button = ttk.Button(buttons, command=refresh_ports)
    refresh_button.grid(row=0, column=0, sticky="ew", padx=(0, 4))
    open_button = ttk.Button(buttons, command=connect)
    open_button.grid(row=0, column=1, sticky="ew", padx=(4, 0))

    language_display_var.trace_add("write", apply_language)
    apply_language()
    root.mainloop()
    if selected["client"] is not None:
        selected["client"].language = selected_language["value"]
    return selected["client"]


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()

    client = choose_client()
    if client is None:
        return 0
    ClockLinkWindow(client, getattr(client, "language", "zh")).run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
