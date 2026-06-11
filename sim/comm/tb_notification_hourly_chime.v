module tb_notification_hourly_chime;
    reg clk = 1'b0;
    reg rst = 1'b0;
    reg tick_1k = 1'b0;
    reg tick_1h = 1'b0;
    reg btn_left_pulse = 1'b0;
    reg btn_right_pulse = 1'b0;
    reg btn_up_pulse = 1'b0;
    reg btn_down_pulse = 1'b0;
    reg btn_center_pulse = 1'b0;
    reg hourly_chime_pulse = 1'b0;
    reg countdown_done_pulse = 1'b0;
    reg alarm_event_valid = 1'b0;
    reg [2:0] alarm_event_slot = 3'd0;
    reg schedule_event_valid = 1'b0;
    reg [2:0] schedule_event_slot = 3'd0;

    wire buzzer_out;
    wire notify_active;
    wire [1:0] notify_type;
    wire [2:0] notify_slot;
    wire alarm_event_ack_pulse;
    wire alarm_snooze_set_pulse;
    wire [3:0] alarm_snooze_add_min;
    wire [2:0] alarm_snooze_slot_index;
    wire schedule_event_ack_pulse;

    notification_ctrl dut (
        .clk(clk),
        .rst(rst),
        .tick_1k(tick_1k),
        .tick_1h(tick_1h),
        .btn_left_pulse(btn_left_pulse),
        .btn_right_pulse(btn_right_pulse),
        .btn_up_pulse(btn_up_pulse),
        .btn_down_pulse(btn_down_pulse),
        .btn_center_pulse(btn_center_pulse),
        .hourly_chime_pulse(hourly_chime_pulse),
        .countdown_done_pulse(countdown_done_pulse),
        .alarm_event_valid(alarm_event_valid),
        .alarm_event_slot(alarm_event_slot),
        .schedule_event_valid(schedule_event_valid),
        .schedule_event_slot(schedule_event_slot),
        .buzzer_out(buzzer_out),
        .notify_active(notify_active),
        .notify_type(notify_type),
        .notify_slot(notify_slot),
        .alarm_event_ack_pulse(alarm_event_ack_pulse),
        .alarm_snooze_set_pulse(alarm_snooze_set_pulse),
        .alarm_snooze_add_min(alarm_snooze_add_min),
        .alarm_snooze_slot_index(alarm_snooze_slot_index),
        .schedule_event_ack_pulse(schedule_event_ack_pulse)
    );

    always #5 clk = ~clk;

    task pulse_hourly_chime;
        begin
            @(negedge clk);
            hourly_chime_pulse = 1'b1;
            @(negedge clk);
            hourly_chime_pulse = 1'b0;
        end
    endtask

    task tick_ms;
        begin
            @(negedge clk);
            tick_1k = 1'b1;
            @(negedge clk);
            tick_1k = 1'b0;
        end
    endtask

    integer i;

    initial begin
        repeat (2) @(negedge clk);
        rst = 1'b1;
        repeat (2) @(negedge clk);

        pulse_hourly_chime();
        @(posedge clk);
        #1;
        if (notify_active !== 1'b0 || notify_type !== 2'd0) begin
            $display("FAIL tb_notification_hourly_chime: hourly chime changed notify state");
            $finish;
        end
        if (buzzer_out !== 1'b1) begin
            $display("FAIL tb_notification_hourly_chime: first hourly beep did not start");
            $finish;
        end

        for (i = 0; i < 100; i = i + 1) begin
            tick_ms();
        end
        #1;
        if (buzzer_out !== 1'b0) begin
            $display("FAIL tb_notification_hourly_chime: off gap did not start");
            $finish;
        end

        for (i = 0; i < 100; i = i + 1) begin
            tick_ms();
        end
        #1;
        if (buzzer_out !== 1'b1) begin
            $display("FAIL tb_notification_hourly_chime: second hourly beep did not start");
            $finish;
        end

        for (i = 0; i < 100; i = i + 1) begin
            tick_ms();
        end
        #1;
        if (buzzer_out !== 1'b0) begin
            $display("FAIL tb_notification_hourly_chime: hourly chime did not stop");
            $finish;
        end

        pulse_hourly_chime();
        @(negedge clk);
        alarm_event_slot = 3'd4;
        alarm_event_valid = 1'b1;
        @(posedge clk);
        #1;
        if (notify_active !== 1'b1 || notify_type !== 2'd2 || notify_slot !== 3'd4) begin
            $display("FAIL tb_notification_hourly_chime: alarm did not override chime");
            $finish;
        end

        $display("PASS tb_notification_hourly_chime");
        $finish;
    end
endmodule
