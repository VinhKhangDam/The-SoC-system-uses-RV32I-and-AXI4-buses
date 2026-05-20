class spi_test extends uvm_test;
  `uvm_component_utils(spi_test)

  spi_env env;
  virtual clk_rst_inf cr_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = spi_env::type_id::create("env", this);

    if (!uvm_config_db#(virtual clk_rst_inf)::get(this, "", "cr_vif", cr_vif))
      `uvm_fatal("SPI_TEST", "Cannot get cr_vif")
  endfunction

  task run_phase(uvm_phase phase);
    spi_sequence seq;

    phase.raise_objection(this);
    wait (cr_vif.rstn == 1);
    repeat (2) @(posedge cr_vif.clk);

    seq = spi_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);

    repeat (200) @(posedge cr_vif.clk);
    phase.drop_objection(this);
  endtask
endclass


