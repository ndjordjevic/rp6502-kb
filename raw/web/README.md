# Web Clips — RP6502

Pages clipped from the official Picocomputer documentation site using Obsidian Web Clipper.

## Naming convention

```
<Page Title> — <Site Name>.md
```

Example: `RP6502-RIA — Picocomputer  documentation.md`

Files are self-describing by name. Sub-folder `picocomputer.github.io/` mirrors the source domain.

## Files

Source site: [picocomputer.github.io](https://picocomputer.github.io/). Clipped: 2026-04-15.

| File | Page | URL |
| --- | --- | --- |
| `picocomputer.github.io/Picocomputer 6502 — Picocomputer  documentation.md` | Index / overview | https://picocomputer.github.io/ |
| `picocomputer.github.io/Hardware — Picocomputer  documentation.md` | Build guide, BOM, connectors | https://picocomputer.github.io/hardware.html |
| `picocomputer.github.io/RP6502-RIA — Picocomputer  documentation.md` | RIA firmware API | https://picocomputer.github.io/ria.html |
| `picocomputer.github.io/RP6502-RIA-W — Picocomputer  documentation.md` | RIA-W (Wi-Fi variant) | https://picocomputer.github.io/ria_w.html |
| `picocomputer.github.io/RP6502-VGA — Picocomputer  documentation.md` | VGA firmware API | https://picocomputer.github.io/vga.html |
| `picocomputer.github.io/RP6502-OS — Picocomputer  documentation.md` | OS API reference | https://picocomputer.github.io/os.html |

Source site: [cc65.github.io](https://cc65.github.io/). Clipped: 2026-04-18.

| File | Page | URL |
| --- | --- | --- |
| `cc65.github.io/Picocomputer 6502 — cc65 documentation.md` | cc65 RP6502 platform docs (memory layout, binary format, headers) | https://cc65.github.io/doc/rp6502.html |

Source site: [6502.org](https://6502.org/tutorials/). Clipped: 2026-04-18.

| File | Page | URL |
| --- | --- | --- |
| `6502.org/65C02 Opcodes — 6502.org.md` | 65C02 vs NMOS 6502: new addressing modes, new instructions, Rockwell/WDC variants, bug fixes, undocumented NOPs | https://6502.org/tutorials/65c02opcodes.html |
| `6502.org/Decimal Mode — 6502.org.md` | BCD arithmetic: flag validity per processor, cycle counts, interrupt D-flag behavior, verification test programs | https://6502.org/tutorials/decimal_mode.html |
| `6502.org/The Overflow (V) Flag Explained — 6502.org.md` | V flag: which instructions affect it, two's complement overflow, SO pin, 65C02 BIT new modes | https://6502.org/tutorials/vflag.html |
| `6502.org/Investigating Interrupts — 6502.org.md` | IRQ/NMI/BRK mechanics, ISR setup, WAI ultra-fast response, VIA 6522 usage, ring buffer, performance data | https://6502.org/tutorials/interrupts.html |
| `6502.org/Register Preservation Using The Stack — 6502.org.md` | A/X/Y stack preservation: 65C02 PHX/PHY simplification vs 6502 workarounds, BRK/IRQ B-flag disambiguation, cycle costs | https://6502.org/tutorials/register_preservation.html |
| `6502.org/Beyond 8-bit Unsigned Comparisons — 6502.org.md` | Equality, unsigned, signed comparisons extended to 16/24-bit; N XOR V signed method; SO pin caveat; test program | https://6502.org/tutorials/compare_beyond.html |
| `6502.org/NMOS 6502 Opcodes — 6502.org.md` | Complete NMOS 6502 opcode reference: all 56 instructions, modes, hex, cycle counts, JMP indirect bug, zero-page wrap-around | https://6502.org/tutorials/6502opcodes.html |
| `6502.org/6502 Compare Instructions — 6502.org.md` | Beginner CMP/CPX/CPY guide: flag results table, branch selection for unsigned/signed, 5 practical code examples | https://6502.org/tutorials/compare_instructions.html |

## Refresh procedure

Re-clip a page with Obsidian Web Clipper when the upstream docs are updated. Add a new row to the ## Files table if a new page is clipped, and update `raw/README.md`.
