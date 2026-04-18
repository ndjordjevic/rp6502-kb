---
type: concept
tags: [6502, 65c02, assembly, beginner, registers, status-flags, loops, branches, addressing-modes]
related: [[65c02-instruction-set]], [[65c02-addressing-modes]], [[6502-stack-and-subroutines]], [[6502-programming-idioms]], [[6502-subroutine-conventions]]
sources: [[wagner-assembly-lines]]
created: 2026-04-18
updated: 2026-04-18
---

# Learning 6502 Assembly

**Summary**: Beginner-friendly introduction to 6502 assembly language — registers, the Status Register, binary numbers, loops with counters, branch instructions, and addressing modes. This page is the entry scaffold that links to all deeper concept pages.

---

## The 6502 processor — how it works

The 6502 scans through memory addresses sequentially. At each location it finds a **value** (a byte). Depending on what it finds, it executes a given operation — these are called **opcodes**. Operations include adding numbers, storing values, comparing, jumping to other locations, and so on.

A program is a sequence of opcodes (and their operands) stored in consecutive memory locations. An **assembler** converts short human-readable abbreviations called **mnemonics** into the correct opcode values. `STX` = **ST**ore **X** register — the assembler figures out which bytes to store.

Assembly language has only ~55 unique commands (the 6502 has ~56 instructions; 65C02 adds 12 more). The simplicity is what makes machine code fast and compact.

---

## The four registers

The 6502 has four registers — small storage locations on the chip itself:

| Register | Size | Purpose |
|----------|------|---------|
| **Accumulator (A)** | 8-bit | Main arithmetic/logic register; results of ADC, AND, ORA, EOR, ASL, etc. |
| **X Register** | 8-bit | Counter, index offset (for `addr,X` addressing) |
| **Y Register** | 8-bit | Counter, index offset (for `(zp),Y` indirect addressing) |
| **Status Register (P)** | 8-bit | Eight condition **flags** — not a number register |

Plus the 16-bit Program Counter (PC) and 8-bit Stack Pointer (SP) — controlled automatically by the CPU.

---

## Binary numbers

The 6502 is entirely binary. Each memory location holds one **byte** — 8 bits, each either 0 or 1. Because there are 8 positions, we can count from 0 (`00000000`) to 255 (`11111111`), a range of 256 values.

- 0 = `00000000` — all off
- 1 = `00000001`
- 128 = `10000000` — only the highest bit set
- 255 = `11111111` — all on

Binary is important because each bit is an independent condition, and the Status Register exploits this: each of its 8 bits encodes a separate processor state. Hexadecimal (base 16, `$00–$FF`) is used throughout because two hex digits exactly represent one byte.

---

## The Status Register (P) — flags

The Status Register's 8 bits are called **flags**. Each flag is set (1) or clear (0) to record the result of an operation. The 6502 uses them to make decisions via branch instructions.

| Bit | Flag | Set when… |
|-----|------|-----------|
| 7 | **N** (Negative/Sign) | Result's bit 7 = 1 (value ≥ $80) |
| 6 | **V** (Overflow) | Signed arithmetic overflow (or BIT bit 6) |
| 5 | — | Always 1 (not a flag) |
| 4 | **B** (Break) | BRK instruction executed |
| 3 | **D** (Decimal) | BCD mode enabled (SED/CLD) |
| 2 | **I** (Interrupt disable) | IRQ masked |
| 1 | **Z** (Zero) | Result = $00 |
| 0 | **C** (Carry) | Arithmetic carry out, or comparison no-borrow |

**Key insight**: The "Zero flag" = 1 when the result IS zero. Seems backward at first — but it records the presence/absence of a given condition. A value of 1 means "yes, the zero condition is present."

Flags are set/cleared automatically by the 6502 after most operations. Load/Transfer instructions set N and Z. Store instructions do **not** touch flags. See [[65c02-instruction-set]] for per-instruction flag effects.

---

## Increment, decrement, and the Zero flag

The main loop-driving instructions:

| Instruction | Target | Effect | Flags |
|-------------|--------|--------|-------|
| `INC addr` | Memory | Memory location += 1 | N, Z |
| `DEC addr` | Memory | Memory location -= 1 | N, Z |
| `INX` | X register | X += 1 | N, Z |
| `INY` | Y register | Y += 1 | N, Z |
| `DEX` | X register | X -= 1 | N, Z |
| `DEY` | Y register | Y -= 1 | N, Z |

**The Accumulator cannot be directly incremented/decremented** with INC/DEC on NMOS 6502. Use `CLC; ADC #1` instead, or `INC A` on the 65C02.

**Wrap-around**: incrementing $FF gives $00 (Z=1); decrementing $00 gives $FF (Z=0). INC/DEC **do not** affect the Carry flag — safe to use as loop counters inside a carry chain.

