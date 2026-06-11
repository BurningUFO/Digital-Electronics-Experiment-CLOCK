module notification_ctrl(
    input  clk,
    input  rst,
    input  tick_1k,
    input  tick_1h,
    input  btn_left_pulse,
    input  btn_right_pulse,
    input  btn_up_pulse,
    input  btn_down_pulse,
    input  btn_center_pulse,
    input  hourly_chime_pulse,
    input  countdown_done_pulse,
    input  alarm_event_valid,
    input  [2:0] alarm_event_slot,
    input  schedule_event_valid,
    input  [2:0] schedule_event_slot,
    output buzzer_out,
    output notify_active,
    output [1:0] notify_type,
    output [2:0] notify_slot,
    output reg alarm_event_ack_pulse,
    output reg alarm_snooze_set_pulse,
    output reg [3:0] alarm_snooze_add_min,
    output reg [2:0] alarm_snooze_slot_index,
    output reg schedule_event_ack_pulse
);
    localparam [1:0] TYPE_NONE      = 2'd0;
    localparam [1:0] TYPE_COUNTDOWN = 2'd1;
    localparam [1:0] TYPE_ALARM     = 2'd2;
    localparam [1:0] TYPE_SCHEDULE  = 2'd3;

    localparam [5:0] COUNTDOWN_MAX_SEC = 6'd30;
    localparam [5:0] ALARM_MAX_SEC     = 6'd60;
    localparam [5:0] SCHEDULE_MAX_SEC  = 6'd15;

    localparam [10:0] COUNTDOWN_PERIOD_MS = 11'd200;
    localparam [10:0] COUNTDOWN_ON_MS     = 11'd80;
    localparam [10:0] ALARM_PERIOD_MS     = 11'd1000;
    localparam [10:0] ALARM_ON_MS         = 11'd400;
    localparam [10:0] SCHEDULE_PERIOD_MS  = 11'd2000;
    localparam [10:0] SCHEDULE_ON_MS      = 11'd250;
    localparam [8:0] HOURLY_ON_MS         = 9'd100;
    localparam [8:0] HOURLY_OFF_MS        = 9'd100;
    localparam [8:0] HOURLY_SECOND_ON_MS  = HOURLY_ON_MS + HOURLY_OFF_MS;
    localparam [8:0] HOURLY_TOTAL_MS      = HOURLY_SECOND_ON_MS + HOURLY_ON_MS;

    reg countdown_pending_reg;
    reg [1:0] notify_type_reg;
    reg [2:0] notify_slot_reg;
    reg [5:0] ring_sec_cnt;
    reg [10:0] beep_ms_cnt;
    reg reminder_buzzer_reg;
    reg hourly_chime_active_reg;
    reg [8:0] hourly_chime_ms_cnt;

    wire [1:0] selected_type;
    wire [2:0] selected_slot;
    wire selected_active;
    wire event_changed;
    wire timeout_due;
    wire snooze_current;
    wire dismiss_current;
    wire countdown_pending_next;
    wire hourly_chime_buzzer;

    function [1:0] highest_type;
        input countdown_pending;
        input alarm_pending;
        input schedule_pending;
        begin
            if (countdown_pending) begin
                highest_type = TYPE_COUNTDOWN;
            end else if (alarm_pending) begin
                highest_type = TYPE_ALARM;
            end else if (schedule_pending) begin
                highest_type = TYPE_SCHEDULE;
            end else begin
                highest_type = TYPE_NONE;
            end
        end
    endfunction

    function [2:0] highest_slot;
        input countdown_pending;
        input alarm_pending;
        input [2:0] alarm_slot;
        input schedule_pending;
        input [2:0] schedule_slot;
        begin
            if (countdown_pending) begin
                highest_slot = 3'd0;
            end else if (alarm_pending) begin
                highest_slot = alarm_slot;
            end else if (schedule_pending) begin
                highest_slot = schedule_slot;
            end else begin
                highest_slot = 3'd0;
            end
        end
    endfunction

    function [5:0] max_ring_seconds;
        input [1:0] event_type;
        begin
            case (event_type)
                TYPE_COUNTDOWN: max_ring_seconds = COUNTDOWN_MAX_SEC;
                TYPE_ALARM:     max_ring_seconds = ALARM_MAX_SEC;
                TYPE_SCHEDULE:  max_ring_seconds = SCHEDULE_MAX_SEC;
                default:        max_ring_seconds = 6'd1;
            endcase
        end
    endfunction

    function [10:0] beep_period_ms;
        input [1:0] event_type;
        begin
            case (event_type)
                TYPE_COUNTDOWN: beep_period_ms = COUNTDOWN_PERIOD_MS;
                TYPE_ALARM:     beep_period_ms = ALARM_PERIOD_MS;
                TYPE_SCHEDULE:  beep_period_ms = SCHEDULE_PERIOD_MS;
                default:        beep_period_ms = 11'd1;
            endcase
        end
    endfunction

    function [10:0] beep_on_ms;
        input [1:0] event_type;
        begin
            case (event_type)
                TYPE_COUNTDOWN: beep_on_ms = COUNTDOWN_ON_MS;
                TYPE_ALARM:     beep_on_ms = ALARM_ON_MS;
                TYPE_SCHEDULE:  beep_on_ms = SCHEDULE_ON_MS;
                default:        beep_on_ms = 11'd0;
            endcase
        end
    endfunction

    assign selected_type = highest_type(countdown_pending_reg,
                                        alarm_event_valid,
                                        schedule_event_valid);
    assign selected_slot = highest_slot(countdown_pending_reg,
                                        alarm_event_valid,
                                        alarm_event_slot,
                                        schedule_event_valid,
                                        schedule_event_slot);
    assign selected_active = (selected_type != TYPE_NONE);
    assign event_changed = (selected_type != notify_type_reg) ||
                           (selected_slot != notify_slot_reg);
    assign timeout_due = selected_active &&
                         !event_changed &&
                         tick_1h &&
                         (ring_sec_cnt == (max_ring_seconds(selected_type) - 1'b1));
    assign snooze_current = selected_active &&
                            (selected_type == TYPE_ALARM) &&
                            (btn_up_pulse | btn_right_pulse | btn_down_pulse | btn_left_pulse);
    assign dismiss_current = selected_active &&
                             (btn_center_pulse | timeout_due | snooze_current);
    assign countdown_pending_next =
        (countdown_pending_reg &&
         !(dismiss_current && (selected_type == TYPE_COUNTDOWN))) ||
        countdown_done_pulse;

    assign notify_active = (notify_type_reg != TYPE_NONE);
    assign notify_type = notify_type_reg;
    assign notify_slot = notify_slot_reg;
    assign hourly_chime_buzzer =
        hourly_chime_active_reg &&
        ((hourly_chime_ms_cnt < HOURLY_ON_MS) ||
         ((hourly_chime_ms_cnt >= HOURLY_SECOND_ON_MS) &&
          (hourly_chime_ms_cnt < (HOURLY_SECOND_ON_MS + HOURLY_ON_MS))));
    assign buzzer_out = selected_active ? reminder_buzzer_reg : hourly_chime_buzzer;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            countdown_pending_reg <= 1'b0;
            notify_type_reg <= TYPE_NONE;
            notify_slot_reg <= 3'd0;
            ring_sec_cnt <= 6'd0;
            beep_ms_cnt <= 11'd0;
            reminder_buzzer_reg <= 1'b0;
            hourly_chime_active_reg <= 1'b0;
            hourly_chime_ms_cnt <= 9'd0;
            alarm_event_ack_pulse <= 1'b0;
            alarm_snooze_set_pulse <= 1'b0;
            alarm_snooze_add_min <= 4'd0;
            alarm_snooze_slot_index <= 3'd0;
            schedule_event_ack_pulse <= 1'b0;
        end else begin
            alarm_event_ack_pulse <= 1'b0;
            alarm_snooze_set_pulse <= 1'b0;
            alarm_snooze_add_min <= 4'd0;
            alarm_snooze_slot_index <= selected_slot;
            schedule_event_ack_pulse <= 1'b0;

            if (dismiss_current && (selected_type == TYPE_ALARM)) begin
                if (snooze_current) begin
                    alarm_snooze_set_pulse <= 1'b1;
                    alarm_snooze_slot_index <= selected_slot;
                    if (btn_up_pulse) begin
                        alarm_snooze_add_min <= 4'd1;
                    end else if (btn_right_pulse) begin
                        alarm_snooze_add_min <= 4'd3;
                    end else if (btn_down_pulse) begin
                        alarm_snooze_add_min <= 4'd5;
                    end else begin
                        alarm_snooze_add_min <= 4'd10;
                    end
                end else begin
                    alarm_event_ack_pulse <= 1'b1;
                end
            end

            if (dismiss_current && (selected_type == TYPE_SCHEDULE)) begin
                schedule_event_ack_pulse <= 1'b1;
            end

            countdown_pending_reg <= countdown_pending_next;
            notify_type_reg <= selected_type;
            notify_slot_reg <= selected_slot;

            if (!selected_active || dismiss_current || event_changed) begin
                ring_sec_cnt <= 6'd0;
            end else if (tick_1h) begin
                ring_sec_cnt <= ring_sec_cnt + 1'b1;
            end

            if (selected_active) begin
                hourly_chime_active_reg <= 1'b0;
                hourly_chime_ms_cnt <= 9'd0;
            end else if (hourly_chime_pulse) begin
                hourly_chime_active_reg <= 1'b1;
                hourly_chime_ms_cnt <= 9'd0;
            end else if (tick_1k && hourly_chime_active_reg) begin
                if (hourly_chime_ms_cnt == (HOURLY_TOTAL_MS - 1'b1)) begin
                    hourly_chime_active_reg <= 1'b0;
                    hourly_chime_ms_cnt <= 9'd0;
                end else begin
                    hourly_chime_ms_cnt <= hourly_chime_ms_cnt + 1'b1;
                end
            end

            if (!selected_active || dismiss_current) begin
                beep_ms_cnt <= 11'd0;
                reminder_buzzer_reg <= 1'b0;
            end else if (event_changed) begin
                beep_ms_cnt <= 11'd0;
                reminder_buzzer_reg <= 1'b1;
            end else if (tick_1k) begin
                if (beep_ms_cnt == (beep_period_ms(selected_type) - 1'b1)) begin
                    beep_ms_cnt <= 11'd0;
                    reminder_buzzer_reg <= 1'b1;
                end else begin
                    beep_ms_cnt <= beep_ms_cnt + 1'b1;
                    reminder_buzzer_reg <= (beep_ms_cnt < (beep_on_ms(selected_type) - 1'b1));
                end
            end
        end
    end
endmodule
