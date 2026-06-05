`timescale 1ns / 1ps

module tb_comm_ctrl_time;
    localparam integer CLK_FREQ  = 1_000_000;
    localparam integer BAUD_RATE = 100_000;
    localparam integer BIT_NS    = 10_000;
    localparam integer TIME_SET_FRAME_LEN = 56;
    localparam integer TIME_GET_FRAME_LEN = 17;

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

    reg [3:0] cur_year_thousand_bcd = 4'd2;
    reg [3:0] cur_year_hundred_bcd = 4'd0;
    reg [3:0] cur_year_ten_bcd = 4'd2;
    reg [3:0] cur_year_unit_bcd = 4'd6;
    reg [3:0] cur_month_ten_bcd = 4'd0;
    reg [3:0] cur_month_unit_bcd = 4'd6;
    reg [3:0] cur_day_ten_bcd = 4'd0;
    reg [3:0] cur_day_unit_bcd = 4'd5;
    reg [2:0] cur_weekday = 3'd5;
    reg [3:0] cur_hour_ten_bcd = 4'd1;
    reg [3:0] cur_hour_unit_bcd = 4'd5;
    reg [3:0] cur_min_ten_bcd = 4'd0;
    reg [3:0] cur_min_unit_bcd = 4'd3;
    reg [3:0] cur_sec_ten_bcd = 4'd0;
    reg [3:0] cur_sec_unit_bcd = 4'd0;

    wire uart_tx_line;
    wire [2:0] comm_status;
    wire pc_time_load_valid;
    wire [3:0] pc_hour_ten_bcd;
    wire [3:0] pc_hour_unit_bcd;
    wire [3:0] pc_min_ten_bcd;
    wire [3:0] pc_min_unit_bcd;
    wire [3:0] pc_sec_ten_bcd;
    wire [3:0] pc_sec_unit_bcd;
    wire pc_date_load_valid;
    wire [3:0] pc_year_thousand_bcd;
    wire [3:0] pc_year_hundred_bcd;
    wire [3:0] pc_year_ten_bcd;
    wire [3:0] pc_year_unit_bcd;
    wire [3:0] pc_month_ten_bcd;
    wire [3:0] pc_month_unit_bcd;
    wire [3:0] pc_day_ten_bcd;
    wire [3:0] pc_day_unit_bcd;
    wire [2:0] pc_weekday;

    reg [15:0] tick_count = 16'd0;
    reg [7:0] captured [0:127];
    reg [7:0] capture_count = 8'd0;
    reg capture_done = 1'b0;
    reg capture_clear = 1'b0;
    reg [3:0] load_count = 4'd0;
    reg load_pair_error = 1'b0;
    reg [3:0] saved_year_thousand_bcd;
    reg [3:0] saved_year_hundred_bcd;
    reg [3:0] saved_year_ten_bcd;
    reg [3:0] saved_year_unit_bcd;
    reg [3:0] saved_month_ten_bcd;
    reg [3:0] saved_month_unit_bcd;
    reg [3:0] saved_day_ten_bcd;
    reg [3:0] saved_day_unit_bcd;
    reg [3:0] saved_hour_ten_bcd;
    reg [3:0] saved_hour_unit_bcd;
    reg [3:0] saved_min_ten_bcd;
    reg [3:0] saved_min_unit_bcd;
    reg [3:0] saved_sec_ten_bcd;
    reg [3:0] saved_sec_unit_bcd;
    reg [2:0] saved_weekday;
    wire cap_valid;
    wire [7:0] cap_data;

    localparam [8*TIME_SET_FRAME_LEN-1:0] TIME_SET_FRAME =
        "#03|TIME_SET|date=2026-06-05;time=15:03:00;weekday=5*60\n";
    localparam [8*TIME_GET_FRAME_LEN-1:0] TIME_GET_FRAME =
        "#04|TIME_GET|*18\n";
    localparam [8*TIME_SET_FRAME_LEN-1:0] BAD_MONTH_FRAME =
        "#05|TIME_SET|date=2026-13-05;time=15:03:00;weekday=5*62\n";
    localparam [8*TIME_SET_FRAME_LEN-1:0] BAD_DAY_FRAME =
        "#06|TIME_SET|date=2026-02-29;time=15:03:00;weekday=5*6F\n";
    localparam [8*TIME_SET_FRAME_LEN-1:0] BAD_WEEKDAY_FRAME =
        "#07|TIME_SET|date=2026-06-05;time=15:03:00;weekday=0*61\n";

    localparam integer ACK_LEN = 31;
    localparam integer TIME_LEN = 52;
    localparam integer NACK_LEN = 32;
    localparam [8*ACK_LEN-1:0] ACK_TIME_SET =
        "#03|ACK|ack=03;cmd=TIME_SET*79\n";
    localparam [8*TIME_LEN-1:0] TIME_RESPONSE =
        "#04|TIME|date=2026-06-05;time=15:03:00;weekday=5*7A\n";
    localparam [8*NACK_LEN-1:0] NACK_BAD_MONTH =
        "#05|NACK|ack=05;err=BAD_TIME*3D\n";
    localparam [8*NACK_LEN-1:0] NACK_BAD_DAY =
        "#06|NACK|ack=06;err=BAD_TIME*3D\n";
    localparam [8*NACK_LEN-1:0] NACK_BAD_WEEKDAY =
        "#07|NACK|ack=07;err=BAD_TIME*3D\n";

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
        .cur_year_thousand_bcd(cur_year_thousand_bcd),
        .cur_year_hundred_bcd(cur_year_hundred_bcd),
        .cur_year_ten_bcd(cur_year_ten_bcd),
        .cur_year_unit_bcd(cur_year_unit_bcd),
        .cur_month_ten_bcd(cur_month_ten_bcd),
        .cur_month_unit_bcd(cur_month_unit_bcd),
        .cur_day_ten_bcd(cur_day_ten_bcd),
        .cur_day_unit_bcd(cur_day_unit_bcd),
        .cur_weekday(cur_weekday),
        .cur_hour_ten_bcd(cur_hour_ten_bcd),
        .cur_hour_unit_bcd(cur_hour_unit_bcd),
        .cur_min_ten_bcd(cur_min_ten_bcd),
        .cur_min_unit_bcd(cur_min_unit_bcd),
        .cur_sec_ten_bcd(cur_sec_ten_bcd),
        .cur_sec_unit_bcd(cur_sec_unit_bcd),
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
        .pc_hour_ten_bcd(pc_hour_ten_bcd),
        .pc_hour_unit_bcd(pc_hour_unit_bcd),
        .pc_min_ten_bcd(pc_min_ten_bcd),
        .pc_min_unit_bcd(pc_min_unit_bcd),
        .pc_sec_ten_bcd(pc_sec_ten_bcd),
        .pc_sec_unit_bcd(pc_sec_unit_bcd),
        .pc_date_load_valid(pc_date_load_valid),
        .pc_year_thousand_bcd(pc_year_thousand_bcd),
        .pc_year_hundred_bcd(pc_year_hundred_bcd),
        .pc_year_ten_bcd(pc_year_ten_bcd),
        .pc_year_unit_bcd(pc_year_unit_bcd),
        .pc_month_ten_bcd(pc_month_ten_bcd),
        .pc_month_unit_bcd(pc_month_unit_bcd),
        .pc_day_ten_bcd(pc_day_ten_bcd),
        .pc_day_unit_bcd(pc_day_unit_bcd),
        .pc_weekday(pc_weekday),
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
            load_count <= 4'd0;
            load_pair_error <= 1'b0;
            saved_year_thousand_bcd <= 4'd0;
            saved_year_hundred_bcd <= 4'd0;
            saved_year_ten_bcd <= 4'd0;
            saved_year_unit_bcd <= 4'd0;
            saved_month_ten_bcd <= 4'd0;
            saved_month_unit_bcd <= 4'd0;
            saved_day_ten_bcd <= 4'd0;
            saved_day_unit_bcd <= 4'd0;
            saved_hour_ten_bcd <= 4'd0;
            saved_hour_unit_bcd <= 4'd0;
            saved_min_ten_bcd <= 4'd0;
            saved_min_unit_bcd <= 4'd0;
            saved_sec_ten_bcd <= 4'd0;
            saved_sec_unit_bcd <= 4'd0;
            saved_weekday <= 3'd0;
        end else if (capture_clear) begin
            load_count <= 4'd0;
            load_pair_error <= 1'b0;
        end else if (pc_time_load_valid || pc_date_load_valid) begin
            if (!pc_time_load_valid || !pc_date_load_valid) begin
                load_pair_error <= 1'b1;
            end
            load_count <= load_count + 1'b1;
            saved_year_thousand_bcd <= pc_year_thousand_bcd;
            saved_year_hundred_bcd <= pc_year_hundred_bcd;
            saved_year_ten_bcd <= pc_year_ten_bcd;
            saved_year_unit_bcd <= pc_year_unit_bcd;
            saved_month_ten_bcd <= pc_month_ten_bcd;
            saved_month_unit_bcd <= pc_month_unit_bcd;
            saved_day_ten_bcd <= pc_day_ten_bcd;
            saved_day_unit_bcd <= pc_day_unit_bcd;
            saved_hour_ten_bcd <= pc_hour_ten_bcd;
            saved_hour_unit_bcd <= pc_hour_unit_bcd;
            saved_min_ten_bcd <= pc_min_ten_bcd;
            saved_min_unit_bcd <= pc_min_unit_bcd;
            saved_sec_ten_bcd <= pc_sec_ten_bcd;
            saved_sec_unit_bcd <= pc_sec_unit_bcd;
            saved_weekday <= pc_weekday;
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

    task send_time_set_frame;
        input [8*TIME_SET_FRAME_LEN-1:0] data;
        integer idx;
        reg [7:0] ch;
        begin
            for (idx = 0; idx < TIME_SET_FRAME_LEN; idx = idx + 1) begin
                ch = data[((TIME_SET_FRAME_LEN - idx) * 8) - 1 -: 8];
                send_byte(ch);
            end
        end
    endtask

    task send_time_get_frame;
        input [8*TIME_GET_FRAME_LEN-1:0] data;
        integer idx;
        reg [7:0] ch;
        begin
            for (idx = 0; idx < TIME_GET_FRAME_LEN; idx = idx + 1) begin
                ch = data[((TIME_GET_FRAME_LEN - idx) * 8) - 1 -: 8];
                send_byte(ch);
            end
        end
    endtask

    task expect_capture;
        input integer expected_len;
        input [8*128-1:0] expected;
        integer idx;
        reg [7:0] exp_ch;
        begin
            if (!capture_done || (capture_count != expected_len)) begin
                $write("Captured response: ");
                for (idx = 0; idx < capture_count; idx = idx + 1) begin
                    $write("%c", captured[idx]);
                end
                $write("\n");
                $display("FAIL tb_comm_ctrl_time: expected len %0d got %0d", expected_len, capture_count);
                $finish;
            end
            for (idx = 0; idx < expected_len; idx = idx + 1) begin
                exp_ch = expected[((128 - idx) * 8) - 1 -: 8];
                if (captured[idx] != exp_ch) begin
                    $write("Captured response: ");
                    for (i = 0; i < capture_count; i = i + 1) begin
                        $write("%c", captured[i]);
                    end
                    $write("\n");
                    $display("FAIL tb_comm_ctrl_time: byte %0d expected %c got %c", idx, exp_ch, captured[idx]);
                    $finish;
                end
            end
        end
    endtask

    initial begin
        uart_rx_line = 1'b1;
        #5000;
        rst = 1'b1;
        #5000;

        send_time_set_frame(TIME_SET_FRAME);
        wait_capture_done;

        if ((load_count != 4'd1) || load_pair_error) begin
            if (load_count == 4'd0) begin
                $display("FAIL tb_comm_ctrl_time: TIME_SET did not assert load");
            end else begin
                $display("FAIL tb_comm_ctrl_time: TIME_SET load pulse was not one cycle");
            end
            $finish;
        end
        if ((saved_year_thousand_bcd != 4'd2) || (saved_year_hundred_bcd != 4'd0) ||
            (saved_year_ten_bcd != 4'd2) || (saved_year_unit_bcd != 4'd6) ||
            (saved_month_ten_bcd != 4'd0) || (saved_month_unit_bcd != 4'd6) ||
            (saved_day_ten_bcd != 4'd0) || (saved_day_unit_bcd != 4'd5) ||
            (saved_hour_ten_bcd != 4'd1) || (saved_hour_unit_bcd != 4'd5) ||
            (saved_min_ten_bcd != 4'd0) || (saved_min_unit_bcd != 4'd3) ||
            (saved_sec_ten_bcd != 4'd0) || (saved_sec_unit_bcd != 4'd0) ||
            (saved_weekday != 3'd5)) begin
            $display("FAIL tb_comm_ctrl_time: loaded BCD fields mismatch");
            $finish;
        end
        expect_capture(ACK_LEN, {ACK_TIME_SET, {(128-ACK_LEN){8'h00}}});

        clear_capture;
        send_time_get_frame(TIME_GET_FRAME);
        wait_capture_done;
        if (load_count != 4'd0) begin
            $display("FAIL tb_comm_ctrl_time: TIME_GET asserted load");
            $finish;
        end
        expect_capture(TIME_LEN, {TIME_RESPONSE, {(128-TIME_LEN){8'h00}}});

        clear_capture;
        send_time_set_frame(BAD_MONTH_FRAME);
        wait_capture_done;
        if (load_count != 4'd0) begin
            $display("FAIL tb_comm_ctrl_time: bad month asserted load");
            $finish;
        end
        expect_capture(NACK_LEN, {NACK_BAD_MONTH, {(128-NACK_LEN){8'h00}}});

        clear_capture;
        send_time_set_frame(BAD_DAY_FRAME);
        wait_capture_done;
        if (load_count != 4'd0) begin
            $display("FAIL tb_comm_ctrl_time: bad day asserted load");
            $finish;
        end
        expect_capture(NACK_LEN, {NACK_BAD_DAY, {(128-NACK_LEN){8'h00}}});

        clear_capture;
        send_time_set_frame(BAD_WEEKDAY_FRAME);
        wait_capture_done;
        if (load_count != 4'd0) begin
            $display("FAIL tb_comm_ctrl_time: bad weekday asserted load");
            $finish;
        end
        expect_capture(NACK_LEN, {NACK_BAD_WEEKDAY, {(128-NACK_LEN){8'h00}}});

        $display("PASS tb_comm_ctrl_time");
        $finish;
    end
endmodule
