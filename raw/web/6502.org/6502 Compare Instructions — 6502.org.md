---
title: "6502 Compare Instructions — 6502.org"
source: "https://6502.org/tutorials/compare_instructions.html"
author:
published: 2002-12-01
created: 2026-04-18
description: "Beginner-friendly guide to 6502 CMP/CPX/CPY: flag results table, branch instruction selection for unsigned and signed comparisons, and practical code examples including equality test, sorting, three-way decision, and multi-byte move."
tags:
  - "clippings"
---

# 6502 Compare Instructions

## Overview

The compare instructions establish or reset three status flags—Carry, Zero, and Negative—without modifying the operand itself. These flags can subsequently be tested using branch instructions.

## Compare Instruction Types

| Instruction | Description |
|---|---|
| CMP | Compare Memory and Accumulator |
| CPX | Compare Memory and Index X |
| CPY | Compare Memory and Index Y |

CMP supports eight addressing modes (same as ADC and SBC), while CPX and CPY operate with three modes: immediate, absolute, and zero page.

## How Compare Works

The compare instructions subtract an immediate value or memory contents from a register without storing the result. Only the three status flags indicate the outcome.

### Compare Instruction Results

| Compare Result | N | Z | C |
|---|---|---|---|
| A, X, or Y < Memory | * | 0 | 0 |
| A, X, or Y = Memory | 0 | 1 | 1 |
| A, X, or Y > Memory | * | 0 | 1 |

*The N flag reflects bit 7 of (A, X, or Y - Memory)*

## Branch Instructions Following Compare

| To Branch If | Unsigned | Signed |
|---|---|---|
| Register < data | BCC THERE | BMI THERE |
| Register = data | BEQ THERE | BEQ THERE |
| Register > data | BEQ HERE / BCS THERE | BEQ HERE / BPL THERE |
| Register ≤ data | BCC THERE / BEQ THERE | BMI THERE / BEQ THERE |
| Register ≥ data | BCS THERE | BPL THERE |

## Code Examples

### Example 1: Comparing Memory to Accumulator

```assembly
CMP  $20     ;Accumulator less than location $20?
BCC  THERE
HERE                 ;No, continue execution here.
        .
        .
        .
THERE                ;Execute this if Accumulator is less than location $20.
        .
        .
        .
```

### Example 2: Testing Two Locations for Equality

```assembly
;This routine sets memory location $22 to "One" if the contents
;of locations $20 and $21 are equal, and to "Zero" if otherwise.

        LDX  #00     ;Initialize flag to zero
        LDA  $20     ;Get first value
        CMP  $21     ;Is second value identical?
        BNE  DONE
        INX          ;Yes, set flag to one
DONE    STX  $22     ;Store flag
```

### Example 3: Arranging Two Numbers in Order of Value

```assembly
;This routine arranges two numbers in locations $20 and $21 in
;order of value, with the lower-valued number in location $20.

        LDA  $21     ;Load second number into accumulator
        CMP  $20     ;Compare the numbers
        BCS  DONE    ;DONE if first is less than or equal to second.
        LDX  $20
        STA  $20     ;Otherwise swap them.
        STX  $21
DONE     .
         .
         .
```

### Example 4: A Three-Way Decision Routine

```assembly
;This routine stores the contents of the accumulator into location
;$20, $21, or $22, depending upon whether the accumulator holds a
;value less than 3, equal to 3, or greater than 3, respectively.

        CMP  #03     ;Compare accumulator to 3
        BCS  EQGT3
        STA  $20     ;Accumulator less than 3
        JMP  DONE
EQGT3   BNE  GT3
        STA  $21     ;Accumulator equal to 3
        JMP  DONE
GT3     STA  $22     ;Accumulator greater than 3
DONE     .
         .
         .
```

### Example 5: A Multiple-Byte Move Routine

```assembly
;This routine moves up to 256 bytes of memory, starting at
;location $20, to another portion of memory, starting at location
;$0320.  The byte count is contained in location $1F.

        LDX  #00     ;Index = 0
NXTBYT  LDA  $20,X   ;Load next byte
        STA  $0320,X ;Store next byte
        INX          ;Increment index
        CPX  $1F     ;All bytes moved?
        BNE  NXTBYT  ;If not, move next byte
```

## Additional Notes

CPX and CPY are particularly valuable for monitoring X and Y register contents when used as count-up counters, enabling comparison against maximum values up to 255 (decimal).

For testing individual bits, the BIT instruction provides bit-masking functionality without altering the accumulator—a more efficient approach than AND in certain scenarios.

---

*Last Updated December 1, 2002*
