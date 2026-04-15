`timescale 1ns/1ps

class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)
    
    uvm_analysis_imp #(axi_transaction, axi_scoreboard) item_collected_export;

    bit [31:0] sc_mem [bit[31:0]];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    virtual function void write(axi_transaction tr);
        // --- VÙNG DRAM (0x1000_0000 - 0x1FFF_FFFF) ---
        if (tr.addr >= 32'h1000_0000 && tr.addr < 32'h2000_0000) begin
            if (tr.is_write) begin
                sc_mem[tr.addr] = tr.data;
                `uvm_info("SCB_WRITE", $sformatf("Ghi vao SCB: Addr=%h, Data=%h", tr.addr, tr.data), UVM_HIGH)
            end else if (sc_mem.exists(tr.addr)) begin
                if (sc_mem[tr.addr] == tr.data)
                    `uvm_info("SCB_PASS", $sformatf("Match! Addr=%h, Data=%h", tr.addr, tr.data), UVM_LOW)
                else
                    // Chỗ này báo lỗi là do DRAM thật trả về rác (deadbeef)
                    `uvm_error("SCB_FAIL", $sformatf("DRAM THAT LOI! Addr=%h, SCB_giu:%h, DRAM_tra:%h", tr.addr, sc_mem[tr.addr], tr.data))
            end
        end

        // --- VÙNG NGOẠI VI (UART, SPI, TIMER >= 0x2000_0000) ---
        else if (tr.addr >= 32'h2000_0000) begin
            string peripheral;
            if      (tr.addr < 32'h3000_0000) peripheral = "TIMER";
            else if (tr.addr < 32'h4000_0000) peripheral = "UART";
            else if (tr.addr < 32'h5000_0000) peripheral = "SPI";
            else                              peripheral = "UNKNOWN";

            `uvm_info("MON_IO", $sformatf("[%s] %s: Addr=%h, Data=%h", 
                      peripheral, (tr.is_write ? "WRITE" : "READ"), tr.addr, tr.data), UVM_LOW)
            
            if (!tr.is_write && tr.data == 32'hDEADBEEF) begin
                `uvm_warning("SCB_IO_ERR", $sformatf("Ngoai vi %s tra ve DEADBEEF (Decode Error?)", peripheral))
            end
        end

        // --- VÙNG IRAM (0x0000_0000) ---
        else begin
            `uvm_info("SCB_IRAM", $sformatf("CPU Fetch/Access IRAM: Addr=%h", tr.addr), UVM_HIGH)
        end

    endfunction
endclass