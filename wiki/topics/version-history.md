---
type: topic
tags: [rp6502, history, versions, changelog]
related: [[release-notes]], [[known-issues]], [[rp6502-ria]], [[rp6502-vga]], [[rp6502-os]]
sources: [[release-notes]]
created: 2026-04-16
updated: 2026-04-16
---

# Version History

**Summary**: Narrative history of the RP6502 project from v0.1 (Aug 2023) to v0.23 (Apr 2026), organized by era.

---

## Era 1 — Proof of concept (v0.1–v0.1, Aug 2023)

The first versioned release established a working 65C02 + RIA firmware on Pi Pico 1. No VGA, no audio — just the bus interface, monitor, and basic I/O.

---

## Era 2 — VGA and input (v0.2–v0.7, Oct 2023–Feb 2024)

**v0.2** was the first major architectural release: the PIX bus, programmable VGA, and 16-bit color ANSI terminal. This was an ABI-breaking release.

**v0.3–v0.4** rapidly filled in the VGA mode set (modes 0–4) and added direct keyboard/mouse HID input, `stdin`/`fgets`, and filesystem write calls (`unlink`, `rename`).

**v0.5** introduced VSYNC IRQ support and a readline-subset line editor — the monitor became genuinely interactive.

**v0.6** added the PSG: 8 oscillators, ADSR, stereo pan, PWM. The machine now had audio.

**v0.7** added PS4 gamepad support and `clock()` for cc65's `sleep()`.

---

## Era 3 — USB stability (v0.8–v0.9, Jul–Sep 2024)

**v0.8** was a bad release with a littlefs formatting bug. **Do not use.** **v0.9** fixed it.

---

## Era 4 — Pi Pico 2 migration (v0.10–v0.11, Apr–May 2025)

**v0.10** was the migration to Pi Pico 2 (RP2350). This was a **hard hardware break** — Pico 1 boards are no longer supported. The RP2350 defaults to 150 MHz (vs the RP2040's 133 MHz), and the RIA firmware overclocks it further to 256 MHz / 1.15 V (see [[pio-architecture]]) — enabling 8 MHz PHI2 with headroom for USB, audio, and networking simultaneously.

**v0.11** paid off technical debt: USB hub-in-hub support (up to 16 devices, 8 filesystems), VGA scanvideo internals rewritten for a 10% fill rate improvement, and the project optimized to O3.

---

## Era 5 — Wireless and BBS (v0.12–v0.14, Jul–Oct 2025)

**v0.12** was the splash release: RIA-W firmware with WiFi, NTP, and a Hayes-style modem that could call BBSs over the internet. `term.rp6502` provided a CP437 ANSI terminal. VGA now requires Pico 2. Telnet noted as planned but not implemented (raw TCP only).

**v0.13** expanded input: BLE HID for wireless keyboards/joysticks/gamepads, USB gamepad drivers, PHI2 default raised from 4000 to 8000 kHz. Non-W RIA builds no longer released.

**v0.14** was a deep infrastructure release: errno system completely replaced (native compiler errno.h; the old `oserror`/`mappederrno` system is gone), documentation refreshed, and 17 directory/file management OS calls added.

---

## Era 6 — Polish and FM audio (v0.15–v0.17, Dec 2025–Jan 2026)

**v0.15** added keyboard localization and dead key sequences. All ARM assembly ported to C.

**v0.16** added OPL2 FM synthesis (Yamaha YM3812 emulation via `emu8950`), intel hex monitor support, monitor pagination, and an improved timezone database.

**v0.17** upgraded the DAC from 8-bit to 10-bit, resolved BLE audio noise, and fixed VGA detection reliability.

---

## Era 7 — ROM filesystem and USB maturity (v0.18–v0.20, Feb–Mar 2026)

**v0.18** was a large feature release: monitor command history, VCP USB-to-serial support, XInput (Xbox controllers), ROM asset filesystem (`.rp6502` files can now embed named assets, demonstrated by Colossal Cave Adventure), and initial CBI floppy support.

**v0.19** fixed the TinyUSB silicon-level bug that caused the system to freeze on USB plug events. 3.5" floppy drives confirmed working.

**v0.20** completed the MSC driver (>2TB drives, ExFAT-ready when patents expire, TRIM support) and rewrote the console parser to support quoted and escaped strings.

---

## Era 8 — Process management and sprites (v0.21–v0.23, Mar–Apr 2026)

**v0.21** was the most architecturally significant release since v0.2: the attribute system generalized to `ria_get_attr`/`ria_set_attr`; ROMs can now pass argv to each other via `ria_execl`/`ria_execv`; the [[launcher]] mechanism enables persistent-shell patterns and fault-tolerant native OS boot; NFC cards can launch programs; CON:/TTY: special devices added; console BEL attribute.

**v0.22** made storage 8× faster (floppy ~15 KB/s, flash ~512 KB/s), added `nfc.rp6502` as an NFC programming tool, and rewrote the HID parser.

**v0.23** added mode 5 (sprite rendering with 1/2/4/8-bit color), rewrote the scanvideo library for instant canvas switching without HDMI resync, and formalized the Alt-F4 / Ctrl-Alt-Del keystroke model for the [[launcher]] pattern.

---

## Related pages

- [[release-notes]] — raw chronological table
- [[known-issues]] — bugs and workarounds
- [[rp6502-os]] · [[launcher]] · [[rom-file-format]] · [[rp6502-abi]]
