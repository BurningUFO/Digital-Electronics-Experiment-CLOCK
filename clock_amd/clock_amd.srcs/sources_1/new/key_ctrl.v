module key_ctrl(
    input  clk,
    input  tick_1k,
    input  rst,
    input  qd_key,
    input  sw_a,
    input  sw_b,
    input  sw_c,
    output [2:0] ctrl_sel,
    output reg qd_pulse,
    output wire key_select_pulse,
    output wire key_add_pulse,
    output wire key_confirm_pulse
);
    reg qd_ff0, qd_ff1;
    reg [3:0] stable_cnt;
    reg qd_stable;
    reg qd_stable_d;

    assign ctrl_sel = {sw_c, sw_b, sw_a};

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            qd_ff0 <= 1'b0;
            qd_ff1 <= 1'b0;
        end else begin
            qd_ff0 <= qd_key;
            qd_ff1 <= qd_ff0;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            stable_cnt  <= 4'd0;
            qd_stable   <= 1'b0;
            qd_stable_d <= 1'b0;
            qd_pulse    <= 1'b0;
        end else if (tick_1k) begin
            qd_stable_d <= qd_stable;

            if (qd_ff1 == qd_stable) begin
                stable_cnt <= 4'd0;
            end else if (stable_cnt == 4'd15) begin
                qd_stable  <= qd_ff1;
                stable_cnt <= 4'd0;
            end else begin
                stable_cnt <= stable_cnt + 1'b1;
            end

            if (!qd_stable_d && qd_stable) begin
                qd_pulse <= 1'b1;
            end else begin
                qd_pulse <= 1'b0;
            end
        end
    end

    assign key_select_pulse  = qd_pulse & (ctrl_sel == 3'b001);
    assign key_add_pulse     = qd_pulse & (ctrl_sel == 3'b010);
    assign key_confirm_pulse = qd_pulse & (ctrl_sel == 3'b011);
endmodule
