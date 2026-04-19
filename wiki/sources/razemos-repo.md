---
type: source
tags: [rp6502, community, os, shell, cc65, assembler, uart, fatfs]
related:
  - "[[razemos]]"
  - "[[hass]]"
  - "[[cc65]]"
  - "[[rp6502-os]]"
  - "[[community-projects]]"
  - "[[rom-file-format]]"
  - "[[fatfs]]"
sources:
  - "[[rumbledethumps-discord]]"
created: 2026-04-19
updated: 2026-04-19
---

# razemOS Repository

**Summary**: Source page for `WojciechGw/cc65-rp6502os` (commit `782ff15`, 2026-04-19) — a native 65C02 community shell and OS for the RP6502 Picocomputer, including the HASS on-device assembler.

---

## Repository

- **URL**: https://github.com/WojciechGw/cc65-rp6502os
- **Author**: WojciechGw (Wojciech Gwiozdik / voidas_pl)
- **Status**: Active (commits as of 2026-04-19)
- **Build**: cc65 toolchain + CMake
- **Commit ingested**: `782ff15` (2026-04-19)

---

## What it is

razemOS (formerly known as `cc65-rp6502os`) is a community-built shell running on the RP6502. It sits on top of the standard [[rp6502-os]] API and provides a Unix-like shell, file management, extensible commands, file transfer, and a native assembler. Based on ideas and code from Jason Howard's `rp6502-shell`.

---

## Key facts

- User programs run in `$8000–$FCFF` (~31 KB)
- Shell is installed as a boot ROM (`razemos.rp6502`)
- ROM commands can be overridden or extended via `.com` files in `MSC0:/SHELL/`
- Supports **three program formats**:
  - `.com` — loaded at a given address and run; `.com` extension may be omitted for commands in ROM or `MSC0:/SHELL/`
  - `.exe` — last two bytes are LSB,MSB pointer to entry point
  - `.rp6502` — standard RP6502 ROM (launched via `cart` or `roms` commands)
- File transfer uses Intel HEX over UART with CRC32
- Wi-Fi + NTP for real-time clock at startup
- `hass` — bundled **Handy ASSembler** with built-in W65C02S software emulator; see [[hass]]

---

## Shell commands

### Internal commands (built-in)

| Command | Description |
|---------|-------------|
| `bload` | Load binary file to RAM or XRAM |
| `bsave` | Save RAM or XRAM region to binary file |
| `brun` | Load binary file to RAM and run it |
| `cart` | Launch a ROM by filename (without extension) |
| `cd` | Change active directory |
| `chmod` | Set file attributes |
| `cls` | Reset/clear terminal |
| `com` | Load `.com` binary at given address and run |
| `copy` | Copy a single file |
| `cp` | Copy or move files (wildcards supported) |
| `drive` | Set active drive |
| `exit` | Exit to the system monitor |
| `launcher` | Register or deregister razemOS as system launcher |
| `list` | Display text file contents |
| `ls` | List active directory |
| `mem` | Show available RAM (lowest/highest address and size) |
| `mkdir` | Create directory |
| `phi2` | Show CPU clock frequency |
| `rename` | Rename or move a file or directory |
| `rm` | Remove file(s) — wildcards supported |
| `run` | Execute code at given address |
| `stat` | Show file or directory info |
| `time` | Show local date and time |

### ROM commands (`.com` files embedded in `razemos.rp6502`)

| Command | Description |
|---------|-------------|
| `crx` | File receiver — download from PC to RP6502 over UART |
| `ctx` | File sender — upload from RP6502 to PC over UART |
| `date` | Clock, calendar and RTC management |
| `dir` | Directory listing with optional wildcards and sorting |
| `drives` | List available drives |
| `help` | Show help; `help <command>` or F1 for command-specific info |
| `hex` | Hex dump of a file |
| `keyboard` | Interactive keyboard state visualiser |
| `label` | Show or set active drive volume label |
| `pack` | Create or extract ZIP archives (STORE or DEFLATE) |
| `peek` | Memory viewer (RAM or XRAM) |
| `roms` | Tile browser for `.rp6502` files — navigate and launch |
| `ss-matrix` | Screensaver: Matrix Rain |
| `ss-noise` | Screensaver: Character Noise |
| `tree` | Display directory tree with subdirectories |
| `view` | Display monochrome BMP (640×480×1bpp); dump framebuffer to `.bin` |

### Keyboard shortcuts

| Key | Action |
|-----|--------|
| F1 | Help |
| F2 | Keyboard visualiser |
| F3 | Date, time and calendar |
| F4 | Directory of active drive |
| ↑ | Recall last command |

---

## File transfer protocol

**PC → RP6502**: run `crx` on shell, then `ctx.py <file>` on PC  
**RP6502 → PC**: run `ctx filename` on shell, then `crx.py` on PC  
Protocol: Intel HEX over UART with CRC32 checksumming.

---

## Build extensions (`razemOScmd.py`)

`tools/razemOScmd.py` builds and optionally uploads `.com` shell extension commands.

```
razemOScmd.py <command> [options]   # build single command
razemOScmd.py --all [options]       # build all ext-*.c commands
razemOScmd.py --clean               # remove .com, .map artefacts
```

Upload options: `--upload`, `--uploader ctx|rp6502`, `--shell <path>`, `--port <port>`, `--baud <rate>`.

---

## Related pages

- [[razemos]] — entity page with design details and version history
- [[hass]] — HASS assembler reference
- [[rp6502-os]] — the underlying OS API
- [[community-projects]] — other community projects
- [[rom-file-format]] — `.rp6502` ROM format
- [[cc65]] — toolchain used to build razemOS
