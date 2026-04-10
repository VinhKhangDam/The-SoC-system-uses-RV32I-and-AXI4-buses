package soc_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // 1. Transaction (Gốc)
    `include "axi_transaction.sv"

    // 2. Các thành phần cơ bản (Level 1)
    `include "axi_sequencer.sv"
    `include "axi_monitor.sv"
    `include "axi_driver.sv"

    // 3. Agent (Chứa Sequencer, Monitor, Driver)
    `include "axi_agent.sv"
    
	`include "axi_scoreboard.sv"

    // 4. Env (Chứa Agent)
    `include "axi_env.sv"

    // 5. Sequence và Test (Cấp cao nhất)
    `include "axi_simple_sequence.sv"
    `include "base_test.sv"
endpackage
