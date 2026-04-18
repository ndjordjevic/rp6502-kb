# Wiki Index

Catalog of all pages in this wiki. Updated by Claude at the end of every session.
When answering a query, read this file first to find relevant pages, then drill in.

## Sources

*Pages summarizing raw source documents.*

| Page | Description |
| --- | --- |
| [[picocomputer-intro]] | Landing page: project pitch, specs, links to all subsystems |
| [[hardware]] | Build guide, schematic link, full BOM, parts substitution rules |
| [[schematic-2023]] | 2023-06-07 KiCad schematic (Rev A = Rev B electrically): connectors, glue logic, VGA DAC, audio circuit |
| [[rp6502-ria-docs]] | RIA firmware reference: monitor, PIX, XRAM, input, audio, NFC, ROM format |
| [[rp6502-ria-w-docs]] | Wireless additions: WiFi setup, NTP, Hayes modem, BLE pairing |
| [[rp6502-vga-docs]] | VGA module: 3-plane scanline video, 6 modes, control channel, ANSI terminal |
| [[rp6502-os-docs]] | Protected OS: memory map, ABI, full POSIX-flavored API surface |
| [[rp6502-github-repo]] | Monorepo source at commit 368ed8e: complete API op-codes, register map, GPIO pinout, PIO layout |
| [[release-notes]] | All 23 releases v0.1–v0.23: feature introduction dates, breaking changes, known issues |
| [[quadros-rp2040]] | "Knowing the RP2040" (Quadros, 2022): hardware reference — architecture, PIO ISA, GPIO, interrupts, dual-core/SIO, DMA, USB, clocks, UART, SPI (all planned chapters ingested) |
| [[fairhead-pico-c]] | "Programming the Raspberry Pi Pico/W in C" (Fairhead, 3rd ed. 2025): SDK programming — PIO, GPIO, multicore, FreeRTOS, WiFi, SPI, UART (all planned chapters ingested) |
| [[pico-c-sdk]] | Raspberry Pi Pico-series C/C++ SDK (RP-009085-KB-1, 2025): official API reference — function signatures, PIOASM encoding, RP2040/RP2350 compat table; all 14 sessions ingested ✅ |
| [[rp2350-datasheet]] | RP2350 datasheet (RP-008373-DS-2, 2025-07-29): authoritative RP2350 hardware reference — SIO/TMDS, clocks/LPOSC, GPIO F0–F11, PIO v1, DMA (16-ch), USB, UART, SPI, HSTX, errata E1–E28; all 14 sessions ingested ✅ |
| [[w65c02s-datasheet]] | W65C02S datasheet (WDC, Feb 2024, 32 pp.): official CPU reference — 70 instructions, 16 addressing modes, 212 opcodes, pin functions, AC/DC timing, NMOS-vs-CMOS caveats |
| [[leventhal-6502-assembly]] | *6502 Assembly Language Programming, 2nd Ed.* (Leventhal, 1986): definitive 6502 programmer's reference — 65C02 enhancements (Ch.17), interrupts, subroutines, string/arithmetic/table idioms |
| [[leventhal-subroutines]] | *6502 Assembly Language Subroutines* (Leventhal & Saville, 1982): emulating missing instructions, common errors, 16-bit arithmetic, 6522 VIA reference, subroutine library (60 routines w/ cycle counts) |
| [[wagner-assembly-lines]] | *Assembly Lines: The Complete Book* (Wagner/Torrence, 2014): pedagogical 6502 teaching scaffold — loops, branches, addressing modes, stack, arithmetic, shift/logical operators, BCD, relocatable code, 65C02 enhancements |
| [[zaks-programming-6502]] | *Programming the 6502* (Zaks, 4th Ed. 1983): systematic 6502 textbook — algorithm design methodology, improved multiply, subroutine parameter passing, data structures (linked list/tree/hash/merge), I/O scheduling (polling vs. interrupts) |
| [[youtube-playlist]] | Official "Picocomputer 6502" YouTube series (22 eps, 2022–2026): hub page + episode list |
| [[rumbledethumps-discord]] | Rumbledethumps Discord server exports: #chat (2022–2026, 1,015 msgs) — hardware tips, firmware internals, USB silicon bug, OPL2, community projects |
| [[community-wiki]] | Community wiki (2 pages): project directory + USB/BLE device compatibility |
| [[adventure]] | Colossal Cave Adventure port to RP6502: named ROM assets, DATADIR→"ROM:" pattern, cc65 toolchain |
| [[vscode-llvm-mos]] | Official llvm-mos VSCode project template: setup steps, PATH conflict fix, CMake structure |
| [[vscode-cc65]] | Official cc65 VSCode project template: setup steps (Linux/Windows), CMake macros, hello-world C + ASM |
| [[pico-extras]] | picocomputer fork of raspberrypi/pico-extras: two mode-change bug fixes (memory leak + debug printf) for RP6502-VGA |
| [[ehbasic-repo]] | picocomputer/ehbasic repo: EhBASIC 2.22p5 port — OS glue layer, memory layout, LOAD/SAVE, IRQ pattern |
| [[examples]] | Official picocomputer/examples repo: ~20 C programs covering VGA modes, audio PSG, gamepad, NFC, FatFS, exec, benchmarking |
| [[yt-ep01-8bit-retro-computer]] | Ep1: series intro, breadboard with 12 glue chips, USB/VGA working |
| [[yt-ep02-pio-and-dma]] | Ep2: dual-Pico pivot; PIO+DMA 6502 read path; 8 MHz achieved |
| [[yt-ep03-writing-to-pico]] | Ep3: write path; glue logic; AC-chip discovery; RIA name coined |
| [[yt-ep04-picocomputer-hello]] | Ep4: first Hello World demo; fast-load pattern prototype; schematic release |
| [[yt-ep06-roms-filesystem]] | Ep6: FatFs vs littlefs rationale; ROM concept introduced; first USB-drive 6502 load |
| [[yt-ep07-operating-system]] | Ep7: OS emergence retrospective; "32 bytes is all I ask"; Colossal Cave Adventure demo |
| [[yt-ep08-vga-pix-bus]] | Ep8: PIX bus design (DDR 4-wire); PIO resource cost; DMA priority hierarchy |
| [[yt-ep09-c-programming-setup]] | Ep9: cc65 + VSCode template; Ctrl+Shift+B workflow; rp6502.py tool |
| [[yt-ep10-diy-build]] | Ep10: through-hole PCB assembly; Founders Edition boards; 3-phase bring-up |
| [[yt-ep11-no-soldering]] | Ep11: PCBWay single-unit manufacturing; no-soldering assembly |
| [[yt-ep12-fonts-vsync]] | Ep12: v0.1 release; code pages; VSYNC backchannel over reversed UART TX |
| [[yt-ep13-graphics-programming]] | Ep13: canvas/mode/xreg; 3-plane compositing; scanline partition; VSYNC scrolling |
| [[yt-ep14-usb-mouse]] | Ep14: 3 input modes; fgets() added; paint program demo |
| [[yt-ep15-asset-management]] | Ep15: CMake asset workflow; sprites with affine transforms; help-text shebang |
| [[yt-ep16-psg-intro]] | Ep16: PSG intro — 8 channels, 5 waveforms, ADSR, PWM; music tracker |
| [[yt-ep17-basics-of-basic]] | Ep17: EhBASIC install; SET BOOT BASIC; reset vs. reboot; RND quirk |
| [[yt-ep18-llvm-mos]] | Ep18: cc65 vs LLVM-MOS comparison; performance benchmark |
| [[yt-ep19-game-of-life]] | Ep19: Game of Life coding walkthrough; 640×480 monochrome bitmap |
| [[yt-ep20-bbs]] | Ep20: Pi Pico 2 upgrade; WiFi BBS access; NTP+DST |
| [[yt-ep21-ai-programming]] | Ep21: GitHub Copilot demos; "AI loves ignoring the docs" |
| [[yt-ep22-graphics-sound-demos]] | Ep22: community demos; OPL2 FM synth origin story; music tracker |

