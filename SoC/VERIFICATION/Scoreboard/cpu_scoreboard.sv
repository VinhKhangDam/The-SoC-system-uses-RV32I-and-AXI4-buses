// ============================================================
// cpu_scoreboard.sv
//
// Loads expected CPU registers from expected.mem, tracks CPU WB,
// checks AXI responses, and compares AXI read data for DRAM and
// stable peripheral registers.
// ============================================================

`uvm_analysis_imp_decl(_wb)
`uvm_analysis_imp_decl(_axi)

class cpu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cpu_scoreboard)

  uvm_analysis_imp_wb #(cpu_transaction, cpu_scoreboard) wb_export;
  uvm_analysis_imp_axi #(axi_transaction, cpu_scoreboard) axi_export;

  logic [31:0] expected_regs[32];
  logic [31:0] actual_regs[32];
  bit expected_loaded = 0;
  bit reg_written[32];

  int unsigned wb_count = 0;

  int unsigned axi_write_errors = 0;
  int unsigned axi_read_errors = 0;
  int unsigned axi_data_errors = 0;
  int unsigned axi_read_passes = 0;
  int unsigned axi_read_fails = 0;
  int unsigned axi_read_skips = 0;

  int unsigned dram_writes = 0;
  int unsigned dram_reads = 0;
  int unsigned timer_accesses = 0;
  int unsigned uart_accesses = 0;
  int unsigned spi_accesses = 0;

  bit [31:0] dram_shadow[bit [31:0]];
  bit [31:0] periph_shadow[bit [31:0]];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    wb_export  = new("wb_export", this);
    axi_export = new("axi_export", this);

    for (int i = 0; i < 32; i++) begin
      expected_regs[i] = 32'h0;
      actual_regs[i]   = 32'h0;
      reg_written[i]   = 1'b0;
    end
  endfunction

  function string slave_name(bit [31:0] addr);
    if (addr >= 32'h1000_0000 && addr < 32'h2000_0000) return "DRAM";
    else if (addr >= 32'h2000_0000 && addr < 32'h3000_0000) return "TIMER";
    else if (addr >= 32'h3000_0000 && addr < 32'h4000_0000) return "UART";
    else if (addr >= 32'h4000_0000 && addr < 32'h5000_0000) return "SPI";
    else return "UNKNOWN";
  endfunction

  function bit is_periph(bit [31:0] addr);
    return (addr >= 32'h2000_0000 && addr < 32'h5000_0000);
  endfunction

  function bit is_volatile_read(bit [31:0] addr);
    case (addr)
      32'h2000_0008: return 1'b1;  // TIMER_COUNT
      32'h3000_0004: return 1'b1;  // UART_RXDATA
      32'h3000_0008: return 1'b1;  // UART_STATUS
      32'h4000_0000: return 1'b1;  // SPI_DATA RX
      32'h4000_0008: return 1'b1;  // SPI_STATUS
      default:       return 1'b0;
    endcase
  endfunction

  function bit shadows_peripheral_write(bit [31:0] addr);
    case (addr)
      32'h2000_0000,  // TIMER_CONTROL
      32'h2000_0004,  // TIMER_PERIOD
      32'h3000_000C,  // UART_BAUD
      32'h4000_0004,  // SPI_CONTROL
      32'h4000_000C:  // SPI_BAUD
      return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  function bit periph_default_expected(bit [31:0] addr, output bit [31:0] exp);
    case (addr)
      32'h2000_0000: begin
        exp = 32'h0000_0000;
        return 1'b1;
      end
      32'h2000_0004: begin
        exp = 32'h0000_0000;
        return 1'b1;
      end
      32'h3000_000C: begin
        exp = 32'd115200;
        return 1'b1;
      end
      32'h4000_0004: begin
        exp = 32'h0000_0008;
        return 1'b1;
      end
      32'h4000_000C: begin
        exp = 32'd10;
        return 1'b1;
      end
      default: begin
        exp = 32'h0000_0000;
        return 1'b0;
      end
    endcase
  endfunction

  function void count_slave_access(bit [31:0] addr);
    if (addr >= 32'h2000_0000 && addr < 32'h3000_0000) timer_accesses++;
    else if (addr >= 32'h3000_0000 && addr < 32'h4000_0000) uart_accesses++;
    else if (addr >= 32'h4000_0000 && addr < 32'h5000_0000) spi_accesses++;
  endfunction

  function void report_axi_read_compare(string pname, bit [31:0] addr, bit [31:0] expected,
                                        bit [31:0] actual);
    if (expected !== actual) begin
      axi_data_errors++;
      axi_read_fails++;
      `uvm_error("SCB_FAIL", $sformatf("[%s] READ FAIL Addr=%h Expected=%h Got=%h", pname, addr,
                                       expected, actual))
    end else begin
      axi_read_passes++;
      `uvm_info("SCB_PASS", $sformatf(
                "[%s] READ PASS Addr=%h Expected=%h Got=%h", pname, addr, expected, actual),
                UVM_LOW)
    end
  endfunction

  virtual function void build_phase(uvm_phase phase);
    string expected_file;
    super.build_phase(phase);

    if (!$value$plusargs("expected_file=%s", expected_file)) expected_file = "expected.mem";

    load_expected(expected_file);
  endfunction

  function void load_expected(string path);
    int fd;
    string line;
    int reg_idx = 0;

    fd = $fopen(path, "r");
    if (fd == 0) begin
      `uvm_warning("SCB",
                   $sformatf(
                       "Cannot open expected file: %s - scoreboard will skip register comparison",
                       path))
      expected_loaded = 0;
      return;
    end

    while (!$feof(
        fd
    ) && reg_idx < 32) begin
      void'($fgets(line, fd));

      foreach (line[i]) begin
        if (line[i] == "/" && line[i+1] == "/") begin
          line = line.substr(0, i - 1);
          break;
        end
      end

      line = line.substr(0, line.len() - 1);
      if (line.len() > 0) begin
        if ($sscanf(line, "%h", expected_regs[reg_idx]) == 1) reg_idx++;
      end
    end
    $fclose(fd);

    if (reg_idx == 32) begin
      expected_loaded = 1;
      `uvm_info("SCB", $sformatf("Loaded expected registers from: %s", path), UVM_LOW)
    end else begin
      expected_loaded = 0;
      `uvm_warning("SCB", $sformatf("expected.mem incomplete: only %0d registers loaded", reg_idx))
    end

    expected_regs[0] = 32'h0;
  endfunction

  virtual function void write_wb(cpu_transaction tr);
    wb_count++;

    if (tr.rd == 5'h0) return;

    actual_regs[tr.rd] = tr.result;
    reg_written[tr.rd] = 1'b1;

    `uvm_info("SCB", $sformatf("[WB #%0d] x%02d <= %h", wb_count, tr.rd, tr.result), UVM_HIGH)
  endfunction

  virtual function void write_axi(axi_transaction tr);
    bit [31:0] addr;
    bit [31:0] data;
    bit [31:0] expected;
    string pname;

    addr = tr.addr;
    data = tr.data;

    if (tr.is_write) begin
      if (tr.bresp != 2'b00) begin
        axi_write_errors++;
        `uvm_error("SCB_AXI", $sformatf("AXI WRITE ERROR: Addr=%h Data=%h BRESP=%b", addr, data,
                                        tr.bresp))
      end
    end else begin
      if (tr.rresp != 2'b00) begin
        axi_read_errors++;
        `uvm_error("SCB_AXI", $sformatf("AXI READ ERROR: Addr=%h Data=%h RRESP=%b", addr, data,
                                        tr.rresp))
      end
    end

    if (addr >= 32'h1000_0000 && addr < 32'h2000_0000) begin
      if (tr.is_write) begin
        dram_shadow[addr] = data;
        dram_writes++;
        `uvm_info("SCB_MEM", $sformatf("[DRAM] WRITE Addr=%h Data=%h", addr, data), UVM_HIGH)
      end else begin
        dram_reads++;
        expected = dram_shadow.exists(addr) ? dram_shadow[addr] : 32'h0000_0000;
        report_axi_read_compare("DRAM", addr, expected, data);
      end
    end else if (is_periph(addr)) begin
      pname = slave_name(addr);
      count_slave_access(addr);

      if (tr.is_write) begin
        if (shadows_peripheral_write(addr)) periph_shadow[addr] = data;

        `uvm_info("SCB_PERIPH", $sformatf("[%s] WRITE Addr=%h Data=%h", pname, addr, data), UVM_LOW)
      end else if (is_volatile_read(addr)) begin
        axi_read_skips++;
        `uvm_info("SCB_PERIPH", $sformatf("[%s] READ Addr=%h Data=%h (volatile, compare skipped)",
                                          pname, addr, data), UVM_LOW)
      end else if (periph_shadow.exists(addr)) begin
        report_axi_read_compare(pname, addr, periph_shadow[addr], data);
      end else if (periph_default_expected(addr, expected)) begin
        report_axi_read_compare(pname, addr, expected, data);
      end else begin
        axi_read_skips++;
        `uvm_info("SCB_PERIPH", $sformatf(
                  "[%s] READ Addr=%h Data=%h (no expected value)", pname, addr, data), UVM_LOW)
      end
    end
  endfunction

  virtual function void check_phase(uvm_phase phase);
    int pass_count = 0;
    int fail_count = 0;
    int skip_count = 0;
    string status;

    super.check_phase(phase);

    `uvm_info("SCB", "", UVM_LOW)
    `uvm_info("SCB", "==============================================================", UVM_LOW)
    `uvm_info("SCB", "            CPU REGISTER FILE - FINAL RESULT                  ", UVM_LOW)
    `uvm_info("SCB", "==============================================================", UVM_LOW)
    `uvm_info("SCB", " REG   |   EXPECTED   |    ACTUAL    | MATCH |    STATUS    ", UVM_LOW)
    `uvm_info("SCB", "--------------------------------------------------------------", UVM_LOW)

    for (int i = 0; i < 32; i++) begin
      logic [31:0] exp_val;
      logic [31:0] act_val;
      string match_str;

      exp_val = expected_regs[i];
      act_val = (i == 0) ? 32'h0 : actual_regs[i];

      if (!expected_loaded) begin
        match_str = "  ??  ";
        status = "NO_REF";
        skip_count++;
      end else if (i == 0) begin
        match_str = " PASS ";
        status = "PASS";
        pass_count++;
      end else if (!reg_written[i] && exp_val == 32'h0) begin
        match_str = " PASS ";
        status = "PASS";
        pass_count++;
      end else if (!reg_written[i]) begin
        match_str = " FAIL ";
        status = "FAIL (never written)";
        fail_count++;
      end else if (act_val === exp_val) begin
        match_str = " PASS ";
        status = "PASS";
        pass_count++;
      end else begin
        match_str = " FAIL ";
        status = $sformatf("FAIL (diff=%h)", exp_val ^ act_val);
        fail_count++;
      end

      `uvm_info("SCB", $sformatf(
                "| x%02d |  %08h  |  %08h  | %-5s | %-20s |", i, exp_val, act_val, match_str, status
                ), UVM_LOW)
    end

    `uvm_info("SCB", "--------------------------------------------------------------", UVM_LOW)
    `uvm_info("SCB", $sformatf(
              " Total WB events : %-5d   PASS : %-3d   FAIL : %-3d   SKIP : %-3d",
              wb_count,
              pass_count,
              fail_count,
              skip_count
              ), UVM_LOW)
    `uvm_info("SCB", $sformatf(
              " AXI Write Errors : %-3d   AXI Read Errors : %-3d", axi_write_errors, axi_read_errors
              ), UVM_LOW)
    `uvm_info("SCB", $sformatf(
              " AXI Data Errors  : %-3d   DRAM W/R : %0d/%0d   TIMER:%0d UART:%0d SPI:%0d",
              axi_data_errors,
              dram_writes,
              dram_reads,
              timer_accesses,
              uart_accesses,
              spi_accesses
              ), UVM_LOW)
    `uvm_info("SCB", $sformatf(
              " AXI Read Checks  : PASS:%0d FAIL:%0d SKIP:%0d",
              axi_read_passes,
              axi_read_fails,
              axi_read_skips
              ), UVM_LOW)
    `uvm_info("SCB", "==============================================================", UVM_LOW)
    `uvm_info("SCB", "", UVM_LOW)

    if (fail_count > 0)
      `uvm_error("SCB", $sformatf("SIMULATION FAILED : %0d register(s) mismatch", fail_count))
    else if (axi_write_errors > 0 || axi_read_errors > 0 || axi_data_errors > 0)
      `uvm_error("SCB", $sformatf(
                 "SIMULATION FAILED - AXI errors: %0d write, %0d read, %0d data",
                 axi_write_errors,
                 axi_read_errors,
                 axi_data_errors
                 ))
    else if (pass_count > 0)
      `uvm_info("SCB", "SIMULATION PASSED: all registers and AXI reads match expected", UVM_LOW)
  endfunction
endclass
