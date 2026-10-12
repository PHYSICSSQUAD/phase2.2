class reset_monitor extends uvm_monitor;
	`uvm_component_utils(reset_monitor)

	// ports
	uvm_analysis_port#(reset_item) ap;

	// variables
	virtual reset_if vif;

	// UVM Events for instant asynchronous broadcasting
	uvm_event reset_assert_ev;
	uvm_event reset_deassert_ev;

	// Constructor
	function new(string name = "reset_monitor", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
	    super.build_phase(phase);
		ap = new("ap", this);

		// Get handles to the global events
	    reset_assert_ev   = uvm_event_pool::get_global("async_reset_assert");
	    reset_deassert_ev = uvm_event_pool::get_global("async_reset_deassert");
	endfunction

	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		fork
			sync_scoreboard_feed();
			async_agent_alert();
		join
   	endtask : run_phase

	extern virtual task sync_scoreboard_feed();

	extern virtual task async_agent_alert();

endclass : reset_monitor

// --------------------------------------------------------

task reset_monitor::sync_scoreboard_feed();
    reset_item item;

    forever begin
		@(posedge vif.clk);
		item = reset_item::type_id::create("item");
		item.reset_state = vif.rst_n;

		ap.write(item);
    end
  endtask

// --------------------------------------------------------

task reset_monitor::async_agent_alert();
	forever begin
		@(vif.rst_n);

		if (vif.rst_n == 1'b0) begin
			`uvm_info("RST_MON", "Async Reset ASSERTED instantly!", UVM_HIGH)
			reset_assert_ev.trigger();
			reset_deassert_ev.reset();
		end
		else begin
			`uvm_info("RST_MON", "Async Reset DE-ASSERTED instantly!", UVM_HIGH)
			reset_deassert_ev.trigger();
			reset_assert_ev.reset();
		end
	end
endtask
