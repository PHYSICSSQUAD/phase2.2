`include "instruction_if.sv"
`include "instruction_sva.sv"

package instruction_pkg;
	import uvm_pkg::*;
	import shared_pkg::*;
	import base_pkg::*;

	`include "uvm_macros.svh"

	`include "instruction_seq_item.sv"
	// `include "instruction_error_item.sv"

	`include "instruction_seq_random.sv"

	`include "instruction_agent_config.sv"

	`include "instruction_sequencer.sv"
	`include "instruction_driver.sv"
	`include "instruction_monitor.sv"

	`include "instruction_agent.sv"
endpackage : instruction_pkg
