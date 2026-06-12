// -----------------------------------------------------------------------------
// 八位数码管显示内容控制。
//
// 输入均为各功能模块已经计算好的 BCD/状态信号；本模块只负责：
// 1. 按当前模式选择要显示的 8 个字符码。
// 2. 在设置层对当前字段做闪烁隐藏。
// 3. 对 COMM 状态、日程类型等非数字内容转成 seg_7 能识别的字符码。
//
// 输出仍是 6-bit 字符码，真正的七段译码和位扫描在 nexys_seg_scan/seg_7 中完成。
// -----------------------------------------------------------------------------
module display_ctrl(
    input  clk,
    input  rst,
    input  [2:0] mode_state,
    input  setting_active,
    input  blink_hide,
    input  [2:0] field_index,
    input  [2:0] comm_status,
    input  selected_alarm_enable,
    input  next_alarm_valid,
    input  countdown_run,
    input  hour_format_12h,
    input  [3:0] sec_unit_time_bcd,
    input  [3:0] sec_ten_time_bcd,
    input  [3:0] min_unit_time_bcd,
    input  [3:0] min_ten_time_bcd,
    input  [3:0] hour_unit_time_bcd,
    input  [3:0] hour_ten_time_bcd,
    input  [3:0] disp_hour_unit_time_bcd,
    input  [3:0] disp_hour_ten_time_bcd,
    input  [3:0] date_month_ten_bcd,
    input  [3:0] date_month_unit_bcd,
    input  [3:0] date_day_ten_bcd,
    input  [3:0] date_day_unit_bcd,
    input  [2:0] date_weekday,
    input  [3:0] alarm_sec_ten_bcd,
    input  [3:0] alarm_sec_unit_bcd,
    input  [3:0] alarm_min_ten_bcd,
    input  [3:0] alarm_min_unit_bcd,
    input  [3:0] alarm_hour_unit_bcd,
    input  [3:0] alarm_hour_ten_bcd,
    input  [3:0] next_alarm_sec_ten_bcd,
    input  [3:0] next_alarm_sec_unit_bcd,
    input  [3:0] next_alarm_min_ten_bcd,
    input  [3:0] next_alarm_min_unit_bcd,
    input  [3:0] next_alarm_hour_unit_bcd,
    input  [3:0] next_alarm_hour_ten_bcd,
    input  [2:0] selected_schedule_type,
    input  schedule_type_page,
    input  [2:0] schedule_selected_slot,
    input  next_schedule_valid,
    input  [2:0] next_schedule_slot,
    input  [3:0] schedule_sec_ten_bcd,
    input  [3:0] schedule_sec_unit_bcd,
    input  [3:0] schedule_min_ten_bcd,
    input  [3:0] schedule_min_unit_bcd,
    input  [3:0] schedule_hour_unit_bcd,
    input  [3:0] schedule_hour_ten_bcd,
    input  [3:0] next_schedule_sec_ten_bcd,
    input  [3:0] next_schedule_sec_unit_bcd,
    input  [3:0] next_schedule_min_ten_bcd,
    input  [3:0] next_schedule_min_unit_bcd,
    input  [3:0] next_schedule_hour_unit_bcd,
    input  [3:0] next_schedule_hour_ten_bcd,
    input  [3:0] countdown_hour_ten_bcd,
    input  [3:0] countdown_hour_unit_bcd,
    input  [3:0] countdown_min_ten_bcd,
    input  [3:0] countdown_min_unit_bcd,
    input  [3:0] countdown_sec_ten_bcd,
    input  [3:0] countdown_sec_unit_bcd,
    output reg [5:0] mode_disp_code,
    output reg [5:0] status_disp_code,
    output reg [5:0] sec_unit_disp_bcd,
    output reg [5:0] sec_ten_disp_bcd,
    output reg [5:0] min_unit_disp_bcd,
    output reg [5:0] min_ten_disp_bcd,
    output reg [5:0] hour_unit_disp_bcd,
    output reg [5:0] hour_ten_disp_bcd
);
    localparam [5:0] DISP_2     = 6'd2;
    localparam [5:0] DISP_1     = 6'd1;
    localparam [5:0] DISP_0     = 6'd0;
    localparam [5:0] DISP_BLANK = 6'd10;
    localparam [5:0] DISP_N     = 6'd16;
    localparam [5:0] DISP_T     = 6'd17;
    localparam [5:0] DISP_A     = 6'd18;
    localparam [5:0] DISP_H     = 6'd19;
    localparam [5:0] DISP_C     = 6'd20;
    localparam [5:0] DISP_S     = 6'd21;
    localparam [5:0] DISP_O     = 6'd22;
    localparam [5:0] DISP_F     = 6'd23;
    localparam [5:0] DISP_R     = 6'd24;
    localparam [5:0] DISP_P     = 6'd25;
    localparam [5:0] DISP_D     = 6'd26;
    localparam [5:0] DISP_B     = 6'd27;
    localparam [5:0] DISP_E     = 6'd28;
    localparam [5:0] DISP_L     = 6'd29;
    localparam [5:0] DISP_U     = 6'd30;
    localparam [5:0] DISP_K     = 6'd31;
    localparam [5:0] DISP_M     = 6'd32;
    localparam [5:0] DISP_I     = 6'd33;
    localparam [5:0] DISP_G     = 6'd34;
    localparam [5:0] DISP_W     = 6'd35;
    localparam [5:0] DISP_EXCL  = 6'd36;

    localparam MODE_NORMAL      = 3'b000;
    localparam MODE_TIME_SET    = 3'b001;
    localparam MODE_ALARM       = 3'b010;
    localparam MODE_HOUR_FORMAT = 3'b011;
    localparam MODE_COUNTDOWN   = 3'b100;
    localparam MODE_SCHEDULE    = 3'b101;
    localparam MODE_COMM        = 3'b110;

    reg [5:0] mode_next;
    reg [5:0] status_next;
    reg [5:0] sec_unit_next;
    reg [5:0] sec_ten_next;
    reg [5:0] min_unit_next;
    reg [5:0] min_ten_next;
    reg [5:0] hour_unit_next;
    reg [5:0] hour_ten_next;

    // 槽位面向用户从 1 开始显示，内部仍保持 0..7。
    function [5:0] slot_digit;
        input [2:0] slot;
        begin
            slot_digit = {3'b000, slot} + 6'd1;
        end
    endfunction

    // 日程类型页使用六位数码管近似显示 CLASS1、BREAK 等固定标签。
    function [5:0] schedule_type_char;
        input [2:0] type_index;
        input [2:0] char_index;
        begin
            schedule_type_char = DISP_BLANK;

            case (type_index)
                3'd0: begin
                    case (char_index)
                        3'd0: schedule_type_char = DISP_C;
                        3'd1: schedule_type_char = DISP_L;
                        3'd2: schedule_type_char = DISP_A;
                        3'd3: schedule_type_char = DISP_S;
                        3'd4: schedule_type_char = DISP_S;
                        default: schedule_type_char = DISP_1;
                    endcase
                end
                3'd1: begin
                    case (char_index)
                        3'd0: schedule_type_char = DISP_C;
                        3'd1: schedule_type_char = DISP_O;
                        3'd2: schedule_type_char = DISP_N;
                        3'd3: schedule_type_char = DISP_F;
                        3'd4: schedule_type_char = DISP_0;
                        default: schedule_type_char = DISP_1;
                    endcase
                end
                3'd2: begin
                    case (char_index)
                        3'd0: schedule_type_char = DISP_L;
                        3'd1: schedule_type_char = DISP_A;
                        3'd2: schedule_type_char = DISP_B;
                        3'd3: schedule_type_char = DISP_0;
                        3'd4: schedule_type_char = DISP_0;
                        default: schedule_type_char = DISP_1;
                    endcase
                end
                3'd3: begin
                    case (char_index)
                        3'd0: schedule_type_char = DISP_T;
                        3'd1: schedule_type_char = DISP_E;
                        3'd2: schedule_type_char = DISP_S;
                        3'd3: schedule_type_char = DISP_T;
                        3'd4: schedule_type_char = DISP_0;
                        default: schedule_type_char = DISP_1;
                    endcase
                end
                3'd4: begin
                    case (char_index)
                        3'd0: schedule_type_char = DISP_D;
                        3'd1: schedule_type_char = DISP_U;
                        3'd2: schedule_type_char = DISP_E;
                        3'd3: schedule_type_char = DISP_0;
                        3'd4: schedule_type_char = DISP_0;
                        default: schedule_type_char = DISP_1;
                    endcase
                end
                3'd5: begin
                    case (char_index)
                        3'd0: schedule_type_char = DISP_B;
                        3'd1: schedule_type_char = DISP_R;
                        3'd2: schedule_type_char = DISP_E;
                        3'd3: schedule_type_char = DISP_A;
                        3'd4: schedule_type_char = DISP_K;
                        default: schedule_type_char = DISP_1;
                    endcase
                end
                3'd6: begin
                    case (char_index)
                        3'd0: schedule_type_char = DISP_E;
                        3'd1: schedule_type_char = DISP_A;
                        3'd2: schedule_type_char = DISP_T;
                        3'd3: schedule_type_char = DISP_0;
                        3'd4: schedule_type_char = DISP_0;
                        default: schedule_type_char = DISP_1;
                    endcase
                end
                default: begin
                    case (char_index)
                        3'd0: schedule_type_char = DISP_S;
                        3'd1: schedule_type_char = DISP_P;
                        3'd2: schedule_type_char = DISP_O;
                        3'd3: schedule_type_char = DISP_R;
                        3'd4: schedule_type_char = DISP_T;
                        default: schedule_type_char = DISP_1;
                    endcase
                end
            endcase
        end
    endfunction

    // COMM 右四位状态：DISC/WAIT/CONN/MSG!/ERR。
    function [5:0] comm_status_char;
        input [2:0] status;
        input [1:0] char_index;
        begin
            comm_status_char = DISP_BLANK;
            case (status)
                3'd1: begin // WAIT
                    case (char_index)
                        2'd0: comm_status_char = DISP_W;
                        2'd1: comm_status_char = DISP_A;
                        2'd2: comm_status_char = DISP_I;
                        default: comm_status_char = DISP_T;
                    endcase
                end
                3'd2: begin // CONN
                    case (char_index)
                        2'd0: comm_status_char = DISP_C;
                        2'd1: comm_status_char = DISP_O;
                        2'd2: comm_status_char = DISP_N;
                        default: comm_status_char = DISP_N;
                    endcase
                end
                3'd3: begin // MSG!
                    case (char_index)
                        2'd0: comm_status_char = DISP_M;
                        2'd1: comm_status_char = DISP_S;
                        2'd2: comm_status_char = DISP_G;
                        default: comm_status_char = DISP_EXCL;
                    endcase
                end
                3'd4: begin // ERR
                    case (char_index)
                        2'd0: comm_status_char = DISP_E;
                        2'd1: comm_status_char = DISP_R;
                        2'd2: comm_status_char = DISP_R;
                        default: comm_status_char = DISP_BLANK;
                    endcase
                end
                default: begin // DISC
                    case (char_index)
                        2'd0: comm_status_char = DISP_D;
                        2'd1: comm_status_char = DISP_I;
                        2'd2: comm_status_char = DISP_S;
                        default: comm_status_char = DISP_C;
                    endcase
                end
            endcase
        end
    endfunction

    // 组合阶段先计算下一拍显示内容；输出寄存阶段再建立时序边界。
    always @(*) begin
        mode_next      = DISP_N;
        status_next    = DISP_BLANK;
        sec_unit_next  = {2'b00, sec_unit_time_bcd};
        sec_ten_next   = {2'b00, sec_ten_time_bcd};
        min_unit_next  = {2'b00, min_unit_time_bcd};
        min_ten_next   = {2'b00, min_ten_time_bcd};
        hour_unit_next = {2'b00, disp_hour_unit_time_bcd};
        hour_ten_next  = {2'b00, disp_hour_ten_time_bcd};

        case (mode_state)
            MODE_NORMAL: begin
                mode_next   = DISP_N;
                status_next = setting_active ? DISP_D : DISP_BLANK;

                if (setting_active) begin
                    hour_ten_next  = {2'b00, date_month_ten_bcd};
                    hour_unit_next = {2'b00, date_month_unit_bcd};
                    min_ten_next   = {2'b00, date_day_ten_bcd};
                    min_unit_next  = {2'b00, date_day_unit_bcd};
                    sec_ten_next   = DISP_0;
                    sec_unit_next  = {3'b000, date_weekday};
                end
            end

            MODE_TIME_SET: begin
                mode_next   = DISP_T;
                status_next = DISP_BLANK;

                if (setting_active) begin
                    hour_unit_next = {2'b00, hour_unit_time_bcd};
                    hour_ten_next  = {2'b00, hour_ten_time_bcd};
                end
            end

            MODE_ALARM: begin
                mode_next      = DISP_A;
                if (setting_active) begin
                    status_next    = (selected_alarm_enable == 1'b1) ? DISP_O : DISP_F;
                    sec_unit_next  = {2'b00, alarm_sec_unit_bcd};
                    sec_ten_next   = {2'b00, alarm_sec_ten_bcd};
                    min_unit_next  = {2'b00, alarm_min_unit_bcd};
                    min_ten_next   = {2'b00, alarm_min_ten_bcd};
                    hour_unit_next = {2'b00, alarm_hour_unit_bcd};
                    hour_ten_next  = {2'b00, alarm_hour_ten_bcd};
                end else if (next_alarm_valid) begin
                    status_next    = DISP_O;
                    sec_unit_next  = {2'b00, next_alarm_sec_unit_bcd};
                    sec_ten_next   = {2'b00, next_alarm_sec_ten_bcd};
                    min_unit_next  = {2'b00, next_alarm_min_unit_bcd};
                    min_ten_next   = {2'b00, next_alarm_min_ten_bcd};
                    hour_unit_next = {2'b00, next_alarm_hour_unit_bcd};
                    hour_ten_next  = {2'b00, next_alarm_hour_ten_bcd};
                end else begin
                    status_next    = DISP_F;
                    sec_unit_next  = DISP_0;
                    sec_ten_next   = DISP_0;
                    min_unit_next  = DISP_0;
                    min_ten_next   = DISP_0;
                    hour_unit_next = DISP_0;
                    hour_ten_next  = DISP_0;
                end
            end

            MODE_HOUR_FORMAT: begin
                mode_next   = DISP_H;
                status_next = hour_format_12h ? DISP_1 : DISP_2;
            end

            MODE_COUNTDOWN: begin
                mode_next      = DISP_C;
                status_next    = (countdown_run == 1'b1) ? DISP_R : DISP_P;
                sec_unit_next  = {2'b00, countdown_sec_unit_bcd};
                sec_ten_next   = {2'b00, countdown_sec_ten_bcd};
                min_unit_next  = {2'b00, countdown_min_unit_bcd};
                min_ten_next   = {2'b00, countdown_min_ten_bcd};
                hour_unit_next = {2'b00, countdown_hour_unit_bcd};
                hour_ten_next  = {2'b00, countdown_hour_ten_bcd};
            end

            MODE_SCHEDULE: begin
                mode_next   = DISP_S;
                status_next = setting_active ? slot_digit(schedule_selected_slot) :
                             next_schedule_valid ? slot_digit(next_schedule_slot) :
                             slot_digit(schedule_selected_slot);

                if (setting_active && schedule_type_page) begin
                    hour_ten_next  = schedule_type_char(selected_schedule_type, 3'd0);
                    hour_unit_next = schedule_type_char(selected_schedule_type, 3'd1);
                    min_ten_next   = schedule_type_char(selected_schedule_type, 3'd2);
                    min_unit_next  = schedule_type_char(selected_schedule_type, 3'd3);
                    sec_ten_next   = schedule_type_char(selected_schedule_type, 3'd4);
                    sec_unit_next  = schedule_type_char(selected_schedule_type, 3'd5);
                end else if (setting_active) begin
                    sec_unit_next  = {2'b00, schedule_sec_unit_bcd};
                    sec_ten_next   = {2'b00, schedule_sec_ten_bcd};
                    min_unit_next  = {2'b00, schedule_min_unit_bcd};
                    min_ten_next   = {2'b00, schedule_min_ten_bcd};
                    hour_unit_next = {2'b00, schedule_hour_unit_bcd};
                    hour_ten_next  = {2'b00, schedule_hour_ten_bcd};
                end else if (next_schedule_valid) begin
                    sec_unit_next  = {2'b00, next_schedule_sec_unit_bcd};
                    sec_ten_next   = {2'b00, next_schedule_sec_ten_bcd};
                    min_unit_next  = {2'b00, next_schedule_min_unit_bcd};
                    min_ten_next   = {2'b00, next_schedule_min_ten_bcd};
                    hour_unit_next = {2'b00, next_schedule_hour_unit_bcd};
                    hour_ten_next  = {2'b00, next_schedule_hour_ten_bcd};
                end else begin
                    sec_unit_next  = DISP_0;
                    sec_ten_next   = DISP_0;
                    min_unit_next  = DISP_0;
                    min_ten_next   = DISP_0;
                    hour_unit_next = DISP_0;
                    hour_ten_next  = DISP_0;
                end
            end

            MODE_COMM: begin
                mode_next      = DISP_C;
                status_next    = DISP_O;
                hour_ten_next  = DISP_M;
                hour_unit_next = DISP_M;
                min_ten_next   = comm_status_char(comm_status, 2'd0);
                min_unit_next  = comm_status_char(comm_status, 2'd1);
                sec_ten_next   = comm_status_char(comm_status, 2'd2);
                sec_unit_next  = comm_status_char(comm_status, 2'd3);
            end

            default: begin
            end
        endcase

        // 设置层字段闪烁：只隐藏当前正在编辑的字段，其他内容保持可读。
        if (setting_active && blink_hide) begin
            case (mode_state)
                MODE_NORMAL: begin
                    if (field_index == 3'd0) begin
                        hour_unit_next = DISP_BLANK;
                        hour_ten_next  = DISP_BLANK;
                    end else if (field_index == 3'd1) begin
                        min_unit_next = DISP_BLANK;
                        min_ten_next  = DISP_BLANK;
                    end else begin
                        sec_unit_next = DISP_BLANK;
                        sec_ten_next  = DISP_BLANK;
                    end
                end

                MODE_TIME_SET: begin
                    if (field_index == 3'd0) begin
                        hour_unit_next = DISP_BLANK;
                        hour_ten_next  = DISP_BLANK;
                    end else if (field_index == 3'd1) begin
                        min_unit_next = DISP_BLANK;
                        min_ten_next  = DISP_BLANK;
                    end else begin
                        sec_unit_next = DISP_BLANK;
                        sec_ten_next  = DISP_BLANK;
                    end
                end

                MODE_ALARM: begin
                    case (field_index)
                        3'd1: begin
                            hour_unit_next = DISP_BLANK;
                            hour_ten_next  = DISP_BLANK;
                        end
                        3'd2: begin
                            min_unit_next = DISP_BLANK;
                            min_ten_next  = DISP_BLANK;
                        end
                        3'd3: begin
                            sec_unit_next = DISP_BLANK;
                            sec_ten_next  = DISP_BLANK;
                        end
                        3'd4: begin
                            status_next = DISP_BLANK;
                        end
                        default: begin
                        end
                    endcase
                end

                MODE_HOUR_FORMAT: begin
                    status_next = DISP_BLANK;
                end

                MODE_COUNTDOWN: begin
                    case (field_index)
                        3'd0: begin
                            hour_unit_next = DISP_BLANK;
                            hour_ten_next  = DISP_BLANK;
                        end
                        3'd1: begin
                            min_unit_next = DISP_BLANK;
                            min_ten_next  = DISP_BLANK;
                        end
                        3'd2: begin
                            sec_ten_next  = DISP_BLANK;
                            sec_unit_next = DISP_BLANK;
                        end
                        default: begin
                        end
                    endcase
                end

                MODE_SCHEDULE: begin
                    if (schedule_type_page) begin
                        hour_unit_next = DISP_BLANK;
                        hour_ten_next  = DISP_BLANK;
                        min_unit_next  = DISP_BLANK;
                        min_ten_next   = DISP_BLANK;
                        sec_unit_next  = DISP_BLANK;
                        sec_ten_next   = DISP_BLANK;
                    end else begin
                        case (field_index)
                        3'd0: begin
                            hour_unit_next = DISP_BLANK;
                            hour_ten_next  = DISP_BLANK;
                        end
                        3'd1: begin
                            min_unit_next = DISP_BLANK;
                            min_ten_next  = DISP_BLANK;
                        end
                        3'd2: begin
                            sec_unit_next = DISP_BLANK;
                            sec_ten_next  = DISP_BLANK;
                        end
                        default: begin
                        end
                        endcase
                    end
                end

                default: begin
                end
            endcase
        end
    end

    // 寄存输出，切断多模式选择到七段扫描模块之间的长组合路径。
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            mode_disp_code      <= DISP_N;
            status_disp_code    <= DISP_BLANK;
            sec_unit_disp_bcd   <= DISP_0;
            sec_ten_disp_bcd    <= DISP_0;
            min_unit_disp_bcd   <= DISP_0;
            min_ten_disp_bcd    <= DISP_0;
            hour_unit_disp_bcd  <= DISP_0;
            hour_ten_disp_bcd   <= DISP_0;
        end else begin
            mode_disp_code      <= mode_next;
            status_disp_code    <= status_next;
            sec_unit_disp_bcd   <= sec_unit_next;
            sec_ten_disp_bcd    <= sec_ten_next;
            min_unit_disp_bcd   <= min_unit_next;
            min_ten_disp_bcd    <= min_ten_next;
            hour_unit_disp_bcd  <= hour_unit_next;
            hour_ten_disp_bcd   <= hour_ten_next;
        end
    end
endmodule
