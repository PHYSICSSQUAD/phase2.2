import shared_pkg::*;

interface instruction_if (input logic clk);

    bit [31:0] instr_addr_o;
    bit        instr_req_o;
    bit        instr_gnt_i;
    bit        instr_rvalid_i;
    instr_t    instr_rdata_i;

    // clocking blocks
    // Driver
    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output instr_gnt_i;
        output instr_rvalid_i;
        output instr_rdata_i;
        input  instr_addr_o;
        input  instr_req_o;
    endclocking

    // Monitor
    clocking mon_cb @(posedge clk);
        default input #1step;
        input instr_gnt_i;
        input instr_rvalid_i;
        input instr_rdata_i;
        input instr_addr_o;
        input instr_req_o;
    endclocking

    // modports
    // Driver
    modport DRIVER (
        clocking drv_cb,
        output instr_gnt_i, instr_rvalid_i, instr_rdata_i
    );
    // Monitor
    modport MONITOR (
        clocking mon_cb
    );

    // SVA
    modport ASSERT (
        input clk,
        input instr_gnt_i,
        input instr_rvalid_i,
        input instr_rdata_i,
        input instr_addr_o,
        input instr_req_o
    );

endinterface