## Entities

*Named things: boards, chips, signals, buses, firmware variants.*

| Page | Description |
| --- | --- |
| [[rp6502-board]] | Reference PCB (Rev B): 150×100 mm, 8 ICs, 100% through-hole |
| [[w65c02s]] | The actual 65C02 CPU (WDC, U1, 0.1–8.0 MHz) |
| [[6522-via]] | 6522 VIA (Versatile Interface Adapter): full register reference — Port A/B, DDR, PCR, IER, IFR, ACR, T1/T2 timers, Shift Register; typical init sequence; Port A vs B differences |
| [[w65c22s]] | 65C22 VIA at `$FFD0-$FFDF` (WDC, U5) |
| [[rp6502-ria]] | RP6502 Interface Adapter: Pi Pico 2 + RIA firmware. Required. |
| [[rp6502-ria-w]] | Wireless RIA superset: WiFi 4 + BLE HID + Hayes modem |
| [[rp6502-vga]] | Optional Pi Pico 2 + VGA firmware video adapter |
| [[rp6502-os]] | 32-bit protected OS running inside the RIA (POSIX-like API) |
| [[rp2350]] | RP2350 microcontroller: dual Cortex-M33 @ 150 MHz, 520 KB SRAM, 3 PIO blocks, TMDS encoder, HSTX; powers Pi Pico 2 |
| [[cc65]] | cc65 cross-development package: C compiler + assembler + linker for 6502; primary Picocomputer toolchain since Ep9 |
| [[llvm-mos]] | llvm-mos: LLVM fork for 6502 — C++/floats/64-bit; second supported Picocomputer toolchain; stronger optimization |
| [[ezpsg]] | ezpsg library: high-level tracker + polyphonic scheduler on top of the 8-channel RIA PSG |
| [[ehbasic]] | EhBASIC 2.22p5: BASIC interpreter for RP6502 — LOAD/SAVE via OS, ACIA simulation I/O, SET BOOT |

