module mode_ctrl(
    input  clk_1k,
    input  rst,
    input  key_mode_pulse,
    output reg [2:0] mode_state
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
endmodule
