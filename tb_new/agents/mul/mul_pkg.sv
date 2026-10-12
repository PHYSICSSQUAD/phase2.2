// 🔥 NEW (MUL/DIV integration) - MUL agent package, same style as instruction_pkg.sv.
// 🔥 Uses shared_pkg (NOT tb_pkg from mul_env, which does not exist in tb_new/).
`include "alu_mul_if.sv"

package mul_pkg;
	import uvm_pkg::*;
	import shared_pkg::*;
	import base_pkg::*;

	`include "uvm_macros.svh"

	`include "mul_seq_item.sv"

	`include "mul_agent_config.sv"

	`include "mul_monitor.sv"

	`include "mul_agent.sv"
endpackage : mul_pkg
