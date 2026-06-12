`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// UART 8N1 发送器。
//
// tx_start 拉高一拍后锁存 tx_data，依次发送 start bit、8 个数据位和 stop bit。
// tx_busy 表示发送过程正在进行，tx_done 在整帧发送完成时输出一拍。
// -----------------------------------------------------------------------------
module uart_tx #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx,
    output reg        tx_busy,
    output reg        tx_done
);
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam [2:0] ST_IDLE  = 3'd0;
    localparam [2:0] ST_START = 3'd1;
    localparam [2:0] ST_DATA  = 3'd2;
    localparam [2:0] ST_STOP  = 3'd3;
    localparam [2:0] ST_DONE  = 3'd4;

    reg [2:0] state;
    reg [31:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] tx_shift;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state     <= ST_IDLE;
            clk_count <= 32'd0;
            bit_index <= 3'd0;
            tx_shift  <= 8'd0;
            tx         <= 1'b1;
            tx_busy    <= 1'b0;
            tx_done    <= 1'b0;
        end else begin
            tx_done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    tx        <= 1'b1;
                    tx_busy   <= 1'b0;
                    clk_count <= 32'd0;
                    bit_index <= 3'd0;

                    if (tx_start) begin
                        tx_shift  <= tx_data;
                        tx_busy   <= 1'b1;
                        tx        <= 1'b0;
                        clk_count <= CLKS_PER_BIT - 1;
                        state     <= ST_START;
                    end
                end

                ST_START: begin
                    tx <= 1'b0;

                    if (clk_count == 32'd0) begin
                        tx        <= tx_shift[0];
                        clk_count <= CLKS_PER_BIT - 1;
                        state     <= ST_DATA;
                    end else begin
                        clk_count <= clk_count - 1'b1;
                    end
                end

                ST_DATA: begin
                    tx <= tx_shift[bit_index];

                    if (clk_count == 32'd0) begin
                        clk_count <= CLKS_PER_BIT - 1;

                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            tx        <= 1'b1;
                            state     <= ST_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            tx        <= tx_shift[bit_index + 1'b1];
                        end
                    end else begin
                        clk_count <= clk_count - 1'b1;
                    end
                end

                ST_STOP: begin
                    tx <= 1'b1;

                    if (clk_count == 32'd0) begin
                        state <= ST_DONE;
                    end else begin
                        clk_count <= clk_count - 1'b1;
                    end
                end

                ST_DONE: begin
                    tx_done <= 1'b1;
                    tx_busy <= 1'b0;
                    tx      <= 1'b1;
                    state   <= ST_IDLE;
                end

                default: begin
                    state   <= ST_IDLE;
                    tx      <= 1'b1;
                    tx_busy <= 1'b0;
                end
            endcase
        end
    end
endmodule
