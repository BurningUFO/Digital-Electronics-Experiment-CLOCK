module clock(
    input clk_1k,
    input rst,
    input qd_key,
    input sw_a,
    input sw_b,
    input sw_c,
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

    wire [2:0] ctrl_sel;
    wire [2:0] mode_state;
    wire qd_pulse;
    wire key_mode_pulse;
    wire key_select_pulse;
    wire key_add_pulse;
    wire key_confirm_pulse;
    wire mode_normal;
    wire mode_time_set;
    wire mode_alarm;
    wire mode_hour_format;
    wire mode_countdown;
    wire mode_schedule;
    wire time_set_select_hour;
    wire time_set_hour_add_pulse;
    wire time_set_min_add_pulse;
    wire [3:0] countdown_min_ten;
    wire [3:0] countdown_min_unit;
    wire [3:0] countdown_sec_ten;
    wire [3:0] countdown_sec_unit;

    clk_ring u_clk_div(
        .clk_1k(clk_1k),
        .rst(rst),
        .tick_1h(tick_1h)
    );

    key_ctrl u_key_ctrl(
        .clk_1k(clk_1k),
        .rst(rst),
        .qd_key(qd_key),
        .sw_a(sw_a),
        .sw_b(sw_b),
        .sw_c(sw_c),
        .ctrl_sel(ctrl_sel),
        .qd_pulse(qd_pulse),
        .key_mode_pulse(key_mode_pulse),
        .key_select_pulse(key_select_pulse),
        .key_add_pulse(key_add_pulse),
        .key_confirm_pulse(key_confirm_pulse)
    );

    mode_ctrl u_mode_ctrl(
        .clk_1k(clk_1k),
        .rst(rst),
        .key_mode_pulse(key_mode_pulse),
        .mode_state(mode_state),
        .mode_normal(mode_normal),
        .mode_time_set(mode_time_set),
        .mode_alarm(mode_alarm),
        .mode_hour_format(mode_hour_format),
        .mode_countdown(mode_countdown),
        .mode_schedule(mode_schedule)
    );

    time_set_ctrl u_time_set_ctrl(
        .clk_1k(clk_1k),
        .rst(rst),
        .mode_time_set(mode_time_set),
        .key_select_pulse(key_select_pulse),
        .key_add_pulse(key_add_pulse),
        .select_hour(time_set_select_hour),
        .hour_add_pulse(time_set_hour_add_pulse),
        .min_add_pulse(time_set_min_add_pulse)
    );

    time_core u_time_core(
        .clk_1k(clk_1k),
        .rst(rst),
        .tick_1h(tick_1h),
        .freeze_run(mode_time_set),
        .add_hour_pulse(time_set_hour_add_pulse),
        .add_min_pulse(time_set_min_add_pulse),
        .sec_unit_bcd(sec_u_time),
        .sec_ten_bcd(sec_t_time),
        .min_unit_bcd(min_u_time),
        .min_ten_bcd(min_t_time),
        .hour_unit_bcd(hour_u_time),
        .hour_ten_bcd(hour_t_time)
    );

    countdown_ctrl u_countdown_ctrl(
        .clk_1k(clk_1k),
        .rst(rst),
        .tick_1h(tick_1h),
        .mode_countdown(mode_countdown),
        .qd_pulse(qd_pulse),
        .ctrl_sel(ctrl_sel),
        .min_ten_bcd(countdown_min_ten),
        .min_unit_bcd(countdown_min_unit),
        .sec_ten_bcd(countdown_sec_ten),
        .sec_unit_bcd(countdown_sec_unit)
    );

    display_ctrl u_display_ctrl(
        .mode_state(mode_state),
        .time_set_select_hour(time_set_select_hour),
        .sec_unit_time_bcd(sec_u_time),
        .sec_ten_time_bcd(sec_t_time),
        .min_unit_time_bcd(min_u_time),
        .min_ten_time_bcd(min_t_time),
        .hour_unit_time_bcd(hour_u_time),
        .hour_ten_time_bcd(hour_t_time),
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
        .seg(sec_unit_seg)
    );
endmodule
