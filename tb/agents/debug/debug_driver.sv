class debug_driver extends driver_base#(uvm_sequence_item);
	`uvm_component_utils(debug_driver)

	// variables
	virtual debug_if.DRIVER vif;

	function new(string name = "debug_driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	virtual task run_phase(uvm_phase phase);
		forever begin
			drive_txn(null);
		end
	endtask : run_phase

	protected virtual task drive_txns();
	endtask : drive_txns

	extern protected virtual task drive_txn(uvm_sequence_item item);

endclass : debug_driver

task debug_driver::drive_txn(uvm_sequence_item item);
    @(vif.drv_cb);
	vif.drv_cb.irq_i       <= 32'h0;
	vif.drv_cb.debug_req_i <= 1'b0;
endtask : drive_txn
