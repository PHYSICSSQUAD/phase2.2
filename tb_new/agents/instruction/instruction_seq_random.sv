class instruction_seq_random extends uvm_sequence#(instruction_seq_item);
	`uvm_object_utils(instruction_seq_random)

	int num_txns;
	int completed_txns;

	function new(string name = "instruction_seq_random");
		super.new(name);
	endfunction : new

	virtual task body();
		completed_txns = 0;

		repeat(num_txns) begin
			instruction_seq_item item = instruction_seq_item::type_id::create("item");
			start_item(item);

			if (!item.randomize() /*with {group inside {LOAD,STORE}; data.s_type.rs2 == 4;}op == LW;}*/)
				`uvm_fatal("RANDOMIZE_FAIL", "Failed to randomize item in instruction_seq_random")
			finish_item(item);

			completed_txns++;
		end
	endtask : body

endclass : instruction_seq_random
