---
title: "Decimal Mode — 6502.org"
source: "https://6502.org/tutorials/decimal_mode.html"
author: "Bruce Clark"
published:
created: 2026-04-18
description: "Comprehensive reference for BCD (Binary Coded Decimal) arithmetic on the 6502 family: flag validity differences between 6502/65C02/65816, cycle count changes, interrupt D-flag behavior, and verification test programs."
tags:
  - "clippings"
---

# 6502.org Tutorials: Decimal Mode

## Table of Contents

1. Introduction
2. What is BCD?
3. Using Decimal Mode on the 6502
   - 3.1 Instructions that Affect the D Flag
   - 3.2 Instructions Affected by the D Flag
   - 3.2.1 The Accumulator and the Carry Flag
   - 3.2.2 The N, V, and Z Flags
   - 3.2.3 Cycle Counts on the 65C02
4. Useful Techniques
   - 4.1 Valid N and Z Flags on the 6502
   - 4.2 Using CMP to Compare BCD Numbers
5. Interrupts (Including BRK) and Decimal Mode
6. Code that Relies Upon Undocumented Decimal Mode Behavior
7. Decimal Mode Applications
8. Appendices

---

## Introduction

"BCD (Binary Coded Decimal) numbers can be directly added or subtracted on the 6502 by using decimal mode." The specifics of decimal mode operation and practical implementation require careful attention to the processor's behavior across different conditions and variants.

---

## What is BCD?

A byte can represent 256 possible values ranging from $00 to $FF. In Binary Coded Decimal representation, each byte stores two decimal digits: the upper 4 bits represent the tens digit, and the lower 4 bits represent the ones digit. This allows representation of values from 0 to 99.

For example, $28 in BCD represents 28 (decimal), whereas in binary it represents 40 (decimal). Values where either hex digit ranges from A to F are considered invalid BCD numbers; there are 156 such invalid values while 100 represent valid BCD.

### Packed vs. Unpacked BCD

**Packed BCD** stores two digits per byte ($00–$99 valid range). **Unpacked BCD** stores one digit per byte ($00–$09 valid range), with the remaining 246 values being invalid. While unpacked BCD wastes memory, it resembles ASCII digit encoding ($30–$39).

### BCD vs. Binary Arithmetic

- $19 + $28 = $47 using BCD addition
- $19 + $28 = $41 (25 + 40 = 65) using binary addition

---

## Using Decimal Mode on the 6502

The D (Decimal) flag determines whether ADC and SBC instructions produce binary or BCD results. When D = 0, the processor operates in "binary mode" (also called "hex mode"). When D = 1, it operates in "decimal mode" (also called "BCD mode").

### Instructions that Affect the D Flag

Four instructions modify the D flag:

| Instruction | Effect |
|-------------|--------|
| CLD | Clears D flag (binary mode) |
| SED | Sets D flag (decimal mode) |
| PLP | Pulls processor status from stack (affects all flags) |
| RTI | Returns from interrupt (affects all flags) |

On the 65816, REP and SEP instructions can also affect the D flag.

Most 6502 routines assume binary mode upon entry. "BCD calculations typically begin with a SED instruction, proceed with calculation code, and finish with a CLD instruction." For debugging routines that must preserve the D flag's initial state, use PHP before modification and PLP before returning.

### Instructions Affected by the D Flag

Only two instructions respond to the D flag: **ADC** (Add with Carry) and **SBC** (Subtract with Carry). All other instructions, including ASL, INC, and DEC, always perform binary operations regardless of the D flag state.

#### Example: D Flag Has No Effect on Non-Arithmetic Instructions

```assembly
SED           ; Decimal mode
LDA #$05
ASL A         ; Accumulator becomes $0A (binary result, not $10)

SED           ; Decimal mode
LDA #$09
STA NUM
INC NUM       ; NUM becomes $0A (binary result, not $10)
```

### The Accumulator and the Carry Flag

In decimal mode, the carry flag works similarly to binary mode but with different thresholds:

