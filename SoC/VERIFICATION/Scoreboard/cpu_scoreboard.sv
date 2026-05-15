// ============================================================
// cpu_scoreboard.sv
//
// Reads expected.mem (produced by sim_expected.py) at start.
// Tracks actual register values written by CPU pipeline.
// Checks AXI BRESP/RRESP — any SLVERR causes immediate error.
// At end of simulation: compares actual vs expected, prints
// per-register PASS/FAIL table.
// ============================================================

// FIX: need two analysis_imp types — one for WB transactions,
// one for AXI transactions. Use the _imp macro with a suffix.
`uvm_analysis_imp_decl(_wb)
`uvm_analysis_imp_decl(_axi)

class cpu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(cpu_scoreboard)

    // FIX: separate analysis imports for WB and AXI transactions
    uvm_analysis_imp_wb  #(cpu_transaction, cpu_scoreboard) wb_export;
    uvm_analysis_imp_axi #(axi_transaction,    cpu_scoreboard) axi_export;

    // Expected register values loaded from expected.mem
    logic [31:0] expected_regs [32];
    bit          expected_loaded = 0;

    // Actual final register values tracked as CPU writes
    logic [31:0] actual_regs    [32];
    bit          reg_written     [32];

    // AXI error counters
    int unsigned axi_write_errors = 0;
    int unsigned axi_read_errors  = 0;

    // Total writeback events seen
    int unsigned wb_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        wb_export  = new("wb_export",  this);
        axi_export = new("axi_export", this);
        for (int i = 0; i < 32; i++) begin
            actual_regs[i]   = '0;
            expected_regs[i] = '0;
            reg_written[i]   = 0;
        end
    endfunction

    // ----------------------------------------------------------
    // build_phase: load expected.mem
    // ----------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        string expected_file;
        super.build_phase(phase);

        if (!$value$plusargs("expected_file=%s", expected_file))
            expected_file = "expected.mem";

        load_expected(expected_file);
    endfunction

    // ----------------------------------------------------------
    // Load expected.mem — format: one hex word per line, x0 first
    // ----------------------------------------------------------
    function void load_expected(string path);
        int fd;
        string line;
        int    reg_idx = 0;

        fd = $fopen(path, "r");
        if (fd == 0) begin
            `uvm_warning("SCB",
                $sformatf("Cannot open expected file: %s — scoreboard will skip comparison", path))
            expected_loaded = 0;
            return;
        end

        while (!$feof(fd) && reg_idx < 32) begin
            void'($fgets(line, fd));
            // Strip everything after '//'
            foreach (line[i]) begin
                if (line[i] == "/" && line[i+1] == "/") begin
                    line = line.substr(0, i-1);
                    break;
                end
            end
            line = line.substr(0, line.len()-1); // strip newline
            if (line.len() > 0) begin
                if ($sscanf(line, "%h", expected_regs[reg_idx]) == 1)
                    reg_idx++;
            end
        end
        $fclose(fd);

        if (reg_idx == 32) begin
            expected_loaded = 1;
            `uvm_info("SCB",
                $sformatf("Loaded expected registers from: %s", path), UVM_LOW)
        end else begin
            `uvm_warning("SCB",
                $sformatf("expected.mem incomplete: only %0d registers loaded", reg_idx))
        end

        // Always force x0 = 0
        expected_regs[0] = 32'h0;
    endfunction

    // ----------------------------------------------------------
    // write_wb() — called by monitor on every WB event
    // ----------------------------------------------------------
    virtual function void write_wb(cpu_transaction tr);
        wb_count++;

        if (tr.rd == 5'h0) return;

        actual_regs[tr.rd] = tr.result;
        reg_written[tr.rd] = 1;

        `uvm_info("SCB",
            $sformatf("[WB #%0d] x%02d <= %h", wb_count, tr.rd, tr.result),
            UVM_HIGH)
    endfunction

    // ----------------------------------------------------------
    // write_axi() — called by monitor on every AXI transaction
    // FIX: checks BRESP/RRESP and errors immediately on SLVERR
    // ----------------------------------------------------------
    virtual function void write_axi(axi_transaction tr);
        if (tr.is_write) begin
            if (tr.bresp != 2'b00) begin
                axi_write_errors++;
                `uvm_error("SCB_AXI",
                    $sformatf("AXI WRITE ERROR: Addr=%h Data=%h BRESP=%b (expected 2'b00 OKAY)",
                        tr.addr, tr.data, tr.bresp))
            end
        end else begin
            if (tr.rresp != 2'b00) begin
                axi_read_errors++;
                `uvm_error("SCB_AXI",
                    $sformatf("AXI READ ERROR:  Addr=%h Data=%h RRESP=%b (expected 2'b00 OKAY)",
                        tr.addr, tr.data, tr.rresp))
            end
        end
    endfunction

    // ----------------------------------------------------------
    // check_phase — compare actual vs expected, print table
    // ----------------------------------------------------------
    virtual function void check_phase(uvm_phase phase);
        int pass_count = 0;
        int fail_count = 0;
        int skip_count = 0;
        string status;

        super.check_phase(phase);

        `uvm_info("SCB", "", UVM_LOW)
        `uvm_info("SCB",
            "==============================================================",
            UVM_LOW)

        `uvm_info("SCB",
            "            CPU REGISTER FILE - FINAL RESULT                  ",
            UVM_LOW)

        `uvm_info("SCB",
            "==============================================================",
            UVM_LOW)

        `uvm_info("SCB",
            " REG   |   EXPECTED   |    ACTUAL    | MATCH |    STATUS    ",
            UVM_LOW)

        `uvm_info("SCB",
            "--------------------------------------------------------------",
            UVM_LOW)
        `uvm_info("SCB", "", UVM_LOW)

        for (int i = 0; i < 32; i++) begin
            logic [31:0] exp_val = expected_regs[i];
            logic [31:0] act_val = actual_regs[i];
            string match_str;

            if (!expected_loaded) begin
                status    = "NO_REF";
                match_str = "  ??  ";
                skip_count++;

            end else if (i == 0) begin
                act_val   = 32'h0;
                match_str = " PASS ";
                status    = "PASS";
                pass_count++;

            end else if (!reg_written[i] && exp_val == 32'h0) begin
                match_str = " PASS ";
                status    = "PASS";
                pass_count++;

            end else if (!reg_written[i]) begin
                match_str = " FAIL ";
                status    = "FAIL (never written)";
                fail_count++;

            end else if (act_val === exp_val) begin
                match_str = " PASS ";
                status    = "PASS";
                pass_count++;

            end else begin
                match_str = " FAIL ";
                status    = $sformatf("FAIL (diff=%h)", exp_val ^ act_val);
                fail_count++;
            end

            `uvm_info("SCB",
                $sformatf("| x%02d |  %08h  |  %08h  | %-5s | %-20s |",
                    i,
                    exp_val,
                    (i==0) ? 32'h0 : act_val,
                    match_str,
                    status),
                UVM_LOW)
        end

        `uvm_info("SCB",
            "--------------------------------------------------------------",
            UVM_LOW)

        `uvm_info("SCB",
            $sformatf(" Total WB events : %-5d   PASS : %-3d   FAIL : %-3d   SKIP : %-3d",
                wb_count, pass_count, fail_count, skip_count),
            UVM_LOW)

        `uvm_info("SCB",
            $sformatf(" AXI Write Errors : %-3d   AXI Read Errors : %-3d",
                axi_write_errors, axi_read_errors),
            UVM_LOW)

        `uvm_info("SCB",
            "==============================================================",
            UVM_LOW)

        `uvm_info("SCB", "", UVM_LOW)

        if (fail_count > 0)
            `uvm_error("SCB",
                $sformatf("SIMULATION FAILED : %0d register(s) mismatch", fail_count))
        else if (axi_write_errors > 0 || axi_read_errors > 0)
            `uvm_error("SCB",
                $sformatf("SIMULATION FAILED — AXI errors: %0d write, %0d read",
                    axi_write_errors, axi_read_errors))
        else if (pass_count > 0)
            `uvm_info("SCB", "SIMULATION PASSED: all registers match expected", UVM_LOW)

    endfunction

endclass
