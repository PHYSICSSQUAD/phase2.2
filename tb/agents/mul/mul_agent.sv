// 🔥 NEW (MUL/DIV integration) - PASSIVE MUL agent (monitor only).
// 🔥 Same structure as instruction_agent.sv, without sequencer and driver.
class mul_agent extends agent_base#(mul_seq_item);
	`uvm_component_utils(mul_agent)

	// 🔥 components
	mul_monitor mon;

	// 🔥 configurations
	mul_agent_config cfg;

	function new(string name = "mul_agent", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		// 🔥 get configuration object
		if(!uvm_config_db#(mul_agent_config)::get(this, "", "mul_cfg", cfg))
            `uvm_fatal(get_full_name(), "Error: cant get cfg")
        super.cfg = cfg;

		if (cfg.get_mode() == UVM_ACTIVE)
			`uvm_warning(get_full_name(), "mul_agent is passive only: UVM_ACTIVE ignored, no driver/sequencer built")

		mon = mul_monitor::type_id::create("mon", this);
	endfunction : build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		// 🔥 connect virtual interface and analysis port
		mon.vif = cfg.get_vif();
		mon.set_cfg(cfg);
		mon.ap.connect(mon_ap);
	endfunction : connect_phase

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        if (cfg.get_vif() == null)
            `uvm_fatal("ALGORITHM_ISSUE", "The virtual interface is not configured at \"Start of simulation\" phase")
        else
            `uvm_info("MUL_CONFIG", "The virtual interface is configured at \"Start of simulation\" phase", UVM_DEBUG)
    endfunction : start_of_simulation_phase

endclass : mul_agent
