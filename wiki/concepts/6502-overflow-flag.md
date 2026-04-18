---
type: concept
tags: [6502, 65c02, assembly, flags, overflow, signed, arithmetic, so-pin, bit, adc, sbc]
related: [[65c02-instruction-set]], [[6502-programming-idioms]], [[6502-compare-instructions]], [[6502-decimal-mode]], [[6502-common-errors]], [[learning-6502-assembly]]
sources: [[6502org-tutorials]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Overflow (V) Flag

**Summary**: The V (overflow) flag signals two's-complement signed arithmetic overflow in ADC and SBC. Only six instructions affect it. The BIT instruction uses V for non-arithmetic bit testing. The SO hardware pin can set it externally. Understanding V is essential for correct signed arithmetic.

---

## Instructions that affect V

Only **six** instructions modify V:

| Instruction | Effect on V |
|-------------|-------------|
| `ADC` | Set if signed result out of −128…+127 range |
| `SBC` | Set if signed result out of −128…+127 range |
| `BIT` | Copies bit 6 of memory into V (immediate mode on 65C02 does NOT affect V) |
| `CLV` | Clears V unconditionally |
| `PLP` | Restores V from stack (bit 6 of pulled byte) |
| `RTI` | Restores V from stack |

**Notably absent**: INC, DEC, ASL, LSR, ROL, ROR, AND, ORA, EOR, CMP, CPX, CPY — none affect V.

There is no `SEV` instruction. To set V in software, use `BIT` on a ROM location whose bit 6 is 1:
```assembly
BIT  $FFFF   ; $FFFF typically holds $60 (RTS opcode); bit 6 = 1 → V set
```

---

## Two's complement review

8-bit signed range: −128 (`$80`) to +127 (`$7F`). Bit 7 is the sign bit.

- $00–$7F = 0 to +127
- $80–$FF = −128 to −1

V detects when signed arithmetic produces a result outside this range. The C flag detects unsigned overflow.

| Test | Code | V result |
|------|------|---------|
| 1 + 1 = 2 | `CLC; LDA #$01; ADC #$01` | V=0 (in range) |
| 127 + 1 = 128 | `CLC; LDA #$7F; ADC #$01` | **V=1** (out of range) |
| 1 + (−1) = 0 | `CLC; LDA #$01; ADC #$FF` | V=0 |
| (−128) + (−1) = −129 | `CLC; LDA #$80; ADC #$FF` | **V=1** |
| 0 − 1 = −1 | `SEC; LDA #$00; SBC #$01` | V=0 |
| (−128) − 1 = −129 | `SEC; LDA #$80; SBC #$01` | **V=1** |
| 127 − (−1) = 128 | `SEC; LDA #$7F; SBC #$FF` | **V=1** |

The carry-in state affects V:
```assembly
SEC             ; (63) + (64) + 1 = 128 → V=1
LDA  #$3F
ADC  #$40
```

---

## 16-bit signed subtraction

```assembly
SEC
LDA  NUM1L
SBC  NUM2L
STA  RESULTL
LDA  NUM1H
SBC  NUM2H
STA  RESULTH
; After SBC NUM2H:
;   V=0 if −32768 ≤ RESULT ≤ 32767
;   V=1 if RESULT < −32768 or RESULT > 32767
```

---

## BIT instruction and V

BIT copies **bit 6** of the memory operand into V, and **bit 7** into N. Z is set from `A AND memory`.

```assembly
BIT  $1000   ; if [$1000] = $40 (bit 6 = 1) → V set
             ; if [$1000] = $80 (bit 6 = 0) → V clear
```

Common uses:
- Test bit 6 of a hardware register via `BVC`/`BVS` without destroying A.
- `CLV; BVC LOOP` = forced branch for relocatable code (pre-BRA 6502 idiom).

**65C02 BIT immediate mode exception**: `BIT #imm` only affects Z; it does **not** affect N or V. This is unique — BIT is the only instruction with different flag effects across addressing modes.

```assembly
BIT  $12     ; (abs) → affects N, V, Z
BIT  #$12    ; (imm, 65C02 only) → affects Z only
```

---

## Signed comparison using V

For signed comparisons, the correct test is **N XOR V**, not N alone. After `SEC; SBC NUM`:

```assembly
SEC
SBC  NUM
BVC  LABEL    ; if V=0, N XOR V = N (nothing to do)
EOR  #$80     ; if V=1, flip bit 7 → N XOR V now in N
LABEL
; BMI: register < NUM (signed); BPL: register ≥ NUM (signed)
```

> See [[6502-compare-instructions]] for full signed comparison patterns and multi-byte extension.

---

## The SO hardware pin

The 6502 and 65C02 have a hardware **SO** (Set Overflow) pin — DIP pin 38. A **negative transition** (high→low) sets V regardless of software state.

- Pin aliases: SO, /SO, −SO, *SO, SOB, SOBAR, S.O.
- The **65C02 has an internal pull-up** on SO; unused pins should still be pulled high.
- The **65816 does not have the SO pin** — it was removed entirely.
- 65816 uses REP/SEP: `REP #$40` clears V; `SEP #$40` sets V.

**Hardware polling alternative using SO**:

Standard approach (polling loop):
```assembly
LOOP BIT  FLAG    ; 3–7 cycles per iteration
     BMI  LOOP
```

SO-based approach:
```assembly
     CLV
LOOP BVC  LOOP   ; 3 cycles per iteration; 4 if branch crosses page
```

The SO approach saves ~4 cycles/iteration but requires hardware capable of asserting SO and sacrifices the FLAG address.

---

## Decimal mode and V

V is **undocumented** in decimal mode on all 6502 variants. BCD is fundamentally unsigned, so signed overflow is meaningless. Nonetheless:

- **SBC in decimal mode**: V follows binary SBC rules — apply the formula treating values as two's complement, even if they're invalid BCD.
- **ADC in decimal mode**: V depends on a two-step process involving per-nibble carry — see [[6502-decimal-mode]] for the algorithm.
- This behavior has been tested on Rockwell 6502, Synertek 6502, GTE 65C02, and GTE 65C816 but should not be relied upon.

---

## 65816 additions

The 65816 adds REP and SEP instructions that can modify V directly (bit 6 of their operand):

```assembly
REP  #$40    ; clear V (equivalent to CLV; 2 bytes, 3 cycles)
SEP  #$40    ; set V
REP  #$41    ; clear V and carry
SEP  #$01    ; set carry only (V unaffected)
```

In 16-bit mode (m=0), BIT reflects **bit 14** of memory into V instead of bit 6, and ADC/SBC detect overflow in the −32768…+32767 range.

---

## Common mistakes

1. **Assuming N after CMP is the signed result** — wrong; only N XOR V is correct. See [[6502-compare-instructions]].
2. **Using PHP/PLA to read B flag for BRK vs. IRQ** — wrong; read it from the stack via TSX. See [[6502-stack-and-subroutines]].
3. **Expecting V to be set after INC, DEC, shift, or logical operations** — V is unaffected by all of these.

---

## Related pages

- [[6502-compare-instructions]]
- [[6502-decimal-mode]]
- [[6502-programming-idioms]]
- [[6502-common-errors]]
- [[65c02-instruction-set]]
- [[learning-6502-assembly]]
