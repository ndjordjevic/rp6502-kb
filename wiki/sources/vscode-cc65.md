---
type: source
tags: [rp6502, cc65, toolchain, vscode, cmake, template]
related:
  - "[[cc65]]"
  - "[[rp6502-abi]]"
  - "[[rom-file-format]]"
  - "[[toolchain-setup]]"
sources:
  - "[[yt-ep09-c-programming-setup]]"
  - "[[rp6502-github-repo]]"
created: 2026-04-18
updated: 2026-04-18
---

# picocomputer/vscode-cc65

**Summary**: The official VSCode project template for cc65-based RP6502 development — includes hello-world C and assembly starters, a CMake toolchain file, and the `rp6502.py` build/flash/run tool.

---

## Repository overview

- Commit `794a6f2` (2026-04-17, tag: none)
- All commits by `rumbledethumps`; actively maintained (most recent: telnet support)
- Key files: `CMakeLists.txt`, `tools/rp6502.cmake`, `tools/cc65.cmake`, `tools/rp6502.py`, `src/main.c`, `src/main.s`
- `.github/copilot-instructions.md` — constraints for AI-assisted coding in this project

## Key facts

- `rp6502.py` no longer requires `pyserial` — replaced with custom cross-platform serial implementation (POSIX + Windows native). Changed in commit `ec2598c` (Jan 2026, "remove pyserial requirement and change to rpw65").
- Telnet support added 2026-04-17.
- The CMake toolchain wraps `cl65` through an IntelliSense-compatible shim (`cc65.cmake`) to enable VS Code problem matchers and IntelliSense — do not disable or override.
- `rp6502_asset()` must be called **before** `rp6502_executable()` for the same target.
- `help.txt` is packaged as a named ROM asset accessible at `ROM:help` — displayed by the HELP and INFO monitor commands.

## Scope

| Item | Status |
|------|--------|
| `README.md` — install and getting-started | [x] ingested |
| `CMakeLists.txt` + `tools/rp6502.cmake` + `tools/cc65.cmake` | [x] ingested |
| `src/main.c` + `src/main.s` | [x] ingested |
| `.github/copilot-instructions.md` | [x] ingested |
| `tools/rp6502.py` (full Python tool) | [-] skipped — implementation detail; interface documented in toolchain-setup |

## Related pages

- [[cc65]] — cc65 compiler entity
- [[toolchain-setup]] — cc65 install and project workflow (derived from this source)
- [[rom-file-format]] — output format produced by `rp6502_executable()`
- [[rp6502-abi]] — ABI the cc65 fastcall convention maps to
