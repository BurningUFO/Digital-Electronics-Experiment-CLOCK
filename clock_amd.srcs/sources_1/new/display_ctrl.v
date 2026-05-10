module display_ctrl(
    input  [2:0] mode_state,
    input  edit_active,
    input  blink_hide,
    input  [2:0] field_index,
    input  [3:0] sec_unit_time_bcd,
    input  [3:0] sec_ten_time_bcd,
    input  [3:0] min_unit_time_bcd,
    input  [3:0] min_ten_time_bcd,
    input  [3:0] hour_unit_time_bcd,
    input  [3:0] hour_ten_time_bcd,
    input  [3:0] alarm_sec_ten_bcd,
    input  [3:0] alarm_sec_unit_bcd,
    input  [3:0] alarm_min_ten_bcd,
    input  [3:0] alarm_min_unit_bcd,
    input  [3:0] alarm_hour_unit_bcd,
    input  [3:0] alarm_hour_ten_bcd,
    input  [3:0] countdown_hour_ten_bcd,
    input  [3:0] countdown_hour_unit_bcd,
    input  [3:0] countdown_min_ten_bcd,
    input  [3:0] countdown_min_unit_bcd,
    input  [3:0] countdown_sec_ten_bcd,
    input  [3:0] countdown_sec_unit_bcd,
    output [3:0] sec_unit_disp_bcd,
    output [3:0] sec_ten_disp_bcd,
    output [3:0] min_unit_disp_bcd,
    output [3:0] min_ten_disp_bcd,
    output [3:0] hour_unit_disp_bcd,
    output [3:0] hour_ten_disp_bcd
);
    localparam [3:0] DIGIT_BLANK = 4'd10;
    localparam MODE_TIME_SET  = 3'b001;
    localparam MODE_ALARM     = 3'b010;
    localparam MODE_COUNTDOWN = 3'b100;

    reg [3:0] sec_unit_reg;
    reg [3:0] sec_ten_reg;
    reg [3:0] min_unit_reg;
    reg [3:0] min_ten_reg;
    reg [3:0] hour_unit_reg;
    reg [3:0] hour_ten_reg;

    assign sec_unit_disp_bcd  = sec_unit_reg;
    assign sec_ten_disp_bcd   = sec_ten_reg;
    assign min_unit_disp_bcd  = min_unit_reg;
    assign min_ten_disp_bcd   = min_ten_reg;
    assign hour_unit_disp_bcd = hour_unit_reg;
    assign hour_ten_disp_bcd  = hour_ten_reg;

    always @(*) begin
        sec_unit_reg  = sec_unit_time_bcd;
        sec_ten_reg   = sec_ten_time_bcd;
        min_unit_reg  = min_unit_time_bcd;
        min_ten_reg   = min_ten_time_bcd;
        hour_unit_reg = hour_unit_time_bcd;
        hour_ten_reg  = hour_ten_time_bcd;

        case (mode_state)
            MODE_ALARM: begin
                sec_unit_reg  = alarm_sec_unit_bcd;
                sec_ten_reg   = alarm_sec_ten_bcd;
                min_unit_reg  = alarm_min_unit_bcd;
                min_ten_reg   = alarm_min_ten_bcd;
                hour_unit_reg = alarm_hour_unit_bcd;
                hour_ten_reg  = alarm_hour_ten_bcd;
            end

            MODE_COUNTDOWN: begin
                sec_unit_reg  = countdown_sec_unit_bcd;
                sec_ten_reg   = countdown_sec_ten_bcd;
                min_unit_reg  = countdown_min_unit_bcd;
                min_ten_reg   = countdown_min_ten_bcd;
                hour_unit_reg = countdown_hour_unit_bcd;
                hour_ten_reg  = countdown_hour_ten_bcd;
            end

            default: begin
            end
        endcase

        if (edit_active && blink_hide) begin
            case (mode_state)
                MODE_TIME_SET: begin
                    if (field_index == 3'd0) begin
                        hour_unit_reg = DIGIT_BLANK;
                        hour_ten_reg  = DIGIT_BLANK;
                    end else if (field_index == 3'd1) begin
                        min_unit_reg = DIGIT_BLANK;
                        min_ten_reg  = DIGIT_BLANK;
                    end else begin
                        sec_unit_reg = DIGIT_BLANK;
                        sec_ten_reg  = DIGIT_BLANK;
                    end
                end

                MODE_ALARM: begin
                    case (field_index)
                        3'd0: begin
                            hour_unit_reg = DIGIT_BLANK;
                            hour_ten_reg  = DIGIT_BLANK;
                        end
                        3'd1: begin
                            min_unit_reg = DIGIT_BLANK;
                            min_ten_reg  = DIGIT_BLANK;
                        end
                        3'd2: begin
                            sec_unit_reg = DIGIT_BLANK;
                            sec_ten_reg  = DIGIT_BLANK;
                        end
                        default: begin
                        end
                    endcase
                end

                MODE_COUNTDOWN: begin
                    case (field_index)
                        3'd0: begin
                            hour_unit_reg = DIGIT_BLANK;
                            hour_ten_reg  = DIGIT_BLANK;
                        end
                        3'd1: begin
                            min_unit_reg = DIGIT_BLANK;
                            min_ten_reg  = DIGIT_BLANK;
                        end
                        3'd2: begin
                            sec_ten_reg  = DIGIT_BLANK;
                            sec_unit_reg = DIGIT_BLANK;
                        end
                        default: begin
                        end
                    endcase
                end

                default: begin
                end
            endcase
        end
    end
endmodule
