class data_monitor extends monitor_base#(data_seq_item);
    `uvm_component_utils(data_monitor)

    // ports
    uvm_analysis_port#(data_seq_item) req_ap;

    // vif
    virtual data_if.MONITOR vif;
    mailbox#(data_seq_item) mbx;

    function new(string name = "data_monitor", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        req_ap = new("req_ap", this);
        mbx = new();
    endfunction : build_phase

    // Implement the specific sampling logic
    protected virtual task collect_txn();
        @(vif.mon_cb);
        if (vif.mon_cb.data_req_o && vif.mon_cb.data_gnt_i) begin
            data_seq_item item = data_seq_item::type_id::create("item");
            item.addr  = vif.mon_cb.data_addr_o;
            item.we    = vif.mon_cb.data_we_o;
            item.be    = vif.mon_cb.data_be_o;
            item.wdata = vif.mon_cb.data_wdata_o;

            mbx.put(item);
            // broadcast to sqr
            req_ap.write(item);
            `uvm_info("DATA_MON", $sformatf("Observed DATA %s", item.convert2string()), UVM_NONE)
        end

        // 2. Match with Completed Response Phase
        if (vif.mon_cb.data_rvalid_i) begin
            data_seq_item full_item = data_seq_item::type_id::create("full_item");
            mbx.get(full_item);
            full_item.rdata = vif.mon_cb.data_rdata_i;
            `uvm_info("DATA_MON", $sformatf("Full Observed DATA %s", full_item.convert2string()), UVM_NONE)

            // Broadcast completed data fetch to Predictor && Coverage Collector
            ap.write(full_item);
        end
    endtask : collect_txn

endclass : data_monitor
