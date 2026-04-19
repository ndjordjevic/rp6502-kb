---
type: concept
tags: [6502, 65c02, assembly, debugging, errors, carry, flags, addressing, decimal-mode]
related:
  - "[[65c02-instruction-set]]"
  - "[[6502-programming-idioms]]"
  - "[[6502-emulated-instructions]]"
  - "[[6502-subroutine-conventions]]"
  - "[[6502-interrupt-patterns]]"
  - "[[6502-decimal-mode]]"
  - "[[6502-compare-instructions]]"
  - "[[6502-overflow-flag]]"
sources:
  - "[[leventhal-subroutines]]"
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Common Programming Errors

**Summary**: A systematic catalogue of bugs that commonly appear in 6502 assembly programs — carry misuse, flag side effects, addressing confusion, decimal mode hazards, loop errors, and ISR pitfalls — from Leventhal & Saville Ch. 3.

---

## Carry flag misuse

The Carry flag is the most common source of 6502 bugs because it behaves differently from most other processors and varies across instruction types.

### Carry is an inverted borrow in subtraction

`CMP`, `CPX`, `CPY`, `SBC` all set Carry = 1 if no borrow occurred, Carry = 0 if a borrow occurred. This is the **opposite** of the 6800, 6809, 8080, 8085, and Z-80.

```
CMP ADDR sets:
  Carry = 1  if (A) ≥ (ADDR)  [no borrow needed]
  Carry = 0  if (A) < (ADDR)  [borrow needed]
```

### Forgetting SEC before SBC

`SBC` subtracts `(1 − Carry)` from the result: `(A) = (A) − (M) − (1 − Carry)`.

If Carry is 0, SBC subtracts one extra — wrong answer.

```asm
; WRONG — Carry unknown:
SBC  #$40       ; result off by 1 if Carry happened to be 0

; CORRECT — explicit clear of borrow:
SEC
SBC  #$40       ; (A) = (A) − $40 exactly
```

### Forgetting CLC before ADC

`ADC` adds the Carry: `(A) = (A) + (M) + Carry`.

If Carry is 1 (left over from a prior comparison or shift), the result is one too high.

```asm
; WRONG:
ADC  #VALUE     ; adds extra 1 if Carry happens to be set

; CORRECT:
CLC
ADC  #VALUE
```

### INC/DEC do not affect Carry

`INC`/`DEC`/`INX`/`DEX`/`INY`/`DEY` never touch the Carry flag. This is actually useful — they can be used as loop counters inside a multi-byte carry chain without disturbing it. But:

```asm
; WRONG — detecting a carry from INC:
INC  ADDR
BCS  OVERFLOW   ; BCS will give unpredictable results!

; CORRECT — INC sets Zero flag when result wraps to $00:
INC  ADDR
BEQ  WRAPPED_TO_ZERO
```

For detecting borrow from a 16-bit decrement, the pattern is:

```asm
; 16-bit decrement of INDEX/INDEX+1 with borrow detection:
LDA  INDEX      ; check LSB BEFORE decrementing
BNE  NOINC      ; if not zero, no borrow from MSB needed
DEC  INDEX+1    ; borrow from MSB
NOINC:
DEC  INDEX
```

### Multi-byte carry chain — INC/DEC are safe loop counters

```asm
CLC
LDX  #N         ; byte count
LOOP:
LDA  OP1-1,X    ; load from operand 1
ADC  OP2-1,X    ; add + carry
STA  RESULT-1,X
DEX             ; safe: DEX doesn't touch Carry
BNE  LOOP
```

---

## Flag side effects

### STA, STX, STY do not set flags

Store instructions never modify any flags. After a store, the Zero and Negative flags reflect whatever happened **before** the store, not the value stored.

```asm
; WRONG:
STA  $1700
BEQ  DONE       ; BEQ tests Z flag — NOT the value just stored!

; CORRECT option 1 — compare first:
STA  $1700
CMP  #0
BEQ  DONE

; CORRECT option 2 — test register before storing:
STA  $1700
TAX             ; or TAY; or CMP #0
BEQ  DONE
```

### BIT instruction sets N and V unconditionally

`BIT ADDR` places bit 7 of `ADDR` in the **Negative flag** and bit 6 of `ADDR` in the **Overflow flag** — regardless of the accumulator value. Only the **Zero flag** reflects the logical AND of A and the memory location.

```asm
LDA  #%00010000  ; mask for bit 4
BIT  ADDR
BNE  BIT4_SET   ; Z=0 → bit 4 of ADDR is 1

; But simultaneously:
; N = bit 7 of ADDR (regardless of A)
; V = bit 6 of ADDR (regardless of A)
```

To test bit 7 or bit 6 of a memory location without loading A:
```asm
BIT  ADDR
BMI  BIT7_SET   ; bit 7 of ADDR is 1
BVS  BIT6_SET   ; bit 6 of ADDR is 1
```

