---
type: entity
tags: [rp6502, hardware, pcb]
related: [[rp6502-ria]], [[rp6502-ria-w]], [[rp6502-vga]], [[w65c02s]], [[w65c22s]]
sources: [[hardware]], [[picocomputer-intro]]
created: 2026-04-15
updated: 2026-04-15
---

# RP6502 Board

**Summary**: The reference PCB for the Picocomputer 6502 project. A 150×100 mm, 2-layer, 100% through-hole, 8-IC homebrew design. Rev B is current.

---

## What it is

The "Picocomputer 6502" name refers to both the **project** and the **reference board** (`RP6502`). The board is a reference design for modular RP6502 hardware. The **only required module** is [[rp6502-ria]]; [[rp6502-vga]] is optional.

Rev A and Rev B are electrically identical — Rev B only removed unused debug connectors under the RIA.

## ICs (from [[hardware]])

| Ref | Part | Role |
| --- | --- | --- |
| U1 | WDC **W65C02S** → [[w65c02s]] | 65C02 CPU |
| U5 | WDC **W65C22S** → [[w65c22s]] | VIA @ `$FFD0-$FFDF` |
| U2 | Raspberry Pi Pico 2 **W** | [[rp6502-ria-w]] |
| U4 | Raspberry Pi Pico 2 | [[rp6502-vga]] |
| U3 | Alliance AS6C1008 | 128 K SRAM (≤ 70 ns) |
| U6 | TI CD74AC00E | Glue |
| U7 | TI CD74AC02E | Glue |
| U8 | TI CD74HC30E | Glue |

Two of U6/U7/U8 **must be AC** (not HC, never HCT/ACT) to hit 8 MHz.

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
- [[hardware]] (build guide source)
