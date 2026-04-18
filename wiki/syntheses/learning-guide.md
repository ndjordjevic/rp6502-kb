---
type: synthesis
tags: [rp6502, 6502, learning, guide]
related: [[overview]], [[learning-6502-assembly]], [[toolchain-setup]], [[rp6502-os]]
created: 2026-04-18
updated: 2026-04-18
---

# RP6502 Learning Guide — What to Read and In What Order

**Summary**: A structured reading path through the wiki for anyone learning 6502 and RP6502 programming from scratch, covering both hardware understanding and software development.

---

## Before you start — quick orientation syntheses

Read these three synthesis pages first. Each is a short, direct answer to a fundamental question. Together they give you a mental model before you dive into the detailed tracks.

| Page | Question answered |
| ---  | ---               |
| [[what-does-ria-do]] | What does the RIA actually do? (Three roles: hardware ctrl, bus interface, protected OS) |
| [[getting-started]] | What does the end-to-end path look like? (Hardware → firmware → toolchain → first program) |
| [[cc65-vs-llvm-mos]] | Which toolchain should I use? (Feature comparison, performance, decision table) |

---

## How to use this guide

The guide has four tracks that partially overlap. If you are completely new to 6502, start at **Track A** before touching RP6502 material. If you already know 6502 assembly, skip straight to **Track B**.

Each item is a wiki page. Read it, follow the wikilinks it contains, then come back and continue down the list.

---

## Track A — 6502 Assembly Foundations

*Goal: understand the CPU itself before you touch any RP6502-specific code.*
*Source books behind these pages: Wagner (beginner), Zaks (methodology), Leventhal (depth).*

| Step | Page | What you learn |
| ---  | ---  | ---            |
| A1 | [[learning-6502-assembly]] | Registers, Status Register flags, binary arithmetic, counter/loop patterns, all 8 branch instructions |
| A2 | [[65c02-addressing-modes]] | All 16 addressing modes with cycle and byte counts; new `(zp)` and `(a,x)` modes; X-vs-Y asymmetry |
| A3 | [[65c02-instruction-set]] | Every 65C02 mnemonic; CMOS additions over NMOS; how to read the opcode table |
| A4 | [[6502-stack-and-subroutines]] | Stack layout ($0100–$01FF), PHA/PLA mechanics, JSR saves PC−1, RTS adds 1; register save/restore idioms |
| A5 | [[6502-subroutine-conventions]] | Parameter-passing (registers / ZP / inline / stack), Leventhal's 10-field template, reentrancy |
| A6 | [[6502-interrupt-patterns]] | IRQ/NMI/BRK/RESET vectors, ISR register save/restore, polling dispatch, RTI; VIA interrupt pattern |
| A7 | [[6502-programming-idioms]] | Multi-precision arithmetic, 8-bit multiply/divide, BCD mode, carry-chain rules, 14 quirks quick reference |
| A8 | [[6502-data-structures]] | Lists, queues, sort, jump tables, linked lists, trees, binary search, hashing (Zaks Ch.9) |
| A9 | [[6502-application-snippets]] | Reusable patterns: string ops, hex↔ASCII, BCD, parity, checksum; Zaks memory-clear and range-test |
| A10 | [[6502-common-errors]] | Bug catalogue: carry misuse, flag side effects, decimal-mode hazards, ISR pitfalls |
| A11 | [[6502-emulated-instructions]] | How to emulate missing 6502 ops: 16-bit shifts, extended branches, signed comparisons |
| A12 | [[6502-relocatable-and-self-modifying]] | Position-independent code: forced branches, CLV+BVC, BRA (65C02), indirect JMP tables |
| A13 | [[6502-io-patterns]] | Terminal I/O (RDLINE/WRLINE), parity, CRC-16, device-independent I/O handler |

**After A13** you have the full 6502 programmer's toolkit. Return here for reference as you write real code.

---

## Track B — RP6502 Hardware

*Goal: understand what the board is and how the silicon pieces connect.*

