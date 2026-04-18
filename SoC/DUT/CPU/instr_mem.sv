module instr_mem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    // Memory array: 256 x 32-bit (1KB)
    logic [31:0] mem [0:255];

    initial begin
        // Thêm đường dẫn nếu cần, ví dụ: "../CPU/instr.memh"
        $readmemh("cpu_instr.mem", mem);
        
        // Kiểm tra xem lệnh đầu tiên có dữ liệu không
        if (mem[0] === 32'bx || mem[0] === 32'bz) begin
            $display("--- ERROR: Khong tim thay file instr.memh hoac file rong! ---");
        end else begin
            $display("--- SUCCESS: Da nap chuong trinh vao Instruction Memory ---");
        end
    end

    // Đọc không đồng bộ: PC thay đổi là Instr thay đổi ngay
    assign instr = mem[addr[9:2]];

endmodule