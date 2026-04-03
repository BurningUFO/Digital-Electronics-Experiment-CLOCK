module clk_ring(
    input clk_1k,
    input rst,
    output tick_1h
);
    reg [9:0] cnt;

    assign tick_1h = (cnt == 10'd999);

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            cnt <= 10'd0;
        end else if (tick_1h) begin
            cnt <= 10'd0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
endmodule
