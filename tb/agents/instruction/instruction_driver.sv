class instruction_driver extends driver_base#(instruction_seq_item);
	`uvm_component_utils(instruction_driver)

	// variables
	virtual instruction_if.DRIVER vif;

	function new(string name = "instruction_driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	extern protected virtual task drive_txn(instruction_seq_item item);

	virtual function void handle_reset(uvm_phase phase);
		super.handle_reset(phase);
		vif.drv_cb.instr_gnt_i    <= 1'b0;
		vif.drv_cb.instr_rvalid_i <= 1'b0;
		vif.drv_cb.instr_rdata_i  <=   '0;
	endfunction

endclass : instruction_driver



task instruction_driver::drive_txn(instruction_seq_item item);

	// drive from txn-level to pin-level
	@(vif.drv_cb iff vif.drv_cb.instr_req_o);
	repeat(item.delay) @(vif.drv_cb);
	vif.drv_cb.instr_gnt_i <= 1'b1;
	@(vif.drv_cb);
	vif.drv_cb.instr_gnt_i <= 1'b0;

	repeat(item.delay) @(vif.drv_cb);
	vif.drv_cb.instr_rvalid_i <= 1'b1;
	vif.drv_cb.instr_rdata_i  <= item.data;

	@(vif.drv_cb);
	vif.drv_cb.instr_rvalid_i <= 1'b0;

	`uvm_info("DEBUG", $sformatf("Driving \"%0s\": %0s", item.get_full_name(), item.convert2string()), UVM_NONE)
endtask : drive_txn
