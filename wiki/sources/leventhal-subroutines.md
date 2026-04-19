---
type: source
tags: [6502, assembly, subroutines, leventhal, 1982, reference]
related:
  - "[[6502-emulated-instructions]]"
  - "[[6502-common-errors]]"
  - "[[6502-subroutine-conventions]]"
  - "[[6502-programming-idioms]]"
  - "[[6502-interrupt-patterns]]"
  - "[[6502-application-snippets]]"
  - "[[6502-data-structures]]"
  - "[[6522-via]]"
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Assembly Language Subroutines (Leventhal & Saville, 1982)

**Summary**: A companion reference and subroutine library for 6502 assembly programmers. Where the 1986 book teaches the language, this 1982 book provides a tutorial for experienced programmers (Chapters 1–3) plus a standardised library of ready-to-use subroutines (Chapters 4–11). Unique content: emulating missing instructions, a systematic error catalogue, and subroutines documented with cycle counts and memory requirements.

---

## Bibliographic details

- **Title**: 6502 Assembly Language Subroutines
- **Authors**: Lance Leventhal, Winthrop Saville
- **Publisher**: Osborne/McGraw-Hill
- **Year**: 1982
- **Pages**: ~545 (plus appendices)
- **File**: `raw/pdfs/6502 Assembly Language Subroutines Lance Leventhal 1982.pdf`

---

## Key facts

- Companion to Leventhal's *6502 Assembly Language Programming* (1986). The 1986 book is the tutorial; this 1982 book is the reference + subroutine library.
- **Chapters 1–3** are tutorial/reference for experienced programmers — the most wiki-relevant content.
- **Chapters 4–11** are a standardised subroutine library (8 categories, ~60 routines). Each routine has a 10-field documentation header including cycle count, byte count, and entry/exit conditions.
- **Appendix B** is a 6522 VIA programming reference (registers: Port A/B, DDR, PCR, IER, IFR, ACR, T1/T2 timers, shift register) — directly relevant to RP6502 hardware.
- OCR quality: prose sections clean; assembly listing tables often garbled — capture algorithms and idioms only, not listings.

---

## Key takeaways

### Chapter 1 — General Programming Methods
- The "Quick Summary for Experienced Programmers" enumerates 14 6502 quirks concisely (now in [[6502-programming-idioms]]): inverted carry-borrow, CLC/SEC mandatory, no 16-bit registers, stack page-1 only, JSR off-by-one, decimal flag not reset on power-up, stores don't set flags, no INC/DEC A, 8-bit index registers, BIT flag side effects, missing instructions, byte order, etc.
- Parameter passing: Ch. 1 formalises four methods — registers, ZP pseudo-registers, inline (after JSR), and stack. Inline method is unique to this book.
- 16-bit counter patterns, multi-dimensional array access, list/queue patterns, I/O device tables, VIA peripheral control — all covered with example sequences.

### Chapter 2 — Implementing Additional Instructions and Addressing Modes
- Comprehensive catalogue of instruction emulations: arithmetic (add/sub with/without carry, decimal, 16-bit), shifts (ASR, 16-bit LSL/LSR), branch extensions (signed comparisons, extended range), indirect/indexed addressing emulation, block move, exchange, save/restore patterns.
- Now captured in [[6502-emulated-instructions]].

### Chapter 3 — Common Programming Errors
- Systematic error guide organised by category: Carry misuse (SBC/CMP/ADC), flag side effects (BIT, STA, INC, Overflow), addressing mode confusion (immediate vs. direct, `$xxFF` JMP bug), format errors (hex notation, ASCII↔BCD conversion), array off-by-one, initialisation errors (decimal flag, Carry), I/O driver errors, ISR errors.
- Now captured in [[6502-common-errors]].

### Introduction to Program Section (between Ch. 3 and Ch. 4)
- Defines the 10-field subroutine documentation standard used throughout the library.
- Defines three parameter-passing conventions used by all subroutines: (1) 8-bit in A, second in Y; (2) 16-bit in A (MSB) + Y (LSB), accompanying 8-bit in X; (3) larger parameter sets via stack.
- Error convention: Carry = 1 on error/exception; Carry = 0 on success.
- Philosophy: trivial inputs (empty array, zero-length string) cause immediate exits with minimal side effects.
- Now captured in [[6502-subroutine-conventions]].

---

## Scope

| Chapter | Title | Pages | Status |
|---------|-------|-------|--------|
| 1 | General Programming Methods | 1–72 | [x] ingested — [[6502-programming-idioms]] (14 quirks), [[6502-subroutine-conventions]] (inline params) |
| 2 | Implementing Additional Instructions and Addressing Modes | 73–132 | [x] ingested — [[6502-emulated-instructions]] (new page) |
| 3 | Common Programming Errors | 133–162 | [x] ingested — [[6502-common-errors]] (new page) |
| Intro | Introduction to Program Section | 157–162 | [x] ingested — [[6502-subroutine-conventions]] (formal template + error convention) |
| 4 | Code Conversion | 163–192 | [x] ingested — [[6502-application-snippets]] (BN2BCD, BCD2BN, BN2HEX, HEX2BN, BN2DEC, DEC2BN) |
| 5 | Array Manipulation and Indexing | 193–229 | [x] ingested — [[6502-data-structures]] (MFILL, BLKMOV, D1BYTE/D1WORD/D2BYTE/D2WORD/NDIM) |
| 6 | Arithmetic | 230–305 | [x] ingested — [[6502-programming-idioms]] (16-bit add/sub/mul/div, comparison) |
| 7 | Bit Manipulation and Shifts | 306–344 | [x] ingested — [[6502-programming-idioms]] (bit set/clear/test, BFE/BFI, multi-precision shifts) |
| 8 | String Manipulation | 345–381 | [x] ingested — [[6502-application-snippets]] (STRCMP, CONCAT, POS substring search) |
| 9 | Array Operations | 382–417 | [x] ingested — [[6502-data-structures]] (ASUM8, ASUM16, BINSCH, BUBSRT, RAMTST) |
| 10 | Input/Output | 418–463 | [x] ingested — [[6502-io-patterns]] (new concept page: RDLINE, WRLINE, GEPRTY, CKPRTY, CRC-16, IOHDLR) |
| 11 | Interrupts | 464–504 | [x] ingested — [[6502-interrupt-patterns]] (PINTIO VIA pattern, ring-buffer, real-time clock) |
| App A | 6502 Instruction Set Summary | 505–509 | [-] skipped — redundant with [[65c02-instruction-set]] |
| App B | 6522 VIA Programming Reference | 510–516 | [x] ingested — [[6522-via]] (new entity page) |
| App C | ASCII Character Set | 517–518 | [-] skipped — reference table only |
