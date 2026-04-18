---
type: concept
tags: [w65c02s, 65c02, instruction-set, opcodes, assembly]
related: [[w65c02s]], [[65c02-addressing-modes]], [[rp6502-abi]], [[cc65]], [[llvm-mos]], [[6502-subroutine-conventions]], [[6502-data-structures]]
sources: [[w65c02s-datasheet]], [[leventhal-6502-assembly]]
created: 2026-04-17
updated: 2026-04-18
---

# 65C02 Instruction Set

**Summary**: The W65C02S executes **70 mnemonics** across **212 opcodes** and **16 addressing modes**. This page lists every instruction, the new/updated instructions vs NMOS 6502, and summarizes the opcode matrix.

---

## Instruction list (Table 5-1)

Legend (from datasheet):
- `●` = **new instruction** (not on NMOS 6502)
- `*` = **old instruction with new addressing modes** on W65C02S

| # | Mnemonic | Description |
|---|---|---|
| 1 | \*ADC | ADd memory to accumulator with Carry |
| 2 | \*AND | "AND" memory with accumulator |
| 3 | \*ASL | Arithmetic Shift one bit Left, memory or accumulator |
| 4 | ●BBR | Branch on Bit Reset (BBR0–BBR7) |
| 5 | ●BBS | Branch on Bit Set (BBS0–BBS7) |
| 6 | BCC | Branch on Carry Clear (C=0) |
| 7 | BCS | Branch on Carry Set (C=1) |
| 8 | BEQ | Branch if EQual (Z=1) |
| 9 | \*BIT | BIt Test |
| 10 | BMI | Branch if result MInus (N=1) |
| 11 | BNE | Branch if Not Equal (Z=0) |
| 12 | BPL | Branch if result PLus (N=0) |
| 13 | ●BRA | BRanch Always |
| 14 | BRK | BReaK (software interrupt) |
| 15 | BVC | Branch on oVerflow Clear (V=0) |
| 16 | BVS | Branch on oVerflow Set (V=1) |
| 17 | CLC | CLear Carry flag |
| 18 | CLD | CLear Decimal mode |
| 19 | CLI | CLear Interrupt disable bit |
| 20 | CLV | CLear oVerflow flag |
| 21 | \*CMP | CoMPare memory and accumulator |
| 22 | CPX | CoMPare memory and X register |
| 23 | CPY | CoMPare memory and Y register |
| 24 | \*DEC | DECrement memory or accumulator by one |
| 25 | DEX | DEcrement X by one |
| 26 | DEY | DEcrement Y by one |
| 27 | \*EOR | "Exclusive OR" memory with accumulator |
| 28 | \*INC | INCrement memory or accumulator by one |
| 29 | INX | INcrement X register by one |
| 30 | INY | INcrement Y register by one |
| 31 | \*JMP | JuMP to new location |
| 32 | JSR | Jump to new location Saving Return (Jump to SubRoutine) |
| 33 | \*LDA | LoaD Accumulator with memory |
| 34 | LDX | LoaD the X register with memory |
| 35 | LDY | LoaD the Y register with memory |
| 36 | LSR | Logical Shift one bit Right memory or accumulator |
| 37 | NOP | No OPeration |
| 38 | \*ORA | "OR" memory with Accumulator |
| 39 | PHA | PusH Accumulator on stack |
| 40 | PHP | PusH Processor status on stack |
| 41 | ●PHX | PusH X register on stack |
| 42 | ●PHY | PusH Y register on stack |
| 43 | PLA | PuLl Accumulator from stack |
| 44 | PLP | PuLl Processor status from stack |
| 45 | ●PLX | PuLl X register from stack |
| 46 | ●PLY | PuLl Y register from stack |
| 47 | ●RMB | Reset Memory Bit (RMB0–RMB7) |
| 48 | ROL | ROtate one bit Left memory or accumulator |
| 49 | ROR | ROtate one bit Right memory or accumulator |
| 50 | RTI | ReTurn from Interrupt |
| 51 | RTS | ReTurn from Subroutine |
| 52 | \*SBC | SuBtract memory from accumulator with borrow (Carry bit) |
| 53 | SEC | SEt Carry |
| 54 | SED | SEt Decimal mode |
| 55 | SEI | SEt Interrupt disable status |
| 56 | ●SMB | Set Memory Bit (SMB0–SMB7) |
| 57 | \*STA | STore Accumulator in memory |
| 58 | ●STP | SToP mode (stop clock) |
| 59 | STX | STore the X register in memory |
| 60 | STY | STore the Y register in memory |
| 61 | ●STZ | STore Zero in memory |
| 62 | TAX | Transfer the Accumulator to the X register |
| 63 | TAY | Transfer the Accumulator to the Y register |
| 64 | ●TRB | Test and Reset memory Bit |
| 65 | ●TSB | Test and Set memory Bit |
| 66 | TSX | Transfer the Stack pointer to the X register |
| 67 | TXA | Transfer the X register to the Accumulator |
| 68 | TXS | Transfer the X register to the Stack pointer |
| 69 | TYA | Transfer Y register to the Accumulator |
| 70 | ●WAI | WAit for Interrupt |

