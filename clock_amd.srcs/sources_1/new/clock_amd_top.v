module clock_amd_top(
    input  CLK100MHZ,
    input  CPU_RESETN,
    input  BTNL,
    input  BTNR,
    input  BTNU,
    input  BTND,
    input  BTNC,
    input  [15:0] SW,
    input  UART_RXD,
    output UART_TXD,
    output [7:0] AN,
    output CA,
    output CB,
    output CC,
    output CD,
    output CE,
    output CF,
    output CG,
    output DP,
    output [15:0] LED,
    output BUZZER_IO,
    inout  OLED_SCL,
    inout  OLED_SDA,
    inout  TMP_SCL,
    inout  TMP_SDA
);
    localparam integer TICK_1K_DIV = 17'd100000;

    reg [16:0] tick_1k_cnt;
    reg tick_1k;
    wire buzzer_on;
    wire countdown_run;
    wire [2:0] mode_state;
    wire setting_active;
    wire hour_format_12h;
    wire temp_valid;
    wire temp_negative;
    wire [7:0] temp_c_abs;
    wire temp_read_error;
    wire notify_active;
    wire [1:0] notify_type;
    wire [2:0] notify_slot;
    wire [2:0] comm_status;
    wire comm_reply_mode;
    wire [2:0] comm_reply_index;
    wire [3:0] comm_selected_slot;
    wire comm_message_valid;
    wire [2:0] comm_scroll_line;
    wire [151:0] comm_timestamp_ascii;
    wire [6:0] comm_message_len;
    wire [511:0] comm_message_window_ascii;
    wire [3:0] date_month_ten_bcd;
    wire [3:0] date_month_unit_bcd;
    wire [3:0] date_day_ten_bcd;
    wire [3:0] date_day_unit_bcd;
    wire [2:0] date_weekday;
    wire next_alarm_valid;
    wire [3:0] next_alarm_hour_ten_bcd;
    wire [3:0] next_alarm_hour_unit_bcd;
    wire [3:0] next_alarm_min_ten_bcd;
    wire [3:0] next_alarm_min_unit_bcd;
    wire next_schedule_valid;
    wire [2:0] next_schedule_slot;
    wire [3:0] next_schedule_hour_ten_bcd;
    wire [3:0] next_schedule_hour_unit_bcd;
    wire [3:0] next_schedule_min_ten_bcd;
    wire [3:0] next_schedule_min_unit_bcd;
    wire [3:0] countdown_hour_ten_bcd;
    wire [3:0] countdown_hour_unit_bcd;
    wire [3:0] countdown_min_ten_bcd;
    wire [3:0] countdown_min_unit_bcd;
    wire [3:0] countdown_sec_ten_bcd;
    wire [3:0] countdown_sec_unit_bcd;
    wire [7:0] slot_led_mask;
    wire [47:0] digit_code_bus;
    wire [7:0] dp_mask;

    always @(posedge CLK100MHZ or negedge CPU_RESETN) begin
        if (!CPU_RESETN) begin
            tick_1k_cnt <= 17'd0;
            tick_1k     <= 1'b0;
        end else if (tick_1k_cnt == TICK_1K_DIV - 1'b1) begin
            tick_1k_cnt <= 17'd0;
            tick_1k     <= 1'b1;
        end else begin
            tick_1k_cnt <= tick_1k_cnt + 1'b1;
            tick_1k     <= 1'b0;
        end
    end

    clock u_clock(
        .clk(CLK100MHZ),
        .tick_1k(tick_1k),
        .rst(CPU_RESETN),
        .btn_left(BTNL),
        .btn_right(BTNR),
        .btn_up(BTNU),
        .btn_down(BTND),
        .btn_center(BTNC),
        .sw(SW),
        .uart_rx(UART_RXD),
        .uart_tx(UART_TXD),
        .buzzer_on(buzzer_on),
        .countdown_run(countdown_run),
        .mode_state(mode_state),
        .setting_active(setting_active),
        .comm_status(comm_status),
        .comm_reply_mode(comm_reply_mode),
        .comm_reply_index(comm_reply_index),
        .comm_selected_slot(comm_selected_slot),
        .comm_message_valid(comm_message_valid),
        .comm_scroll_line(comm_scroll_line),
        .comm_timestamp_ascii(comm_timestamp_ascii),
        .comm_message_len(comm_message_len),
        .comm_message_window_ascii(comm_message_window_ascii),
        .hour_format_12h_out(hour_format_12h),
        .notify_active(notify_active),
        .notify_type(notify_type),
        .notify_slot(notify_slot),
        .date_month_ten_bcd(date_month_ten_bcd),
        .date_month_unit_bcd(date_month_unit_bcd),
        .date_day_ten_bcd(date_day_ten_bcd),
        .date_day_unit_bcd(date_day_unit_bcd),
        .date_weekday(date_weekday),
        .next_alarm_valid(next_alarm_valid),
        .next_alarm_hour_ten_bcd(next_alarm_hour_ten_bcd),
        .next_alarm_hour_unit_bcd(next_alarm_hour_unit_bcd),
        .next_alarm_min_ten_bcd(next_alarm_min_ten_bcd),
        .next_alarm_min_unit_bcd(next_alarm_min_unit_bcd),
        .next_schedule_valid(next_schedule_valid),
        .next_schedule_slot(next_schedule_slot),
        .next_schedule_hour_ten_bcd(next_schedule_hour_ten_bcd),
        .next_schedule_hour_unit_bcd(next_schedule_hour_unit_bcd),
        .next_schedule_min_ten_bcd(next_schedule_min_ten_bcd),
        .next_schedule_min_unit_bcd(next_schedule_min_unit_bcd),
        .countdown_hour_ten_bcd(countdown_hour_ten_bcd),
        .countdown_hour_unit_bcd(countdown_hour_unit_bcd),
        .countdown_min_ten_bcd(countdown_min_ten_bcd),
        .countdown_min_unit_bcd(countdown_min_unit_bcd),
        .countdown_sec_ten_bcd(countdown_sec_ten_bcd),
        .countdown_sec_unit_bcd(countdown_sec_unit_bcd),
        .slot_led_mask(slot_led_mask),
        .digit_code_bus(digit_code_bus),
        .dp_mask(dp_mask)
    );

    adt7420_reader u_adt7420_reader(
        .clk(CLK100MHZ),
        .rst(~CPU_RESETN),
        .temp_valid(temp_valid),
        .temp_negative(temp_negative),
        .temp_c_abs(temp_c_abs),
        .read_error(temp_read_error),
        .tmp_scl(TMP_SCL),
        .tmp_sda(TMP_SDA)
    );

    nexys_seg_scan u_nexys_seg_scan(
        .clk(CLK100MHZ),
        .rst(CPU_RESETN),
        .sec_unit_seg(8'd0),
        .sec_ten_bcd(4'd0),
        .min_unit_bcd(4'd0),
        .min_ten_bcd(4'd0),
        .hour_unit_bcd(4'd0),
        .hour_ten_bcd(4'd0),
        .full_display_en(1'b1),
        .digit_code_bus(digit_code_bus),
        .dp_mask(dp_mask),
        .an(AN),
        .CA(CA),
        .CB(CB),
        .CC(CC),
        .CD(CD),
        .CE(CE),
        .CF(CF),
        .CG(CG),
        .DP(DP)
    );

    oled_ui_display u_oled_ui_display(
        .clk(CLK100MHZ),
        .rst(~CPU_RESETN),
        .mode_state(mode_state),
        .edit_active(setting_active),
        .countdown_run(countdown_run),
        .hour_format_12h(hour_format_12h),
        .temp_valid(temp_valid),
        .temp_negative(temp_negative),
        .temp_c_abs(temp_c_abs),
        .notify_active(notify_active),
        .notify_type(notify_type),
        .notify_slot(notify_slot),
        .date_month_ten_bcd(date_month_ten_bcd),
        .date_month_unit_bcd(date_month_unit_bcd),
        .date_day_ten_bcd(date_day_ten_bcd),
        .date_day_unit_bcd(date_day_unit_bcd),
        .date_weekday(date_weekday),
        .next_alarm_valid(next_alarm_valid),
        .next_alarm_hour_ten_bcd(next_alarm_hour_ten_bcd),
        .next_alarm_hour_unit_bcd(next_alarm_hour_unit_bcd),
        .next_alarm_min_ten_bcd(next_alarm_min_ten_bcd),
        .next_alarm_min_unit_bcd(next_alarm_min_unit_bcd),
        .next_schedule_valid(next_schedule_valid),
        .next_schedule_slot(next_schedule_slot),
        .next_schedule_hour_ten_bcd(next_schedule_hour_ten_bcd),
        .next_schedule_hour_unit_bcd(next_schedule_hour_unit_bcd),
        .next_schedule_min_ten_bcd(next_schedule_min_ten_bcd),
        .next_schedule_min_unit_bcd(next_schedule_min_unit_bcd),
        .countdown_hour_ten_bcd(countdown_hour_ten_bcd),
        .countdown_hour_unit_bcd(countdown_hour_unit_bcd),
        .countdown_min_ten_bcd(countdown_min_ten_bcd),
        .countdown_min_unit_bcd(countdown_min_unit_bcd),
        .countdown_sec_ten_bcd(countdown_sec_ten_bcd),
        .countdown_sec_unit_bcd(countdown_sec_unit_bcd),
        .comm_status(comm_status),
        .comm_reply_mode(comm_reply_mode),
        .comm_reply_index(comm_reply_index),
        .comm_selected_slot(comm_selected_slot),
        .comm_message_valid(comm_message_valid),
        .comm_scroll_line(comm_scroll_line),
        .comm_timestamp_ascii(comm_timestamp_ascii),
        .comm_message_len(comm_message_len),
        .comm_message_window_ascii(comm_message_window_ascii),
        .init_done(),
        .error(),
        .oled_scl(OLED_SCL),
        .oled_sda(OLED_SDA)
    );

    // The active buzzer module is driven low to sound.
    assign BUZZER_IO = ~buzzer_on;
    assign LED = {8'b0000_0000, slot_led_mask};
endmodule
