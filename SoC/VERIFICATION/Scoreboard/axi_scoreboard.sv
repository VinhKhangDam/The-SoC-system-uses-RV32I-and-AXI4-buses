`timescale 1ns/1ps

class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp #(axi_transaction, axi_scoreboard) item_collected_export;

    // DRAM shadow memory
    bit [31:0] sc_mem [bit[31:0]];

    bit [31:0] sc_iram [bit[31:0]];

    // Peripheral shadow registers — keyed by full address
    bit [31:0] sc_periph [bit[31:0]];

    // Track which peripheral addresses are write-only (no read-back check)
    // UART 0x30000000 = TX register (write only)
    // Add more as needed
    bit write_only_regs [bit[31:0]];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Mark write-only registers — reads from these return 0 by design
        write_only_regs[32'h3000_0000] = 1; // UART TX data register
        write_only_regs[32'h4000_0000] = 1; // SPI DATA: TX write, RX read
        $readmemh("instr.mem", sc_iram);
    endfunction

    function string get_peripheral(bit [31:0] addr);
        if      (addr >= 32'h2000_0000 && addr < 32'h3000_0000) return "TIMER";
        else if (addr >= 32'h3000_0000 && addr < 32'h4000_0000) return "UART";
        else if (addr >= 32'h4000_0000 && addr < 32'h5000_0000) return "SPI";
        else                                                      return "UNKNOWN";
    endfunction

    virtual function void write(axi_transaction tr);
        bit [31:0] exp_data;

        // --- Illegal decode region (0x5000_0000 - 0xFFFF_FFFF) ---
        if (tr.addr >= 32'h5000_0000) begin
            if (tr.is_write) begin
                if (tr.bresp == 2'b11)
                    `uvm_info("SCB_PASS", $sformatf("[DECERR] PASS WRITE Addr=%h BResp=%b", tr.addr, tr.bresp), UVM_LOW)
                else
                    `uvm_error("SCB_FAIL", $sformatf("[DECERR] WRITE Addr=%h Expected BResp=11 Got=%b", tr.addr, tr.bresp))
            end else begin
                if (tr.rresp == 2'b11 && tr.data == 32'hDEAD_BEEF)
                    `uvm_info("SCB_PASS", $sformatf("[DECERR] PASS READ Addr=%h Data=%h RResp=%b", tr.addr, tr.data, tr.rresp), UVM_LOW)
                else
                    `uvm_error("SCB_FAIL", $sformatf("[DECERR] READ Addr=%h Expected Data=DEADBEEF RResp=11 Got Data=%h RResp=%b",
                               tr.addr, tr.data, tr.rresp))
            end
            return;
        end

        // --- DRAM (0x1000_0000 - 0x1FFF_FFFF) ---
        if (tr.addr >= 32'h1000_0000 && tr.addr < 32'h2000_0000) begin
            if (tr.is_write) begin
                exp_data = sc_mem.exists(tr.addr) ? sc_mem[tr.addr] : 32'h0;
                if (tr.wstrb[0]) exp_data[7:0]   = tr.data[7:0];
                if (tr.wstrb[1]) exp_data[15:8]  = tr.data[15:8];
                if (tr.wstrb[2]) exp_data[23:16] = tr.data[23:16];
                if (tr.wstrb[3]) exp_data[31:24] = tr.data[31:24];
                sc_mem[tr.addr] = exp_data;
                `uvm_info("SCB_WR", $sformatf("[DRAM] WRITE Addr=%h Data=%h Strb=%b Expected=%h",
                          tr.addr, tr.data, tr.wstrb, exp_data), UVM_HIGH)
            end else begin
                if (!sc_mem.exists(tr.addr)) begin
                    `uvm_warning("SCB_WARN", $sformatf("[DRAM] READ Addr=%h but never written — skipping check", tr.addr))
                end else if (sc_mem[tr.addr] == tr.data) begin
                    `uvm_info("SCB_PASS", $sformatf("[DRAM] PASS Addr=%h Expected=%h Got=%h",
                              tr.addr, sc_mem[tr.addr], tr.data), UVM_LOW)
                end else begin
                    `uvm_error("SCB_FAIL", $sformatf("[DRAM] FAIL Addr=%h Expected=%h Got=%h",
                               tr.addr, sc_mem[tr.addr], tr.data))
                end
            end
        end

        // --- Peripherals (TIMER/UART/SPI >= 0x2000_0000) ---
        else if (tr.addr >= 32'h2000_0000) begin
            string pname = get_peripheral(tr.addr);

            if (tr.is_write) begin
                // Store expected value for readable registers
                if (!write_only_regs.exists(tr.addr))
                    sc_periph[tr.addr] = tr.data;
                `uvm_info("SCB_WR", $sformatf("[%s] WRITE Addr=%h Data=%h",
                          pname, tr.addr, tr.data), UVM_LOW)
            end else begin
                // Check DEADBEEF = interconnect decode error
                if (tr.data == 32'hDEAD_BEEF) begin
                    `uvm_error("SCB_FAIL", $sformatf("[%s] READ Addr=%h returned DEADBEEF — DECERR from interconnect!",
                               pname, tr.addr))
                end
                // Write-only register — 0x00 is correct, just log it
                else if (write_only_regs.exists(tr.addr)) begin
                    `uvm_info("SCB_PASS", $sformatf("[%s] PASS Addr=%h is write-only, read returned %h (expected 0x00)",
                              pname, tr.addr, tr.data), UVM_LOW)
                end
                // Readable register — check against shadow
                else if (sc_periph.exists(tr.addr)) begin
                    if (sc_periph[tr.addr] == tr.data)
                        `uvm_info("SCB_PASS", $sformatf("[%s] PASS Addr=%h Expected=%h Got=%h",
                                  pname, tr.addr, sc_periph[tr.addr], tr.data), UVM_LOW)
                    else
                        `uvm_error("SCB_FAIL", $sformatf("[%s] FAIL Addr=%h Expected=%h Got=%h",
                                   pname, tr.addr, sc_periph[tr.addr], tr.data))
                end
                // Never written — just log the value
                else begin
                    `uvm_info("SCB_RD", $sformatf("[%s] READ Addr=%h Data=%h (status/no prior write)",
                              pname, tr.addr, tr.data), UVM_LOW)
                end
            end
        end

        // --- IRAM (0x0000_0000 - 0x0FFF_FFFF) ---
        else begin
            int idx = tr.addr >> 2;

            if (!tr.is_write) begin
                if (sc_iram[idx] != tr.data) begin
                    `uvm_error("SCB_FAIL",
                        $sformatf("[IRAM] FAIL Addr=%h Expected=%h Got=%h",
                                tr.addr, sc_iram[idx], tr.data))
                end
                else begin
                    // 🔥 PASS → print so you KNOW it's working
                    `uvm_info("SCB_PASS",
                        $sformatf("[IRAM] PASS Addr=%h Data=%h",
                                tr.addr, tr.data),
                        UVM_LOW)
                end
            end
        end
    endfunction
endclass