## New instructions (CMOS additions)

Instructions **added** by the W65C02S over the original NMOS 6502:

- **Branch-on-bit**: `BBR0–BBR7`, `BBS0–BBS7` — 5-byte instructions that test a single bit in zero-page and branch (opcodes `0F/1F/.../7F` for BBR, `8F/9F/.../FF` for BBS).
- **Bit modify**: `RMB0–RMB7`, `SMB0–SMB7` — reset/set a single bit in zero-page without touching other bits (opcodes `07/17/.../77` for RMB, `87/97/.../F7` for SMB).
- **Unconditional branch**: `BRA` (opcode `80`) — relative branch always taken; fills a long-standing gap.
- **Extra stack**: `PHX`, `PHY`, `PLX`, `PLY` — push/pull X and Y via stack directly (`DA, 5A, FA, 7A`).
- **Memory zero**: `STZ` — store zero (`64 zp`, `74 zp,x`, `9C a`, `9E a,x`). Saves the "LDA #0 / STA" pair.
- **Test and toggle bits**: `TRB`, `TSB` — read-modify-write that ANDs/ORs with accumulator and sets Z flag based on original value.
- **Power/sync**: `WAI` (`CB`), `STP` (`DB`) — Wait for interrupt / Stop the clock. Both reduce power and interrupt latency.

## New addressing modes for existing instructions

Opcodes marked with `*` gain new modes on the W65C02S:

- `(zp)` — Zero Page Indirect — added to ADC, AND, CMP, EOR, LDA, ORA, SBC, STA.
- `(a,x)` — Absolute Indexed Indirect — JMP only (`7C a`). Pairs well with jump tables.
- `BIT` gains `#imm`, `zp,x`, `a,x`.
- `INC A` / `DEC A` — accumulator variant (`1A`, `3A`).

## Opcode matrix (Table 5-2)

The 256-cell opcode map is 98% filled (212 valid + reserved NOPs). Cells are indexed by high nibble (row) × low nibble (column). Key single-byte opcodes worth memorizing:

| Op | Mnemonic | Notes |
|---|---|---|
| `00` | BRK | Software interrupt via FFFE/F |
| `EA` | NOP | 1-byte, 2-cycle |
| `40` | RTI | Return from interrupt |
| `60` | RTS | Return from subroutine |
| `4C` | JMP a | Absolute jump |
| `6C` | JMP (a) | Absolute indirect (fixed — no page wrap) |
| `7C` | JMP (a,x) | **New** — indexed indirect |
| `80` | BRA r | **New** — unconditional branch |
| `CB` | WAI | **New** — wait for interrupt |
| `DB` | STP | **New** — stop clock |
| `9C` / `9E` | STZ a / a,x | **New** — store zero |

The full matrix with cycle counts and flag effects is in Table 5-2 and Table 6-4 of the [[w65c02s-datasheet]].

## Reserved / invalid opcodes

All invalid opcodes on the W65C02S execute as **deterministic NOPs** with documented byte/cycle cost (not "illegal ops" like NMOS). Groups from Ch. 7:

