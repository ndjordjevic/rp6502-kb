---
type: topic
tags: [rp6502, community, projects, demos, games, tools, tracker, razemos, native-os]
related: [[rp6502-ria]], [[rp6502-vga]], [[opl2-fm-synth]], [[pix-bus]], [[cc65]], [[llvm-mos]]
sources: [[rumbledethumps-discord]], [[community-wiki]]
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

## Community wiki directory

The official [picocomputer/community wiki](https://github.com/picocomputer/community/wiki) maintains a curated project directory by category.

### Games

| Project | Author/Repo | Description |
|---------|-------------|-------------|
| **Star-Swarms** | [discussion #66](https://github.com/orgs/picocomputer/discussions/66) | Galaxian clone |
| **Tetricks** | [discussion #54](https://github.com/orgs/picocomputer/discussions/54) | Tetris clone |
| **Colossal Cave Adventure** | [picocomputer/adventure](https://github.com/picocomputer/adventure) | Classic text adventure |
| **Snake** | [netzerohero/snake](https://github.com/netzerohero/snake) | Snake game |
| **Sliding Block Puzzle** | [discussion #100](https://github.com/orgs/picocomputer/discussions/100) | Sliding block puzzle games |
| **Game of Life** | [grakoczy](https://github.com/grakoczy/picocomputer-game-of-life) | Conway's Game of Life |
| **Space Raiders** | [marklinebaugh/RP6502-Space-Raiders](https://github.com/marklinebaugh/RP6502-Space-Raiders) | Space Invaders tribute |
| **RP Mega Super Fighter** | [discussion #158](https://github.com/orgs/picocomputer/discussions/158) | 2D space shooter (jasonr1100) |
| **Mega Chopper** | [discussion #160](https://github.com/orgs/picocomputer/discussions/160) | Choplifter variant (jasonr1100) |

### Applications

| Project | Author/Repo | Description |
|---------|-------------|-------------|
| **TE — ASCII Text Editor** | [discussion #96](https://github.com/orgs/picocomputer/discussions/96) | ASCII text editor (tonyvr0759) |
| **Home Monitor** | [discussion #159](https://github.com/orgs/picocomputer/discussions/159) | RSS feed display via AT commands / HTTP |

### BASIC

| Resource | Description |
|----------|-------------|
| **EhBASIC** | [picocomputer/ehbasic](https://github.com/picocomputer/ehbasic) — Lee Davison's Enhanced BASIC |
| **BASIC Computer Games** | Classic games run on EhBASIC; change `RND(1)` → `RND(0)` |
| **EhBASIC+ Graphics ROM** | [netzerohero/picocomputer-ehbasic](https://github.com/netzerohero/picocomputer-ehbasic) — prototype graphics extension |

### Utilities and Techniques

| Project | Author/Repo | Description |
|---------|-------------|-------------|
| **Wozmon** | [discussion #48](https://github.com/orgs/picocomputer/discussions/48) | Apple 1 monitor |
| **SMON** | [discussion #78](https://github.com/orgs/picocomputer/discussions/78) | Full-featured 6502 monitor with assembler/disassembler/single-step debug (originally for C64, 1984) |
| **RP6502-Shell** | [discussion #91](https://github.com/orgs/picocomputer/discussions/91) | Basic shell with `func(argc, argv[])` dispatch |
| **Parallax scrolling** | [netzerohero/paralax](https://github.com/netzerohero/paralax) | Parallax scrolling example |
| **Game of Life (LLVM-MOS)** | [rumbledethumps/life](https://github.com/rumbledethumps/life) | Game of Life for the experimental llvm-mos compiler |
| **Game of Life (cc65)** | [netzerohero/life-pico-cc65](https://github.com/netzerohero/life-pico-cc65) | Instrumented cc65 version measuring loop times |

### Cases

| Project | Link | Description |
|---------|------|-------------|
| **3D printed case** | [discussion #50](https://github.com/orgs/picocomputer/discussions/50) | 3D-printable enclosure |

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
- [[community-wiki]]
