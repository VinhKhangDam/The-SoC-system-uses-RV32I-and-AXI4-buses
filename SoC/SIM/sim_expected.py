"""
sim_expected.py  –  RV32I Golden Reference ISS
================================================
Reads  : instr.mem
Writes : expected.mem

Format of output files (32 lines, x0 first):
    00000000  // x0
    10000000  // x1  (set by LUI prologue in gen_mem.py)
    ...

Register init  : all registers start at 0, matching hardware reset.
                 x1 gets set to 0x1000_0000 by the LUI prologue that
                 gen_mem.py emits as the first instruction — the ISS
                 executes it normally, no special-casing needed.
Control flow   : full PC-driven simulation (BEQ branches, JAL jumps).
Memory (LW/SW) : flat dict — SW stores, LW loads back correctly.
                 All addresses land in DRAM range (x1-based addressing).

Usage:
    python3 sim_expected.py <MEM_SEED>
    python3 sim_expected.py          # seed unused, kept for CLI compat
"""

import os
import sys

# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────
MASK32 = 0xFFFF_FFFF

PERIPH_RESET = {
    0x2000_0000: 0x0000_0000,  # TIMER_CONTROL
    0x2000_0004: 0x0000_0000,  # TIMER_PERIOD
    0x3000_000C: 115200,       # UART_BAUD
    0x4000_0004: 0x0000_0008,  # SPI_CONTROL
    0x4000_000C: 10,           # SPI_BAUD
}

def to_signed32(v):
    v &= MASK32
    return v - (1 << 32) if v & (1 << 31) else v

def to_u32(v):
    return v & MASK32

def sign_ext(val, bits):
    val &= (1 << bits) - 1
    if val & (1 << (bits - 1)):
        val -= (1 << bits)
    return val

def word_base(addr):
    return addr & ~0x3

def load_word(mem, addr):
    return mem.get(word_base(addr), 0)

def store_word(mem, addr, data):
    mem[word_base(addr)] = to_u32(data)

def load_byte(mem, addr):
    word = load_word(mem, addr)
    shift = (addr & 0x3) * 8
    return (word >> shift) & 0xFF

def store_byte(mem, addr, data):
    base = word_base(addr)
    shift = (addr & 0x3) * 8
    word = mem.get(base, 0)
    word &= ~(0xFF << shift)
    word |= (data & 0xFF) << shift
    mem[base] = to_u32(word)

def load_half(mem, addr):
    word = load_word(mem, addr)
    shift = 16 if (addr & 0x2) else 0
    return (word >> shift) & 0xFFFF

def store_half(mem, addr, data):
    base = word_base(addr)
    shift = 16 if (addr & 0x2) else 0
    word = mem.get(base, 0)
    word &= ~(0xFFFF << shift)
    word |= (data & 0xFFFF) << shift
    mem[base] = to_u32(word)
# ──────────────────────────────────────────────────────────────────────────────
# Decode
# ──────────────────────────────────────────────────────────────────────────────
def decode(instr):
    opcode = instr & 0x7F
    rd     = (instr >>  7) & 0x1F
    funct3 = (instr >> 12) & 0x07
    rs1    = (instr >> 15) & 0x1F
    rs2    = (instr >> 20) & 0x1F
    funct7 = (instr >> 25) & 0x7F

    imm_i = sign_ext(instr >> 20, 12)

    imm_s = sign_ext(
        ((instr >> 25) & 0x7F) << 5 | ((instr >> 7) & 0x1F), 12)

    imm_b = sign_ext(
        ((instr >> 31) & 1) << 12 | ((instr >>  7) & 1) << 11 |
        ((instr >> 25) & 0x3F) << 5 | ((instr >>  8) & 0xF) << 1, 13)

    imm_j = sign_ext(
        ((instr >> 31) & 1) << 20 | ((instr >> 12) & 0xFF) << 12 |
        ((instr >> 20) & 1) << 11 | ((instr >> 21) & 0x3FF) << 1, 21)

    imm_u = (instr >> 12) & 0xFFFFF

    return dict(opcode=opcode, rd=rd, rs1=rs1, rs2=rs2,
                funct3=funct3, funct7=funct7,
                imm_i=imm_i, imm_s=imm_s, imm_b=imm_b, imm_j=imm_j,
                imm_u=imm_u)

