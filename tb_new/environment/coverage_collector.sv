import instruction_coverage_pkg::*;
import data_coverage_pkg::*;
import mul_coverage_pkg::*; // 🔥 NEW (MUL/DIV integration)

class coverage_collector extends uvm_component;
    `uvm_component_utils(coverage_collector)

    // exports
    uvm_analysis_export#(instruction_seq_item) instr_exp;
    uvm_analysis_export#(data_seq_item)         data_exp;
    uvm_analysis_export#(mul_seq_item)          mul_exp;  // 🔥 NEW (MUL/DIV integration): from mul_agt monitor

    // fifos
    uvm_tlm_analysis_fifo#(instruction_seq_item) instr_fifo;
    uvm_tlm_analysis_fifo#(data_seq_item)         data_fifo;
    uvm_tlm_analysis_fifo#(mul_seq_item)          mul_fifo; // 🔥 NEW (MUL/DIV integration)

    // Event to handle the reset interruption
    uvm_analysis_imp#(reset_item, coverage_collector) rst_imp;
    uvm_event rst_event;

    // coverage group instance
    instruction_covgp instr_cg;
    data_covgp         data_cg;
`ifndef MUL_NO_COVERGROUP  // 🔥 NEW (MUL/DIV integration)
    mul_covgp          mul_cg; // 🔥
`endif                     // 🔥
    int unsigned       mul_sampled; // 🔥 RV32M items sampled (counted even without the covergroup)

    bit in_reset = 0;

    function new(string name = "coverage_collector", uvm_component parent=null);
        super.new(name, parent);
        instr_cg = new();
        data_cg  = new();
`ifndef MUL_NO_COVERGROUP  // 🔥 NEW (MUL/DIV integration)
        mul_cg   = new();  // 🔥
`endif                     // 🔥
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        instr_exp = new("instr_exp",  this);
        data_exp  = new("data_exp", this);
        mul_exp   = new("mul_exp", this);   // 🔥 NEW (MUL/DIV integration)

        instr_fifo = new("instr_fifo",  this);
        data_fifo  = new("data_fifo", this);
        mul_fifo   = new("mul_fifo", this); // 🔥 NEW (MUL/DIV integration)

        rst_imp   = new("rst_imp", this);
        rst_event = new("rst_event");

    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        instr_exp.connect(instr_fifo.analysis_export);
        data_exp.connect(data_fifo.analysis_export);
        mul_exp.connect(mul_fifo.analysis_export); // 🔥 NEW (MUL/DIV integration)
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            fork
                fork
                    instr_sample();
                     data_sample();
                     mul_sample(); // 🔥 NEW (MUL/DIV integration)
                join
                begin
                    rst_event.wait_trigger();

                    instr_fifo.flush();
                    data_fifo.flush();
                    mul_fifo.flush(); // 🔥 NEW (MUL/DIV integration)

                    `uvm_info("COV_RST", "Coverage FIFOs flushed and state cleared due to reset", UVM_HIGH)
                end
            join_any

            disable fork;
        end
    endtask : run_phase

    protected task instr_sample();
        instruction_seq_item item;
        logic [31:0] inst;
        instr_e op;
        instr_group_e group_op;
        logic signed [31:0] imm;
        logic [4:0] shamt;
        bit rd_used;
        bit rs1_used;
        bit rs2_used;
        bit imm_used;
        bit shamt_used;

        forever begin
          instr_fifo.get(item);

          if (in_reset)
            continue;

          inst = item.data;

          op       = decode_instr(inst);
          group_op = classify_group(op);

          rd_used   = has_rd(op);
          rs1_used  = has_rs1(op);
          rs2_used  = has_rs2(op);
          imm_used  = has_imm(op);
          shamt_used = has_shamt(op);

          imm   = get_imm_value(inst, op);
          shamt = inst[24:20];

          instr_cg.sample(
                inst,
                op,
                group_op,
                imm,
                shamt,
                rd_used,
                rs1_used,
                rs2_used,
                imm_used,
                shamt_used
          );
        end
    endtask : instr_sample

    protected task data_sample();
        data_seq_item item;

        forever begin
            data_fifo.get(item);

            if (in_reset)
            continue;

            data_cg.sample(
                item.addr,
                item.we,
                item.be,
                item.wdata,
                item.rdata
            );
        end
    endtask : data_sample

    // 🔥 NEW (MUL/DIV integration): one sample per RV32M op published by mul_monitor
    protected task mul_sample();                                   // 🔥
        mul_seq_item item;                                         // 🔥
        forever begin                                              // 🔥
            mul_fifo.get(item);                                    // 🔥
            if (in_reset)                                          // 🔥
                continue;                                          // 🔥
            mul_sampled++;                                         // 🔥
`ifndef MUL_NO_COVERGROUP                                          // 🔥
            mul_cg.sample(item.op, item.rs1_val, item.rs2_val, item.result); // 🔥
`endif                                                             // 🔥
        end                                                        // 🔥
    endtask : mul_sample                                           // 🔥

    // 🔥 NEW (MUL/DIV integration): RV32M coverage summary
    virtual function void report_phase(uvm_phase phase);           // 🔥
        super.report_phase(phase);                                 // 🔥
`ifndef MUL_NO_COVERGROUP                                          // 🔥
        `uvm_info("MUL_COV", $sformatf("RV32M MUL/DIV functional coverage = %0.2f%% (%0d items sampled)", mul_cg.get_inst_coverage(), mul_sampled), UVM_NONE) // 🔥
`else                                                              // 🔥
        `uvm_info("MUL_COV", $sformatf("MUL_NO_COVERGROUP defined: covergroup disabled, %0d items sampled", mul_sampled), UVM_NONE) // 🔥
`endif                                                             // 🔥
    endfunction : report_phase                                     // 🔥

    virtual function void write(reset_item rst_item);
        instr_fifo.flush();
        data_fifo.flush();
        mul_fifo.flush(); // 🔥 NEW (MUL/DIV integration)

        if (rst_item.reset_state == 1'b0) begin
            rst_event.trigger();
            in_reset = 1;
        end
        else
            in_reset = 0;

    endfunction

endclass : coverage_collector
