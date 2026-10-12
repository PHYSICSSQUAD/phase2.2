class reset_driver extends uvm_driver#(reset_item);
	`uvm_component_utils(reset_driver)

	// variables
	virtual reset_if vif;

	// Constructor
	function new(string name = "reset_driver", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			reset_item item;

			// get
			seq_item_port.get_next_item(item);

			// drive from txn-level to pin-level
			`uvm_info("RESET", $sformatf("Reset Driving %0s: %0s", item.get_full_name(), item.convert2string()), UVM_HIGH)

			repeat(item.delay_cycles) @(posedge vif.clk);
			#(item.assert_offset);
			vif.rst_n <= 0;

			repeat(item.reset_cycles) @(posedge vif.clk);
			@(posedge vif.clk);
			vif.rst_n <= 1;

            seq_item_port.item_done();
		end
	endtask : run_phase

endclass : reset_driver