| Step | Page | What you learn |
| ---  | ---  | ---            |
| B1 | [[picocomputer-intro]] | Project pitch, module list, links to all subsystems — the 10-minute tour |
| B2 | [[overview]] | Living synthesis: how the pieces talk, firmware variants, key design decisions |
| B3 | [[hardware-build-guide]] | PCB sourcing, BOM, assembly sequence, firmware flashing, first-boot — the complete physical build |
| B4 | [[rp6502-board]] | Reference PCB: 150×100 mm, 8 ICs, 100% through-hole, what each IC does |
| B5 | [[w65c02s]] | The actual CPU: pin functions, AC/DC timing, NMOS-vs-CMOS caveats |
| B6 | [[w65c22s]] | The VIA at `$FFD0–$FFDF`: Port A/B, DDR, timers, shift register |
| B7 | [[6522-via]] | Deep VIA reference: PCR, IER, IFR, ACR; init sequence; Port A vs B differences |
| B8 | [[memory-map]] | 6502 address space + extended XRAM layout — what lives where |
| B9 | [[board-circuits]] | Glue logic (WE#, IORQ, IRQ merge), VGA DAC, audio filter, dual power rail |
| B10 | [[gpio-pinout]] | GPIO pin assignments for RIA and VGA Pico; RP2040/RP2350 function select tables |
| B11 | [[schematic-2023]] | 2023 KiCad schematic: connectors, glue logic, VGA DAC, audio circuit |

---

## Track C — RP6502 Firmware and OS

*Goal: understand the RIA firmware, the OS ABI, and every register the 6502 can touch.*
*Read Track B first.*

| Step | Page | What you learn |
| ---  | ---  | ---            |
| C1 | [[rp6502-ria]] | RIA overview: what the Pi Pico 2 does, why it owns PHI2 and RESB |
| C2 | [[monitor-reference]] | Monitor shell: LOAD/INSTALL/SET/filesystem commands; how to configure and operate the board |
| C3 | [[reset-model]] | RESB is a state not a pulse; reboot ≠ reset; only the RIA may drive RESB |
| C4 | [[ria-registers]] | Exact register addresses $FFE0–$FFFF (including $FFE3 = VSYNC), return stub, full errno table |
| C5 | [[rp6502-abi]] | Fastcall ABI: XSTACK, short stacking, bulk XRAM transfer, RIA_SPIN pattern |
| C6 | [[xram]] | 64 K extended RAM inside RIA; how auto-increment windows RW0/RW1 work |
| C7 | [[pix-bus]] | 5-wire DDR broadcast bus from RIA to VGA and other PIX devices |
| C8 | [[xreg]] | Extended register config: `xreg(device, channel, addr, val)` — how you configure hardware |
| C9 | [[api-opcodes]] | Complete OS call dispatch (op-codes 0x01–0x2E): every available OS function |
| C10 | [[rp6502-os]] | Protected OS inside RIA: POSIX-like API, memory model, errno, process lifecycle |
| C11 | [[rp6502-os-docs]] | Full OS API reference: `open`, `read`, `write`, `chdir`, `clock_gettime`, etc. |
| C12 | [[rom-file-format]] | `.rp6502` shebang + asset chunks; named ROM-asset filesystem |
| C13 | [[launcher]] | Process manager hook for persistent shell + native-OS boot pattern |
| C14 | [[exec-api]] | `ria_execl()` process replacement; argc/argv opt-in; device paths |
| C15 | [[rp6502-ria-docs]] | Full RIA firmware reference: monitor, PIX, XRAM, input, audio, NFC |
| C16 | [[rp6502-vga]] | VGA module overview: 3-plane scanline video, ANSI terminal |
| C17 | [[rp6502-vga-docs]] | VGA firmware reference: 6 modes, control channel, canvas/mode config structs |
| C18 | [[rp6502-ria-w]] | Wireless RIA overview: WiFi, BLE HID, Hayes modem — hardware entity |
| C19 | [[ria-w-networking]] | All network features in depth: WiFi config, NTP, BLE, telnet console, AT command set |
| C20 | [[rp6502-ria-w-docs]] | Wireless additions firmware reference: complete SET command reference |

---

## Track D — Software Development

*Goal: write, build, and run programs on the RP6502.*
*Read Track C (at least C1–C14) first.*

| Step | Page | What you learn |
| ---  | ---  | ---            |
| D1 | [[toolchain-setup]] | Install cc65 (or llvm-mos), create a project, CMake macro reference, minimal C + ASM programs |
| D2 | [[cc65]] | cc65 cross-development: compiler, assembler, linker; primary toolchain |
| D3 | [[cc65-rp6502-platform]] | Official cc65 platform docs: C runtime memory layout, stack at $FEFF, `rp6502.h` header — **authoritative** |
| D4 | [[llvm-mos]] | LLVM-MOS alternative: C++, floats, stronger optimisation; when to choose it over cc65 |
| D5 | [[vscode-cc65]] | VSCode + cc65 project template: setup, CMake macros, hello-world |
| D6 | [[vscode-llvm-mos]] | VSCode + llvm-mos template: PATH fix, CMake structure |
| D7 | [[examples]] | Official examples repo: ~20 programs covering every major API; canonical reference |
| D8 | [[vga-display-modes]] | 6 VGA modes: canvas selection, config structs, color depths, layer compositing |
| D9 | [[vga-graphics]] | Graphics techniques: BGAR5515 pixel format, mode-4 affine sprites, dual-port XRAM writes |
| D10 | [[game-loop-patterns]] | 60 Hz game loop: VSYNC polling, interrupt-driven sync, frame budget, double-buffering |
| D11 | [[via-programming]] | Practical VIA programming: GPIO setup, T1/T2 timer interrupts, shift register, software RTC |
| D12 | [[programmable-sound-generator]] | PSG: 8 channels, 5 waveforms, ADSR, stereo pan; how xreg drives audio |
| D13 | [[ezpsg]] | ezpsg library: high-level music tracker and polyphonic note scheduler on top of PSG |
| D14 | [[opl2-fm-synth]] | OPL2 FM synthesis (AdLib/Sound Blaster compatible): firmware-only, no hardware change |
| D15 | [[gamepad-input]] | `xreg_ria_gamepad()`, 10-byte-per-player data layout, 4 players, analog axes |
| D16 | [[fatfs]] | FatFs over USB MSC: FAT32, 8 open files max, directory API, code-page interaction |
| D17 | [[code-pages]] | CP437/CP850 glyph sets, FAT short-name encoding, 8.3 filenames |
| D18 | [[rtc]] | Real-time clock via POSIX `time()`/`gmtime()`; NTP on RIA-W |
| D19 | [[nfc]] | NFC device API: `open("NFC:", …)`, NDEF TLV read/write |
| D20 | [[ehbasic]] | EhBASIC 2.22p5: BASIC interpreter, LOAD/SAVE via OS, SET BOOT BASIC |
| D21 | [[adventure]] | Colossal Cave Adventure port: DATADIR→"ROM:" pattern, cc65 toolchain in practice |

---

## Community projects — what others built

Once you can write programs, explore what the community has made. These pages show real-world RP6502 programming patterns.

| Page | What it is |
| ---  | ---        |
| [[razemos]] | razemOS — native 65C02 OS by voidas_pl; kernel below $8000, built with cc65, exec pattern, ROM self-update |
| [[rptracker]] | OPL2 music tracker by jasonr1100 — 9 channels, 256 patches, CP437 UI, save/load |
| [[ehbasic]] | EhBASIC 2.22p5 — how the BASIC I/O glue integrates with the OS |
| [[community-projects]] | Full catalogue: games, demos, utilities, hardware expansions |

---

## YouTube companion path

Watch these episodes in order as a complement to the wiki pages. They show the *why* and the design evolution, which the docs don't.

| Episode | Wiki page | Covers |
| ---     | ---       | ---    |
| Ep1 | [[yt-ep01-8bit-retro-computer]] | Project intro, breadboard prototype |
| Ep2 | [[yt-ep02-pio-and-dma]] | Dual-Pico pivot; PIO+DMA 6502 read path |
| Ep3 | [[yt-ep03-writing-to-pico]] | Write path; glue logic; RIA name coined |
| Ep4 | [[yt-ep04-picocomputer-hello]] | First Hello World; fast-load pattern |
| Ep6 | [[yt-ep06-roms-filesystem]] | ROM concept; first USB-drive 6502 load |
| Ep7 | [[yt-ep07-operating-system]] | OS emergence; Colossal Cave demo |
| Ep8 | [[yt-ep08-vga-pix-bus]] | PIX bus design; DMA priority |
| Ep9 | [[yt-ep09-c-programming-setup]] | cc65 + VSCode workflow |
| Ep12 | [[yt-ep12-fonts-vsync]] | v0.1 release; VSYNC backchannel |
| Ep13 | [[yt-ep13-graphics-programming]] | Canvas/mode/xreg; 3-plane compositing |
| Ep16 | [[yt-ep16-psg-intro]] | PSG intro; music tracker |
| Ep18 | [[yt-ep18-llvm-mos]] | cc65 vs LLVM-MOS benchmark |
| Ep19 | [[yt-ep19-game-of-life]] | Game of Life: full coding walkthrough |
| Ep20 | [[yt-ep20-bbs]] | Pi Pico 2 upgrade; WiFi BBS |
| Ep21 | [[yt-ep21-ai-programming]] | AI-assisted development tips |
| Ep22 | [[yt-ep22-graphics-sound-demos]] | Community demos; OPL2 origin |

---

## Suggested combined learning path

If you have no prior 6502 experience and want to write a real RP6502 program (e.g. a simple game):

```
Orientation: what-does-ria-do → getting-started   # 30 minutes
A1 → A2 → A3            # CPU basics — 1-2 sessions
B1 → B2 → B3            # Board overview + build guide — 1 session
A4 → A5 → A6            # Stack, subroutines, interrupts — 1-2 sessions
C1 → C2 → C4 → C5 → C6 # RIA, monitor, registers, ABI — 1 session
D1 → D2 → D3 → D5       # Toolchain + VSCode — 1 session
C9 → C10 → C11          # OS API — 1 session
D7                       # Examples repo — ongoing reference
D8 → D9 → D10           # VGA graphics + game loop — when ready for video
D11                      # VIA timers — when you need hardware timing
D12 → D13               # Audio — when ready for sound
A7 → A8 → A9            # Arithmetic + data structures — as needed
```

For someone who **already knows 6502**: start at B1, proceed through B, C, D in order. Read the three orientation syntheses first.

For someone who wants to **understand the firmware internals** (PIO, DMA, RP2350):
- [[pio-architecture]] → [[pioasm]] → [[dma-controller]] → [[hstx]] → [[rp2040-clocks]]
- Also: [[quadros-rp2040]] and [[fairhead-pico-c]] source summaries.

For **wireless/networking** features (WiFi, telnet, Hayes modem):
- C18 → C19 → C20, then [[ria-w-networking]] for the full AT command reference.

---

## Reference pages to bookmark

These are dense references you will look up repeatedly while coding, not read once:

- [[ria-registers]] — every register address ($FFE0–$FFFF) and meaning, including VSYNC at $FFE3
- [[api-opcodes]] — all OS call op-codes
- [[65c02-instruction-set]] — full mnemonic table
- [[65c02-addressing-modes]] — cycle counts by mode
- [[6502-common-errors]] — check this when a bug seems inexplicable
- [[memory-map]] — what lives where in the 64 K address space
- [[cc65-rp6502-platform]] — authoritative cc65 C runtime memory layout
- [[monitor-reference]] — all monitor commands
- [[known-issues]] — RP2350 errata and firmware gotchas
- [[performance]] — storage and CPU throughput numbers
- [[usb-compatibility]] — controller recommendations before buying hardware
- [[roadmap]] — what's planned and why

---

## Related pages

- [[overview]]
- [[toolchain-setup]]
- [[examples]]
- [[version-history]]
- [[community-projects]]
