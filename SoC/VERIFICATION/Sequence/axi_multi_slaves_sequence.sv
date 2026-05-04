class axi_multi_slaves_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_multi_slaves_sequence)

    // ADDRESS MAP
    localparam DRAM_BASE = 32'h1000_0000;
    localparam TIMER_BASE = 32'h2000_0000;
    localparam UART_BASE = 32'h3000_0000;
    localparam SPI_BASE = 32'h4000_0000;

    function new(string name = "axi_multi_slaves_sequence");
        super.new(name);
    endfunction

    task send_write(bit [31:0] addr, bit[31:0] data, bit [2:0] prot = 3'b000);
        req = axi_transaction::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.data = data;
        req.is_write = 1'b1;
        req.wstrb = 4'hF;
        req.awprot = prot;
        finish_item(req);
    endtask

    task send_read(bit[31:0] addr);
        req = axi_transaction::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.data = 32'h0;
        req.is_write = 1'b0;
        req.wstrb = 4'h0;
        finish_item(req);
    endtask

    virtual task body();
        `uvm_info("SEQ", "--- Basic AXI4-Lite Multi Slaves ---", UVM_LOW)
 
        // --- Slave 1: DRAM (write + read back, scoreboard verifies) ---
        `uvm_info("SEQ", "Accessing DRAM (0x1000_0000)...", UVM_LOW)
        send_write(DRAM_BASE + 32'h00, 32'hA5A5_A5A5);
        send_write(DRAM_BASE + 32'h04, 32'h5A5A_5A5A);
        send_read (DRAM_BASE + 32'h00);
        send_read (DRAM_BASE + 32'h04);
 
        // --- TIMER: use awprot=3'b001 to pass privilege check ---
        // Write PERIOD (0x4) and CONTROL (0x0 with ENABLE=1)
        // Read back PERIOD (0x4) and CONTROL (0x0) — both readable
        `uvm_info("SEQ", "Accessing Timer (0x2000_0000)...", UVM_LOW)
        send_write(TIMER_BASE + 32'h04, 32'h0000_0064, 3'b001); // PERIOD = 100, privileged
        send_write(TIMER_BASE, 32'h0000_0001, 3'b001); // CONTROL: ENABLE=1, privileged
        send_read (TIMER_BASE + 32'h04); // read PERIOD — should match 0x64
        send_read (TIMER_BASE); // read CONTROL — should match 0x01
 
        // --- UART: write BAUD (0xC, readable), read it back ---
        // Also write TX (0x0, write-only), read back 0x00 (expected)
        `uvm_info("SEQ", "Accessing UART (0x3000_0000)...", UVM_LOW)
        send_write(UART_BASE + 32'h0C, 32'h0000_01B2); // BAUD = 434 (115200 @ 50MHz)
        send_write(UART_BASE, 32'h0000_0041); // TX = 'A' (write-only)
        send_read (UART_BASE + 32'h0C); // read BAUD — should match 0x1B2
        send_read (UART_BASE); // read TX reg — write-only, expect 0x00
 
        // --- SPI: write BAUD (0xC), read back ---
        // Write DATA (0x0), read back after no transfer = 0x00
        `uvm_info("SEQ", "Accessing SPI (0x4000_0000)...", UVM_LOW)
        send_write(SPI_BASE + 32'h0C, 32'h0000_000A); // BAUD = 10
        send_write(SPI_BASE, 32'h0000_00AB); // TX data = 0xAB
        send_read (SPI_BASE + 32'h0C); // read BAUD — should match 0x0A
        send_read (SPI_BASE); // read RX data — no transfer yet, expect 0x00
        
        // --- Final DRAM check: ensure peripheral accesses didn't corrupt DRAM ---
        `uvm_info("SEQ", "Final DRAM integrity check after peripheral accesses...", UVM_LOW)
        send_read(DRAM_BASE + 32'h00);
        send_read(DRAM_BASE + 32'h04);
 
        `uvm_info("SEQ", "--- Basic AXI4-Lite Multi Slaves Done ---", UVM_LOW)
    endtask
endclass