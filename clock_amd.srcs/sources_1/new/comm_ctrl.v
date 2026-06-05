`timescale 1ns / 1ps

module comm_ctrl #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 115_200
)(
    input  wire        clk,
    input  wire        tick_1k,
    input  wire        rst,
    input  wire        mode_comm,
    input  wire [2:0]  mode_state,
    input  wire [15:0] sw,
    input  wire        btn_up_pulse,
    input  wire        btn_down_pulse,
    input  wire        btn_center_pulse,
    input  wire        btn_right_pulse,
    input  wire        uart_rx,
    input  wire        countdown_run,
    input  wire [3:0]  cur_year_thousand_bcd,
    input  wire [3:0]  cur_year_hundred_bcd,
    input  wire [3:0]  cur_year_ten_bcd,
    input  wire [3:0]  cur_year_unit_bcd,
    input  wire [3:0]  cur_month_ten_bcd,
    input  wire [3:0]  cur_month_unit_bcd,
    input  wire [3:0]  cur_day_ten_bcd,
    input  wire [3:0]  cur_day_unit_bcd,
    input  wire [2:0]  cur_weekday,
    input  wire [3:0]  cur_hour_ten_bcd,
    input  wire [3:0]  cur_hour_unit_bcd,
    input  wire [3:0]  cur_min_ten_bcd,
    input  wire [3:0]  cur_min_unit_bcd,
    input  wire [3:0]  cur_sec_ten_bcd,
    input  wire [3:0]  cur_sec_unit_bcd,
    input  wire [2:0]  alarm_read_slot,
    input  wire [3:0]  alarm_read_hour_ten_bcd,
    input  wire [3:0]  alarm_read_hour_unit_bcd,
    input  wire [3:0]  alarm_read_min_ten_bcd,
    input  wire [3:0]  alarm_read_min_unit_bcd,
    input  wire [3:0]  alarm_read_sec_ten_bcd,
    input  wire [3:0]  alarm_read_sec_unit_bcd,
    input  wire        alarm_read_enable,
    input  wire [2:0]  sched_read_slot,
    input  wire [3:0]  sched_read_hour_ten_bcd,
    input  wire [3:0]  sched_read_hour_unit_bcd,
    input  wire [3:0]  sched_read_min_ten_bcd,
    input  wire [3:0]  sched_read_min_unit_bcd,
    input  wire [3:0]  sched_read_sec_ten_bcd,
    input  wire [3:0]  sched_read_sec_unit_bcd,
    input  wire [2:0]  sched_read_type,
    input  wire        sched_read_enable,
    input  wire [3:0]  count_hour_ten_bcd,
    input  wire [3:0]  count_hour_unit_bcd,
    input  wire [3:0]  count_min_ten_bcd,
    input  wire [3:0]  count_min_unit_bcd,
    input  wire [3:0]  count_sec_ten_bcd,
    input  wire [3:0]  count_sec_unit_bcd,
    output wire        uart_tx,
    output reg         pc_time_load_valid,
    output wire [3:0]  pc_hour_ten_bcd,
    output wire [3:0]  pc_hour_unit_bcd,
    output wire [3:0]  pc_min_ten_bcd,
    output wire [3:0]  pc_min_unit_bcd,
    output wire [3:0]  pc_sec_ten_bcd,
    output wire [3:0]  pc_sec_unit_bcd,
    output reg         pc_date_load_valid,
    output wire [3:0]  pc_year_thousand_bcd,
    output wire [3:0]  pc_year_hundred_bcd,
    output wire [3:0]  pc_year_ten_bcd,
    output wire [3:0]  pc_year_unit_bcd,
    output wire [3:0]  pc_month_ten_bcd,
    output wire [3:0]  pc_month_unit_bcd,
    output wire [3:0]  pc_day_ten_bcd,
    output wire [3:0]  pc_day_unit_bcd,
    output wire [2:0]  pc_weekday,
    output reg         pc_alarm_write_valid,
    output wire [2:0]  pc_alarm_write_slot,
    output wire [3:0]  pc_alarm_write_hour_ten_bcd,
    output wire [3:0]  pc_alarm_write_hour_unit_bcd,
    output wire [3:0]  pc_alarm_write_min_ten_bcd,
    output wire [3:0]  pc_alarm_write_min_unit_bcd,
    output wire [3:0]  pc_alarm_write_sec_ten_bcd,
    output wire [3:0]  pc_alarm_write_sec_unit_bcd,
    output wire        pc_alarm_write_enable,
    output wire [2:0]  pc_alarm_read_slot,
    output reg         pc_sched_write_valid,
    output wire [2:0]  pc_sched_write_slot,
    output wire [3:0]  pc_sched_write_hour_ten_bcd,
    output wire [3:0]  pc_sched_write_hour_unit_bcd,
    output wire [3:0]  pc_sched_write_min_ten_bcd,
    output wire [3:0]  pc_sched_write_min_unit_bcd,
    output wire [3:0]  pc_sched_write_sec_ten_bcd,
    output wire [3:0]  pc_sched_write_sec_unit_bcd,
    output wire [2:0]  pc_sched_write_type,
    output wire        pc_sched_write_enable,
    output wire [2:0]  pc_sched_read_slot,
    output reg         pc_count_load_valid,
    output wire [3:0]  pc_count_hour_ten_bcd,
    output wire [3:0]  pc_count_hour_unit_bcd,
    output wire [3:0]  pc_count_min_ten_bcd,
    output wire [3:0]  pc_count_min_unit_bcd,
    output wire [3:0]  pc_count_sec_ten_bcd,
    output wire [3:0]  pc_count_sec_unit_bcd,
    output reg         pc_count_start_pulse,
    output reg         pc_count_stop_pulse,
    output wire [2:0]  comm_status,
    output reg         comm_reply_mode,
    output reg  [2:0]  comm_reply_index,
    output wire [159:0] comm_reply_text_ascii,
    output wire [5:0]   comm_reply_text_len,
    output reg  [3:0]  comm_selected_slot,
    output wire        comm_message_valid,
    output wire        comm_message_unread,
    output wire [4:0]  comm_message_count,
    output wire [4:0]  comm_unread_count,
    output reg  [2:0]  comm_scroll_line,
    output wire [151:0] comm_timestamp_ascii,
    output wire [6:0]   comm_message_len,
    output wire [511:0] comm_message_window_ascii
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

    localparam [3:0] ERR_TX_BUSY = 4'd9;

    localparam [2:0] COMM_STATUS_DISC = 3'd0;
    localparam [2:0] COMM_STATUS_WAIT = 3'd1;
    localparam [2:0] COMM_STATUS_CONN = 3'd2;
    localparam [2:0] COMM_STATUS_MSG  = 3'd3;
    localparam [2:0] COMM_STATUS_ERR  = 3'd4;

    wire rx_valid;
    wire [7:0] rx_data;
    wire rx_busy;
    wire tx_start_wire;
    wire [7:0] tx_data_wire;
    wire tx_busy;
    wire tx_done;
    wire builder_busy;
    wire builder_done;

    wire parser_hello_valid;
    wire parser_ping_valid;
    wire parser_status_get_valid;
    wire parser_time_set_valid;
    wire parser_time_get_valid;
    wire parser_alarm_set_valid;
    wire parser_alarm_get_valid;
    wire parser_sched_set_valid;
    wire parser_sched_get_valid;
    wire parser_count_set_valid;
    wire parser_count_start_valid;
    wire parser_count_stop_valid;
    wire parser_count_status_valid;
    wire [3:0] parser_time_year_thousand_bcd;
    wire [3:0] parser_time_year_hundred_bcd;
    wire [3:0] parser_time_year_ten_bcd;
    wire [3:0] parser_time_year_unit_bcd;
    wire [3:0] parser_time_month_ten_bcd;
    wire [3:0] parser_time_month_unit_bcd;
    wire [3:0] parser_time_day_ten_bcd;
    wire [3:0] parser_time_day_unit_bcd;
    wire [3:0] parser_time_hour_ten_bcd;
    wire [3:0] parser_time_hour_unit_bcd;
    wire [3:0] parser_time_min_ten_bcd;
    wire [3:0] parser_time_min_unit_bcd;
    wire [3:0] parser_time_sec_ten_bcd;
    wire [3:0] parser_time_sec_unit_bcd;
    wire [2:0] parser_time_weekday;
    wire [2:0] parser_alarm_slot;
    wire [3:0] parser_alarm_hour_ten_bcd;
    wire [3:0] parser_alarm_hour_unit_bcd;
    wire [3:0] parser_alarm_min_ten_bcd;
    wire [3:0] parser_alarm_min_unit_bcd;
    wire [3:0] parser_alarm_sec_ten_bcd;
    wire [3:0] parser_alarm_sec_unit_bcd;
    wire parser_alarm_enable;
    wire [2:0] parser_sched_slot;
    wire [3:0] parser_sched_hour_ten_bcd;
    wire [3:0] parser_sched_hour_unit_bcd;
    wire [3:0] parser_sched_min_ten_bcd;
    wire [3:0] parser_sched_min_unit_bcd;
    wire [3:0] parser_sched_sec_ten_bcd;
    wire [3:0] parser_sched_sec_unit_bcd;
    wire [2:0] parser_sched_type;
    wire parser_sched_enable;
    wire [3:0] parser_count_hour_ten_bcd;
    wire [3:0] parser_count_hour_unit_bcd;
    wire [3:0] parser_count_min_ten_bcd;
    wire [3:0] parser_count_min_unit_bcd;
    wire [3:0] parser_count_sec_ten_bcd;
    wire [3:0] parser_count_sec_unit_bcd;
    wire parser_msg_begin_valid;
    wire parser_msg_tx_valid;
    wire [151:0] parser_msg_timestamp_ascii;
    wire [6:0] parser_msg_len;
    wire parser_msg_char_valid;
    wire [6:0] parser_msg_char_index;
    wire [7:0] parser_msg_char_ascii;
    wire parser_msg_get_valid;
    wire [3:0] parser_msg_get_slot;
    wire parser_msg_clear_valid;
    wire parser_msg_clear_all;
    wire [3:0] parser_msg_clear_slot;
    wire parser_nack_valid;
    wire [3:0] parser_nack_err;
    wire [15:0] parser_seq_ascii;

    reg clear_all;
    reg clear_slot_valid;
    reg connected;
    reg [11:0] error_timer_ms;
    reg [3:0] selected_slot_d;

    reg response_pending;
    reg [3:0] response_kind_reg;
    reg [15:0] response_seq_reg;
    reg [3:0] response_ack_cmd_reg;
    reg [3:0] response_nack_err_reg;
    reg builder_start;

    reg store_response_pending;
    reg [15:0] store_response_seq;
    reg clear_response_pending;
    reg [15:0] clear_response_seq;
    reg reply_response_pending;
    reg [15:0] reply_response_seq;
    reg [7:0] reply_seq_counter;
    reg [3:0] reply_slot_reg;
    reg [2:0] reply_index_reg;
    reg [151:0] reply_timestamp_reg;
    reg [159:0] reply_text_reg;
    reg [5:0] reply_text_len_reg;
    reg [2:0] alarm_read_slot_reg;
    reg [2:0] sched_read_slot_reg;
    wire [6:0] comm_window_base_index;

    assign comm_window_base_index = {comm_scroll_line, 4'b0000};

    assign comm_status = (error_timer_ms != 12'd0) ? COMM_STATUS_ERR :
                         (comm_unread_count != 5'd0) ? COMM_STATUS_MSG :
                         (response_pending || builder_busy) ? COMM_STATUS_WAIT :
                         connected ? COMM_STATUS_CONN :
                         COMM_STATUS_DISC;
    assign pc_year_thousand_bcd = parser_time_year_thousand_bcd;
    assign pc_year_hundred_bcd  = parser_time_year_hundred_bcd;
    assign pc_year_ten_bcd      = parser_time_year_ten_bcd;
    assign pc_year_unit_bcd     = parser_time_year_unit_bcd;
    assign pc_month_ten_bcd     = parser_time_month_ten_bcd;
    assign pc_month_unit_bcd    = parser_time_month_unit_bcd;
    assign pc_day_ten_bcd       = parser_time_day_ten_bcd;
    assign pc_day_unit_bcd      = parser_time_day_unit_bcd;
    assign pc_weekday           = parser_time_weekday;
    assign pc_hour_ten_bcd      = parser_time_hour_ten_bcd;
    assign pc_hour_unit_bcd     = parser_time_hour_unit_bcd;
    assign pc_min_ten_bcd       = parser_time_min_ten_bcd;
    assign pc_min_unit_bcd      = parser_time_min_unit_bcd;
    assign pc_sec_ten_bcd       = parser_time_sec_ten_bcd;
    assign pc_sec_unit_bcd      = parser_time_sec_unit_bcd;
    assign pc_alarm_write_slot = parser_alarm_slot;
    assign pc_alarm_write_hour_ten_bcd = parser_alarm_hour_ten_bcd;
    assign pc_alarm_write_hour_unit_bcd = parser_alarm_hour_unit_bcd;
    assign pc_alarm_write_min_ten_bcd = parser_alarm_min_ten_bcd;
    assign pc_alarm_write_min_unit_bcd = parser_alarm_min_unit_bcd;
    assign pc_alarm_write_sec_ten_bcd = parser_alarm_sec_ten_bcd;
    assign pc_alarm_write_sec_unit_bcd = parser_alarm_sec_unit_bcd;
    assign pc_alarm_write_enable = parser_alarm_enable;
    assign pc_alarm_read_slot = alarm_read_slot_reg;
    assign pc_sched_write_slot = parser_sched_slot;
    assign pc_sched_write_hour_ten_bcd = parser_sched_hour_ten_bcd;
    assign pc_sched_write_hour_unit_bcd = parser_sched_hour_unit_bcd;
    assign pc_sched_write_min_ten_bcd = parser_sched_min_ten_bcd;
    assign pc_sched_write_min_unit_bcd = parser_sched_min_unit_bcd;
    assign pc_sched_write_sec_ten_bcd = parser_sched_sec_ten_bcd;
    assign pc_sched_write_sec_unit_bcd = parser_sched_sec_unit_bcd;
    assign pc_sched_write_type = parser_sched_type;
    assign pc_sched_write_enable = parser_sched_enable;
    assign pc_sched_read_slot = sched_read_slot_reg;
    assign pc_count_hour_ten_bcd = parser_count_hour_ten_bcd;
    assign pc_count_hour_unit_bcd = parser_count_hour_unit_bcd;
    assign pc_count_min_ten_bcd = parser_count_min_ten_bcd;
    assign pc_count_min_unit_bcd = parser_count_min_unit_bcd;
    assign pc_count_sec_ten_bcd = parser_count_sec_ten_bcd;
    assign pc_count_sec_unit_bcd = parser_count_sec_unit_bcd;

    function [3:0] lowest_switch_slot;
        input [15:0] switches;
        begin
            if (switches[0])       lowest_switch_slot = 4'd0;
            else if (switches[1])  lowest_switch_slot = 4'd1;
            else if (switches[2])  lowest_switch_slot = 4'd2;
            else if (switches[3])  lowest_switch_slot = 4'd3;
            else if (switches[4])  lowest_switch_slot = 4'd4;
            else if (switches[5])  lowest_switch_slot = 4'd5;
            else if (switches[6])  lowest_switch_slot = 4'd6;
            else if (switches[7])  lowest_switch_slot = 4'd7;
            else if (switches[8])  lowest_switch_slot = 4'd8;
            else if (switches[9])  lowest_switch_slot = 4'd9;
            else if (switches[10]) lowest_switch_slot = 4'd10;
            else if (switches[11]) lowest_switch_slot = 4'd11;
            else if (switches[12]) lowest_switch_slot = 4'd12;
            else if (switches[13]) lowest_switch_slot = 4'd13;
            else if (switches[14]) lowest_switch_slot = 4'd14;
            else if (switches[15]) lowest_switch_slot = 4'd15;
            else                   lowest_switch_slot = 4'd0;
        end
    endfunction

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

    preset_reply_rom u_preset_reply_rom (
        .reply_index(comm_reply_index),
        .reply_ascii(comm_reply_text_ascii),
        .reply_len(comm_reply_text_len)
    );

    function [2:0] max_scroll_for_len;
        input [6:0] len;
        reg [3:0] line_count;
        begin
            line_count = (len + 7'd15) >> 4;
            if (line_count > 4'd4) begin
                max_scroll_for_len = line_count[2:0] - 3'd4;
            end else begin
                max_scroll_for_len = 3'd0;
            end
        end
    endfunction

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_rx (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .rx_busy(rx_busy)
    );

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_tx (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start_wire),
        .tx_data(tx_data_wire),
        .tx(uart_tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    protocol_parser u_protocol_parser (
        .clk(clk),
        .rst(rst),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .cmd_hello_valid(parser_hello_valid),
        .cmd_ping_valid(parser_ping_valid),
        .cmd_status_get_valid(parser_status_get_valid),
        .cmd_time_set_valid(parser_time_set_valid),
        .cmd_time_get_valid(parser_time_get_valid),
        .cmd_alarm_set_valid(parser_alarm_set_valid),
        .cmd_alarm_get_valid(parser_alarm_get_valid),
        .cmd_sched_set_valid(parser_sched_set_valid),
        .cmd_sched_get_valid(parser_sched_get_valid),
        .cmd_count_set_valid(parser_count_set_valid),
        .cmd_count_start_valid(parser_count_start_valid),
        .cmd_count_stop_valid(parser_count_stop_valid),
        .cmd_count_status_valid(parser_count_status_valid),
        .time_year_thousand_bcd(parser_time_year_thousand_bcd),
        .time_year_hundred_bcd(parser_time_year_hundred_bcd),
        .time_year_ten_bcd(parser_time_year_ten_bcd),
        .time_year_unit_bcd(parser_time_year_unit_bcd),
        .time_month_ten_bcd(parser_time_month_ten_bcd),
        .time_month_unit_bcd(parser_time_month_unit_bcd),
        .time_day_ten_bcd(parser_time_day_ten_bcd),
        .time_day_unit_bcd(parser_time_day_unit_bcd),
        .time_hour_ten_bcd(parser_time_hour_ten_bcd),
        .time_hour_unit_bcd(parser_time_hour_unit_bcd),
        .time_min_ten_bcd(parser_time_min_ten_bcd),
        .time_min_unit_bcd(parser_time_min_unit_bcd),
        .time_sec_ten_bcd(parser_time_sec_ten_bcd),
        .time_sec_unit_bcd(parser_time_sec_unit_bcd),
        .time_weekday(parser_time_weekday),
        .alarm_slot(parser_alarm_slot),
        .alarm_hour_ten_bcd(parser_alarm_hour_ten_bcd),
        .alarm_hour_unit_bcd(parser_alarm_hour_unit_bcd),
        .alarm_min_ten_bcd(parser_alarm_min_ten_bcd),
        .alarm_min_unit_bcd(parser_alarm_min_unit_bcd),
        .alarm_sec_ten_bcd(parser_alarm_sec_ten_bcd),
        .alarm_sec_unit_bcd(parser_alarm_sec_unit_bcd),
        .alarm_enable(parser_alarm_enable),
        .sched_slot(parser_sched_slot),
        .sched_hour_ten_bcd(parser_sched_hour_ten_bcd),
        .sched_hour_unit_bcd(parser_sched_hour_unit_bcd),
        .sched_min_ten_bcd(parser_sched_min_ten_bcd),
        .sched_min_unit_bcd(parser_sched_min_unit_bcd),
        .sched_sec_ten_bcd(parser_sched_sec_ten_bcd),
        .sched_sec_unit_bcd(parser_sched_sec_unit_bcd),
        .sched_type(parser_sched_type),
        .sched_enable(parser_sched_enable),
        .count_hour_ten_bcd(parser_count_hour_ten_bcd),
        .count_hour_unit_bcd(parser_count_hour_unit_bcd),
        .count_min_ten_bcd(parser_count_min_ten_bcd),
        .count_min_unit_bcd(parser_count_min_unit_bcd),
        .count_sec_ten_bcd(parser_count_sec_ten_bcd),
        .count_sec_unit_bcd(parser_count_sec_unit_bcd),
        .msg_begin_valid(parser_msg_begin_valid),
        .cmd_msg_tx_valid(parser_msg_tx_valid),
        .msg_timestamp_ascii(parser_msg_timestamp_ascii),
        .msg_len(parser_msg_len),
        .msg_char_valid(parser_msg_char_valid),
        .msg_char_index(parser_msg_char_index),
        .msg_char_ascii(parser_msg_char_ascii),
        .cmd_msg_get_valid(parser_msg_get_valid),
        .msg_get_slot(parser_msg_get_slot),
        .cmd_msg_clear_valid(parser_msg_clear_valid),
        .msg_clear_all(parser_msg_clear_all),
        .msg_clear_slot(parser_msg_clear_slot),
        .nack_valid(parser_nack_valid),
        .nack_err(parser_nack_err),
        .seq_ascii(parser_seq_ascii)
    );

    message_store u_message_store (
        .clk(clk),
        .rst(rst),
        .store_begin(parser_msg_begin_valid),
        .store_timestamp_ascii(parser_msg_timestamp_ascii),
        .store_len(parser_msg_len),
        .store_char_valid(parser_msg_char_valid),
        .store_char_index(parser_msg_char_index),
        .store_char_ascii(parser_msg_char_ascii),
        .clear_all(clear_all),
        .clear_slot_valid(clear_slot_valid),
        .clear_slot(parser_msg_clear_slot),
        .selected_slot(comm_selected_slot),
        .window_base_index(comm_window_base_index),
        .selected_valid(comm_message_valid),
        .selected_unread(comm_message_unread),
        .selected_timestamp_ascii(comm_timestamp_ascii),
        .selected_len(comm_message_len),
        .selected_window_ascii(comm_message_window_ascii),
        .message_count(comm_message_count),
        .unread_count(comm_unread_count)
    );

    protocol_builder u_protocol_builder (
        .clk(clk),
        .rst(rst),
        .start(builder_start),
        .response_kind(response_kind_reg),
        .seq_ascii(response_seq_reg),
        .ack_cmd_kind(response_ack_cmd_reg),
        .nack_err_kind(response_nack_err_reg),
        .mode_state(mode_state),
        .comm_status(comm_status),
        .countdown_run(countdown_run),
        .message_count(comm_message_count),
        .unread_count(comm_unread_count),
        .reply_slot(reply_slot_reg),
        .reply_index(reply_index_reg),
        .reply_timestamp_ascii(reply_timestamp_reg),
        .reply_text_ascii(reply_text_reg),
        .reply_text_len(reply_text_len_reg),
        .time_year_thousand_bcd(cur_year_thousand_bcd),
        .time_year_hundred_bcd(cur_year_hundred_bcd),
        .time_year_ten_bcd(cur_year_ten_bcd),
        .time_year_unit_bcd(cur_year_unit_bcd),
        .time_month_ten_bcd(cur_month_ten_bcd),
        .time_month_unit_bcd(cur_month_unit_bcd),
        .time_day_ten_bcd(cur_day_ten_bcd),
        .time_day_unit_bcd(cur_day_unit_bcd),
        .time_hour_ten_bcd(cur_hour_ten_bcd),
        .time_hour_unit_bcd(cur_hour_unit_bcd),
        .time_min_ten_bcd(cur_min_ten_bcd),
        .time_min_unit_bcd(cur_min_unit_bcd),
        .time_sec_ten_bcd(cur_sec_ten_bcd),
        .time_sec_unit_bcd(cur_sec_unit_bcd),
        .time_weekday(cur_weekday),
        .alarm_slot(alarm_read_slot),
        .alarm_hour_ten_bcd(alarm_read_hour_ten_bcd),
        .alarm_hour_unit_bcd(alarm_read_hour_unit_bcd),
        .alarm_min_ten_bcd(alarm_read_min_ten_bcd),
        .alarm_min_unit_bcd(alarm_read_min_unit_bcd),
        .alarm_sec_ten_bcd(alarm_read_sec_ten_bcd),
        .alarm_sec_unit_bcd(alarm_read_sec_unit_bcd),
        .alarm_enable(alarm_read_enable),
        .sched_slot(sched_read_slot),
        .sched_hour_ten_bcd(sched_read_hour_ten_bcd),
        .sched_hour_unit_bcd(sched_read_hour_unit_bcd),
        .sched_min_ten_bcd(sched_read_min_ten_bcd),
        .sched_min_unit_bcd(sched_read_min_unit_bcd),
        .sched_sec_ten_bcd(sched_read_sec_ten_bcd),
        .sched_sec_unit_bcd(sched_read_sec_unit_bcd),
        .sched_type(sched_read_type),
        .sched_enable(sched_read_enable),
        .count_hour_ten_bcd(count_hour_ten_bcd),
        .count_hour_unit_bcd(count_hour_unit_bcd),
        .count_min_ten_bcd(count_min_ten_bcd),
        .count_min_unit_bcd(count_min_unit_bcd),
        .count_sec_ten_bcd(count_sec_ten_bcd),
        .count_sec_unit_bcd(count_sec_unit_bcd),
        .tx_busy(tx_busy),
        .tx_start(tx_start_wire),
        .tx_data(tx_data_wire),
        .busy(builder_busy),
        .done(builder_done)
    );

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            comm_selected_slot <= 4'd0;
            selected_slot_d <= 4'd0;
            comm_scroll_line <= 3'd0;
            comm_reply_mode <= 1'b0;
            comm_reply_index <= 3'd0;
        end else begin
            comm_selected_slot <= lowest_switch_slot(sw);
            selected_slot_d <= comm_selected_slot;

            if (!mode_comm || parser_msg_begin_valid || (lowest_switch_slot(sw) != selected_slot_d)) begin
                comm_scroll_line <= 3'd0;
                comm_reply_mode <= 1'b0;
            end else if (btn_center_pulse && comm_message_valid) begin
                comm_reply_mode <= ~comm_reply_mode;
            end else if (comm_reply_mode) begin
                if (btn_down_pulse) begin
                    comm_reply_index <= comm_reply_index + 1'b1;
                end else if (btn_up_pulse) begin
                    comm_reply_index <= comm_reply_index - 1'b1;
                end
            end else if (btn_down_pulse && (comm_scroll_line < max_scroll_for_len(comm_message_len))) begin
                comm_scroll_line <= comm_scroll_line + 1'b1;
            end else if (btn_up_pulse && (comm_scroll_line != 3'd0)) begin
                comm_scroll_line <= comm_scroll_line - 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            connected <= 1'b0;
            error_timer_ms <= 12'd0;
            clear_all <= 1'b0;
            clear_slot_valid <= 1'b0;
            pc_time_load_valid <= 1'b0;
            pc_date_load_valid <= 1'b0;
            pc_alarm_write_valid <= 1'b0;
            pc_sched_write_valid <= 1'b0;
            pc_count_load_valid <= 1'b0;
            pc_count_start_pulse <= 1'b0;
            pc_count_stop_pulse <= 1'b0;
            response_pending <= 1'b0;
            response_kind_reg <= RESP_ACK;
            response_seq_reg <= {"0", "0"};
            response_ack_cmd_reg <= ACK_HELLO;
            response_nack_err_reg <= 4'd0;
            builder_start <= 1'b0;
            store_response_pending <= 1'b0;
            store_response_seq <= {"0", "0"};
            clear_response_pending <= 1'b0;
            clear_response_seq <= {"0", "0"};
            reply_response_pending <= 1'b0;
            reply_response_seq <= {"F", "0"};
            reply_seq_counter <= 8'hF0;
            reply_slot_reg <= 4'd0;
            reply_index_reg <= 3'd0;
            reply_timestamp_reg <= {19{8'h20}};
            reply_text_reg <= {20{8'h20}};
            reply_text_len_reg <= 6'd0;
            alarm_read_slot_reg <= 3'd0;
            sched_read_slot_reg <= 3'd0;
        end else begin
            clear_all <= 1'b0;
            clear_slot_valid <= 1'b0;
            pc_time_load_valid <= 1'b0;
            pc_date_load_valid <= 1'b0;
            pc_alarm_write_valid <= 1'b0;
            pc_sched_write_valid <= 1'b0;
            pc_count_load_valid <= 1'b0;
            pc_count_start_pulse <= 1'b0;
            pc_count_stop_pulse <= 1'b0;
            builder_start <= 1'b0;

            if (tick_1k && (error_timer_ms != 12'd0)) begin
                error_timer_ms <= error_timer_ms - 1'b1;
            end

            if (response_pending && !builder_busy) begin
                builder_start <= 1'b1;
                response_pending <= 1'b0;
            end else if (reply_response_pending) begin
                response_kind_reg <= RESP_REPLY;
                response_seq_reg <= reply_response_seq;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
                reply_response_pending <= 1'b0;
            end else if (store_response_pending) begin
                response_kind_reg <= RESP_MSG_STORED;
                response_seq_reg <= store_response_seq;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
                store_response_pending <= 1'b0;
            end else if (clear_response_pending) begin
                response_kind_reg <= RESP_ACK;
                response_seq_reg <= clear_response_seq;
                response_ack_cmd_reg <= ACK_MSG_CLEAR;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
                clear_response_pending <= 1'b0;
            end else if ((parser_hello_valid || parser_ping_valid || parser_status_get_valid ||
                         parser_time_set_valid || parser_time_get_valid ||
                         parser_alarm_set_valid || parser_alarm_get_valid ||
                         parser_sched_set_valid || parser_sched_get_valid ||
                         parser_count_set_valid || parser_count_start_valid ||
                         parser_count_stop_valid || parser_count_status_valid ||
                         parser_msg_tx_valid || parser_msg_get_valid || parser_msg_clear_valid) &&
                         (response_pending || builder_busy)) begin
                response_kind_reg <= RESP_NACK;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= ERR_TX_BUSY;
                response_pending <= 1'b1;
                error_timer_ms <= 12'd2000;
            end else if (parser_nack_valid) begin
                response_kind_reg <= RESP_NACK;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= parser_nack_err;
                response_pending <= 1'b1;
                error_timer_ms <= 12'd2000;
            end else if (parser_hello_valid) begin
                connected <= 1'b1;
                response_kind_reg <= RESP_ACK;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_ping_valid) begin
                connected <= 1'b1;
                response_kind_reg <= RESP_PONG;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_status_get_valid) begin
                connected <= 1'b1;
                response_kind_reg <= RESP_STATUS;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_time_set_valid) begin
                connected <= 1'b1;
                pc_time_load_valid <= 1'b1;
                pc_date_load_valid <= 1'b1;
                response_kind_reg <= RESP_ACK;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_TIME_SET;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_time_get_valid) begin
                connected <= 1'b1;
                response_kind_reg <= RESP_TIME;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_alarm_set_valid) begin
                connected <= 1'b1;
                pc_alarm_write_valid <= 1'b1;
                alarm_read_slot_reg <= parser_alarm_slot;
                response_kind_reg <= RESP_ACK;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_ALARM_SET;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_alarm_get_valid) begin
                connected <= 1'b1;
                alarm_read_slot_reg <= parser_alarm_slot;
                response_kind_reg <= RESP_ALARM;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_sched_set_valid) begin
                connected <= 1'b1;
                pc_sched_write_valid <= 1'b1;
                sched_read_slot_reg <= parser_sched_slot;
                response_kind_reg <= RESP_ACK;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_SCHED_SET;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_sched_get_valid) begin
                connected <= 1'b1;
                sched_read_slot_reg <= parser_sched_slot;
                response_kind_reg <= RESP_SCHED;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_count_set_valid) begin
                connected <= 1'b1;
                pc_count_load_valid <= 1'b1;
                response_kind_reg <= RESP_ACK;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_COUNT_SET;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_count_start_valid) begin
                connected <= 1'b1;
                pc_count_start_pulse <= 1'b1;
                response_kind_reg <= RESP_ACK;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_COUNT_START;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_count_stop_valid) begin
                connected <= 1'b1;
                pc_count_stop_pulse <= 1'b1;
                response_kind_reg <= RESP_ACK;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_COUNT_STOP;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_count_status_valid) begin
                connected <= 1'b1;
                response_kind_reg <= RESP_COUNT_STATUS;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= 4'd0;
                response_pending <= 1'b1;
            end else if (parser_msg_tx_valid) begin
                connected <= 1'b1;
                store_response_seq <= parser_seq_ascii;
                store_response_pending <= 1'b1;
            end else if (parser_msg_get_valid) begin
                connected <= 1'b1;
                response_kind_reg <= RESP_NACK;
                response_seq_reg <= parser_seq_ascii;
                response_ack_cmd_reg <= ACK_HELLO;
                response_nack_err_reg <= 4'd7;
                response_pending <= 1'b1;
            end else if (parser_msg_clear_valid) begin
                connected <= 1'b1;
                clear_all <= parser_msg_clear_all;
                clear_slot_valid <= !parser_msg_clear_all;
                clear_response_seq <= parser_seq_ascii;
                clear_response_pending <= 1'b1;
            end else if (mode_comm && comm_reply_mode && comm_message_valid && btn_right_pulse &&
                         !reply_response_pending && !response_pending && !builder_busy) begin
                reply_response_seq <= {hex_char(reply_seq_counter[7:4]), hex_char(reply_seq_counter[3:0])};
                reply_seq_counter <= reply_seq_counter + 1'b1;
                reply_slot_reg <= comm_selected_slot;
                reply_index_reg <= comm_reply_index;
                reply_timestamp_reg <= comm_timestamp_ascii;
                reply_text_reg <= comm_reply_text_ascii;
                reply_text_len_reg <= comm_reply_text_len;
                reply_response_pending <= 1'b1;
            end
        end
    end
endmodule
