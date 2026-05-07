"""
sim_expected.py  –  RV32I Golden Reference ISS
================================================
Reads  : instr.mem  (and cpu_instr.mem if present)
Writes : expected.mem  /  cpu_expected.mem

Format of output files (32 lines, x0 first):
    00000000  // x0
    a3f12c44  // x1
    ...

Register init  : x0 = 0 always; x1-x31 = random values seeded with the
                 same MEM_SEED that gen_mem.py used, so both scripts stay
                 in perfect lock-step.
Control flow   : full PC-driven simulation (BEQ branches, JAL jumps).
Memory (LW/SW) : modelled as a flat dict – stores/loads work but do not
                 affect any real memory image (scoreboard checks regs only).

Usage:
    python3 sim_expected.py <MEM_SEED>
    python3 sim_expected.py          # seed=0 fallback (deterministic)
"""

import random
import os
import sys

# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────
MASK32 = 0xFFFF_FFFF

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

# ──────────────────────────────────────────────────────────────────────────────
# Decode  –  returns a dict with every field the executor needs
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

    return dict(opcode=opcode, rd=rd, rs1=rs1, rs2=rs2,
                funct3=funct3, funct7=funct7,
                imm_i=imm_i, imm_s=imm_s, imm_b=imm_b, imm_j=imm_j)

# ──────────────────────────────────────────────────────────────────────────────
# Execute one instruction
# Returns (next_pc, rd, result)  –  caller does the register write-back
# ──────────────────────────────────────────────────────────────────────────────
def execute(d, regs, mem, pc):
    op      = d['opcode']
    rd      = d['rd']
    rs1     = d['rs1']
    rs2     = d['rs2']
    f3      = d['funct3']
    f7      = d['funct7']

    next_pc = (pc + 4) & MASK32
    result  = None   # written to rd only when not None

    # ── R-type  opcode 0110011 ────────────────────────────────────────────────
    if op == 0b011_0011:
        a  = to_signed32(regs[rs1])
        b  = to_signed32(regs[rs2])
        ua = to_u32(regs[rs1])
        ub = to_u32(regs[rs2])
        sh = ub & 0x1F   # shift amount

        if   f3 == 0b000 and f7 == 0b000_0000: result = a + b      # ADD
        elif f3 == 0b000 and f7 == 0b010_0000: result = a - b      # SUB
        elif f3 == 0b111 and f7 == 0b000_0000: result = ua & ub    # AND
        elif f3 == 0b110 and f7 == 0b000_0000: result = ua | ub    # OR
        elif f3 == 0b100 and f7 == 0b000_0000: result = ua ^ ub    # XOR
        elif f3 == 0b001 and f7 == 0b000_0000: result = ua << sh   # SLL
        elif f3 == 0b101 and f7 == 0b000_0000: result = ua >> sh   # SRL
        elif f3 == 0b101 and f7 == 0b010_0000: result = a  >> sh   # SRA
        elif f3 == 0b010 and f7 == 0b000_0000: result = 1 if a < b else 0  # SLT
        else:
            print(f"[WARN] Unknown R-type f3={f3:03b} f7={f7:07b} @ PC={pc:#010x}")

    # ── I-type ALU  opcode 0010011 ────────────────────────────────────────────
    elif op == 0b001_0011:
        a   = to_signed32(regs[rs1])
        ua  = to_u32(regs[rs1])
        imm = d['imm_i']

        if   f3 == 0b000: result = a  + imm             # ADDI
        elif f3 == 0b111: result = ua & to_u32(imm)     # ANDI
        elif f3 == 0b110: result = ua | to_u32(imm)     # ORI
        elif f3 == 0b100: result = ua ^ to_u32(imm)     # XORI
        else:
            print(f"[WARN] Unknown I-ALU f3={f3:03b} @ PC={pc:#010x}")

    # ── LOAD  opcode 0000011 ──────────────────────────────────────────────────
    elif op == 0b000_0011:
        addr = to_u32(to_signed32(regs[rs1]) + d['imm_i'])
        if f3 == 0b010:                                  # LW
            result = mem.get(addr, 0)
        else:
            print(f"[WARN] Unsupported load f3={f3:03b} @ PC={pc:#010x}")

    # ── STORE  opcode 0100011 ─────────────────────────────────────────────────
    elif op == 0b010_0011:
        addr = to_u32(to_signed32(regs[rs1]) + d['imm_s'])
        if f3 == 0b010:                                  # SW
            mem[addr] = to_u32(regs[rs2])
        else:
            print(f"[WARN] Unsupported store f3={f3:03b} @ PC={pc:#010x}")

    # ── BRANCH  opcode 1100011 ────────────────────────────────────────────────
    elif op == 0b110_0011:
        a     = to_signed32(regs[rs1])
        b     = to_signed32(regs[rs2])
        taken = False
        if   f3 == 0b000: taken = (a == b)   # BEQ
        elif f3 == 0b001: taken = (a != b)   # BNE
        elif f3 == 0b100: taken = (a <  b)   # BLT
        elif f3 == 0b101: taken = (a >= b)   # BGE
        else:
            print(f"[WARN] Unsupported branch f3={f3:03b} @ PC={pc:#010x}")
        if taken:
            next_pc = to_u32(pc + d['imm_b'])

    # ── JAL  opcode 1101111 ───────────────────────────────────────────────────
    elif op == 0b110_1111:
        result  = next_pc                    # rd = PC + 4
        next_pc = to_u32(pc + d['imm_j'])

    else:
        print(f"[WARN] Unknown opcode={op:#09b} @ PC={pc:#010x}")

    return next_pc, rd, result

