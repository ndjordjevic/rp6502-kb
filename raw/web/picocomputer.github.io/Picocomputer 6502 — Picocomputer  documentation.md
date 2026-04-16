---
title: "Picocomputer 6502 — Picocomputer  documentation"
source: "https://picocomputer.github.io/"
author:
published:
created: 2026-04-15
description:
tags:
  - "clippings"
---
## Picocomputer 6502

Pure 6502. No governor. No speed limits.

The **Picocomputer 6502** is an open source, modern-retro gaming computer built around a real WDC 65C02. The design philosophy: keep the soul of programming a 6502 and 6522, then rethink everything else.

[![Picocomputer Photo](https://picocomputer.github.io/_images/ria-w-sandwich.jpg)](https://picocomputer.github.io/_images/ria-w-sandwich.jpg)

## Specs

- **Core** — WDC 65C02 CPU and WDC 65C22 VIA; variable 0.1-8.0 MHz
- **RAM** — 64 KB system + 64 KB extended
- **ROM** — 1 MB of onboard flash for installing and auto-booting ROMs
- **Video** — VGA and HD output; 3 planes, scanline programmable
- **Sound** — PSG (8 voices) and OPL2 FM (9 voices)
- **Clock** — Real-Time Clock with Daylight Savings Time
- **TRNG** — True random number generator

## Quality of Life

- **Open by Design** — DIY-friendly with fully open source hardware and software
- **Storage** — Blazing fast 512 KB/sec USB flash drive reads and writes
- **Keyboard** — International keyboard layout support
- **Fonts** — Built-in code pages for international character sets

## Connectivity

- **WiFi** — NTP time sync, Hayes modem emulation for dialing into BBSs
- **Bluetooth LE** — keyboard, mouse, and gamepads
- **USB Host** — keyboard, mouse, gamepads, hubs, UART serial, NFC, floppy drives, and flash drives
- **USB Device** — driverless CDC ACM; console access (can operate headless)

## Programming

- **Protected OS** — 32-bit operating system; uses no 6502 RAM
- **FAT filesystem** — read and write files on any USB flash or floppy drive
- **API** — POSIX-like C library for familiar, portable programming
- **cc65** — [VS Code integration for cc65](https://github.com/picocomputer/vscode-cc65)
- **llvm-mos** — [VS Code integration for llvm-mos](https://github.com/picocomputer/vscode-llvm-mos)
- **AI Assistance** — The latest models via VS Code extensions or GitHub Copilot

## Build It

100% through-hole construction. No IC programmer needed. Hundreds of people have built one, typically for under $100 USD. You can also have a unit manufactured in China — no soldering required. All parts are currently in production; the Raspberry Pi Pico 2 is guaranteed until at least January 2040.

- [Hardware](https://picocomputer.github.io/hardware.html): Schematic and manufacturing information.

## Documentation

The Picocomputer 6502 is a reference design for RP6502 modular hardware. The only required module is the RP6502-RIA.

- [RP6502-RIA](https://picocomputer.github.io/ria.html): Interface adapter for the 6502, akin to CIA, VIA, and ACIA devices.
- [RP6502-RIA-W](https://picocomputer.github.io/ria_w.html): Wireless features available when using the “Pico 2 W”.
- [RP6502-VGA](https://picocomputer.github.io/vga.html): Optional video adapter.
- [RP6502-OS](https://picocomputer.github.io/os.html): The operating system and application programming interface.

[Please contribute to this documentation.](https://github.com/picocomputer/picocomputer.github.io)