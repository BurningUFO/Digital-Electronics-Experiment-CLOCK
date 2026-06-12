// -----------------------------------------------------------------------------
// 统一 UI 控制层。
//
// 职责：
// 1. 对五个板载按键做消抖并输出单周期 pulse。
// 2. 管理 CLOCK -> TIME -> ALARM -> HOUR -> COUNT -> SCHED -> COMM 的模式环。
// 3. 根据 SW0 或 SCHED 专用开关规则生成 setting_active。
// 4. 在提醒激活时冻结普通交互，使 BTNC/方向键优先服务提醒确认和贪睡。
//
// COMM 特殊约定：COMM 模式不进入普通设置层，SW0-SW15 全部留给消息槽选择。
// -----------------------------------------------------------------------------
module ui_ctrl(
    input  clk,
    input  tick_1k,
    input  rst,
    input  btn_left,
    input  btn_right,
    input  btn_up,
    input  btn_down,
    input  btn_center,
    input  [15:0] sw,
    input  interaction_lock,
    input  mode_nav_lock,
    output reg [2:0] mode_state,
    output setting_active,
    output reg [2:0] field_index,
    output reg value_inc_pulse,
    output reg value_dec_pulse,
    output reg confirm_pulse,
    output reg blink_hide,
    output btn_left_pulse,
    output btn_right_pulse,
    output btn_up_pulse,
    output btn_down_pulse,
    output btn_center_pulse
);
    localparam MODE_NORMAL      = 3'b000;
    localparam MODE_TIME_SET    = 3'b001;
    localparam MODE_ALARM       = 3'b010;
    localparam MODE_HOUR_FORMAT = 3'b011;
    localparam MODE_COUNTDOWN   = 3'b100;
    localparam MODE_SCHEDULE    = 3'b101;
    localparam MODE_COMM        = 3'b110;
    localparam integer BLINK_HALF_MS = 9'd250;

    wire blink_active;

    reg [8:0] blink_cnt;
    reg setting_active_d;

    // 设置层进入规则：
    // - 普通模式使用 SW0。
    // - SCHED 模式沿用旧交互，SW[7:0]/SW15 同时承担槽位和类型页选择。
    // - COMM 模式强制为浏览层，避免 SW0 被解释为设置开关。
    assign setting_active = (mode_state == MODE_COMM) ? 1'b0 :
                            (mode_state == MODE_SCHEDULE) ? ((|sw[7:0]) | sw[15]) : sw[0];
    assign blink_active = interaction_lock |
                          setting_active |
                          (mode_state == MODE_ALARM) |
                          (mode_state == MODE_SCHEDULE);

    // 浏览层右键模式顺序。
    function [2:0] next_mode;
        input [2:0] mode_in;
        begin
            case (mode_in)
                MODE_NORMAL:      next_mode = MODE_TIME_SET;
                MODE_TIME_SET:    next_mode = MODE_ALARM;
                MODE_ALARM:       next_mode = MODE_HOUR_FORMAT;
                MODE_HOUR_FORMAT: next_mode = MODE_COUNTDOWN;
                MODE_COUNTDOWN:   next_mode = MODE_SCHEDULE;
                MODE_SCHEDULE:    next_mode = MODE_COMM;
                default:          next_mode = MODE_NORMAL;
            endcase
        end
    endfunction

    // 浏览层左键模式顺序。
    function [2:0] prev_mode;
        input [2:0] mode_in;
        begin
            case (mode_in)
                MODE_TIME_SET:    prev_mode = MODE_NORMAL;
                MODE_ALARM:       prev_mode = MODE_TIME_SET;
                MODE_HOUR_FORMAT: prev_mode = MODE_ALARM;
                MODE_COUNTDOWN:   prev_mode = MODE_HOUR_FORMAT;
                MODE_SCHEDULE:    prev_mode = MODE_COUNTDOWN;
                MODE_COMM:        prev_mode = MODE_SCHEDULE;
                default:          prev_mode = MODE_COMM;
            endcase
        end
    endfunction

    // 各模式设置层字段数量。字段从 0 开始编号。
    function [2:0] max_field_index;
        input [2:0] mode_in;
        begin
            case (mode_in)
                MODE_NORMAL:      max_field_index = 3'd2;
                MODE_TIME_SET:    max_field_index = 3'd2;
                MODE_ALARM:       max_field_index = 3'd4;
                MODE_HOUR_FORMAT: max_field_index = 3'd0;
                MODE_COUNTDOWN:   max_field_index = 3'd2;
                MODE_SCHEDULE:    max_field_index = sw[15] ? 3'd0 : 3'd2;
                MODE_COMM:        max_field_index = 3'd0;
                default:          max_field_index = 3'd0;
            endcase
        end
    endfunction

    button_pulse u_btn_left(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .btn_in(btn_left),
        .pulse(btn_left_pulse)
    );

    button_pulse u_btn_right(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .btn_in(btn_right),
        .pulse(btn_right_pulse)
    );

    button_pulse u_btn_up(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .btn_in(btn_up),
        .pulse(btn_up_pulse)
    );

    button_pulse u_btn_down(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .btn_in(btn_down),
        .pulse(btn_down_pulse)
    );

    button_pulse u_btn_center(
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .btn_in(btn_center),
        .pulse(btn_center_pulse)
    );

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            mode_state       <= MODE_NORMAL;
            field_index      <= 3'd0;
            value_inc_pulse  <= 1'b0;
            value_dec_pulse  <= 1'b0;
            confirm_pulse    <= 1'b0;
            blink_cnt        <= 9'd0;
            blink_hide       <= 1'b0;
            setting_active_d <= 1'b0;
        end else begin
            value_inc_pulse <= 1'b0;
            value_dec_pulse <= 1'b0;
            confirm_pulse   <= 1'b0;
            setting_active_d <= setting_active;

            // 提醒激活时 BTNC 由 notification_ctrl 使用，普通 confirm 不再发出。
            if (!interaction_lock && btn_center_pulse) begin
                confirm_pulse <= 1'b1;
            end

            if (interaction_lock) begin
                // 提醒期间普通 UI 不切模式、不换字段、不改数值。
            end else if (setting_active != setting_active_d) begin
                field_index <= 3'd0;
            end else if (setting_active) begin
                if (btn_left_pulse) begin
                    if (field_index == 3'd0) begin
                        field_index <= max_field_index(mode_state);
                    end else begin
                        field_index <= field_index - 1'b1;
                    end
                end else if (btn_right_pulse) begin
                    if (field_index >= max_field_index(mode_state)) begin
                        field_index <= 3'd0;
                    end else begin
                        field_index <= field_index + 1'b1;
                    end
                end else if (field_index > max_field_index(mode_state)) begin
                    field_index <= 3'd0;
                end

                if (btn_up_pulse) begin
                    value_inc_pulse <= 1'b1;
                end else if (btn_down_pulse) begin
                    value_dec_pulse <= 1'b1;
                end
            end else begin
                field_index <= 3'd0;

                if (!mode_nav_lock && btn_left_pulse) begin
                    mode_state <= prev_mode(mode_state);
                end else if (!mode_nav_lock && btn_right_pulse) begin
                    mode_state <= next_mode(mode_state);
                end else if (mode_state == MODE_COUNTDOWN) begin
                    if (btn_up_pulse) begin
                        value_inc_pulse <= 1'b1;
                    end else if (btn_down_pulse) begin
                        value_dec_pulse <= 1'b1;
                    end
                end
            end

            if (!blink_active) begin
                blink_cnt  <= 9'd0;
                blink_hide <= 1'b0;
            end else if (tick_1k) begin
                if (blink_cnt == BLINK_HALF_MS - 1'b1) begin
                    blink_cnt  <= 9'd0;
                    blink_hide <= ~blink_hide;
                end else begin
                    blink_cnt <= blink_cnt + 1'b1;
                end
            end
        end
    end
endmodule
