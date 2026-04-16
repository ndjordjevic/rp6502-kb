---
type: source
tags: [rp6502, releases, history, changelog]
related: [[rp6502-ria]], [[rp6502-ria-w]], [[rp6502-vga]], [[rp6502-os]], [[version-history]], [[known-issues]]
sources: []
created: 2026-04-16
updated: 2026-04-16
---

# Release Notes

**Summary**: Synthesis of all 23 release notes (v0.1–v0.23, Aug 2023–Apr 2026) from `raw/github/picocomputer/rp6502/releases/`. Canonical record of when features were introduced and breaking changes made.

---

## Release timeline

| Version | Date | Headline |
| --- | --- | --- |
| v0.1 | 2023-08 | First versioned release |
| v0.2 | 2023-10 | Programmable VGA added; **ABI break** (must recompile) |
| v0.3 | 2023-10 | Keyboard/mouse input; mode 3 (2bpp); stdin/fgets (pre-release) |
| v0.4 | 2023-11 | VGA modes 1, 2, 4 complete (all 0–4 done); time.h; unlink/rename |
| v0.5 | 2023-12 | VSYNC IRQ; stdin_opt; line editor (readline subset); littlefs 2.8.1 |
| v0.6 | 2024-01 | PSG (Programmable Sound Generator) added |
| v0.7 | 2024-02 | PS4 gamepad; clock() for cc65 sleep() |
| v0.8 | 2024-07 | **BROKEN — DO NOT USE.** littlefs bug corrupts new Pico flash |
| v0.9 | 2024-09 | Fix for v0.8 littlefs formatting failure (littlefs 2.9.3) |
| v0.10 | 2025-04 | **Migrated to Pi Pico 2 (RP2350).** Pico 1 boards no longer supported |
| v0.11 | 2025-05 | USB hub-in-hub support (16 devices, 8 filesystems); VGA scanvideo rewrite (+10% fill) |
| v0.12 | 2025-07 | **WiFi + Hayes modem** (RIA-W); VGA requires Pico 2; `term.rp6502` CP437 terminal |
| v0.13 | 2025-09 | BLE HID; USB gamepad; PHI2 default 4000→8000; non-W RIA no longer released |
| v0.14 | 2025-10 | Errno system overhauled (native compiler errno); 17 dir/file calls added |
| v0.15 | 2025-12 | Dead keys; keyboard localization; cursor terminal codes; all ARM asm→C |
| v0.16 | 2025-12 | **OPL2 FM sound** added; intel hex in monitor; pagination; improved TZ database |
| v0.17 | 2026-01 | Audio 8-bit→10-bit; OPL level boost; VGA detection fix |
| v0.18 | 2026-02 | Monitor history; VCP USB-to-serial; XInput (Xbox); **ROM asset filesystem** |
| v0.19 | 2026-03 | Silicon-level USB fix (no more freeze on plug-in); 3.5" floppy works |
| v0.20 | 2026-03 | MSC greatly improved (>2TB/ExFAT ready, TRIM); console quoted strings |
| v0.21 | 2026-03 | **ria_get_attr/ria_set_attr; launcher; ria_execl/execv; argv; NFC launch; CON:/TTY:** |
| v0.22 | 2026-04 | MSC 8× faster; nfc.rp6502 tool; BLE fixes; HID parser rewrite |
| v0.23 | 2026-04 | **Mode 5 sprites**; scanvideo rewrite (no HDMI resync); Alt-F4 launcher shortcut |

---

## Feature introduction dates

### Hardware platform
- **v0.1–v0.9**: Pi Pico 1 (RP2040)
- **v0.10+**: Pi Pico 2 (RP2350) required — **breaking change, no backwards compatibility**
- **v0.12+**: VGA also requires Pico 2 (was optional on Pico 1 before)
- **v0.13+**: Only RIA-W firmware is released; plain RIA must be built from source

### ABI / OS
- **v0.2**: First ABI break — full recompile required from v0.1
- **v0.14**: Errno system completely replaced — `oserror`/`mappederrno` removed; native compiler errno.h used directly
- **v0.21**: Attribute system generalized to `ria_get_attr`/`ria_set_attr` (replaces individual calls)

### VGA modes
- **v0.2**: Programmable VGA system introduced; modes 0, 3 initially
- **v0.3**: Mode 3 (2bpp graphics)
- **v0.4**: Modes 1, 2, 4 — all 5 modes (0–4) complete
- **v0.23**: Mode 5 (sprites: 1/2/4/8-bit) added — completing the 6-mode set

### Audio
- **v0.6**: PSG (8 oscillators, ADSR, stereo pan)
- **v0.16**: OPL2 FM synthesis (Yamaha YM3812 emulation)
- **v0.17**: Audio upgraded 8-bit → 10-bit DAC

### Input
- **v0.3**: Keyboard and mouse
- **v0.5**: Num pad; line editor
- **v0.7**: PS4 gamepad
- **v0.13**: USB gamepad generalized; BLE HID (keyboards, joysticks, gamepads)
- **v0.15**: Dead key sequences; keyboard localization
- **v0.18**: XInput (Xbox 360/One controllers)

### Storage / USB
- **v0.4**: unlink(), rename()
- **v0.11**: Hub-in-hub USB; up to 16 devices, 8 filesystems
- **v0.18**: VCP USB-to-serial; CBI floppy (partial); ROM asset filesystem
- **v0.19**: Silicon USB fix; 3.5" floppy confirmed working
- **v0.20**: MSC driver mature (>2TB, ExFAT-ready, TRIM)
- **v0.22**: MSC 8× faster (floppy ~15 KB/s, flash ~512 KB/s)

### Networking (RIA-W only)
- **v0.12**: WiFi, NTP, Hayes modem (raw TCP only); `term.rp6502` BBS terminal
- **v0.13**: BLE HID input
- **v0.14**: NTP fixed (only syncs at first WiFi connect + every 24 h)

### Process / ROM management
- **v0.18**: ROM asset filesystem (named assets embedded in `.rp6502`)
- **v0.21**: `ria_execl`/`ria_execv`; argc/argv; launcher mechanism; NFC card launch; CON:/TTY: devices; BEL attribute

### Monitor / UX
- **v0.5**: Line editor (readline subset, no history)
- **v0.16**: Intel hex format; monitor pagination (ctrl-c/q)
- **v0.18**: Command history (3 lines, up/down arrows)
- **v0.20**: Console parser supports quoted and escaped strings
- **v0.23**: Alt-F4 = stop ROM → launcher; Ctrl-Alt-Del = stop ROM → monitor

---

## Known issues and warnings (from release notes)

See [[known-issues]] for the full operational list. Key warnings:

- **v0.8**: Corrupts internal filesystem on brand-new Pico. **Do not flash.** Use v0.9 or later.
- **v0.16**: PHI2 setting may reset to 100 after upgrade. Fix with `SET PHI2 8000`.
- **v0.13**: Non-W RIA no longer released. Plain RIA builds require building from source.
- **v0.14**: Requires cc65 fork (`picocomputer/cc65`) until PR #2844 is merged upstream.
- **v0.12**: Modem is raw TCP only. Telnet layer is a planned future feature.
- **v0.13**: Bluetooth BR/EDR not supported (BLE only). TinyUSB XInput was re-enabled in v0.18.

---

## Related pages

- [[version-history]] · [[known-issues]]
- [[rp6502-ria]] · [[rp6502-ria-w]] · [[rp6502-vga]] · [[rp6502-os]]
- [[rom-file-format]] · [[launcher]] · [[rp6502-abi]]
