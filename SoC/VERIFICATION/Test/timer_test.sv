class timer_test extends uvm_test;
  `uvm_component_utils(timer_test)

  timer_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction  // new

  function void build_phase(uvm_phase phase);
    env = timer_env::type_id::create("env", this);
  endfunction  // build_phase

  task run_phase(uvm_phase phase);
    timer_sequence seq;

    phase.raise_objection(this);

    seq = timer_sequence::type_id::create("seq");
    seq.start(env.sequencer);

    repeat (50) @(posedge env.driver.vif.clk);
    phase.drop_objection(this);

  endtask  // run_phase

endclass  // timer_test
