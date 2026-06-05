from __future__ import annotations

from protocol.codec import FrameError, hex_to_ascii_text, parse_payload


SCHEDULE_TYPE_LABELS = {
    0: "CLASS 1",
    1: "BREAK",
    2: "CLASS 2",
    3: "LUNCH",
    4: "CLASS 3",
    5: "BREAK",
    6: "STUDY",
    7: "REST",
}


class ClockLinkWindow:
    def __init__(self, client) -> None:
        self.client = client

    def run(self) -> None:
        import tkinter as tk
        from tkinter import messagebox, scrolledtext, ttk

        root = tk.Tk()
        root.title("ClockLink Studio")
        root.minsize(760, 560)

        status_var = tk.StringVar(value="Ready")
        message_var = tk.StringVar(value="Hello FPGA")
        msg_slot_var = tk.IntVar(value=0)
        alarm_slot_var = tk.IntVar(value=0)
        alarm_time_var = tk.StringVar(value="07:30:00")
        alarm_enable_var = tk.BooleanVar(value=True)
        sched_slot_var = tk.IntVar(value=0)
        sched_time_var = tk.StringVar(value="08:00:00")
        sched_type_var = tk.IntVar(value=0)
        sched_enable_var = tk.BooleanVar(value=True)
        count_time_var = tk.StringVar(value="00:05:00")

        def append_log(text: str) -> None:
            log.configure(state="normal")
            log.insert("end", text + "\n")
            log.see("end")
            log.configure(state="disabled")

        def show_frame(label: str, frame) -> None:
            line = f"{label}: {frame.seq_hex} {frame.cmd} {frame.payload}"
            status_var.set(line)
            append_log(line)

        def run_action(label: str, callback) -> None:
            try:
                show_frame(label, callback())
            except Exception as exc:
                status_var.set(str(exc))
                append_log(f"ERROR {label}: {exc}")
                messagebox.showerror("ClockLink", str(exc))

        def ping() -> None:
            run_action("ping", self.client.ping)

        def status() -> None:
            run_action("status", self.client.status)

        def sync_time() -> None:
            run_action("sync-time", self.client.sync_time)

        def time_get() -> None:
            run_action("time-get", self.client.time_get)

        def send_message() -> None:
            run_action("message", lambda: self.client.send_message(message_var.get()))

        def get_message() -> None:
            frame = self.client.get_message(msg_slot_var.get())
            show_frame("message-get", frame)
            payload = parse_payload(frame.payload)
            if payload.get("valid") == "1" and "text" in payload:
                try:
                    append_log(f"message-text: {hex_to_ascii_text(payload['text'])}")
                except FrameError as exc:
                    append_log(f"message-text decode error: {exc}")

        def alarm_set() -> None:
            run_action(
                "alarm-set",
                lambda: self.client.alarm_set(
                    alarm_slot_var.get(),
                    alarm_time_var.get(),
                    alarm_enable_var.get(),
                ),
            )

        def alarm_get() -> None:
            run_action("alarm-get", lambda: self.client.alarm_get(alarm_slot_var.get()))

        def sched_set() -> None:
            run_action(
                "sched-set",
                lambda: self.client.sched_set(
                    sched_slot_var.get(),
                    sched_time_var.get(),
                    sched_type_var.get(),
                    sched_enable_var.get(),
                ),
            )

        def sched_get() -> None:
            run_action("sched-get", lambda: self.client.sched_get(sched_slot_var.get()))

        def count_set() -> None:
            run_action("count-set", lambda: self.client.count_set(count_time_var.get()))

        def count_start() -> None:
            run_action("count-start", self.client.count_start)

        def count_stop() -> None:
            run_action("count-stop", self.client.count_stop)

        def count_status() -> None:
            run_action("count-status", self.client.count_status)

        root.columnconfigure(0, weight=1)
        root.rowconfigure(1, weight=1)

        status = ttk.Label(root, textvariable=status_var, anchor="w", padding=(8, 6))
        status.grid(row=0, column=0, sticky="ew")

        tabs = ttk.Notebook(root)
        tabs.grid(row=1, column=0, sticky="nsew", padx=8, pady=4)

        main_tab = ttk.Frame(tabs, padding=8)
        control_tab = ttk.Frame(tabs, padding=8)
        log_tab = ttk.Frame(tabs, padding=8)
        tabs.add(main_tab, text="Connect")
        tabs.add(control_tab, text="Control")
        tabs.add(log_tab, text="Log")

        for col in range(4):
            main_tab.columnconfigure(col, weight=1)
            control_tab.columnconfigure(col, weight=1)
        main_tab.rowconfigure(4, weight=1)
        log_tab.rowconfigure(0, weight=1)
        log_tab.columnconfigure(0, weight=1)

        ttk.Label(main_tab, text="Session").grid(row=0, column=0, sticky="w")
        ttk.Button(main_tab, text="HELLO", command=lambda: run_action("hello", self.client.hello)).grid(
            row=1, column=0, sticky="ew", padx=2, pady=2
        )
        ttk.Button(main_tab, text="PING", command=ping).grid(row=1, column=1, sticky="ew", padx=2, pady=2)
        ttk.Button(main_tab, text="STATUS", command=status).grid(row=1, column=2, sticky="ew", padx=2, pady=2)

        ttk.Label(main_tab, text="Time").grid(row=2, column=0, sticky="w", pady=(12, 0))
        ttk.Button(main_tab, text="SYNC", command=sync_time).grid(row=3, column=0, sticky="ew", padx=2, pady=2)
        ttk.Button(main_tab, text="GET", command=time_get).grid(row=3, column=1, sticky="ew", padx=2, pady=2)

        ttk.Label(main_tab, text="Message").grid(row=4, column=0, sticky="nw", pady=(12, 0))
        ttk.Entry(main_tab, textvariable=message_var).grid(row=5, column=0, columnspan=3, sticky="ew", padx=2, pady=2)
        ttk.Button(main_tab, text="SEND", command=send_message).grid(row=5, column=3, sticky="ew", padx=2, pady=2)
        ttk.Spinbox(main_tab, from_=0, to=15, textvariable=msg_slot_var, width=5).grid(
            row=6, column=0, sticky="w", padx=2, pady=2
        )
        ttk.Button(main_tab, text="MSG GET", command=get_message).grid(row=6, column=1, sticky="ew", padx=2, pady=2)

        ttk.Label(control_tab, text="Alarm").grid(row=0, column=0, sticky="w")
        ttk.Spinbox(control_tab, from_=0, to=7, textvariable=alarm_slot_var, width=5).grid(
            row=1, column=0, sticky="ew", padx=2, pady=2
        )
        ttk.Entry(control_tab, textvariable=alarm_time_var, width=10).grid(
            row=1, column=1, sticky="ew", padx=2, pady=2
        )
        ttk.Checkbutton(control_tab, text="Enable", variable=alarm_enable_var).grid(
            row=1, column=2, sticky="w", padx=2, pady=2
        )
        ttk.Button(control_tab, text="SET", command=alarm_set).grid(row=1, column=3, sticky="ew", padx=2, pady=2)
        ttk.Button(control_tab, text="GET", command=alarm_get).grid(row=2, column=3, sticky="ew", padx=2, pady=2)

        ttk.Label(control_tab, text="Schedule").grid(row=3, column=0, sticky="w", pady=(12, 0))
        ttk.Spinbox(control_tab, from_=0, to=7, textvariable=sched_slot_var, width=5).grid(
            row=4, column=0, sticky="ew", padx=2, pady=2
        )
        ttk.Entry(control_tab, textvariable=sched_time_var, width=10).grid(
            row=4, column=1, sticky="ew", padx=2, pady=2
        )
        sched_type = ttk.Combobox(
            control_tab,
            textvariable=sched_type_var,
            values=list(SCHEDULE_TYPE_LABELS.keys()),
            width=5,
            state="readonly",
        )
        sched_type.grid(row=4, column=2, sticky="ew", padx=2, pady=2)
        ttk.Checkbutton(control_tab, text="Enable", variable=sched_enable_var).grid(
            row=5, column=2, sticky="w", padx=2, pady=2
        )
        ttk.Button(control_tab, text="SET", command=sched_set).grid(row=4, column=3, sticky="ew", padx=2, pady=2)
        ttk.Button(control_tab, text="GET", command=sched_get).grid(row=5, column=3, sticky="ew", padx=2, pady=2)

        ttk.Label(control_tab, text="Countdown").grid(row=6, column=0, sticky="w", pady=(12, 0))
        ttk.Entry(control_tab, textvariable=count_time_var, width=10).grid(
            row=7, column=0, sticky="ew", padx=2, pady=2
        )
        ttk.Button(control_tab, text="SET", command=count_set).grid(row=7, column=1, sticky="ew", padx=2, pady=2)
        ttk.Button(control_tab, text="START", command=count_start).grid(row=7, column=2, sticky="ew", padx=2, pady=2)
        ttk.Button(control_tab, text="STOP", command=count_stop).grid(row=7, column=3, sticky="ew", padx=2, pady=2)
        ttk.Button(control_tab, text="STATUS", command=count_status).grid(row=8, column=3, sticky="ew", padx=2, pady=2)

        log = scrolledtext.ScrolledText(log_tab, height=18, state="disabled")
        log.grid(row=0, column=0, sticky="nsew")

        append_log("ClockLink Studio started")
        root.mainloop()
