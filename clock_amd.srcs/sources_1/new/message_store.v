`timescale 1ns / 1ps

// Stores the 16 most recent PC messages. Logical slot 0 is the newest
// message; physical storage uses a ring pointer so storing a new message does
// not move 16 x 100 characters through a wide mux.
//
// 中文说明：
// 逻辑 slot 与物理 RAM 槽位通过 head_slot 做映射。每来一条新消息，只移动
// head 指针并写入新的物理槽，旧消息不整体搬移。
//
// OLED 只需要显示当前 slot 的 4 行 x 16 字符窗口，因此正文 RAM 采用
// “同步读 + 逐字节重建窗口”的方式输出 64 字节窗口，避免 1600 字节正文
// 通过组合大选择器直接进入 OLED 渲染路径。
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
    output wire [511:0] selected_window_ascii,
    output reg [4:0]   message_count,
    output reg [4:0]   unread_count
);
    reg valid_mem [0:15];
    reg unread_mem [0:15];
    reg [6:0] len_mem [0:15];
    reg [151:0] timestamp_mem [0:15];
    (* ram_style = "block" *) reg [7:0] text_mem [0:1599];
    reg [7:0] selected_window_mem [0:63];

    reg [3:0] head_slot;
    reg [3:0] write_slot;
    reg [3:0] selected_slot_d;
    reg [6:0] window_base_d;
    reg [3:0] selected_phys_reg;
    reg [6:0] selected_len_reg;
    reg       selected_valid_reg;
    reg       window_build_active;
    reg [5:0] window_build_index;
    reg [1:0] window_build_phase;
    reg [10:0] window_read_addr;
    reg [7:0] window_read_data;
    reg       window_read_in_range;
    wire [3:0] next_head_slot;
    wire [7:0] window_build_abs_index;
    wire [7:0] store_char_index_ext;
    wire [7:0] store_window_base_ext;
    wire [7:0] store_window_end_ext;
    wire       store_char_in_window;
    wire [6:0] store_window_offset;
    wire       text_store_valid;
    wire [10:0] text_store_addr;

    integer slot_idx;
    integer window_idx;
    genvar window_out_idx;

    assign next_head_slot = head_slot - 1'b1;
    assign window_build_abs_index = {1'b0, window_base_d} + {2'b00, window_build_index};
    assign store_char_index_ext = {1'b0, store_char_index};
    assign store_window_base_ext = {1'b0, window_base_index};
    assign store_window_end_ext = store_window_base_ext + 8'd64;
    assign store_char_in_window = (store_char_index_ext >= store_window_base_ext) &&
                                  (store_char_index_ext < store_window_end_ext);
    assign store_window_offset = store_char_index - window_base_index;
    assign text_store_valid = store_char_valid && (store_char_index < 7'd100);
    assign text_store_addr = text_addr(write_slot, store_char_index);

    generate
        for (window_out_idx = 0; window_out_idx < 64; window_out_idx = window_out_idx + 1) begin : g_window_out
            assign selected_window_ascii[window_out_idx * 8 +: 8] = selected_window_mem[window_out_idx];
        end
    endgenerate

    // 把用户看到的逻辑 slot0..15 映射到环形物理槽。
    function [3:0] logical_to_physical;
        input [3:0] logical_slot;
        begin
            logical_to_physical = head_slot + logical_slot;
        end
    endfunction

    // 每条消息最多 100 字符，16 条共 1600 字节。
    function [10:0] text_addr;
        input [3:0] phys_slot;
        input [6:0] char_index;
        begin
            text_addr = ({7'd0, phys_slot} * 11'd100) + {4'd0, char_index};
        end
    endfunction

    // 当选择的消息槽或滚动基地址变化时，启动 64 字节窗口重建。
    task start_window_rebuild;
        begin
            selected_slot_d <= selected_slot;
            window_base_d <= window_base_index;
            selected_phys_reg <= logical_to_physical(selected_slot);
            selected_valid_reg <= (selected_slot < message_count) && valid_mem[logical_to_physical(selected_slot)];
            selected_len_reg <= len_mem[logical_to_physical(selected_slot)];
            window_build_index <= 6'd0;
            window_build_phase <= 2'd0;
            window_read_addr <= 11'd0;
            window_read_in_range <= 1'b0;
            window_build_active <= 1'b1;
            for (window_idx = 0; window_idx < 64; window_idx = window_idx + 1) begin
                selected_window_mem[window_idx] <= 8'h20;
            end
        end
    endtask

    // 正文 RAM 写入和窗口同步读独立出来，便于 Vivado 推断 Block RAM。
    always @(posedge clk) begin
        if (text_store_valid) begin
            text_mem[text_store_addr] <= store_char_ascii;
        end

        if (window_build_active && (window_build_phase == 2'd1)) begin
            window_read_data <= text_mem[window_read_addr];
        end
    end

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
            selected_slot_d <= 4'd0;
            window_base_d <= 7'd0;
            selected_phys_reg <= 4'd0;
            selected_len_reg <= 7'd0;
            selected_valid_reg <= 1'b0;
            window_build_active <= 1'b0;
            window_build_index <= 6'd0;
            window_build_phase <= 2'd0;
            window_read_addr <= 11'd0;
            window_read_in_range <= 1'b0;

            for (slot_idx = 0; slot_idx < 16; slot_idx = slot_idx + 1) begin
                valid_mem[slot_idx] <= 1'b0;
                unread_mem[slot_idx] <= 1'b0;
                len_mem[slot_idx] <= 7'd0;
                timestamp_mem[slot_idx] <= {19{8'h20}};
            end
            for (window_idx = 0; window_idx < 64; window_idx = window_idx + 1) begin
                selected_window_mem[window_idx] <= 8'h20;
            end
        end else begin
            if (clear_all) begin
                message_count <= 5'd0;
                unread_count <= 5'd0;
                selected_valid <= 1'b0;
                selected_unread <= 1'b0;
                selected_timestamp_ascii <= {19{8'h20}};
                selected_len <= 7'd0;
                window_build_active <= 1'b0;
                window_build_phase <= 2'd0;
                window_read_addr <= 11'd0;
                window_read_in_range <= 1'b0;
                for (slot_idx = 0; slot_idx < 16; slot_idx = slot_idx + 1) begin
                    valid_mem[slot_idx] <= 1'b0;
                    unread_mem[slot_idx] <= 1'b0;
                    len_mem[slot_idx] <= 7'd0;
                end
                for (window_idx = 0; window_idx < 64; window_idx = window_idx + 1) begin
                    selected_window_mem[window_idx] <= 8'h20;
                end
            end else begin
                if (store_begin) begin
                    // 新消息写入逻辑 slot0：物理 head 前移，旧逻辑 slot 自动后移。
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
                        window_build_active <= 1'b0;
                        window_build_phase <= 2'd0;
                        window_read_in_range <= 1'b0;
                        for (window_idx = 0; window_idx < 64; window_idx = window_idx + 1) begin
                            selected_window_mem[window_idx] <= 8'h20;
                        end
                    end else begin
                        selected_slot_d <= selected_slot + 1'b1;
                        window_base_d <= window_base_index;
                        window_build_active <= 1'b0;
                        window_build_phase <= 2'd0;
                        window_read_in_range <= 1'b0;
                    end
                end

                if (text_store_valid) begin
                    if ((selected_slot == 4'd0) && store_char_in_window) begin
                        selected_window_mem[store_window_offset[5:0]] <= store_char_ascii;
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
                    // 三阶段窗口重建：发起地址 -> 等待同步读 -> 写入窗口字节。
                    case (window_build_phase)
                        2'd0: begin
                            if (selected_valid_reg &&
                                (window_build_abs_index < {1'b0, selected_len_reg}) &&
                                (window_build_abs_index < 8'd100)) begin
                                window_read_addr <= text_addr(selected_phys_reg, window_build_abs_index[6:0]);
                                window_read_in_range <= 1'b1;
                            end else begin
                                window_read_addr <= 11'd0;
                                window_read_in_range <= 1'b0;
                            end
                            window_build_phase <= 2'd1;
                        end

                        2'd1: begin
                            window_build_phase <= 2'd2;
                        end

                        default: begin
                            selected_window_mem[window_build_index] <= window_read_in_range ? window_read_data : 8'h20;
                            window_build_phase <= 2'd0;
                            if (window_build_index == 6'd63) begin
                                window_build_active <= 1'b0;
                            end else begin
                                window_build_index <= window_build_index + 1'b1;
                            end
                        end
                    endcase
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
