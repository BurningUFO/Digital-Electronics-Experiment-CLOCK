module mode_ctrl(
    input  mode_time_set_sw,
    input  mode_alarm_sw,
    input  mode_hour_format_sw,
    input  mode_countdown_sw,
    input  mode_schedule_sw,
    output reg [2:0] mode_state
);
    localparam MODE_NORMAL      = 3'b000;
    localparam MODE_TIME_SET    = 3'b001;
    localparam MODE_ALARM       = 3'b010;
    localparam MODE_HOUR_FORMAT = 3'b011;
    localparam MODE_COUNTDOWN   = 3'b100;
    localparam MODE_SCHEDULE    = 3'b101;

    always @(*) begin
        if (mode_schedule_sw) begin
            mode_state = MODE_SCHEDULE;
        end else if (mode_countdown_sw) begin
            mode_state = MODE_COUNTDOWN;
        end else if (mode_hour_format_sw) begin
            mode_state = MODE_HOUR_FORMAT;
        end else if (mode_alarm_sw) begin
            mode_state = MODE_ALARM;
        end else if (mode_time_set_sw) begin
            mode_state = MODE_TIME_SET;
        end else begin
            mode_state = MODE_NORMAL;
        end
    end
endmodule
