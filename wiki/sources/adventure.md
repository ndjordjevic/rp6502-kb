---
type: source
tags: [rp6502, cc65, rom, adventure, game, porting]
related:
  - "[[rom-file-format]]"
  - "[[toolchain-setup]]"
  - "[[cc65]]"
  - "[[rp6502-os]]"
  - "[[examples]]"
sources: []
created: 2026-04-18
updated: 2026-04-18
---

# picocomputer/adventure

**Summary**: The official Picocomputer port of the classic Colossal Cave Adventure text game — a clean example of how to adapt an existing C program to run on RP6502 using named ROM assets and the cc65 toolchain.

---

## Source

- GitHub: `https://github.com/picocomputer/adventure`
- Local clone: `raw/github/picocomputer/adventure/` (commit `6ac165f`)
- Latest tag: `v20260225` (commit `1228d14`, 2026-02-25)
- License: upstream `troglobit/adventure` (public domain / Colossal Cave)

## What it is

Colossal Cave Adventure (ADVENT, by Crowther and Woods, ~1975) ported to RP6502 using the cc65 toolchain. The game logic itself comes from the [troglobit/adventure](https://github.com/troglobit/adventure) C port — included as a git submodule in `troglobit/`. The RP6502-specific adaptation lives in just two files.

## File structure

```
CMakeLists.txt         -- build + ROM asset declarations
src/config.h           -- DATADIR and SAVEDIR defines
src/err.c / err.h      -- platform error wrapper
tools/                 -- cc65 CMake toolchain (same as vscode-cc65 template)
troglobit/             -- submodule: troglobit/adventure (uninitialized in kb clone)
.vscode/               -- CMake/IntelliSense settings
```

## RP6502 adaptations

### config.h — redirect data files to ROM filesystem

```c
#define SAVEDIR "."
#define DATADIR "ROM:"
```

`DATADIR "ROM:"` is the key: the troglobit game code opens the four data files with paths like `DATADIR "advent1.txt"` → `"ROM:advent1.txt"`. The RP6502-OS maps this to the named asset `advent1.txt` packed into the ROM file. No change needed in the upstream game code — just changing this one define redirects all file I/O to the ROM filesystem.

### err.c — platform error wrapper

The troglobit code calls `err()` and `warn()` (POSIX-style error exits); the RP6502 port provides a thin wrapper that uses `strerror(errno)` and `fprintf(stderr, ...)` — the OS provides both.

## Build: CMakeLists.txt

```cmake
project(ADVENT4 C ASM)

add_subdirectory(tools)

add_executable(adventure)
rp6502_asset(adventure /advent1.txt troglobit/src/advent1.txt)
rp6502_asset(adventure /advent2.txt troglobit/src/advent2.txt)
rp6502_asset(adventure /advent3.txt troglobit/src/advent3.txt)
rp6502_asset(adventure /advent4.txt troglobit/src/advent4.txt)
rp6502_executable(adventure
    DATA 0x200
    RESET 0x200
)
```

- Four named ROM assets: `/advent1.txt`–`/advent4.txt`. The leading `/` is the address — a non-numeric path means "filename in the ROM filesystem" (see [[rom-file-format]]).
- `DATA 0x200 RESET 0x200` — cc65 entry point at `$0200`.
- `rp6502_asset()` called four times before `rp6502_executable()` — ordering is enforced (calling in wrong order triggers a CMake FATAL_ERROR).

## Named ROM asset pattern

This repo is the canonical example of the **named ROM asset** workflow introduced in v0.18 (Feb 2026):

1. Declare assets before the executable in CMake:
   ```cmake
   rp6502_asset(adventure /advent1.txt troglobit/src/advent1.txt)
   ```
2. At runtime the OS serves them as files:
   ```c
   fd = open("ROM:advent1.txt", O_RDONLY);
   ```
3. The game code never knows it's talking to a ROM — it uses standard POSIX `open()`/`read()`/`close()`.

## Porting pattern for existing C programs

The adventure port shows a minimal, clean approach to porting an existing C program:

| Problem | Solution |
|---------|----------|
| Game reads data files by path | Change `DATADIR` define to `"ROM:"` → zero upstream code changes |
| Game uses `err()`/`warn()` (POSIX error API) | Write a thin `err.c` using `strerror(errno)` + `fprintf(stderr, ...)` |
| Data files bundled at build time | `rp6502_asset()` packs them as named ROM assets |

The `tools/` directory is identical to the [[vscode-cc65]] template (cc65 IntelliSense shim, `rp6502.py`, CMake macros) — drop it in from the template to start any cc65 project.

## Commit history (all by rumbledethumps)

| Commit | Date | Summary |
|--------|------|---------|
| `6ac165f` | 2026-04-11 | rename executable |
| `0617b51` | 2026-02-27 | minor tool fix |
| `da5d723` | 2026-02-27 | readme |
| `1228d14` | 2026-02-25 | make asset out dir ← **v20260225 tag** |
| `322ef90` | 2026-02-26 | BIG ROM (#1) — full named-asset conversion |
| `c5d4255` | 2025-12-04 | update rp6502.py for v0.15 |
| `4f9ab01` | 2025-09-26 | use errno instead of `__oserror` |
| `dc6ca5e` | 2023-12-13 | add mapfile |
| `73c2f82` | 2023-11-24 | use oserror instead of errno ← **v20231124 tag** |
| `9151726` | 2023-11-23 | verbose err.c |
| `8c2e2a8` | 2023-11-23 | first commit |

Notable: the "BIG ROM (#1)" commit on 2026-02-26 converted the project from the old asset format to the current named-asset system (v0.18-era).

## Related pages

- [[rom-file-format]] — named asset format and CMake workflow
- [[toolchain-setup]] — cc65 install + project creation
- [[cc65]] — cc65 toolchain entity
- [[rp6502-os]] — OS `open("ROM:...")` path handling
- [[vscode-cc65]] — the `tools/` directory template this repo uses
- [[examples]] — other RP6502 example programs
- [[yt-ep07-operating-system]] — Ep7 features a Colossal Cave Adventure live demo
