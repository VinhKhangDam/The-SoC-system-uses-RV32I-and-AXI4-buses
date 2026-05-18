module IRAM #(
    parameter ADDR_WIDTH = 16,
    parameter INIT_FILE  = "instr.mem",
    parameter DUMP_WORDS = 256
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
        int loaded_words;

        for (int i = 0; i < MEM_DEPTH; i++)
            mem[i] = 32'h0000_0013; // NOP: ADDI x0, x0, 0

        if (INIT_FILE != "") begin
            $display("[IRAM] Loading file: %s", INIT_FILE);
            $readmemh(INIT_FILE, mem);

            loaded_words = 0;
            for (int i = 0; i < MEM_DEPTH; i++) begin
                if (!$isunknown(mem[i])) begin
                    loaded_words++;
                    if (i < DUMP_WORDS)
                        $display("[IRAM] mem[%0d] = %h", i, mem[i]);
                end
            end

            $display("[IRAM] Loaded %0d instruction words", loaded_words);
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
