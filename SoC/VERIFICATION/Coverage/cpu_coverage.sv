class cpu_coverage extends uvm_subscriber #(cpu_transaction);
    `uvm_component_utils(cpu_coverage)

    cpu_transaction tr;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic       funct7b;
    logic [4:0] rd;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [31:0] pc;

    covergroup opcode_cg;
        option.per_instance = 1;
        option.comment = "CPU opcode coverage";

        OPCODE_CP : coverpoint opcode {
            bins LOAD   = {7'b0000011};
            bins STORE  = {7'b0100011};
            bins OP_IMM = {7'b0010011};
            bins OP     = {7'b0110011};
            bins BRANCH = {7'b1100011};
            bins JAL    = {7'b1101111};
            bins LUI    = {7'b0110111};
            bins OTHER  = default;
        }
    endgroup

    covergroup alu_cg;
        option.per_instance = 1;
        option.comment = "CPU ALU instruction coverage";

        R_TYPE_CP : coverpoint {funct7b, funct3} iff (opcode == 7'b0110011) {
            bins ADD = {4'b0_000};
            bins SUB = {4'b1_000};
            bins SLL = {4'b0_001};
            bins SLT = {4'b0_010};
            bins XOR = {4'b0_100};
            bins SRL = {4'b0_101};
            bins SRA = {4'b1_101};
            bins OR  = {4'b0_110};
            bins AND = {4'b0_111};
        }

        I_TYPE_CP : coverpoint funct3 iff (opcode == 7'b0010011) {
            bins ADDI = {3'b000};
            bins SLTI = {3'b010};
            bins XORI = {3'b100};
            bins ORI  = {3'b110};
            bins ANDI = {3'b111};
        }
    endgroup

    covergroup branch_cg;
        option.per_instance = 1;
        option.comment = "CPU branch instruction coverage";

        BRANCH_CP : coverpoint funct3 iff (opcode == 7'b1100011) {
            bins BEQ  = {3'b000};
            bins BNE  = {3'b001};
            bins BLT  = {3'b100};
            bins BGE  = {3'b101};
            bins BLTU = {3'b110};
            bins BGEU = {3'b111};
        }
    endgroup

    covergroup register_cg;
        option.per_instance = 1;
        option.comment = "CPU register operand coverage";

        RD_CP : coverpoint rd {
            bins X0      = {5'd0};
            bins LINK    = {5'd1, 5'd5};
            bins LOW     = {[5'd2:5'd7]};
            bins MID     = {[5'd8:5'd23]};
            bins HIGH    = {[5'd24:5'd31]};
        }

        RS1_CP : coverpoint rs1 {
            bins X0      = {5'd0};
            bins NONZERO = {[5'd1:5'd31]};
        }

        RS2_CP : coverpoint rs2 {
            bins X0      = {5'd0};
            bins NONZERO = {[5'd1:5'd31]};
        }

        REG_OPERAND_CROSS : cross RD_CP, RS1_CP, RS2_CP;
    endgroup

    covergroup pc_cg;
        option.per_instance = 1;
        option.comment = "CPU PC alignment coverage";

        PC_ALIGN_CP : coverpoint pc[1:0] {
            bins ALIGNED = {2'b00};
            illegal_bins MISALIGNED = {2'b01, 2'b10, 2'b11};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        opcode_cg   = new();
        alu_cg      = new();
        branch_cg   = new();
        register_cg = new();
        pc_cg       = new();
    endfunction

    virtual function void write(cpu_transaction t);
        tr      = t;
        opcode  = t.instr[6:0];
        funct3  = t.instr[14:12];
        funct7b = t.instr[30];
        rd      = t.instr[11:7];
        rs1     = t.instr[19:15];
        rs2     = t.instr[24:20];
        pc      = t.pc;

        if (!$isunknown(t.instr) && opcode != 7'b0000000)
        begin
            opcode_cg.sample();
            alu_cg.sample();
            branch_cg.sample();
            register_cg.sample();
            pc_cg.sample();
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        real opcode_cov = opcode_cg.get_coverage();
        real alu_cov    = alu_cg.get_coverage();
        real branch_cov = branch_cg.get_coverage();
        real reg_cov    = register_cg.get_coverage();
        real pc_cov     = pc_cg.get_coverage();
        real total_cov  = (opcode_cov + alu_cov + branch_cov + reg_cov + pc_cov) / 5.0;

        `uvm_info("CPU_COV", "", UVM_LOW)
        `uvm_info("CPU_COV", "======================================================", UVM_LOW)
        `uvm_info("CPU_COV", "              CPU FUNCTIONAL COVERAGE REPORT          ", UVM_LOW)
        `uvm_info("CPU_COV", "======================================================", UVM_LOW)

        `uvm_info("CPU_COV", $sformatf(" Opcode Coverage         : %6.2f%%  (target >90%%)", opcode_cov), UVM_LOW)
        `uvm_info("CPU_COV", $sformatf(" ALU Instruction Coverage: %6.2f%%  (target >85%%)", alu_cov),    UVM_LOW)
        `uvm_info("CPU_COV", $sformatf(" Branch Coverage         : %6.2f%%  (target >80%%)", branch_cov), UVM_LOW)
        `uvm_info("CPU_COV", $sformatf(" Register Operand Cover  : %6.2f%%  (target >85%%)", reg_cov),    UVM_LOW)
        `uvm_info("CPU_COV", $sformatf(" PC Alignment Coverage   : %6.2f%%  (target 100%%)", pc_cov),     UVM_LOW)

        `uvm_info("CPU_COV", "------------------------------------------------------", UVM_LOW)
        `uvm_info("CPU_COV", $sformatf(" TOTAL (avg)             : %6.2f%%  (target >90%%)", total_cov), UVM_LOW)
        `uvm_info("CPU_COV", "======================================================", UVM_LOW)
        `uvm_info("CPU_COV", "", UVM_LOW)

        if (opcode_cov < 90.0) `uvm_warning("CPU_COV", $sformatf("Opcode coverage %.1f%% < 90%% target", opcode_cov))
        if (alu_cov    < 85.0) `uvm_warning("CPU_COV", $sformatf("ALU coverage %.1f%% < 85%% target", alu_cov))
        if (branch_cov < 80.0) `uvm_warning("CPU_COV", $sformatf("Branch coverage %.1f%% < 80%% target", branch_cov))
        if (reg_cov    < 85.0) `uvm_warning("CPU_COV", $sformatf("Register coverage %.1f%% < 85%% target", reg_cov))
        if (pc_cov     < 100.0) `uvm_warning("CPU_COV", $sformatf("PC alignment coverage %.1f%% < 100%% target", pc_cov))
    endfunction

endclass
