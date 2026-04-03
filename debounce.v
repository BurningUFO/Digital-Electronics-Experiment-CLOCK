// ===================== 1. 按键消抖模块 (保留) =====================
	module debounce(
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