module ALUControl (
    input  logic [1:0]  ALUOp,
    input  logic [2:0]  funct3,
    input  logic        funct7b,    // Instr[30]
    output logic [3:0]  ALUControl  // Đã nâng lên 4 bit
);
    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 4'b0010; // Add (cho Load/Store/AUIPC)
            2'b01: ALUControl = 4'b0110; // Subtract (cho Branch)
            
            2'b10: begin // R-type hoặc I-type ALU
                case (funct3)
                    3'b000: if (funct7b) 
                                 ALUControl = 4'b0110; // Subtract (sub)
                            else 
                                 ALUControl = 4'b0010; // Add (add, addi)
                    
                    3'b001: ALUControl = 4'b0100; // SLL, SLLI (Dịch trái)
                    
                    3'b010: ALUControl = 4'b0111; // SLT, SLTI (So sánh bé hơn)
                    
                    3'b100: ALUControl = 4'b0011; // XOR, XORI
                    
                    3'b101: if (funct7b)
                                 ALUControl = 4'b1001; // SRA, SRAI (Dịch phải số học)
                            else
                                 ALUControl = 4'b0101; // SRL, SRLI (Dịch phải logic)
                                 
                    3'b110: ALUControl = 4'b0001; // OR, ORI
                    3'b111: ALUControl = 4'b0000; // AND, ANDI
                    
                    default: ALUControl = 4'b0010;
                endcase
            end
            
            default: ALUControl = 4'b0010;
        endcase
    end
endmodule