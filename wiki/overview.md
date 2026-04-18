---
type: topic
tags: [rp6502, overview]
updated: 2026-04-18
---

# RP6502 Wiki — Overview

**Summary**: Living synthesis of everything this wiki currently knows about the RP6502 Picocomputer ecosystem.

*This page is revised by Claude at the end of every ingest session.*

---

## What is RP6502?

The **RP6502** is a homebrew, modular 8-bit computer designed around a real WDC 65C02. The reference design is the **Picocomputer 6502** ([[rp6502-board]]) — a 150×100 mm, 100% through-hole board with eight ICs that you can build for ~$100. Project tagline: *"Pure 6502. No governor. No speed limits."*

The cleverness of the design is that *all* of the system services normally provided by glue chips — clock generation, reset control, I/O, video, audio, storage, networking, RTC, even the "OS" — are pushed onto a single **Raspberry Pi Pico 2** running custom firmware called the **RIA** (RP6502 Interface Adapter). The 6502 sees a bare 64 K address space with the RIA's 32 registers at `$FFE0-$FFFF` and a familiar [[w65c22s|65C22 VIA]] at `$FFD0-$FFDF`. Every program starts from zero — no ROM, no reserved zero page, no monitor stub in RAM.

## Hardware components

| Module | Required? | Built from | Role |
| --- | --- | --- | --- |
| [[rp6502-board]] | Reference PCB | 8 ICs | Carries CPU + VIA + glue + 2 Picos |
| [[w65c02s]] | Yes | WDC chip @ U1 | The actual 6502 (0.1–8.0 MHz) |
| [[w65c22s]] | Yes | WDC chip @ U5 | VIA at `$FFD0-$FFDF`, exposes J1 GPIO |
| [[rp6502-ria]] | **Yes (only required module)** | Pi Pico 2 + RIA firmware @ U2 | Owns PHI2 and RESB; provides everything the 6502 doesn't have |
| [[rp6502-ria-w]] | (replaces RIA on reference board) | Pi Pico 2 W + RIA-W firmware @ U2 | Strict superset of RIA: WiFi 4, BLE HID, NTP, Hayes modem |
| [[rp6502-vga]] | Optional | Pi Pico 2 + VGA firmware @ U4 | Scanline-programmable 3-plane video adapter, ANSI terminal |

The two Picos are connected by a custom 5-wire **[[pix-bus]]** (Pico Information Exchange).

## How the pieces talk

- **6502 ↔ RIA**: classic memory-mapped I/O at `$FFE0-$FFFF`. The 6502 stores an op-code into `RIA_OP`, polls `RIA_BUSY` (or `JSR RIA_SPIN`), then reads results from `RIA_A` / `RIA_X` / `RIA_SREG`. This is the [[rp6502-abi]] — a fastcall-style ABI based on cc65 internals.
- **6502 ↔ XRAM**: `RIA_RW0` / `RIA_RW1` are auto-incrementing windows into 64 K of [[xram]] that lives inside the RIA, not on the 6502 bus.
- **RIA → VGA (and other PIX devices)**: every XRAM write is broadcast as a 32-bit [[pix-bus]] frame. Each PIX device caches the parts of XRAM it cares about. Devices are configured via [[xreg]] — "extended register" writes that say "install your virtual hardware at this XRAM address."
- **VGA → RIA**: PIX is one-way, so the VGA Pico reuses its **UART Tx pin** as a backchannel for VSYNC ticks and op acks.

This shared-XRAM-with-replicas design is also why the Picocomputer **has no paged memory**: bulk XRAM operations move ~512 KB/s, so a full 64 K reload is ~150 ms. Disk effectively *is* RAM.

## Firmware variants

There are three Pico firmwares, all from the same monorepo:

- **RP6502-RIA** ([[rp6502-ria]]) — minimum viable, runs on a plain Pi Pico 2.
- **RP6502-RIA-W** ([[rp6502-ria-w]]) — same plus WiFi/BLE/Hayes/NTP, runs on a Pi Pico 2 W. Used on the reference board's U2 slot.
- **RP6502-VGA** ([[rp6502-vga]]) — video adapter, runs on a plain Pi Pico 2. Used on the reference board's U4 slot.

