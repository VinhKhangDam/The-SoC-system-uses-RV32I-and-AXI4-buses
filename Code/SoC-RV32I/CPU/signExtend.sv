module signExtend (
    input logic [31:7] immInstr,
    input logic [2:0] ImmSrc,
    output logic [31:0] ExtImm
);
    localparam I-TYPE = 3'b000;
    localparam S-TYPE = 3'b001;
    localparam B-TYPE = 3'b010;
    localparam U-TYPE = 3'b011;
    localparam J-TYPE = 3'b100;

    always_comb begin
        case(ImmSrc)
            I-TYPE: ExtImm = {20{immInstr[31]}, immInstr[31:20]};
            S-TYPE: ExtImm = {20{immInstr[31]}, immInstr[31:25], immInstr[4:0]};
            B-TYPE: ExtImm = {19{immInstr[31]}, immInstr[31], immInstr[7], immInstr[30:25], immInstr[11:8], 1'b0};
            U-TYPE: ExtImm = {12{immInstr[31]}, immInstr[31:12]};
            J-TYPE: ExtImm = {11{immInstr[31]}, immInstr[31], immInstr[19:12], immInstr[20], immInstr[30:21], 1'b0};
            default: ExtImm = 32'd0;
        endcase
    end

endmodule