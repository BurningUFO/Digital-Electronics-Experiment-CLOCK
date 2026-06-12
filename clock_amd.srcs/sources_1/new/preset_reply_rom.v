`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// COMM 模式预设回复 ROM。
//
// 固定保存 8 条英文 ASCII 回复，供 FPGA 在回复模式下选择并发送 REPLY 帧。
// 文本同时被 OLED 回复页面显示，因此长度和内容应保持在可打印 ASCII 范围内。
// 字符存储约定：char0 位于 [7:0]，char1 位于 [15:8]，未使用字节填空格。
// -----------------------------------------------------------------------------
module preset_reply_rom(
    input  wire [2:0]  reply_index,
    output reg  [159:0] reply_ascii,
    output reg  [5:0]   reply_len
);
    task clear_reply;
        begin
            reply_ascii = {20{8'h20}};
            reply_len = 6'd0;
        end
    endtask

    always @* begin
        clear_reply;
        case (reply_index)
            3'd0: begin
                reply_len = 6'd13;
                reply_ascii[0*8 +: 8] = "O";
                reply_ascii[1*8 +: 8] = "K";
                reply_ascii[2*8 +: 8] = ",";
                reply_ascii[3*8 +: 8] = " ";
                reply_ascii[4*8 +: 8] = "r";
                reply_ascii[5*8 +: 8] = "e";
                reply_ascii[6*8 +: 8] = "c";
                reply_ascii[7*8 +: 8] = "e";
                reply_ascii[8*8 +: 8] = "i";
                reply_ascii[9*8 +: 8] = "v";
                reply_ascii[10*8 +: 8] = "e";
                reply_ascii[11*8 +: 8] = "d";
                reply_ascii[12*8 +: 8] = ".";
            end
            3'd1: begin
                reply_len = 6'd9;
                reply_ascii[0*8 +: 8] = "B";
                reply_ascii[1*8 +: 8] = "u";
                reply_ascii[2*8 +: 8] = "s";
                reply_ascii[3*8 +: 8] = "y";
                reply_ascii[4*8 +: 8] = " ";
                reply_ascii[5*8 +: 8] = "n";
                reply_ascii[6*8 +: 8] = "o";
                reply_ascii[7*8 +: 8] = "w";
                reply_ascii[8*8 +: 8] = ".";
            end
            3'd2: begin
                reply_len = 6'd17;
                reply_ascii[0*8 +: 8] = "W";
                reply_ascii[1*8 +: 8] = "i";
                reply_ascii[2*8 +: 8] = "l";
                reply_ascii[3*8 +: 8] = "l";
                reply_ascii[4*8 +: 8] = " ";
                reply_ascii[5*8 +: 8] = "c";
                reply_ascii[6*8 +: 8] = "h";
                reply_ascii[7*8 +: 8] = "e";
                reply_ascii[8*8 +: 8] = "c";
                reply_ascii[9*8 +: 8] = "k";
                reply_ascii[10*8 +: 8] = " ";
                reply_ascii[11*8 +: 8] = "l";
                reply_ascii[12*8 +: 8] = "a";
                reply_ascii[13*8 +: 8] = "t";
                reply_ascii[14*8 +: 8] = "e";
                reply_ascii[15*8 +: 8] = "r";
                reply_ascii[16*8 +: 8] = ".";
            end
            3'd3: begin
                reply_len = 6'd17;
                reply_ascii[0*8 +: 8] = "P";
                reply_ascii[1*8 +: 8] = "l";
                reply_ascii[2*8 +: 8] = "e";
                reply_ascii[3*8 +: 8] = "a";
                reply_ascii[4*8 +: 8] = "s";
                reply_ascii[5*8 +: 8] = "e";
                reply_ascii[6*8 +: 8] = " ";
                reply_ascii[7*8 +: 8] = "s";
                reply_ascii[8*8 +: 8] = "y";
                reply_ascii[9*8 +: 8] = "n";
                reply_ascii[10*8 +: 8] = "c";
                reply_ascii[11*8 +: 8] = " ";
                reply_ascii[12*8 +: 8] = "t";
                reply_ascii[13*8 +: 8] = "i";
                reply_ascii[14*8 +: 8] = "m";
                reply_ascii[15*8 +: 8] = "e";
                reply_ascii[16*8 +: 8] = ".";
            end
            3'd4: begin
                reply_len = 6'd14;
                reply_ascii[0*8 +: 8] = "S";
                reply_ascii[1*8 +: 8] = "y";
                reply_ascii[2*8 +: 8] = "s";
                reply_ascii[3*8 +: 8] = "t";
                reply_ascii[4*8 +: 8] = "e";
                reply_ascii[5*8 +: 8] = "m";
                reply_ascii[6*8 +: 8] = " ";
                reply_ascii[7*8 +: 8] = "n";
                reply_ascii[8*8 +: 8] = "o";
                reply_ascii[9*8 +: 8] = "r";
                reply_ascii[10*8 +: 8] = "m";
                reply_ascii[11*8 +: 8] = "a";
                reply_ascii[12*8 +: 8] = "l";
                reply_ascii[13*8 +: 8] = ".";
            end
            3'd5: begin
                reply_len = 6'd12;
                reply_ascii[0*8 +: 8] = "A";
                reply_ascii[1*8 +: 8] = "l";
                reply_ascii[2*8 +: 8] = "a";
                reply_ascii[3*8 +: 8] = "r";
                reply_ascii[4*8 +: 8] = "m";
                reply_ascii[5*8 +: 8] = " ";
                reply_ascii[6*8 +: 8] = "n";
                reply_ascii[7*8 +: 8] = "o";
                reply_ascii[8*8 +: 8] = "t";
                reply_ascii[9*8 +: 8] = "e";
                reply_ascii[10*8 +: 8] = "d";
                reply_ascii[11*8 +: 8] = ".";
            end
            3'd6: begin
                reply_len = 6'd15;
                reply_ascii[0*8 +: 8] = "S";
                reply_ascii[1*8 +: 8] = "c";
                reply_ascii[2*8 +: 8] = "h";
                reply_ascii[3*8 +: 8] = "e";
                reply_ascii[4*8 +: 8] = "d";
                reply_ascii[5*8 +: 8] = "u";
                reply_ascii[6*8 +: 8] = "l";
                reply_ascii[7*8 +: 8] = "e";
                reply_ascii[8*8 +: 8] = " ";
                reply_ascii[9*8 +: 8] = "n";
                reply_ascii[10*8 +: 8] = "o";
                reply_ascii[11*8 +: 8] = "t";
                reply_ascii[12*8 +: 8] = "e";
                reply_ascii[13*8 +: 8] = "d";
                reply_ascii[14*8 +: 8] = ".";
            end
            default: begin
                reply_len = 6'd10;
                reply_ascii[0*8 +: 8] = "N";
                reply_ascii[1*8 +: 8] = "e";
                reply_ascii[2*8 +: 8] = "e";
                reply_ascii[3*8 +: 8] = "d";
                reply_ascii[4*8 +: 8] = " ";
                reply_ascii[5*8 +: 8] = "h";
                reply_ascii[6*8 +: 8] = "e";
                reply_ascii[7*8 +: 8] = "l";
                reply_ascii[8*8 +: 8] = "p";
                reply_ascii[9*8 +: 8] = ".";
            end
        endcase
    end
endmodule
