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
    `include "axi_write_sequence.sv"
    `include "axi_read_sequence.sv"
    `include "axi_multi_slaves_sequence.sv"
    `include "axi_random_wr_rd_test.sv"
    `include "axi_write_test.sv"
    `include "axi_read_test.sv"
    `include "axi_multi_slaves_test.sv"
endpackage
