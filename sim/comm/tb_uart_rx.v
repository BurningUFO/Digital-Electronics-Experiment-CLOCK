`timescale 1ns / 1ps

module tb_uart_rx;
    localparam integer CLK_FREQ = 100_000_000;
    localparam integer BAUD_RATE = 115_200;
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer BIT_PERIOD_NS = CLKS_PER_BIT * 10;

    reg clk = 1'b0;
    reg rst = 1'b0;
    reg rx = 1'b1;
    wire rx_valid;
    wire [7:0] rx_data;
    wire rx_busy;
    reg seen_valid = 1'b0;
    reg [7:0] seen_data = 8'd0;

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .rx_busy(rx_busy)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rx_valid) begin
            seen_valid <= 1'b1;
            seen_data <= rx_data;
        end
    end

    task send_byte;
        input [7:0] data;
        integer i;
        begin
            rx = 1'b0;
            #(BIT_PERIOD_NS);

            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD_NS);
            end

            rx = 1'b1;
            #(BIT_PERIOD_NS);
        end
    endtask

    initial begin
        rst = 1'b0;
        rx = 1'b1;
        repeat (5) @(posedge clk);
        rst = 1'b1;
        repeat (5) @(posedge clk);

        send_byte(8'hA5);
        repeat (20) @(posedge clk);

        if (!seen_valid) begin
            $display("FAIL tb_uart_rx no rx_valid pulse");
            $finish;
        end

        if (seen_data !== 8'hA5) begin
            $display("FAIL tb_uart_rx expected A5 got %02h", seen_data);
            $finish;
        end

        $display("PASS tb_uart_rx");
        $finish;
    end
endmodule
