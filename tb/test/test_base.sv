virtual class test_base extends uvm_test;

	// components
	environment  env;

	function new(string name = "test_base", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = environment::type_id::create("env", this);
	endfunction : build_phase

endclass : test_base
