module IF_ID (
    input logic clk,
    input logic rstn,
    input logic [31:0] instrF,
    output logic [31:0] instrD,
    input [31:0] pcF,
    output [31:0] pcD,
    // Harvard
    input stall, 
    input flush
);
    localparam NOP = 32'h0;
    always_ff @(posedge clk or negedge rst) begin
        if (~rstn) begin
            // Reset signals to 0
            instrD <= NOP;
            pcD <= '0;
            // If flush, insert NOP 
        end else if (flush) begin
            instrD <= NOP;
        end else if (!stall) begin
            instrD <= instrF;
            pcD <= pcF;
        end
        // if stall = 1, registers retain their values implicitly
    end
endmodule