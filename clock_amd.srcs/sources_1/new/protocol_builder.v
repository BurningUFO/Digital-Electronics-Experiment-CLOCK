`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// ClockLink 协议回复帧构造器。
//
// 输入为 comm_ctrl 锁存好的响应类型和业务字段，输出为 uart_tx 可消费的
// tx_start/tx_data 字节流。帧格式固定为：
//   #SEQ|CMD|PAYLOAD*CS\n
//
// 资源/时序约束：
// - 帧长限制为 MAX_FRAME，当前业务回复都短于该长度。
// - 构帧按响应类型拆成多个 ST_BUILD_xxx 状态，避免一个周期拼接过多字符。
// - tx_buf 是短帧缓冲；发送阶段只按 send_index 顺序取字节。
// -----------------------------------------------------------------------------
module protocol_builder #(
    parameter integer MAX_FRAME = 128
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [3:0]  response_kind,
    input  wire [15:0] seq_ascii,
    input  wire [3:0]  ack_cmd_kind,
    input  wire [3:0]  nack_err_kind,
    input  wire [2:0]  mode_state,
    input  wire [2:0]  comm_status,
    input  wire        countdown_run,
    input  wire [4:0]  message_count,
    input  wire [4:0]  unread_count,
    input  wire [3:0]  reply_slot,
    input  wire [2:0]  reply_index,
    input  wire [151:0] reply_timestamp_ascii,
    input  wire [159:0] reply_text_ascii,
    input  wire [5:0]   reply_text_len,
    input  wire [3:0]   time_year_thousand_bcd,
    input  wire [3:0]   time_year_hundred_bcd,
    input  wire [3:0]   time_year_ten_bcd,
    input  wire [3:0]   time_year_unit_bcd,
    input  wire [3:0]   time_month_ten_bcd,
    input  wire [3:0]   time_month_unit_bcd,
    input  wire [3:0]   time_day_ten_bcd,
    input  wire [3:0]   time_day_unit_bcd,
    input  wire [3:0]   time_hour_ten_bcd,
    input  wire [3:0]   time_hour_unit_bcd,
    input  wire [3:0]   time_min_ten_bcd,
    input  wire [3:0]   time_min_unit_bcd,
    input  wire [3:0]   time_sec_ten_bcd,
    input  wire [3:0]   time_sec_unit_bcd,
    input  wire [2:0]   time_weekday,
    input  wire [2:0]   alarm_slot,
    input  wire [3:0]   alarm_hour_ten_bcd,
    input  wire [3:0]   alarm_hour_unit_bcd,
    input  wire [3:0]   alarm_min_ten_bcd,
    input  wire [3:0]   alarm_min_unit_bcd,
    input  wire [3:0]   alarm_sec_ten_bcd,
    input  wire [3:0]   alarm_sec_unit_bcd,
    input  wire         alarm_enable,
    input  wire [2:0]   sched_slot,
    input  wire [3:0]   sched_hour_ten_bcd,
    input  wire [3:0]   sched_hour_unit_bcd,
    input  wire [3:0]   sched_min_ten_bcd,
    input  wire [3:0]   sched_min_unit_bcd,
    input  wire [3:0]   sched_sec_ten_bcd,
    input  wire [3:0]   sched_sec_unit_bcd,
    input  wire [2:0]   sched_type,
    input  wire         sched_enable,
    input  wire [3:0]   count_hour_ten_bcd,
    input  wire [3:0]   count_hour_unit_bcd,
    input  wire [3:0]   count_min_ten_bcd,
    input  wire [3:0]   count_min_unit_bcd,
    input  wire [3:0]   count_sec_ten_bcd,
    input  wire [3:0]   count_sec_unit_bcd,
    input  wire        tx_busy,
    output reg         tx_start,
    output reg [7:0]   tx_data,
    output wire        busy,
    output reg         done
);
    localparam [3:0] RESP_ACK          = 4'd0;
    localparam [3:0] RESP_PONG         = 4'd1;
    localparam [3:0] RESP_STATUS       = 4'd2;
    localparam [3:0] RESP_MSG_STORED   = 4'd3;
    localparam [3:0] RESP_REPLY        = 4'd4;
    localparam [3:0] RESP_NACK         = 4'd5;
    localparam [3:0] RESP_TIME         = 4'd6;
    localparam [3:0] RESP_ALARM        = 4'd7;
    localparam [3:0] RESP_SCHED        = 4'd8;
    localparam [3:0] RESP_COUNT_STATUS = 4'd9;

    localparam [3:0] ACK_HELLO     = 4'd0;
    localparam [3:0] ACK_MSG_CLEAR = 4'd1;
    localparam [3:0] ACK_TIME_SET  = 4'd2;
    localparam [3:0] ACK_ALARM_SET = 4'd3;
    localparam [3:0] ACK_SCHED_SET = 4'd4;
    localparam [3:0] ACK_COUNT_SET = 4'd5;
    localparam [3:0] ACK_COUNT_START = 4'd6;
    localparam [3:0] ACK_COUNT_STOP = 4'd7;

    localparam [3:0] ERR_BAD_FRAME    = 4'd0;
    localparam [3:0] ERR_BAD_CHECKSUM = 4'd1;
    localparam [3:0] ERR_UNKNOWN_CMD  = 4'd2;
    localparam [3:0] ERR_BAD_PAYLOAD  = 4'd3;
    localparam [3:0] ERR_BAD_LEN      = 4'd4;
    localparam [3:0] ERR_BAD_HEX      = 4'd5;
    localparam [3:0] ERR_BAD_SLOT     = 4'd6;
    localparam [3:0] ERR_UNSUPPORTED  = 4'd7;
    localparam [3:0] ERR_RX_OVERFLOW  = 4'd8;
    localparam [3:0] ERR_TX_BUSY      = 4'd9;
    localparam [3:0] ERR_BAD_TIME     = 4'd10;

    localparam [3:0] ST_IDLE               = 4'd0;
    localparam [3:0] ST_BUILD_ACK          = 4'd1;
    localparam [3:0] ST_BUILD_PONG         = 4'd2;
    localparam [3:0] ST_BUILD_STATUS       = 4'd3;
    localparam [3:0] ST_BUILD_MSG_STORED   = 4'd4;
    localparam [3:0] ST_BUILD_REPLY        = 4'd5;
    localparam [3:0] ST_BUILD_NACK         = 4'd6;
    localparam [3:0] ST_BUILD_TIME         = 4'd7;
    localparam [3:0] ST_BUILD_ALARM        = 4'd8;
    localparam [3:0] ST_BUILD_SCHED        = 4'd9;
    localparam [3:0] ST_BUILD_COUNT_STATUS = 4'd10;
    localparam [3:0] ST_SEND               = 4'd11;
    localparam [3:0] ST_WAIT_BUSY          = 4'd12;
    localparam [3:0] ST_WAIT_DONE          = 4'd13;

    reg [3:0] state;
    reg [8:0] tx_len;
    reg [8:0] send_index;
    reg [7:0] tx_buf [0:MAX_FRAME-1];
    reg [8:0] build_len;
    reg [7:0] build_cs;
    reg [15:0] req_seq_ascii;
    reg [3:0] req_ack_cmd_kind;
    reg [3:0] req_nack_err_kind;
    reg [2:0] req_mode_state;
    reg [2:0] req_comm_status;
    reg req_countdown_run;
    reg [4:0] req_message_count;
    reg [4:0] req_unread_count;
    reg [3:0] req_reply_slot;
    reg [2:0] req_reply_index;
    reg [151:0] req_reply_timestamp_ascii;
    reg [159:0] req_reply_text_ascii;
    reg [5:0] req_reply_text_len;
    reg [3:0] req_time_year_thousand_bcd;
    reg [3:0] req_time_year_hundred_bcd;
    reg [3:0] req_time_year_ten_bcd;
    reg [3:0] req_time_year_unit_bcd;
    reg [3:0] req_time_month_ten_bcd;
    reg [3:0] req_time_month_unit_bcd;
    reg [3:0] req_time_day_ten_bcd;
    reg [3:0] req_time_day_unit_bcd;
    reg [3:0] req_time_hour_ten_bcd;
    reg [3:0] req_time_hour_unit_bcd;
    reg [3:0] req_time_min_ten_bcd;
    reg [3:0] req_time_min_unit_bcd;
    reg [3:0] req_time_sec_ten_bcd;
    reg [3:0] req_time_sec_unit_bcd;
    reg [2:0] req_time_weekday;
    reg [2:0] req_alarm_slot;
    reg [3:0] req_alarm_hour_ten_bcd;
    reg [3:0] req_alarm_hour_unit_bcd;
    reg [3:0] req_alarm_min_ten_bcd;
    reg [3:0] req_alarm_min_unit_bcd;
    reg [3:0] req_alarm_sec_ten_bcd;
    reg [3:0] req_alarm_sec_unit_bcd;
    reg req_alarm_enable;
    reg [2:0] req_sched_slot;
    reg [3:0] req_sched_hour_ten_bcd;
    reg [3:0] req_sched_hour_unit_bcd;
    reg [3:0] req_sched_min_ten_bcd;
    reg [3:0] req_sched_min_unit_bcd;
    reg [3:0] req_sched_sec_ten_bcd;
    reg [3:0] req_sched_sec_unit_bcd;
    reg [2:0] req_sched_type;
    reg req_sched_enable;
    reg [3:0] req_count_hour_ten_bcd;
    reg [3:0] req_count_hour_unit_bcd;
    reg [3:0] req_count_min_ten_bcd;
    reg [3:0] req_count_min_unit_bcd;
    reg [3:0] req_count_sec_ten_bcd;
    reg [3:0] req_count_sec_unit_bcd;

    assign busy = (state != ST_IDLE);

    function [7:0] hex_char;
        input [3:0] value;
        begin
            if (value < 4'd10) begin
                hex_char = "0" + value;
            end else begin
                hex_char = "A" + (value - 4'd10);
            end
        end
    endfunction

    // append_raw 写入不参与校验的字符，如 #、*、校验 HEX 和换行。
    task append_raw;
        input [7:0] ch;
        begin
            tx_buf[build_len] = ch;
            build_len = build_len + 1'b1;
        end
    endtask

    // append_body 写入 BODY 字符，同时累计 XOR 校验。
    task append_body;
        input [7:0] ch;
        begin
            tx_buf[build_len] = ch;
            build_len = build_len + 1'b1;
            build_cs = build_cs ^ ch;
        end
    endtask

    task append_text3;
        input [23:0] text;
        begin
            append_body(text[23:16]);
            append_body(text[15:8]);
            append_body(text[7:0]);
        end
    endtask

    task append_text4;
        input [31:0] text;
        begin
            append_body(text[31:24]);
            append_body(text[23:16]);
            append_body(text[15:8]);
            append_body(text[7:0]);
        end
    endtask

    task append_text5;
        input [39:0] text;
        begin
            append_body(text[39:32]);
            append_body(text[31:24]);
            append_body(text[23:16]);
            append_body(text[15:8]);
            append_body(text[7:0]);
        end
    endtask

    task append_text6;
        input [47:0] text;
        begin
            append_body(text[47:40]);
            append_body(text[39:32]);
            append_body(text[31:24]);
            append_body(text[23:16]);
            append_body(text[15:8]);
            append_body(text[7:0]);
        end
    endtask

    task append_text7;
        input [55:0] text;
        begin
            append_body(text[55:48]);
            append_body(text[47:40]);
            append_body(text[39:32]);
            append_body(text[31:24]);
            append_body(text[23:16]);
            append_body(text[15:8]);
            append_body(text[7:0]);
        end
    endtask

    task append_text8;
        input [63:0] text;
        begin
            append_body(text[63:56]);
            append_body(text[55:48]);
            append_body(text[47:40]);
            append_body(text[39:32]);
            append_body(text[31:24]);
            append_body(text[23:16]);
            append_body(text[15:8]);
            append_body(text[7:0]);
        end
    endtask

    task append_text10;
        input [79:0] text;
        begin
            append_body(text[79:72]);
            append_body(text[71:64]);
            append_body(text[63:56]);
            append_body(text[55:48]);
            append_body(text[47:40]);
            append_body(text[39:32]);
            append_body(text[31:24]);
            append_body(text[23:16]);
            append_body(text[15:8]);
            append_body(text[7:0]);
        end
    endtask

    task append_dec;
        input [7:0] value;
        reg [7:0] hundreds;
        reg [7:0] tens;
        reg [7:0] ones;
        begin
            hundreds = value / 8'd100;
            tens = (value % 8'd100) / 8'd10;
            ones = value % 8'd10;
            if (hundreds != 8'd0) begin
                append_body("0" + hundreds);
                append_body("0" + tens);
                append_body("0" + ones);
            end else if (tens != 8'd0) begin
                append_body("0" + tens);
                append_body("0" + ones);
            end else begin
                append_body("0" + ones);
            end
        end
    endtask

    task append_digit_0_9;
        input [3:0] value;
        begin
            append_body("0" + {4'd0, value});
        end
    endtask

    task append_slot_value;
        begin
            if (req_reply_slot >= 4'd10) begin
                append_body("1");
                append_digit_0_9(req_reply_slot - 4'd10);
            end else begin
                append_digit_0_9(req_reply_slot);
            end
        end
    endtask

    task append_mode_value;
        begin
            case (req_mode_state)
                3'b000: append_text5({"C","L","O","C","K"});
                3'b001: append_text4({"T","I","M","E"});
                3'b010: append_text5({"A","L","A","R","M"});
                3'b011: append_text4({"H","O","U","R"});
                3'b100: append_text5({"C","O","U","N","T"});
                3'b101: append_text5({"S","C","H","E","D"});
                default: append_text4({"C","O","M","M"});
            endcase
        end
    endtask

    task append_conn_value;
        begin
            case (req_comm_status)
                3'd1: append_text4({"W","A","I","T"});
                3'd2: append_text4({"C","O","N","N"});
                3'd3: append_text3({"M","S","G"});
                3'd4: append_text3({"E","R","R"});
                default: append_text4({"D","I","S","C"});
            endcase
        end
    endtask

    task append_ack_cmd_value;
        begin
            case (req_ack_cmd_kind)
                ACK_MSG_CLEAR: append_text9_msg_clear;
                ACK_TIME_SET: append_text8_time_set;
                ACK_ALARM_SET: append_text9_alarm_set;
                ACK_SCHED_SET: append_text9_sched_set;
                ACK_COUNT_SET: append_text9_count_set;
                ACK_COUNT_START: append_text11_count_start;
                ACK_COUNT_STOP: append_text10_count_stop;
                default: append_text5({"H","E","L","L","O"});
            endcase
        end
    endtask

    task append_text8_time_set;
        begin
            append_text4({"T","I","M","E"});
            append_body("_");
            append_text3({"S","E","T"});
        end
    endtask

    task append_text9_msg_clear;
        begin
            append_text3({"M","S","G"});
            append_body("_");
            append_text5({"C","L","E","A","R"});
        end
    endtask

    task append_text9_alarm_set;
        begin
            append_text5({"A","L","A","R","M"});
            append_body("_");
            append_text3({"S","E","T"});
        end
    endtask

    task append_text9_sched_set;
        begin
            append_text5({"S","C","H","E","D"});
            append_body("_");
            append_text3({"S","E","T"});
        end
    endtask

    task append_text9_count_set;
        begin
            append_text5({"C","O","U","N","T"});
            append_body("_");
            append_text3({"S","E","T"});
        end
    endtask

    task append_text11_count_start;
        begin
            append_text5({"C","O","U","N","T"});
            append_body("_");
            append_text5({"S","T","A","R","T"});
        end
    endtask

    task append_text10_count_stop;
        begin
            append_text5({"C","O","U","N","T"});
            append_body("_");
            append_text4({"S","T","O","P"});
        end
    endtask

    task append_error_value;
        begin
            case (req_nack_err_kind)
                ERR_BAD_CHECKSUM: begin append_text3({"B","A","D"}); append_body("_"); append_text8_checksum; end
                ERR_UNKNOWN_CMD:  begin append_text7({"U","N","K","N","O","W","N"}); append_body("_"); append_text3({"C","M","D"}); end
                ERR_BAD_PAYLOAD:  begin append_text3({"B","A","D"}); append_body("_"); append_text7({"P","A","Y","L","O","A","D"}); end
                ERR_BAD_LEN:      begin append_text3({"B","A","D"}); append_body("_"); append_text3({"L","E","N"}); end
                ERR_BAD_HEX:      begin append_text3({"B","A","D"}); append_body("_"); append_text3({"H","E","X"}); end
                ERR_BAD_SLOT:     begin append_text3({"B","A","D"}); append_body("_"); append_text4({"S","L","O","T"}); end
                ERR_UNSUPPORTED:  begin append_text11_unsupported; end
                ERR_RX_OVERFLOW:  begin append_text2_rx; append_body("_"); append_text8_overflow; end
                ERR_TX_BUSY:      begin append_text2_tx; append_body("_"); append_text4({"B","U","S","Y"}); end
                ERR_BAD_TIME:     begin append_text3({"B","A","D"}); append_body("_"); append_text4({"T","I","M","E"}); end
                default:          begin append_text3({"B","A","D"}); append_body("_"); append_text5({"F","R","A","M","E"}); end
            endcase
        end
    endtask

    task append_text2_rx;
        begin
            append_body("R");
            append_body("X");
        end
    endtask

    task append_text2_tx;
        begin
            append_body("T");
            append_body("X");
        end
    endtask

    task append_text8_checksum;
        begin
            append_text5({"C","H","E","C","K"});
            append_text3({"S","U","M"});
        end
    endtask

    task append_text8_overflow;
        begin
            append_text4({"O","V","E","R"});
            append_text4({"F","L","O","W"});
        end
    endtask

    task append_text11_unsupported;
        begin
            append_text6({"U","N","S","U","P","P"});
            append_text5({"O","R","T","E","D"});
        end
    endtask

    task append_payload_ack;
        begin
            append_text4({"a","c","k","="});
            append_body(req_seq_ascii[15:8]);
            append_body(req_seq_ascii[7:0]);
            append_text5({";","c","m","d","="});
            append_ack_cmd_value;
        end
    endtask

    task append_payload_status;
        begin
            append_text5({"m","o","d","e","="});
            append_mode_value;
            append_text6({";","c","o","n","n","="});
            append_conn_value;
            append_text8_unread_key;
            append_dec({3'd0, req_unread_count});
            append_text11_count_run_key;
            append_body(req_countdown_run ? "1" : "0");
        end
    endtask

    task append_payload_msg_stored;
        begin
            append_text7({"s","l","o","t","=","0",";"});
            append_text6({"c","o","u","n","t","="});
            append_dec({3'd0, req_message_count});
            append_text8_unread_key;
            append_dec({3'd0, req_unread_count});
        end
    endtask

    task append_payload_reply;
        begin
            append_text5({"s","l","o","t","="});
            append_slot_value;
            append_text7({";","r","e","p","l","y","="});
            append_digit_0_9({1'b0, req_reply_index});
            append_text4({";","t","s","="});
            append_timestamp_value;
            append_text6({";","t","e","x","t","="});
            append_reply_text_hex;
        end
    endtask

    task append_payload_nack;
        begin
            append_text4({"a","c","k","="});
            append_body(req_seq_ascii[15:8]);
            append_body(req_seq_ascii[7:0]);
            append_text5({";","e","r","r","="});
            append_error_value;
        end
    endtask

    task append_hms;
        input [3:0] hour_ten;
        input [3:0] hour_unit;
        input [3:0] min_ten;
        input [3:0] min_unit;
        input [3:0] sec_ten;
        input [3:0] sec_unit;
        begin
            append_digit_0_9(hour_ten);
            append_digit_0_9(hour_unit);
            append_body(":");
            append_digit_0_9(min_ten);
            append_digit_0_9(min_unit);
            append_body(":");
            append_digit_0_9(sec_ten);
            append_digit_0_9(sec_unit);
        end
    endtask

    task append_alarm_payload;
        begin
            append_text5({"s","l","o","t","="});
            append_digit_0_9({1'b0, req_alarm_slot});
            append_text6({";","t","i","m","e","="});
            append_hms(req_alarm_hour_ten_bcd, req_alarm_hour_unit_bcd,
                       req_alarm_min_ten_bcd, req_alarm_min_unit_bcd,
                       req_alarm_sec_ten_bcd, req_alarm_sec_unit_bcd);
            append_text8({";","e","n","a","b","l","e","="});
            append_body(req_alarm_enable ? "1" : "0");
        end
    endtask

    task append_sched_payload;
        begin
            append_text5({"s","l","o","t","="});
            append_digit_0_9({1'b0, req_sched_slot});
            append_text6({";","t","i","m","e","="});
            append_hms(req_sched_hour_ten_bcd, req_sched_hour_unit_bcd,
                       req_sched_min_ten_bcd, req_sched_min_unit_bcd,
                       req_sched_sec_ten_bcd, req_sched_sec_unit_bcd);
            append_text6({";","t","y","p","e","="});
            append_digit_0_9({1'b0, req_sched_type});
            append_text8({";","e","n","a","b","l","e","="});
            append_body(req_sched_enable ? "1" : "0");
        end
    endtask

    task append_count_status_payload;
        begin
            append_text5({"t","i","m","e","="});
            append_hms(req_count_hour_ten_bcd, req_count_hour_unit_bcd,
                       req_count_min_ten_bcd, req_count_min_unit_bcd,
                       req_count_sec_ten_bcd, req_count_sec_unit_bcd);
            append_text5({";","r","u","n","="});
            append_body(req_countdown_run ? "1" : "0");
        end
    endtask

    task append_time_payload;
        begin
            append_text5({"d","a","t","e","="});
            append_digit_0_9(req_time_year_thousand_bcd);
            append_digit_0_9(req_time_year_hundred_bcd);
            append_digit_0_9(req_time_year_ten_bcd);
            append_digit_0_9(req_time_year_unit_bcd);
            append_body("-");
            append_digit_0_9(req_time_month_ten_bcd);
            append_digit_0_9(req_time_month_unit_bcd);
            append_body("-");
            append_digit_0_9(req_time_day_ten_bcd);
            append_digit_0_9(req_time_day_unit_bcd);
            append_text6({";","t","i","m","e","="});
            append_digit_0_9(req_time_hour_ten_bcd);
            append_digit_0_9(req_time_hour_unit_bcd);
            append_body(":");
            append_digit_0_9(req_time_min_ten_bcd);
            append_digit_0_9(req_time_min_unit_bcd);
            append_body(":");
            append_digit_0_9(req_time_sec_ten_bcd);
            append_digit_0_9(req_time_sec_unit_bcd);
            append_body(";");
            append_text7({"w","e","e","k","d","a","y"});
            append_body("=");
            append_digit_0_9({1'b0, req_time_weekday});
        end
    endtask

    task append_timestamp_value;
        integer ts_idx;
        begin
            for (ts_idx = 0; ts_idx < 19; ts_idx = ts_idx + 1) begin
                append_body(req_reply_timestamp_ascii[ts_idx * 8 +: 8]);
            end
        end
    endtask

    task append_reply_text_hex;
        integer text_idx;
        reg [7:0] ch;
        begin
            for (text_idx = 0; text_idx < 20; text_idx = text_idx + 1) begin
                if (text_idx < req_reply_text_len) begin
                    ch = req_reply_text_ascii[text_idx * 8 +: 8];
                    append_body(hex_char(ch[7:4]));
                    append_body(hex_char(ch[3:0]));
                end
            end
        end
    endtask

    task append_text8_unread_key;
        begin
            append_body(";");
            append_text6({"u","n","r","e","a","d"});
            append_body("=");
        end
    endtask

    task append_text11_count_run_key;
        begin
            append_body(";");
            append_text5({"c","o","u","n","t"});
            append_body("_");
            append_text3({"r","u","n"});
            append_body("=");
        end
    endtask

    // 构帧公共头：写 #、SEQ、|、CMD、|，并开始计算 BODY 校验。
    task begin_frame;
        begin
            build_len = 9'd0;
            build_cs = 8'd0;
            append_raw("#");
            append_body(req_seq_ascii[15:8]);
            append_body(req_seq_ascii[7:0]);
            append_body("|");
        end
    endtask

    // 构帧公共尾：追加 *CS\n，并把 build_len 固化为待发送长度。
    task finish_frame;
        begin
            append_raw("*");
            append_raw(hex_char(build_cs[7:4]));
            append_raw(hex_char(build_cs[3:0]));
            append_raw(8'h0A);
            tx_len = build_len;
        end
    endtask

    task build_ack_frame;
        begin
            begin_frame;
            append_text3({"A","C","K"});
            append_body("|");
            append_payload_ack;
            finish_frame;
        end
    endtask

    task build_pong_frame;
        begin
            begin_frame;
            append_text4({"P","O","N","G"});
            append_body("|");
            finish_frame;
        end
    endtask

    task build_status_frame;
        begin
            begin_frame;
            append_text6({"S","T","A","T","U","S"});
            append_body("|");
            append_payload_status;
            finish_frame;
        end
    endtask

    task build_msg_stored_frame;
        begin
            begin_frame;
            append_text3({"M","S","G"});
            append_body("_");
            append_text6({"S","T","O","R","E","D"});
            append_body("|");
            append_payload_msg_stored;
            finish_frame;
        end
    endtask

    task build_reply_frame;
        begin
            begin_frame;
            append_text5({"R","E","P","L","Y"});
            append_body("|");
            append_payload_reply;
            finish_frame;
        end
    endtask

    task build_nack_frame;
        begin
            begin_frame;
            append_text4({"N","A","C","K"});
            append_body("|");
            append_payload_nack;
            finish_frame;
        end
    endtask

    task build_time_frame;
        begin
            begin_frame;
            append_text4({"T","I","M","E"});
            append_body("|");
            append_time_payload;
            finish_frame;
        end
    endtask

    task build_alarm_frame;
        begin
            begin_frame;
            append_text5({"A","L","A","R","M"});
            append_body("|");
            append_alarm_payload;
            finish_frame;
        end
    endtask

    task build_sched_frame;
        begin
            begin_frame;
            append_text5({"S","C","H","E","D"});
            append_body("|");
            append_sched_payload;
            finish_frame;
        end
    endtask

    task build_count_status_frame;
        begin
            begin_frame;
            append_text5({"C","O","U","N","T"});
            append_body("_");
            append_text6({"S","T","A","T","U","S"});
            append_body("|");
            append_count_status_payload;
            finish_frame;
        end
    endtask

    function [3:0] build_state_for_kind;
        input [3:0] kind;
        begin
            case (kind)
                RESP_ACK:          build_state_for_kind = ST_BUILD_ACK;
                RESP_PONG:         build_state_for_kind = ST_BUILD_PONG;
                RESP_STATUS:       build_state_for_kind = ST_BUILD_STATUS;
                RESP_MSG_STORED:   build_state_for_kind = ST_BUILD_MSG_STORED;
                RESP_REPLY:        build_state_for_kind = ST_BUILD_REPLY;
                RESP_TIME:         build_state_for_kind = ST_BUILD_TIME;
                RESP_ALARM:        build_state_for_kind = ST_BUILD_ALARM;
                RESP_SCHED:        build_state_for_kind = ST_BUILD_SCHED;
                RESP_COUNT_STATUS: build_state_for_kind = ST_BUILD_COUNT_STATUS;
                default:           build_state_for_kind = ST_BUILD_NACK;
            endcase
        end
    endfunction

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= ST_IDLE;
            tx_len <= 9'd0;
            send_index <= 9'd0;
            tx_start <= 1'b0;
            tx_data <= 8'd0;
            done <= 1'b0;
            req_seq_ascii <= {"0", "0"};
            req_ack_cmd_kind <= ACK_HELLO;
            req_nack_err_kind <= ERR_BAD_FRAME;
            req_mode_state <= 3'b000;
            req_comm_status <= 3'd0;
            req_countdown_run <= 1'b0;
            req_message_count <= 5'd0;
            req_unread_count <= 5'd0;
            req_reply_slot <= 4'd0;
            req_reply_index <= 3'd0;
            req_reply_timestamp_ascii <= {19{8'h20}};
            req_reply_text_ascii <= {20{8'h20}};
            req_reply_text_len <= 6'd0;
            req_time_year_thousand_bcd <= 4'd2;
            req_time_year_hundred_bcd <= 4'd0;
            req_time_year_ten_bcd <= 4'd2;
            req_time_year_unit_bcd <= 4'd6;
            req_time_month_ten_bcd <= 4'd0;
            req_time_month_unit_bcd <= 4'd1;
            req_time_day_ten_bcd <= 4'd0;
            req_time_day_unit_bcd <= 4'd1;
            req_time_hour_ten_bcd <= 4'd0;
            req_time_hour_unit_bcd <= 4'd0;
            req_time_min_ten_bcd <= 4'd0;
            req_time_min_unit_bcd <= 4'd0;
            req_time_sec_ten_bcd <= 4'd0;
            req_time_sec_unit_bcd <= 4'd0;
            req_time_weekday <= 3'd1;
            req_alarm_slot <= 3'd0;
            req_alarm_hour_ten_bcd <= 4'd0;
            req_alarm_hour_unit_bcd <= 4'd0;
            req_alarm_min_ten_bcd <= 4'd0;
            req_alarm_min_unit_bcd <= 4'd0;
            req_alarm_sec_ten_bcd <= 4'd0;
            req_alarm_sec_unit_bcd <= 4'd0;
            req_alarm_enable <= 1'b0;
            req_sched_slot <= 3'd0;
            req_sched_hour_ten_bcd <= 4'd0;
            req_sched_hour_unit_bcd <= 4'd0;
            req_sched_min_ten_bcd <= 4'd0;
            req_sched_min_unit_bcd <= 4'd0;
            req_sched_sec_ten_bcd <= 4'd0;
            req_sched_sec_unit_bcd <= 4'd0;
            req_sched_type <= 3'd0;
            req_sched_enable <= 1'b0;
            req_count_hour_ten_bcd <= 4'd0;
            req_count_hour_unit_bcd <= 4'd0;
            req_count_min_ten_bcd <= 4'd0;
            req_count_min_unit_bcd <= 4'd0;
            req_count_sec_ten_bcd <= 4'd0;
            req_count_sec_unit_bcd <= 4'd0;
        end else begin
            tx_start <= 1'b0;
            done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    send_index <= 9'd0;
                    if (start) begin
                        req_seq_ascii <= seq_ascii;
                        req_ack_cmd_kind <= ack_cmd_kind;
                        req_nack_err_kind <= nack_err_kind;
                        req_mode_state <= mode_state;
                        req_comm_status <= comm_status;
                        req_countdown_run <= countdown_run;
                        req_message_count <= message_count;
                        req_unread_count <= unread_count;
                        req_reply_slot <= reply_slot;
                        req_reply_index <= reply_index;
                        req_reply_timestamp_ascii <= reply_timestamp_ascii;
                        req_reply_text_ascii <= reply_text_ascii;
                        req_reply_text_len <= reply_text_len;
                        req_time_year_thousand_bcd <= time_year_thousand_bcd;
                        req_time_year_hundred_bcd <= time_year_hundred_bcd;
                        req_time_year_ten_bcd <= time_year_ten_bcd;
                        req_time_year_unit_bcd <= time_year_unit_bcd;
                        req_time_month_ten_bcd <= time_month_ten_bcd;
                        req_time_month_unit_bcd <= time_month_unit_bcd;
                        req_time_day_ten_bcd <= time_day_ten_bcd;
                        req_time_day_unit_bcd <= time_day_unit_bcd;
                        req_time_hour_ten_bcd <= time_hour_ten_bcd;
                        req_time_hour_unit_bcd <= time_hour_unit_bcd;
                        req_time_min_ten_bcd <= time_min_ten_bcd;
                        req_time_min_unit_bcd <= time_min_unit_bcd;
                        req_time_sec_ten_bcd <= time_sec_ten_bcd;
                        req_time_sec_unit_bcd <= time_sec_unit_bcd;
                        req_time_weekday <= time_weekday;
                        req_alarm_slot <= alarm_slot;
                        req_alarm_hour_ten_bcd <= alarm_hour_ten_bcd;
                        req_alarm_hour_unit_bcd <= alarm_hour_unit_bcd;
                        req_alarm_min_ten_bcd <= alarm_min_ten_bcd;
                        req_alarm_min_unit_bcd <= alarm_min_unit_bcd;
                        req_alarm_sec_ten_bcd <= alarm_sec_ten_bcd;
                        req_alarm_sec_unit_bcd <= alarm_sec_unit_bcd;
                        req_alarm_enable <= alarm_enable;
                        req_sched_slot <= sched_slot;
                        req_sched_hour_ten_bcd <= sched_hour_ten_bcd;
                        req_sched_hour_unit_bcd <= sched_hour_unit_bcd;
                        req_sched_min_ten_bcd <= sched_min_ten_bcd;
                        req_sched_min_unit_bcd <= sched_min_unit_bcd;
                        req_sched_sec_ten_bcd <= sched_sec_ten_bcd;
                        req_sched_sec_unit_bcd <= sched_sec_unit_bcd;
                        req_sched_type <= sched_type;
                        req_sched_enable <= sched_enable;
                        req_count_hour_ten_bcd <= count_hour_ten_bcd;
                        req_count_hour_unit_bcd <= count_hour_unit_bcd;
                        req_count_min_ten_bcd <= count_min_ten_bcd;
                        req_count_min_unit_bcd <= count_min_unit_bcd;
                        req_count_sec_ten_bcd <= count_sec_ten_bcd;
                        req_count_sec_unit_bcd <= count_sec_unit_bcd;
                        state <= build_state_for_kind(response_kind);
                    end
                end

                ST_BUILD_ACK: begin
                    build_ack_frame;
                    state <= ST_SEND;
                end

                ST_BUILD_PONG: begin
                    build_pong_frame;
                    state <= ST_SEND;
                end

                ST_BUILD_STATUS: begin
                    build_status_frame;
                    state <= ST_SEND;
                end

                ST_BUILD_MSG_STORED: begin
                    build_msg_stored_frame;
                    state <= ST_SEND;
                end

                ST_BUILD_REPLY: begin
                    build_reply_frame;
                    state <= ST_SEND;
                end

                ST_BUILD_NACK: begin
                    build_nack_frame;
                    state <= ST_SEND;
                end

                ST_BUILD_TIME: begin
                    build_time_frame;
                    state <= ST_SEND;
                end

                ST_BUILD_ALARM: begin
                    build_alarm_frame;
                    state <= ST_SEND;
                end

                ST_BUILD_SCHED: begin
                    build_sched_frame;
                    state <= ST_SEND;
                end

                ST_BUILD_COUNT_STATUS: begin
                    build_count_status_frame;
                    state <= ST_SEND;
                end

                ST_SEND: begin
                    if ((send_index < tx_len) && !tx_busy) begin
                        tx_data <= tx_buf[send_index];
                        tx_start <= 1'b1;
                        send_index <= send_index + 1'b1;
                        state <= ST_WAIT_BUSY;
                    end else if ((send_index >= tx_len) && !tx_busy) begin
                        done <= 1'b1;
                        state <= ST_IDLE;
                    end
                end

                ST_WAIT_BUSY: begin
                    if (tx_busy) begin
                        state <= ST_WAIT_DONE;
                    end
                end

                ST_WAIT_DONE: begin
                    if (!tx_busy) begin
                        state <= ST_SEND;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule
