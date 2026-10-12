class instruction_seq_item extends uvm_sequence_item;
	`uvm_object_utils(instruction_seq_item)

	// Request fields
	bit [31:0] addr;

	// Response fields
	rand instr_t data;
	rand int 	 delay;

	// Gen Knobs
	rand instr_group_e group;
	rand instr_e op;

	//------------------ Constraints -----------------\\
	constraint delay_c { delay inside {[0:5]}; }

	constraint opcode_c { data.raw[6:0] == get_opcode(op); }

	constraint funct3_c { !(op inside {LUI, AUIPC, JAL}) -> data.raw[14:12] == get_funct3(op); }

  	constraint funct7_c {
    (op inside {ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND, MUL, MULH,
				MULHSU, MULHU, DIV, DIVU, REM, REMU, SLLI, SRLI, SRAI})
				-> data.raw[31:25] == get_funct7(op);
  	}

	constraint group_c {
		(group == ALU_R)  -> op inside {ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND};
		(group == MULDIV) -> op inside {MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU};
		(group == ALU_I)  -> op inside {ADDI, SLTI, SLTIU, XORI, ORI, ANDI};
		(group == SHIFT)  -> op inside {SLLI, SRLI, SRAI};
		(group == LOAD)   -> op inside {LB, LH, LW, LBU, LHU};
		(group == STORE)  -> op inside {SB, SH, SW};
		(group == BRANCH) -> op inside {BEQ, BNE, BLT, BGE, BLTU, BGEU};
		(group == JUMP)   -> op inside {JAL, JALR};
		(group == UPPER)  -> op inside {LUI, AUIPC};
	}

	constraint solve_order_c {
		solve group before op;
		solve op before data;
	}

	function new(string name = "instruction_seq_item");
		super.new(name);
	endfunction : new

	extern virtual function string convert2string();
	extern virtual function void   do_copy(uvm_object rhs);
	extern virtual function bit    do_compare(uvm_object rhs, uvm_comparer comparer);

endclass : instruction_seq_item


function string instruction_seq_item::convert2string();
	string contents = super.convert2string();
	$sformat(contents, "%s, addr  = 0x%0h", contents, addr);
	$sformat(contents, "%s, data  = 0x%0h", contents, data);
	$sformat(contents, "%s, delay = 0x%0h", contents, delay);
	return contents;
endfunction

function void instruction_seq_item::do_copy(uvm_object rhs);
	instruction_seq_item item;

	super.do_copy(rhs);

	if (!$cast(item, rhs))
	  	`uvm_fatal(get_type_name(), "do_copy: Cast failed")

	addr  = item.addr;
	data  = item.data;
	delay = item.delay;
	endfunction

	function bit instruction_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
	instruction_seq_item item;
	bit      status = 1;

	if (!$cast(item, rhs)) begin
	    `uvm_error("COMPARE", "Cast failed in do_compare")
	    return 0;
	end

	status &= super.do_compare(rhs, comparer);

	status &= (this.addr  == item.addr);
	status &= (this.data  == item.data);
	status &= (this.delay == item.delay);

	return status;
endfunction
