class reset_agent extends uvm_agent;
	`uvm_component_utils(reset_agent)

	// components
	reset_sequencer rst_sqr;
	reset_driver    rst_drv;
	reset_monitor   rst_mon;

	// configurations
	reset_agent_config rst_cfg;

	// ports
	uvm_analysis_port#(reset_item) rst_ap;

	// Constructor
	function new(string name = "reset_agent", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		rst_ap = new("rst_ap", this);

		// get configuration object
		if(!uvm_config_db#(reset_agent_config)::get(this, "", "rst_cfg", rst_cfg))
            `uvm_fatal(get_full_name(), "Error")
		
		if (rst_cfg.get_mode() == UVM_ACTIVE) begin
			rst_sqr = reset_sequencer::type_id::create("rst_sqr", this);
			rst_drv = reset_driver   ::type_id::create("rst_drv", this);
		end
	
		rst_mon = reset_monitor  ::type_id::create("rst_mon", this);

	endfunction : build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		rst_mon.ap.connect(rst_ap);

		// sequencer to driver tlm connection
		if (rst_cfg.get_mode() == UVM_ACTIVE) begin
			rst_drv.vif = rst_cfg.get_vif();
			rst_drv.seq_item_port.connect(rst_sqr.seq_item_export);
		end

		// connect virtual interfaces
		rst_mon.vif = rst_cfg.get_vif();

	endfunction : connect_phase

endclass : reset_agent