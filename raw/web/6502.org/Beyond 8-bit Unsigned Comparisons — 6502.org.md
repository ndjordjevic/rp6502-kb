---
title: "Beyond 8-bit Unsigned Comparisons — 6502.org"
source: "https://6502.org/tutorials/compare_beyond.html"
author: "Bruce Clark"
published: 2004-04-03
created: 2026-04-18
description: "Systematic 6502 comparison techniques: equality, unsigned, and signed comparisons extended to 16-bit and 24-bit; EOR-based tricks; signed comparison via N XOR V; SO pin caveat; verification test program."
tags:
  - "clippings"
---

# 6502.org Tutorials: Compare Instructions

## Table of Contents

1. Introduction
   - 1.1 Types of comparisons
   - 1.2 Review of twos complement (signed) numbers
2. Review of compare instructions
   - 2.1 The CMP, CPX, and CPY instructions
   - 2.2 A trick so simple that it's often overlooked
   - 2.3 Using EOR for equality comparisons
   - 2.4 Using EOR to compare only some of the bits in a byte
   - 2.5 A trick when using SBC for unsigned comparisons
3. Extending the equality comparison beyond 8 bits
4. Extending the unsigned comparison beyond 8 bits
   - 4.1 Comparing one byte at a time
   - 4.2 An equality and unsigned comparison
   - 4.3 Comparison by subtraction
5. Signed comparisons
   - 5.1 Comparing two 8-bit numbers
   - 5.2 A caveat: the SO pin
6. Extending the signed comparison beyond 8 bits
7. Appendix A: A program that demonstrates that the signed comparison works

---

## Introduction

The 6502 processor offers multiple options for comparing numerical values. Each method involves trade-offs regarding execution speed and code size. Additionally, some frequently misunderstood concepts exist regarding signed (twos complement) number comparisons.

### Types of comparisons

Two numbers are typically compared to determine either equality or relative magnitude. Three distinct comparison categories are used throughout this tutorial:

- **Equality Comparison**: determines whether two numbers are identical. The distinction between signed and unsigned representations is irrelevant for this operation.
- **Signed Comparison**: evaluates which of two signed numbers has the smaller value.
- **Unsigned Comparison**: evaluates which of two unsigned numbers has the smaller value.

Note that BCD numbers represent a subset of unsigned values, so unsigned comparison techniques apply to BCD operations.

### Review of twos complement (signed) numbers

A single byte contains 256 possible values: $00 to $FF in hexadecimal.

**8-bit ranges:**
- Unsigned: 0 ($00) to 255 ($FF)
- Signed: -128 ($80) to 127 ($7F)

**16-bit ranges:**
- Unsigned: 0 ($0000) to 65535 ($FFFF)
- Signed: -32768 ($8000) to 32767 ($7FFF)

**Key properties of twos complement representation:**

First, the overlapping range of 0 to 127 appears identically in both signed ($00 to $7F) and unsigned representations.

Second, the most significant bit (bit 7 for an 8-bit value) equals zero for non-negative values and one for negative values. This property directly inspired the naming of the N (negative) flag.

Third, addition and subtraction function identically for both signed and unsigned numbers. For example:

```assembly
CLC
LDA #$FF
ADC #$01
```

produces $00 with the carry flag set. In unsigned arithmetic, this represents 255 + 1 = 256. In signed arithmetic, this represents -1 + 1 = 0.

---

## Review of compare instructions

The 6502 provides three dedicated comparison instructions: CMP, CPX, and CPY. However, EOR and SBC instructions can also perform comparisons in specific contexts.

### The CMP, CPX, and CPY instructions

These instructions execute internal subtractions without modifying their respective registers. The instruction:

```assembly
CMP NUM
```

functions identically to:

```assembly
SEC
SBC NUM
```

regarding flag effects on N, Z, and C. However, CMP differs from SBC in three ways:

- CMP ignores the D (decimal) flag
- CMP leaves the accumulator unchanged
- CMP does not affect the V (overflow) flag

**Flag interpretation after CMP:**

The Z flag provides equality comparison results:
- Z = 0: values differ (BNE branches)
- Z = 1: values match (BEQ branches)

The C flag provides unsigned comparison results:
- C = 0: first value is smaller (BCC branches)
- C = 1: first value is greater or equal (BCS branches)

Many 6502 assemblers accept BLT (Branch on Less Than) and BGE (Branch on Greater than or Equal) as aliases for BCC and BCS respectively.

