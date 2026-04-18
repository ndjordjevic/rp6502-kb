---
type: source
tags: [rp6502, hardware, schematic, pcb, glue-logic, vga-dac, audio]
related: [[rp6502-board]], [[board-circuits]], [[gpio-pinout]], [[pix-bus]], [[w65c22s]]
sources: [raw/pdfs/2023-06-07-rp6502.pdf]
created: 2026-04-18
updated: 2026-04-18
---

# Source — Schematic (2023-06-07)

**Summary**: The single-page KiCad schematic for the Picocomputer 6502. Dated 2023-06-07; electrically identical to Rev B (only cosmetic debug-connector change between revisions). Hosted as `_static/2023-06-07-rp6502.pdf` on the docs site; `_static/2026-01-26-rp6502.pdf` is the current Rev B version.

Raw: [raw/pdfs/2023-06-07-rp6502.pdf](../../raw/pdfs/2023-06-07-rp6502.pdf)

---

## Key facts

- One-page schematic (Id: 1/1), USLetter, by Rumbledethumps.
- All 8 active ICs are present: U1 (W65C02S), U2 (Pico RIA), U3 (AS6C1008), U4 (Pico VGA), U5 (W65C22S), U6 (74AC00), U7 (74AC02), U8 (74HC30).
- Two power rails: **+3V3A** (analog — VGA DAC + audio) and **+3V3B** (digital — Picos, logic ICs).
- Power decoupling: eight 0.1 µF caps (C1–C8) on +3V3A; two 0.1 µF caps (C4–C5) on +3V3B; two 47 µF bulk caps (C10, C12) for audio channels.
- Note: resistors "Use 1% resistors for audio and video."

## Connectors

| Ref | Name | Size | Signals |
| --- | --- | --- | --- |
| J1 | GPIO | 2×12 (24 pin) | PA0–PA7, PB0–PB7, CA0–CA1, CB0–CB1 of W65C22S + VBUS/GND |
| J2 | PIX | 2×6 (12 pin) | PHI2, PIX0, PIX1, PIX2, PIX3 + VBUS/GND |
| J3 | VGA | DE-15 | REDV, GRNV, BLUV, HSYNC, VSYNC (R16=47Ω, R17=47Ω sync termination) |
| J4 | AUDIO | 3.5 mm TRS | AUDL (left), AUDR (right) |
| JP1 | POWER | 2-pin | VBUS — board power-select jumper |
| JP2 | SHIELD | 2-pin | USB shield to GND |
| SW1 | REBOOT | Momentary | Wired directly to RIA Pico RUN pin |

## Glue logic gates (U6/U7/U8)

See [[board-circuits]] for full analysis.

| Gate | Part | Inputs | Output | Function |
| --- | --- | --- | --- | --- |
| U6A | 74AC00 NAND | PHI2, RWB | WE# | SRAM write-enable generation |
| U6B | 74AC00 NAND | RIRQB, VIRQB | → U7D | IRQ merge (first stage) |
| U6C | 74AC00 NAND | A7, A6 | → U7A | I/O address qualification |
| U6D | 74AC00 NAND | A5, IORQ | RREQ | RIA request signal |
| U7A | 74AC02 NOR | (from U6C) | → IORQB path | Address decode |
| U7B | 74AC02 NOR | A8–A15 from U8A, other | IORQ | Final IORQ assertion to RIA |
| U7C | 74AC02 NOR | PHI2, RWB | → U6A | WE# timing |
| U7D | 74AC02 NOR | RIRQB, VIRQB | IRQB | IRQ merge (final → CPU) |
| U8A | 74HC30 8-NAND | A8–A15 | IORQB | Detects address in `$FFxx` range |

## VGA DAC

5-bit R-2R resistor ladder per color channel. Values (1% tolerance required):
`8.06k → 4.02k → 2k → 1k → 499Ω` for each of RED0–4, GRN0–4, BLU0–4.
Combined analog outputs: REDV, GRNV, BLUV → J3.
Two 47Ω resistors (R16, R17) terminate HSYNC and VSYNC at J3.

## Audio circuit

Per-channel (L and R identical):
`PWML/PWMR → 220Ω (R19/R22) → junction: 100Ω (R20/R23) to GND + 0.1µF (C9/C11) → 47µF (C10/C12) → 1.8kΩ (R21/R24) → AUDL/AUDR → J4`

The RC network (100Ω || 0.1µF) low-pass filters the PWM signal. 47µF AC-couples the output. 1.8kΩ limits current to the jack.

## Related pages

- [[rp6502-board]] · [[board-circuits]] · [[gpio-pinout]] · [[pix-bus]] · [[w65c22s]]
