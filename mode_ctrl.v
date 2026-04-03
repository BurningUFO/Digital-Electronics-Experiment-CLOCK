module mode_ctrl(
    input  clk_1k,
    input  rst,
    input  key_mode_pulse,
    output reg [2:0] mode_state,
    output wire mode_normal,
    output wire mode_time_set,
    output wire mode_alarm,
    output wire mode_hour_format,
    output wire mode_countdown,
    output wire mode_schedule
);
    localparam MODE_NORMAL      = 3'b000;
    localparam MODE_TIME_SET    = 3'b001;
    localparam MODE_ALARM       = 3'b010;
    localparam MODE_HOUR_FORMAT = 3'b011;
    localparam MODE_COUNTDOWN   = 3'b100;
    localparam MODE_SCHEDULE    = 3'b101;

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            mode_state <= MODE_NORMAL;
        end else if (key_mode_pulse) begin
            if (mode_state == MODE_SCHEDULE) begin
                mode_state <= MODE_NORMAL;
            end else begin
                mode_state <= mode_state + 1'b1;
            end
        end
    end

    assign mode_normal      = (mode_state == MODE_NORMAL);
    assign mode_time_set    = (mode_state == MODE_TIME_SET);
    assign mode_alarm       = (mode_state == MODE_ALARM);
    assign mode_hour_format = (mode_state == MODE_HOUR_FORMAT);
    assign mode_countdown   = (mode_state == MODE_COUNTDOWN);
    assign mode_schedule    = (mode_state == MODE_SCHEDULE);
endmodule
