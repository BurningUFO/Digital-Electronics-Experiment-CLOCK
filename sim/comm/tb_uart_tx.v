`timescale 1ns / 1ps

module tb_uart_tx;
    localparam integer CLK_FREQ = 100_000_000;
    localparam integer BAUD_RATE = 115_200;
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer BIT_PERIOD_NS = CLKS_PER_BIT * 10;

    reg clk = 1'b0;
    reg rst = 1'b0;
    reg tx_start = 1'b0;
    reg [7:0] tx_data = 8'h00;
    wire tx;
    wire tx_busy;
    wire tx_done;

    integer i;
    reg [7:0] expected;

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    always #5 clk = ~clk;

    initial begin
        expected = 8'hA5;
        rst = 1'b0;
        repeat (5) @(posedge clk);
        rst = 1'b1;
        repeat (5) @(posedge clk);

        tx_data = expected;
        tx_start = 1'b1;
        @(posedge clk);
        tx_start = 1'b0;

        wait (tx_busy == 1'b1);
        #(BIT_PERIOD_NS / 2);

        if (tx !== 1'b0) begin
            $display("FAIL tb_uart_tx start bit");
            $finish;
        end

        for (i = 0; i < 8; i = i + 1) begin
            #(BIT_PERIOD_NS);
            if (tx !== expected[i]) begin
                $display("FAIL tb_uart_tx bit %0d expected %0b got %0b", i, expected[i], tx);
                $finish;
            end
        end

        #(BIT_PERIOD_NS);
        if (tx !== 1'b1) begin
            $display("FAIL tb_uart_tx stop bit");
            $finish;
        end

        wait (tx_done == 1'b1);
        $display("PASS tb_uart_tx");
        $finish;
    end
endmodule
