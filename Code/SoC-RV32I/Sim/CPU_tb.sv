`timescale 1ns/1ps

module CPU_tb();
    logic clk, rstn;

    // Instance CPU Top của Khang
    CPU dut (.clk(clk), .rstn(rstn));

    // Tạo xung Clock: chu kỳ 10ns (100MHz)
    always #5 clk = ~clk;

    // Mảng kết quả mong đợi
    logic [31:0] expected_rf [31:0];
    
    // Khai báo chuỗi để chứa tên lệnh và mô tả (Fix lỗi vopt-7070)
    string assembly;
    string description;

    // --- BẢNG KẾT QUẢ MONG ĐỢI ---
    initial begin
        for (int i = 0; i < 32; i++) expected_rf[i] = 32'h0;

        // GIAI ĐOẠN 1: KHỞI TẠO
        expected_rf[1]  = 32'd10;  
        expected_rf[2]  = 32'd20;  
        expected_rf[3]  = 32'd30;  
        expected_rf[4]  = 32'd40;  
        expected_rf[5]  = 32'd50;  
        expected_rf[6]  = 32'd60;  
        expected_rf[7]  = 32'd70;  
        expected_rf[8]  = 32'd80;  
        expected_rf[9]  = 32'd90;  
        expected_rf[10] = 32'd100; 

        // GIAI ĐOẠN 2: TÍNH TOÁN
        expected_rf[11] = 32'd30;  
        expected_rf[12] = 32'd30;  
        expected_rf[13] = 32'd20;  
        expected_rf[14] = 32'd20;  
        expected_rf[15] = 32'd20;  
        expected_rf[16] = 32'd0;   
        expected_rf[17] = 32'h00a00000;  
        expected_rf[18] = 32'd10;  
        expected_rf[19] = 32'd1;   

        // GIAI ĐOẠN 3: DATA MEMORY & LOAD
        expected_rf[20] = 32'd61; // Giá trị cuối cùng sau add x20, x20, x19
        expected_rf[21] = 32'd30;  
        expected_rf[22] = 32'd20;  
    end

    // --- LOGIC ĐIỀU KHIỂN MÔ PHỎNG ---
    initial begin
        clk = 0; rstn = 0;
        #20 rstn = 1;
        $display("\033[0;34m[SYSTEM] Bat dau chay chuong trinh test...\033[0m");

        // Đợi cho đến khi PC chạm địa chỉ kết thúc
        wait (dut.PcF >= 32'h00000098);
        #100; 

        $display("\n==================================================");
        $display("          KET QUA KIEM TRA TU DONG                ");
        $display("==================================================");
        
        for (int i = 1; i <= 25; i++) begin
            if (expected_rf[i] !== 32'h0) begin
                if (dut.rf.reg_internal[i] === expected_rf[i]) begin
                    $display("\033[0;32m [PASS] Reg x%0d = %h\033[0m", i, dut.rf.reg_internal[i]);
                end else begin
                    $display("\033[0;31m [FAIL] Reg x%0d = %h (Expected: %h)\033[0m", 
                             i, dut.rf.reg_internal[i], expected_rf[i]);
                end
            end
        end
        $display("==================================================\n");
        $finish;
    end

    // --- MONITOR DỊCH MÃ LỆNH (DISASSEMBLER) ---
    always @(negedge clk) begin
        if (rstn && dut.InstrD !== 32'hxxxxxxxx && dut.PcD < 32'h000000a0) begin
            
            // 1. Giải mã tên lệnh (Sử dụng gán chuỗi trực tiếp an toàn)
            case (dut.InstrD[6:0])
                7'h33: begin // R-type
                    case (dut.InstrD[14:12])
                        3'h0: assembly = (dut.InstrD[30]) ? "SUB" : "ADD";
                        3'h1: assembly = "SLL";
                        3'h2: assembly = "SLT";
                        3'h4: assembly = "XOR";
                        3'h5: assembly = (dut.InstrD[30]) ? "SRA" : "SRL";
                        3'h6: assembly = "OR";
                        3'h7: assembly = "AND";
                        default: assembly = "R-TYPE";
                    endcase
                end
                7'h13: assembly = "ADDI";
                7'h03: assembly = "LW";
                7'h23: assembly = "SW";
                7'h63: assembly = "BEQ";
                7'h6f: assembly = "JAL";
                default: assembly = "UNKNOWN";
            endcase

            // 2. Sử dụng $sformatf để tạo mô tả hành động (Fix lỗi vopt-7070)
            case (assembly)
                "ADD":  description = $sformatf("x%0d = x%0d + x%0d", dut.RdD, dut.Rs1D, dut.Rs2D);
                "SUB":  description = $sformatf("x%0d = x%0d - x%0d", dut.RdD, dut.Rs1D, dut.Rs2D);
                "ADDI": description = $sformatf("x%0d = x%0d + %0d", dut.RdD, dut.Rs1D, $signed(dut.ExtImmD));
                
                // --- THÊM CÁC DÒNG NÀY VÀO ---
                "AND":  description = $sformatf("x%0d = x%0d & x%0d", dut.RdD, dut.Rs1D, dut.Rs2D);
                "OR":   description = $sformatf("x%0d = x%0d | x%0d", dut.RdD, dut.Rs1D, dut.Rs2D);
                "XOR":  description = $sformatf("x%0d = x%0d ^ x%0d", dut.RdD, dut.Rs1D, dut.Rs2D);
                "SLL":  description = $sformatf("x%0d = x%0d << x%0d[4:0]", dut.RdD, dut.Rs1D, dut.Rs2D);
                "SRL":  description = $sformatf("x%0d = x%0d >> x%0d[4:0]", dut.RdD, dut.Rs1D, dut.Rs2D);
                "SRA":  description = $sformatf("x%0d = x%0d >>> x%0d[4:0]", dut.RdD, dut.Rs1D, dut.Rs2D);
                "SLT":  description = $sformatf("x%0d = (x%0d < x%0d) ? 1 : 0", dut.RdD, dut.Rs1D, dut.Rs2D);
                // -----------------------------

                "LW":   description = $sformatf("x%0d = RAM[x%0d + %0d]", dut.RdD, dut.Rs1D, $signed(dut.ExtImmD));
                "SW":   description = $sformatf("RAM[x%0d + %0d] = x%0d", dut.Rs1D, $signed(dut.ExtImmD), dut.Rs2D);
                "BEQ":  description = $sformatf("if(x%0d == x%0d) jump", dut.Rs1D, dut.Rs2D);
                "JAL":  description = $sformatf("Jump target");
                default: description = "--- Hành động chưa xác định ---";
            endcase

            // 3. In Log ra Terminal
            $display("\033[1;36m[PC:%h]\033[0m \033[1;33m%-6s\033[0m | \033[1;32m%-25s\033[0m | ResW: %h", 
                     dut.PcD, assembly, description, dut.ResultW);
        end
    end
endmodule