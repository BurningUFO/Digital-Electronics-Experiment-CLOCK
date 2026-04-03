module display_ctrl(
    input  [2:0] mode_state,
    input  time_set_select_hour,
    input  [3:0] sec_unit_time_bcd,
    input  [3:0] sec_ten_time_bcd,
    input  [3:0] min_unit_time_bcd,
    input  [3:0] min_ten_time_bcd,
    input  [3:0] hour_unit_time_bcd,
    input  [3:0] hour_ten_time_bcd,
    output reg [3:0] sec_unit_disp_bcd,
    output reg [3:0] sec_ten_disp_bcd,
    output reg [3:0] min_unit_disp_bcd,
    output reg [3:0] min_ten_disp_bcd,
    output reg [3:0] hour_unit_disp_bcd,
    output reg [3:0] hour_ten_disp_bcd
);
    always @(*) begin
        sec_unit_disp_bcd  = sec_unit_time_bcd;
        sec_ten_disp_bcd   = sec_ten_time_bcd;
        min_unit_disp_bcd  = min_unit_time_bcd;
        min_ten_disp_bcd   = min_ten_time_bcd;
        hour_unit_disp_bcd = hour_unit_time_bcd;
        hour_ten_disp_bcd  = hour_ten_time_bcd;

        if (mode_state == 3'b001) begin
            // 校时模式下，LG1 显示当前正在调整的字段：1=小时，2=分钟
            sec_unit_disp_bcd = time_set_select_hour ? 4'd1 : 4'd2;
        end else if (mode_state != 3'b000) begin
            // 其余扩展模式先显示模式编号，便于联调
            sec_unit_disp_bcd = {1'b0, mode_state};
        end
    end
endmodule