**ADC behavior:**
- C clear: A = A + NUM
- C set: A = A + NUM + 1

**SBC behavior:**
- C clear: A = A - NUM - 1
- C set: A = A - NUM

**Carry flag results after operation:**
- ADC: C set if result > 99, clear if result ≤ 99
- SBC: C clear if result < 0, set if result ≥ 0

#### Decimal Mode Addition Examples

```assembly
SED           ; Decimal mode (58 + 46 + 1 = 105)
SEC
LDA #$58
ADC #$46      ; C = 1, A = $05
```

```assembly
SED           ; Decimal mode (12 + 34 = 46)
CLC
LDA #$12
ADC #$34      ; C = 0, A = $46
```

```assembly
SED           ; Decimal mode (81 + 92 = 173)
CLC
LDA #$81
ADC #$92      ; C = 1, A = $73
```

#### Decimal Mode Subtraction Examples

```assembly
SED           ; Decimal mode (46 - 12 = 34)
SEC
LDA #$46
SBC #$12      ; C = 1, A = $34
```

```assembly
SED           ; Decimal mode (32 - 2 - 1 = 29)
CLC
LDA #$32
SBC #$02      ; C = 1, A = $29
```

#### Wraparound Behavior

Like binary mode, decimal mode exhibits wraparound:

```assembly
SED           ; Decimal mode (12 - 21)
SEC
LDA #$12
SBC #$21      ; C = 0, A = $91
```

#### Multi-Byte BCD Addition

```assembly
SED           ; BCD addition: NUM3 = NUM1 + NUM2
CLC
LDA NUM1L
ADC NUM2L
STA NUM3L
LDA NUM1H
ADC NUM2H
STA NUM3H
```

#### Multi-Byte BCD Subtraction

```assembly
SED           ; BCD subtraction: NUM3 = NUM1 - NUM2
SEC
LDA NUM1L
SBC NUM2L
STA NUM3L
LDA NUM1H
SBC NUM2H
STA NUM3H
```

### The N, V, and Z Flags

ADC and SBC affect the N, V, and Z flags even in decimal mode. However, their meanings differ between processors.

#### Z Flag Behavior

The Z flag indicates whether the result is zero (Z = 1) or non-zero (Z = 0) on both the 6502 and 65C02/65816. However, on the 6502 in decimal mode, the Z flag behavior with invalid BCD numbers or certain results may not match the accumulator contents.

#### N Flag Behavior

The N flag's value equals bit 7 of the result in decimal mode. On the 6502, it may not reflect the actual accumulator result with invalid BCD numbers.

#### V Flag Behavior

"The V flag does not have a useful meaning in decimal mode" because BCD is fundamentally unsigned. Interpreting $80–$99 as negative numbers (-20 to -1) would require special handling. The V flag behavior "follows binary subtraction rules" but cannot be meaningfully interpreted for negative BCD representation.

#### Flag Validity by Processor

| Processor | Valid Flags | Details |
|-----------|------------|---------|
| 6502 | C only | N, V, Z are undocumented; may not match accumulator |
| 65C02 | C, N, Z | V flag is also undocumented despite datasheet claims |
| 65816 | C, N, Z | V flag is undocumented; timing matches 6502 |

#### Example: Invalid Z Flag on 6502

```assembly
SED           ; Decimal mode (99 + 1 = 0)
CLC
LDA #$99
ADC #$01      ; A = $00, but Z flag = 0 (incorrect on 6502)
```

On a 65C02 or 65816, the Z flag would correctly be set to 1.

### Cycle Counts on the 65C02

Computing valid N and Z flags requires additional cycles on the 65C02:

| Instruction | 6502 | 65C02 | 65816 |
|-------------|------|-------|-------|
| ADC #$00 | 2 cycles | 3 cycles | 2 cycles |
| SBC $01FF,X | 5 cycles | 6 cycles | 5 cycles |

The 65816 matches 6502 timing despite producing valid flags. Programs requiring exact timing must account for these differences.

---

## Useful Techniques

