---
type: source
tags: [rp6502, os, api, abi, source]
related:
  - "[[rp6502-os]]"
  - "[[rp6502-abi]]"
  - "[[memory-map]]"
  - "[[xram]]"
  - "[[launcher]]"
sources: [picocomputer.github.io/os]
created: 2026-04-15
updated: 2026-04-15
---

# Source — RP6502-OS docs

**Summary**: The 32-bit protected OS that runs **inside the RIA** and exposes a POSIX-like C API to the 6502. Uses **zero 6502 RAM**.

Raw: [RP6502-OS](<../../raw/web/picocomputer.github.io/RP6502-OS — Picocomputer  documentation.md>)

---

## Foundational claims

- **No ROM** on the 6502 bus. Nothing in zero page reserved. Every boot starts with a clean slate.
- The OS is POSIX-flavored, built around **FatFs** for FAT32 (ExFAT "ready when patents expire").
- ABI is based on [[cc65]]'s **fastcall**; identical from assembly or C. See [[rp6502-abi]].
- Provides `stdio.h` / `unistd.h` to both [[cc65]] and [[llvm-mos]] runtimes.

## Memory map (from the source)

| Address | Use |
| --- | --- |
| `$0000-$FEFF` | RAM, 63.75 K |
| `$FF00-$FFCF` | Unassigned (for user chip-select expansion) |
| `$FFD0-$FFDF` | VIA ([[w65c22s]]) |
| `$FFE0-$FFFF` | RIA ([[rp6502-ria]]) |
| `$10000-$1FFFF` | XRAM, 64 K (see [[xram]]) |

→ Lifted into [[memory-map]].

## The ABI in one page

- Args pushed left to right on the **XSTACK**; last arg passed in `RIA_A` / `RIA_AX` / `RIA_AXSREG`.
- Op ID → `RIA_OP` starts the call; poll `RIA_BUSY` or `JSR RIA_SPIN`.
- Return in `RIA_A` / `RIA_AX` / `RIA_AXSREG`; `RIA_ERRNO` on error.
- **Short stacking**: push fewer bytes when the first arg fits.
- **Bulk XSTACK** (≤ 512 B): pass buf over the xstack itself.
- **Bulk XRAM**: `read_xram` / `write_xram` hit ~512 KB/s — "disk" has no seek time, so the Picocomputer **does not use paged memory**.

→ Lifted into [[rp6502-abi]].

## API surface (grouped)

- **Process/runtime**: `zxstack`, `_argv`, `_exec` / `ria_execl` / `ria_execv`, `exit`.
- **Attributes**: `ria_attr_get` / `ria_attr_set`. IDs: `RIA_ATTR_ERRNO_OPT`, `RIA_ATTR_PHI2_KHZ`, `RIA_ATTR_CODE_PAGE`, `RIA_ATTR_RLN_LENGTH`, `RIA_ATTR_LRAND`, `RIA_ATTR_BEL`, `RIA_ATTR_LAUNCHER`, `RIA_ATTR_EXIT_CODE`.
- **Time**: `clock`, `clock_getres`, `clock_gettime`, `clock_settime`, `tzset`, `_tzquery` / `localtime`. Monotonic clock ticks 100× per sec, wraps ~497 days.
- **XREG**: `xreg()` / `xregn()` — install virtual hardware on the PIX bus. See [[xreg]].
- **File I/O**: `open`, `close`, `read`, `write`, `read_xstack`, `write_xstack`, `read_xram`, `write_xram`, `lseek`/`f_lseek`, `unlink`, `rename`, `syncfs`, `f_stat`, `f_opendir`/`f_readdir`/`f_closedir`/`f_telldir`/`f_seekdir`/`f_rewinddir`, `f_chmod`, `f_utime`, `f_mkdir`, `chdir`, `f_chdrive`, `f_getcwd`, `f_setlabel`/`f_getlabel`, `f_getfree`.
- **Launcher**: `RIA_ATTR_LAUNCHER` registers the current ROM as the process-manager launcher. See [[launcher]].

## Errno mapping

The OS maps **FatFs** errors onto errno. Both [[cc65]] and [[llvm-mos]] use different errno constants, so `RIA_ATTR_ERRNO_OPT` selects which. C runtimes set this automatically; assembly must set it before any fallible call.

## Notable details

- `open("CON:")` = non-blocking cooked console. `open("TTY:")` = non-blocking raw.
- `open("VCP0:115200,8N1")` etc. opens USB-serial adapters (FTDI, CP210x, CH34x, PL2303, CDC ACM).
- `open("NFC:")` takes control of the PN532 and suppresses auto-ROM-launching.
- `f_chdrive` takes names like `USB0:`–`USB9:` (shortcut `0:`–`9:`).
- Up to **8 files** and **8 directories** open at once.

## Related pages

- [[rp6502-os]] · [[rp6502-abi]] · [[memory-map]] · [[xram]] · [[xreg]] · [[launcher]]
