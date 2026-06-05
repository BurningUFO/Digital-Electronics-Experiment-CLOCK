module schedule_ctrl(
    input  clk,
    input  rst,
    input  schedule_slot_inc_pulse,
    input  schedule_slot_dec_pulse,
    input  [7:0] schedule_slot_switches,
    input  schedule_hour_inc_pulse,
    input  schedule_hour_dec_pulse,
    input  schedule_min_inc_pulse,
    input  schedule_min_dec_pulse,
    input  schedule_sec_inc_pulse,
    input  schedule_sec_dec_pulse,
    input  schedule_type_inc_pulse,
    input  schedule_type_dec_pulse,
    input  schedule_enable_inc_pulse,
    input  schedule_enable_dec_pulse,
    input  schedule_enable_toggle_pulse,
    input  schedule_event_ack_pulse,
    input  [3:0] cur_sec_ten_bcd,
    input  [3:0] cur_sec_unit_bcd,
    input  [3:0] cur_min_ten_bcd,
    input  [3:0] cur_min_unit_bcd,
    input  [3:0] cur_hour_ten_bcd,
    input  [3:0] cur_hour_unit_bcd,
    output [3:0] schedule_sec_ten_bcd,
    output [3:0] schedule_sec_unit_bcd,
    output [3:0] schedule_min_ten_bcd,
    output [3:0] schedule_min_unit_bcd,
    output [3:0] schedule_hour_ten_bcd,
    output [3:0] schedule_hour_unit_bcd,
    output selected_schedule_enable,
    output [2:0] selected_schedule_type,
    output [2:0] schedule_selected_slot,
    output [7:0] schedule_slot_enable_mask,
    output [7:0] schedule_slot_selected_mask,
    output [7:0] schedule_pending_mask,
    output next_schedule_valid,
    output [2:0] next_schedule_slot,
    output [3:0] next_schedule_sec_ten_bcd,
    output [3:0] next_schedule_sec_unit_bcd,
    output [3:0] next_schedule_min_ten_bcd,
    output [3:0] next_schedule_min_unit_bcd,
    output [3:0] next_schedule_hour_ten_bcd,
    output [3:0] next_schedule_hour_unit_bcd,
    output schedule_event_valid,
    output [2:0] schedule_event_slot
);
    reg [2:0] selected_slot_reg;
    reg [7:0] enable_mask_reg;
    reg [7:0] pending_mask_reg;
    reg [7:0] match_d;

    reg [1:0] hour_ten_reg [0:7];
    reg [3:0] hour_unit_reg [0:7];
    reg [2:0] min_ten_reg [0:7];
    reg [3:0] min_unit_reg [0:7];
    reg [2:0] sec_ten_reg [0:7];
    reg [3:0] sec_unit_reg [0:7];
    reg [2:0] type_reg [0:7];

    reg [7:0] match_mask_reg;
    reg [7:0] pending_next;
    reg next_valid_reg;
    reg [2:0] next_slot_reg;
    reg [1:0] best_hour_ten_reg;
    reg [3:0] best_hour_unit_reg;
    reg [2:0] best_min_ten_reg;
    reg [3:0] best_min_unit_reg;
    reg [2:0] best_sec_ten_reg;
    reg [3:0] best_sec_unit_reg;
    reg [3:0] scan_index_reg;
    reg scan_valid_reg;
    reg scan_future_found_reg;
    reg [2:0] scan_slot_reg;
    reg [1:0] scan_hour_ten_reg;
    reg [3:0] scan_hour_unit_reg;
    reg [2:0] scan_min_ten_reg;
    reg [3:0] scan_min_unit_reg;
    reg [2:0] scan_sec_ten_reg;
    reg [3:0] scan_sec_unit_reg;

    wire [7:0] trigger_mask;
    wire [7:0] current_event_mask;
    wire [7:0] selected_slot_mask;
    wire [2:0] switch_selected_slot;
    wire [2:0] scan_candidate_slot;
    wire [5:0] hour_inc_value;
    wire [5:0] hour_dec_value;
    wire [6:0] min_inc_value;
    wire [6:0] min_dec_value;
    wire [6:0] sec_inc_value;
    wire [6:0] sec_dec_value;

    integer i;

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

    function [1:0] default_hour_ten;
        input [2:0] slot;
        begin
            case (slot)
                3'd2,
                3'd3,
                3'd4,
                3'd5,
                3'd6:
                    default_hour_ten = 2'd1;
                3'd7: default_hour_ten = 2'd2;
                default: default_hour_ten = 2'd0;
            endcase
        end
    endfunction

    function [3:0] default_hour_unit;
        input [2:0] slot;
        begin
            case (slot)
                3'd0: default_hour_unit = 4'd8;
                3'd1: default_hour_unit = 4'd9;
                3'd2: default_hour_unit = 4'd0;
                3'd3: default_hour_unit = 4'd1;
                3'd4: default_hour_unit = 4'd4;
                3'd5: default_hour_unit = 4'd5;
                3'd6: default_hour_unit = 4'd9;
                default: default_hour_unit = 4'd1;
            endcase
        end
    endfunction

    function [2:0] default_min_ten;
        input [2:0] slot;
        begin
            case (slot)
                3'd1,
                3'd3,
                3'd5: default_min_ten = 3'd4;
                3'd7: default_min_ten = 3'd3;
                default: default_min_ten = 3'd0;
            endcase
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
                 {scan_hour_ten_reg, scan_hour_unit_reg,
                  scan_min_ten_reg, scan_min_unit_reg,
                  scan_sec_ten_reg, scan_sec_unit_reg});
        end
    endfunction

    assign switch_selected_slot = first_set_index(schedule_slot_switches);
    assign selected_slot_mask = 8'b0000_0001 << selected_slot_reg;
    assign current_event_mask = first_set_mask(pending_mask_reg);
    assign trigger_mask = match_mask_reg & ~match_d;
    assign scan_candidate_slot = scan_index_reg[2:0] - 3'd1;

    assign hour_inc_value = inc_hour(hour_ten_reg[selected_slot_reg],
                                     hour_unit_reg[selected_slot_reg]);
    assign hour_dec_value = dec_hour(hour_ten_reg[selected_slot_reg],
                                     hour_unit_reg[selected_slot_reg]);
    assign min_inc_value = inc_60(min_ten_reg[selected_slot_reg],
                                  min_unit_reg[selected_slot_reg]);
    assign min_dec_value = dec_60(min_ten_reg[selected_slot_reg],
                                  min_unit_reg[selected_slot_reg]);
    assign sec_inc_value = inc_60(sec_ten_reg[selected_slot_reg],
                                  sec_unit_reg[selected_slot_reg]);
    assign sec_dec_value = dec_60(sec_ten_reg[selected_slot_reg],
                                  sec_unit_reg[selected_slot_reg]);

    assign schedule_sec_ten_bcd = {1'b0, sec_ten_reg[selected_slot_reg]};
    assign schedule_sec_unit_bcd = sec_unit_reg[selected_slot_reg];
    assign schedule_min_ten_bcd = {1'b0, min_ten_reg[selected_slot_reg]};
    assign schedule_min_unit_bcd = min_unit_reg[selected_slot_reg];
    assign schedule_hour_ten_bcd = {2'b00, hour_ten_reg[selected_slot_reg]};
    assign schedule_hour_unit_bcd = hour_unit_reg[selected_slot_reg];
    assign selected_schedule_enable = enable_mask_reg[selected_slot_reg];
    assign selected_schedule_type = type_reg[selected_slot_reg];
    assign schedule_selected_slot = selected_slot_reg;
    assign schedule_slot_enable_mask = enable_mask_reg;
    assign schedule_slot_selected_mask = selected_slot_mask;
    assign schedule_pending_mask = pending_mask_reg;
    assign next_schedule_valid = next_valid_reg;
    assign next_schedule_slot = next_slot_reg;
    assign next_schedule_sec_ten_bcd = next_valid_reg ? {1'b0, best_sec_ten_reg} : 4'd0;
    assign next_schedule_sec_unit_bcd = next_valid_reg ? best_sec_unit_reg : 4'd0;
    assign next_schedule_min_ten_bcd = next_valid_reg ? {1'b0, best_min_ten_reg} : 4'd0;
    assign next_schedule_min_unit_bcd = next_valid_reg ? best_min_unit_reg : 4'd0;
    assign next_schedule_hour_ten_bcd = next_valid_reg ? {2'b00, best_hour_ten_reg} : 4'd0;
    assign next_schedule_hour_unit_bcd = next_valid_reg ? best_hour_unit_reg : 4'd0;
    assign schedule_event_valid = |pending_mask_reg;
    assign schedule_event_slot = first_set_index(pending_mask_reg);

    always @(*) begin
        match_mask_reg = 8'b0000_0000;

        for (i = 0; i < 8; i = i + 1) begin
            if (enable_mask_reg[i] &&
                (hour_ten_reg[i] == cur_hour_ten_bcd[1:0]) &&
                (hour_unit_reg[i] == cur_hour_unit_bcd) &&
                (min_ten_reg[i] == cur_min_ten_bcd[2:0]) &&
                (min_unit_reg[i] == cur_min_unit_bcd) &&
                (sec_ten_reg[i] == cur_sec_ten_bcd[2:0]) &&
                (sec_unit_reg[i] == cur_sec_unit_bcd)) begin
                match_mask_reg[i] = 1'b1;
            end
        end
    end

    always @(*) begin
        pending_next = pending_mask_reg;

        if (schedule_event_ack_pulse) begin
            pending_next = pending_next & ~current_event_mask;
        end

        pending_next = pending_next | trigger_mask;
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            selected_slot_reg <= 3'd0;
            enable_mask_reg <= 8'b1111_1111;
            pending_mask_reg <= 8'b0000_0000;
            match_d <= 8'b0000_0000;
            next_valid_reg <= 1'b0;
            next_slot_reg <= 3'd0;
            best_hour_ten_reg <= 2'd0;
            best_hour_unit_reg <= 4'd0;
            best_min_ten_reg <= 3'd0;
            best_min_unit_reg <= 4'd0;
            best_sec_ten_reg <= 3'd0;
            best_sec_unit_reg <= 4'd0;
            scan_index_reg <= 4'd0;
            scan_valid_reg <= 1'b0;
            scan_future_found_reg <= 1'b0;
            scan_slot_reg <= 3'd0;
            scan_hour_ten_reg <= 2'd0;
            scan_hour_unit_reg <= 4'd0;
            scan_min_ten_reg <= 3'd0;
            scan_min_unit_reg <= 4'd0;
            scan_sec_ten_reg <= 3'd0;
            scan_sec_unit_reg <= 4'd0;

            for (i = 0; i < 8; i = i + 1) begin
                hour_ten_reg[i] <= default_hour_ten(i[2:0]);
                hour_unit_reg[i] <= default_hour_unit(i[2:0]);
                min_ten_reg[i] <= default_min_ten(i[2:0]);
                min_unit_reg[i] <= 4'd0;
                sec_ten_reg[i] <= 3'd0;
                sec_unit_reg[i] <= 4'd0;
                type_reg[i] <= i[2:0];
            end
        end else begin
            pending_mask_reg <= pending_next;
            match_d <= match_mask_reg;

            if (|schedule_slot_switches) begin
                selected_slot_reg <= switch_selected_slot;
            end else if (schedule_slot_inc_pulse) begin
                selected_slot_reg <= selected_slot_reg + 1'b1;
            end else if (schedule_slot_dec_pulse) begin
                selected_slot_reg <= selected_slot_reg - 1'b1;
            end

            if (scan_index_reg == 4'd8) begin
                scan_index_reg <= 4'd0;
            end else begin
                scan_index_reg <= scan_index_reg + 1'b1;
            end

            if (scan_index_reg == 4'd0) begin
                next_valid_reg <= scan_valid_reg;
                next_slot_reg <= scan_slot_reg;
                best_hour_ten_reg <= scan_hour_ten_reg;
                best_hour_unit_reg <= scan_hour_unit_reg;
                best_min_ten_reg <= scan_min_ten_reg;
                best_min_unit_reg <= scan_min_unit_reg;
                best_sec_ten_reg <= scan_sec_ten_reg;
                best_sec_unit_reg <= scan_sec_unit_reg;
                scan_valid_reg <= 1'b0;
                scan_future_found_reg <= 1'b0;
                scan_slot_reg <= 3'd0;
                scan_hour_ten_reg <= 2'd0;
                scan_hour_unit_reg <= 4'd0;
                scan_min_ten_reg <= 3'd0;
                scan_min_unit_reg <= 4'd0;
                scan_sec_ten_reg <= 3'd0;
                scan_sec_unit_reg <= 4'd0;
            end

            if ((scan_index_reg != 4'd0) && enable_mask_reg[scan_candidate_slot]) begin
                if (time_ge_current(hour_ten_reg[scan_candidate_slot],
                                    hour_unit_reg[scan_candidate_slot],
                                    min_ten_reg[scan_candidate_slot],
                                    min_unit_reg[scan_candidate_slot],
                                    sec_ten_reg[scan_candidate_slot],
                                    sec_unit_reg[scan_candidate_slot])) begin
                    if (!scan_future_found_reg ||
                        time_less_than_scan_best(hour_ten_reg[scan_candidate_slot],
                                                 hour_unit_reg[scan_candidate_slot],
                                                 min_ten_reg[scan_candidate_slot],
                                                 min_unit_reg[scan_candidate_slot],
                                                 sec_ten_reg[scan_candidate_slot],
                                                 sec_unit_reg[scan_candidate_slot])) begin
                        scan_valid_reg <= 1'b1;
                        scan_future_found_reg <= 1'b1;
                        scan_slot_reg <= scan_candidate_slot;
                        scan_hour_ten_reg <= hour_ten_reg[scan_candidate_slot];
                        scan_hour_unit_reg <= hour_unit_reg[scan_candidate_slot];
                        scan_min_ten_reg <= min_ten_reg[scan_candidate_slot];
                        scan_min_unit_reg <= min_unit_reg[scan_candidate_slot];
                        scan_sec_ten_reg <= sec_ten_reg[scan_candidate_slot];
                        scan_sec_unit_reg <= sec_unit_reg[scan_candidate_slot];
                    end
                end else if (!scan_future_found_reg &&
                             (!scan_valid_reg ||
                              time_less_than_scan_best(hour_ten_reg[scan_candidate_slot],
                                                       hour_unit_reg[scan_candidate_slot],
                                                       min_ten_reg[scan_candidate_slot],
                                                       min_unit_reg[scan_candidate_slot],
                                                       sec_ten_reg[scan_candidate_slot],
                                                       sec_unit_reg[scan_candidate_slot]))) begin
                    scan_valid_reg <= 1'b1;
                    scan_slot_reg <= scan_candidate_slot;
                    scan_hour_ten_reg <= hour_ten_reg[scan_candidate_slot];
                    scan_hour_unit_reg <= hour_unit_reg[scan_candidate_slot];
                    scan_min_ten_reg <= min_ten_reg[scan_candidate_slot];
                    scan_min_unit_reg <= min_unit_reg[scan_candidate_slot];
                    scan_sec_ten_reg <= sec_ten_reg[scan_candidate_slot];
                    scan_sec_unit_reg <= sec_unit_reg[scan_candidate_slot];
                end
            end

            if (schedule_hour_inc_pulse) begin
                hour_ten_reg[selected_slot_reg] <= hour_inc_value[5:4];
                hour_unit_reg[selected_slot_reg] <= hour_inc_value[3:0];
            end else if (schedule_hour_dec_pulse) begin
                hour_ten_reg[selected_slot_reg] <= hour_dec_value[5:4];
                hour_unit_reg[selected_slot_reg] <= hour_dec_value[3:0];
            end

            if (schedule_min_inc_pulse) begin
                min_ten_reg[selected_slot_reg] <= min_inc_value[6:4];
                min_unit_reg[selected_slot_reg] <= min_inc_value[3:0];
            end else if (schedule_min_dec_pulse) begin
                min_ten_reg[selected_slot_reg] <= min_dec_value[6:4];
                min_unit_reg[selected_slot_reg] <= min_dec_value[3:0];
            end

            if (schedule_sec_inc_pulse) begin
                sec_ten_reg[selected_slot_reg] <= sec_inc_value[6:4];
                sec_unit_reg[selected_slot_reg] <= sec_inc_value[3:0];
            end else if (schedule_sec_dec_pulse) begin
                sec_ten_reg[selected_slot_reg] <= sec_dec_value[6:4];
                sec_unit_reg[selected_slot_reg] <= sec_dec_value[3:0];
            end

            if (schedule_type_inc_pulse) begin
                type_reg[selected_slot_reg] <= type_reg[selected_slot_reg] + 1'b1;
            end else if (schedule_type_dec_pulse) begin
                type_reg[selected_slot_reg] <= type_reg[selected_slot_reg] - 1'b1;
            end

            if (schedule_enable_toggle_pulse) begin
                enable_mask_reg[selected_slot_reg] <= ~enable_mask_reg[selected_slot_reg];
            end else if (schedule_enable_inc_pulse) begin
                enable_mask_reg[selected_slot_reg] <= 1'b1;
            end else if (schedule_enable_dec_pulse) begin
                enable_mask_reg[selected_slot_reg] <= 1'b0;
            end
        end
    end
endmodule
