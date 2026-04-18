---
type: source
tags: [6502, 65c02, assembly, leventhal, programming, reference]
related: [[w65c02s]], [[65c02-instruction-set]], [[65c02-addressing-modes]], [[6502-interrupt-patterns]], [[6502-subroutine-conventions]], [[6502-application-snippets]], [[6502-programming-idioms]], [[6502-data-structures]]
sources: []
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Assembly Language Programming, 2nd Ed — Lance Leventhal (1986)

**Summary**: The definitive 6502 assembly reference, updated for the 65C02. Chapter 17 adds complete coverage of the W65C02S enhancements directly relevant to RP6502 programming. Strong on I/O patterns, interrupt service routines, subroutine conventions, and worked examples with full object code listings.

---

## Key facts

- **Author**: Lance A. Leventhal
- **Publisher**: Osborne/McGraw-Hill, Berkeley CA
- **Edition**: Second (1st ed. 1979; 2nd ed. 1986)
- **Pages**: ~670 pp
- **ISBN**: 0-07-881216-X
- **File**: `raw/pdfs/6502 Assembly Language Programming (2nd Edition) Lance Leventhal 1986.pdf` (23 MB)

### Why the 2nd edition matters

The primary new content vs. the 1st edition is **Chapter 17 — 65C02 Programming**, which documents every software enhancement of the 65C02 over the NMOS 6502: new indirect addressing mode for arithmetic/logic instructions, `JMP (a,x)` for jump tables, the bit-manipulation family (SMB/RMB/BBR/BBS), plus minor enhancements (BRA, PHX/PHY/PLX/PLY, STZ, INC A/DEC A, TRB/TSB). The RP6502 uses the **W65C02S**, so this chapter is directly applicable.

### Structure

The book is in 3 sections:
- **Foundation** (Ch 1–3): assembly language, assemblers, 6502 instruction set
- **Worked examples** (Ch 4–11): programs organized by task type — simple programs, loops, character/string, code conversion, arithmetic, tables, I/O
- **Systems programming** (Ch 12–17): interrupts, subroutines, I/O, design methodology, debugging, and the 65C02 chapter

---

## Scope

All chapters in the book, with ingestion status:

| Chapter | Title | Status |
|---------|-------|--------|
| Ch 1 | Introduction to Assembly Language Programming | [-] skipped — general overview |
| Ch 2 | Assemblers | [-] skipped — 1986-era macro-assembler material; cc65/ca65 is the reference |
| Ch 3 | 6502 Instruction Set | [-] skipped — covered by [[65c02-instruction-set]] from datasheet |
| Ch 4 | Simple Programs | [-] skipped — baseline exercises, redundant with Assembly Lines |
| Ch 5 | Simple Program Loops | [-] skipped — covered by Assembly Lines Ch 4–5 |
| Ch 6 | Character-Coded Data | [x] ingested → [[6502-application-snippets]] |
| Ch 7 | Code Conversion | [x] ingested → [[6502-application-snippets]] |
| Ch 8 | Arithmetic Problems | [x] ingested → [[6502-programming-idioms]] |
| Ch 9 | Tables and Lists | [x] ingested → [[6502-data-structures]] |
| Ch 10 | Subroutines | [x] ingested → [[6502-subroutine-conventions]] |
| Ch 11 | Input/Output | [-] skipped — uses 6520 PIA/6522 VIA/6850 ACIA hardware not in RP6502; generic I/O scheduling patterns captured in [[6502-interrupt-patterns]] |
| Ch 12 | Interrupts | [x] ingested → [[6502-interrupt-patterns]] |
| Ch 13 | Problem Definition and Program Design | [-] skipped — dated software-engineering methodology |
| Ch 14 | Debugging and Testing | [-] skipped — ditto |
| Ch 15 | Documentation and Redesign | [-] skipped — ditto |
| Ch 16 | Sample Projects | [-] skipped — digital stopwatch/thermometer using PIA/VIA, not transferable |
| Ch 17 | 65C02 Programming | [x] ingested → [[65c02-instruction-set]] (augmented) |

---

## Key takeaways

