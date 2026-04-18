---
type: source
tags: [rp6502, cc65, toolchain, memory-layout, platform]
related: [[cc65]], [[memory-map]], [[rp6502-abi]], [[rom-file-format]]
sources: [[cc65-rp6502-platform]]
created: 2026-04-18
updated: 2026-04-18
---

# cc65 RP6502 Platform Documentation

**Summary**: Official cc65 documentation page for the Picocomputer 6502 target platform — covers binary format, memory layout, and platform-specific header files. Authoritative source for cc65 C runtime memory conventions.

---

## Source

- URL: https://cc65.github.io/doc/rp6502.html
- Author: Ullrich von Bassewitz (cc65 project)
- Clipped: 2026-04-18
- Raw file: `raw/web/cc65.github.io/Picocomputer 6502 — cc65 documentation.md`

---

## Key facts

### Memory layout (cc65 C runtime)

| Region | Address / location | Notes |
|---|---|---|
| C run-time stack | `$FEFF`, grows downward | Fixed by cc65 RP6502 platform config |
| C heap | End of program, grows up toward stack | Dynamic allocation via `malloc()` |
| RAM | `$0000`–`$FEFF` | 63.75 KB; default load address is `$0200` |
| ROM | None in 6502 space | RP6502 has no ROM at any 6502 address |
| VIA | `$FFD0` | 16-byte W65C22S register block |
| RIA | `$FFE0` | 32-byte RIA register block |
| User I/O | `$FF00`–`$FFCF` | Unassigned (user expansion) |

### Binary format

The cc65 linker outputs plain machine language without any prefix or postfix. The IDEs (VSCode templates) convert this into `.rp6502` ROM files for upload/install.

### Platform header files

- `rp6502.h` — C header for RP6502-specific operations (required for `xreg()`, `set_irq()`, `RIA.*` struct access)
- `rp6502.inc` — Assembly include file for the same definitions

---

## Cross-references

This source corroborates and provides authoritative backing for:
- [[memory-map]] — stack at `$FEFF`, heap at program end, no ROM
- [[cc65]] entity — C runtime memory layout, stack limit implications
- [[rp6502-abi]] — why last argument convention uses A/X rather than stack (cc65 fastcall)
- [[toolchain-setup]] — load address `$0200`, platform header usage

---

## Related pages

- [[cc65]] — cc65 toolchain entity
- [[memory-map]] — full RP6502 address space
- [[rp6502-abi]] — ABI modeled on cc65 fastcall
- [[toolchain-setup]] — development environment setup
- [[cc65-vs-llvm-mos]] — toolchain comparison synthesis