## Concepts

*Mechanisms and ideas: protocols, instruction sets, timing, modes.*

| Page | Description |
| --- | --- |
| [[memory-map]] | 6502 address space + extended XRAM space |
| [[pix-bus]] | 5-wire DDR broadcast bus between RIA and PIX devices, 32-bit frame format |
| [[xram]] | 64 K extended RAM inside the RIA, broadcast-replicated across PIX devices |
| [[xreg]] | The "extended register" config mechanism (`xreg(device, channel, addr, val)`) |
| [[rom-file-format]] | `.rp6502` shebang + asset chunks; named ROM-asset filesystem |
| [[rp6502-abi]] | Fastcall-style ABI: XSTACK, short stacking, bulk XRAM, RIA_SPIN |
| [[reset-model]] | RESB is a state, not a pulse; reboot ≠ reset; only the RIA may drive RESB |
| [[launcher]] | Process manager hook for persistent host ROM + native-OS boot pattern |
| [[ria-registers]] | Exact register addresses $FFE0–$FFFF, return stub, full errno table |
| [[api-opcodes]] | Complete OS call dispatch table (op-codes 0x01–0x2E) from main.c |
| [[pio-architecture]] | PIO state machine layout for 65C02 bus interface and PIX; RP2350 overclock; DMA-DREQ integration; dynamic program generation (`pio_encode_*` composition, full JMP variants, `pio_src_dest` enum, wait_pin vs wait_gpio); SM EXEC; v0/v1 ISA encoding; v1-only additions; `pio_interrupt_source` enum; compile-time macros; MOV STATUS type; multi-SM synchronization; sticky output; RP2350B GPIO base |
| [[pioasm]] | PIOASM assembler: complete directive reference, value/expression syntax, output pass-through, generated header structure, v0/v1 ISA opcode table |
| [[gpio-pinout]] | GPIO pin assignments for RIA/VGA Pico confirmed from source; RP2040/RP2350 function select tables |
| [[board-circuits]] | Glue logic functions (WE#, IORQ, IRQ merge), VGA DAC resistors, audio filter, dual power rail, connector signals |; full SDK API (pull state queries, PAD config, interrupt model, concurrency-safe gpio_put_masked, raw handler notes); 64-bit/bank-n RP2350 variants; Erratum E9 |
| [[hardware-irq]] | `hardware_irq` SDK: NVIC per-core semantics, IRQ number tables (RP2040 + RP2350), three handler-install patterns, priority model, user (software) IRQs |
| [[dual-core-sio]] | Two-core ARM model, SIO FIFOs (RP2040: 8 deep, RP2350: 4 deep), lockout mechanism, doorbell API (RP2350), hardware spinlocks (32 locks, number assignment table, RP2350-E2 erratum), memory barriers, processor events, interrupt control, atomic GPIO, full `pico_multicore` + `pico_sync` SDK (critical_section, mutex, recursive_mutex, semaphore with all timeout variants) |
| [[rp2040-memory]] | RP2040 memory types (ROM/SRAM/Flash), SRAM banking, XIP, full APB/AHB address map |
| [[dma-controller]] | 16-channel DMA (RP2350) / 12-channel (RP2040): DREQ tables, control blocks, chaining, CRC sniffing, RP2350 encoded_transfer_count/endless/self-trigger/4-IRQ-lines, SDK API |
| [[usb-controller]] | RP2040/RP2350 USB 1.1 controller: host/device modes, HID boot protocol, CDC VCP, TinyUSB API, RIA host usage; RP2350 PHY_ISO startup requirement |
| [[rp2040-clocks]] | RP2040/RP2350 clock subsystem: ROSC/XOSC/LPOSC/PLLs, clock domains, divisor precision, resus; 256 MHz overclock; `pll_init`/`pll_deinit` SDK functions; Timer (RP2350 two instances, 64-bit µs, full alarm API, compile-time macros); full `pico_time` API (absolute_time_t, sleep/busy_wait, alarm pools, repeating timers); Watchdog, RTC |
| [[rp2040-uart]] | RP2040 UARTs: framing, 32-entry FIFOs + error flags, fractional baud rate, interrupts, hardware flow control, full SDK API (incl. macros `UART_FUNCSEL_NUM` etc.), `uart_deinit`; RIA uses UART1/GPIO4-5/115200 |
| [[rp2040-spi]] | RP2040 SPI: master/slave, 4–16-bit words, CPOL/CPHA modes, manual SS in master mode, DMA DREQ macros, full SDK API (`spi_init`/`spi_deinit`/`spi_get_baudrate`/`spi_get_index`/blocking transfer variants); RIA uses USB MSC (not SPI) for storage |
| [[sdk-architecture]] | Pico SDK build model: CMake INTERFACE libraries, library tiers, hardware claiming, builder pattern, RP2040/RP2350 platform split |
| [[hstx]] | RP2350 HSTX peripheral: DDR serial output up to 300 Mb/s/pin, async FIFO, output shift register, bit crossbar, clock generator, command expander (RAW/TMDS/REPEAT opcodes), PIO-coupled mode, DVI/TMDS example; used by RP6502 VGA firmware |
| [[code-pages]] | Code page 437/850/855: glyph-set swap + FAT short-name encoding; CP850 default; 8.3 fallback with ~1 suffix |
| [[fatfs]] | FatFs r0.15+ filesystem driver: FAT32 over USB MSC, ExFAT ready, 8 files+dirs max open; directory API (f_opendir/f_readdir/f_closedir); code-page/short-name interaction; littlefs history |
| [[vga-display-modes]] | VGA modes 0–5: canvas selection, config structs, color depths, layer compositing, VSYNC sync pattern |
| [[vga-graphics]] | VGA graphics techniques: BGAR5515 format, mode-4 sprites, affine transforms, dual-port writes, pixel addressing |
| [[gamepad-input]] | Gamepad input: `xreg_ria_gamepad()`, 10-byte-per-player data layout, 4 players, analog axes, compatibility notes |
| [[rtc]] | Real-time clock via standard POSIX time() / gmtime() / localtime(); NTP sync on RIA-W |
| [[nfc]] | NFC device API: `open("NFC:", …)`, binary command/response protocol, NDEF TLV read/write |
| [[exec-api]] | Process exec: `ria_execl()`, argc/argv opt-in, device paths (NFC:, TTY:, AT:, ROM:) |
| [[programmable-sound-generator]] | PSG in RIA firmware: 8 channels, 5 waveforms, variable duty cycle, ADSR envelope, stereo pan, PWM physical layer; ezpsg library; first in v0.6 |
| [[opl2-fm-synth]] | OPL2 FM synthesizer (Yamaha YM3812-compatible) in RIA firmware: same as AdLib/Sound Blaster; firmware-flash only; added v0.16 |
| [[65c02-instruction-set]] | W65C02S instruction set: 70 mnemonics, 212 opcodes, new CMOS instructions (BBR/BBS, BRA, PHX/PHY/PLX/PLY, RMB/SMB, STP, STZ, TRB/TSB, WAI), reserved-NOP table; Ch.17 Leventhal pedagogical notes; Ch.33 Wagner beginner perspective |
| [[65c02-addressing-modes]] | W65C02S 16 addressing modes with cycle/byte counts; new `(zp)` and `(a,x)` modes vs NMOS 6502; X vs Y non-interchangeability in indirect modes (Wagner Ch.7) |
| [[6502-interrupt-patterns]] | 6502 CPU interrupt system: IRQ/NMI/BRK/RESET vectors, ISR register save/restore, polling dispatch, RTI semantics, ISR design guidelines, 6522 VIA unbuffered interrupt I/O (PINTIO), ring-buffer buffered I/O, real-time clock/calendar (Ch. 11B/11D Leventhal 1982) |
| [[6502-subroutine-conventions]] | JSR/RTS mechanics, four parameter-passing methods (registers / ZP pseudo-regs / inline / stack), Leventhal 1982 formal 10-field template, reentrancy, relocatability |
| [[6502-application-snippets]] | Reusable 6502 patterns: string length, blank-skip, hex↔ASCII, BCD↔7-segment, pattern match; Leventhal 1982 Ch.4 code-conversion routines; Ch.8 string manipulation (STRCMP, CONCAT, POS); Zaks Ch.8 memory clear, bracket test, parity, max/sum/checksum/zero-count |
| [[6502-programming-idioms]] | 6502 arithmetic idioms: multi-precision binary/BCD addition, 8-bit multiply/divide (incl. Zaks optimised multiply), 16-bit add/sub/mul/div/cmp; bit manipulation; shift/logical operators; BCD mode; carry-chain rules; subroutine parameter passing (3 methods); 14 6502 quirks |
| [[6502-data-structures]] | 6502 data structure patterns: lists, queues, sort, jump tables; Leventhal 1982 array/table idioms; Zaks Ch.9 linked lists, circular list, trees, doubly-linked, binary search (O(log N)), hashing (XOR+rotate, 80% rule), merge algorithm |
| [[6502-io-patterns]] | Terminal line I/O (RDLINE/WRLINE), parity (GEPRTY/CKPRTY), CRC-16 (IBM BSC, X¹⁶+X¹⁵+X²+1), and device-independent I/O handler (IOHDLR with I/O Control Block + device table linked list) — from Leventhal 1982 Ch. 10 |
| [[6502-emulated-instructions]] | Emulating missing 6502 instructions: 16-bit add/sub, arithmetic shifts, multi-byte shifts, extended branches, indirect addressing, decimal operations |
| [[6502-common-errors]] | Systematic catalogue of 6502 bugs: carry misuse, flag side effects, addressing confusion, decimal mode hazards, loop errors, ISR pitfalls |
| [[learning-6502-assembly]] | Beginner 6502 scaffold: registers, Status Register flags, binary numbers, counter/loop patterns (BNE/BEQ), all branch instructions, addressing modes overview; X vs Y non-interchangeability |
| [[6502-stack-and-subroutines]] | 6502 stack mechanics: LIFO page-1 stack ($0100–$01FF), PHA/PLA rules, PHX/PHY/PLX/PLY (65C02), JSR/RTS operation (PC−1 quirk), register save/restore idioms, stack depth limits |
| [[6502-relocatable-and-self-modifying]] | Techniques for position-independent 6502 code: forced branch (CLV+BVC, BRA on 65C02), JSR simulation, indirect JMP dispatch tables, JMP page-boundary bug (NMOS) fixed on 65C02, self-modifying code patterns |

## Inbox

*Rough notes and planning documents awaiting full organization.*

| Page | Description |
| --- | --- |

## Syntheses

*Answers to queries worth keeping; comparisons; analyses.*

| Page | Description |
| --- | --- |

## Topics

*Operational pages: getting-started, known-issues, toolchain guides.*

| Page | Description |
| --- | --- |
| [[toolchain-setup]] | cc65 (and llvm-mos) install, project creation, CMake macro reference, minimal C + ASM programs |
| [[overview]] | Living synthesis across all sources (revised after every ingest) |
| [[version-history]] | Narrative history from v0.1 (2023) to v0.24 (2026), organized by era |
| [[known-issues]] | Bugs, workarounds, and things to watch out for — from release notes + full RP2350 silicon errata (E1–E28) + Discord community reports |
| [[development-history]] | Chronological narrative of RP6502 design evolution across 5 eras (late 2022–2026) |
| [[community-projects]] | Notable games, demos, tools, and hardware expansions built by community members |
| [[usb-compatibility]] | USB and BLE device compatibility: known-incompatible categories + recommended controllers |
| [[performance]] | Storage and CPU throughput benchmarks: USB MSC read/write speeds, XRAM load rates, PHI2 clock scaling |
