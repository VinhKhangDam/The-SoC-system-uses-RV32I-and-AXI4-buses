import random
import sys
import os

# -----------------------------
# ENCODERS
# -----------------------------
def r_type(funct7, rs2, rs1, funct3, rd, opcode=0b0110011):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def i_type(imm, rs1, funct3, rd, opcode):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def s_type(imm, rs2, rs1, funct3, opcode=0b0100011):
    imm11_5 = (imm >> 5) & 0x7F
    imm4_0  = imm & 0x1F
    return (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm4_0 << 7) | opcode

def b_type(imm, rs2, rs1, funct3, opcode=0b1100011):
    imm12  = (imm >> 12) & 0x1
    imm11  = (imm >> 11) & 0x1
    imm105 = (imm >> 5)  & 0x3F
    imm41  = (imm >> 1)  & 0xF
    return (
        (imm12  << 31) | (imm105 << 25) | (rs2 << 20) | (rs1 << 15) |
        (funct3 << 12) | (imm41  << 8)  | (imm11 << 7) | opcode
    )

def j_type(imm, rd, opcode=0b1101111):
    imm20   = (imm >> 20) & 0x1
    imm101  = (imm >> 1)  & 0x3FF
    imm11   = (imm >> 11) & 0x1
    imm1912 = (imm >> 12) & 0xFF
    return (
        (imm20 << 31) | (imm101 << 21) | (imm11 << 20) |
        (imm1912 << 12) | (rd << 7) | opcode
    )

# -----------------------------
# DECODE HELPERS (self-verify)
# -----------------------------
def sign_ext(val, bits):
    if val & (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def decode_b(instr):
    return sign_ext(
        ((instr>>31&1)<<12) | ((instr>>7&1)<<11) |
        ((instr>>25&0x3F)<<5) | ((instr>>8&0xF)<<1), 13)

def decode_j(instr):
    return sign_ext(
        ((instr>>31&1)<<20) | ((instr>>12&0xFF)<<12) |
        ((instr>>20&1)<<11) | ((instr>>21&0x3FF)<<1), 21)

# -----------------------------
# GENERATOR
# -----------------------------
def generate_instr():
    rd  = random.randint(1, 31)
    rs1 = random.randint(1, 31)
    rs2 = random.randint(1, 31)

    instr_type = random.choice(["R", "I", "LW", "SW", "BEQ", "JAL"])

    if instr_type == "R":
        ops = {
            "add": (0b000, 0b0000000), "sub": (0b000, 0b0100000),
            "and": (0b111, 0b0000000), "or" : (0b110, 0b0000000),
            "xor": (0b100, 0b0000000), "sll": (0b001, 0b0000000),
            "srl": (0b101, 0b0000000), "sra": (0b101, 0b0100000),
            "slt": (0b010, 0b0000000),
        }
        name = random.choice(list(ops.keys()))
        funct3, funct7 = ops[name]
        instr = r_type(funct7, rs2, rs1, funct3, rd)
        asm   = f"{name} x{rd}, x{rs1}, x{rs2}"

    elif instr_type == "I":
        imm  = random.randint(-2048, 2047)
        ops  = {"addi": 0b000, "andi": 0b111, "ori": 0b110, "xori": 0b100}
        name = random.choice(list(ops.keys()))
        instr = i_type(imm, rs1, ops[name], rd, 0b0010011)
        asm   = f"{name} x{rd}, x{rs1}, {imm}"

    elif instr_type == "LW":
        imm  = random.randint(-2048, 2047)
        instr = i_type(imm, rs1, 0b010, rd, 0b0000011)
        asm   = f"lw x{rd}, {imm}(x{rs1})"

    elif instr_type == "SW":
        imm  = random.randint(-2048, 2047)
        instr = s_type(imm, rs2, rs1, 0b010)
        asm   = f"sw x{rs2}, {imm}(x{rs1})"

    elif instr_type == "BEQ":
        imm  = random.randint(-128, 128) * 2
        instr = b_type(imm, rs2, rs1, 0b000)
        assert decode_b(instr) == imm
        asm   = f"beq x{rs1}, x{rs2}, {imm}"

    elif instr_type == "JAL":
        imm  = random.randint(-1024, 1024) * 2
        instr = j_type(imm, rd)
        assert decode_j(instr) == imm
        asm   = f"jal x{rd}, {imm}"

    return instr, asm

def generate_file(filepath, header, count, seed):
    random.seed(seed)
    with open(filepath, "w") as f:
        f.write(f"// --- {header} ({count} lines) ---\n")
        for _ in range(count):
            instr, asm = generate_instr()
            f.write(f"{instr:08x}  // {asm}\n")
    print(f"Generated {filepath}  (seed={seed})")

# -----------------------------
# MAIN
# -----------------------------
# Files are written next to this script
script_dir = os.path.dirname(os.path.abspath(__file__))

generate_file(
    os.path.join(script_dir, "cpu_instr.mem"),
    "cpu_instr.mem Automated Testcases", 100, seed=42
)
generate_file(
    os.path.join(script_dir, "instr.mem"),
    "instr.mem Automated Testcases",     100, seed=99
)