### Valid N and Z Flags on the 6502

To ensure valid N and Z flags on the 6502 after ADC or SBC, insert an instruction that affects these flags without changing the accumulator:

```assembly
SED
LDA #$99
CLC
ADC #$01      ; A = $00
EOR #0        ; Ensures Z and N flags reflect accumulator
```

The instructions EOR #0, AND #$FF, or ORA #0 all take one byte and one cycle. This technique allows code to run on all 6502 variants without modification, though it's intended for valid BCD numbers only.

### Using CMP to Compare BCD Numbers

The CMP instruction can compare BCD numbers even though it performs binary subtraction:

"The reason is that $19 < $20, regardless of whether $19 and $20 represent 25 and 32 (unsigned binary numbers) or 19 and 20 (BCD numbers)."

The Z flag indicates equality, and the C flag indicates magnitude (clear for less-than, set for greater-than-or-equal).

#### 16-Bit BCD Comparison

```assembly
LDA NUM1L     ; Compare two 16-bit numbers
CMP NUM2L
LDA NUM1H
SBC NUM2H     ; C = 0 if NUM1 < NUM2; C = 1 if NUM1 ≥ NUM2
```

This works identically for both BCD and unsigned binary numbers.

---

## Interrupts (Including BRK) and Decimal Mode

The D flag behavior during interrupts varies by processor:

| Interrupt Type | 6502 | 65C02 | 65816 |
|---|---|---|---|
| BRK | No change | D cleared | D cleared |
| IRQ | No change | D cleared | D cleared |
| NMI | No change | D cleared | D cleared |
| COP/ABORT | N/A | N/A | D cleared |
| RESET | Undefined | D cleared | D cleared |

On 65C02 and 65816 processors, automatic D flag clearing saves a CLD instruction (2 cycles) per interrupt, improving response time. This is particularly beneficial for frequently occurring interrupts.

For 6502 compatibility, interrupt handlers should include explicit CLD instructions if decimal mode was active during the interrupt.

---

## Code that Relies Upon Undocumented Decimal Mode Behavior

Some techniques exploit undocumented behavior but may not work in simulators:

### Example 1: Distinguishing 6502 from 65C02

```assembly
SED
CLC
LDA #$99
ADC #$01      ; Z flag = 0 on 6502, Z flag = 1 on 65C02
CLD
```

This relies on the Z flag being invalid on the 6502 but valid on the 65C02.

### Example 2: Converting Hex Digit to ASCII

```assembly
SED
CMP #$0A
ADC #$30      ; Converts $00–$0F to $30–$39, $41–$46
CLD
```

This exploits decimal mode carry behavior but can be replicated without decimal mode:

```assembly
CMP #$0A
BCC SKIP
ADC #$66      ; Add $67 (carry is set); $0A–$0F → $71–$76
SKIP EOR #$30 ; $00–$09, $71–$76 → $30–$39, $41–$46
```

The second approach avoids undocumented behavior but requires 2 additional bytes.

---

## Decimal Mode Applications

### Hardware Integration

Hardware counters like the 74HC160 (BCD counter) naturally count 0–9, making BCD more convenient than binary for direct integration with hardware displays.

### Performance-Critical Operations

In arcade-style games, updating scores and timers quickly is crucial. "Any time saved could be used for additional action or other features." BCD arithmetic can be faster than converting binary to decimal for display.

### Fixed-Point and Floating-Point Math

Fixed-point numbers often combine an integer portion with a fractional portion. Binary fractions cannot represent 0.1 exactly (6553/65536 ≈ 0.1), but BCD fractions can (1000/10000 = 0.1 exactly).

This matters for financial calculations and user-facing numbers where 0.1 must be representable without approximation.

---

## Appendix A: Invalid BCD Values and Invalid Flags

Decimal mode undocumented behavior includes:

1. Arithmetic with invalid BCD numbers (values with hex digits A–F)
2. Invalid N and Z flags on 6502
3. V flag behavior in decimal mode

### ADC in Decimal Mode

