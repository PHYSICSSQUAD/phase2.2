`include "test_pkg.sv"

import uvm_pkg::*;
import shared_pkg::*;
import test_pkg::*;
import reset_pkg::*;
import instruction_pkg::*;
import data_pkg::*;
import debug_pkg::*;

module top;
	logic clk;

	// interfaces
	instruction_if instr_if(clk);
	data_if 	    data_if(clk);
	reset_if         rst_if(clk);
	debug_if         dbg_if(clk);

	// dut instance
	cv32e40p_top #(
	    .FPU                      ( 0 ),
	    .FPU_ADDMUL_LAT           ( 0 ),
	    .FPU_OTHERS_LAT           ( 0 ),
	    .ZFINX                    ( 0 ),
	    .COREV_PULP               ( 0 ),
	    .COREV_CLUSTER            ( 0 ),
	    .NUM_MHPMCOUNTERS         ( 1 )
	) u_core (
	    // Clock and reset
	    .rst_ni                   (rst_if.rst_n),
	    .clk_i                    (clk),
	    .scan_cg_en_i             (1'b0),

	    // Special control signals
	    .fetch_enable_i           (1'b1),
	    .pulp_clock_en_i          (1'b0),
	    .core_sleep_o             (),

	    // Configuration
	    .boot_addr_i              (0),
	    .mtvec_addr_i             (0),
	    .dm_halt_addr_i           (0),
	    .dm_exception_addr_i      (0),
	    .hart_id_i                (0),

	    // Instruction memory interface
	    .instr_addr_o             (instr_if.instr_addr_o),
	    .instr_req_o              (instr_if.instr_req_o),
	    .instr_gnt_i              (instr_if.instr_gnt_i),
	    .instr_rvalid_i           (instr_if.instr_rvalid_i),
	    .instr_rdata_i            (instr_if.instr_rdata_i),

	    // Data memory interface
	    .data_addr_o              (data_if.data_addr_o),
	    .data_req_o               (data_if.data_req_o),
	    .data_gnt_i               (data_if.data_gnt_i),
	    .data_we_o                (data_if.data_we_o),
	    .data_be_o                (data_if.data_be_o),
	    .data_wdata_o             (data_if.data_wdata_o),
	    .data_rvalid_i            (data_if.data_rvalid_i),
	    .data_rdata_i             (data_if.data_rdata_i),

	     // Interrupt interface
	    .irq_i                    (dbg_if.irq_i),
	    .irq_ack_o                (dbg_if.irq_id_o),
	    .irq_id_o                 (dbg_if.irq_ack_o),

	    // Debug interface
	    .debug_req_i              (dbg_if.debug_req_i),
	    .debug_havereset_o        (dbg_if.debug_havereset_o),
	    .debug_running_o          (dbg_if.debug_running_o),
	    .debug_halted_o           (dbg_if.debug_halted_o)
	);

	// assertions binding
	bind u_core instruction_sva instr_asrt(instr_if.ASSERT, rst_if.rst_n);
	bind u_core data_sva data_asrt(data_if.ASSERT, rst_if.rst_n);

	// Dump waveforms
	// initial begin
	// 	$dumpfile("waves.vcd");
	// 	$vcdpluson;
	// 	$dumpvars(0, top);
	// end

	initial begin
		// set interfaces before starting UVM
		uvm_config_db#(virtual instruction_if)::set(null, "uvm_test_top", "instr_vif",instr_if);
		uvm_config_db#(virtual data_if)::set(null, "uvm_test_top", "data_vif",data_if);
		uvm_config_db#(virtual reset_if)::set(null, "uvm_test_top", "rst_vif", rst_if);
		uvm_config_db#(virtual debug_if)::set(null, "uvm_test_top", "dbg_vif", dbg_if);

		fork
			reset();
			run_test("test_random");
		join

	end

	// clock generation
	initial begin
		clk = 0;
		forever #(T/2) clk = !clk;
	end

	// reset task
	task reset();
		rst_if.rst_n <= 1'b0;
		repeat(3) @(posedge clk);
		rst_if.rst_n <= 1'b1;
	endtask : reset

endmodule
