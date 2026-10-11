// 🔥 NEW (MUL/DIV integration) - binds alu_mul_if inside cv32e40p_core.
// 🔥 Copied from mul_env/alu_mul_bind.sv without `timescale.
// 🔥 The bind adds a small wrapper module INSIDE every cv32e40p_core instance,
// 🔥 so the port connections use the core's own local signal names: no RTL edit
// 🔥 and no hierarchical "u_core.core_i..." paths in top.sv.
// 🔥 The wrapper publishes the interface handle in uvm_config_db as "alu_mul_vif".
// 🔥 Usage in top.sv:  `include "alu_mul_bind.sv"  +  alu_mul_bind mul_bind ();

// 🔥 Wrapper: owns the interface instance and publishes its handle.
module alu_mul_bind_wrap (
    input logic        clk,
    input logic        rst_n,
    input logic        id_valid,
    input logic [31:0] id_instr,
    input logic        ex_mult_en,
    input logic [31:0] ex_mult_operand_a,
    input logic [31:0] ex_mult_operand_b,
    input logic        ex_alu_en,
    input logic [31:0] ex_alu_operand_a,
    input logic [31:0] ex_alu_operand_b,
    input logic        ex_valid,
    input logic        ex_wb_we,
    input logic [5:0]  ex_wb_waddr,
    input logic [31:0] ex_wb_wdata
);
    import uvm_pkg::*;

    alu_mul_if mul_if (.*);

    // 🔥 Time 0, no delay: runs before UVM build_phase of the environment.
    initial uvm_config_db#(virtual alu_mul_if)::set(null, "*", "alu_mul_vif", mul_if);
endmodule : alu_mul_bind_wrap

// 🔥 The bind statement lives inside a module so every simulator elaborates it
// 🔥 (ModelSim may ignore a bind that is alone in a compilation unit).
module alu_mul_bind;
bind cv32e40p_core alu_mul_bind_wrap alu_mul_bind_i (
    .clk               (clk),                  // 🔥 gated core clock (ID/EX registers)
    .rst_n             (rst_ni),
    .id_valid          (id_valid),
    .id_instr          (instr_rdata_id),
    .ex_mult_en        (mult_en_ex),
    .ex_mult_operand_a (mult_operand_a_ex),
    .ex_mult_operand_b (mult_operand_b_ex),
    .ex_alu_en         (alu_en_ex),
    .ex_alu_operand_a  (alu_operand_a_ex),
    .ex_alu_operand_b  (alu_operand_b_ex),
    .ex_valid          (ex_valid),
    .ex_wb_we          (regfile_alu_we_fw),
    .ex_wb_waddr       (regfile_alu_waddr_fw),
    .ex_wb_wdata       (regfile_alu_wdata_fw)
);
endmodule : alu_mul_bind
