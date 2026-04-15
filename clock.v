// ======================================================
// 模块 1: 分频模块 (1kHz -> 1Hz)
// ======================================================
module clk_ring(
    input clk_1k,   
    input rst,      
    output tick_1h 
);
    reg [9:0] cnt; 
    assign tick_1h = (cnt == 10'd999);

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) cnt <= 0;
        else if (tick_1h) cnt <= 0;
        else cnt <= cnt + 1'b1;
    end
endmodule

// ======================================================
// 模块 2: 60 进制计数器 (秒/分)
// ======================================================
module cnt60(
    input clk, rst, en,
    output reg [3:0] q_ten, q_unit,
    output cout
);
    assign cout = (q_ten == 4'd5 && q_unit == 4'd9 && en) ? 1'b1 : 1'b0;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            q_ten <= 4'd0; q_unit <= 4'd0;
        end else if (en) begin
            if (q_ten == 4'd5 && q_unit == 4'd9) begin
                q_ten <= 4'd0; q_unit <= 4'd0;
            end else if (q_unit == 4'd9) begin
                q_ten <= q_ten + 1'b1; q_unit <= 4'd0;
            end else q_unit <= q_unit + 1'b1;
        end
    end
endmodule

// ======================================================
// 模块 3: 24 进制计数器 (时)
// ======================================================
module cnt24(
    input clk, rst, en,
    output reg [3:0] q_ten, q_unit
);
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            q_ten <= 4'd0; q_unit <= 4'd0;
        end else if (en) begin
            if (q_ten == 4'd2 && q_unit == 4'd3) begin
                q_ten <= 4'd0; q_unit <= 4'd0;
            end else if (q_unit == 4'd9) begin
                q_ten <= q_ten + 1'b1; q_unit <= 4'd0;
            end else q_unit <= q_unit + 1'b1;
        end
    end
endmodule

// ======================================================
// 模块 4: 七段译码模块
// ======================================================
module seg_7(
    input [3:0] A,
    output reg [7:0] seg
);
    always @ (A) begin
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

// ======================================================
// 顶层模块: clock (已优化资源占用)
// ======================================================
module clock(
    input clk_1k,    
    input rst,       
    input key_select,   
    input key_add,      
    input key_confirm,  
    output [7:0] sec_unit_seg, 
    output [3:0] sec_ten_bcd,  
    output [3:0] min_unit_bcd, 
    output [3:0] min_ten_bcd,  
    output [3:0] hour_unit_bcd,
    output [3:0] hour_ten_bcd
);
    wire tick_1h, carry_sec, carry_min;
    wire [3:0] sec_u;
    
    // 1. 基础计时实例化
    clk_ring u_clk_div(.clk_1k(clk_1k), .rst(rst), .tick_1h(tick_1h));
    cnt60 u_sec(.clk(clk_1k), .rst(rst), .en(tick_1h), .q_ten(sec_ten_bcd), .q_unit(sec_u), .cout(carry_sec));
    cnt60 u_min(.clk(clk_1k), .rst(rst), .en(carry_sec), .q_ten(min_ten_bcd), .q_unit(min_unit_bcd), .cout(carry_min));
    cnt24 u_hour(.clk(clk_1k), .rst(rst), .en(carry_min), .q_ten(hour_ten_bcd), .q_unit(hour_unit_bcd));

    // 2. 实例化闹钟模块 (关键修改：移除 *10 转换，直接传 BCD 信号)
    wire alarm_hit_sig;
    alarm_ctrl u_alarm (
        .clk_1k(clk_1k),
        .rst_n(rst),
        .mode_state(3'b010), 
        .key_select_pulse(key_select),
        .key_add_pulse(key_add),
        .key_confirm_pulse(key_confirm),
        // 传给闹钟模块的当前时间 BCD 码
        .cur_h_t(hour_ten_bcd), 
        .cur_h_u(hour_unit_bcd),
        .cur_m_t(min_ten_bcd), 
        .cur_m_u(min_unit_bcd),
        .cur_s_t(sec_ten_bcd),
        .alarm_hit(alarm_hit_sig) 
    );

    // 3. LG1 显示逻辑与响铃绑定
    wire [7:0] seg_data;
    seg_7 seg_s_u(.A(sec_u), .seg(seg_data)); 
    
    // 闹钟响铃时，LG1 的小数点 dp (sec_unit_seg[7]) 会亮起
    assign sec_unit_seg = {alarm_hit_sig, seg_data[6:0]};

endmodule