module i2c_master_simple #(
    parameter integer CLK_DIV = 500
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       cmd_valid,
    input  wire [1:0] cmd_type,
    input  wire [7:0] cmd_data,
    output reg        busy,
    output reg        done,
    output reg        ack_ok,
    inout  wire       scl,
    inout  wire       sda
);
    localparam [1:0] CMD_START = 2'd0;
    localparam [1:0] CMD_WRITE = 2'd1;
    localparam [1:0] CMD_STOP  = 2'd2;

    localparam [3:0] ST_IDLE       = 4'd0;
    localparam [3:0] ST_START_A    = 4'd1;
    localparam [3:0] ST_START_B    = 4'd2;
    localparam [3:0] ST_START_C    = 4'd3;
    localparam [3:0] ST_WRITE_SET  = 4'd4;
    localparam [3:0] ST_WRITE_HIGH = 4'd5;
    localparam [3:0] ST_WRITE_LOW  = 4'd6;
    localparam [3:0] ST_ACK_SET    = 4'd7;
    localparam [3:0] ST_ACK_HIGH   = 4'd8;
    localparam [3:0] ST_ACK_LOW    = 4'd9;
    localparam [3:0] ST_STOP_A     = 4'd10;
    localparam [3:0] ST_STOP_B     = 4'd11;
    localparam [3:0] ST_STOP_C     = 4'd12;
    localparam [3:0] ST_DONE       = 4'd13;

    reg [3:0]  state = ST_IDLE;
    reg [15:0] div_count = 16'd0;
    reg [1:0]  active_cmd = CMD_START;
    reg [7:0]  shift_reg = 8'd0;
    reg [2:0]  bit_index = 3'd0;
    reg        scl_drive_low = 1'b0;
    reg        sda_drive_low = 1'b0;

    wire tick = (div_count == CLK_DIV - 1);
    wire sda_in = sda;

    assign scl = scl_drive_low ? 1'b0 : 1'bz;
    assign sda = sda_drive_low ? 1'b0 : 1'bz;

    always @(posedge clk) begin
        if (rst) begin
            state         <= ST_IDLE;
            div_count     <= 16'd0;
            active_cmd    <= CMD_START;
            shift_reg     <= 8'd0;
            bit_index     <= 3'd0;
            busy          <= 1'b0;
            done          <= 1'b0;
            ack_ok        <= 1'b1;
            scl_drive_low <= 1'b0;
            sda_drive_low <= 1'b0;
        end else begin
            done <= 1'b0;

            if (state == ST_IDLE) begin
                div_count <= 16'd0;
                if (cmd_valid) begin
                    active_cmd <= cmd_type;
                    shift_reg  <= cmd_data;
                    bit_index  <= 3'd7;
                    busy       <= 1'b1;
                    ack_ok     <= 1'b1;

                    case (cmd_type)
                        CMD_START: state <= ST_START_A;
                        CMD_WRITE: state <= ST_WRITE_SET;
                        CMD_STOP:  state <= ST_STOP_A;
                        default:   state <= ST_DONE;
                    endcase
                end
            end else begin
                if (tick) begin
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
                            state <= ST_DONE;
                        end

                        ST_WRITE_SET: begin
                            scl_drive_low <= 1'b1;
                            sda_drive_low <= ~shift_reg[bit_index];
                            state <= ST_WRITE_HIGH;
                        end

                        ST_WRITE_HIGH: begin
                            scl_drive_low <= 1'b0;
                            state <= ST_WRITE_LOW;
                        end

                        ST_WRITE_LOW: begin
                            scl_drive_low <= 1'b1;
                            if (bit_index == 3'd0) begin
                                state <= ST_ACK_SET;
                            end else begin
                                bit_index <= bit_index - 1'b1;
                                state <= ST_WRITE_SET;
                            end
                        end

                        ST_ACK_SET: begin
                            scl_drive_low <= 1'b1;
                            sda_drive_low <= 1'b0;
                            state <= ST_ACK_HIGH;
                        end

                        ST_ACK_HIGH: begin
                            scl_drive_low <= 1'b0;
                            ack_ok <= ~sda_in;
                            state <= ST_ACK_LOW;
                        end

                        ST_ACK_LOW: begin
                            scl_drive_low <= 1'b1;
                            state <= ST_DONE;
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
                            busy  <= 1'b0;
                            done  <= 1'b1;
                            state <= ST_IDLE;
                        end

                        default: state <= ST_IDLE;
                    endcase
                end else begin
                    div_count <= div_count + 1'b1;
                end
            end
        end
    end
endmodule
