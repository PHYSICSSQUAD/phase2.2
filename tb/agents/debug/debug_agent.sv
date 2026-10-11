class debug_agent extends agent_base#(uvm_sequence_item);
	`uvm_component_utils(debug_agent)

	// components
	debug_driver drv;

	// configurations
	debug_agent_config cfg;

	function new(string name = "debug_agent", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(!uvm_config_db#(debug_agent_config)::get(this, "", "dbg_cfg", cfg))
            `uvm_fatal(get_full_name(), "Error: cant get cfg")
        super.cfg = cfg;

		if (cfg.get_mode() == UVM_ACTIVE) begin
			drv = debug_driver::type_id::create("drv", this);
		end
	endfunction : build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		if (cfg.get_mode() == UVM_ACTIVE) begin
			drv.set_cfg(cfg);
			drv.vif = cfg.get_vif();
		end
	endfunction : connect_phase

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        if (cfg.get_vif() == null)
            `uvm_fatal("ALGORITHM_ISSUE", "The virtual interface is not configured at \"Start of simulation\" phase")
        else
            `uvm_info("dbg_CONFIG", "The virtual interface is configured at \"Start of simulation\" phase", UVM_DEBUG)
    endfunction : start_of_simulation_phase

endclass : debug_agent
