---
type: concept
tags: [6502, 65c02, assembly, compare, cmp, cpx, cpy, signed, unsigned, multi-byte, flags]
related: [[65c02-instruction-set]], [[6502-programming-idioms]], [[learning-6502-assembly]], [[6502-overflow-flag]], [[6502-common-errors]], [[6502-emulated-instructions]]
sources: [[6502org-tutorials]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Compare Instructions

**Summary**: The 6502/65C02 compare instructions (CMP, CPX, CPY) perform subtraction without storing the result, setting N, Z, and C flags to indicate relative magnitude. This page covers basic compare mechanics, branch selection, and multi-byte equality/unsigned/signed comparisons.

---

## The compare instructions

| Instruction | Compares | Addressing modes |
|-------------|----------|-----------------|
| `CMP` | Accumulator vs. memory | 8 modes (immediate, zp, zp,X, abs, abs,X, abs,Y, (zp,X), (zp),Y) |
| `CPX` | X register vs. memory | 3 modes (immediate, absolute, zero page) |
| `CPY` | Y register vs. memory | 3 modes (immediate, absolute, zero page) |

All three execute `register − operand` internally. The register is **unchanged**. Only N, Z, C flags are affected. V is **not** affected (unlike SBC).

**Important difference from SBC**: CMP ignores the D (decimal) flag — it always performs binary subtraction.

---

## Flag results after compare

| Result | N | Z | C |
|--------|---|---|---|
| register < memory | * | 0 | **0** |
| register = memory | 0 | **1** | **1** |
| register > memory | * | 0 | **1** |

*N reflects bit 7 of (register − memory) and is **not** the signed comparison result.*

The reliable flags are:
- **Z = 1**: values are equal
- **C = 0**: register is less (unsigned)
- **C = 1**: register is greater or equal (unsigned)

---

## Branch selection table

| Branch condition | Unsigned | Signed |
|-----------------|----------|--------|
| register < data | BCC | BMI |
| register = data | BEQ | BEQ |
| register > data | `BEQ here / BCS there` | `BEQ here / BPL there` |
| register ≤ data | `BCC / BEQ` | `BMI / BEQ` |
| register ≥ data | BCS | BPL |

**Signed branches use BMI/BPL because N XOR V is the correct signed result** (see [[6502-overflow-flag]] and the multi-byte section below). For simple 8-bit signed CMP, N is close enough only when no overflow occurs, which is never guaranteed — always use the SBC method (§ Signed comparisons) for correctness.

---

## Practical tips

### Reversing operands saves code

Instead of:
```assembly
LDA NUM1
CMP NUM2
BCC LABEL   ; branch if NUM1 < NUM2
BEQ LABEL   ; (NUM1 ≤ NUM2)
```

Use:
```assembly
LDA NUM2
CMP NUM1
BCS LABEL   ; branch if NUM2 ≥ NUM1  (≡ NUM1 ≤ NUM2)
```

One instruction saved.

### Testing for equality

```assembly
LDA  $20
CMP  $21
BEQ  EQUAL   ; Z=1 → they match
```

Or with EOR (preserves C flag from a previous operation):
```assembly
LDA  BYTE1
EOR  BYTE2   ; Z=1 if equal; destroys A
BEQ  EQUAL
```

### EOR for partial-bit equality

```assembly
LDA  BYTE1
EOR  BYTE2
AND  #$AB    ; mask bits 7,5,3,1,0
BEQ  MATCH   ; those bits are equal
```

---

## Multi-byte equality

For 16-bit equality compare both bytes, branching on any mismatch:

```assembly
; Branch to LABEL if 16-bit NUM1 ≠ NUM2 (low byte in Y, high in A)
CPY  NUML
BNE  LABEL
CMP  NUMH
BNE  LABEL
```

Bytes may be compared in any order; EOR may substitute for CMP.

24-bit example (low in Y, mid in X, high in A):
```assembly
CPY  NUML
BNE  LABEL
CPX  NUMM
BNE  LABEL
CMP  NUMH
BNE  LABEL
```

---

## Multi-byte unsigned comparison

### Byte-at-a-time (high bytes first)

Fastest when high-byte inequality resolves the comparison early.

**16-bit: branch to LABEL2 if NUM1 < NUM2**

```assembly
     LDA  NUM1H
     CMP  NUM2H
     BCC  LABEL2   ; NUM1H < NUM2H → NUM1 < NUM2
     BNE  LABEL1   ; NUM1H > NUM2H → NUM1 ≥ NUM2
     LDA  NUM1L
     CMP  NUM2L
     BCC  LABEL2   ; NUM1L < NUM2L → NUM1 < NUM2
LABEL1
```

### Comparison by subtraction (compact)

After `CMP low_byte; SBC high_byte`, C holds the unsigned result.

```assembly
LDA  NUM1L
CMP  NUM2L    ; sets carry for subsequent SBC
LDA  NUM1H
SBC  NUM2H    ; C=1 if NUM1 ≥ NUM2, C=0 if NUM1 < NUM2
```

**24-bit by subtraction:**

```assembly
LDA  NUM1L
CMP  NUM2L
LDA  NUM1M
SBC  NUM2M
LDA  NUM1H
SBC  NUM2H    ; C holds result
```

### Simultaneous Z and C flags (16-bit)

```assembly
     CMP  NUMH    ; compare high bytes first
     BNE  LABEL
     CPY  NUML    ; compare low bytes (Z and C now reflect 16-bit result)
LABEL
```

---

## Signed comparisons (8-bit)

**The N flag after CMP is NOT the signed comparison result.** Examples:

- `LDA #$01; CMP #$FF` → C=0, N=0; but signed result is 1 ≥ −1 (should be ≥, not <)
- `LDA #$7F; CMP #$80` → C=0, N=1; but signed result is 127 ≥ −128

The correct method uses SBC, whose V flag captures signed overflow, making **N XOR V** the true signed result:

```assembly
; Signed less-than: branch to LABEL if A (signed) < NUM (signed)
SEC
SBC  NUM
BVC  LABEL    ; V=0 → N XOR V = N
EOR  #$80     ; V=1 → invert bit 7 → N XOR V now in N
LABEL
; BMI branches if A < NUM; BPL branches if A ≥ NUM
```

**After this sequence:**
- N=1 (BMI): A < NUM (signed)
- N=0 (BPL): A ≥ NUM (signed)
- C flag: still the unsigned comparison result (unaffected by BVC/EOR)

> **Note**: The Z flag does not indicate equality after signed comparison — EOR #$80 disturbs it.

### SO pin caveat

The 6502/65C02 SO pin (DIP-38) can set V externally. If SO is used in the circuit, use the MSB-flip alternative:

```assembly
LDA  NUM2
EOR  #$80    ; invert MSB of NUM2
STA  TEMP
LDA  NUM1
EOR  #$80    ; invert MSB of NUM1
CMP  TEMP    ; C=0: NUM1 < NUM2 (signed); C=1: NUM1 ≥ NUM2
```

---

## Multi-byte signed comparison

### 16-bit signed, result in N flag

```assembly
LDA  NUM1L
CMP  NUM2L    ; use CMP for low byte (no SEC needed — V is set by SBC high)
LDA  NUM1H
SBC  NUM2H
BVC  LABEL
EOR  #$80
LABEL
; BMI: NUM1 < NUM2; BPL: NUM1 ≥ NUM2
```

### 24-bit signed, result in N flag

```assembly
LDA  NUM1L
CMP  NUM2L
LDA  NUM1M
SBC  NUM2M
LDA  NUM1H
SBC  NUM2H
BVC  LABEL
EOR  #$80
LABEL
```

---

## CPX/CPY special uses

- Ideal for **count-up loop termination** — compare X or Y against a limit (up to 255).
- CPX/CPY can save an instruction over loading X/Y into A to use CMP.

```assembly
; Move N bytes (count in $1F)
LDX  #00
LOOP LDA  $20,X
     STA  $0320,X
     INX
     CPX  $1F
     BNE  LOOP
```

---

## Related pages

- [[65c02-instruction-set]]
- [[6502-overflow-flag]]
- [[6502-decimal-mode]]
- [[6502-programming-idioms]]
- [[6502-common-errors]]
- [[learning-6502-assembly]]
