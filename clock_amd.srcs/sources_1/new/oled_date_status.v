// -----------------------------------------------------------------------------
// OLED 日期/星期文本辅助模块。
//
// 将 BCD 月/日和 weekday 编号转换为紧凑 ASCII 文本，供主 OLED 渲染模块使用。
// -----------------------------------------------------------------------------
module oled_date_status(
    input  wire [3:0] month_ten,
    input  wire [3:0] month_unit,
    input  wire [3:0] day_ten,
    input  wire [3:0] day_unit,
    input  wire [2:0] weekday,
    output reg  [71:0] date_text_ascii
);
    localparam [7:0] CHAR_SLASH = 8'h2f;
    localparam [7:0] CHAR_SPACE = 8'h20;

    function [7:0] bcd_to_ascii;
        input [3:0] bcd_digit;
        begin
            if (bcd_digit <= 4'd9) begin
                bcd_to_ascii = 8'h30 + bcd_digit;
            end else begin
                bcd_to_ascii = 8'h3f;
            end
        end
    endfunction

    function [23:0] weekday_to_ascii;
        input [2:0] weekday_code;
        begin
            case (weekday_code)
                3'd1: weekday_to_ascii = {8'h4d, 8'h4f, 8'h4e}; // MON
                3'd2: weekday_to_ascii = {8'h54, 8'h55, 8'h45}; // TUE
                3'd3: weekday_to_ascii = {8'h57, 8'h45, 8'h44}; // WED
                3'd4: weekday_to_ascii = {8'h54, 8'h48, 8'h55}; // THU
                3'd5: weekday_to_ascii = {8'h46, 8'h52, 8'h49}; // FRI
                3'd6: weekday_to_ascii = {8'h53, 8'h41, 8'h54}; // SAT
                3'd7: weekday_to_ascii = {8'h53, 8'h55, 8'h4e}; // SUN
                default: weekday_to_ascii = {8'h3f, 8'h3f, 8'h3f};
            endcase
        end
    endfunction

    always @* begin
        date_text_ascii = {
            bcd_to_ascii(month_ten),
            bcd_to_ascii(month_unit),
            CHAR_SLASH,
            bcd_to_ascii(day_ten),
            bcd_to_ascii(day_unit),
            CHAR_SPACE,
            weekday_to_ascii(weekday)
        };
    end
endmodule
