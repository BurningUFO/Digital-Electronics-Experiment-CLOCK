module time_core(
    input clk_1k,
    input rst,
    input tick_1h,
    input freeze_run,
    input add_hour_pulse,
    input add_min_pulse,
    output reg [3:0] sec_unit_bcd,
    output reg [3:0] sec_ten_bcd,
    output reg [3:0] min_unit_bcd,
    output reg [3:0] min_ten_bcd,
    output reg [3:0] hour_unit_bcd,
    output reg [3:0] hour_ten_bcd
);
    wire tick_en;
    wire sec_wrap;
    wire min_en;
    wire min_wrap;
    wire hour_en;

    assign tick_en  = tick_1h & ~freeze_run & ~add_hour_pulse & ~add_min_pulse;
    assign sec_wrap = tick_en &
                      (sec_ten_bcd == 4'd5) &
                      (sec_unit_bcd == 4'd9);
    assign min_en   = add_min_pulse | sec_wrap;
    assign min_wrap = sec_wrap &
                      (min_ten_bcd == 4'd5) &
                      (min_unit_bcd == 4'd9);
    assign hour_en  = add_hour_pulse | min_wrap;

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            sec_unit_bcd  <= 4'd0;
            sec_ten_bcd   <= 4'd0;
        end else if (tick_en) begin
            if (sec_ten_bcd == 4'd5 && sec_unit_bcd == 4'd9) begin
                sec_ten_bcd  <= 4'd0;
                sec_unit_bcd <= 4'd0;
            end else if (sec_unit_bcd == 4'd9) begin
                sec_ten_bcd  <= sec_ten_bcd + 1'b1;
                sec_unit_bcd <= 4'd0;
            end else begin
                sec_unit_bcd <= sec_unit_bcd + 1'b1;
            end
        end
    end

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            min_unit_bcd <= 4'd0;
            min_ten_bcd  <= 4'd0;
        end else if (min_en) begin
            if (min_ten_bcd == 4'd5 && min_unit_bcd == 4'd9) begin
                min_ten_bcd  <= 4'd0;
                min_unit_bcd <= 4'd0;
            end else if (min_unit_bcd == 4'd9) begin
                min_ten_bcd  <= min_ten_bcd + 1'b1;
                min_unit_bcd <= 4'd0;
            end else begin
                min_unit_bcd <= min_unit_bcd + 1'b1;
            end
        end
    end

    always @(posedge clk_1k or negedge rst) begin
        if (!rst) begin
            hour_unit_bcd <= 4'd0;
            hour_ten_bcd  <= 4'd0;
        end else if (hour_en) begin
            if (hour_ten_bcd == 4'd2 && hour_unit_bcd == 4'd3) begin
                hour_ten_bcd  <= 4'd0;
                hour_unit_bcd <= 4'd0;
            end else if (hour_unit_bcd == 4'd9) begin
                hour_unit_bcd <= 4'd0;
                hour_ten_bcd  <= hour_ten_bcd + 1'b1;
            end else begin
                hour_unit_bcd <= hour_unit_bcd + 1'b1;
            end
        end
    end
endmodule
