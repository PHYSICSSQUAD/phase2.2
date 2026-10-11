import shared_pkg::*;
class coverage_collector extends uvm_component;
    `uvm_component_utils(coverage_collector)


    // exports
    uvm_analysis_export#(instruction_seq_item) instr_exp;
    uvm_analysis_export#(data_seq_item)         data_exp;

    // fifos
    uvm_tlm_analysis_fifo#(instruction_seq_item) instr_fifo;
    uvm_tlm_analysis_fifo#(data_seq_item) data_fifo;

    // Event to handle the reset interruption
    uvm_analysis_imp#(reset_item, coverage_collector) rst_imp;
    uvm_event rst_event;

    function new(string name = "coverage_collector", uvm_component parent=null);
        super.new(name, parent);
        covgp = new();
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        instr_exp = new("instr_exp",  this);
        data_exp = new("data_exp", this);
        rst_imp = new("rst_imp", this);

        instr_fifo = new("instr_fifo",  this);
        data_fifo = new("data_fifo", this);

        rst_event = new("rst_event");
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        instr_exp.connect(instr_fifo.analysis_export);
        data_exp.connect(data_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            fork
                fork
                    begin
                        instr_sample();
                    end
                    // begin
                        
                    // end
                join
                begin
                    rst_event.wait_trigger();

                    instr_fifo.flush();
                    data_fifo.flush();

                    instr_item = instruction_seq_item::type_id::create("instr_item");
                    data_item = data_seq_item::type_id::create("data_item");

                    `uvm_info("COV_RST", "Coverage FIFOs flushed and state cleared due to reset", UVM_HIGH)
                end
            join_any

            disable fork;
        end
    endtask : run_phase

    virtual function void instr_sample();
        instruction_seq_item instr_item;

        forever begin
            instr_fifo.get(instr_item);

            instr_cg.sample(

            );
        end
    endfunction : instr_sample

    virtual function void write(reset_item rst_item);
        if (rst_item.reset_state == 1'b0) begin
            rst_event.trigger();
        end
    endfunction

endclass : coverage_collector
