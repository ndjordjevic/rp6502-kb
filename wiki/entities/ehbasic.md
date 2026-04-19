---
type: entity
tags: [rp6502, basic, ehbasic, interpreter, language]
related:
  - "[[rp6502-os]]"
  - "[[ria-registers]]"
  - "[[rp6502-abi]]"
  - "[[launcher]]"
  - "[[rom-file-format]]"
  - "[[cc65]]"
sources:
  - "[[ehbasic-repo]]"
  - "[[rumbledethumps-discord]]"
  - "[[yt-ep17-basics-of-basic]]"
created: 2026-04-18
updated: 2026-04-18
---

# EhBASIC

**Summary**: Lee Davison's Enhanced BASIC 2.22p5, ported to RP6502-OS by `rumbledethumps`. The primary BASIC interpreter for the Picocomputer 6502 — boots directly from USB, integrates with RP6502-OS LOAD/SAVE via `open()`/`close()`, and supports `SET BOOT BASIC` for auto-start.

---

## What it is

EhBASIC 2.22p5 is a feature-complete integer and floating-point BASIC interpreter for the 6502, originally by Lee Davison (†2013). The RP6502 port targets the W65C02S and is built with cc65 against the **picocomputer fork** of cc65 (not the upstream release).

> **No RP6502-specific BASIC extensions.** All commands are stock EhBASIC 2.22p5. The RP6502 integration is in the I/O glue layer only.

The reference manual for the full EhBASIC command set is maintained at:  
http://retro.hansotten.nl/6502-sbc/lee-davison-web-site/enhanced-6502-basic/

---

## Memory layout

| Segment | Address | Content |
|---------|---------|---------|
| HEAD (RESET/IRQ/NMI vectors) | `$D000–$D00E` | Interrupt dispatch |
| BASIC interpreter + runtime | `$D000+` | EhBASIC code, zero page usage |
| User program area | below BASIC | Available RAM |

BASIC is loaded as a `.rp6502` ROM file. It declares `DATA 0xD000`, `RESET 0xD000`, `IRQ 0xD002`, `NMI 0xD00C` in its CMakeLists.

---

## Loading and booting

```
load ehbasic.rp6502   ; load via RIA monitor
run                   ; start interpreter
```

Or set as default boot ROM:

```
set boot basic        ; auto-start BASIC on power-on
```

To return to the monitor from BASIC: press **Ctrl-Alt-Del**, then use `RESET` for warm start (preserves program) or reload the ROM for a cold start.

---

## LOAD and SAVE

EhBASIC's `LOAD` and `SAVE` commands work with the RP6502 filesystem:

```basic
SAVE "myprogram"     ; saves BASIC listing to file
LOAD "myprogram"     ; loads and runs BASIC listing from file
```

Internally, `V_LOAD` calls `open(filename, O_RDONLY)` and redirects character input through the RP6502-OS `read_xstack` call. `V_SAVE` calls `open(filename, O_TRUNC|O_CREAT|O_WRONLY)` and redirects character output through `write_xstack`. Files are plain BASIC text, using LF line endings.

> **Note**: `RND(1)` in classic BASIC programs must be changed to `RND(0)` for EhBASIC compatibility.

---

## OS I/O integration

Normal console I/O uses the **ACIA simulation** registers exposed by the RIA:

| Register | Address | Use |
|----------|---------|-----|
| `RIA_READY` | `$FFE0` | Bit 7 = TX ready, Bit 6 = RX byte available |
| `RIA_TX` | `$FFE1` | Write character to console output |
| `RIA_RX` | `$FFE2` | Read character from console input |

The `V_INPT` vector polls `RIA_READY` bit 6 before reading `RIA_RX`. The `V_OUTP` vector polls `RIA_READY` bit 7 before writing `RIA_TX`. This ACIA simulation is available to any RP6502 assembly program — not just EhBASIC.

See [[ria-registers]] for the full register map.

---

## USR() extension point

`src/usr.s` provides the `V_USR` hook called by EhBASIC when the `USR(x)` function is evaluated. The default implementation returns a "Function call" error. To add a hardware-specific numeric function from assembly, replace `V_USR` with custom code following the EhBASIC calling convention (parameter in A/X/float accumulator, result returned the same way).

---

## Cold vs warm start

`main.s` uses **self-modifying code** for cold/warm start detection:

```asm
CLC                 ; first run: CLC (cold start path)
BCC   AutoCold
JMP   LAB_WARM      ; subsequent: SEC was patched in → warm start
AutoCold:
LDA   #$38          ; opcode for SEC
STA   _main         ; patch the CLC to SEC
JMP   LAB_COLD      ; cold start
```

On the first run `CLC` branches to `AutoCold`, patches itself to `SEC`, and does a cold start. Every subsequent run finds `SEC` and jumps to `LAB_WARM` directly.

---

## Releases

| Version | Date | Notes |
|---------|------|-------|
| `v20240112` | 2024-01-12 | First binary release; includes SAVE and LOAD |
| `v20240114` | 2024-01-14 | Backspace fixes (`$08`/`$7F` both accepted); default column width and tab size per manual |

---

## Related pages

- [[ria-registers]] — ACIA simulation (RIA_TX/RIA_RX/RIA_READY)
- [[rp6502-abi]] — OS call mechanics used by LOAD/SAVE
- [[rom-file-format]] — `.rp6502` shebang format
- [[launcher]] — `SET BOOT` mechanism for auto-starting BASIC
- [[community-projects]] — community BASIC resources (BASIC Computer Games, EhBASIC+ graphics)
- [[cc65]] — required toolchain (picocomputer fork)
