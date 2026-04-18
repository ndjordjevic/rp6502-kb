---
title: "Register Preservation Using The Stack — 6502.org"
source: "https://6502.org/tutorials/register_preservation.html"
author: "Bruce Clark"
published: 2004-06-07
created: 2026-04-18
description: "Stack-based A/X/Y register preservation on 6502 and 65C02: 65C02 PHX/PHY/PLX/PLY simplification, 6502 workarounds, BRK/IRQ handler with B-flag disambiguation, cycle and byte cost comparisons."
tags:
  - "clippings"
---

# Register Preservation Using The Stack (and a BRK handler)

**by Bruce Clark, 7 Jun 2004**

---

## Overview

This technical guide explains how to preserve CPU registers (A, X, Y) on 6502 and 65C02 processors using stack-based techniques, with applications to interrupt handling.

## 65C02 Register Preservation

The 65C02 processor simplifies register preservation with dedicated instructions:

```assembly
PHA
PHX
PHY
```

Restoration uses:

```assembly
PLY
PLX
PLA
RTS
```

## 6502 Register Preservation

Since the 6502 lacks PHX/PLX and PHY/PLY instructions, alternative approaches are required.

### Basic Method (Preserves X and Y, overwrites A)

```assembly
PHA
TXA
PHA
TYA
PHA
```

Restoration:

```assembly
PLA
TAY
PLA
TAX
PLA
RTS
```

### Preserving All Three Registers with Temporary Storage

```assembly
STA TEMP
PHA
TXA
PHA
TYA
PHA
LDA TEMP
```

This approach requires "4 additional bytes and 6 additional cycles if TEMP is a zero page location." However, it necessitates disabling interrupts when the subroutine operates alongside interrupt handlers to prevent conflicts over the temporary storage.

### Stack-Based Alternative (No Temporary Storage)

```assembly
PHA
TXA
TSX
PHA
TYA
PHA
INX
LDA $100,X ; get A from the stack
```

This technique avoids temporary storage by "extracting A from the stack rather than requiring a special memory location," making it safer for NMI usage. It costs "5 additional bytes and 8 additional cycles" compared to the basic method.

### Preserving A, X, and Y (Stack-Based)

```assembly
PHA
TXA
TSX
PHA
TYA
PHA
INX
LDA $100,X ; get A from the stack
PHA
DEX
LDA $100,X ; get X from the stack
TAX
PLA
```

This requires "7 bytes and 15 cycles longer than the previous example."

## BRK/IRQ Handler Implementation

### 6502 Approach

```assembly
PHA
TXA
TSX
PHA
INX
INX
LDA $100,X ; get the status register from the stack
AND #$10   ; mask B flag
BNE BREAK
BEQ IRQ
```

Exit sequence:

```assembly
PLA
TAX
PLA
RTI
```

### 65C02 Approach

```assembly
PHX
TSX
PHA
INX
INX
LDA $100,X ; get the status register from the stack
AND #$10   ; mask B flag
BNE BREAK
BEQ IRQ
```

Exit sequence:

```assembly
PLA
PLX
RTI
```

The 65C02 version uses "1 fewer byte and 2 fewer cycles" in both entry and exit sequences.

## Understanding the B Flag

A critical point: the B (Break) flag distinction between BRK and IRQ cannot be determined from the processor status register within the handler itself.

**Incorrect approach:**

```assembly
PHA
PHP
PLA
AND #$10  ; mask B flag
BNE BREAK
BEQ IRQ
```

This "does NOT properly distinguish a BRK from an IRQ."

**Why:** When a BRK executes, the pushed status register is ORed with $10. When an IRQ occurs, the pushed value is ANDed with $EF. The handler must examine the stack-resident copy of the status register, not the current register state.

---

**Last page update: November 11, 2006**
