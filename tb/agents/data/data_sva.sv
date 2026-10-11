module data_sva (data_if.ASSERT intf, input logic rst_n);

    // -------------------------------------------------------------------------
    // Reset
    // -------------------------------------------------------------------------
    always_comb begin
        if(!rst_n)
            ia_out : assert final(intf.data_req_o == 0);
    end

    property p_reset;
        @(posedge intf.clk) !rst_n |=> (intf.data_req_o == 0);
    endproperty
    a_reset : assert property (p_reset);
    c_reset : cover  property (p_reset);

    // -------------------------------------------------------------------------
    // Protocol Handshake Assertions
    // -------------------------------------------------------------------------

    // Every granted request must receive a response
    property p_data_gnt_to_rvalid;
        @(posedge intf.clk) disable iff (!rst_n)
        intf.data_req_o && intf.data_gnt_i |-> ##[1:$] intf.data_rvalid_i;
    endproperty
    a_data_gnt_to_rvalid: assert property (p_data_gnt_to_rvalid)
        else $error("[SVA] Data request granted without eventual data_rvalid_i.");

    // -------------------------------------------------------------------------
    // Byte Enable & Address Alignment Rules
    // -------------------------------------------------------------------------

    // Byte enable must be non-zero during active request
    property p_data_be_not_zero;
        @(posedge intf.clk) disable iff (!rst_n)
        intf.data_req_o |-> (intf.data_be_o != 4'b0000);
    endproperty
    a_data_be_not_zero: assert property (p_data_be_not_zero);
    c_data_be_not_zero: cover  property (p_data_be_not_zero);

    // Byte enables must form contiguous bytes
    property p_data_be_valid_pattern;
        @(posedge intf.clk) disable iff (!rst_n)
        intf.data_req_o |-> intf.data_be_o inside {
            4'b0001, 4'b0010, 4'b0100, 4'b1000, // 1-byte
            4'b0011, 4'b1100,                   // 2-byte
            4'b1111                             // 4-byte
        };
    endproperty
    // a_data_be_valid_pattern: assert property (p_data_be_valid_pattern);
    // c_data_be_valid_pattern: cover  property (p_data_be_valid_pattern);

    // Half-word Alignment Check
    property p_data_halfword_alignment;
        @(posedge intf.clk) disable iff (!rst_n)
        intf.data_req_o && (intf.data_be_o inside {4'b0011, 4'b1100}) |-> (intf.data_addr_o[0] == 1'b0);
    endproperty
    a_data_halfword_alignment: assert property (p_data_halfword_alignment);
    c_data_halfword_alignment: cover  property (p_data_halfword_alignment);

    // Word Alignment Check
    property p_data_word_alignment;
        @(posedge intf.clk) disable iff (!rst_n)
        intf.data_req_o && (intf.data_be_o == 4'b1111) |-> (intf.data_addr_o[1:0] == 2'b00);
    endproperty
    a_data_word_alignment: assert property (p_data_word_alignment);
    c_data_word_alignment: cover  property (p_data_word_alignment);

endmodule : data_sva
