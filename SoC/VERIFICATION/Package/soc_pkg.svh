package soc_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ---- Core transaction (must be first) ----
  `include "axi_transaction.sv"
  `include "cpu_transaction.sv"

  // ---- Infrastructure ----
  `include "axi_sequencer.sv"
  `include "axi_monitor.sv"
  `include "cpu_monitor.sv"
  `include "axi_driver.sv"
  `include "axi_agent.sv"
  `include "cpu_agent.sv"

  // ---- Scoreboards (before env — env references them) ----
  `include "axi_scoreboard.sv"
  `include "cpu_scoreboard.sv"  // put in Scoreboard/ folder

  // ---- Coverage ----
  `include "axi_coverage.sv"
  `include "cpu_coverage.sv"

  // ---- Environments ----
  `include "axi_env.sv"
  `include "cpu_env.sv"  // put in Env/ folder

  // ---- UVM MASTER sequences + tests ----
  //`include "axi_write_sequence.sv"
  //`include "axi_read_sequence.sv"
  `include "axi_random_wr_rd.sv"
  `include "axi_multi_slaves_sequence.sv"
  //`include "axi_write_test.sv"
  //`include "axi_read_test.sv"
  `include "axi_random_wr_rd_test.sv"
  `include "axi_multi_slaves_test.sv"

  // ---- CPU MASTER test ----
  `include "cpu_test.sv"  // put in Test/ folder

endpackage
