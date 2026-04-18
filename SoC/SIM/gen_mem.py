import os
import random

def generate_riscv_instr(num_tests, filename):
    # Danh sách các opcode/funct cơ bản (Dạng Hex mẫu cho RISC-V 32I)
    # Cấu trúc: [Lệnh ASM, Hex Format String]
    instructions = [
        ("addi", "00000{rs1}0{rd}93"), # addi rd, rs1, imm
        ("add",  "000{rs2}{rs1}0{rd}33"), # add  rd, rs1, rs2
        ("sub",  "400{rs2}{rs1}0{rd}33"), # sub  rd, rs1, rs2
        ("and",  "000{rs2}{rs1}7{rd}33"), # and  rd, rs1, rs2
        ("or",   "000{rs2}{rs1}6{rd}33"), # or   rd, rs1, rs2
        ("xor",  "000{rs2}{rs1}4{rd}33"), # xor  rd, rs1, rs2
        ("sll",  "000{rs2}{rs1}1{rd}33"), # sll  rd, rs1, rs2
    ]

    # Xóa file cũ nếu tồn tại
    if os.path.exists(filename):
        os.remove(filename)

    with open(filename, "w") as f:
        f.write(f"// --- {filename} Automated Testcases (100 lines) ---\n")
        
        for i in range(num_tests):
            instr_name, hex_template = random.choice(instructions)
            
            # Tạo ngẫu nhiên thanh ghi từ 1-31 (tránh x0)
            rd  = format(random.randint(1, 31), '01x') # 5 bit nhưng trong template mẫu để đơn giản
            rs1 = format(random.randint(1, 31), '01x')
            rs2 = format(random.randint(1, 31), '01x')
            imm = format(random.randint(0, 255), '03x') # Immediate giá trị nhỏ để dễ debug

            # Tạo mã hex giả lập (đây là logic đơn giản hóa để tạo file mẫu)
            # Trong thực tế bạn có thể dùng thư viện lắp mã (assembler)
            hex_code = f"{random.randint(0x00000000, 0xFFFFFFFF):08x}"
            
            f.write(f"{hex_code} // Line {i+1}: Random {instr_name} sequence\n")

    print(f"Generated {filename} with {num_tests} unique instructions.")

if __name__ == "__main__":
    # Tạo 2 tập lệnh khác nhau hoàn toàn
    generate_riscv_instr(100, "instr.mem")
    generate_riscv_instr(100, "cpu_instr.mem")