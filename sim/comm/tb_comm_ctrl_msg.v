`timescale 1ns / 1ps

module tb_comm_ctrl_msg;
    localparam integer CLK_FREQ  = 1_000_000;
    localparam integer BAUD_RATE = 100_000;
    localparam integer BIT_NS    = 10_000;
    localparam integer FRAME_LEN = 59;

    reg clk = 1'b0;
    reg rst = 1'b0;
    reg tick_1k = 1'b0;
    reg mode_comm = 1'b1;
    reg [2:0] mode_state = 3'b110;
    reg [15:0] sw = 16'h0001;
    reg btn_up_pulse = 1'b0;
    reg btn_down_pulse = 1'b0;
    reg btn_center_pulse = 1'b0;
    reg btn_right_pulse = 1'b0;
    reg uart_rx_line = 1'b1;

    wire uart_tx_line;
    wire [2:0] comm_status;
    wire comm_reply_mode;
    wire [2:0] comm_reply_index;
    wire [3:0] comm_selected_slot;
    wire comm_message_valid;
    wire comm_message_unread;
    wire [4:0] comm_message_count;
    wire [4:0] comm_unread_count;
    wire pc_time_load_valid;
    wire pc_date_load_valid;
    wire [2:0] comm_scroll_line;
    wire [151:0] comm_timestamp_ascii;
    wire [6:0] comm_message_len;
    wire [511:0] comm_message_window_ascii;

    reg [15:0] tick_count = 16'd0;
    reg [7:0] captured [0:127];
    reg [7:0] capture_count = 8'd0;
    reg capture_done = 1'b0;
    wire cap_valid;
    wire [7:0] cap_data;
    wire cap_busy;

    localparam [8*FRAME_LEN-1:0] MSG_FRAME =
        "#04|MSG_TX|ts=2026-06-05T15:03:00;len=5;text=48656C6C6F*52\n";

    integer i;

    always #500 clk = ~clk;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            tick_count <= 16'd0;
            tick_1k <= 1'b0;
        end else if (tick_count == 16'd999) begin
            tick_count <= 16'd0;
            tick_1k <= 1'b1;
        end else begin
            tick_count <= tick_count + 1'b1;
            tick_1k <= 1'b0;
        end
    end

    comm_ctrl #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .tick_1k(tick_1k),
        .rst(rst),
        .mode_comm(mode_comm),
        .mode_state(mode_state),
        .sw(sw),
        .btn_up_pulse(btn_up_pulse),
        .btn_down_pulse(btn_down_pulse),
        .btn_center_pulse(btn_center_pulse),
        .btn_right_pulse(btn_right_pulse),
        .uart_rx(uart_rx_line),
        .countdown_run(1'b0),
        .cur_year_thousand_bcd(4'd2),
        .cur_year_hundred_bcd(4'd0),
        .cur_year_ten_bcd(4'd2),
        .cur_year_unit_bcd(4'd6),
        .cur_month_ten_bcd(4'd0),
        .cur_month_unit_bcd(4'd6),
        .cur_day_ten_bcd(4'd0),
        .cur_day_unit_bcd(4'd5),
        .cur_weekday(3'd5),
        .cur_hour_ten_bcd(4'd1),
        .cur_hour_unit_bcd(4'd5),
        .cur_min_ten_bcd(4'd0),
        .cur_min_unit_bcd(4'd3),
        .cur_sec_ten_bcd(4'd0),
        .cur_sec_unit_bcd(4'd0),
        .alarm_read_slot(3'd0),
        .alarm_read_hour_ten_bcd(4'd0),
        .alarm_read_hour_unit_bcd(4'd0),
        .alarm_read_min_ten_bcd(4'd0),
        .alarm_read_min_unit_bcd(4'd0),
        .alarm_read_sec_ten_bcd(4'd0),
        .alarm_read_sec_unit_bcd(4'd0),
        .alarm_read_enable(1'b0),
        .sched_read_slot(3'd0),
        .sched_read_hour_ten_bcd(4'd0),
        .sched_read_hour_unit_bcd(4'd0),
        .sched_read_min_ten_bcd(4'd0),
        .sched_read_min_unit_bcd(4'd0),
        .sched_read_sec_ten_bcd(4'd0),
        .sched_read_sec_unit_bcd(4'd0),
        .sched_read_type(3'd0),
        .sched_read_enable(1'b0),
        .count_hour_ten_bcd(4'd0),
        .count_hour_unit_bcd(4'd0),
        .count_min_ten_bcd(4'd0),
        .count_min_unit_bcd(4'd0),
        .count_sec_ten_bcd(4'd0),
        .count_sec_unit_bcd(4'd0),
        .uart_tx(uart_tx_line),
        .pc_time_load_valid(pc_time_load_valid),
        .pc_hour_ten_bcd(),
        .pc_hour_unit_bcd(),
        .pc_min_ten_bcd(),
        .pc_min_unit_bcd(),
        .pc_sec_ten_bcd(),
        .pc_sec_unit_bcd(),
        .pc_date_load_valid(pc_date_load_valid),
        .pc_year_thousand_bcd(),
        .pc_year_hundred_bcd(),
        .pc_year_ten_bcd(),
        .pc_year_unit_bcd(),
        .pc_month_ten_bcd(),
        .pc_month_unit_bcd(),
        .pc_day_ten_bcd(),
        .pc_day_unit_bcd(),
        .pc_weekday(),
        .pc_alarm_write_valid(),
        .pc_alarm_write_slot(),
        .pc_alarm_write_hour_ten_bcd(),
        .pc_alarm_write_hour_unit_bcd(),
        .pc_alarm_write_min_ten_bcd(),
        .pc_alarm_write_min_unit_bcd(),
        .pc_alarm_write_sec_ten_bcd(),
        .pc_alarm_write_sec_unit_bcd(),
        .pc_alarm_write_enable(),
        .pc_alarm_read_slot(),
        .pc_sched_write_valid(),
        .pc_sched_write_slot(),
        .pc_sched_write_hour_ten_bcd(),
        .pc_sched_write_hour_unit_bcd(),
        .pc_sched_write_min_ten_bcd(),
        .pc_sched_write_min_unit_bcd(),
        .pc_sched_write_sec_ten_bcd(),
        .pc_sched_write_sec_unit_bcd(),
        .pc_sched_write_type(),
        .pc_sched_write_enable(),
        .pc_sched_read_slot(),
        .pc_count_load_valid(),
        .pc_count_hour_ten_bcd(),
        .pc_count_hour_unit_bcd(),
        .pc_count_min_ten_bcd(),
        .pc_count_min_unit_bcd(),
        .pc_count_sec_ten_bcd(),
        .pc_count_sec_unit_bcd(),
        .pc_count_start_pulse(),
        .pc_count_stop_pulse(),
        .comm_status(comm_status),
        .comm_reply_mode(comm_reply_mode),
        .comm_reply_index(comm_reply_index),
        .comm_reply_text_ascii(),
        .comm_reply_text_len(),
        .comm_selected_slot(comm_selected_slot),
        .comm_message_valid(comm_message_valid),
        .comm_message_unread(comm_message_unread),
        .comm_message_count(comm_message_count),
        .comm_unread_count(comm_unread_count),
        .comm_scroll_line(comm_scroll_line),
        .comm_timestamp_ascii(comm_timestamp_ascii),
        .comm_message_len(comm_message_len),
        .comm_message_window_ascii(comm_message_window_ascii)
    );

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) tx_capture (
        .clk(clk),
        .rst(rst),
        .rx(uart_tx_line),
        .rx_valid(cap_valid),
        .rx_data(cap_data),
        .rx_busy(cap_busy)
    );

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            capture_count <= 8'd0;
            capture_done <= 1'b0;
        end else if (cap_valid && (capture_count < 8'd128)) begin
            captured[capture_count] <= cap_data;
            capture_count <= capture_count + 1'b1;
            if (cap_data == 8'h0A) begin
                capture_done <= 1'b1;
            end
        end
    end

    task send_byte;
        input [7:0] data;
        integer bit_idx;
        begin
            uart_rx_line = 1'b0;
            #(BIT_NS);
            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                uart_rx_line = data[bit_idx];
                #(BIT_NS);
            end
            uart_rx_line = 1'b1;
            #(BIT_NS);
        end
    endtask

    task send_frame;
        input [8*FRAME_LEN-1:0] data;
        integer idx;
        reg [7:0] ch;
        begin
            for (idx = 0; idx < FRAME_LEN; idx = idx + 1) begin
                ch = data[((FRAME_LEN - idx) * 8) - 1 -: 8];
                send_byte(ch);
            end
        end
    endtask

    initial begin
        uart_rx_line = 1'b1;
        #5000;
        rst = 1'b1;
        #5000;

        send_frame(MSG_FRAME);

        for (i = 0; i < 50000; i = i + 1) begin
            @(posedge clk);
            if (capture_done) begin
                i = 50000;
            end
        end

        if (!comm_message_valid) begin
            $display("FAIL tb_comm_ctrl_msg: message not valid");
            $finish;
        end
        if ((comm_message_count != 5'd1) || (comm_unread_count != 5'd1)) begin
            $display("FAIL tb_comm_ctrl_msg: bad counts count=%0d unread=%0d", comm_message_count, comm_unread_count);
            $finish;
        end
        if (comm_message_len != 7'd5) begin
            $display("FAIL tb_comm_ctrl_msg: bad message len %0d", comm_message_len);
            $finish;
        end
        if ((comm_timestamp_ascii[0 +: 8] != "2") ||
            (comm_timestamp_ascii[10*8 +: 8] != "T") ||
            (comm_message_window_ascii[0 +: 8] != "H") ||
            (comm_message_window_ascii[4*8 +: 8] != "o")) begin
            $display("FAIL tb_comm_ctrl_msg: bad stored payload");
            $finish;
        end
        if (!capture_done || (capture_count < 8'd16) ||
            (captured[0] != "#") || (captured[1] != "0") || (captured[2] != "4") ||
            (captured[3] != "|") || (captured[4] != "M") || (captured[5] != "S") ||
            (captured[6] != "G") || (captured[7] != "_") || (captured[8] != "S") ||
            (captured[9] != "T") || (captured[10] != "O") || (captured[11] != "R") ||
            (captured[12] != "E") || (captured[13] != "D")) begin
            $write("Captured response: ");
            for (i = 0; i < capture_count; i = i + 1) begin
                $write("%c", captured[i]);
            end
            $write("\n");
            $display("FAIL tb_comm_ctrl_msg: missing MSG_STORED response");
            $finish;
        end

        $display("PASS tb_comm_ctrl_msg");
        $finish;
    end
endmodule
