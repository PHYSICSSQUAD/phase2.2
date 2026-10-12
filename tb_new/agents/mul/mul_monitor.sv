// 🔥 NEW (MUL/DIV integration) - passive monitor of the ALU_MUL interface.
// 🔥 Extends monitor_base like instruction_monitor: monitor_base waits for reset
// 🔥 de-assert, calls collect_txn() forever, and kills it on reset.
// 🔥 Sampling logic taken from mul_env/mul_monitor.sv:
// 🔥  - remember the instruction that leaves ID (id_valid),
// 🔥  - when EX completes (ex_valid) and it is a MUL (mult_en) or a DIV/REM
// 🔥    (alu_en + DIV/REM encoding), publish one item with operands + result.
class mul_monitor extends monitor_base#(mul_seq_item);
    `uvm_component_utils(mul_monitor)

    // 🔥 vif
    virtual alu_mul_if.MON vif;

    // 🔥 instruction currently in EX
    protected logic [31:0] ex_instr;
    protected bit          ex_instr_valid;

    int unsigned num_items;

    function new(string name = "mul_monitor", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    // 🔥 one clock of sampling
    protected virtual task collect_txn();
        @(vif.mon_cb);

        if (vif.mon_cb.rst_n !== 1'b1) begin
            ex_instr_valid = 0;
            return;
        end

        if (vif.mon_cb.ex_valid === 1'b1) begin
            if (vif.mon_cb.ex_mult_en === 1'b1 ||
                (vif.mon_cb.ex_alu_en === 1'b1 && ex_instr_valid && is_div_or_rem(ex_instr))) begin
                if (!ex_instr_valid)
                    `uvm_error(get_type_name(), "RV32M operation completed but no instruction was seen entering EX")
                else
                    publish_item();
            end
            ex_instr_valid = 0;
        end

        if (vif.mon_cb.id_valid === 1'b1) begin
            ex_instr       = vif.mon_cb.id_instr;
            ex_instr_valid = 1;
        end
    endtask : collect_txn

    // 🔥 on reset also forget the instruction that was in EX
    virtual function void handle_reset(uvm_phase phase);
        super.handle_reset(phase);
        ex_instr_valid = 0;
    endfunction : handle_reset

    // 🔥 build and broadcast the ACTUAL item
    protected virtual function void publish_item();
        mul_seq_item item;
        instr_e      op;

        if (!decode_m_op(ex_instr, op)) begin
            `uvm_error(get_type_name(),
                $sformatf("Execution unit used by a non-supported RV32M instruction 0x%08h - not checked", ex_instr))
            return;
        end

        item          = mul_seq_item::type_id::create("item");
        item.instr    = ex_instr;
        item.op       = op;
        item.rd       = item.instr.r_type.rd;
        if (is_div_op(op)) begin
            // 🔥 the decoder swaps DIV/REM operands: a = rs2, b = rs1
            item.rs1_val = vif.mon_cb.ex_alu_operand_b;
            item.rs2_val = vif.mon_cb.ex_alu_operand_a;
        end
        else begin
            item.rs1_val = vif.mon_cb.ex_mult_operand_a;
            item.rs2_val = vif.mon_cb.ex_mult_operand_b;
        end
        item.result   = vif.mon_cb.ex_wb_wdata;
        item.wb_we    = vif.mon_cb.ex_wb_we;
        item.wb_waddr = vif.mon_cb.ex_wb_waddr;

        num_items++;
        `uvm_info("MUL_MON", {"Observed: ", item.convert2string()}, UVM_HIGH)
        ap.write(item);
    endfunction : publish_item

    // 🔥 decode one of the 8 RV32M encodings (shared_pkg helpers)
    protected virtual function bit decode_m_op(logic [31:0] raw, output instr_e op);
        instr_t i;
        instr_e cand[8] = '{MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU};
        i = raw;
        foreach (cand[k]) begin
            if (i.r_type.opcode === get_opcode(cand[k]) &&
                i.r_type.funct3 === get_funct3(cand[k]) &&
                i.r_type.funct7 === get_funct7(cand[k])) begin
                op = cand[k];
                return 1;
            end
        end
        op = MUL;
        return 0;
    endfunction : decode_m_op

    protected virtual function bit is_div_op(instr_e op);
        return op inside {DIV, DIVU, REM, REMU};
    endfunction : is_div_op

    protected virtual function bit is_div_or_rem(logic [31:0] raw);
        instr_e op;
        return decode_m_op(raw, op) && is_div_op(op);
    endfunction : is_div_or_rem

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("MUL_MON", $sformatf("RV32M monitor published %0d multiply/divide transactions", num_items), UVM_LOW)
    endfunction : report_phase

endclass : mul_monitor