| OpCodes | Bytes | Cycles |
|---|---|---|
| `02, 22, 42, 62, 82, C2, E2` | 2 | 2 |
| `03, 0B, 13, 1B, 23, 2B, 33, 3B, 43, 4B, 53, 5B, 63, 6B, 73, 7B, 83, 8B, 93, 9B, A3, AB, B3, BB, C3, CB*, D3, DB*, E3, EB, F3, FB` | 1 | 1 |
| `44` | 2 | 3 |
| `54, D4, F4` | 2 | 4 |
| `5C` | 3 | 8 |
| `DC, FC` | 3 | 4 |

*Note: `CB`=WAI and `DB`=STP are **not** NOPs — they are new WDC instructions. Rows in the table above listing them are for context; see instruction list for actual behavior.*

## Flag semantics (from Table 6-4)

- After **ADC/SBC** in decimal mode: N, V, Z are valid (NMOS: undefined), at cost of +1 cycle.
- **BRK** sets `I=1`, `D=0` automatically, and pushes P with B=1.
- **RESB** / **NMIB** / **IRQB** all push PC and P with B=0, then set `I=1`, `D=0`, and load the vector.
- Decimal flag `D` is **initialized to 0** by hardware reset.

## Usage on RP6502

The RP6502's [[rp6502-abi]] leverages WDC enhancements:
- `JSR RIA_SPIN` spins on `RIA_BUSY` — small, since the spin stub fits in 32 bytes of zero-page.
- `cc65` and `llvm-mos` both target the **W65C02S** instruction set (not plain 6502), so STZ/BRA/PHX/PHY/etc. are emitted freely.
- `WAI` is not currently used by RIA-served programs but is available; see open question in [[w65c02s]].

## Related pages

- [[w65c02s]] · [[65c02-addressing-modes]] · [[w65c02s-datasheet]] · [[rp6502-abi]] · [[cc65]] · [[llvm-mos]]

---

## Leventhal Ch. 17 — pedagogical notes on new instructions

The following notes come from *6502 Assembly Language Programming, 2nd Ed.* (Leventhal, 1986), Ch. 17, which frames the 65C02 enhancements from a programmer's perspective. Source: [[leventhal-6502-assembly]].

### Indirect addressing for arithmetic/logic — the key improvement

The NMOS 6502 only supports indirect addressing for `JMP` and for the two pre/post-indexed indirect modes `(zp,X)` / `(zp),Y`. The 65C02 adds **true `(zp)` indirect** to all arithmetic, logical, and transfer instructions (ADC, AND, CMP, EOR, LDA, ORA, SBC, STA). This is the most practically significant 65C02 enhancement:

```asm
; Load from address stored in zero-page pair $40/$41:
LDA  ($40)        ; effective address = word at ($40), ($41)

; Compare with indirect data:
CMP  ($42)        ; compares A with byte pointed to by ($42)/$43

; Without this mode (NMOS): must set Y=0 and use (zp),Y
LDY  #0
LDA  ($40),Y      ; NMOS equivalent — wastes a register
```

Any zero-page address pair can now serve as a full 16-bit address register. This is Leventhal's primary motivation for recommending the 65C02 over the NMOS 6502 for new designs.

### `JMP (a,x)` — clean jump tables

```asm
; Jump to table entry indexed by Accumulator:
ASL  A            ; × 2 (each entry is 2 bytes)
TAX
JMP  (JTBL,X)     ; opcode $7C — load PC from JTBL+X
```

This replaces a 7-instruction pre-65C02 sequence (ASL / TAX / LDA JTBL,X / STA $40 / LDA JTBL+1,X / STA $41 / JMP ($40)). See [[6502-data-structures]] for full comparison.

### Bit-manipulation instructions — `SMB` / `RMB` / `BBS` / `BBR`

These four instruction families operate on **single bits of zero-page bytes**:

| Mnemonic | Opcode range | Operation |
|----------|-------------|-----------|
| `RMB0`–`RMB7` | `$07,$17,...,$77` | Reset (clear) bit N of zero-page byte |
| `SMB0`–`SMB7` | `$87,$97,...,$F7` | Set bit N of zero-page byte |
| `BBR0`–`BBR7` | `$0F,$1F,...,$7F` | Branch if bit N of ZP byte is 0 |
| `BBS0`–`BBS7` | `$8F,$9F,...,$FF` | Branch if bit N of ZP byte is 1 |

