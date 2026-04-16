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
    wire edit_min_ten;
    wire edit_min_unit;
    wire edit_sec_ten;
    wire edit_sec_unit;
    wire run_tick;
    wire run_tick_nonzero;
    wire borrow_sec_ten;
    wire borrow_min_unit;
    wire borrow_min_ten;

    assign countdown_nonzero = (|min_ten_bcd) |
                               (|min_unit_bcd) |
                               (|sec_ten_bcd) |
                               (|sec_unit_bcd);
    assign countdown_one  = (min_ten_bcd == 4'd0) &&
                            (min_unit_bcd == 4'd0) &&
                            (sec_ten_bcd == 4'd0) &&
                            (sec_unit_bcd == 4'd1);
    assign edit_min_ten   = mode_countdown & ~countdown_run & qd_pulse & (ctrl_sel == 3'b001);
    assign edit_min_unit  = mode_countdown & ~countdown_run & qd_pulse & (ctrl_sel == 3'b010);
    assign edit_sec_ten   = mode_countdown & ~countdown_run & qd_pulse & (ctrl_sel == 3'b100);
    assign edit_sec_unit  = mode_countdown & ~countdown_run & qd_pulse & (ctrl_sel == 3'b101);
    assign run_tick       = mode_countdown & countdown_run & tick_1h;
    assign run_tick_nonzero = run_tick & countdown_nonzero;
    assign borrow_sec_ten   = run_tick_nonzero & (sec_unit_bcd == 4'd0);
    assign borrow_min_unit  = borrow_sec_ten & (sec_ten_bcd == 4'd0);
    assign borrow_min_ten   = borrow_min_unit & (min_unit_bcd == 4'd0);

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
            sec_unit_bcd <= 4'd0;
        end else if (edit_sec_unit) begin
            if (sec_unit_bcd == 4'd9) begin
                sec_unit_bcd <= 4'd0;
            end else begin
                sec_unit_bcd <= sec_unit_bcd + 1'b1;
            end
        end else if (run_tick_nonzero) begin
            if (sec_unit_bcd == 4'd0) begin
                sec_unit_bcd <= 4'd9;
            end else begin
                sec_unit_bcd <= sec_unit_bcd - 1'b1;
            end
        end
    end

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            sec_ten_bcd <= 4'd0;
        end else if (edit_sec_ten) begin
            if (sec_ten_bcd == 4'd5) begin
                sec_ten_bcd <= 4'd0;
            end else begin
                sec_ten_bcd <= sec_ten_bcd + 1'b1;
            end
        end else if (borrow_sec_ten) begin
            if (sec_ten_bcd == 4'd0) begin
                sec_ten_bcd <= 4'd5;
            end else begin
                sec_ten_bcd <= sec_ten_bcd - 1'b1;
            end
        end
    end

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            min_unit_bcd <= 4'd0;
        end else if (edit_min_unit) begin
            if (min_unit_bcd == 4'd9) begin
                min_unit_bcd <= 4'd0;
            end else begin
                min_unit_bcd <= min_unit_bcd + 1'b1;
            end
        end else if (borrow_min_unit) begin
            if (min_unit_bcd == 4'd0) begin
                min_unit_bcd <= 4'd9;
            end else begin
                min_unit_bcd <= min_unit_bcd - 1'b1;
            end
        end
    end

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            min_ten_bcd <= 4'd0;
        end else if (edit_min_ten) begin
            if (min_ten_bcd == 4'd9) begin
                min_ten_bcd <= 4'd0;
            end else begin
                min_ten_bcd <= min_ten_bcd + 1'b1;
            end
        end else if (borrow_min_ten && min_ten_bcd > 4'd0) begin
            min_ten_bcd <= min_ten_bcd - 1'b1;
        end
    end
endmodule
