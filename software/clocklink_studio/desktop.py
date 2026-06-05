from __future__ import annotations

import sys

from services.client import ClockLinkClient
from transport.mock_transport import MockTransport
from transport.serial_transport import SerialTransport
from ui.main_window import ClockLinkWindow


TEXT = {
    "zh": {
        "title": "ClockLink Studio 启动",
        "app_name": "ClockLink Studio",
        "subtitle": "选择连接方式后进入控制台",
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
        "app_name": "ClockLink Studio",
        "subtitle": "Choose a connection and open the console",
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

COLORS = {
    "window": "#eef3f8",
    "surface": "#ffffff",
    "border": "#d9e2ec",
    "text": "#172033",
    "muted": "#667085",
    "primary": "#2aabee",
    "primary_dark": "#1686bd",
}


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
    from tkinter import font as tkfont
    from tkinter import messagebox, ttk

    ports = available_ports()
    root = tk.Tk()
    root.resizable(False, False)
    root.configure(bg=COLORS["window"])

    body_font = tkfont.Font(family="Microsoft YaHei UI", size=10)
    title_font = tkfont.Font(family="Microsoft YaHei UI", size=16, weight="bold")
    small_font = tkfont.Font(family="Microsoft YaHei UI", size=9)
    root.option_add("*Font", body_font)

    style = ttk.Style(root)
    try:
        style.theme_use("clam")
    except tk.TclError:
        pass
    style.configure("TCombobox", padding=4)
    style.configure("TRadiobutton", background=COLORS["surface"], foreground=COLORS["text"])
    style.configure("TButton", padding=(12, 8))
    style.configure("Primary.TButton", padding=(14, 8))
    style.map(
        "Primary.TButton",
        foreground=[("active", "#ffffff"), ("!disabled", "#ffffff")],
        background=[("active", COLORS["primary_dark"]), ("!disabled", COLORS["primary"])],
    )

    mode_var = tk.StringVar(value="serial" if ports else "mock")
    port_var = tk.StringVar(value=ports[0] if ports else "COM5")
    language_display_var = tk.StringVar(value=LANGUAGE_NAMES["zh"])
    selected: dict[str, ClockLinkClient | None] = {"client": None}
    selected_language = {"value": "zh"}

    def tr(key: str) -> str:
        return TEXT[current_language()][key]

    def current_language() -> str:
        return LANGUAGE_OPTIONS.get(language_display_var.get(), "zh")

    frame = tk.Frame(
        root,
        bg=COLORS["surface"],
        padx=20,
        pady=18,
        highlightthickness=1,
        highlightbackground=COLORS["border"],
    )
    frame.grid(row=0, column=0, sticky="nsew")
    frame.columnconfigure(1, weight=1)

    title_label = tk.Label(frame, bg=COLORS["surface"], fg=COLORS["text"], font=title_font)
    title_label.grid(row=0, column=0, columnspan=2, sticky="w")
    subtitle_label = tk.Label(frame, bg=COLORS["surface"], fg=COLORS["muted"], font=small_font)
    subtitle_label.grid(row=1, column=0, columnspan=2, sticky="w", pady=(2, 14))

    language_label = tk.Label(frame, bg=COLORS["surface"], fg=COLORS["muted"], font=small_font)
    language_label.grid(row=2, column=0, sticky="w")
    language_box = ttk.Combobox(
        frame,
        textvariable=language_display_var,
        values=list(LANGUAGE_OPTIONS.keys()),
        state="readonly",
        width=18,
    )
    language_box.grid(row=2, column=1, sticky="ew", padx=(8, 0))

    connection_label = tk.Label(frame, bg=COLORS["surface"], fg=COLORS["text"])
    connection_label.grid(row=3, column=0, sticky="w", columnspan=2, pady=(14, 0))
    serial_button = ttk.Radiobutton(frame, value="serial", variable=mode_var)
    serial_button.grid(
        row=4, column=0, sticky="w", pady=(8, 2)
    )
    port_box = ttk.Combobox(frame, textvariable=port_var, values=ports, width=18)
    port_box.grid(row=4, column=1, sticky="ew", padx=(8, 0), pady=(8, 2))
    mock_button = ttk.Radiobutton(frame, value="mock", variable=mode_var)
    mock_button.grid(row=5, column=0, sticky="w")

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
        title_label.configure(text=tr("app_name"))
        subtitle_label.configure(text=tr("subtitle"))
        language_label.configure(text=tr("language"))
        connection_label.configure(text=tr("connection"))
        serial_button.configure(text=tr("serial"))
        mock_button.configure(text=tr("mock"))
        refresh_button.configure(text=tr("refresh"))
        open_button.configure(text=tr("open"))

    buttons = tk.Frame(frame, bg=COLORS["surface"])
    buttons.grid(row=6, column=0, columnspan=2, sticky="ew", pady=(16, 0))
    buttons.columnconfigure(0, weight=1)
    buttons.columnconfigure(1, weight=1)
    refresh_button = ttk.Button(buttons, command=refresh_ports)
    refresh_button.grid(row=0, column=0, sticky="ew", padx=(0, 4))
    open_button = ttk.Button(buttons, style="Primary.TButton", command=connect)
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
