class data_driver extends driver_base#(data_seq_item);
	`uvm_component_utils(data_driver)

	// variables
	virtual data_if.DRIVER vif;

	function new(string name = "data_driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	protected virtual task drive_txns();
		fork
			begin
				process_drive_txn = process::self;
				forever begin
					data_seq_item item;
                    vif.drv_cb.data_gnt_i <= 1'b1;
					seq_item_port.get_next_item(item);
					drive_txn(item);
		            seq_item_port.item_done();
				end
			end
		join
	endtask : drive_txns

	extern protected virtual task drive_txn(data_seq_item item);

	virtual function void handle_reset(uvm_phase phase);
		super.handle_reset(phase);
		vif.drv_cb.data_gnt_i    <= 1'b0;
		vif.drv_cb.data_rvalid_i <= 1'b0;
		vif.drv_cb.data_rdata_i  <=  'b0;
	endfunction

endclass : data_driver


task data_driver::drive_txn(data_seq_item item);

	repeat(item.delay) @(vif.drv_cb);
	vif.drv_cb.data_rvalid_i <= 1'b1;
	vif.drv_cb.data_rdata_i  <= item.rdata;

	@(vif.drv_cb);
	vif.drv_cb.data_rvalid_i <= 1'b0;

	`uvm_info("DEBUG", $sformatf("Driving \"%0s\": %0s", item.get_full_name(), item.convert2string()), UVM_FULL)

endtask : drive_txn
