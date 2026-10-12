class instruction_monitor extends monitor_base#(instruction_seq_item);
    `uvm_component_utils(instruction_monitor)

    // vif
    virtual instruction_if.MONITOR vif;
    mailbox#(instruction_seq_item) mbx;

    function new(string name = "instruction_monitor", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mbx = new();
    endfunction : build_phase

    // Implement the specific sampling logic
    protected virtual task collect_txn();
        @(vif.mon_cb);
        if (vif.mon_cb.instr_req_o && vif.mon_cb.instr_gnt_i) begin
            instruction_seq_item item = instruction_seq_item::type_id::create("item");
            item.addr = vif.mon_cb.instr_addr_o;
            mbx.put(item);
        end

        // 2. Match with Completed Response Phase
        if (vif.mon_cb.instr_rvalid_i) begin
            instruction_seq_item full_item = instruction_seq_item::type_id::create("full_item");
            mbx.get(full_item);
            full_item.data = vif.mon_cb.instr_rdata_i;
            `uvm_info("FETCH_MON", $sformatf("Observed Fetch @ Addr: 0x%0h | Instr: 0x%0h", full_item.addr, full_item.data), UVM_NONE)

            // Broadcast completed instruction fetch to Predictor && Coverage Collector
            ap.write(full_item);
        end
    endtask : collect_txn

endclass : instruction_monitor
