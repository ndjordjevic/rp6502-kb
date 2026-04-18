---
type: source
tags: [6502, 65c02, assembly, beginner, pedagogy, bcd, relocatable, apple-ii, wagner]
related: [[learning-6502-assembly]], [[6502-stack-and-subroutines]], [[6502-programming-idioms]], [[65c02-addressing-modes]], [[65c02-instruction-set]], [[6502-relocatable-and-self-modifying]]
created: 2026-04-18
updated: 2026-04-18
---

# Source: Assembly Lines — The Complete Book (Roger Wagner, ed. Chris Torrence, 2014)

**Summary**: The friendliest pedagogical introduction to 6502 assembly language, originally collected from *Softalk* magazine (1980–1983) and the 1982 book, re-edited in 2014 by Chris Torrence. Apple II–focused hardware chapters aside, the first ~10 chapters and chapters 15, 28, 33 provide the clearest beginner-to-intermediate 6502 teaching in the wiki.

---

## File

`raw/pdfs/Assembly Lines Complete Rodger Wagner 2014.pdf` — 454 pages, 10.6 MB.  
Author: Roger Wagner. Editor: Chris Torrence (2014 edition).  
License: Creative Commons Attribution-NonCommercial-ShareAlike 2.0.

---

## Role in the wiki

This is the **teaching scaffold** book. Use it to understand the *why* behind 6502 patterns. Leventhal (1986) and Zaks (1983) are reference books; Wagner explains things step by step with motivation and worked examples.

- First ~10 chapters: beginner foundations (registers, binary, loops, stack, arithmetic)
- Ch 15: relocatable code patterns — practical for RP6502 ROM development
- Ch 28: BCD mode — complements the Leventhal multi-precision treatment
- Ch 33: 65C02 upgrade overview — friendly framing to accompany the WDC datasheet

Apple-specific hardware chapters (Monitor, DOS, hi-res graphics, Applesoft BASIC interop) are skipped as they do not transfer to the RP6502 platform.

---

## Key facts

- **Binary numbers**: each byte is 8 bits; values 0–255 ($00–$FF); choice of hex notation is practical, not arbitrary
- **Four registers**: A (Accumulator), X, Y (Index), P (Status) — each 8 bits; plus 16-bit PC and 8-bit SP
- **Status Register flags**: N (bit 7), V (bit 6), D (BCD mode), I (IRQ disable), Z (zero), C (carry)
- **Zero flag**: Z=1 means result IS zero — set by LDA/LDX/LDY/ADC/SBC/INC/DEC etc.
- **BNE/BEQ loop pattern**: load counter; DEC/DEX/DEY in body; BNE loops back while nonzero; BEQ exits when zero
- **Branch offsets**: signed 8-bit (±127 bytes from next instruction); JMP for longer distances
- **Addressing mode table**: Immediate, Absolute, Zero Page, Indexed, Indirect Indexed `(zp),Y`, Indexed Indirect `(zp,X)`, Relative, Implied
- **X vs Y**: Indirect Indexed `(zp),Y` uses Y only; Indexed Indirect `(zp,X)` uses X only — **not interchangeable**
- **Stack**: LIFO; $0100–$01FF; SP auto-adjusts; PHA/PLA for manual use; JSR pushes PC−1 (not next instruction), RTS adds 1
- **Stack limit**: 256 bytes total (128 JSR frames), shared with OS/BASIC
- **PHX/PHY/PLX/PLY**: 65C02 additions — save/restore X and Y without touching A
- **ADC**: always CLC before first add; carry propagates into next ADC for multi-byte
- **SBC**: always SEC before first subtract; carry acts as inverted borrow
- **Two's complement**: negate by inverting bits then add 1; carry from high byte discarded
- **ASL**: shift left, bit 7→C, 0→bit 0; multiplies by 2 per shift
- **LSR**: shift right, bit 0→C, 0→bit 7; divides by 2 per shift
- **ROL/ROR**: rotate through carry; chain for multi-byte shifts
- **AND**: bit-and; zero specific bits (masking), test whether bits match
- **ORA**: bit-or; set specific bits to 1
- **EOR**: exclusive-or; toggle bits; applying twice restores original
- **BIT**: tests bits in memory against A without changing A; bit 7→N, bit 6→V, (A AND mem)→Z
- **BCD mode**: SED to enter, CLD to leave; ADC/SBC produce decimal-correct results; INC/DEC always binary; each nibble = one decimal digit
- **Relocatable code**: avoid absolute addresses within code block; JMP/JSR create non-relocatability
- **Forced branch**: CLV+BVC (or BRA on 65C02) replaces non-relocatable JMP; range ±127 bytes
- **Indirect JMP**: `JMP ($addr)` — pointer anywhere in memory; enables dispatch tables
- **JMP page-boundary bug**: NMOS 6502 `JMP ($xxFF)` reads from `$xx00` instead of `$(xx+1)00`; fixed on 65C02
- **65C02 — 12 new instructions**: BBR, BBS, BRA, PHX, PHY, PLX, PLY, RMB, SMB, STZ, TRB, TSB
- **STZ**: stores zero directly to memory without using Accumulator; 4 addressing modes
- **TSB**: OR memory with Accumulator, then set Z if (A AND memory) = 0 (test and set bits)
- **TRB**: clear memory bits from Accumulator, set Z if (A AND memory) = 0 (test and reset bits)
- **BIT on 65C02**: adds Immediate, Absolute,X, Zero Page,X modes
- **65C02 BCD**: N, V, Z flags fully valid after BCD ADC/SBC (NMOS: N and V undefined)
- **65C02 compatibility**: pin-compatible replacement; most software runs unchanged; undocumented opcode users may have problems