All are 3-byte instructions. Example pattern for a status-flag byte in zero page:

```asm
; Set flag 3 in ZP location FLAGS ($42):
SMB3  $42         ; bit 3 of ($42) ← 1

; Clear flag 0:
RMB0  $42         ; bit 0 of ($42) ← 0

; Branch if flag 5 is set:
BBS5  $42, TARGET ; branch to TARGET if bit 5 of ($42) = 1
```

These are particularly useful for port-pin control and software flags without needing ORA/AND masks.

### `BRA` — unconditional relative branch

Opcode `$80`. Eliminates the common NMOS workaround of using `BNE *+0` (exploit a known flag) or a 3-byte `JMP` for short branches:

```asm
; NMOS: need a trick or 3-byte JMP for short backward branch
LOOP:   INX
        BNE  LOOP    ; only works if you want to branch when Z=0

; 65C02: always branch with BRA
LOOP:   INX
        BRA  LOOP    ; unconditional, 2-byte, ±127 bytes range
```

### `PHX` / `PHY` / `PLX` / `PLY` — save/restore index registers without trashing A

```asm
; Preserve X and Y across a subroutine call:
PHX               ; push X ($DA — 3 cycles)
PHY               ; push Y ($5A — 3 cycles)
JSR  MYFUNC
PLY               ; pop Y ($7A — 4 cycles)
PLX               ; pop X ($FA — 4 cycles)
; A is not touched
```

Total: 4 instructions (14 cycles) instead of 6 instructions (20+ cycles) via TXA/PHA/TYA/PHA/PLA/TAY/PLA/TAX. See [[6502-subroutine-conventions]].

### `STZ` — store zero without loading the accumulator

```asm
; NMOS: LDA #0 / STA addr (3 bytes, 5 cycles)
LDA  #0
STA  $40

; 65C02: STZ addr (2 bytes, 3 cycles for ZP)
STZ  $40          ; opcode $64 (ZP), $74 (ZP,X), $9C (abs), $9E (abs,X)
```

Initialization loops that clear arrays become significantly shorter.

### `INC A` / `DEC A` — accumulator increment/decrement

```asm
; NMOS: CLC / ADC #1 (2 instructions, 4 cycles)
CLC
ADC  #1

; 65C02: INC A (1 instruction, 2 cycles, opcode $1A)
INC  A            ; or just: INC (bare accumulator mode)
DEC  A            ; opcode $3A
```

### `TRB` / `TSB` — test and modify bits

`TSB` (Test and Set Bits, opcodes `$04` ZP / `$0C` abs): Z = (A AND M) == 0; M ← M OR A.  
`TRB` (Test and Reset Bits, opcodes `$14` ZP / `$1C` abs): Z = (A AND M) == 0; M ← M AND NOT(A).

Pattern: use accumulator as a **mask**, test bits, and set or clear them — all in one instruction:

```asm
; Turn on bits 3 and 5 of PORT, test if they were previously clear:
LDA  #%00101000   ; mask for bits 3 and 5
TSB  PORT         ; PORT ← PORT | mask; Z = 1 if both were 0 before

; Clear bits 3 and 5, test if they were set:
LDA  #%00101000
TRB  PORT         ; PORT ← PORT & ~mask; Z = 1 if both were 0
```

### Decimal mode flag cleared on interrupt (65C02 fix)

On the 65C02, hardware interrupts (IRQ, NMI, BRK, RESET) **automatically clear P.D** before loading the vector. This means the ISR body starts in binary mode regardless of what the interrupted code was doing. On the NMOS 6502, the ISR had to explicitly `CLD` at entry to be safe. This is a silent but important correctness fix.

### JMP indirect page-boundary bug fixed

On the NMOS 6502, `JMP ($xxFF)` reads the low byte from `$xxFF` and the high byte from `$xx00` (wraps within the same page). The 65C02 fixes this: `JMP ($xxFF)` correctly reads the high byte from `$(xx+1)00`.

