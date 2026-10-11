import shared_pkg::*;

interface debug_if (input logic clk);
    bit [31:0] irq_i;
    bit [ 4:0] irq_id_o;
    bit        irq_ack_o;
    bit        debug_req_i;
    bit        debug_havereset_o;
    bit        debug_running_o;
    bit        debug_halted_o;

    // clocking blocks
    // Driver
    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output irq_i;
        output debug_req_i;
        input  irq_id_o;
        input  irq_ack_o;
        input  debug_havereset_o;
        input  debug_running_o;
        input  debug_halted_o;
    endclocking

    // modports
    // Driver
    modport DRIVER (
        clocking drv_cb,
        output irq_i, debug_req_i
    );

endinterface
