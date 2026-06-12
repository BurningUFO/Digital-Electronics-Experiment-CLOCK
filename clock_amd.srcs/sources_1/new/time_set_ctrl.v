// -----------------------------------------------------------------------------
// 旧版 TIME 设置辅助模块。
//
// 当前主线直接在 clock.v 中根据 ui_ctrl 的 field_index 分发 TIME 设置脉冲。
// 本模块保留用于旧结构参考，不再承担主线时间设置入口。
// -----------------------------------------------------------------------------
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
