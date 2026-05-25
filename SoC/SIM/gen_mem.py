import os
import random
import struct
import sys


def r_type(funct7, rs2, rs1, funct3, rd, opcode=0b0110011):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def i_type(imm, rs1, funct3, rd, opcode):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def u_type(imm, rd, opcode):
    return ((imm & 0xFFFFF) << 12) | (rd << 7) | opcode


def s_type(imm, rs2, rs1, funct3, opcode=0b0100011):
    imm11_5 = (imm >> 5) & 0x7F
    imm4_0 = imm & 0x1F
    return (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm4_0 << 7) | opcode


def b_type(imm, rs2, rs1, funct3, opcode=0b1100011):
    imm12 = (imm >> 12) & 0x1
    imm11 = (imm >> 11) & 0x1
    imm105 = (imm >> 5) & 0x3F
    imm41 = (imm >> 1) & 0xF

    return (
        (imm12 << 31)
        | (imm105 << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (funct3 << 12)
        | (imm41 << 8)
        | (imm11 << 7)
        | opcode
    )


def j_type(imm, rd, opcode=0b1101111):
    imm20 = (imm >> 20) & 0x1
    imm101 = (imm >> 1) & 0x3FF
    imm11 = (imm >> 11) & 0x1
    imm1912 = (imm >> 12) & 0xFF

    return (
        (imm20 << 31)
        | (imm101 << 21)
        | (imm11 << 20)
        | (imm1912 << 12)
        | (rd << 7)
        | opcode
    )


def sign_ext(val, bits):
    if val & (1 << (bits - 1)):
        val -= 1 << bits
    return val


def decode_b(instr):
    return sign_ext(
        ((instr >> 31 & 1) << 12)
        | ((instr >> 7 & 1) << 11)
        | ((instr >> 25 & 0x3F) << 5)
        | ((instr >> 8 & 0xF) << 1),
        13,
    )


def decode_j(instr):
    return sign_ext(
        ((instr >> 31 & 1) << 20)
        | ((instr >> 12 & 0xFF) << 12)
        | ((instr >> 20 & 1) << 11)
        | ((instr >> 21 & 0x3FF) << 1),
        21,
    )


DRAM_BASE_REG = 1
TIMER_BASE_REG = 2
UART_BASE_REG = 3
SPI_BASE_REG = 4

DRAM_BASE_VAL = 0x10000000
TIMER_BASE_VAL = 0x20000000
UART_BASE_VAL = 0x30000000
SPI_BASE_VAL = 0x40000000

SCRATCH_REGS = list(range(5, 32))

CPU_RANDOM_CASES = 54
ALU_DIRECTED_CASES = 14
JAL_CASES = 8
BRANCH_CASES = 40
TIMER_CASES = 30
UART_CASES = 30
SPI_CASES = 20


def make_prologue():
    return [
        (u_type(DRAM_BASE_VAL >> 12, DRAM_BASE_REG, 0b0110111),
         f"lui x{DRAM_BASE_REG}, 0x10000   // x1 = DRAM base 0x1000_0000"),
        (u_type(TIMER_BASE_VAL >> 12, TIMER_BASE_REG, 0b0110111),
         f"lui x{TIMER_BASE_REG}, 0x20000  // x2 = Timer base 0x2000_0000"),
        (u_type(UART_BASE_VAL >> 12, UART_BASE_REG, 0b0110111),
         f"lui x{UART_BASE_REG}, 0x30000   // x3 = UART base 0x3000_0000"),
        (u_type(SPI_BASE_VAL >> 12, SPI_BASE_REG, 0b0110111),
         f"lui x{SPI_BASE_REG}, 0x40000    // x4 = SPI base 0x4000_0000"),
    ]


def lw(rd, base, imm):
    return i_type(imm, base, 0b010, rd, 0b0000011)


def sw(rs2, base, imm):
    return s_type(imm, rs2, base, 0b010)

def make_soc_signature_test():
    return [
        (i_type(0x5A, 0, 0b000, 5, 0b0010011),
         "addi x5, x0, 0x5A"),

        (sw(5, DRAM_BASE_REG, 0x300),
         "sw x5, 0x300(x1) // self-checking write"),

        (lw(6, DRAM_BASE_REG, 0x300),
         "lw x6, 0x300(x1) // self-checking readback"),

        (b_type(8, 6, 5, 0b001),
         "bne x5, x6, fail_signature"),

        (i_type(0x5A, 0, 0b000, 7, 0b0010011),
         "addi x7, x0, 0x5A // PASS signature"),

        (j_type(8, 0),
         "jal x0, write_signature"),

        (i_type(0xA5, 0, 0b000, 7, 0b0010011),
         "addi x7, x0, 0xA5 // FAIL signature"),

        (sw(7, DRAM_BASE_REG, 0x3F0),
         "sw x7, 0x3F0(x1) // SOC software signature"),
    ]

def generate_cpu_random_instr():
    rd = random.choice(SCRATCH_REGS)
    rs1 = random.choice(SCRATCH_REGS)
    rs2 = random.choice(SCRATCH_REGS)

    instr_type = random.choice([
        "R", "R", "R", "R",
        "I", "I", "I",
        "LW", "LW",
        "SW", "SW",
    ])

    if instr_type == "R":
        ops = {
            "add": (0b000, 0b0000000),
            "sub": (0b000, 0b0100000),
            "and": (0b111, 0b0000000),
            "or":  (0b110, 0b0000000),
            "xor": (0b100, 0b0000000),
            "sll": (0b001, 0b0000000),
            "srl": (0b101, 0b0000000),
            "sra": (0b101, 0b0100000),
            "slt": (0b010, 0b0000000),
        }
        name = random.choice(list(ops.keys()))
        funct3, funct7 = ops[name]
        return r_type(funct7, rs2, rs1, funct3, rd), f"[CPU] {name} x{rd}, x{rs1}, x{rs2}"

    if instr_type == "I":
        imm = random.randint(-2048, 2047)
        ops = {
            "addi": 0b000,
            "slti": 0b010,
            "andi": 0b111,
            "ori":  0b110,
            "xori": 0b100,
        }
        name = random.choice(list(ops.keys()))
        return i_type(imm, rs1, ops[name], rd, 0b0010011), f"[CPU] {name} x{rd}, x{rs1}, {imm}"

    if instr_type == "LW":
        imm = random.randint(0, 511) * 4
        return lw(rd, DRAM_BASE_REG, imm), f"[DRAM] lw x{rd}, {imm}(x{DRAM_BASE_REG})"

    imm = random.randint(0, 511) * 4
    return sw(rs2, DRAM_BASE_REG, imm), f"[DRAM] sw x{rs2}, {imm}(x{DRAM_BASE_REG})"


def generate_alu_directed_instr(name):
    rd = random.choice(SCRATCH_REGS)
    rs1 = random.choice(SCRATCH_REGS)
    rs2 = random.choice(SCRATCH_REGS)
    imm = random.randint(-2048, 2047)

    r_ops = {
        "add": (0b000, 0b0000000),
        "sub": (0b000, 0b0100000),
        "sll": (0b001, 0b0000000),
        "slt": (0b010, 0b0000000),
        "xor": (0b100, 0b0000000),
        "srl": (0b101, 0b0000000),
        "sra": (0b101, 0b0100000),
        "or":  (0b110, 0b0000000),
        "and": (0b111, 0b0000000),
    }
    i_ops = {
        "addi": 0b000,
        "slti": 0b010,
        "xori": 0b100,
        "ori":  0b110,
        "andi": 0b111,
    }

    if name in r_ops:
        funct3, funct7 = r_ops[name]
        return r_type(funct7, rs2, rs1, funct3, rd), f"[ALU_COV] {name} x{rd}, x{rs1}, x{rs2}"

    return i_type(imm, rs1, i_ops[name], rd, 0b0010011), f"[ALU_COV] {name} x{rd}, x{rs1}, {imm}"


def generate_jal_instr():
    rd = random.choice([5] + SCRATCH_REGS)
    imm = 4
    instr = j_type(imm, rd)
    assert decode_j(instr) == imm
    return instr, f"[JAL_COV] jal x{rd}, {imm}  // no skip"


def generate_branch_instr(name):
    ops = {
        "beq":  0b000,
        "bne":  0b001,
        "blt":  0b100,
        "bge":  0b101,
        "bltu": 0b110,
        "bgeu": 0b111,
    }

    # +4 gives branch coverage without skipping the randomized SoC accesses.
    imm = 4
    branch_operands = {
        "beq":  (0, 0, "taken"),
        "bne":  (0, random.choice(SCRATCH_REGS), "data-dependent"),
        "blt":  (0, random.choice(SCRATCH_REGS), "data-dependent"),
        "bge":  (0, 0, "taken"),
        "bltu": (0, random.choice(SCRATCH_REGS), "data-dependent"),
        "bgeu": (0, 0, "taken"),
    }

    rs1, rs2, note = branch_operands[name]
    instr = b_type(imm, rs2, rs1, ops[name])
    assert decode_b(instr) == imm
    return instr, f"[BRANCH] {name} x{rs1}, x{rs2}, {imm}  // {note}, no skip"


def generate_timer_instr(kind):
    rd = random.choice(SCRATCH_REGS)
    rs2 = random.choice(SCRATCH_REGS)

    if kind == "wr_ctrl":
        return sw(rs2, TIMER_BASE_REG, 0x0), f"[TIMER] sw x{rs2}, 0(x{TIMER_BASE_REG})  // TIMER_CONTROL"
    if kind == "wr_period":
        return sw(rs2, TIMER_BASE_REG, 0x4), f"[TIMER] sw x{rs2}, 4(x{TIMER_BASE_REG})  // TIMER_PERIOD"
    if kind == "rd_ctrl":
        return lw(rd, TIMER_BASE_REG, 0x0), f"[TIMER] lw x{rd}, 0(x{TIMER_BASE_REG})  // TIMER_CONTROL"
    if kind == "rd_period":
        return lw(rd, TIMER_BASE_REG, 0x4), f"[TIMER] lw x{rd}, 4(x{TIMER_BASE_REG})  // TIMER_PERIOD"
    return lw(0, TIMER_BASE_REG, 0x8), f"[TIMER] lw x0, 8(x{TIMER_BASE_REG})  // TIMER_COUNT volatile"


def generate_uart_instr(kind):
    rd = random.choice(SCRATCH_REGS)
    rs2 = random.choice(SCRATCH_REGS)

    if kind == "wr_tx":
        return sw(rs2, UART_BASE_REG, 0x0), f"[UART] sw x{rs2}, 0(x{UART_BASE_REG})  // UART_TXDATA"
    if kind == "wr_baud":
        return sw(rs2, UART_BASE_REG, 0xC), f"[UART] sw x{rs2}, 12(x{UART_BASE_REG})  // UART_BAUD"
    if kind == "rd_baud":
        return lw(rd, UART_BASE_REG, 0xC), f"[UART] lw x{rd}, 12(x{UART_BASE_REG})  // UART_BAUD"
    if kind == "rd_rx":
        return lw(0, UART_BASE_REG, 0x4), f"[UART] lw x0, 4(x{UART_BASE_REG})  // UART_RXDATA volatile"
    return lw(0, UART_BASE_REG, 0x8), f"[UART] lw x0, 8(x{UART_BASE_REG})  // UART_STATUS volatile"


def generate_spi_instr(kind):
    rd = random.choice(SCRATCH_REGS)
    rs2 = random.choice(SCRATCH_REGS)

    if kind == "wr_data":
        return sw(rs2, SPI_BASE_REG, 0x0), f"[SPI] sw x{rs2}, 0(x{SPI_BASE_REG})  // SPI_DATA"
    if kind == "wr_ctrl":
        return sw(rs2, SPI_BASE_REG, 0x4), f"[SPI] sw x{rs2}, 4(x{SPI_BASE_REG})  // SPI_CONTROL"
    if kind == "wr_baud":
        return sw(rs2, SPI_BASE_REG, 0xC), f"[SPI] sw x{rs2}, 12(x{SPI_BASE_REG})  // SPI_BAUD"
    if kind == "rd_ctrl":
        return lw(rd, SPI_BASE_REG, 0x4), f"[SPI] lw x{rd}, 4(x{SPI_BASE_REG})  // SPI_CONTROL"
    if kind == "rd_baud":
        return lw(rd, SPI_BASE_REG, 0xC), f"[SPI] lw x{rd}, 12(x{SPI_BASE_REG})  // SPI_BAUD"
    if kind == "rd_data":
        return lw(0, SPI_BASE_REG, 0x0), f"[SPI] lw x0, 0(x{SPI_BASE_REG})  // SPI_DATA volatile"
    return lw(0, SPI_BASE_REG, 0x8), f"[SPI] lw x0, 8(x{SPI_BASE_REG})  // SPI_STATUS volatile"


def repeated_randomized(items, count):
    seq = []
    while len(seq) < count:
        shuffled = list(items)
        random.shuffle(shuffled)
        seq.extend(shuffled)
    return seq[:count]


def make_random_cases():
    cases = [("CPU", None)] * CPU_RANDOM_CASES

    cases.extend(("ALU", op) for op in repeated_randomized(
        ["add", "sub", "sll", "slt", "xor", "srl", "sra", "or", "and",
         "addi", "slti", "xori", "ori", "andi"], ALU_DIRECTED_CASES))
    cases.extend(("JAL", None) for _ in range(JAL_CASES))

    cases.extend(("BRANCH", op) for op in repeated_randomized(
        ["beq", "bne", "blt", "bge", "bltu", "bgeu"], BRANCH_CASES))
    cases.extend(("TIMER", op) for op in repeated_randomized(
        ["wr_ctrl", "wr_period", "rd_ctrl", "rd_period", "rd_count"], TIMER_CASES))
    cases.extend(("UART", op) for op in repeated_randomized(
        ["wr_tx", "wr_baud", "rd_baud", "rd_rx", "rd_status"], UART_CASES))
    cases.extend(("SPI", op) for op in repeated_randomized(
        ["wr_data", "wr_ctrl", "wr_baud", "rd_ctrl", "rd_baud", "rd_data", "rd_status"], SPI_CASES))

    random.shuffle(cases)
    return cases


def generate_case(kind, detail):
    if kind == "CPU":
        return generate_cpu_random_instr()
    if kind == "ALU":
        return generate_alu_directed_instr(detail)
    if kind == "JAL":
        return generate_jal_instr()
    if kind == "BRANCH":
        return generate_branch_instr(detail)
    if kind == "TIMER":
        return generate_timer_instr(detail)
    if kind == "UART":
        return generate_uart_instr(detail)
    if kind == "SPI":
        return generate_spi_instr(detail)
    raise ValueError(f"Unknown testcase kind: {kind}")


def generate_file(filepath, header, seed):
    random.seed(seed)

    prologue = make_prologue()
    soc_signature = make_soc_signature_test()
    cases = make_random_cases()
    instr_count = len(prologue) + len(soc_signature) + len(cases)

    with open(filepath, "w") as f:
        f.write(f"// --- {header} ({instr_count} instructions, seed={seed}) ---\n")
        f.write(
            f"// Mix: CPU={CPU_RANDOM_CASES}, ALU={ALU_DIRECTED_CASES}, "
            f"JAL={JAL_CASES}, BRANCH={BRANCH_CASES}, "
            f"TIMER={TIMER_CASES}, UART={UART_CASES}, SPI={SPI_CASES}\n"
        )

        for instr, asm in prologue:
            f.write(f"{instr:08x}  // {asm}\n")
        
        for instr, asm in soc_signature:
            f.write(f"{instr:08x} // {asm}\n")

        for kind, detail in cases:
            instr, asm = generate_case(kind, detail)
            f.write(f"{instr:08x}  // {asm}\n")

    print(f"Generated {filepath}  ({instr_count} instructions, seed={seed})")


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
    "instr.mem Randomized Mixed Testcases",
    SEED,
)
