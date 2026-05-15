// ============================================================
// cpu_monitor.sv
// Passive monitor that watches:
//   1. CPU pipeline internal signals (via cpu_monitor_inf)
//   2. AXI bus transactions (via soc_inf.mon_cb)
//
// Emits two analysis streams:
//   - fetch_port : one cpu_transaction per fetched instruction
//   - wb_port    : one cpu_wb_transaction per register writeback
//   - axi_port   : one axi_transaction per AXI write/read
// ============================================================
class cpu_monitor extends uvm_monitor;
    `uvm_component_utils(cpu_monitor)

    // Interfaces
    virtual cpu_monitor_inf  cpu_vif;
    virtual soc_inf         axi_vif;
    virtual clk_rst_inf     cr_vif;

    // Analysis ports
    uvm_analysis_port #(cpu_transaction) fetch_port;
    uvm_analysis_port #(cpu_transaction) wb_port;
    uvm_analysis_port #(axi_transaction)    axi_port;

    // Captured state for tracking last fetch (for logging)
    logic [31:0] last_pc_f    = '0;
    logic [31:0] last_instr_f = '0;

    // ======================================================
    // Instruction statistics
    // ======================================================
    int total_instr = 0;
    int cycle_count = 0;

    int instr_stat[string];

    // ---- Instruction mnemonic decoder (for readable logs) ----
    function string decode_instr(logic [31:0] instr);
        logic [6:0] op   = instr[6:0];
        logic [2:0] f3   = instr[14:12];
        logic f7 = instr[30];
        logic [4:0] rd   = instr[11:7];
        logic [4:0] rs1  = instr[19:15];
        logic [4:0] rs2  = instr[24:20];
        logic signed [11:0] imm_i = instr[31:20];
        // U-type immediate [31:12]
        logic [19:0] imm_u = instr[31:12];

        case (op)
            7'b011_0011: begin // R-type
                case ({f7, f3})
                    4'b0_000: return $sformatf("ADD  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    4'b1_000: return $sformatf("SUB  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    4'b0_111: return $sformatf("AND  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    4'b0_110: return $sformatf("OR   x%0d, x%0d, x%0d", rd, rs1, rs2);
                    4'b0_100: return $sformatf("XOR  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    4'b0_001: return $sformatf("SLL  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    4'b0_101: return $sformatf("SRL  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    4'b1_101: return $sformatf("SRA  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    4'b0_010: return $sformatf("SLT  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    default:  return $sformatf("R-?? x%0d, x%0d, x%0d", rd, rs1, rs2);
                endcase
            end
            7'b001_0011: begin // I-ALU
                case (f3)
                    3'b000: return $sformatf("ADDI x%0d, x%0d, %0d",  rd, rs1, $signed(imm_i));
                    3'b111: return $sformatf("ANDI x%0d, x%0d, %0d",  rd, rs1, $signed(imm_i));
                    3'b110: return $sformatf("ORI  x%0d, x%0d, %0d",  rd, rs1, $signed(imm_i));
                    3'b100: return $sformatf("XORI x%0d, x%0d, %0d",  rd, rs1, $signed(imm_i));
                    default:return $sformatf("I-?? x%0d, x%0d, %0d",  rd, rs1, $signed(imm_i));
                endcase
            end
            7'b011_0111: return $sformatf("LUI  x%0d, 0x%0h",        rd, imm_u);  // FIX: was missing
            7'b000_0011: return $sformatf("LW   x%0d, %0d(x%0d)",    rd,  $signed(imm_i), rs1);
            7'b010_0011: return $sformatf("SW   x%0d, %0d(x%0d)",    rs2, $signed(imm_i), rs1);
            7'b110_0011: begin
                case (f3)
                    3'b000: return $sformatf("BEQ  x%0d, x%0d, ...", rs1, rs2);
                    3'b001: return $sformatf("BNE  x%0d, x%0d, ...", rs1, rs2);
                    3'b100: return $sformatf("BLT  x%0d, x%0d, ...", rs1, rs2);
                    3'b101: return $sformatf("BGE  x%0d, x%0d, ...", rs1, rs2);
                    default:return $sformatf("BR?? x%0d, x%0d, ...", rs1, rs2);
                endcase
            end
            7'b110_1111: return $sformatf("JAL  x%0d, ...", rd);
            7'b000_0000: return "NOP";
            default:     return $sformatf("???  [%h]", instr);
        endcase
    endfunction // decode_instr

    function string get_slaves_name(logic [31:0] addr);
       case(addr & 32'hFF00_0000)
         32'h0000_0000: return "IRAM";
         32'h1000_0000: return "DRAM";
         32'h2000_0000: return "TIMER";
         32'h3000_0000: return "UART";
         32'h4000_0000: return "SPI";
         default      : return "UNKNOWN";
       endcase
    endfunction

    function string get_opcode_name(logic [31:0] instr);

        logic [6:0] op = instr[6:0];
        logic [2:0] f3 = instr[14:12];
        logic       f7 = instr[30];

        case (op)

            // =========================
            // R-TYPE
            // =========================
            7'b0110011: begin
                case ({f7,f3})
                    4'b0_000: return "ADD";
                    4'b1_000: return "SUB";
                    4'b0_111: return "AND";
                    4'b0_110: return "OR";
                    4'b0_100: return "XOR";
                    4'b0_001: return "SLL";
                    4'b0_101: return "SRL";
                    4'b1_101: return "SRA";
                    4'b0_010: return "SLT";
                    default:  return "R_UNKNOWN";
                endcase
            end

            // =========================
            // I-TYPE
            // =========================
            7'b0010011: begin
                case (f3)
                    3'b000: return "ADDI";
                    3'b111: return "ANDI";
                    3'b110: return "ORI";
                    3'b100: return "XORI";
                    default:return "I_UNKNOWN";
                endcase
            end

            // =========================
            // LOAD / STORE
            // =========================
            7'b0000011: return "LW";
            7'b0100011: return "SW";

            // =========================
            // BRANCH
            // =========================
            7'b1100011: begin
                case (f3)
                    3'b000: return "BEQ";
                    3'b001: return "BNE";
                    3'b100: return "BLT";
                    3'b101: return "BGE";
                    default:return "BRANCH_UNKNOWN";
                endcase
            end

            // =========================
            // JUMP
            // =========================
            7'b1101111: return "JAL";

            // =========================
            // U-TYPE
            // =========================
            7'b0110111: return "LUI";

            default: return "UNKNOWN";
        endcase

    endfunction

    function new(string name, uvm_component parent);
        super.new(name, parent);
        fetch_port = new("fetch_port", this);
        wb_port    = new("wb_port",    this);
        axi_port   = new("axi_port",   this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual cpu_monitor_inf)::get(
                this, "", "cpu_vif", cpu_vif))
            `uvm_fatal("CPU_MON", "Cannot get cpu_vif")
        if (!uvm_config_db #(virtual soc_inf)::get(
                this, "", "vif_soc", axi_vif))
            `uvm_fatal("CPU_MON", "Cannot get vif_soc (axi)")
        if (!uvm_config_db #(virtual clk_rst_inf)::get(
                this, "", "vif_cr", cr_vif))
            `uvm_fatal("CPU_MON", "Cannot get vif_cr")
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Wait for reset
        @(posedge cr_vif.rstn);
        repeat(2) @(posedge cr_vif.clk);

        `uvm_info("CPU_MON", "=== CPU Monitor started == watching pipeline ===", UVM_LOW)
        `uvm_info("CPU_MON",
            "============================================================", UVM_LOW)

        fork
            monitor_pipeline();
            monitor_axi_writes();
            monitor_axi_reads();
        join_none
    endtask

    // ----------------------------------------------------------
    // 1. Watch pipeline — log every stage each cycle + emit WB
    // ----------------------------------------------------------
    task monitor_pipeline();
        forever begin
            @(cpu_vif.mon_cb);
            cycle_count++;

            // ---- FETCH: log every new PC / instruction ----
            if (cpu_vif.mon_cb.PcF !== last_pc_f && !cpu_vif.mon_cb.StallF) begin
                cpu_transaction fetch_tr;
                last_pc_f    = cpu_vif.mon_cb.PcF;
                last_instr_f = cpu_vif.mon_cb.InstrF;
                fetch_tr       = cpu_transaction::type_id::create("fetch_tr");
                fetch_tr.pc    = cpu_vif.mon_cb.PcF;
                fetch_tr.instr = cpu_vif.mon_cb.InstrF;
                fetch_port.write(fetch_tr);
                `uvm_info("IF",
                    $sformatf("PC=%h  INSTR=%h  [%s]%s",
                        cpu_vif.mon_cb.PcF,
                        cpu_vif.mon_cb.InstrF,
                        decode_instr(cpu_vif.mon_cb.InstrF),
                        cpu_vif.mon_cb.mem_stall_i ? " <AXI_STALL>" : ""),
                    UVM_MEDIUM)
            end

            // ---- DECODE: log Rs1/Rs2/Rd ----
            if (cpu_vif.mon_cb.InstrD !== '0) begin
                `uvm_info("ID",
                    $sformatf("PC=%h  rs1=x%0d rs2=x%0d rd=x%0d  [%s]",
                        cpu_vif.mon_cb.PcD,
                        cpu_vif.mon_cb.Rs1D,
                        cpu_vif.mon_cb.Rs2D,
                        cpu_vif.mon_cb.RdD,
                        decode_instr(cpu_vif.mon_cb.InstrD)),
                    UVM_HIGH)
            end

            // ---- EXECUTE: log ALU result + forwarding ----
            if (cpu_vif.mon_cb.RdE !== '0) begin
                `uvm_info("EX",
                    $sformatf("rd=x%0d  ALU=%h  Fwd=[%b,%b]%s",
                        cpu_vif.mon_cb.RdE,
                        cpu_vif.mon_cb.ALUResultE,
                        cpu_vif.mon_cb.ForwardA,
                        cpu_vif.mon_cb.ForwardB,
                        cpu_vif.mon_cb.PCSrc ?
                            $sformatf("  *** BRANCH/JUMP TAKEN → flush ***") : ""),
                    UVM_HIGH)
            end

            // ---- MEMORY: log store ----
            if (cpu_vif.mon_cb.MemWriteM) begin
                `uvm_info("MEM",
                    $sformatf("STORE Addr=%h Data=%h",
                        cpu_vif.mon_cb.ALUResultM,
                        cpu_vif.mon_cb.WriteDataM),
                    UVM_MEDIUM)
            end

            // ---- WRITEBACK: emit transaction + log ----
            // FIX: guard with !mem_stall_i so we don't fire multiple times
            // during AXI stalls (MEM_WB frozen -> RegWriteW stays high).
            // FIX: capture signals from WB stage only (not M stage).
            if (cpu_vif.mon_cb.RegWriteW && cpu_vif.mon_cb.RdW !== '0
                && !cpu_vif.mon_cb.mem_stall_i) begin
                cpu_transaction tr;
                tr              = cpu_transaction::type_id::create("wb_tr");
                tr.rd           = cpu_vif.mon_cb.RdW;
                tr.result       = cpu_vif.mon_cb.ResultW;   // WB stage result
                // alu_result / mem_write are M-stage signals — only valid when
                // the same instruction is in MEM, not when it has moved to WB.
                // Keep them for debug logging but don't use for correctness checks.
                tr.alu_result   = cpu_vif.mon_cb.ALUResultM;
                tr.mem_write    = cpu_vif.mon_cb.MemWriteM;
                tr.mem_wdata    = cpu_vif.mon_cb.WriteDataM;
                tr.forward_a    = cpu_vif.mon_cb.ForwardA;
                tr.forward_b    = cpu_vif.mon_cb.ForwardB;
                tr.branch_taken = cpu_vif.mon_cb.PCSrc;
                tr.pc    = last_pc_f;
                tr.instr = last_instr_f;

                `uvm_info("WB",
                    $sformatf("x%02d <= %h  (PC~%h)",
                        tr.rd, tr.result, tr.pc),
                    UVM_LOW)

                wb_port.write(tr);
            end

            // ---- HAZARD: log stalls / flushes ----
            if (cpu_vif.mon_cb.StallF)
                `uvm_info("HAZ", "STALL (fetch frozen)", UVM_HIGH)
            if (cpu_vif.mon_cb.FlushE)
                `uvm_info("HAZ", "FLUSH (ID/EX bubble inserted)", UVM_HIGH)
        end
    endtask

    // ----------------------------------------------------------
    // 2. Watch AXI Write channel (CPU stores to DRAM/peripherals)
    // ----------------------------------------------------------
    task monitor_axi_writes();
        forever begin
            axi_transaction tr;
            @(axi_vif.mon_cb);

            if (axi_vif.mon_cb.awvalid && axi_vif.mon_cb.awready) begin
                tr          = axi_transaction::type_id::create("tr");
                tr.addr     = axi_vif.mon_cb.awaddr;
                tr.is_write = 1'b1;

                while (!(axi_vif.mon_cb.wvalid && axi_vif.mon_cb.wready))
                    @(axi_vif.mon_cb);
                tr.data  = axi_vif.mon_cb.wdata;
                tr.wstrb = axi_vif.mon_cb.wstrb;

                while (!(axi_vif.mon_cb.bvalid && axi_vif.mon_cb.bready))
                    @(axi_vif.mon_cb);
                // FIX: was inside wrong block scope due to misaligned 'end'
                tr.bresp = axi_vif.mon_cb.bresp;

                `uvm_info("AXI_WR",
                    $sformatf("CPU -> %s  Addr=%h Data=%h Strb=%b BRESP=%b",
                        get_slaves_name(tr.addr), tr.addr, tr.data, tr.wstrb, tr.bresp),
                    UVM_LOW)

                axi_port.write(tr);
            end
        end
    endtask

    // ----------------------------------------------------------
    // 3. Watch AXI Read channel (CPU loads from DRAM/peripherals)
    // ----------------------------------------------------------
    task monitor_axi_reads();
        forever begin
            axi_transaction tr;
            @(axi_vif.mon_cb);

            if (axi_vif.mon_cb.arvalid && axi_vif.mon_cb.arready) begin
                tr          = axi_transaction::type_id::create("tr");
                tr.addr     = axi_vif.mon_cb.araddr;
                tr.is_write = 1'b0;
                tr.wstrb    = 4'h0;

                while (!(axi_vif.mon_cb.rvalid && axi_vif.mon_cb.rready))
                    @(axi_vif.mon_cb);
                tr.data  = axi_vif.mon_cb.rdata;
                tr.rresp = axi_vif.mon_cb.rresp;

                `uvm_info("AXI_RD",
                    $sformatf("CPU <- %s  Addr=%h Data=%h RRESP=%b",
                        get_slaves_name(tr.addr), tr.addr, tr.data, tr.rresp),
                    UVM_LOW)

                axi_port.write(tr);
            end
        end
    endtask

endclass
