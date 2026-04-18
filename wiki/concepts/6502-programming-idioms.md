---
type: concept
tags: [6502, 65c02, assembly, arithmetic, bcd, multiply, divide, multi-precision]
related: [[65c02-instruction-set]], [[6502-application-snippets]], [[6502-data-structures]]
sources: [[leventhal-6502-assembly]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Programming Idioms

**Summary**: Core 6502/65C02 arithmetic idioms — multi-precision binary and BCD addition, 8-bit multiply, 8-bit divide — from Leventhal Ch. 8. These patterns recur in any serious 6502 program.

---

## Multi-precision binary addition

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

## Related pages

- [[6502-application-snippets]] — string and code conversion idioms
- [[6502-data-structures]] — tables, sorted lists, sorting algorithms
- [[65c02-instruction-set]] — `INC A` / `DEC A` (65C02 new ops, save a CLC/ADC #1)
- [[6502-subroutine-conventions]] — packaging these as callable subroutines
