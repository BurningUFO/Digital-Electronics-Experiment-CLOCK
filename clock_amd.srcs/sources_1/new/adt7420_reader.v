module adt7420_reader(
    input  wire       clk,
    input  wire       rst,
    output reg        temp_valid,
    output reg        temp_negative,
    output reg [7:0]  temp_c_abs,
    output reg        read_error,
    inout  wire       tmp_scl,
    inout  wire       tmp_sda
);
    localparam integer I2C_DIV = 500;
    localparam integer SAMPLE_WAIT = 100_000_000;

    localparam [4:0] ST_WAIT            = 5'd0;
    localparam [4:0] ST_START_A         = 5'd1;
    localparam [4:0] ST_START_B         = 5'd2;
    localparam [4:0] ST_START_C         = 5'd3;
    localparam [4:0] ST_WRITE_SETUP     = 5'd4;
    localparam [4:0] ST_WRITE_HIGH      = 5'd5;
    localparam [4:0] ST_WRITE_LOW       = 5'd6;
    localparam [4:0] ST_WRITE_ACK_HIGH  = 5'd7;
    localparam [4:0] ST_WRITE_ACK_LOW   = 5'd8;
    localparam [4:0] ST_READ_SETUP      = 5'd9;
    localparam [4:0] ST_READ_HIGH       = 5'd10;
    localparam [4:0] ST_READ_LOW        = 5'd11;
    localparam [4:0] ST_READ_ACK_SETUP  = 5'd12;
    localparam [4:0] ST_READ_ACK_HIGH   = 5'd13;
    localparam [4:0] ST_READ_ACK_LOW    = 5'd14;
    localparam [4:0] ST_STOP_A          = 5'd15;
    localparam [4:0] ST_STOP_B          = 5'd16;
    localparam [4:0] ST_STOP_C          = 5'd17;
    localparam [4:0] ST_DONE            = 5'd18;

    localparam [2:0] STEP_ADDR_W = 3'd0;
    localparam [2:0] STEP_REG    = 3'd1;
    localparam [2:0] STEP_ADDR_R = 3'd2;
    localparam [2:0] STEP_MSB    = 3'd3;
    localparam [2:0] STEP_LSB    = 3'd4;

    reg [4:0]  state;
    reg [2:0]  step;
    reg [15:0] div_count;
    reg [26:0] sample_wait_count;
    reg [7:0]  tx_byte;
    reg [7:0]  rx_byte;
    reg [7:0]  temp_msb;
    reg [7:0]  temp_lsb;
    reg [2:0]  bit_index;
    reg        ack_error;
    reg        scl_drive_low;
    reg        sda_drive_low;

    wire tick = (div_count == I2C_DIV - 1);
    wire sda_in = tmp_sda;
    wire [12:0] raw_temp = {temp_msb, temp_lsb[7:3]};
    wire raw_negative = raw_temp[12];
    wire [12:0] raw_abs = raw_negative ? ((~raw_temp) + 13'd1) : raw_temp;
    wire [8:0] temp_integer = raw_abs[12:4];

    assign tmp_scl = scl_drive_low ? 1'b0 : 1'bz;
    assign tmp_sda = sda_drive_low ? 1'b0 : 1'bz;

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_WAIT;
            step <= STEP_ADDR_W;
            div_count <= 16'd0;
            sample_wait_count <= 27'd0;
            tx_byte <= 8'd0;
            rx_byte <= 8'd0;
            temp_msb <= 8'd0;
            temp_lsb <= 8'd0;
            bit_index <= 3'd7;
            ack_error <= 1'b0;
            scl_drive_low <= 1'b0;
            sda_drive_low <= 1'b0;
            temp_valid <= 1'b0;
            temp_negative <= 1'b0;
            temp_c_abs <= 8'd0;
            read_error <= 1'b0;
        end else if (state == ST_WAIT) begin
            div_count <= 16'd0;
            scl_drive_low <= 1'b0;
            sda_drive_low <= 1'b0;

            if (sample_wait_count == SAMPLE_WAIT - 1) begin
                sample_wait_count <= 27'd0;
                step <= STEP_ADDR_W;
                tx_byte <= 8'h96; // ADT7420 7-bit address 0x4B, write.
                bit_index <= 3'd7;
                ack_error <= 1'b0;
                state <= ST_START_A;
            end else begin
                sample_wait_count <= sample_wait_count + 1'b1;
            end
        end else if (tick) begin
            div_count <= 16'd0;

            case (state)
                ST_START_A: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b0;
                    state <= ST_START_B;
                end
                ST_START_B: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b1;
                    state <= ST_START_C;
                end
                ST_START_C: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= 1'b1;
                    state <= ST_WRITE_SETUP;
                end
                ST_WRITE_SETUP: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= ~tx_byte[bit_index];
                    state <= ST_WRITE_HIGH;
                end
                ST_WRITE_HIGH: begin
                    scl_drive_low <= 1'b0;
                    state <= ST_WRITE_LOW;
                end
                ST_WRITE_LOW: begin
                    scl_drive_low <= 1'b1;
                    if (bit_index == 3'd0) begin
                        sda_drive_low <= 1'b0;
                        state <= ST_WRITE_ACK_HIGH;
                    end else begin
                        bit_index <= bit_index - 1'b1;
                        state <= ST_WRITE_SETUP;
                    end
                end
                ST_WRITE_ACK_HIGH: begin
                    scl_drive_low <= 1'b0;
                    if (sda_in) begin
                        ack_error <= 1'b1;
                    end
                    state <= ST_WRITE_ACK_LOW;
                end
                ST_WRITE_ACK_LOW: begin
                    scl_drive_low <= 1'b1;
                    if (ack_error) begin
                        state <= ST_STOP_A;
                    end else if (step == STEP_ADDR_W) begin
                        step <= STEP_REG;
                        tx_byte <= 8'h00; // Temperature MSB register pointer.
                        bit_index <= 3'd7;
                        state <= ST_WRITE_SETUP;
                    end else if (step == STEP_REG) begin
                        step <= STEP_ADDR_R;
                        tx_byte <= 8'h97; // Repeated start, then read.
                        bit_index <= 3'd7;
                        state <= ST_START_A;
                    end else if (step == STEP_ADDR_R) begin
                        step <= STEP_MSB;
                        bit_index <= 3'd7;
                        rx_byte <= 8'd0;
                        state <= ST_READ_SETUP;
                    end else begin
                        state <= ST_STOP_A;
                    end
                end
                ST_READ_SETUP: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= 1'b0;
                    state <= ST_READ_HIGH;
                end
                ST_READ_HIGH: begin
                    scl_drive_low <= 1'b0;
                    rx_byte[bit_index] <= sda_in;
                    state <= ST_READ_LOW;
                end
                ST_READ_LOW: begin
                    scl_drive_low <= 1'b1;
                    if (bit_index == 3'd0) begin
                        state <= ST_READ_ACK_SETUP;
                    end else begin
                        bit_index <= bit_index - 1'b1;
                        state <= ST_READ_SETUP;
                    end
                end
                ST_READ_ACK_SETUP: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= (step == STEP_MSB);
                    state <= ST_READ_ACK_HIGH;
                end
                ST_READ_ACK_HIGH: begin
                    scl_drive_low <= 1'b0;
                    state <= ST_READ_ACK_LOW;
                end
                ST_READ_ACK_LOW: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= 1'b0;
                    if (step == STEP_MSB) begin
                        temp_msb <= rx_byte;
                        step <= STEP_LSB;
                        bit_index <= 3'd7;
                        rx_byte <= 8'd0;
                        state <= ST_READ_SETUP;
                    end else begin
                        temp_lsb <= rx_byte;
                        state <= ST_STOP_A;
                    end
                end
                ST_STOP_A: begin
                    scl_drive_low <= 1'b1;
                    sda_drive_low <= 1'b1;
                    state <= ST_STOP_B;
                end
                ST_STOP_B: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b1;
                    state <= ST_STOP_C;
                end
                ST_STOP_C: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b0;
                    state <= ST_DONE;
                end
                ST_DONE: begin
                    read_error <= ack_error;
                    temp_valid <= ~ack_error;
                    temp_negative <= raw_negative;
                    temp_c_abs <= (temp_integer > 9'd99) ? 8'd99 : temp_integer[7:0];
                    state <= ST_WAIT;
                end
                default: begin
                    state <= ST_WAIT;
                end
            endcase
        end else begin
            div_count <= div_count + 1'b1;
        end
    end
endmodule