The accumulator and carry results follow this sequence:

**Sequence 1 (Valid on all processors):**
```
1a. AL = (A & $0F) + (B & $0F) + C
1b. If AL >= $0A, then AL = ((AL + $06) & $0F) + $10
1c. A = (A & $F0) + (B & $F0) + AL
1d. If A >= $A0, then A = A + $60
1e. Accumulator = lower 8 bits of A
1f. Carry = 1 if A >= $100, else 0
```

**N and Z Flag Results:**

| Flag | 6502 | 65C02 | 65816 |
|------|------|-------|-------|
| N | Sequence 2 | dec | dec |
| Z | bin | dec | dec |

**Sequence 2 (For N flag):**
```
2a. AL = (A & $0F) + (B & $0F) + C
2b. If AL >= $0A, then AL = ((AL + $06) & $0F) + $10
2c. A = (A & $F0) + (B & $F0) + AL (signed arithmetic)
2e. N flag = 1 if bit 7 = 1, else 0
2f. V flag = 1 if A < -128 or A > 127, else 0
```

### SBC in Decimal Mode

**Sequence 3 (6502 and 65816):**
```
3a. AL = (A & $0F) - (B & $0F) + C - 1
3b. If AL < 0, then AL = ((AL - $06) & $0F) - $10
3c. A = (A & $F0) - (B & $F0) + AL
3d. If A < 0, then A = A - $60
3e. Accumulator = lower 8 bits of A
```

**Sequence 4 (65C02 only):**
```
4a. AL = (A & $0F) - (B & $0F) + C - 1
4b. A = A - B + C - 1
4c. If A < 0, then A = A - $60
4d. If AL < 0, then A = A - $06
4e. Accumulator = lower 8 bits of A
```

**SBC Flag Results:**

| Flag | 6502 | 65C02 | 65816 |
|------|------|-------|-------|
| C | bin | bin | bin |
| N | bin | dec | dec |
| V | bin | bin | bin |
| Z | bin | dec | dec |

---

## Appendix B: Program to Verify Decimal Mode Operation

This comprehensive test program verifies decimal mode behavior by testing all 262,144 cases (2 instructions × 2 carry values × 256 accumulator values × 256 operand values).

```assembly
; Verify decimal mode behavior
; Written by Bruce Clark. This code is public domain.
;
; Returns:
;   ERROR = 0 if test passed
;   ERROR = 1 if test failed
;
; Variables required (17 bytes RAM):
;   AR, CF, DA, DNVZC, ERROR, HA, HNVZC, N1, N1H, N1L, N2, N2L, N2H (2 bytes), NF, VF, ZF

TEST    LDY #1        ; initialize Y (loop through carry flag values)
        STY ERROR     ; store 1 in ERROR until test passes
        LDA #0        ; initialize N1 and N2
        STA N1
        STA N2
LOOP1   LDA N2        ; N2L = N2 & $0F
        AND #$0F      ; [1] see text
        STA N2L
        LDA N2        ; N2H = N2 & $F0
        AND #$F0      ; [2] see text
        STA N2H
        ORA #$0F      ; N2H+1 = (N2 & $F0) + $0F
        STA N2H+1
LOOP2   LDA N1        ; N1L = N1 & $0F
        AND #$0F      ; [3] see text
        STA N1L
        LDA N1        ; N1H = N1 & $F0
        AND #$F0      ; [4] see text
        STA N1H
        JSR ADD
        JSR A6502
        JSR COMPARE
        BNE DONE
        JSR SUB
        JSR S6502
        JSR COMPARE
        BNE DONE
        INC N1        ; [5] see text
        BNE LOOP2     ; loop through all 256 values of N1
        INC N2        ; [6] see text
        BNE LOOP1     ; loop through all 256 values of N2
        DEY
        BPL LOOP1     ; loop through both carry flag values
        LDA #0        ; test passed
        STA ERROR
DONE    RTS

ADD     SED           ; decimal mode
        CPY #1        ; set carry if Y = 1, clear if Y = 0
        LDA N1
        ADC N2
        STA DA        ; actual accumulator result in decimal mode
        PHP
        PLA
        STA DNVZC     ; actual flags result in decimal mode
        CLD           ; binary mode
        CPY #1
        LDA N1
        ADC N2
        STA HA        ; accumulator result of N1+N2 using binary arithmetic
        PHP
        PLA
        STA HNVZC     ; flags result of N1+N2 using binary arithmetic
        CPY #1
        LDA N1L
        ADC N2L
        CMP #$0A
        LDX #0
        BCC A1
        INX
        ADC #5        ; add 6 (carry is set)
        AND #$0F
        SEC
A1      ORA N1H
        ADC N2H,X
        PHP
        BCS A2
        CMP #$A0
        BCC A3
A2      ADC #$5F      ; add $60 (carry is set)
        SEC
A3      STA AR        ; predicted accumulator result
        PHP
        PLA
        STA CF        ; predicted carry result
        PLA
        STA VF        ; predicted V flags (all 8 bits of P register)
        RTS

SUB     SED           ; decimal mode
        CPY #1
        LDA N1
        SBC N2
        STA DA        ; actual accumulator result in decimal mode
        PHP
        PLA
        STA DNVZC     ; actual flags result in decimal mode
        CLD           ; binary mode
        CPY #1
        LDA N1
        SBC N2
        STA HA        ; accumulator result of N1-N2 using binary arithmetic
        PHP
        PLA
        STA HNVZC     ; flags result of N1-N2 using binary arithmetic
        RTS

SUB1    CPY #1        ; set carry if Y = 1, clear if Y = 0
        LDA N1L
        SBC N2L
        LDX #0
        BCS S11
        INX
        SBC #5        ; subtract 6 (carry is clear)
        AND #$0F
        CLC
S11     ORA N1H
        SBC N2H,X
        BCS S12
        SBC #$5F      ; subtract $60 (carry is clear)
S12     STA AR
        RTS

SUB2    CPY #1        ; set carry if Y = 1, clear if Y = 0
        LDA N1L
        SBC N2L
        LDX #0
        BCS S21
        INX
        AND #$0F
        CLC
S21     ORA N1H
        SBC N2H,X
        BCS S22
        SBC #$5F      ; subtract $60 (carry is clear)
S22     CPX #0
        BEQ S23
        SBC #6
S23     STA AR        ; predicted accumulator result
        RTS

COMPARE LDA DA        ; compare accumulator actual to predicted
        CMP AR
        BNE C1
        LDA DNVZC     ; [7] see text
        EOR NF
        AND #$80      ; mask off N flag
        BNE C1
        LDA DNVZC     ; [8] see text
        EOR VF
        AND #$40      ; mask off V flag
        BNE C1        ; [9] see text
        LDA DNVZC
        EOR ZF        ; mask off Z flag
        AND #2
        BNE C1        ; [10] see text
        LDA DNVZC
        EOR CF
        AND #1        ; mask off C flag
C1      RTS

A6502   LDA VF        ; store predicted values for ADC on 6502
        STA NF
        LDA HNVZC
        STA ZF
        RTS

S6502   JSR SUB1
        LDA HNVZC
        STA NF
        STA VF
        STA ZF
        STA CF
        RTS

A65C02  LDA AR
        PHP
        PLA
        STA NF
        STA ZF
        RTS

S65C02  JSR SUB2
        LDA AR
        PHP
        PLA
        STA NF
        STA ZF
        LDA HNVZC
        STA VF
        STA CF
        RTS

A65816  LDA AR
        PHP
        PLA
        STA NF
        STA ZF
        RTS

S65816  JSR SUB1
        LDA AR
        PHP
        PLA
        STA NF
        STA ZF
        LDA HNVZC
        STA VF
        STA CF
        RTS
```

### Testing Valid BCD Numbers Only

To test only valid BCD numbers, add these modifications:

