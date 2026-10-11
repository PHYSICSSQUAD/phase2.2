class data_agent_config extends agent_config_base;
    `uvm_object_utils(data_agent_config)

    // variables
    local virtual data_if vif;

	function new (string name = "data_agent_config");
		super.new (name);
        mode = UVM_ACTIVE;
	endfunction

    //Setter & Getter for the virtual interface
    virtual function void set_vif(virtual data_if value);
        if(vif == null)
            vif = value;
        else
            `uvm_fatal("ALGORITHM_ISSUE", "Trying to set the virtual interface more than once")
    endfunction
    virtual function virtual data_if get_vif();
        return vif;
    endfunction

endclass : data_agent_config
