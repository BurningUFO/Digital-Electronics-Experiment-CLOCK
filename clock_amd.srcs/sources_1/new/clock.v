module clock(
    input clk,
    input tick_1k,
    input rst,
    input btn_left,
    input btn_right,
    input btn_up,
    input btn_down,
    input btn_center,
    input [15:0] sw,
    input uart_rx,
    output uart_tx,
    output buzzer_on,
    output countdown_run,
    output [2:0] mode_state,
    output setting_active,
    output [2:0] comm_status,
    output comm_reply_mode,
    output [2:0] comm_reply_index,
    output [3:0] comm_selected_slot,
    output comm_message_valid,
    output [2:0] comm_scroll_line,
    output [151:0] comm_timestamp_ascii,
    output [6:0] comm_message_len,
    output [511:0] comm_message_window_ascii,
    output hour_format_12h_out,
    output notify_active,
    output [1:0] notify_type,
    output [2:0] notify_slot,
    output [3:0] date_month_ten_bcd,
    output [3:0] date_month_unit_bcd,
    output [3:0] date_day_ten_bcd,
    output [3:0] date_day_unit_bcd,
    output [2:0] date_weekday,
    output next_alarm_valid,
    output [3:0] next_alarm_hour_ten_bcd,
    output [3:0] next_alarm_hour_unit_bcd,
    output [3:0] next_alarm_min_ten_bcd,
    output [3:0] next_alarm_min_unit_bcd,
    output next_schedule_valid,
    output [2:0] next_schedule_slot,
    output [3:0] next_schedule_hour_ten_bcd,
    output [3:0] next_schedule_hour_unit_bcd,
    output [3:0] next_schedule_min_ten_bcd,
    output [3:0] next_schedule_min_unit_bcd,
    output [3:0] countdown_hour_ten_bcd,
    output [3:0] countdown_hour_unit_bcd,
    output [3:0] countdown_min_ten_bcd,
    output [3:0] countdown_min_unit_bcd,
    output [3:0] countdown_sec_ten_bcd,
    output [3:0] countdown_sec_unit_bcd,
    output [7:0] slot_led_mask,
    output [47:0] digit_code_bus,
    output [7:0] dp_mask
);
    wire tick_1h;
    wire [3:0] sec_u_time;
    wire [3:0] sec_t_time;
    wire [3:0] min_u_time;
    wire [3:0] min_t_time;
    wire [3:0] hour_u_time;
    wire [3:0] hour_t_time;
    wire [3:0] disp_hour_u_time;
    wire [3:0] disp_hour_t_time;
    wire [3:0] date_month_ten;
    wire [3:0] date_month_unit;
    wire [3:0] date_day_ten;
    wire [3:0] date_day_unit;
    wire [3:0] date_year_thousand;
    wire [3:0] date_year_hundred;
    wire [3:0] date_year_ten;
    wire [3:0] date_year_unit;
    wire pc_time_load_valid;
    wire [3:0] pc_hour_ten_bcd;
    wire [3:0] pc_hour_unit_bcd;
    wire [3:0] pc_min_ten_bcd;
    wire [3:0] pc_min_unit_bcd;
    wire [3:0] pc_sec_ten_bcd;
    wire [3:0] pc_sec_unit_bcd;
    wire pc_date_load_valid;
    wire [3:0] pc_year_thousand_bcd;
    wire [3:0] pc_year_hundred_bcd;
    wire [3:0] pc_year_ten_bcd;
    wire [3:0] pc_year_unit_bcd;
    wire [3:0] pc_month_ten_bcd;
    wire [3:0] pc_month_unit_bcd;
    wire [3:0] pc_day_ten_bcd;
    wire [3:0] pc_day_unit_bcd;
    wire [2:0] pc_weekday;
    wire pc_alarm_write_valid;
    wire [2:0] pc_alarm_write_slot;
    wire [3:0] pc_alarm_write_hour_ten_bcd;
    wire [3:0] pc_alarm_write_hour_unit_bcd;
    wire [3:0] pc_alarm_write_min_ten_bcd;
    wire [3:0] pc_alarm_write_min_unit_bcd;
    wire [3:0] pc_alarm_write_sec_ten_bcd;
    wire [3:0] pc_alarm_write_sec_unit_bcd;
    wire pc_alarm_write_enable;
    wire [2:0] pc_alarm_read_slot;
    wire [3:0] pc_alarm_read_hour_ten_bcd;
    wire [3:0] pc_alarm_read_hour_unit_bcd;
    wire [3:0] pc_alarm_read_min_ten_bcd;
    wire [3:0] pc_alarm_read_min_unit_bcd;
    wire [3:0] pc_alarm_read_sec_ten_bcd;
    wire [3:0] pc_alarm_read_sec_unit_bcd;
    wire pc_alarm_read_enable;
    wire pc_sched_write_valid;
    wire [2:0] pc_sched_write_slot;
    wire [3:0] pc_sched_write_hour_ten_bcd;
    wire [3:0] pc_sched_write_hour_unit_bcd;
    wire [3:0] pc_sched_write_min_ten_bcd;
    wire [3:0] pc_sched_write_min_unit_bcd;
    wire [3:0] pc_sched_write_sec_ten_bcd;
    wire [3:0] pc_sched_write_sec_unit_bcd;
    wire [2:0] pc_sched_write_type;
    wire pc_sched_write_enable;
    wire [2:0] pc_sched_read_slot;
    wire [3:0] pc_sched_read_hour_ten_bcd;
    wire [3:0] pc_sched_read_hour_unit_bcd;
    wire [3:0] pc_sched_read_min_ten_bcd;
    wire [3:0] pc_sched_read_min_unit_bcd;
    wire [3:0] pc_sched_read_sec_ten_bcd;
    wire [3:0] pc_sched_read_sec_unit_bcd;
    wire [2:0] pc_sched_read_type;
    wire pc_sched_read_enable;
    wire pc_count_load_valid;
    wire [3:0] pc_count_hour_ten_bcd;
    wire [3:0] pc_count_hour_unit_bcd;
    wire [3:0] pc_count_min_ten_bcd;
    wire [3:0] pc_count_min_unit_bcd;
    wire [3:0] pc_count_sec_ten_bcd;
    wire [3:0] pc_count_sec_unit_bcd;
    wire pc_count_start_pulse;
    wire pc_count_stop_pulse;
    wire [5:0] sec_u_disp;
    wire [5:0] sec_t_disp;
    wire [5:0] min_u_disp;
    wire [5:0] min_t_disp;
    wire [5:0] hour_u_disp;
    wire [5:0] hour_t_disp;
    wire [5:0] mode_disp_code;
    wire [5:0] status_disp_code;
    wire dp_indicator;

    wire mode_time_set;
    wire mode_alarm;
    wire mode_hour_format;
    wire mode_countdown;
    wire mode_schedule;
    wire mode_comm;
    wire blink_hide;
    wire [2:0] field_index;
    wire value_inc_pulse;
    wire value_dec_pulse;
    wire confirm_pulse;
    wire btn_left_pulse_raw;
    wire btn_right_pulse_raw;
    wire btn_up_pulse_raw;
    wire btn_down_pulse_raw;
    wire btn_center_pulse_raw;
    wire [3:0] alarm_hour_ten;
    wire [3:0] alarm_hour_unit;
    wire [3:0] alarm_min_ten;
    wire [3:0] alarm_min_unit;
    wire [3:0] alarm_sec_ten;
    wire [3:0] alarm_sec_unit;
    wire alarm_enable;
    wire alarm_match;
    wire alarm_beep_legacy;
    wire [2:0] alarm_selected_slot;
    wire [7:0] alarm_slot_enable_mask;
    wire [7:0] alarm_slot_selected_mask;
    wire [7:0] alarm_pending_mask;
    wire next_alarm_valid_raw;
    wire [2:0] next_alarm_slot;
    wire [3:0] next_alarm_sec_ten;
    wire [3:0] next_alarm_sec_unit;
    wire [3:0] next_alarm_min_ten;
    wire [3:0] next_alarm_min_unit;
    wire [3:0] next_alarm_hour_ten;
    wire [3:0] next_alarm_hour_unit;
    wire alarm_event_valid;
    wire [2:0] alarm_event_slot;
    wire [7:0] alarm_led_mask;
    wire [3:0] countdown_hour_ten;
    wire [3:0] countdown_hour_unit;
    wire [3:0] countdown_min_ten;
    wire [3:0] countdown_min_unit;
    wire [3:0] countdown_sec_ten;
    wire [3:0] countdown_sec_unit;
    wire countdown_done_pulse;
    wire time_sec_inc_pulse;
    wire time_sec_dec_pulse;
    wire time_hour_inc_pulse;
    wire time_hour_dec_pulse;
    wire time_min_inc_pulse;
    wire time_min_dec_pulse;
    wire alarm_hour_inc_pulse;
    wire alarm_hour_dec_pulse;
    wire alarm_min_inc_pulse;
    wire alarm_min_dec_pulse;
    wire alarm_sec_inc_pulse;
    wire alarm_sec_dec_pulse;
    wire alarm_enable_inc_pulse;
    wire alarm_enable_dec_pulse;
    wire alarm_enable_toggle_pulse;
    wire alarm_slot_inc_pulse;
    wire alarm_slot_dec_pulse;
    wire alarm_event_ack_pulse;
    wire alarm_snooze_set_pulse;
    wire [3:0] alarm_snooze_add_min;
    wire [2:0] alarm_snooze_slot_index;
    wire countdown_hour_inc_pulse;
    wire countdown_hour_dec_pulse;
    wire countdown_min_inc_pulse;
    wire countdown_min_dec_pulse;
    wire countdown_sec_inc_pulse;
    wire countdown_sec_dec_pulse;
    wire countdown_start_pulse;
    wire countdown_stop_pulse;
    wire schedule_slot_inc_pulse;
    wire schedule_slot_dec_pulse;
    wire schedule_enable_inc_pulse;
    wire schedule_enable_dec_pulse;
    wire schedule_enable_toggle_pulse;
    wire schedule_hour_inc_pulse;
    wire schedule_hour_dec_pulse;
    wire schedule_min_inc_pulse;
    wire schedule_min_dec_pulse;
    wire schedule_sec_inc_pulse;
    wire schedule_sec_dec_pulse;
    wire schedule_type_inc_pulse;
    wire schedule_type_dec_pulse;
    wire schedule_type_page;
    wire schedule_event_ack_pulse;
    wire selected_schedule_enable;
    wire [2:0] selected_schedule_type;
    wire [2:0] schedule_selected_slot;
    wire [7:0] schedule_slot_enable_mask;
    wire [7:0] schedule_slot_selected_mask;
    wire [7:0] schedule_pending_mask;
    wire [7:0] schedule_led_mask;
    wire [3:0] schedule_hour_ten;
    wire [3:0] schedule_hour_unit;
    wire [3:0] schedule_min_ten;
    wire [3:0] schedule_min_unit;
    wire [3:0] schedule_sec_ten;
    wire [3:0] schedule_sec_unit;
    wire [3:0] next_schedule_hour_ten;
    wire [3:0] next_schedule_hour_unit;
    wire [3:0] next_schedule_min_ten;
    wire [3:0] next_schedule_min_unit;
    wire [3:0] next_schedule_sec_ten;
    wire [3:0] next_schedule_sec_unit;
    wire next_schedule_valid_raw;
    wire [2:0] next_schedule_slot_raw;
    wire schedule_event_valid;
    wire [2:0] schedule_event_slot;
    wire date_month_inc_pulse;
    wire date_month_dec_pulse;
    wire date_day_inc_pulse;
    wire date_day_dec_pulse;
    wire date_weekday_inc_pulse;
    wire date_weekday_dec_pulse;
    wire time_auto_tick_en;
    wire day_tick_pulse;
    wire hour_format_toggle_pulse;
    wire hour_format_12h;
    wire time_is_pm;
    wire time_is_midnight_or_noon;
    reg next_alarm_valid_public_reg;
    reg [3:0] next_alarm_hour_ten_public_reg;
    reg [3:0] next_alarm_hour_unit_public_reg;
    reg [3:0] next_alarm_min_ten_public_reg;
    reg [3:0] next_alarm_min_unit_public_reg;
    reg next_schedule_valid_public_reg;
    reg [2:0] next_schedule_slot_public_reg;
    reg [3:0] next_schedule_hour_ten_public_reg;
    reg [3:0] next_schedule_hour_unit_public_reg;
    reg [3:0] next_schedule_min_ten_public_reg;
    reg [3:0] next_schedule_min_unit_public_reg;

    clk_ring u_clk_div(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .tick_1h(tick_1h)
    );

    ui_ctrl u_ui_ctrl(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_center(btn_center),
        .sw(sw),
        .interaction_lock(notify_active),
        .mode_nav_lock(mode_comm & comm_reply_mode),
        .mode_state(mode_state),
        .setting_active(setting_active),
        .field_index(field_index),
        .value_inc_pulse(value_inc_pulse),
        .value_dec_pulse(value_dec_pulse),
        .confirm_pulse(confirm_pulse),
        .blink_hide(blink_hide),
        .btn_left_pulse(btn_left_pulse_raw),
        .btn_right_pulse(btn_right_pulse_raw),
        .btn_up_pulse(btn_up_pulse_raw),
        .btn_down_pulse(btn_down_pulse_raw),
        .btn_center_pulse(btn_center_pulse_raw)
    );

    assign mode_time_set     = (mode_state == 3'b001);
    assign mode_alarm        = (mode_state == 3'b010);
    assign mode_hour_format  = (mode_state == 3'b011);
    assign mode_countdown    = (mode_state == 3'b100);
    assign mode_schedule     = (mode_state == 3'b101);
    assign mode_comm         = (mode_state == 3'b110);
    assign dp_indicator   = mode_alarm
                            ? ((setting_active && (field_index == 3'd4) && blink_hide)
                               ? 1'b0 : alarm_enable)
                            : alarm_match;
    assign time_sec_inc_pulse          = mode_time_set  & setting_active & (field_index == 3'd2) & value_inc_pulse;
    assign time_sec_dec_pulse          = mode_time_set  & setting_active & (field_index == 3'd2) & value_dec_pulse;
    assign time_hour_inc_pulse         = mode_time_set  & setting_active & (field_index == 3'd0) & value_inc_pulse;
    assign time_hour_dec_pulse         = mode_time_set  & setting_active & (field_index == 3'd0) & value_dec_pulse;
    assign time_min_inc_pulse          = mode_time_set  & setting_active & (field_index == 3'd1) & value_inc_pulse;
    assign time_min_dec_pulse          = mode_time_set  & setting_active & (field_index == 3'd1) & value_dec_pulse;
    assign alarm_hour_inc_pulse        = mode_alarm     & setting_active & (field_index == 3'd1) & value_inc_pulse;
    assign alarm_hour_dec_pulse        = mode_alarm     & setting_active & (field_index == 3'd1) & value_dec_pulse;
    assign alarm_min_inc_pulse         = mode_alarm     & setting_active & (field_index == 3'd2) & value_inc_pulse;
    assign alarm_min_dec_pulse         = mode_alarm     & setting_active & (field_index == 3'd2) & value_dec_pulse;
    assign alarm_sec_inc_pulse         = mode_alarm     & setting_active & (field_index == 3'd3) & value_inc_pulse;
    assign alarm_sec_dec_pulse         = mode_alarm     & setting_active & (field_index == 3'd3) & value_dec_pulse;
    assign alarm_enable_inc_pulse      = mode_alarm     & setting_active & (field_index == 3'd4) & value_inc_pulse;
    assign alarm_enable_dec_pulse      = mode_alarm     & setting_active & (field_index == 3'd4) & value_dec_pulse;
    assign alarm_enable_toggle_pulse   = mode_alarm     & setting_active & (field_index == 3'd4) & confirm_pulse;
    assign alarm_slot_inc_pulse        = mode_alarm     & setting_active & (field_index == 3'd0) & value_inc_pulse;
    assign alarm_slot_dec_pulse        = mode_alarm     & setting_active & (field_index == 3'd0) & value_dec_pulse;
    assign countdown_hour_inc_pulse    = mode_countdown & setting_active & (field_index == 3'd0) & value_inc_pulse;
    assign countdown_hour_dec_pulse    = mode_countdown & setting_active & (field_index == 3'd0) & value_dec_pulse;
    assign countdown_min_inc_pulse     = mode_countdown & setting_active & (field_index == 3'd1) & value_inc_pulse;
    assign countdown_min_dec_pulse     = mode_countdown & setting_active & (field_index == 3'd1) & value_dec_pulse;
    assign countdown_sec_inc_pulse     = mode_countdown & setting_active & (field_index == 3'd2) & value_inc_pulse;
    assign countdown_sec_dec_pulse     = mode_countdown & setting_active & (field_index == 3'd2) & value_dec_pulse;
    assign countdown_start_pulse       = mode_countdown & ~setting_active & value_inc_pulse;
    assign countdown_stop_pulse        = mode_countdown & ~setting_active & value_dec_pulse;
    assign schedule_type_page          = mode_schedule & sw[15];
    assign schedule_slot_inc_pulse     = 1'b0;
    assign schedule_slot_dec_pulse     = 1'b0;
    assign schedule_hour_inc_pulse     = mode_schedule & setting_active & ~schedule_type_page & (field_index == 3'd0) & value_inc_pulse;
    assign schedule_hour_dec_pulse     = mode_schedule & setting_active & ~schedule_type_page & (field_index == 3'd0) & value_dec_pulse;
    assign schedule_min_inc_pulse      = mode_schedule & setting_active & ~schedule_type_page & (field_index == 3'd1) & value_inc_pulse;
    assign schedule_min_dec_pulse      = mode_schedule & setting_active & ~schedule_type_page & (field_index == 3'd1) & value_dec_pulse;
    assign schedule_sec_inc_pulse      = mode_schedule & setting_active & ~schedule_type_page & (field_index == 3'd2) & value_inc_pulse;
    assign schedule_sec_dec_pulse      = mode_schedule & setting_active & ~schedule_type_page & (field_index == 3'd2) & value_dec_pulse;
    assign schedule_type_inc_pulse     = mode_schedule & setting_active & schedule_type_page & ~notify_active &
                                          (value_inc_pulse | btn_right_pulse_raw);
    assign schedule_type_dec_pulse     = mode_schedule & setting_active & schedule_type_page & ~notify_active &
                                          (value_dec_pulse | btn_left_pulse_raw);
    assign schedule_enable_inc_pulse   = 1'b0;
    assign schedule_enable_dec_pulse   = 1'b0;
    assign schedule_enable_toggle_pulse = mode_schedule & setting_active & confirm_pulse;
    assign date_month_inc_pulse        = (mode_state == 3'b000) & setting_active & (field_index == 3'd0) & value_inc_pulse;
    assign date_month_dec_pulse        = (mode_state == 3'b000) & setting_active & (field_index == 3'd0) & value_dec_pulse;
    assign date_day_inc_pulse          = (mode_state == 3'b000) & setting_active & (field_index == 3'd1) & value_inc_pulse;
    assign date_day_dec_pulse          = (mode_state == 3'b000) & setting_active & (field_index == 3'd1) & value_dec_pulse;
    assign date_weekday_inc_pulse      = (mode_state == 3'b000) & setting_active & (field_index == 3'd2) & value_inc_pulse;
    assign date_weekday_dec_pulse      = (mode_state == 3'b000) & setting_active & (field_index == 3'd2) & value_dec_pulse;
    assign hour_format_toggle_pulse    = mode_hour_format & setting_active &
                                          (value_inc_pulse | value_dec_pulse | confirm_pulse);
    assign time_auto_tick_en           = tick_1h & ~(mode_time_set & setting_active) &
                                          ~time_sec_inc_pulse & ~time_sec_dec_pulse &
                                          ~time_hour_inc_pulse & ~time_hour_dec_pulse &
                                          ~time_min_inc_pulse & ~time_min_dec_pulse;
    assign day_tick_pulse              = time_auto_tick_en &
                                          (hour_t_time == 4'd2) & (hour_u_time == 4'd3) &
                                          (min_t_time == 4'd5) & (min_u_time == 4'd9) &
                                          (sec_t_time == 4'd5) & (sec_u_time == 4'd9);
    assign digit_code_bus              = {mode_disp_code, status_disp_code,
                                          hour_t_disp, hour_u_disp,
                                          min_t_disp, min_u_disp,
                                          sec_t_disp, sec_u_disp};
    assign dp_mask                     = mode_comm ? 8'b0000_0000 :
                                         mode_schedule
                                          ? {1'b0,
                                             (setting_active ? selected_schedule_enable : next_schedule_valid_raw),
                                             6'b000000}
                                          : {7'b0000000, dp_indicator};
    assign date_month_ten_bcd          = date_month_ten;
    assign date_month_unit_bcd         = date_month_unit;
    assign date_day_ten_bcd            = date_day_ten;
    assign date_day_unit_bcd           = date_day_unit;
    assign next_alarm_valid            = next_alarm_valid_public_reg;
    assign next_alarm_hour_ten_bcd     = next_alarm_hour_ten_public_reg;
    assign next_alarm_hour_unit_bcd    = next_alarm_hour_unit_public_reg;
    assign next_alarm_min_ten_bcd      = next_alarm_min_ten_public_reg;
    assign next_alarm_min_unit_bcd     = next_alarm_min_unit_public_reg;
    assign next_schedule_valid         = next_schedule_valid_public_reg;
    assign next_schedule_slot          = next_schedule_slot_public_reg;
    assign next_schedule_hour_ten_bcd  = next_schedule_hour_ten_public_reg;
    assign next_schedule_hour_unit_bcd = next_schedule_hour_unit_public_reg;
    assign next_schedule_min_ten_bcd   = next_schedule_min_ten_public_reg;
    assign next_schedule_min_unit_bcd  = next_schedule_min_unit_public_reg;
    assign countdown_hour_ten_bcd      = countdown_hour_ten;
    assign countdown_hour_unit_bcd     = countdown_hour_unit;
    assign countdown_min_ten_bcd       = countdown_min_ten;
    assign countdown_min_unit_bcd      = countdown_min_unit;
    assign countdown_sec_ten_bcd       = countdown_sec_ten;
    assign countdown_sec_unit_bcd      = countdown_sec_unit;
    assign hour_format_12h_out         = hour_format_12h;
    assign alarm_led_mask              = mode_alarm
                                          ? (blink_hide
                                             ? (alarm_slot_enable_mask & ~alarm_slot_selected_mask)
                                             : (alarm_slot_enable_mask | alarm_slot_selected_mask))
                                          : 8'b0000_0000;
    assign schedule_led_mask           = mode_schedule
                                          ? (blink_hide
                                             ? (schedule_slot_enable_mask & ~schedule_slot_selected_mask)
                                             : (schedule_slot_enable_mask | schedule_slot_selected_mask))
                                          : 8'b0000_0000;
    assign slot_led_mask               = mode_alarm ? alarm_led_mask :
                                          mode_schedule ? schedule_led_mask :
                                          8'b0000_0000;

    comm_ctrl u_comm_ctrl(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .mode_comm(mode_comm & ~notify_active),
        .mode_state(mode_state),
        .sw(sw),
        .btn_up_pulse(btn_up_pulse_raw),
        .btn_down_pulse(btn_down_pulse_raw),
        .btn_center_pulse(btn_center_pulse_raw),
        .btn_right_pulse(btn_right_pulse_raw),
        .uart_rx(uart_rx),
        .countdown_run(countdown_run),
        .cur_year_thousand_bcd(date_year_thousand),
        .cur_year_hundred_bcd(date_year_hundred),
        .cur_year_ten_bcd(date_year_ten),
        .cur_year_unit_bcd(date_year_unit),
        .cur_month_ten_bcd(date_month_ten),
        .cur_month_unit_bcd(date_month_unit),
        .cur_day_ten_bcd(date_day_ten),
        .cur_day_unit_bcd(date_day_unit),
        .cur_weekday(date_weekday),
        .cur_hour_ten_bcd(hour_t_time),
        .cur_hour_unit_bcd(hour_u_time),
        .cur_min_ten_bcd(min_t_time),
        .cur_min_unit_bcd(min_u_time),
        .cur_sec_ten_bcd(sec_t_time),
        .cur_sec_unit_bcd(sec_u_time),
        .alarm_read_slot(pc_alarm_read_slot),
        .alarm_read_hour_ten_bcd(pc_alarm_read_hour_ten_bcd),
        .alarm_read_hour_unit_bcd(pc_alarm_read_hour_unit_bcd),
        .alarm_read_min_ten_bcd(pc_alarm_read_min_ten_bcd),
        .alarm_read_min_unit_bcd(pc_alarm_read_min_unit_bcd),
        .alarm_read_sec_ten_bcd(pc_alarm_read_sec_ten_bcd),
        .alarm_read_sec_unit_bcd(pc_alarm_read_sec_unit_bcd),
        .alarm_read_enable(pc_alarm_read_enable),
        .sched_read_slot(pc_sched_read_slot),
        .sched_read_hour_ten_bcd(pc_sched_read_hour_ten_bcd),
        .sched_read_hour_unit_bcd(pc_sched_read_hour_unit_bcd),
        .sched_read_min_ten_bcd(pc_sched_read_min_ten_bcd),
        .sched_read_min_unit_bcd(pc_sched_read_min_unit_bcd),
        .sched_read_sec_ten_bcd(pc_sched_read_sec_ten_bcd),
        .sched_read_sec_unit_bcd(pc_sched_read_sec_unit_bcd),
        .sched_read_type(pc_sched_read_type),
        .sched_read_enable(pc_sched_read_enable),
        .count_hour_ten_bcd(countdown_hour_ten),
        .count_hour_unit_bcd(countdown_hour_unit),
        .count_min_ten_bcd(countdown_min_ten),
        .count_min_unit_bcd(countdown_min_unit),
        .count_sec_ten_bcd(countdown_sec_ten),
        .count_sec_unit_bcd(countdown_sec_unit),
        .uart_tx(uart_tx),
        .pc_time_load_valid(pc_time_load_valid),
        .pc_hour_ten_bcd(pc_hour_ten_bcd),
        .pc_hour_unit_bcd(pc_hour_unit_bcd),
        .pc_min_ten_bcd(pc_min_ten_bcd),
        .pc_min_unit_bcd(pc_min_unit_bcd),
        .pc_sec_ten_bcd(pc_sec_ten_bcd),
        .pc_sec_unit_bcd(pc_sec_unit_bcd),
        .pc_date_load_valid(pc_date_load_valid),
        .pc_year_thousand_bcd(pc_year_thousand_bcd),
        .pc_year_hundred_bcd(pc_year_hundred_bcd),
        .pc_year_ten_bcd(pc_year_ten_bcd),
        .pc_year_unit_bcd(pc_year_unit_bcd),
        .pc_month_ten_bcd(pc_month_ten_bcd),
        .pc_month_unit_bcd(pc_month_unit_bcd),
        .pc_day_ten_bcd(pc_day_ten_bcd),
        .pc_day_unit_bcd(pc_day_unit_bcd),
        .pc_weekday(pc_weekday),
        .pc_alarm_write_valid(pc_alarm_write_valid),
        .pc_alarm_write_slot(pc_alarm_write_slot),
        .pc_alarm_write_hour_ten_bcd(pc_alarm_write_hour_ten_bcd),
        .pc_alarm_write_hour_unit_bcd(pc_alarm_write_hour_unit_bcd),
        .pc_alarm_write_min_ten_bcd(pc_alarm_write_min_ten_bcd),
        .pc_alarm_write_min_unit_bcd(pc_alarm_write_min_unit_bcd),
        .pc_alarm_write_sec_ten_bcd(pc_alarm_write_sec_ten_bcd),
        .pc_alarm_write_sec_unit_bcd(pc_alarm_write_sec_unit_bcd),
        .pc_alarm_write_enable(pc_alarm_write_enable),
        .pc_alarm_read_slot(pc_alarm_read_slot),
        .pc_sched_write_valid(pc_sched_write_valid),
        .pc_sched_write_slot(pc_sched_write_slot),
        .pc_sched_write_hour_ten_bcd(pc_sched_write_hour_ten_bcd),
        .pc_sched_write_hour_unit_bcd(pc_sched_write_hour_unit_bcd),
        .pc_sched_write_min_ten_bcd(pc_sched_write_min_ten_bcd),
        .pc_sched_write_min_unit_bcd(pc_sched_write_min_unit_bcd),
        .pc_sched_write_sec_ten_bcd(pc_sched_write_sec_ten_bcd),
        .pc_sched_write_sec_unit_bcd(pc_sched_write_sec_unit_bcd),
        .pc_sched_write_type(pc_sched_write_type),
        .pc_sched_write_enable(pc_sched_write_enable),
        .pc_sched_read_slot(pc_sched_read_slot),
        .pc_count_load_valid(pc_count_load_valid),
        .pc_count_hour_ten_bcd(pc_count_hour_ten_bcd),
        .pc_count_hour_unit_bcd(pc_count_hour_unit_bcd),
        .pc_count_min_ten_bcd(pc_count_min_ten_bcd),
        .pc_count_min_unit_bcd(pc_count_min_unit_bcd),
        .pc_count_sec_ten_bcd(pc_count_sec_ten_bcd),
        .pc_count_sec_unit_bcd(pc_count_sec_unit_bcd),
        .pc_count_start_pulse(pc_count_start_pulse),
        .pc_count_stop_pulse(pc_count_stop_pulse),
        .comm_status(comm_status),
        .comm_reply_mode(comm_reply_mode),
        .comm_reply_index(comm_reply_index),
        .comm_reply_text_ascii(),
        .comm_reply_text_len(),
        .comm_selected_slot(comm_selected_slot),
        .comm_message_valid(comm_message_valid),
        .comm_message_unread(),
        .comm_message_count(),
        .comm_unread_count(),
        .comm_scroll_line(comm_scroll_line),
        .comm_timestamp_ascii(comm_timestamp_ascii),
        .comm_message_len(comm_message_len),
        .comm_message_window_ascii(comm_message_window_ascii)
    );

    // Register public next-event outputs to keep OLED render timing local.
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            next_alarm_valid_public_reg <= 1'b0;
            next_alarm_hour_ten_public_reg <= 4'd0;
            next_alarm_hour_unit_public_reg <= 4'd0;
            next_alarm_min_ten_public_reg <= 4'd0;
            next_alarm_min_unit_public_reg <= 4'd0;
            next_schedule_valid_public_reg <= 1'b0;
            next_schedule_slot_public_reg <= 3'd0;
            next_schedule_hour_ten_public_reg <= 4'd0;
            next_schedule_hour_unit_public_reg <= 4'd0;
            next_schedule_min_ten_public_reg <= 4'd0;
            next_schedule_min_unit_public_reg <= 4'd0;
        end else begin
            next_alarm_valid_public_reg <= next_alarm_valid_raw;
            next_alarm_hour_ten_public_reg <= next_alarm_hour_ten;
            next_alarm_hour_unit_public_reg <= next_alarm_hour_unit;
            next_alarm_min_ten_public_reg <= next_alarm_min_ten;
            next_alarm_min_unit_public_reg <= next_alarm_min_unit;
            next_schedule_valid_public_reg <= next_schedule_valid_raw;
            next_schedule_slot_public_reg <= next_schedule_slot_raw;
            next_schedule_hour_ten_public_reg <= next_schedule_hour_ten;
            next_schedule_hour_unit_public_reg <= next_schedule_hour_unit;
            next_schedule_min_ten_public_reg <= next_schedule_min_ten;
            next_schedule_min_unit_public_reg <= next_schedule_min_unit;
        end
    end

    time_core u_time_core(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .tick_1h(tick_1h),
        .freeze_run(mode_time_set & setting_active),
        .add_sec_pulse(time_sec_inc_pulse),
        .dec_sec_pulse(time_sec_dec_pulse),
        .add_hour_pulse(time_hour_inc_pulse),
        .dec_hour_pulse(time_hour_dec_pulse),
        .add_min_pulse(time_min_inc_pulse),
        .dec_min_pulse(time_min_dec_pulse),
        .pc_time_load_valid(pc_time_load_valid),
        .pc_hour_ten_bcd(pc_hour_ten_bcd),
        .pc_hour_unit_bcd(pc_hour_unit_bcd),
        .pc_min_ten_bcd(pc_min_ten_bcd),
        .pc_min_unit_bcd(pc_min_unit_bcd),
        .pc_sec_ten_bcd(pc_sec_ten_bcd),
        .pc_sec_unit_bcd(pc_sec_unit_bcd),
        .sec_unit_bcd(sec_u_time),
        .sec_ten_bcd(sec_t_time),
        .min_unit_bcd(min_u_time),
        .min_ten_bcd(min_t_time),
        .hour_unit_bcd(hour_u_time),
        .hour_ten_bcd(hour_t_time)
    );

    date_core u_date_core(
        .clk(clk),
        .rst(rst),
        .day_tick_pulse(day_tick_pulse),
        .month_inc_pulse(date_month_inc_pulse),
        .month_dec_pulse(date_month_dec_pulse),
        .day_inc_pulse(date_day_inc_pulse),
        .day_dec_pulse(date_day_dec_pulse),
        .weekday_inc_pulse(date_weekday_inc_pulse),
        .weekday_dec_pulse(date_weekday_dec_pulse),
        .pc_date_load_valid(pc_date_load_valid),
        .pc_year_thousand_bcd(pc_year_thousand_bcd),
        .pc_year_hundred_bcd(pc_year_hundred_bcd),
        .pc_year_ten_bcd(pc_year_ten_bcd),
        .pc_year_unit_bcd(pc_year_unit_bcd),
        .pc_month_ten_bcd(pc_month_ten_bcd),
        .pc_month_unit_bcd(pc_month_unit_bcd),
        .pc_day_ten_bcd(pc_day_ten_bcd),
        .pc_day_unit_bcd(pc_day_unit_bcd),
        .pc_weekday(pc_weekday),
        .year_thousand_bcd(date_year_thousand),
        .year_hundred_bcd(date_year_hundred),
        .year_ten_bcd(date_year_ten),
        .year_unit_bcd(date_year_unit),
        .month_ten_bcd(date_month_ten),
        .month_unit_bcd(date_month_unit),
        .day_ten_bcd(date_day_ten),
        .day_unit_bcd(date_day_unit),
        .weekday(date_weekday)
    );

    hour_format_ctrl u_hour_format_ctrl(
        .clk(clk),
        .rst(rst),
        .toggle_pulse(hour_format_toggle_pulse),
        .inc_format_pulse(1'b0),
        .dec_format_pulse(1'b0),
        .hour_format_12h(hour_format_12h)
    );

    hour_format_display u_hour_format_display_time(
        .hour_ten_24(hour_t_time),
        .hour_unit_24(hour_u_time),
        .hour_format_12h(hour_format_12h),
        .display_hour_ten(disp_hour_t_time),
        .display_hour_unit(disp_hour_u_time),
        .is_pm(time_is_pm),
        .is_midnight_or_noon(time_is_midnight_or_noon)
    );

    alarm_ctrl u_alarm_ctrl(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .alarm_slot_inc_pulse(alarm_slot_inc_pulse),
        .alarm_slot_dec_pulse(alarm_slot_dec_pulse),
        .alarm_hour_inc_pulse(alarm_hour_inc_pulse),
        .alarm_hour_dec_pulse(alarm_hour_dec_pulse),
        .alarm_min_inc_pulse(alarm_min_inc_pulse),
        .alarm_min_dec_pulse(alarm_min_dec_pulse),
        .alarm_sec_inc_pulse(alarm_sec_inc_pulse),
        .alarm_sec_dec_pulse(alarm_sec_dec_pulse),
        .alarm_enable_inc_pulse(alarm_enable_inc_pulse),
        .alarm_enable_dec_pulse(alarm_enable_dec_pulse),
        .alarm_enable_toggle_pulse(alarm_enable_toggle_pulse),
        .alarm_event_ack_pulse(alarm_event_ack_pulse),
        .snooze_1_pulse(1'b0),
        .snooze_3_pulse(1'b0),
        .snooze_5_pulse(1'b0),
        .snooze_10_pulse(1'b0),
        .snooze_set_pulse(alarm_snooze_set_pulse),
        .snooze_add_min(alarm_snooze_add_min),
        .snooze_slot_index(alarm_snooze_slot_index),
        .cur_sec_ten_bcd(sec_t_time),
        .cur_sec_unit_bcd(sec_u_time),
        .cur_min_ten_bcd(min_t_time),
        .cur_min_unit_bcd(min_u_time),
        .cur_hour_unit_bcd(hour_u_time),
        .cur_hour_ten_bcd(hour_t_time),
        .pc_alarm_write_valid(pc_alarm_write_valid),
        .pc_alarm_write_slot(pc_alarm_write_slot),
        .pc_alarm_write_hour_ten_bcd(pc_alarm_write_hour_ten_bcd),
        .pc_alarm_write_hour_unit_bcd(pc_alarm_write_hour_unit_bcd),
        .pc_alarm_write_min_ten_bcd(pc_alarm_write_min_ten_bcd),
        .pc_alarm_write_min_unit_bcd(pc_alarm_write_min_unit_bcd),
        .pc_alarm_write_sec_ten_bcd(pc_alarm_write_sec_ten_bcd),
        .pc_alarm_write_sec_unit_bcd(pc_alarm_write_sec_unit_bcd),
        .pc_alarm_write_enable(pc_alarm_write_enable),
        .pc_alarm_read_slot(pc_alarm_read_slot),
        .alarm_sec_ten_bcd(alarm_sec_ten),
        .alarm_sec_unit_bcd(alarm_sec_unit),
        .alarm_hour_ten_bcd(alarm_hour_ten),
        .alarm_hour_unit_bcd(alarm_hour_unit),
        .alarm_min_ten_bcd(alarm_min_ten),
        .alarm_min_unit_bcd(alarm_min_unit),
        .alarm_enable(alarm_enable),
        .pc_alarm_read_hour_ten_bcd(pc_alarm_read_hour_ten_bcd),
        .pc_alarm_read_hour_unit_bcd(pc_alarm_read_hour_unit_bcd),
        .pc_alarm_read_min_ten_bcd(pc_alarm_read_min_ten_bcd),
        .pc_alarm_read_min_unit_bcd(pc_alarm_read_min_unit_bcd),
        .pc_alarm_read_sec_ten_bcd(pc_alarm_read_sec_ten_bcd),
        .pc_alarm_read_sec_unit_bcd(pc_alarm_read_sec_unit_bcd),
        .pc_alarm_read_enable(pc_alarm_read_enable),
        .alarm_match(alarm_match),
        .alarm_beep(alarm_beep_legacy),
        .alarm_selected_slot(alarm_selected_slot),
        .alarm_slot_enable_mask(alarm_slot_enable_mask),
        .alarm_slot_selected_mask(alarm_slot_selected_mask),
        .alarm_pending_mask(alarm_pending_mask),
        .next_alarm_valid(next_alarm_valid_raw),
        .next_alarm_slot(next_alarm_slot),
        .next_alarm_sec_ten_bcd(next_alarm_sec_ten),
        .next_alarm_sec_unit_bcd(next_alarm_sec_unit),
        .next_alarm_min_ten_bcd(next_alarm_min_ten),
        .next_alarm_min_unit_bcd(next_alarm_min_unit),
        .next_alarm_hour_ten_bcd(next_alarm_hour_ten),
        .next_alarm_hour_unit_bcd(next_alarm_hour_unit),
        .alarm_event_valid(alarm_event_valid),
        .alarm_event_slot(alarm_event_slot)
    );

    countdown_ctrl u_countdown_ctrl(
        .clk(clk),
        .rst(rst),
        .tick_1h(tick_1h),
        .hour_inc_pulse(countdown_hour_inc_pulse),
        .hour_dec_pulse(countdown_hour_dec_pulse),
        .min_inc_pulse(countdown_min_inc_pulse),
        .min_dec_pulse(countdown_min_dec_pulse),
        .sec_inc_pulse(countdown_sec_inc_pulse),
        .sec_dec_pulse(countdown_sec_dec_pulse),
        .countdown_start_pulse(countdown_start_pulse),
        .countdown_stop_pulse(countdown_stop_pulse),
        .pc_count_load_valid(pc_count_load_valid),
        .pc_count_hour_ten_bcd(pc_count_hour_ten_bcd),
        .pc_count_hour_unit_bcd(pc_count_hour_unit_bcd),
        .pc_count_min_ten_bcd(pc_count_min_ten_bcd),
        .pc_count_min_unit_bcd(pc_count_min_unit_bcd),
        .pc_count_sec_ten_bcd(pc_count_sec_ten_bcd),
        .pc_count_sec_unit_bcd(pc_count_sec_unit_bcd),
        .pc_count_start_pulse(pc_count_start_pulse),
        .pc_count_stop_pulse(pc_count_stop_pulse),
        .countdown_run(countdown_run),
        .countdown_done_pulse(countdown_done_pulse),
        .hour_ten_bcd(countdown_hour_ten),
        .hour_unit_bcd(countdown_hour_unit),
        .min_ten_bcd(countdown_min_ten),
        .min_unit_bcd(countdown_min_unit),
        .sec_ten_bcd(countdown_sec_ten),
        .sec_unit_bcd(countdown_sec_unit)
    );

    schedule_ctrl u_schedule_ctrl(
        .clk(clk),
        .rst(rst),
        .schedule_slot_inc_pulse(schedule_slot_inc_pulse),
        .schedule_slot_dec_pulse(schedule_slot_dec_pulse),
        .schedule_slot_switches(mode_schedule ? sw[7:0] : 8'd0),
        .schedule_hour_inc_pulse(schedule_hour_inc_pulse),
        .schedule_hour_dec_pulse(schedule_hour_dec_pulse),
        .schedule_min_inc_pulse(schedule_min_inc_pulse),
        .schedule_min_dec_pulse(schedule_min_dec_pulse),
        .schedule_sec_inc_pulse(schedule_sec_inc_pulse),
        .schedule_sec_dec_pulse(schedule_sec_dec_pulse),
        .schedule_type_inc_pulse(schedule_type_inc_pulse),
        .schedule_type_dec_pulse(schedule_type_dec_pulse),
        .schedule_enable_inc_pulse(schedule_enable_inc_pulse),
        .schedule_enable_dec_pulse(schedule_enable_dec_pulse),
        .schedule_enable_toggle_pulse(schedule_enable_toggle_pulse),
        .schedule_event_ack_pulse(schedule_event_ack_pulse),
        .cur_sec_ten_bcd(sec_t_time),
        .cur_sec_unit_bcd(sec_u_time),
        .cur_min_ten_bcd(min_t_time),
        .cur_min_unit_bcd(min_u_time),
        .cur_hour_ten_bcd(hour_t_time),
        .cur_hour_unit_bcd(hour_u_time),
        .pc_sched_write_valid(pc_sched_write_valid),
        .pc_sched_write_slot(pc_sched_write_slot),
        .pc_sched_write_hour_ten_bcd(pc_sched_write_hour_ten_bcd),
        .pc_sched_write_hour_unit_bcd(pc_sched_write_hour_unit_bcd),
        .pc_sched_write_min_ten_bcd(pc_sched_write_min_ten_bcd),
        .pc_sched_write_min_unit_bcd(pc_sched_write_min_unit_bcd),
        .pc_sched_write_sec_ten_bcd(pc_sched_write_sec_ten_bcd),
        .pc_sched_write_sec_unit_bcd(pc_sched_write_sec_unit_bcd),
        .pc_sched_write_type(pc_sched_write_type),
        .pc_sched_write_enable(pc_sched_write_enable),
        .pc_sched_read_slot(pc_sched_read_slot),
        .schedule_sec_ten_bcd(schedule_sec_ten),
        .schedule_sec_unit_bcd(schedule_sec_unit),
        .schedule_min_ten_bcd(schedule_min_ten),
        .schedule_min_unit_bcd(schedule_min_unit),
        .schedule_hour_ten_bcd(schedule_hour_ten),
        .schedule_hour_unit_bcd(schedule_hour_unit),
        .selected_schedule_enable(selected_schedule_enable),
        .selected_schedule_type(selected_schedule_type),
        .pc_sched_read_hour_ten_bcd(pc_sched_read_hour_ten_bcd),
        .pc_sched_read_hour_unit_bcd(pc_sched_read_hour_unit_bcd),
        .pc_sched_read_min_ten_bcd(pc_sched_read_min_ten_bcd),
        .pc_sched_read_min_unit_bcd(pc_sched_read_min_unit_bcd),
        .pc_sched_read_sec_ten_bcd(pc_sched_read_sec_ten_bcd),
        .pc_sched_read_sec_unit_bcd(pc_sched_read_sec_unit_bcd),
        .pc_sched_read_type(pc_sched_read_type),
        .pc_sched_read_enable(pc_sched_read_enable),
        .schedule_selected_slot(schedule_selected_slot),
        .schedule_slot_enable_mask(schedule_slot_enable_mask),
        .schedule_slot_selected_mask(schedule_slot_selected_mask),
        .schedule_pending_mask(schedule_pending_mask),
        .next_schedule_valid(next_schedule_valid_raw),
        .next_schedule_slot(next_schedule_slot_raw),
        .next_schedule_sec_ten_bcd(next_schedule_sec_ten),
        .next_schedule_sec_unit_bcd(next_schedule_sec_unit),
        .next_schedule_min_ten_bcd(next_schedule_min_ten),
        .next_schedule_min_unit_bcd(next_schedule_min_unit),
        .next_schedule_hour_ten_bcd(next_schedule_hour_ten),
        .next_schedule_hour_unit_bcd(next_schedule_hour_unit),
        .schedule_event_valid(schedule_event_valid),
        .schedule_event_slot(schedule_event_slot)
    );

    notification_ctrl u_notification_ctrl(
        .clk(clk),
        .rst(rst),
        .tick_1k(tick_1k),
        .tick_1h(tick_1h),
        .btn_left_pulse(btn_left_pulse_raw),
        .btn_right_pulse(btn_right_pulse_raw),
        .btn_up_pulse(btn_up_pulse_raw),
        .btn_down_pulse(btn_down_pulse_raw),
        .btn_center_pulse(btn_center_pulse_raw),
        .countdown_done_pulse(countdown_done_pulse),
        .alarm_event_valid(alarm_event_valid),
        .alarm_event_slot(alarm_event_slot),
        .schedule_event_valid(schedule_event_valid),
        .schedule_event_slot(schedule_event_slot),
        .buzzer_out(buzzer_on),
        .notify_active(notify_active),
        .notify_type(notify_type),
        .notify_slot(notify_slot),
        .alarm_event_ack_pulse(alarm_event_ack_pulse),
        .alarm_snooze_set_pulse(alarm_snooze_set_pulse),
        .alarm_snooze_add_min(alarm_snooze_add_min),
        .alarm_snooze_slot_index(alarm_snooze_slot_index),
        .schedule_event_ack_pulse(schedule_event_ack_pulse)
    );

    display_ctrl u_display_ctrl(
        .mode_state(mode_state),
        .setting_active(setting_active),
        .blink_hide(blink_hide),
        .field_index(field_index),
        .comm_status(comm_status),
        .selected_alarm_enable(alarm_enable),
        .next_alarm_valid(next_alarm_valid_raw),
        .countdown_run(countdown_run),
        .hour_format_12h(hour_format_12h),
        .sec_unit_time_bcd(sec_u_time),
        .sec_ten_time_bcd(sec_t_time),
        .min_unit_time_bcd(min_u_time),
        .min_ten_time_bcd(min_t_time),
        .hour_unit_time_bcd(hour_u_time),
        .hour_ten_time_bcd(hour_t_time),
        .disp_hour_unit_time_bcd(disp_hour_u_time),
        .disp_hour_ten_time_bcd(disp_hour_t_time),
        .date_month_ten_bcd(date_month_ten),
        .date_month_unit_bcd(date_month_unit),
        .date_day_ten_bcd(date_day_ten),
        .date_day_unit_bcd(date_day_unit),
        .date_weekday(date_weekday),
        .alarm_sec_ten_bcd(alarm_sec_ten),
        .alarm_sec_unit_bcd(alarm_sec_unit),
        .alarm_min_ten_bcd(alarm_min_ten),
        .alarm_min_unit_bcd(alarm_min_unit),
        .alarm_hour_unit_bcd(alarm_hour_unit),
        .alarm_hour_ten_bcd(alarm_hour_ten),
        .next_alarm_sec_ten_bcd(next_alarm_sec_ten),
        .next_alarm_sec_unit_bcd(next_alarm_sec_unit),
        .next_alarm_min_ten_bcd(next_alarm_min_ten),
        .next_alarm_min_unit_bcd(next_alarm_min_unit),
        .next_alarm_hour_unit_bcd(next_alarm_hour_unit),
        .next_alarm_hour_ten_bcd(next_alarm_hour_ten),
        .selected_schedule_type(selected_schedule_type),
        .schedule_type_page(schedule_type_page),
        .schedule_selected_slot(schedule_selected_slot),
        .next_schedule_valid(next_schedule_valid_raw),
        .next_schedule_slot(next_schedule_slot_raw),
        .schedule_sec_ten_bcd(schedule_sec_ten),
        .schedule_sec_unit_bcd(schedule_sec_unit),
        .schedule_min_ten_bcd(schedule_min_ten),
        .schedule_min_unit_bcd(schedule_min_unit),
        .schedule_hour_unit_bcd(schedule_hour_unit),
        .schedule_hour_ten_bcd(schedule_hour_ten),
        .next_schedule_sec_ten_bcd(next_schedule_sec_ten),
        .next_schedule_sec_unit_bcd(next_schedule_sec_unit),
        .next_schedule_min_ten_bcd(next_schedule_min_ten),
        .next_schedule_min_unit_bcd(next_schedule_min_unit),
        .next_schedule_hour_unit_bcd(next_schedule_hour_unit),
        .next_schedule_hour_ten_bcd(next_schedule_hour_ten),
        .countdown_hour_ten_bcd(countdown_hour_ten),
        .countdown_hour_unit_bcd(countdown_hour_unit),
        .countdown_min_ten_bcd(countdown_min_ten),
        .countdown_min_unit_bcd(countdown_min_unit),
        .countdown_sec_ten_bcd(countdown_sec_ten),
        .countdown_sec_unit_bcd(countdown_sec_unit),
        .mode_disp_code(mode_disp_code),
        .status_disp_code(status_disp_code),
        .sec_unit_disp_bcd(sec_u_disp),
        .sec_ten_disp_bcd(sec_t_disp),
        .min_unit_disp_bcd(min_u_disp),
        .min_ten_disp_bcd(min_t_disp),
        .hour_unit_disp_bcd(hour_u_disp),
        .hour_ten_disp_bcd(hour_t_disp)
    );
endmodule
