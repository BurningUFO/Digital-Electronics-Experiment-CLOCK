`timescale 1ns / 1ps

module tb_comm_ctrl_control;
    localparam integer CLK_FREQ  = 1_000_000;
    localparam integer BAUD_RATE = 100_000;
    localparam integer BIT_NS    = 10_000;
    localparam integer MAX_LEN   = 80;

    reg clk = 1'b0;
    reg rst = 1'b0;
    reg tick_1k = 1'b0;
    reg mode_comm = 1'b1;
    reg [2:0] mode_state = 3'b110;
    reg [15:0] sw = 16'h0000;
    reg btn_up_pulse = 1'b0;
    reg btn_down_pulse = 1'b0;
    reg btn_center_pulse = 1'b0;
    reg btn_right_pulse = 1'b0;
    reg uart_rx_line = 1'b1;

    reg [3:0] alarm_hour_ten = 4'd0;
    reg [3:0] alarm_hour_unit = 4'd7;
    reg [3:0] alarm_min_ten = 4'd3;
    reg [3:0] alarm_min_unit = 4'd0;
    reg [3:0] alarm_sec_ten = 4'd0;
    reg [3:0] alarm_sec_unit = 4'd0;
    reg alarm_enable = 1'b1;
    reg [2:0] sched_type = 3'd3;
    reg sched_enable = 1'b0;
    reg countdown_run = 1'b0;
    reg [3:0] count_hour_ten = 4'd0;
    reg [3:0] count_hour_unit = 4'd0;
    reg [3:0] count_min_ten = 4'd0;
    reg [3:0] count_min_unit = 4'd5;
    reg [3:0] count_sec_ten = 4'd3;
    reg [3:0] count_sec_unit = 4'd0;

    wire uart_tx_line;
    wire pc_alarm_write_valid;
    wire [2:0] pc_alarm_write_slot;
    wire [3:0] pc_alarm_write_hour_ten_bcd;
    wire [3:0] pc_alarm_write_hour_unit_bcd;
    wire [3:0] pc_alarm_write_min_ten_bcd;
    wire [3:0] pc_alarm_write_min_unit_bcd;
    wire [3:0] pc_alarm_write_sec_ten_bcd;
    wire [3:0] pc_alarm_write_sec_unit_bcd;
    wire pc_alarm_write_enable;
    wire [2:0] pc_alarm_read_slot;
    wire pc_sched_write_valid;
    wire [2:0] pc_sched_write_slot;
    wire [3:0] pc_sched_write_hour_ten_bcd;
    wire [3:0] pc_sched_write_hour_unit_bcd;
    wire [3:0] pc_sched_write_min_ten_bcd;
    wire [3:0] pc_sched_write_min_unit_bcd;
    wire [3:0] pc_sched_write_sec_ten_bcd;
    wire [3:0] pc_sched_write_sec_unit_bcd;
    wire [2:0] pc_sched_write_type;
    wire pc_sched_write_enable;
    wire [2:0] pc_sched_read_slot;
    wire pc_count_load_valid;
    wire [3:0] pc_count_hour_ten_bcd;
    wire [3:0] pc_count_hour_unit_bcd;
    wire [3:0] pc_count_min_ten_bcd;
    wire [3:0] pc_count_min_unit_bcd;
    wire [3:0] pc_count_sec_ten_bcd;
    wire [3:0] pc_count_sec_unit_bcd;
    wire pc_count_start_pulse;
    wire pc_count_stop_pulse;

    reg [15:0] tick_count = 16'd0;
    reg [7:0] captured [0:127];
    reg [7:0] capture_count = 8'd0;
    reg capture_done = 1'b0;
    reg capture_clear = 1'b0;
    reg [3:0] alarm_write_count = 4'd0;
    reg [3:0] sched_write_count = 4'd0;
    reg [3:0] count_load_count = 4'd0;
    reg [3:0] count_start_count = 4'd0;
    reg [3:0] count_stop_count = 4'd0;
    wire cap_valid;
    wire [7:0] cap_data;

    localparam integer ALARM_SET_LEN = 47;
    localparam integer ALARM_GET_LEN = 24;
    localparam integer SCHED_SET_LEN = 54;
    localparam integer SCHED_GET_LEN = 24;
    localparam integer COUNT_SET_LEN = 31;
    localparam integer COUNT_START_LEN = 20;
    localparam integer COUNT_STOP_LEN = 19;
    localparam integer COUNT_STATUS_LEN = 21;

    localparam [8*ALARM_SET_LEN-1:0] ALARM_SET_FRAME =
        "#10|ALARM_SET|slot=1;time=07:30:00;enable=1*66\n";
    localparam [8*ALARM_GET_LEN-1:0] ALARM_GET_FRAME =
        "#11|ALARM_GET|slot=1*52\n";
    localparam [8*SCHED_SET_LEN-1:0] SCHED_SET_FRAME =
        "#12|SCHED_SET|slot=2;time=08:45:10;type=3;enable=0*4D\n";
    localparam [8*SCHED_GET_LEN-1:0] SCHED_GET_FRAME =
        "#13|SCHED_GET|slot=2*59\n";
    localparam [8*COUNT_SET_LEN-1:0] COUNT_SET_FRAME =
        "#14|COUNT_SET|time=00:05:30*75\n";
    localparam [8*COUNT_START_LEN-1:0] COUNT_START_FRAME =
        "#15|COUNT_START|*58\n";
    localparam [8*COUNT_STOP_LEN-1:0] COUNT_STOP_FRAME =
        "#16|COUNT_STOP|*03\n";
    localparam [8*COUNT_STATUS_LEN-1:0] COUNT_STATUS_FRAME =
        "#17|COUNT_STATUS|*0E\n";
    localparam [8*ALARM_SET_LEN-1:0] BAD_ALARM_SLOT_FRAME =
        "#18|ALARM_SET|slot=8;time=07:30:00;enable=1*67\n";
    localparam [8*COUNT_SET_LEN-1:0] BAD_COUNT_TIME_FRAME =
        "#19|COUNT_SET|time=24:00:00*78\n";

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
        .countdown_run(countdown_run),
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
        .alarm_read_slot(pc_alarm_read_slot),
        .alarm_read_hour_ten_bcd(alarm_hour_ten),
        .alarm_read_hour_unit_bcd(alarm_hour_unit),
        .alarm_read_min_ten_bcd(alarm_min_ten),
        .alarm_read_min_unit_bcd(alarm_min_unit),
        .alarm_read_sec_ten_bcd(alarm_sec_ten),
        .alarm_read_sec_unit_bcd(alarm_sec_unit),
        .alarm_read_enable(alarm_enable),
        .sched_read_slot(pc_sched_read_slot),
        .sched_read_hour_ten_bcd(4'd0),
        .sched_read_hour_unit_bcd(4'd8),
        .sched_read_min_ten_bcd(4'd4),
        .sched_read_min_unit_bcd(4'd5),
        .sched_read_sec_ten_bcd(4'd1),
        .sched_read_sec_unit_bcd(4'd0),
        .sched_read_type(sched_type),
        .sched_read_enable(sched_enable),
        .count_hour_ten_bcd(count_hour_ten),
        .count_hour_unit_bcd(count_hour_unit),
        .count_min_ten_bcd(count_min_ten),
        .count_min_unit_bcd(count_min_unit),
        .count_sec_ten_bcd(count_sec_ten),
        .count_sec_unit_bcd(count_sec_unit),
        .uart_tx(uart_tx_line),
        .pc_time_load_valid(),
        .pc_hour_ten_bcd(),
        .pc_hour_unit_bcd(),
        .pc_min_ten_bcd(),
        .pc_min_unit_bcd(),
        .pc_sec_ten_bcd(),
        .pc_sec_unit_bcd(),
        .pc_date_load_valid(),
        .pc_year_thousand_bcd(),
        .pc_year_hundred_bcd(),
        .pc_year_ten_bcd(),
        .pc_year_unit_bcd(),
        .pc_month_ten_bcd(),
        .pc_month_unit_bcd(),
        .pc_day_ten_bcd(),
        .pc_day_unit_bcd(),
        .pc_weekday(),
        .pc_alarm_write_valid(pc_alarm_write_valid),
        .pc_alarm_write_slot(pc_alarm_write_slot),
        .pc_alarm_write_hour_ten_bcd(pc_alarm_write_hour_ten_bcd),
        .pc_alarm_write_hour_unit_bcd(pc_alarm_write_hour_unit_bcd),
        .pc_alarm_write_min_ten_bcd(pc_alarm_write_min_ten_bcd),
        .pc_alarm_write_min_unit_bcd(pc_alarm_write_min_unit_bcd),
        .pc_alarm_write_sec_ten_bcd(pc_alarm_write_sec_ten_bcd),
        .pc_alarm_write_sec_unit_bcd(pc_alarm_write_sec_unit_bcd),
        .pc_alarm_write_enable(pc_alarm_write_enable),
        .pc_alarm_read_slot(pc_alarm_read_slot),
        .pc_sched_write_valid(pc_sched_write_valid),
        .pc_sched_write_slot(pc_sched_write_slot),
        .pc_sched_write_hour_ten_bcd(pc_sched_write_hour_ten_bcd),
        .pc_sched_write_hour_unit_bcd(pc_sched_write_hour_unit_bcd),
        .pc_sched_write_min_ten_bcd(pc_sched_write_min_ten_bcd),
        .pc_sched_write_min_unit_bcd(pc_sched_write_min_unit_bcd),
        .pc_sched_write_sec_ten_bcd(pc_sched_write_sec_ten_bcd),
        .pc_sched_write_sec_unit_bcd(pc_sched_write_sec_unit_bcd),
        .pc_sched_write_type(pc_sched_write_type),
        .pc_sched_write_enable(pc_sched_write_enable),
        .pc_sched_read_slot(pc_sched_read_slot),
        .pc_count_load_valid(pc_count_load_valid),
        .pc_count_hour_ten_bcd(pc_count_hour_ten_bcd),
        .pc_count_hour_unit_bcd(pc_count_hour_unit_bcd),
        .pc_count_min_ten_bcd(pc_count_min_ten_bcd),
        .pc_count_min_unit_bcd(pc_count_min_unit_bcd),
        .pc_count_sec_ten_bcd(pc_count_sec_ten_bcd),
        .pc_count_sec_unit_bcd(pc_count_sec_unit_bcd),
        .pc_count_start_pulse(pc_count_start_pulse),
        .pc_count_stop_pulse(pc_count_stop_pulse),
        .comm_status(),
        .comm_reply_mode(),
        .comm_reply_index(),
        .comm_reply_text_ascii(),
        .comm_reply_text_len(),
        .comm_selected_slot(),
        .comm_message_valid(),
        .comm_message_unread(),
        .comm_message_count(),
        .comm_unread_count(),
        .comm_scroll_line(),
        .comm_timestamp_ascii(),
        .comm_message_len(),
        .comm_message_window_ascii()
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
        .rx_busy()
    );

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            capture_count <= 8'd0;
            capture_done <= 1'b0;
        end else if (capture_clear) begin
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

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            alarm_write_count <= 4'd0;
            sched_write_count <= 4'd0;
            count_load_count <= 4'd0;
            count_start_count <= 4'd0;
            count_stop_count <= 4'd0;
        end else if (capture_clear) begin
            alarm_write_count <= 4'd0;
            sched_write_count <= 4'd0;
            count_load_count <= 4'd0;
            count_start_count <= 4'd0;
            count_stop_count <= 4'd0;
        end else begin
            if (pc_alarm_write_valid) alarm_write_count <= alarm_write_count + 1'b1;
            if (pc_sched_write_valid) sched_write_count <= sched_write_count + 1'b1;
            if (pc_count_load_valid) count_load_count <= count_load_count + 1'b1;
            if (pc_count_start_pulse) count_start_count <= count_start_count + 1'b1;
            if (pc_count_stop_pulse) count_stop_count <= count_stop_count + 1'b1;
        end
    end

    task clear_capture;
        begin
            @(posedge clk);
            capture_clear = 1'b1;
            @(posedge clk);
            capture_clear = 1'b0;
        end
    endtask

    task wait_capture_done;
        integer wait_idx;
        begin
            for (wait_idx = 0; wait_idx < 90000; wait_idx = wait_idx + 1) begin
                @(posedge clk);
                if (capture_done) begin
                    wait_idx = 90000;
                end
            end
        end
    endtask

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
        input integer len;
        input [8*MAX_LEN-1:0] data;
        integer idx;
        reg [7:0] ch;
        begin
            for (idx = 0; idx < len; idx = idx + 1) begin
                ch = data[((MAX_LEN - idx) * 8) - 1 -: 8];
                send_byte(ch);
            end
        end
    endtask

    task expect_prefix;
        input integer len;
        input [8*MAX_LEN-1:0] text;
        integer idx;
        reg [7:0] exp_ch;
        begin
            if (!capture_done || (capture_count < len)) begin
                $write("Captured: ");
                for (idx = 0; idx < capture_count; idx = idx + 1) $write("%c", captured[idx]);
                $write("\n");
                $display("FAIL tb_comm_ctrl_control: missing response");
                $finish;
            end
            for (idx = 0; idx < len; idx = idx + 1) begin
                exp_ch = text[((MAX_LEN - idx) * 8) - 1 -: 8];
                if (captured[idx] != exp_ch) begin
                    $write("Captured: ");
                    for (i = 0; i < capture_count; i = i + 1) $write("%c", captured[i]);
                    $write("\n");
                    $display("FAIL tb_comm_ctrl_control: prefix byte %0d expected %c got %c", idx, exp_ch, captured[idx]);
                    $finish;
                end
            end
        end
    endtask

    initial begin
        #5000;
        rst = 1'b1;
        #5000;

        send_frame(ALARM_SET_LEN, {ALARM_SET_FRAME, {(MAX_LEN-ALARM_SET_LEN){8'h00}}});
        wait_capture_done;
        if ((alarm_write_count != 4'd1) || (pc_alarm_write_slot != 3'd1) ||
            (pc_alarm_write_hour_ten_bcd != 4'd0) || (pc_alarm_write_hour_unit_bcd != 4'd7) ||
            (pc_alarm_write_min_ten_bcd != 4'd3) || (pc_alarm_write_enable != 1'b1)) begin
            $display("FAIL tb_comm_ctrl_control: bad ALARM_SET write");
            $finish;
        end
        expect_prefix(28, {"#10|ACK|ack=10;cmd=ALARM_SET", {(MAX_LEN-28){8'h00}}});

        clear_capture;
        send_frame(ALARM_GET_LEN, {ALARM_GET_FRAME, {(MAX_LEN-ALARM_GET_LEN){8'h00}}});
        wait_capture_done;
        expect_prefix(39, {"#11|ALARM|slot=1;time=07:30:00;enable=1", {(MAX_LEN-39){8'h00}}});

        clear_capture;
        send_frame(SCHED_SET_LEN, {SCHED_SET_FRAME, {(MAX_LEN-SCHED_SET_LEN){8'h00}}});
        wait_capture_done;
        if ((sched_write_count != 4'd1) || (pc_sched_write_slot != 3'd2) ||
            (pc_sched_write_hour_unit_bcd != 4'd8) || (pc_sched_write_min_ten_bcd != 4'd4) ||
            (pc_sched_write_sec_ten_bcd != 4'd1) || (pc_sched_write_type != 3'd3) ||
            (pc_sched_write_enable != 1'b0)) begin
            $display("FAIL tb_comm_ctrl_control: bad SCHED_SET write");
            $finish;
        end
        expect_prefix(28, {"#12|ACK|ack=12;cmd=SCHED_SET", {(MAX_LEN-28){8'h00}}});

        clear_capture;
        send_frame(SCHED_GET_LEN, {SCHED_GET_FRAME, {(MAX_LEN-SCHED_GET_LEN){8'h00}}});
        wait_capture_done;
        expect_prefix(46, {"#13|SCHED|slot=2;time=08:45:10;type=3;enable=0", {(MAX_LEN-46){8'h00}}});

        clear_capture;
        send_frame(COUNT_SET_LEN, {COUNT_SET_FRAME, {(MAX_LEN-COUNT_SET_LEN){8'h00}}});
        wait_capture_done;
        if ((count_load_count != 4'd1) || (pc_count_min_unit_bcd != 4'd5) ||
            (pc_count_sec_ten_bcd != 4'd3)) begin
            $display("FAIL tb_comm_ctrl_control: bad COUNT_SET load");
            $finish;
        end
        expect_prefix(28, {"#14|ACK|ack=14;cmd=COUNT_SET", {(MAX_LEN-28){8'h00}}});

        clear_capture;
        send_frame(COUNT_START_LEN, {COUNT_START_FRAME, {(MAX_LEN-COUNT_START_LEN){8'h00}}});
        wait_capture_done;
        if (count_start_count != 4'd1) begin
            $display("FAIL tb_comm_ctrl_control: COUNT_START pulse missing");
            $finish;
        end
        expect_prefix(30, {"#15|ACK|ack=15;cmd=COUNT_START", {(MAX_LEN-30){8'h00}}});

        clear_capture;
        send_frame(COUNT_STOP_LEN, {COUNT_STOP_FRAME, {(MAX_LEN-COUNT_STOP_LEN){8'h00}}});
        wait_capture_done;
        if (count_stop_count != 4'd1) begin
            $display("FAIL tb_comm_ctrl_control: COUNT_STOP pulse missing");
            $finish;
        end
        expect_prefix(29, {"#16|ACK|ack=16;cmd=COUNT_STOP", {(MAX_LEN-29){8'h00}}});

        clear_capture;
        send_frame(COUNT_STATUS_LEN, {COUNT_STATUS_FRAME, {(MAX_LEN-COUNT_STATUS_LEN){8'h00}}});
        wait_capture_done;
        expect_prefix(36, {"#17|COUNT_STATUS|time=00:05:30;run=0", {(MAX_LEN-36){8'h00}}});

        clear_capture;
        send_frame(ALARM_SET_LEN, {BAD_ALARM_SLOT_FRAME, {(MAX_LEN-ALARM_SET_LEN){8'h00}}});
        wait_capture_done;
        if (alarm_write_count != 4'd0) begin
            $display("FAIL tb_comm_ctrl_control: bad slot caused write");
            $finish;
        end
        expect_prefix(15, {"#18|NACK|ack=18", {(MAX_LEN-15){8'h00}}});

        clear_capture;
        send_frame(COUNT_SET_LEN, {BAD_COUNT_TIME_FRAME, {(MAX_LEN-COUNT_SET_LEN){8'h00}}});
        wait_capture_done;
        if (count_load_count != 4'd0) begin
            $display("FAIL tb_comm_ctrl_control: bad count time caused load");
            $finish;
        end
        expect_prefix(15, {"#19|NACK|ack=19", {(MAX_LEN-15){8'h00}}});

        $display("PASS tb_comm_ctrl_control");
        $finish;
    end
endmodule
