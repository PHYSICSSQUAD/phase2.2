virtual class virtual_seq_base extends uvm_sequence;

	instruction_agent_config cfg;

	`uvm_declare_p_sequencer(virtual_sequencer)

	// Constructor
	function new(string name = "virtual_seq_base");
		super.new(name);
	endfunction : new

	virtual task pre_start();
        super.pre_start();
        if (!uvm_config_db#(instruction_agent_config)::get(p_sequencer, "", "instr_cfg", cfg)) begin
            `uvm_fatal("NO_CFG", "Failed to get instruction_agent_config in virtual_seq_base")
        end
    endtask: pre_start
endclass : virtual_seq_base