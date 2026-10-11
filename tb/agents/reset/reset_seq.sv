class reset_seq extends uvm_sequence#(reset_item);
	`uvm_object_utils(reset_seq)

	// Constructor
	function new(string name = "reset_seq");
		super.new(name);
	endfunction : new

	virtual task body();
		repeat(no_txn) begin
			reset_item item = reset_item::type_id::create("item");
			start_item(item);
			if (!item.randomize())
				`uvm_fatal("RANDOMIZE_FAIL", "Failed to randomize reset_item in rst_seq")
			finish_item(item);
		end
	endtask : body

endclass : reset_seq