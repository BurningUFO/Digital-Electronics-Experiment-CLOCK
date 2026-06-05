module oled_ui_display (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] mode_state,
    input  wire       edit_active,
    input  wire       countdown_run,
    input  wire       hour_format_12h,
    input  wire       temp_valid,
    input  wire       temp_negative,
    input  wire [7:0] temp_c_abs,
    input  wire       notify_active,
    input  wire [1:0] notify_type,
    input  wire [2:0] notify_slot,
    input  wire [3:0] date_month_ten_bcd,
    input  wire [3:0] date_month_unit_bcd,
    input  wire [3:0] date_day_ten_bcd,
    input  wire [3:0] date_day_unit_bcd,
    input  wire [2:0] date_weekday,
    input  wire       next_alarm_valid,
    input  wire [3:0] next_alarm_hour_ten_bcd,
    input  wire [3:0] next_alarm_hour_unit_bcd,
    input  wire [3:0] next_alarm_min_ten_bcd,
    input  wire [3:0] next_alarm_min_unit_bcd,
    input  wire       next_schedule_valid,
    input  wire [2:0] next_schedule_slot,
    input  wire [3:0] next_schedule_hour_ten_bcd,
    input  wire [3:0] next_schedule_hour_unit_bcd,
    input  wire [3:0] next_schedule_min_ten_bcd,
    input  wire [3:0] next_schedule_min_unit_bcd,
    input  wire [3:0] countdown_hour_ten_bcd,
    input  wire [3:0] countdown_hour_unit_bcd,
    input  wire [3:0] countdown_min_ten_bcd,
    input  wire [3:0] countdown_min_unit_bcd,
    input  wire [3:0] countdown_sec_ten_bcd,
    input  wire [3:0] countdown_sec_unit_bcd,
    output reg        init_done,
    output reg        error,
    inout  wire       oled_scl,
    inout  wire       oled_sda
);
    localparam [7:0] OLED_ADDR_WRITE = 8'h78;

    localparam [1:0] CMD_START = 2'd0;
    localparam [1:0] CMD_WRITE = 2'd1;
    localparam [1:0] CMD_STOP  = 2'd2;

    localparam [2:0] ST_POWERUP   = 3'd0;
    localparam [2:0] ST_INIT      = 3'd1;
    localparam [2:0] ST_PAGE_ADDR = 3'd2;
    localparam [2:0] ST_PAGE_DATA = 3'd3;
    localparam [2:0] ST_ERROR     = 3'd4;

    localparam integer POWERUP_WAIT     = 22'd2_000_000;
    localparam [2:0] SIDE_PAGE          = 3'd1;
    localparam [2:0] SCHEDULE_PAGE      = 3'd2;
    localparam [2:0] CENTER_PAGE_BASE   = 3'd3;
    localparam [2:0] ALARM_PAGE         = 3'd5;
    localparam [2:0] STATUS_PAGE        = 3'd6;
    localparam [2:0] ACTIVE_PAGE_FIRST  = 3'd1;
    localparam [2:0] ACTIVE_PAGE_LAST   = 3'd6;
    localparam [1:0] NOTIFY_NONE        = 2'd0;
    localparam [1:0] NOTIFY_COUNTDOWN   = 2'd1;
    localparam [1:0] NOTIFY_ALARM       = 2'd2;
    localparam [1:0] NOTIFY_SCHEDULE    = 2'd3;
    localparam [7:0] POPUP_X_LEFT       = 8'd6;
    localparam [7:0] POPUP_X_RIGHT      = 8'd121;
    localparam [7:0] POPUP_Y_TOP        = 8'd12;
    localparam [7:0] POPUP_Y_BOTTOM     = 8'd55;

    reg [2:0]  state = ST_POWERUP;
    reg [21:0] powerup_count = 22'd0;
    reg [5:0]  init_index = 6'd0;
    reg [2:0]  page_index = 3'd0;
    reg [7:0]  step_index = 8'd0;
    reg        waiting_done = 1'b0;
    reg [1:0]  ll_cmd_type = CMD_START;
    reg [7:0]  ll_cmd_data = 8'd0;
    reg        ll_cmd_valid = 1'b0;
    reg [1:0]  active_ll_cmd = CMD_START;
    reg [2:0]  display_mode = 3'b000;
    reg [39:0] render_display_label_ascii = {"C","L","O","C","K"};
    reg        render_countdown_run = 1'b0;
    reg        render_hour_format_12h = 1'b0;
    reg        render_temp_valid = 1'b0;
    reg        render_temp_negative = 1'b0;
    reg [7:0]  render_temp_tens_ascii = "0";
    reg [7:0]  render_temp_ones_ascii = "0";
    reg        render_notify_active = 1'b0;
    reg [1:0]  render_notify_type = NOTIFY_NONE;
    reg [2:0]  render_notify_slot = 3'd0;
    reg [3:0]  render_date_month_ten_bcd = 4'd0;
    reg [3:0]  render_date_month_unit_bcd = 4'd0;
    reg [3:0]  render_date_day_ten_bcd = 4'd0;
    reg [3:0]  render_date_day_unit_bcd = 4'd0;
    reg [2:0]  render_date_weekday = 3'd1;
    reg        render_next_alarm_valid = 1'b0;
    reg [3:0]  render_next_alarm_hour_ten_bcd = 4'd0;
    reg [3:0]  render_next_alarm_hour_unit_bcd = 4'd0;
    reg [3:0]  render_next_alarm_min_ten_bcd = 4'd0;
    reg [3:0]  render_next_alarm_min_unit_bcd = 4'd0;
    reg        render_next_schedule_valid = 1'b0;
    reg [2:0]  render_next_schedule_slot = 3'd0;
    reg [3:0]  render_next_schedule_hour_ten_bcd = 4'd0;
    reg [3:0]  render_next_schedule_hour_unit_bcd = 4'd0;
    reg [3:0]  render_next_schedule_min_ten_bcd = 4'd0;
    reg [3:0]  render_next_schedule_min_unit_bcd = 4'd0;
    reg [3:0]  render_countdown_hour_ten_bcd = 4'd0;
    reg [3:0]  render_countdown_hour_unit_bcd = 4'd0;
    reg [3:0]  render_countdown_min_ten_bcd = 4'd0;
    reg [3:0]  render_countdown_min_unit_bcd = 4'd0;
    reg [3:0]  render_countdown_sec_ten_bcd = 4'd0;
    reg [3:0]  render_countdown_sec_unit_bcd = 4'd0;
    reg        frame_tick_toggle = 1'b0;
    reg        frame_tick_toggle_d = 1'b0;

    wire ll_busy;
    wire ll_done;
    wire ll_ack_ok;
    wire [71:0] date_text_ascii;
    wire [95:0] countdown_text_ascii;
    wire [3:0]  countdown_text_len;
    wire [95:0] notify_text_ascii;

    i2c_master_simple #(
        .CLK_DIV(100)
    ) u_i2c_master_simple (
        .clk(clk),
        .rst(rst),
        .cmd_valid(ll_cmd_valid),
        .cmd_type(ll_cmd_type),
        .cmd_data(ll_cmd_data),
        .busy(ll_busy),
        .done(ll_done),
        .ack_ok(ll_ack_ok),
        .scl(oled_scl),
        .sda(oled_sda)
    );

    oled_date_status u_oled_date_status(
        .month_ten(render_date_month_ten_bcd),
        .month_unit(render_date_month_unit_bcd),
        .day_ten(render_date_day_ten_bcd),
        .day_unit(render_date_day_unit_bcd),
        .weekday(render_date_weekday),
        .date_text_ascii(date_text_ascii)
    );

    oled_countdown_status u_oled_countdown_status(
        .countdown_run(render_countdown_run),
        .countdown_hour_ten_bcd(render_countdown_hour_ten_bcd),
        .countdown_hour_unit_bcd(render_countdown_hour_unit_bcd),
        .countdown_min_ten_bcd(render_countdown_min_ten_bcd),
        .countdown_min_unit_bcd(render_countdown_min_unit_bcd),
        .countdown_sec_ten_bcd(render_countdown_sec_ten_bcd),
        .countdown_sec_unit_bcd(render_countdown_sec_unit_bcd),
        .countdown_ascii(countdown_text_ascii),
        .countdown_ascii_len(countdown_text_len)
    );

    oled_notify_status u_oled_notify_status(
        .notify_active(render_notify_active),
        .notify_type(render_notify_type),
        .notify_slot(render_notify_slot),
        .notify_text(notify_text_ascii)
    );

    function [7:0] init_cmd;
        input [5:0] index;
        begin
            case (index)
                6'd0:  init_cmd = 8'hAE;
                6'd1:  init_cmd = 8'hD5;
                6'd2:  init_cmd = 8'h80;
                6'd3:  init_cmd = 8'hA8;
                6'd4:  init_cmd = 8'h3F;
                6'd5:  init_cmd = 8'hD3;
                6'd6:  init_cmd = 8'h00;
                6'd7:  init_cmd = 8'h40;
                6'd8:  init_cmd = 8'h8D;
                6'd9:  init_cmd = 8'h14;
                6'd10: init_cmd = 8'h20;
                6'd11: init_cmd = 8'h02;
                6'd12: init_cmd = 8'hA1;
                6'd13: init_cmd = 8'hC8;
                6'd14: init_cmd = 8'hDA;
                6'd15: init_cmd = 8'h12;
                6'd16: init_cmd = 8'h81;
                6'd17: init_cmd = 8'hCF;
                6'd18: init_cmd = 8'hD9;
                6'd19: init_cmd = 8'hF1;
                6'd20: init_cmd = 8'hDB;
                6'd21: init_cmd = 8'h40;
                6'd22: init_cmd = 8'hA4;
                6'd23: init_cmd = 8'hA6;
                6'd24: init_cmd = 8'hAF;
                default: init_cmd = 8'h00;
            endcase
        end
    endfunction

    function [2:0] prev_mode;
        input [2:0] mode_in;
        begin
            case (mode_in)
                3'b001: prev_mode = 3'b000;
                3'b010: prev_mode = 3'b001;
                3'b011: prev_mode = 3'b010;
                3'b100: prev_mode = 3'b011;
                3'b101: prev_mode = 3'b100;
                default: prev_mode = 3'b101;
            endcase
        end
    endfunction

    function [2:0] next_mode;
        input [2:0] mode_in;
        begin
            case (mode_in)
                3'b000: next_mode = 3'b001;
                3'b001: next_mode = 3'b010;
                3'b010: next_mode = 3'b011;
                3'b011: next_mode = 3'b100;
                3'b100: next_mode = 3'b101;
                default: next_mode = 3'b000;
            endcase
        end
    endfunction

    function [2:0] mode_len;
        input [2:0] mode;
        begin
            case (mode)
                3'b001: mode_len = 3'd4;
                3'b011: mode_len = 3'd4;
                default: mode_len = 3'd5;
            endcase
        end
    endfunction

    function [39:0] mode_label_ascii;
        input [2:0] mode;
        begin
            case (mode)
                3'b000: mode_label_ascii = {"C","L","O","C","K"};
                3'b001: mode_label_ascii = {"T","I","M","E"," "};
                3'b010: mode_label_ascii = {"A","L","A","R","M"};
                3'b011: mode_label_ascii = {"H","O","U","R"," "};
                3'b100: mode_label_ascii = {"C","O","U","N","T"};
                default: mode_label_ascii = {"S","C","H","E","D"};
            endcase
        end
    endfunction

    function [7:0] label_char;
        input [39:0] label;
        input [2:0] index;
        begin
            case (index)
                3'd0: label_char = label[39:32];
                3'd1: label_char = label[31:24];
                3'd2: label_char = label[23:16];
                3'd3: label_char = label[15:8];
                3'd4: label_char = label[7:0];
                default: label_char = " ";
            endcase
        end
    endfunction

    function [7:0] center_x_start;
        input [2:0] mode;
        begin
            center_x_start = 8'd64 - {5'd0, mode_len(mode), 3'b000};
        end
    endfunction

    function [7:0] mode_char;
        input [2:0] mode;
        input [2:0] index;
        begin
            case (mode)
                3'b000: begin
                    case (index)
                        3'd0: mode_char = "C";
                        3'd1: mode_char = "L";
                        3'd2: mode_char = "O";
                        3'd3: mode_char = "C";
                        3'd4: mode_char = "K";
                        default: mode_char = " ";
                    endcase
                end
                3'b001: begin
                    case (index)
                        3'd0: mode_char = "T";
                        3'd1: mode_char = "I";
                        3'd2: mode_char = "M";
                        3'd3: mode_char = "E";
                        default: mode_char = " ";
                    endcase
                end
                3'b010: begin
                    case (index)
                        3'd0: mode_char = "A";
                        3'd1: mode_char = "L";
                        3'd2: mode_char = "A";
                        3'd3: mode_char = "R";
                        3'd4: mode_char = "M";
                        default: mode_char = " ";
                    endcase
                end
                3'b011: begin
                    case (index)
                        3'd0: mode_char = "H";
                        3'd1: mode_char = "O";
                        3'd2: mode_char = "U";
                        3'd3: mode_char = "R";
                        default: mode_char = " ";
                    endcase
                end
                3'b100: begin
                    case (index)
                        3'd0: mode_char = "C";
                        3'd1: mode_char = "O";
                        3'd2: mode_char = "U";
                        3'd3: mode_char = "N";
                        3'd4: mode_char = "T";
                        default: mode_char = " ";
                    endcase
                end
                default: begin
                    case (index)
                        3'd0: mode_char = "S";
                        3'd1: mode_char = "C";
                        3'd2: mode_char = "H";
                        3'd3: mode_char = "E";
                        3'd4: mode_char = "D";
                        default: mode_char = " ";
                    endcase
                end
            endcase
        end
    endfunction

    function [7:0] glyph_row;
        input [7:0] ch;
        input [2:0] row;
        begin
            case (ch)
                "A": begin
                    case (row)
                        3'd0: glyph_row = 8'b00011000;
                        3'd1: glyph_row = 8'b00100100;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b01111110;
                        3'd4: glyph_row = 8'b01000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b01000010;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "C": begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000000;
                        3'd3: glyph_row = 8'b01000000;
                        3'd4: glyph_row = 8'b01000000;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "D": begin
                    case (row)
                        3'd0: glyph_row = 8'b01111000;
                        3'd1: glyph_row = 8'b01000100;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b01000010;
                        3'd4: glyph_row = 8'b01000010;
                        3'd5: glyph_row = 8'b01000100;
                        3'd6: glyph_row = 8'b01111000;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "E": begin
                    case (row)
                        3'd0: glyph_row = 8'b01111110;
                        3'd1: glyph_row = 8'b01000000;
                        3'd2: glyph_row = 8'b01000000;
                        3'd3: glyph_row = 8'b01111100;
                        3'd4: glyph_row = 8'b01000000;
                        3'd5: glyph_row = 8'b01000000;
                        3'd6: glyph_row = 8'b01111110;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "F": begin
                    case (row)
                        3'd0: glyph_row = 8'b01111110;
                        3'd1: glyph_row = 8'b01000000;
                        3'd2: glyph_row = 8'b01000000;
                        3'd3: glyph_row = 8'b01111100;
                        3'd4: glyph_row = 8'b01000000;
                        3'd5: glyph_row = 8'b01000000;
                        3'd6: glyph_row = 8'b01000000;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "H": begin
                    case (row)
                        3'd0: glyph_row = 8'b01000010;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b01111110;
                        3'd4: glyph_row = 8'b01000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b01000010;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "I": begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b00011000;
                        3'd2: glyph_row = 8'b00011000;
                        3'd3: glyph_row = 8'b00011000;
                        3'd4: glyph_row = 8'b00011000;
                        3'd5: glyph_row = 8'b00011000;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "K": begin
                    case (row)
                        3'd0: glyph_row = 8'b01000010;
                        3'd1: glyph_row = 8'b01000100;
                        3'd2: glyph_row = 8'b01001000;
                        3'd3: glyph_row = 8'b01110000;
                        3'd4: glyph_row = 8'b01001000;
                        3'd5: glyph_row = 8'b01000100;
                        3'd6: glyph_row = 8'b01000010;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "L": begin
                    case (row)
                        3'd0: glyph_row = 8'b01000000;
                        3'd1: glyph_row = 8'b01000000;
                        3'd2: glyph_row = 8'b01000000;
                        3'd3: glyph_row = 8'b01000000;
                        3'd4: glyph_row = 8'b01000000;
                        3'd5: glyph_row = 8'b01000000;
                        3'd6: glyph_row = 8'b01111110;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "M": begin
                    case (row)
                        3'd0: glyph_row = 8'b01000010;
                        3'd1: glyph_row = 8'b01100110;
                        3'd2: glyph_row = 8'b01011010;
                        3'd3: glyph_row = 8'b01000010;
                        3'd4: glyph_row = 8'b01000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b01000010;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "N": begin
                    case (row)
                        3'd0: glyph_row = 8'b01000010;
                        3'd1: glyph_row = 8'b01100010;
                        3'd2: glyph_row = 8'b01010010;
                        3'd3: glyph_row = 8'b01001010;
                        3'd4: glyph_row = 8'b01000110;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b01000010;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "O": begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b01000010;
                        3'd4: glyph_row = 8'b01000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "P": begin
                    case (row)
                        3'd0: glyph_row = 8'b01111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b01111100;
                        3'd4: glyph_row = 8'b01000000;
                        3'd5: glyph_row = 8'b01000000;
                        3'd6: glyph_row = 8'b01000000;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "R": begin
                    case (row)
                        3'd0: glyph_row = 8'b01111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b01111100;
                        3'd4: glyph_row = 8'b01001000;
                        3'd5: glyph_row = 8'b01000100;
                        3'd6: glyph_row = 8'b01000010;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "S": begin
                    case (row)
                        3'd0: glyph_row = 8'b00111110;
                        3'd1: glyph_row = 8'b01000000;
                        3'd2: glyph_row = 8'b01000000;
                        3'd3: glyph_row = 8'b00111100;
                        3'd4: glyph_row = 8'b00000010;
                        3'd5: glyph_row = 8'b00000010;
                        3'd6: glyph_row = 8'b01111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "T": begin
                    case (row)
                        3'd0: glyph_row = 8'b01111110;
                        3'd1: glyph_row = 8'b00011000;
                        3'd2: glyph_row = 8'b00011000;
                        3'd3: glyph_row = 8'b00011000;
                        3'd4: glyph_row = 8'b00011000;
                        3'd5: glyph_row = 8'b00011000;
                        3'd6: glyph_row = 8'b00011000;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "U": begin
                    case (row)
                        3'd0: glyph_row = 8'b01000010;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b01000010;
                        3'd4: glyph_row = 8'b01000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "W": begin
                    case (row)
                        3'd0: glyph_row = 8'b01000010;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b01000010;
                        3'd4: glyph_row = 8'b01011010;
                        3'd5: glyph_row = 8'b01100110;
                        3'd6: glyph_row = 8'b01000010;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "X": begin
                    case (row)
                        3'd0: glyph_row = 8'b01000010;
                        3'd1: glyph_row = 8'b00100100;
                        3'd2: glyph_row = 8'b00011000;
                        3'd3: glyph_row = 8'b00011000;
                        3'd4: glyph_row = 8'b00011000;
                        3'd5: glyph_row = 8'b00100100;
                        3'd6: glyph_row = 8'b01000010;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "Y": begin
                    case (row)
                        3'd0: glyph_row = 8'b01000010;
                        3'd1: glyph_row = 8'b00100100;
                        3'd2: glyph_row = 8'b00011000;
                        3'd3: glyph_row = 8'b00011000;
                        3'd4: glyph_row = 8'b00011000;
                        3'd5: glyph_row = 8'b00011000;
                        3'd6: glyph_row = 8'b00011000;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "0": begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000110;
                        3'd3: glyph_row = 8'b01001010;
                        3'd4: glyph_row = 8'b01010010;
                        3'd5: glyph_row = 8'b01100010;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "1": begin
                    case (row)
                        3'd0: glyph_row = 8'b00011000;
                        3'd1: glyph_row = 8'b00101000;
                        3'd2: glyph_row = 8'b00001000;
                        3'd3: glyph_row = 8'b00001000;
                        3'd4: glyph_row = 8'b00001000;
                        3'd5: glyph_row = 8'b00001000;
                        3'd6: glyph_row = 8'b00111110;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "2": begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b00000010;
                        3'd3: glyph_row = 8'b00001100;
                        3'd4: glyph_row = 8'b00110000;
                        3'd5: glyph_row = 8'b01000000;
                        3'd6: glyph_row = 8'b01111110;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "3": begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b00000010;
                        3'd3: glyph_row = 8'b00011100;
                        3'd4: glyph_row = 8'b00000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "4": begin
                    case (row)
                        3'd0: glyph_row = 8'b00000100;
                        3'd1: glyph_row = 8'b00001100;
                        3'd2: glyph_row = 8'b00010100;
                        3'd3: glyph_row = 8'b00100100;
                        3'd4: glyph_row = 8'b01111110;
                        3'd5: glyph_row = 8'b00000100;
                        3'd6: glyph_row = 8'b00000100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "5": begin
                    case (row)
                        3'd0: glyph_row = 8'b01111110;
                        3'd1: glyph_row = 8'b01000000;
                        3'd2: glyph_row = 8'b01000000;
                        3'd3: glyph_row = 8'b01111100;
                        3'd4: glyph_row = 8'b00000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "6": begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b01000000;
                        3'd2: glyph_row = 8'b01000000;
                        3'd3: glyph_row = 8'b01111100;
                        3'd4: glyph_row = 8'b01000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "7": begin
                    case (row)
                        3'd0: glyph_row = 8'b01111110;
                        3'd1: glyph_row = 8'b00000010;
                        3'd2: glyph_row = 8'b00000100;
                        3'd3: glyph_row = 8'b00001000;
                        3'd4: glyph_row = 8'b00010000;
                        3'd5: glyph_row = 8'b00100000;
                        3'd6: glyph_row = 8'b00100000;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "8": begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b00111100;
                        3'd4: glyph_row = 8'b01000010;
                        3'd5: glyph_row = 8'b01000010;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "9": begin
                    case (row)
                        3'd0: glyph_row = 8'b00111100;
                        3'd1: glyph_row = 8'b01000010;
                        3'd2: glyph_row = 8'b01000010;
                        3'd3: glyph_row = 8'b00111110;
                        3'd4: glyph_row = 8'b00000010;
                        3'd5: glyph_row = 8'b00000010;
                        3'd6: glyph_row = 8'b00111100;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                ":": begin
                    case (row)
                        3'd0: glyph_row = 8'b00000000;
                        3'd1: glyph_row = 8'b00011000;
                        3'd2: glyph_row = 8'b00011000;
                        3'd3: glyph_row = 8'b00000000;
                        3'd4: glyph_row = 8'b00011000;
                        3'd5: glyph_row = 8'b00011000;
                        3'd6: glyph_row = 8'b00000000;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "/": begin
                    case (row)
                        3'd0: glyph_row = 8'b00000010;
                        3'd1: glyph_row = 8'b00000100;
                        3'd2: glyph_row = 8'b00001000;
                        3'd3: glyph_row = 8'b00010000;
                        3'd4: glyph_row = 8'b00100000;
                        3'd5: glyph_row = 8'b01000000;
                        3'd6: glyph_row = 8'b00000000;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                "-": begin
                    case (row)
                        3'd0: glyph_row = 8'b00000000;
                        3'd1: glyph_row = 8'b00000000;
                        3'd2: glyph_row = 8'b00000000;
                        3'd3: glyph_row = 8'b01111110;
                        3'd4: glyph_row = 8'b00000000;
                        3'd5: glyph_row = 8'b00000000;
                        3'd6: glyph_row = 8'b00000000;
                        default: glyph_row = 8'b00000000;
                    endcase
                end
                default: glyph_row = 8'b00000000;
            endcase
        end
    endfunction

    function [7:0] glyph_column;
        input [7:0] ch;
        input [2:0] col;
        integer r;
        reg [7:0] row_bits;
        begin
            glyph_column = 8'h00;
            for (r = 0; r < 8; r = r + 1) begin
                row_bits = glyph_row(ch, r[2:0]);
                glyph_column[r] = row_bits[7 - col];
            end
        end
    endfunction

    function [7:0] side_label_data;
        input [7:0] col;
        input [2:0] mode;
        input [7:0] x_start;
        reg [7:0] local_col;
        reg [2:0] char_index;
        reg [2:0] glyph_col_index;
        begin
            side_label_data = 8'h00;
            if (col >= x_start && col < x_start + {5'd0, mode_len(mode), 3'b000}) begin
                local_col       = col - x_start;
                char_index      = local_col[7:3];
                glyph_col_index = local_col[2:0];
                side_label_data = glyph_column(mode_char(mode, char_index), glyph_col_index);
            end
        end
    endfunction

    function [2:0] status_len;
        input run_flag;
        begin
            if (run_flag) begin
                status_len = 3'd3;
            end else begin
                status_len = 3'd4;
            end
        end
    endfunction

    function [7:0] status_char;
        input run_flag;
        input [2:0] index;
        begin
            if (run_flag) begin
                case (index)
                    3'd0: status_char = "R";
                    3'd1: status_char = "U";
                    3'd2: status_char = "N";
                    default: status_char = " ";
                endcase
            end else begin
                case (index)
                    3'd0: status_char = "S";
                    3'd1: status_char = "T";
                    3'd2: status_char = "O";
                    3'd3: status_char = "P";
                    default: status_char = " ";
                endcase
            end
        end
    endfunction

    function [7:0] status_x_start;
        input run_flag;
        begin
            if (run_flag) begin
                status_x_start = 8'd52;
            end else begin
                status_x_start = 8'd48;
            end
        end
    endfunction

    function [7:0] status_label_data;
        input [7:0] col;
        input run_flag;
        reg [7:0] x_start;
        reg [7:0] local_col;
        reg [2:0] char_index;
        reg [2:0] glyph_col_index;
        begin
            status_label_data = 8'h00;
            x_start = status_x_start(run_flag);
            if (col >= x_start && col < x_start + {5'd0, status_len(run_flag), 3'b000}) begin
                local_col       = col - x_start;
                char_index      = local_col[7:3];
                glyph_col_index = local_col[2:0];
                status_label_data = glyph_column(status_char(run_flag, char_index), glyph_col_index);
            end
        end
    endfunction

    function [7:0] packed12_char;
        input [95:0] text;
        input [3:0] index;
        begin
            case (index)
                4'd0:  packed12_char = text[95:88];
                4'd1:  packed12_char = text[87:80];
                4'd2:  packed12_char = text[79:72];
                4'd3:  packed12_char = text[71:64];
                4'd4:  packed12_char = text[63:56];
                4'd5:  packed12_char = text[55:48];
                4'd6:  packed12_char = text[47:40];
                4'd7:  packed12_char = text[39:32];
                4'd8:  packed12_char = text[31:24];
                4'd9:  packed12_char = text[23:16];
                4'd10: packed12_char = text[15:8];
                4'd11: packed12_char = text[7:0];
                default: packed12_char = " ";
            endcase
        end
    endfunction

    function [7:0] packed9_char;
        input [71:0] text;
        input [3:0] index;
        begin
            case (index)
                4'd0: packed9_char = text[71:64];
                4'd1: packed9_char = text[63:56];
                4'd2: packed9_char = text[55:48];
                4'd3: packed9_char = text[47:40];
                4'd4: packed9_char = text[39:32];
                4'd5: packed9_char = text[31:24];
                4'd6: packed9_char = text[23:16];
                4'd7: packed9_char = text[15:8];
                4'd8: packed9_char = text[7:0];
                default: packed9_char = " ";
            endcase
        end
    endfunction

    function [7:0] bcd_ascii;
        input [3:0] digit;
        begin
            bcd_ascii = (digit <= 4'd9) ? (8'h30 + digit) : "?";
        end
    endfunction

    function [7:0] decimal_tens_ascii;
        input [7:0] value;
        begin
            if (value >= 8'd90) begin
                decimal_tens_ascii = "9";
            end else if (value >= 8'd80) begin
                decimal_tens_ascii = "8";
            end else if (value >= 8'd70) begin
                decimal_tens_ascii = "7";
            end else if (value >= 8'd60) begin
                decimal_tens_ascii = "6";
            end else if (value >= 8'd50) begin
                decimal_tens_ascii = "5";
            end else if (value >= 8'd40) begin
                decimal_tens_ascii = "4";
            end else if (value >= 8'd30) begin
                decimal_tens_ascii = "3";
            end else if (value >= 8'd20) begin
                decimal_tens_ascii = "2";
            end else if (value >= 8'd10) begin
                decimal_tens_ascii = "1";
            end else begin
                decimal_tens_ascii = "0";
            end
        end
    endfunction

    function [7:0] decimal_ones_ascii;
        input [7:0] value;
        reg [7:0] ones;
        begin
            if (value >= 8'd90) begin
                ones = value - 8'd90;
            end else if (value >= 8'd80) begin
                ones = value - 8'd80;
            end else if (value >= 8'd70) begin
                ones = value - 8'd70;
            end else if (value >= 8'd60) begin
                ones = value - 8'd60;
            end else if (value >= 8'd50) begin
                ones = value - 8'd50;
            end else if (value >= 8'd40) begin
                ones = value - 8'd40;
            end else if (value >= 8'd30) begin
                ones = value - 8'd30;
            end else if (value >= 8'd20) begin
                ones = value - 8'd20;
            end else if (value >= 8'd10) begin
                ones = value - 8'd10;
            end else begin
                ones = value;
            end
            decimal_ones_ascii = 8'h30 + ones[3:0];
        end
    endfunction

    function [7:0] temp_char;
        input [3:0] index;
        begin
            if (!render_temp_valid) begin
                case (index)
                    4'd0: temp_char = "-";
                    4'd1: temp_char = "-";
                    4'd2: temp_char = "C";
                    default: temp_char = " ";
                endcase
            end else if (render_temp_negative) begin
                case (index)
                    4'd0: temp_char = "-";
                    4'd1: temp_char = render_temp_tens_ascii;
                    4'd2: temp_char = render_temp_ones_ascii;
                    4'd3: temp_char = "C";
                    default: temp_char = " ";
                endcase
            end else begin
                case (index)
                    4'd0: temp_char = render_temp_tens_ascii;
                    4'd1: temp_char = render_temp_ones_ascii;
                    4'd2: temp_char = "C";
                    default: temp_char = " ";
                endcase
            end
        end
    endfunction

    function [7:0] schedule_char;
        input [3:0] index;
        begin
            if (!render_next_schedule_valid) begin
                case (index)
                    4'd0: schedule_char = "S";
                    4'd1: schedule_char = " ";
                    4'd2: schedule_char = "-";
                    4'd3: schedule_char = "-";
                    4'd4: schedule_char = ":";
                    4'd5: schedule_char = "-";
                    4'd6: schedule_char = "-";
                    default: schedule_char = " ";
                endcase
            end else begin
                case (index)
                    4'd0: schedule_char = "S";
                    4'd1: schedule_char = bcd_ascii({1'b0, render_next_schedule_slot} + 4'd1);
                    4'd2: schedule_char = " ";
                    4'd3: schedule_char = bcd_ascii(render_next_schedule_hour_ten_bcd);
                    4'd4: schedule_char = bcd_ascii(render_next_schedule_hour_unit_bcd);
                    4'd5: schedule_char = ":";
                    4'd6: schedule_char = bcd_ascii(render_next_schedule_min_ten_bcd);
                    4'd7: schedule_char = bcd_ascii(render_next_schedule_min_unit_bcd);
                    default: schedule_char = " ";
                endcase
            end
        end
    endfunction

    function [7:0] alarm_char;
        input [3:0] index;
        begin
            if (!render_next_alarm_valid) begin
                case (index)
                    4'd0: alarm_char = "A";
                    4'd1: alarm_char = " ";
                    4'd2: alarm_char = "-";
                    4'd3: alarm_char = "-";
                    4'd4: alarm_char = ":";
                    4'd5: alarm_char = "-";
                    4'd6: alarm_char = "-";
                    default: alarm_char = " ";
                endcase
            end else begin
                case (index)
                    4'd0: alarm_char = "A";
                    4'd1: alarm_char = " ";
                    4'd2: alarm_char = bcd_ascii(render_next_alarm_hour_ten_bcd);
                    4'd3: alarm_char = bcd_ascii(render_next_alarm_hour_unit_bcd);
                    4'd4: alarm_char = ":";
                    4'd5: alarm_char = bcd_ascii(render_next_alarm_min_ten_bcd);
                    4'd6: alarm_char = bcd_ascii(render_next_alarm_min_unit_bcd);
                    default: alarm_char = " ";
                endcase
            end
        end
    endfunction

    function [7:0] format_char;
        input [3:0] index;
        begin
            case (index)
                4'd0: format_char = render_hour_format_12h ? "1" : "2";
                4'd1: format_char = render_hour_format_12h ? "2" : "4";
                4'd2: format_char = "H";
                default: format_char = " ";
            endcase
        end
    endfunction

    function [7:0] text_line_data;
        input [2:0] page;
        input [7:0] col;
        input [2:0] target_page;
        input [7:0] x_start;
        input [3:0] len;
        input [3:0] text_kind;
        reg [7:0] local_col;
        reg [3:0] char_index;
        reg [2:0] glyph_col_index;
        reg [7:0] ch;
        begin
            text_line_data = 8'h00;
            if ((page == target_page) && (col >= x_start) && (col < x_start + {1'b0, len, 3'b000})) begin
                local_col = col - x_start;
                char_index = {1'b0, local_col[7:3]};
                glyph_col_index = local_col[2:0];
                case (text_kind)
                    4'd0: ch = packed9_char(date_text_ascii, char_index);
                    4'd1: ch = temp_char(char_index);
                    4'd2: ch = schedule_char(char_index);
                    4'd3: ch = alarm_char(char_index);
                    4'd4: ch = packed12_char(countdown_text_ascii, char_index);
                    4'd5: ch = format_char(char_index);
                    4'd6: ch = packed12_char(notify_text_ascii, char_index);
                    4'd7: ch = label_char(render_display_label_ascii, char_index[2:0]);
                    default: ch = " ";
                endcase
                text_line_data = glyph_column(ch, glyph_col_index);
            end
        end
    endfunction

    function [7:0] popup_box_data;
        input [2:0] page;
        input [7:0] col;
        integer bit_idx;
        reg [7:0] y_abs;
        reg [7:0] out_byte;
        begin
            out_byte = 8'h00;
            if ((col >= POPUP_X_LEFT) && (col <= POPUP_X_RIGHT)) begin
                for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                    y_abs = {5'd0, page, 3'b000} + bit_idx[7:0];
                    if (((col == POPUP_X_LEFT) || (col == POPUP_X_RIGHT)) &&
                        (y_abs >= POPUP_Y_TOP) && (y_abs <= POPUP_Y_BOTTOM)) begin
                        out_byte[bit_idx] = 1'b1;
                    end
                    if (((y_abs == POPUP_Y_TOP) || (y_abs == POPUP_Y_BOTTOM)) &&
                        (col >= POPUP_X_LEFT) && (col <= POPUP_X_RIGHT)) begin
                        out_byte[bit_idx] = 1'b1;
                    end
                end
            end
            popup_box_data = out_byte;
        end
    endfunction

    function [7:0] page_data;
        input [2:0] page;
        input [7:0] col;
        input edit_flag;
        reg [7:0] data_byte;
        begin
            data_byte = 8'h00;

            case (page)
                SIDE_PAGE: begin
                    data_byte = text_line_data(page, col, SIDE_PAGE, 8'd2, 4'd9, 4'd0) |
                                text_line_data(page, col, SIDE_PAGE, 8'd96, 4'd4, 4'd1);
                end
                SCHEDULE_PAGE: begin
                    data_byte = text_line_data(page, col, SCHEDULE_PAGE, 8'd24, 4'd8, 4'd2);
                end
                CENTER_PAGE_BASE,
                CENTER_PAGE_BASE + 1'b1: begin
                    if (page == CENTER_PAGE_BASE) begin
                        data_byte = text_line_data(page, col, CENTER_PAGE_BASE, 8'd44, 4'd5, 4'd7);
                    end else if (edit_flag && (col >= 8'd44) && (col < 8'd84)) begin
                        data_byte = 8'h01;
                    end else begin
                        data_byte = 8'h00;
                    end
                end
                ALARM_PAGE: begin
                    data_byte = text_line_data(page, col, ALARM_PAGE, 8'd2, 4'd7, 4'd3) |
                                text_line_data(page, col, ALARM_PAGE, 8'd96, 4'd3, 4'd5);
                end
                STATUS_PAGE: begin
                    data_byte = text_line_data(page, col, STATUS_PAGE, 8'd16, 4'd12, 4'd4);
                end
                default: begin
                    data_byte = 8'h00;
                end
            endcase

            if (render_notify_active) begin
                if ((page >= 3'd2) && (page <= 3'd6) &&
                    (col >= POPUP_X_LEFT) && (col <= POPUP_X_RIGHT)) begin
                    data_byte = popup_box_data(page, col) |
                                text_line_data(page, col, CENTER_PAGE_BASE, 8'd16, 4'd12, 4'd6);
                end
            end

            page_data = data_byte;
        end
    endfunction

    task issue_ll_cmd;
        input [1:0] t;
        input [7:0] d;
        begin
            ll_cmd_type   <= t;
            ll_cmd_data   <= d;
            ll_cmd_valid  <= 1'b1;
            active_ll_cmd <= t;
            waiting_done  <= 1'b1;
        end
    endtask

    always @(posedge clk) begin
        if (rst) begin
            display_mode      <= 3'b000;
            render_display_label_ascii <= {"C","L","O","C","K"};
            render_countdown_run <= 1'b0;
            render_hour_format_12h <= 1'b0;
            render_temp_valid <= 1'b0;
            render_temp_negative <= 1'b0;
            render_temp_tens_ascii <= "0";
            render_temp_ones_ascii <= "0";
            render_notify_active <= 1'b0;
            render_notify_type <= NOTIFY_NONE;
            render_notify_slot <= 3'd0;
            render_date_month_ten_bcd <= 4'd0;
            render_date_month_unit_bcd <= 4'd0;
            render_date_day_ten_bcd <= 4'd0;
            render_date_day_unit_bcd <= 4'd0;
            render_date_weekday <= 3'd1;
            render_next_alarm_valid <= 1'b0;
            render_next_alarm_hour_ten_bcd <= 4'd0;
            render_next_alarm_hour_unit_bcd <= 4'd0;
            render_next_alarm_min_ten_bcd <= 4'd0;
            render_next_alarm_min_unit_bcd <= 4'd0;
            render_next_schedule_valid <= 1'b0;
            render_next_schedule_slot <= 3'd0;
            render_next_schedule_hour_ten_bcd <= 4'd0;
            render_next_schedule_hour_unit_bcd <= 4'd0;
            render_next_schedule_min_ten_bcd <= 4'd0;
            render_next_schedule_min_unit_bcd <= 4'd0;
            render_countdown_hour_ten_bcd <= 4'd0;
            render_countdown_hour_unit_bcd <= 4'd0;
            render_countdown_min_ten_bcd <= 4'd0;
            render_countdown_min_unit_bcd <= 4'd0;
            render_countdown_sec_ten_bcd <= 4'd0;
            render_countdown_sec_unit_bcd <= 4'd0;
            frame_tick_toggle_d <= 1'b0;
        end else begin
            if (mode_state != display_mode) begin
                display_mode <= mode_state;
            end

            if (frame_tick_toggle != frame_tick_toggle_d) begin
                frame_tick_toggle_d  <= frame_tick_toggle;
                render_display_label_ascii <= mode_label_ascii(display_mode);
                render_countdown_run <= countdown_run;
                render_hour_format_12h <= hour_format_12h;
                render_temp_valid <= temp_valid;
                render_temp_negative <= temp_negative;
                render_temp_tens_ascii <= decimal_tens_ascii(temp_c_abs);
                render_temp_ones_ascii <= decimal_ones_ascii(temp_c_abs);
                render_notify_active <= notify_active;
                render_notify_type <= notify_type;
                render_notify_slot <= notify_slot;
                render_date_month_ten_bcd <= date_month_ten_bcd;
                render_date_month_unit_bcd <= date_month_unit_bcd;
                render_date_day_ten_bcd <= date_day_ten_bcd;
                render_date_day_unit_bcd <= date_day_unit_bcd;
                render_date_weekday <= date_weekday;
                render_next_alarm_valid <= next_alarm_valid;
                render_next_alarm_hour_ten_bcd <= next_alarm_hour_ten_bcd;
                render_next_alarm_hour_unit_bcd <= next_alarm_hour_unit_bcd;
                render_next_alarm_min_ten_bcd <= next_alarm_min_ten_bcd;
                render_next_alarm_min_unit_bcd <= next_alarm_min_unit_bcd;
                render_next_schedule_valid <= next_schedule_valid;
                render_next_schedule_slot <= next_schedule_slot;
                render_next_schedule_hour_ten_bcd <= next_schedule_hour_ten_bcd;
                render_next_schedule_hour_unit_bcd <= next_schedule_hour_unit_bcd;
                render_next_schedule_min_ten_bcd <= next_schedule_min_ten_bcd;
                render_next_schedule_min_unit_bcd <= next_schedule_min_unit_bcd;
                render_countdown_hour_ten_bcd <= countdown_hour_ten_bcd;
                render_countdown_hour_unit_bcd <= countdown_hour_unit_bcd;
                render_countdown_min_ten_bcd <= countdown_min_ten_bcd;
                render_countdown_min_unit_bcd <= countdown_min_unit_bcd;
                render_countdown_sec_ten_bcd <= countdown_sec_ten_bcd;
                render_countdown_sec_unit_bcd <= countdown_sec_unit_bcd;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state         <= ST_POWERUP;
            powerup_count <= 22'd0;
            init_index    <= 6'd0;
            page_index    <= 3'd0;
            step_index    <= 8'd0;
            waiting_done  <= 1'b0;
            ll_cmd_valid  <= 1'b0;
            ll_cmd_type   <= CMD_START;
            ll_cmd_data   <= 8'd0;
            active_ll_cmd <= CMD_START;
            init_done     <= 1'b0;
            error         <= 1'b0;
            frame_tick_toggle <= 1'b0;
        end else begin
            ll_cmd_valid <= 1'b0;

            if (state == ST_POWERUP) begin
                if (powerup_count == POWERUP_WAIT - 1) begin
                    powerup_count <= 22'd0;
                    init_index    <= 6'd0;
                    step_index    <= 8'd0;
                    state         <= ST_INIT;
                end else begin
                    powerup_count <= powerup_count + 1'b1;
                end
            end else if (state == ST_ERROR) begin
            end else if (waiting_done) begin
                if (ll_done) begin
                    waiting_done <= 1'b0;

                    if (active_ll_cmd == CMD_WRITE && !ll_ack_ok) begin
                        error <= 1'b1;
                        state <= ST_ERROR;
                    end else begin
                        case (state)
                            ST_INIT: begin
                                if (step_index == 8'd4) begin
                                    step_index <= 8'd0;
                                    if (init_index == 6'd24) begin
                                        page_index <= 3'd0;
                                        init_done  <= 1'b0;
                                        state      <= ST_PAGE_ADDR;
                                    end else begin
                                        init_index <= init_index + 1'b1;
                                    end
                                end else begin
                                    step_index <= step_index + 1'b1;
                                end
                            end

                            ST_PAGE_ADDR: begin
                                if (step_index == 8'd6) begin
                                    step_index <= 8'd0;
                                    state      <= ST_PAGE_DATA;
                                end else begin
                                    step_index <= step_index + 1'b1;
                                end
                            end

                            ST_PAGE_DATA: begin
                                if (step_index == 8'd131) begin
                                    step_index <= 8'd0;
                                    if ((!init_done && (page_index == 3'd7)) ||
                                        (init_done && (page_index == ACTIVE_PAGE_LAST))) begin
                                        init_done  <= 1'b1;
                                        page_index <= ACTIVE_PAGE_FIRST;
                                        frame_tick_toggle <= ~frame_tick_toggle;
                                    end else begin
                                        page_index <= page_index + 1'b1;
                                    end
                                    state <= ST_PAGE_ADDR;
                                end else begin
                                    step_index <= step_index + 1'b1;
                                end
                            end

                            default: begin
                                state <= ST_ERROR;
                                error <= 1'b1;
                            end
                        endcase
                    end
                end
            end else if (!ll_busy) begin
                case (state)
                    ST_INIT: begin
                        case (step_index)
                            8'd0: issue_ll_cmd(CMD_START, 8'h00);
                            8'd1: issue_ll_cmd(CMD_WRITE, OLED_ADDR_WRITE);
                            8'd2: issue_ll_cmd(CMD_WRITE, 8'h00);
                            8'd3: issue_ll_cmd(CMD_WRITE, init_cmd(init_index));
                            8'd4: issue_ll_cmd(CMD_STOP, 8'h00);
                            default: begin
                                state <= ST_ERROR;
                                error <= 1'b1;
                            end
                        endcase
                    end

                    ST_PAGE_ADDR: begin
                        case (step_index)
                            8'd0: issue_ll_cmd(CMD_START, 8'h00);
                            8'd1: issue_ll_cmd(CMD_WRITE, OLED_ADDR_WRITE);
                            8'd2: issue_ll_cmd(CMD_WRITE, 8'h00);
                            8'd3: issue_ll_cmd(CMD_WRITE, 8'hB0 | {5'd0, page_index});
                            8'd4: issue_ll_cmd(CMD_WRITE, 8'h00);
                            8'd5: issue_ll_cmd(CMD_WRITE, 8'h10);
                            8'd6: issue_ll_cmd(CMD_STOP, 8'h00);
                            default: begin
                                state <= ST_ERROR;
                                error <= 1'b1;
                            end
                        endcase
                    end

                    ST_PAGE_DATA: begin
                        if (step_index == 8'd0) begin
                            issue_ll_cmd(CMD_START, 8'h00);
                        end else if (step_index == 8'd1) begin
                            issue_ll_cmd(CMD_WRITE, OLED_ADDR_WRITE);
                        end else if (step_index == 8'd2) begin
                            issue_ll_cmd(CMD_WRITE, 8'h40);
                        end else if (step_index >= 8'd3 && step_index <= 8'd130) begin
                            issue_ll_cmd(CMD_WRITE, page_data(page_index, step_index - 8'd3, edit_active));
                        end else if (step_index == 8'd131) begin
                            issue_ll_cmd(CMD_STOP, 8'h00);
                        end else begin
                            state <= ST_ERROR;
                            error <= 1'b1;
                        end
                    end

                    default: begin
                        state <= ST_ERROR;
                        error <= 1'b1;
                    end
                endcase
            end
        end
    end
endmodule
