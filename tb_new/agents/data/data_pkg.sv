`include "data_if.sv"
`include "data_sva.sv"

package data_pkg;
	import uvm_pkg::*;
	import shared_pkg::*;
	import base_pkg::*;
	
	`include "uvm_macros.svh"

	`include "reset_handler.sv"

	`include "data_seq_item.sv"
	// `include "data_error_item.sv"

	`include "data_agent_config.sv"
	`include "data_sequencer.sv"
	`include "data_seq_random.sv"

	`include "data_driver.sv"
	`include "data_monitor.sv"

	`include "data_agent.sv"
endpackage : data_pkg
