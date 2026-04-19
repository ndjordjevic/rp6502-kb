---
type: entity
tags: [rp6502, community, os, native, 65c02, razemos, shell, uart]
related:
  - "[[rp6502-os]]"
  - "[[rp6502-abi]]"
  - "[[cc65]]"
  - "[[launcher]]"
  - "[[community-projects]]"
  - "[[hass]]"
  - "[[razemos-repo]]"
  - "[[rom-file-format]]"
  - "[[fatfs]]"
sources:
  - "[[rumbledethumps-discord]]"
  - "[[razemos-repo]]"
created: 2026-04-18
updated: 2026-04-19
---

# razemOS

**Summary**: A native 65C02 community shell/OS for the RP6502 Picocomputer developed by WojciechGw (voidas_pl). Provides a Unix-like interactive shell, file management, UART file transfer, extensible `.com` commands, Wi-Fi/NTP, and the HASS native assembler. Based on ideas from Jason Howard's `rp6502-shell`.

---

## Overview

razemOS is a community-developed 65C02 shell that runs on the RP6502 hardware on top of the [[rp6502-os]] API. Unlike the built-in OS (which lives entirely inside the RP2350), razemOS runs in the 6502's own 64 KB address space and provides a full interactive shell environment.

Developer: **WojciechGw** (Wojciech Gwiozdik / voidas_pl)  
Repository: `https://github.com/WojciechGw/cc65-rp6502os` (see [[razemos-repo]])  
Build: [[cc65]] toolchain + CMake

---

## Memory layout

- **User programs**: `$8000–$FCFF` (~31 KB)
- razemOS kernel occupies below `$8000`

---

## Program formats

| Extension | Format | Launched by |
|-----------|--------|-------------|
| `.com` | Loaded at a given address and run; ROM commands omit extension | `com <addr>` or type command name |
| `.exe` | Raw binary; last two bytes are LSB,MSB entry-point pointer | Type filename or `run` |
| `.rp6502` | Standard RP6502 ROM | `cart <name>` or `roms` browser |

ROM commands (`.com` files embedded in `razemos.rp6502`) can be overridden by placing updated `.com` files in `MSC0:/SHELL/` — without rebuilding the whole ROM.

---

## Design

- Built with [[cc65]] (C + 6502 assembly)
- Uses [[rp6502-abi]] for all file I/O and system calls
- Shell supports ~20 internal commands + extensible ROM `.com` commands
- Wi-Fi connection at startup; RTC updated via NTP
- ZIP archive support (STORE and DEFLATE modes)

### Extension command system

`.com` files placed in `MSC0:/SHELL/` take precedence over ROM commands. This allows updating individual commands without rebuilding `razemos.rp6502`. Use `tools/razemOScmd.py` to build and upload extensions.

### UART file transfer

Protocol: Intel HEX over UART with CRC32.
- **PC → RP6502**: `crx` on shell + `ctx.py <file>` on PC
- **RP6502 → PC**: `ctx filename` on shell + `crx.py` on PC

### OS exec pattern

Uses the [[rp6502-abi]] `exec` system call to launch programs; the kernel acts as the parent. Programs exit back to the razemOS shell.

### ROM self-update pattern

A running ROM can write a new `.rp6502` file and trigger a restart from the updated image — enabling OTA ROM updates from within a running session.

### Keyboard exit convention

- **Alt-F4**: exit current program, return to razemOS shell
- **Ctrl-Alt-Del**: exit to RP6502 monitor

---

## HASS assembler

razemOS bundles [[hass]] — a **native two-pass assembler** for the W65C02S with:
- Interactive mode with line editing (`@EDIT`, `@DEL`, `@INS`)
- `@MAKE` to assemble; `@CYCLES` for cycle counting
- `@TRACE` — built-in W65C02S software emulator (single-step + run mode)
- Full 65C02 + WDC extensions (RMBx, SMBx, BBRx, BBSx, WAI, STP)
- 512-line / 16 KB code / 128-symbol limits

---

## Version history

| Version | Date | Key changes |
|---------|------|-------------|
| v0.01 | 2026-04-10 | Initial release — kernel + HASS assembler; ctx.py/crx.py PC transfer scripts |
| v0.02 | 2026-04-12 | ZIP support; `roms` launcher command; ROM self-update pattern |
| (active) | 2026-04-19 | Latest commit `782ff15`; full command set documented in [[razemos-repo]] |

---

## Related pages

- [[razemos-repo]] — full source page with complete command tables
- [[hass]] — HASS assembler reference
- [[community-projects]] — all community projects
- [[rp6502-os]] — the underlying OS API razemOS builds on
- [[rp6502-abi]] — the ABI used for system calls
- [[launcher]] — the official RP6502 launcher mechanism
- [[cc65]] — toolchain used to build razemOS
- [[rom-file-format]] — `.rp6502` ROM format
