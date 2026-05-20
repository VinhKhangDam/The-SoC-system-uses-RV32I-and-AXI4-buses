// ============================================================
// cpu_agent.sv — PASSIVE, observe-only
// ============================================================
class cpu_agent extends uvm_agent;
  `uvm_component_utils(cpu_agent)
  cpu_monitor monitor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "*", "is_active", UVM_PASSIVE);
    monitor = cpu_monitor::type_id::create("monitor", this);
  endfunction

endclass

