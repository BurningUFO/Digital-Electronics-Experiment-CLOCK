// -----------------------------------------------------------------------------
// 8 槽位闹钟控制器。
//
// 每个槽保存 HH:MM:SS 和 enable 状态，到点后进入 pending 队列。
// notification_ctrl 负责实际蜂鸣和用户确认，本模块只维护事件、贪睡和最近闹钟。
//
// PC 直接写入：
// - pc_alarm_write_valid 会直接覆盖指定槽位时间和开关。
// - 写入同时清除该槽 pending、snooze 和 match，避免旧事件残留。
// -----------------------------------------------------------------------------
module alarm_ctrl(
    input  clk,
    input  tick_1k,
    input  rst,
    input  alarm_slot_inc_pulse,
    input  alarm_slot_dec_pulse,
    input  alarm_hour_inc_pulse,
    input  alarm_hour_dec_pulse,
    input  alarm_min_inc_pulse,
    input  alarm_min_dec_pulse,
    input  alarm_sec_inc_pulse,
    input  alarm_sec_dec_pulse,
    input  alarm_enable_inc_pulse,
    input  alarm_enable_dec_pulse,
    input  alarm_enable_toggle_pulse,
    input  alarm_event_ack_pulse,
    input  snooze_1_pulse,
    input  snooze_3_pulse,
    input  snooze_5_pulse,
    input  snooze_10_pulse,
    input  snooze_set_pulse,
    input  [3:0] snooze_add_min,
    input  [2:0] snooze_slot_index,
    input  [3:0] cur_sec_ten_bcd,
    input  [3:0] cur_sec_unit_bcd,
    input  [3:0] cur_min_ten_bcd,
    input  [3:0] cur_min_unit_bcd,
    input  [3:0] cur_hour_unit_bcd,
    input  [3:0] cur_hour_ten_bcd,
    input  pc_alarm_write_valid,
    input  [2:0] pc_alarm_write_slot,
    input  [3:0] pc_alarm_write_hour_ten_bcd,
    input  [3:0] pc_alarm_write_hour_unit_bcd,
    input  [3:0] pc_alarm_write_min_ten_bcd,
    input  [3:0] pc_alarm_write_min_unit_bcd,
    input  [3:0] pc_alarm_write_sec_ten_bcd,
    input  [3:0] pc_alarm_write_sec_unit_bcd,
    input  pc_alarm_write_enable,
    input  [2:0] pc_alarm_read_slot,
    output [3:0] alarm_sec_ten_bcd,
    output [3:0] alarm_sec_unit_bcd,
    output [3:0] alarm_hour_ten_bcd,
    output [3:0] alarm_hour_unit_bcd,
    output [3:0] alarm_min_ten_bcd,
    output [3:0] alarm_min_unit_bcd,
    output alarm_enable,
    output [3:0] pc_alarm_read_hour_ten_bcd,
    output [3:0] pc_alarm_read_hour_unit_bcd,
    output [3:0] pc_alarm_read_min_ten_bcd,
    output [3:0] pc_alarm_read_min_unit_bcd,
    output [3:0] pc_alarm_read_sec_ten_bcd,
    output [3:0] pc_alarm_read_sec_unit_bcd,
    output pc_alarm_read_enable,
    output alarm_match,
    output alarm_beep,
    output [2:0] alarm_selected_slot,
    output [7:0] alarm_slot_enable_mask,
    output [7:0] alarm_slot_selected_mask,
    output [7:0] alarm_pending_mask,
    output next_alarm_valid,
    output [2:0] next_alarm_slot,
    output [3:0] next_alarm_sec_ten_bcd,
    output [3:0] next_alarm_sec_unit_bcd,
    output [3:0] next_alarm_min_ten_bcd,
    output [3:0] next_alarm_min_unit_bcd,
    output [3:0] next_alarm_hour_ten_bcd,
    output [3:0] next_alarm_hour_unit_bcd,
    output alarm_event_valid,
    output [2:0] alarm_event_slot
);
    localparam [1:0] BEEP_IDLE      = 2'd0;
    localparam [1:0] BEEP_ON        = 2'd1;
    localparam [1:0] BEEP_OFF       = 2'd2;
    localparam [1:0] BEEP_GROUP_GAP = 2'd3;
    localparam integer BEEP_ON_MS   = 10'd120;
    localparam integer BEEP_OFF_MS  = 10'd120;
    localparam integer GROUP_GAP_MS = 10'd500;
    reg [2:0] selected_slot_reg;
    reg [7:0] alarm_enable_reg;
    reg [7:0] snooze_active_reg;
    reg [7:0] pending_mask_reg;
    reg [7:0] match_d;

    reg [1:0] alarm_hour_ten_reg [0:7];
    reg [3:0] alarm_hour_unit_reg [0:7];
    reg [2:0] alarm_min_ten_reg [0:7];
    reg [3:0] alarm_min_unit_reg [0:7];
    reg [2:0] alarm_sec_ten_reg [0:7];
    reg [3:0] alarm_sec_unit_reg [0:7];

    reg [1:0] snooze_hour_ten_reg [0:7];
    reg [3:0] snooze_hour_unit_reg [0:7];
    reg [2:0] snooze_min_ten_reg [0:7];
    reg [3:0] snooze_min_unit_reg [0:7];
    reg [2:0] snooze_sec_ten_reg [0:7];
    reg [3:0] snooze_sec_unit_reg [0:7];

    reg alarm_beep_reg;
    reg [1:0] beep_state;
    reg [1:0] beep_index;
    reg [1:0] group_index;
    reg [9:0] beep_tick_cnt;

    reg [7:0] normal_match_mask_reg;
    reg [7:0] snooze_match_mask_reg;
    reg [7:0] pending_next;
    reg [7:0] snooze_active_next;
    reg snooze_request_reg;
    reg [3:0] snooze_request_min_reg;
    reg next_alarm_valid_reg;
    reg [2:0] next_alarm_slot_reg;
    reg [1:0] next_alarm_best_hour_ten_reg;
    reg [3:0] next_alarm_best_hour_unit_reg;
    reg [2:0] next_alarm_best_min_ten_reg;
    reg [3:0] next_alarm_best_min_unit_reg;
    reg [2:0] next_alarm_best_sec_ten_reg;
    reg [3:0] next_alarm_best_sec_unit_reg;
    reg [4:0] next_alarm_scan_index_reg;
    reg next_alarm_scan_valid_reg;
    reg next_alarm_scan_future_found_reg;
    reg [2:0] next_alarm_scan_slot_reg;
    reg [1:0] next_alarm_scan_hour_ten_reg;
    reg [3:0] next_alarm_scan_hour_unit_reg;
    reg [2:0] next_alarm_scan_min_ten_reg;
    reg [3:0] next_alarm_scan_min_unit_reg;
    reg [2:0] next_alarm_scan_sec_ten_reg;
    reg [3:0] next_alarm_scan_sec_unit_reg;
    reg next_alarm_candidate_valid;
    reg [2:0] next_alarm_candidate_slot;
    reg [1:0] next_alarm_candidate_hour_ten;
    reg [3:0] next_alarm_candidate_hour_unit;
    reg [2:0] next_alarm_candidate_min_ten;
    reg [3:0] next_alarm_candidate_min_unit;
    reg [2:0] next_alarm_candidate_sec_ten;
    reg [3:0] next_alarm_candidate_sec_unit;

    wire [7:0] match_mask;
    wire [7:0] trigger_mask;
    wire [7:0] snooze_trigger_mask;
    wire [7:0] current_event_mask;
    wire [7:0] pending_after_current_clear_mask;
    wire [2:0] current_event_slot;
    wire [7:0] selected_slot_mask;
    wire [12:0] snooze_target_hm;
    wire current_snooze_pulse;
    wire current_event_clear_pulse;
    wire [3:0] next_alarm_candidate_index;
    wire [5:0] hour_inc_value;
    wire [5:0] hour_dec_value;
    wire [6:0] min_inc_value;
    wire [6:0] min_dec_value;
    wire [6:0] sec_inc_value;
    wire [6:0] sec_dec_value;
    wire event_start_pulse;

    integer i;

    // 以下增减函数保持 BCD 格式，小时范围固定 00..23。
    function [5:0] inc_hour;
        input [1:0] ten_in;
        input [3:0] unit_in;
        begin
            if (ten_in == 2'd2 && unit_in == 4'd3) begin
                inc_hour = {2'd0, 4'd0};
            end else if (unit_in == 4'd9) begin
                inc_hour = {ten_in + 1'b1, 4'd0};
            end else begin
                inc_hour = {ten_in, unit_in + 1'b1};
            end
        end
    endfunction

    function [5:0] dec_hour;
        input [1:0] ten_in;
        input [3:0] unit_in;
        begin
            if (ten_in == 2'd0 && unit_in == 4'd0) begin
                dec_hour = {2'd2, 4'd3};
            end else if (unit_in == 4'd0) begin
                dec_hour = {ten_in - 1'b1, 4'd9};
            end else begin
                dec_hour = {ten_in, unit_in - 1'b1};
            end
        end
    endfunction

    function [6:0] inc_60;
        input [2:0] ten_in;
        input [3:0] unit_in;
        begin
            if (ten_in == 3'd5 && unit_in == 4'd9) begin
                inc_60 = {3'd0, 4'd0};
            end else if (unit_in == 4'd9) begin
                inc_60 = {ten_in + 1'b1, 4'd0};
            end else begin
                inc_60 = {ten_in, unit_in + 1'b1};
            end
        end
    endfunction

    function [6:0] dec_60;
        input [2:0] ten_in;
        input [3:0] unit_in;
        begin
            if (ten_in == 3'd0 && unit_in == 4'd0) begin
                dec_60 = {3'd5, 4'd9};
            end else if (unit_in == 4'd0) begin
                dec_60 = {ten_in - 1'b1, 4'd9};
            end else begin
                dec_60 = {ten_in, unit_in - 1'b1};
            end
        end
    endfunction

    function [2:0] first_set_index;
        input [7:0] mask;
        begin
            if (mask[0]) begin
                first_set_index = 3'd0;
            end else if (mask[1]) begin
                first_set_index = 3'd1;
            end else if (mask[2]) begin
                first_set_index = 3'd2;
            end else if (mask[3]) begin
                first_set_index = 3'd3;
            end else if (mask[4]) begin
                first_set_index = 3'd4;
            end else if (mask[5]) begin
                first_set_index = 3'd5;
            end else if (mask[6]) begin
                first_set_index = 3'd6;
            end else begin
                first_set_index = 3'd7;
            end
        end
    endfunction

    function [7:0] first_set_mask;
        input [7:0] mask;
        begin
            if (mask[0]) begin
                first_set_mask = 8'b0000_0001;
            end else if (mask[1]) begin
                first_set_mask = 8'b0000_0010;
            end else if (mask[2]) begin
                first_set_mask = 8'b0000_0100;
            end else if (mask[3]) begin
                first_set_mask = 8'b0000_1000;
            end else if (mask[4]) begin
                first_set_mask = 8'b0001_0000;
            end else if (mask[5]) begin
                first_set_mask = 8'b0010_0000;
            end else if (mask[6]) begin
                first_set_mask = 8'b0100_0000;
            end else if (mask[7]) begin
                first_set_mask = 8'b1000_0000;
            end else begin
                first_set_mask = 8'b0000_0000;
            end
        end
    endfunction

    function time_ge_current;
        input [1:0] hour_ten;
        input [3:0] hour_unit;
        input [2:0] min_ten;
        input [3:0] min_unit;
        input [2:0] sec_ten;
        input [3:0] sec_unit;
        begin
            time_ge_current =
                ({hour_ten, hour_unit, min_ten, min_unit, sec_ten, sec_unit} >=
                 {cur_hour_ten_bcd[1:0], cur_hour_unit_bcd,
                  cur_min_ten_bcd[2:0], cur_min_unit_bcd,
                  cur_sec_ten_bcd[2:0], cur_sec_unit_bcd});
        end
    endfunction

    function time_less_than_scan_best;
        input [1:0] hour_ten;
        input [3:0] hour_unit;
        input [2:0] min_ten;
        input [3:0] min_unit;
        input [2:0] sec_ten;
        input [3:0] sec_unit;
        begin
            time_less_than_scan_best =
                ({hour_ten, hour_unit, min_ten, min_unit, sec_ten, sec_unit} <
                 {next_alarm_scan_hour_ten_reg, next_alarm_scan_hour_unit_reg,
                  next_alarm_scan_min_ten_reg, next_alarm_scan_min_unit_reg,
                  next_alarm_scan_sec_ten_reg, next_alarm_scan_sec_unit_reg});
        end
    endfunction

    function [5:0] inc_hour_no_wrap_flag;
        input [1:0] ten_in;
        input [3:0] unit_in;
        begin
            inc_hour_no_wrap_flag = inc_hour(ten_in, unit_in);
        end
    endfunction

    function [12:0] add_snooze_hm;
        input [3:0] base_hour_ten;
        input [3:0] base_hour_unit;
        input [3:0] base_min_ten;
        input [3:0] base_min_unit;
        input [3:0] add_min;
        reg [1:0] hour_ten_tmp;
        reg [3:0] hour_unit_tmp;
        reg [2:0] min_ten_tmp;
        reg [3:0] min_unit_tmp;
        reg [5:0] hour_tmp;
        reg [3:0] add_unit_tmp;
        reg add_ten_tmp;
        reg [4:0] unit_sum_tmp;
        begin
            hour_ten_tmp = base_hour_ten[1:0];
            hour_unit_tmp = base_hour_unit;
            min_ten_tmp = base_min_ten[2:0];
            min_unit_tmp = base_min_unit;
            add_ten_tmp = (add_min == 4'd10);

            case (add_min)
                4'd1: add_unit_tmp = 4'd1;
                4'd3: add_unit_tmp = 4'd3;
                4'd5: add_unit_tmp = 4'd5;
                default: add_unit_tmp = 4'd0;
            endcase

            if (add_ten_tmp) begin
                if (min_ten_tmp == 3'd5) begin
                    min_ten_tmp = 3'd0;
                    hour_tmp = inc_hour_no_wrap_flag(hour_ten_tmp, hour_unit_tmp);
                    hour_ten_tmp = hour_tmp[5:4];
                    hour_unit_tmp = hour_tmp[3:0];
                end else begin
                    min_ten_tmp = min_ten_tmp + 1'b1;
                end
            end else begin
                unit_sum_tmp = {1'b0, min_unit_tmp} + {1'b0, add_unit_tmp};

                if (unit_sum_tmp >= 5'd10) begin
                    min_unit_tmp = unit_sum_tmp - 5'd10;
                    if (min_ten_tmp == 3'd5) begin
                        min_ten_tmp = 3'd0;
                        hour_tmp = inc_hour_no_wrap_flag(hour_ten_tmp, hour_unit_tmp);
                        hour_ten_tmp = hour_tmp[5:4];
                        hour_unit_tmp = hour_tmp[3:0];
                    end else begin
                        min_ten_tmp = min_ten_tmp + 1'b1;
                    end
                end else begin
                    min_unit_tmp = unit_sum_tmp[3:0];
                end
            end

            add_snooze_hm = {hour_ten_tmp, hour_unit_tmp, min_ten_tmp, min_unit_tmp};
        end
    endfunction

    assign snooze_target_hm = add_snooze_hm(cur_hour_ten_bcd, cur_hour_unit_bcd,
                                            cur_min_ten_bcd, cur_min_unit_bcd,
                                            snooze_request_min_reg);
    assign next_alarm_candidate_index = next_alarm_scan_index_reg[3:0] - 4'd1;
    assign selected_slot_mask = 8'b0000_0001 << selected_slot_reg;
    assign current_event_slot = first_set_index(pending_mask_reg);
    assign current_event_mask = first_set_mask(pending_mask_reg);
    assign pending_after_current_clear_mask = pending_mask_reg & ~current_event_mask;
    assign current_snooze_pulse = (|pending_mask_reg) & snooze_request_reg & ~alarm_event_ack_pulse;
    assign current_event_clear_pulse = alarm_event_ack_pulse | current_snooze_pulse;
    assign match_mask = normal_match_mask_reg | snooze_match_mask_reg;
    assign trigger_mask = match_mask & ~match_d;
    assign snooze_trigger_mask = snooze_match_mask_reg & ~match_d;
    assign event_start_pulse = (tick_1k & (|trigger_mask)) |
                               (current_event_clear_pulse & (|pending_after_current_clear_mask));

    assign hour_inc_value = inc_hour(alarm_hour_ten_reg[selected_slot_reg],
                                     alarm_hour_unit_reg[selected_slot_reg]);
    assign hour_dec_value = dec_hour(alarm_hour_ten_reg[selected_slot_reg],
                                     alarm_hour_unit_reg[selected_slot_reg]);
    assign min_inc_value = inc_60(alarm_min_ten_reg[selected_slot_reg],
                                  alarm_min_unit_reg[selected_slot_reg]);
    assign min_dec_value = dec_60(alarm_min_ten_reg[selected_slot_reg],
                                  alarm_min_unit_reg[selected_slot_reg]);
    assign sec_inc_value = inc_60(alarm_sec_ten_reg[selected_slot_reg],
                                  alarm_sec_unit_reg[selected_slot_reg]);
    assign sec_dec_value = dec_60(alarm_sec_ten_reg[selected_slot_reg],
                                  alarm_sec_unit_reg[selected_slot_reg]);

    assign alarm_sec_ten_bcd   = {1'b0, alarm_sec_ten_reg[selected_slot_reg]};
    assign alarm_sec_unit_bcd  = alarm_sec_unit_reg[selected_slot_reg];
    assign alarm_hour_ten_bcd  = {2'b00, alarm_hour_ten_reg[selected_slot_reg]};
    assign alarm_hour_unit_bcd = alarm_hour_unit_reg[selected_slot_reg];
    assign alarm_min_ten_bcd   = {1'b0, alarm_min_ten_reg[selected_slot_reg]};
    assign alarm_min_unit_bcd  = alarm_min_unit_reg[selected_slot_reg];
    assign alarm_enable        = alarm_enable_reg[selected_slot_reg];
    assign pc_alarm_read_hour_ten_bcd = {2'b00, alarm_hour_ten_reg[pc_alarm_read_slot]};
    assign pc_alarm_read_hour_unit_bcd = alarm_hour_unit_reg[pc_alarm_read_slot];
    assign pc_alarm_read_min_ten_bcd = {1'b0, alarm_min_ten_reg[pc_alarm_read_slot]};
    assign pc_alarm_read_min_unit_bcd = alarm_min_unit_reg[pc_alarm_read_slot];
    assign pc_alarm_read_sec_ten_bcd = {1'b0, alarm_sec_ten_reg[pc_alarm_read_slot]};
    assign pc_alarm_read_sec_unit_bcd = alarm_sec_unit_reg[pc_alarm_read_slot];
    assign pc_alarm_read_enable = alarm_enable_reg[pc_alarm_read_slot];
    assign alarm_match         = |match_mask;
    assign alarm_beep          = alarm_beep_reg;
    assign alarm_selected_slot = selected_slot_reg;
    assign alarm_slot_enable_mask = alarm_enable_reg;
    assign alarm_slot_selected_mask = selected_slot_mask;
    assign alarm_pending_mask = pending_mask_reg;
    assign alarm_event_valid = |pending_mask_reg;
    assign alarm_event_slot = current_event_slot;
    assign next_alarm_valid = next_alarm_valid_reg;
    assign next_alarm_slot = next_alarm_slot_reg;
    assign next_alarm_sec_ten_bcd = next_alarm_valid_reg ? {1'b0, next_alarm_best_sec_ten_reg} : 4'd0;
    assign next_alarm_sec_unit_bcd = next_alarm_valid_reg ? next_alarm_best_sec_unit_reg : 4'd0;
    assign next_alarm_min_ten_bcd = next_alarm_valid_reg ? {1'b0, next_alarm_best_min_ten_reg} : 4'd0;
    assign next_alarm_min_unit_bcd = next_alarm_valid_reg ? next_alarm_best_min_unit_reg : 4'd0;
    assign next_alarm_hour_ten_bcd = next_alarm_valid_reg ? {2'b00, next_alarm_best_hour_ten_reg} : 4'd0;
    assign next_alarm_hour_unit_bcd = next_alarm_valid_reg ? next_alarm_best_hour_unit_reg : 4'd0;

    always @(*) begin
        normal_match_mask_reg = 8'b0000_0000;
        snooze_match_mask_reg = 8'b0000_0000;

        for (i = 0; i < 8; i = i + 1) begin
            if (alarm_enable_reg[i] &&
                (alarm_hour_ten_reg[i] == cur_hour_ten_bcd[1:0]) &&
                (alarm_hour_unit_reg[i] == cur_hour_unit_bcd) &&
                (alarm_min_ten_reg[i] == cur_min_ten_bcd[2:0]) &&
                (alarm_min_unit_reg[i] == cur_min_unit_bcd) &&
                (alarm_sec_ten_reg[i] == cur_sec_ten_bcd[2:0]) &&
                (alarm_sec_unit_reg[i] == cur_sec_unit_bcd)) begin
                normal_match_mask_reg[i] = 1'b1;
            end

            if (snooze_active_reg[i] &&
                (snooze_hour_ten_reg[i] == cur_hour_ten_bcd[1:0]) &&
                (snooze_hour_unit_reg[i] == cur_hour_unit_bcd) &&
                (snooze_min_ten_reg[i] == cur_min_ten_bcd[2:0]) &&
                (snooze_min_unit_reg[i] == cur_min_unit_bcd) &&
                (snooze_sec_ten_reg[i] == cur_sec_ten_bcd[2:0]) &&
                (snooze_sec_unit_reg[i] == cur_sec_unit_bcd)) begin
                snooze_match_mask_reg[i] = 1'b1;
            end
        end
    end

    always @(*) begin
        snooze_request_reg = 1'b0;
        snooze_request_min_reg = 4'd0;

        if (snooze_1_pulse) begin
            snooze_request_reg = 1'b1;
            snooze_request_min_reg = 4'd1;
        end else if (snooze_3_pulse) begin
            snooze_request_reg = 1'b1;
            snooze_request_min_reg = 4'd3;
        end else if (snooze_5_pulse) begin
            snooze_request_reg = 1'b1;
            snooze_request_min_reg = 4'd5;
        end else if (snooze_10_pulse) begin
            snooze_request_reg = 1'b1;
            snooze_request_min_reg = 4'd10;
        end else if (snooze_set_pulse && (snooze_add_min != 4'd0)) begin
            snooze_request_reg = 1'b1;
            if (snooze_add_min > 4'd10) begin
                snooze_request_min_reg = 4'd10;
            end else begin
                snooze_request_min_reg = snooze_add_min;
            end
        end
    end

    always @(*) begin
        pending_next = pending_mask_reg;
        if (current_event_clear_pulse) begin
            pending_next = pending_next & ~current_event_mask;
        end
        if (tick_1k) begin
            pending_next = pending_next | trigger_mask;
        end
    end

    always @(*) begin
        snooze_active_next = snooze_active_reg;
        if (tick_1k) begin
            snooze_active_next = snooze_active_next & ~snooze_trigger_mask;
        end
        if (current_snooze_pulse) begin
            snooze_active_next[snooze_slot_index] = 1'b1;
        end
    end

    always @(*) begin
        next_alarm_candidate_valid = 1'b0;
        next_alarm_candidate_slot = next_alarm_candidate_index[2:0];
        next_alarm_candidate_hour_ten = 2'd0;
        next_alarm_candidate_hour_unit = 4'd0;
        next_alarm_candidate_min_ten = 3'd0;
        next_alarm_candidate_min_unit = 4'd0;
        next_alarm_candidate_sec_ten = 3'd0;
        next_alarm_candidate_sec_unit = 4'd0;

        if (next_alarm_scan_index_reg != 5'd0 && !next_alarm_candidate_index[3]) begin
            if (alarm_enable_reg[next_alarm_candidate_index[2:0]]) begin
                next_alarm_candidate_valid = 1'b1;
                next_alarm_candidate_hour_ten = alarm_hour_ten_reg[next_alarm_candidate_index[2:0]];
                next_alarm_candidate_hour_unit = alarm_hour_unit_reg[next_alarm_candidate_index[2:0]];
                next_alarm_candidate_min_ten = alarm_min_ten_reg[next_alarm_candidate_index[2:0]];
                next_alarm_candidate_min_unit = alarm_min_unit_reg[next_alarm_candidate_index[2:0]];
                next_alarm_candidate_sec_ten = alarm_sec_ten_reg[next_alarm_candidate_index[2:0]];
                next_alarm_candidate_sec_unit = alarm_sec_unit_reg[next_alarm_candidate_index[2:0]];
            end
        end else if (next_alarm_scan_index_reg != 5'd0) begin
            if (snooze_active_reg[next_alarm_candidate_index[2:0]]) begin
                next_alarm_candidate_valid = 1'b1;
                next_alarm_candidate_hour_ten = snooze_hour_ten_reg[next_alarm_candidate_index[2:0]];
                next_alarm_candidate_hour_unit = snooze_hour_unit_reg[next_alarm_candidate_index[2:0]];
                next_alarm_candidate_min_ten = snooze_min_ten_reg[next_alarm_candidate_index[2:0]];
                next_alarm_candidate_min_unit = snooze_min_unit_reg[next_alarm_candidate_index[2:0]];
                next_alarm_candidate_sec_ten = snooze_sec_ten_reg[next_alarm_candidate_index[2:0]];
                next_alarm_candidate_sec_unit = snooze_sec_unit_reg[next_alarm_candidate_index[2:0]];
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            selected_slot_reg <= 3'd0;
            alarm_enable_reg <= 8'b0000_0000;
            snooze_active_reg <= 8'b0000_0000;
            pending_mask_reg <= 8'b0000_0000;
            match_d <= 8'b0000_0000;
            alarm_beep_reg <= 1'b0;
            beep_state <= BEEP_IDLE;
            beep_index <= 2'd0;
            group_index <= 2'd0;
            beep_tick_cnt <= 10'd0;
            next_alarm_valid_reg <= 1'b0;
            next_alarm_slot_reg <= 3'd0;
            next_alarm_best_hour_ten_reg <= 2'd0;
            next_alarm_best_hour_unit_reg <= 4'd0;
            next_alarm_best_min_ten_reg <= 3'd0;
            next_alarm_best_min_unit_reg <= 4'd0;
            next_alarm_best_sec_ten_reg <= 3'd0;
            next_alarm_best_sec_unit_reg <= 4'd0;
            next_alarm_scan_index_reg <= 5'd0;
            next_alarm_scan_valid_reg <= 1'b0;
            next_alarm_scan_future_found_reg <= 1'b0;
            next_alarm_scan_slot_reg <= 3'd0;
            next_alarm_scan_hour_ten_reg <= 2'd0;
            next_alarm_scan_hour_unit_reg <= 4'd0;
            next_alarm_scan_min_ten_reg <= 3'd0;
            next_alarm_scan_min_unit_reg <= 4'd0;
            next_alarm_scan_sec_ten_reg <= 3'd0;
            next_alarm_scan_sec_unit_reg <= 4'd0;

            for (i = 0; i < 8; i = i + 1) begin
                alarm_hour_ten_reg[i] <= 2'd0;
                alarm_hour_unit_reg[i] <= 4'd0;
                alarm_min_ten_reg[i] <= 3'd0;
                alarm_min_unit_reg[i] <= 4'd0;
                alarm_sec_ten_reg[i] <= 3'd0;
                alarm_sec_unit_reg[i] <= 4'd0;
                snooze_hour_ten_reg[i] <= 2'd0;
                snooze_hour_unit_reg[i] <= 4'd0;
                snooze_min_ten_reg[i] <= 3'd0;
                snooze_min_unit_reg[i] <= 4'd0;
                snooze_sec_ten_reg[i] <= 3'd0;
                snooze_sec_unit_reg[i] <= 4'd0;
            end
        end else begin
            pending_mask_reg <= pending_next;
            snooze_active_reg <= snooze_active_next;
            if (next_alarm_scan_index_reg == 5'd16) begin
                next_alarm_scan_index_reg <= 5'd0;
            end else begin
                next_alarm_scan_index_reg <= next_alarm_scan_index_reg + 1'b1;
            end

            if (next_alarm_scan_index_reg == 5'd0) begin
                next_alarm_valid_reg <= next_alarm_scan_valid_reg;
                next_alarm_slot_reg <= next_alarm_scan_slot_reg;
                next_alarm_best_hour_ten_reg <= next_alarm_scan_hour_ten_reg;
                next_alarm_best_hour_unit_reg <= next_alarm_scan_hour_unit_reg;
                next_alarm_best_min_ten_reg <= next_alarm_scan_min_ten_reg;
                next_alarm_best_min_unit_reg <= next_alarm_scan_min_unit_reg;
                next_alarm_best_sec_ten_reg <= next_alarm_scan_sec_ten_reg;
                next_alarm_best_sec_unit_reg <= next_alarm_scan_sec_unit_reg;
                next_alarm_scan_valid_reg <= 1'b0;
                next_alarm_scan_future_found_reg <= 1'b0;
                next_alarm_scan_slot_reg <= 3'd0;
                next_alarm_scan_hour_ten_reg <= 2'd0;
                next_alarm_scan_hour_unit_reg <= 4'd0;
                next_alarm_scan_min_ten_reg <= 3'd0;
                next_alarm_scan_min_unit_reg <= 4'd0;
                next_alarm_scan_sec_ten_reg <= 3'd0;
                next_alarm_scan_sec_unit_reg <= 4'd0;
            end

            if (next_alarm_candidate_valid) begin
                if (time_ge_current(next_alarm_candidate_hour_ten,
                                    next_alarm_candidate_hour_unit,
                                    next_alarm_candidate_min_ten,
                                    next_alarm_candidate_min_unit,
                                    next_alarm_candidate_sec_ten,
                                    next_alarm_candidate_sec_unit)) begin
                    if (!next_alarm_scan_future_found_reg ||
                        time_less_than_scan_best(next_alarm_candidate_hour_ten,
                                                 next_alarm_candidate_hour_unit,
                                                 next_alarm_candidate_min_ten,
                                                 next_alarm_candidate_min_unit,
                                                 next_alarm_candidate_sec_ten,
                                                 next_alarm_candidate_sec_unit)) begin
                        next_alarm_scan_valid_reg <= 1'b1;
                        next_alarm_scan_future_found_reg <= 1'b1;
                        next_alarm_scan_slot_reg <= next_alarm_candidate_slot;
                        next_alarm_scan_hour_ten_reg <= next_alarm_candidate_hour_ten;
                        next_alarm_scan_hour_unit_reg <= next_alarm_candidate_hour_unit;
                        next_alarm_scan_min_ten_reg <= next_alarm_candidate_min_ten;
                        next_alarm_scan_min_unit_reg <= next_alarm_candidate_min_unit;
                        next_alarm_scan_sec_ten_reg <= next_alarm_candidate_sec_ten;
                        next_alarm_scan_sec_unit_reg <= next_alarm_candidate_sec_unit;
                    end
                end else if (!next_alarm_scan_future_found_reg &&
                             (!next_alarm_scan_valid_reg ||
                              time_less_than_scan_best(next_alarm_candidate_hour_ten,
                                                       next_alarm_candidate_hour_unit,
                                                       next_alarm_candidate_min_ten,
                                                       next_alarm_candidate_min_unit,
                                                       next_alarm_candidate_sec_ten,
                                                       next_alarm_candidate_sec_unit))) begin
                    next_alarm_scan_valid_reg <= 1'b1;
                    next_alarm_scan_slot_reg <= next_alarm_candidate_slot;
                    next_alarm_scan_hour_ten_reg <= next_alarm_candidate_hour_ten;
                    next_alarm_scan_hour_unit_reg <= next_alarm_candidate_hour_unit;
                    next_alarm_scan_min_ten_reg <= next_alarm_candidate_min_ten;
                    next_alarm_scan_min_unit_reg <= next_alarm_candidate_min_unit;
                    next_alarm_scan_sec_ten_reg <= next_alarm_candidate_sec_ten;
                    next_alarm_scan_sec_unit_reg <= next_alarm_candidate_sec_unit;
                end
            end

            if (tick_1k) begin
                match_d <= match_mask;
            end

            if (!pc_alarm_write_valid) begin
                if (alarm_slot_inc_pulse) begin
                    selected_slot_reg <= selected_slot_reg + 1'b1;
                end else if (alarm_slot_dec_pulse) begin
                    selected_slot_reg <= selected_slot_reg - 1'b1;
                end

                if (alarm_enable_toggle_pulse) begin
                    alarm_enable_reg[selected_slot_reg] <= ~alarm_enable_reg[selected_slot_reg];
                end else if (alarm_enable_inc_pulse) begin
                    alarm_enable_reg[selected_slot_reg] <= 1'b1;
                end else if (alarm_enable_dec_pulse) begin
                    alarm_enable_reg[selected_slot_reg] <= 1'b0;
                end

                if (alarm_hour_inc_pulse) begin
                    alarm_hour_ten_reg[selected_slot_reg] <= hour_inc_value[5:4];
                    alarm_hour_unit_reg[selected_slot_reg] <= hour_inc_value[3:0];
                end else if (alarm_hour_dec_pulse) begin
                    alarm_hour_ten_reg[selected_slot_reg] <= hour_dec_value[5:4];
                    alarm_hour_unit_reg[selected_slot_reg] <= hour_dec_value[3:0];
                end

                if (alarm_min_inc_pulse) begin
                    alarm_min_ten_reg[selected_slot_reg] <= min_inc_value[6:4];
                    alarm_min_unit_reg[selected_slot_reg] <= min_inc_value[3:0];
                end else if (alarm_min_dec_pulse) begin
                    alarm_min_ten_reg[selected_slot_reg] <= min_dec_value[6:4];
                    alarm_min_unit_reg[selected_slot_reg] <= min_dec_value[3:0];
                end

                if (alarm_sec_inc_pulse) begin
                    alarm_sec_ten_reg[selected_slot_reg] <= sec_inc_value[6:4];
                    alarm_sec_unit_reg[selected_slot_reg] <= sec_inc_value[3:0];
                end else if (alarm_sec_dec_pulse) begin
                    alarm_sec_ten_reg[selected_slot_reg] <= sec_dec_value[6:4];
                    alarm_sec_unit_reg[selected_slot_reg] <= sec_dec_value[3:0];
                end
            end

            if (current_snooze_pulse) begin
                snooze_hour_ten_reg[snooze_slot_index] <= snooze_target_hm[12:11];
                snooze_hour_unit_reg[snooze_slot_index] <= snooze_target_hm[10:7];
                snooze_min_ten_reg[snooze_slot_index] <= snooze_target_hm[6:4];
                snooze_min_unit_reg[snooze_slot_index] <= snooze_target_hm[3:0];
                snooze_sec_ten_reg[snooze_slot_index] <= cur_sec_ten_bcd[2:0];
                snooze_sec_unit_reg[snooze_slot_index] <= cur_sec_unit_bcd;
            end

            if (pc_alarm_write_valid) begin
                alarm_hour_ten_reg[pc_alarm_write_slot] <= pc_alarm_write_hour_ten_bcd[1:0];
                alarm_hour_unit_reg[pc_alarm_write_slot] <= pc_alarm_write_hour_unit_bcd;
                alarm_min_ten_reg[pc_alarm_write_slot] <= pc_alarm_write_min_ten_bcd[2:0];
                alarm_min_unit_reg[pc_alarm_write_slot] <= pc_alarm_write_min_unit_bcd;
                alarm_sec_ten_reg[pc_alarm_write_slot] <= pc_alarm_write_sec_ten_bcd[2:0];
                alarm_sec_unit_reg[pc_alarm_write_slot] <= pc_alarm_write_sec_unit_bcd;
                alarm_enable_reg[pc_alarm_write_slot] <= pc_alarm_write_enable;
                pending_mask_reg[pc_alarm_write_slot] <= 1'b0;
                snooze_active_reg[pc_alarm_write_slot] <= 1'b0;
                match_d[pc_alarm_write_slot] <= 1'b0;
            end

            if (current_event_clear_pulse) begin
                alarm_beep_reg <= 1'b0;
                beep_state <= BEEP_IDLE;
                beep_index <= 2'd0;
                group_index <= 2'd0;
                beep_tick_cnt <= 10'd0;

                if (|pending_after_current_clear_mask) begin
                    alarm_beep_reg <= 1'b1;
                    beep_state <= BEEP_ON;
                end
            end else if (event_start_pulse) begin
                alarm_beep_reg <= 1'b1;
                beep_state <= BEEP_ON;
                beep_index <= 2'd0;
                group_index <= 2'd0;
                beep_tick_cnt <= 10'd0;
            end else if (tick_1k) begin
                case (beep_state)
                    BEEP_IDLE: begin
                        alarm_beep_reg <= 1'b0;
                        beep_index <= 2'd0;
                        group_index <= 2'd0;
                        beep_tick_cnt <= 10'd0;
                    end

                    BEEP_ON: begin
                        alarm_beep_reg <= 1'b1;

                        if (beep_tick_cnt == BEEP_ON_MS - 1'b1) begin
                            alarm_beep_reg <= 1'b0;
                            beep_tick_cnt <= 10'd0;

                            if (beep_index == 2'd2) begin
                                if (group_index == 2'd2) begin
                                    beep_state <= BEEP_IDLE;
                                end else begin
                                    beep_state <= BEEP_GROUP_GAP;
                                end
                            end else begin
                                beep_state <= BEEP_OFF;
                            end
                        end else begin
                            beep_tick_cnt <= beep_tick_cnt + 1'b1;
                        end
                    end

                    BEEP_OFF: begin
                        alarm_beep_reg <= 1'b0;

                        if (beep_tick_cnt == BEEP_OFF_MS - 1'b1) begin
                            beep_tick_cnt <= 10'd0;
                            beep_index <= beep_index + 1'b1;
                            alarm_beep_reg <= 1'b1;
                            beep_state <= BEEP_ON;
                        end else begin
                            beep_tick_cnt <= beep_tick_cnt + 1'b1;
                        end
                    end

                    default: begin
                        alarm_beep_reg <= 1'b0;

                        if (beep_tick_cnt == GROUP_GAP_MS - 1'b1) begin
                            beep_tick_cnt <= 10'd0;
                            beep_index <= 2'd0;
                            group_index <= group_index + 1'b1;
                            alarm_beep_reg <= 1'b1;
                            beep_state <= BEEP_ON;
                        end else begin
                            beep_tick_cnt <= beep_tick_cnt + 1'b1;
                        end
                    end
                endcase
            end
        end
    end
endmodule
