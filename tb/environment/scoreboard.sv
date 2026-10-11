
class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    // data exports
    uvm_analysis_export #(mon_item) data_act_exp;
    uvm_analysis_export #(mon_item) data_exp_exp;

    // data fifos
    uvm_tlm_analysis_fifo #(mon_item) data_act_fifo;
    uvm_tlm_analysis_fifo #(mon_item) data_exp_fifo;

    // reset imp
    uvm_analysis_imp_rst #(reset_item, scoreboard) rst_imp;

    // vars
    int correct, error;

    // Add a UVM event to synchronize the reset
    uvm_event rst_event;

    function new(string name = "scoreboard", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        data_act_exp = new("data_act_exp", this);
        data_exp_exp = new("data_exp_exp", this);

        data_act_fifo = new("data_act_fifo", this);
        data_exp_fifo = new("data_exp_fifo", this);

        rst_imp   = new("rst_imp", this);
        rst_event = new("rst_event");
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        data_act_exp.connect(data_act_fifo.analysis_export);
        data_exp_exp.connect(data_exp_fifo.analysis_export);
    endfunction

    // reset handler
    virtual function void write_rst(reset_item rst_item);
        if (rst_item.reset_state == 1'b0) begin
            data_act_fifo.flush();
            data_exp_fifo.flush();
            rst_event.trigger();
            `uvm_info("SCB_RST", "Scoreboard pipeline FIFOs flushed due to reset", UVM_HIGH)
        end
    endfunction

    // compare
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            data_seq_item data_act_item, data_exp_item;
            fork
                fork
                    begin
                        // Predictor produces expected item earlier; grab expected first
                        data_exp_fifo.get(data_exp_item);
                        data_act_fifo.get(data_act_item);

                        // Compare
                        if (data_exp_item.compare(data_act_item)) begin
                            correct++;
                            `uvm_info("DATA_SCB_PASS", $sformatf("Match! %0s  vs  %0s", data_act_item.convert2string(), data_exp_item.convert2string()), UVM_FULL)
                        end
                        else begin
                            error++;
                            `uvm_error("DATA_SCB_FAIL", $sformatf("Mismatch on %0s: \nExpected C: %0d \nActual C: %0d", data_act_item.get_full_name(), data_exp_item.convert2string(), data_act_item.convert2string()))
                        end
                    end
                    // begin

                    // end
                join
                begin
                    rst_event.wait_trigger();
                end
            join_any

            disable fork;
        end
    endtask : run_phase

endclass : scoreboard