## Software stack

- The [[rp6502-os]] is a 32-bit protected OS that **runs inside the RIA**, not on the 6502, and uses zero 6502 RAM. From the 6502 it looks like a tray of POSIX-flavored functions: `open`, `read`, `write`, `chdir`, `clock_gettime`, `xreg`, `ria_execl`, `exit`, etc.
- **C support**: both [[cc65]] and [[llvm-mos]] toolchains are first-class. The OS errno table can be switched between the two via `RIA_ATTR_ERRNO_OPT`.
- **Programs ship as `.rp6502` ROMs** — text shebang + binary asset chunks. See [[rom-file-format]]. Loaded with the monitor's `load`, persisted with `install`, auto-booted via `set boot`.
- The OS supports a **[[launcher]]** mechanism: a small ROM can register itself as the persistent shell that the process manager re-runs whenever any other ROM exits. This is the foundation for fault-tolerant boot of a native 6502 OS on top.
- **NFC**: tap a programmed NTAG215 card and the named ROM file loads. Implemented with a PN532 over USB.

## Audio

Two coexisting synthesizers run inside the RIA firmware, sharing the same PWM → RC filter → audio jack path:

- **[[programmable-sound-generator]]** — 8 channels, 5 waveforms, ADSR envelope, stereo pan. Introduced v0.6.
- **[[opl2-fm-synth]]** — YM3812-compatible FM synthesis (AdLib / Sound Blaster). Added v0.16. Firmware-only — no hardware change needed.

Both are driven through [[xreg]] + an XRAM-resident register image; programs write into XRAM and the RIA streams the audio on its side.

## RP2350 silicon notes (Pi Pico 2)

The RP6502 VGA module uses the Pi Pico 2 (RP2350), and the RIA-W uses the Pi Pico 2 W. Key RP2350 differences from RP2040 relevant to RP6502 development:

- **HSTX** ([[hstx]]): new RP2350 peripheral for high-speed serial video output. Drives DDR serial at up to 300 Mb/s/pin via a bit crossbar and hardware TMDS encoder. Used by the RP6502-VGA firmware for DVI output.
- **DMA**: 16 channels (vs 12) and 4 IRQ lines (vs 2). New `TRANS_COUNT` MODE field and `INCR_READ/WRITE_REV` for bit-reversal. See [[dma-controller]].
- **USB PHY_ISO**: `MAIN_CTRL.PHY_ISO` resets to 1 on RP2350 — must clear before any USB use. RP2040 code that immediately enables the USB controller will hang. `clk_sys` must be **> 48 MHz** (not equal) when USB is active (RP2350-E12). See [[usb-controller]].
- **Silicon errata**: 28 documented errata (E1–E28). Most critical: E12 (USB), E5/E8 (DMA CHAIN_TO/ABORT), E2 (SIO spinlock), E1 (interpolator OVERF). Full list with workarounds: [[known-issues]] § RP2350 silicon errata.

## 6502 Programmer's library

The wiki now contains a layer of 6502 **programming knowledge** drawn from four books: Leventhal's *6502 Assembly Language Programming, 2nd Ed.* (1986), Leventhal's *6502 Assembly Language Subroutines* (1982), Roger Wagner's *Assembly Lines: The Complete Book* (2014), and Rodnay Zaks's *Programming the 6502, 4th Ed.* (1983). Together these form the RP6502 6502 programmer's library — Leventhal for depth (subroutine patterns), Wagner for accessibility (beginner tutorial), Zaks for methodology (algorithm and data-structure theory).

- **Beginner scaffold** ([[learning-6502-assembly]]): registers, Status Register flags, binary numbers, counter/loop patterns (BNE/BEQ), all 8 branch instructions with signed-distance table, addressing modes overview, X vs Y non-interchangeability in indirect modes. *Wagner-first framing — suitable for newcomers to 6502.*
- **Stack mechanics** ([[6502-stack-and-subroutines]]): $0100–$01FF LIFO layout, PHA/PLA/PHP/PLP rules, PHX/PHY/PLX/PLY (65C02), JSR saves PC−1, RTS adds 1 — the return-address-as-data-pointer pattern; register save/restore idioms (NMOS 4-instr vs 65C02 direct), stack depth limits; interrupt context. *Synthesised from Wagner Ch.9 + Leventhal.*
- **Relocatable and self-modifying code** ([[6502-relocatable-and-self-modifying]]): what makes 6502 code non-relocatable; forced branch patterns (CLV+BVC, CLC+BCC, BRA on 65C02); stepping technique; JSR simulation via stack push; indirect JMP dispatch tables; NMOS JMP page-boundary bug (fixed on 65C02); self-modifying code. *Synthesised from Wagner Ch.15.*

