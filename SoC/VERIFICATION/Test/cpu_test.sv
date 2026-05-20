// ============================================================
// cpu_test.sv - CPU program test
// Loads instr.mem into IRAM, pulses reset, waits for CPU
// to execute the loaded program, then scoreboard check_phase runs.
// ============================================================
class cpu_test extends uvm_test;
  `uvm_component_utils(cpu_test)

  cpu_env                 env;
  virtual clk_rst_inf     vif_cr;
  virtual cpu_monitor_inf cpu_vif;

  // Sim timeout: override with +timeout_ns=<N>
  int unsigned            timeout_ns     = 100_000;
  // IRAM .mem file: override with +instr_mem=<path>
  string                  instr_mem_file = "instr.mem";

  function new(string name = "cpu_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = cpu_env::type_id::create("env", this);
    void'($value$plusargs("timeout_ns=%0d", timeout_ns));
    void'($value$plusargs("instr_mem=%s", instr_mem_file));
  endfunction

  virtual task run_phase(uvm_phase phase);
    int unsigned instr_count;
    int fd;
    string line;

    phase.raise_objection(this);

    if (!uvm_config_db#(virtual clk_rst_inf)::get(this, "", "vif_cr", vif_cr))
      `uvm_fatal("TEST", "Cannot get vif_cr")

    if (!uvm_config_db#(virtual cpu_monitor_inf)::get(this, "", "cpu_vif", cpu_vif))
      `uvm_fatal("TEST", "Cannot get cpu_vif")

    instr_count = 0;
    fd = $fopen(instr_mem_file, "r");
    if (fd == 0) `uvm_fatal("TEST", $sformatf("Cannot open %s", instr_mem_file))

    while (!$feof(
        fd
    )) begin
      void'($fgets(line, fd));
      if (line.len() > 1 && line[0] != "/") instr_count++;
    end
    $fclose(fd);

    `uvm_info("TEST", $sformatf("Program has %0d instructions, end PC = %h", instr_count,
                                instr_count * 4), UVM_LOW)

    vif_cr.rstn = 1'b0;
    repeat (5) @(posedge vif_cr.clk);
    @(posedge vif_cr.clk);
    vif_cr.rstn = 1'b1;
    `uvm_info("TEST", "Reset released - CPU executing from IRAM", UVM_LOW)

    fork
      begin
        @(posedge vif_cr.clk);
        forever begin
          @(posedge vif_cr.clk);
          if (cpu_vif.mon_cb.PcF >= (instr_count * 4)) begin
            `uvm_info("TEST", $sformatf("PC=%h reached first address past loaded program - ending",
                                        cpu_vif.mon_cb.PcF), UVM_LOW)
            break;
          end
        end
      end
      begin
        #(timeout_ns * 1ns);
        `uvm_warning("TEST", "Timeout reached before PC walked off end")
      end
    join_any
    disable fork;

    // Let the last fetched instructions reach WB before scoreboard check_phase.
    // CPU SVA is gated after the loaded program, so these drain cycles are safe.
    repeat (30) @(posedge vif_cr.clk);

    phase.drop_objection(this);
  endtask

endclass
