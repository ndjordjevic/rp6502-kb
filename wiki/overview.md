---
type: topic
tags: [rp6502, overview]
updated: 2026-04-17 (lint pass 3 — full audit, 8 fixes, source cross-verification)
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

## Key open questions

1. **W65C02S WAI / STP** — does the RIA polling loop interact usefully with the CPU's wait-for-interrupt instruction? The `ria_write` PIO generates PHI2 continuously; WAI would just stall the 6502 in-place until IRQ fires.
2. **Maximum stable PHI2 margin** — the firmware sets 8 MHz as the max (`CPU_PHI2_MAX_KHZ 8000`). PIO timing comments say "good range narrows as PHI2 increases" — the exact electrical limit isn't documented.
3. **`cc65` vs. `llvm-mos` entity pages** — both toolchains have first-class support (separate `lseek` op-codes 0x1A vs 0x1D, separate errno-opt) but no wiki pages yet.
4. **VIA pinout / J1 GPIO header** — not in web docs or repo source; needs the schematic PDF.
5. **VGA GPIO full pinout** — only GPIO 11 (PHI2 in) and GPIO 0–3 (PIX in) confirmed from VGA source. DAC output pins, sync signals not yet read.

## Hub pages

- **Sources**: [[picocomputer-intro]] · [[hardware]] · [[rp6502-ria-docs]] · [[rp6502-ria-w-docs]] · [[rp6502-vga-docs]] · [[rp6502-os-docs]] · [[rp6502-github-repo]] · [[release-notes]] · [[quadros-rp2040]] · [[fairhead-pico-c]]
- **Entities**: [[rp6502-board]] · [[rp6502-ria]] · [[rp6502-ria-w]] · [[rp6502-vga]] · [[rp6502-os]] · [[w65c02s]] · [[w65c22s]]
- **Concepts**: [[memory-map]] · [[pix-bus]] · [[xram]] · [[xreg]] · [[rom-file-format]] · [[rp6502-abi]] · [[reset-model]] · [[launcher]] · [[ria-registers]] · [[api-opcodes]] · [[pio-architecture]] · [[gpio-pinout]] · [[dual-core-sio]] · [[rp2040-memory]] · [[dma-controller]] · [[usb-controller]] · [[rp2040-clocks]] · [[rp2040-uart]] · [[rp2040-spi]]
- **Topics**: [[version-history]] · [[known-issues]]
