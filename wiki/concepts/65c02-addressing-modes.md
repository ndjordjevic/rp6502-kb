---
type: concept
tags: [w65c02s, 65c02, addressing-modes, assembly]
related: [[w65c02s]], [[65c02-instruction-set]], [[memory-map]], [[learning-6502-assembly]], [[6502-relocatable-and-self-modifying]]
sources: [[w65c02s-datasheet]], [[wagner-assembly-lines]]
created: 2026-04-17
updated: 2026-04-18
---

# 65C02 Addressing Modes

**Summary**: The W65C02S provides **16 addressing modes** for effective-address computation. Two are new vs NMOS 6502: Absolute Indexed Indirect `(a,x)` (JMP only) and Zero Page Indirect `(zp)`.

---

## All 16 modes (Table 4-1)

Cycle/byte counts are for the W65C02S. Parenthesized numbers are conditional (page-cross, branch-taken, RMW, etc.).

| # | Mode | Assembly | Cycles | Bytes | Notes |
|---|---|---|---|---|---|
| 1 | Absolute | `a` | 4 (3) | 3 | 16-bit operand |
| 2 | **Absolute Indexed Indirect** | `(a,x)` | 6 | 3 | **New** — JMP only |
| 3 | Absolute Indexed, X | `a,x` | 4 (1,3) | 3 | +1 if page crossed; STA always +1 |
| 4 | Absolute Indexed, Y | `a,y` | 4 (1) | 3 | +1 if page crossed |
| 5 | Absolute Indirect | `(a)` | 6 | 3 | JMP — **no page-wrap bug** (fixed vs NMOS) |
| 6 | Accumulator | `A` | 2 | 1 | Operand is A |
| 7 | Immediate | `#imm` | 2 | 2 | Operand follows opcode |
| 8 | Implied | — | 2 | 1 | No operand |
| 9 | Program Counter Relative | `r` | 2 (1,2) | 2 | Branches; +1 taken, +1 page-cross |
| 10 | Stack | `s` | 3–7 | 1 (5) | PHA/PLA/BRK/RTS/RTI/etc. |
| 11 | Zero Page | `zp` | 3 (3) | 2 | +2 if RMW |
| 12 | Zero Page Indexed Indirect, X | `(zp,x)` | 6 | 2 | a.k.a. "Indirect,X" |
| 13 | Zero Page Indexed, X | `zp,x` | 4 (3) | 2 | +2 if RMW |
| 14 | Zero Page Indexed, Y | `zp,y` | 4 | 2 | LDX/STX only |
| 15 | **Zero Page Indirect** | `(zp)` | 5 | 2 | **New** — fills an NMOS gap |
| 16 | Zero Page Indirect Indexed, Y | `(zp),y` | 5 (1) | 2 | a.k.a. "Indirect,Y" |

Notes from Table 4-1:
1. Page boundary: +1 cycle if page crossed when forming address (always +1 for `STA abs,X`).
2. Branch taken: +1; page-crossed branch: +1 more.
3. RMW (read-modify-write): +2 cycles.
4. **New mode for W65C02S** (applies to `(a,x)` and `(zp)`).
5. BRK is a 2-byte instruction; the signature byte is skipped by PC++.

## Mode details

### Absolute `a`
16-bit absolute address follows the opcode (low byte first).
```
Byte:   [OpCode] [ADL] [ADH]
EA:     ADH:ADL
```

### Absolute Indexed Indirect `(a,x)` — **new**
`a` + `X` forms a pointer; new PC = word at that pointer. **JMP only** (`7C ADL ADH`). Useful for dense jump tables.

### Absolute Indexed `a,x` / `a,y`
`a + X` (or `a + Y`) → effective address. +1 cycle if crossing a page boundary (or always for `STA abs,X`).

### Absolute Indirect `(a)`
JMP only (`6C ADL ADH`). New PC = word at `ADH:ADL`. The NMOS page-wrap bug (reading `XXFF/XX00`) is **fixed** on W65C02S at the cost of +1 cycle.

