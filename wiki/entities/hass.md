---
type: entity
tags: [rp6502, assembler, community, razemos, 65c02, wdc, hass]
related:
  - "[[razemos]]"
  - "[[razemos-repo]]"
  - "[[65c02-instruction-set]]"
  - "[[65c02-addressing-modes]]"
  - "[[cc65]]"
sources:
  - "[[razemos-repo]]"
created: 2026-04-19
updated: 2026-04-19
---

# HASS — Handy ASSembler

**Summary**: HASS is a native two-pass assembler for the WDC 65C02S running directly on the RP6502 Picocomputer, bundled with [[razemos]]. It supports the full 65C02 instruction set including WDC extensions, interactive editing, a built-in software emulator, and cycle counting.

---

## Overview

HASS ships as a standalone `.rp6502` ROM (`hass.rp6502`) and is a component of the [[razemos]] community shell. It is a **native on-device assembler** — programs are written and assembled on the Picocomputer itself without a PC-side toolchain.

Full documentation: `docs/hass-manual-en.txt` (also `hass-manual-pl.txt` in Polish), or type `@MANUAL` in interactive mode.

---

## Invocation

```
hass [source.asm] [-o output.bin] [-i]
```

| Option | Description |
|--------|-------------|
| `source.asm` | Input file (if omitted: interactive mode) |
| `-o output.bin` | Output binary (default: `out.bin`) |
| `-i` | Load source, then enter interactive mode instead of assembling |

Output: `out.bin` (raw binary), `out.lst` (listing file).

**Examples:**
```
hass program.asm                   # assemble to out.bin
hass program.asm -o program.bin    # assemble to named file
hass program.asm -o prog.exe       # .exe loadable by razemOS shell
hass                               # interactive: enter code, @MAKE to assemble
hass program.asm -i                # load file, continue editing interactively
```

---

## Interactive mode commands

All `@` commands are available only in interactive mode and are never stored in the source buffer. Case-insensitive.

| Command | Description |
|---------|-------------|
| `@SAVE filename` | Save buffer to file (does not stop editing) |
| `@LOAD filename` | Clear buffer, load file into it |
| `@APPEND filename [startline]` | Append or insert file into buffer at optional line |
| `@NEW` | Clear buffer and symbol table |
| `@MAKE [filename]` | Assemble current buffer, write binary; continues editing |
| `@LIST [from [to]]` | Display buffered lines with 1-based numbers |
| `@EDIT N text` | Replace line N with given text |
| `@DEL N` | Delete line N (subsequent lines shift up) |
| `@INS N text` | Insert line before N (subsequent lines shift down) |
| `@SYMBOLS` | List all symbols (labels + constants) with hex values |
| `@CYCLES [from [to]]` | Count base cycles for current buffer or line range |
| `@TRACE [R]` | Run in built-in software emulator (interactive or run mode) |
| `@CD [path]` | Change or show current working directory |
| `@DIR [path]` | List files in current or given directory |
| `@MANUAL [en\|pl] [N]` | Show manual, optionally in Polish, jump to chapter N |
| `@EXIT` | End session; auto-saves buffer to `last.hass` |

---

## @TRACE — built-in software emulator

`@TRACE` assembles the current buffer and runs it in a **built-in W65C02S software emulator**:

- **Interactive (no arg)**: single-step mode. Each step shows PC, disassembly, flags (NVDIIZC), registers A, X, Y, SP.
  - `ENTER` — execute one instruction
  - `R` — run continuously until BRK/STP or 10,000-step limit
  - `Z` — dump Zero Page ($00–$FF)
  - `Q` — quit tracer
- **`@TRACE R`**: run mode — executes until BRK/STP/limit, prints summary.
- Supports **self-modifying code**: writes to code area stored in XRAM and read back correctly.
- Cycle count includes branch-taken and page-crossing penalties (accurate runtime count, unlike `@CYCLES`).
- Memory model: ZP ($0000–$00FF), stack ($0100–$01FF), code area (read/write); other reads return $FF.

---

## @CYCLES — cycle counting

`@CYCLES [from [to]]` reports the **base cycle count** for the assembled program or a line range.

