---
type: source
tags: [rp6502, llvm-mos, toolchain, vscode, cmake, template]
related:
  - "[[llvm-mos]]"
  - "[[rp6502-abi]]"
  - "[[rom-file-format]]"
  - "[[toolchain-setup]]"
sources:
  - "[[yt-ep18-llvm-mos]]"
  - "[[rp6502-github-repo]]"
created: 2026-04-18
updated: 2026-04-18
---

# picocomputer/vscode-llvm-mos

**Summary**: The official VSCode project template for llvm-mos-based RP6502 development — includes a hello-world C starter, CMake integration via `llvm-mos-sdk`, and the same `rp6502.py` build/flash/run tool as the cc65 template.

---

## Repository overview

- Commit `17af418` (2026-04-17, tag: none)
- All commits by `rumbledethumps`; maintained in sync with `vscode-cc65`
- Key files: `CMakeLists.txt`, `tools/CMakeLists.txt` (identical macros to cc65 template), `tools/rp6502.py`, `src/main.c`
- No assembly hello-world starter (llvm-mos programs use standard C entry point `int main(void)`)
- No separate toolchain cmake file — llvm-mos integrates natively with CMake

## Key differences from vscode-cc65

| | vscode-cc65 | vscode-llvm-mos |
|---|---|---|
| Languages | `C ASM` | `C CXX ASM` |
| SDK setup | `find_program(cl65 ...)` | `find_package(llvm-mos-sdk REQUIRED)` |
| Addresses | Explicit (`DATA 0x200 RESET 0x200`) | From linker (`DATA file RESET file`) |
| Entry point | `void main()` | `int main(void)` |
| IntelliSense shim | Yes (`tools/cc65.cmake`) | No (native CMake support) |
| PATH gotcha | None | Conflicts with system LLVM installations |
| CMake kit | Any | Must choose `[Unspecified]` |

## PATH conflict warning

LLVM-MOS must be in PATH, but this can conflict with the system LLVM (e.g., the one installed by your OS package manager). Fix: add `.vscode/settings.json` to prepend only the llvm-mos `bin/` to the CMake environment:

```json
{
    "cmake.environment": {
        "PATH": "~/llvm-mos/bin:${env:PATH}"
    }
}
```

This scopes the PATH override to CMake only, leaving the rest of the system unaffected.

## `tools/CMakeLists.txt`

Identical to the cc65 template — same `rp6502_executable()` and `rp6502_asset()` macros. The same ordering rule applies: `rp6502_asset()` must be called before `rp6502_executable()`.

## Scope

| Item | Status |
|------|--------|
| `README.md` — install and getting-started | [x] ingested |
| `CMakeLists.txt` + `tools/CMakeLists.txt` | [x] ingested |
| `src/main.c` | [x] ingested |
| `.github/copilot-instructions.md` | [x] ingested |
| `tools/rp6502.py` | [-] skipped — same tool as vscode-cc65; see [[vscode-cc65]] |

## Related pages

- [[llvm-mos]] — llvm-mos compiler entity
- [[toolchain-setup]] — full install steps and llvm-mos section
- [[vscode-cc65]] — cc65 counterpart template
- [[rom-file-format]] — `.rp6502` output format
