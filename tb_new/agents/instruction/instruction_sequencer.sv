class instruction_sequencer extends uvm_sequencer#(instruction_seq_item) implements reset_handler;
	`uvm_component_utils(instruction_sequencer)

	function new(string name = "instruction_sequencer", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

	virtual function void handle_reset(uvm_phase phase);

        stop_sequences();

        $display("*** RESET in instruction sequencer at time %0t ***", $time);
        `uvm_info("SEQ_RESET", "Sequencer reset handler called", UVM_HIGH)

	endfunction

endclass : instruction_sequencer
