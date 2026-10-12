class virtual_seq_random extends virtual_seq_base;
    `uvm_object_utils(virtual_seq_random)

    function new(string name = "virtual_seq_random");
        super.new(name);
    endfunction : new

    virtual task body();
        instruction_seq_random instr_seq_rand;
        data_seq_random         data_seq_rand;
        reset_seq               rst_seq;
        int                     txns_remaining;

        `uvm_info(get_type_name(), "virtual_seq_random: Inside Body", UVM_LOW);

        txns_remaining = no_txn;

        fork
            begin
                rst_seq = reset_seq::type_id::create("rst_seq");
                rst_seq.start(p_sequencer.rst_sqr);
            end
            begin
                forever begin
                    fork
                        fork
                            begin
                                instr_seq_rand = instruction_seq_random::type_id::create("instr_seq_rand");
                                instr_seq_rand.num_txns = txns_remaining;
                                instr_seq_rand.start(p_sequencer.instr_sqr);
                            end
                            begin
                                data_seq_rand = data_seq_random::type_id::create("data_seq_rand");
                                data_seq_rand.num_txns = txns_remaining;
                                data_seq_rand.start(p_sequencer.data_sqr);
                            end
                        join
                        begin
                            cfg.wait_rst_start();
                        end
                    join_any

                    disable fork;

                    if (cfg.as_rst.is_on()) begin
                        txns_remaining = txns_remaining - instr_seq_rand.completed_txns;

                        `uvm_info(get_type_name(), $sformatf("Reset interrupted! Completed %0d txns. Remaining: %0d",
                                  instr_seq_rand.completed_txns, txns_remaining), UVM_LOW);

                        if (txns_remaining <= 0) begin
                            `uvm_info(get_type_name(), "Target txns reached despite reset. Exiting.", UVM_LOW);
                            break;
                        end
                        cfg.wait_rst_end();
                        `uvm_info(get_type_name(), "Reset cleared. Resuming remaining txns...", UVM_LOW);
                    end else begin
                        `uvm_info(get_type_name(), "All random transactions completed successfully!", UVM_LOW);
                        break;
                    end
                end
            end
        join_any

        disable fork;
    endtask : body

endclass : virtual_seq_random
