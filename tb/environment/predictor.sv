`uvm_analysis_imp_decl(_instr)
`uvm_analysis_imp_decl(_rst)
`uvm_analysis_imp_decl(_mul) // 🔥 NEW (MUL/DIV integration): imp for the MUL monitor

class predictor extends uvm_component;
    `uvm_component_utils(predictor)

    // Analysis imps
    uvm_analysis_imp_instr#(instruction_seq_item, predictor) instr_imp;
    uvm_analysis_imp_rst  #(reset_item,           predictor) rst_imp;
    uvm_analysis_imp_mul  #(mul_seq_item,         predictor) mul_imp; // 🔥 NEW (MUL/DIV integration): ACTUAL RV32M ops in

    // Analysis port to scoreboard
    uvm_analysis_port#(data_seq_item) data_ap;
    uvm_analysis_port#(mul_seq_item)  mul_ap; // 🔥 NEW (MUL/DIV integration): EXPECTED RV32M ops out to mul_scoreboard

    shadow_data_memory shadow_data_mem;

    // Model State
    bit [31:0] target_address;
    bit [31:0] predicted_load_data;
    bit in_reset;
    
    // Shadow Register File to track 32-bit register contents
    bit [31:0] shadow_reg_file [32];

    function new(string name = "predictor", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function automatic void build_phase(uvm_phase phase);
        super.build_phase(phase);
        instr_imp = new("instr_imp", this);
        data_ap   = new("data_ap", this);
        rst_imp   = new("rst_imp", this);
        mul_imp   = new("mul_imp", this); // 🔥 NEW (MUL/DIV integration)
        mul_ap    = new("mul_ap", this);  // 🔥 NEW (MUL/DIV integration)

        shadow_data_mem = new();
    endfunction

    // Instruction handler
    virtual function automatic void write_instr(instruction_seq_item item);
        instr_t data;
        instr_e op;
        data_seq_item data_txn;

        bit [31:0] sign_extended_imm;
        bit [31:0] rs1_value;
        bit [31:0] rs2_value;

        if (in_reset) return;

        data.raw = item.data;
        op = decode_instr(data.raw);

        if (classify_group(op) inside {LOAD, STORE}) begin
            data_txn = data_seq_item::type_id::create("data_txn");

            // 1. Decode Immediate and Read Register Contents
            if (classify_group(op) == LOAD) begin
                sign_extended_imm = {{20{data.i_type.imm_11_0[11]}}, data.i_type.imm_11_0};
                rs1_value         = shadow_reg_file[data.i_type.rs1];
                rs2_value         = 32'b0;
            end else begin
                sign_extended_imm = {{20{data.s_type.imm_11_5[6]}}, data.s_type.imm_11_5, data.s_type.imm_4_0};
                rs1_value         = shadow_reg_file[data.s_type.rs1];
                rs2_value         = shadow_reg_file[data.s_type.rs2];
            end

            // 2. Compute Target Address and Memory Bus Attributes
            target_address = rs1_value + sign_extended_imm;

            data_txn.addr  = target_address;
            data_txn.we    = (op inside {SB, SH, SW});
            data_txn.be    = get_byte_enable(op, target_address[1:0]);
            data_txn.wdata = rs2_value;

            // 3. Execute LSU in Shadow Memory
            predicted_load_data = shadow_data_mem.execute_lsu(op, target_address, rs2_value);

            // 4. Update Register File on Loads (for dependent instructions)
            if (op inside {LB, LH, LW, LBU, LHU}) begin
                data_txn.rdata = predicted_load_data;
                if (data.i_type.rd != 5'b0) begin
                    shadow_reg_file[data.i_type.rd] = predicted_load_data;
                end
            end

            // 5. Broadcast predicted transaction (for both Loads & Stores)
            data_ap.write(data_txn);
            `uvm_info("PRED", $sformatf("Predicted LSU Txn: %s", data_txn.convert2string()), UVM_NONE)
        end
    endfunction

    // Reset handler
    virtual function void write_rst(reset_item rst_item);
        if (rst_item.reset_state == 1'b0) begin
            in_reset = 1'b1;
            shadow_data_mem.flush_memory();
            foreach (shadow_reg_file[i]) shadow_reg_file[i] = '0;
            shadow_reg_file[1] = 32'hA5A5_A5A5; // seed non-zero data source for store/load validation
            target_address = '0;
            predicted_load_data = '0;
            `uvm_info("PRED_RST", "Predictor state cleared due to async reset", UVM_NONE)
        end else begin
            in_reset = 1'b0;
        end
    endfunction

    // 🔥 NEW (MUL/DIV integration) ------------------------------------------
    // 🔥 RV32M handler: builds the EXPECTED item for one ACTUAL item.
    // 🔥 Not gated by in_reset on purpose: mul_monitor already drops ops during
    // 🔥 reset, and every ACTUAL item must get exactly one EXPECTED item, or the
    // 🔥 two mul_scoreboard FIFOs would get out of step.
    virtual function void write_mul(mul_seq_item item);
        mul_seq_item exp_item;
        $cast(exp_item, item.clone());
        exp_item.set_name("mul_exp_item");
        exp_item.result   = predict_mul(item.op, item.rs1_val, item.rs2_val);
        exp_item.wb_we    = 1'b1;
        exp_item.wb_waddr = {1'b0, item.rd};
        mul_ap.write(exp_item);
        `uvm_info("PRED_MUL", $sformatf("Predicted RV32M: %s", exp_item.convert2string()), UVM_HIGH)
    endfunction

    // 🔥 dispatcher: expected rd value for one of the 8 RV32M ops
    virtual function logic [31:0] predict_mul(instr_e op, logic [31:0] rs1_val, logic [31:0] rs2_val);
        case (op)
            MUL   : return exp_mul   (rs1_val, rs2_val);
            MULH  : return exp_mulh  (rs1_val, rs2_val);
            MULHSU: return exp_mulhsu(rs1_val, rs2_val);
            MULHU : return exp_mulhu (rs1_val, rs2_val);
            DIV   : return exp_div   (rs1_val, rs2_val);
            DIVU  : return exp_divu  (rs1_val, rs2_val);
            REM   : return exp_rem   (rs1_val, rs2_val);
            REMU  : return exp_remu  (rs1_val, rs2_val);
            default: begin
                `uvm_error("PRED_MUL", $sformatf("predict_mul() called with non-RV32M op %s", op.name()))
                return 'x;
            end
        endcase
    endfunction

    // 🔥 MUL: low 32 bits of rs1 * rs2
    function logic [31:0] exp_mul(logic [31:0] a, logic [31:0] b);
        logic [63:0] p;
        p = longint'($signed(a)) * longint'($signed(b));
        return p[31:0];
    endfunction

    // 🔥 MULH: high 32 bits of signed * signed
    function logic [31:0] exp_mulh(logic [31:0] a, logic [31:0] b);
        logic [63:0] p;
        p = longint'($signed(a)) * longint'($signed(b));
        return p[63:32];
    endfunction

    // 🔥 MULHSU: high 32 bits of signed rs1 * unsigned rs2
    function logic [31:0] exp_mulhsu(logic [31:0] a, logic [31:0] b);
        logic [63:0] p;
        p = longint'($signed(a)) * longint'({32'b0, b});
        return p[63:32];
    endfunction

    // 🔥 MULHU: high 32 bits of unsigned * unsigned
    function logic [31:0] exp_mulhu(logic [31:0] a, logic [31:0] b);
        logic [63:0] p;
        p = {32'b0, a} * {32'b0, b};
        return p[63:32];
    endfunction

    // 🔥 DIV: signed; /0 -> -1, overflow (-2^31 / -1) -> -2^31
    function logic [31:0] exp_div(logic [31:0] a, logic [31:0] b);
        if (b == 32'b0)                              return 32'hFFFF_FFFF;
        if (a == 32'h8000_0000 && b == 32'hFFFF_FFFF) return 32'h8000_0000;
        return $signed(a) / $signed(b);
    endfunction

    // 🔥 DIVU: unsigned; /0 -> 2^32-1
    function logic [31:0] exp_divu(logic [31:0] a, logic [31:0] b);
        if (b == 32'b0) return 32'hFFFF_FFFF;
        return a / b;
    endfunction

    // 🔥 REM: signed; %0 -> rs1, overflow -> 0
    function logic [31:0] exp_rem(logic [31:0] a, logic [31:0] b);
        if (b == 32'b0)                              return a;
        if (a == 32'h8000_0000 && b == 32'hFFFF_FFFF) return 32'b0;
        return $signed(a) % $signed(b);
    endfunction

    // 🔥 REMU: unsigned; %0 -> rs1
    function logic [31:0] exp_remu(logic [31:0] a, logic [31:0] b);
        if (b == 32'b0) return a;
        return a % b;
    endfunction
    // 🔥 END NEW (MUL/DIV integration) --------------------------------------

endclass : predictor