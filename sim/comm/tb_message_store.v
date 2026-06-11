`timescale 1ns / 1ps

module tb_message_store;
    reg clk = 1'b0;
    reg rst = 1'b0;
    reg store_begin = 1'b0;
    reg [151:0] store_timestamp_ascii = {19{8'h20}};
    reg [6:0] store_len = 7'd0;
    reg store_char_valid = 1'b0;
    reg [6:0] store_char_index = 7'd0;
    reg [7:0] store_char_ascii = 8'h20;
    reg clear_all = 1'b0;
    reg clear_slot_valid = 1'b0;
    reg [3:0] clear_slot = 4'd0;
    reg [3:0] selected_slot = 4'd0;
    reg [6:0] window_base_index = 7'd0;

    wire selected_valid;
    wire selected_unread;
    wire [151:0] selected_timestamp_ascii;
    wire [6:0] selected_len;
    wire [511:0] selected_window_ascii;
    wire [4:0] message_count;
    wire [4:0] unread_count;

    integer i;

    always #5 clk = ~clk;

    message_store dut (
        .clk(clk),
        .rst(rst),
        .store_begin(store_begin),
        .store_timestamp_ascii(store_timestamp_ascii),
        .store_len(store_len),
        .store_char_valid(store_char_valid),
        .store_char_index(store_char_index),
        .store_char_ascii(store_char_ascii),
        .clear_all(clear_all),
        .clear_slot_valid(clear_slot_valid),
        .clear_slot(clear_slot),
        .selected_slot(selected_slot),
        .window_base_index(window_base_index),
        .selected_valid(selected_valid),
        .selected_unread(selected_unread),
        .selected_timestamp_ascii(selected_timestamp_ascii),
        .selected_len(selected_len),
        .selected_window_ascii(selected_window_ascii),
        .message_count(message_count),
        .unread_count(unread_count)
    );

    task pulse_store_begin;
        input [151:0] ts;
        input [6:0] len;
        begin
            @(negedge clk);
            store_timestamp_ascii = ts;
            store_len = len;
            store_begin = 1'b1;
            @(negedge clk);
            store_begin = 1'b0;
        end
    endtask

    task push_char;
        input [6:0] idx;
        input [7:0] ch;
        begin
            @(negedge clk);
            store_char_index = idx;
            store_char_ascii = ch;
            store_char_valid = 1'b1;
            @(negedge clk);
            store_char_valid = 1'b0;
        end
    endtask

    task store_hello_fpga;
        begin
            pulse_store_begin({"2","0","2","6","-","0","6","-","0","5","T","1","1",":","5","2",":","2","0"}, 7'd10);
            push_char(7'd0, "h");
            push_char(7'd1, "e");
            push_char(7'd2, "l");
            push_char(7'd3, "l");
            push_char(7'd4, "o");
            push_char(7'd5, " ");
            push_char(7'd6, "f");
            push_char(7'd7, "p");
            push_char(7'd8, "g");
            push_char(7'd9, "a");
        end
    endtask

    task store_hello;
        begin
            pulse_store_begin({"2","0","2","6","-","0","6","-","0","5","T","1","1",":","5","2",":","2","1"}, 7'd5);
            push_char(7'd0, "h");
            push_char(7'd1, "e");
            push_char(7'd2, "l");
            push_char(7'd3, "l");
            push_char(7'd4, "o");
        end
    endtask

    task wait_rebuild;
        begin
            for (i = 0; i < 220; i = i + 1) begin
                @(posedge clk);
            end
        end
    endtask

    task check_window_hello;
        input [3:0] slot;
        begin
            if (!selected_valid) begin
                $display("FAIL tb_message_store: slot %0d not valid", slot);
                $finish;
            end
            if (selected_len != 7'd5) begin
                $display("FAIL tb_message_store: slot %0d len=%0d expected 5", slot, selected_len);
                $finish;
            end
            if ((selected_window_ascii[0*8 +: 8] != "h") ||
                (selected_window_ascii[1*8 +: 8] != "e") ||
                (selected_window_ascii[2*8 +: 8] != "l") ||
                (selected_window_ascii[3*8 +: 8] != "l") ||
                (selected_window_ascii[4*8 +: 8] != "o") ||
                (selected_window_ascii[5*8 +: 8] != " ")) begin
                $display("FAIL tb_message_store: slot %0d is not hello: %c%c%c%c%c%c",
                         slot,
                         selected_window_ascii[0*8 +: 8],
                         selected_window_ascii[1*8 +: 8],
                         selected_window_ascii[2*8 +: 8],
                         selected_window_ascii[3*8 +: 8],
                         selected_window_ascii[4*8 +: 8],
                         selected_window_ascii[5*8 +: 8]);
                $finish;
            end
        end
    endtask

    task check_window_hello_fpga;
        input [3:0] slot;
        begin
            if (!selected_valid) begin
                $display("FAIL tb_message_store: slot %0d not valid", slot);
                $finish;
            end
            if (selected_len != 7'd10) begin
                $display("FAIL tb_message_store: slot %0d len=%0d expected 10", slot, selected_len);
                $finish;
            end
            if ((selected_window_ascii[0*8 +: 8] != "h") ||
                (selected_window_ascii[1*8 +: 8] != "e") ||
                (selected_window_ascii[2*8 +: 8] != "l") ||
                (selected_window_ascii[3*8 +: 8] != "l") ||
                (selected_window_ascii[4*8 +: 8] != "o") ||
                (selected_window_ascii[5*8 +: 8] != " ") ||
                (selected_window_ascii[6*8 +: 8] != "f") ||
                (selected_window_ascii[7*8 +: 8] != "p") ||
                (selected_window_ascii[8*8 +: 8] != "g") ||
                (selected_window_ascii[9*8 +: 8] != "a") ||
                (selected_window_ascii[10*8 +: 8] != " ")) begin
                $display("FAIL tb_message_store: slot %0d is not hello fpga: %c%c%c%c%c%c%c%c%c%c%c",
                         slot,
                         selected_window_ascii[0*8 +: 8],
                         selected_window_ascii[1*8 +: 8],
                         selected_window_ascii[2*8 +: 8],
                         selected_window_ascii[3*8 +: 8],
                         selected_window_ascii[4*8 +: 8],
                         selected_window_ascii[5*8 +: 8],
                         selected_window_ascii[6*8 +: 8],
                         selected_window_ascii[7*8 +: 8],
                         selected_window_ascii[8*8 +: 8],
                         selected_window_ascii[9*8 +: 8],
                         selected_window_ascii[10*8 +: 8]);
                $finish;
            end
        end
    endtask

    initial begin
        #20;
        rst = 1'b1;
        wait_rebuild;

        selected_slot = 4'd0;
        store_hello_fpga;
        wait_rebuild;
        check_window_hello_fpga(4'd0);

        store_hello;
        wait_rebuild;
        if ((message_count != 5'd2) || (unread_count != 5'd2)) begin
            $display("FAIL tb_message_store: counts count=%0d unread=%0d", message_count, unread_count);
            $finish;
        end
        check_window_hello(4'd0);

        selected_slot = 4'd1;
        wait_rebuild;
        check_window_hello_fpga(4'd1);

        selected_slot = 4'd0;
        wait_rebuild;
        check_window_hello(4'd0);

        $display("PASS tb_message_store");
        $finish;
    end
endmodule
