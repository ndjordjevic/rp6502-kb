---
type: source
tags: [rp6502, youtube, llvm-mos, cc65, toolchain, compiler, comparison]
related:
  - "[[cc65]]"
  - "[[llvm-mos]]"
  - "[[rp6502-abi]]"
  - "[[development-history]]"
sources:
  - "[[youtube-playlist]]"
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep18 — Are You Keeping up with LLVM-MOS?

**Summary**: Side-by-side comparison of the two supported C toolchains for the Picocomputer — cc65 (stable, good stdlib) vs. LLVM-MOS (modern, C++/floats/64-bit, better optimization) — to help developers choose the right tool.

---

## Key topics

- **Both toolchains supported**: cc65 and LLVM-MOS both have official Picocomputer support; use either for new projects.
- **cc65**: since 1998; stable; good standard library (`stdio.h`, `stdlib.h`, etc.); mature for 6502-idiomatic code.
- **LLVM-MOS**: commits from 2001 but not yet stable for production; very little standard library currently; supports C++, latest C dialects, floating point, 64-bit integers, Rust (not investigated).
- **Code size**: roughly equivalent once applications are sufficiently large.
- **Performance**: LLVM-MOS gave a significant boost on the Mandelbrot benchmark with no extra optimization effort. cc65 can be made faster but requires crafting code specifically for cc65's optimizer.
- **Decision guide**:
  - Need good stdlib → cc65 is the only choice.
  - Need C++, floats, or 64-bit integers → LLVM-MOS is the only choice.
  - Once LLVM-MOS stdlib catches up, LLVM-MOS will be generally preferable.
- **Historical note**: the cc65 Mandelbrot demo from Ep8 is re-benchmarked here for comparison.

## Related pages

- [[cc65]] — cc65 toolchain details
- [[llvm-mos]] — LLVM-MOS toolchain details
- [[rp6502-abi]] — ABI differences between the two toolchains
- [[development-history]] — Era E: toolchain split story
