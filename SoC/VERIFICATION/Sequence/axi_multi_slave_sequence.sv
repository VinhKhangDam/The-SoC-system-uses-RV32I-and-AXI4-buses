class axi_multi_slave_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_multi_slave_sequence)

    function new(string name = "axi_multi_slave_sequence");
        super.new(name);
    endfunction

    task send_trans(bit [31:0] addr, bit [31:0] data, bit is_write, bit [3:0] wstrb = 4'hf);
        req = axi_transaction::type_id::create("req");
        start_item(req);
        req.addr     = addr;
        req.data     = data;
        req.is_write = is_write;
        req.wstrb    = wstrb; 
        finish_item(req);
    endtask

    virtual task body();
        `uvm_info("SEQ", "--- STARTING AGGRESSIVE COVERAGE TEST ---", UVM_LOW)

        // 1. TEST DATA PATTERNS (Đạt ID 4, ID 13)
        `uvm_info("SEQ", "Testing Data Patterns...", UVM_LOW)
        send_trans(32'h1000_0000, 32'h5555_AAAA, 1'b1);
        send_trans(32'h1000_0004, 32'hAAAA_5555, 1'b1); 
        send_trans(32'h1000_0008, 32'hFFFF_FFFF, 1'b1); 
        send_trans(32'h1000_000C, 32'h0000_0000, 1'b1); 

        // 2. TEST STROBE RANDOM (Đạt ID 14 - Memory Boundary)
        `uvm_info("SEQ", "Testing Byte Strobe Access...", UVM_LOW)
        send_trans(32'h1000_0100, 32'h0000_00FF, 1'b1, 4'b0001);
        send_trans(32'h1000_0100, 32'h0000_FF00, 1'b1, 4'b0010); 
        send_trans(32'h1000_03FC, 32'hDEADC0DE, 1'b1, 4'b1111); 

        // 3. TEST RANDOM MIX (Đạt ID 11, ID 12)
        `uvm_info("SEQ", "Generating 100 Random Transactions...", UVM_LOW)
        for(int i=0; i<100; i++) begin
            bit [31:0] r_addr;
            bit [31:0] r_data;
            bit        r_rw;
            r_addr = $urandom_range(32'h1000_0000, 32'h1000_03FC) & 32'hFFFF_FFFC;
            r_data = $urandom();
            r_rw   = $urandom_range(0, 1);
            send_trans(r_addr, r_data, r_rw);
        end

        // 4. TEST SLAVE ERROR CHECK (ID 4)
        `uvm_info("SEQ", "Checking Illegal Address...", UVM_LOW)
        send_trans(32'hFFFF_FFFF, 32'h0, 1'b0);

        // 5. TEST NGOẠI VI THEO REGISTER MAP (ID 17, 18)
        send_trans(32'h3000_0000, 32'h0000_004B, 1'b1);
        // SPI Start
        send_trans(32'h4000_0004, 32'h0000_0001, 1'b1); 

        `uvm_info("SEQ", "--- ALL TESTCASES SENT ---", UVM_LOW)
    endtask
endclass