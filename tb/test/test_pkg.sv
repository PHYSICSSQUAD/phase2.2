`include "shared_pkg.sv"
`include "base_pkg.sv"
`include "instruction_pkg.sv"
`include "data_pkg.sv"
`include "reset_pkg.sv"
`include "debug_pkg.sv"
`include "mul_pkg.sv" // 🔥 NEW (MUL/DIV integration)
`include "env_pkg.sv"

package test_pkg;
	import uvm_pkg::*;
	import shared_pkg::*;
	import env_pkg::*;
	import base_pkg::*;
	import instruction_pkg::*;
	import data_pkg::*;
	import reset_pkg::*;
	import debug_pkg::*;
	import mul_pkg::*; // 🔥 NEW (MUL/DIV integration)

	`include "uvm_macros.svh"

	`include "virtual_seq_base.sv"
	`include "virtual_seq_random.sv"
	// `include "virtual_seq_corner.sv"
	// `include "virtual_seq_stress.sv"

	`include "environment.sv"

	`include "test_base.sv"
	`include "test_random.sv"
	// `include "test_corner.sv"
	// `include "test_error.sv"
	// `include "test_stress.sv"

endpackage : test_pkg