# ──────────────────────────────────────────────────────────────────────────────
# Execute one instruction
# ──────────────────────────────────────────────────────────────────────────────
def execute(d, regs, mem, pc):
    op  = d['opcode']
    rd  = d['rd']
    rs1 = d['rs1']
    rs2 = d['rs2']
    f3  = d['funct3']
    f7  = d['funct7']

    next_pc = (pc + 4) & MASK32
    result  = None

    # ── R-type ───────────────────────────────────────────────────────────────
    if op == 0b011_0011:
        a  = to_signed32(regs[rs1])
        b  = to_signed32(regs[rs2])
        ua = to_u32(regs[rs1])
        ub = to_u32(regs[rs2])
        sh = ub & 0x1F

        if   f3 == 0b000 and f7 == 0b000_0000: result = a + b
        elif f3 == 0b000 and f7 == 0b010_0000: result = a - b
        elif f3 == 0b111 and f7 == 0b000_0000: result = ua & ub
        elif f3 == 0b110 and f7 == 0b000_0000: result = ua | ub
        elif f3 == 0b100 and f7 == 0b000_0000: result = ua ^ ub
        elif f3 == 0b001 and f7 == 0b000_0000: result = ua << sh
        elif f3 == 0b101 and f7 == 0b000_0000: result = ua >> sh
        elif f3 == 0b101 and f7 == 0b010_0000: result = a  >> sh
        elif f3 == 0b010 and f7 == 0b000_0000: result = 1 if a < b else 0
        elif f3 == 0b011 and f7 == 0b000_0000: result = 1 if ua < ub else 0
        else:
            print(f"[WARN] Unknown R-type f3={f3:03b} f7={f7:07b} @ PC={pc:#010x}")

    # ── I-type ALU ───────────────────────────────────────────────────────────
    elif op == 0b001_0011:
        a   = to_signed32(regs[rs1])
        ua  = to_u32(regs[rs1])
        imm = d['imm_i']
        sh  = (d['imm_i'] & 0x1F)

        if   f3 == 0b000: result = a  + imm
        elif f3 == 0b010: result = 1 if a < imm else 0
        elif f3 == 0b011: result = 1 if ua < to_u32(imm) else 0
        elif f3 == 0b111: result = ua & to_u32(imm)
        elif f3 == 0b110: result = ua | to_u32(imm)
        elif f3 == 0b100: result = ua ^ to_u32(imm)
        elif f3 == 0b001 and f7 == 0b000_0000: result = ua << sh
        elif f3 == 0b101 and f7 == 0b000_0000: result = ua >> sh
        elif f3 == 0b101 and f7 == 0b010_0000: result = a >> sh
        else:
            print(f"[WARN] Unknown I-ALU f3={f3:03b} @ PC={pc:#010x}")

    # ── LUI ──────────────────────────────────────────────────────────────────
    elif op == 0b011_0111:
        result = to_u32(d['imm_u'] << 12)

    # ── AUIPC ────────────────────────────────────────────────────────────────
    elif op == 0b001_0111:
        result = to_u32(pc + (d['imm_u'] << 12))

    # ── LOAD ─────────────────────────────────────────────────────────────────
    elif op == 0b000_0011:
        addr = to_u32(to_signed32(regs[rs1]) + d['imm_i'])

        if f3 == 0b000:      # LB
            result = sign_ext(load_byte(mem, addr), 8)
        elif f3 == 0b001:    # LH
            result = sign_ext(load_half(mem, addr), 16)
        elif f3 == 0b010:    # LW
            result = load_word(mem, addr)
        elif f3 == 0b100:    # LBU
            result = load_byte(mem, addr)
        elif f3 == 0b101:    # LHU
            result = load_half(mem, addr)
        else:
            print(f"[WARN] Unsupported load f3={f3:03b} @ PC={pc:#010x}")

    # ── STORE ────────────────────────────────────────────────────────────────
    elif op == 0b010_0011:
        addr = to_u32(to_signed32(regs[rs1]) + d['imm_s'])
        if f3 == 0b000:      # SB
            store_byte(mem, addr, regs[rs2])
        elif f3 == 0b001:    # SH
            store_half(mem, addr, regs[rs2])
        elif f3 == 0b010:    # SW
            store_word(mem, addr, regs[rs2])
        else:
            print(f"[WARN] Unsupported store f3={f3:03b} @ PC={pc:#010x}")

    # ── BRANCH ───────────────────────────────────────────────────────────────
    elif op == 0b110_0011:
        a     = to_signed32(regs[rs1])
        b     = to_signed32(regs[rs2])
        ua    = to_u32(regs[rs1])
        ub    = to_u32(regs[rs2])
        taken = False
        if   f3 == 0b000: taken = (a == b)
        elif f3 == 0b001: taken = (a != b)
        elif f3 == 0b100: taken = (a <  b)
        elif f3 == 0b101: taken = (a >= b)
        elif f3 == 0b110: taken = (ua <  ub)
        elif f3 == 0b111: taken = (ua >= ub)
        else:
            print(f"[WARN] Unsupported branch f3={f3:03b} @ PC={pc:#010x}")
        if taken:
            next_pc = to_u32(pc + d['imm_b'])

    # ── JAL ──────────────────────────────────────────────────────────────────
    elif op == 0b110_1111:
        result  = next_pc
        next_pc = to_u32(pc + d['imm_j'])

    # ── JALR ─────────────────────────────────────────────────────────────────
    elif op == 0b110_0111:
        if f3 == 0b000:
            result  = next_pc
            next_pc = to_u32((to_signed32(regs[rs1]) + d['imm_i']) & ~1)
        else:
            print(f"[WARN] Unsupported JALR f3={f3:03b} @ PC={pc:#010x}")

    # ── FENCE ─────────────────────────────────────────────────────────────────
    elif op == 0b000_1111:
        pass

    else:
        print(f"[WARN] Unknown opcode={op:#09b} @ PC={pc:#010x}")

    return next_pc, rd, result