### Accumulator `A`
Single-byte; operand is the accumulator. Used by ASL, LSR, ROL, ROR, INC, DEC.

### Immediate `#`
Operand is the byte following the opcode.

### Implied `i`
No operand: INX, INY, DEX, DEY, TAX, TXA, ..., CLC, NOP, WAI, STP.

### Program Counter Relative `r`
Branch opcodes (BCC, BCS, BEQ, BNE, BMI, BPL, BVC, BVS, **BRA**). Signed 8-bit displacement added to PC after fetch.

### Stack `s`
Implicit stack pointer `$0100 | S`. Used by PHA/PLA, PHP/PLP, PHX/PHY/PLX/PLY, JSR/RTS, BRK/RTI, and interrupts.

### Zero Page `zp`
8-bit address: EA = `$00:zp`. 3 cycles read, 5 cycles RMW.

### Zero Page Indexed Indirect `(zp,x)`
Compute `zp + X` (zero-page wrap), fetch 16-bit pointer from that zero-page address, EA = pointer. Used by `LDA (zp,x)` etc.

### Zero Page Indexed `zp,x` / `zp,y`
EA = `(zp + X) & $FF` (or Y). `zp,y` is only available for LDX and STX.

### Zero Page Indirect `(zp)` — **new**
Fetch 16-bit pointer from `$00:zp`; EA = pointer. Fills the NMOS gap that required Y=0 with `(zp),y`.

### Zero Page Indirect Indexed `(zp),y`
Fetch 16-bit pointer from `$00:zp`; EA = pointer + Y. +1 cycle if page crossed. The workhorse mode for buffer access.

## New modes vs NMOS 6502

Only **two** addressing modes are new on W65C02S:
- `(a,x)` — Absolute Indexed Indirect (JMP).
- `(zp)` — Zero Page Indirect.

The other 14 are inherited from the NMOS 6502; some are newly available to additional instructions (`BIT #imm`, `BIT zp,x`, `BIT a,x`, `INC A`, `DEC A`, `STA` via `(zp)`, etc.) — see [[65c02-instruction-set]].

---

## When to use X vs Y — pedagogical sidebar (Wagner)

The X and Y registers look symmetric but are **not interchangeable** in the two indirect modes. This is the most common source of confusion for beginners:

### Indexed Indirect `(zp,X)` — pre-indexing, X only

```
LDA ($80,X)
```
1. Add X to the zero-page base address: `$80 + X`
2. Fetch the 2-byte pointer stored at the resulting zero-page address.
3. Use that pointer as the effective address.

X selects *which pointer* in a table of zero-page pointers. Y **cannot** be used here. This mode is useful when walking a table of pointers at fixed zero-page offsets (e.g., a dispatch table).

Typical use: `X` is loaded with `0, 2, 4, 6...` (multiples of 2) to select successive pointer pairs on page zero.

### Indirect Indexed `(zp),Y` — post-indexing, Y only

```
LDA ($80),Y
```
1. Fetch the 2-byte base address stored at zero-page addresses `$80` and `$81`.
2. Add Y to that base address.
3. Use the result as the effective address.

Y adds an offset to the base pointer. X **cannot** be used here. This is the workhorse mode for any buffer, string, or array access via a pointer — load the pointer into `($80)` once, then Y walks through elements.

### Summary

| Mode | Syntax | Register | When to use |
|------|--------|----------|-------------|
| Indexed Indirect | `(zp,X)` | X only | Selecting one of several zero-page pointers |
| Indirect Indexed | `(zp),Y` | Y only | Walking through a buffer via a single pointer |

For plain indexed addressing (`abs,X` or `abs,Y`), X and Y work similarly — but note `zp,Y` is only available for `LDX`/`STX`, and `abs,Y` is not available for all instructions. Always consult the instruction table in [[65c02-instruction-set]].

---

## Related pages

- [[65c02-instruction-set]] · [[w65c02s]] · [[w65c02s-datasheet]] · [[memory-map]]
- [[learning-6502-assembly]] — beginner overview of all modes
- [[6502-relocatable-and-self-modifying]] — `JMP (abs,X)` for jump tables
