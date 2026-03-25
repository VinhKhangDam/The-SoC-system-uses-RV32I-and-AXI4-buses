module CPU (
    input logic clk,
    input logic rstn,

    output logic [31:0] mem_addr_o,
    output logic [31:0] mem_wdata_o,
    output logic mem_we_o,
    output logic mem_req_o,
    output logic [2:0] mem_funct_o,
    input logic [31:0] mem_rdata_i,
    input logic mem_stall_i
);
    // Internal variables
    // Fetch Stage   
    logic [31:0] InstrF;
    logic StallF, FlushF;
    logic [31:0] PcF, Pc_nextF;
    logic [31:0] PcPlus4F;
    
    // Decode Stage
    // From ID-IF buffer
    logic [31:0] InstrD;
    logic [31:0] PcD;
    logic [31:0] PcPlus4D;
    // Output from Control Unit
    logic RegWriteD;
    logic [1:0] ResultSrcD;
    logic MemWriteD;
    logic JumpD;
    logic BranchD;
    logic [3:0] ALUControlD;
    logic ALUSrcD;
    logic [2:0] ImmSrc;
    // Field of Instruction
    logic [6:0] Opcode;
    logic [2:0] Funct3, Funct3E, Funct3M; 
    logic Funct7;
    logic [4:0] Rs1D;
    logic [4:0] Rs2D;
    logic [4:0] RdD;
    logic [24:0] Immediate;
    // Output of Register File
    logic [31:0] Rd1D, Rd2D;
    // SignExtend
    logic [31:0] ExtImmD;
    
    // Execution Stage
    logic RegWriteE;
    logic [1:0] ResultSrcE;
    logic JumpE;
    logic BranchE;
    logic [3:0] ALUControlE;
    logic ALUSrcE;
    logic [31:0] Rd1E;
    logic [31:0] Rd2E;
    logic [4:0] Rs1E;
    logic [4:0] Rs2E;
    logic [4:0] RdE;
    logic [31:0] PcE;
    logic [31:0] PcPlus4E;
    logic [31:0] ExtImmE;
    logic PCSrc;
    logic Zero;
    logic [1:0] ForwardA, ForwardB;
    logic [31:0] SrcA, SrcB;
    logic [31:0] ALUResultE;
    logic [31:0] PC_ExtImm;
    logic [31:0] WriteDataE;
    logic FlushE;
    logic MemWriteE;

    // Memory stage
    logic RegWriteM;
    logic [1:0] ResultSrcM;
    logic MemWriteM;
    logic [31:0] ALUResultM;
    logic [31:0] WriteDataM;
    logic [4:0] RdM;
    logic [31:0] PcPlus4M;
    logic [31:0] ReadDataM;

    //Writeback stage
    logic RegWriteW;
    logic [1:0] ResultSrcW;
    logic [31:0] ALUResultW;
    logic [31:0] ReadDataW;
    logic [4:0] RdW;
    logic [31:0] PcPlus4W;
    logic [31:0] ResultW;
    
    // Fetch Stage processing
    pc_reg pcmd (
        .clk(clk),
        .rstn(rstn),
        .stallF(StallF),
        .pc_next(Pc_nextF),
        .pc(PcF)
    );
    
    instr_mem inmem (
        .addr (PcF),
        .instr(InstrF)
    );

    assign PcPlus4F = PcF + 32'd4;
    assign Pc_nextF = (PCSrc) ? (PC_ExtImm) : (PcPlus4F);

    // Buffer IF-ID
    IF_ID ifid (
        .clk(clk),
        .rstn(rstn),
        .instrF(InstrF),
        .instrD(InstrD),
        .pcF(PcF),
        .pcD(PcD),
        .pcPlus4F(PcPlus4F),
        .pcPlus4D(PcPlus4D),
        .stall(mem_stall_i),
        .flush(FlushF)
    );

    // Decode Stage Processing

    // Assing field of Instruction
    assign Opcode = InstrD[6:0];
    assign Funct3 = InstrD[14:12];
    assign Funct7 = InstrD[30];
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    assign RdD = InstrD[11:7];
    assign Immediate = InstrD[31:7];

    ControlUnit cu (
        .Opcode(Opcode),
        .funct3(Funct3),
        .funct7(Funct7),
        .RegWrite(RegWriteD),
        .ResultSrc(ResultSrcD),
        .MemWrite(MemWriteD),
        .Jump(JumpD),
        .Branch(BranchD),
        .ALUControl(ALUControlD),
        .ALUSrc(ALUSrcD),
        .ImmSrc(ImmSrc)
    );

    RegFile rf (
        .clk(clk),
        .rstn(rstn),
        .rs1(Rs1D),
        .rs2(Rs2D),
        .rd(RdW),
        .WriteData(ResultW),
        .write_enable(RegWriteW),
        .rd1(Rd1D),
        .rd2(Rd2D)
    );

    signExtend se(
        .immInstr(Immediate),
        .ImmSrc(ImmSrc),
        .ExtImm(ExtImmD)
    );

    ID_EX idexmd(
        .clk(clk),
        .rstn(rstn),
        .RegWriteD(RegWriteD),
        .MemWriteD(MemWriteD),
        .ResultSrcD(ResultSrcD),
        .JumpD(JumpD),
        .BranchD(BranchD),
        .ALUControlD(ALUControlD),
        .ALUSrcD(ALUSrcD),
        .rd1D(Rd1D),
        .rd2D(Rd2D),
        .rs1D(Rs1D),
        .rs2D(Rs2D),
        .rdD(RdD),
        .pcD(PcD),
        .pcPlus4D(PcPlus4D),
        .Funct3D(Funct3)
        .ExtImmD(ExtImmD),
        .RegWriteE(RegWriteE),
        .MemWriteE(MemWriteE),
        .ResultSrcE(ResultSrcE),
        .JumpE(JumpE),
        .BranchE(BranchE),
        .ALUControlE(ALUControlE),
        .ALUSrcE(ALUSrcE),
        .rd1E(Rd1E),
        .rd2E(Rd2E),
        .rs1E(Rs1E),
        .rs2E(Rs2E),
        .rdE(RdE),
        .pcE(PcE),
        .pcPlus4E(PcPlus4E),
        .ExtImmE(ExtImmE),
        .flush(FlushE),
        .Funct3E(Funct3E),
        .stall(mem_stall_i)
    );

    // Execution Processing
    assign PCSrc = JumpE | (Zero & BranchE);
    assign SrcA = (ForwardA == 2'b10) ? ALUResultM : 
                (ForwardA == 2'b01) ? ResultW    : Rd1E;

    assign WriteDataE = (ForwardB == 2'b10) ? ALUResultM : 
                        (ForwardB == 2'b01) ? ResultW    : Rd2E;

    assign SrcB = (ALUSrcE) ? ExtImmE : WriteDataE;
    assign PC_ExtImm = PcE + ExtImmE;

    ALU alu(
        .OpA(SrcA),
        .OpB(SrcB),
        .ALUControl(ALUControlE),
        .ALUResult(ALUResultE),
        .Zero(Zero)
    );

    EX_MEM exmemmd(
        .clk(clk),
        .rstn(rstn),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .ALUResultE(ALUResultE),
        .WriteDataE(WriteDataE),
        .rdE(RdE),
        .pcPlus4E(PcPlus4E),
        .Funct3E(Funct3E),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .MemWriteM(MemWriteM),
        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),
        .rdM(RdM),
        .pcPlus4M(PcPlus4M),
        .Funct3M(Funct3M),
        .stall(mem_stall_i)
    );

    // Mem processing
    // Data mem will use in Test CPU, but i want to design a Soc so I decide remove data mem and use LSU
    // data_mem dm(
    //     .clk(clk),
    //     .rstn(rstn),
    //     .WE(MemWriteM),
    //     .ALUResult(ALUResultM),
    //     .WriteData(WriteDataM),
    //     .ReadData(ReadDataM)
    // );

    assign mem_addr_o   = ALUResultM;
    assign mem_wdata_o  = WriteDataM;
    assign mem_we_o     = MemWriteM;
    assign mem_req_o    = MemWriteM | (ResultSrcM == 2'b01);
    assign mem_funct3_o = Funct3M;
    assign ReadDataM    = mem_rdata_i;

    MEM_WB memwbmd(
        .clk(clk),
        .rstn(rstn),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .ALUResultM(ALUResultM),
        .ReadDataM(ReadDataM),
        .rdM(RdM),
        .pcPlus4M(PcPlus4M),
        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW),
        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .rdW(RdW),
        .pcPlus4W(PcPlus4W),
        .stall(mem_stall_i)
    );

    // WriteBack processing
    assign ResultW = (ResultSrcW == 2'b10) ? PcPlus4W : 
                 (ResultSrcW == 2'b01) ? ReadDataW : 
                                         ALUResultW;

    HazardUnit hz(
        .rs1D(Rs1D),
        .rs2D(Rs2D),
        .rs1E(Rs1E),
        .rs2E(Rs2E),
        .rdE(RdE),
        .rdM(RdM),
        .rdW(RdW),
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .ResultSrc0(ResultSrcE[0]),
        .pcSrcE(PCSrc),
        .forwardAE(ForwardA),
        .forwardBE(ForwardB),
        .stallF(StallF),
        .stallD(StallD),
        .flushE(FlushE),
        .flushD(FlushD),
        .lsu_stall(mem_stall_i)
    );

endmodule   