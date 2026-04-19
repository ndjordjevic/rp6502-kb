---
type: source
tags: [rp6502, youtube, cc65, vscode, sdk, cmake]
related:
  - "[[cc65]]"
  - "[[rp6502-abi]]"
  - "[[rom-file-format]]"
  - "[[development-history]]"
sources:
  - "[[youtube-playlist]]"
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep09 — C Programming Setup

**Summary**: Demonstrates the cc65-based development environment for the Picocomputer: VSCode template repository, CMake project structure, `rp6502.py` upload tool, and a live demo using standard C file I/O on FAT storage.

---

## Key topics

- **cc65 chosen** as the primary C toolchain (includes macro assembler); demonstrated with a simple file counter program using `fopen`/`fread`/`fwrite`.
- **VSCode template repo**: `use this template` on GitHub → create repo → clone → SDK git submodule init. Easiest on Linux; VSCode remote development works for Windows/Mac users.
- **Ctrl+Shift+B**: VSCode build task that compiles, packages ROM, uploads over USB, and executes on the Picocomputer.
- **CMakeLists.txt structure**: `rp6502_executable()` for the build target; source files listed; SDK added as subdirectory.
- **`rp6502.py`**: Python script for remotely controlling a Picocomputer — create ROM files, upload, run. Used by VSCode tasks and also runnable from the command line.
- **`config.ld`**: controls how cc65 uses 6502 memory (unlikely to need changes unless hardware changes significantly).
- **Intermediate assembly**: generated `.s` files available in `build/` folder for inspection.
- **Key point**: standard POSIX-like C code (file open/read/write) works unchanged — "boring is good."

## Related pages

- [[cc65]] — the toolchain demonstrated
- [[rp6502-abi]] — how C maps to OS calls
- [[rom-file-format]] — the `.rp6502` file built by CMake
- [[development-history]] — Era D: cc65 SDK availability
