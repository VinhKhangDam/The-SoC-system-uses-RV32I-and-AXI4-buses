package soc_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "axi_transaction.sv"
    `include "axi_sequencer.sv"
    `include "axi_monitor.sv"
    `include "axi_driver.sv"
    `include "axi_agent.sv"
    `include "axi_scoreboard.sv"
    `include "axi_coverage.sv"
    `include "axi_env.sv"
    `include "axi_random_wr_rd.sv"
    `include "axi_random_wr_rd_test.sv"
endpackage
