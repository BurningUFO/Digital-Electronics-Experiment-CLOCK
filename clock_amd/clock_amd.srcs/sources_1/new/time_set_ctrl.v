module time_set_ctrl(
    input  clk,
    input  tick_1k,
    input  rst,
    input  mode_time_set,
    input  key_select_pulse,
    input  key_add_pulse,
    output reg  select_hour,
    output wire hour_add_pulse,
    output wire min_add_pulse
);
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            select_hour <= 1'b1;
        end else if (!mode_time_set) begin
            select_hour <= 1'b1;
        end else if (tick_1k && key_select_pulse) begin
            select_hour <= ~select_hour;
        end
    end

    assign hour_add_pulse = mode_time_set &  select_hour & key_add_pulse;
    assign min_add_pulse  = mode_time_set & ~select_hour & key_add_pulse;
endmodule
