module ALU (
    input logic [31:0] OpA, OpB,
    input logic [3:0] ALUControl,
    output logic [31:0] ALUResult,
    output logic Zero
);
    // Logic Group
    localparam AND = 4'b0000;
    localparam OR  = 4'b0001;
    localparam XOR = 4'b0011;

    // Arithmetic Group
    localparam ADD = 4'b0010;
    localparam SUB = 4'b0110;
    localparam SLT = 4'b0111; // Set Less Than

    // Shift Group
    localparam SLL = 4'b0100; // Shift Left Logical
    localparam SRL = 4'b0101; // Shift Right Logical
    localparam SRA = 4'b1001; // Shift Right Arithmetic

    always_comb begin
        case(ALUControl)
            AND : ALUResult = OpA & OpB;
            OR  : ALUResult = OpA | OpB;
            XOR : ALUResult = OpA ^ OpB;
            ADD : ALUResult = OpA + OpB;
            SUB : ALUResult = OpA - OpB;
            SLT : ALUResult = ($signed(OpA) > ($signed(OpB))) ? 32'd0 : 32'd1;
            SLL : ALUResult = OpA << (OpB[4:0]);
            SRL : ALUResult = OpA >> (OpB[4:0]);
            SRA : ALUResult = $signed(OpA) >>> (OpB[4:0]);
            default: ALUResult = 32'd0;
        endcase
    end

    assign Zero = (ALUResult == '0);
endmodule