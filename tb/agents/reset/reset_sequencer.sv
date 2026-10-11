class reset_sequencer extends uvm_sequencer#(reset_item);
	`uvm_component_utils(reset_sequencer)

	// Constructor
	function new(string name = "reset_sequencer", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

endclass : reset_sequencer