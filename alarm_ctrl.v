module alarm_ctrl (
    input  wire       clk_1k, rst_n,
    input  wire [2:0] mode_state,
    input  wire       key_select_pulse, key_add_pulse, key_confirm_pulse,
    // 直接接收 BCD 码，省去乘法器
    input  wire [3:0] cur_h_t, cur_h_u, cur_m_t, cur_m_u, cur_s_t,
    output reg        alarm_enable,
    output wire       alarm_hit
);
    // 存储 BCD 格式的闹钟设置
    reg [3:0] al_h_t, al_h_u, al_m_t, al_m_u;
    reg is_setting_min;

    always @(posedge clk_1k or negedge rst_n) begin
        if (!rst_n) begin
            {al_h_t, al_h_u, al_m_t, al_m_u} <= 16'h0000;
            alarm_enable <= 0; is_setting_min <= 0;
        end else if (mode_state == 3'b010) begin
            if (key_select_pulse) is_setting_min <= ~is_setting_min;
            if (key_confirm_pulse) alarm_enable <= ~alarm_enable;
            if (key_add_pulse) begin
                if (!is_setting_min) begin // 调时逻辑
                    if (al_h_u == 9) begin al_h_u <= 0; al_h_t <= al_h_t + 1; end
                    else al_h_u <= al_h_u + 1;
                    if (al_h_t == 2 && al_h_u == 3) begin al_h_t <= 0; al_h_u <= 0; end
                end else begin // 调分逻辑
                    if (al_m_u == 9) begin al_m_u <= 0; al_m_t <= al_m_t + 1; end
                    else al_m_u <= al_m_u + 1;
                    if (al_m_t == 5 && al_m_u == 9) begin al_m_t <= 0; al_m_u <= 0; end
                end
            end
        end
    end

    // 比较 BCD 码，不产生乘法逻辑
    assign alarm_hit = (alarm_enable && cur_h_t == al_h_t && cur_h_u == al_h_u && 
                        cur_m_t == al_m_t && cur_m_u == al_m_u && cur_s_t == 0) ? 1'b1 : 1'b0;
endmodule