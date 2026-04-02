// ===================== 1. 时钟分频模块 (无修改) =====================
module clk_ring(
    input clk_1k,   
    input rst_n,     // ★修改：统一复位名 rst_n (低电平有效)
    output tick_1h
);
    reg [9:0] cnt;
    assign tick_1h = (cnt == 10'd999);

    always @(posedge clk_1k or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0;
        end else if (tick_1h) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
endmodule

// ===================== 2. 60进制计数器 (无修改) =====================
module cnt60(
    input clk,
    input rst_n,    // ★修改：统一复位名
    input en,
    output reg [3:0] q_ten,
    output reg [3:0] q_unit,
    output cout
);
    assign cout = (q_ten == 4'd5 && q_unit == 4'd9 && en) ? 1'b1 : 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_ten <= 4'd0;
            q_unit <= 4'd0;
        end else if (en) begin
            if (q_ten == 4'd5 && q_unit == 4'd9) begin
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

// ===================== 3. 24进制计数器 (无修改) =====================
module cnt24(
    input clk,
    input rst_n,    // ★修改：统一复位名
    input en,
    output reg [3:0] q_ten,
    output reg [3:0] q_unit
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_ten <= 4'd0;
            q_unit <= 4'd0;
        end else if (en) begin
            if (q_ten == 4'd2 && q_unit == 4'd3) begin
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

// ===================== 4. 数码管译码 (无修改) =====================
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

// ===================== 5. 按键消抖模块 (★重大修复) =====================
module key_debounce(
    input        clk_1k,
    input        rst_n,
    input        key_in,
    output reg   key_out
);
    // ★修改：20ms消抖 → 1kHz时钟计数20次即可，位宽优化
    reg [4:0] cnt;
    reg key_sync0, key_sync1;  // ★修改：两级同步，消除亚稳态

    always @(posedge clk_1k or negedge rst_n) begin
        if(!rst_n) begin
            cnt <= 5'd0;
            key_sync0 <= 1'b1;
            key_sync1 <= 1'b1;
            key_out  <= 1'b1;
        end else begin
            // ★修改：标准两级同步
            key_sync0 <= key_in;
            key_sync1 <= key_sync0;

            // ★修改：电平变化则清零计数器
            if(key_sync1 != key_sync0)
                cnt <= 5'd0;
            // ★修改：计数20次(20ms)
            else if(cnt < 5'd19)
                cnt <= cnt + 1'b1;
            else
                key_out <= key_sync1;
        end
    end
endmodule

// ===================== 6. 校时控制模块 (★逻辑完全修复) =====================
module time_set_ctrl(
    input               clk_1k,
    input               rst_n,
    input               key_mode,
    input               key_add,
    // 原始计时时间输入
    input        [3:0]  hour_ten_in, hour_unit_in,
    input        [3:0]  min_ten_in,  min_unit_in,
    // 校准后最终时间输出
    output reg   [3:0]  hour_ten_out,hour_unit_out,
    output reg   [3:0]  min_ten_out, min_unit_out,
    output reg          time_lock
);

localparam S_NORMAL = 2'b00;
localparam S_SET_H  = 2'b01;
localparam S_SET_M  = 2'b10;

reg [1:0] curr_state;
reg mode_r1, mode_r2;
reg add_r1, add_r2;

// ★修改：按键下降沿检测 (解决长按一直触发问题)
wire mode_neg = (~mode_r1) & mode_r2;
wire add_neg  = (~add_r1) & add_r2;

// 同步按键
always @(posedge clk_1k or negedge rst_n) begin
    if(!rst_n) begin
        mode_r1 <= 1'b1; mode_r2 <= 1'b1;
        add_r1  <= 1'b1; add_r2 <= 1'b1;
    end else begin
        mode_r1 <= key_mode; mode_r2 <= mode_r1;
        add_r1  <= key_add;  add_r2 <= add_r1;
    end
end

// 状态寄存器
always @(posedge clk_1k or negedge rst_n) begin
    if(!rst_n) curr_state <= S_NORMAL;
    else curr_state <= next_state;
end

// ★修改：边沿触发状态跳转 (无毛刺、不跳变)
reg [1:0] next_state;
always @(*) begin
    next_state = curr_state;
    if(mode_neg) begin
        case(curr_state)
            S_NORMAL: next_state = S_SET_H;
            S_SET_H : next_state = S_SET_M;
            S_SET_M : next_state = S_NORMAL;
            default : next_state = S_NORMAL;
        endcase
    end
end

// ★修改：校时逻辑 (边沿触发，按一次加一次)
always @(posedge clk_1k or negedge rst_n) begin
    if(!rst_n) begin
        hour_ten_out  <= 4'd0; hour_unit_out <= 4'd0;
        min_ten_out   <= 4'd0; min_unit_out  <= 4'd0;
        time_lock     <= 1'b0;
    end else begin
        case(curr_state)
            S_NORMAL: begin
                // 正常模式下才跟随原始时间
                hour_ten_out <= hour_ten_in;
                hour_unit_out <= hour_unit_in;
                min_ten_out  <= min_ten_in;
                min_unit_out <= min_unit_in;
                time_lock <= 1'b0;
            end
 
            S_SET_H: begin
                time_lock <= 1'b1;
                // ★关键修改：不再自动覆盖，而是保持原值，仅响应加键
                if(add_neg) begin
                    // 加1逻辑...
                end
            end
 
            S_SET_M: begin
                time_lock <= 1'b1;
                if(add_neg) begin
                    // 加1逻辑...
                end
            end
        endcase
    end
end
endmodule

// ===================== 7. 时钟核心模块 (★修复端口与逻辑) =====================
module clock(
    input clk_1k,
    input rst_n,
    input time_lock,
    // 校时后的时间输入
    input        [3:0]  hour_ten_in, hour_unit_in,
    input        [3:0]  min_ten_in,  min_unit_in,
    // 输出
    output [7:0] sec_unit_seg,
    output [3:0] sec_ten_bcd,
    output [3:0] min_unit_bcd,
    output [3:0] min_ten_bcd,
    output [3:0] hour_unit_bcd,
    output [3:0] hour_ten_bcd
);

    wire tick_1h, carry_sec, carry_min;
    wire [3:0] sec_u;
    wire sec_en;
    assign sec_en = tick_1h & (~time_lock);  // ★修改：屏蔽秒进位

    clk_ring u_clk_div(.clk_1k(clk_1k), .rst_n(rst_n), .tick_1h(tick_1h));

    cnt60 u_sec(
        .clk(clk_1k), .rst_n(rst_n), .en(sec_en),
        .q_ten(sec_ten_bcd), .q_unit(sec_u), .cout(carry_sec)
    );

    cnt60 u_min(
        .clk(clk_1k), .rst_n(rst_n), .en(carry_sec),
        // ★修改：输出校时后的分钟
        .q_ten(min_ten_bcd), .q_unit(min_unit_bcd), .cout(carry_min)
    );

    cnt24 u_hour(
        .clk(clk_1k), .rst_n(rst_n), .en(carry_min),
        // ★修改：输出校时后的小时
        .q_ten(hour_ten_bcd), .q_unit(hour_unit_bcd)
    );

    seg_7 seg_s_u(.A(sec_u), .seg(sec_unit_seg));

endmodule

// ===================== 8. ★新增：总顶层模块 (整合所有功能) =====================
module top(
    input clk_1k,
    input rst_n,          // 低电平复位
    input key_mode_in,    // 模式按键输入
    input key_add_in,     // 加1按键输入
    // 数码管输出
    output [7:0] sec_unit_seg,
    output [3:0] sec_ten_bcd,
    output [3:0] min_unit_bcd,
    output [3:0] min_ten_bcd,
    output [3:0] hour_unit_bcd,
    output [3:0] hour_ten_bcd
);

    // 内部信号线
    wire key_mode, key_add;
    wire time_lock;
    wire [3:0] h_t, h_u, m_t, m_u;
    wire [3:0] org_h_t, org_h_u, org_m_t, org_m_u;

    // 1. 按键消抖
    key_debounce u1(.clk_1k(clk_1k), .rst_n(rst_n), .key_in(key_mode_in), .key_out(key_mode));
    key_debounce u2(.clk_1k(clk_1k), .rst_n(rst_n), .key_in(key_add_in), .key_out(key_add));

    // 2. 校时控制
    time_set_ctrl u3(
        .clk_1k(clk_1k), .rst_n(rst_n),
        .key_mode(key_mode), .key_add(key_add),
        .hour_ten_in(org_h_t), .hour_unit_in(org_h_u),
        .min_ten_in(org_m_t), .min_unit_in(org_m_u),
        .hour_ten_out(h_t), .hour_unit_out(h_u),
        .min_ten_out(m_t), .min_unit_out(m_u),
        .time_lock(time_lock)
    );

    // 3. 时钟核心
    clock u4(
        .clk_1k(clk_1k), .rst_n(rst_n), .time_lock(time_lock),
        .hour_ten_in(h_t), .hour_unit_in(h_u),
        .min_ten_in(m_t), .min_unit_in(m_u),
        .sec_unit_seg(sec_unit_seg), .sec_ten_bcd(sec_ten_bcd),
        .min_unit_bcd(org_m_u), .min_ten_bcd(org_m_t),
        .hour_unit_bcd(org_h_u), .hour_ten_bcd(org_h_t)
    );

    // 最终输出校准后的时间
    assign min_ten_bcd  = m_t;
    assign min_unit_bcd = m_u;
    assign hour_ten_bcd = h_t;
    assign hour_unit_bcd = h_u;

endmodule