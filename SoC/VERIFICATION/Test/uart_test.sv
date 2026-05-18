class uart_test extends uvm_test;
   `uvm_component_utils(uart_test)

   uart_env env;
   virtual clk_rst_inf vif_cr;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction // new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = uart_env::type_id::create("env", this);

      if (!uvm_config_db #(virtual clk_rst_inf)::get(this, "", "vif_cr", vif_cr))
        `uvm_fatal("UART_TEST", "Cannot get vif_cr")
   endfunction // build_phase

   task run_phase(uvm_phase phase);
      uart_sequence seq;

      phase.raise_objection(this);

      wait(vif_cr.rstn == 1'b1);

      seq = uart_sequence::type_id::create("seq");
      seq.start(env.sequencer);

      repeat(200) @(posedge vif_cr.clk);

      phase.drop_objection(this);
   endtask // run_phase
endclass // uart_test
