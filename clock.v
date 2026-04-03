	// ===================== 1. 按键消抖模块 (保留) =====================
	module key_debounce(
	    input        clk_1k,
	    input        rst_n,
	    input        key_in,
	    output reg   key_out_pulse
	);
	    reg [4:0] cnt;
	    reg key_sync0, key_sync1;
	    reg key_out_r; // 用于保存“上一次”稳定的状态，用于比较
	    // 同步处理（防止亚稳态）
	    always @(posedge clk_1k or negedge rst_n) begin
	        if(!rst_n) begin
	            key_sync0 <= 1;
	            key_sync1 <= 1;
	        end else begin
	            key_sync0 <= key_in;
	            key_sync1 <= key_sync0;
	        end
	    end
	    // 消抖与脉冲生成逻辑
	    always @(posedge clk_1k or negedge rst_n) begin
	        if(!rst_n) begin
	            cnt <= 0;
	            key_out_r <= 1;   // 默认高电平（松开状态）
	            key_out_pulse <= 0;
	        end else begin
	            key_out_pulse <= 0; // 默认输出0，只在特定条件输出1个周期
	            // 1. 检测抖动：如果信号发生变化，计数器清零
	            if(key_sync1 != key_sync0) begin
	                cnt <= 0;
	            end
	            // 2. 计数过程：信号稳定且未计满
	            else if(cnt < 20) begin
	                cnt <= cnt + 1;
	            end
	            // 3. 计数满20ms：信号已稳定，判断状态变化
	            else begin
	                // 如果当前稳定状态(key_sync1) 与 上次记录的状态(key_out_r) 不同
	                if(key_out_r != key_sync1) begin
	                    key_out_r <= key_sync1; // 更新记录的状态
	                    // 只有检测到上升沿(0->1)时才输出脉冲
	                    // 如果你的按键按下是低电平，请改为 if(key_out_r == 1 && key_sync1 == 0)
	                    if(key_out_r == 0 && key_sync1 == 1) 
	                        key_out_pulse <= 1;
	                end
	            end
	        end
	    end
	endmodule
 
// ===================== 2. 七段译码模块 (保留) =====================
module seg_7(
    input [3:0] A,
    output reg [7:0] seg
);
    always @ (*) begin
        case (A)
            4'd0: seg = 8'b0011_1111; // 0x3F
            4'd1: seg = 8'b0000_0110; // 0x06
            4'd2: seg = 8'b0101_1011; // 0x5B
            4'd3: seg = 8'b0100_1111; // 0x4F
            4'd4: seg = 8'b0110_0110; // 0x66
            4'd5: seg = 8'b0110_1101; // 0x6D
            4'd6: seg = 8'b0111_1101; // 0x7D
            4'd7: seg = 8'b0000_0111; // 0x07
            4'd8: seg = 8'b0111_1111; // 0x7F
            4'd9: seg = 8'b0110_1111; // 0x6F
            default: seg = 8'b0000_0000;
        endcase
    end
endmodule
 
