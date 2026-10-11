class data_seq_item extends uvm_sequence_item;
		`uvm_object_utils(data_seq_item)

		// Request fields
		bit [31:0] addr;
		bit 	   we;
		bit [3 :0] be;
		bit [31:0] wdata;

		// Response fields
		     bit [31:0] rdata;
		rand int 		delay;

		// constraints
		constraint delay_c { delay inside {[0:5]}; }

		function new(string name = "data_seq_item");
			super.new(name);
		endfunction : new

		extern virtual function string convert2string();
		extern virtual function void   do_copy(uvm_object rhs);
		extern virtual function bit    do_compare(uvm_object rhs, uvm_comparer comparer);

endclass : data_seq_item


function string data_seq_item::convert2string();
	string contents = super.convert2string();
	$sformat(contents, "%s, addr  = 0x%0h", contents, addr);
	$sformat(contents, "%s, we    = 0x%0h", contents, we);
	$sformat(contents, "%s, be    = 0x%0h", contents, be);
	$sformat(contents, "%s, wdata = 0x%0h", contents, wdata);
	$sformat(contents, "%s, rdata = 0x%0h", contents, rdata);
	$sformat(contents, "%s, delay = 0x%0h", contents, delay);
	return contents;
endfunction

function void data_seq_item::do_copy(uvm_object rhs);
	data_seq_item item;

	super.do_copy(rhs);

	if (!$cast(item, rhs))
	  	`uvm_fatal(get_type_name(), "do_copy: Cast failed")

	addr  = item.addr;
	we    = item.we;
	be    = item.be;
	wdata = item.wdata;
	rdata = item.rdata;
	delay = item.delay;
endfunction

function bit data_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
    data_seq_item item;
    bit      status = 1;

    if (!$cast(item, rhs)) begin
        `uvm_error("COMPARE", "Cast failed in do_compare")
        return 0;
    end

    status &= super.do_compare(rhs, comparer);

    status &= (this.addr  == item.addr);
    status &= (this.we    == item.we);
    status &= (this.be    == item.be);
    status &= (this.wdata == item.wdata);
    status &= (this.rdata == item.rdata);
    status &= (this.delay == item.delay);

    return status;
endfunction