> **Note**: counts are minimum; branch instructions add +1 (taken) or +2 (page cross); indexed instructions add +1 on page cross. Use `@TRACE R` for accurate runtime counts.

---

## Source file format

```
[label:] [mnemonic [operand]] [;comment]
```

- Labels start in column 1, end with `:`
- Maximum line length: **50 characters**
- Maximum lines: **512**
- Case-insensitive mnemonics and labels

---

## Directives

| Directive | Description |
|-----------|-------------|
| `.ORG address` | Set program counter (default: $8000) |
| `.EQU value` | Define constant: `NAME .EQU value` |
| `.BYTE vals` | Emit bytes (comma-separated) |
| `.WORD vals` | Emit 16-bit words, little-endian |
| `.ASCII "text"` | Emit string without null terminator |
| `.ASCIZ "text"` | Emit string with null terminator ($00) |
| `.INCLUDE "file"` | Include source file (max 4 nesting levels) |

---

## Addressing modes

All standard 65C02 modes are supported. Assembler automatically selects ZP mode when operand fits in $00–$FF. Use `*` prefix to force ZP for higher addresses.

| Mode | Syntax | Example |
|------|--------|---------|
| Implied | `NOP` | `NOP` |
| Accumulator | `mnemonic A` | `INC A` |
| Immediate | `#value` | `LDA #$FF` |
| Zero Page | `value` | `LDA $80` |
| Zero Page,X/Y | `value,X` | `LDA $80,X` |
| Absolute | `$1234` | `LDA $8000` |
| Absolute,X/Y | `$1234,X` | `LDA $8000,X` |
| ZP Indirect | `(value)` | `JMP ($80)` |
| ZP Indirect,X | `(value,X)` | `LDA ($80,X)` |
| ZP Indirect,Y | `(value),Y` | `LDA ($80),Y` |
| ABS Indirect | `($1234)` | `JMP ($8000)` |
| ABS Indirect,X | `($1234,X)` | `JMP ($8000,X)` |
| PC-Relative | `label` | `BEQ label` |

**Unary operators**: `<value` (low byte), `>value` (high byte), `*value` (force ZP).  
**Label arithmetic**: `label+N`, `label-N`, `<label+N`, `>label+N` — computed at assembly time.

---

## Instruction set

Full 65C02 + WDC extensions:

- **Load/Store**: `LDA LDX LDY STA STX STY STZ`
- **Arithmetic**: `ADC SBC`
- **Logic**: `AND EOR ORA`
- **Shifts**: `ASL LSR ROL ROR`
- **Bit ops**: `BIT TRB TSB RMB0–RMB7 SMB0–SMB7` (WDC)
- **Inc/Dec**: `INC INX INY DEC DEX DEY`
- **Transfers**: `TAX TAY TXA TYA TSX TXS`
- **Stack**: `PHA PHP PHX PHY PLA PLP PLX PLY`
- **Jumps**: `JMP JSR RTS RTI`
- **Branches**: `BCC BCS BEQ BNE BMI BPL BVC BVS BRA`
- **Bit branches** (WDC): `BBR0–BBR7 zp,label` / `BBS0–BBS7 zp,label`
- **Flags**: `CLC SEC CLD SED CLI SEI CLV`
- **Compare**: `CMP CPX CPY`
- **Misc**: `NOP BRK WAI STP` (WAI/STP are WDC extensions)

---

## Limits

| Parameter | Limit |
|-----------|-------|
| Source lines | 512 |
| Line length | 50 characters |
| Code size | 16 KB |
| Symbols | 128 |
| Symbol name | 47 characters |
| `.INCLUDE` depth | 4 levels |
| Branch range | −128..+127 bytes |

---

## Listing file (`out.lst`)

```
AAAA BB BB BB ... | source line
```

Example:
```
8000 A9 00       | start:  LDA #$00
8002 85 80       |         STA $80
8004 E8          | loop:   INX
8005 D0 FD       |         BNE loop
```

---

## Related pages

- [[razemos]] — the OS/shell that bundles HASS
- [[razemos-repo]] — repo source page
- [[65c02-instruction-set]] — full W65C02S instruction reference
- [[65c02-addressing-modes]] — addressing mode details
