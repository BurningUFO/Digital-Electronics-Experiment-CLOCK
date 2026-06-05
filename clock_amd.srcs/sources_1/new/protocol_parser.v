`timescale 1ns / 1ps

// Streaming parser for #SEQ|CMD|PAYLOAD*CS\n frames.
// MSG_TX text is decoded while the frame body is received and only committed
// after checksum validation, avoiding a wide dynamic BODY buffer.
module protocol_parser #(
    parameter integer MAX_BODY = 256
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        rx_valid,
    input  wire [7:0]  rx_data,
    output reg         cmd_hello_valid,
    output reg         cmd_ping_valid,
    output reg         cmd_status_get_valid,
    output reg         cmd_time_set_valid,
    output reg         cmd_time_get_valid,
    output reg         cmd_alarm_set_valid,
    output reg         cmd_alarm_get_valid,
    output reg         cmd_sched_set_valid,
    output reg         cmd_sched_get_valid,
    output reg         cmd_count_set_valid,
    output reg         cmd_count_start_valid,
    output reg         cmd_count_stop_valid,
    output reg         cmd_count_status_valid,
    output reg [3:0]   time_year_thousand_bcd,
    output reg [3:0]   time_year_hundred_bcd,
    output reg [3:0]   time_year_ten_bcd,
    output reg [3:0]   time_year_unit_bcd,
    output reg [3:0]   time_month_ten_bcd,
    output reg [3:0]   time_month_unit_bcd,
    output reg [3:0]   time_day_ten_bcd,
    output reg [3:0]   time_day_unit_bcd,
    output reg [3:0]   time_hour_ten_bcd,
    output reg [3:0]   time_hour_unit_bcd,
    output reg [3:0]   time_min_ten_bcd,
    output reg [3:0]   time_min_unit_bcd,
    output reg [3:0]   time_sec_ten_bcd,
    output reg [3:0]   time_sec_unit_bcd,
    output reg [2:0]   time_weekday,
    output reg [2:0]   alarm_slot,
    output reg [3:0]   alarm_hour_ten_bcd,
    output reg [3:0]   alarm_hour_unit_bcd,
    output reg [3:0]   alarm_min_ten_bcd,
    output reg [3:0]   alarm_min_unit_bcd,
    output reg [3:0]   alarm_sec_ten_bcd,
    output reg [3:0]   alarm_sec_unit_bcd,
    output reg         alarm_enable,
    output reg [2:0]   sched_slot,
    output reg [3:0]   sched_hour_ten_bcd,
    output reg [3:0]   sched_hour_unit_bcd,
    output reg [3:0]   sched_min_ten_bcd,
    output reg [3:0]   sched_min_unit_bcd,
    output reg [3:0]   sched_sec_ten_bcd,
    output reg [3:0]   sched_sec_unit_bcd,
    output reg [2:0]   sched_type,
    output reg         sched_enable,
    output reg [3:0]   count_hour_ten_bcd,
    output reg [3:0]   count_hour_unit_bcd,
    output reg [3:0]   count_min_ten_bcd,
    output reg [3:0]   count_min_unit_bcd,
    output reg [3:0]   count_sec_ten_bcd,
    output reg [3:0]   count_sec_unit_bcd,
    output reg         msg_begin_valid,
    output reg         cmd_msg_tx_valid,
    output reg [151:0] msg_timestamp_ascii,
    output reg [6:0]   msg_len,
    output reg         msg_char_valid,
    output reg [6:0]   msg_char_index,
    output reg [7:0]   msg_char_ascii,
    output reg         cmd_msg_get_valid,
    output reg [3:0]   msg_get_slot,
    output reg         cmd_msg_clear_valid,
    output reg         msg_clear_all,
    output reg [3:0]   msg_clear_slot,
    output reg         nack_valid,
    output reg [3:0]   nack_err,
    output reg [15:0]  seq_ascii
);
    localparam [2:0] ST_IDLE  = 3'd0;
    localparam [2:0] ST_BODY  = 3'd1;
    localparam [2:0] ST_CS_HI = 3'd2;
    localparam [2:0] ST_CS_LO = 3'd3;
    localparam [2:0] ST_EOL   = 3'd4;
    localparam [2:0] ST_DROP  = 3'd5;
    localparam [2:0] ST_EMIT  = 3'd6;

    localparam [3:0] ERR_BAD_FRAME    = 4'd0;
    localparam [3:0] ERR_BAD_CHECKSUM = 4'd1;
    localparam [3:0] ERR_BAD_PAYLOAD  = 4'd3;
    localparam [3:0] ERR_BAD_LEN      = 4'd4;
    localparam [3:0] ERR_BAD_HEX      = 4'd5;
    localparam [3:0] ERR_BAD_SLOT     = 4'd6;
    localparam [3:0] ERR_UNSUPPORTED  = 4'd7;
    localparam [3:0] ERR_RX_OVERFLOW  = 4'd8;
    localparam [3:0] ERR_BAD_TIME     = 4'd10;

    localparam [3:0] CMD_HELLO      = 4'd0;
    localparam [3:0] CMD_PING       = 4'd1;
    localparam [3:0] CMD_STATUS_GET = 4'd2;
    localparam [3:0] CMD_MSG_TX     = 4'd3;
    localparam [3:0] CMD_MSG_GET    = 4'd4;
    localparam [3:0] CMD_MSG_CLEAR  = 4'd5;
    localparam [3:0] CMD_TIME_SET   = 4'd6;
    localparam [3:0] CMD_TIME_GET   = 4'd7;
    localparam [3:0] CMD_ALARM_SET  = 4'd8;
    localparam [3:0] CMD_ALARM_GET  = 4'd9;
    localparam [3:0] CMD_SCHED_SET  = 4'd10;
    localparam [3:0] CMD_SCHED_GET  = 4'd11;
    localparam [3:0] CMD_COUNT_SET  = 4'd12;
    localparam [3:0] CMD_COUNT_START = 4'd13;
    localparam [3:0] CMD_COUNT_STOP = 4'd14;
    localparam [3:0] CMD_COUNT_STATUS = 4'd15;

    reg [2:0] state;
    reg [8:0] body_len;
    reg [7:0] calc_xor;
    reg [7:0] cs_hi_ascii;
    reg [7:0] cs_lo_ascii;
    reg drop_overflow;
    reg drop_bad_frame;

    reg match_hello;
    reg match_ping;
    reg match_status_get;
    reg match_time_set;
    reg match_time_get;
    reg match_msg_tx;
    reg match_msg_get;
    reg match_msg_clear;
    reg match_alarm_set;
    reg match_alarm_get;
    reg match_sched_set;
    reg match_sched_get;
    reg match_count_set;
    reg match_count_start;
    reg match_count_stop;
    reg match_count_status;

    reg msg_tx_error;
    reg [3:0] msg_tx_error_code;
    reg [6:0] msg_len_acc;
    reg [1:0] msg_len_digit_count;
    reg msg_len_done;
    reg [8:0] msg_text_start;
    reg [2:0] msg_text_key_index;
    reg msg_text_key_done;
    reg msg_hex_hi_pending;
    reg [7:0] msg_hex_hi_ascii;
    reg [6:0] msg_decoded_count;
    reg [6:0] msg_emit_index;
    reg [7:0] msg_char_buf [0:99];

    reg clear_all_match;
    reg clear_digit0_valid;
    reg clear_digit1_valid;
    reg [3:0] clear_digit0;
    reg [3:0] clear_digit1;
    reg time_set_error;
    reg control_error;

    function is_hex_char;
        input [7:0] ch;
        begin
            is_hex_char = ((ch >= "0") && (ch <= "9")) ||
                          ((ch >= "A") && (ch <= "F")) ||
                          ((ch >= "a") && (ch <= "f"));
        end
    endfunction

    function [3:0] hex_nibble;
        input [7:0] ch;
        begin
            if ((ch >= "0") && (ch <= "9")) begin
                hex_nibble = ch - "0";
            end else if ((ch >= "A") && (ch <= "F")) begin
                hex_nibble = ch - "A" + 4'd10;
            end else if ((ch >= "a") && (ch <= "f")) begin
                hex_nibble = ch - "a" + 4'd10;
            end else begin
                hex_nibble = 4'd0;
            end
        end
    endfunction

    function is_digit;
        input [7:0] ch;
        begin
            is_digit = (ch >= "0") && (ch <= "9");
        end
    endfunction

    function is_printable_ascii;
        input [7:0] ch;
        begin
            is_printable_ascii = (ch >= 8'h20) && (ch <= 8'h7E);
        end
    endfunction

    function [7:0] hex_pair_byte;
        input [7:0] hi;
        input [7:0] lo;
        begin
            hex_pair_byte = {hex_nibble(hi), hex_nibble(lo)};
        end
    endfunction

    function [6:0] bcd2_value;
        input [3:0] ten;
        input [3:0] unit;
        begin
            bcd2_value = ({3'd0, ten} * 7'd10) + {3'd0, unit};
        end
    endfunction

    function [5:0] time_month_max_day;
        input [3:0] month_ten;
        input [3:0] month_unit;
        reg [6:0] month_value;
        begin
            month_value = bcd2_value(month_ten, month_unit);
            case (month_value)
                7'd2: time_month_max_day = 6'd28;
                7'd4,
                7'd6,
                7'd9,
                7'd11: time_month_max_day = 6'd30;
                default: time_month_max_day = 6'd31;
            endcase
        end
    endfunction

    function valid_time_set_values;
        input unused;
        reg [6:0] month_value;
        reg [6:0] day_value;
        reg [6:0] hour_value;
        reg [6:0] min_value;
        reg [6:0] sec_value;
        begin
            month_value = bcd2_value(time_month_ten_bcd, time_month_unit_bcd);
            day_value = bcd2_value(time_day_ten_bcd, time_day_unit_bcd);
            hour_value = bcd2_value(time_hour_ten_bcd, time_hour_unit_bcd);
            min_value = bcd2_value(time_min_ten_bcd, time_min_unit_bcd);
            sec_value = bcd2_value(time_sec_ten_bcd, time_sec_unit_bcd);
            valid_time_set_values =
                (time_year_thousand_bcd <= 4'd9) &&
                (time_year_hundred_bcd <= 4'd9) &&
                (time_year_ten_bcd <= 4'd9) &&
                (time_year_unit_bcd <= 4'd9) &&
                (month_value >= 7'd1) && (month_value <= 7'd12) &&
                (day_value >= 7'd1) && (day_value <= {1'b0, time_month_max_day(time_month_ten_bcd, time_month_unit_bcd)}) &&
                (hour_value <= 7'd23) &&
                (min_value <= 7'd59) &&
                (sec_value <= 7'd59) &&
                (time_weekday >= 3'd1) && (time_weekday <= 3'd7);
        end
    endfunction

    function valid_hms_values;
        input [3:0] hour_ten;
        input [3:0] hour_unit;
        input [3:0] min_ten;
        input [3:0] min_unit;
        input [3:0] sec_ten;
        input [3:0] sec_unit;
        reg [6:0] hour_value;
        reg [6:0] min_value;
        reg [6:0] sec_value;
        begin
            hour_value = bcd2_value(hour_ten, hour_unit);
            min_value = bcd2_value(min_ten, min_unit);
            sec_value = bcd2_value(sec_ten, sec_unit);
            valid_hms_values = (hour_value <= 7'd23) &&
                               (min_value <= 7'd59) &&
                               (sec_value <= 7'd59);
        end
    endfunction

    function [7:0] text_key_char;
        input [2:0] idx;
        begin
            case (idx)
                3'd0: text_key_char = "t";
                3'd1: text_key_char = "e";
                3'd2: text_key_char = "x";
                3'd3: text_key_char = "t";
                default: text_key_char = "=";
            endcase
        end
    endfunction

    function prefix_ok;
        input [3:0] cmd;
        input [8:0] pos;
        input [7:0] ch;
        begin
            prefix_ok = 1'b1;
            case (cmd)
                CMD_HELLO: begin
                    case (pos)
                        9'd2: prefix_ok = (ch == "|");
                        9'd3: prefix_ok = (ch == "H");
                        9'd4: prefix_ok = (ch == "E");
                        9'd5: prefix_ok = (ch == "L");
                        9'd6: prefix_ok = (ch == "L");
                        9'd7: prefix_ok = (ch == "O");
                        9'd8: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_PING: begin
                    case (pos)
                        9'd2: prefix_ok = (ch == "|");
                        9'd3: prefix_ok = (ch == "P");
                        9'd4: prefix_ok = (ch == "I");
                        9'd5: prefix_ok = (ch == "N");
                        9'd6: prefix_ok = (ch == "G");
                        9'd7: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_STATUS_GET: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "S");
                        9'd4:  prefix_ok = (ch == "T");
                        9'd5:  prefix_ok = (ch == "A");
                        9'd6:  prefix_ok = (ch == "T");
                        9'd7:  prefix_ok = (ch == "U");
                        9'd8:  prefix_ok = (ch == "S");
                        9'd9:  prefix_ok = (ch == "_");
                        9'd10: prefix_ok = (ch == "G");
                        9'd11: prefix_ok = (ch == "E");
                        9'd12: prefix_ok = (ch == "T");
                        9'd13: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_TIME_SET: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "T");
                        9'd4:  prefix_ok = (ch == "I");
                        9'd5:  prefix_ok = (ch == "M");
                        9'd6:  prefix_ok = (ch == "E");
                        9'd7:  prefix_ok = (ch == "_");
                        9'd8:  prefix_ok = (ch == "S");
                        9'd9:  prefix_ok = (ch == "E");
                        9'd10: prefix_ok = (ch == "T");
                        9'd11: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_TIME_GET: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "T");
                        9'd4:  prefix_ok = (ch == "I");
                        9'd5:  prefix_ok = (ch == "M");
                        9'd6:  prefix_ok = (ch == "E");
                        9'd7:  prefix_ok = (ch == "_");
                        9'd8:  prefix_ok = (ch == "G");
                        9'd9:  prefix_ok = (ch == "E");
                        9'd10: prefix_ok = (ch == "T");
                        9'd11: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_MSG_TX: begin
                    case (pos)
                        9'd2: prefix_ok = (ch == "|");
                        9'd3: prefix_ok = (ch == "M");
                        9'd4: prefix_ok = (ch == "S");
                        9'd5: prefix_ok = (ch == "G");
                        9'd6: prefix_ok = (ch == "_");
                        9'd7: prefix_ok = (ch == "T");
                        9'd8: prefix_ok = (ch == "X");
                        9'd9: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_MSG_GET: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "M");
                        9'd4:  prefix_ok = (ch == "S");
                        9'd5:  prefix_ok = (ch == "G");
                        9'd6:  prefix_ok = (ch == "_");
                        9'd7:  prefix_ok = (ch == "G");
                        9'd8:  prefix_ok = (ch == "E");
                        9'd9:  prefix_ok = (ch == "T");
                        9'd10: prefix_ok = (ch == "|");
                        9'd11: prefix_ok = (ch == "s");
                        9'd12: prefix_ok = (ch == "l");
                        9'd13: prefix_ok = (ch == "o");
                        9'd14: prefix_ok = (ch == "t");
                        9'd15: prefix_ok = (ch == "=");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_ALARM_SET: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "A");
                        9'd4:  prefix_ok = (ch == "L");
                        9'd5:  prefix_ok = (ch == "A");
                        9'd6:  prefix_ok = (ch == "R");
                        9'd7:  prefix_ok = (ch == "M");
                        9'd8:  prefix_ok = (ch == "_");
                        9'd9:  prefix_ok = (ch == "S");
                        9'd10: prefix_ok = (ch == "E");
                        9'd11: prefix_ok = (ch == "T");
                        9'd12: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_ALARM_GET: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "A");
                        9'd4:  prefix_ok = (ch == "L");
                        9'd5:  prefix_ok = (ch == "A");
                        9'd6:  prefix_ok = (ch == "R");
                        9'd7:  prefix_ok = (ch == "M");
                        9'd8:  prefix_ok = (ch == "_");
                        9'd9:  prefix_ok = (ch == "G");
                        9'd10: prefix_ok = (ch == "E");
                        9'd11: prefix_ok = (ch == "T");
                        9'd12: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_SCHED_SET: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "S");
                        9'd4:  prefix_ok = (ch == "C");
                        9'd5:  prefix_ok = (ch == "H");
                        9'd6:  prefix_ok = (ch == "E");
                        9'd7:  prefix_ok = (ch == "D");
                        9'd8:  prefix_ok = (ch == "_");
                        9'd9:  prefix_ok = (ch == "S");
                        9'd10: prefix_ok = (ch == "E");
                        9'd11: prefix_ok = (ch == "T");
                        9'd12: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_SCHED_GET: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "S");
                        9'd4:  prefix_ok = (ch == "C");
                        9'd5:  prefix_ok = (ch == "H");
                        9'd6:  prefix_ok = (ch == "E");
                        9'd7:  prefix_ok = (ch == "D");
                        9'd8:  prefix_ok = (ch == "_");
                        9'd9:  prefix_ok = (ch == "G");
                        9'd10: prefix_ok = (ch == "E");
                        9'd11: prefix_ok = (ch == "T");
                        9'd12: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_COUNT_SET: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "C");
                        9'd4:  prefix_ok = (ch == "O");
                        9'd5:  prefix_ok = (ch == "U");
                        9'd6:  prefix_ok = (ch == "N");
                        9'd7:  prefix_ok = (ch == "T");
                        9'd8:  prefix_ok = (ch == "_");
                        9'd9:  prefix_ok = (ch == "S");
                        9'd10: prefix_ok = (ch == "E");
                        9'd11: prefix_ok = (ch == "T");
                        9'd12: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_COUNT_START: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "C");
                        9'd4:  prefix_ok = (ch == "O");
                        9'd5:  prefix_ok = (ch == "U");
                        9'd6:  prefix_ok = (ch == "N");
                        9'd7:  prefix_ok = (ch == "T");
                        9'd8:  prefix_ok = (ch == "_");
                        9'd9:  prefix_ok = (ch == "S");
                        9'd10: prefix_ok = (ch == "T");
                        9'd11: prefix_ok = (ch == "A");
                        9'd12: prefix_ok = (ch == "R");
                        9'd13: prefix_ok = (ch == "T");
                        9'd14: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_COUNT_STOP: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "C");
                        9'd4:  prefix_ok = (ch == "O");
                        9'd5:  prefix_ok = (ch == "U");
                        9'd6:  prefix_ok = (ch == "N");
                        9'd7:  prefix_ok = (ch == "T");
                        9'd8:  prefix_ok = (ch == "_");
                        9'd9:  prefix_ok = (ch == "S");
                        9'd10: prefix_ok = (ch == "T");
                        9'd11: prefix_ok = (ch == "O");
                        9'd12: prefix_ok = (ch == "P");
                        9'd13: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                CMD_COUNT_STATUS: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "C");
                        9'd4:  prefix_ok = (ch == "O");
                        9'd5:  prefix_ok = (ch == "U");
                        9'd6:  prefix_ok = (ch == "N");
                        9'd7:  prefix_ok = (ch == "T");
                        9'd8:  prefix_ok = (ch == "_");
                        9'd9:  prefix_ok = (ch == "S");
                        9'd10: prefix_ok = (ch == "T");
                        9'd11: prefix_ok = (ch == "A");
                        9'd12: prefix_ok = (ch == "T");
                        9'd13: prefix_ok = (ch == "U");
                        9'd14: prefix_ok = (ch == "S");
                        9'd15: prefix_ok = (ch == "|");
                        default: prefix_ok = 1'b1;
                    endcase
                end
                default: begin
                    case (pos)
                        9'd2:  prefix_ok = (ch == "|");
                        9'd3:  prefix_ok = (ch == "M");
                        9'd4:  prefix_ok = (ch == "S");
                        9'd5:  prefix_ok = (ch == "G");
                        9'd6:  prefix_ok = (ch == "_");
                        9'd7:  prefix_ok = (ch == "C");
                        9'd8:  prefix_ok = (ch == "L");
                        9'd9:  prefix_ok = (ch == "E");
                        9'd10: prefix_ok = (ch == "A");
                        9'd11: prefix_ok = (ch == "R");
                        9'd12: prefix_ok = (ch == "|");
                        9'd13: prefix_ok = (ch == "s");
                        9'd14: prefix_ok = (ch == "l");
                        9'd15: prefix_ok = (ch == "o");
                        9'd16: prefix_ok = (ch == "t");
                        9'd17: prefix_ok = (ch == "=");
                        default: prefix_ok = 1'b1;
                    endcase
                end
            endcase
        end
    endfunction

    task reset_frame_state;
        begin
            body_len <= 9'd0;
            calc_xor <= 8'd0;
            drop_overflow <= 1'b0;
            drop_bad_frame <= 1'b0;
            match_hello <= 1'b1;
            match_ping <= 1'b1;
            match_status_get <= 1'b1;
            match_time_set <= 1'b1;
            match_time_get <= 1'b1;
            match_msg_tx <= 1'b1;
            match_msg_get <= 1'b1;
            match_msg_clear <= 1'b1;
            match_alarm_set <= 1'b1;
            match_alarm_get <= 1'b1;
            match_sched_set <= 1'b1;
            match_sched_get <= 1'b1;
            match_count_set <= 1'b1;
            match_count_start <= 1'b1;
            match_count_stop <= 1'b1;
            match_count_status <= 1'b1;
            msg_tx_error <= 1'b0;
            msg_tx_error_code <= ERR_BAD_PAYLOAD;
            msg_len_acc <= 7'd0;
            msg_len_digit_count <= 2'd0;
            msg_len_done <= 1'b0;
            msg_text_start <= 9'd0;
            msg_text_key_index <= 3'd0;
            msg_text_key_done <= 1'b0;
            msg_hex_hi_pending <= 1'b0;
            msg_hex_hi_ascii <= 8'h00;
            msg_decoded_count <= 7'd0;
            msg_emit_index <= 7'd0;
            clear_all_match <= 1'b1;
            clear_digit0_valid <= 1'b0;
            clear_digit1_valid <= 1'b0;
            clear_digit0 <= 4'd0;
            clear_digit1 <= 4'd0;
            time_set_error <= 1'b0;
            control_error <= 1'b0;
            seq_ascii <= {"0", "0"};
        end
    endtask

    task set_msg_error;
        input [3:0] err_code;
        begin
            if (!msg_tx_error) begin
                msg_tx_error <= 1'b1;
                msg_tx_error_code <= err_code;
            end
        end
    endtask

    task set_time_error;
        begin
            time_set_error <= 1'b1;
        end
    endtask

    task set_control_error;
        begin
            control_error <= 1'b1;
        end
    endtask

    task set_alarm_digit;
        input [8:0] pos;
        input [7:0] ch;
        begin
            if (!is_digit(ch)) begin
                set_control_error;
            end else begin
                case (pos)
                    9'd18: begin
                        alarm_slot <= ch - "0";
                        if (ch > "7") begin
                            set_control_error;
                        end
                    end
                    9'd25: alarm_hour_ten_bcd <= ch - "0";
                    9'd26: alarm_hour_unit_bcd <= ch - "0";
                    9'd28: alarm_min_ten_bcd <= ch - "0";
                    9'd29: alarm_min_unit_bcd <= ch - "0";
                    9'd31: alarm_sec_ten_bcd <= ch - "0";
                    9'd32: alarm_sec_unit_bcd <= ch - "0";
                    9'd41: begin
                        alarm_enable <= (ch == "1");
                        if ((ch != "0") && (ch != "1")) begin
                            set_control_error;
                        end
                    end
                    default: begin end
                endcase
            end
        end
    endtask

    task set_sched_digit;
        input [8:0] pos;
        input [7:0] ch;
        begin
            if (!is_digit(ch)) begin
                set_control_error;
            end else begin
                case (pos)
                    9'd18: begin
                        sched_slot <= ch - "0";
                        if (ch > "7") begin
                            set_control_error;
                        end
                    end
                    9'd25: sched_hour_ten_bcd <= ch - "0";
                    9'd26: sched_hour_unit_bcd <= ch - "0";
                    9'd28: sched_min_ten_bcd <= ch - "0";
                    9'd29: sched_min_unit_bcd <= ch - "0";
                    9'd31: sched_sec_ten_bcd <= ch - "0";
                    9'd32: sched_sec_unit_bcd <= ch - "0";
                    9'd39: begin
                        sched_type <= ch - "0";
                        if (ch > "7") begin
                            set_control_error;
                        end
                    end
                    9'd47: begin
                        sched_enable <= (ch == "1");
                        if ((ch != "0") && (ch != "1")) begin
                            set_control_error;
                        end
                    end
                    default: begin end
                endcase
            end
        end
    endtask

    task set_count_digit;
        input [8:0] pos;
        input [7:0] ch;
        begin
            if (!is_digit(ch)) begin
                set_control_error;
            end else begin
                case (pos)
                    9'd18: count_hour_ten_bcd <= ch - "0";
                    9'd19: count_hour_unit_bcd <= ch - "0";
                    9'd21: count_min_ten_bcd <= ch - "0";
                    9'd22: count_min_unit_bcd <= ch - "0";
                    9'd24: count_sec_ten_bcd <= ch - "0";
                    9'd25: count_sec_unit_bcd <= ch - "0";
                    default: begin end
                endcase
            end
        end
    endtask

    task set_time_digit;
        input [8:0] pos;
        input [7:0] ch;
        begin
            if (!is_digit(ch)) begin
                set_time_error;
            end else begin
                case (pos)
                    9'd17: time_year_thousand_bcd <= ch - "0";
                    9'd18: time_year_hundred_bcd <= ch - "0";
                    9'd19: time_year_ten_bcd <= ch - "0";
                    9'd20: time_year_unit_bcd <= ch - "0";
                    9'd22: time_month_ten_bcd <= ch - "0";
                    9'd23: time_month_unit_bcd <= ch - "0";
                    9'd25: time_day_ten_bcd <= ch - "0";
                    9'd26: time_day_unit_bcd <= ch - "0";
                    9'd33: time_hour_ten_bcd <= ch - "0";
                    9'd34: time_hour_unit_bcd <= ch - "0";
                    9'd36: time_min_ten_bcd <= ch - "0";
                    9'd37: time_min_unit_bcd <= ch - "0";
                    9'd39: time_sec_ten_bcd <= ch - "0";
                    9'd40: time_sec_unit_bcd <= ch - "0";
                    9'd50: time_weekday <= ch - "0";
                    default: begin end
                endcase
            end
        end
    endtask

    task emit_nack;
        input [3:0] err_code;
        begin
            nack_err <= err_code;
            nack_valid <= 1'b1;
            state <= ST_IDLE;
        end
    endtask

    task parse_msg_tx_body_char;
        input [8:0] pos;
        input [7:0] ch;
        reg [7:0] decoded;
        begin
            if (pos == 9'd10) begin
                if (ch != "t") set_msg_error(ERR_BAD_PAYLOAD);
            end else if (pos == 9'd11) begin
                if (ch != "s") set_msg_error(ERR_BAD_PAYLOAD);
            end else if (pos == 9'd12) begin
                if (ch != "=") set_msg_error(ERR_BAD_PAYLOAD);
            end else if ((pos >= 9'd13) && (pos <= 9'd31)) begin
                msg_timestamp_ascii[(pos - 9'd13) * 8 +: 8] <= ch;
            end else if (pos == 9'd32) begin
                if (ch != ";") set_msg_error(ERR_BAD_PAYLOAD);
            end else if (pos == 9'd33) begin
                if (ch != "l") set_msg_error(ERR_BAD_PAYLOAD);
            end else if (pos == 9'd34) begin
                if (ch != "e") set_msg_error(ERR_BAD_PAYLOAD);
            end else if (pos == 9'd35) begin
                if (ch != "n") set_msg_error(ERR_BAD_PAYLOAD);
            end else if (pos == 9'd36) begin
                if (ch != "=") set_msg_error(ERR_BAD_PAYLOAD);
            end else if (pos >= 9'd37) begin
                if (!msg_len_done) begin
                    if (is_digit(ch) && (msg_len_digit_count < 2'd3)) begin
                        msg_len_acc <= ((msg_len_acc << 3) + (msg_len_acc << 1)) + (ch - "0");
                        msg_len_digit_count <= msg_len_digit_count + 1'b1;
                    end else if ((ch == ";") && (msg_len_digit_count != 2'd0)) begin
                        msg_len_done <= 1'b1;
                        msg_text_start <= pos + 9'd6;
                        msg_text_key_index <= 3'd0;
                    end else begin
                        set_msg_error(ERR_BAD_PAYLOAD);
                    end
                end else if (!msg_text_key_done) begin
                    if (ch == text_key_char(msg_text_key_index)) begin
                        if (msg_text_key_index == 3'd4) begin
                            msg_text_key_done <= 1'b1;
                        end else begin
                            msg_text_key_index <= msg_text_key_index + 1'b1;
                        end
                    end else begin
                        set_msg_error(ERR_BAD_PAYLOAD);
                    end
                end else begin
                    if (!is_hex_char(ch)) begin
                        set_msg_error(ERR_BAD_HEX);
                    end else if (!msg_hex_hi_pending) begin
                        msg_hex_hi_ascii <= ch;
                        msg_hex_hi_pending <= 1'b1;
                    end else begin
                        decoded = hex_pair_byte(msg_hex_hi_ascii, ch);
                        msg_hex_hi_pending <= 1'b0;
                        if (!is_printable_ascii(decoded)) begin
                            set_msg_error(ERR_BAD_HEX);
                        end else if (msg_decoded_count >= 7'd100) begin
                            set_msg_error(ERR_BAD_LEN);
                        end else begin
                            msg_char_buf[msg_decoded_count] <= decoded;
                            msg_decoded_count <= msg_decoded_count + 1'b1;
                        end
                    end
                end
            end
        end
    endtask

    task parse_time_set_body_char;
        input [8:0] pos;
        input [7:0] ch;
        begin
            case (pos)
                9'd12: if (ch != "d") set_time_error;
                9'd13: if (ch != "a") set_time_error;
                9'd14: if (ch != "t") set_time_error;
                9'd15: if (ch != "e") set_time_error;
                9'd16: if (ch != "=") set_time_error;
                9'd17,
                9'd18,
                9'd19,
                9'd20,
                9'd22,
                9'd23,
                9'd25,
                9'd26,
                9'd33,
                9'd34,
                9'd36,
                9'd37,
                9'd39,
                9'd40,
                9'd50: set_time_digit(pos, ch);
                9'd21,
                9'd24: if (ch != "-") set_time_error;
                9'd27,
                9'd41: if (ch != ";") set_time_error;
                9'd28: if (ch != "t") set_time_error;
                9'd29: if (ch != "i") set_time_error;
                9'd30: if (ch != "m") set_time_error;
                9'd31: if (ch != "e") set_time_error;
                9'd32: if (ch != "=") set_time_error;
                9'd35,
                9'd38: if (ch != ":") set_time_error;
                9'd42: if (ch != "w") set_time_error;
                9'd43: if (ch != "e") set_time_error;
                9'd44: if (ch != "e") set_time_error;
                9'd45: if (ch != "k") set_time_error;
                9'd46: if (ch != "d") set_time_error;
                9'd47: if (ch != "a") set_time_error;
                9'd48: if (ch != "y") set_time_error;
                9'd49: if (ch != "=") set_time_error;
                default: begin
                    if (pos > 9'd50) begin
                        set_time_error;
                    end
                end
            endcase
        end
    endtask

    task parse_alarm_set_body_char;
        input [8:0] pos;
        input [7:0] ch;
        begin
            case (pos)
                9'd13: if (ch != "s") set_control_error;
                9'd14: if (ch != "l") set_control_error;
                9'd15: if (ch != "o") set_control_error;
                9'd16: if (ch != "t") set_control_error;
                9'd17: if (ch != "=") set_control_error;
                9'd18,
                9'd25,
                9'd26,
                9'd28,
                9'd29,
                9'd31,
                9'd32,
                9'd41: set_alarm_digit(pos, ch);
                9'd19,
                9'd33: if (ch != ";") set_control_error;
                9'd20: if (ch != "t") set_control_error;
                9'd21: if (ch != "i") set_control_error;
                9'd22: if (ch != "m") set_control_error;
                9'd23: if (ch != "e") set_control_error;
                9'd24: if (ch != "=") set_control_error;
                9'd27,
                9'd30: if (ch != ":") set_control_error;
                9'd34: if (ch != "e") set_control_error;
                9'd35: if (ch != "n") set_control_error;
                9'd36: if (ch != "a") set_control_error;
                9'd37: if (ch != "b") set_control_error;
                9'd38: if (ch != "l") set_control_error;
                9'd39: if (ch != "e") set_control_error;
                9'd40: if (ch != "=") set_control_error;
                default: begin
                    if (pos > 9'd41) begin
                        set_control_error;
                    end
                end
            endcase
        end
    endtask

    task parse_alarm_get_body_char;
        input [8:0] pos;
        input [7:0] ch;
        begin
            case (pos)
                9'd13: if (ch != "s") set_control_error;
                9'd14: if (ch != "l") set_control_error;
                9'd15: if (ch != "o") set_control_error;
                9'd16: if (ch != "t") set_control_error;
                9'd17: if (ch != "=") set_control_error;
                9'd18: set_alarm_digit(pos, ch);
                default: begin
                    if (pos > 9'd18) begin
                        set_control_error;
                    end
                end
            endcase
        end
    endtask

    task parse_sched_set_body_char;
        input [8:0] pos;
        input [7:0] ch;
        begin
            case (pos)
                9'd13: if (ch != "s") set_control_error;
                9'd14: if (ch != "l") set_control_error;
                9'd15: if (ch != "o") set_control_error;
                9'd16: if (ch != "t") set_control_error;
                9'd17: if (ch != "=") set_control_error;
                9'd18,
                9'd25,
                9'd26,
                9'd28,
                9'd29,
                9'd31,
                9'd32,
                9'd39,
                9'd48: set_sched_digit(pos, ch);
                9'd19,
                9'd33,
                9'd40: if (ch != ";") set_control_error;
                9'd20: if (ch != "t") set_control_error;
                9'd21: if (ch != "i") set_control_error;
                9'd22: if (ch != "m") set_control_error;
                9'd23: if (ch != "e") set_control_error;
                9'd24: if (ch != "=") set_control_error;
                9'd27,
                9'd30: if (ch != ":") set_control_error;
                9'd34: if (ch != "t") set_control_error;
                9'd35: if (ch != "y") set_control_error;
                9'd36: if (ch != "p") set_control_error;
                9'd37: if (ch != "e") set_control_error;
                9'd38: if (ch != "=") set_control_error;
                9'd41: if (ch != "e") set_control_error;
                9'd42: if (ch != "n") set_control_error;
                9'd43: if (ch != "a") set_control_error;
                9'd44: if (ch != "b") set_control_error;
                9'd45: if (ch != "l") set_control_error;
                9'd46: if (ch != "e") set_control_error;
                9'd47: if (ch != "=") set_control_error;
                default: begin
                    if (pos > 9'd48) begin
                        set_control_error;
                    end
                end
            endcase
        end
    endtask

    task parse_sched_get_body_char;
        input [8:0] pos;
        input [7:0] ch;
        begin
            case (pos)
                9'd13: if (ch != "s") set_control_error;
                9'd14: if (ch != "l") set_control_error;
                9'd15: if (ch != "o") set_control_error;
                9'd16: if (ch != "t") set_control_error;
                9'd17: if (ch != "=") set_control_error;
                9'd18: set_sched_digit(pos, ch);
                default: begin
                    if (pos > 9'd18) begin
                        set_control_error;
                    end
                end
            endcase
        end
    endtask

    task parse_count_set_body_char;
        input [8:0] pos;
        input [7:0] ch;
        begin
            case (pos)
                9'd13: if (ch != "t") set_control_error;
                9'd14: if (ch != "i") set_control_error;
                9'd15: if (ch != "m") set_control_error;
                9'd16: if (ch != "e") set_control_error;
                9'd18,
                9'd19,
                9'd21,
                9'd22,
                9'd24,
                9'd25: set_count_digit(pos, ch);
                9'd17: if (ch != "=") set_control_error;
                9'd20,
                9'd23: if (ch != ":") set_control_error;
                default: begin
                    if ((pos == 9'd12 && ch != "|") || (pos > 9'd25)) begin
                        set_control_error;
                    end
                end
            endcase
        end
    endtask

    task parse_msg_clear_body_char;
        input [8:0] pos;
        input [7:0] ch;
        begin
            if (pos == 9'd18) begin
                clear_all_match <= (ch == "a");
                if (is_digit(ch)) begin
                    clear_digit0_valid <= 1'b1;
                    clear_digit0 <= ch - "0";
                end
            end else if (pos == 9'd19) begin
                clear_all_match <= clear_all_match && (ch == "l");
                if (is_digit(ch)) begin
                    clear_digit1_valid <= 1'b1;
                    clear_digit1 <= ch - "0";
                end
            end else if (pos == 9'd20) begin
                clear_all_match <= clear_all_match && (ch == "l");
            end
        end
    endtask

    task finish_valid_frame;
        reg [6:0] clear_slot_value;
        begin
            if ((body_len < 9'd4) || !match_hello && !match_ping && !match_status_get &&
                !match_time_set && !match_time_get &&
                !match_msg_tx && !match_msg_get && !match_msg_clear &&
                !match_alarm_set && !match_alarm_get &&
                !match_sched_set && !match_sched_get &&
                !match_count_set && !match_count_start &&
                !match_count_stop && !match_count_status) begin
                emit_nack(ERR_UNSUPPORTED);
            end else if (match_hello && (body_len >= 9'd9)) begin
                cmd_hello_valid <= 1'b1;
                state <= ST_IDLE;
            end else if (match_ping && (body_len >= 9'd8)) begin
                cmd_ping_valid <= 1'b1;
                state <= ST_IDLE;
            end else if (match_status_get && (body_len >= 9'd14)) begin
                cmd_status_get_valid <= 1'b1;
                state <= ST_IDLE;
            end else if (match_time_set && (body_len >= 9'd12)) begin
                if ((body_len != 9'd51) || time_set_error || !valid_time_set_values(1'b1)) begin
                    emit_nack(ERR_BAD_TIME);
                end else begin
                    cmd_time_set_valid <= 1'b1;
                    state <= ST_IDLE;
                end
            end else if (match_time_get && (body_len == 9'd12)) begin
                cmd_time_get_valid <= 1'b1;
                state <= ST_IDLE;
            end else if (match_msg_tx && (body_len >= 9'd44)) begin
                if (msg_tx_error) begin
                    emit_nack(msg_tx_error_code);
                end else if (!msg_len_done || !msg_text_key_done) begin
                    emit_nack(ERR_BAD_PAYLOAD);
                end else if (msg_hex_hi_pending) begin
                    emit_nack(ERR_BAD_HEX);
                end else if ((msg_len_acc > 7'd100) ||
                             (msg_decoded_count != msg_len_acc) ||
                             (body_len != msg_text_start + ({2'b00, msg_len_acc} << 1))) begin
                    emit_nack(ERR_BAD_LEN);
                end else begin
                    msg_len <= msg_len_acc;
                    msg_emit_index <= 7'd0;
                    msg_begin_valid <= 1'b1;
                    state <= ST_EMIT;
                end
            end else if (match_msg_get && (body_len >= 9'd17)) begin
                emit_nack(ERR_UNSUPPORTED);
            end else if (match_msg_clear && (body_len >= 9'd19)) begin
                if ((body_len == 9'd21) && clear_all_match) begin
                    msg_clear_all <= 1'b1;
                    msg_clear_slot <= 4'd0;
                    cmd_msg_clear_valid <= 1'b1;
                    state <= ST_IDLE;
                end else if ((body_len == 9'd19) && clear_digit0_valid) begin
                    msg_clear_all <= 1'b0;
                    msg_clear_slot <= clear_digit0;
                    cmd_msg_clear_valid <= 1'b1;
                    state <= ST_IDLE;
                end else if ((body_len == 9'd20) && clear_digit0_valid && clear_digit1_valid) begin
                    clear_slot_value = ({3'd0, clear_digit0} * 7'd10) + {3'd0, clear_digit1};
                    if (clear_slot_value <= 7'd15) begin
                        msg_clear_all <= 1'b0;
                        msg_clear_slot <= clear_slot_value[3:0];
                        cmd_msg_clear_valid <= 1'b1;
                        state <= ST_IDLE;
                    end else begin
                        emit_nack(ERR_BAD_SLOT);
                    end
                end else begin
                    emit_nack(ERR_BAD_SLOT);
                end
            end else begin
                if (match_alarm_set && (body_len == 9'd42)) begin
                    if (control_error || (alarm_slot > 3'd7)) begin
                        emit_nack(ERR_BAD_SLOT);
                    end else if (!valid_hms_values(alarm_hour_ten_bcd, alarm_hour_unit_bcd,
                                                   alarm_min_ten_bcd, alarm_min_unit_bcd,
                                                   alarm_sec_ten_bcd, alarm_sec_unit_bcd)) begin
                        emit_nack(ERR_BAD_TIME);
                    end else begin
                        cmd_alarm_set_valid <= 1'b1;
                        state <= ST_IDLE;
                    end
                end else if (match_alarm_get && (body_len == 9'd19)) begin
                    if (control_error || (alarm_slot > 3'd7)) begin
                        emit_nack(ERR_BAD_SLOT);
                    end else begin
                        cmd_alarm_get_valid <= 1'b1;
                        state <= ST_IDLE;
                    end
                end else if (match_sched_set && (body_len == 9'd49)) begin
                    if (control_error || (sched_slot > 3'd7)) begin
                        emit_nack(ERR_BAD_SLOT);
                    end else if (sched_type > 3'd7) begin
                        emit_nack(ERR_BAD_PAYLOAD);
                    end else if (!valid_hms_values(sched_hour_ten_bcd, sched_hour_unit_bcd,
                                                   sched_min_ten_bcd, sched_min_unit_bcd,
                                                   sched_sec_ten_bcd, sched_sec_unit_bcd)) begin
                        emit_nack(ERR_BAD_TIME);
                    end else begin
                        cmd_sched_set_valid <= 1'b1;
                        state <= ST_IDLE;
                    end
                end else if (match_sched_get && (body_len == 9'd19)) begin
                    if (control_error || (sched_slot > 3'd7)) begin
                        emit_nack(ERR_BAD_SLOT);
                    end else begin
                        cmd_sched_get_valid <= 1'b1;
                        state <= ST_IDLE;
                    end
                end else if (match_count_set && (body_len == 9'd26)) begin
                    if (control_error || !valid_hms_values(count_hour_ten_bcd, count_hour_unit_bcd,
                                                           count_min_ten_bcd, count_min_unit_bcd,
                                                           count_sec_ten_bcd, count_sec_unit_bcd)) begin
                        emit_nack(ERR_BAD_TIME);
                    end else begin
                        cmd_count_set_valid <= 1'b1;
                        state <= ST_IDLE;
                    end
                end else if (match_count_start && (body_len == 9'd15)) begin
                    cmd_count_start_valid <= 1'b1;
                    state <= ST_IDLE;
                end else if (match_count_stop && (body_len == 9'd14)) begin
                    cmd_count_stop_valid <= 1'b1;
                    state <= ST_IDLE;
                end else if (match_count_status && (body_len == 9'd16)) begin
                    cmd_count_status_valid <= 1'b1;
                    state <= ST_IDLE;
                end else begin
                    emit_nack(ERR_UNSUPPORTED);
                end
            end
        end
    endtask

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= ST_IDLE;
            body_len <= 9'd0;
            calc_xor <= 8'd0;
            cs_hi_ascii <= 8'd0;
            cs_lo_ascii <= 8'd0;
            drop_overflow <= 1'b0;
            drop_bad_frame <= 1'b0;
            match_hello <= 1'b1;
            match_ping <= 1'b1;
            match_status_get <= 1'b1;
            match_time_set <= 1'b1;
            match_time_get <= 1'b1;
            match_msg_tx <= 1'b1;
            match_msg_get <= 1'b1;
            match_msg_clear <= 1'b1;
            match_alarm_set <= 1'b1;
            match_alarm_get <= 1'b1;
            match_sched_set <= 1'b1;
            match_sched_get <= 1'b1;
            match_count_set <= 1'b1;
            match_count_start <= 1'b1;
            match_count_stop <= 1'b1;
            match_count_status <= 1'b1;
            time_set_error <= 1'b0;
            control_error <= 1'b0;
            msg_tx_error <= 1'b0;
            msg_tx_error_code <= ERR_BAD_PAYLOAD;
            msg_len_acc <= 7'd0;
            msg_len_digit_count <= 2'd0;
            msg_len_done <= 1'b0;
            msg_text_start <= 9'd0;
            msg_text_key_index <= 3'd0;
            msg_text_key_done <= 1'b0;
            msg_hex_hi_pending <= 1'b0;
            msg_hex_hi_ascii <= 8'h00;
            msg_decoded_count <= 7'd0;
            msg_emit_index <= 7'd0;
            clear_all_match <= 1'b1;
            clear_digit0_valid <= 1'b0;
            clear_digit1_valid <= 1'b0;
            clear_digit0 <= 4'd0;
            clear_digit1 <= 4'd0;
            cmd_hello_valid <= 1'b0;
            cmd_ping_valid <= 1'b0;
            cmd_status_get_valid <= 1'b0;
            cmd_time_set_valid <= 1'b0;
            cmd_time_get_valid <= 1'b0;
            cmd_alarm_set_valid <= 1'b0;
            cmd_alarm_get_valid <= 1'b0;
            cmd_sched_set_valid <= 1'b0;
            cmd_sched_get_valid <= 1'b0;
            cmd_count_set_valid <= 1'b0;
            cmd_count_start_valid <= 1'b0;
            cmd_count_stop_valid <= 1'b0;
            cmd_count_status_valid <= 1'b0;
            time_year_thousand_bcd <= 4'd2;
            time_year_hundred_bcd <= 4'd0;
            time_year_ten_bcd <= 4'd2;
            time_year_unit_bcd <= 4'd6;
            time_month_ten_bcd <= 4'd0;
            time_month_unit_bcd <= 4'd1;
            time_day_ten_bcd <= 4'd0;
            time_day_unit_bcd <= 4'd1;
            time_hour_ten_bcd <= 4'd0;
            time_hour_unit_bcd <= 4'd0;
            time_min_ten_bcd <= 4'd0;
            time_min_unit_bcd <= 4'd0;
            time_sec_ten_bcd <= 4'd0;
            time_sec_unit_bcd <= 4'd0;
            time_weekday <= 3'd1;
            alarm_slot <= 3'd0;
            alarm_hour_ten_bcd <= 4'd0;
            alarm_hour_unit_bcd <= 4'd0;
            alarm_min_ten_bcd <= 4'd0;
            alarm_min_unit_bcd <= 4'd0;
            alarm_sec_ten_bcd <= 4'd0;
            alarm_sec_unit_bcd <= 4'd0;
            alarm_enable <= 1'b0;
            sched_slot <= 3'd0;
            sched_hour_ten_bcd <= 4'd0;
            sched_hour_unit_bcd <= 4'd0;
            sched_min_ten_bcd <= 4'd0;
            sched_min_unit_bcd <= 4'd0;
            sched_sec_ten_bcd <= 4'd0;
            sched_sec_unit_bcd <= 4'd0;
            sched_type <= 3'd0;
            sched_enable <= 1'b0;
            count_hour_ten_bcd <= 4'd0;
            count_hour_unit_bcd <= 4'd0;
            count_min_ten_bcd <= 4'd0;
            count_min_unit_bcd <= 4'd0;
            count_sec_ten_bcd <= 4'd0;
            count_sec_unit_bcd <= 4'd0;
            msg_begin_valid <= 1'b0;
            cmd_msg_tx_valid <= 1'b0;
            msg_timestamp_ascii <= {19{8'h20}};
            msg_len <= 7'd0;
            msg_char_valid <= 1'b0;
            msg_char_index <= 7'd0;
            msg_char_ascii <= 8'h20;
            cmd_msg_get_valid <= 1'b0;
            msg_get_slot <= 4'd0;
            cmd_msg_clear_valid <= 1'b0;
            msg_clear_all <= 1'b0;
            msg_clear_slot <= 4'd0;
            nack_valid <= 1'b0;
            nack_err <= ERR_BAD_FRAME;
            seq_ascii <= {"0", "0"};
        end else begin
            cmd_hello_valid <= 1'b0;
            cmd_ping_valid <= 1'b0;
            cmd_status_get_valid <= 1'b0;
            cmd_time_set_valid <= 1'b0;
            cmd_time_get_valid <= 1'b0;
            cmd_alarm_set_valid <= 1'b0;
            cmd_alarm_get_valid <= 1'b0;
            cmd_sched_set_valid <= 1'b0;
            cmd_sched_get_valid <= 1'b0;
            cmd_count_set_valid <= 1'b0;
            cmd_count_start_valid <= 1'b0;
            cmd_count_stop_valid <= 1'b0;
            cmd_count_status_valid <= 1'b0;
            msg_begin_valid <= 1'b0;
            cmd_msg_tx_valid <= 1'b0;
            msg_char_valid <= 1'b0;
            cmd_msg_get_valid <= 1'b0;
            cmd_msg_clear_valid <= 1'b0;
            msg_clear_all <= 1'b0;
            nack_valid <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (rx_valid && (rx_data == "#")) begin
                        reset_frame_state;
                        state <= ST_BODY;
                    end
                end

                ST_BODY: begin
                    if (rx_valid) begin
                        if (rx_data == "#") begin
                            reset_frame_state;
                        end else if (rx_data == "*") begin
                            state <= ST_CS_HI;
                        end else if (!is_printable_ascii(rx_data)) begin
                            drop_bad_frame <= 1'b1;
                            state <= ST_DROP;
                        end else if (body_len >= MAX_BODY) begin
                            drop_overflow <= 1'b1;
                            state <= ST_DROP;
                        end else begin
                            if (body_len == 9'd0) begin
                                seq_ascii[15:8] <= rx_data;
                            end else if (body_len == 9'd1) begin
                                seq_ascii[7:0] <= rx_data;
                            end

                            match_hello <= match_hello && prefix_ok(CMD_HELLO, body_len, rx_data);
                            match_ping <= match_ping && prefix_ok(CMD_PING, body_len, rx_data);
                            match_status_get <= match_status_get && prefix_ok(CMD_STATUS_GET, body_len, rx_data);
                            match_time_set <= match_time_set && prefix_ok(CMD_TIME_SET, body_len, rx_data);
                            match_time_get <= match_time_get && prefix_ok(CMD_TIME_GET, body_len, rx_data);
                            match_msg_tx <= match_msg_tx && prefix_ok(CMD_MSG_TX, body_len, rx_data);
                            match_msg_get <= match_msg_get && prefix_ok(CMD_MSG_GET, body_len, rx_data);
                            match_msg_clear <= match_msg_clear && prefix_ok(CMD_MSG_CLEAR, body_len, rx_data);
                            match_alarm_set <= match_alarm_set && prefix_ok(CMD_ALARM_SET, body_len, rx_data);
                            match_alarm_get <= match_alarm_get && prefix_ok(CMD_ALARM_GET, body_len, rx_data);
                            match_sched_set <= match_sched_set && prefix_ok(CMD_SCHED_SET, body_len, rx_data);
                            match_sched_get <= match_sched_get && prefix_ok(CMD_SCHED_GET, body_len, rx_data);
                            match_count_set <= match_count_set && prefix_ok(CMD_COUNT_SET, body_len, rx_data);
                            match_count_start <= match_count_start && prefix_ok(CMD_COUNT_START, body_len, rx_data);
                            match_count_stop <= match_count_stop && prefix_ok(CMD_COUNT_STOP, body_len, rx_data);
                            match_count_status <= match_count_status && prefix_ok(CMD_COUNT_STATUS, body_len, rx_data);

                            if (match_time_set) begin
                                parse_time_set_body_char(body_len, rx_data);
                            end
                            if (match_msg_tx) begin
                                parse_msg_tx_body_char(body_len, rx_data);
                            end
                            if (match_msg_clear) begin
                                parse_msg_clear_body_char(body_len, rx_data);
                            end
                            if (match_alarm_set) begin
                                parse_alarm_set_body_char(body_len, rx_data);
                            end
                            if (match_alarm_get) begin
                                parse_alarm_get_body_char(body_len, rx_data);
                            end
                            if (match_sched_set) begin
                                parse_sched_set_body_char(body_len, rx_data);
                            end
                            if (match_sched_get) begin
                                parse_sched_get_body_char(body_len, rx_data);
                            end
                            if (match_count_set) begin
                                parse_count_set_body_char(body_len, rx_data);
                            end

                            calc_xor <= calc_xor ^ rx_data;
                            body_len <= body_len + 1'b1;
                        end
                    end
                end

                ST_CS_HI: begin
                    if (rx_valid) begin
                        cs_hi_ascii <= rx_data;
                        state <= ST_CS_LO;
                    end
                end

                ST_CS_LO: begin
                    if (rx_valid) begin
                        cs_lo_ascii <= rx_data;
                        state <= ST_EOL;
                    end
                end

                ST_EOL: begin
                    if (rx_valid) begin
                        if (rx_data != 8'h0A) begin
                            drop_bad_frame <= 1'b1;
                            state <= ST_DROP;
                        end else if (!is_hex_char(cs_hi_ascii) || !is_hex_char(cs_lo_ascii) ||
                                     ({hex_nibble(cs_hi_ascii), hex_nibble(cs_lo_ascii)} != calc_xor)) begin
                            emit_nack(ERR_BAD_CHECKSUM);
                        end else begin
                            finish_valid_frame;
                        end
                    end
                end

                ST_DROP: begin
                    if (rx_valid) begin
                        if (rx_data == "#") begin
                            reset_frame_state;
                            state <= ST_BODY;
                        end else if (rx_data == 8'h0A) begin
                            if (drop_overflow) begin
                                emit_nack(ERR_RX_OVERFLOW);
                            end else if (drop_bad_frame) begin
                                emit_nack(ERR_BAD_FRAME);
                            end else begin
                                state <= ST_IDLE;
                            end
                        end
                    end
                end

                ST_EMIT: begin
                    if (msg_emit_index < msg_len) begin
                        msg_char_valid <= 1'b1;
                        msg_char_index <= msg_emit_index;
                        msg_char_ascii <= msg_char_buf[msg_emit_index];
                        msg_emit_index <= msg_emit_index + 1'b1;
                    end else begin
                        cmd_msg_tx_valid <= 1'b1;
                        state <= ST_IDLE;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule
