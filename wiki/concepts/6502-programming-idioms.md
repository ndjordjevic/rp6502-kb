---
type: concept
tags: [6502, 65c02, assembly, arithmetic, bcd, multiply, divide, multi-precision, bit-manipulation, shift, logical, asl, lsr, rol, ror, and, ora, eor, bit, subroutine-parameters]
related: [[65c02-instruction-set]], [[6502-application-snippets]], [[6502-data-structures]], [[6502-emulated-instructions]], [[6502-common-errors]], [[6522-via]], [[learning-6502-assembly]], [[6502-subroutine-conventions]], [[6502-compare-instructions]], [[6502-decimal-mode]], [[6502-overflow-flag]]
sources: [[leventhal-6502-assembly]], [[leventhal-subroutines]], [[wagner-assembly-lines]], [[zaks-programming-6502]], [[6502org-tutorials]]
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

## Multi-precision binary addition (Leventhal 1982, Ch. 6)

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

## Shift and rotate operators (Wagner Ch. 12)

Four shift instructions move bits through the Accumulator (or a memory location) one position at a time, feeding in or out through the Carry flag.

| Instruction | Operation | Notes |
|-------------|-----------|-------|
| `ASL` | Arithmetic Shift Left: bit 7 → C, 0 → bit 0 | Multiplies by 2 |
| `LSR` | Logical Shift Right: bit 0 → C, 0 → bit 7 | Divides by 2 (unsigned) |
| `ROL` | Rotate Left: bit 7 → C, old C → bit 0 | Rotate through carry |
| `ROR` | Rotate Right: bit 0 → C, old C → bit 7 | Rotate through carry |

Flags affected: N, Z, C (for all four). Each instruction targets A (implied) or a memory location.

### ASL — multiply by powers of 2

```
$01 (0000 0001) → ASL → $02 (0000 0010), C=0
$80 (1000 0000) → ASL → $00 (0000 0000), C=1  (overflow)
$81 (1000 0001) → ASL → $02 (0000 0010), C=1
```

To multiply by 4: two ASLs. To multiply by 8: three ASLs. ASL is the fastest way to compute `N × 2^k` on the 6502.

```asm
    ASL  A           ; A *= 2
    ASL  A           ; A *= 2  (now A *= 4)
    ASL  A           ; A *= 2  (now A *= 8)
```

### LSR — test bit 0, halve a value

```
$01 (0000 0001) → LSR → $00, C=1  (C gets the bit we shifted out)
$02 (0000 0010) → LSR → $01, C=0
```

LSR is used to shift out the least-significant bit of an accumulator value for testing — the bit lands in Carry where `BCC`/`BCS` can act on it.

### ROL / ROR — chaining shifts through Carry

ROL/ROR thread the Carry flag through the shift, making them ideal for multi-byte shifts:

```asm
; Shift a 3-byte number (BASE, BASE+1, BASE+2) one bit left
    ASL  BASE+2      ; shift LSB: bit 7 → Carry
    ROL  BASE+1      ; shift middle: old Carry → bit 0, bit 7 → Carry
    ROL  BASE        ; shift MSB:   old Carry → bit 0, bit 7 → Carry
```

Note the direction: left-shift starts from the **LSB** (highest index) and works toward the **MSB** (lowest index). See also the multi-precision shift routines in the Leventhal section above.

### Common idiom: testing any bit with shifts

Shift left until the desired bit reaches bit 7, then use `BMI`/`BPL`:
```asm
    LDA  VALUE
    ASL  A           ; bit 6 → bit 7 → N flag
    BMI  BIT6_SET    ; branch if bit 6 was set
```

Or shift right until the desired bit falls into Carry:
```asm
    LDA  VALUE
    LSR  A           ; bit 0 → Carry
    BCS  BIT0_SET
    LSR  A           ; bit 1 → Carry
    BCS  BIT1_SET
```

---

## Logical operators: AND, ORA, EOR, BIT (Wagner Ch. 12)

All four logical operators work bit-by-bit on the Accumulator and an operand (immediate, zero page, absolute, or indexed):

### AND — force bits to 0, test bits

Truth table: `1 AND 1 = 1`; any `0 AND x = 0`.

```asm
    LDA  VALUE
    AND  #$0F        ; clear upper nibble (mask = 0000 1111)
    ; A now holds lower nibble only

    AND  #$C0        ; keep only bits 7 and 6
    CMP  #$C0
    BEQ  BOTH_SET    ; both bits 7 and 6 were 1
```

Primary uses: (1) force specific bits to 0 (masking), (2) isolate a sub-field, (3) test whether all of a set of bits are set (AND then CMP).

### ORA — force bits to 1

