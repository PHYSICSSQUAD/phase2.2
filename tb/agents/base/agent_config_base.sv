virtual class agent_config_base extends uvm_object;

    // variables
    protected uvm_active_passive_enum mode;

    // uvm rst events
    uvm_event as_rst = uvm_event_pool::get_global("async_reset_assert");
    uvm_event de_rst = uvm_event_pool::get_global("async_reset_deassert");

	function new (string name = "agent_config_base");
		super.new (name);
	endfunction

    //Setter & Getter for the agent mode
    virtual function uvm_active_passive_enum get_mode();
        return mode;
    endfunction
    virtual function void set_mode(uvm_active_passive_enum value);
        mode = value;
    endfunction

    virtual task wait_rst_start();
        as_rst.wait_on();
    endtask : wait_rst_start

    virtual task wait_rst_end();
        de_rst.wait_on();
    endtask : wait_rst_end

endclass : agent_config_base
