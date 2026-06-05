module time_core(
    input clk,
    input tick_1k,
    input rst,
    input tick_1h,
    input freeze_run,
    input add_sec_pulse,
    input dec_sec_pulse,
    input add_hour_pulse,
    input dec_hour_pulse,
    input add_min_pulse,
    input dec_min_pulse,
    input pc_time_load_valid,
    input [3:0] pc_hour_ten_bcd,
    input [3:0] pc_hour_unit_bcd,
    input [3:0] pc_min_ten_bcd,
    input [3:0] pc_min_unit_bcd,
    input [3:0] pc_sec_ten_bcd,
    input [3:0] pc_sec_unit_bcd,
    output reg [3:0] sec_unit_bcd,
    output reg [3:0] sec_ten_bcd,
    output reg [3:0] min_unit_bcd,
    output reg [3:0] min_ten_bcd,
    output reg [3:0] hour_unit_bcd,
    output reg [3:0] hour_ten_bcd
);
    wire tick_en;
    wire sec_wrap;
    wire min_wrap;

    assign tick_en  = tick_1h & ~freeze_run & ~pc_time_load_valid &
                      ~add_sec_pulse & ~dec_sec_pulse &
                      ~add_hour_pulse & ~dec_hour_pulse &
                      ~add_min_pulse & ~dec_min_pulse;
    assign sec_wrap = tick_en &
                      (sec_ten_bcd == 4'd5) &
                      (sec_unit_bcd == 4'd9);
    assign min_wrap = sec_wrap &
                      (min_ten_bcd == 4'd5) &
                      (min_unit_bcd == 4'd9);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sec_unit_bcd  <= 4'd0;
            sec_ten_bcd   <= 4'd0;
        end else if (pc_time_load_valid) begin
            sec_unit_bcd <= pc_sec_unit_bcd;
            sec_ten_bcd  <= pc_sec_ten_bcd;
        end else if (add_sec_pulse) begin
            if (sec_ten_bcd == 4'd5 && sec_unit_bcd == 4'd9) begin
                sec_ten_bcd  <= 4'd0;
                sec_unit_bcd <= 4'd0;
            end else if (sec_unit_bcd == 4'd9) begin
                sec_ten_bcd  <= sec_ten_bcd + 1'b1;
                sec_unit_bcd <= 4'd0;
            end else begin
                sec_unit_bcd <= sec_unit_bcd + 1'b1;
            end
        end else if (dec_sec_pulse) begin
            if (sec_ten_bcd == 4'd0 && sec_unit_bcd == 4'd0) begin
                sec_ten_bcd  <= 4'd5;
                sec_unit_bcd <= 4'd9;
            end else if (sec_unit_bcd == 4'd0) begin
                sec_ten_bcd  <= sec_ten_bcd - 1'b1;
                sec_unit_bcd <= 4'd9;
            end else begin
                sec_unit_bcd <= sec_unit_bcd - 1'b1;
            end
        end else if (tick_1k && tick_en) begin
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

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            min_unit_bcd <= 4'd0;
            min_ten_bcd  <= 4'd0;
        end else if (pc_time_load_valid) begin
            min_unit_bcd <= pc_min_unit_bcd;
            min_ten_bcd  <= pc_min_ten_bcd;
        end else if (add_min_pulse) begin
            if (min_ten_bcd == 4'd5 && min_unit_bcd == 4'd9) begin
                min_ten_bcd  <= 4'd0;
                min_unit_bcd <= 4'd0;
            end else if (min_unit_bcd == 4'd9) begin
                min_ten_bcd  <= min_ten_bcd + 1'b1;
                min_unit_bcd <= 4'd0;
            end else begin
                min_unit_bcd <= min_unit_bcd + 1'b1;
            end
        end else if (dec_min_pulse) begin
            if (min_ten_bcd == 4'd0 && min_unit_bcd == 4'd0) begin
                min_ten_bcd  <= 4'd5;
                min_unit_bcd <= 4'd9;
            end else if (min_unit_bcd == 4'd0) begin
                min_ten_bcd  <= min_ten_bcd - 1'b1;
                min_unit_bcd <= 4'd9;
            end else begin
                min_unit_bcd <= min_unit_bcd - 1'b1;
            end
        end else if (tick_1k && sec_wrap) begin
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

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            hour_unit_bcd <= 4'd0;
            hour_ten_bcd  <= 4'd0;
        end else if (pc_time_load_valid) begin
            hour_unit_bcd <= pc_hour_unit_bcd;
            hour_ten_bcd  <= pc_hour_ten_bcd;
        end else if (add_hour_pulse) begin
            if (hour_ten_bcd == 4'd2 && hour_unit_bcd == 4'd3) begin
                hour_ten_bcd  <= 4'd0;
                hour_unit_bcd <= 4'd0;
            end else if (hour_unit_bcd == 4'd9) begin
                hour_unit_bcd <= 4'd0;
                hour_ten_bcd  <= hour_ten_bcd + 1'b1;
            end else begin
                hour_unit_bcd <= hour_unit_bcd + 1'b1;
            end
        end else if (dec_hour_pulse) begin
            if (hour_ten_bcd == 4'd0 && hour_unit_bcd == 4'd0) begin
                hour_ten_bcd  <= 4'd2;
                hour_unit_bcd <= 4'd3;
            end else if (hour_unit_bcd == 4'd0) begin
                hour_ten_bcd  <= hour_ten_bcd - 1'b1;
                hour_unit_bcd <= 4'd9;
            end else begin
                hour_unit_bcd <= hour_unit_bcd - 1'b1;
            end
        end else if (tick_1k && min_wrap) begin
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
