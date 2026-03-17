module ControlUnit (
    input  logic [6:0] Opcode,
    input  logic [2:0] funct3,
    input  logic       funct7,        // Instr[30]
    output logic       RegWrite,
    output logic       ResultSrc,
    output logic       MemWrite,
    output logic       Jump,
    output logic       Branch,
    output logic [3:0] ALUControl,    // Đã nâng lên 4 bit
    output logic       ALUSrc,
    output logic [2:0] ImmSrc
);
    // Dây trung gian nối từ MainDecoder sang ALUControl
    logic [1:0] ALUOp_wire; 

    // 1. Khối giải mã chính (Main Decoder)
    MainDecoder md (
        .opcode(Opcode),
        .RegWrite(RegWrite),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .Jump(Jump),
        .Branch(Branch),
        .ALUOp(ALUOp_wire),          // Đã sửa: Nối vào dây ALUOp
        .ALUSrc(ALUSrc),
        .ImmSrc(ImmSrc)
    );

    // 2. Khối điều khiển ALU (ALU Control)
    ALUControl a1 (
        .ALUOp(ALUOp_wire),          // Nhận tín hiệu từ MainDecoder
        .funct3(funct3),
        .funct7b(funct7),            // Tên port phải khớp với module ALUControl bạn viết
        .ALUControl(ALUControl)      // Xuất ra mã lệnh 4-bit cho ALU
    );
    
endmodule