### 65C02 enhancements (Ch 17)
- **True indirect addressing** for all arithmetic/logical/transfer instructions: `AND ($40)`, `LDA ($40)` etc. Zero-page pair acts as a 16-bit address register. Solves the lack of 16-bit address registers on the 6502.
- **`JMP (a,x)`** — indexed absolute indirect. Enables clean jump tables without zero-page indirection: `ASL A / TAX / JMP (JTBL,X)`.
- **Bit manipulation**: `SMB0–SMB7` / `RMB0–RMB7` set/clear individual zero-page bits. `BBS0–BBS7` / `BBR0–BBR7` branch on bit state. Powerful for flag bytes and port-bit control.
- **`BRA`** — unconditional relative branch. Eliminates the common `BNE * / JMP` workaround for short backward jumps.
- **`PHX` / `PHY` / `PLX` / `PLY`** — push/pull X and Y without routing through A. Saves 2 instructions per register preserved.
- **`STZ`** — store zero directly. Replaces `LDA #0 / STA addr`.
- **`INC A` / `DEC A`** — accumulator increment/decrement. Replaces `CLC / ADC #1` / `SEC / SBC #1`.
- **`TRB` / `TSB`** — test-and-reset/test-and-set bits. Read-modify-write via accumulator mask; Z flag = original AND result.
- **Decimal mode fix**: N, V, Z flags are now valid after BCD arithmetic (NMOS: undefined).
- **JMP indirect page-boundary bug fixed**: `JMP ($xxFF)` now works correctly.

### Interrupt system (Ch 12)
- IRQ/NMI/RESET response saves PC (MSB first) then P on stack, then loads vector from `FFFE/FFFF`, `FFFA/FFFB`, `FFFC/FFFD` respectively.
- `BRK` produces the same stack push as IRQ but sets P.B=1 in the saved copy. Distinguish BRK from IRQ by `PLA / AND #$10 / BNE BREAK`.
- ISR golden rule: **save all registers before modifying them; restore before RTI**.
- Save sequence: `PHA / TXA / PHA / TYA / PHA`; restore sequence: `PLA / TAY / PLA / TAX / PLA`.
- RTI restores P automatically, re-enabling interrupts if I was 0 before.
- Polling priority: first device polled has highest priority. VIA bit-7 of IFR = any interrupt active and enabled.

### Subroutine conventions (Ch 10)
- JSR saves the address of the *last byte* of JSR on the stack. RTS reads it back and adds 1.
- Three parameter-passing methods: registers, zero-page pseudo-registers (ZP address pairs), stack.
- Reentrancy requires using only registers and stack — no fixed memory locations for temps.
- Relocatability requires using only relative branch addresses — no absolute `JMP`.
- Always document: purpose, in/out parameters, registers used, sample case.

### String and code idioms (Ch 6–7)
- String length: scan with `INX / CMP #$0D / BNE` loop until carriage return (`$0D`).
- Hex-to-ASCII: `CMP #10 / BCC / ADC #'A-'9-2 / ADC #'0` — bridges the ASCII gap between '9' and 'A'.
- BCD-to-7-segment: table lookup via `LDA SSEG,X`.
- Decimal mode: `SED` before BCD arithmetic, `CLD` immediately after.

### Arithmetic (Ch 8)
- Multi-precision binary addition: `CLC` once before loop; `ADC` propagates carry between bytes (MSB-first, iterate with DEX/BNE).
- Multi-precision BCD addition: same loop wrapped in `SED`/`CLD`.
- 8-bit multiply: shift-and-add (8 iterations, `ASL/ROL/BCC`). ~250 clock cycles typical.
- 8-bit divide: shift-and-subtract (8 iterations). Quotient and remainder both 8-bit.

### Tables and lists (Ch 9)
- Jump table (pre-65C02 style): `ASL A / TAX / LDA JTBL,X / STA $40 / LDA JTBL+1,X / STA $41 / JMP ($40)`. With 65C02: `JMP (JTBL,X)` — 3 instructions instead of 7.
- Bubble sort: clear INTER flag, scan pairs, swap out-of-order elements via stack (`PHA`/load/store/`PLA`/store), set INTER; repeat until INTER stays clear.
- List search: compare with `CMP $42,X / BEQ found / DEX / BNE loop`.

---

## Related pages

- [[w65c02s]] · [[65c02-instruction-set]] · [[65c02-addressing-modes]]
- [[6502-interrupt-patterns]] · [[6502-subroutine-conventions]]
- [[6502-application-snippets]] · [[6502-programming-idioms]] · [[6502-data-structures]]
- [[rp6502-abi]] · [[hardware-irq]]
