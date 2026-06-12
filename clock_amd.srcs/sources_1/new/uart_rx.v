`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// UART 8N1 接收器。
//
// 参数化支持不同时钟和波特率；当前工程使用 100MHz / 115200。
// 检测 start bit 后在每个 bit 中点采样，收到 8 个数据位和 stop bit 后
// 输出单周期 rx_valid 与 rx_data。
// -----------------------------------------------------------------------------
module uart_rx #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg        rx_valid,
    output reg [7:0]  rx_data,
    output reg        rx_busy
);
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer HALF_BIT     = CLKS_PER_BIT / 2;

    localparam [2:0] ST_IDLE  = 3'd0;
    localparam [2:0] ST_START = 3'd1;
    localparam [2:0] ST_DATA  = 3'd2;
    localparam [2:0] ST_STOP  = 3'd3;

    reg [2:0] state;
    reg [31:0] clk_count;
    reg [2:0] bit_index;
    reg rx_meta;
    reg rx_sync;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state     <= ST_IDLE;
            clk_count <= 32'd0;
            bit_index <= 3'd0;
            rx_data   <= 8'd0;
            rx_valid  <= 1'b0;
            rx_busy   <= 1'b0;
        end else begin
            rx_valid <= 1'b0;

            case (state)
                ST_IDLE: begin
                    rx_busy   <= 1'b0;
                    clk_count <= 32'd0;
                    bit_index <= 3'd0;

                    if (!rx_sync) begin
                        rx_busy   <= 1'b1;
                        clk_count <= HALF_BIT;
                        state     <= ST_START;
                    end
                end

                ST_START: begin
                    if (clk_count == 32'd0) begin
                        if (!rx_sync) begin
                            clk_count <= CLKS_PER_BIT - 1;
                            state     <= ST_DATA;
                        end else begin
                            state   <= ST_IDLE;
                            rx_busy <= 1'b0;
                        end
                    end else begin
                        clk_count <= clk_count - 1'b1;
                    end
                end

                ST_DATA: begin
                    if (clk_count == 32'd0) begin
                        rx_data[bit_index] <= rx_sync;
                        clk_count <= CLKS_PER_BIT - 1;

                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state     <= ST_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count - 1'b1;
                    end
                end

                ST_STOP: begin
                    if (clk_count == 32'd0) begin
                        rx_busy <= 1'b0;
                        state   <= ST_IDLE;

                        if (rx_sync) begin
                            rx_valid <= 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count - 1'b1;
                    end
                end

                default: begin
                    state   <= ST_IDLE;
                    rx_busy <= 1'b0;
                end
            endcase
        end
    end
endmodule
