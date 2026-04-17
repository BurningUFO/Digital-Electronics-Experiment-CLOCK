module seg_7(
    input [3:0] A,
    output reg [6:0] seg
);
    always @(*) begin
        case (A)
            4'd0: seg = 7'b011_1111;
            4'd1: seg = 7'b000_0110;
            4'd2: seg = 7'b101_1011;
            4'd3: seg = 7'b100_1111;
            4'd4: seg = 7'b110_0110;
            4'd5: seg = 7'b110_1101;
            4'd6: seg = 7'b111_1101;
            4'd7: seg = 7'b000_0111;
            4'd8: seg = 7'b111_1111;
            4'd9: seg = 7'b110_1111;
            default: seg = 7'bxxx_xxxx;
        endcase
    end
endmodule
