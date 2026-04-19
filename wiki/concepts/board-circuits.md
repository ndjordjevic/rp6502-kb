---
type: concept
tags: [rp6502, hardware, glue-logic, vga-dac, audio, irq, iorq, schematic]
related:
  - "[[rp6502-board]]"
  - "[[schematic-2023]]"
  - "[[w65c02s]]"
  - "[[w65c22s]]"
  - "[[rp6502-ria]]"
  - "[[rp6502-vga]]"
  - "[[gpio-pinout]]"
  - "[[pix-bus]]"
sources:
  - "[[schematic-2023]]"
created: 2026-04-18
updated: 2026-04-18
---

# Board Circuits

**Summary**: Board-level circuit topology of the RP6502 reference PCB — glue logic functions, IRQ merge, IORQ decode, VGA DAC, and audio filter. Derived from the 2023-06-07 schematic (Rev A = Rev B electrically).

---

## Power rails

Two separate 3.3 V supplies:

| Rail | Name | Feeds |
| --- | --- | --- |
| +3V3A | Analog | VGA DAC resistor network, audio filter caps, pull-up on W65C02S |
| +3V3B | Digital | Pico RIA (U2), Pico VGA (U4), 74xx logic ICs |

Decoupling: eight 0.1 µF ceramic caps (C1–C8) distributed across +3V3A; two 0.1 µF caps (C4–C5) on +3V3B. Two 47 µF bulk caps (C10, C12) are in the audio output path.

Separating rails keeps PWM switching noise on +3V3B from coupling into the analog video/audio path on +3V3A.

---

## Glue logic overview

Three logic ICs provide all board-level decoding:

| IC | Part | Type | Key use |
| --- | --- | --- | --- |
| U6 | 74AC00 | Quad NAND | WE# generation, IRQ merge, I/O address bits |
| U7 | 74AC02 | Quad NOR | WE# timing, IORQ/RREQ output, IRQ merge output |
| U8 | 74HC30 | 8-input NAND | Full-address IORQB detection |

**Must be AC for 8 MHz**: U6 and U7 are AC-family. U8 is HC (used only for IORQ decode, not in the critical write path).

---

## SRAM write enable (WE#)

The AS6C1008 SRAM (U3) write-enable signal is generated from PHI2 and RWB (the 65C02 read/write line). The glue combination ensures WE# asserts only during the correct phase of a CPU write cycle — preventing spurious writes during address setup or read cycles.

The 65C02 data bus is multiplexed between the RIA (for I/O) and the SRAM (for RAM). WE# timing must respect PHI2 phase to avoid bus contention.

---

## IORQ decode

The RIA register window (`$FFE0–$FFFF`) is decoded in two stages:

1. **U8A (74HC30, 8-input NAND)**: Takes address bits A8–A15. IORQB goes low when ALL of A8–A15 are high — i.e., address is in `$FFxx`. This is an active-low flag meaning "address is in the high page."

2. **U6C + U7A + U6D**: Further qualify IORQB with A5–A7 to narrow selection to the specific `$FFE0–$FFFF` window. Output is **IORQ** — asserted to the RIA Pico to signal a register access.

3. **RREQ**: A control output from the RIA gate that signals bus request to the 65C02 (used for RIA handshaking; the 65C02's RDY pin or equivalent path).

The RIA only decodes 5 address bits (A0–A4) internally — chip-select logic on the board handles the `$FFE0` window gate.

---

## IRQ merge

Two independent interrupt sources can signal the W65C02S:

| Signal | Source | Meaning |
| --- | --- | --- |
| RIRQB | Pico RIA (U2, GPIO 22) | OS interrupt (timer, USB event, etc.) |
| VIRQB | Pico VGA (U4) | VSYNC tick or VGA event |

Both are active-low open-collector style. The glue logic (U6B → U7D) wire-AND's the two sources and drives the 65C02's **IRQB** pin. Either module can independently interrupt the CPU; IRQB goes low if either RIRQB or VIRQB is asserted.

Implication: the CPU IRQ handler must poll both `RIA_IRQ` and the VSYNC register to determine which source fired (or use separate vectors if both are pending simultaneously — standard 6502 IRQ dispatch pattern).

---

## VGA DAC

The Pico VGA (U4) outputs 5-bit color on GPIO 6–21 (RED0–4, GRN0–4, BLU0–4). These digital signals are converted to analog by an **R-2R resistor ladder** per channel.

**Resistor values (1% tolerance required, from +3V3A rail):**

| Bit | Weight | Value |
| --- | --- | --- |
| bit 4 (MSB) | R | 8.06 kΩ |
| bit 3 | 2R | 4.02 kΩ (≈ 2 × 2k) |
| bit 2 | 2R | 2 kΩ |
| bit 1 | 2R | 1 kΩ |
| bit 0 (LSB) | 2R | 499 Ω |

Combined analog output (REDV, GRNV, BLUV) → J3 (DE-15 VGA connector). HSYNC and VSYNC are terminated with 47Ω resistors (R16, R17) at J3 to match transmission-line impedance.

**Color depth**: 5 bits × 3 channels = 15 bits analog → matches the RGB555 pixel format used in XRAM. The 16th bit in XRAM color words is the alpha/transparency flag (not a color bit) and is not routed to the DAC.

---

## Audio circuit

The RIA generates stereo PWM audio on two GPIO pins (PWML = left, PWMR = right). Each channel passes through an identical analog filter before reaching J4 (3.5 mm audio jack):

```
PWML/PWMR
    │
   220Ω (R19/R22)         ← series current limit
    │
    ├── 100Ω (R20/R23) ── GND     ← RC low-pass with C9/C11
    └── 0.1µF (C9/C11) ── GND
    │
   47µF (C10/C12)         ← AC coupling (blocks DC offset)
    │
   1.8kΩ (R21/R24)        ← output series resistor (headphone protection)
    │
  AUDL/AUDR → J4
```

The 100Ω + 0.1µF RC filter removes high-frequency PWM carrier. The 47µF cap AC-couples so only audio-band signal reaches the jack. The 1.8kΩ output resistor limits short-circuit current and provides some impedance matching.

The [[programmable-sound-generator]] and [[opl2-fm-synth]] both route through this circuit.

---

## Connector summary

| Ref | Purpose | Key signals |
| --- | --- | --- |
| J1 GPIO | VIA expansion | PA0–7, PB0–7, CA0–1, CB0–1 of [[w65c22s]] |
| J2 PIX | [[pix-bus]] | PHI2, PIX0–PIX3 |
| J3 VGA | Analog video out | REDV, GRNV, BLUV, HSYNC, VSYNC |
| J4 AUDIO | Analog audio out | AUDL, AUDR |
| JP1 POWER | USB power select | VBUS bridge |
| JP2 SHIELD | USB shield | Shield to GND |
| SW1 REBOOT | Hard reboot | RIA Pico RUN pin |

**J1 (GPIO) is entirely W65C22S I/O** — not raw 6502 address/data bus. Any expansion hardware hanging off J1 talks to the 65C02 through the VIA register interface at `$FFD0–$FFDF`.

---

## Related pages

- [[rp6502-board]] — ICs, Mouser BOM, schematic files
- [[schematic-2023]] — source page for this analysis
- [[gpio-pinout]] — RIA and VGA Pico firmware-level GPIO assignments
- [[programmable-sound-generator]] · [[opl2-fm-synth]] — audio sources
- [[w65c22s]] — VIA connected to J1
- [[pix-bus]] — PIX bus protocol on J2
