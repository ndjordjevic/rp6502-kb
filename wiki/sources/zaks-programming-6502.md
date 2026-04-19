---
type: source
tags: [6502, assembly, programming, textbook, bcd, data-structures, subroutines, io, hashing, sorting, merging]
related:
  - "[[65c02-instruction-set]]"
  - "[[65c02-addressing-modes]]"
  - "[[6502-programming-idioms]]"
  - "[[6502-application-snippets]]"
  - "[[6502-data-structures]]"
  - "[[6502-interrupt-patterns]]"
  - "[[6502-subroutine-conventions]]"
created: 2026-04-18
updated: 2026-04-18
---

# Zaks — Programming the 6502 (4th Ed, 1983)

**Summary**: Classic 4th-edition textbook by Rodnay Zaks covering 6502 programming from first principles through advanced data structures. Distinguished from Leventhal (subroutine library focus) and Wagner (Apple-oriented tutorial) by its strong emphasis on data structure theory, algorithm design, and formal programming methodology.

---

## Key facts

- **Full title**: *Programming the 6502*, 4th Edition
- **Author**: Rodnay Zaks, Sybex, 1983
- **Pages**: ~420, including Appendix (instruction tables and answers to exercises)
- **Audience**: Beginner to intermediate; structured "learn by doing" approach with flowcharts for every algorithm
- **Role in wiki**: Theoretical scaffold for data structures, algorithm design methodology, and I/O scheduling. Complements [[leventhal-6502-assembly]] (subroutine patterns) and [[wagner-assembly-lines]] (beginner teaching).
- **PDF quality**: Good — pdftotext readable with minor OCR artefacts; mostly clean prose and code listings

---

## Unique contributions vs. other books in the wiki

| Topic | Zaks contribution | Prior coverage |
|-------|-------------------|----------------|
| Multiply algorithm | Improved 8×8 using accumulator as partial product (halves code size) | Leventhal has standard shift-and-add |
| Subroutine parameters | Explicit 3-method comparison (registers/memory/stack) + pointer hybrid | Leventhal covers stack convention in detail |
| Polling vs. interrupts | Clean conceptual framing + save/restore overhead analysis | Leventhal/VIA has patterns; Zaks adds methodology |
| Linked lists | Full theory + 6502 insertion/deletion code patterns | Only mentioned in prior wiki pages |
| Binary search | Algorithmic complexity + 6502 implementation of log₂N search | Leventhal has table lookup; Zaks adds sorted-table binary search |
| Hashing | XOR+rotate hash function + 80% fullness rule + collision resolution | Not previously covered |
| Merge | Two-sorted-table merge algorithm + 6502 code | Not previously covered |
| Circular list / tree | Theory + 6502 application guidance | Not previously covered |
| BCD mode | BCD to binary conversion hint (N3N2N1N0 via repeated ×10) | Wagner covers BCD fundamentals; Zaks adds conversion |
| ASCII bracket test | V+C flag encoding for range results (no explicit branch on return) | Not previously covered |

---

## Key technical facts

- **8-bit addition pattern**: `CLC` before every `ADC` for safety; `CLD` before binary arithmetic to guarantee D=0.
- **16-bit addition**: `CLC` + `LDA LSB / ADC LSB / STA / LDA MSB / ADC MSB / STA` — carry propagates naturally.
- **16-bit subtraction**: `SEC` instead of `CLC`; use `SBC` pairs (carry = not-borrow).
- **BCD add/subtract**: `SED` + `CLC` (add) or `SED` + `SEC` (subtract); 6502 ADC/SBC handles decimal adjust automatically.
- **Improved multiply**: 10 instructions vs. ~18 for naive; accumulator holds partial product high; B (ZP) holds low; C holds multiplier; D holds multiplicand.
- **JSR is 3-byte instruction** → return address on stack = PC of byte following JSR's last byte.
- **Stack can accommodate ~128 nested subroutine calls** if no registers saved and no interrupts — practical limit is much lower.
- **Paging**: page 0 = ZP ($0000–$00FF); page 1 = stack ($0100–$01FF); all other pages are free.
- **Branch timing**: 2 cycles (not taken) / 3 cycles (taken, same page) / 4 cycles (taken, crosses page boundary).
- **BCC/BCS after CMP**: carry SET when A ≥ operand; CLEAR when A < operand.
- **Hash table fullness**: ≤ 80% for ~3 average accesses; degrades rapidly above 80%.
- **Merge precondition**: both source tables must be pre-sorted; output is sorted union.
- **Recursion**: legal because JSR pushes return address onto stack (fresh frame per call); risky only if working data is in fixed memory (breaks if subroutine calls itself).

---

## Scope

| Chapter | Pages | Status | Notes |
|---------|-------|--------|-------|
| Ch I — Basic Concepts | 7–37 | `[-] skipped` | Binary, hex, flowcharts — assumed background |
| Ch II — 6502 Hardware Organization | 38–52 | `[x] ingested` | Stack/paging concept, register overview, bus architecture |
| Ch III — Basic Programming Techniques | 53–98 | `[x] ingested` | Arithmetic, BCD, multiply, divide, logical ops, subroutines, parameter passing |
| Ch IV — 6502 Instruction Set | 99–187 | `[-] skipped` | Already covered by [[65c02-instruction-set]] from W65C02S datasheet |
| Ch V — Addressing Techniques | 188–210 | `[x] ingested` | Full mode taxonomy (implicit/immediate/absolute/direct/relative/indexed/indirect/combinations); pre- vs. post-indexing framing |
| Ch VI — Input/Output Techniques | 211–253 | `[x] ingested` | Signal generation, delay loops, polling vs. interrupts, IRQ/NMI/RTI, register save/restore overhead |
| Ch VII — Input/Output Devices | 254–261 | `[-] skipped` | Covers 6520/6522/6530/6532 — not used in RP6502 (RIA handles I/O) |
| Ch VIII — Application Examples | 262–274 | `[x] ingested` | Memory clear, polling, character input, bracket test, parity, ASCII/BCD, max, sum, checksum, zero count, string search |
| Ch IX — Data Structures | 275–342 | `[x] ingested` | Pointers, directories, sequential/linked/circular lists, queue, stack, trees, doubly-linked, binary search, hashing, bubble sort, merge |
| Ch X — Program Development | 343–367 | `[-] skipped` | Assembler/macro concepts — covered better by cc65/llvm-mos workflow |
| Ch XI — Conclusion | 368–370 | `[-] skipped` | Summary only |
| Appendix — Answers to exercises | — | `[-] skipped` | Exercises, not reference content |

---

## Related pages

- [[6502-programming-idioms]] — augmented with improved multiply and subroutine parameter methods
- [[6502-application-snippets]] — augmented with memory clear, bracket test, parity, ASCII/BCD, max, sum, checksum, zero count
- [[6502-data-structures]] — augmented with linked lists, circular lists, trees, doubly-linked lists, binary search, hashing, merge
- [[6502-interrupt-patterns]] — Zaks Ch VI polling/interrupt framing cross-references
- [[65c02-addressing-modes]] — Zaks Ch V provides complementary mode taxonomy
