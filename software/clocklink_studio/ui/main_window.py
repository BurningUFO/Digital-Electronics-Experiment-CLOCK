from __future__ import annotations

from protocol.codec import FrameError, hex_to_ascii_text, parse_payload


SCHEDULE_TYPE_LABELS = {
    "zh": {
        0: "第1节课",
        1: "课间",
        2: "第2节课",
        3: "午休",
        4: "第3节课",
        5: "课间",
        6: "晚自习",
        7: "休息",
    },
    "en": {
        0: "CLASS 1",
        1: "BREAK",
        2: "CLASS 2",
        3: "LUNCH",
        4: "CLASS 3",
        5: "BREAK",
        6: "STUDY",
        7: "REST",
    },
}


TEXT = {
    "zh": {
        "title": "ClockLink Studio 时钟通信工具",
        "ready": "就绪",
        "language": "界面语言",
        "tab_connect": "连接与消息",
        "tab_control": "功能控制",
        "tab_log": "通信日志",
        "session": "连接测试",
        "hello": "握手",
        "ping": "连通测试",
        "status": "状态",
        "time": "时间同步",
        "sync": "同步电脑时间",
        "get": "读取",
        "message": "发送消息",
        "send": "发送到 FPGA",
        "slot": "槽位",
        "msg_get": "读取消息",
        "alarm": "闹钟",
        "schedule": "日程",
        "countdown": "倒计时",
        "enable": "启用",
        "set": "写入",
        "alarm_get_button": "读取",
        "sched_set_button": "写入",
        "sched_get_button": "读取",
        "count_set_button": "写入",
        "start": "启动",
        "stop": "停止",
        "count_status": "查询状态",
        "enable_sched": "启用",
        "type": "类型",
        "log_started": "ClockLink Studio 已启动",
        "message_text": "消息正文",
        "decode_error": "消息解码失败",
        "error_prefix": "错误",
    },
    "en": {
        "title": "ClockLink Studio",
        "ready": "Ready",
        "language": "Language",
        "tab_connect": "Connect",
        "tab_control": "Control",
        "tab_log": "Log",
        "session": "Session",
        "hello": "HELLO",
        "ping": "PING",
        "status": "STATUS",
        "time": "Time",
        "sync": "SYNC",
        "get": "GET",
        "message": "Message",
        "send": "SEND",
        "slot": "Slot",
        "msg_get": "MSG GET",
        "alarm": "Alarm",
        "schedule": "Schedule",
        "countdown": "Countdown",
        "enable": "Enable",
        "set": "SET",
        "alarm_get_button": "GET",
        "sched_set_button": "SET",
        "sched_get_button": "GET",
        "count_set_button": "SET",
        "start": "START",
        "stop": "STOP",
        "count_status": "STATUS",
        "enable_sched": "Enable",
        "type": "Type",
        "log_started": "ClockLink Studio started",
        "message_text": "message-text",
        "decode_error": "message-text decode error",
        "error_prefix": "ERROR",
    },
}

LANGUAGE_OPTIONS = {
    "中文": "zh",
    "English": "en",
}

LANGUAGE_NAMES = {value: key for key, value in LANGUAGE_OPTIONS.items()}


