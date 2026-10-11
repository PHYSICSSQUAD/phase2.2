virtual class agent_base#(type T) extends uvm_agent implements reset_handler;

	// configurations
	agent_config_base cfg;

	// ports
	uvm_analysis_port#(T) mon_ap;

	function new(string name = "agent_base", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
		mon_ap = new("mon_ap", this);
    endfunction : build_phase

	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			wait_rst_start();
			handle_reset(phase);
			wait_rst_end();
		end
	endtask : run_phase

	virtual function void handle_reset(uvm_phase phase);
	    uvm_component children[$];
	    get_children(children);
	    foreach(children[i]) begin
			reset_handler reset_handler;
			if ($cast(reset_handler, children[i])) begin
				reset_handler.handle_reset(phase);
	        end
	    end
	endfunction
	// task for wating the reset to start
    virtual task wait_rst_start();
        cfg.wait_rst_start();
    endtask : wait_rst_start
	// task for wating the reset to end
    virtual task wait_rst_end();
    	cfg.wait_rst_end();
    endtask : wait_rst_end

endclass : agent_base
