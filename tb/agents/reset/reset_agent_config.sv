class reset_agent_config extends uvm_object;
    `uvm_object_utils(reset_agent_config)

    // variables
    local uvm_active_passive_enum rst_mode;
    local virtual reset_if rst_vif;

	function new (string name = "reset_agent_config");
		super.new (name);
        rst_mode = UVM_ACTIVE;
	endfunction

    //Setter & Getter for the virtual interface
    virtual function void set_vif(virtual reset_if value);
        if(rst_vif == null)
            rst_vif = value;
        else
            `uvm_fatal("ALGORITHM_ISSUE", "Trying to set the virtual interface more than once")
    endfunction
    virtual function virtual reset_if get_vif();
        return rst_vif;
    endfunction

    //Setter & Getter for the agent rst_mode
    virtual function uvm_active_passive_enum get_mode();
        return rst_mode;
    endfunction
    virtual function void set_mode(uvm_active_passive_enum value);
        rst_mode = value;
    endfunction

endclass : reset_agent_config