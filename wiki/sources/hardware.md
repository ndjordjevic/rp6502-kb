---
type: source
tags: [rp6502, hardware, build, source]
related: [[rp6502-board]], [[w65c02s]], [[w65c22s]]
sources: [picocomputer.github.io/hardware]
created: 2026-04-15
updated: 2026-04-15
---

# Source — Hardware (build guide)

**Summary**: Build instructions, schematic link, BOM, and parts-substitution rules for the [[rp6502-board]] reference PCB (Rev B).

Raw: [Hardware](<../../raw/web/picocomputer.github.io/Hardware — Picocomputer  documentation.md>)

---

## Key facts

- Rev. A and Rev. B boards are **electrically identical**; Rev B only removed unused debug connectors under the RIA.
- Board size: **150 × 100 mm** (4×6 in), 2-layer, through-hole only.
- Two Pi Picos on the board:
  - **U2** = Raspberry Pi Pico 2 **W** → runs [[rp6502-ria-w]] firmware.
  - **U4** = Raspberry Pi Pico 2 → runs [[rp6502-vga]] firmware.
- **Firmware install** = hold BOOTSEL, drag UF2 from [GitHub releases](https://github.com/picocomputer/rp6502/releases). LED turns on when done.
- **VGA-to-HDMI cables** work fine and are zero-lag; video uses HDMI-compatible timings.

## Active parts list (ICs only)

| Ref | Part | Role |
| --- | --- | --- |
| U1 | WDC **W65C02S** | CPU → [[w65c02s]] |
| U5 | WDC **W65C22S** | VIA → [[w65c22s]] |
| U2 | Raspberry Pi Pico 2 W | [[rp6502-ria-w]] |
| U4 | Raspberry Pi Pico 2 | [[rp6502-vga]] |
| U3 | Alliance **AS6C1008** | 128 K SRAM (≤ 70 ns for 8 MHz) |
| U6 | TI **CD74AC00E** | Quad NAND |
| U7 | TI **CD74AC02E** | Quad NOR |
| U8 | TI **CD74HC30E** | 8-input NAND |

## Substitution rules (gotchas)

- **74xx must be true CMOS**: use AC or HC, **never ACT/HCT**.
- Two of the three 74xx (U6/U7) **must be AC** for 8 MHz; HC works but limits top speed.
- W65C02S and W65C22S **must not be substituted**; no NMOS 6502/6522.
- SRAM speed must be **≤ 70 ns** to hit 8 MHz.
- Pi Pico SWD 3-pin connector is unused and can be ignored when sourcing alternatives.

## Board connectors

- **J1** — GPIO 2×12 header
- **J2** — **PIX** 2×6 header → [[pix-bus]]
- **J3** — VGA jack
- **J4** — 3.5 mm audio jack
- **SW1** — reboot momentary switch (wired to RIA RUN pin; see [[reset-model]])

## Related pages

- [[rp6502-board]]
- [[rp6502-ria]] / [[rp6502-ria-w]] / [[rp6502-vga]]
- [[pix-bus]]
