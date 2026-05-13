// ============================================================
// cpu_test.sv — THE test
// Loads instr.mem into IRAM, pulses reset, waits for CPU
// to finish (timeout), then scoreboard check_phase runs.
// ============================================================
class cpu_test extends uvm_test;
    `uvm_component_utils(cpu_test)
 
    cpu_env             env;
    virtual clk_rst_inf vif_cr;
    virtual cpu_monitor_inf cpu_vif;
 
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
        int unsigned instr_count;
        int fd;
        string line;
        phase.raise_objection(this);

        if (!uvm_config_db #(virtual clk_rst_inf)::get(this, "", "vif_cr", vif_cr))
            `uvm_fatal("TEST", "Cannot get vif_cr")

        // Get the monitor interface to watch PC
        if (!uvm_config_db #(virtual cpu_monitor_inf)::get(this, "", "cpu_vif", cpu_vif))
            `uvm_fatal("TEST", "Cannot get cpu_vif")

        // Count instructions in instr.mem to know when PC is past the end
        instr_count = 0;
        fd = $fopen(instr_mem_file, "r");
        if (fd == 0)
            `uvm_fatal("TEST", $sformatf("Cannot open %s", instr_mem_file))
        while (!$feof(fd)) begin
            void'($fgets(line, fd));
            if (line.len() > 1 && line[0] != "/")
                instr_count++;
        end
        $fclose(fd);

        `uvm_info("TEST", $sformatf("Program has %0d instructions, end PC = %h",
            instr_count, instr_count * 4), UVM_LOW)

        // Pulse reset
        vif_cr.rstn = 1'b0;
        repeat(5) @(posedge vif_cr.clk);
        @(posedge vif_cr.clk);
        vif_cr.rstn = 1'b1;
        `uvm_info("TEST", "Reset released — CPU executing from IRAM", UVM_LOW)

        // Wait until PC goes past last instruction OR timeout
        fork
            begin
                // PC-based termination
                @(posedge vif_cr.clk);
                forever begin
                    @(posedge vif_cr.clk);
                    if (cpu_vif.mon_cb.PcF >= (instr_count * 4)) begin
                        `uvm_info("TEST",
                            $sformatf("PC=%h reached end of program — stopping",
                                cpu_vif.mon_cb.PcF), UVM_LOW)
                        break;
                    end
                end
            end
            begin
                // Safety timeout fallback
                #(timeout_ns * 1ns);
                `uvm_warning("TEST", "Timeout reached before PC walked off end")
            end
        join_any
        disable fork;

        // Allow pipeline to drain (4 stages = 4 extra cycles)
        repeat(10) @(posedge vif_cr.clk);

        phase.drop_objection(this);
    endtask
 
endclass