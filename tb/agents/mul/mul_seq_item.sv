// 🔥 NEW (MUL/DIV integration) - one completed RV32M operation
// 🔥 (MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU) as seen in the EX stage.
// 🔥 Analysis-only transaction: built by mul_monitor (ACTUAL) and cloned by the
// 🔥 predictor (EXPECTED). Nothing randomizes it, so no field is "rand".
class mul_seq_item extends uvm_sequence_item;
    `uvm_object_utils(mul_seq_item)

    // 🔥 what was executed
    instr_t      instr;      // 🔥 raw 32-bit encoding (shared_pkg union)
    instr_e      op;         // 🔥 decoded op name
    logic [4:0]  rd;         // 🔥 destination register from the encoding

    // 🔥 operands seen by the execution unit
    logic [31:0] rs1_val;
    logic [31:0] rs2_val;

    // 🔥 write-back (actual from DUT, or expected from predictor)
    logic [31:0] result;
    logic        wb_we;
    logic [5:0]  wb_waddr;

    function new(string name = "mul_seq_item");
        super.new(name);
    endfunction : new

    // 🔥 one-line print used in all messages
    virtual function string convert2string();
        return $sformatf("%-6s rd=x%0d rs1_val=0x%08h rs2_val=0x%08h result=0x%08h (instr=0x%08h we=%0b waddr=%0d)",
                         op.name(), rd, rs1_val, rs2_val, result, instr.raw, wb_we, wb_waddr);
    endfunction : convert2string

    // 🔥 field copy (used by clone() in the predictor)
    virtual function void do_copy(uvm_object rhs);
        mul_seq_item rhs_;
        if (!$cast(rhs_, rhs))
            `uvm_fatal(get_type_name(), "do_copy: rhs is not a mul_seq_item")
        super.do_copy(rhs);
        instr    = rhs_.instr;
        op       = rhs_.op;
        rd       = rhs_.rd;
        rs1_val  = rhs_.rs1_val;
        rs2_val  = rhs_.rs2_val;
        result   = rhs_.result;
        wb_we    = rhs_.wb_we;
        wb_waddr = rhs_.wb_waddr;
    endfunction : do_copy

    // 🔥 field compare with "===" so X/Z never counts as a match
    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        mul_seq_item rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return super.do_compare(rhs, comparer) &&
               (instr.raw === rhs_.instr.raw)  &&
               (rs1_val   === rhs_.rs1_val)    &&
               (rs2_val   === rhs_.rs2_val)    &&
               (result    === rhs_.result)     &&
               (wb_we     === rhs_.wb_we)      &&
               (wb_waddr  === rhs_.wb_waddr);
    endfunction : do_compare

endclass : mul_seq_item
