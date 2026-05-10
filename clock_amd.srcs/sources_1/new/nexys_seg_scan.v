module nexys_seg_scan(
    input  clk,
    input  rst,
    input  [7:0] sec_unit_seg,
    input  [3:0] sec_ten_bcd,
    input  [3:0] min_unit_bcd,
    input  [3:0] min_ten_bcd,
    input  [3:0] hour_unit_bcd,
    input  [3:0] hour_ten_bcd,
    output reg [7:0] an,
    output reg CA,
    output reg CB,
    output reg CC,
    output reg CD,
    output reg CE,
    output reg CF,
    output reg CG,
    output reg DP
);
    localparam integer SCAN_DIV = 14'd12500;

    reg [13:0] scan_div_cnt;
    reg [2:0] scan_idx;
    reg [7:0] seg_active_high;
    wire [6:0] sec_ten_seg_raw;
    wire [6:0] min_unit_seg_raw;
    wire [6:0] min_ten_seg_raw;
    wire [6:0] hour_unit_seg_raw;
    wire [6:0] hour_ten_seg_raw;

    seg_7 u_seg_sec_ten(
        .A(sec_ten_bcd),
        .seg(sec_ten_seg_raw)
    );

    seg_7 u_seg_min_unit(
        .A(min_unit_bcd),
        .seg(min_unit_seg_raw)
    );

    seg_7 u_seg_min_ten(
        .A(min_ten_bcd),
        .seg(min_ten_seg_raw)
    );

    seg_7 u_seg_hour_unit(
        .A(hour_unit_bcd),
        .seg(hour_unit_seg_raw)
    );

    seg_7 u_seg_hour_ten(
        .A(hour_ten_bcd),
        .seg(hour_ten_seg_raw)
    );

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            scan_div_cnt <= 14'd0;
            scan_idx     <= 3'd0;
        end else if (scan_div_cnt == SCAN_DIV - 1'b1) begin
            scan_div_cnt <= 14'd0;
            scan_idx     <= scan_idx + 1'b1;
        end else begin
            scan_div_cnt <= scan_div_cnt + 1'b1;
        end
    end

    always @(*) begin
        seg_active_high = 8'b0000_0000;
        an              = 8'hFF;

        case (scan_idx)
            3'd0: begin
                seg_active_high = sec_unit_seg;
                an[0]           = 1'b0;
            end
            3'd1: begin
                seg_active_high = {1'b0, sec_ten_seg_raw};
                an[1]           = 1'b0;
            end
            3'd2: begin
                seg_active_high = {1'b0, min_unit_seg_raw};
                an[2]           = 1'b0;
            end
            3'd3: begin
                seg_active_high = {1'b0, min_ten_seg_raw};
                an[3]           = 1'b0;
            end
            3'd4: begin
                seg_active_high = {1'b0, hour_unit_seg_raw};
                an[4]           = 1'b0;
            end
            3'd5: begin
                seg_active_high = {1'b0, hour_ten_seg_raw};
                an[5]           = 1'b0;
            end
            3'd6: begin
                seg_active_high = 8'b0000_0000;
                an[6]           = 1'b0;
            end
            default: begin
                seg_active_high = 8'b0000_0000;
                an[7]           = 1'b0;
            end
        endcase
    end

    always @(*) begin
        CA = ~seg_active_high[0];
        CB = ~seg_active_high[1];
        CC = ~seg_active_high[2];
        CD = ~seg_active_high[3];
        CE = ~seg_active_high[4];
        CF = ~seg_active_high[5];
        CG = ~seg_active_high[6];
        DP = ~seg_active_high[7];
    end
endmodule
