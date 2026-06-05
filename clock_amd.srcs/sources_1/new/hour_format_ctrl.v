module hour_format_ctrl(
    input  clk,
    input  rst,
    input  toggle_pulse,
    input  inc_format_pulse,
    input  dec_format_pulse,
    output hour_format_12h
);
    reg format_12h_reg;

    assign hour_format_12h = format_12h_reg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            format_12h_reg <= 1'b0;
        end else if (toggle_pulse || inc_format_pulse || dec_format_pulse) begin
            format_12h_reg <= ~format_12h_reg;
        end
    end
endmodule
