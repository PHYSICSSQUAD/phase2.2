module instruction_sva (instruction_if.ASSERT intf, input logic rst_n);

    // -------------------------------------------------------------------------
    // Reset
    // -------------------------------------------------------------------------
    always_comb begin
        if(!rst_n)
            ia_out : assert final(intf.instr_req_o == 0);
    end

    property p_reset;
        @(posedge intf.clk) !rst_n |=> (intf.instr_req_o == 0);
    endproperty
    a_reset : assert property (p_reset);
    c_reset : cover  property (p_reset);

    // -------------------------------------------------------------------------
    // Protocol Handshake
    // -------------------------------------------------------------------------

    // req must remain high until gnt is returned
    property p_instr_req_stability;
        @(posedge intf.clk) disable iff (!rst_n)
        intf.instr_req_o && !intf.instr_gnt_i |=> intf.instr_req_o;
    endproperty
    a_instr_req_stability: assert property (p_instr_req_stability);
    c_instr_req_stability: cover  property (p_instr_req_stability);

    // Fetch address must remain stable while req is waiting for gnt
    property p_instr_addr_stability;
        @(posedge intf.clk) disable iff (!rst_n)
        intf.instr_req_o && !intf.instr_gnt_i |=> $stable(intf.instr_addr_o);
    endproperty
    a_instr_addr_stability: assert property (p_instr_addr_stability);
    c_instr_addr_stability: cover property (p_instr_addr_stability);

    // Every granted request must eventually yield an rvalid response
    property p_instr_gnt_to_rvalid;
        @(posedge intf.clk) disable iff (!rst_n)
        intf.instr_req_o && intf.instr_gnt_i |-> ##[1:$] intf.instr_rvalid_i;
    endproperty
    a_instr_gnt_to_rvalid: assert property (p_instr_gnt_to_rvalid);
    c_instr_gnt_to_rvalid: cover  property (p_instr_gnt_to_rvalid);

    // -------------------------------------------------------------------------
    // ISA Constraints
    // -------------------------------------------------------------------------

    // instruction fetch address must be 4-byte aligned
    property p_instr_addr_aligned;
        @(posedge intf.clk) disable iff (!rst_n)
        intf.instr_req_o |-> (intf.instr_addr_o[1:0] == 2'b00);
    endproperty
    a_instr_addr_aligned: assert property (p_instr_addr_aligned);
    c_instr_addr_aligned: cover  property (p_instr_addr_aligned);

    // -------------------------------------------------------------------------
    // Signal Validity Checks
    // -------------------------------------------------------------------------

    // Unknown Checks
    property p_instr_no_x_control;
        @(posedge intf.clk) disable iff (!rst_n)
        !$isunknown({intf.instr_req_o, intf.instr_gnt_i, intf.instr_rvalid_i});
    endproperty
    a_instr_no_x_control: assert property (p_instr_no_x_control);
    c_instr_no_x_control: cover  property (p_instr_no_x_control);

    property p_instr_no_x_rdata;
        @(posedge intf.clk) disable iff (!rst_n)
        intf.instr_rvalid_i |-> !$isunknown(intf.instr_rdata_i);
    endproperty
    a_instr_no_x_rdata: assert property (p_instr_no_x_rdata);
    c_instr_no_x_rdata: cover  property (p_instr_no_x_rdata);

endmodule : instruction_sva
