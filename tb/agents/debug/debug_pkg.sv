`include "debug_if.sv"

package debug_pkg;
	import uvm_pkg::*;
	import shared_pkg::*;
	import base_pkg::*;

	`include "uvm_macros.svh"
	`include "debug_agent_config.sv"
	`include "debug_driver.sv"
	`include "debug_agent.sv"
endpackage : debug_pkg
