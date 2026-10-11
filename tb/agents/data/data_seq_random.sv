class data_seq_random extends uvm_sequence#(data_seq_item);
    `uvm_object_utils(data_seq_random)
    `uvm_declare_p_sequencer(data_sequencer)

    bit [31:0] mem [bit [31:0]];
    int num_txns;
    int completed_txns;

    function new(string name = "data_seq_random");
        super.new(name);
    endfunction : new

    virtual task body();
        data_seq_item req_item;
        data_seq_item rsp_item;
        completed_txns = 0;

        repeat(num_txns) begin
            p_sequencer.data_req_fifo.get(req_item);

            rsp_item = data_seq_item::type_id::create("rsp_item");
            rsp_item.addr  = req_item.addr;
            rsp_item.we    = req_item.we;
            rsp_item.be    = req_item.be;
            rsp_item.wdata = req_item.wdata;

            if (req_item.we) begin
                logic [31:0] current_val = mem.exists(req_item.addr) ? mem[req_item.addr] : 32'h0;
                mem[req_item.addr] = apply_be_mask(current_val, req_item.wdata, req_item.be);
                rsp_item.rdata = 32'h0;
                `uvm_info("REACTIVE_SEQ",
                    $sformatf("STORE @ Addr: 0x%0h = 0x%0h (BE: 4'b%04b)", req_item.addr, mem[req_item.addr], req_item.be),
                    UVM_NONE)
            end else begin
                rsp_item.rdata = mem.exists(req_item.addr) ? mem[req_item.addr] : 32'h0;
                `uvm_info("REACTIVE_SEQ",
                    $sformatf("LOAD @ Addr: 0x%0h = 0x%0h", req_item.addr, rsp_item.rdata),
                    UVM_NONE)
            end

            start_item(rsp_item);
                if (!rsp_item.randomize()) begin
                    `uvm_error("REACTIVE_SEQ", "Randomization failed!")
                end
            finish_item(rsp_item);

            completed_txns++;
        end
    endtask : body

endclass : data_seq_random
