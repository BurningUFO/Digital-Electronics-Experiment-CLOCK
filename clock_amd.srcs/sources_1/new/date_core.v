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
    input pc_date_load_valid,
    input [3:0] pc_year_thousand_bcd,
    input [3:0] pc_year_hundred_bcd,
    input [3:0] pc_year_ten_bcd,
    input [3:0] pc_year_unit_bcd,
    input [3:0] pc_month_ten_bcd,
    input [3:0] pc_month_unit_bcd,
    input [3:0] pc_day_ten_bcd,
    input [3:0] pc_day_unit_bcd,
    input [2:0] pc_weekday,

    output [3:0] year_thousand_bcd,
    output [3:0] year_hundred_bcd,
    output [3:0] year_ten_bcd,
    output [3:0] year_unit_bcd,
    output [3:0] month_ten_bcd,
    output [3:0] month_unit_bcd,
    output [3:0] day_ten_bcd,
    output [3:0] day_unit_bcd,
    output [2:0] weekday
);
    reg [3:0] month_reg;
    reg [5:0] day_reg;
    reg [2:0] weekday_reg;
    reg [3:0] year_thousand_reg;
    reg [3:0] year_hundred_reg;
    reg [3:0] year_ten_reg;
    reg [3:0] year_unit_reg;

    assign year_thousand_bcd = year_thousand_reg;
    assign year_hundred_bcd  = year_hundred_reg;
    assign year_ten_bcd      = year_ten_reg;
    assign year_unit_bcd     = year_unit_reg;
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

    function [3:0] bcd_month_value;
        input [3:0] ten;
        input [3:0] unit;
        reg [5:0] raw;
        begin
            raw = ({2'd0, ten} * 6'd10) + {2'd0, unit};
            if (raw < 6'd1) begin
                bcd_month_value = 4'd1;
            end else if (raw > 6'd12) begin
                bcd_month_value = 4'd12;
            end else begin
                bcd_month_value = raw[3:0];
            end
        end
    endfunction

    function [5:0] bcd_day_value;
        input [3:0] ten;
        input [3:0] unit;
        reg [6:0] raw;
        begin
            raw = ({3'd0, ten} * 7'd10) + {3'd0, unit};
            if (raw < 7'd1) begin
                bcd_day_value = 6'd1;
            end else if (raw > 7'd31) begin
                bcd_day_value = 6'd31;
            end else begin
                bcd_day_value = raw[5:0];
            end
        end
    endfunction

    function [2:0] weekday_value;
        input [2:0] weekday_in;
        begin
            if ((weekday_in < 3'd1) || (weekday_in > 3'd7)) begin
                weekday_value = 3'd1;
            end else begin
                weekday_value = weekday_in;
            end
        end
    endfunction

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            month_reg   <= 4'd1;
            day_reg     <= 6'd1;
            weekday_reg <= 3'd1;
            year_thousand_reg <= 4'd2;
            year_hundred_reg  <= 4'd0;
            year_ten_reg      <= 4'd2;
            year_unit_reg     <= 4'd6;
        end else if (pc_date_load_valid) begin
            month_reg   <= bcd_month_value(pc_month_ten_bcd, pc_month_unit_bcd);
            day_reg     <= clamp_day(bcd_day_value(pc_day_ten_bcd, pc_day_unit_bcd),
                                      bcd_month_value(pc_month_ten_bcd, pc_month_unit_bcd));
            weekday_reg <= weekday_value(pc_weekday);
            year_thousand_reg <= pc_year_thousand_bcd;
            year_hundred_reg  <= pc_year_hundred_bcd;
            year_ten_reg      <= pc_year_ten_bcd;
            year_unit_reg     <= pc_year_unit_bcd;
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
