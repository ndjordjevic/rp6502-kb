---
type: entity
tags: [rp6502, community, os, native, 65c02, razemos]
related:
  - "[[rp6502-os]]"
  - "[[rp6502-abi]]"
  - "[[cc65]]"
  - "[[launcher]]"
  - "[[community-projects]]"
sources:
  - "[[rumbledethumps-discord]]"
created: 2026-04-18
updated: 2026-04-18
---

# razemOS

**Summary**: A native 65C02 operating system for the RP6502 Picocomputer developed by voidas_pl (WojciechGw). "razem" means "together" in Polish — the OS aims to provide a 65C02-native multitasking shell above the RP6502 OS API.

---

## Overview

razemOS is a community-developed 65C02 operating system that runs on the RP6502 hardware on top of the [[rp6502-os]] API. Unlike the built-in OS (which lives entirely inside the RP2350), razemOS runs in the 6502's own 64 KB address space and provides shell commands, file management, and a path toward multitasking.

Developer: **voidas_pl** (WojciechGw)  
Repository: `https://github.com/WojciechGw/cc65-rp6502os`

---

## Design

- **Kernel fits below `$8000`** — upper half of RAM is available for user programs
- Built with [[cc65]] (C + 6502 assembly)
- Uses [[rp6502-abi]] for all file I/O and system calls
- Programs are loaded as `.rp6502` ROMs; the `roms` command lists installed ROMs

### OS exec pattern

razemOS uses the [[rp6502-abi]] `exec` system call to launch programs, with the kernel acting as the parent process. Programs can exit back to the razemOS shell.

### ROM self-update pattern

razemOS v0.02 introduced a self-update mechanism: a running ROM can write a new `.rp6502` file to the internal filesystem and trigger a restart from the updated image, without requiring a USB connection. This enables over-the-air (or over-network) ROM updates from within a running razemOS session.

### Keyboard exit convention

Following the RP6502 standard:
- **Alt-F4**: exit current program and return to razemOS shell
- **Ctrl-Alt-Del**: exit and return to RP6502 monitor

---

## Version history

| Version | Date | Key changes |
|---------|------|-------------|
| v0.01 | 2026-04-10 | Initial release — kernel + HASS assembler (native 65C02 on-device assembler); ctx.py/crx.py PC transfer scripts |
| v0.02 | 2026-04-12 | Added zip support; `roms` launcher command; ROM self-update pattern |

---

## Bundled tools

| Tool | Description |
|------|-------------|
| **HASS** | Handy ASSembler for 65C02 — a native on-device assembler. Ships as standalone `.rp6502` (load address `$7B00` as a .com-style program). |
| **ctx.py** | Python (PC-side) script for transferring files **to** the Picocomputer |
| **crx.py** | Python (PC-side) script for receiving files **from** the Picocomputer |

---

## Status and roadmap

As of v0.02 (2026-04-12), razemOS was actively developed with multitasking as a stated near-term goal. The project represents one of the most ambitious community software efforts for the RP6502.

> **Note**: razemOS is a community project and is not affiliated with the official Picocomputer project.

---

## Related pages

- [[community-projects]] — all community projects with jasonr1100, tonyvr0759, etc.
- [[rp6502-os]] — the underlying OS API razemOS builds on
- [[rp6502-abi]] — the ABI used for system calls
- [[launcher]] — the official RP6502 launcher mechanism
- [[cc65]] — toolchain used to build razemOS
