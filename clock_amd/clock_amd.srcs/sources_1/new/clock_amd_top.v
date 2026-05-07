module clock_amd_top(
    input  CLK100MHZ,
    input  CPU_RESETN,
    input  BTNC,
    input  [7:0] SW,
    output [7:0] AN,
    output CA,
    output CB,
    output CC,
    output CD,
    output CE,
    output CF,
    output CG,
    output DP,
    output BUZZER_IO
);
    localparam integer TICK_1K_DIV = 17'd100000;

    reg [16:0] tick_1k_cnt;
    reg tick_1k;
    wire alarm_beep;
    wire [7:0] sec_unit_seg;
    wire [3:0] sec_ten_bcd;
    wire [3:0] min_unit_bcd;
    wire [3:0] min_ten_bcd;
    wire [3:0] hour_unit_bcd;
    wire [3:0] hour_ten_bcd;

    always @(posedge CLK100MHZ or negedge CPU_RESETN) begin
        if (!CPU_RESETN) begin
            tick_1k_cnt <= 17'd0;
            tick_1k     <= 1'b0;
        end else if (tick_1k_cnt == TICK_1K_DIV - 1'b1) begin
            tick_1k_cnt <= 17'd0;
            tick_1k     <= 1'b1;
        end else begin
            tick_1k_cnt <= tick_1k_cnt + 1'b1;
            tick_1k     <= 1'b0;
        end
    end

    clock u_clock(
        .clk(CLK100MHZ),
        .tick_1k(tick_1k),
        .rst(CPU_RESETN),
        .qd_key(BTNC),
        .sw_a(SW[0]),
        .sw_b(SW[1]),
        .sw_c(SW[2]),
        .k1_mode_time_set(SW[3]),
        .k2_mode_alarm(SW[4]),
        .k3_mode_hour_format(SW[5]),
        .k4_mode_countdown(SW[6]),
        .k5_mode_schedule(SW[7]),
        .alarm_beep(alarm_beep),
        .sec_unit_seg(sec_unit_seg),
        .sec_ten_bcd(sec_ten_bcd),
        .min_unit_bcd(min_unit_bcd),
        .min_ten_bcd(min_ten_bcd),
        .hour_unit_bcd(hour_unit_bcd),
        .hour_ten_bcd(hour_ten_bcd)
    );

    nexys_seg_scan u_nexys_seg_scan(
        .clk(CLK100MHZ),
        .rst(CPU_RESETN),
        .sec_unit_seg(sec_unit_seg),
        .sec_ten_bcd(sec_ten_bcd),
        .min_unit_bcd(min_unit_bcd),
        .min_ten_bcd(min_ten_bcd),
        .hour_unit_bcd(hour_unit_bcd),
        .hour_ten_bcd(hour_ten_bcd),
        .an(AN),
        .CA(CA),
        .CB(CB),
        .CC(CC),
        .CD(CD),
        .CE(CE),
        .CF(CF),
        .CG(CG),
        .DP(DP)
    );

    // The active buzzer module is driven low to sound.
    assign BUZZER_IO = ~alarm_beep;
endmodule
