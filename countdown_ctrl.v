module countdown_ctrl(
    input  clk_1k,
    input  rst,
    input  tick_1h,
    input  mode_countdown,
    input  qd_pulse,
    input  [2:0] ctrl_sel,
    output reg [3:0] min_ten_bcd,
    output reg [3:0] min_unit_bcd,
    output reg [3:0] sec_ten_bcd,
    output reg [3:0] sec_unit_bcd
);
    reg        countdown_run;
    wire countdown_nonzero;
    wire countdown_one;

    assign countdown_nonzero = (|min_ten_bcd) |
                               (|min_unit_bcd) |
                               (|sec_ten_bcd) |
                               (|sec_unit_bcd);
    assign countdown_one  = (min_ten_bcd == 4'd0) &&
                            (min_unit_bcd == 4'd0) &&
                            (sec_ten_bcd == 4'd0) &&
                            (sec_unit_bcd == 4'd1);

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            countdown_run <= 1'b0;
        end else if (!mode_countdown) begin
            countdown_run <= 1'b0;
        end else if (countdown_run) begin
            if (qd_pulse && ctrl_sel == 3'b011) begin
                countdown_run <= 1'b0;
            end else if (tick_1h && countdown_one) begin
                countdown_run <= 1'b0;
            end
        end else if (qd_pulse && ctrl_sel == 3'b011 && countdown_nonzero) begin
            countdown_run <= 1'b1;
        end
    end

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            min_ten_bcd  <= 4'd0;
            min_unit_bcd <= 4'd0;
            sec_ten_bcd  <= 4'd0;
            sec_unit_bcd <= 4'd0;
        end else if (mode_countdown && !countdown_run && qd_pulse) begin
            case (ctrl_sel)
                3'b001: begin
                    if (min_ten_bcd == 4'd9) begin
                        min_ten_bcd <= 4'd0;
                    end else begin
                        min_ten_bcd <= min_ten_bcd + 1'b1;
                    end
                end
                3'b010: begin
                    if (min_unit_bcd == 4'd9) begin
                        min_unit_bcd <= 4'd0;
                    end else begin
                        min_unit_bcd <= min_unit_bcd + 1'b1;
                    end
                end
                3'b100: begin
                    if (sec_ten_bcd == 4'd5) begin
                        sec_ten_bcd <= 4'd0;
                    end else begin
                        sec_ten_bcd <= sec_ten_bcd + 1'b1;
                    end
                end
                3'b101: begin
                    if (sec_unit_bcd == 4'd9) begin
                        sec_unit_bcd <= 4'd0;
                    end else begin
                        sec_unit_bcd <= sec_unit_bcd + 1'b1;
                    end
                end
                default: begin
                end
            endcase
        end else if (mode_countdown && countdown_run && tick_1h && countdown_one) begin
            min_ten_bcd  <= 4'd0;
            min_unit_bcd <= 4'd0;
            sec_ten_bcd  <= 4'd0;
            sec_unit_bcd <= 4'd0;
        end else if (mode_countdown && countdown_run && tick_1h) begin
            if (sec_unit_bcd > 4'd0) begin
                sec_unit_bcd <= sec_unit_bcd - 1'b1;
            end else begin
                sec_unit_bcd <= 4'd9;
                if (sec_ten_bcd > 4'd0) begin
                    sec_ten_bcd <= sec_ten_bcd - 1'b1;
                end else begin
                    sec_ten_bcd <= 4'd5;
                    if (min_unit_bcd > 4'd0) begin
                        min_unit_bcd <= min_unit_bcd - 1'b1;
                    end else begin
                        min_unit_bcd <= 4'd9;
                        if (min_ten_bcd > 4'd0) begin
                            min_ten_bcd <= min_ten_bcd - 1'b1;
                        end
                    end
                end
            end
        end
    end
endmodule
