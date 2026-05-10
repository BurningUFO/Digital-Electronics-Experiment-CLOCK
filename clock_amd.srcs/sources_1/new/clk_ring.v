module clk_ring(
    input clk,
    input tick_1k,
    input rst,
    output tick_1h
);
    reg [9:0] cnt;

    assign tick_1h = tick_1k && (cnt == 10'd999);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cnt <= 10'd0;
        end else if (tick_1k) begin
            if (cnt == 10'd999) begin
                cnt <= 10'd0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule
