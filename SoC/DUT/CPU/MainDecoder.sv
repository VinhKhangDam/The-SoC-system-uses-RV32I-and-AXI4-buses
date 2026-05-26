module MainDecoder (
    input  logic [6:0] opcode,
    output logic       RegWrite,
    output logic       ALUSrc,
    output logic       MemWrite,
    output logic [1:0] ResultSrc,
    output logic       Jump,
    output logic       Branch,
    output logic [1:0] ALUOp,
    output logic [2:0] ImmSrc,
    output logic       AUIPC,
    output logic       JALR
);

  always_comb begin
    // Set default value to avoid generate latch
    RegWrite  = 0;
    ALUSrc    = 0;
    MemWrite  = 0;
    ResultSrc = '0;
    Jump      = 0;
    Branch    = 0;
    ALUOp     = 2'b00;
    ImmSrc    = 3'b000;
    AUIPC     = 1'b0;
    JALR      = 1'b0;

    case (opcode)
      7'b0000011: begin  // lw (Load Word)
        RegWrite  = 1;
        ImmSrc    = 3'b000;  // I-type
        ALUSrc    = 1;
        ResultSrc = 2'b01;
        ALUOp     = 2'b00;
      end

      7'b0100011: begin  // sw (Store Word)
        ImmSrc   = 3'b001;  // S-type
        ALUSrc   = 1;
        MemWrite = 1;
        ALUOp    = 2'b00;
      end

      7'b0110011: begin  // R-Type (add, sub,...)
        RegWrite  = 1;
        ALUOp     = 2'b10;
        ResultSrc = 2'b00;
        ALUSrc    = '0;
      end

      7'b0010011: begin  // I-Type ALU (addi, slli,...)
        RegWrite  = 1;
        ImmSrc    = 3'b000;  // I-type
        ALUSrc    = 1;
        ALUOp     = 2'b10;
        ResultSrc = 2'b00;
      end

      7'b1100011: begin  // beq (Branch)
        ImmSrc = 3'b010;  // B-type
        Branch = 1;
        ALUOp  = 2'b01;
      end

      7'b1101111: begin  // jal (Jump)
        RegWrite  = 1;
        ImmSrc    = 3'b100;  // J-type
        Jump      = 1;
        ResultSrc = 2'b10;
      end

      7'b0110111: begin  // LUI
        RegWrite  = 1;
        ALUSrc    = 1;
        ResultSrc = 2'b00;
        ALUOp     = 2'b11;  // or dedicated control
        ImmSrc    = 3'b011;  // U-type
      end

      7'b0010111: begin  // AUIPC
        RegWrite  = 1'b1;
        ALUSrc    = 1'b1;
        ResultSrc = 2'b00;
        ALUOp     = 2'b00;  // ADD 
        ImmSrc    = 3'b011;  // U-Type
        AUIPC     = 1'b1;
      end

      7'b1100111: begin  // JALR
        RegWrite  = 1'b1;
        ImmSrc    = 3'b000;  // I-type
        ALUSrc    = 1'b1;
        ResultSrc = 2'b10;  // rd = PC + 4
        Jump      = 1'b1;
        ALUOp     = 2'b00;  // ADD sr1 + Imm 
        JALR      = 1'b1;
      end
      default: ;
    endcase
  end

endmodule
