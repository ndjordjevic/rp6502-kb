---
type: inbox
tags: [ingest-plan, 6502, 65c02, assembly, wagner, apple-ii]
created: 2026-04-17
updated: 2026-04-17
---

# Ingest Plan — Assembly Lines: The Complete Book (Roger Wagner, ed. Chris Torrence, 2014)

**Source file**: `raw/pdfs/Assembly Lines Complete Rodger Wagner 2014.pdf` (10.6 MB, 454 pages)
**Role in wiki**: The modern (2014) friendly pedagogical introduction. Collected from *Softalk* magazine (1980–1983) plus the 1982 book, with a 2014 re-edit by Chris Torrence. Apple II–focused, but the first ~10 chapters are the clearest beginner 6502 teaching we have. Chapter 33 covers the 65C02 transition.

**Guiding principle**: This is the **teaching scaffold** book. Use chapters 1–10 and 15 and 33 to extract beginner-friendly framings and idioms. Apple-specific hardware chapters (DOS, Applesoft BASIC, hi-res graphics) do not transfer to the RP6502 and are skipped.

---

## Chapter plan

### HIGH value — pedagogical foundation

- [ ] **Ch 1 — Apple's Architecture** (pp. 1–7) — *skim*. Light intro; take only the framing of "6502 Operation" for use in a new `[[learning-6502-assembly]]` page.
- [ ] **Ch 2 — The Monitor** (pp. 9–11) — *skip*; Apple-specific Monitor ROM.
- [ ] **Ch 3 — Assemblers** (pp. 13–19) — *skim*; mini-assembler is Apple-specific, but the load/store intro is useful framing.
- [ ] **Ch 4 — Loops and Counters** (pp. 21–25) — **HIGH**. Binary numbers, status register intro, INC/DEC, BNE looping. Cleanest intro to the status register anywhere. → `[[learning-6502-assembly]]` + link from [[65c02-instruction-set]].
- [ ] **Ch 5 — Loops, Branches, COUT, and Paddles** (pp. 27–35) — **MEDIUM**. Branch offsets and reverse branches are transferable; COUT/paddle I/O is Apple-specific, skip.
- [ ] **Ch 6 — I/O Using Monitor and Keyboards** (pp. 37–43) — *skip mostly*; Apple Monitor-specific. Extract only the compare/carry-flag explanation.
- [ ] **Ch 7 — Addressing Modes** (pp. 45–51) — **HIGH**. Indexed addressing, when X and Y aren't interchangeable — good pedagogy. Add to [[65c02-addressing-modes]] as "When to use which mode" sidebar.
- [ ] **Ch 8 — Sound Generation** (pp. 53–59) — *skip*; Apple speaker-specific. RP6502 uses [[opl2-fm-synth]] / [[programmable-sound-generator]].
- [ ] **Ch 9 — The Stack** (pp. 61–63) — **HIGH**. Short and excellent stack intro + stack limit. → new concept page `[[6502-stack-and-subroutines]]` (alongside the Leventhal subroutine-conventions page).
- [ ] **Ch 10 — Addition and Subtraction** (pp. 65–75) — **HIGH**. Binary arithmetic, ADC, signed numbers, sign flag. → augments `[[6502-programming-idioms]]`.

### MEDIUM — advanced but transferable

- [ ] **Ch 12 — Shift Operators and Logical Operators** (pp. 89–103) — **HIGH**. Shift, logical, BIT, ORA, EOR. Clean idiom coverage. → augments `[[6502-programming-idioms]]`.
- [ ] **Ch 15 — Special Programming Techniques** (pp. 127–141) — **HIGH**. Relocatable vs non-relocatable code, JMP, JSR simulations, self-modifying code, indirect jumps. Very relevant when writing RP6502 ROMs. → new concept page `[[6502-relocatable-and-self-modifying]]`.
- [ ] **Ch 28 — BCD (Binary Coded Decimal)** (pp. 271–280) — **MEDIUM**. Short, complements Zaks Ch III. Fold into `[[6502-programming-idioms]]` (BCD section).
- [ ] **Ch 33 — The 65C02** (pp. 327–337) — **HIGH**. Friendliest overview of 65C02 vs NMOS 6502. Cross-check with [[65c02-instruction-set]] (already from datasheet) and reconcile any pedagogical framings.

### SKIP — Apple II specific, not transferable

- [ ] **Ch 11 — DOS and Disk Access** — Apple DOS 3.3.
- [ ] **Ch 13 — I/O Routines** — Apple Monitor print/input.
- [ ] **Ch 14 — Reading and Writing Files on Disk** — Apple DOS.
- [ ] **Ch 16–17 — Applesoft Data Passing** — Applesoft BASIC interop.
- [ ] **Ch 18–25 — Hi-Res Graphics & Animation** — Apple II hi-res hardware; RP6502 VGA is entirely different.
- [ ] **Ch 26–27 — Floating-Point Math / Applesoft FAC** — Applesoft-specific.
- [ ] **Ch 29–30 — Intercepting Output / Input** — Apple I/O vectors (KSW/CSW).
- [ ] **Ch 31–32 — Hi-Res Character Generator / Editor** — Apple hi-res.
- [ ] **Appendices A–B** — Contest, assembly commands (redundant).
- [ ] **Appendix C — 6502 Instruction Set** — redundant with [[65c02-instruction-set]].
- [ ] **Appendices D–G** — Apple-specific (Monitor subroutines, text-screen map, hi-res memory map, Merlin assembler guide).

---

## Expected wiki output

**New concept pages:**
- `wiki/concepts/learning-6502-assembly.md` — beginner-friendly intro: registers, status flags, loops, branches. Scaffold that links to all deeper pages.
- `wiki/concepts/6502-stack-and-subroutines.md` — stack mechanics + subroutine conventions (consolidated with the Leventhal plan's subroutine page — may merge if overlap is heavy).
- `wiki/concepts/6502-relocatable-and-self-modifying.md` — relocatable code, JSR simulation, self-modifying code, indirect jumps. Relevant for RP6502 ROM loading.

**Pages augmented:**
- `[[65c02-addressing-modes]]` — "When X vs Y" pedagogical sidebar from Ch 7.
- `[[65c02-instruction-set]]` — reconcile Wagner's friendly Ch 33 framing with datasheet.
- `[[6502-programming-idioms]]` (from Zaks) — Wagner Ch 10, 12, 28 additions.

**Source page:**
- `wiki/sources/wagner-assembly-lines.md` — summary + Scope section. Note the Apple II origin and why most later chapters are skipped.

---

## Cross-book coordination

These three ingest plans share output pages. Suggested order:

1. **Zaks Ch III, VIII, IX** first — establishes `6502-programming-idioms`, `6502-application-snippets`, `6502-data-structures`.
2. **Wagner Ch 1–10** — creates `learning-6502-assembly` scaffold and cross-links to the Zaks pages.
3. **Leventhal Ch 17, 12, 10** — adds 65C02 specifics, interrupt patterns, formal subroutine conventions.
4. **Wagner Ch 15, 33; Leventhal Ch 6–9** — fill in remaining patterns and idioms.

This avoids repeatedly re-opening the same output page.
