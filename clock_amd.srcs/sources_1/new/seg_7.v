module seg_7(
    input [5:0] A,
    output reg [6:0] seg
);
    localparam [5:0] SEG_CHAR_BLANK = 6'd10;
    localparam [5:0] SEG_CHAR_N     = 6'd16;
    localparam [5:0] SEG_CHAR_T     = 6'd17;
    localparam [5:0] SEG_CHAR_A     = 6'd18;
    localparam [5:0] SEG_CHAR_H     = 6'd19;
    localparam [5:0] SEG_CHAR_C     = 6'd20;
    localparam [5:0] SEG_CHAR_S     = 6'd21;
    localparam [5:0] SEG_CHAR_O     = 6'd22;
    localparam [5:0] SEG_CHAR_F     = 6'd23;
    localparam [5:0] SEG_CHAR_R     = 6'd24;
    localparam [5:0] SEG_CHAR_P     = 6'd25;
    localparam [5:0] SEG_CHAR_D     = 6'd26;
    localparam [5:0] SEG_CHAR_B     = 6'd27;
    localparam [5:0] SEG_CHAR_E     = 6'd28;
    localparam [5:0] SEG_CHAR_L     = 6'd29;
    localparam [5:0] SEG_CHAR_U     = 6'd30;
    localparam [5:0] SEG_CHAR_K     = 6'd31;
    localparam [5:0] SEG_CHAR_M     = 6'd32;
    localparam [5:0] SEG_CHAR_I     = 6'd33;
    localparam [5:0] SEG_CHAR_G     = 6'd34;
    localparam [5:0] SEG_CHAR_W     = 6'd35;
    localparam [5:0] SEG_CHAR_EXCL  = 6'd36;

    // seg[6:0] maps to {g,f,e,d,c,b,a}; 1 means segment on before Nexys low-active inversion.
    always @(*) begin
        case (A)
            6'd0:          seg = 7'b011_1111; // 0
            6'd1:          seg = 7'b000_0110; // 1
            6'd2:          seg = 7'b101_1011; // 2
            6'd3:          seg = 7'b100_1111; // 3
            6'd4:          seg = 7'b110_0110; // 4
            6'd5:          seg = 7'b110_1101; // 5 / S
            6'd6:          seg = 7'b111_1101; // 6
            6'd7:          seg = 7'b000_0111; // 7
            6'd8:          seg = 7'b111_1111; // 8
            6'd9:          seg = 7'b110_1111; // 9
            SEG_CHAR_BLANK: seg = 7'b000_0000; // blank
            SEG_CHAR_N:     seg = 7'b101_0100; // n
            SEG_CHAR_T:     seg = 7'b111_1000; // t
            SEG_CHAR_A:     seg = 7'b111_0111; // A
            SEG_CHAR_H:     seg = 7'b111_0110; // H
            SEG_CHAR_C:     seg = 7'b011_1001; // C
            SEG_CHAR_S:     seg = 7'b110_1101; // S
            SEG_CHAR_O:     seg = 7'b101_1100; // o
            SEG_CHAR_F:     seg = 7'b111_0001; // F
            SEG_CHAR_R:     seg = 7'b101_0000; // r
            SEG_CHAR_P:     seg = 7'b111_0011; // P
            SEG_CHAR_D:     seg = 7'b101_1110; // d
            SEG_CHAR_B:     seg = 7'b111_1100; // b
            SEG_CHAR_E:     seg = 7'b111_1001; // E
            SEG_CHAR_L:     seg = 7'b011_1000; // L
            SEG_CHAR_U:     seg = 7'b011_1110; // U
            SEG_CHAR_K:     seg = 7'b111_0110; // K approximated as H on seven-seg
            SEG_CHAR_M:     seg = 7'b001_0101; // M approximated on seven-seg
            SEG_CHAR_I:     seg = 7'b000_0110; // I approximated as 1
            SEG_CHAR_G:     seg = 7'b111_1101; // G approximated as 6
            SEG_CHAR_W:     seg = 7'b011_1110; // W approximated as U
            SEG_CHAR_EXCL:  seg = 7'b000_0110; // ! approximated as 1
            default: seg = 7'b000_0000;
        endcase
    end
endmodule
