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
    localparam integer BLINK_HALF_MS = 9'd250;

    wire blink_active;

    reg [8:0] blink_cnt;
    reg setting_active_d;

    assign setting_active = (mode_state == MODE_SCHEDULE) ? ((|sw[7:0]) | sw[15]) : sw[0];
    assign blink_active = interaction_lock |
                          setting_active |
                          (mode_state == MODE_ALARM) |
                          (mode_state == MODE_SCHEDULE);

    function [2:0] next_mode;
        input [2:0] mode_in;
        begin
            case (mode_in)
                MODE_NORMAL:      next_mode = MODE_TIME_SET;
                MODE_TIME_SET:    next_mode = MODE_ALARM;
                MODE_ALARM:       next_mode = MODE_HOUR_FORMAT;
                MODE_HOUR_FORMAT: next_mode = MODE_COUNTDOWN;
                MODE_COUNTDOWN:   next_mode = MODE_SCHEDULE;
                default:          next_mode = MODE_NORMAL;
            endcase
        end
    endfunction

    function [2:0] prev_mode;
        input [2:0] mode_in;
        begin
            case (mode_in)
                MODE_TIME_SET:    prev_mode = MODE_NORMAL;
                MODE_ALARM:       prev_mode = MODE_TIME_SET;
                MODE_HOUR_FORMAT: prev_mode = MODE_ALARM;
                MODE_COUNTDOWN:   prev_mode = MODE_HOUR_FORMAT;
                MODE_SCHEDULE:    prev_mode = MODE_COUNTDOWN;
                default:          prev_mode = MODE_SCHEDULE;
            endcase
        end
    endfunction

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

            if (!interaction_lock && btn_center_pulse) begin
                confirm_pulse <= 1'b1;
            end

            if (interaction_lock) begin
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

                if (btn_left_pulse) begin
                    mode_state <= prev_mode(mode_state);
                end else if (btn_right_pulse) begin
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
