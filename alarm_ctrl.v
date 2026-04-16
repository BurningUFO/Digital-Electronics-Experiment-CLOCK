module alarm_ctrl(
    input  clk_1k,
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
    output alarm_match
);
    reg  alarm_enable_reg;
    reg  [1:0] alarm_hour_ten_reg;
    reg  [3:0] alarm_hour_unit_reg;
    reg  [2:0] alarm_min_ten_reg;
    reg  [3:0] alarm_min_unit_reg;
    wire [12:0] cur_alarm_bus;
    wire [12:0] set_alarm_bus;

    assign alarm_hour_ten_bcd  = {2'b00, alarm_hour_ten_reg};
    assign alarm_hour_unit_bcd = alarm_hour_unit_reg;
    assign alarm_min_ten_bcd   = {1'b0, alarm_min_ten_reg};
    assign alarm_min_unit_bcd  = alarm_min_unit_reg;
    assign alarm_enable        = alarm_enable_reg;
    assign cur_alarm_bus       = {cur_hour_ten_bcd[1:0], cur_hour_unit_bcd,
                                  cur_min_ten_bcd[2:0], cur_min_unit_bcd};
    assign set_alarm_bus       = {alarm_hour_ten_reg, alarm_hour_unit_reg,
                                  alarm_min_ten_reg, alarm_min_unit_reg};
    assign alarm_match         = alarm_enable_reg & ~|(cur_alarm_bus ^ set_alarm_bus);

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            alarm_hour_ten_reg  <= 2'd0;
            alarm_hour_unit_reg <= 4'd0;
            alarm_min_ten_reg   <= 3'd0;
            alarm_min_unit_reg  <= 4'd0;
            alarm_enable_reg    <= 1'b0;
        end else begin
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
        end
    end
endmodule
