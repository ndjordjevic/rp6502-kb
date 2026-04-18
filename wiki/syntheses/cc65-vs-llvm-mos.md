---
type: synthesis
tags: [rp6502, cc65, llvm-mos, toolchain, comparison, synthesis]
related: [[cc65]], [[llvm-mos]], [[rp6502-abi]], [[toolchain-setup]], [[rom-file-format]]
sources: [[yt-ep18-llvm-mos]], [[rp6502-abi]], [[vscode-cc65]], [[vscode-llvm-mos]], [[rumbledethumps-discord]]
created: 2026-04-18
updated: 2026-04-18
---

# cc65 vs llvm-mos — Toolchain Comparison

**Summary**: A synthesis comparing the two officially supported C toolchains for the RP6502 — [[cc65]] and [[llvm-mos]] — covering language features, performance, binary size, maturity, and when to choose each.

---

## Quick recommendation

**Start with cc65** unless you need C++, floating point, or 64-bit integers. cc65 has a more complete standard library, smaller binaries, and has been the primary RP6502 toolchain since the project began.

---

## Feature comparison

| Aspect | cc65 | llvm-mos |
|---|---|---|
| In use since | 1998 (mature) | 2020s (newer) |
| Language standard | C (roughly C89) | C11/C17/C23 |
| C++ support | ❌ | ✅ Full C++ |
| `float` / `double` | ❌ | ✅ Software float |
| `long long` / `uint64_t` | ❌ | ✅ |
| `int` width | **16-bit** | **16-bit** |
| Standard library | Complete (stdio, stdlib, string, time, …) | Sparse but growing |
| RP6502 template repo | `picocomputer/vscode-cc65` | `picocomputer/vscode-llvm-mos` |
| Binary size | Smaller | Larger |
| Performance (untuned code) | Good | Better (LLVM optimizer) |
| Performance (tuned code) | Comparable | Comparable |
| `errno` convention | cc65 fastcall | llvm-mos (different) — set `RIA_ATTR_ERRNO_OPT` |
| Rust support | ❌ | Reportedly possible (untested on RP6502) |
| Best for | Most projects | C++, floats, numerical algorithms |

---

## Performance

From [[yt-ep18-llvm-mos]] Mandelbrot benchmark (Ep18):
- LLVM-MOS produced significantly faster code from the **same portably-written C source** — without any compiler-specific tuning.
- cc65 can match or exceed LLVM-MOS, but requires **writing code in patterns that exploit cc65's optimizer** (e.g., `near` pointers, loop restructuring, using `register` keyword strategically).
- For general code written without compiler-specific tuning, **LLVM-MOS is faster by default**.

---

## Binary size

cc65 produces **smaller binaries** than llvm-mos for most programs. This matters on a system with only 64 KB of RAM — smaller programs leave more heap and stack for data. llvm-mos has limited size-optimization passes (expected to improve). (@rumbledethumps, 2025-12-02)

---

## Standard library completeness

cc65 provides `stdio.h`, `stdlib.h`, `string.h`, `unistd.h`, `fcntl.h`, `time.h` and more, all mapped to RP6502-OS calls transparently. The llvm-mos library was described as "sparse" in Ep18 (2025), with the author expecting it to catch up. If your project relies on `printf`, `fopen`, `malloc`, `localtime`, etc., **cc65 is currently safer**.

---

## ABI differences

Both toolchains call the same [[rp6502-abi]] underlying OS, but differ in calling conventions:
- **cc65 fastcall**: last argument in A/X registers; earlier args on XSTACK, pushed left-to-right.
- **llvm-mos**: different calling convention; `RIA_ATTR_ERRNO_OPT` flag must be set manually in assembly programs. The `lseek` op-code argument order also differs between toolchains.

Assembly code that calls OS functions must be written with the target toolchain in mind, or use the toolchain-agnostic C wrapper headers.

---

## Installation gotchas

### cc65

> **Package manager versions will not work.** `brew install cc65` or `apt install cc65` installs v2.18 from May 2019 — years before the RP6502 project.

Build from the **picocomputer fork**: `github.com/picocomputer/cc65` (or use the picocomputer-provided snapshot binaries). Required until upstream PR #2844 (errno rework) merges.

### llvm-mos

- When prompted for a CMake kit, choose **`[Unspecified]`**.
- Prepend LLVM-MOS to PATH via `.vscode/settings.json` → `cmake.environment.PATH` — do not modify your global PATH (conflicts with system LLVM).
- If you hit "mismatched clang version" configure errors, update llvm-mos-sdk to commit `6d99981` or later (fixes SDK v22 version lock).

---

## DST / time zone support (cc65-specific)

`localtime()` with DST handling was contributed upstream to cc65 by @rumbledethumps (PR #2911, merged 2026-01-04). The RP6502 monitor `SET TZ` accepts POSIX TZ strings or city names. Required for correct local time in RTC-aware apps. This feature is **cc65-specific** — llvm-mos may have different timezone support.

---

## Random number generation

- **cc65**: `randomize()` seeds with hardware entropy (from `RIA_ERRNO` TRNG).
- **llvm-mos**: use `lrand()` (available in recent llvm-mos-sdk versions) for true hardware randomness. Do not use `rand()` if true randomness is required. (@rumbledethumps, 2026-04-02)

---

## Summary decision table

| Use case | Toolchain |
|---|---|
| First project / learning | cc65 |
| Needs C++ classes or RAII | llvm-mos |
| Needs `float` or `double` | llvm-mos |
| Needs `int64_t` / `uint64_t` | llvm-mos |
| Maximum binary performance, willing to tune | cc65 (or either) |
| Smallest possible binary | cc65 |
| Complete `stdio` / `stdlib` | cc65 |
| Numerical / scientific code | llvm-mos |

---

## Related pages

- [[cc65]] — cc65 entity page
- [[llvm-mos]] — llvm-mos entity page
- [[toolchain-setup]] — installation and project setup
- [[rp6502-abi]] — the ABI both toolchains target
- [[yt-ep18-llvm-mos]] — Ep18 toolchain comparison video
- [[known-issues]] — cc65 Homebrew warning, cmake build regressions, llvm-mos SDK lock
