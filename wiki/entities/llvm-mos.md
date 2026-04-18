---
type: entity
tags: [rp6502, llvm-mos, toolchain, compiler, 6502, c, cpp]
related: [[cc65]], [[rp6502-abi]], [[rp6502-os]]
sources: [[yt-ep18-llvm-mos]], [[rp6502-abi]], [[release-notes]], [[rumbledethumps-discord]], [[vscode-llvm-mos]]
created: 2026-04-17
updated: 2026-04-18
---

# llvm-mos

**Summary**: llvm-mos is a fork of LLVM targeting the MOS 6502/65C02 family — the second officially supported toolchain for the RP6502, offering C++, floating point, 64-bit integers, and stronger optimization at the cost of a less mature standard library.

---

## What it is

llvm-mos is a port of the LLVM/Clang compiler infrastructure to the 6502 processor family. It provides:
- **Clang C compiler** — modern C11/C17/C23 dialects
- **C++ compiler** — full C++ support (classes, templates, RAII, etc.)
- **Optimizer** — LLVM optimization passes with more aggressive code generation than cc65
- **Floating point** — software float support
- **64-bit integers** — `long long` / `uint64_t` supported
- **Rust** — reportedly possible but not officially tested on RP6502 (as of Ep18)

## RP6502 support

llvm-mos has a Picocomputer SDK template alongside the [[cc65]] template. The standard library wrappers (stdio, unistd, fcntl, etc.) are provided for both toolchains; they call the same [[rp6502-os]] API underneath.

## ABI difference

llvm-mos uses a different calling convention and errno encoding from cc65. The RP6502 ABI handles this via `RIA_ATTR_ERRNO_OPT` — the C runtime sets this automatically, but assembly programs must set it manually. The `lseek` op-code argument order also differs between the two toolchains.

## Standard library status

As of [[yt-ep18-llvm-mos]] (2025): the llvm-mos standard library was "sparse" compared to cc65. The Picocomputer author expected it to catch up "this year," at which point llvm-mos would be generally preferable for new projects.

## Performance

From [[yt-ep18-llvm-mos]] Mandelbrot benchmark:
- LLVM-MOS produced significantly faster code from the same portably-written C source.
- cc65 can match or exceed this, but requires writing code in specific patterns that exploit cc65's optimizer (more developer effort).
- For code written without compiler-specific tuning, LLVM-MOS is faster.

## Comparison with cc65

| Aspect | [[cc65]] | llvm-mos |
|---|---|---|
| Maturity | Since 1998; stable | Newer; less stable |
| Standard library | Complete | Sparse (growing) |
| C++ support | No | Yes |
| Float / 64-bit | No | Yes |
| Code size | ~equivalent (large apps) | ~equivalent (large apps) |
| Performance | Good with tuned code | Better optimization by default |
| Best for | Most projects needing stdlib | C++, floats, or 64-bit math |

## SDK version lock issue (fixed in 6d99981)

llvm-mos-sdk v22 hardcoded a specific clang version in its cmake files, causing configure-time failures with a "mismatched clang version" error. Fixed in llvm-mos-sdk commit `6d99981`. If you hit this, update the SDK. (@tonyvr0759, 2026-02-24)

## `lrand()` random number

The RP6502 provides `lrand()` as its random number function (hardware entropy). Available in recent llvm-mos-sdk versions. Do not use `rand()` if true randomness is needed. (@rumbledethumps, 2026-04-02)

## Binary size vs. cc65

llvm-mos produces **larger binaries** than cc65 for most programs, and lacks good size optimization passes (expected to improve over time). cc65 is slightly slower in execution but produces smaller output — a meaningful trade-off on a system with 64 KB of RAM. (@rumbledethumps, 2025-12-02)

## VSCode development environment

Template repository: `picocomputer/vscode-llvm-mos`. Workflow is identical to cc65: F5 to build/flash/run, `.rp6502` config file auto-created, USB to RP6502-VGA port.

**Key setup notes** (from [[vscode-llvm-mos]]):
- When prompted for a CMake kit, choose **`[Unspecified]`**.
- LLVM-MOS PATH must be prepended via `.vscode/settings.json` → `cmake.environment.PATH` — do not modify your global PATH (conflicts with system LLVM).
- No IntelliSense shim needed — llvm-mos integrates natively with CMake.
- Entry point is `int main(void)` (standard C), not `void main()`.
- CMake uses `DATA file RESET file` (reads addresses from linker output, no hard-coding).
- See [[toolchain-setup]] for full install steps and side-by-side cc65 comparison.

## Related pages

- [[cc65]] — the primary toolchain and direct comparison
- [[rp6502-abi]] — ABI conventions and errno handling differences
- [[toolchain-setup]] — install steps and comparison table
- [[yt-ep18-llvm-mos]] — toolchain comparison episode
- [[known-issues]] — llvm-mos SDK version lock workaround