**Load also sets Z**: `LDA`, `LDX`, `LDY` set Z=1 if the loaded value is $00.

---

## Creating loops with BNE and BEQ

The fundamental counter loop pattern:

```asm
    LDX  #$FF      ; load counter with 255
LOOP:
    ; ... body of loop ...
    DEX            ; decrement counter; sets Z if counter = 0
    BNE  LOOP      ; branch back if counter ≠ 0 (Z=0)
    ; fall through when counter hits 0 (Z=1)
```

**BNE** = Branch Not Equal = "branch if Z=0 (not zero)".
**BEQ** = Branch Equal = "branch if Z=1 (zero)".

To count up instead:
```asm
    LDX  #$00      ; start at 0
LOOP:
    ; ... body of loop ...
    INX            ; increment; sets Z when X wraps to 0 (after 255)
    CPX  #$10      ; compare X with 16
    BCC  LOOP      ; branch back while X < 16 (Carry clear = no borrow)
```

All six branch instructions test a specific flag:

| Instruction | Tests | Branches when… |
|-------------|-------|----------------|
| `BEQ` | Z | Z = 1 (result was zero) |
| `BNE` | Z | Z = 0 (result was nonzero) |
| `BCC` | C | C = 0 (no carry / no borrow) |
| `BCS` | C | C = 1 (carry / borrow) |
| `BMI` | N | N = 1 (negative / bit 7 set) |
| `BPL` | N | N = 0 (positive / bit 7 clear) |
| `BVC` | V | V = 0 (no overflow) |
| `BVS` | V | V = 1 (overflow) |
| `BRA` | — | Always (65C02 only) |

Branch offsets are **signed 8-bit** values (−128 to +127 bytes from the next instruction). For longer jumps use `JMP` (3 bytes, absolute) or the stepping technique in [[6502-relocatable-and-self-modifying]].

---

## Addressing modes — a quick map

The 6502 accesses memory in several different ways:

| Mode | Example | Description |
|------|---------|-------------|
| Immediate | `LDA #$A0` | Operand is the literal byte following the opcode |
| Absolute | `LDA $0700` | Operand is at 16-bit address |
| Zero Page | `LDA $80` | Operand is at an address in page 0 ($00–$FF); saves one byte and one cycle |
| Indexed | `LDA $0200,X` | Address = base + X register |
| Indirect Indexed | `LDA ($80),Y` | Zero-page pointer contains base; Y adds offset (post-indexing) |
| Indexed Indirect | `LDA ($80,X)` | X selects which zero-page pointer to use (pre-indexing) |
| Relative | `BNE LOOP` | Signed 8-bit offset from PC (branches only) |
| Implied | `INX` | No operand needed |

### When X and Y aren't interchangeable

The two indirect modes have **fixed register assignments** — they are not interchangeable:

- **Indirect Indexed `(zp),Y`** — X cannot be used here. The zero-page pointer is accessed first, *then* Y is added (post-indexing). This is the standard mode for walking through buffers via a pointer.
- **Indexed Indirect `(zp,X)`** — Y cannot be used here. X is added to the zero-page address *first*, then the 2-byte pointer is fetched from the resulting address (pre-indexing). Used when indexing through a table of pointers.

For simple indexed (`abs,X` or `abs,Y`), X and Y are interchangeable in most instructions, but not all: `LDX`/`STX` use `zp,Y` for zero-page indexed; `LDY`/`STY` use `zp,X`. Check the instruction table in [[65c02-instruction-set]] or [[65c02-addressing-modes]].

See [[65c02-addressing-modes]] for the full cycle/byte count table and all 16 modes.

---

## Building upward from here

| To learn about… | Go to… |
|-----------------|--------|
| Arithmetic (ADC, SBC, shifts, logical, BCD) | [[6502-programming-idioms]] |
| The stack, PHA/PLA, JSR/RTS | [[6502-stack-and-subroutines]] |
| Subroutine entry/exit conventions | [[6502-subroutine-conventions]] |
| All 65C02 instructions with flag effects | [[65c02-instruction-set]] |
| All 16 addressing modes with cycle counts | [[65c02-addressing-modes]] |
| Interrupt handling | [[6502-interrupt-patterns]] |
| Relocatable and self-modifying code | [[6502-relocatable-and-self-modifying]] |
| Common bugs and how to avoid them | [[6502-common-errors]] |

---

## Related pages

- [[65c02-instruction-set]]
- [[65c02-addressing-modes]]
- [[6502-stack-and-subroutines]]
- [[6502-programming-idioms]]
- [[6502-subroutine-conventions]]
- [[6502-common-errors]]
- [[learning-guide]] — structured reading path through all 6502 and RP6502 wiki pages
