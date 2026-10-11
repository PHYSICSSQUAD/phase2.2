class instruction_agent_config extends agent_config_base;
    `uvm_object_utils(instruction_agent_config)

    // variables
    local virtual instruction_if vif;

	function new (string name = "instruction_agent_config");
		super.new (name);
        mode = UVM_ACTIVE;
	endfunction

    //Setter & Getter for the virtual interface
    virtual function void set_vif(virtual instruction_if value);
        if(vif == null)
            vif = value;
        else
            `uvm_fatal("ALGORITHM_ISSUE", "Trying to set the virtual interface more than once")
    endfunction
    virtual function virtual instruction_if get_vif();
        return vif;
    endfunction

endclass : instruction_agent_config
