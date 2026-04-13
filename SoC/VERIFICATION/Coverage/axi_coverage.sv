class axi_coverage extends uvm_subscriber #(axi_transaction);
    `uvm_component_utils(axi_coverage)

    axi_transaction tr;

    // COVERGROUP
    covergroup axi_cg;
        option.per_instance = 1;
        option.comment = "Coverage for SOC RISC-V AXI-Lite";

        ADDR_CP : coverpoint tr.addr {
            bins IRAM   = { [32'h0000_0000 : 32'h0FFF_FFFF] };
            bins DRAM   = { [32'h1000_0000 : 32'h1FFF_FFFF] };
            bins TIMER  = { [32'h2000_0000 : 32'h2FFF_FFFF] };
            bins UART   = { [32'h3000_0000 : 32'h3FFF_FFFF] };
            bins SPI    = { [32'h4000_0000 : 32'h4FFF_FFFF] };
            bins ILLEGAL = default;
        }

        CMD_CP : coverpoint tr.is_write {
            bins WRITE = {1};
            bins READ  = {0};  
        }

        DATA_CP : coverpoint tr.data {
            bins zero     = {32'h0000_0000};
            bins ones     = {32'hFFFF_FFFF};
            bins alt_05   = {32'h5555_AAAA}; 
            bins alt_A    = {32'hAAAA_5555};
            bins others   = default;  
        }

        STRB_CP : coverpoint tr.wstrb {
            bins byte_acc = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
            bins word_acc = {4'b1111};    
        }

        ADDR_x_CMD : cross ADDR_CP, CMD_CP;
        
        RAM_x_STRB : cross ADDR_CP, STRB_CP {
            ignore_bins non_ram = !binsof(ADDR_CP.DRAM);
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        axi_cg = new();
    endfunction

    virtual function void write(axi_transaction t);
        this.tr = t;
        axi_cg.sample();
    endfunction
endclass