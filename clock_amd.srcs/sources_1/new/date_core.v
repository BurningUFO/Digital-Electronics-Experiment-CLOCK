module date_core(
    input clk,
    input rst,
    input day_tick_pulse,

    input month_inc_pulse,
    input month_dec_pulse,
    input day_inc_pulse,
    input day_dec_pulse,
    input weekday_inc_pulse,
    input weekday_dec_pulse,

    output [3:0] month_ten_bcd,
    output [3:0] month_unit_bcd,
    output [3:0] day_ten_bcd,
    output [3:0] day_unit_bcd,
    output [2:0] weekday
);
    reg [3:0] month_reg;
    reg [5:0] day_reg;
    reg [2:0] weekday_reg;

    assign month_ten_bcd  = (month_reg >= 4'd10) ? 4'd1 : 4'd0;
    assign month_unit_bcd = (month_reg >= 4'd10) ? (month_reg - 4'd10) : month_reg;
    assign day_ten_bcd    = (day_reg >= 6'd30) ? 4'd3 :
                            (day_reg >= 6'd20) ? 4'd2 :
                            (day_reg >= 6'd10) ? 4'd1 : 4'd0;
    assign day_unit_bcd   = (day_reg >= 6'd30) ? (day_reg - 6'd30) :
                            (day_reg >= 6'd20) ? (day_reg - 6'd20) :
                            (day_reg >= 6'd10) ? (day_reg - 6'd10) : day_reg[3:0];
    assign weekday        = weekday_reg;

    function [5:0] month_max_day;
        input [3:0] month_in;
        begin
            case (month_in)
                4'd2: month_max_day = 6'd28;
                4'd4,
                4'd6,
                4'd9,
                4'd11: month_max_day = 6'd30;
                default: month_max_day = 6'd31;
            endcase
        end
    endfunction

    function [3:0] next_month;
        input [3:0] month_in;
        begin
            if (month_in == 4'd12) begin
                next_month = 4'd1;
            end else begin
                next_month = month_in + 1'b1;
            end
        end
    endfunction

    function [3:0] prev_month;
        input [3:0] month_in;
        begin
            if (month_in == 4'd1) begin
                prev_month = 4'd12;
            end else begin
                prev_month = month_in - 1'b1;
            end
        end
    endfunction

    function [5:0] clamp_day;
        input [5:0] day_in;
        input [3:0] month_in;
        begin
            if (day_in > month_max_day(month_in)) begin
                clamp_day = month_max_day(month_in);
            end else begin
                clamp_day = day_in;
            end
        end
    endfunction

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            month_reg   <= 4'd1;
            day_reg     <= 6'd1;
            weekday_reg <= 3'd1;
        end else if (month_inc_pulse) begin
            month_reg <= next_month(month_reg);
            day_reg   <= clamp_day(day_reg, next_month(month_reg));
        end else if (month_dec_pulse) begin
            month_reg <= prev_month(month_reg);
            day_reg   <= clamp_day(day_reg, prev_month(month_reg));
        end else if (day_inc_pulse) begin
            if (day_reg >= month_max_day(month_reg)) begin
                day_reg <= 6'd1;
            end else begin
                day_reg <= day_reg + 1'b1;
            end
        end else if (day_dec_pulse) begin
            if (day_reg <= 6'd1) begin
                day_reg <= month_max_day(month_reg);
            end else begin
                day_reg <= day_reg - 1'b1;
            end
        end else if (weekday_inc_pulse) begin
            if (weekday_reg == 3'd7) begin
                weekday_reg <= 3'd1;
            end else begin
                weekday_reg <= weekday_reg + 1'b1;
            end
        end else if (weekday_dec_pulse) begin
            if (weekday_reg <= 3'd1) begin
                weekday_reg <= 3'd7;
            end else begin
                weekday_reg <= weekday_reg - 1'b1;
            end
        end else if (day_tick_pulse) begin
            if (day_reg >= month_max_day(month_reg)) begin
                day_reg   <= 6'd1;
                month_reg <= next_month(month_reg);
            end else begin
                day_reg <= day_reg + 1'b1;
            end

            if (weekday_reg == 3'd7) begin
                weekday_reg <= 3'd1;
            end else begin
                weekday_reg <= weekday_reg + 1'b1;
            end
        end
    end
endmodule
