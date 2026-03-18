module signExtend (
    input logic [24:0] immInstr,
    input logic [2:0] ImmSrc,
    output logic [31:0] ExtImm
);
    localparam I_TYPE = 3'b000;
    localparam S_TYPE = 3'b001;
    localparam B_TYPE = 3'b010;
    localparam U_TYPE = 3'b011;
    localparam J_TYPE = 3'b100;

    always_comb begin
        case(ImmSrc)
            // I-Type: { {21{bit31}}, bit30:20 }
            I_TYPE:  ExtImm = { {21{immInstr[24]}}, immInstr[23:13] };
            // S-Type: { {21{bit31}}, bit30:25, bit11:7 }
            S_TYPE:  ExtImm = { {21{immInstr[24]}}, immInstr[23:18], immInstr[4:0] };
            // B-Type: { {20{bit31}}, bit7, bit30:25, bit11:8, 1'b0 }
            B_TYPE:  ExtImm = { {20{immInstr[24]}}, immInstr[0], immInstr[23:18], immInstr[4:1], 1'b0 };
            // U-Type: { bit31:12, 12'b0 }
            U_TYPE:  ExtImm = { immInstr[24:5], 12'b0 };
            // J-Type: { {12{bit31}}, bit19:12, bit20, bit30:21, 1'b0 }
            J_TYPE:  ExtImm = { {12{immInstr[24]}}, immInstr[12:5], immInstr[13], immInstr[23:14], 1'b0 };
            default: ExtImm = 32'd0;
        endcase
    end

endmodule