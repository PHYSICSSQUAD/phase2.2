// 🔥 NEW (MUL/DIV integration) - configuration of the passive MUL agent.
// 🔥 Same style as instruction_agent_config.sv; default mode is UVM_PASSIVE.
class mul_agent_config extends agent_config_base;
    `uvm_object_utils(mul_agent_config)

    // 🔥 variables
    local virtual alu_mul_if vif;

    function new (string name = "mul_agent_config");
        super.new (name);
        mode = UVM_PASSIVE; // 🔥 monitor only: no sequencer, no driver
    endfunction

    // 🔥 Setter & Getter for the virtual interface
    virtual function void set_vif(virtual alu_mul_if value);
        if(vif == null)
            vif = value;
        else
            `uvm_fatal("ALGORITHM_ISSUE", "Trying to set the virtual interface more than once")
    endfunction
    virtual function virtual alu_mul_if get_vif();
        return vif;
    endfunction

endclass : mul_agent_config