// ===================== 3. 核心功能整合模块 (新增：合并计数与校时) =====================
module clock_core(
    input clk_1k,
    input rst_n,
    input key_mode_pulse, // 模式脉冲
    input key_add_pulse,  // 加1脉冲
    output reg [3:0] h_ten, h_unit, // 小时
    output reg [3:0] m_ten, m_unit, // 分钟
    output reg [3:0] s_ten, s_unit  // 秒钟
);
 
    // --- 1. 状态机定义 ---
    localparam S_RUN  = 2'b00; // 正常走时
    localparam S_SET_H = 2'b01; // 设置小时
    localparam S_SET_M = 2'b10; // 设置分钟
    
    reg [1:0] state;
 
    // --- 2. 1Hz 分频逻辑 ---
    reg [9:0] cnt_1k;
    wire tick_1s = (cnt_1k == 999);
    
    always @(posedge clk_1k or negedge rst_n) begin
        if(!rst_n) cnt_1k <= 0;
        else cnt_1k <= (tick_1s) ? 0 : cnt_1k + 1;
    end
 
    // --- 3. 状态跳转逻辑 ---
    always @(posedge clk_1k or negedge rst_n) begin
        if(!rst_n) state <= S_RUN;
        else if(key_mode_pulse) begin
            case(state)
                S_RUN:  state <= S_SET_H;
                S_SET_H: state <= S_SET_M;
                S_SET_M: state <= S_RUN;
            endcase
        end
    end
 
    // --- 4. 计数与校时逻辑 ---
    // 统一的进位逻辑
    wire carry_min = (s_unit==9 && s_ten==5 && tick_1s);
    wire carry_hour = (m_unit==9 && m_ten==5 && carry_min);
 
    always @(posedge clk_1k or negedge rst_n) begin
        if(!rst_n) begin
            {h_ten, h_unit, m_ten, m_unit, s_ten, s_unit} <= 0;
        end else begin
            case(state)
                S_RUN: begin
                    // 正常走时逻辑
                    if(tick_1s) begin
                        if(s_unit < 9) s_unit <= s_unit + 1;
                        else begin 
                            s_unit <= 0;
                            if(s_ten < 5) s_ten <= s_ten + 1;
                            else begin
                                s_ten <= 0; // 秒归零，产生分钟进位
                                // 分钟逻辑
                                if(m_unit < 9) m_unit <= m_unit + 1;
                                else begin
                                    m_unit <= 0;
                                    if(m_ten < 5) m_ten <= m_ten + 1;
                                    else begin
                                        m_ten <= 0; // 分钟归零，产生小时进位
                                        // 小时逻辑
                                        if(h_ten < 2 || (h_ten==2 && h_unit<3)) begin
                                             if(h_unit < 9) h_unit <= h_unit + 1;
                                             else begin h_unit <= 0; h_ten <= h_ten + 1; end
                                        end
                                        else begin h_ten <= 0; h_unit <= 0; end // 24小时归零
                                    end
                                end
                            end
                        end
                    end
                end
 
                S_SET_H: begin
                    // 小时设置逻辑 (补全)
                    if(key_add_pulse) begin
                        if(h_ten == 2 && h_unit == 3) begin // 23 -> 00
                            h_ten <= 0; h_unit <= 0;
                        end
                        else if(h_unit == 9) begin
                            h_unit <= 0; h_ten <= h_ten + 1;
                        end
                        else begin
                            h_unit <= h_unit + 1;
                        end
                    end
                end
 
                S_SET_M: begin
                    // 分钟设置逻辑 (补全)
                    if(key_add_pulse) begin
                        if(m_ten == 5 && m_unit == 9) begin // 59 -> 00
                            m_ten <= 0; m_unit <= 0;
                        end
                        else if(m_unit == 9) begin
                            m_unit <= 0; m_ten <= m_ten + 1;
                        end
                        else begin
                            m_unit <= m_unit + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule
 
// ===================== 4. 顶层模块 (精简连接) =====================
module clock(
    input clk_1k,
    input rst_n,
    input key_mode_in,
    input key_add_in,
    output [7:0] sec_unit_seg, // 仅秒个位需要译码输出
    output [3:0] sec_ten_bcd,
    output [3:0] min_unit_bcd,
    output [3:0] min_ten_bcd,
    output [3:0] hour_unit_bcd,
    output [3:0] hour_ten_bcd
);
 
    wire mode_pulse, add_pulse;
    wire [3:0] s_u;
 
    // 1. 按键消抖 (输出脉冲)
    key_debounce u_deb_mode(.clk_1k(clk_1k), .rst_n(rst_n), .key_in(key_mode_in), .key_out_pulse(mode_pulse));
    key_debounce u_deb_add (.clk_1k(clk_1k), .rst_n(rst_n), .key_in(key_add_in),  .key_out_pulse(add_pulse));
 
    // 2. 核心时钟
    clock_core u_core(
        .clk_1k(clk_1k), .rst_n(rst_n),
        .key_mode_pulse(mode_pulse), .key_add_pulse(add_pulse),
        .h_ten(hour_ten_bcd), .h_unit(hour_unit_bcd),
        .m_ten(min_ten_bcd),  .m_unit(min_unit_bcd),
        .s_ten(sec_ten_bcd),  .s_unit(s_u)
    );
 
    // 3. 显示译码
    seg_7 u_seg(.A(s_u), .seg(sec_unit_seg));
 
endmodule