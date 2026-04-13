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
    `include "axi_simple_sequence.sv"
    `include "axi_multi_slave_sequence.sv"
    `include "base_test.sv"
endpackage
