class timer_env extends uvm_env;
  `uvm_component_utils(timer_env)

  uvm_sequencer #(timer_transaction) sequencer;
  timer_driver driver;
  timer_monitor monitor;
  timer_scoreboard scoreboard;
  timer_coverage coverage;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction  // new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = uvm_sequencer#(timer_transaction)::type_id::create("sequencer", this);
    driver = timer_driver::type_id::create("driver", this);
    monitor = timer_monitor::type_id::create("monitor", this);
    scoreboard = timer_scoreboard::type_id::create("scoreboard", this);
    coverage = timer_coverage::type_id::create("coverage", this);
  endfunction  // build_phase

  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
    monitor.ap.connect(scoreboard.imp);
    monitor.ap.connect(coverage.analysis_export);
  endfunction  // connect_phase

endclass  // timer_env
