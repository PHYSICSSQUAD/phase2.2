// 🔥 NEW (MUL/DIV integration) - ALU_MUL scoreboard for the 8 RV32M ops.
// 🔥 Separate from the shared scoreboard. Two inputs:
// 🔥   mul_act_exp : ACTUAL items from mul_agent (monitor)
// 🔥   mul_exp_exp : EXPECTED items from the predictor (predictor.mul_ap)
// 🔥 Both feed a uvm_tlm_analysis_fifo; the compare runs in its own thread
// 🔥 (forever loop in run_phase), not inside write().
// 🔥 Checks: result (===), wb_we == 1, wb_waddr == {1'b0, rd}.
class mul_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(mul_scoreboard)

    // 🔥 exports (inputs)
    uvm_analysis_export#(mul_seq_item) mul_act_exp;
    uvm_analysis_export#(mul_seq_item) mul_exp_exp;

    // 🔥 fifos
    uvm_tlm_analysis_fifo#(mul_seq_item) mul_act_fifo;
    uvm_tlm_analysis_fifo#(mul_seq_item) mul_exp_fifo;

    // 🔥 counters
    int unsigned pass_count;
    int unsigned fail_count;
    int unsigned op_count[instr_e];

    function new(string name = "mul_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mul_act_exp  = new("mul_act_exp", this);
        mul_exp_exp  = new("mul_exp_exp", this);
        mul_act_fifo = new("mul_act_fifo", this);
        mul_exp_fifo = new("mul_exp_fifo", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mul_act_exp.connect(mul_act_fifo.analysis_export);
        mul_exp_exp.connect(mul_exp_fifo.analysis_export);
    endfunction : connect_phase

    // 🔥 compare thread: one EXPECTED + one ACTUAL per RV32M op
    virtual task run_phase(uvm_phase phase);
        mul_seq_item exp_item;
        mul_seq_item act_item;
        super.run_phase(phase);
        forever begin
            mul_exp_fifo.get(exp_item);
            mul_act_fifo.get(act_item);
            compare(exp_item, act_item);
        end
    endtask : run_phase

    protected virtual function void compare(mul_seq_item exp_item, mul_seq_item act_item);
        bit ok;

        ok = (act_item.instr.raw === exp_item.instr.raw) &&
             (act_item.result    === exp_item.result)    &&
             (act_item.wb_we     === exp_item.wb_we)     &&
             (act_item.wb_waddr  === exp_item.wb_waddr);

        if (op_count.exists(act_item.op)) op_count[act_item.op]++;
        else                              op_count[act_item.op] = 1;

        if (ok) begin
            pass_count++;
            `uvm_info("MUL_SCB", $sformatf("PASS %-6s rs1=0x%08h rs2=0x%08h expected=0x%08h actual=0x%08h rd=x%0d",
                      act_item.op.name(), act_item.rs1_val, act_item.rs2_val,
                      exp_item.result, act_item.result, act_item.rd), UVM_MEDIUM)
        end
        else begin
            fail_count++;
            `uvm_error("MUL_SCB", $sformatf("FAIL %-6s instr=0x%08h rs1=0x%08h rs2=0x%08h expected=0x%08h actual=0x%08h | wb_we=%0b (exp %0b) wb_waddr=%0d (exp %0d)",
                       act_item.op.name(), act_item.instr.raw, act_item.rs1_val, act_item.rs2_val,
                       exp_item.result, act_item.result,
                       act_item.wb_we, exp_item.wb_we, act_item.wb_waddr, exp_item.wb_waddr))
        end
    endfunction : compare

    // 🔥 a test with zero checks proves nothing; leftovers mean lost pairs
    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (pass_count + fail_count == 0)
            `uvm_warning("MUL_SCB", "No MUL/MULH/MULHSU/MULHU/DIV/DIVU/REM/REMU instruction was checked in this test")
        if (!mul_act_fifo.is_empty() || !mul_exp_fifo.is_empty())
            `uvm_error("MUL_SCB", $sformatf("Unmatched items left: actual=%0d expected=%0d",
                       mul_act_fifo.used(), mul_exp_fifo.used()))
    endfunction : check_phase

    virtual function void report_phase(uvm_phase phase);
        string s;
        super.report_phase(phase);
        s = "\n-------------- RV32M MUL/DIV SCOREBOARD SUMMARY ----------\n";
        s = {s, $sformatf("  Checked : %0d   PASS : %0d   FAIL : %0d\n",
                          pass_count + fail_count, pass_count, fail_count)};
        foreach (op_count[op])
            s = {s, $sformatf("  %-6s : %0d\n", op.name(), op_count[op])};
        s = {s, "---------------------------------------------------------"};
        `uvm_info("MUL_SCB", s, UVM_NONE)
    endfunction : report_phase

endclass : mul_scoreboard
