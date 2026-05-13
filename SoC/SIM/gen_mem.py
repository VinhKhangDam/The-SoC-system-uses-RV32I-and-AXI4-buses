import random
import sys
import os
import struct

# ==============================
# ENCODERS
# ==============================
def r_type(funct7, rs2, rs1, funct3, rd, opcode=0b0110011):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def i_type(imm, rs1, funct3, rd, opcode):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def u_type(imm, rd, opcode):
    return ((imm & 0xFFFFF) << 12) | (rd << 7) | opcode

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
        (imm12 << 31) |
        (imm105 << 25) |
        (rs2 << 20) |
        (rs1 << 15) |
        (funct3 << 12) |
        (imm41 << 8) |
        (imm11 << 7) |
        opcode
    )

def j_type(imm, rd, opcode=0b1101111):
    imm20   = (imm >> 20) & 0x1
    imm101  = (imm >> 1)  & 0x3FF
    imm11   = (imm >> 11) & 0x1
    imm1912 = (imm >> 12) & 0xFF

    return (
        (imm20 << 31) |
        (imm101 << 21) |
        (imm11 << 20) |
        (imm1912 << 12) |
        (rd << 7) |
        opcode
    )

# ==============================
# DECODE HELPERS
# ==============================
def sign_ext(val, bits):
    if val & (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def decode_b(instr):
    return sign_ext(
        ((instr >> 31 & 1) << 12) |
        ((instr >> 7  & 1) << 11) |
        ((instr >> 25 & 0x3F) << 5) |
        ((instr >> 8 & 0xF) << 1),
        13
    )

def decode_j(instr):
    return sign_ext(
        ((instr >> 31 & 1) << 20) |
        ((instr >> 12 & 0xFF) << 12) |
        ((instr >> 20 & 1) << 11) |
        ((instr >> 21 & 0x3FF) << 1),
        21
    )

# ==============================
# CONFIG
# ==============================
DRAM_BASE_REG = 1
DRAM_BASE_VAL = 0x10000000

MAX_BEQ = 5
MAX_JAL = 5

beq_count = 0
jal_count = 0

# ==============================
# PROLOGUE
# ==============================
def make_prologue():
    instr = u_type(0x10000, DRAM_BASE_REG, 0b0110111)

    return [
        (
            instr,
            f"lui x{DRAM_BASE_REG}, 0x10000   // x1 = DRAM base 0x1000_0000"
        )
    ]

# ==============================
# INSTRUCTION GENERATOR
# ==============================
def generate_instr(instr_index, total_count):

    global beq_count
    global jal_count

    # x0 = hardwired 0
    # x1 = DRAM base
    rd  = random.randint(2, 31)
    rs1 = random.randint(2, 31)
    rs2 = random.randint(2, 31)

    # Weighted instruction selection
    available_types = [
        "R", "R", "R", "R",
        "I", "I", "I",
        "LW", "LW",
        "SW", "SW"
    ]

    if beq_count < MAX_BEQ:
        available_types.append("BEQ")

    if jal_count < MAX_JAL:
        available_types.append("JAL")

    instr_type = random.choice(available_types)

    # ==========================================
    # R-TYPE
    # ==========================================
    if instr_type == "R":

        ops = {
            "add": (0b000, 0b0000000),
            "sub": (0b000, 0b0100000),
            "and": (0b111, 0b0000000),
            "or" : (0b110, 0b0000000),
            "xor": (0b100, 0b0000000),
            "sll": (0b001, 0b0000000),
            "srl": (0b101, 0b0000000),
            "sra": (0b101, 0b0100000),
            "slt": (0b010, 0b0000000),
        }

        name = random.choice(list(ops.keys()))

        funct3, funct7 = ops[name]

        instr = r_type(
            funct7,
            rs2,
            rs1,
            funct3,
            rd
        )

        asm = f"{name} x{rd}, x{rs1}, x{rs2}"

    # ==========================================
    # I-TYPE
    # ==========================================
    elif instr_type == "I":

        imm = random.randint(-2048, 2047)

        ops = {
            "addi": 0b000,
            "andi": 0b111,
            "ori" : 0b110,
            "xori": 0b100
        }

        name = random.choice(list(ops.keys()))

        instr = i_type(
            imm,
            rs1,
            ops[name],
            rd,
            0b0010011
        )

        asm = f"{name} x{rd}, x{rs1}, {imm}"

    # ==========================================
    # LW
    # ==========================================
    elif instr_type == "LW":

        imm = random.randint(0, 511) * 4

        instr = i_type(
            imm,
            DRAM_BASE_REG,
            0b010,
            rd,
            0b0000011
        )

        asm = f"lw x{rd}, {imm}(x{DRAM_BASE_REG})"

    # ==========================================
    # SW
    # ==========================================
    elif instr_type == "SW":

        imm = random.randint(0, 511) * 4

        instr = s_type(
            imm,
            rs2,
            DRAM_BASE_REG,
            0b010
        )

        asm = f"sw x{rs2}, {imm}(x{DRAM_BASE_REG})"

    # ==========================================
    # BEQ
    # ==========================================
    elif instr_type == "BEQ":

        beq_count += 1

        max_fwd = min(12, (total_count - 1) - instr_index)
        max_bwd = min(12, instr_index)

        lo = -max_bwd
        hi =  max_fwd

        if lo == hi:
            lo, hi = 0, 0

        imm = random.randint(lo, hi) * 4

        instr = b_type(
            imm,
            rs2,
            rs1,
            0b000
        )

        assert decode_b(instr) == imm

        asm = f"beq x{rs1}, x{rs2}, {imm}"

    # ==========================================
    # JAL
    # ==========================================
    elif instr_type == "JAL":

        jal_count += 1

        max_fwd = min(12, (total_count - 1) - instr_index)
        max_bwd = min(12, instr_index)

        lo = -max_bwd
        hi =  max_fwd

        if lo == hi:
            lo, hi = 0, 0

        imm = random.randint(lo, hi) * 4

        instr = j_type(
            imm,
            rd
        )

        assert decode_j(instr) == imm

        asm = f"jal x{rd}, {imm}"

    return instr, asm

# ==============================
# FILE WRITER
# ==============================
def generate_file(filepath, header, count, seed):

    random.seed(seed)

    prologue = make_prologue()

    with open(filepath, "w") as f:

        f.write(
            f"// --- {header} ({count} lines, seed={seed}) ---\n"
        )

        for instr, asm in prologue:
            f.write(f"{instr:08x}  // {asm}\n")

        for i in range(count):
            instr, asm = generate_instr(i, count)
            f.write(f"{instr:08x}  // {asm}\n")

    print(f"Generated {filepath}  (seed={seed})")

# ==============================
# MAIN
# ==============================
if len(sys.argv) >= 2:

    try:
        SEED = int(sys.argv[1])

    except ValueError:
        print(f"[ERROR] Seed must be an integer, got: {sys.argv[1]}")
        sys.exit(1)

else:
    SEED = struct.unpack("I", os.urandom(4))[0]

print(f"[gen_mem] MEM_SEED = {SEED}")

script_dir = os.path.dirname(os.path.abspath(__file__))

generate_file(
    os.path.join(script_dir, "instr.mem"),
    "instr.mem Automated Testcases",
    100,
    SEED
)