module LSU (
    // Clock and reset
    input logic clk, 
    input logic rstn,

    // ----------------------------------------------------------------
    // IF Channel : Instruction Fetch (from Fetch Stage / PC)
    // ----------------------------------------------------------------
    input  logic [31:0] if_pc_i,      // PcF  - current PC to fetch
    input  logic        if_req_i,     // 1 every cycle (always want next instr)
    output logic [31:0] if_instr_o,   // fetched instruction -> InstrF
    output logic        if_stall_o,   // stall IF/ID while waiting for IRAM

    // ----------------------------------------------------------------
    // DATA Channel : Load / Store (from EX/MEM pipeline stage)
    // ----------------------------------------------------------------
    input  logic [31:0] addr_i,       // ALUResultM
    input  logic [31:0] data_i,       // WriteDataM
    input  logic        we_i,         // MemWriteM
    input  logic        req_i,        // MemWriteM | ResultSrc==01
    input  logic [2:0]  funct3,       // lb/lh/lw/sb/sh/sw
    output logic [31:0] lsu_rdata_o,  // ReadDataM
    output logic        lsu_stall_o,  // stall whole pipeline during data txn

    // ----------------------------------------------------------------
    // AXI4-Lite Master Port (shared by IF and DATA)
    // ----------------------------------------------------------------
    output logic [31:0] m_axi_awaddr,
    output logic [2:0]  m_axi_awprot,
    output logic        m_axi_awvalid,
    input  logic        m_axi_awready,

    output logic [31:0] m_axi_wdata,
    output logic [3:0]  m_axi_wstrb,
    output logic        m_axi_wvalid,
    input  logic        m_axi_wready,

    input  logic [1:0]  m_axi_bresp,
    input  logic        m_axi_bvalid,
    output logic        m_axi_bready,

    output logic [31:0] m_axi_araddr,
    output logic [2:0]  m_axi_arprot,
    output logic        m_axi_arvalid,
    input  logic        m_axi_arready,

    input  logic [31:0] m_axi_rdata,
    input  logic [1:0]  m_axi_rresp,
    input  logic        m_axi_rvalid,
    output logic        m_axi_rready
);

    // ----------------------------------------------------------------
    // FSM States
    // ST_IDLE      : no transaction in flight
    // ST_IF_ADDR   : sending AR for instruction fetch
    // ST_IF_DATA   : waiting RVALID for instruction fetch
    // ST_W_ADDR    : sending AW+W for data store
    // ST_W_RESP    : waiting BVALID for data store
    // ST_R_ADDR    : sending AR for data load
    // ST_R_DATA    : waiting RVALID for data load
    // ----------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE    = 3'b000,
        ST_IF_ADDR = 3'b001,
        ST_IF_DATA = 3'b010,
        ST_W_ADDR  = 3'b011,
        ST_W_RESP  = 3'b100,
        ST_R_ADDR  = 3'b101,
        ST_R_DATA  = 3'b110
    } state_t;

    state_t PresentState, NextState;

    // ----------------------------------------------------------------
    // Registered transaction context
    // ----------------------------------------------------------------
    logic [31:0] addr_reg, data_reg;
    logic [2:0]  funct3_reg;
    logic [3:0]  wstrb_reg;
    logic [31:0] if_pc_reg;           // latched PC for IF fetch
    logic [31:0] if_instr_reg;        // latched instruction result
    logic [31:0] rdata_reg;

    // ----------------------------------------------------------------
    // DATA channel: write strobe + data alignment (same as before)
    // ----------------------------------------------------------------
    logic [3:0]  wstrb_comb;
    logic [31:0] wdata_comb;

    always_comb begin
        case (funct3[1:0])
            2'b00: // SB
                case (addr_i[1:0])
                    2'b00: wstrb_comb = 4'b0001;
                    2'b01: wstrb_comb = 4'b0010;
                    2'b10: wstrb_comb = 4'b0100;
                    2'b11: wstrb_comb = 4'b1000;
                    default: wstrb_comb = 4'b0000;
                endcase
            2'b01: wstrb_comb = (addr_i[1]) ? 4'b1100 : 4'b0011; // SH
            2'b10: wstrb_comb = 4'b1111;                          // SW
            default: wstrb_comb = 4'b0000;
        endcase
    end

    always_comb begin
        case (funct3[1:0])
            2'b00:
                case (addr_i[1:0])
                    2'b00: wdata_comb = {24'b0, data_i[7:0]};
                    2'b01: wdata_comb = {16'b0, data_i[7:0], 8'b0};
                    2'b10: wdata_comb = {8'b0,  data_i[7:0], 16'b0};
                    2'b11: wdata_comb = {data_i[7:0], 24'b0};
                    default: wdata_comb = 32'b0;
                endcase
            2'b01:
                wdata_comb = (addr_i[1]) ? {data_i[15:0], 16'b0} : {16'b0, data_i[15:0]};
            default:
                wdata_comb = data_i;
        endcase
    end

    // ----------------------------------------------------------------
    // AW / W handshake tracking (data write channel)
    // ----------------------------------------------------------------
    logic aw_handshaked, w_handshaked;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn || PresentState == ST_IDLE) begin
            aw_handshaked <= '0;
            w_handshaked  <= '0;
        end else begin
            if (m_axi_awvalid && m_axi_awready) aw_handshaked <= 1'b1;
            if (m_axi_wvalid  && m_axi_wready)  w_handshaked  <= 1'b1;
        end
    end

    // ----------------------------------------------------------------
    // Sequential: state register + context latch
    // ----------------------------------------------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            PresentState <= ST_IDLE;
            addr_reg     <= '0;
            data_reg     <= '0;
            funct3_reg   <= '0;
            wstrb_reg    <= '0;
            if_pc_reg    <= '0;
            if_instr_reg <= 32'h0000_0013; // NOP (ADDI x0,x0,0)
        end else begin
            PresentState <= NextState;

            // Latch DATA context when a new data request arrives in IDLE
            if (PresentState == ST_IDLE && req_i) begin
                addr_reg   <= addr_i;
                data_reg   <= wdata_comb;
                funct3_reg <= funct3;
                wstrb_reg  <= wstrb_comb;
            end

            // Latch IF PC when starting an IF fetch in IDLE
            if (PresentState == ST_IDLE && if_req_i) begin
                if_pc_reg <= if_pc_i;
            end

            // Capture instruction when IRAM returns data
            if (PresentState == ST_IF_DATA && m_axi_rvalid) begin
                if_instr_reg <= m_axi_rdata;
            end
        end
    end

    // ----------------------------------------------------------------
    // Combinational: FSM next-state + AXI output logic
    //
    // PRIORITY: DATA request > IF request
    //   - If a data req comes while IF is pending, IF is preempted
    //     back to ST_IDLE (data req will be seen next cycle)
    //   - In practice the pipeline is stalled during data, so IF
    //     won't issue a new PC during that time anyway.
    // ----------------------------------------------------------------
    always_comb begin
        // Defaults
        NextState     = PresentState;
        m_axi_awvalid = 1'b0;
        m_axi_wvalid  = 1'b0;
        m_axi_arvalid = 1'b0;
        m_axi_bready  = 1'b0;
        m_axi_rready  = 1'b0;
        lsu_stall_o   = 1'b0;
        if_stall_o    = 1'b0;

        case (PresentState)

            // ----------------------------------------------------------
            ST_IDLE: begin
                if (req_i) begin
                    // DATA request takes priority
                    lsu_stall_o = 1'b1;
                    if_stall_o  = 1'b1;   // also freeze IF while data runs
                    NextState   = (we_i) ? ST_W_ADDR : ST_R_ADDR;
                end else if (if_req_i) begin
                    // No data req — serve instruction fetch
                    if_stall_o = 1'b1;
                    NextState  = ST_IF_ADDR;
                end
            end

            // ----------------------------------------------------------
            // Instruction Fetch path
            // ----------------------------------------------------------
            ST_IF_ADDR: begin
                if_stall_o    = 1'b1;
                m_axi_arvalid = 1'b1;
                // Abort if a DATA request arrives (data has priority)
                if (req_i) begin
                    m_axi_arvalid = 1'b0;
                    lsu_stall_o   = 1'b1;
                    NextState     = (we_i) ? ST_W_ADDR : ST_R_ADDR;
                end else if (m_axi_arready) begin
                    NextState = ST_IF_DATA;
                end
            end

            ST_IF_DATA: begin
                if_stall_o   = 1'b1;
                m_axi_rready = 1'b1;
                if (m_axi_rvalid) begin
                    // Fetch done — instruction is captured in if_instr_reg
                    if_stall_o = 1'b0;
                    NextState  = ST_IDLE;
                end
            end

            // ----------------------------------------------------------
            // Data Write path
            // ----------------------------------------------------------
            ST_W_ADDR: begin
                lsu_stall_o   = 1'b1;
                if_stall_o    = 1'b1;
                m_axi_awvalid = !aw_handshaked;
                m_axi_wvalid  = !w_handshaked;
                if ((aw_handshaked || m_axi_awready) &&
                    (w_handshaked  || m_axi_wready))
                    NextState = ST_W_RESP;
            end

            ST_W_RESP: begin
                lsu_stall_o  = 1'b1;
                if_stall_o   = 1'b1;
                m_axi_bready = 1'b1;
                if (m_axi_bvalid) begin
                    lsu_stall_o = 1'b0;
                    if_stall_o  = 1'b0;
                    NextState   = ST_IDLE;
                end
            end

            // ----------------------------------------------------------
            // Data Read path
            // ----------------------------------------------------------
            ST_R_ADDR: begin
                lsu_stall_o   = 1'b1;
                if_stall_o    = 1'b1;
                m_axi_arvalid = 1'b1;
                if (m_axi_arready)
                    NextState = ST_R_DATA;
            end

            ST_R_DATA: begin
                lsu_stall_o  = 1'b1;
                if_stall_o   = 1'b1;
                m_axi_rready = 1'b1;
                if (m_axi_rvalid) begin
                    lsu_stall_o = 1'b0;
                    if_stall_o  = 1'b0;
                    NextState   = ST_IDLE;
                end
            end

            default: NextState = ST_IDLE;
        endcase
    end

    // ----------------------------------------------------------------
    // AXI address mux: IF fetch uses if_pc_reg, DATA uses addr_reg
    // ----------------------------------------------------------------
    logic is_if_state;
    assign is_if_state = (PresentState == ST_IF_ADDR) || (PresentState == ST_IF_DATA);

    assign m_axi_araddr = is_if_state ? if_pc_reg  : addr_reg;
    assign m_axi_awaddr = addr_reg;
    assign m_axi_wdata  = data_reg;
    assign m_axi_wstrb  = wstrb_reg;
    assign m_axi_awprot = 3'b000;
    assign m_axi_arprot = 3'b000;

    // ----------------------------------------------------------------
    // IF instruction output
    // Hold the last fetched instruction so the pipeline sees a stable
    // value while if_stall_o is low (fetch done, pipeline advancing).
    // ----------------------------------------------------------------
    assign if_instr_o = if_instr_reg;

    // ----------------------------------------------------------------
    // DATA read data with sign-extension (unchanged from original)
    // ----------------------------------------------------------------
    logic [31:0] rdata_aligned;
    always_comb begin
        case (funct3_reg)
            3'b000: begin // LB
                case (addr_reg[1:0])
                    2'b00: rdata_aligned = {{24{m_axi_rdata[7]}},  m_axi_rdata[7:0]};
                    2'b01: rdata_aligned = {{24{m_axi_rdata[15]}}, m_axi_rdata[15:8]};
                    2'b10: rdata_aligned = {{24{m_axi_rdata[23]}}, m_axi_rdata[23:16]};
                    2'b11: rdata_aligned = {{24{m_axi_rdata[31]}}, m_axi_rdata[31:24]};
                    default: rdata_aligned = 32'b0;
                endcase
            end
            3'b001: begin // LH
                rdata_aligned = (addr_reg[1]) ?
                    {{16{m_axi_rdata[31]}}, m_axi_rdata[31:16]} :
                    {{16{m_axi_rdata[15]}}, m_axi_rdata[15:0]};
            end
            3'b010: rdata_aligned = m_axi_rdata; // LW
            3'b100: begin // LBU
                case (addr_reg[1:0])
                    2'b00: rdata_aligned = {24'b0, m_axi_rdata[7:0]};
                    2'b01: rdata_aligned = {24'b0, m_axi_rdata[15:8]};
                    2'b10: rdata_aligned = {24'b0, m_axi_rdata[23:16]};
                    2'b11: rdata_aligned = {24'b0, m_axi_rdata[31:24]};
                    default: rdata_aligned = 32'b0;
                endcase
            end
            3'b101: begin // LHU
                rdata_aligned = (addr_reg[1]) ?
                    {16'b0, m_axi_rdata[31:16]} :
                    {16'b0, m_axi_rdata[15:0]};
            end
            default: rdata_aligned = m_axi_rdata;
        endcase
    end

    always_ff @( posedge clk ) begin
        if (PresentState == ST_R_DATA && m_axi_rvalid)
            rdata_reg <= rdata_aligned;
    end
    assign lsu_rdata_o = rdata_reg;

endmodule