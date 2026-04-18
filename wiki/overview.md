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

The cleverness of the design is that *all* of the system services normally provided by glue chips — clock generation, reset control, I/O, video, audio, storage, networking, RTC, even the "OS" — are pushed onto a single **Raspberry Pi Pico 2** running custom firmware called the **RIA** (RP6502 Interface Adapter). The 6502 sees a bare 64 K address space with the RIA's 32 registers at `$FFE0-$FFFF` and a familiar 65C22 VIA at `$FFD0-$FFDF`. Every program starts from zero — no ROM, no reserved zero page, no monitor stub in RAM.

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

The wiki now contains a layer of 6502 **programming knowledge** drawn from Leventhal's *6502 Assembly Language Programming, 2nd Ed.* (1986), the definitive reference for practical 65C02 coding.

- **Instruction set enhancements** ([[65c02-instruction-set]]): all 65C02 additions over NMOS 6502 — `(zp)` indirect, `JMP (a,x)`, BRA, PHX/PHY/PLX/PLY, STZ, INC A/DEC A, TRB/TSB, SMB/RMB/BBR/BBS; decimal-flag-cleared-on-interrupt fix; JMP indirect page-boundary fix.
- **Interrupt system** ([[6502-interrupt-patterns]]): IRQ/NMI/BRK/RESET vectors, canonical 5-instruction register save/restore sequence, IRQ-vs-BRK distinguish via stack B-bit, polling dispatch, RTI semantics, ISR design rules.
- **Subroutine conventions** ([[6502-subroutine-conventions]]): JSR/RTS off-by-one mechanics, three parameter-passing methods (registers / ZP pseudo-registers / stack), reentrancy, relocatability. Related to the XSTACK ABI ([[rp6502-abi]]).
- **Application snippets** ([[6502-application-snippets]]): string length, blank-skip, parity, hex↔ASCII, BCD-to-7-segment, pattern match.
- **Arithmetic idioms** ([[6502-programming-idioms]]): multi-precision binary/BCD addition, 8-bit multiply (shift-and-add), 8-bit divide (shift-and-subtract), carry-chain rules.
- **Data structures** ([[6502-data-structures]]): unordered/ordered list operations, circular queue, bubble sort, jump tables (pre- and 65C02-style).

These pages answer *how to write 6502 code for RP6502* — patterns that map directly onto the OS ABI and the 65C02 silicon on the board.

## Key open questions

1. **W65C02S WAI / STP** — the datasheet ([[w65c02s-datasheet]], Ch. 7) confirms WAI pulls RDY low and releases on any interrupt; the RIA currently busy-polls via a 32-byte `RIA_SPIN` stub. A WAI-based ABI could reduce power but would need an IRQB source on every RIA completion, which RP6502 firmware doesn't currently wire. The `ria_write` PIO generates PHI2 continuously; WAI would stall the 6502 in-place until IRQ fires.
2. **Maximum stable PHI2 margin** — the firmware sets 8 MHz as the max (`CPU_PHI2_MAX_KHZ 8000`). PIO timing comments say "good range narrows as PHI2 increases" — the exact electrical limit isn't documented.
3. **`cc65` and `llvm-mos` toolchain pages** — ✅ Created in Sessions 3–9. Both have first-class support (separate `lseek` op-codes 0x1A vs 0x1D, separate errno-opt); see [[cc65]] and [[llvm-mos]].
4. **VIA pinout / J1 GPIO header** — not in web docs or repo source; needs the schematic PDF.
5. **VGA GPIO full pinout** — only GPIO 11 (PHI2 in) and GPIO 0–3 (PIX in) confirmed from VGA source. DAC output pins, sync signals not yet read.

## Hub pages

- **Sources**: [[picocomputer-intro]] · [[hardware]] · [[rp6502-ria-docs]] · [[rp6502-ria-w-docs]] · [[rp6502-vga-docs]] · [[rp6502-os-docs]] · [[rp6502-github-repo]] · [[release-notes]] · [[quadros-rp2040]] · [[fairhead-pico-c]] · [[pico-c-sdk]] · [[rp2350-datasheet]] · [[w65c02s-datasheet]] · [[leventhal-6502-assembly]] · [[youtube-playlist]]
- **Entities**: [[rp6502-board]] · [[rp6502-ria]] · [[rp6502-ria-w]] · [[rp6502-vga]] · [[rp6502-os]] · [[w65c02s]] · [[w65c22s]] · [[rp2350]] · [[cc65]] · [[llvm-mos]]
- **Concepts**: [[memory-map]] · [[pix-bus]] · [[xram]] · [[xreg]] · [[rom-file-format]] · [[rp6502-abi]] · [[reset-model]] · [[launcher]] · [[ria-registers]] · [[api-opcodes]] · [[65c02-instruction-set]] · [[65c02-addressing-modes]] · [[6502-interrupt-patterns]] · [[6502-subroutine-conventions]] · [[6502-application-snippets]] · [[6502-programming-idioms]] · [[6502-data-structures]] · [[pio-architecture]] · [[pioasm]] · [[gpio-pinout]] · [[hardware-irq]] · [[dual-core-sio]] · [[rp2040-memory]] · [[dma-controller]] · [[usb-controller]] · [[rp2040-clocks]] · [[rp2040-uart]] · [[rp2040-spi]] · [[sdk-architecture]] · [[hstx]] · [[code-pages]] · [[programmable-sound-generator]] · [[opl2-fm-synth]]
- **Topics**: [[version-history]] · [[known-issues]] · [[development-history]]
