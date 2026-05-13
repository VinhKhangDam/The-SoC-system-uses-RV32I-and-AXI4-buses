module IRAM #(
    parameter ADDR_WIDTH = 14,
    parameter INIT_FILE  = "instr.mem"
)(
    input  logic        clk,
    input  logic        rstn,

    // AXI READ ADDRESS CHANNEL
    input  logic [31:0] s_axi_araddr,
    input  logic [2:0]  s_axi_arprot,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // AXI READ DATA CHANNEL
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready
);

    localparam MEM_DEPTH = (2**ADDR_WIDTH)/4;

    logic [31:0] mem [0:MEM_DEPTH-1];

    wire [ADDR_WIDTH-3:0] read_index;

    assign read_index = s_axi_araddr[ADDR_WIDTH-1:2];

    // =========================================================
    // LOAD INSTRUCTION MEMORY
    // =========================================================
    initial begin
        if (INIT_FILE != "") begin
            $display("[IRAM] Loading file: %s", INIT_FILE);
            $readmemh(INIT_FILE, mem);

            for (int i = 0; i < 101; i++) begin
                $display("[IRAM] mem[%0d] = %h", i, mem[i]);
            end
        end
    end

    // =========================================================
    // READ LOGIC
    // =========================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'h0;
        end
        else begin

            // AR handshake
            s_axi_arready <= !s_axi_arready && s_axi_arvalid;

            // Read response
            if (s_axi_arready && s_axi_arvalid) begin
                s_axi_rdata  <= mem[read_index];
                s_axi_rvalid <= 1'b1;
            end
            else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    assign s_axi_rresp = 2'b00;

endmodule