1. Add label NEXT1 to INC N1
2. Add label NEXT2 to INC N2
3. After AND #$0F in LOOP1, add:
   ```assembly
   CMP #$0A
   BCS NEXT2
   ```
4. After AND #$F0 in LOOP1, add:
   ```assembly
   CMP #$A0
   BCS NEXT2
   ```
5. After AND #$0F in LOOP2, add:
   ```assembly
   CMP #$0A
   BCS NEXT1
   ```
6. After AND #$F0 in LOOP2, add:
   ```assembly
   CMP #$A0
   BCS NEXT1
   ```

### Testing Valid Flags Only

For the 6502, remove N, V, and Z flag comparisons from COMPARE.

For 65C02 and 65816, remove V flag comparison from COMPARE.

---

## Appendix C: Decimal Mode on the 65816 with 16-Bit Numbers

On the 65816, 16-bit BCD arithmetic can be decomposed into 8-bit operations. With m flag = 0 (16-bit accumulator) and e flag = 0 (native mode):

### 16-Bit ADC Equivalence

```assembly
REP #$20      ; 16-bit accumulator and memory
ADC N1
STA N2
```

Produces the same accumulator and N, V, C flags as:

```assembly
SEP #$20      ; 8-bit accumulator and memory
ADC N1        ; add low bytes first
STA N2
XBA
ADC N1+1      ; then add high bytes
STA N2+1
```

For the Z flag, use:

```assembly
SEP #$20
ADC N1        ; add low bytes first
STA N2
XBA
ADC N1+1      ; then add high bytes
ORA N2        ; check all 16 bits for Z flag
```

### 16-Bit SBC Equivalence

```assembly
REP #$20      ; 16-bit accumulator and memory
SBC N1
STA N2
```

Produces the same accumulator and N, V, C flags as:

```assembly
SEP #$20      ; 8-bit accumulator and memory
SBC N1        ; subtract low bytes first
STA N2
XBA
SBC N1+1      ; then subtract high bytes
STA N2+1
```

For the Z flag, use:

```assembly
SEP #$20
SBC N1        ; subtract low bytes first
STA N2
XBA
SBC N1+1      ; then subtract high bytes
ORA N2        ; check all 16 bits for Z flag
```

---

## Appendix D: Errata for Appendix B

The test program requires specific processor routines:

- **6502**: Use JSR A6502 and JSR S6502
- **65C02**: Use JSR A65C02 and JSR S65C02
- **65816**: Use JSR A65816 and JSR S65816

### Program Design Notes

The program calculates correct values using binary arithmetic; therefore, binary arithmetic must function correctly to avoid false positives or negatives.

N2H is a 2-byte variable; all others are 1 byte.

The program tests 262,144 cases (2 instructions × 2 carry values × 256 accumulator values × 256 operand values).

### Result Interpretation

Returns:
- $00 in ERROR if all tests passed
- $01 in ERROR if any test failed

When a failure occurs, the program stops, allowing inspection of:
- Input values (Y register contains carry; N1 contains accumulator; N2 contains operand)
- Expected results (AR, NF, VF, ZF, CF calculated using binary arithmetic)
- Actual results (DA contains accumulator; DNVZC contains all flags)

### Flag Result Storage

Results are stored with specific bits set:

- **NF**: Bit 7 contains N flag result; other bits ignored
- **VF**: Bit 6 contains V flag result; other bits ignored
- **ZF**: Bit 1 contains Z flag result; other bits ignored
- **CF**: Bit 0 contains C flag result; other bits ignored

### COMPARE Routine Structure

The COMPARE routine tests results in this order:

1. Lines 1–3: Compare accumulator result
2. Lines 4–7: Compare N flag result
3. Lines 8–11: Compare V flag result
4. Lines 12–15: Compare Z flag result
5. Lines 16–18: Compare C flag result

Modifications to test only valid flags require removing specific comparison sections.

### Execution Time

The program requires approximately 1 minute at 1 MHz (slightly longer on 65C02 than 6502 or 65816).

**Last Updated September 12, 2016.**