Truth table: `0 OR 0 = 0`; `1 OR x = 1`.

```asm
    LDA  CHAR
    ORA  #$80        ; set bit 7 (Apple II high-bit convention)
```

Used to force specific bits on without disturbing others.

### EOR — toggle bits, encode/decode

Truth table: `0 XOR 0 = 0`; `1 XOR 1 = 0`; `0 XOR 1 = 1` (exclusive).

```asm
    LDA  VALUE
    EOR  #$03        ; flip bits 0 and 1
    ; applying EOR again with the same mask restores original value
```

Key property: applying EOR with the same constant twice returns the original value. This makes it ideal for simple encryption/decryption and for toggling state (e.g., alternate between two display buffers).

```
Example – toggling bit 0:
  $80 EOR $03 = $83  (bits 0 and 1 flipped)
  $83 EOR $03 = $80  (restored)
```

### BIT — test memory bits without changing Accumulator

`BIT addr` ANDs the Accumulator with the memory byte and sets flags, but does **not** change A:
- **N flag** = bit 7 of the memory byte (not A AND memory)
- **V flag** = bit 6 of the memory byte (not A AND memory)
- **Z flag** = 1 if (A AND memory) = 0

```asm
; Test bit 7 — keyboard ready on Apple II:
    BIT  $C000       ; N = bit 7 of $C000 (key pressed if N=1)
    BPL  NOKEY       ; branch if N=0 (bit 7 clear, no key)

; Test bits 7 and 6 using mask in A:
    LDA  #$C0        ; mask = 1100 0000
    BIT  MEM
    BNE  ATLEAST_ONE ; Z=0 means at least one of bits 7,6 was set in MEM
```

The BIT instruction is the 6502's only way to test bits 6 and 7 directly in memory without loading the full value into A. It is also commonly used to clear the keyboard strobe: `BIT $C010` toggles the hardware without changing A.

**65C02 additions to BIT**: Three new addressing modes added: Immediate (`BIT #imm`), Absolute Indexed (`BIT addr,X`), Zero Page Indexed (`BIT zp,X`). The immediate mode is useful for quick flag tests; note that BIT immediate does NOT update N and V from the immediate value — only Z is updated.

---

## BCD mode fundamentals (Wagner Ch. 28)

The 6502 has a **Decimal mode** (D flag) that changes how `ADC` and `SBC` work. In decimal mode, each byte is treated as two **BCD** (Binary Coded Decimal) digits: the upper nibble holds the tens digit, the lower nibble holds the units digit.

### Enabling and disabling decimal mode

```asm
    SED              ; Set Decimal mode
    ; ... ADC/SBC here produce BCD results ...
    CLD              ; Clear Decimal mode (ALWAYS do this when done)
```

**Warning**: The D flag is NOT cleared on hardware reset (NMOS 6502) or power-up in all cases. Every startup routine and every ISR that uses ADC/SBC must execute `CLD` before the arithmetic. The 65C02 clears D on reset. See rule 7 in the quirks table above.

### BCD arithmetic example

```asm
    SED
    CLC
    LDA  #$46        ; $46 = BCD 46 (decimal 46)
    ADC  #$38        ; $38 = BCD 38 (decimal 38)
    ; Result: A = $84 (BCD 84 = decimal 84), not $7E (hex 78)
    CLD
```

In normal (binary) mode, `$46 + $38 = $7E`. In BCD mode, the 6502 automatically adjusts the result: `46 + 38 = 84` in decimal.

### Multi-byte BCD arithmetic

Multi-byte BCD works identically to multi-byte binary — carry propagates through `ADC`:

```asm
    SED
    CLC
    LDA  BCD1_LO     ; add low BCD byte (two digits)
    ADC  BCD2_LO
    STA  RESULT_LO
    LDA  BCD1_HI     ; add high BCD byte (two more digits)
    ADC  BCD2_HI     ; carry from low byte carries in
    STA  RESULT_HI
    CLD
```

### Printing BCD values

The major advantage of BCD: each nibble maps directly to a decimal digit. To convert one BCD byte to two ASCII characters:

```asm
    ; A = BCD byte (two digits)
    PHA              ; save original
    LSR  A           ; shift upper nibble down
    LSR  A
    LSR  A
    LSR  A           ; upper digit now in bits 3-0
    ORA  #$30        ; convert to ASCII digit ('0'–'9' = $30–$39)
    ; print upper digit
    PLA              ; restore original
    AND  #$0F        ; clear upper nibble
    ORA  #$30        ; convert lower nibble to ASCII
    ; print lower digit
```

With BCD, no divide-by-10 loop is needed for decimal display. This is the key advantage over raw binary: BCD storage allows O(1) digit extraction.

