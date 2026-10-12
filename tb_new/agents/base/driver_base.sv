virtual class driver_base#(type T = uvm_sequence_item) extends uvm_driver#(T) implements reset_handler;

    // variables
    protected agent_config_base cfg;

    // process for driv_transaction task
    protected process process_drive_txn;

	function new(string name = "driver_base", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			fork
				begin
					wait_rst_end();
					drive_txns();

					disable fork;
				end
			join
		end
	endtask : run_phase

	protected virtual task drive_txns();
		fork
			begin
				process_drive_txn = process::self;
				forever begin
					T item;
					seq_item_port.get_next_item(item);
					drive_txn(item);
		            seq_item_port.item_done();
				end
			end
		join
	endtask : drive_txns

	pure protected virtual task drive_txn(T item);

	virtual function void handle_reset(uvm_phase phase);
	    // at reset: kill the transaction process if running
	    if (process_drive_txn) begin
	        process_drive_txn.kill();
	        process_drive_txn = null;
		end
	endfunction

	virtual function void set_cfg(agent_config_base c);
		cfg = c;
	endfunction

	virtual function agent_config_base get_cfg();
		return cfg;
	endfunction

	// task for wating the reset to start
    virtual task wait_rst_start();
        cfg.wait_rst_start();
    endtask : wait_rst_start

	// task for wating the reset to end
    virtual task wait_rst_end();
    	cfg.wait_rst_end();
    endtask : wait_rst_end

endclass : driver_base
