interface data_if (input logic clk);

    bit [31:0] data_addr_o;
    bit        data_req_o;
    bit        data_gnt_i;
    bit        data_we_o;
    bit [3 :0] data_be_o;
    bit [31:0] data_wdata_o;
    bit        data_rvalid_i;
    bit [31:0] data_rdata_i;

    // clocking blocks
    // Driver
    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output data_gnt_i;
        output data_rvalid_i;
        output data_rdata_i;
        input  data_addr_o;
        input  data_req_o;
        input  data_we_o;
        input  data_be_o;
        input  data_wdata_o;
    endclocking

    // Monitor
    clocking mon_cb @(posedge clk);
        default input #1step;
        input data_gnt_i;
        input data_rvalid_i;
        input data_rdata_i;
        input data_addr_o;
        input data_req_o;
        input data_we_o;
        input data_be_o;
        input data_wdata_o;
    endclocking

    // modports
    // Driver 
    modport DRIVER (
        clocking drv_cb,
        output data_gnt_i, data_rvalid_i, data_rdata_i
    );
    // Monitor 
    modport MONITOR (
        clocking mon_cb
    );

    // SVA
    modport ASSERT (    
        input clk,
        input data_gnt_i,
        input data_rvalid_i,
        input data_rdata_i,
        input data_addr_o,
        input data_req_o,
        input data_we_o,
        input data_be_o,
        input data_wdata_o
    );

endinterface