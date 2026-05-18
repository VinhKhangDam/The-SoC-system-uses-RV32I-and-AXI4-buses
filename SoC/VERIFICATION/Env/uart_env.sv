class uart_env extends uvm_env;
   `uvm_component_utils(uart_env)

   uvm_sequencer #(uart_transaction) sequencer;
   uart_driver driver;
   uart_monitor monitor;
   uart_scoreboard scoreboard;
   uart_coverage coverage;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      sequencer  = uvm_sequencer #(uart_transaction)::type_id::create("sequencer", this);
      driver     = uart_driver::type_id::create("driver", this);
      monitor    = uart_monitor::type_id::create("monitor", this);
      scoreboard = uart_scoreboard::type_id::create("scoreboard", this);
      coverage   = uart_coverage::type_id::create("coverage", this);
   endfunction

   function void connect_phase(uvm_phase phase);
      driver.seq_item_port.connect(sequencer.seq_item_export);
      driver.ap.connect(scoreboard.imp);
      driver.ap.connect(coverage.analysis_export);
      monitor.ap.connect(scoreboard.imp);
      monitor.ap.connect(coverage.analysis_export);
   endfunction
endclass