# ──────────────────────────────────────────────────────────────────────────────
# Simulate a list of instructions and return final register file
# ──────────────────────────────────────────────────────────────────────────────
def simulate(instructions, seed):
    """
    instructions : list of int (32-bit words), index 0 = PC 0x00000000
    seed         : integer MEM_SEED shared with gen_mem.py
    Returns      : list[32] of unsigned 32-bit register values (x0..x31)
    """
    rng = random.Random(seed)

    # x0 hardwired to 0; x1-x31 random (same RNG as gen_mem uses for regs)
    regs = [0] + [rng.randint(0, MASK32) for _ in range(31)]

    mem      = {}                           # word-addressed data memory
    pc       = 0
    pc_limit = len(instructions) * 4       # valid instruction window

    max_steps = len(instructions) * 10     # safety guard vs infinite loops
    steps     = 0

    while steps < max_steps:
        # Stop if PC escapes the instruction window
        if pc < 0 or pc >= pc_limit or (pc & 3) != 0:
            break

        instr = instructions[pc >> 2]
        d     = decode(instr)

        next_pc, rd, result = execute(d, regs, mem, pc)

        # Write-back (x0 is always 0)
        if result is not None and rd != 0:
            regs[rd] = to_u32(result)

        pc     = next_pc
        steps += 1

    return regs

# ──────────────────────────────────────────────────────────────────────────────
# File I/O
# ──────────────────────────────────────────────────────────────────────────────
def load_mem_file(path):
    """Parse .mem file: take hex word before any '//' comment, skip blanks."""
    instructions = []
    with open(path) as f:
        for line in f:
            token = line.split("//")[0].strip()
            if not token:
                continue
            try:
                instructions.append(int(token, 16))
            except ValueError:
                pass   # skip non-hex lines (e.g. header comments)
    return instructions

def write_expected(path, regs):
    """Write 32 hex register values, one per line (x0 first)."""
    with open(path, "w") as f:
        for i, v in enumerate(regs):
            f.write(f"{v:08x}  // x{i}\n")
    print(f"Written : {path}")

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Seed must match what gen_mem.py used for this run.
    # Pass it from the Makefile: python3 sim_expected.py $(MEM_SEED)
    if len(sys.argv) >= 2:
        try:
            SEED = int(sys.argv[1])
        except ValueError:
            print(f"[ERROR] Seed must be an integer, got: {sys.argv[1]}")
            sys.exit(1)
    else:
        SEED = 0
        print("[INFO] No seed supplied – using seed=0. "
              "Pass the same MEM_SEED used by gen_mem.py for accurate results.")

    # ── instr.mem → expected.mem ───────────────────────────────────────────
    instr_path    = os.path.join(script_dir, "instr.mem")
    expected_path = os.path.join(script_dir, "expected.mem")

    if not os.path.exists(instr_path):
        print(f"[ERROR] {instr_path} not found – run gen_mem.py first.")
        sys.exit(1)

    instrs = load_mem_file(instr_path)
    print(f"Loaded  : {len(instrs)} instructions from instr.mem  (seed={SEED})")
    write_expected(expected_path, simulate(instrs, SEED))
