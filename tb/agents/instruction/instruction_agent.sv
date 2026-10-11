class instruction_agent extends agent_base#(instruction_seq_item);
	`uvm_component_utils(instruction_agent)

	// components
	instruction_sequencer sqr;
	instruction_driver    drv;
	instruction_monitor   mon;

	// configurations
	instruction_agent_config cfg;

	function new(string name = "instruction_agent", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		// get configuration object
		if(!uvm_config_db#(instruction_agent_config)::get(this, "", "instr_cfg", cfg))
            `uvm_fatal(get_full_name(), "Error: cant get cfg")
        super.cfg = cfg;

		// construct instances
		if (cfg.get_mode() == UVM_ACTIVE) begin
			sqr = instruction_sequencer::type_id::create("sqr", this);
			drv = instruction_driver   ::type_id::create("drv", this);
		end

		mon = instruction_monitor::type_id::create("mon", this);
	endfunction : build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		// sequencer to driver tlm connection
		if (cfg.get_mode() == UVM_ACTIVE) begin
			drv.set_cfg(cfg);
			drv.vif = cfg.get_vif();
			drv.seq_item_port.connect(sqr.seq_item_export);
		end

		// connect virtual interfaces
		mon.vif = cfg.get_vif();
		mon.set_cfg(cfg);
		mon.ap.connect(mon_ap);

	endfunction : connect_phase

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        if (cfg.get_vif() == null)
            `uvm_fatal("ALGORITHM_ISSUE", "The virtual interface is not configured at \"Start of simulation\" phase")
        else
            `uvm_info("instr_CONFIG", "The virtual interface is configured at \"Start of simulation\" phase", UVM_DEBUG)
    endfunction : start_of_simulation_phase

endclass : instruction_agent
