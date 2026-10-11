package env_pkg;
	import uvm_pkg::*;
	import shared_pkg::*;
	import base_pkg::*;
	import instruction_pkg::*;
	import data_pkg::*;
	import reset_pkg::*;
	import debug_pkg::*;
	import mul_pkg::*; // 🔥 NEW (MUL/DIV integration)
	// import instruction_coverage_pkg::*;
	

    `include "shadow_data_memory.sv"

    // `include "instruction_coverage_pkg"

	// `include "coverage_collector.sv"
	`include "predictor.sv"
	`include "mul_scoreboard.sv" // 🔥 NEW (MUL/DIV integration)
	`include "mul_coverage.sv"   // 🔥 NEW (MUL/DIV integration)
	// `include "scoreboard.sv"

	`include "virtual_sequencer.sv"

endpackage : env_pkg