- **Instruction set enhancements** ([[65c02-instruction-set]]): all 65C02 additions over NMOS 6502 — `(zp)` indirect, `JMP (a,x)`, BRA, PHX/PHY/PLX/PLY, STZ, INC A/DEC A, TRB/TSB, SMB/RMB/BBR/BBS; decimal-flag-cleared-on-interrupt fix; JMP indirect page-boundary fix.
- **Interrupt system** ([[6502-interrupt-patterns]]): IRQ/NMI/BRK/RESET vectors, canonical 5-instruction register save/restore sequence, IRQ-vs-BRK distinguish via stack B-bit, polling dispatch, RTI semantics, ISR design rules; complete 6522 VIA interrupt-driven I/O pattern (PINTIO — 6 subroutines, single-character buffers, OIE unserviced-interrupt flag); ring-buffer pattern for high-throughput serial I/O; real-time clock/calendar ISR with tick-down chain, leap-year detection, 24-hour wrap.
- **Subroutine conventions** ([[6502-subroutine-conventions]]): JSR/RTS off-by-one mechanics, four parameter-passing methods (registers / ZP pseudo-registers / inline / stack), Leventhal 1982 formal 10-field documentation template, reentrancy, relocatability. Related to the XSTACK ABI ([[rp6502-abi]]).
- **Application snippets** ([[6502-application-snippets]]): string length, blank-skip, parity, hex↔ASCII, BCD-to-7-segment, pattern match; Leventhal code-conversion and string subroutines; **Zaks Ch.8**: memory clear (ZEROM, 5 cycles/byte), bracket test (range test via V+C flags), parity generation (ROL-based), ASCII↔BCD (AND #$0F / BCD-to-binary ×10 trick), find-max, 16-bit sum, EOR checksum, zero count.
- **Arithmetic idioms** ([[6502-programming-idioms]]): multi-precision binary/BCD addition, 8-bit multiply (standard shift-and-add; also Zaks optimised — 10 instr using accumulator as partial product), 8-bit divide, carry-chain rules, 14 6502 quirks quick reference; **Zaks**: subroutine parameter passing — 3 methods (registers/memory/stack) comparison + pointer-hybrid guideline. Extended with Leventhal 16-bit routines, Wagner shift/logical/BCD.
- **Data structures** ([[6502-data-structures]]): list/queue/sort/jump-table idioms from Leventhal; **Zaks Ch.9**: pointers and directories (two-level, pointer-per-block), linked lists (O(1) insert/delete), circular list (round-robin polling), queue (FIFO), trees, doubly-linked lists, binary search (O(log₂N) on sorted table), hashing (XOR+rotate, 80% fullness rule, sequential open addressing), merge algorithm for two pre-sorted tables.
- **I/O patterns** ([[6502-io-patterns]]): terminal line I/O — RDLINE (138B, Control-H/X editing, bell on overflow, platform-hook architecture for RDCHAR/WRCHAR/WRNEWL); WRLINE (37B); parity — GEPRTY (114 cycles, even parity in bit 7), CKPRTY (111 cycles, Carry flag); CRC-16 — ICRC16/CRC16/GCRC16 (IBM BSC polynomial, 302–454 cycles/byte); device-independent I/O — IOHDLR linked-list device table (I/O Control Block 7 bytes, device table entry 17 bytes, operations 0–6, INITIO+ADDDL management). *(from Leventhal 1982 Ch. 10)*
- **Emulated instructions** ([[6502-emulated-instructions]]): comprehensive catalogue of sequences emulating missing 6502 operations — 16-bit add/sub, arithmetic shift right, multi-byte shifts, extended branches, signed comparisons, indirect addressing, block move. Cross-reference table of all missing instructions and their idioms. *(from Leventhal 1982)*
- **Common errors** ([[6502-common-errors]]): systematic bug catalogue — Carry misuse (SBC/CMP/ADC all different conventions), flag side effects (BIT, STA, INC/DEC), addressing confusion, decimal mode hazards, off-by-one loops, uninitialised decimal flag, ISR save/restore errors. *(from Leventhal 1982)*

These pages answer *how to write 6502 code for RP6502* — patterns that map directly onto the OS ABI and the 65C02 silicon on the board.

## Examples repository — canonical API reference

The `picocomputer/examples` repo ([[examples]]) is the authoritative usage reference for every major RP6502 subsystem API. Key patterns documented:

- **VGA modes** ([[vga-display-modes]]): 6 compositable modes (console, text/tile, tile-bitmap, chunky-bitmap, affine sprites, multi-sprite). Selected via `xreg_vga_canvas()` + `xreg_vga_mode()`. All config structs live in XRAM.
- **VGA graphics** ([[vga-graphics]]): BGAR5515 pixel format; mode-4 affine transform (Q8 2×3 matrix); dual-port XRAM writes for high-throughput sprite position updates; mode-3 pixel addressing at 1/2/4/8/16 bpp.
- **Audio** ([[ezpsg]]): the `ezpsg` library wraps the 8-channel PSG into a music tracker with polyphonic note scheduling. `ezpsg_tick(tempo)` drives the engine; `ezpsg_play_note()` allocates channels by duration.
- **Gamepad** ([[gamepad-input]]): `xreg_ria_gamepad(addr)` exposes 4-player input as a 10-byte-per-player block in XRAM (hat/sticks/buttons/analog axes).
- **NFC** ([[nfc]]): `open("NFC:", O_RDWR)` returns a binary command/response fd for NDEF card read/write.
- **exec** ([[exec-api]]): `ria_execl()` replaces the running process; argc/argv requires an opt-in `argv_mem()` function.
- **FatFS directory API** ([[fatfs]]): `f_opendir`/`f_readdir`/`f_closedir`/`f_getfree`.
- **Storage benchmark** ([[performance]]): `write_xram`/`read_xram` through FatFS; typical USB drives 1–3 MB/s.

## Key open questions

1. **W65C02S WAI / STP** — the datasheet ([[w65c02s-datasheet]], Ch. 7) confirms WAI pulls RDY low and releases on any interrupt; the RIA currently busy-polls via a 32-byte `RIA_SPIN` stub. A WAI-based ABI could reduce power but would need an IRQB source on every RIA completion, which RP6502 firmware doesn't currently wire. The `ria_write` PIO generates PHI2 continuously; WAI would stall the 6502 in-place until IRQ fires.
2. **Maximum stable PHI2 margin** — the firmware sets 8 MHz as the max (`CPU_PHI2_MAX_KHZ 8000`). PIO timing comments say "good range narrows as PHI2 increases" — the exact electrical limit isn't documented.
3. **`cc65` and `llvm-mos` toolchain pages** — ✅ Created in Sessions 3–9. Both have first-class support (separate `lseek` op-codes 0x1A vs 0x1D, separate errno-opt); see [[cc65]] and [[llvm-mos]].
4. **VIA pinout / J1 GPIO header** — not in web docs or repo source; needs the KiCad schematic (`.kicad_sch` not in submodule). J1 is a 2×12 header but VIA PA/PB/CA/CB pin mapping is only in the schematic.
5. ~~**VGA GPIO full pinout**~~ ✅ Resolved from `scanvideo.c`: R=GPIO 6–10, G=GPIO 12–16, B=GPIO 17–21, HSYNC=GPIO 26, VSYNC=GPIO 27 (RGB555). See [[gpio-pinout]].

## Community project ecosystem

The `picocomputer/community` wiki ([[community-wiki]]) catalogs a growing ecosystem of community-built software and hardware. As of April 2026:

- **Games**: Star-Swarms (Galaxian), Tetricks (Tetris), Colossal Cave Adventure, Snake, Sliding Block Puzzle, Game of Life, Space Raiders, RP Mega Super Fighter, Mega Chopper
- **Applications**: ASCII text editor (TE), Home Monitor (RSS via AT commands)
- **BASIC**: EhBASIC runs the classic BASIC Computer Games book; EhBASIC+ prototype adds graphics
- **Utilities**: Wozmon, SMON (C64 monitor with single-step debugger), RP6502-Shell, parallax scrolling
- **Cases**: 3D-printed enclosure
- **Hardware**: jasonr1100's FPGA OPL2 card, tonyvr0759's 65816 breadboard variant, jjjacer's eInk laptop

USB/BLE compatibility is an important hardware constraint: XInput wired controllers are permanently disabled (TinyUSB quality issue on Pi Pico), Nintendo Switch Pro doesn't work even on Windows, and some USB hubs crash the stack. Recommended: Xbox One/Series via BLE or DS4/DS5 via USB. Full details: [[usb-compatibility]].

## EhBASIC — primary BASIC environment

[[ehbasic]] (EhBASIC 2.22p5) is the primary BASIC interpreter for RP6502. It integrates with RP6502-OS via the ACIA simulation registers (`RIA_TX`, `RIA_RX`, `RIA_READY` at `$FFE0–$FFE2`) for console I/O, and uses `open()`/`close()`/`read_xstack()`/`write_xstack()` for `LOAD`/`SAVE`. No custom BASIC extensions exist — the RP6502 port is a clean I/O glue layer over the unmodified EhBASIC 2.22p5 core. BASIC programs can be auto-started via `SET BOOT BASIC`.



- **Sources**: [[picocomputer-intro]] · [[hardware]] · [[rp6502-ria-docs]] · [[rp6502-ria-w-docs]] · [[rp6502-vga-docs]] · [[rp6502-os-docs]] · [[rp6502-github-repo]] · [[release-notes]] · [[quadros-rp2040]] · [[fairhead-pico-c]] · [[pico-c-sdk]] · [[rp2350-datasheet]] · [[w65c02s-datasheet]] · [[leventhal-6502-assembly]] · [[leventhal-subroutines]] · [[wagner-assembly-lines]] · [[zaks-programming-6502]] · [[youtube-playlist]] · [[rumbledethumps-discord]] · [[examples]] · [[community-wiki]] · [[ehbasic-repo]]
- **Entities**: [[rp6502-board]] · [[rp6502-ria]] · [[rp6502-ria-w]] · [[rp6502-vga]] · [[rp6502-os]] · [[w65c02s]] · [[w65c22s]] · [[6522-via]] · [[rp2350]] · [[cc65]] · [[llvm-mos]] · [[ezpsg]]
- **Concepts**: [[memory-map]] · [[pix-bus]] · [[xram]] · [[xreg]] · [[rom-file-format]] · [[rp6502-abi]] · [[reset-model]] · [[launcher]] · [[ria-registers]] · [[api-opcodes]] · [[vga-display-modes]] · [[vga-graphics]] · [[gamepad-input]] · [[rtc]] · [[nfc]] · [[exec-api]] · [[65c02-instruction-set]] · [[65c02-addressing-modes]] · [[6502-interrupt-patterns]] · [[6502-subroutine-conventions]] · [[6502-application-snippets]] · [[6502-programming-idioms]] · [[6502-data-structures]] · [[6502-emulated-instructions]] · [[6502-common-errors]] · [[6502-io-patterns]] · [[learning-6502-assembly]] · [[6502-stack-and-subroutines]] · [[6502-relocatable-and-self-modifying]] · [[pio-architecture]] · [[pioasm]] · [[gpio-pinout]] · [[hardware-irq]] · [[dual-core-sio]] · [[rp2040-memory]] · [[dma-controller]] · [[usb-controller]] · [[rp2040-clocks]] · [[rp2040-uart]] · [[rp2040-spi]] · [[sdk-architecture]] · [[hstx]] · [[code-pages]] · [[programmable-sound-generator]] · [[opl2-fm-synth]] · [[fatfs]]
- **Topics**: [[version-history]] · [[known-issues]] · [[development-history]] · [[community-projects]] · [[performance]]
