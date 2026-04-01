module clk_ring(
    input clk_1k,   // 实验箱提供的 1KHz 标准时钟
    input rst,      // 复位信号（低电平有效）
    output tick_1h // 输出 1Hz 使能脉冲
);
    reg [9:0] cnt; // 10位计数器，足够计到 999
    assign tick_1h = (cnt == 10'd999);

    // 在单一 1KHz 时钟域中产生终值脉冲，供后级计数器使能
    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            cnt <= 0;
        end else if (tick_1h) begin // 1KHz 计满 1000 个周期为 1 秒
            cnt <= 0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
endmodule

module cnt60(
    input clk,      // 系统时钟
    input rst,      // 异步复位
    input en,       // 使能信号（为 1 时计数器加一）
    output reg [3:0] q_ten,  // 十位（最大 5）
    output reg [3:0] q_unit, // 个位（最大 9）
    output cout     // 进位输出信号
);
    // 当计数器当前值为 59 且本拍有效时，输出进位脉冲
    assign cout = (q_ten == 4'd5 && q_unit == 4'd9 && en) ? 1'b1 : 1'b0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            q_ten <= 4'd0;
            q_unit <= 4'd0;
        end else if (en) begin
            if (q_ten == 4'd5 && q_unit == 4'd9) begin // 从 59 回到 00
                q_ten <= 4'd0;
                q_unit <= 4'd0;
            end else if (q_unit == 4'd9) begin // 个位到 9，十位加 1
                q_ten <= q_ten + 1'b1;
                q_unit <= 4'd0;
            end else begin
                q_unit <= q_unit + 1'b1; // 个位递增
            end
        end
    end
endmodule


module cnt24(
    input clk,
    input rst,
    input en,
    output reg [3:0] q_ten,
    output reg [3:0] q_unit
);
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            q_ten <= 4'd0;
            q_unit <= 4'd0;
        end else if (en) begin
            if (q_ten == 4'd2 && q_unit == 4'd3) begin // 从 23 回到 00
                q_ten <= 4'd0;
                q_unit <= 4'd0;
            end else if (q_unit == 4'd9) begin
                q_ten <= q_ten + 1'b1;
                q_unit <= 4'd0;
            end else begin
                q_unit <= q_unit + 1'b1;
            end
        end
    end
endmodule


module seg_7(
    input [3:0] A,      // 4位输入（BCD码）
    output reg [7:0] seg // 8位输出，对应 a~g 和 dp
);
    always @ (A) begin
        // 参考 ex-5 的已验证工程，LG1 实际采用高电平点亮的 a~g 段码
        case (A)
            4'd0: seg = 8'b0011_1111;
            4'd1: seg = 8'b0000_0110;
            4'd2: seg = 8'b0101_1011;
            4'd3: seg = 8'b0100_1111;
            4'd4: seg = 8'b0110_0110;
            4'd5: seg = 8'b0110_1101;
            4'd6: seg = 8'b0111_1101;
            4'd7: seg = 8'b0000_0111;
            4'd8: seg = 8'b0111_1111;
            4'd9: seg = 8'b0110_1111;
            default: seg = 8'b0000_0000;
        endcase
    end
endmodule

module clock(
    input clk_1k,    
    input rst,       
    output [7:0] sec_unit_seg, 
    output [3:0] sec_ten_bcd,  
    output [3:0] min_unit_bcd, 
    output [3:0] min_ten_bcd,  
    output [3:0] hour_unit_bcd,
    output [3:0] hour_ten_bcd  
);

    wire tick_1h, carry_sec, carry_min;
    wire [3:0] sec_u;
    
    // 使用统一的 1KHz 时钟，计数推进由 1Hz 使能脉冲控制
    clk_ring u_clk_div(.clk_1k(clk_1k), .rst(rst), .tick_1h(tick_1h));

    cnt60 u_sec(
        .clk(clk_1k), .rst(rst), .en(tick_1h), 
        .q_ten(sec_ten_bcd), .q_unit(sec_u), .cout(carry_sec) 
    );

    cnt60 u_min(
        .clk(clk_1k), .rst(rst), .en(carry_sec), 
        .q_ten(min_ten_bcd), .q_unit(min_unit_bcd), .cout(carry_min)
    );

    cnt24 u_hour(
        .clk(clk_1k), .rst(rst), .en(carry_min), 
        .q_ten(hour_ten_bcd), .q_unit(hour_unit_bcd)
    );

    // 当前系统只有 LG1 需要输出七段段码
    seg_7 seg_s_u(.A(sec_u), .seg(sec_unit_seg)); 

endmodule