### BCD limitations

- Only values `$00`–`$99` per byte are valid BCD. Values `$A0`–`$FF` are undefined in decimal mode.
- `INC`/`DEC`/`INX`/`DEY` etc. are **always binary** even in decimal mode. Use `ADC #1` / `SBC #1` inside a `SED`…`CLD` block to increment BCD counters.
- `INC`/`DEC` inside decimal mode have no harmful effect on later `ADC`/`SBC` (the D flag only affects those two instructions), but counting results will be wrong.
- Never call Monitor, OS, or foreign routines while D=1 unless you know they handle decimal mode safely.

### BCD: 65C02 improvements

On the **W65C02S** (the RP6502 CPU), decimal mode is **fully specified**:
- N, Z, V flags are **valid** after BCD `ADC`/`SBC` (NMOS 6502: N and V are undefined after BCD operations).
- This matches the multi-precision BCD note in the Leventhal section above.

---

## Improved 8×8 multiply (Zaks Ch. 3)

Zaks presents an optimized multiply that halves the instruction count by placing the partial product in the accumulator, freeing register TMP. The accumulator is right-shifted via `ROR` to accept bits freed by the multiplier as it is shifted right.

```asm
; Inputs:  C = multiplier (memory byte), D = multiplicand (memory byte)
; Outputs: A = high byte of result, B = low byte (page 0 location)
; Uses: A (partial product high), B (partial product low), X (counter)

MULT    LDA  #0        ; initialize partial product high byte
        STA  B         ; initialize low byte
        LDX  #8        ; 8-bit shift counter
LOOP    LSR  C         ; shift multiplier right; bit falls into carry
        BCC  NOADD     ; if carry=0, no addition this pass
        CLC            ; carry was 1 — clear it before ADC
        ADC  D         ; A = A + multiplicand
NOADD   ROR  A         ; shift partial product high byte right (carry→bit7)
        ROR  B         ; shift partial product low byte, catching bit from A
        DEX
        BNE  LOOP      ; repeat for all 8 bits
```

**Key insight**: combining the multiplier's right-shift with the result's right-shift shares a single register chain. Each `ROR A` / `ROR B` pair shifts the 16-bit partial product right by one, reusing the bits that the multiplier frees from its left side. This is roughly half the code of the naive approach.

**Trade-off**: result ends up right-shifted (low byte in B, high byte accumulates in A). The result is the correct 16-bit product after all 8 iterations.

---

## Subroutine parameter passing (Zaks Ch. 3)

Three mechanisms for passing data between caller and subroutine:

| Method | Pros | Cons |
|--------|------|------|
| **Registers** (A, X, Y) | Fast; no fixed memory needed; subroutine is relocatable | Only 3×8-bit values |
| **Fixed memory locations** | Handles large data blocks | Ties the subroutine to specific addresses; unsafe for recursion |
| **Stack** | Relocatable; safe for recursion; natural for nested calls | Reduces available stack depth |

**Pointer hybrid**: when a large block of data must be passed, pass a 16-bit **pointer** to the block rather than the block itself. The pointer can travel in:
- two stack bytes (most portable)
- zero-page pair (fastest with `(zp),Y`)
- two registers (caller sets ZP pointer before JSR; callee dereferences via `(zp),Y`)

**Recursion** is legal on the 6502 because JSR saves the return address on the stack — each call creates a fresh stack frame. The only limits are the 256-byte stack size and the requirement that working registers be preserved on the stack, not in fixed memory.

> **Guideline** (Zaks): prefer registers → stack → fixed memory, in that order. Fixed-memory parameter passing is a "mailbox" convention and prevents reentrance.

---

## Related pages

- [[6502-application-snippets]] — string and code conversion idioms
- [[6502-data-structures]] — tables, sorted lists, sorting algorithms
- [[6502-emulated-instructions]] — simulating missing instructions (16-bit ops, shifts, extended branches)
- [[6502-common-errors]] — systematic catalogue of bugs arising from these quirks
- [[65c02-instruction-set]] — `INC A` / `DEC A` (65C02 new ops, save a CLC/ADC #1)
- [[6502-subroutine-conventions]] — packaging these as callable subroutines
- [[6522-via]] — VIA timer register idioms
- [[learning-6502-assembly]] — beginner introduction to loops, branches, Status Register
- [[6502-compare-instructions]] — CMP/CPX/CPY mechanics, multi-byte comparisons, signed branch selection
- [[6502-decimal-mode]] — BCD arithmetic, D flag, flag validity per CPU variant
- [[6502-overflow-flag]] — V flag mechanics, signed arithmetic, SO pin
