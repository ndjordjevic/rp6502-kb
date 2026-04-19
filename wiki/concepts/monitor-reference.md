---
type: concept
tags: [rp6502, monitor, shell, commands, setup, uefi]
related:
  - "[[rp6502-ria]]"
  - "[[rp6502-ria-w]]"
  - "[[rom-file-format]]"
  - "[[launcher]]"
  - "[[reset-model]]"
  - "[[known-issues]]"
sources:
  - "[[rp6502-ria-docs]]"
  - "[[rp6502-ria-w-docs]]"
  - "[[release-notes]]"
created: 2026-04-18
updated: 2026-04-18
---

# Monitor Reference

**Summary**: Complete reference for the RP6502 monitor — the UEFI-like shell that boots before any ROM, used to load/install programs, configure system settings, and manage the filesystem.

---

## Overview

The RP6502 monitor boots automatically on a fresh or un-configured board. It is analogous to a UEFI shell or a ROM BIOS setup screen — its job is to manage `.rp6502` ROM files, configure the hardware, and hand off to a user ROM.

The monitor is **not** a general OS shell. It has no pipes, no scripting, no background tasks. It runs entirely in the RP2350 (not the 6502). The 6502 is held in reset while the monitor is active.

**Access:**
1. Ctrl-Alt-Del from a running program → monitor (6502 RAM preserved)
2. Power-on without a boot ROM configured → monitor
3. UART on the RIA (115200 8N1) — for headless builds
4. Telnet (v0.24+, if `SET PORT` and `SET KEY` are configured) — remote access

---

## General commands

| Command | Description |
|---|---|
| `help` | Show top-level help |
| `help <command>` | Context-sensitive help for a command (e.g. `help set phi2`) |
| `status` | Show current system state (WiFi, PHI2, boot ROM, etc.) |
| `reset` | Soft-reset the 6502 (RAM preserved, boot ROM does not reload) |
| `reboot` | Full RIA restart (reloads boot ROM from flash, cleans up) |

---

## ROM management

| Command | Description |
|---|---|
| `load <file.rp6502>` | Load and run a `.rp6502` ROM from the USB filesystem |
| `install <file.rp6502>` | Copy a ROM to the RIA's internal flash |
| `uninstall <name>` | Remove an installed ROM from flash |
| `list` | List all installed ROMs |
| `info <name>` | Show help/info for an installed ROM |
| `run <name>` | Run an installed ROM by name (short name without `.rp6502`) |

**Typical workflow:**
```
load hello.rp6502        ; run directly from USB
install hello.rp6502     ; copy to flash
set boot hello           ; configure as boot ROM
reboot                   ; now boots hello.rp6502 automatically
```

---

## SET commands

`SET` configures persistent settings stored in flash. All settings survive power cycles. Use `help set` or `help set <key>` for current documentation.

### System

| Command | Description |
|---|---|
| `set phi2 <khz>` | CPU clock in kHz (default: 8000; max: 8000). Use 8000 for full speed. |
| `set boot <name>` | ROM to auto-launch on boot; `-` clears |
| `set save` / `save` | Persist current settings to flash |

> **Gotcha**: after upgrading from some older firmware versions, `PHI2` may reset to 100 kHz. Fix: `set phi2 8000` → `save`. See [[known-issues]].

### WiFi (RIA-W only)

| Command | Description |
|---|---|
| `set rf 0` / `set rf 1` | Disable / enable all radios |
| `set rfcc <cc>` or `-` | Country code (`US`, `GB`, etc.); `-` = worldwide default |
| `set ssid <name>` or `-` | WiFi network name |
| `set pass <pw>` or `-` | WiFi password |
| `set tz <tz>` | Timezone: POSIX TZ string or city name (e.g. `US/Eastern`) |

### Telnet console (RIA-W, v0.24+)

| Command | Description |
|---|---|
| `set port <n>` or `0` | TCP listening port for telnet access; `0` disables; standard = 23 |
| `set key <key>` or `-` | Passkey required from connecting clients; `-` clears |

Both `PORT` and `KEY` must be set to enable the telnet console.

### BLE (RIA-W only)

| Command | Description |
|---|---|
| `set ble 2` | Enter BLE pairing mode (LED blinks); put device into pairing mode too |

---

## Filesystem commands

The RIA mounts USB mass storage (flash drives) automatically.

| Command | Description |
|---|---|
| `ls` | List files in the current directory |
| `cd <dir>` | Change directory |
| `pwd` | Print working directory |
| `rm <file>` | Remove a file |
| `mv <src> <dst>` | Rename / move a file |
| `mkdir <dir>` | Create a directory |
| `cat <file>` | Print a file to the console |
| `upload` | Receive a file via XMODEM / Intel hex (depends on version) |

> Note: monitor filesystem commands are minimal. For full file management, run a ROM with file tools (e.g. a FAT shell ROM).

---

## Intel hex upload (v0.16+)

The monitor accepts Intel hex records for loading code directly into 6502 RAM without a `.rp6502` file:

```
upload               ; puts monitor in receive mode
<paste Intel hex>    ; send `.hex` file contents
```

Useful for testing small code snippets without the full build + package workflow. See [[rom-file-format]] for the `.rp6502` packaging alternative.

---

## Monitor output pagination (v0.16+)

`CTRL-C` and `Q` stop paginated output (e.g. long `list` or `cat`). Added in v0.16.

---

## Command history (v0.18+)

Up/down arrow keys cycle through the last 3 commands. Added in v0.18.

---

## Version timeline

| Version | Monitor change |
|---------|---------------|
| v0.1 | Initial monitor (load, install, basic SET) |
| v0.5 | Readline-subset line editor |
| v0.16 | Intel hex, output pagination (Ctrl-C/Q) |
| v0.18 | Command history (3 lines, up/down) |
| v0.20 | Console parser: quoted and escaped strings |
| v0.23 | Alt-F4 = stop ROM → launcher; Ctrl-Alt-Del = stop ROM → monitor |
| v0.24 | `SET PORT` / `SET KEY` for telnet console |

---

## Related pages

- [[rp6502-ria]] — RIA entity (monitor access methods, UART)
- [[rp6502-ria-w]] — RIA-W (WiFi/BLE SET commands, telnet)
- [[rom-file-format]] — `.rp6502` file packaging
- [[launcher]] — `SET BOOT` and ROM-based launcher
- [[reset-model]] — reset vs. reboot distinction
- [[known-issues]] — PHI2 reset gotcha after upgrades
- [[ria-w-networking]] — complete networking command reference
