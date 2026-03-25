module LSU (
    // Clock and reset
    input logic clk, 
    input logic rstn,

    // Signals communicate with CPU
    // Signal be received from EX-MEM Pipeline
    input logic [31:0] addr_i, // ALUResultM
    input logic [31:0] data_i, // WriteDataM
    input logic we_i, // MemWriteM
    input logic req_i, // MemWriteM | ResultSrc == 0
    input logic [2:0] funct3, // lb, lh, lw, sb, sh, sw
    output logic [31:0] lsu_rdata_o, // ReadDataM
    output logic lsu_stall_o, // lsu_stall

    // Signals communicate AXI-Lite
    // Write Address Channels
    output logic [31:0] m_axi_awaddr,
    output logic [2:0] m_axi_awprot,
    output logic m_axi_awvalid,
    input logic m_axi_awready,
    // Write Data Channels
    output logic [31:0] m_axi_wdata,
    output logic [3:0] m_axi_wstrb,
    output logic m_axi_wvalid,
    input logic m_axi_wready,
    //Response Channels
    input logic [1:0] m_axi_bresp,
    input logic m_axi_bvalid,
    output logic m_axi_bready,
    //Read Address Channels
    output logic [31:0] m_axi_araddr,
    output logic [2:0] m_axi_arprot,
    output logic m_axi_arvalid,
    input logic m_axi_arready,
    //Read Data Channels
    input logic [31:0] m_axi_rdata,
    input logic [1:0] m_axi_rresp,
    input logic m_axi_rvalid,
    output logic m_axi_rready
);
    // Internal States
    typedef enum logic [2:0] { 
        ST_IDLE = 3'b000,
        ST_W_ADDR = 3'b001, // Send AW & W
        ST_W_RESP = 3'b010, // Wait BVALID
        ST_R_ADDR = 3'b011, // Send AR
        ST_R_DATA = 3'b100 // Wait RVALID
    } state_t;

    state_t PresentState, NextState;

    // Internal Signals
    logic [31:0] addr_reg, data_reg;
    logic [2:0] funct3_reg;
    logic [3:0] wstrb_reg;

    // Processing 1 : Processing Signals from CPU
    logic [3:0] wstrb_comb;
    logic [31:0] wdata_comb;

    // Caculate Write Trobe (mask for sb, sh, sw)
    always_comb begin
        case (funct3[1:0])
            2'b00: // sb
                case (addr_i[1:0])
                    2'b00: wstrb_comb = 4'b0001;
                    2'b01: wstrb_comb = 4'b0010;
                    2'b10: wstrb_comb = 4'b0100;
                    2'b11: wstrb_comb = 4'b1000;
                    default: wstrb_comb = 4'b0000;
                endcase
            2'b01:   wstrb_comb = (addr_i[1]) ? 4'b1100 : 4'b0011; // sh
            2'b10:   wstrb_comb = 4'b1111; // sw
            default: wstrb_comb = 4'b0000;
        endcase
    end

    // Write Data Align
    always_comb begin
        case (funct3[1:0])
            2'b00: // Byte
                case (addr_i[1:0])
                    2'b00: wdata_comb = {24'b0, data_i[7:0]};
                    2'b01: wdata_comb = {16'b0, data_i[7:0], 8'b0};
                    2'b10: wdata_comb = {8'b0,  data_i[7:0], 16'b0};
                    2'b11: wdata_comb = {data_i[7:0], 24'b0};
                    default: wdata_comb = 32'b0;
                endcase
            2'b01: // Halfword
                wdata_comb = (addr_i[1]) ? {data_i[15:0], 16'b0} : {16'b0, data_i[15:0]};
            default: // Word
                wdata_comb = data_i;
        endcase
    end

    // Processing 2 : FSM
    always_ff @( posedge clk or negedge rstn ) begin
        if (~rstn) begin
            PresentState <= ST_IDLE;
            addr_reg <= '0;
            data_reg <= '0;
            funct3_reg <= '0;
            wstrb_reg <= '0;
        end else begin
            PresentState <= NextState;
            if (PresentState == ST_IDLE && req_i) begin
                addr_reg   <= addr_i;
                data_reg   <= wdata_comb;
                funct3_reg <= funct3;
                wstrb_reg  <= wstrb_comb;
            end
        end
    end

    always_comb begin
        NextState = PresentState;
        m_axi_awvalid = 1'b0;
        m_axi_wvalid  = 1'b0;
        m_axi_arvalid = 1'b0;
        m_axi_bready  = 1'b0;
        m_axi_rready  = 1'b0;
        lsu_stall_o   = 1'b0;

        case (PresentState)
            ST_IDLE: begin
                if (req_i) begin
                    lsu_stall_o = 1'b1;
                    NextState = (we_i) ? ST_W_ADDR : ST_R_ADDR;
                end
            end

            ST_W_ADDR: begin // Write address
                lsu_stall_o   = 1'b1;
                m_axi_awvalid = 1'b1;
                m_axi_wvalid  = 1'b1;
                if (m_axi_awready && m_axi_wready) 
                    NextState = ST_W_RESP;
            end

            ST_W_RESP: begin // Response
                lsu_stall_o  = 1'b1;
                m_axi_bready = 1'b1;
                if (m_axi_bvalid) begin
                    lsu_stall_o = 1'b0;
                    NextState  = ST_IDLE;
                end
            end

            ST_R_ADDR: begin
                lsu_stall_o   = 1'b1;
                m_axi_arvalid = 1'b1;
                if (m_axi_arready) 
                    NextState = ST_R_DATA;
            end

            ST_R_DATA: begin
                lsu_stall_o  = 1'b1;
                m_axi_rready = 1'b1;
                if (m_axi_rvalid) begin
                    lsu_stall_o = 1'b0;
                    NextState  = ST_IDLE;
                end
            end
            
            default: NextState = ST_IDLE;
        endcase
    end

    assign m_axi_awaddr = addr_reg;
    assign m_axi_araddr = addr_reg;
    assign m_axi_wdata  = data_reg;
    assign m_axi_wstrb  = wstrb_reg;
    assign m_axi_awprot = 3'b000;
    assign m_axi_arprot = 3'b000;

    // Processing 3: Processing signals of read and write (Sign-extension)
    logic [31:0] rdata_aligned;
    always_comb begin
        case (funct3_reg)
            3'b000: begin // LB (Load Byte Signed)
                case (addr_reg[1:0])
                    2'b00: rdata_aligned = {{24{m_axi_rdata[7]}},  m_axi_rdata[7:0]};
                    2'b01: rdata_aligned = {{24{m_axi_rdata[15]}}, m_axi_rdata[15:8]};
                    2'b10: rdata_aligned = {{24{m_axi_rdata[23]}}, m_axi_rdata[23:16]};
                    2'b11: rdata_aligned = {{24{m_axi_rdata[31]}}, m_axi_rdata[31:24]};
                    default: rdata_aligned = 32'b0;
                endcase
            end
            3'b001: begin // LH (Load Half Signed)
                rdata_aligned = (addr_reg[1]) ? {{16{m_axi_rdata[31]}}, m_axi_rdata[31:16]} : 
                                              {{16{m_axi_rdata[15]}}, m_axi_rdata[15:0]};
            end
            3'b010: rdata_aligned = m_axi_rdata; // LW
            3'b100: begin // LBU (Load Byte Unsigned)
                case (addr_reg[1:0])
                    2'b00: rdata_aligned = {24'b0, m_axi_rdata[7:0]};
                    2'b01: rdata_aligned = {24'b0, m_axi_rdata[15:8]};
                    2'b10: rdata_aligned = {24'b0, m_axi_rdata[23:16]};
                    2'b11: rdata_aligned = {24'b0, m_axi_rdata[31:24]};
                    default: rdata_aligned = 32'b0;
                endcase
            end
            3'b101: begin // LHU (Load Half Unsigned)
                rdata_aligned = (addr_reg[1]) ? {16'b0, m_axi_rdata[31:16]} : {16'b0, m_axi_rdata[15:0]};
            end
            default: rdata_aligned = m_axi_rdata;
        endcase
    end

    assign lsu_rdata_o = rdata_aligned;

endmodule