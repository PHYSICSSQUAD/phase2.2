class data_sequencer extends uvm_sequencer#(data_seq_item) implements reset_handler;
	`uvm_component_utils(data_sequencer)

	uvm_analysis_export  #(data_seq_item) data_req_exp;
	uvm_tlm_analysis_fifo#(data_seq_item) data_req_fifo;

	function new(string name = "data_sequencer", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
        data_req_exp  = new("data_req_exp",  this);
        data_req_fifo = new("data_req_fifo", this);
	endfunction : build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
        data_req_exp.connect(data_req_fifo.analysis_export);
	endfunction : connect_phase

	virtual function void handle_reset(uvm_phase phase);
        stop_sequences();

        $display("*** RESET in data sequencer at time %0t ***", $time);
        `uvm_info("SEQ_RESET", "Sequencer reset handler called", UVM_HIGH)
	endfunction

endclass : data_sequencer