# ──────────────────────────────────────────────────────────────────────────────
# Simulate
# ──────────────────────────────────────────────────────────────────────────────
def simulate(instructions):
    """
    All registers start at 0 — matches hardware reset.
    x1 will be set to 0x1000_0000 by the LUI prologue (first instruction).
    """
    regs = [0] * 32

    mem      = dict(PERIPH_RESET)
    pc       = 0
    pc_limit = len(instructions) * 4
    max_steps = max(len(instructions) * 16, 64)
    steps     = 0

    while steps < max_steps:
        if pc < 0 or pc >= pc_limit or (pc & 3) != 0:
            break

        instr = instructions[pc >> 2]

        # ECALL / EBREAK halt this simple CPU model.
        if instr in (0x00000073, 0x00100073):
            break

        d     = decode(instr)

        next_pc, rd, result = execute(d, regs, mem, pc)

        if result is not None and rd != 0:
            regs[rd] = to_u32(result)

        pc     = next_pc
        steps += 1

    return regs

# ──────────────────────────────────────────────────────────────────────────────
# File I/O
# ──────────────────────────────────────────────────────────────────────────────
def load_mem_file(path):
    instructions = []
    with open(path) as f:
        for line in f:
            token = line.split("//")[0].strip()
            if not token:
                continue
            try:
                instructions.append(int(token, 16))
            except ValueError:
                pass
    return instructions

def write_expected(path, regs):
    with open(path, "w") as f:
        for i, v in enumerate(regs):
            f.write(f"{v:08x}  // x{i}\n")
    print(f"Written : {path}")

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Seed argument kept for Makefile compatibility but no longer used
    if len(sys.argv) >= 2:
        try:
            SEED = int(sys.argv[1])
        except ValueError:
            print(f"[ERROR] Seed must be an integer, got: {sys.argv[1]}")
            sys.exit(1)
    else:
        SEED = 0

    instr_path    = os.path.join(script_dir, "instr.mem")
    expected_path = os.path.join(script_dir, "expected.mem")

    if not os.path.exists(instr_path):
        print(f"[ERROR] {instr_path} not found – run gen_mem.py first.")
        sys.exit(1)

    instrs = load_mem_file(instr_path)
    print(f"Loaded  : {len(instrs)} instructions from instr.mem")
    write_expected(expected_path, simulate(instrs))
