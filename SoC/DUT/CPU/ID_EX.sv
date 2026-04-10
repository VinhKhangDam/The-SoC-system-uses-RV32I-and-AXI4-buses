module ID_EX (
    // Input
    input logic clk, 
    input logic rstn,
    input logic RegWriteD,
    input logic [1:0] ResultSrcD,
    input logic MemWriteD,
    input logic JumpD,
    input logic BranchD,
    input logic [3:0] ALUControlD,
    input logic ALUSrcD,
    input logic [31:0] rd1D,
    input logic [31:0] rd2D,
    input logic [4:0] rs1D,
    input logic [4:0] rs2D,
    input logic [4:0] rdD, 
    input logic [31:0] pcD,
    input logic [31:0] pcPlus4D,
    input logic [31:0] ExtImmD, 
    input logic [2:0] Funct3D,

    // Output
    output logic RegWriteE,
    output logic [1:0] ResultSrcE,
    output logic MemWriteE,
    output logic JumpE,
    output logic BranchE,
    output logic [3:0] ALUControlE,
    output logic ALUSrcE,
    output logic [31:0] rd1E, 
    output logic [31:0] rd2E,
    output logic [4:0] rs1E, 
    output logic [4:0] rs2E,
    output logic [4:0] rdE, 
    output logic [31:0] pcE,
    output logic [31:0] pcPlus4E,
    output logic [31:0] ExtImmE, 
    output logic [2:0] Funct3E,

    // Harvard Unit
    input logic flush,
    input logic stall
);

    always_ff @(posedge clk or negedge rstn ) begin
        if (~rstn) begin
            RegWriteE <= 0;
            ResultSrcE <= '0;
            MemWriteE <= 0;
            JumpE <= 0;
            BranchE <= 0;
            ALUControlE <= '0;
            ALUSrcE <= 0;
            rd1E <= 32'd0;
            rd2E <= 32'd0;
            rs1E <= 5'd0;
            rs2E <= 5'd0;
            rdE <= 5'd0;
            pcE <= 32'd0;
            pcPlus4E <= 32'd0;
            ExtImmE <= 32'd0;
            Funct3E <= '0;
        end
        else begin
            if (flush) begin
                RegWriteE   <= 0;
                MemWriteE   <= 0;
                JumpE       <= 0;
                BranchE     <= 0;
                ResultSrcE  <= 0;
                ALUControlE <= 0;
                ALUSrcE     <= 0;
                rd1E        <= 32'd0;
                rd2E        <= 32'd0;
                rs1E        <= 5'd0;
                rs2E        <= 5'd0;
                rdE         <= 5'd0;
                ExtImmE     <= 32'd0;
                Funct3E     <= '0;
            end
            else if (!stall) begin
                RegWriteE <= RegWriteD;
                MemWriteE <= MemWriteD;
                ResultSrcE <= ResultSrcD;
                JumpE <= JumpD;
                BranchE <= BranchD;
                ALUControlE <= ALUControlD;
                ALUSrcE <= ALUSrcD;
                rd1E <= rd1D;
                rd2E <= rd2D;
                rs1E <= rs1D;
                rs2E <= rs2D;
                rdE <= rdD;
                pcE <= pcD;
                pcPlus4E <= pcPlus4D;
                ExtImmE <= ExtImmD;
                Funct3E <= Funct3D; 
            end
        end
    end
    
endmodule