**Important note on the N flag:**

The N flag reflects bit 7 of the subtraction result. This is frequently misunderstood as the signed comparison result, which is incorrect. Consider these examples:

After `LDA #$01; CMP #$FF`:
- A = $01, C = 0, N = 0 (subtraction yields $02)
- Equality: false ($01 ≠ $FF)
- Signed: 1 ≥ -1
- Unsigned: 1 < 255

After `LDA #$7F; CMP #$80`:
- A = $7F, C = 0, N = 1 (subtraction yields $FF)
- Equality: false ($7F ≠ $80)
- Signed: 127 ≥ -128
- Unsigned: 127 < 128

Notice the N flag differs despite identical signed comparison results.

CPX and CPY function identically to CMP, except they operate on the X and Y registers respectively.

### A trick so simple that it's often overlooked

A common code pattern:

```assembly
LDA NUM1
CMP NUM2
BCC LABEL
BEQ LABEL
```

branches to LABEL when NUM1 ≤ NUM2 (unsigned). However, this sequence accomplishes the same result more efficiently:

```assembly
LDA NUM2
CMP NUM1
BCS LABEL
```

This shorter, often faster alternative branches when NUM2 ≥ NUM1, equivalent to NUM1 ≤ NUM2.

### Using EOR for equality comparisons

The EOR instruction performs equality comparisons with important differences from CMP:

- EOR modifies the accumulator (unlike CMP)
- EOR works only with the accumulator (no X or Y register variants)
- EOR does not affect the C flag

After EOR, the Z flag contains the equality result:
- Z = 0: values differ (BNE branches)
- Z = 1: values match (BEQ branches)

The fact that EOR preserves the C flag makes it valuable for maintaining unsigned comparison state from previous operations.

### Using EOR to compare only some of the bits in a byte

EOR enables selective bit comparison. After performing EOR, apply AND with a mask to isolate relevant bits. The Z flag will correctly reflect equality of only those masked bits.

Example:

```assembly
LDA BYTE1
EOR BYTE2
AND #$AB  ; $AB = %10101011 (binary)
```

The Z flag equals 1 (BEQ branches) if bits 7, 5, 3, 1, and 0 match between BYTE1 and BYTE2, and equals 0 (BNE branches) if they differ.

### A trick when using SBC for unsigned comparisons

Since CMP and SBC both perform subtraction, SBC can execute unsigned comparisons, though this is rare since SBC affects the accumulator. One useful scenario involves clearing the carry before SBC:

```assembly
CLC
SBC NUM
```

The C flag maintains the unsigned comparison result with inverted interpretation:
- C = 0: first value is smaller or equal (BCC branches)
- C = 1: first value is larger (BCS branches)

**Interesting note:** The V and C flags remain constant regardless of the D (decimal) flag state during SBC, even with invalid BCD values. This applies to the 6502, 65C02, and 65C816 processors.

---

## Extending the equality comparison beyond 8 bits

Extending equality comparisons beyond 8 bits requires no special tricks; simply compare bytes sequentially.

**Example 3.1:** 16-bit equality comparison (low byte in Y, high byte in A) branching to LABEL if unequal

```assembly
CPY NUML  ; compare low bytes
BNE LABEL
CMP NUMH  ; compare high bytes
BNE LABEL
```

**Example 3.2:** 16-bit equality comparison branching to LABEL2 if equal

```assembly
       CPY NUML   ; compare low bytes
       BNE LABEL1
       CMP NUMH   ; compare high bytes
       BEQ LABEL2
LABEL1
```

**Example 3.3:** 16-bit equality comparison leaving Z flag result

```assembly
       CPY NUML  ; compare low bytes
       BNE LABEL
       CMP NUMH  ; compare high bytes
LABEL
```

**Example 3.4:** 24-bit equality comparison (low byte in Y, middle byte in X, high byte in A) branching to LABEL if unequal

```assembly
CPY NUML  ; compare low bytes
BNE LABEL
CPX NUMM  ; compare middle bytes
BNE LABEL
CMP NUMH  ; compare high bytes
BNE LABEL
```

**Example 3.5:** 24-bit equality comparison branching to LABEL2 if equal

```assembly
       CPY NUML   ; compare low bytes
       BNE LABEL1
       CPX NUML   ; compare middle bytes
       BNE LABEL1
       CMP NUMH   ; compare high bytes
       BEQ LABEL2
LABEL1
```

