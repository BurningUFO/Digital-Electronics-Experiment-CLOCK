from __future__ import annotations

from datetime import datetime

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
        "session": "连接测试",
        "hello": "握手",
        "ping": "连通测试",
        "status": "状态",
        "time": "时间同步",
        "sync": "同步电脑时间",
        "get": "读取",
        "message": "发送消息",
        "chat_history": "聊天记录",
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
        "log_title": "通信日志",
        "log_smaller": "缩小日志",
        "log_default": "默认大小",
        "log_larger": "放大日志",
        "log_started": "ClockLink Studio 已启动",
        "message_text": "消息正文",
        "decode_error": "消息解码失败",
        "error_prefix": "错误",
        "pc_label": "我（PC）",
        "fpga_label": "板子（FPGA）",
        "system_label": "系统",
        "empty_message": "请输入消息内容。",
        "message_stored": "消息已发送，FPGA 返回",
        "no_message": "该槽位暂无消息。",
    },
    "en": {
        "title": "ClockLink Studio",
        "ready": "Ready",
        "language": "Language",
        "tab_connect": "Connect",
        "tab_control": "Control",
        "session": "Session",
        "hello": "HELLO",
        "ping": "PING",
        "status": "STATUS",
        "time": "Time",
        "sync": "SYNC",
        "get": "GET",
        "message": "Message",
        "chat_history": "Chat",
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
        "log_title": "Communication Log",
        "log_smaller": "Smaller Log",
        "log_default": "Default",
        "log_larger": "Larger Log",
        "log_started": "ClockLink Studio started",
        "message_text": "message-text",
        "decode_error": "message-text decode error",
        "error_prefix": "ERROR",
        "pc_label": "Me (PC)",
        "fpga_label": "Board (FPGA)",
        "system_label": "System",
        "empty_message": "Enter a message first.",
        "message_stored": "Message sent, FPGA replied",
        "no_message": "No message in this slot.",
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
        log_height_ratios = (0.30, 0.48, 0.64)
        log_height_index = tk.IntVar(value=1)

        def tr(key: str) -> str:
            return TEXT[current_language()][key]

        def current_language() -> str:
            return LANGUAGE_OPTIONS.get(language_display_var.get(), "zh")

        def append_log(text: str) -> None:
            log.configure(state="normal")
            log.insert("end", text + "\n")
            log.see("end")
            log.configure(state="disabled")

        def append_chat(sender_key: str, text: str) -> None:
            tag = {
                "pc_label": "chat_pc",
                "fpga_label": "chat_fpga",
                "system_label": "chat_system",
            }.get(sender_key, "chat_system")
            timestamp = datetime.now().strftime("%H:%M:%S")
            sender = tr(sender_key)
            chat.configure(state="normal")
            chat.insert("end", f"{sender}  {timestamp}\n{text}\n\n", (tag,))
            chat.see("end")
            chat.configure(state="disabled")

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
            text = message_var.get().strip()
            if not text:
                append_chat("system_label", tr("empty_message"))
                return
            append_chat("pc_label", text)
            try:
                frame = self.client.send_message(text)
                show_frame("message", frame)
                append_chat("fpga_label", f"{tr('message_stored')}: {frame.cmd} {frame.payload}")
                message_var.set("")
            except Exception as exc:
                status_var.set(str(exc))
                append_log(f"{tr('error_prefix')} message: {exc}")
                append_chat("system_label", str(exc))
                messagebox.showerror("ClockLink", str(exc))

        def get_message() -> None:
            frame = self.client.get_message(msg_slot_var.get())
            show_frame("message-get", frame)
            payload = parse_payload(frame.payload)
            if payload.get("valid") == "1" and "text" in payload:
                try:
                    decoded = hex_to_ascii_text(payload["text"])
                    append_log(f"{tr('message_text')}: {decoded}")
                    append_chat("fpga_label", decoded)
                except FrameError as exc:
                    append_log(f"{tr('decode_error')}: {exc}")
                    append_chat("system_label", f"{tr('decode_error')}: {exc}")
            else:
                append_chat("system_label", tr("no_message"))

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

        def set_log_height(index: int) -> None:
            log_height_index.set(index)
            root.update_idletasks()
            pane_height = max(vertical_pane.winfo_height(), root.winfo_height() - 48, 520)
            target = int(pane_height * log_height_ratios[index])
            max_sash = max(240, pane_height - 100)
            sash_position = min(max(220, pane_height - target), max_sash)
            try:
                vertical_pane.sashpos(0, sash_position)
            except tk.TclError:
                pass

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

        vertical_pane = tk.PanedWindow(root, orient=tk.VERTICAL, sashwidth=6, sashrelief=tk.RAISED)
        vertical_pane.grid(row=1, column=0, sticky="nsew", padx=8, pady=(0, 8))

        top_area = ttk.Frame(vertical_pane)
        bottom_area = ttk.Frame(vertical_pane)
        vertical_pane.add(top_area, minsize=260)
        vertical_pane.add(bottom_area, minsize=90)
        top_area.columnconfigure(0, weight=1)
        top_area.rowconfigure(0, weight=1)
        bottom_area.columnconfigure(0, weight=1)
        bottom_area.rowconfigure(1, weight=1)

        tabs = ttk.Notebook(top_area)
        tabs.grid(row=0, column=0, sticky="nsew")

        main_tab = ttk.Frame(tabs, padding=8)
        control_tab = ttk.Frame(tabs, padding=8)
        tabs.add(main_tab)
        tabs.add(control_tab)
        tab_ids["connect"] = main_tab
        tab_ids["control"] = control_tab

        for col in range(4):
            main_tab.columnconfigure(col, weight=1)
            control_tab.columnconfigure(col, weight=1)

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
        message_entry = ttk.Entry(main_tab, textvariable=message_var)
        message_entry.grid(row=5, column=0, columnspan=3, sticky="ew", padx=2, pady=2)
        message_entry.bind("<Return>", lambda _event: send_message())
        labels["send"] = ttk.Button(main_tab, command=send_message)
        labels["send"].grid(row=5, column=3, sticky="ew", padx=2, pady=2)
        labels["chat_history"] = ttk.Label(main_tab)
        labels["chat_history"].grid(row=6, column=0, sticky="nw", padx=2, pady=(8, 2))
        chat = scrolledtext.ScrolledText(main_tab, height=9, state="disabled", wrap="word")
        chat.grid(row=7, column=0, columnspan=4, sticky="nsew", padx=2, pady=2)
        chat.tag_configure(
            "chat_pc",
            justify="right",
            lmargin1=120,
            lmargin2=120,
            rmargin=8,
            spacing1=4,
            spacing3=8,
            background="#e8f1ff",
        )
        chat.tag_configure(
            "chat_fpga",
            justify="left",
            lmargin1=8,
            lmargin2=8,
            rmargin=120,
            spacing1=4,
            spacing3=8,
            background="#edf7ed",
        )
        chat.tag_configure(
            "chat_system",
            justify="center",
            lmargin1=48,
            lmargin2=48,
            rmargin=48,
            spacing1=4,
            spacing3=8,
            foreground="#606060",
            background="#f5f5f5",
        )
        main_tab.rowconfigure(7, weight=1)
        labels["slot"] = ttk.Label(main_tab)
        labels["slot"].grid(row=8, column=0, sticky="w", padx=2, pady=2)
        ttk.Spinbox(main_tab, from_=0, to=15, textvariable=msg_slot_var, width=5).grid(
            row=8, column=1, sticky="w", padx=2, pady=2
        )
        labels["msg_get"] = ttk.Button(main_tab, command=get_message)
        labels["msg_get"].grid(row=8, column=2, sticky="ew", padx=2, pady=2)

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

        log_toolbar = ttk.Frame(bottom_area)
        log_toolbar.grid(row=0, column=0, sticky="ew")
        log_toolbar.columnconfigure(0, weight=1)
        labels["log_title"] = ttk.Label(log_toolbar)
        labels["log_title"].grid(row=0, column=0, sticky="w")
        labels["log_smaller"] = ttk.Button(log_toolbar, command=lambda: set_log_height(0))
        labels["log_smaller"].grid(row=0, column=1, sticky="e", padx=2)
        labels["log_default"] = ttk.Button(log_toolbar, command=lambda: set_log_height(1))
        labels["log_default"].grid(row=0, column=2, sticky="e", padx=2)
        labels["log_larger"] = ttk.Button(log_toolbar, command=lambda: set_log_height(2))
        labels["log_larger"].grid(row=0, column=3, sticky="e", padx=2)

        log = scrolledtext.ScrolledText(bottom_area, height=8, state="disabled", wrap="none")
        log.grid(row=1, column=0, sticky="nsew", pady=(4, 0))

        language_display_var.trace_add("write", apply_language)
        apply_language()
        append_log(tr("log_started"))
        append_chat("system_label", tr("log_started"))
        root.after(100, lambda: set_log_height(log_height_index.get()))
        root.mainloop()
