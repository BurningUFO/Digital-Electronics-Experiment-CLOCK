module display_ctrl(
    input  [2:0] mode_state,
    input  time_set_select_hour,
    input  [3:0] sec_unit_time_bcd,
    input  [3:0] sec_ten_time_bcd,
    input  [3:0] min_unit_time_bcd,
    input  [3:0] min_ten_time_bcd,
    input  [3:0] hour_unit_time_bcd,
    input  [3:0] hour_ten_time_bcd,
    input  [3:0] countdown_min_ten_bcd,
    input  [3:0] countdown_min_unit_bcd,
    input  [3:0] countdown_sec_ten_bcd,
    input  [3:0] countdown_sec_unit_bcd,
    output [3:0] sec_unit_disp_bcd,
    output [3:0] sec_ten_disp_bcd,
    output [3:0] min_unit_disp_bcd,
    output [3:0] min_ten_disp_bcd,
    output [3:0] hour_unit_disp_bcd,
    output [3:0] hour_ten_disp_bcd
);
    wire mode_time_set;
    wire mode_countdown;
    wire mode_other;

    assign mode_time_set  = (mode_state == 3'b001);
    assign mode_countdown = mode_state[2] & ~mode_state[1] & ~mode_state[0];
    assign mode_other     = |mode_state[2:1] | (mode_state[0] & ~mode_state[1]);

    assign sec_unit_disp_bcd = mode_time_set ? (time_set_select_hour ? 4'd1 : 4'd2) :
                               mode_countdown ? countdown_sec_unit_bcd :
                               mode_other ? {1'b0, mode_state} :
                               sec_unit_time_bcd;

    assign sec_ten_disp_bcd = mode_countdown ? countdown_sec_ten_bcd : sec_ten_time_bcd;
    assign min_unit_disp_bcd = mode_countdown ? countdown_min_unit_bcd : min_unit_time_bcd;
    assign min_ten_disp_bcd = mode_countdown ? countdown_min_ten_bcd : min_ten_time_bcd;
    assign hour_unit_disp_bcd = mode_countdown ? 4'd0 : hour_unit_time_bcd;
    assign hour_ten_disp_bcd = mode_countdown ? 4'd0 : hour_ten_time_bcd;
endmodule
