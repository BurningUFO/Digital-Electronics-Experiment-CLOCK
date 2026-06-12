// -----------------------------------------------------------------------------
// Nexys A7 八位数码管动态扫描。
//
// 输入 digit_code_bus 按 {D7..D0} 打包，每个字符 6 bit。
// 本模块循环选择一个显示位，调用 seg_7 译码，再输出低有效 AN/段码/DP。
// -----------------------------------------------------------------------------
module nexys_seg_scan(
    input  clk,
    input  rst,
    input  [47:0] digit_code_bus,
    input  [7:0] dp_mask,
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
    localparam [5:0] DISP_BLANK = 6'd10;

    reg [13:0] scan_div_cnt;
    reg [2:0] scan_idx;
    reg [5:0] digit_code;
    reg digit_dp;
    reg [7:0] an_next;

    wire [6:0] digit_seg_raw;

    // digit_code_bus[5:0] is D0/AN0, ... digit_code_bus[47:42] is D7/AN7.
    seg_7 u_seg_digit(
        .A(digit_code),
        .seg(digit_seg_raw)
    );

    always @(*) begin
        digit_code = DISP_BLANK;
        digit_dp   = 1'b0;
        an_next    = 8'hFF;

        case (scan_idx)
            3'd0: begin
                digit_code = digit_code_bus[5:0];
                digit_dp   = dp_mask[0];
                an_next[0] = 1'b0;
            end
            3'd1: begin
                digit_code = digit_code_bus[11:6];
                digit_dp   = dp_mask[1];
                an_next[1] = 1'b0;
            end
            3'd2: begin
                digit_code = digit_code_bus[17:12];
                digit_dp   = dp_mask[2];
                an_next[2] = 1'b0;
            end
            3'd3: begin
                digit_code = digit_code_bus[23:18];
                digit_dp   = dp_mask[3];
                an_next[3] = 1'b0;
            end
            3'd4: begin
                digit_code = digit_code_bus[29:24];
                digit_dp   = dp_mask[4];
                an_next[4] = 1'b0;
            end
            3'd5: begin
                digit_code = digit_code_bus[35:30];
                digit_dp   = dp_mask[5];
                an_next[5] = 1'b0;
            end
            3'd6: begin
                digit_code = digit_code_bus[41:36];
                digit_dp   = dp_mask[6];
                an_next[6] = 1'b0;
            end
            default: begin
                digit_code = digit_code_bus[47:42];
                digit_dp   = dp_mask[7];
                an_next[7] = 1'b0;
            end
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            scan_div_cnt <= 14'd0;
            scan_idx     <= 3'd0;
            an           <= 8'hFF;
            CA           <= 1'b1;
            CB           <= 1'b1;
            CC           <= 1'b1;
            CD           <= 1'b1;
            CE           <= 1'b1;
            CF           <= 1'b1;
            CG           <= 1'b1;
            DP           <= 1'b1;
        end else begin
            an <= an_next;
            CA <= ~digit_seg_raw[0];
            CB <= ~digit_seg_raw[1];
            CC <= ~digit_seg_raw[2];
            CD <= ~digit_seg_raw[3];
            CE <= ~digit_seg_raw[4];
            CF <= ~digit_seg_raw[5];
            CG <= ~digit_seg_raw[6];
            DP <= ~digit_dp;

            if (scan_div_cnt == SCAN_DIV - 1'b1) begin
                scan_div_cnt <= 14'd0;
                scan_idx     <= scan_idx + 1'b1;
            end else begin
                scan_div_cnt <= scan_div_cnt + 1'b1;
            end
        end
    end
endmodule
