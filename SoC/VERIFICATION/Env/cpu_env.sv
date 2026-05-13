// ============================================================
// cpu_env.sv
// ============================================================
class cpu_env extends uvm_env;
    `uvm_component_utils(cpu_env)
    cpu_agent      agent;
    cpu_scoreboard scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = cpu_agent::type_id::create("agent",      this);
        scoreboard = cpu_scoreboard::type_id::create("scoreboard", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        // Monitor WB port → Scoreboard WB import
        agent.monitor.wb_port.connect(scoreboard.wb_export);
        // FIX: Monitor AXI port → Scoreboard AXI import (was unconnected before)
        agent.monitor.axi_port.connect(scoreboard.axi_export);
    endfunction

endclass