---
type: source
tags: [rp6502, basic, ehbasic, interpreter, cc65]
related: [[ehbasic]], [[rp6502-abi]], [[ria-registers]], [[cc65]]
sources: []
created: 2026-04-18
updated: 2026-04-18
---

# EhBASIC Source (picocomputer/ehbasic)

**Summary**: The `picocomputer/ehbasic` repo is a port of Lee Davison's Enhanced BASIC 2.22p5 to the RP6502-OS using cc65. The RP6502-specific code is entirely in the I/O glue layer (`min_mon.s`) — the BASIC interpreter core (`basic.s`) is unmodified from upstream.

---

## Source details

| Field | Value |
|-------|-------|
| Repo | https://github.com/picocomputer/ehbasic |
| Clone | `raw/github/picocomputer/ehbasic/` (commit `acd5deb`, 2026-04-18) |
| EhBASIC version | 2.22p5 |
| Author | Lee Davison (original); `rumbledethumps` (RP6502 port) |
| Reference manual | http://retro.hansotten.nl/6502-sbc/lee-davison-web-site/enhanced-6502-basic/ |
| Original archive | http://mycorner.no-ip.org/6502/ehbasic/index.html (Internet Archive snapshot, 2013-03-08) |

---

## Releases

| Tag | Date | Notes |
|-----|------|-------|
| `v20240112` | 2024-01-12 | First binary release. Includes SAVE and LOAD. |
| `v20240114` | 2024-01-14 (latest) | Fix various backspace key bugs. Accepts both `$08` and `$7F` as backspace. |

---

## Repository structure

| File | Purpose |
|------|---------|
| `src/basic.s` | Lee Davison's EhBASIC 2.22p5 interpreter core — **unmodified** (~8870 lines) |
| `src/head.s` | HEAD segment at `$D000`: RESET/IRQ/NMI vectors, IRQ/NMI flag-byte pattern |
| `src/main.s` | Cold/warm start dispatch via self-modifying code |
| `src/min_mon.s` | **RP6502-OS integration layer**: `V_INPT`, `V_OUTP`, `V_LOAD`, `V_SAVE` (~169 lines) |
| `src/usr.s` | USR() function hook stub (returns "Function call" error by default) |
| `doc/help.rp6502` | Distributable ROM with copyright/credits text (not a command reference) |

---

## Key findings

### No RP6502-specific BASIC extensions

The `doc/help.rp6502` file contains only the copyright/license notice — it is a credits ROM, not a command reference. The RP6502 port of EhBASIC has **no custom BASIC keywords or extensions**. All BASIC commands are stock EhBASIC 2.22p5. The RP6502-specific work is entirely in the OS glue layer.

### Memory layout

BASIC loads at `$D000`:

| Vector | Address | Meaning |
|--------|---------|---------|
| RESET | `$D000` | Jumps to `ProgStart` (then to cold or warm BASIC start) |
| IRQ | `$D002` | IRQ flag-byte handler |
| NMI | `$D00C` | NMI flag-byte handler |

### OS integration (min_mon.s)

The RP6502 port replaces the traditional monitor ROM at `$FF00` with a glue layer that bridges EhBASIC's I/O vectors to RP6502-OS:

| EhBASIC vector | RP6502-OS call | Description |
|----------------|---------------|-------------|
| `V_INPT` | `RIA_RX` (ACIA) / `RIA_OP_READ_XSTACK` | Read one character from console or file |
| `V_OUTP` | `RIA_TX` (ACIA) / `RIA_OP_WRITE_XSTACK` | Write one character to console or file |
| `V_LOAD` | `RIA_OP_OPEN` (O_RDONLY) | Open a file, redirect V_INPT to read BASIC source from it |
| `V_SAVE` | `RIA_OP_OPEN` (O_TRUNC\|O_CREAT\|O_WRONLY) | Open a file, redirect V_OUTP to write BASIC listing to it |

See [[ehbasic]] for the detailed OS call patterns, and [[ria-registers]] for the ACIA simulation registers.

### USR() hook

`src/usr.s` exports `V_USR` which currently just jumps to `LAB_FCER` ("Function call" error). The comment references the EhBASIC manual's "using USR()" section. This is the extension point for hardware-specific numeric functions callable from BASIC programs.

### IRQ/NMI flag-byte pattern

The interrupt handlers in `head.s` use a shift-OR idiom to track interrupt occurrence:

```asm
LDA   IrqBase      ; current flag byte
LSR                ; shift b7 → b6 (history)
ORA   IrqBase      ; OR in original b7 (current)
STA   IrqBase      ; write back
```

This preserves a "did IRQ fire since last check" bit in b7 and a "did it fire previously" bit in b6 — a two-bit rolling interrupt log without additional state.

---

## Scope

- [x] README.md
- [x] doc/help.rp6502
- [x] src/head.s + src/main.s (vectors, cold/warm start)
- [x] src/min_mon.s (OS integration layer — `V_INPT`, `V_OUTP`, `V_LOAD`, `V_SAVE`)
- [x] src/usr.s (USR() stub)
- [x] Releases (v20240112, v20240114)
- [-] src/basic.s — skipped; unmodified upstream EhBASIC 2.22p5 core (8870 lines)

---

## Related pages

- [[ehbasic]] — entity page: how to use EhBASIC on RP6502
- [[ria-registers]] — ACIA simulation registers (`RIA_RX`, `RIA_TX`, `RIA_READY`)
- [[rp6502-abi]] — OS call mechanics
- [[cc65]] — required toolchain for building from source
- [[community-projects]] — community BASIC resources
