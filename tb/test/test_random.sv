class test_random extends test_base;
	`uvm_component_utils(test_random)

	// configs
	instruction_agent_config instr_cfg;
	data_agent_config 		 data_cfg;
	reset_agent_config 		 rst_cfg;
	debug_agent_config      dbg_cfg;

	// variables
	virtual instruction_if instr_vif;
	virtual data_if        data_vif;
	virtual reset_if       rst_vif;
	virtual debug_if       dbg_vif;

	function new(string name = "test_random", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		// cfg
		instr_cfg = instruction_agent_config::type_id::create("instr_cfg");
		data_cfg  = data_agent_config::type_id::create("data_cfg");
		rst_cfg   = reset_agent_config::type_id::create("rst_cfg");
		dbg_cfg   = debug_agent_config::type_id::create("dbg_cfg");

		// get interfaces
		if (!uvm_config_db#(virtual instruction_if)::get(this, "", "instr_vif", instr_vif))
			`uvm_fatal(get_full_name(), "Error: can't get the instruction interface")

		if (!uvm_config_db#(virtual data_if)::get(this, "", "data_vif", data_vif))
			`uvm_fatal(get_full_name(), "Error: can't get the data interface")

		if (!uvm_config_db#(virtual reset_if)::get(this, "", "rst_vif", rst_vif))
			`uvm_fatal(get_full_name(), "Error: can't get the reset interface")

		if (!uvm_config_db#(virtual debug_if)::get(this, "", "dbg_vif", dbg_vif))
			`uvm_fatal(get_full_name(), "Error: can't get the debug interface")

		instr_cfg.set_vif(instr_vif);
		instr_cfg.set_mode(UVM_ACTIVE);

		data_cfg.set_vif(data_vif);
		data_cfg.set_mode(UVM_ACTIVE);

		rst_cfg.set_vif(rst_vif);
		rst_cfg.set_mode(UVM_ACTIVE);

		dbg_cfg.set_vif(dbg_vif);
		dbg_cfg.set_mode(UVM_ACTIVE);

		uvm_config_db#(instruction_agent_config)::set(this, "*", "instr_cfg", instr_cfg);
		uvm_config_db#(data_agent_config)::set(this, "*", "data_cfg", data_cfg);
		uvm_config_db#(reset_agent_config)::set(this, "*", "rst_cfg", rst_cfg);
		uvm_config_db#(debug_agent_config)::set(this, "*", "dbg_cfg", dbg_cfg);

	endfunction : build_phase

	virtual task run_phase(uvm_phase phase);
		virtual_seq_random vseq_random;

		super.run_phase(phase);

		phase.raise_objection(this);
		`uvm_info("DEBUG", "wait for reset deassert before starting virtual sequence", UVM_NONE)

		vseq_random = virtual_seq_random::type_id::create("vseq_random");
		`uvm_info("DEBUG", "this is the start of the random test", UVM_NONE)
		vseq_random.start(env.vsqr);

		`uvm_info("DEBUG", "this is the end of the random test", UVM_NONE)
		#100
		// `uvm_info("REPORT", $sformatf("this is the report: correct: %d, errors: %d", env.scb.correct, env.scb.error), UVM_NONE)
		phase.drop_objection(this);

	endtask : run_phase

endclass : test_random
