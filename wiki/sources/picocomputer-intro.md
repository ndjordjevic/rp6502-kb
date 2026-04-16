---
type: source
tags: [rp6502, overview, source]
related: [[rp6502-board]], [[rp6502-ria]], [[rp6502-ria-w]], [[rp6502-vga]]
sources: [picocomputer.github.io/index]
created: 2026-04-15
updated: 2026-04-15
---

# Source — Picocomputer 6502 (landing page)

**Summary**: The official one-page introduction to the project. Tagline: *"Pure 6502. No governor. No speed limits."*

Raw: [Picocomputer 6502](<../../raw/web/picocomputer.github.io/Picocomputer 6502 — Picocomputer  documentation.md>)

---

## Key facts

- **Real 6502**: WDC [[w65c02s]] + WDC [[w65c22s]] VIA, variable **0.1–8.0 MHz**.
- **Memory**: 64 KB system RAM + 64 KB extended (XRAM via [[rp6502-ria]]).
- **Onboard flash**: 1 MB for installing and auto-booting `.rp6502` ROMs.
- **Video**: VGA + HD output; 3 planes, scanline-programmable (see [[rp6502-vga]]).
- **Sound**: 8-voice PSG + YM3812 OPL2 FM (both inside [[rp6502-ria]]).
- **RTC** with DST; true RNG (via [[rp6502-ria]]).
- **Wireless** (via [[rp6502-ria-w]]): WiFi 4, NTP, Hayes modem emulation, BLE for HID.
- **USB host**: keyboard, mouse, gamepads, hubs, UART, NFC, floppy, flash.
- **USB device**: driverless CDC ACM console.
- **Programming**: 32-bit protected OS ([[rp6502-os]]); POSIX-like C; supports [[cc65]] and [[llvm-mos]].
- **Build**: 100% through-hole, ~$100 USD. Reference design; [[rp6502-board]] is the canonical PCB. The only required module is [[rp6502-ria]].

## Key claims (worth verifying)

- VGA firmware runs on a **Raspberry Pi Pico 2** (RP2350).
- RIA-W firmware runs on a **Raspberry Pi Pico 2 W**.
- Pico 2 is guaranteed in production **until at least January 2040**.

## Related pages

- [[rp6502-board]] — reference PCB
- [[rp6502-ria]] — interface adapter (the required module)
- [[rp6502-ria-w]] — wireless variant
- [[rp6502-vga]] — optional video module
- [[rp6502-os]] — the OS + API
