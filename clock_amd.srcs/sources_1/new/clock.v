module clock(
    input clk,
    input tick_1k,
    input rst,
    input btn_left,
    input btn_right,
    input btn_up,
    input btn_down,
    input btn_center,
    output alarm_beep,
    output countdown_run,
    output [2:0] mode_state,
    output edit_active,
    output [7:0] sec_unit_seg,
    output [3:0] sec_ten_bcd,
    output [3:0] min_unit_bcd,
    output [3:0] min_ten_bcd,
    output [3:0] hour_unit_bcd,
    output [3:0] hour_ten_bcd
);
    wire tick_1h;
    wire [3:0] sec_u_time;
    wire [3:0] sec_t_time;
    wire [3:0] min_u_time;
    wire [3:0] min_t_time;
    wire [3:0] hour_u_time;
    wire [3:0] hour_t_time;
    wire [3:0] sec_u_disp;
    wire dp_indicator;

    wire mode_time_set;
    wire mode_alarm;
    wire mode_countdown;
    wire blink_hide;
    wire [2:0] field_index;
    wire value_inc_pulse;
    wire value_dec_pulse;
    wire [3:0] alarm_hour_ten;
    wire [3:0] alarm_hour_unit;
    wire [3:0] alarm_min_ten;
    wire [3:0] alarm_min_unit;
    wire [3:0] alarm_sec_ten;
    wire [3:0] alarm_sec_unit;
    wire alarm_enable;
    wire alarm_match;
    wire [3:0] countdown_hour_ten;
    wire [3:0] countdown_hour_unit;
    wire [3:0] countdown_min_ten;
    wire [3:0] countdown_min_unit;
    wire [3:0] countdown_sec_ten;
    wire [3:0] countdown_sec_unit;
    wire countdown_done_pulse;
    wire [6:0] sec_unit_seg_raw;
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
    wire countdown_hour_inc_pulse;
    wire countdown_hour_dec_pulse;
    wire countdown_min_inc_pulse;
    wire countdown_min_dec_pulse;
    wire countdown_sec_inc_pulse;
    wire countdown_sec_dec_pulse;
    wire countdown_start_pulse;
    wire countdown_stop_pulse;

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
        .mode_state(mode_state),
        .edit_active(edit_active),
        .field_index(field_index),
        .value_inc_pulse(value_inc_pulse),
        .value_dec_pulse(value_dec_pulse),
        .blink_hide(blink_hide)
    );

    assign mode_time_set  = (mode_state == 3'b001);
    assign mode_alarm     = (mode_state == 3'b010);
    assign mode_countdown = (mode_state == 3'b100);
    assign dp_indicator   = mode_alarm
                            ? ((edit_active && (field_index == 3'd3) && blink_hide)
                               ? 1'b0 : alarm_enable)
                            : alarm_match;
    assign time_sec_inc_pulse          = mode_time_set  & edit_active & (field_index == 3'd2) & value_inc_pulse;
    assign time_sec_dec_pulse          = mode_time_set  & edit_active & (field_index == 3'd2) & value_dec_pulse;
    assign time_hour_inc_pulse         = mode_time_set  & edit_active & (field_index == 3'd0) & value_inc_pulse;
    assign time_hour_dec_pulse         = mode_time_set  & edit_active & (field_index == 3'd0) & value_dec_pulse;
    assign time_min_inc_pulse          = mode_time_set  & edit_active & (field_index == 3'd1) & value_inc_pulse;
    assign time_min_dec_pulse          = mode_time_set  & edit_active & (field_index == 3'd1) & value_dec_pulse;
    assign alarm_hour_inc_pulse        = mode_alarm     & edit_active & (field_index == 3'd0) & value_inc_pulse;
    assign alarm_hour_dec_pulse        = mode_alarm     & edit_active & (field_index == 3'd0) & value_dec_pulse;
    assign alarm_min_inc_pulse         = mode_alarm     & edit_active & (field_index == 3'd1) & value_inc_pulse;
    assign alarm_min_dec_pulse         = mode_alarm     & edit_active & (field_index == 3'd1) & value_dec_pulse;
    assign alarm_sec_inc_pulse         = mode_alarm     & edit_active & (field_index == 3'd2) & value_inc_pulse;
    assign alarm_sec_dec_pulse         = mode_alarm     & edit_active & (field_index == 3'd2) & value_dec_pulse;
    assign alarm_enable_inc_pulse      = mode_alarm     & edit_active & (field_index == 3'd3) & value_inc_pulse;
    assign alarm_enable_dec_pulse      = mode_alarm     & edit_active & (field_index == 3'd3) & value_dec_pulse;
    assign countdown_hour_inc_pulse    = mode_countdown & edit_active & (field_index == 3'd0) & value_inc_pulse;
    assign countdown_hour_dec_pulse    = mode_countdown & edit_active & (field_index == 3'd0) & value_dec_pulse;
    assign countdown_min_inc_pulse     = mode_countdown & edit_active & (field_index == 3'd1) & value_inc_pulse;
    assign countdown_min_dec_pulse     = mode_countdown & edit_active & (field_index == 3'd1) & value_dec_pulse;
    assign countdown_sec_inc_pulse     = mode_countdown & edit_active & (field_index == 3'd2) & value_inc_pulse;
    assign countdown_sec_dec_pulse     = mode_countdown & edit_active & (field_index == 3'd2) & value_dec_pulse;
    assign countdown_start_pulse       = mode_countdown & ~edit_active & value_inc_pulse;
    assign countdown_stop_pulse        = mode_countdown & ~edit_active & value_dec_pulse;

    time_core u_time_core(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .tick_1h(tick_1h),
        .freeze_run(mode_time_set),
        .add_sec_pulse(time_sec_inc_pulse),
        .dec_sec_pulse(time_sec_dec_pulse),
        .add_hour_pulse(time_hour_inc_pulse),
        .dec_hour_pulse(time_hour_dec_pulse),
        .add_min_pulse(time_min_inc_pulse),
        .dec_min_pulse(time_min_dec_pulse),
        .sec_unit_bcd(sec_u_time),
        .sec_ten_bcd(sec_t_time),
        .min_unit_bcd(min_u_time),
        .min_ten_bcd(min_t_time),
        .hour_unit_bcd(hour_u_time),
        .hour_ten_bcd(hour_t_time)
    );

    alarm_ctrl u_alarm_ctrl(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .alarm_hour_inc_pulse(alarm_hour_inc_pulse),
        .alarm_hour_dec_pulse(alarm_hour_dec_pulse),
        .alarm_min_inc_pulse(alarm_min_inc_pulse),
        .alarm_min_dec_pulse(alarm_min_dec_pulse),
        .alarm_sec_inc_pulse(alarm_sec_inc_pulse),
        .alarm_sec_dec_pulse(alarm_sec_dec_pulse),
        .alarm_enable_inc_pulse(alarm_enable_inc_pulse),
        .alarm_enable_dec_pulse(alarm_enable_dec_pulse),
        .countdown_done_pulse(countdown_done_pulse),
        .cur_sec_ten_bcd(sec_t_time),
        .cur_sec_unit_bcd(sec_u_time),
        .cur_min_ten_bcd(min_t_time),
        .cur_min_unit_bcd(min_u_time),
        .cur_hour_unit_bcd(hour_u_time),
        .cur_hour_ten_bcd(hour_t_time),
        .alarm_sec_ten_bcd(alarm_sec_ten),
        .alarm_sec_unit_bcd(alarm_sec_unit),
        .alarm_hour_ten_bcd(alarm_hour_ten),
        .alarm_hour_unit_bcd(alarm_hour_unit),
        .alarm_min_ten_bcd(alarm_min_ten),
        .alarm_min_unit_bcd(alarm_min_unit),
        .alarm_enable(alarm_enable),
        .alarm_match(alarm_match),
        .alarm_beep(alarm_beep)
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
        .countdown_run(countdown_run),
        .countdown_done_pulse(countdown_done_pulse),
        .hour_ten_bcd(countdown_hour_ten),
        .hour_unit_bcd(countdown_hour_unit),
        .min_ten_bcd(countdown_min_ten),
        .min_unit_bcd(countdown_min_unit),
        .sec_ten_bcd(countdown_sec_ten),
        .sec_unit_bcd(countdown_sec_unit)
    );

    display_ctrl u_display_ctrl(
        .mode_state(mode_state),
        .edit_active(edit_active),
        .blink_hide(blink_hide),
        .field_index(field_index),
        .sec_unit_time_bcd(sec_u_time),
        .sec_ten_time_bcd(sec_t_time),
        .min_unit_time_bcd(min_u_time),
        .min_ten_time_bcd(min_t_time),
        .hour_unit_time_bcd(hour_u_time),
        .hour_ten_time_bcd(hour_t_time),
        .alarm_sec_ten_bcd(alarm_sec_ten),
        .alarm_sec_unit_bcd(alarm_sec_unit),
        .alarm_min_ten_bcd(alarm_min_ten),
        .alarm_min_unit_bcd(alarm_min_unit),
        .alarm_hour_unit_bcd(alarm_hour_unit),
        .alarm_hour_ten_bcd(alarm_hour_ten),
        .countdown_hour_ten_bcd(countdown_hour_ten),
        .countdown_hour_unit_bcd(countdown_hour_unit),
        .countdown_min_ten_bcd(countdown_min_ten),
        .countdown_min_unit_bcd(countdown_min_unit),
        .countdown_sec_ten_bcd(countdown_sec_ten),
        .countdown_sec_unit_bcd(countdown_sec_unit),
        .sec_unit_disp_bcd(sec_u_disp),
        .sec_ten_disp_bcd(sec_ten_bcd),
        .min_unit_disp_bcd(min_unit_bcd),
        .min_ten_disp_bcd(min_ten_bcd),
        .hour_unit_disp_bcd(hour_unit_bcd),
        .hour_ten_disp_bcd(hour_ten_bcd)
    );

    seg_7 u_seg_sec_unit(
        .A(sec_u_disp),
        .seg(sec_unit_seg_raw)
    );

    assign sec_unit_seg = {dp_indicator, sec_unit_seg_raw};
endmodule
