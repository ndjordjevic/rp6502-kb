---
title: "The Overflow (V) Flag Explained — 6502.org"
source: "https://6502.org/tutorials/vflag.html"
author: "Bruce Clark"
published:
created: 2026-04-18
description: "Complete explanation of the 6502/65C02 overflow flag: which instructions affect V, two's complement arithmetic overflow, the SO hardware pin, 65C02 BIT new addressing modes, and decimal mode V behavior."
tags:
  - "clippings"
---

# 6502.org Tutorials: The Overflow (V) Flag Explained

## Table of Contents

1. Introduction
2. Instructions that affect V
   - CLV
   - PLP and RTI
   - BIT
   - ADC and SBC
3. The hardware caveat: the SO pin
4. V and the 65816
5. Why should I take your word for it?
6. Appendices

---

## Introduction

The overflow (V) flag represents one of the 6502's more enigmatic features. As noted in this tutorial, "the overflow flag will be referred to as V" for brevity. The flag serves multiple purposes, which contributes to widespread confusion about its behavior.

Several factors complicate understanding V:

- It sees infrequent use, so developers may lack practical experience
- Different instructions affect V in distinct ways
- The BIT instruction uses V for non-arithmetic purposes
- A hardware subtlety exists via the SO pin
- Reference materials often lack detailed coverage
- Some existing documentation contains errors

A notable anecdote from former Commodore engineer Bil Herd describes discovering the SO pin's origins on the original 6502 schematic, revealing it was called the "Chuck Peddle Special pin" in pencil notation.

---

## Instructions that affect V

Only six instructions modify V: ADC, BIT, CLV, PLP, RTI, and SBC.

### CLV

CLV clears the V flag. Common usage pairs CLV with BVC to simulate a forced branch in relocatable code, compensating for the 6502's lack of a dedicated BRA instruction (available on the 65C02).

### PLP and RTI

Both instructions restore the processor status register from the stack. Since V occupies bit 6 of the status register, both instructions set V according to bit 6 of the pulled byte.

### BIT

On the original 6502, BIT supports zero page and absolute addressing. The 65C02 and 65816 add zero page indexed by X, absolute indexed by X, and immediate modes.

The immediate mode (65C02/65816 only) does not affect V. Other modes set V to match bit 6 of the specified memory location.

#### Example Usage

If memory location $1000 contains $AB (binary 10101011), then "BIT $1000 will clear V, since bit 6 of $AB is 0." Conversely, if $1000 holds $40 (binary 01000000), then "BIT $1000 will set V, since bit 6 of $40 is 1."

Common applications include:
- Testing bit 6 of a memory location via BVC/BVS
- Setting V (since no SEV instruction exists) by reading a ROM location containing a byte with bit 6 set, such as $60 (RTS)

### ADC and SBC

These instructions produce the most confusion regarding V. Understanding V with ADC and SBC requires reviewing unsigned numbers, two's complement representation, and arithmetic overflow concepts.

#### Unsigned Numbers, Addition, and Subtraction

Bytes can represent values $00–$FF (0–255 unsigned). The carry flag serves two purposes:

1. Extending arithmetic operations beyond 8 bits
2. Indicating when results exceed the 0–255 range

The carry behaves as follows:

- Addition result 0–255: carry cleared
- Addition result > 255: carry set
- Subtraction result 0–255: carry set
- Subtraction result < 0: carry cleared

#### Two's Complement (Signed Numbers)

Two's complement represents negative numbers by selecting values where adding a number to its negative yields zero. For 8-bit numbers, the range spans –128 to 127.

**Key Properties:**

The range 0–127 uses identical representations in both unsigned ($00–$7F) and two's complement systems. Bit 7 indicates sign: set for negative, clear for non-negative. The value $80 represents –128 due to this convention.

