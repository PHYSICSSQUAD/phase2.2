// 🔥 NEW (MUL/DIV integration) - ALU_MUL interface, copied from mul_env/alu_mul_if.sv.
// 🔥 Only change vs. mul_env: no `timescale (it would leak into the RTL compile).
// 🔥 All signals are inputs: the interface only OBSERVES the EX stage (passive agent).
interface alu_mul_if (
    input logic        clk,
    input logic        rst_n,

    input logic        id_valid,           // 🔥 ID stage hands its instruction to EX
    input logic [31:0] id_instr,           // 🔥 instruction word in ID

    input logic        ex_mult_en,         // 🔥 multiplier instruction in EX
    input logic [31:0] ex_mult_operand_a,  // 🔥 MUL rs1 value
    input logic [31:0] ex_mult_operand_b,  // 🔥 MUL rs2 value
    input logic        ex_alu_en,          // 🔥 ALU instruction in EX (DIV/REM run in the ALU)
    input logic [31:0] ex_alu_operand_a,   // 🔥 DIV operand a (= rs2, decoder swaps them)
    input logic [31:0] ex_alu_operand_b,   // 🔥 DIV operand b (= rs1)
    input logic        ex_valid,           // 🔥 EX instruction completes this cycle
    input logic        ex_wb_we,           // 🔥 EX write-back enable
    input logic [5:0]  ex_wb_waddr,        // 🔥 EX write-back address
    input logic [31:0] ex_wb_wdata         // 🔥 EX write-back data (the result)
);

    // 🔥 Monitor clocking block: sample just before each posedge.
    clocking mon_cb @(posedge clk);
        default input #1step;
        input rst_n;
        input id_valid, id_instr;
        input ex_mult_en, ex_mult_operand_a, ex_mult_operand_b;
        input ex_alu_en, ex_alu_operand_a, ex_alu_operand_b;
        input ex_valid;
        input ex_wb_we, ex_wb_waddr, ex_wb_wdata;
    endclocking

    // 🔥 Monitor modport (same idea as instruction_if.MONITOR)
    modport MON (clocking mon_cb, input clk, input rst_n);

endinterface : alu_mul_if
