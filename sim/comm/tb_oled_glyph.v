module tb_oled_glyph;
    integer code;
    integer row;
    reg found_pixel;
    wire init_done;
    wire error;
    wire oled_scl;
    wire oled_sda;

    oled_ui_display dut (
        .clk(1'b0),
        .rst(1'b0),
        .mode_state(3'b110),
        .edit_active(1'b0),
        .countdown_run(1'b0),
        .hour_format_12h(1'b0),
        .temp_valid(1'b0),
        .temp_negative(1'b0),
        .temp_c_abs(8'd0),
        .notify_active(1'b0),
        .notify_type(2'd0),
        .notify_slot(3'd0),
        .date_month_ten_bcd(4'd0),
        .date_month_unit_bcd(4'd6),
        .date_day_ten_bcd(4'd0),
        .date_day_unit_bcd(4'd5),
        .date_weekday(3'd5),
        .next_alarm_valid(1'b0),
        .next_alarm_hour_ten_bcd(4'd0),
        .next_alarm_hour_unit_bcd(4'd0),
        .next_alarm_min_ten_bcd(4'd0),
        .next_alarm_min_unit_bcd(4'd0),
        .next_schedule_valid(1'b0),
        .next_schedule_slot(3'd0),
        .next_schedule_hour_ten_bcd(4'd0),
        .next_schedule_hour_unit_bcd(4'd0),
        .next_schedule_min_ten_bcd(4'd0),
        .next_schedule_min_unit_bcd(4'd0),
        .countdown_hour_ten_bcd(4'd0),
        .countdown_hour_unit_bcd(4'd0),
        .countdown_min_ten_bcd(4'd0),
        .countdown_min_unit_bcd(4'd0),
        .countdown_sec_ten_bcd(4'd0),
        .countdown_sec_unit_bcd(4'd0),
        .comm_status(3'd3),
        .comm_reply_mode(1'b0),
        .comm_reply_index(3'd0),
        .comm_selected_slot(4'd0),
        .comm_message_valid(1'b1),
        .comm_scroll_line(3'd0),
        .comm_timestamp_ascii({"2","0","2","6","-","0","6","-","0","5","T","1","1",":","5","2",":","2","0"}),
        .comm_message_len(7'd10),
        .comm_message_window_ascii({{54{8'h20}}, "a", "g", "p", "f", " ", "o", "l", "l", "e", "h"}),
        .init_done(init_done),
        .error(error),
        .oled_scl(oled_scl),
        .oled_sda(oled_sda)
    );

    initial begin
        #1;
        for (row = 0; row < 8; row = row + 1) begin
            if (dut.glyph_row(8'h20, row[2:0]) !== 8'b00000000) begin
                $display("FAIL tb_oled_glyph: space row %0d is not blank", row);
                $finish;
            end
        end

        for (code = 8'h21; code <= 8'h7E; code = code + 1) begin
            found_pixel = 1'b0;
            for (row = 0; row < 7; row = row + 1) begin
                if (dut.glyph_row(code[7:0], row[2:0]) !== 8'b00000000) begin
                    found_pixel = 1'b1;
                end
            end
            if (!found_pixel) begin
                $display("FAIL tb_oled_glyph: printable ASCII 0x%02h is blank", code[7:0]);
                $finish;
            end
        end

        if (dut.glyph_row("a", 3'd0) === dut.glyph_row("A", 3'd0)) begin
            $display("FAIL tb_oled_glyph: lowercase a is not distinct from uppercase A");
            $finish;
        end
        if (dut.glyph_row("?", 3'd0) === 8'b00000000) begin
            $display("FAIL tb_oled_glyph: question mark is blank");
            $finish;
        end
        if (dut.glyph_row("@", 3'd2) === 8'b00000000) begin
            $display("FAIL tb_oled_glyph: at sign is blank");
            $finish;
        end
        if (dut.glyph_row("_", 3'd6) === 8'b00000000) begin
            $display("FAIL tb_oled_glyph: underscore is blank");
            $finish;
        end
        if (dut.glyph_row("~", 3'd2) === 8'b00000000) begin
            $display("FAIL tb_oled_glyph: tilde is blank");
            $finish;
        end

        $display("PASS tb_oled_glyph");
        $finish;
    end
endmodule
