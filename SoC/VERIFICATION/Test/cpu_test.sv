// ============================================================
// cpu_test.sv — THE test
// Loads instr.mem into IRAM, pulses reset, waits for CPU
// to finish (timeout), then scoreboard check_phase runs.
// ============================================================
class cpu_test extends uvm_test;
    `uvm_component_utils(cpu_test)
 
    cpu_env             env;
    virtual clk_rst_inf vif_cr;
 
    // Sim timeout: override with +timeout_ns=<N>
    int unsigned timeout_ns = 100_000;
    // IRAM .mem file: override with +instr_mem=<path>
    string instr_mem_file = "instr.mem";
 
    function new(string name = "cpu_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
 
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = cpu_env::type_id::create("env", this);
        void'($value$plusargs("timeout_ns=%0d",  timeout_ns));
        void'($value$plusargs("instr_mem=%s",    instr_mem_file));
    endfunction
 
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        if (!uvm_config_db #(virtual clk_rst_inf)::get(this, "", "vif_cr", vif_cr))
            `uvm_fatal("TEST", "Cannot get vif_cr")

        // IRAM already loaded by Questasim via INIT_FILE="instr.mem"
        // Just pulse reset to start the CPU
        vif_cr.rstn = 1'b0;
        repeat(5) @(posedge vif_cr.clk);
        @(posedge vif_cr.clk);
        vif_cr.rstn = 1'b1;
        `uvm_info("TEST", "Reset released — CPU executing from IRAM", UVM_LOW)

        // Wait for program to finish
        #(timeout_ns * 1ns);
        repeat(10) @(posedge vif_cr.clk);

        phase.drop_objection(this);
    endtask
 
endclass