class ClockLinkWindow:
    def __init__(self, client, language: str = "zh") -> None:
        self.client = client
        self.language = language if language in TEXT else "zh"

    def run(self) -> None:
        import tkinter as tk
        from tkinter import messagebox, scrolledtext, ttk

        root = tk.Tk()
        root.title(TEXT[self.language]["title"])
        root.minsize(760, 560)

        language_display_var = tk.StringVar(value=LANGUAGE_NAMES[self.language])
        status_var = tk.StringVar(value=TEXT[self.language]["ready"])
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
        labels: dict[str, object] = {}
        tab_ids: dict[str, object] = {}
        schedule_type_values: list[str] = []

        def tr(key: str) -> str:
            return TEXT[current_language()][key]

        def current_language() -> str:
            return LANGUAGE_OPTIONS.get(language_display_var.get(), "zh")

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
                append_log(f"{tr('error_prefix')} {label}: {exc}")
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
                    append_log(f"{tr('message_text')}: {hex_to_ascii_text(payload['text'])}")
                except FrameError as exc:
                    append_log(f"{tr('decode_error')}: {exc}")

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

        def schedule_type_display_values(lang: str) -> list[str]:
            return [f"{index}: {label}" for index, label in SCHEDULE_TYPE_LABELS[lang].items()]

        def on_schedule_type_selected(_event=None) -> None:
            selected = sched_type.get()
            try:
                sched_type_var.set(int(selected.split(":", 1)[0]))
            except (ValueError, IndexError):
                sched_type_var.set(0)

        def update_schedule_type_text() -> None:
            nonlocal schedule_type_values
            schedule_type_values = schedule_type_display_values(current_language())
            sched_type.configure(values=schedule_type_values)
            index = sched_type_var.get()
            if 0 <= index < len(schedule_type_values):
                sched_type.set(schedule_type_values[index])

        def apply_language(*_args) -> None:
            lang = current_language()
            root.title(TEXT[lang]["title"])
            status_var.set(TEXT[lang]["ready"] if status_var.get() in ("Ready", "就绪") else status_var.get())
            tabs.tab(tab_ids["connect"], text=tr("tab_connect"))
            tabs.tab(tab_ids["control"], text=tr("tab_control"))
            tabs.tab(tab_ids["log"], text=tr("tab_log"))
            for key, widget in labels.items():
                widget.configure(text=tr(key))
            update_schedule_type_text()

        root.columnconfigure(0, weight=1)
        root.rowconfigure(1, weight=1)

        header = ttk.Frame(root, padding=(8, 6))
        header.grid(row=0, column=0, sticky="ew")
        header.columnconfigure(0, weight=1)
        status = ttk.Label(header, textvariable=status_var, anchor="w")
        status.grid(row=0, column=0, sticky="ew")
        labels["language"] = ttk.Label(header)
        labels["language"].grid(row=0, column=1, sticky="e", padx=(8, 4))
        language_box = ttk.Combobox(
            header,
            textvariable=language_display_var,
            values=list(LANGUAGE_OPTIONS.keys()),
            state="readonly",
            width=8,
        )
        language_box.grid(row=0, column=2, sticky="e")

        tabs = ttk.Notebook(root)
        tabs.grid(row=1, column=0, sticky="nsew", padx=8, pady=4)

        main_tab = ttk.Frame(tabs, padding=8)
        control_tab = ttk.Frame(tabs, padding=8)
        log_tab = ttk.Frame(tabs, padding=8)
        tabs.add(main_tab)
        tabs.add(control_tab)
        tabs.add(log_tab)
        tab_ids["connect"] = main_tab
        tab_ids["control"] = control_tab
        tab_ids["log"] = log_tab

        for col in range(4):
            main_tab.columnconfigure(col, weight=1)
            control_tab.columnconfigure(col, weight=1)
        main_tab.rowconfigure(4, weight=1)
        log_tab.rowconfigure(0, weight=1)
        log_tab.columnconfigure(0, weight=1)

        labels["session"] = ttk.Label(main_tab)
        labels["session"].grid(row=0, column=0, sticky="w")
        labels["hello"] = ttk.Button(main_tab, command=lambda: run_action("hello", self.client.hello))
        labels["hello"].grid(
            row=1, column=0, sticky="ew", padx=2, pady=2
        )
        labels["ping"] = ttk.Button(main_tab, command=ping)
        labels["ping"].grid(row=1, column=1, sticky="ew", padx=2, pady=2)
        labels["status"] = ttk.Button(main_tab, command=status)
        labels["status"].grid(row=1, column=2, sticky="ew", padx=2, pady=2)

        labels["time"] = ttk.Label(main_tab)
        labels["time"].grid(row=2, column=0, sticky="w", pady=(12, 0))
        labels["sync"] = ttk.Button(main_tab, command=sync_time)
        labels["sync"].grid(row=3, column=0, sticky="ew", padx=2, pady=2)
        labels["get"] = ttk.Button(main_tab, command=time_get)
        labels["get"].grid(row=3, column=1, sticky="ew", padx=2, pady=2)

        labels["message"] = ttk.Label(main_tab)
        labels["message"].grid(row=4, column=0, sticky="nw", pady=(12, 0))
        ttk.Entry(main_tab, textvariable=message_var).grid(row=5, column=0, columnspan=3, sticky="ew", padx=2, pady=2)
        labels["send"] = ttk.Button(main_tab, command=send_message)
        labels["send"].grid(row=5, column=3, sticky="ew", padx=2, pady=2)
        labels["slot"] = ttk.Label(main_tab)
        labels["slot"].grid(row=6, column=0, sticky="w", padx=2, pady=2)
        ttk.Spinbox(main_tab, from_=0, to=15, textvariable=msg_slot_var, width=5).grid(
            row=6, column=1, sticky="w", padx=2, pady=2
        )
        labels["msg_get"] = ttk.Button(main_tab, command=get_message)
        labels["msg_get"].grid(row=6, column=2, sticky="ew", padx=2, pady=2)

        labels["alarm"] = ttk.Label(control_tab)
        labels["alarm"].grid(row=0, column=0, sticky="w")
        ttk.Spinbox(control_tab, from_=0, to=7, textvariable=alarm_slot_var, width=5).grid(
            row=1, column=0, sticky="ew", padx=2, pady=2
        )
        ttk.Entry(control_tab, textvariable=alarm_time_var, width=10).grid(
            row=1, column=1, sticky="ew", padx=2, pady=2
        )
        labels["enable"] = ttk.Checkbutton(control_tab, variable=alarm_enable_var)
        labels["enable"].grid(
            row=1, column=2, sticky="w", padx=2, pady=2
        )
        labels["set"] = ttk.Button(control_tab, command=alarm_set)
        labels["set"].grid(row=1, column=3, sticky="ew", padx=2, pady=2)
        labels["alarm_get_button"] = ttk.Button(control_tab, command=alarm_get)
        labels["alarm_get_button"].grid(row=2, column=3, sticky="ew", padx=2, pady=2)

        labels["schedule"] = ttk.Label(control_tab)
        labels["schedule"].grid(row=3, column=0, sticky="w", pady=(12, 0))
        ttk.Spinbox(control_tab, from_=0, to=7, textvariable=sched_slot_var, width=5).grid(
            row=4, column=0, sticky="ew", padx=2, pady=2
        )
        ttk.Entry(control_tab, textvariable=sched_time_var, width=10).grid(
            row=4, column=1, sticky="ew", padx=2, pady=2
        )
        sched_type = ttk.Combobox(
            control_tab,
            width=12,
            state="readonly",
        )
        sched_type.bind("<<ComboboxSelected>>", on_schedule_type_selected)
        sched_type.grid(row=4, column=2, sticky="ew", padx=2, pady=2)
        labels["enable_sched"] = ttk.Checkbutton(control_tab, variable=sched_enable_var)
        labels["enable_sched"].grid(
            row=5, column=2, sticky="w", padx=2, pady=2
        )
        labels["sched_set_button"] = ttk.Button(control_tab, command=sched_set)
        labels["sched_set_button"].grid(row=4, column=3, sticky="ew", padx=2, pady=2)
        labels["sched_get_button"] = ttk.Button(control_tab, command=sched_get)
        labels["sched_get_button"].grid(row=5, column=3, sticky="ew", padx=2, pady=2)

        labels["countdown"] = ttk.Label(control_tab)
        labels["countdown"].grid(row=6, column=0, sticky="w", pady=(12, 0))
        ttk.Entry(control_tab, textvariable=count_time_var, width=10).grid(
            row=7, column=0, sticky="ew", padx=2, pady=2
        )
        labels["count_set_button"] = ttk.Button(control_tab, command=count_set)
        labels["count_set_button"].grid(row=7, column=1, sticky="ew", padx=2, pady=2)
        labels["start"] = ttk.Button(control_tab, command=count_start)
        labels["start"].grid(row=7, column=2, sticky="ew", padx=2, pady=2)
        labels["stop"] = ttk.Button(control_tab, command=count_stop)
        labels["stop"].grid(row=7, column=3, sticky="ew", padx=2, pady=2)
        labels["count_status"] = ttk.Button(control_tab, command=count_status)
        labels["count_status"].grid(row=8, column=3, sticky="ew", padx=2, pady=2)

        log = scrolledtext.ScrolledText(log_tab, height=18, state="disabled")
        log.grid(row=0, column=0, sticky="nsew")

        language_display_var.trace_add("write", apply_language)
        apply_language()
        append_log(tr("log_started"))
        root.mainloop()
