---
type: concept
tags: [6502, 65c02, assembly, emulation, instructions, addressing-modes, 16-bit, shifts, branches]
related: [[65c02-instruction-set]], [[6502-programming-idioms]], [[6502-common-errors]], [[6502-subroutine-conventions]], [[6502-compare-instructions]], [[6502-overflow-flag]]
sources: [[leventhal-subroutines]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Emulated Instructions

**Summary**: Instruction sequences that simulate operations missing from the 6502 instruction set — including 16-bit arithmetic, arithmetic shifts, multi-byte shifts, extended branches, indirect/indexed addressing, and decimal operations — from Leventhal & Saville Ch. 2.

---

## Overview

The 6502 lacks many instructions available on the 6800, 6809, 8080, and other contemporary processors. This page catalogues the standard idioms for emulating those missing operations. Each idiom shows the minimum correct sequence; commentary explains carry-handling and flag side effects.

See [[6502-common-errors]] for pitfalls that arise when these idioms are used incorrectly.

---

## Arithmetic instructions

### Add without carry (plain ADD)
```asm
CLC
ADC  ADDR       ; (A) = (A) + (ADDR)
```
```asm
CLC
ADC  #VALUE     ; (A) = (A) + VALUE
```
`CLC` is mandatory — `ADC` always includes the Carry flag.

### Subtract without borrow (plain SUB)
```asm
SEC
SBC  ADDR       ; (A) = (A) − (ADDR)
```
`SEC` is mandatory — `SBC` subtracts `(1 − Carry)` from the result, so an uninitialised Carry gives wrong answers.

### Decimal add without carry
```asm
SED
CLC
ADC  ADDR       ; (A) = (A) + (ADDR) in BCD
CLD
```
Always restore binary mode immediately after the decimal operation.

### Decimal add with carry
```asm
SED
ADC  #0         ; (A) = (A) + Carry (in decimal)
CLD
```

### Decimal subtract without borrow
```asm
SED
SEC
SBC  ADDR       ; (A) = (A) − (ADDR) in BCD
CLD
```

### Decimal subtract with borrow (restore)
```asm
SED
SBC  #0         ; (A) = (A) − (1−Carry) in decimal
CLD
```

### Add index register to accumulator
```asm
STX  ZPAGE      ; save X to zero page
CLC
ADC  ZPAGE      ; (A) = (A) + (X)
```
Works for Y as well (`STY ZPAGE`). Destroys the zero-page location.

### 16-bit addition (without carry)
Add `ADDR`/`ADDR+1` (MSB at `ADDR+1`) to `SUM`/`SUM+1`:
```asm
CLC
LDA  SUM
ADC  ADDR       ; add LSBs
STA  SUM
LDA  SUM+1
ADC  ADDR+1     ; add MSBs with carry
STA  SUM+1
```

### 16-bit addition of a 16-bit immediate constant
```asm
CLC
LDA  SUM
ADC  #VAL16L    ; add LSB of constant
STA  SUM
LDA  SUM+1
ADC  #VAL16H    ; add MSB of constant with carry
STA  SUM+1
```

### 16-bit addition with carry
Omit the leading `CLC` — carry from a prior operation propagates into the LSB addition.

### 16-bit subtraction (without borrow)
```asm
SEC
LDA  DIFF
SBC  ADDR       ; subtract LSBs
STA  DIFF
LDA  DIFF+1
SBC  ADDR+1     ; subtract MSBs with borrow
STA  DIFF+1
```

### Increment accumulator
```asm
CLC
ADC  #1         ; (A) = (A) + 1
```
(65C02 adds `INC A` as a real instruction — use it instead.)

### Decrement accumulator
```asm
SEC
SBC  #1         ; (A) = (A) − 1
```
(65C02 adds `DEC A` — use it instead.)

### Negate accumulator (two's complement)
```asm
EOR  #$FF       ; one's complement
CLC
ADC  #1         ; two's complement
```

### Reverse subtraction (VALUE − A)
```asm
EOR  #$FF       ; one's complement A
CLC
ADC  #1         ; two's complement
ADC  #VALUE     ; VALUE + (−A) = VALUE − A
```
Alternatively: `SEC; SBC` with reversed operands using zero page.

---

## Multiplication and division

### 8-bit unsigned multiply (shift-and-add)
See [[6502-programming-idioms]] for the full listing. Summary: 8 shift iterations, `ASL` multiplier and conditionally `ADC` multiplicand to partial product. Result is 16-bit in memory. Approximately 170–280 clock cycles.

### 8-bit unsigned divide (shift-and-subtract)
See [[6502-programming-idioms]] for the full listing. 8 iterations of `ASL`/`ROL`/`SEC`/`SBC` with conditional restore. Result: 8-bit quotient and 8-bit remainder. Approximately 200–250 clock cycles.

---

## Comparison and branch emulation

### Signed greater-than branch (`BGT`)
```asm
CMP  ADDR
BEQ  NOT_GT     ; equal → not greater
BVS  DEST       ; overflow set → sign inverted, so branch
BMI  DEST       ; negative (and no overflow) → A > ADDR... wait
```
Actually: "branch if A > ADDR (signed)" requires:
```asm
SEC
SBC  ADDR       ; A − ADDR (preserves overflow)
BEQ  SKIP       ; equal → not greater
BVC  L1         ; no overflow → use N flag as-is
EOR  #$80       ; overflow: invert sign bit
L1: BMI  DEST   ; if (adjusted) result is negative → A < ADDR; else A > ADDR
SKIP:
```
The 6502 lacks BGT/BLE/BGE/BLT for signed comparisons; these must be built from `CMP`/`BEQ`/`BMI`/`BVC` sequences (see also Ch. 2 extended branch section).

### Extended branch (beyond ±127 bytes)
When a branch target is more than 127 bytes away, invert the condition and use `JMP`:
```asm
BNE  NEAR       ; branch if condition NOT met (inverted)
JMP  FAR_DEST   ; unconditional jump to distant target
NEAR:
```
This adds 3 bytes and 3 cycles for the not-taken path.

### Unconditional relative branch
```asm
BEQ  DEST       ; set Z=1 first with CMP #(A), then branch
```
Or simply use `JMP DEST` (3 bytes). No short-branch penalty.

---

## Logical and bit operations

### Clear a specific bit (e.g., bit 3)
```asm
AND  #%11110111  ; mask off bit 3
```

### Set a specific bit (e.g., bit 6)
```asm
ORA  #%01000000  ; set bit 6
```

### Invert a specific bit (e.g., bit 2)
```asm
EOR  #%00000100  ; toggle bit 2
```

### Test a specific bit (e.g., bit 5)
```asm
AND  #%00100000  ; result non-zero if bit 5 is set
BNE  BIT_IS_SET
```
Or using `BIT` instruction to avoid destroying A:
```asm
LDA  #%00100000
BIT  ADDR        ; Z = 1 if bit 5 of ADDR is 0
BNE  BIT_IS_SET
```

### Complement (logical NOT)
```asm
EOR  #$FF        ; invert all 8 bits
```

---

## Shift and rotate emulation

### Arithmetic shift right (preserve sign bit)
The 6502 has `LSR` (logical shift, clears bit 7) but not `ASR` (arithmetic shift, copies bit 7):
```asm
CMP  #$80        ; copy bit 7 to Carry (set if negative)
ROR  A           ; rotate: Carry → bit 7, bit 0 → Carry
```

### 16-bit logical shift left (ASL word)
```asm
ASL  ADDR        ; shift LSB left, bit 7 → Carry
ROL  ADDR+1      ; shift MSB left with carry from LSB
```

### 16-bit logical shift right (LSR word)
```asm
LSR  ADDR+1      ; shift MSB right, bit 0 → Carry
ROR  ADDR        ; shift LSB right with carry from MSB
```

### 16-bit arithmetic shift right (sign-preserving)
```asm
LDA  ADDR+1      ; get MSB
ASL  A           ; bit 7 → Carry (sign bit copy)
ROR  ADDR+1      ; rotate: Carry (=sign) → bit 7 of MSB
ROR  ADDR        ; shift LSB right through carry
```

### Multi-byte shift left N positions
For N > 1, repeat the 2-instruction pair (`ASL`/`ROL`) N times, or put in a loop with a counter.

---

## Load and store emulation

### Load accumulator indirect (no page-zero restriction)
Using zero page pointer `PGZRO`/`PGZRO+1`:
```asm
LDY  #0
LDA  (PGZRO),Y  ; load from address stored in PGZRO/PGZRO+1
```
65C02 direct: `LDA (PGZRO)` — no need to clear Y.

### Store accumulator indirect
```asm
LDY  #0
STA  (PGZRO),Y  ; store to address in PGZRO/PGZRO+1
```
65C02: `STA (PGZRO)`.

### Load stack pointer immediate
```asm
LDX  #VALUE
TXS              ; SP = VALUE
```

### Load status register immediate
```asm
PHA              ; any value on stack
PLA              ; pull status — no, this won't work
; Correct:
PHP              ; push current status
PLA              ; pull to A
AND  #MASK       ; modify
PHA              ; push modified value
PLP              ; pull to status register
```
Or to set status to an immediate value:
```asm
LDA  #VALUE
PHA
PLP
```

### Store stack pointer
```asm
TSX
STX  ADDR        ; SP → ADDR (via X)
```

### Transfer X ↔ Y (no direct instruction)
```asm
TXA
TAY              ; X → A → Y
```
```asm
TYA
TAX              ; Y → A → X
```

### Exchange X and Y
```asm
STX  TEMP
TYA
TAX              ; Y → X
LDA  TEMP
TAY              ; old X → Y
```

### Block move (short)
```asm
LDY  #LENGTH-1
MOVLP:
    LDA  SRC,Y
    STA  DST,Y
    DEY
    BPL  MOVLP
```
For blocks > 256 bytes, see [[6502-data-structures]] (Ch. 5 block move subroutine).

---

## Addressing mode emulation

### Indirect addressing (non-JMP)
The 6502 only supports `JMP (addr)` for direct indirect. For other instructions:
```asm
LDY  #0
LDA  (PGZRO),Y  ; postindexed with Y=0 = plain indirect
```
Limitation: pointer must be on page 0.

### Indexed addressing with automatic pointer increment (autoincrement)
```asm
; Pre-increment (read then advance):
INC  PGZRO
BNE  NOINC
INC  PGZRO+1     ; carry into high byte
NOINC:
LDY  #0
LDA  (PGZRO),Y
```
There is no hardware autoincrement on the 6502; it must be managed manually.

---

## Interrupt enable/disable emulation

### Save and restore interrupt flag
```asm
PHP              ; save status register (including I flag)
SEI              ; disable maskable interrupts
; ... critical section ...
PLP              ; restore I flag (and all other flags)
```
This is safer than using `CLI` unconditionally, because `PLP` restores the exact state before `PHP`.

---

## Decimal mode flag management

### Save and restore decimal mode flag
```asm
PHP              ; save P (includes D flag)
CLD              ; or SED
; ... arithmetic ...
PLP              ; restore old D flag
```
Interrupt service routines **must** do this if they execute `ADC` or `SBC`, because the D flag is not automatically saved/restored on interrupt entry (unlike the I flag).

---

## Quick reference: missing 6502 instructions and their emulations

| Missing instruction | Emulation |
|---------------------|-----------|
| `ADD` (no carry) | `CLC; ADC` |
| `SUB` (no borrow) | `SEC; SBC` |
| `NEG` | `EOR #$FF; CLC; ADC #1` |
| `INC A` | `CLC; ADC #1` (or `INC A` on 65C02) |
| `DEC A` | `SEC; SBC #1` (or `DEC A` on 65C02) |
| `ASR` (arithmetic shift right) | `CMP #$80; ROR A` |
| `ASL16` (16-bit shift left) | `ASL lo; ROL hi` |
| `LSR16` (16-bit shift right) | `LSR hi; ROR lo` |
| `CLR` (clear accumulator) | `LDA #0` |
| `NOT` (complement) | `EOR #$FF` |
| `JMP (reg)` | `STA PGZRO; STY PGZRO+1; JMP (PGZRO)` |
| `LIND` (load indirect) | `LDY #0; LDA (PGZRO),Y` |
| `SIND` (store indirect) | `LDY #0; STA (PGZRO),Y` |
| `LDSP` (load stack pointer) | `LDX #val; TXS` |
| `STSP` (store stack pointer) | `TSX; STX ADDR` |
| `TXY` | `TXA; TAY` |
| `TYX` | `TYA; TAX` |
| Unconditional relative branch | `JMP DEST` or flag+branch |
| Signed `BGT`/`BLE` | Multi-step `CMP`+`BEQ`+`BVS`+`BMI` sequences |
| Long conditional branch | Invert condition + `JMP FAR` |

---

> **Conflict**: The NMOS 6502 `JMP ($xxFF)` indirect jump has a page-boundary bug: if the indirect address vector spans a page boundary (e.g., `$12FF`/`$1300`), the CPU reads the high byte from `$1200` instead of `$1300`. The 65C02 and W65C02S fix this bug. See [[6502-common-errors]] for details.

---

## Related pages

- [[6502-common-errors]] — misuse of these idioms is a primary source of bugs
- [[6502-programming-idioms]] — 8-bit and 16-bit arithmetic, BCD patterns
- [[65c02-instruction-set]] — 65C02 new instructions that replace some emulations (`INC A`, `DEC A`, `PHX`, `PHY`, `BRA`, `(zp)` addressing)
- [[6502-compare-instructions]] — correct multi-byte and signed comparison patterns
- [[6502-overflow-flag]] — V flag mechanics underlying the signed comparison emulations
- [[6502-subroutine-conventions]] — parameter passing, reentrancy
- [[6502-data-structures]] — 16-bit block move, N-dimensional array indexing
