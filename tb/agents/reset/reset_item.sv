class reset_item extends uvm_sequence_item;
	`uvm_object_utils(reset_item)

	// vars
	rand int delay_cycles;
	rand int reset_cycles;
	// offset
	rand int assert_offset;

	bit reset_state;

	// constraint c_delay 		{ delay_cycles  inside {[(T*5):(T*T)    ]}; }
	constraint c_delay 		{ delay_cycles  == 100; }
	constraint c_width 		{ reset_cycles  inside {[(T/5):(T/2)    ]}; }
	constraint c_assert_off { assert_offset inside {[    0:(T-(T/T))]}; }

	// Constructor
	function new(string name = "reset_item");
		super.new(name);
	endfunction : new

	virtual function string convert2string();
		string contents = super.convert2string();

		$sformat(contents,
          "%s, delay_cycles=%0t, reset_cycles=%0d, assert_offset=%0d, reset_state=%0b",
          contents, delay_cycles, reset_cycles, assert_offset, reset_state);

		return contents;
	endfunction

	virtual function void do_copy(uvm_object rhs);
		reset_item rst_item;

		super.do_copy(rhs);

		if (!$cast(rst_item, rhs))
		  	`uvm_fatal(get_type_name(), "do_copy: Cast failed")

		delay_cycles    = rst_item.delay_cycles;
		reset_cycles    = rst_item.reset_cycles;
		assert_offset   = rst_item.assert_offset;
		reset_state     = rst_item.reset_state;
	endfunction

endclass : reset_item