Examples:
- $01 + $FF = $00 (1 + –1 = 0)
- $02 + $FE = $00 (2 + –2 = 0)
- $7F + $01 = $80 (127 + 1 = –128 in two's complement, overflow)

Two's complement extends to 16-bit numbers (range –32,768 to 32,767) and beyond, with the most significant bit indicating sign.

#### Two's Complement Addition and Subtraction

While carry facilitates multi-byte operations, it fails to indicate two's complement overflow. V fills this role: it detects when signed arithmetic results fall outside the valid range (–128 to 127 for 8-bit).

**Test Cases:**

```assembly
CLC      ; 1 + 1 = 2, returns V = 0
LDA #$01
ADC #$01

CLC      ; 127 + 1 = 128, returns V = 1
LDA #$7F
ADC #$01

CLC      ; 1 + –1 = 0, returns V = 0
LDA #$01
ADC #$FF

CLC      ; –128 + –1 = –129, returns V = 1
LDA #$80
ADC #$FF

SEC      ; 0 – 1 = –1, returns V = 0
LDA #$00
SBC #$01

SEC      ; –128 – 1 = –129, returns V = 1
LDA #$80
SBC #$01

SEC      ; 127 – –1 = 128, returns V = 1
LDA #$7F
SBC #$FF
```

The carry's input state affects the result and V. Example:

```assembly
SEC      ; Note: SEC, not CLC
LDA #$3F ; 63 + 64 + 1 = 128, returns V = 1
ADC #$40

CLC      ; Note: CLC, not SEC
LDA #$C0 ; –64 – 64 – 1 = –129, returns V = 1
SBC #$40
```

For 16-bit two's complement subtraction:

```assembly
SEC         ; RESULT = NUM1 – NUM2
LDA NUM1L   ; After SBC NUM2H:
SBC NUM2L   ;   V = 0 if –32768 ≤ RESULT ≤ 32767
STA RESULTL ;   V = 1 if RESULT < –32768 or RESULT > 32767
LDA NUM1H
SBC NUM2H
STA RESULTH
```

---

## The Hardware Caveat: The SO Pin

Beyond software control, the 6502 and 65C02 feature an SO (Set Overflow) pin that allows hardware to set V independently. The 65816 lacks this pin.

The SO pin sets V on a negative transition (high-to-low voltage change). Variant nomenclatures in documentation include: SO, /SO, –SO, \*SO, SOB, SOBAR, S.O.

On a 40-pin DIP package, SO is pin 38. The 65C02 includes internal pull-up on the SO pin; unused pins should still be pulled high or low as a precaution.

**Practical Consideration:** The SO pin rarely appears in actual circuits. When present, it operates predictably for specific purposes. The guideline: ignore the SO pin unless hardware events suggest otherwise.

### An SO Pin Example

Memory-mapped I/O systems typically place RAM at $0000+, ROM at $FFFF−, with I/O between them. Polling hardware events conventionally looks like:

```assembly
LOOP BIT FLAG ; test the hardware flag
     BMI LOOP ; loop until the hardware flag goes low
```

An alternative using SO:

```assembly
     CLV
LOOP BVC LOOP ; loop until the hardware sets V
```

The SO-based approach saves 4 cycles per iteration (3 vs 7 cycles assuming no page boundary crossing), though it requires hardware capable of asserting SO and removes the FLAG address for other purposes. Hardware flexibility makes FLAG-based polling more practical in most designs.

---

## V and the 65816

The 65816 maintains V behavior consistent with the 65C02 and 6502, with notable additions:

**No SO Pin:** The 65816 eliminates the SO pin entirely.

**REP and SEP Instructions:** These affect V based on bit 6 of their operand:
- REP clears V if bit 6 is set
- SEP sets V if bit 6 is set

Examples:

```assembly
REP #$40 ; clear V (2 bytes, 3 cycles, like CLV)
REP #$41 ; clear V and carry flag

SEP #$40 ; set V only
SEP #$41 ; set V and carry flag

SEP #$01 ; set carry flag only (V unaffected)
```

**16-Bit Mode:** When the m flag is 0, the 65816 operates on 16-bit data. BIT now reflects bit 14 (rather than bit 6) into V. ADC and SBC work with 16-bit numbers, making V indicate overflow for the range –32,768 ($8000) to 32,767 ($7FFF).

---

## Why Should I Take Your Word for It?

The tutorial includes a complete test program validating V behavior across all 8-bit combinations. The program exhaustively tests ADC and SBC with both carry states and all 256×256 value pairs, comparing V against predicted unsigned overflow conditions.

**Program Overview:**

- Initializes S1 from –128 ($80) to 127 ($7F)
- Initializes S2 similarly
- Maintains unsigned equivalents U1 and U2
- Tests both ADC and SBC with carry set and cleared
- Validates V against mathematical predictions
- Completes in approximately 16 seconds at 1 MHz

**Mathematical Basis:**

For addition with U1 = S1 + 128 and U2 = S2 + 128:
- V = 0 when U1 + U2 ≥ 128 and U1 + U2 ≤ 383 ($17F)
- V = 1 when U1 + U2 < 128 or U1 + U2 > 383

For subtraction, using (65280 + U1) − U2:
- V = 0 when result ≥ 65152 ($FE80) and result ≤ 65407 ($FF7F)
- V = 1 when result < 65152 or result > 65407

The complete assembly code is provided in the tutorial for validation.

---

## Appendices

### Appendix A: Another Way of Thinking About Two's Complement

Binary digit positions represent powers of 2, with the most significant bit in two's complement representing a negative power. For $AB (10101011):

Unsigned interpretation:
```
1×128 + 0×64 + 1×32 + 0×16 + 1×8 + 0×4 + 1×2 + 1×1 = 171
```

Two's complement interpretation:
```
1×(−128) + 0×64 + 1×32 + 0×16 + 1×8 + 0×4 + 1×2 + 1×1 = −85
```

The most significant bit weight becomes negative, enabling signed representation within the same bit width.

### Appendix B: What About Decimal Mode?

The 65C02 datasheet notes that when the D flag enables decimal mode, ADC and SBC require one additional cycle, and N, V, Z flags become valid (the 6502 only guaranteed C).

**SBC in Decimal Mode:**

V behavior matches non-decimal SBC; perform the operation treating numbers as two's complement (even invalid BCD), then check V.

**ADC in Decimal Mode:**

V is determined by processing one decimal digit at a time:

1. Add lower digits; carry if result exceeds 9
2. Add upper digits as 4-bit two's complement numbers (–8 to 7)
3. V = 1 if upper digit sum overflows the –8 to 7 range

**Examples:**

```
  24
+ 56
----
Lower: 4 + 6 = 10 (carry 1)
Upper: 1 + 2 + 5 = 8 (out of range −8 to 7, V = 1)

  89
+ 76
----
Lower: 9 + 6 = 15 (carry 1)
Upper: 1 + 8 + 7 = 1 + (−8) + 7 = 0 (in range, V = 0)
```

Behavior persists even with invalid BCD numbers. When lower digits sum beyond 19, carry exactly 1 (not proportional to excess).

This behavior, tested on Rockwell 6502, Synertek 6502, GTE 65C02, and GTE 65C816 variants, constitutes undocumented behavior and should not be relied upon in critical code.

---

Last Updated: April 4, 2004
