---
type: concept
tags: [rp6502, audio, opl2, fm, synthesis, ym3812]
related: [[rp6502-ria]], [[programmable-sound-generator]], [[xreg]], [[xram]], [[pix-bus]]
sources: [[yt-ep22-graphics-sound-demos]], [[release-notes]]
created: 2026-04-17
updated: 2026-04-17
---

# OPL2 FM Synthesizer

**Summary**: The OPL2 FM synthesizer is a firmware-based emulation of the Yamaha YM3812 chip (used in AdLib and Sound Blaster cards) added to the [[rp6502-ria]] — accessible via flash upgrade with no hardware change.

---

## What it is

OPL2 (Operator Level 2) is the FM synthesis standard popularized by the **AdLib sound card** (1987) and **Sound Blaster** (1989). It uses frequency modulation of oscillators (operators) to create a wide palette of musical timbres — from piano to brass to organ to bells. The chip implemented in those cards was Yamaha's **YM3812**.

The Picocomputer's OPL2 is a **firmware emulation** (`emu8950` library) running on the RP2350 inside the RIA — not a discrete chip. The audio output shares the same PWM → RC filter → audio jack path as the [[programmable-sound-generator]].

## History

> **From [[yt-ep22-graphics-sound-demos]] (Ep22, 2026)**:
>
> A prolific community member who wrote several games (Space Invaders, Asteroids, a Sega Genesis port) "strapped an FPGA to the [[pix-bus|PIX bus]] to experiment with OPL2 sound" and mentioned writing a music tracker. This inspired the author to add OPL2 natively to the RIA firmware.
>
> The author had tried to get FM working when the system used the Pi Pico 1, but "multiple things were in the way." The Pi Pico 2 unblocked it technically, but motivation was lacking until the FPGA experiment demonstrated that the community needed a tracker accessible without FPGA hardware.

> **Version**: Added in the **v0.16** era (see [[version-history]] Era 6, Dec 2025–Jan 2026: "OPL2 FM synthesis via `emu8950`").

## Firmware upgrade

To get OPL2 support on existing hardware: flash new RIA firmware (`.uf2` file). No hardware change required. Coexists with the [[programmable-sound-generator]] — both can be active simultaneously.

## Register interface

| XREG address | Content |
|---|---|
| `$0:1:01` | OPL2 register image start address in [[xram|XRAM]] (must be page-aligned) |

The OPL2 register image is **256 bytes** — a direct map of the YM3812 register space. Programs write to this XRAM block using the [[xreg]] mechanism.

**Limitation**: Timers, interrupts, and the status register are not supported (the Picocomputer has its own timer subsystem). The full synthesis register set is supported.

## Compatibility

The YM3812 register set is well-documented and compatible with the AdLib standard. Existing OPL2 music files and tracker formats can be targeted at this interface.

## Music tracker

A community-written music tracker supports both the PSG and OPL2. Effects include arpeggio, portamento, vibrato, echo, tremolo, and microtonal folds. Documentation is 20 pages long.

## Related pages

- [[rp6502-ria]] — the firmware that contains the OPL2 emulation
- [[programmable-sound-generator]] — the PSG that coexists with OPL2
- [[xreg]] — how to point the OPL2 at its 256-byte register image
- [[yt-ep22-graphics-sound-demos]] — origin story and first demo
