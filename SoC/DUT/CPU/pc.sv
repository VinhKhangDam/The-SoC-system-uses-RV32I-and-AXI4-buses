module pc_reg (
    input logic clk,
    input logic rstn,
    input logic stallF, //From hazard unit
    input logic [31:0] pc_next,
    output logic [31:0] pc
);

    always_ff @( posedge clk or negedge rstn ) begin
        if (~rstn) begin
            pc <= '0;
        end
        else if (~stallF) begin
            pc <= pc_next;
        end
    end

endmodule