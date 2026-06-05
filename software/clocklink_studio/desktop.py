from __future__ import annotations

import sys

from services.client import ClockLinkClient
from transport.mock_transport import MockTransport
from transport.serial_transport import SerialTransport
from ui.main_window import ClockLinkWindow


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
    root.title("ClockLink Studio")
    root.resizable(False, False)

    mode_var = tk.StringVar(value="serial" if ports else "mock")
    port_var = tk.StringVar(value=ports[0] if ports else "COM5")
    selected: dict[str, ClockLinkClient | None] = {"client": None}

    frame = ttk.Frame(root, padding=12)
    frame.grid(row=0, column=0, sticky="nsew")
    frame.columnconfigure(1, weight=1)

    ttk.Label(frame, text="Connection").grid(row=0, column=0, sticky="w", columnspan=2)
    ttk.Radiobutton(frame, text="Serial", value="serial", variable=mode_var).grid(
        row=1, column=0, sticky="w", pady=(8, 2)
    )
    port_box = ttk.Combobox(frame, textvariable=port_var, values=ports, width=18)
    port_box.grid(row=1, column=1, sticky="ew", padx=(8, 0), pady=(8, 2))
    ttk.Radiobutton(frame, text="Mock", value="mock", variable=mode_var).grid(row=2, column=0, sticky="w")

    def refresh_ports() -> None:
        new_ports = available_ports()
        port_box.configure(values=new_ports)
        if new_ports and (not port_var.get() or port_var.get() not in new_ports):
            port_var.set(new_ports[0])

    def connect() -> None:
        if mode_var.get() == "mock":
            selected["client"] = ClockLinkClient(MockTransport())
            root.destroy()
            return

        port = port_var.get().strip()
        if not port:
            messagebox.showerror("ClockLink Studio", "Select a serial port.")
            return
        selected["client"] = ClockLinkClient(SerialTransport(port))
        root.destroy()

    buttons = ttk.Frame(frame)
    buttons.grid(row=3, column=0, columnspan=2, sticky="ew", pady=(12, 0))
    buttons.columnconfigure(0, weight=1)
    buttons.columnconfigure(1, weight=1)
    ttk.Button(buttons, text="Refresh", command=refresh_ports).grid(row=0, column=0, sticky="ew", padx=(0, 4))
    ttk.Button(buttons, text="Open", command=connect).grid(row=0, column=1, sticky="ew", padx=(4, 0))

    root.mainloop()
    return selected["client"]


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()

    client = choose_client()
    if client is None:
        return 0
    ClockLinkWindow(client).run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
