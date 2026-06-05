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
        "app_name": "ClockLink Studio",
        "subtitle": "Nexys A7 USB-UART 通信控制台",
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
        "message_tools": "消息工具",
        "chat_history": "ClockLink 对话",
        "chat_subtitle": "PC 与 FPGA 的消息互动记录",
        "send": "发送",
        "slot": "消息槽位",
        "msg_get": "读取消息",
        "alarm": "闹钟",
        "schedule": "日程",
        "countdown": "倒计时",
        "control_hint": "直接写入 FPGA 内部模块，不模拟按键",
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
        "log_smaller": "缩小",
        "log_default": "默认",
        "log_larger": "放大",
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
        "app_name": "ClockLink Studio",
        "subtitle": "Nexys A7 USB-UART Control Console",
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
        "message_tools": "Message Tools",
        "chat_history": "ClockLink Chat",
        "chat_subtitle": "PC and FPGA message history",
        "send": "SEND",
        "slot": "Message Slot",
        "msg_get": "MSG GET",
        "alarm": "Alarm",
        "schedule": "Schedule",
        "countdown": "Countdown",
        "control_hint": "Direct FPGA module writes, no button simulation",
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
        "log_smaller": "Smaller",
        "log_default": "Default",
        "log_larger": "Larger",
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

COLORS = {
    "window": "#eef3f8",
    "surface": "#ffffff",
    "surface_soft": "#f7f9fc",
    "border": "#d9e2ec",
    "text": "#172033",
    "muted": "#667085",
    "primary": "#2aabee",
    "primary_dark": "#1686bd",
    "bubble_pc": "#2aabee",
    "bubble_fpga": "#ffffff",
    "bubble_system": "#dfe7ef",
    "chat": "#e8eef5",
    "log_bg": "#111827",
    "log_fg": "#dbeafe",
}


