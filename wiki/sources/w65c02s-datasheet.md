---
type: source
tags: [w65c02s, 65c02, cpu, wdc, datasheet]
related: [[w65c02s]], [[65c02-instruction-set]], [[65c02-addressing-modes]], [[memory-map]], [[reset-model]]
sources: [[w65c02s-datasheet]]
created: 2026-04-17
updated: 2026-04-17
---

# W65C02S Datasheet (WDC, Feb 2024)

**Summary**: Official Western Design Center datasheet for the W65C02S 8-bit microprocessor — the physical CPU at slot **U1** of the [[rp6502-board]]. 32 pages; dated February 16, 2024.

Raw: [w65c02s.pdf](../../raw/pdfs/w65c02s.pdf)

---

## Scope

| # | Chapter | Status |
|---|---|---|
| 1 | Introduction & Features | [x] ingested |
| 2 | Functional Description (registers) | [x] ingested |
| 3 | Pin Function Description | [x] ingested |
| 4 | Addressing Modes (16 modes) | [x] ingested |
| 5 | Operation Tables (instruction set, opcode matrix) | [x] ingested |
| 6 | DC, AC and Timing Characteristics | [x] ingested |
| 7 | Caveats (NMOS 6502 vs W65C02S differences) | [x] ingested |
| 8 | Hard Core Model | [-] skipped — ASIC IP, not relevant to RP6502 |
| 9 | Soft Core RTL Model | [-] skipped — ASIC IP, not relevant to RP6502 |
| 10 | Ordering Information | [x] ingested |

---

## Key facts

- **8-bit data bus**, **16-bit address bus** → 64 KiB address space.
- **70 instructions**, **16 addressing modes**, **212 opcodes**.
- Registers: A (8), X (8), Y (8), S (8, stack pointer), PC (16), P (8 status: NV1BDIZC).
- **Fully static** core — PHI2 can be stopped indefinitely in either state; registers preserved.
- **Wide VDD range**: 1.8 V to 5.0 V. Max PHI2 is VDD-dependent — **14 MHz @ 5 V**, **8 MHz @ 3.3 V**, **8 MHz @ 3.0 V**, **4 MHz @ 2.5 V**, **2 MHz @ 1.8 V**.
- Low power: **150 µA @ 1 MHz**.
- Interrupt vectors (fixed): **FFFA/B = NMIB**, **FFFC/D = RESB**, **FFFE/F = BRK/IRQB**.
- Part used on RP6502: **W65C02S6TPG-14** (40-pin PDIP, TSMC 0.6 µm process, 14 MHz speed grade).

See:
- [[w65c02s]] for RP6502-specific context (PHI2 owner, memory map slot, BOM substitutions).
- [[65c02-instruction-set]] for the full instruction set and opcode matrix.
- [[65c02-addressing-modes]] for all 16 addressing modes.

## Differences from NMOS 6502 (Ch. 7 "Caveats")

The W65C02S is binary-compatible with the NMOS 6502 but adds instructions, addressing modes, and several behavioral fixes:

- **New instructions** (marked `●` in Table 5-1): BBRn/BBSn (branch on bit n reset/set), BRA, PHX/PHY/PLX/PLY, RMBn/SMBn (reset/set memory bit), STP, STZ, TRB/TSB, WAI.
- **Old instructions with new addressing modes** (marked `*`): ADC, AND, ASL, BIT, CMP, DEC, EOR, INC, JMP, LDA, ORA, SBC, STA, SBC.
- **New addressing modes**: Absolute Indexed Indirect `(a,x)` (JMP only), Zero Page Indirect `(zp)`.
- **Invalid opcodes are guaranteed NOPs** of documented byte/cycle cost (no "illegal opcode" behavior). The original NMOS 6502 terminated only by reset on some undocumented opcodes.
- **Decimal flag D is initialized to 0** on reset and interrupts (NMOS 6502 left it undefined).
- **N, V, Z flags are valid after decimal operations** (NMOS: invalid). Costs +1 cycle.
- **JMP (XXFF)** no longer has the NMOS page-wrap bug — page increments correctly (+1 cycle).
- **Read-Modify-Write** pattern is now read / read / write (was read / write / write).
- **WAI** pulls RDY low; releases on next interrupt. Reduces power and latency.
- **Invalid opcode table** (reserved as NOPs with fixed cost): `02,22,42,62,82,C2,E2` = 2B/2c; `X3,0B,1B,2B,3B,4B,5B,6B,7B,8B,9B,AB,BB,CB,DB,EB,FB` = 1B/1c; `44` = 2B/3c; `54,D4,F4` = 2B/4c; `5C` = 3B/8c; `DC,FC` = 3B/4c.

## Pin-function highlights

See [[w65c02s]]#pin-function-highlights for the full table. RP6502-relevant signals:

- **PHI2** — driven by the [[rp6502-ria]] (never by a crystal on the RP6502). PHI1O/PHI2O are not used; RIA generates PHI2 via PIO.
- **RESB** — state-held low by the RIA during reset windows; see [[reset-model]].
- **RDY** — bi-directional. WAI pulls low. Latest TSMC parts have **no internal pull-up** — the datasheet now recommends an external pull-up if RDY is used.
- **IRQB, NMIB** — tied high on the RP6502 by default (the [[w65c22s]] VIA can drive IRQB).
- **VPB** — goes low while the CPU reads an interrupt vector from `$FFFA-$FFFF`. Not currently used by RP6502 firmware.
- **BE** (Bus Enable) — asynchronous; drops A0-A15, D0-D7, RWB to high-Z when low (DMA hook). RP6502 keeps BE high.
- **SYNC** — high during opcode fetch; can be combined with RDY for single-instruction stepping.
- **SOB** — sets the V flag on negative edge. WDC notes: "not recommended in new system design."
- **MLB** (Memory Lock) — asserted during RMW for multiprocessor bus arbitration. RP6502 is single-master, ignored.

## Packages

- 40-pin **PDIP** (used on the RP6502 board)
- 44-pin **PLCC**
- 44-pin **QFP**

## Related pages

- [[w65c02s]] · [[65c02-instruction-set]] · [[65c02-addressing-modes]] · [[memory-map]] · [[reset-model]] · [[ria-registers]]
