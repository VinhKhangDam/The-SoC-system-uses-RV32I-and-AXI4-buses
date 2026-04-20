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

    task send_write(bit [31:0] addr, bit[31:0] data);
        req = axi_transaction::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.data = data;
        req.is_write = 1'b1;
        req.wstrb = 4'hF;
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
 
        // --- Slave 2: Timer (write control reg, read back) ---
        // Scoreboard logs it as peripheral — no data integrity check expected
        `uvm_info("SEQ", "Accessing Timer (0x2000_0000)...", UVM_LOW)
        send_write(TIMER_BASE + 32'h00, 32'h0000_00FF); // Load timer value
        send_read (TIMER_BASE + 32'h00);
 
        // --- Slave 3: UART (write TX data, read status) ---
        `uvm_info("SEQ", "Accessing UART (0x3000_0000)...", UVM_LOW)
        send_write(UART_BASE + 32'h00, 32'h0000_0041); // 'A' character
        send_read (UART_BASE + 32'h00);
 
        // --- Slave 4: SPI (write config register) ---
        `uvm_info("SEQ", "Accessing SPI (0x4000_0000)...", UVM_LOW)
        send_write(SPI_BASE + 32'h00, 32'h0000_0001); // Enable SPI
        send_read (SPI_BASE + 32'h00);
 
        // --- Final DRAM check: ensure peripheral accesses didn't corrupt DRAM ---
        `uvm_info("SEQ", "Final DRAM integrity check after peripheral accesses...", UVM_LOW)
        send_read(DRAM_BASE + 32'h00);
        send_read(DRAM_BASE + 32'h04);
 
        `uvm_info("SEQ", "--- Basic AXI4-Lite Multi Slaves Done ---", UVM_LOW)
    endtask
endclass