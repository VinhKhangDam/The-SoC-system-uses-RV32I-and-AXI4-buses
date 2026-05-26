module CPU (
    input logic clk,
    input logic rstn,

    // DATA channel (load/store) to LSU
    output logic [31:0] mem_addr_o,
    output logic [31:0] mem_wdata_o,
    output logic        mem_we_o,
    output logic        mem_req_o,
    output logic [ 2:0] mem_funct_o,
    input  logic [31:0] mem_rdata_i,
    input  logic        mem_stall_i,

    // IF channel (instruction fetch) to LSU
    output logic [31:0] if_pc_o,
    output logic        if_req_o,
    input  logic [31:0] if_instr_i,
    input  logic        if_stall_i
);

  // Fetch stage
  logic [31:0] InstrF;
  logic [31:0] PcF, Pc_nextF, PcPlus4F;

  // Decode stage
  logic [31:0] InstrD, PcD, PcPlus4D;
  logic RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD;
  logic [1:0] ResultSrcD;
  logic [3:0] ALUControlD;
  logic [2:0] ImmSrc;
  logic [6:0] Opcode;
  logic [2:0] Funct3, Funct3E, Funct3M;
  logic Funct7;
  logic [4:0] Rs1D, Rs2D, RdD;
  logic [24:0] Immediate;
  logic [31:0] Rd1D, Rd2D, ExtImmD;

  // Branch logic signal
  logic BranchTaken;
  logic JALRD, JALRE;
  logic [31:0] BranchTargetE;
  logic [31:0] JalrTargetE;

  // Execute stage
  logic RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE;
  logic [1:0] ResultSrcE;
  logic [3:0] ALUControlE;
  logic [31:0] Rd1E, Rd2E, ExtImmE, PcE, PcPlus4E;
  logic [4:0] Rs1E, Rs2E, RdE;
  logic PCSrc, Zero;
  logic [1:0] ForwardA, ForwardB;
  logic [31:0] SrcA, SrcB, WriteDataE, ALUResultE, PC_ExtImm;
  logic AUIPCD, AUIPCE;
  logic [31:0] RegSrcA;

  // Memory stage
  logic RegWriteM, MemWriteM;
  logic [1:0] ResultSrcM;
  logic [31:0] ALUResultM, WriteDataM, ReadDataM, PcPlus4M;
  logic [4:0] RdM;

  // Writeback stage
  logic       RegWriteW;
  logic [1:0] ResultSrcW;
  logic [31:0] ALUResultW, ReadDataW, PcPlus4W, ResultW;
  logic [4:0] RdW;

  // Stall/Flush from HazardUnit
  logic StallF, StallD, FlushE, FlushD;

  logic hz_FlushE;

  logic mem_access_m;

  // Combined AXI stall passed into HazardUnit
  logic front_stall;
  assign front_stall = mem_stall_i | if_stall_i;

  // ----------------------------------------------------------------
  // FETCH STAGE
  // ----------------------------------------------------------------
  pc_reg pcmd (
      .clk    (clk),
      .rstn   (rstn),
      .stallF (StallF),
      .pc_next(Pc_nextF),
      .pc     (PcF)
  );

  assign if_pc_o  = PcF;
  assign if_req_o = 1'b1;
  assign InstrF   = if_instr_i;
  assign PcPlus4F = PcF + 32'd4;
  assign Pc_nextF = PCSrc ? PC_ExtImm : PcPlus4F;

  // IF/ID: stall=StallF (lwStall|any_stall), flush=FlushD (pcSrcE)
  IF_ID ifid (
      .clk(clk),
      .rstn(rstn),
      .instrF(InstrF),
      .instrD(InstrD),
      .pcF(PcF),
      .pcD(PcD),
      .pcPlus4F(PcPlus4F),
      .pcPlus4D(PcPlus4D),
      .stall(StallF),
      .flush(FlushD)
  );

  // ----------------------------------------------------------------
  // DECODE STAGE
  // ----------------------------------------------------------------
  assign Opcode    = InstrD[6:0];
  assign Funct3    = InstrD[14:12];
  assign Funct7    = InstrD[30];
  assign Rs1D      = InstrD[19:15];
  assign Rs2D      = InstrD[24:20];
  assign RdD       = InstrD[11:7];
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
      .ImmSrc(ImmSrc),
      .AUIPC(AUIPCD),
      .JALR(JALRD)
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

  signExtend se (
      .immInstr(Immediate),
      .ImmSrc  (ImmSrc),
      .ExtImm  (ExtImmD)
  );

  // ID/EX: stall=StallD (lwStall|any_stall), flush=FlushE (lwStall|pcSrcE)
  ID_EX idexmd (
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
      .Funct3D(Funct3),
      .ExtImmD(ExtImmD),
      .AUIPCD(AUIPCD),
      .JALRD(JALRD),
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
      .Funct3E(Funct3E),
      .AUIPCE(AUIPCE),
      .JALRE(JALRE),
      .flush(FlushE),
      .stall(StallD)
  );

  // ----------------------------------------------------------------
  // EXECUTE STAGE
  // ----------------------------------------------------------------
  // assign SrcA       = (ForwardA == 2'b10) ? ALUResultM : (ForwardA == 2'b01) ? ResultW : Rd1E;
  assign RegSrcA    = (ForwardA == 2'b10) ? ALUResultM : (ForwardB == 2'b01) ? ResultW : Rd1E;
  assign SrcA       = AUIPCE ? PcE : RegSrcA;
  assign WriteDataE = (ForwardB == 2'b10) ? ALUResultM : (ForwardB == 2'b01) ? ResultW : Rd2E;
  assign SrcB       = ALUSrcE ? ExtImmE : WriteDataE;
  // assign PC_ExtImm  = PcE + ExtImmE;

  ALU alu (
      .OpA(SrcA),
      .OpB(SrcB),
      .ALUControl(ALUControlE),
      .ALUResult(ALUResultE),
      .Zero(Zero)
  );

  // EX/MEM: stall=any_stall (lwStall resolved before EX)
  EX_MEM exmemmd (
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
      .stall(front_stall)
  );

  // Logic of BranchTaken
  always_comb begin
    case (Funct3E)
      3'b000:  BranchTaken = (SrcA == WriteDataE);  // BEQ
      3'b001:  BranchTaken = (SrcA != WriteDataE);  // BNE
      3'b100:  BranchTaken = ($signed(SrcA) < $signed(WriteDataE));  // BLT
      3'b101:  BranchTaken = ($signed(SrcA) >= $signed(WriteDataE));  // BGE
      3'b110:  BranchTaken = (SrcA < WriteDataE);  // BLTU
      3'b111:  BranchTaken = (SrcA >= WriteDataE);  // BGEU
      default: BranchTaken = 1'b0;
    endcase  // case (Funct3E)
  end  // always_comb

  assign BranchTargetE = PcE + ExtImmE;
  assign JalrTargetE = (RegSrcA + ExtImmE) & 32'hFFFF_FFFE;
  assign PC_ExtImm = JALRE ? JalrTargetE : BranchTargetE;
  assign PCSrc = JumpE | (BranchE & BranchTaken);

  // ----------------------------------------------------------------
  // MEMORY STAGE — all accesses via LSU over AXI
  // ----------------------------------------------------------------
  assign mem_access_m = MemWriteM || (ResultSrcM == 2'b01);
  assign ReadDataM   = mem_rdata_i;
  assign mem_addr_o  = ALUResultM;
  assign mem_wdata_o = WriteDataM;
  assign mem_we_o    = MemWriteM;
  assign mem_req_o   = mem_access_m;
  assign mem_funct_o = Funct3M;

  MEM_WB memwbmd (
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
      .stall(front_stall)
  );

  // ----------------------------------------------------------------
  // WRITEBACK STAGE
  // ----------------------------------------------------------------
  assign ResultW = (ResultSrcW==2'b10) ? PcPlus4W :
                     (ResultSrcW==2'b01) ? ReadDataW : ALUResultW;

  // ----------------------------------------------------------------
  // HAZARD UNIT
  // any_stall -> lsu_stall; HazardUnit adds lwStall -> StallF/StallD/FlushE/FlushD
  // ----------------------------------------------------------------
  HazardUnit hz (
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
      .stallF(StallF),  // -> pc_reg, IF_ID.stall
      .stallD(StallD),  // -> ID_EX.stall
      .flushE(hz_FlushE),  // -> ID_EX.flush
      .flushD(FlushD),  // -> IF_ID.flush
      .lsu_stall(front_stall)
  );

  assign FlushE = hz_FlushE && !front_stall;

endmodule
