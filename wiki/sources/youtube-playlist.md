---
type: source
tags: [rp6502, youtube, playlist]
related:
  - "[[development-history]]"
  - "[[overview]]"
sources: []
created: 2026-04-17
updated: 2026-04-17
---

# YouTube Playlist — Picocomputer 6502

**Summary**: Hub page for the official "Picocomputer 6502" YouTube series by `rumbledethumps` (the project author). 22 episodes spanning late 2022 to 2026, documenting hardware bring-up, firmware design, OS development, toolchain choices, and community software.

**Playlist**: [Picocomputer 6502](https://www.youtube.com/playlist?list=PLvCRDUYedILfHDoD57Yj8BAXNmNJLVM2r)

For the chronological narrative of design decisions, see [[development-history]].

---

## Episode list

| # | Title | Video ID | Wiki page | Notes |
|---|---|---|---|---|
| 1 | The start of an 8-bit Retro Gaming Computer | `SVZaSRUhIjo` | [[yt-ep01-8bit-retro-computer]] | Breadboard intro; USB/VGA up; 12 glue chips |
| 2 | 6502 reads Raspberry Pi Pico @ 8 MHz - PIO and DMA | `GOEI2OpMncY` | [[yt-ep02-pio-and-dma]] | Dual-Pico pivot; PIO+DMA read path; 8 MHz achieved |
| 3 | Writing to the Raspberry Pi Pico - More PIO and DMA | `wxV6x5BUMH4` | [[yt-ep03-writing-to-pico]] | Write path; glue logic; AC-chip discovery |
| 4 | The Picocomputer says hello! | `uL8BL7ZDdlk` | [[yt-ep04-picocomputer-hello]] | First demo; fast-load pattern; schematic release |
| 5 | A short BASIC demo | `szCiDvR06ws` | — | ⏭ no captions available |
| 6 | ROMs and the filesystem - TinyUSB and FatFs | `9u82Uy_458E` | [[yt-ep06-roms-filesystem]] | *(Session 2)* |
| 7 | The Operating System - featuring Colossal Cave Adventure | `kf-mvyL70bc` | [[yt-ep07-operating-system]] | *(Session 2)* |
| 8 | VGA Graphics and the PIX bus | `yh26kSxFnvY` | [[yt-ep08-vga-pix-bus]] | DDR 4-wire PIX bus design; PIO resource cost; DMA priority |
| 9 | C Programming Setup | `YP90d0YI9Qc` | [[yt-ep09-c-programming-setup]] | cc65 + VSCode template; Ctrl+Shift+B workflow; rp6502.py |
| 10 | DIY build with soldering | `bwgLXEQdq20` | [[yt-ep10-diy-build]] | Through-hole PCB assembly; Founders Edition boards |
| 11 | No soldering and no breadboard | `4CjouKoCMUw` | [[yt-ep11-no-soldering]] | PCBWay single-unit manufacturing; $30 assembly fee |
| 12 | Fonts and Vsync and Versioning | `CcatgIZI--Y` | [[yt-ep12-fonts-vsync]] | v0.1 release; code pages CP437/850/855; VSYNC backchannel |
| 13 | Graphics Programming | `QVvH03OSVf0` | [[yt-ep13-graphics-programming]] | Canvas/mode/xreg; planes; scanline partition; scrolling |
| 14 | USB Mouse on a 6502 | `e1c91LBn-b8` | [[yt-ep14-usb-mouse]] | 3 input modes; fgets() added; paint demo |
| 15 | Asset Management and More Graphics | `s6BZ5MKbLEk` | [[yt-ep15-asset-management]] | CMake asset workflow; sprites with affine transforms |
| 16 | Programmable Sound Generator Intro | `UxFtKBV5d8A` | [[yt-ep16-psg-intro]] | PSG: 8ch, 5 waveforms, ADSR, PWM |
| 17 | The basics of BASIC | `Y3_pkzlLjtk` | [[yt-ep17-basics-of-basic]] | EhBASIC install; SET BOOT; reset vs. reboot |
| 18 | Are you keeping up with LLVM-MOS? | `xkolkC1RgOY` | [[yt-ep18-llvm-mos]] | cc65 vs LLVM-MOS comparison |
| 19 | Programming the Game of Life on a 6502 | `ZsH-SggoK_Y` | [[yt-ep19-game-of-life]] | 640×480 monochrome bitmap; tutorial |
| 20 | The 6502 calls a BBS | `7U__9tsimOA` | [[yt-ep20-bbs]] | Pi Pico 2 upgrade; WiFi BBS; NTP+DST |
| 21 | Programming a 6502 with AI | `tZmbrMx5vy8` | [[yt-ep21-ai-programming]] | GitHub Copilot; "AI loves ignoring the docs" |
| 22 | Graphics and Sound Demos | `MPlms833KOU` | [[yt-ep22-graphics-sound-demos]] | Community demos; OPL2 FM synth origin story |

---

## Coverage summary

- **21/22 transcripts** retrieved. Ep5 has no captions (silent BASIC demo — skipped by design).
- [[development-history]] covers the full chronological narrative across all eras.
- Episode source pages are indexing stubs — technical content lives on concept/entity/topic pages.

## Scope

| Episode | Status |
|---|---|
| Ep1 | [x] ingested |
| Ep2 | [x] ingested |
| Ep3 | [x] ingested |
| Ep4 | [x] ingested |
| Ep5 | [-] skipped — no captions available |
| Ep6 | [x] ingested |
| Ep7 | [x] ingested |
| Ep8 | [x] ingested |
| Ep9 | [x] ingested |
| Ep10 | [x] ingested |
| Ep11 | [x] ingested |
| Ep12 | [x] ingested |
| Ep13 | [x] ingested |
| Ep14 | [x] ingested |
| Ep15 | [x] ingested |
| Ep16 | [x] ingested |
| Ep17 | [x] ingested |
| Ep18 | [x] ingested |
| Ep19 | [x] ingested |
| Ep20 | [x] ingested |
| Ep21 | [x] ingested |
| Ep22 | [x] ingested |

## Related pages

- [[development-history]] — design evolution narrative organized by era
- [[overview]] — current-state synthesis across all sources