**Notes:** Bytes may be compared in any order, and EOR can substitute for CMP in all examples.

---

## Extending the unsigned comparison beyond 8 bits

Multiple techniques exist for extending unsigned comparisons, each offering different speed and size trade-offs.

### Comparing one byte at a time

This straightforward approach compares high bytes first, proceeding toward low bytes. This method proves fastest when high byte comparisons frequently resolve the overall comparison early.

**Example 4.1.1:** 16-bit unsigned comparison branching to LABEL2 if NUM1 < NUM2

```assembly
       LDA NUM1H  ; compare high bytes
       CMP NUM2H
       BCC LABEL2 ; if NUM1H < NUM2H then NUM1 < NUM2
       BNE LABEL1 ; if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)
       LDA NUM1L  ; compare low bytes
       CMP NUM2L
       BCC LABEL2 ; if NUM1L < NUM2L then NUM1 < NUM2
LABEL1
```

**Example 4.1.2:** 16-bit unsigned comparison branching to LABEL2 if NUM1 >= NUM2

```assembly
       LDA NUM1H  ; compare high bytes
       CMP NUM2H
       BCC LABEL1 ; if NUM1H < NUM2H then NUM1 < NUM2
       BNE LABEL2 ; if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)
       LDA NUM1L  ; compare low bytes
       CMP NUM2L
       BCS LABEL2 ; if NUM1L >= NUM2L then NUM1 >= NUM2
LABEL1
```

**Example 4.1.3:** 24-bit unsigned comparison branching to LABEL2 if NUM1 < NUM2

```assembly
       LDA NUM1H  ; compare high bytes
       CMP NUM2H
       BCC LABEL2 ; if NUM1H < NUM2H then NUM1 < NUM2
       BNE LABEL1 ; if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)
       LDA NUM1M  ; compare middle bytes
       CMP NUM2M
       BCC LABEL2 ; if NUM1M < NUM2M then NUM1 < NUM2
       BNE LABEL1 ; if NUM1M <> NUM2M then NUM1 > NUM2 (so NUM1 >= NUM2)
       LDA NUM1L  ; compare low bytes
       CMP NUM2L
       BCC LABEL2 ; if NUM1L < NUM2L then NUM1 < NUM2
LABEL1
```

**Example 4.1.4:** 24-bit unsigned comparison branching to LABEL2 if NUM1 >= NUM2

```assembly
       LDA NUM1H  ; compare high bytes
       CMP NUM2H
       BCC LABEL1 ; if NUM1H < NUM2H then NUM1 < NUM2
       BNE LABEL2 ; if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)
       LDA NUM1M  ; compare middle bytes
       CMP NUM2M
       BCC LABEL1 ; if NUM1M < NUM2M then NUM1 < NUM2
       BNE LABEL2 ; if NUM1M <> NUM2M then NUM1 > NUM2 (so NUM1 >= NUM2)
       LDA NUM1L  ; compare low bytes
       CMP NUM2L
       BCS LABEL2 ; if NUM1L >= NUM2L then NUM1 >= NUM2
LABEL1
```

### An equality and unsigned comparison

CMP provides both equality and unsigned comparison results simultaneously. This technique extends that capability beyond 8 bits by comparing high bytes first, recognizing that unequal high bytes eliminate the need for lower byte comparison.

**Example 4.2.1:** 16-bit comparison leaving Z flag (equality) and C flag (unsigned comparison) results

```assembly
      CMP NUMH  ; compare high bytes
      BNE LABEL
      CPY NUML  ; compare low bytes
LABEL
```

**Example 4.2.2:** 24-bit comparison leaving Z flag (equality) and C flag (unsigned comparison) results

```assembly
      CMP NUMH
      BNE LABEL
      CPX NUMM
      BNE LABEL
      CPY NUML
LABEL
```

### Comparison by subtraction

Since CMP performs internal subtraction, multi-byte comparisons can use multi-byte subtraction. After the sequence:

```assembly
SEC       ; NUM3 = NUM1 - NUM2
LDA NUM1L
SBC NUM2L
STA NUM3L
LDA NUM1H
SBC NUM2H
STA NUM3H
```

The C flag contains the unsigned comparison result. Since only the C flag matters, the STA instructions can be removed, and SEC + first SBC replaced with CMP:

