---
type: entity
tags: [rp6502, hardware, pcb]
related:
  - "[[rp6502-ria]]"
  - "[[rp6502-ria-w]]"
  - "[[rp6502-vga]]"
  - "[[w65c02s]]"
  - "[[w65c22s]]"
sources:
  - "[[hardware]]"
  - "[[picocomputer-intro]]"
  - "[[schematic-2023]]"
created: 2026-04-15
updated: 2026-04-18
---

# RP6502 Board

**Summary**: The reference PCB for the Picocomputer 6502 project. A 150×100 mm, 2-layer, 100% through-hole, 8-IC homebrew design. Rev B is current.

---

## What it is

The "Picocomputer 6502" name refers to both the **project** and the **reference board** (`RP6502`). The board is a reference design for modular RP6502 hardware. The **only required module** is [[rp6502-ria]]; [[rp6502-vga]] is optional.

Rev A and Rev B are electrically identical — Rev B only removed unused debug connectors under the RIA.

## ICs (from [[hardware]])

| Ref | Part | Role | Mouser # |
| --- | --- | --- | --- |
| U1 | WDC **W65C02S** → [[w65c02s]] | 65C02 CPU | `955-W65C02S6TPG-14` |
| U5 | WDC **W65C22S** → [[w65c22s]] | VIA @ `$FFD0-$FFDF` | `955-W65C22S6TPG-14` |
| U2 | Raspberry Pi Pico 2 **W** (w/headers) | [[rp6502-ria-w]] | `358-SC1634` |
| U4 | Raspberry Pi Pico 2 (w/headers) | [[rp6502-vga]] | `358-SC1632` |
| U3 | Alliance AS6C1008-55PCN | 128 K SRAM — **55 ns** (≤70 ns req'd) | `913-AS6C1008-55PCN` |
| U6 | TI CD74AC00E | Glue — quad NAND | `595-CD74AC00E` |
| U7 | TI CD74AC02E | Glue — quad NOR | `595-CD74AC02E` |
| U8 | TI CD74HC30E | Glue — 8-input NAND | `595-CD74HC30E` |

Two of U6/U7/U8 **must be AC** (not HC, never HCT/ACT) to hit 8 MHz.

> **Headerless build**: use `358-SC1633` (Pico 2 W, no headers) + `358-SC1631` (Pico 2, no headers) + separate 20-pin headers (`649-1012937892001BLF`, 2 per Pico). See `rp6502-revb-picos.csv` on the docs site.

## Schematics

- **Rev B schematic** (current): `_static/2026-01-26-rp6502.pdf` on docs site
- **Rev A schematic** (older): `_static/2023-06-07-rp6502.pdf` on docs site
- Rev A and Rev B are electrically identical — Rev B only removed unused debug connectors.
- Gerber + assembly zips for both revisions are also in `_static/`.

## Connectors

- **J1** — 2×12 GPIO expansion header
- **J2** — 2×6 [[pix-bus]] header
- **J3** — VGA DE-15
- **J4** — 3.5 mm audio
- **SW1** — reboot button, wired to **RIA RUN pin** (see [[reset-model]])

## Speed / clocks

Variable **0.1–8.0 MHz** system clock, driven by [[rp6502-ria]]'s PHI2 generator. 8 MHz requires AC glue and ≤70 ns SRAM. `RIA_ATTR_PHI2_KHZ` changes speed at runtime (reverts when the ROM exits).

## Related pages

- [[rp6502-ria]] · [[rp6502-ria-w]] · [[rp6502-vga]]
- [[hardware]] (build guide source) · [[schematic-2023]] (schematic source)
- [[board-circuits]] — glue logic, VGA DAC, audio filter, IRQ topology
