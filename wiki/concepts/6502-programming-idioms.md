---
type: concept
tags: [6502, 65c02, assembly, arithmetic, bcd, multiply, divide, multi-precision, bit-manipulation]
related: [[65c02-instruction-set]], [[6502-application-snippets]], [[6502-data-structures]], [[6502-emulated-instructions]], [[6502-common-errors]], [[6522-via]]
sources: [[leventhal-6502-assembly]], [[leventhal-subroutines]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Programming Idioms

**Summary**: Core 6502/65C02 arithmetic idioms — multi-precision binary and BCD addition, 8-bit multiply, 8-bit divide — from Leventhal Ch. 8. These patterns recur in any serious 6502 program.

---

## 16-bit arithmetic (Leventhal 1982)

The 6502 has no native 16-bit registers, so all word-length arithmetic is synthesised from 8-bit operations. The patterns below are adapted from the Leventhal 1982 subroutine library (Ch. 6) — each routine passes operands on the stack and returns the result at the top of the stack.

### 16-bit addition (ADD16) — 80 cycles, 38 bytes

```asm
; Stack convention (all little-endian 16-bit, LSB on top):
;   [top]  = return address LSB
;   [+1]   = return address MSB
;   [+2]   = operand 2 LSB
;   [+3]   = operand 2 MSB
;   [+4]   = operand 1 LSB
;   [+5]   = operand 1 MSB
; Exit: [top] = sum LSB, [+1] = sum MSB; Carry = carry out

ADD16:
    PLA : STA RETADR       ; save return address
    PLA : STA RETADR+1
    PLA : STA ADEND2       ; pop operand 2
    PLA : STA ADEND2+1
    PLA                    ; pop operand 1 LSB
    CLC
    ADC ADEND2             ; add LSBs (carry in = 0)
    TAY                    ; save sum LSB in Y
    PLA                    ; pop operand 1 MSB
    ADC ADEND2+1           ; add MSBs + carry from LSB addition
    PHA                    ; push sum MSB
    TYA : PHA              ; push sum LSB
    LDA RETADR+1 : PHA     ; restore return address
    LDA RETADR : PHA
    RTS
```

**Key points**: `CLC` before the first `ADC`, carry propagates naturally into the second `ADC`. Result Carry = overflow from the MSB addition (carry out of bit 15).

### 16-bit subtraction (SUB16) — 80 cycles, 38 bytes

Identical stack convention to ADD16. Subtrahend on top of minuend.

```asm
; Procedure: SEC before SBC on LSBs; SBC on MSBs uses borrow from LSB
    SEC
    PLA-operand1-lsb  SBC operand2-lsb  TAY   ; LSB difference in Y
    PLA-operand1-msb  SBC operand2-msb         ; MSB difference, Carry = not borrow
```

Carry = 1 means no borrow (minuend ≥ subtrahend). Carry = 0 means borrow.

### 16-bit multiplication (MUL16) — 650–1100 cycles, 238 bytes, 8 bytes data

Uses **shift-and-add** algorithm: 17 iterations (16 bits + 1 extra to capture the last carry). Maintains a 32-bit partial product in `HIPROD:MLIER` (full precision), but returns only the lower 16-bit word on the stack.

```
; Algorithm sketch:
; HIPROD:MLIER := 0      (32-bit partial product, MSW in HIPROD)
; for X = 17 downto 1:
;     ROR HIPROD+1, ROR HIPROD, ROR MLIER+1, ROR MLIER   (shift right 32 bits)
;     if Carry:
;         CLC; HIPROD := HIPROD + MCAND     (add multiplicand into high word)
```

- **Performance**: 650–1100 cycles (depends on number of 1-bits in multiplier). At 1 MHz ≈ 0.65–1.1 ms. At RP6502's 8 MHz ≈ 80–140 µs.
- **Precision**: full 32-bit product available in `HIPROD:MLIER`; the extra 16 MSBs are in memory after the call. Use them to check overflow.
- **Signed**: the routine is unsigned; for signed operands, take absolute values first, compute sign of result separately (XOR of sign bits), then negate the result if the sign is negative.

### 16-bit division (SDIV16 / UDIV16 / SREM16 / UREM16) — ~1000–1160 cycles, 293 bytes

Four entry points covering all sign/result combinations:
- **UDIV16**: unsigned quotient
- **UREM16**: unsigned remainder
- **SDIV16**: signed quotient
- **SREM16**: signed remainder (takes sign of dividend)

**Special case**: if divisor = 0, Carry is set to 1 and result = 0.

Algorithm: shift-and-subtract (also called non-restoring division). 16 iterations, each rotating quotient bit into position.

```
; Carry = 0 → normal; Carry = 1 → divide-by-zero error
; Both quotient (DVEND) and remainder (DVEND+2) are always computed;
; the correct one is returned to the stack based on entry point.
```

**Signed convention**: remainder takes the sign of the dividend (not the divisor). To get an always-positive remainder: if remainder sign differs from dividend sign, add the absolute value of the divisor.

### 16-bit comparison (CMP16) — ~90 cycles, 65 bytes

Returns flags as if a 16-bit subtraction had been performed. Corrects for two's complement overflow.

Exit flags:
- **Z = 1**: operands are equal.
- **Carry = 1** (if unsigned): minuend ≥ subtrahend (no borrow).
- **Negative = 1** (if signed): subtrahend > minuend (accounting for overflow correction).

Overflow correction: if the high-byte subtraction overflows, EOR result with `$80` to complement the Negative flag and force Z = 0.

---

## Bit manipulation idioms (Leventhal 1982, Ch. 7)

The 6502 lacks dedicated bit-set/clear/test instructions (unlike later CPUs). All bit operations use ORA/AND/EOR with a mask table. Leventhal provides a library of subroutines targeting **16-bit words** (A = high byte, Y = low byte, X = bit number 0–15).

### Bit Set (BITSET) — 57 cycles, 42 bytes

Sets bit X of the 16-bit word in A:Y. Uses a table of 8 single-bit masks (`00000001B` through `10000000B`).

```
; X = bit number (0..15)
; Determine byte: bit 3 of X → 0=low byte (Y), 1=high byte (A)
; Determine position within byte: X AND $07 → index into mask table
; OR that byte with the mask
```

### Bit Clear (BITCLR) — 57 cycles, 42 bytes

Clears bit X. Uses an inverted mask table (`11111110B` through `01111111B`). AND the selected byte with the mask.

### Bit Test (BITTST) — ~50 cycles, 37 bytes

Returns the value of bit X in the **Carry flag**. Algorithm: AND the byte with the single-bit mask; if result is zero (Z=1), Carry = 0; else Carry = 1.

```asm
; Usage: load A = MSB, Y = LSB, X = bit number; JSR BITTST → Carry = bit value
; Result: BCC means bit was 0; BCS means bit was 1
```

### Bit Field Extraction (BFE) — 134 bytes

Extracts a sub-field of N bits starting at bit position P from a 16-bit word, right-aligning the result:
1. Load a mask with N consecutive 1s from a table.
2. Shift mask left P times to align with the field.
3. AND with the data to isolate the field.
4. Shift right P times to normalise to bit 0.

Entry via stack: `[starting bit, field width, data low, data high]`. Exit: A = high byte, Y = low byte of extracted field.

If the requested field extends past bit 15, only the available bits are returned (no wraparound).

### Bit Field Insertion (BFI) — companion routine

Inserts a right-aligned value into a field of N bits at position P within a 16-bit word. Uses the same mask table as BFE; clears the target field via AND-inverted-mask then OR-shifts the new value in.

### Multi-precision shifts (7F–7J)

All operate on arbitrary-length byte arrays in memory:

| Routine | Operation | Notes |
|---------|-----------|-------|
| MPSLL (7F) | Multiple-precision logical shift left | Shifts carry from LSB upward; fills bit 0 with 0 |
| MPLSR (7G) | Multiple-precision logical shift right | Shifts carry from MSB downward; fills bit 7 with 0 |
| MPASR (7F-like) | Multiple-precision arithmetic shift right | Fills bit 7 with original sign bit (sign extension) |
| MPRR (7H) | Multiple-precision rotate right | Bit 0 → Carry → bit 7 of MSB |
| MPRL (7J) | Multiple-precision rotate left | Bit 7 → Carry → bit 0 of LSB |

General pattern for a left-shift loop (N-byte number at address BASE, length in X):

```asm
; Shift left (LSB to MSB)
    CLC                    ; no carry in
    LDX #LENGTH
SHFTLP:
    ROL BASE,X             ; rotate byte, carry out → Carry → next byte's bit 0
    DEX
    BNE SHFTLP
```

Arithmetic right shift requires copying the sign bit back into the MSB after the first `LSR`:

```asm
    LDA  BASE              ; MSB
    ASL  A                 ; put sign bit into Carry
    ROR  BASE              ; restore sign bit (arithmetic shift)
    ; then cascade ROR through remaining bytes
```

---

Add two N-byte unsigned integers stored MSB-first. The carry propagates from LSB to MSB via the `ADC` instruction.

```asm
; Input:  (0040) = byte length N
;         (0041..0040+N) = first number (MSB first)
;         (0051..0050+N) = second number (MSB first)
; Output: first number location = sum
; Registers used: A, X, Carry

        LDX  $40        ; X = length
        CLC             ; no carry into least-significant byte
ADDW:
        LDA  $40,X      ; load byte from number 1
        ADC  $50,X      ; add corresponding byte from number 2 (+ carry)
        STA  $40,X      ; store result
        DEX
        BNE  ADDW       ; repeat for all bytes
```

**Key points**:
- `CLC` is issued **once** before the loop — clears the carry into the LSBs.
- The loop works MSB-last (X counts down from N to 1) because LSB-to-MSB carry propagation requires starting from the least significant byte. Wait — actually, starting from `X = N` and going to `X = 1` processes the MSB in slot `$0040+N` (offset N) last, which is wrong for carry propagation. The correct pattern starts from the LSB (highest index) and counts down. Since the numbers are stored MSB-first, the LSBs are at the highest index (`$0040+N`). Iterating `X` from `N` down to `1` processes LSB first → MSB last. ✓
- `INC`/`DEC` instructions do **not** affect carry — safe to use as loop counters inside the carry chain.
- Ten binary bits ≈ 3 decimal digits (2¹⁰ = 1024 ≈ 1000). For K decimal digits of precision, use `ceil(K × 10/3)` bits ≈ `ceil(K / 2.4)` bytes.

---

## Multi-precision BCD (decimal) addition

Identical to binary addition, wrapped in `SED`/`CLD`:

```asm
        SED             ; decimal mode: ADC produces BCD-correct results
        LDX  $40
        CLC
ADDD:
        LDA  $40,X
        ADC  $50,X
        STA  $40,X
        DEX
        BNE  ADDD
        CLD             ; always return to binary mode immediately
```

**Decimal mode on 65C02 vs NMOS 6502**:
- On the W65C02S: N, V, Z flags are **valid** after BCD add/subtract (NMOS: N and V are undefined, Z requires an extra check).
- `INC`/`DEC`/`INX`/`DEX`/`INY`/`DEY` produce **binary** results even in decimal mode — use `ADC #1` / `SBC #1` with `SED` to increment/decrement decimal counters.
- Decimal subtraction (`SBC`) produces correct BCD results; Carry is an **inverted borrow** (Carry=0 means a borrow occurred).

**Warning**: Any code that calls subroutines or handles interrupts after `SED` may get wrong results if those routines don't know the decimal flag is set. Always pair `SED`/`CLD` as tightly as possible.

---

## 8-bit binary multiplication (shift-and-add)

Multiply two unsigned 8-bit operands, producing a 16-bit result. Algorithm: shift multiplier left one bit; if the bit is 1, add multiplicand to partial product; shift product left; repeat 8 times.

```asm
; Input:  (0040) = multiplicand, (0041) = multiplier
; Output: (0042) = LSBs of product, (0043) = MSBs of product
; Registers used: A, X, Carry

        LDA  #0
        STA  $43        ; clear MSBs of product
        LDX  #8         ; 8 iterations
SHIFT:
        ASL  A          ; shift product left (A = LSBs)
        ROL  $43        ; carry into MSBs
        ASL  $41        ; shift multiplier left: bit → Carry
        BCC  CHCNT      ; bit was 0 — skip addition
        CLC
        ADC  $40        ; add multiplicand to product LSBs
        BCC  CHCNT
        INC  $43        ; propagate carry into MSBs
CHCNT:
        DEX
        BNE  SHIFT
        STA  $42        ; save LSBs
```

**Performance**: 170–280 clock cycles depending on the number of 1-bits in the multiplier. Approximately 250 cycles typical at 1 MHz = ~250 µs. At the RP6502's maximum 8 MHz: ~31 µs.

**Signed extension**: for signed multiplication, sign-extend both operands to 16 bits, use this unsigned routine, then adjust the sign of the result.

---

## 8-bit binary division (shift-and-subtract)

Divide a 16-bit dividend by an 8-bit divisor, producing an 8-bit quotient and 8-bit remainder. Preconditions: MSB of dividend and divisor must be 0; divisor > MSB of dividend (guarantees 8-bit quotient).

```asm
; Input:  (0040) = dividend LSBs, (0041) = dividend MSBs
;         (0042) = divisor
; Output: (0043) = quotient, (0044) = remainder
; Registers used: A, X, Carry

; Algorithm: long division in binary — shift dividend left,
; subtract divisor from high byte if possible, record quotient bit

        LDA  $41        ; load high byte of dividend
        LDX  #8
DVLOOP:
        ASL  $40        ; shift dividend LSBs left
        ROL  A          ; shift carry into high byte
        SEC
        SBC  $42        ; try to subtract divisor
        BCS  SETBIT     ; carry set → subtraction succeeded
        ADC  $42        ; restore (subtract failed)
        CLC
SETBIT:
        ROL  $43        ; shift quotient bit in
        DEX
        BNE  DVLOOP
        STA  $44        ; remainder
```

---

## Decimal mode INC/DEC workaround

Because `INC`/`DEC` ignore decimal mode, use this pattern to increment a BCD counter:

```asm
        SED
        LDA  $40        ; load BCD counter
        CLC
        ADC  #1         ; BCD increment
        STA  $40
        CLD
```

---

## Carry-chain rules (summary)

| Instruction | Carry effect |
|-------------|-------------|
| `ADC` | Adds carry in, sets carry out |
| `SBC` | Uses carry as inverted borrow in, sets carry = not borrow |
| `CMP` | Sets carry (no borrow) if A ≥ M; **does not modify A** |
| `ASL` | Shifts bit 7 → carry |
| `LSR` | Shifts bit 0 → carry |
| `ROL` | Carry → bit 0, bit 7 → carry |
| `ROR` | Carry → bit 7, bit 0 → carry |
| `INC`/`DEC`/`INX`/`DEX`/`INY`/`DEY` | **Do not affect carry** ← safe loop counters |
| `CLC` | Clears carry (use before first `ADC` in a chain) |
| `SEC` | Sets carry (use before first `SBC` in a chain) |

---

## Quick reference: 14 6502 quirks (Leventhal 1982)

A concise list of the most common 6502 surprises for programmers familiar with other processors, from the *6502 Assembly Language Subroutines* "Quick Summary for Experienced Programmers":

1. **Carry = inverted borrow**: After `SBC`/`CMP`/`CPX`/`CPY`, Carry=1 means no borrow (i.e., result ≥ 0), opposite to 6800/8080/Z-80.
2. **CLC before ADC, SEC before SBC**: No plain Add/Subtract — must explicitly initialise Carry.
3. **No 16-bit registers**: Use zero-page pointer pairs (`PGZRO`/`PGZRO+1`) and indirect-indexed (`(zp),Y`) for 16-bit address arithmetic.
4. **No general indirect**: Only `JMP (addr)` is truly indirect; others require Y=0 and page-zero pointer via `(zp),Y`.
5. **Stack is page 1 only**: Limited to 256 bytes (`$0100–$01FF`); SP holds address of next **empty** slot.
6. **JSR saves PC−1**: `JSR` saves the address of its own last byte (not the next instruction). `RTS` adds 1 to compensate. Matters when using the saved return address as a data pointer.
7. **Decimal mode not reset on power-up**: Must execute `CLD` in the startup routine; ISRs that use `ADC`/`SBC` must explicitly set/clear D.
8. **Load/Transfer set N and Z; Store does not**: `STA`/`STX`/`STY` leave flags unchanged. (Exception: `TXS` does not set flags either.)
9. **INC/DEC cannot target A**: Use `CLC; ADC #1` / `SEC; SBC #1` — or on 65C02, use `INC A` / `DEC A`.
10. **Index registers are 8-bit only**: For arrays > 256 bytes, update the high byte of a page-zero pointer when Y wraps to 0.
11. **16-bit counters use two memory locations**: Counting up: `INC LO; BNE DONE; INC HI`. Counting down requires checking for borrow before the decrement.
12. **BIT instruction**: Sets N = bit 7 of memory, V = bit 6 of memory (regardless of A); Z = (A AND M == 0). Allows testing bits 7 and 6 without touching A.
13. **Missing instructions**: No `CLR`, `NOT`, `ADD`, `SUB`, `ASR`, `TXY`, unconditional relative branch, `INC A`, `DEC A` (pre-65C02). See [[6502-emulated-instructions]] for idioms.
14. **Byte order**: 16-bit addresses stored LSB first (same as 8080/Z-80, opposite to 6800/6809). Stack pointer points to **next empty** location (same as 6800, opposite to 8080). Interrupt flag I is active-high disable (same as 6800, opposite to 8080).

---

## Related pages

- [[6502-application-snippets]] — string and code conversion idioms
- [[6502-data-structures]] — tables, sorted lists, sorting algorithms
- [[6502-emulated-instructions]] — simulating missing instructions (16-bit ops, shifts, extended branches)
- [[6502-common-errors]] — systematic catalogue of bugs arising from these quirks
- [[65c02-instruction-set]] — `INC A` / `DEC A` (65C02 new ops, save a CLC/ADC #1)
- [[6502-subroutine-conventions]] — packaging these as callable subroutines
- [[6522-via]] — VIA timer register idioms
