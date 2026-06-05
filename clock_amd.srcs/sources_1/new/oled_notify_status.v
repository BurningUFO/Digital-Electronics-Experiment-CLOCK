module oled_notify_status (
    input  wire       notify_active,
    input  wire [1:0] notify_type,
    input  wire [2:0] notify_slot,
    output reg  [95:0] notify_text
);
    localparam [1:0] TYPE_NONE      = 2'd0;
    localparam [1:0] TYPE_COUNTDOWN = 2'd1;
    localparam [1:0] TYPE_ALARM     = 2'd2;
    localparam [1:0] TYPE_SCHEDULE  = 2'd3;

    localparam [95:0] TEXT_BLANK     = {12{8'h20}};
    localparam [95:0] TEXT_COUNTDOWN = {
        8'h43, 8'h4f, 8'h55, 8'h4e, 8'h54, 8'h20,
        8'h44, 8'h4f, 8'h4e, 8'h45, 8'h20, 8'h20
    };

    wire [7:0] slot_ascii;

    assign slot_ascii = 8'h31 + {5'b00000, notify_slot};

    always @(*) begin
        if (!notify_active) begin
            notify_text = TEXT_BLANK;
        end else begin
            case (notify_type)
                TYPE_COUNTDOWN: begin
                    notify_text = TEXT_COUNTDOWN;
                end
                TYPE_ALARM: begin
                    notify_text = {
                        8'h41, 8'h4c, 8'h41, 8'h52, 8'h4d, 8'h20,
                        slot_ascii, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20
                    };
                end
                TYPE_SCHEDULE: begin
                    notify_text = {
                        8'h53, 8'h43, 8'h48, 8'h45, 8'h44, 8'h20,
                        slot_ascii, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20
                    };
                end
                default: begin
                    notify_text = TEXT_BLANK;
                end
            endcase
        end
    end
endmodule
