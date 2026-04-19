---
type: entity
tags: [rp6502, community, music, opl2, tracker, audio]
related:
  - "[[opl2-fm-synth]]"
  - "[[rp6502-vga]]"
  - "[[rp6502-abi]]"
  - "[[cc65]]"
  - "[[community-projects]]"
sources:
  - "[[rumbledethumps-discord]]"
created: 2026-04-18
updated: 2026-04-18
---

# RPTracker

**Summary**: A native OPL2 music tracker for the RP6502 Picocomputer, developed by jasonr1100 — provides 9 channels, 256 instrument patches, multiple effects, CP437 display, and save/load support.

---

## Overview

RPTracker is a full music composition application that runs natively on the RP6502 hardware, using the [[opl2-fm-synth]] (Yamaha YM3812 emulation) provided by the RIA firmware. It was developed by community member jasonr1100 and reached v0.1 on 2025-12-31.

---

## Features

### Audio engine
- **9 channels** — OPL2 provides 9 melodic channels (or 6 melodic + 5 percussion in rhythm mode)
- **256 patches** — two banks of 128 instruments each:
  - Patches 0–127: Sierra On-Line / AdLib instrument set (classic OPL2 FM presets)
  - Patches 128–255: Drums and noise instruments

### Effects (per channel, per step)
| Effect | Description |
|--------|-------------|
| Arpeggio | Rapid alternation between notes to simulate chords |
| Portamento | Glide between notes (pitch slide) |
| Vibrato | Periodic pitch modulation |
| Pitch slide up/down | Linear pitch bend over time |
| Tremolo | Periodic volume modulation |
| Delay | Note repeat / echo pattern |

### Interface and I/O
- **CP437 character set** — full box-drawing characters for the tracker grid
- **Save / Load** — patterns and songs persist to the RP6502 filesystem (FAT via USB flash)
- Runs from USB keyboard input (via RIA HID stack)

---

## Version history

| Version | Date | Notes |
|---------|------|-------|
| v0.1 | 2025-12-31 | Initial release |

---

## Related work by jasonr1100

jasonr1100 also built the `RP6502_OPL2` hardware — an FPGA-based OPL2 sound card connecting via [[pix-bus]] at XRAM `$1FF00–$1FF01`, using W65C22S VIA IRQ for timing. RPTracker uses the software OPL2 emulation built into the RIA firmware, not this external card.

---

## Related pages

- [[opl2-fm-synth]] — YM3812 emulation in the RIA firmware
- [[community-projects]] — all notable community projects
- [[rp6502-ria]] — RIA firmware providing OPL2 via XREG device map
- [[vga-display-modes]] — display context for tracker's CP437 UI