### CMP does not affect Overflow

After `CMP`, the Overflow flag is **undefined** — it keeps its old value. Don't use `BVS`/`BVC` to test for overflow from a comparison.

```asm
; WRONG — trying to detect signed overflow from CMP:
CMP  #VALUE
BVS  DEST       ; V flag not affected by CMP!

; CORRECT — use SBC to affect overflow:
SEC
SBC  #VALUE     ; (A) − VALUE; sets V for signed overflow
BVS  DEST
```

### Only ADC, SBC, BIT, CLV affect the Overflow flag

Other instructions (shifts, comparisons, increments, loads, stores, transfers) do **not** change V. The 6502 differs from the 6800/6809 here — those processors set V on comparisons and shifts.

### Carry after comparison vs. after addition

- After `CMP`/`CPX`/`CPY`: Carry = 1 means ≥ (no borrow), Carry = 0 means < (borrow)
- After `ADC`: Carry = 1 means result overflowed 8 bits (unsigned carry-out)

These are **opposite conventions** — don't mix them.

---

## Addressing mode confusion

### Immediate vs. zero-page (data vs. address)

```asm
LDA  #$40   ; loads the NUMBER $40 into A
LDA  $40    ; loads the CONTENTS of memory location $0040 into A
```

Omitting `#` when you meant immediate is a common typo with no warning from many assemblers.

### Indirect address alignment on page 0

`LDA ($40),Y` uses memory locations `$0040` and `$0041` as a 16-bit pointer (LSB at `$0040`, MSB at `$0041`). If you accidentally use `LDA ($41),Y`, it picks up a pointer from `$0041`/`$0042` — which is almost certainly wrong.

Indirect addresses on page 0 must be **word-aligned** (or at least consistently arranged) — but the 6502 does not enforce this.

### NMOS 6502: JMP ($xxFF) page-boundary bug

On the **NMOS 6502** (not the 65C02 or W65C02S), `JMP ($12FF)` reads the high byte of the jump address from `$1200` instead of `$1300`. This is a hardware bug. The workaround is to avoid placing indirect jump vectors at `$xxFF`. The **W65C02S** (used in RP6502) fixes this bug.

> **RP6502 relevance**: The RP6502 uses the W65C02S, so this bug does not affect it. However, code ported from NMOS 6502 systems may have been written with workarounds that are no longer needed.

---

## Format and notation errors

### Hexadecimal prefix/suffix confusion

| Assembler | Hex syntax | Binary syntax |
|-----------|------------|---------------|
| Most (ca65, cc65) | `$40` | `%00000100` |
| Some (old) | `40H` | `00000100B` |

Using `AND #00000011` instead of `AND #%00000011` means ANDing with decimal 3 — which happens to be the same, but is accidentally correct and confusing.

### BCD digit conversion — ASCII digit ≠ BCD digit

```asm
; ASCII '5' is $35; the BCD digit 5 is $05
; WRONG — treating ASCII digit as BCD:
LDA  DIGIT      ; loads $35 (ASCII '5')
SED
ADC  BCDVAL     ; wrong! adding $35 not $05

; CORRECT — strip ASCII offset first:
LDA  DIGIT
SEC
SBC  #'0'       ; $35 − $30 = $05 = BCD digit 5
SED
CLC
ADC  BCDVAL
CLD
```

### Decimal mode and non-ADC/SBC instructions

`INC`, `DEC`, `INX`, `INY`, etc. always produce **binary** results even when `SED` is active. Only `ADC` and `SBC` produce decimal results.

---

## Array and loop errors

### Off-by-one in indexed loops

```asm
; Iterating over an N-element array at BASE:
LDX  #0
LOOP:
LDA  BASE,X
; ... process element ...
INX
CPX  #N
BNE  LOOP       ; processes elements 0, 1, ..., N-1 ✓

; WRONG — processes one too many (0..N):
; CPX  #N+1 or missing boundary check
```

### 8-bit index overflow for arrays > 256 bytes

Index registers are 8 bits — they cannot index beyond 255 bytes from the base address. For arrays > 256 bytes, use indirect indexed addressing with a page-zero pointer and increment the high byte when Y wraps:

```asm
LDA  INDR+1     ; high byte of base pointer
LOOP:
LDA  (INDR),Y
; ... process ...
INY
BNE  LOOP       ; Y wraps 255 → 0
INC  INDR+1     ; advance to next 256-byte page
BNE  LOOP       ; (continue until outer counter exhausted)
```

Forgetting to increment `INDR+1` causes the access to wrap back to the start of the current page.

---

## Implicit effects of instructions

Several instructions have side effects that are easy to overlook:

