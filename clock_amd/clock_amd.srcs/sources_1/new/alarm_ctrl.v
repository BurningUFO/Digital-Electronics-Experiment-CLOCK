module alarm_ctrl(
    input  clk,
    input  tick_1k,
    input  rst,
    input  mode_alarm,
    input  key_hour_pulse,
    input  key_min_pulse,
    input  key_confirm_pulse,
    input  [3:0] cur_min_ten_bcd,
    input  [3:0] cur_min_unit_bcd,
    input  [3:0] cur_hour_unit_bcd,
    input  [3:0] cur_hour_ten_bcd,
    output [3:0] alarm_hour_ten_bcd,
    output [3:0] alarm_hour_unit_bcd,
    output [3:0] alarm_min_ten_bcd,
    output [3:0] alarm_min_unit_bcd,
    output alarm_enable,
    output alarm_match,
    output alarm_beep
);
    localparam [1:0] BEEP_IDLE      = 2'd0;
    localparam [1:0] BEEP_ON        = 2'd1;
    localparam [1:0] BEEP_OFF       = 2'd2;
    localparam [1:0] BEEP_GROUP_GAP = 2'd3;
    localparam integer BEEP_ON_MS   = 10'd120;
    localparam integer BEEP_OFF_MS  = 10'd120;
    localparam integer GROUP_GAP_MS = 10'd500;

    reg  alarm_enable_reg;
    reg  [1:0] alarm_hour_ten_reg;
    reg  [3:0] alarm_hour_unit_reg;
    reg  [2:0] alarm_min_ten_reg;
    reg  [3:0] alarm_min_unit_reg;
    reg  alarm_match_d;
    reg  alarm_beep_reg;
    reg  [1:0] beep_state;
    reg  [1:0] beep_index;
    reg  [1:0] group_index;
    reg  [9:0] beep_tick_cnt;
    wire [12:0] cur_alarm_bus;
    wire [12:0] set_alarm_bus;
    wire alarm_match_raw;

    assign alarm_hour_ten_bcd  = {2'b00, alarm_hour_ten_reg};
    assign alarm_hour_unit_bcd = alarm_hour_unit_reg;
    assign alarm_min_ten_bcd   = {1'b0, alarm_min_ten_reg};
    assign alarm_min_unit_bcd  = alarm_min_unit_reg;
    assign alarm_enable        = alarm_enable_reg;
    assign cur_alarm_bus       = {cur_hour_ten_bcd[1:0], cur_hour_unit_bcd,
                                  cur_min_ten_bcd[2:0], cur_min_unit_bcd};
    assign set_alarm_bus       = {alarm_hour_ten_reg, alarm_hour_unit_reg,
                                  alarm_min_ten_reg, alarm_min_unit_reg};
    assign alarm_match_raw     = alarm_enable_reg & ~|(cur_alarm_bus ^ set_alarm_bus);
    assign alarm_match         = alarm_match_raw;
    assign alarm_beep          = alarm_beep_reg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            alarm_hour_ten_reg  <= 2'd0;
            alarm_hour_unit_reg <= 4'd0;
            alarm_min_ten_reg   <= 3'd0;
            alarm_min_unit_reg  <= 4'd0;
            alarm_enable_reg    <= 1'b0;
            alarm_match_d       <= 1'b0;
            alarm_beep_reg      <= 1'b0;
            beep_state          <= BEEP_IDLE;
            beep_index          <= 2'd0;
            group_index         <= 2'd0;
            beep_tick_cnt       <= 10'd0;
        end else if (tick_1k) begin
            if (mode_alarm) begin
                if (key_confirm_pulse) begin
                    alarm_enable_reg <= ~alarm_enable_reg;
                end

                if (key_hour_pulse) begin
                    if (alarm_hour_ten_reg == 2'd2 &&
                        alarm_hour_unit_reg == 4'd3) begin
                        alarm_hour_ten_reg  <= 2'd0;
                        alarm_hour_unit_reg <= 4'd0;
                    end else if (alarm_hour_unit_reg == 4'd9) begin
                        alarm_hour_ten_reg  <= alarm_hour_ten_reg + 1'b1;
                        alarm_hour_unit_reg <= 4'd0;
                    end else begin
                        alarm_hour_unit_reg <= alarm_hour_unit_reg + 1'b1;
                    end
                end

                if (key_min_pulse) begin
                    if (alarm_min_ten_reg == 3'd5 &&
                        alarm_min_unit_reg == 4'd9) begin
                        alarm_min_ten_reg  <= 3'd0;
                        alarm_min_unit_reg <= 4'd0;
                    end else if (alarm_min_unit_reg == 4'd9) begin
                        alarm_min_ten_reg  <= alarm_min_ten_reg + 1'b1;
                        alarm_min_unit_reg <= 4'd0;
                    end else begin
                        alarm_min_unit_reg <= alarm_min_unit_reg + 1'b1;
                    end
                end
            end

            alarm_match_d <= alarm_match_raw;

            if (!alarm_enable_reg) begin
                alarm_beep_reg <= 1'b0;
                beep_state     <= BEEP_IDLE;
                beep_index     <= 2'd0;
                group_index    <= 2'd0;
                beep_tick_cnt  <= 10'd0;
            end else begin
                case (beep_state)
                    BEEP_IDLE: begin
                        alarm_beep_reg <= 1'b0;
                        beep_index     <= 2'd0;
                        group_index    <= 2'd0;
                        beep_tick_cnt  <= 10'd0;

                        if (alarm_match_raw && !alarm_match_d) begin
                            alarm_beep_reg <= 1'b1;
                            beep_state     <= BEEP_ON;
                        end
                    end

                    BEEP_ON: begin
                        alarm_beep_reg <= 1'b1;

                        if (beep_tick_cnt == BEEP_ON_MS - 1'b1) begin
                            alarm_beep_reg <= 1'b0;
                            beep_tick_cnt  <= 10'd0;

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
                            beep_tick_cnt  <= 10'd0;
                            beep_index     <= beep_index + 1'b1;
                            alarm_beep_reg <= 1'b1;
                            beep_state     <= BEEP_ON;
                        end else begin
                            beep_tick_cnt <= beep_tick_cnt + 1'b1;
                        end
                    end

                    default: begin
                        alarm_beep_reg <= 1'b0;

                        if (beep_tick_cnt == GROUP_GAP_MS - 1'b1) begin
                            beep_tick_cnt  <= 10'd0;
                            beep_index     <= 2'd0;
                            group_index    <= group_index + 1'b1;
                            alarm_beep_reg <= 1'b1;
                            beep_state     <= BEEP_ON;
                        end else begin
                            beep_tick_cnt <= beep_tick_cnt + 1'b1;
                        end
                    end
                endcase
            end
        end
    end
endmodule
