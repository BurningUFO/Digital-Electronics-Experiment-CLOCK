`timescale 1ns / 1ps

// Stores the 16 most recent PC messages. Logical slot 0 is the newest
// message; physical storage uses a ring pointer so storing a new message does
// not move 16 x 100 characters through a wide mux.
module message_store(
    input  wire        clk,
    input  wire        rst,
    input  wire        store_begin,
    input  wire [151:0] store_timestamp_ascii,
    input  wire [6:0]   store_len,
    input  wire        store_char_valid,
    input  wire [6:0]  store_char_index,
    input  wire [7:0]  store_char_ascii,
    input  wire        clear_all,
    input  wire        clear_slot_valid,
    input  wire [3:0]  clear_slot,
    input  wire [3:0]  selected_slot,
    input  wire [6:0]  window_base_index,
    output reg         selected_valid,
    output reg         selected_unread,
    output reg [151:0] selected_timestamp_ascii,
    output reg [6:0]   selected_len,
    output reg [511:0] selected_window_ascii,
    output reg [4:0]   message_count,
    output reg [4:0]   unread_count
);
    reg valid_mem [0:15];
    reg unread_mem [0:15];
    reg [6:0] len_mem [0:15];
    reg [151:0] timestamp_mem [0:15];
    reg [7:0] text_mem [0:1599];

    reg [3:0] head_slot;
    reg [3:0] write_slot;
    reg [3:0] selected_slot_d;
    reg [6:0] window_base_d;
    reg [3:0] selected_phys_reg;
    reg [6:0] selected_len_reg;
    reg       selected_valid_reg;
    reg       window_build_active;
    reg [5:0] window_build_index;
    wire [3:0] next_head_slot;

    integer slot_idx;

    assign next_head_slot = head_slot - 1'b1;

    function [3:0] logical_to_physical;
        input [3:0] logical_slot;
        begin
            logical_to_physical = head_slot + logical_slot;
        end
    endfunction

    function [10:0] text_addr;
        input [3:0] phys_slot;
        input [6:0] char_index;
        begin
            text_addr = ({7'd0, phys_slot} * 11'd100) + {4'd0, char_index};
        end
    endfunction

    task start_window_rebuild;
        begin
            selected_slot_d <= selected_slot;
            window_base_d <= window_base_index;
            selected_phys_reg <= logical_to_physical(selected_slot);
            selected_valid_reg <= (selected_slot < message_count) && valid_mem[logical_to_physical(selected_slot)];
            selected_len_reg <= len_mem[logical_to_physical(selected_slot)];
            window_build_index <= 6'd0;
            window_build_active <= 1'b1;
            selected_window_ascii <= {64{8'h20}};
        end
    endtask

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            head_slot <= 4'd0;
            write_slot <= 4'd0;
            message_count <= 5'd0;
            unread_count <= 5'd0;
            selected_valid <= 1'b0;
            selected_unread <= 1'b0;
            selected_timestamp_ascii <= {19{8'h20}};
            selected_len <= 7'd0;
            selected_window_ascii <= {64{8'h20}};
            selected_slot_d <= 4'd0;
            window_base_d <= 7'd0;
            selected_phys_reg <= 4'd0;
            selected_len_reg <= 7'd0;
            selected_valid_reg <= 1'b0;
            window_build_active <= 1'b0;
            window_build_index <= 6'd0;

            for (slot_idx = 0; slot_idx < 16; slot_idx = slot_idx + 1) begin
                valid_mem[slot_idx] <= 1'b0;
                unread_mem[slot_idx] <= 1'b0;
                len_mem[slot_idx] <= 7'd0;
                timestamp_mem[slot_idx] <= {19{8'h20}};
            end
        end else begin
            if (clear_all) begin
                message_count <= 5'd0;
                unread_count <= 5'd0;
                selected_valid <= 1'b0;
                selected_unread <= 1'b0;
                selected_timestamp_ascii <= {19{8'h20}};
                selected_len <= 7'd0;
                selected_window_ascii <= {64{8'h20}};
                window_build_active <= 1'b0;
                for (slot_idx = 0; slot_idx < 16; slot_idx = slot_idx + 1) begin
                    valid_mem[slot_idx] <= 1'b0;
                    unread_mem[slot_idx] <= 1'b0;
                    len_mem[slot_idx] <= 7'd0;
                end
            end else begin
                if (store_begin) begin
                    head_slot <= next_head_slot;
                    write_slot <= next_head_slot;
                    valid_mem[next_head_slot] <= 1'b1;
                    unread_mem[next_head_slot] <= 1'b1;
                    len_mem[next_head_slot] <= store_len;
                    timestamp_mem[next_head_slot] <= store_timestamp_ascii;

                    if (message_count < 5'd16) begin
                        message_count <= message_count + 1'b1;
                        unread_count <= unread_count + 1'b1;
                    end else if (!unread_mem[next_head_slot]) begin
                        unread_count <= unread_count + 1'b1;
                    end

                    if (selected_slot == 4'd0) begin
                        selected_slot_d <= selected_slot;
                        window_base_d <= window_base_index;
                        selected_valid <= 1'b1;
                        selected_unread <= 1'b1;
                        selected_timestamp_ascii <= store_timestamp_ascii;
                        selected_len <= store_len;
                        selected_valid_reg <= 1'b1;
                        selected_len_reg <= store_len;
                        selected_phys_reg <= next_head_slot;
                        selected_window_ascii <= {64{8'h20}};
                        window_build_active <= 1'b0;
                    end else begin
                        selected_slot_d <= selected_slot + 1'b1;
                        window_base_d <= window_base_index;
                        window_build_active <= 1'b0;
                    end
                end

                if (store_char_valid && (store_char_index < 7'd100)) begin
                    text_mem[text_addr(write_slot, store_char_index)] <= store_char_ascii;
                    if ((selected_slot == 4'd0) &&
                        (store_char_index >= window_base_index) &&
                        (store_char_index < window_base_index + 7'd64)) begin
                        selected_window_ascii[(store_char_index - window_base_index) * 8 +: 8] <= store_char_ascii;
                    end
                end

                if (clear_slot_valid && (clear_slot < message_count) &&
                    valid_mem[logical_to_physical(clear_slot)] &&
                    unread_mem[logical_to_physical(clear_slot)]) begin
                    unread_mem[logical_to_physical(clear_slot)] <= 1'b0;
                    if (unread_count != 5'd0) begin
                        unread_count <= unread_count - 1'b1;
                    end
                end

                if ((selected_slot != selected_slot_d) || (window_base_index != window_base_d)) begin
                    start_window_rebuild;
                end else if (window_build_active) begin
                    if (selected_valid_reg &&
                        (window_base_d + {1'b0, window_build_index} < selected_len_reg)) begin
                        selected_window_ascii[window_build_index * 8 +: 8] <=
                            text_mem[text_addr(selected_phys_reg, window_base_d + {1'b0, window_build_index})];
                    end else begin
                        selected_window_ascii[window_build_index * 8 +: 8] <= 8'h20;
                    end

                    if (window_build_index == 6'd63) begin
                        window_build_active <= 1'b0;
                    end else begin
                        window_build_index <= window_build_index + 1'b1;
                    end
                end

                if (!store_begin && ((selected_slot != selected_slot_d) || (window_base_index != window_base_d))) begin
                    selected_valid <= (selected_slot < message_count) && valid_mem[logical_to_physical(selected_slot)];
                    selected_unread <= (selected_slot < message_count) && unread_mem[logical_to_physical(selected_slot)];
                    selected_timestamp_ascii <= ((selected_slot < message_count) && valid_mem[logical_to_physical(selected_slot)])
                                                ? timestamp_mem[logical_to_physical(selected_slot)] : {19{8'h20}};
                    selected_len <= ((selected_slot < message_count) && valid_mem[logical_to_physical(selected_slot)])
                                    ? len_mem[logical_to_physical(selected_slot)] : 7'd0;
                end else if (clear_slot_valid && (clear_slot == selected_slot)) begin
                    selected_unread <= 1'b0;
                end
            end
        end
    end
endmodule
