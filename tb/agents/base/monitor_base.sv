virtual class monitor_base#(type T) extends uvm_monitor implements reset_handler;

    // variables
    protected agent_config_base cfg;

    // ports
    uvm_analysis_port#(T) ap;

    // reset process for collect txns
    protected process process_collect_txns;

    function new(string name = "monitor_base", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            wait_rst_end();

            // fork to guard the run_phase from process kill
            fork
                begin
                    process_collect_txns = process::self();
                    forever begin
                        collect_txn();
                    end
                end
            join_none

            wait_rst_start();
            handle_reset(phase);
        end
    endtask : run_phase

    // Implement the specific sampling logic
    pure protected virtual task collect_txn();

    virtual function void handle_reset(uvm_phase phase);
        if (process_collect_txns != null) begin
            process_collect_txns.kill();
            process_collect_txns = null;
        end
    endfunction : handle_reset

    virtual function void set_cfg(agent_config_base c);
        cfg = c;
    endfunction

    virtual function agent_config_base get_cfg();
        return cfg;
    endfunction

    virtual task wait_rst_start();
        cfg.wait_rst_start();
    endtask : wait_rst_start

    virtual task wait_rst_end();
        cfg.wait_rst_end();
    endtask : wait_rst_end
endclass : monitor_base
