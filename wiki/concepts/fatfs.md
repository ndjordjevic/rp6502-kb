---
type: concept
tags: [rp6502, filesystem, fatfs, usb, storage, fat32, exfat]
related: [[rp6502-os]], [[usb-controller]], [[code-pages]], [[xram]], [[rp6502-github-repo]]
sources: [[rp6502-os-docs]], [[yt-ep06-roms-filesystem]], [[rp6502-github-repo]]
created: 2026-04-18
updated: 2026-04-18
---

# FatFS (Filesystem)

**Summary**: The RP6502-OS uses **FatFs r0.15+** (BSD-3-Clause) as its FAT filesystem driver, providing standard POSIX-like file I/O over USB Mass Storage Class (MSC) devices — thumb drives, SD cards via USB adapter, and USB floppy drives.

---

## Why FAT over USB

USB drives and SD cards have built-in wear-leveling controllers, so they can safely use any filesystem. FAT32 was chosen for maximum compatibility — the RP6502 can exchange files with any host OS without special drivers. (@rumbledethumps, Ep6)

Internal Pico flash is a "naked" flash device with no wear-leveling. FAT would wear it out unevenly — this is why **littlefs** was originally considered for internal flash. However, the current RP6502-OS design stores everything on removable USB media (FatFs), not internal flash.

## Capabilities

| Property | Value |
|----------|-------|
| Filesystem | FAT12 / FAT16 / FAT32 |
| ExFAT | Ready (waiting for patent expiry) |
| Max open files | 8 files + 8 directories simultaneously |
| Max USB drives | Supports multi-LUN MSC devices |
| Library version | FatFs r0.15+, BSD-3-Clause |
| Source location | `fatfs/` in picocomputer/rp6502 repo |

## 6502 API

Standard POSIX C file I/O works unchanged from the 6502:

```c
FILE *f = fopen("myfile.txt", "r");
fread(buf, 1, sizeof(buf), f);
fclose(f);
```

Both cc65 and llvm-mos toolchains map `fopen`/`fread`/`fwrite`/`fclose` to the RIA OS calls, which drive FatFs on the RIA RP2350.

## Code pages and FAT short names

The active [[code-pages|code page]] affects both glyph display and FAT short-name (8.3) encoding. If a filename contains characters not in the active code page, FatFs falls back to the 8.3 short name with a `~1` suffix.

Default code page: **CP850** (Latin-1).

## littlefs (historical)

**littlefs** was an early candidate for internal flash storage (designed by Arm for bare flash devices, with wear leveling at the library level). It appeared in early RP6502 discussions (Ep6) but was ultimately not included in the final OS design — the RP6502-OS stores everything on removable USB media only.

---

## Related pages

- [[rp6502-os]] — OS API, file limits, `open()` device paths
- [[usb-controller]] — USB MSC drive support; speed benchmarks
- [[code-pages]] — code page / FAT short-name encoding interaction
