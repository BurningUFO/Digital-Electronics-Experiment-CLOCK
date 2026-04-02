// =============================
// 倒计时模块 【无锁存器 终极版】
// 内部永远无空操作，无latch，MAX芯片完美布局
// =============================
module countdown_ctrl
(
    input             clk,            // 1kHz 系统时钟
    input             rst_n,          // 低电平复位
    input             tick_1hz,       // 1Hz 秒脉冲
    input             qd_pulse,       // QD 单次脉冲 +1
    
    input             start_switch,   // 1=开始倒计时  0=设置时间
    input      [1:0]  sel_switch,     // 2位选择修改位

    // 倒计时输出
    output reg [3:0]  cd_min_ten,
    output reg [3:0]  cd_min_unit,
    output reg [3:0]  cd_sec_ten,
    output reg [3:0]  cd_sec_unit,
    output reg        countdown_done
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cd_min_ten     <= 4'd0;
        cd_min_unit    <= 4'd0;
        cd_sec_ten     <= 4'd0;
        cd_sec_unit    <= 4'd0;
        countdown_done <= 1'b0;
    end
    // 倒计时结束：保持 0000 + done
    else if (countdown_done) begin
        cd_min_ten     <= 4'd0;
        cd_min_unit    <= 4'd0;
        cd_sec_ten     <= 4'd0;
        cd_sec_unit    <= 4'd0;
        countdown_done <= 1'b1;
    end
    // 设置模式：按键加1
    else if (!start_switch) begin
        if (qd_pulse) begin
            case (sel_switch)
                2'b00: cd_min_ten  <= (cd_min_ten ==4'd9) ? 0 : cd_min_ten+1;
                2'b01: cd_min_unit <= (cd_min_unit==4'd9) ? 0 : cd_min_unit+1;
                2'b10: cd_sec_ten  <= (cd_sec_ten ==4'd9) ? 0 : cd_sec_ten+1;
                2'b11: cd_sec_unit <= (cd_sec_unit==4'd9) ? 0 : cd_sec_unit+1;
            endcase
        end
        countdown_done <= 1'b0;
    end
    // 倒计时运行模式
    else if (start_switch && tick_1hz) begin
        if (cd_min_ten ==0 && cd_min_unit==0 && cd_sec_ten==0 && cd_sec_unit==0) begin
            countdown_done <= 1'b1;
        end
        else begin
            if (cd_sec_unit > 0) begin
                cd_sec_unit <= cd_sec_unit - 1;
            end
            else begin
                cd_sec_unit <= 9;
                if (cd_sec_ten >0) cd_sec_ten <= cd_sec_ten -1;
                else begin
                    cd_sec_ten <=5;
                    if (cd_min_unit>0) cd_min_unit <= cd_min_unit-1;
                    else begin
                        cd_min_unit <=9;
                        if (cd_min_ten>0) cd_min_ten <= cd_min_ten-1;
                    end
                end
            end
            countdown_done <= 0;
        end
    end
end

endmodule