---

## Scope

| Chapter | Title | Pages | Status | Wiki output |
|---------|-------|-------|--------|-------------|
| 1 | Apple's Architecture | 1–7 | [x] ingested | [[learning-6502-assembly]] |
| 2 | The Monitor | 9–11 | [-] skipped — Apple Monitor ROM specific | — |
| 3 | Assemblers | 13–19 | [x] ingested (load/store framing only) | [[learning-6502-assembly]] |
| 4 | Loops and Counters | 21–25 | [x] ingested | [[learning-6502-assembly]] |
| 5 | Loops, Branches, COUT, Paddles | 27–35 | [x] ingested (branches + JMP; skipped COUT/paddle) | [[learning-6502-assembly]] |
| 6 | I/O Using Monitor and Keyboards | 37–43 | [-] skipped — Apple Monitor specific | — |
| 7 | Addressing Modes | 45–51 | [x] ingested | [[65c02-addressing-modes]] |
| 8 | Sound Generation | 53–59 | [-] skipped — Apple speaker hardware | — |
| 9 | The Stack | 61–63 | [x] ingested | [[6502-stack-and-subroutines]] |
| 10 | Addition and Subtraction | 65–75 | [x] ingested | [[6502-programming-idioms]] (ADC/SBC basics in carry-chain rules + multi-byte) |
| 11 | DOS and Disk Access | 77–87 | [-] skipped — Apple DOS 3.3 | — |
| 12 | Shift Operators and Logical Operators | 89–103 | [x] ingested | [[6502-programming-idioms]] |
| 13 | I/O Routines | 105–113 | [-] skipped — Apple Monitor print/input | — |
| 14 | Reading and Writing Files on Disk | 115–125 | [-] skipped — Apple DOS | — |
| 15 | Special Programming Techniques | 127–141 | [x] ingested | [[6502-relocatable-and-self-modifying]] |
| 16–17 | Applesoft Data Passing | 143–167 | [-] skipped — Applesoft BASIC interop | — |
| 18–25 | Hi-Res Graphics & Animation | 169–261 | [-] skipped — Apple hi-res hardware | — |
| 26–27 | Floating-Point Math / Applesoft FAC | 263–287 | [-] skipped — Applesoft specific | — |
| 28 | BCD (Binary Coded Decimal) | 271–280 | [x] ingested | [[6502-programming-idioms]] |
| 29–30 | Intercepting Output / Input | 289–313 | [-] skipped — Apple I/O vectors | — |
| 31–32 | Hi-Res Character Generator / Editor | 315–325 | [-] skipped — Apple hi-res | — |
| 33 | The 65C02 | 327–337 | [x] ingested | [[65c02-instruction-set]], [[65c02-addressing-modes]] |
| Appendices A–G | Various | — | [-] skipped — contest, Apple-specific | — |

---

## PDF quality note

The PDF is a scan with OCR artifacts. Words are frequently broken with spurious spaces and some characters are substituted (e.g., "⇢" for "Th", "Sag" for "flag", "Le ct" for "affect"). The content is fully readable with attention, but exact quotes from the text will require cleanup.

---

## Related pages

- [[learning-6502-assembly]] — PRIMARY output: beginner 6502 scaffold (Ch 1, 3, 4, 5)
- [[6502-stack-and-subroutines]] — stack mechanics and PHA/PLA (Ch 9)
- [[65c02-addressing-modes]] — X vs Y sidebar (Ch 7)
- [[6502-programming-idioms]] — shift/logical operators + BCD fundamentals (Ch 10, 12, 28)
- [[6502-relocatable-and-self-modifying]] — relocatable patterns, indirect JMP (Ch 15)
- [[65c02-instruction-set]] — 65C02 new instructions reconciled (Ch 33)
