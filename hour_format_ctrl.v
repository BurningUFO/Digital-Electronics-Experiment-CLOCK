module hour_format_ctrl
(
    input             clk,
    input             rst_n,
    input             format_sel,     // 0=24h, 1=12h
    input      [3:0]  hour_ten_i,
    input      [3:0]  hour_unit_i,
    output reg [3:0]  hour_ten_o,
    output reg [3:0]  hour_unit_o,
    output reg        am_pm_flag
);

wire [4:0] raw_h = hour_ten_i * 10 + hour_unit_i;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        hour_ten_o  <= 0;
        hour_unit_o <= 0;
        am_pm_flag  <= 0;
    end
    else if(!format_sel) begin
        hour_ten_o  <= hour_ten_i;
        hour_unit_o <= hour_unit_i;
        am_pm_flag  <= 0;
    end
    else begin
        if(raw_h == 0) begin
            hour_ten_o  <= 1;
            hour_unit_o <= 2;
            am_pm_flag  <= 0;
        end
        else if(raw_h < 12) begin
            hour_ten_o  <= hour_ten_i;
            hour_unit_o <= hour_unit_i;
            am_pm_flag  <= 0;
        end
        else if(raw_h == 12) begin
            hour_ten_o  <= 1;
            hour_unit_o <= 2;
            am_pm_flag  <= 1;
        end
        else begin
            hour_ten_o  <= (raw_h - 12)/10;
            hour_unit_o <= (raw_h - 12)%10;
            am_pm_flag  <= 1;
        end
    end
end
endmodule
