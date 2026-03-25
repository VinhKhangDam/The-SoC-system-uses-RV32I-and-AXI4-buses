module MainDecoder (
    input  logic [6:0] opcode,
    output logic       RegWrite,
    output logic       ALUSrc,
    output logic       MemWrite,
    output logic [1:0] ResultSrc,
    output logic       Jump,
    output logic       Branch,
    output logic [1:0] ALUOp,      // Nên đặt là ALUOp để phân biệt với ALUControl 4-bit
    output logic [2:0] ImmSrc
);

    always_comb begin
        // Thiết lập giá trị mặc định để tránh tạo Latch
        RegWrite   = 0;
        ALUSrc     = 0;
        MemWrite   = 0;
        ResultSrc  = '0;
        Jump       = 0;
        Branch     = 0;
        ALUOp      = 2'b00;
        ImmSrc     = 3'b000;

        case (opcode)
            7'b0000011: begin // lw (Load Word)
                RegWrite   = 1;
                ImmSrc     = 3'b000; // I-type
                ALUSrc     = 1;
                ResultSrc  = 2'b01;
                ALUOp      = 2'b00;
            end

            7'b0100011: begin // sw (Store Word) - Đã sửa opcode
                ImmSrc     = 3'b001; // S-type
                ALUSrc     = 1;
                MemWrite   = 1;
                ALUOp      = 2'b00;
            end

            7'b0110011: begin // R-Type (add, sub,...)
                RegWrite   = 1;
                ALUOp      = 2'b10;
                ResultSrc  = 2'b00;
                ALUSrc     = '0;
            end

            7'b0010011: begin // I-Type ALU (addi, slli,...)
                RegWrite   = 1;
                ImmSrc     = 3'b000; // I-type
                ALUSrc     = 1;
                ALUOp      = 2'b10;
                ResultSrc  = 2'b00;
            end

            7'b1100011: begin // beq (Branch)
                ImmSrc     = 3'b010; // B-type
                Branch     = 1;      // Đã sửa typo
                ALUOp      = 2'b01;
            end

            7'b1101111: begin // jal (Jump)
                RegWrite   = 1;
                ImmSrc     = 3'b100; // J-type
                Jump       = 1;
                ResultSrc  = 2'b10;
            end
            
            default: ; 
        endcase
    end
    
endmodule