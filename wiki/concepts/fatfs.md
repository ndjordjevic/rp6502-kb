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

## Directory listing API

From `dir.c` in `picocomputer/examples`:

```c
int dirdes = f_opendir(path);         // returns descriptor; < 0 on error
f_stat_t *fi = malloc(sizeof(f_stat_t));
while (1) {
    f_readdir(fi, dirdes);
    if (!fi->fname[0]) break;         // empty fname = end of directory
    // fi->fsize, fi->fattrib, fi->fdate, fi->ftime, fi->fname
}
f_closedir(dirdes);
```

`f_stat_t` field summary:

| Field | Type | Description |
|-------|------|-------------|
| `fsize` | long | File size in bytes |
| `fdate` | uint16 | FAT date: bits [15:9]=year-1980, [8:5]=month, [4:0]=day |
| `ftime` | uint16 | FAT time: bits [15:11]=hours, [10:5]=minutes, [4:0]=seconds/2 |
| `fattrib` | uint8 | Attribute flags (see below) |
| `fname` | char[] | Filename (null-terminated) |

Attribute flags: `AM_RDO`=0x01 (read-only), `AM_HID`=0x02 (hidden), `AM_SYS`=0x04 (system), `AM_DIR`=0x10 (directory), `AM_ARC`=0x20 (archive).

Additional FatFS calls from `dir.c`:

```c
f_getlabel("", label_buf);                          // volume label
f_getcwd(path_buf, sizeof(path_buf));               // current directory
f_getfree("", &free_blocks, &total_blocks);         // 512-byte blocks
```

Errors use standard `errno`; check `errno` after any `< 0` return.

---

## Related pages

- [[rp6502-os]] — OS API, file limits, `open()` device paths
- [[usb-controller]] — USB MSC drive support; speed benchmarks
- [[code-pages]] — code page / FAT short-name encoding interaction
