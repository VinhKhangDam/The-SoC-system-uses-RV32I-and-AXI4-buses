module IF_ID (
    input logic clk,
    input logic rstn,
    input logic [31:0] instrF,
    output logic [31:0] instrD,
    input logic [31:0] pcF,
    output logic [31:0] pcD,
    input logic [31:0] pcPlus4F,
    output logic [31:0] pcPlus4D,
    // Harvard
    input stall, 
    input flush
);
    localparam NOP = 32'h0;
    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            // Reset signals to 0
            instrD <= NOP;
            pcD <= '0;
            pcPlus4D <= '0;
            // If flush, insert NOP 
        end else if (flush) begin
            instrD <= NOP;
        end else if (!stall) begin
            instrD <= instrF;
            pcD <= pcF;
            pcPlus4D <= pcPlus4F;
        end
        // if stall = 1, registers retain their values implicitly
    end
endmodule