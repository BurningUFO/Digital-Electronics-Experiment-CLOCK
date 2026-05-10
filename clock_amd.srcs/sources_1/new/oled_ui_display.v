module oled_ui_display (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] mode_state,
    input  wire       edit_active,
    input  wire       countdown_run,
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
    localparam [7:0] LEFT_X_START       = 8'd2;
    localparam [7:0] RIGHT_X_START      = 8'd86;
    localparam [7:0] ANIM_STEP          = 8'd8;
    localparam [2:0] SIDE_PAGE          = 3'd1;
    localparam [2:0] CENTER_PAGE_BASE   = 3'd3;
    localparam [2:0] STATUS_PAGE        = 3'd6;
    localparam [2:0] ACTIVE_PAGE_FIRST  = 3'd1;
    localparam [2:0] ACTIVE_PAGE_LAST   = 3'd6;
    localparam [7:0] BORDER_Y_TOP       = 8'd20;
    localparam [7:0] BORDER_Y_BOTTOM    = 8'd43;
    localparam [7:0] BORDER_PAD_X       = 8'd4;

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
    reg [2:0]  anim_target_mode = 3'b000;
    reg        animating = 1'b0;
    reg        anim_dir_right = 1'b0;
    reg [7:0]  anim_offset = 8'd0;
    reg [7:0]  anim_total_distance = 8'd0;
    reg [2:0]  render_display_mode = 3'b000;
    reg [2:0]  render_target_mode = 3'b000;
    reg        render_animating = 1'b0;
    reg        render_dir_right = 1'b0;
    reg [7:0]  render_offset = 8'd0;
    reg        render_countdown_run = 1'b0;
    reg        frame_tick_toggle = 1'b0;
    reg        frame_tick_toggle_d = 1'b0;

    wire ll_busy;
    wire ll_done;
    wire ll_ack_ok;

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

    function [7:0] center_x_start;
        input [2:0] mode;
        begin
            center_x_start = 8'd64 - {5'd0, mode_len(mode), 3'b000};
        end
    endfunction

    function [7:0] big_width;
        input [2:0] mode;
        begin
            big_width = {4'd0, mode_len(mode), 4'b0000};
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

    function [7:0] center_label_data;
        input [2:0] page;
        input [7:0] col;
        input [2:0] mode;
        input integer x_start;
        integer bit_idx;
        integer col_i;
        integer width_i;
        integer local_col_i;
        integer char_index_i;
        integer source_col_i;
        reg [7:0] out_byte;
        reg [7:0] row_bits;
        reg pixel;
        reg [7:0] y_abs;
        reg [2:0] source_row;
        begin
            center_label_data = 8'h00;
            col_i = col;
            width_i = big_width(mode);

            if (page >= CENTER_PAGE_BASE &&
                page < CENTER_PAGE_BASE + 2 &&
                col_i >= x_start &&
                col_i < x_start + width_i) begin
                out_byte  = 8'h00;
                local_col_i = col_i - x_start;
                char_index_i = local_col_i / 16;
                source_col_i = (local_col_i / 2) % 8;

                for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                    y_abs      = {5'd0, page, 3'b000} + bit_idx[7:0] - {5'd0, CENTER_PAGE_BASE, 3'b000};
                    source_row = y_abs[4:1];
                    row_bits   = glyph_row(mode_char(mode, char_index_i[2:0]), source_row);
                    pixel      = row_bits[7 - source_col_i[2:0]];
                    out_byte[bit_idx] = pixel;
                end
                center_label_data = out_byte;
            end
        end
    endfunction

    function [7:0] border_overlay;
        input [2:0] page;
        input [7:0] col;
        input [2:0] mode;
        input integer x_start;
        input edit_flag;
        integer bit_idx;
        integer col_i;
        integer width_i;
        integer box_left;
        integer box_right;
        reg [7:0] out_byte;
        reg [7:0] box_y;
        begin
            border_overlay = 8'h00;
            if (edit_flag) begin
                col_i = col;
                width_i = big_width(mode);
                box_left  = x_start - BORDER_PAD_X;
                box_right = x_start + width_i + BORDER_PAD_X - 1;
                out_byte = 8'h00;

                if (col_i >= box_left && col_i <= box_right) begin
                    for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                        box_y = {5'd0, page, 3'b000} + bit_idx[7:0];
                        if (((col_i == box_left) || (col_i == box_right)) &&
                            (box_y >= BORDER_Y_TOP) && (box_y <= BORDER_Y_BOTTOM)) begin
                            out_byte[bit_idx] = 1'b1;
                        end
                        if (((box_y == BORDER_Y_TOP) || (box_y == BORDER_Y_BOTTOM)) &&
                            (col_i >= box_left) && (col_i <= box_right)) begin
                            out_byte[bit_idx] = 1'b1;
                        end
                    end
                end
                border_overlay = out_byte;
            end
        end
    endfunction

    function [7:0] page_data;
        input [2:0] page;
        input [7:0] col;
        input edit_flag;
        reg [7:0] data_byte;
        reg [2:0] view_mode;
        integer current_big_x;
        integer target_big_x;
        begin
            data_byte = 8'h00;
            view_mode = render_animating ? render_target_mode : render_display_mode;

            if (page == SIDE_PAGE) begin
                data_byte = data_byte |
                            side_label_data(col, prev_mode(view_mode), LEFT_X_START) |
                            side_label_data(col, next_mode(view_mode), RIGHT_X_START);
            end

            if ((page == STATUS_PAGE) && (view_mode == 3'b100)) begin
                data_byte = data_byte | status_label_data(col, render_countdown_run);
            end

            if (render_animating) begin
                if (render_dir_right) begin
                    current_big_x = center_x_start(render_display_mode) - render_offset;
                    target_big_x  = 128 - render_offset;
                end else begin
                    current_big_x = center_x_start(render_display_mode) + render_offset;
                    target_big_x  = render_offset - big_width(render_target_mode);
                end
                data_byte = data_byte | center_label_data(page, col, render_display_mode, current_big_x);
                data_byte = data_byte | center_label_data(page, col, render_target_mode, target_big_x);
            end else begin
                current_big_x = center_x_start(render_display_mode);
                data_byte = data_byte | center_label_data(page, col, render_display_mode, current_big_x);
                data_byte = data_byte | border_overlay(page, col, render_display_mode, current_big_x, edit_flag);
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
            anim_target_mode  <= 3'b000;
            animating         <= 1'b0;
            anim_dir_right    <= 1'b0;
            anim_offset       <= 8'd0;
            anim_total_distance <= 8'd0;
            render_display_mode <= 3'b000;
            render_target_mode  <= 3'b000;
            render_animating    <= 1'b0;
            render_dir_right    <= 1'b0;
            render_offset       <= 8'd0;
            render_countdown_run <= 1'b0;
            frame_tick_toggle_d <= 1'b0;
        end else begin
            if (mode_state != display_mode) begin
                animating        <= 1'b1;
                anim_target_mode <= mode_state;
                anim_dir_right   <= (mode_state == next_mode(display_mode));
                if (mode_state == next_mode(display_mode)) begin
                    anim_total_distance <= 8'd128 - center_x_start(mode_state);
                end else begin
                    anim_total_distance <= center_x_start(mode_state) + big_width(mode_state);
                end
            end

            if (frame_tick_toggle != frame_tick_toggle_d) begin
                frame_tick_toggle_d  <= frame_tick_toggle;
                render_display_mode  <= display_mode;
                render_target_mode   <= anim_target_mode;
                render_animating     <= animating;
                render_dir_right     <= anim_dir_right;
                render_offset        <= anim_offset;
                render_countdown_run <= countdown_run;

                if (animating) begin
                    if (anim_offset + ANIM_STEP >= anim_total_distance) begin
                        display_mode        <= anim_target_mode;
                        animating           <= 1'b0;
                        anim_offset         <= 8'd0;
                        anim_total_distance <= 8'd0;
                    end else begin
                        anim_offset <= anim_offset + ANIM_STEP;
                    end
                end
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