| Instruction | Unexpected effect |
|-------------|-------------------|
| `BIT ADDR` | N ← bit 7 of ADDR, V ← bit 6 of ADDR (regardless of A) |
| `ADC #$20` | Can set Carry even with small positive values if A is large |
| `JMP ($1C00)` | On NMOS 6502, if `$1CFF`/`$1D00` vector needed, reads wrong address if at `$1CFF` |
| `PLP` | Restores **all** flags including I (interrupt disable) — be careful in ISRs |
| `RTI` | Pulls P then PC — unlike `RTS` which adjusts the return address |
| `TXS` | Does **not** affect any flags (unlike all other transfer instructions) |

---

## Initialisation errors

### Uninitialised Decimal Mode flag

On reset, the 6502 does **not** clear the Decimal Mode (D) flag. A program that assumes binary mode (`D = 0`) without explicitly setting it with `CLD` will produce wrong arithmetic if D happens to be 1.

**Rule**: The main startup routine must execute `CLD`. Any interrupt service routine that executes `ADC` or `SBC` must also explicitly set or clear D, because it may be entered from code that runs in decimal mode.

### Uninitialised Carry before ADC/SBC chains

Always issue `CLC` before the first `ADC` in a multi-byte addition, and `SEC` before the first `SBC` in a multi-byte subtraction. Failing to do so gives wrong results when prior instructions left Carry in an unexpected state.

### Uninitialised indirect addresses

`LDA ($40),Y` loads from the address stored at `$0040`/`$0041`. If those locations are uninitialised, the load reads garbage.

---

## Program organisation errors

### Falling through into data

Placing data after the last instruction of a routine without a `JMP`/`RTS`/`BRA` causes the CPU to execute the data as instructions — usually producing crashes.

### Branch targets in the wrong routine

On 6502, branch instructions are relative (±127 bytes). If a label is used as a branch target but the code is reorganised, the branch may now exceed ±127 bytes — assembler error. Always check branch range after restructuring code.

---

## Assembler-reported errors vs. silent errors

Assemblers catch:
- Syntax errors
- Out-of-range branches (±127 bytes)
- Undefined labels

Assemblers do **not** catch:
- Missing `CLC`/`SEC` before `ADC`/`SBC`
- Wrong addressing mode (`LDA $40` vs. `LDA #$40`)
- Wrong branch condition (BEQ vs. BNE)
- Uninitialised decimal flag

These logic errors are invisible to the assembler and produce wrong results silently.

---

## I/O driver errors

Common bugs in input/output routines:

- **Not waiting for ready**: testing status after starting a transfer instead of before — the device may not have completed the previous transfer.
- **Wrong status bit**: checking the wrong bit of the status register (off-by-one in bit position).
- **Missing handshake clear**: not clearing the interrupt or ready flag after reading — the driver re-enters immediately.
- **Data register side effect**: on some peripherals (e.g., 6522 VIA), reading or writing the data register clears the interrupt flag. Reading the status port separately first may clear the flag before you read the data.

---

## Interrupt service routine errors

Common bugs in ISRs (see also [[6502-interrupt-patterns]]):

- **Not saving all used registers**: any register modified by the ISR must be saved on entry and restored before `RTI`. On NMOS 6502, only A can be pushed directly (`PHA`); X and Y require `TXA`/`PHA` and `TYA`/`PHA`. On 65C02, use `PHX`/`PHY`.
- **Not initialising the Decimal Mode flag**: enter with `CLD` (or `SED` if needed) rather than assuming D = 0.
- **Not clearing the interrupt source**: if the ISR does not clear the interrupt flag on the peripheral, the CPU immediately re-enters the ISR on `RTI`.
- **Not signalling the main program**: after servicing, set a flag or deposit data in a buffer so the main loop knows work was done.
- **Not saving/restoring write-only registers**: if the peripheral's control register is write-only, the ISR must maintain a RAM copy and update/restore it via the RAM copy.
- **Using RTI instead of RTS**: `RTI` also pulls the status register from the stack — if a normal subroutine was entered without pushing P, `RTI` will restore garbage into the flags.

---

## Related pages

- [[6502-emulated-instructions]] — the correct idioms that avoid these errors
- [[6502-programming-idioms]] — carry chains, BCD arithmetic, multi-precision operations
- [[6502-subroutine-conventions]] — correct parameter passing and register preservation
- [[6502-interrupt-patterns]] — ISR structure, register save/restore, flag management
- [[65c02-instruction-set]] — W65C02S fixes (JMP bug, `INC A`/`DEC A`, `PHX`/`PHY`)
- [[6502-decimal-mode]] — decimal mode hazards in depth (flag validity, cycle cost, interrupt D-clear)
- [[6502-compare-instructions]] — correct comparison patterns; V flag after CMP
- [[6502-overflow-flag]] — V flag mechanics underlying signed arithmetic errors
