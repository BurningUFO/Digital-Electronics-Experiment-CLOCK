module oled_countdown_status(
    input  wire       countdown_run,
    input  wire [3:0] countdown_hour_ten_bcd,
    input  wire [3:0] countdown_hour_unit_bcd,
    input  wire [3:0] countdown_min_ten_bcd,
    input  wire [3:0] countdown_min_unit_bcd,
    input  wire [3:0] countdown_sec_ten_bcd,
    input  wire [3:0] countdown_sec_unit_bcd,
    output wire [95:0] countdown_ascii,
    output wire [3:0]  countdown_ascii_len
);

    // Fixed 12-byte order: char0 is [95:88], char11 is [7:0].
    assign countdown_ascii_len = 4'd12;
    assign countdown_ascii = {
        countdown_run ? "R" : "S",
        countdown_run ? "U" : "T",
        countdown_run ? "N" : "O",
        countdown_run ? " " : "P",
        bcd_to_ascii(countdown_hour_ten_bcd),
        bcd_to_ascii(countdown_hour_unit_bcd),
        ":",
        bcd_to_ascii(countdown_min_ten_bcd),
        bcd_to_ascii(countdown_min_unit_bcd),
        ":",
        bcd_to_ascii(countdown_sec_ten_bcd),
        bcd_to_ascii(countdown_sec_unit_bcd)
    };

    function [7:0] bcd_to_ascii;
        input [3:0] bcd;
        begin
            bcd_to_ascii = (bcd <= 4'd9) ? (8'h30 + bcd) : "?";
        end
    endfunction

endmodule
