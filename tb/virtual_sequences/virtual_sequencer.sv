class virtual_sequencer extends uvm_sequencer;
	`uvm_component_utils(virtual_sequencer)

	instruction_sequencer instr_sqr;
	data_sequencer		   data_sqr;
	reset_sequencer         rst_sqr;

	// Constructor
	function new(string name = "virtual_sequencer", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

endclass : virtual_sequencer
