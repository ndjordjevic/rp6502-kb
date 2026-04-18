---
type: inbox
tags: [ingest-plan, 6502, assembly, zaks]
created: 2026-04-17
updated: 2026-04-17
---

# Ingest Plan — Programming the 6502 (Rodnay Zaks, 4th Ed 1983)

**Source file**: `raw/pdfs/Programming the 6502 Rodnay Zaks 1983.pdf` (70.6 MB, 420 pages)
**Role in wiki**: The classic systematic textbook. Strong on fundamentals, BCD, data structures. 4th edition includes answers to exercises.

**Guiding principle**: The wiki already has [[65c02-instruction-set]] + [[65c02-addressing-modes]] from the W65C02S datasheet. These books contribute **pedagogy, idioms, and programming patterns** — not the instruction reference. Skip what we already have; focus on transferable techniques for cc65/llvm-mos programmers targeting the RP6502.

---

## Chapter plan

Order: start with high-value chapters (3, 8, 9) since they are the most transferable. Defer Ch 2/4/5 where the W65C02S datasheet already covers the ground.

- [ ] **Ch I — Basic Concepts** (pp. 7–37) — *skip*; covers binary, hex, flowcharting — assumed background.
- [ ] **Ch II — 6502 Hardware Organization** (pp. 38–52) — *skim for history*; compare to [[w65c02s]] datasheet. Extract only: NMOS vs CMOS distinction, stack/paging concept framing.
- [ ] **Ch III — Basic Programming Techniques** (pp. 53–98) — **HIGH**. Arithmetic, BCD, logical ops, subroutine conventions. → new concept page `[[6502-programming-idioms]]`.
- [ ] **Ch IV — 6502 Instruction Set** (pp. 99–187) — *skip*; already covered in [[65c02-instruction-set]] from datasheet.
- [ ] **Ch V — Addressing Techniques** (pp. 188–210) — *skim*; already covered in [[65c02-addressing-modes]]. Extract only: worked examples showing when to pick each mode → add to an "addressing patterns" section.
- [ ] **Ch VI — Input/Output Techniques** (pp. 211–253) — **MEDIUM**. Generic polled vs interrupt-driven I/O patterns. Cross-link to [[hardware-irq]]. Skip PIA-specific detail.
- [ ] **Ch VII — Input/Output Devices** (pp. 254–261) — *skip*; covers 6520/6522/6530/6532 which the RP6502 does not use (RIA handles I/O differently).
- [ ] **Ch VIII — Application Examples** (pp. 262–274) — **HIGH**. Memory clear, polling, character I/O, ASCII↔BCD, find-max, sum, checksum, zero count, string search. → new concept page `[[6502-application-snippets]]`.
- [ ] **Ch IX — Data Structures** (pp. 275–342) — **HIGH**. Pointers, lists, trees, sorting, hashing, bubble-sort, merge. → new concept page `[[6502-data-structures]]`.
- [ ] **Ch X — Program Development** (pp. 343–367) — *skim*; assembler/macro/conditional-assembly concepts. Extract only if it complements [[cc65]]/[[llvm-mos]] workflow.
- [ ] **Ch XI — Conclusion** (pp. 368–370) — *skip*.
- [ ] **Appendix I — Answers to Exercises** — *skip*; value is in exercises, not solutions.

---

## Expected wiki output

**New concept pages:**
- `wiki/concepts/6502-programming-idioms.md` — BCD arithmetic, carry/overflow patterns, subroutine argument passing, self-test routines
- `wiki/concepts/6502-application-snippets.md` — common small algorithms (memory clear, checksum, search, max/min)
- `wiki/concepts/6502-data-structures.md` — lists, queues, trees, sort/search on 6502

**Updates to existing pages:**
- `[[hardware-irq]]` — cross-link generic polled-vs-interrupt framing
- `[[65c02-addressing-modes]]` — optionally add a "when to use which mode" section

**Source page:**
- `wiki/sources/zaks-programming-6502.md` — summary + Scope section tracking which chapters were ingested.
