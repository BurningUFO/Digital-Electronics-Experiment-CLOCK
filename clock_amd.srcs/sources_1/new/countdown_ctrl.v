// -----------------------------------------------------------------------------
// 倒计时控制器。
//
// 保存倒计时 HH:MM:SS，支持设置层按键编辑、浏览层启动/停止，以及
// ClockLink PC 直接 COUNT_SET/START/STOP 控制。
//
// 协议语义：COUNT_SET 只加载新时间并停止倒计时；若 PC 需要立即运行，
// 必须随后发送 COUNT_START。
// -----------------------------------------------------------------------------
module countdown_ctrl(
    input  clk,
    input  rst,
    input  tick_1h,
    input  hour_inc_pulse,
    input  hour_dec_pulse,
    input  min_inc_pulse,
    input  min_dec_pulse,
    input  sec_inc_pulse,
    input  sec_dec_pulse,
    input  countdown_start_pulse,
    input  countdown_stop_pulse,
    input  pc_count_load_valid,
    input  [3:0] pc_count_hour_ten_bcd,
    input  [3:0] pc_count_hour_unit_bcd,
    input  [3:0] pc_count_min_ten_bcd,
    input  [3:0] pc_count_min_unit_bcd,
    input  [3:0] pc_count_sec_ten_bcd,
    input  [3:0] pc_count_sec_unit_bcd,
    input  pc_count_start_pulse,
    input  pc_count_stop_pulse,
    output reg countdown_run,
    output countdown_done_pulse,
    output reg [3:0] hour_ten_bcd,
    output reg [3:0] hour_unit_bcd,
    output reg [3:0] min_ten_bcd,
    output reg [3:0] min_unit_bcd,
    output reg [3:0] sec_ten_bcd,
    output reg [3:0] sec_unit_bcd
);
    wire countdown_nonzero;
    wire countdown_one;
    wire run_tick;
    wire run_tick_nonzero;
    wire borrow_minute;
    wire borrow_hour;

    // 非零判断用于禁止 00:00:00 被启动。
    assign countdown_nonzero = (|hour_ten_bcd) |
                               (|hour_unit_bcd) |
                               (|min_ten_bcd) |
                               (|min_unit_bcd) |
                               (|sec_ten_bcd) |
                               (|sec_unit_bcd);
    assign countdown_one     = (hour_ten_bcd == 4'd0) &&
                               (hour_unit_bcd == 4'd0) &&
                               (min_ten_bcd == 4'd0) &&
                               (min_unit_bcd == 4'd0) &&
                               (sec_ten_bcd == 4'd0) &&
                               (sec_unit_bcd == 4'd1);
    assign run_tick          = countdown_run & tick_1h;
    assign run_tick_nonzero  = run_tick & countdown_nonzero;
    assign borrow_minute     = run_tick_nonzero &
                               (sec_ten_bcd == 4'd0) &
                               (sec_unit_bcd == 4'd0);
    assign borrow_hour       = borrow_minute &
                               (min_ten_bcd == 4'd0) &
                               (min_unit_bcd == 4'd0);
    assign countdown_done_pulse = countdown_run & tick_1h & countdown_one;

    // 运行状态优先响应 PC 控制，再响应板上按键控制。
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            countdown_run <= 1'b0;
        end else if (pc_count_load_valid) begin
            countdown_run <= 1'b0;
        end else if (pc_count_stop_pulse) begin
            countdown_run <= 1'b0;
        end else if (pc_count_start_pulse && countdown_nonzero) begin
            countdown_run <= 1'b1;
        end else if (countdown_run) begin
            if (countdown_stop_pulse) begin
                countdown_run <= 1'b0;
            end else if (tick_1h && countdown_one) begin
                countdown_run <= 1'b0;
            end
        end else if (countdown_start_pulse && countdown_nonzero) begin
            countdown_run <= 1'b1;
        end else if (countdown_stop_pulse) begin
            countdown_run <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sec_unit_bcd <= 4'd0;
            sec_ten_bcd  <= 4'd0;
        end else if (pc_count_load_valid) begin
            sec_ten_bcd <= pc_count_sec_ten_bcd;
            sec_unit_bcd <= pc_count_sec_unit_bcd;
        end else if (~countdown_run && sec_inc_pulse) begin
            if (sec_ten_bcd == 4'd5 && sec_unit_bcd == 4'd9) begin
                sec_ten_bcd  <= 4'd0;
                sec_unit_bcd <= 4'd0;
            end else if (sec_unit_bcd == 4'd9) begin
                sec_ten_bcd  <= sec_ten_bcd + 1'b1;
                sec_unit_bcd <= 4'd0;
            end else begin
                sec_unit_bcd <= sec_unit_bcd + 1'b1;
            end
        end else if (~countdown_run && sec_dec_pulse) begin
            if (sec_ten_bcd == 4'd0 && sec_unit_bcd == 4'd0) begin
                sec_ten_bcd  <= 4'd5;
                sec_unit_bcd <= 4'd9;
            end else if (sec_unit_bcd == 4'd0) begin
                sec_ten_bcd  <= sec_ten_bcd - 1'b1;
                sec_unit_bcd <= 4'd9;
            end else begin
                sec_unit_bcd <= sec_unit_bcd - 1'b1;
            end
        end else if (run_tick_nonzero) begin
            if (sec_ten_bcd == 4'd0 && sec_unit_bcd == 4'd0) begin
                sec_ten_bcd  <= 4'd5;
                sec_unit_bcd <= 4'd9;
            end else if (sec_unit_bcd == 4'd0) begin
                sec_ten_bcd  <= sec_ten_bcd - 1'b1;
                sec_unit_bcd <= 4'd9;
            end else begin
                sec_unit_bcd <= sec_unit_bcd - 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            min_unit_bcd <= 4'd0;
            min_ten_bcd  <= 4'd0;
        end else if (pc_count_load_valid) begin
            min_ten_bcd <= pc_count_min_ten_bcd;
            min_unit_bcd <= pc_count_min_unit_bcd;
        end else if (~countdown_run && min_inc_pulse) begin
            if (min_ten_bcd == 4'd5 && min_unit_bcd == 4'd9) begin
                min_ten_bcd  <= 4'd0;
                min_unit_bcd <= 4'd0;
            end else if (min_unit_bcd == 4'd9) begin
                min_ten_bcd  <= min_ten_bcd + 1'b1;
                min_unit_bcd <= 4'd0;
            end else begin
                min_unit_bcd <= min_unit_bcd + 1'b1;
            end
        end else if (~countdown_run && min_dec_pulse) begin
            if (min_ten_bcd == 4'd0 && min_unit_bcd == 4'd0) begin
                min_ten_bcd  <= 4'd5;
                min_unit_bcd <= 4'd9;
            end else if (min_unit_bcd == 4'd0) begin
                min_ten_bcd  <= min_ten_bcd - 1'b1;
                min_unit_bcd <= 4'd9;
            end else begin
                min_unit_bcd <= min_unit_bcd - 1'b1;
            end
        end else if (borrow_minute) begin
            if (min_ten_bcd == 4'd0 && min_unit_bcd == 4'd0) begin
                min_ten_bcd  <= 4'd5;
                min_unit_bcd <= 4'd9;
            end else if (min_unit_bcd == 4'd0) begin
                min_ten_bcd  <= min_ten_bcd - 1'b1;
                min_unit_bcd <= 4'd9;
            end else begin
                min_unit_bcd <= min_unit_bcd - 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            hour_unit_bcd <= 4'd0;
            hour_ten_bcd  <= 4'd0;
        end else if (pc_count_load_valid) begin
            hour_ten_bcd <= pc_count_hour_ten_bcd;
            hour_unit_bcd <= pc_count_hour_unit_bcd;
        end else if (~countdown_run && hour_inc_pulse) begin
            if (hour_ten_bcd == 4'd2 && hour_unit_bcd == 4'd3) begin
                hour_ten_bcd  <= 4'd0;
                hour_unit_bcd <= 4'd0;
            end else if (hour_unit_bcd == 4'd9) begin
                hour_ten_bcd  <= hour_ten_bcd + 1'b1;
                hour_unit_bcd <= 4'd0;
            end else begin
                hour_unit_bcd <= hour_unit_bcd + 1'b1;
            end
        end else if (~countdown_run && hour_dec_pulse) begin
            if (hour_ten_bcd == 4'd0 && hour_unit_bcd == 4'd0) begin
                hour_ten_bcd  <= 4'd2;
                hour_unit_bcd <= 4'd3;
            end else if (hour_unit_bcd == 4'd0) begin
                hour_ten_bcd  <= hour_ten_bcd - 1'b1;
                hour_unit_bcd <= 4'd9;
            end else begin
                hour_unit_bcd <= hour_unit_bcd - 1'b1;
            end
        end else if (borrow_hour && (hour_ten_bcd != 4'd0 || hour_unit_bcd != 4'd0)) begin
            if (hour_unit_bcd == 4'd0) begin
                hour_ten_bcd  <= hour_ten_bcd - 1'b1;
                hour_unit_bcd <= 4'd9;
            end else begin
                hour_unit_bcd <= hour_unit_bcd - 1'b1;
            end
        end
    end
endmodule
