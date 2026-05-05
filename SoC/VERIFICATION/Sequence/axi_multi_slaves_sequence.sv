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
 
        // ========================================
        // TEST 1: Basic DRAM Access
        // ========================================
        `uvm_info("SEQ", "=== TEST 1: Basic DRAM Access ===", UVM_LOW)
        send_write(DRAM_BASE + 32'h00, 32'hA5A5_A5A5);
        send_write(DRAM_BASE + 32'h04, 32'h5A5A_5A5A);
        send_read (DRAM_BASE + 32'h00);
        send_read (DRAM_BASE + 32'h04);
 
        // ========================================
        // TEST 2: Timer Basic Operation
        // ========================================
        `uvm_info("SEQ", "=== TEST 2: Timer Basic Operation ===", UVM_LOW)
        send_write(TIMER_BASE + 32'h04, 32'h0000_0064, 3'b001); // PERIOD = 100
        send_write(TIMER_BASE, 32'h0000_0001, 3'b001);          // ENABLE
        send_read (TIMER_BASE + 32'h04);
        send_read (TIMER_BASE);
        send_read (TIMER_BASE + 32'h08); // Read COUNT register
 
        // ========================================
        // TEST 3: UART Communication
        // ========================================
        `uvm_info("SEQ", "=== TEST 3: UART Communication ===", UVM_LOW)
        send_write(UART_BASE + 32'h0C, 32'h0000_01B2); // BAUD
        send_write(UART_BASE, 32'h0000_0041);          // TX = 'A'
        send_read (UART_BASE + 32'h0C);
        send_read (UART_BASE);
 
        // ========================================
        // TEST 4: SPI Data Transfer
        // ========================================
        `uvm_info("SEQ", "=== TEST 4: SPI Data Transfer ===", UVM_LOW)
        send_write(SPI_BASE + 32'h0C, 32'h0000_000A);  // BAUD = 10
        send_write(SPI_BASE, 32'h0000_00AB);           // TX = 0xAB
        send_read (SPI_BASE + 32'h0C);
        send_read (SPI_BASE);

        // ========================================
        // TEST 5: DRAM Burst Access (Multiple Sequential Addresses)
        // ========================================
        `uvm_info("SEQ", "=== TEST 5: DRAM Burst Write/Read ===", UVM_LOW)
        for (int i = 0; i < 8; i++) begin
            send_write(DRAM_BASE + (i * 4), 32'h1000_0000 + i);
        end
        for (int i = 0; i < 8; i++) begin
            send_read(DRAM_BASE + (i * 4));
        end

        // ========================================
        // TEST 6: Interleaved Multi-Slave Access
        // ========================================
        `uvm_info("SEQ", "=== TEST 6: Interleaved Access Across Slaves ===", UVM_LOW)
        send_write(DRAM_BASE, 32'hDEAD_BEEF);
        send_write(TIMER_BASE + 32'h04, 32'h0000_0032, 3'b001);
        send_write(UART_BASE + 32'h0C, 32'h0000_0100);
        send_write(SPI_BASE + 32'h0C, 32'h0000_0005);
        
        send_read(DRAM_BASE);
        send_read(TIMER_BASE + 32'h04);
        send_read(UART_BASE + 32'h0C);
        send_read(SPI_BASE + 32'h0C);

        // ========================================
        // TEST 7: Timer Disable/Re-enable
        // ========================================
        `uvm_info("SEQ", "=== TEST 7: Timer Disable/Re-enable ===", UVM_LOW)
        send_write(TIMER_BASE + 32'h04, 32'h0000_0050, 3'b001); // PERIOD = 80
        send_write(TIMER_BASE, 32'h0000_0001, 3'b001);          // ENABLE
        send_read (TIMER_BASE + 32'h08);                        // COUNT should be incrementing
        send_write(TIMER_BASE, 32'h0000_0000, 3'b001);          // DISABLE
        send_read (TIMER_BASE + 32'h08);                        // COUNT should reset to 0
        send_read (TIMER_BASE);                                 // Verify CONTROL = 0

        // ========================================
        // TEST 8: UART Multiple Character Transmission
        // ========================================
        `uvm_info("SEQ", "=== TEST 8: UART Multiple TX ===", UVM_LOW)
        send_write(UART_BASE + 32'h0C, 32'h0000_01B2);
        send_write(UART_BASE, 32'h0000_0048); // 'H'
        send_write(UART_BASE, 32'h0000_0045); // 'E'
        send_write(UART_BASE, 32'h0000_004C); // 'L'
        send_write(UART_BASE, 32'h0000_004C); // 'L'
        send_write(UART_BASE, 32'h0000_004F); // 'O'

        // ========================================
        // TEST 9: SPI Multiple Transfers
        // ========================================
        `uvm_info("SEQ", "=== TEST 9: SPI Multiple Transfers ===", UVM_LOW)
        send_write(SPI_BASE + 32'h0C, 32'h0000_0008);
        send_write(SPI_BASE, 32'h0000_00FF);
        send_write(SPI_BASE, 32'h0000_0055);
        send_write(SPI_BASE, 32'h0000_00AA);
        send_read (SPI_BASE);

        // ========================================
        // TEST 10: DRAM Address Boundary Check
        // ========================================
        `uvm_info("SEQ", "=== TEST 10: DRAM Address Boundaries ===", UVM_LOW)
        send_write(DRAM_BASE + 32'h0000, 32'h0000_0001); // Start
        send_write(DRAM_BASE + 32'h0FFC, 32'hFFFF_FFFF); // Near end (4KB boundary)
        send_read (DRAM_BASE + 32'h0000);
        send_read (DRAM_BASE + 32'h0FFC);

        // ========================================
        // TEST 11: Read All Slave Status Registers
        // ========================================
        `uvm_info("SEQ", "=== TEST 11: Read All Status Registers ===", UVM_LOW)
        send_read(TIMER_BASE);          // Timer CONTROL
        send_read(TIMER_BASE + 32'h04); // Timer PERIOD
        send_read(TIMER_BASE + 32'h08); // Timer COUNT
        send_read(UART_BASE + 32'h0C);  // UART BAUD
        send_read(SPI_BASE + 32'h0C);   // SPI BAUD

        // ========================================
        // TEST 12: Rapid Sequential Writes to Same Slave
        // ========================================
        `uvm_info("SEQ", "=== TEST 12: Rapid DRAM Writes ===", UVM_LOW)
        send_write(DRAM_BASE + 32'h100, 32'h1111_1111);
        send_write(DRAM_BASE + 32'h104, 32'h2222_2222);
        send_write(DRAM_BASE + 32'h108, 32'h3333_3333);
        send_write(DRAM_BASE + 32'h10C, 32'h4444_4444);
        send_read (DRAM_BASE + 32'h100);
        send_read (DRAM_BASE + 32'h104);
        send_read (DRAM_BASE + 32'h108);
        send_read (DRAM_BASE + 32'h10C);

        // ========================================
        // TEST 13: Timer Period Update While Running
        // ========================================
        `uvm_info("SEQ", "=== TEST 13: Timer Period Update ===", UVM_LOW)
        send_write(TIMER_BASE + 32'h04, 32'h0000_0010, 3'b001); // PERIOD = 16
        send_write(TIMER_BASE, 32'h0000_0001, 3'b001);          // ENABLE
        send_read (TIMER_BASE + 32'h04);
        send_write(TIMER_BASE + 32'h04, 32'h0000_0020, 3'b001); // Update to 32
        send_read (TIMER_BASE + 32'h04);

        // ========================================
        // TEST 14: Different Baud Rate Configurations
        // ========================================
        `uvm_info("SEQ", "=== TEST 14: UART/SPI Baud Variations ===", UVM_LOW)
        send_write(UART_BASE + 32'h0C, 32'h0000_0064); // 9600 baud equiv
        send_read (UART_BASE + 32'h0C);
        send_write(UART_BASE + 32'h0C, 32'h0000_0032); // 19200 baud equiv
        send_read (UART_BASE + 32'h0C);
        
        send_write(SPI_BASE + 32'h0C, 32'h0000_0002);  // Fast SPI
        send_read (SPI_BASE + 32'h0C);
        send_write(SPI_BASE + 32'h0C, 32'h0000_001E);  // Slow SPI
        send_read (SPI_BASE + 32'h0C);

        // ========================================
        // TEST 15: Final Integrity Check - All Slaves
        // ========================================
        `uvm_info("SEQ", "=== TEST 15: Final Multi-Slave Integrity ===", UVM_LOW)
        send_write(DRAM_BASE, 32'hCAFE_BABE);
        send_write(TIMER_BASE + 32'h04, 32'h0000_007F, 3'b001);
        send_write(UART_BASE + 32'h0C, 32'h0000_0200);
        send_write(SPI_BASE + 32'h0C, 32'h0000_000F);
        
        send_read(DRAM_BASE);
        send_read(TIMER_BASE + 32'h04);
        send_read(UART_BASE + 32'h0C);
        send_read(SPI_BASE + 32'h0C);
 
        `uvm_info("SEQ", "--- All Multi-Slave Tests Complete ---", UVM_LOW)
    endtask
endclass