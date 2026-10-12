class environment extends uvm_env;
	`uvm_component_utils(environment)

	// components
	coverage_collector cov;
	predictor          pdt;
	scoreboard		   scb;

	instruction_agent instr_agt;
	data_agent        data_agt;
	reset_agent       rst_agt;
	debug_agent       dbg_agt;

	// 🔥 NEW (MUL/DIV integration): passive MUL agent, its config and scoreboard
	mul_agent          mul_agt;
	mul_agent_config   mul_cfg;
	mul_scoreboard     mul_scb;
	virtual alu_mul_if mul_vif;

	// virtual sequencer
	virtual_sequencer vsqr;

	function new(string name = "environment", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		cov = coverage_collector::type_id::create("cov", this);
		pdt = predictor::type_id::create("pdt", this);
		scb = scoreboard::type_id::create("scb", this);

		instr_agt = instruction_agent::type_id::create("instr_agt", this);
		data_agt  = data_agent::type_id::create("data_agt", this);
		rst_agt   = reset_agent::type_id::create("rst_agt", this);
		dbg_agt   = debug_agent::type_id::create("dbg_agt", this);

		// 🔥 NEW (MUL/DIV integration): vif comes from alu_mul_bind ("alu_mul_vif")
		if (!uvm_config_db#(virtual alu_mul_if)::get(this, "", "alu_mul_vif", mul_vif))
			`uvm_fatal(get_full_name(), "Error: can't get the ALU_MUL interface \"alu_mul_vif\" (is alu_mul_bind instantiated in top?)")
		mul_cfg = mul_agent_config::type_id::create("mul_cfg");  // 🔥
		mul_cfg.set_vif(mul_vif);                                 // 🔥
		mul_cfg.set_mode(UVM_PASSIVE);                            // 🔥
		uvm_config_db#(mul_agent_config)::set(this, "mul_agt", "mul_cfg", mul_cfg); // 🔥
		mul_agt = mul_agent::type_id::create("mul_agt", this);       // 🔥
		mul_scb = mul_scoreboard::type_id::create("mul_scb", this);  // 🔥

		vsqr = virtual_sequencer::type_id::create("vsqr", this);
	endfunction : build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		// cov
		instr_agt.mon_ap.connect(cov.instr_exp);
		data_agt.mon_ap.connect(cov.data_exp);
		
		// pdt
		instr_agt.mon_ap.connect(pdt.instr_imp);
		
		// scb
		data_agt.mon_ap.connect(scb.data_act_exp);
		pdt.data_ap.connect(scb.data_exp_exp);

		// rst
		rst_agt.rst_ap.connect(cov.rst_imp);
		rst_agt.rst_ap.connect(pdt.rst_imp);
		rst_agt.rst_ap.connect(scb.rst_imp);

		// 🔥 NEW (MUL/DIV integration): monitor -> predictor -> mul_scb (EXPECTED),
		// 🔥 monitor -> mul_scb (ACTUAL), monitor -> main coverage_collector
		mul_agt.mon_ap.connect(pdt.mul_imp);          // 🔥
		pdt.mul_ap.connect(mul_scb.mul_exp_exp);      // 🔥
		mul_agt.mon_ap.connect(mul_scb.mul_act_exp);  // 🔥
		mul_agt.mon_ap.connect(cov.mul_exp);          // 🔥

		// connect virtual sequencer to agent sequencers
		vsqr.instr_sqr = instr_agt.sqr;
		vsqr.data_sqr  = data_agt.sqr;
		vsqr.rst_sqr   = rst_agt.rst_sqr;
	endfunction : connect_phase

endclass : environment
