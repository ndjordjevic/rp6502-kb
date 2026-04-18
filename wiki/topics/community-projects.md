---
type: topic
tags: [rp6502, community, projects, demos, games, tools, tracker, razemos, native-os]
related: [[rp6502-ria]], [[rp6502-vga]], [[opl2-fm-synth]], [[pix-bus]], [[cc65]], [[llvm-mos]]
sources: [[rumbledethumps-discord]]
created: 2026-04-18
updated: 2026-04-18
---

# Community Projects

**Summary**: Notable software, hardware expansions, and tools built by the RP6502 community (excluding the official picocomputer organisation repos).

---

## jasonr1100 (Jason R.)

| Project | Description |
|---------|-------------|
| **RPMegaFighter** | Side-scrolling space shooter |
| **RPMegaChopper** | Choplifter clone (rescue helicopter) |
| **RPMegaRacer** | Sprint/top-down racing game |
| **RPGalaxy** | Lorenz/Rössler fractal attractor demo, 6400 particles |
| **RPTracker** | Native OPL2 music tracker — 9 channels, 256 patches (0–127 Sierra/AdLib, 128–255 drums/noise), effects (arpeggio, portamento, vibrato, slides, tremolo, delay), CP437 support, save/load. v0.1 released 2025-12-31. |
| **RP6502_OPL2** | FPGA OPL2 sound card connecting via [[pix-bus]] at `$1FF00–$1FF01`; used 6522 VIA IRQ for timing |
| **MovieTime6502** | Full-motion video player — Metropolis (1927) playback at ~400 KB/s, 32 colours, tile-based encoding with 2 planes × 256 8×8 tiles, 4-bit colour, ~24 fps |
| **RP6502-Cosmic-Arc** | Cosmic Ark port |

### Notes
- Professor at a liberal arts university; also works on space telescope missions.
- macOS user; contributed fixes to `rp6502.py` macOS port detection.

---

## voidas_pl (WojciechGw)

| Project | Description |
|---------|-------------|
| **razemOS** | Native 65C02 OS for RP6502 ("togetherOS" in Polish). Kernel fits below `0x8000`. v0.01 (2026-04-10): kernel + HASS; v0.02 (2026-04-12): zip support, `roms` launcher command. Moving toward multitasking. |
| **HASS** | Handy ASSembler for 65C02 — ships as standalone `.rp6502` (needs `0x7B00` as .com). Bundled with razemOS. |
| **ctx.py / crx.py** | Python scripts for PC-side file transfer to/from Picocomputer 6502; bundled with razemOS 0.01. |
| **PicoMatrix** | Matrix screen effect demo |
| **RIA math coprocessor PR** | Proposed float32 operations via RIA registers `$FFEF`/`$FFF1` (not merged) |

Repo: `https://github.com/WojciechGw/cc65-rp6502os`

---

## tonyvr0759 (Tony V.)

| Project | Description |
|---------|-------------|
| **RP6502-TextEditor** | ASCII text editor |
| **65816 adaptation** | RP6502 running WDC 65816 at 6 MHz on breadboard; target board: Pimoroni PGA2350 |

---

## jjjacer

| Project | Description |
|---------|-------------|
| **eInk laptop** | RP6502 laptop with ESP32-driven eInk display; console over serial at 115200 bps |

---

## markrvm

| Project | Description |
|---------|-------------|
| **RP6809** | RP6502-style computer with Motorola 6809 CPU; uses GALs for glue logic; target OS: NitrOS-9 |

---

## Other notable contributors

| Handle | Contribution |
|--------|-------------|
| **jasonfrowe** | PR: NFC card reader support via PN532+CH340 USB adapter (merged) |
| **ndjordjevic5067** | Debugged VGA cold-boot `busy_wait_ms(5)` fix (merged v0.18); PR #118 Raspberry Pi keyboard num-lock exception (merged) |
| **pjf.** | Teaches microprocessor application development with RP6502 (built ~12 boards); Darwin support in `rp6502.py` |
| **stephanh80** | Wire-wrapped RP6502 build (no PCB) |
| **sodiumlightbaby** | Analysed `act_loop()` PIO action loop logic; contributed to firmware understanding |

---

## Resources

- Community wiki: https://github.com/picocomputer/community/wiki
- Example ROMs: https://picocomputer.github.io/applications/
- Official Discord: https://discord.gg/rumbledethumps

---

## Related pages

- [[opl2-fm-synth]]
- [[pix-bus]]
- [[rp6502-vga]]
- [[rumbledethumps-discord]]