```assembly
LDA NUM1L
CMP NUM2L
LDA NUM1H
SBC NUM2H
```

A typical 24-bit unsigned comparison:

```assembly
LDA NUM1L
CMP NUM2L
LDA NUM1M
SBC NUM2M
LDA NUM1H
SBC NUM2H
```

---

## Signed comparisons

A critical misconception: the N flag from CMP is **not** the signed comparison result. Signed comparisons require calculating the exclusive-or (XOR) of the N and V flags. After subtracting NUM2 from NUM1, NUM1 < NUM2 when N XOR V = 1, and NUM1 ≥ NUM2 when N XOR V = 0.

### Comparing two 8-bit numbers

Since SBC places the subtraction result in the accumulator and the N flag reflects bit 7, use EOR to invert bit 7 when V = 1. This makes the N flag contain N XOR V.

**Signed less-than comparison:**

```assembly
      SEC       ; prepare carry for SBC
      SBC NUM   ; A-NUM
      BVC LABEL ; if V is 0, N eor V = N, otherwise N eor V = N eor 1
      EOR #$80  ; A = A eor $80, and N = N eor 1
LABEL
```

- N flag = 1: A (signed) < NUM (signed), BMI branches
- N flag = 0: A (signed) ≥ NUM (signed), BPL branches

The mnemonic connection aids memory: minus (BMI) equals less-than, plus (BPL) equals greater-than-or-equal.

The C flag retains the unsigned comparison result (unaffected by BVC and EOR).

**Placing signed comparison result in C flag:**

```assembly
      SEC
      SBC NUM
      BVS LABEL ; Note: BVS not BVC
      EOR #$80
LABEL ASL
```

Using BVS instead of BVC ensures bit 7 equals 0 when A < NUM and 1 when A ≥ NUM. ASL shifts this bit into the carry, providing C = 0 (BCC) when A < NUM and C = 1 (BCS) when A ≥ NUM.

**Variant with cleared carry:**

```assembly
      CLC       ; Note: CLC, not SEC
      SBC NUM
      BVC LABEL
      EOR #$80
LABEL
```

With cleared carry:
- N flag = 1: A (signed) ≤ NUM (signed), BMI branches
- N flag = 0: A (signed) > NUM (signed), BPL branches

**Important note:** The Z flag does **not** contain the equality comparison result after signed comparison. The EOR instruction affects the Z flag after initially reflecting the correct equality state.

**Decimal mode caveat:** Signed comparison fails in decimal mode when using EOR #$80 because BCD arithmetic produces different accumulator values. The V flag behavior remains consistent, but the subsequent EOR operates on an incorrect accumulator value.

### A caveat: the SO pin

The 6502 and 65C02 feature an uncommonly used pin named SO (DIP pin 38), which stands for Set Overflow. This pin allows hardware to set the V flag without software instructions. Since signed comparisons rely on the V flag, the SO pin warrants awareness. However, issues rarely arise because:

- The SO pin is seldom used
- When employed, its behavior is typically intentional and predictable
- The BVC instruction testing V immediately follows the SBC instruction setting it

If SO pin interference occurs, an alternative signed comparison method exists. Invert the most significant bit of **both** numbers before performing unsigned comparison:

```assembly
LDA NUM2
EOR #$80 ; invert the most significant bit of NUM2
STA TEMP ; store for CMP
LDA NUM1
EOR #$80 ; invert the most significant bit of NUM1
CMP TEMP
```

Results:
- C flag = 0: NUM1 (signed) < NUM2 (signed), BCC branches
- C flag = 1: NUM1 (signed) ≥ NUM2 (signed), BCS branches

Note: the Z flag contains the equality comparison result, but the unsigned comparison result is unavailable.

---

## Extending the signed comparison beyond 8 bits

Since the signed comparison method doesn't provide equality results, extending it beyond 8 bits typically uses the multi-byte subtraction approach from section 4.3.

**Example 6.1:** 16-bit signed comparison leaving signed comparison result in N flag

```assembly
      LDA NUM1L ; NUM1-NUM2
      CMP NUM2L
      LDA NUM1H
      SBC NUM2H
      BVC LABEL ; N eor V
      EOR #$80
LABEL
```

The V flag isn't needed until after high bytes are subtracted, allowing low byte subtraction with CMP without requiring SEC.

**Example 6.2:** 24-bit signed comparison leaving signed comparison result in N flag

