module button_pulse(
    input  clk,
    input  tick_1k,
    input  rst,
    input  btn_in,
    output reg pulse
);
    reg btn_ff0;
    reg btn_ff1;
    reg [3:0] stable_cnt;
    reg btn_stable;
    reg btn_stable_d;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            btn_ff0 <= 1'b0;
            btn_ff1 <= 1'b0;
        end else begin
            btn_ff0 <= btn_in;
            btn_ff1 <= btn_ff0;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            stable_cnt   <= 4'd0;
            btn_stable   <= 1'b0;
            btn_stable_d <= 1'b0;
            pulse        <= 1'b0;
        end else begin
            pulse <= 1'b0;

            if (tick_1k) begin
                btn_stable_d <= btn_stable;

                if (btn_ff1 == btn_stable) begin
                    stable_cnt <= 4'd0;
                end else if (stable_cnt == 4'd15) begin
                    btn_stable <= btn_ff1;
                    stable_cnt <= 4'd0;
                end else begin
                    stable_cnt <= stable_cnt + 1'b1;
                end

                if (!btn_stable_d && btn_stable) begin
                    pulse <= 1'b1;
                end
            end
        end
    end
endmodule