class ClockLinkWindow:
    def __init__(self, client, language: str = "zh") -> None:
        self.client = client
        self.language = language if language in TEXT else "zh"

    def run(self) -> None:
        import tkinter as tk
        from tkinter import font as tkfont
        from tkinter import messagebox, scrolledtext, ttk

        root = tk.Tk()
        root.title(TEXT[self.language]["title"])
        root.minsize(980, 680)
        root.configure(bg=COLORS["window"])

        body_font = tkfont.Font(family="Microsoft YaHei UI", size=10)
        strong_font = tkfont.Font(family="Microsoft YaHei UI", size=10, weight="bold")
        title_font = tkfont.Font(family="Microsoft YaHei UI", size=18, weight="bold")
        subtitle_font = tkfont.Font(family="Microsoft YaHei UI", size=10)
        small_font = tkfont.Font(family="Microsoft YaHei UI", size=9)
        code_font = tkfont.Font(family="Consolas", size=9)
        root.option_add("*Font", body_font)

        style = ttk.Style(root)
        try:
            style.theme_use("clam")
        except tk.TclError:
            pass
        style.configure("TFrame", background=COLORS["window"])
        style.configure("Page.TFrame", background=COLORS["surface"], borderwidth=0)
        style.configure("Card.TFrame", background=COLORS["surface"], relief="flat")
        style.configure("Soft.TFrame", background=COLORS["surface_soft"], relief="flat")
        style.configure("TLabel", background=COLORS["window"], foreground=COLORS["text"])
        style.configure("Card.TLabel", background=COLORS["surface"], foreground=COLORS["text"])
        style.configure("Muted.TLabel", background=COLORS["surface"], foreground=COLORS["muted"], font=small_font)
        style.configure("Soft.TLabel", background=COLORS["surface_soft"], foreground=COLORS["muted"], font=small_font)
        style.configure("TButton", padding=(12, 8), font=body_font)
        style.configure("Primary.TButton", padding=(14, 9), font=strong_font)
        style.map(
            "Primary.TButton",
            foreground=[("active", "#ffffff"), ("!disabled", "#ffffff")],
            background=[("active", COLORS["primary_dark"]), ("!disabled", COLORS["primary"])],
        )
        style.configure("Tool.TButton", padding=(10, 6), font=small_font)
        style.configure("TEntry", fieldbackground="#ffffff", bordercolor=COLORS["border"], padding=6)
        style.configure("TCombobox", fieldbackground="#ffffff", bordercolor=COLORS["border"], padding=4)
        style.configure("TSpinbox", fieldbackground="#ffffff", bordercolor=COLORS["border"], padding=4)
        style.configure("Modern.TNotebook", background=COLORS["window"], borderwidth=0)
        style.configure(
            "Modern.TNotebook.Tab",
            background=COLORS["surface_soft"],
            foreground=COLORS["muted"],
            padding=(18, 9),
            font=strong_font,
        )
        style.map(
            "Modern.TNotebook.Tab",
            background=[("selected", COLORS["surface"])],
            foreground=[("selected", COLORS["primary_dark"])],
        )

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
        log_height_ratios = (0.28, 0.44, 0.62)
        log_height_index = tk.IntVar(value=1)
        chat_rows = {"value": 0}

        def tr(key: str) -> str:
            return TEXT[current_language()][key]

        def current_language() -> str:
            return LANGUAGE_OPTIONS.get(language_display_var.get(), "zh")

        def rounded_rect(canvas, x1: int, y1: int, x2: int, y2: int, radius: int, **kwargs) -> None:
            canvas.create_rectangle(x1 + radius, y1, x2 - radius, y2, **kwargs)
            canvas.create_rectangle(x1, y1 + radius, x2, y2 - radius, **kwargs)
            canvas.create_oval(x1, y1, x1 + radius * 2, y1 + radius * 2, **kwargs)
            canvas.create_oval(x2 - radius * 2, y1, x2, y1 + radius * 2, **kwargs)
            canvas.create_oval(x1, y2 - radius * 2, x1 + radius * 2, y2, **kwargs)
            canvas.create_oval(x2 - radius * 2, y2 - radius * 2, x2, y2, **kwargs)

        def wrap_pixels(text: str, max_width: int, text_font) -> list[str]:
            lines: list[str] = []
            for paragraph in text.splitlines() or [""]:
                current = ""
                for char in paragraph:
                    candidate = current + char
                    if current and text_font.measure(candidate) > max_width:
                        lines.append(current.rstrip())
                        current = char.lstrip()
                    else:
                        current = candidate
                lines.append(current.rstrip())
            return lines or [""]

        def append_log(text: str) -> None:
            log.configure(state="normal")
            log.insert("end", text + "\n")
            log.see("end")
            log.configure(state="disabled")

        def append_chat(sender_key: str, text: str) -> None:
            timestamp = datetime.now().strftime("%H:%M")
            sender = tr(sender_key)
            is_pc = sender_key == "pc_label"
            is_fpga = sender_key == "fpga_label"
            fill = COLORS["bubble_pc"] if is_pc else COLORS["bubble_fpga"] if is_fpga else COLORS["bubble_system"]
            text_color = "#ffffff" if is_pc else COLORS["text"]
            meta_color = "#d8f1ff" if is_pc else COLORS["muted"]
            outline = fill if is_pc or not is_fpga else COLORS["border"]
            max_width = max(300, min(560, chat_canvas.winfo_width() - 150))
            content_lines = wrap_pixels(text, max_width - 34, body_font)
            content_width = max([body_font.measure(line) for line in content_lines] + [body_font.measure(sender)])
            bubble_width = min(max(180, content_width + 34), max_width)
            line_height = body_font.metrics("linespace") + 3
            meta_height = small_font.metrics("linespace")
            bubble_height = 16 + meta_height + 8 + len(content_lines) * line_height + 16

            row = tk.Frame(chat_body, bg=COLORS["chat"])
            row.grid(row=chat_rows["value"], column=0, sticky="ew", padx=18, pady=(6, 8))
            row.columnconfigure(0, weight=1)
            row.columnconfigure(1, weight=0)
            row.columnconfigure(2, weight=1)
            chat_rows["value"] += 1

            bubble = tk.Canvas(
                row,
                width=bubble_width,
                height=bubble_height,
                bg=COLORS["chat"],
                highlightthickness=0,
                bd=0,
            )
            if is_pc:
                bubble.grid(row=0, column=2, sticky="e")
            elif is_fpga:
                bubble.grid(row=0, column=0, sticky="w")
            else:
                bubble.grid(row=0, column=0, columnspan=3)

            rounded_rect(
                bubble,
                1,
                1,
                bubble_width - 2,
                bubble_height - 2,
                16,
                fill=fill,
                outline=outline,
            )
            bubble.create_text(
                17,
                12,
                anchor="nw",
                text=f"{sender}  {timestamp}",
                fill=meta_color,
                font=small_font,
            )
            bubble.create_text(
                17,
                12 + meta_height + 8,
                anchor="nw",
                text="\n".join(content_lines),
                fill=text_color,
                font=body_font,
            )
            bubble.bind("<MouseWheel>", on_chat_mousewheel)
            chat_canvas.update_idletasks()
            chat_canvas.configure(scrollregion=chat_canvas.bbox("all"))
            chat_canvas.yview_moveto(1.0)

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
            pane_height = max(vertical_pane.winfo_height(), root.winfo_height() - 88, 560)
            target = int(pane_height * log_height_ratios[index])
            max_sash = max(280, pane_height - 110)
            sash_position = min(max(260, pane_height - target), max_sash)
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

        def make_panel(parent, **grid):
            frame = ttk.Frame(parent, style="Card.TFrame", padding=14)
            frame.grid(**grid)
            return frame

        def make_section_label(parent, key: str, row: int, column: int = 0, columnspan: int = 1, pady=(0, 8)):
            labels[key] = ttk.Label(parent, style="Card.TLabel", font=strong_font)
            labels[key].grid(row=row, column=column, columnspan=columnspan, sticky="w", pady=pady)
            return labels[key]

        def on_chat_body_configure(_event=None) -> None:
            chat_canvas.configure(scrollregion=chat_canvas.bbox("all"))

        def on_chat_canvas_configure(event) -> None:
            chat_canvas.itemconfigure(chat_window, width=event.width)
            chat_canvas.configure(scrollregion=chat_canvas.bbox("all"))

        def on_chat_mousewheel(event) -> None:
            chat_canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")

        root.columnconfigure(0, weight=1)
        root.rowconfigure(1, weight=1)

        header = tk.Frame(root, bg=COLORS["surface"], highlightthickness=1, highlightbackground=COLORS["border"])
        header.grid(row=0, column=0, sticky="ew", padx=12, pady=(12, 8))
        header.columnconfigure(1, weight=1)

        brand = tk.Frame(header, bg=COLORS["surface"])
        brand.grid(row=0, column=0, sticky="w", padx=18, pady=14)
        labels["app_name"] = tk.Label(brand, bg=COLORS["surface"], fg=COLORS["text"], font=title_font)
        labels["app_name"].grid(row=0, column=0, sticky="w")
        labels["subtitle"] = tk.Label(brand, bg=COLORS["surface"], fg=COLORS["muted"], font=subtitle_font)
        labels["subtitle"].grid(row=1, column=0, sticky="w", pady=(2, 0))

        status_chip = tk.Label(
            header,
            textvariable=status_var,
            bg=COLORS["surface_soft"],
            fg=COLORS["muted"],
            font=small_font,
            padx=12,
            pady=7,
            anchor="w",
        )
        status_chip.grid(row=0, column=1, sticky="ew", padx=12)

        lang_area = tk.Frame(header, bg=COLORS["surface"])
        lang_area.grid(row=0, column=2, sticky="e", padx=(0, 18))
        labels["language"] = tk.Label(lang_area, bg=COLORS["surface"], fg=COLORS["muted"], font=small_font)
        labels["language"].grid(row=0, column=0, sticky="e", padx=(0, 8))
        language_box = ttk.Combobox(
            lang_area,
            textvariable=language_display_var,
            values=list(LANGUAGE_OPTIONS.keys()),
            state="readonly",
            width=9,
        )
        language_box.grid(row=0, column=1, sticky="e")

        vertical_pane = tk.PanedWindow(
            root,
            orient=tk.VERTICAL,
            sashwidth=7,
            sashrelief=tk.FLAT,
            bg=COLORS["window"],
            bd=0,
            showhandle=False,
        )
        vertical_pane.grid(row=1, column=0, sticky="nsew", padx=12, pady=(0, 12))

        top_area = ttk.Frame(vertical_pane, style="TFrame")
        bottom_area = ttk.Frame(vertical_pane, style="Card.TFrame", padding=(12, 10))
        vertical_pane.add(top_area, minsize=380)
        vertical_pane.add(bottom_area, minsize=110)
        top_area.columnconfigure(0, weight=1)
        top_area.rowconfigure(0, weight=1)
        bottom_area.columnconfigure(0, weight=1)
        bottom_area.rowconfigure(1, weight=1)

        tabs = ttk.Notebook(top_area, style="Modern.TNotebook")
        tabs.grid(row=0, column=0, sticky="nsew")

        main_tab = ttk.Frame(tabs, style="Page.TFrame", padding=14)
        control_tab = ttk.Frame(tabs, style="Page.TFrame", padding=14)
        tabs.add(main_tab)
        tabs.add(control_tab)
        tab_ids["connect"] = main_tab
        tab_ids["control"] = control_tab

        main_tab.columnconfigure(0, minsize=270)
        main_tab.columnconfigure(1, weight=1)
        main_tab.rowconfigure(0, weight=1)

        left_panel = make_panel(main_tab, row=0, column=0, sticky="nsew", padx=(0, 12))
        left_panel.columnconfigure(0, weight=1)
        left_panel.columnconfigure(1, weight=1)

        make_section_label(left_panel, "session", 0, columnspan=2)
        labels["hello"] = ttk.Button(left_panel, style="Primary.TButton", command=lambda: run_action("hello", self.client.hello))
        labels["hello"].grid(row=1, column=0, sticky="ew", padx=(0, 4), pady=4)
        labels["ping"] = ttk.Button(left_panel, command=ping)
        labels["ping"].grid(row=1, column=1, sticky="ew", padx=(4, 0), pady=4)
        labels["status"] = ttk.Button(left_panel, command=status)
        labels["status"].grid(row=2, column=0, columnspan=2, sticky="ew", pady=4)

        make_section_label(left_panel, "time", 3, columnspan=2, pady=(18, 8))
        labels["sync"] = ttk.Button(left_panel, style="Primary.TButton", command=sync_time)
        labels["sync"].grid(row=4, column=0, columnspan=2, sticky="ew", pady=4)
        labels["get"] = ttk.Button(left_panel, command=time_get)
        labels["get"].grid(row=5, column=0, columnspan=2, sticky="ew", pady=4)

        make_section_label(left_panel, "message_tools", 6, columnspan=2, pady=(18, 8))
        labels["slot"] = ttk.Label(left_panel, style="Card.TLabel")
        labels["slot"].grid(row=7, column=0, sticky="w", pady=4)
        ttk.Spinbox(left_panel, from_=0, to=15, textvariable=msg_slot_var, width=5).grid(
            row=7,
            column=1,
            sticky="ew",
            pady=4,
        )
        labels["msg_get"] = ttk.Button(left_panel, command=get_message)
        labels["msg_get"].grid(row=8, column=0, columnspan=2, sticky="ew", pady=4)

        chat_panel = tk.Frame(
            main_tab,
            bg=COLORS["surface"],
            highlightthickness=1,
            highlightbackground=COLORS["border"],
        )
        chat_panel.grid(row=0, column=1, sticky="nsew")
        chat_panel.columnconfigure(0, weight=1)
        chat_panel.rowconfigure(1, weight=1)

        chat_header = tk.Frame(chat_panel, bg=COLORS["surface"])
        chat_header.grid(row=0, column=0, sticky="ew", padx=16, pady=(14, 8))
        chat_header.columnconfigure(0, weight=1)
        labels["chat_history"] = tk.Label(chat_header, bg=COLORS["surface"], fg=COLORS["text"], font=strong_font)
        labels["chat_history"].grid(row=0, column=0, sticky="w")
        labels["chat_subtitle"] = tk.Label(chat_header, bg=COLORS["surface"], fg=COLORS["muted"], font=small_font)
        labels["chat_subtitle"].grid(row=1, column=0, sticky="w", pady=(2, 0))

        chat_shell = tk.Frame(chat_panel, bg=COLORS["chat"])
        chat_shell.grid(row=1, column=0, sticky="nsew", padx=16, pady=(0, 10))
        chat_shell.columnconfigure(0, weight=1)
        chat_shell.rowconfigure(0, weight=1)
        chat_canvas = tk.Canvas(chat_shell, bg=COLORS["chat"], bd=0, highlightthickness=0)
        chat_scroll = ttk.Scrollbar(chat_shell, orient="vertical", command=chat_canvas.yview)
        chat_canvas.configure(yscrollcommand=chat_scroll.set)
        chat_canvas.grid(row=0, column=0, sticky="nsew")
        chat_scroll.grid(row=0, column=1, sticky="ns")
        chat_body = tk.Frame(chat_canvas, bg=COLORS["chat"])
        chat_body.columnconfigure(0, weight=1)
        chat_window = chat_canvas.create_window((0, 0), window=chat_body, anchor="nw")
        chat_body.bind("<Configure>", on_chat_body_configure)
        chat_canvas.bind("<Configure>", on_chat_canvas_configure)
        chat_canvas.bind("<MouseWheel>", on_chat_mousewheel)

        composer = tk.Frame(chat_panel, bg=COLORS["surface"])
        composer.grid(row=2, column=0, sticky="ew", padx=16, pady=(0, 14))
        composer.columnconfigure(0, weight=1)
        labels["message"] = tk.Label(composer, bg=COLORS["surface"], fg=COLORS["muted"], font=small_font)
        labels["message"].grid(row=0, column=0, sticky="w", pady=(0, 5))
        message_entry = ttk.Entry(composer, textvariable=message_var)
        message_entry.grid(row=1, column=0, sticky="ew", padx=(0, 8))
        message_entry.bind("<Return>", lambda _event: send_message())
        labels["send"] = ttk.Button(composer, style="Primary.TButton", command=send_message)
        labels["send"].grid(row=1, column=1, sticky="ew")

        control_tab.columnconfigure(0, weight=1)
        control_tab.columnconfigure(1, weight=1)
        control_tab.rowconfigure(2, weight=1)

        control_header = ttk.Frame(control_tab, style="Page.TFrame")
        control_header.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 12))
        labels["control_hint"] = ttk.Label(control_header, style="Card.TLabel", font=subtitle_font)
        labels["control_hint"].grid(row=0, column=0, sticky="w")

        alarm_card = make_panel(control_tab, row=1, column=0, sticky="nsew", padx=(0, 8), pady=(0, 12))
        alarm_card.columnconfigure(0, weight=1)
        alarm_card.columnconfigure(1, weight=1)
        alarm_card.columnconfigure(2, weight=1)
        alarm_card.columnconfigure(3, weight=1)
        make_section_label(alarm_card, "alarm", 0, columnspan=4)
        ttk.Spinbox(alarm_card, from_=0, to=7, textvariable=alarm_slot_var, width=5).grid(
            row=1,
            column=0,
            sticky="ew",
            padx=(0, 6),
            pady=4,
        )
        ttk.Entry(alarm_card, textvariable=alarm_time_var, width=10).grid(row=1, column=1, sticky="ew", padx=6, pady=4)
        labels["enable"] = ttk.Checkbutton(alarm_card, variable=alarm_enable_var)
        labels["enable"].grid(row=1, column=2, sticky="w", padx=6, pady=4)
        labels["set"] = ttk.Button(alarm_card, style="Primary.TButton", command=alarm_set)
        labels["set"].grid(row=1, column=3, sticky="ew", padx=(6, 0), pady=4)
        labels["alarm_get_button"] = ttk.Button(alarm_card, command=alarm_get)
        labels["alarm_get_button"].grid(row=2, column=3, sticky="ew", padx=(6, 0), pady=4)

        schedule_card = make_panel(control_tab, row=1, column=1, sticky="nsew", padx=(8, 0), pady=(0, 12))
        schedule_card.columnconfigure(0, weight=1)
        schedule_card.columnconfigure(1, weight=1)
        schedule_card.columnconfigure(2, weight=2)
        schedule_card.columnconfigure(3, weight=1)
        make_section_label(schedule_card, "schedule", 0, columnspan=4)
        ttk.Spinbox(schedule_card, from_=0, to=7, textvariable=sched_slot_var, width=5).grid(
            row=1,
            column=0,
            sticky="ew",
            padx=(0, 6),
            pady=4,
        )
        ttk.Entry(schedule_card, textvariable=sched_time_var, width=10).grid(
            row=1,
            column=1,
            sticky="ew",
            padx=6,
            pady=4,
        )
        sched_type = ttk.Combobox(schedule_card, width=12, state="readonly")
        sched_type.bind("<<ComboboxSelected>>", on_schedule_type_selected)
        sched_type.grid(row=1, column=2, sticky="ew", padx=6, pady=4)
        labels["sched_set_button"] = ttk.Button(schedule_card, style="Primary.TButton", command=sched_set)
        labels["sched_set_button"].grid(row=1, column=3, sticky="ew", padx=(6, 0), pady=4)
        labels["enable_sched"] = ttk.Checkbutton(schedule_card, variable=sched_enable_var)
        labels["enable_sched"].grid(row=2, column=2, sticky="w", padx=6, pady=4)
        labels["sched_get_button"] = ttk.Button(schedule_card, command=sched_get)
        labels["sched_get_button"].grid(row=2, column=3, sticky="ew", padx=(6, 0), pady=4)

        count_card = make_panel(control_tab, row=2, column=0, columnspan=2, sticky="new", pady=(0, 0))
        for col in range(5):
            count_card.columnconfigure(col, weight=1)
        make_section_label(count_card, "countdown", 0, columnspan=5)
        ttk.Entry(count_card, textvariable=count_time_var, width=10).grid(
            row=1,
            column=0,
            sticky="ew",
            padx=(0, 6),
            pady=4,
        )
        labels["count_set_button"] = ttk.Button(count_card, style="Primary.TButton", command=count_set)
        labels["count_set_button"].grid(row=1, column=1, sticky="ew", padx=6, pady=4)
        labels["start"] = ttk.Button(count_card, command=count_start)
        labels["start"].grid(row=1, column=2, sticky="ew", padx=6, pady=4)
        labels["stop"] = ttk.Button(count_card, command=count_stop)
        labels["stop"].grid(row=1, column=3, sticky="ew", padx=6, pady=4)
        labels["count_status"] = ttk.Button(count_card, command=count_status)
        labels["count_status"].grid(row=1, column=4, sticky="ew", padx=(6, 0), pady=4)

        log_toolbar = ttk.Frame(bottom_area, style="Card.TFrame")
        log_toolbar.grid(row=0, column=0, sticky="ew", pady=(0, 8))
        log_toolbar.columnconfigure(0, weight=1)
        labels["log_title"] = ttk.Label(log_toolbar, style="Card.TLabel", font=strong_font)
        labels["log_title"].grid(row=0, column=0, sticky="w")
        labels["log_smaller"] = ttk.Button(log_toolbar, style="Tool.TButton", command=lambda: set_log_height(0))
        labels["log_smaller"].grid(row=0, column=1, sticky="e", padx=3)
        labels["log_default"] = ttk.Button(log_toolbar, style="Tool.TButton", command=lambda: set_log_height(1))
        labels["log_default"].grid(row=0, column=2, sticky="e", padx=3)
        labels["log_larger"] = ttk.Button(log_toolbar, style="Tool.TButton", command=lambda: set_log_height(2))
        labels["log_larger"].grid(row=0, column=3, sticky="e", padx=3)

        log = scrolledtext.ScrolledText(
            bottom_area,
            height=8,
            state="disabled",
            wrap="none",
            bg=COLORS["log_bg"],
            fg=COLORS["log_fg"],
            insertbackground=COLORS["log_fg"],
            relief="flat",
            font=code_font,
            padx=10,
            pady=8,
        )
        log.grid(row=1, column=0, sticky="nsew")

        language_display_var.trace_add("write", apply_language)
        apply_language()
        append_log(tr("log_started"))
        append_chat("system_label", tr("log_started"))
        root.after(120, lambda: set_log_height(log_height_index.get()))
        root.mainloop()
