class axi_coverage extends uvm_subscriber #(axi_transaction);
    `uvm_component_utils(axi_coverage)

    axi_transaction tr;

    // ================================================================
    // COVERGROUP 1 — AXI Protocol Coverage
    // ================================================================
    covergroup axi_protocol_cg;
        option.per_instance = 1;
        option.comment      = "AXI4-Lite Protocol Coverage";

        ADDR_CP : coverpoint tr.addr {
            bins IRAM    = { [32'h0000_0000 : 32'h0FFF_FFFF] };
            bins DRAM    = { [32'h1000_0000 : 32'h1FFF_FFFF] };
            bins TIMER   = { [32'h2000_0000 : 32'h2FFF_FFFF] };
            bins UART    = { [32'h3000_0000 : 32'h3FFF_FFFF] };
            bins SPI     = { [32'h4000_0000 : 32'h4FFF_FFFF] };
            // FIX: use explicit range instead of default
            // so it can be referenced in cross ignore_bins
            bins ILLEGAL = { [32'h5000_0000 : 32'hFFFF_FFFF] };
        }

        CMD_CP : coverpoint tr.is_write {
            bins WRITE = { 1 };
            bins READ  = { 0 };
        }

        STRB_CP : coverpoint tr.wstrb {
            bins BYTE_0  = { 4'b0001 };
            bins BYTE_1  = { 4'b0010 };
            bins BYTE_2  = { 4'b0100 };
            bins BYTE_3  = { 4'b1000 };
            bins HALF_LO = { 4'b0011 };
            bins HALF_HI = { 4'b1100 };
            bins WORD    = { 4'b1111 };
            bins INVALID = default;       // default is fine here — not used in cross
        }

        BRESP_CP : coverpoint tr.bresp {
            bins OKAY   = { 2'b00 };
            bins SLVERR = { 2'b10 };
            bins DECERR = { 2'b11 };
            ignore_bins EXOKAY = { 2'b01 }; // explicit value — legal in ignore_bins
        }

        RRESP_CP : coverpoint tr.rresp {
            bins OKAY   = { 2'b00 };
            bins SLVERR = { 2'b10 };
            bins DECERR = { 2'b11 };
            ignore_bins EXOKAY = { 2'b01 };
        }

        AWPROT_CP : coverpoint tr.awprot {
            bins NORMAL_NONSEC = { 3'b000 };
            bins PRIV_NONSEC   = { 3'b001 };
            bins NORMAL_SEC    = { 3'b010 };
            bins others        = default;
        }

        ARPROT_CP : coverpoint tr.arprot {
            bins NORMAL_NONSEC = { 3'b000 };
            bins PRIV_NONSEC   = { 3'b001 };
            bins NORMAL_SEC    = { 3'b010 };
            bins others        = default;
        }

        // Every slave must be both read AND written
        // FIX: IRAM and ILLEGAL are now named bins — safe to use in cross
        ADDR_x_CMD : cross ADDR_CP, CMD_CP {
            ignore_bins IRAM_WR    = binsof(ADDR_CP.IRAM)    && binsof(CMD_CP.WRITE);
            ignore_bins ILLEGAL_WR = binsof(ADDR_CP.ILLEGAL) && binsof(CMD_CP.WRITE);
            ignore_bins ILLEGAL_RD = binsof(ADDR_CP.ILLEGAL) && binsof(CMD_CP.READ);
        }

        // FIX: Only keep DRAM strobes — list each non-DRAM bin explicitly
        // STRB_CP.INVALID is default → cannot use in cross, so only list named bins
        DRAM_x_STRB : cross ADDR_CP, STRB_CP {
            ignore_bins IRAM_STRB    = binsof(ADDR_CP.IRAM)    && binsof(STRB_CP.BYTE_0);
            ignore_bins IRAM_STRB1   = binsof(ADDR_CP.IRAM)    && binsof(STRB_CP.BYTE_1);
            ignore_bins IRAM_STRB2   = binsof(ADDR_CP.IRAM)    && binsof(STRB_CP.BYTE_2);
            ignore_bins IRAM_STRB3   = binsof(ADDR_CP.IRAM)    && binsof(STRB_CP.BYTE_3);
            ignore_bins IRAM_STRBH0  = binsof(ADDR_CP.IRAM)    && binsof(STRB_CP.HALF_LO);
            ignore_bins IRAM_STRBH1  = binsof(ADDR_CP.IRAM)    && binsof(STRB_CP.HALF_HI);
            ignore_bins IRAM_STRBW   = binsof(ADDR_CP.IRAM)    && binsof(STRB_CP.WORD);
            ignore_bins TIMER_STRB0  = binsof(ADDR_CP.TIMER)   && binsof(STRB_CP.BYTE_0);
            ignore_bins TIMER_STRB1  = binsof(ADDR_CP.TIMER)   && binsof(STRB_CP.BYTE_1);
            ignore_bins TIMER_STRB2  = binsof(ADDR_CP.TIMER)   && binsof(STRB_CP.BYTE_2);
            ignore_bins TIMER_STRB3  = binsof(ADDR_CP.TIMER)   && binsof(STRB_CP.BYTE_3);
            ignore_bins TIMER_STRBH0 = binsof(ADDR_CP.TIMER)   && binsof(STRB_CP.HALF_LO);
            ignore_bins TIMER_STRBH1 = binsof(ADDR_CP.TIMER)   && binsof(STRB_CP.HALF_HI);
            ignore_bins TIMER_STRBW  = binsof(ADDR_CP.TIMER)   && binsof(STRB_CP.WORD);
            ignore_bins UART_STRB0   = binsof(ADDR_CP.UART)    && binsof(STRB_CP.BYTE_0);
            ignore_bins UART_STRB1   = binsof(ADDR_CP.UART)    && binsof(STRB_CP.BYTE_1);
            ignore_bins UART_STRB2   = binsof(ADDR_CP.UART)    && binsof(STRB_CP.BYTE_2);
            ignore_bins UART_STRB3   = binsof(ADDR_CP.UART)    && binsof(STRB_CP.BYTE_3);
            ignore_bins UART_STRBH0  = binsof(ADDR_CP.UART)    && binsof(STRB_CP.HALF_LO);
            ignore_bins UART_STRBH1  = binsof(ADDR_CP.UART)    && binsof(STRB_CP.HALF_HI);
            ignore_bins UART_STRBW   = binsof(ADDR_CP.UART)    && binsof(STRB_CP.WORD);
            ignore_bins SPI_STRB0    = binsof(ADDR_CP.SPI)     && binsof(STRB_CP.BYTE_0);
            ignore_bins SPI_STRB1    = binsof(ADDR_CP.SPI)     && binsof(STRB_CP.BYTE_1);
            ignore_bins SPI_STRB2    = binsof(ADDR_CP.SPI)     && binsof(STRB_CP.BYTE_2);
            ignore_bins SPI_STRB3    = binsof(ADDR_CP.SPI)     && binsof(STRB_CP.BYTE_3);
            ignore_bins SPI_STRBH0   = binsof(ADDR_CP.SPI)     && binsof(STRB_CP.HALF_LO);
            ignore_bins SPI_STRBH1   = binsof(ADDR_CP.SPI)     && binsof(STRB_CP.HALF_HI);
            ignore_bins SPI_STRBW    = binsof(ADDR_CP.SPI)     && binsof(STRB_CP.WORD);
            ignore_bins ILL_STRB0    = binsof(ADDR_CP.ILLEGAL) && binsof(STRB_CP.BYTE_0);
            ignore_bins ILL_STRB1    = binsof(ADDR_CP.ILLEGAL) && binsof(STRB_CP.BYTE_1);
            ignore_bins ILL_STRB2    = binsof(ADDR_CP.ILLEGAL) && binsof(STRB_CP.BYTE_2);
            ignore_bins ILL_STRB3    = binsof(ADDR_CP.ILLEGAL) && binsof(STRB_CP.BYTE_3);
            ignore_bins ILL_STRBH0   = binsof(ADDR_CP.ILLEGAL) && binsof(STRB_CP.HALF_LO);
            ignore_bins ILL_STRBH1   = binsof(ADDR_CP.ILLEGAL) && binsof(STRB_CP.HALF_HI);
            ignore_bins ILL_STRBW    = binsof(ADDR_CP.ILLEGAL) && binsof(STRB_CP.WORD);
        }

        ADDR_x_BRESP : cross ADDR_CP, BRESP_CP;
        ADDR_x_RRESP : cross ADDR_CP, RRESP_CP;

    endgroup

    // ================================================================
    // COVERGROUP 2 — Data Pattern Coverage
    // ================================================================
    covergroup data_pattern_cg;
        option.per_instance = 1;
        option.comment      = "Data Pattern Coverage";

        DATA_CP : coverpoint tr.data {
            bins ZERO         = { 32'h0000_0000 };
            bins ONES         = { 32'hFFFF_FFFF };
            bins ALT_5A       = { 32'h5555_AAAA };
            bins ALT_A5       = { 32'hAAAA_5555 };
            bins WALKING_1    = { 32'h0000_0001, 32'h0000_0002, 32'h0000_0004,
                                  32'h0000_0008, 32'h0000_0010, 32'h0000_0020,
                                  32'h0000_0040, 32'h0000_0080, 32'h0000_0100,
                                  32'h0000_0200, 32'h0000_0400, 32'h0000_0800,
                                  32'h0000_1000, 32'h0000_2000, 32'h0000_4000,
                                  32'h0000_8000, 32'h0001_0000, 32'h0002_0000,
                                  32'h0004_0000, 32'h0008_0000, 32'h0010_0000,
                                  32'h0020_0000, 32'h0040_0000, 32'h0080_0000,
                                  32'h0100_0000, 32'h0200_0000, 32'h0400_0000,
                                  32'h0800_0000, 32'h1000_0000, 32'h2000_0000,
                                  32'h4000_0000, 32'h8000_0000 };
            bins DECERR_MAGIC = { 32'hDEAD_BEEF };
            bins OTHERS       = default;
        }

        DATA_x_CMD : cross DATA_CP, tr.is_write;

    endgroup

    // ================================================================
    // COVERGROUP 3 — DRAM Address Space Coverage
    // ================================================================
    covergroup dram_addr_cg;
        option.per_instance = 1;
        option.comment      = "DRAM Address Space Coverage";

        DRAM_REGION_CP : coverpoint tr.addr {
            bins FIRST_WORD  = { 32'h1000_0000 };
            bins LOW_REGION  = { [32'h1000_0004 : 32'h1000_03FF] };
            bins MID_REGION  = { [32'h1000_0400 : 32'h1000_1FFF] };
            bins HIGH_REGION = { [32'h1000_2000 : 32'h1000_3FFB] };
            bins LAST_WORD   = { 32'h1000_3FFC };
        }

        DRAM_CMD_CP : coverpoint tr.is_write {
            bins WRITE = { 1 };
            bins READ  = { 0 };
        }

        DRAM_REGION_x_CMD : cross DRAM_REGION_CP, DRAM_CMD_CP;

    endgroup

    // ================================================================
    // COVERGROUP 4 — Peripheral Register Coverage
    // ================================================================
    covergroup periph_reg_cg;
        option.per_instance = 1;
        option.comment      = "Peripheral Register Coverage";

        PERIPH_REG_CP : coverpoint tr.addr {
            bins TIMER_CONTROL = { 32'h2000_0000 };
            bins TIMER_PERIOD  = { 32'h2000_0004 };
            bins TIMER_COUNT   = { 32'h2000_0008 };
            bins UART_TX       = { 32'h3000_0000 };
            bins UART_RX       = { 32'h3000_0004 };
            bins UART_STATUS   = { 32'h3000_0008 };
            bins UART_BAUD     = { 32'h3000_000C };
            bins SPI_DATA      = { 32'h4000_0000 };
            bins SPI_CS        = { 32'h4000_0004 };
            bins SPI_STATUS    = { 32'h4000_0008 };
            bins SPI_BAUD      = { 32'h4000_000C };
        }

        PERIPH_CMD_CP : coverpoint tr.is_write {
            bins WRITE = { 1 };
            bins READ  = { 0 };
        }

        PERIPH_REG_x_CMD : cross PERIPH_REG_CP, PERIPH_CMD_CP {
            ignore_bins UART_TX_RD  = binsof(PERIPH_REG_CP.UART_TX)  && binsof(PERIPH_CMD_CP.READ);
            ignore_bins SPI_DATA_RD = binsof(PERIPH_REG_CP.SPI_DATA) && binsof(PERIPH_CMD_CP.READ);
        }

    endgroup

    // ================================================================
    // COVERGROUP 5 — CPU Pipeline Coverage
    // ================================================================
    covergroup cpu_pipeline_cg;
        option.per_instance = 1;
        option.comment      = "CPU Pipeline Coverage";

        RD_CP : coverpoint tr.addr[4:0] {
            bins X1_TO_X7   = { [5'd1  : 5'd7]  };
            bins X8_TO_X15  = { [5'd8  : 5'd15] };
            bins X16_TO_X23 = { [5'd16 : 5'd23] };
            bins X24_TO_X31 = { [5'd24 : 5'd31] };
            ignore_bins X0  = { 5'd0 };
        }

        STORE_CP : coverpoint tr.is_write {
            bins STORE    = { 1 };
            bins NO_STORE = { 0 };
        }

        CPU_DRAM_CP : coverpoint tr.addr {
            bins CPU_DRAM_LOW  = { [32'h1000_0000 : 32'h1000_0FFF] };
            bins CPU_DRAM_HIGH = { [32'h1000_1000 : 32'h1000_3FFF] };
            bins NON_DRAM      = default;
        }

    endgroup

    // ================================================================
    // Constructor
    // ================================================================
    function new(string name, uvm_component parent);
        super.new(name, parent);
        axi_protocol_cg = new();
        data_pattern_cg = new();
        dram_addr_cg    = new();
        periph_reg_cg   = new();
        cpu_pipeline_cg = new();
    endfunction

    // ================================================================
    // write()
    // ================================================================
    virtual function void write(axi_transaction t);
        this.tr = t;
        axi_protocol_cg.sample();
        data_pattern_cg.sample();
        cpu_pipeline_cg.sample();

        if (t.addr >= 32'h1000_0000 && t.addr < 32'h2000_0000)
            dram_addr_cg.sample();

        if (t.addr >= 32'h2000_0000 && t.addr < 32'h5000_0000)
            periph_reg_cg.sample();
    endfunction

    // ================================================================
    // report_phase
    // ================================================================
    virtual function void report_phase(uvm_phase phase);
        real proto_cov  = axi_protocol_cg.get_coverage();
        real data_cov   = data_pattern_cg.get_coverage();
        real dram_cov   = dram_addr_cg.get_coverage();
        real periph_cov = periph_reg_cg.get_coverage();
        real cpu_cov    = cpu_pipeline_cg.get_coverage();
        real total_cov  = (proto_cov + data_cov + dram_cov + periph_cov + cpu_cov) / 5.0;

        `uvm_info("COV", "", UVM_LOW)
        `uvm_info("COV", "======================================================", UVM_LOW)
        `uvm_info("COV", "               FUNCTIONAL COVERAGE REPORT             ", UVM_LOW)
        `uvm_info("COV", "======================================================", UVM_LOW)

        `uvm_info("COV", $sformatf(" AXI Protocol Coverage   : %6.2f%%  (target >90%%)", proto_cov),  UVM_LOW)
        `uvm_info("COV", $sformatf(" Data Pattern Coverage   : %6.2f%%  (target >90%%)", data_cov),   UVM_LOW)
        `uvm_info("COV", $sformatf(" DRAM Address Coverage   : %6.2f%%  (target >90%%)", dram_cov),   UVM_LOW)
        `uvm_info("COV", $sformatf(" Peripheral Reg Coverage : %6.2f%%  (target >80%%)", periph_cov), UVM_LOW)
        `uvm_info("COV", $sformatf(" CPU Pipeline Coverage   : %6.2f%%  (target >80%%)", cpu_cov),    UVM_LOW)

        `uvm_info("COV", "------------------------------------------------------", UVM_LOW)

        `uvm_info("COV", $sformatf(" TOTAL (avg)             : %6.2f%%  (target >90%%)", total_cov), UVM_LOW)

        `uvm_info("COV", "======================================================", UVM_LOW)
        `uvm_info("COV", "", UVM_LOW)

        if (proto_cov  < 90.0) `uvm_warning("COV", $sformatf("AXI Protocol  %.1f%% < 90%% target", proto_cov))
        if (data_cov   < 90.0) `uvm_warning("COV", $sformatf("Data Pattern  %.1f%% < 90%% target", data_cov))
        if (dram_cov   < 90.0) `uvm_warning("COV", $sformatf("DRAM Address  %.1f%% < 90%% target", dram_cov))
        if (periph_cov < 80.0) `uvm_warning("COV", $sformatf("Peripheral    %.1f%% < 80%% target", periph_cov))
        if (cpu_cov    < 80.0) `uvm_warning("COV", $sformatf("CPU Pipeline  %.1f%% < 80%% target", cpu_cov))
    endfunction

endclass