```assembly
      LDA NUM1L ; NUM1-NUM2
      CMP NUM2L
      LDA NUM1M
      SBC NUM2M
      LDA NUM1H
      SBC NUM2H
      BVC LABEL ; N eor V
      EOR #$80
LABEL
```

**Example 6.3:** 16-bit signed comparison using byte-at-a-time approach (branching to LABEL4 if NUM1 < NUM2)

```assembly
       SEC
       LDA NUM1H  ; compare high bytes
       SBC NUM2H
       BVC LABEL1 ; the equality comparison is in the Z flag here
       EOR #$80   ; the Z flag is affected here
LABEL1 BMI LABEL4 ; if NUM1H < NUM2H then NUM1 < NUM2
       BVC LABEL2 ; the Z flag was affected only if V is 1
       EOR #$80   ; restore the Z flag to the value it had after SBC NUM2H
LABEL2 BNE LABEL3 ; if NUM1H <> NUM2H then NUM1 > NUM2 (so NUM1 >= NUM2)
       LDA NUM1L  ; compare low bytes
       SBC NUM2L
       BCC LABEL4 ; if NUM1L < NUM2L then NUM1 < NUM2
LABEL3
```

---

## Appendix A: A program that demonstrates that the signed comparison works

The signed comparison routine is demonstrated correct through the following program. It completes in approximately 3 seconds at 1 MHz.

```assembly
; Test the signed compare routine
;
; Returns with ERROR = 0 if the test passes, ERROR = 1 if the test fails
;
; Three (additional) memory locations are used: ERROR, N1, and N2
;
TEST    CLD        ; Clear decimal mode for test
        LDA #1
        STA ERROR  ; Store 1 in ERROR until test passes
        TSX        ; Save stack pointer so subroutines can exit with ERROR = 1
;
; Test N1 positive, N2 positive
;
        LDA #$00   ; 0
        STA N1
PP1     LDA #$00   ; 0
        STA N2
PP2     JSR SUCMP  ; Verify that the signed and unsigned comparison agree
        INC N2
        BPL PP2
        INC N1
        BPL PP1
;
; Test N1 positive, N2 negative
;
        LDA #$00   ; 0
        STA N1
PN1     LDA #$80   ; -128
        STA N2
PN2     JSR SCMP   ; Signed comparison
        BMI TEST1  ; if N1 (positive) < N2 (negative) exit with ERROR = 1
        INC N2
        BMI PN2
        INC N1
        BPL PN1
;
; Test N1 negative, N2 positive
;
        LDA #$80   ; -128
        STA N1
NP1     LDA #$00   ; 0
        STA N2
NP2     JSR SCMP   ; Signed comparison
        BPL TEST1  ; if N1 (negative) >= N2 (positive) exit with ERROR = 1
        INC N2
        BPL NP2
        INC N1
        BMI NP1
;
; Test N1 negative, N2 negative
;
        LDA #$80   ; -128
        STA N1
NN1     LDA #$80   ; -128
        STA N2
NN2     JSR SUCMP  ; Verify that the signed and unsigned comparisons agree
        INC N2
        BMI NN2
        INC N1
        BMI NN1

        LDA #0
        STA ERROR  ; All tests pass, so store 0 in ERROR
TEST1   RTS

; Signed comparison
;
; Returns with:
;   N=0 (BPL branches) if N1 >= N2 (signed)
;   N=1 (BMI branches) if N1 < N2 (signed)
;
; The unsigned comparison result is returned in the C flag (for free)
;
SCMP    SEC
        LDA N1     ; Compare N1 and N2
        SBC N2
        BVC SCMP1  ; Branch if V = 0
        EOR #$80   ; Invert Accumulator bit 7 (which also inverts the N flag)
SCMP1   RTS

; Test the signed and unsigned comparisons to confirm that they agree
;
SUCMP   JSR SCMP   ; Signed (and unsigned) comparison
        BCC SUCMP2 ; Branch if N1 < N2 (unsigned)
        BPL SUCMP1 ; N1 >= N2 (unsigned), branch if N1 >= N2 (signed)
        TXS        ; reset stack and exit with ERROR = 1
SUCMP1  RTS
SUCMP2  BMI SUCMP3 ; N1 < N2 (unsigned), branch if N1 < N2 (signed)
        TXS        ; reset stack and exit with ERROR = 1
SUCMP3  RTS
```

---

**Last Updated April 3, 2004**
