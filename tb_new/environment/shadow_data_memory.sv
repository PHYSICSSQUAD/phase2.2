import shared_pkg::*;

class shadow_data_memory;

    logic [31:0] mem[bit [31:0]];

    // Constructor
    function new();
        mem.delete();
    endfunction

    // Helper function for safe word reads (handles uninitialized memory gracefully)
    local function logic [31:0] read_word(bit [31:0] word_addr);
        if (mem.exists(word_addr)) begin
            return mem[word_addr];
        end else begin
            return 32'h0000_0000;
        end
    endfunction

    // Main execution function called by the predictor
    function logic [31:0] execute_lsu(
        input instr_e      op,
        input logic [31:0] target_address,
        input logic [31:0] rs2_data
    );
        bit   [31:0] word_addr;
        logic [1:0]  offset;
        logic [31:0] old_word, new_word, raw_word, load_data;
        logic [31:0] wdata;
        logic [3:0]  be;

        // Align target address to 32-bit word boundary & extract 2-bit byte offset
        word_addr = target_address & 32'hFFFF_FFFC;
        offset    = target_address[1:0];
        load_data = 32'b0;

        case (op)
            // STORE INSTRUCTIONS
            SB: begin
                wdata    = rs2_data[7:0] << (offset * 8);
                be       = 4'b0001 << offset;
                old_word = read_word(word_addr);
                new_word = apply_be_mask(old_word, wdata, be);
                mem[word_addr] = new_word;
            end

            SH: begin
                wdata    = rs2_data[15:0] << (offset * 8);
                be       = 4'b0011 << offset;
                old_word = read_word(word_addr);
                new_word = apply_be_mask(old_word, wdata, be);
                mem[word_addr] = new_word;
            end

            SW: begin
                wdata    = rs2_data;
                be       = 4'b1111;
                old_word = read_word(word_addr);
                new_word = apply_be_mask(old_word, wdata, be);
                mem[word_addr] = new_word;
            end

            // LOAD INSTRUCTIONS
            LB: begin
                logic [7:0] b_val;
                raw_word  = read_word(word_addr);
                b_val     = raw_word >> (offset * 8);
                load_data = {{24{b_val[7]}}, b_val}; // Sign-extend
            end

            LBU: begin
                logic [7:0] b_val;
                raw_word  = read_word(word_addr);
                b_val     = raw_word >> (offset * 8);
                load_data = {24'b0, b_val};         // Zero-extend
            end

            LH: begin
                logic [15:0] h_val;
                raw_word  = read_word(word_addr);
                h_val     = raw_word >> (offset * 8);
                load_data = {{16{h_val[15]}}, h_val}; // Sign-extend
            end

            LHU: begin
                logic [15:0] h_val;
                raw_word  = read_word(word_addr);
                h_val     = raw_word >> (offset * 8);
                load_data = {16'b0, h_val};          // Zero-extend
            end

            LW: begin
                load_data = read_word(word_addr);
            end

            default: begin
                load_data = 32'b0;
            end
        endcase

        return load_data;
    endfunction

    // Utility method to wipe the shadow memory entirely between tests
    function void flush_memory();
        mem.delete();
    endfunction

endclass