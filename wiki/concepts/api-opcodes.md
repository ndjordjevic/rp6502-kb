---
type: concept
tags: [rp6502, os, api, opcodes, abi]
related:
  - "[[ria-registers]]"
  - "[[rp6502-abi]]"
  - "[[rp6502-os]]"
  - "[[rp6502-ria]]"
  - "[[cc65]]"
  - "[[llvm-mos]]"
sources:
  - "[[rp6502-github-repo]]"
created: 2026-04-16
updated: 2026-04-16
---

# API Op-Codes

**Summary**: The complete table of numeric op-codes that the 6502 writes to `RIA_OP` (`$FFEF`) to invoke OS services. Derived from the dispatch table in `src/ria/main.c`.

---

## How op-codes work

The 6502 writes a single byte to `$FFEF` (`RIA_OP`). The RIA's `main_api()` function dispatches on that byte to the correct handler. Any unrecognized op-code returns `ENOSYS`. See [[ria-registers]] for the full call sequence and [[rp6502-abi]] for argument passing conventions.

---

## Complete op-code table

### Attribute / system (0x01–0x0B)

| Op | Handler | Description |
| --- | --- | --- |
| `0x01` | `pix_api_xreg` | Set an XREG on a PIX device — see [[xreg]] |
| `0x02` | `atr_api_phi2` | *(deprecated)* Get/set PHI2 clock speed |
| `0x03` | `atr_api_code_page` | *(deprecated)* Get/set OEM code page |
| `0x04` | `atr_api_lrand` | *(deprecated)* Random number |
| `0x06` | `atr_api_errno_opt` | *(deprecated)* Get/set errno mapping ([[cc65]] vs [[llvm-mos]]) |
| `0x08` | `pro_api_argv` | Read argv — process arguments passed by launcher |
| `0x09` | `pro_api_exec` | Execute a ROM (`ria_execl` / `ria_execv`) |
| `0x0A` | `atr_api_get` | Generic attribute get (replaces deprecated 0x02/0x03/0x04/0x06) |
| `0x0B` | `atr_api_set` | Generic attribute set |

### Clock / time (0x0D–0x12)

| Op | Handler | Description |
| --- | --- | --- |
| `0x0D` | `clk_api_tzset` | Set timezone (POSIX TZ string, e.g. `PST8PDT,M3.2.0/2,M11.1.0/2`) |
| `0x0E` | `clk_api_tzquery` | Query timezone info |
| `0x0F` | `clk_api_clock` | `clock()` — processor time used |
| `0x10` | `clk_api_get_res` | `clock_getres()` — clock resolution |
| `0x11` | `clk_api_get_time` | `clock_gettime()` — current wall-clock time |
| `0x12` | `clk_api_set_time` | `clock_settime()` — set wall-clock time |

### File I/O (0x14–0x1E)

| Op | Handler | Description |
| --- | --- | --- |
| `0x14` | `std_api_open` | `open(path, flags, mode)` |
| `0x15` | `std_api_close` | `close(fd)` |
| `0x16` | `std_api_read_xstack` | `read()` into XSTACK buffer |
| `0x17` | `std_api_read_xram` | `read()` directly into XRAM |
| `0x18` | `std_api_write_xstack` | `write()` from XSTACK buffer |
| `0x19` | `std_api_write_xram` | `write()` from XRAM |
| `0x1A` | `std_api_lseek_cc65` | `lseek()` — cc65 32-bit offset convention |
| `0x1D` | `std_api_lseek_llvm` | `lseek()` — llvm-mos 64-bit offset convention |
| `0x1E` | `std_api_syncfs` | `syncfs()` — flush filesystem caches to storage |

### Directory and filesystem (0x1B–0x2E)

| Op | Handler | Description |
| --- | --- | --- |
| `0x1B` | `dir_api_unlink` | `unlink(path)` — delete file |
| `0x1C` | `dir_api_rename` | `rename(old, new)` |
| `0x1F` | `dir_api_stat` | `stat(path, buf)` |
| `0x20` | `dir_api_opendir` | `opendir(path)` |
| `0x21` | `dir_api_readdir` | `readdir(dir)` |
| `0x22` | `dir_api_closedir` | `closedir(dir)` |
| `0x23` | `dir_api_telldir` | `telldir(dir)` |
| `0x24` | `dir_api_seekdir` | `seekdir(dir, loc)` |
| `0x25` | `dir_api_rewinddir` | `rewinddir(dir)` |
| `0x26` | `dir_api_chmod` | `chmod(path, mode)` |
| `0x27` | `dir_api_utime` | `utime(path, times)` — set file timestamps |
| `0x28` | `dir_api_mkdir` | `mkdir(path, mode)` |
| `0x29` | `dir_api_chdir` | `chdir(path)` |
| `0x2A` | `dir_api_chdrive` | `chdrive(drive)` — switch active drive (FatFs extension) |
| `0x2B` | `dir_api_getcwd` | `getcwd(buf, size)` |
| `0x2C` | `dir_api_setlabel` | Set volume label |
| `0x2D` | `dir_api_getlabel` | Get volume label |
| `0x2E` | `dir_api_getfree` | Get free space on drive |

---

## Notes

- Op-codes `0x05`, `0x07`, `0x0C`, `0x13` are unassigned — writing them returns `ENOSYS`.
- The `lseek` split (0x1A vs 0x1D) exists because [[cc65]] and [[llvm-mos]] use different conventions for the 64-bit offset argument. A cc65 program uses 0x1A; a llvm-mos program uses 0x1D.
- Op-codes 0x02/0x03/0x04/0x06 are deprecated but still functional. The generic 0x0A/0x0B attribute system replaces them.
- `std_api_read_xram` / `std_api_write_xram` bypass XSTACK entirely and DMA directly into/from the 64 KB [[xram]] space — preferred for bulk I/O.

## Related pages

- [[ria-registers]] · [[rp6502-abi]] · [[rp6502-os]] · [[xreg]] · [[xram]]
