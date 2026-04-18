---
type: concept
tags: [6502, 65c02, assembly, decimal, bcd, flags, arithmetic, 65816]
related: [[65c02-instruction-set]], [[6502-programming-idioms]], [[6502-compare-instructions]], [[6502-overflow-flag]], [[6502-common-errors]], [[6502-interrupt-patterns]]
sources: [[6502org-tutorials]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Decimal Mode (BCD)

**Summary**: The 6502 family's D (decimal) flag enables BCD (Binary Coded Decimal) arithmetic in ADC and SBC. Flag validity, cycle counts, and interrupt D-flag behavior differ meaningfully between the NMOS 6502, CMOS 65C02, and 65C816.

---

## What is BCD?

BCD (Binary Coded Decimal) stores two decimal digits per byte: upper nibble = tens digit, lower nibble = ones digit. Valid range: `$00`–`$99` (representing 0–99 decimal).

- `$28` in BCD = 28 decimal (vs. 40 decimal in binary)
- Values `$xA`–`$xF` or `$Ax`–`$Fx` are **invalid BCD** (156 of 256 values)

**Packed BCD** (2 digits/byte) is the standard form on the 6502.  
**Unpacked BCD** (1 digit/byte, range `$00`–`$09`) wastes memory but resembles ASCII.

---

## The D flag

| Instruction | Effect on D |
|-------------|-------------|
| `CLD` | Clears D → binary mode |
| `SED` | Sets D → decimal mode |
| `PLP` | Restores D from stack |
| `RTI` | Restores D from stack |

Only **ADC** and **SBC** respond to the D flag. All other arithmetic instructions (ASL, INC, DEC, etc.) always use binary.

Standard pattern:
```assembly
SED         ; enter decimal mode
CLC
LDA  #$58
ADC  #$46   ; 58 + 46 = 104 → C=1, A=$04
CLD         ; back to binary mode
```

---

## Carry behavior in decimal mode

**ADC carry**:
- C=0 before → A = A + operand
- C=1 before → A = A + operand + 1
- Result: C=1 if result > 99; C=0 if result ≤ 99

**SBC carry** (inverted borrow):
- C=1 before → A = A − operand
- C=0 before → A = A − operand − 1
- Result: C=1 if result ≥ 0; C=0 if result < 0 (borrow)

### Multi-byte BCD

```assembly
; NUM3 = NUM1 + NUM2  (2-byte packed BCD, low byte first)
SED
CLC
LDA  NUM1L
ADC  NUM2L
STA  NUM3L
LDA  NUM1H
ADC  NUM2H    ; carry propagates automatically
STA  NUM3H
CLD
```

Subtraction is identical with SEC before the first SBC.

---

## Flag validity by processor

| Flag | NMOS 6502 | 65C02 | 65816 |
|------|-----------|-------|-------|
| C    | ✅ valid  | ✅ valid | ✅ valid |
| A (accumulator) | ✅ valid | ✅ valid | ✅ valid |
| N    | ❌ undocumented | ✅ valid | ✅ valid |
| Z    | ❌ undocumented | ✅ valid | ✅ valid |
| V    | ❌ undocumented | ❌ undocumented | ❌ undocumented |

**On the NMOS 6502**, only the accumulator result and C flag are guaranteed correct. N and Z may not match the actual accumulator in edge cases (e.g., `$99 + $01` produces A=`$00` but Z=0 on a 6502).

**V is undocumented on all variants.** BCD is fundamentally unsigned, so overflow semantics don't apply.

### Forcing valid N/Z flags on 6502

Insert a no-op arithmetic instruction after decimal ADC/SBC:

```assembly
SED
LDA  #$99
CLC
ADC  #$01     ; A=$00, Z=0 (incorrect on 6502)
EOR  #0       ; re-evaluates N and Z from current accumulator
              ; Z=1 (correct on 6502 too)
CLD
```

`EOR #0`, `AND #$FF`, or `ORA #0` all work (1 byte, 1 cycle). Valid only for valid BCD numbers.

---

## Cycle count differences

The 65C02 requires **one extra cycle** per ADC/SBC instruction in decimal mode to compute valid N and Z flags. The 65816 matches 6502 timing despite producing valid flags.

| Instruction | NMOS 6502 | 65C02 | 65816 |
|-------------|-----------|-------|-------|
| `ADC #$00` | 2 | 3 | 2 |
| `SBC $01FF,X` | 5 | 6 | 5 |

When multiple cycle penalties apply (page crossing + decimal mode on 65C02):

```
SBC $1234,X  =  4 (abs,X) + 1 (page boundary) + 1 (decimal)  =  6 cycles
```

---

## Interrupt D-flag behavior

| Interrupt | NMOS 6502 | 65C02 | 65816 |
|-----------|-----------|-------|-------|
| BRK | D unchanged | **D cleared** | D cleared |
| IRQ | D unchanged | **D cleared** | D cleared |
| NMI | D unchanged | **D cleared** | D cleared |
| RESET | undefined | D cleared | D cleared |

**On the NMOS 6502**, if decimal mode was active when an interrupt occurs, the ISR inherits D=1. ISRs must include an explicit `CLD` if they perform arithmetic.

**On the 65C02 and 65816**, the processor auto-clears D during the interrupt sequence (after pushing P to the stack). ISRs save two cycles per entry. However, binary mode arithmetic in the ISR may still require `CLD` for portability.

---

## BCD comparison

CMP works correctly on valid BCD numbers even though it performs binary subtraction:

> "$19 < $20 regardless of whether $19/$20 represent 25/32 (binary) or 19/20 (BCD)."

Z indicates equality; C indicates less-than/greater-or-equal. This holds for any valid BCD pair.

16-bit BCD comparison:
```assembly
LDA  NUM1L
CMP  NUM2L
LDA  NUM1H
SBC  NUM2H    ; C=0 if NUM1 < NUM2; C=1 if NUM1 ≥ NUM2
```

---

## Undocumented / exploited behaviors

### CPU identification

```assembly
SED
CLC
LDA  #$99
ADC  #$01     ; Z=0 on 6502 (invalid Z); Z=1 on 65C02 (valid Z)
CLD
```

### Hex nibble to ASCII (documented + alternative)

Using decimal carry (undocumented):
```assembly
SED
CMP  #$0A
ADC  #$30     ; $0–$9 → $30–$39; $A–$F → $41–$46
CLD
```

Portable equivalent without decimal mode:
```assembly
CMP  #$0A
BCC  SKIP
ADC  #$66     ; C is set from CMP; $0A–$0F → $71–$76
SKIP EOR #$30 ; $00–$09,$71–$76 → $30–$39,$41–$46
```

---

## Applications

- **Score/timer displays in games**: BCD arithmetic avoids the binary→decimal conversion step.
- **Hardware BCD counters** (74HC160): easier integration when keeping BCD throughout.
- **Financial/exact fractions**: BCD can represent `0.1` exactly; binary cannot (`6553/65536 ≈ 0.1`).

---

## Related pages

- [[6502-compare-instructions]]
- [[6502-overflow-flag]]
- [[6502-programming-idioms]]
- [[6502-common-errors]]
- [[65c02-instruction-set]]
- [[6502-interrupt-patterns]]
