module hour_format_display(
    input  [3:0] hour_ten_24,
    input  [3:0] hour_unit_24,
    input        hour_format_12h,
    output [3:0] display_hour_ten,
    output [3:0] display_hour_unit,
    output       is_pm,
    output       is_midnight_or_noon
);
    reg [3:0] display_hour_ten_reg;
    reg [3:0] display_hour_unit_reg;
    reg       is_pm_reg;
    reg       is_midnight_or_noon_reg;

    assign display_hour_ten        = display_hour_ten_reg;
    assign display_hour_unit       = display_hour_unit_reg;
    assign is_pm                   = is_pm_reg;
    assign is_midnight_or_noon     = is_midnight_or_noon_reg;

    always @(*) begin
        display_hour_ten_reg        = hour_ten_24;
        display_hour_unit_reg       = hour_unit_24;
        is_pm_reg                   = 1'b0;
        is_midnight_or_noon_reg     = 1'b0;

        if (hour_format_12h) begin
            case ({hour_ten_24, hour_unit_24})
                8'h00: begin
                    display_hour_ten_reg    = 4'd1;
                    display_hour_unit_reg   = 4'd2;
                    is_pm_reg               = 1'b0;
                    is_midnight_or_noon_reg = 1'b1;
                end
                8'h01, 8'h02, 8'h03, 8'h04, 8'h05,
                8'h06, 8'h07, 8'h08, 8'h09, 8'h10,
                8'h11: begin
                    display_hour_ten_reg    = hour_ten_24;
                    display_hour_unit_reg   = hour_unit_24;
                    is_pm_reg               = 1'b0;
                    is_midnight_or_noon_reg = 1'b0;
                end
                8'h12: begin
                    display_hour_ten_reg    = 4'd1;
                    display_hour_unit_reg   = 4'd2;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b1;
                end
                8'h13: begin
                    display_hour_ten_reg    = 4'd0;
                    display_hour_unit_reg   = 4'd1;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b0;
                end
                8'h14: begin
                    display_hour_ten_reg    = 4'd0;
                    display_hour_unit_reg   = 4'd2;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b0;
                end
                8'h15: begin
                    display_hour_ten_reg    = 4'd0;
                    display_hour_unit_reg   = 4'd3;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b0;
                end
                8'h16: begin
                    display_hour_ten_reg    = 4'd0;
                    display_hour_unit_reg   = 4'd4;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b0;
                end
                8'h17: begin
                    display_hour_ten_reg    = 4'd0;
                    display_hour_unit_reg   = 4'd5;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b0;
                end
                8'h18: begin
                    display_hour_ten_reg    = 4'd0;
                    display_hour_unit_reg   = 4'd6;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b0;
                end
                8'h19: begin
                    display_hour_ten_reg    = 4'd0;
                    display_hour_unit_reg   = 4'd7;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b0;
                end
                8'h20: begin
                    display_hour_ten_reg    = 4'd0;
                    display_hour_unit_reg   = 4'd8;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b0;
                end
                8'h21: begin
                    display_hour_ten_reg    = 4'd0;
                    display_hour_unit_reg   = 4'd9;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b0;
                end
                8'h22: begin
                    display_hour_ten_reg    = 4'd1;
                    display_hour_unit_reg   = 4'd0;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b0;
                end
                8'h23: begin
                    display_hour_ten_reg    = 4'd1;
                    display_hour_unit_reg   = 4'd1;
                    is_pm_reg               = 1'b1;
                    is_midnight_or_noon_reg = 1'b0;
                end
                default: begin
                    display_hour_ten_reg    = hour_ten_24;
                    display_hour_unit_reg   = hour_unit_24;
                    is_pm_reg               = 1'b0;
                    is_midnight_or_noon_reg = 1'b0;
                end
            endcase
        end
    end
endmodule
