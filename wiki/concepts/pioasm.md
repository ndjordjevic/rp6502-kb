---
type: concept
tags: [rp2040, rp2350, pio, pioasm, toolchain, sdk]
related: [[pio-architecture]], [[sdk-architecture]], [[pico-c-sdk]]
sources: [[pico-c-sdk]]
created: 2026-04-17
updated: 2026-04-17
---

# PIOASM Assembler

**Summary**: PIOASM is the PIO assembler included with the Pico SDK. It translates `.pio` source files into C headers (or Python/hex) ready to be loaded into PIO instruction memory. This page covers the complete directive and syntax reference (§3.3) plus v0/v1 ISA encoding tables (§3.4) from the authoritative SDK specification.

---

## Overview

PIOASM is built automatically during `pico-examples` builds. To build standalone:

```sh
mkdir pioasm_build && cd pioasm_build
cmake $PICO_SDK_PATH/tools/pioasm
make
./pioasm
```

Output formats (selected with `-o`):

| Format | Description |
|---|---|
| `c-sdk` (default) | C header for Pico SDK; binary arrays, `pio_program` struct, default-config factory |
| `python` | MicroPython `.py`; useful when sharing PIO code between SDK and MicroPython |
| `hex` | Raw hex opcodes (one per line); single-program input only |

Target PIO version: `-v 0` (RP2040) or `-v 1` (RP2350, default). Set per-program with `.pio_version`.

Within the SDK, use the CMake helper — never invoke pioasm directly:

```cmake
pico_generate_pio_header(my_target ${CMAKE_CURRENT_LIST_DIR}/myprogram.pio)
target_link_libraries(my_target hardware_pio)
```

This runs pioasm, generates `myprogram.pio.h`, and adds it to `my_target`'s include path.

---

## Directives

Directives configure the assembler and embed default SM configuration in the generated header. All must appear before the first instruction in their scope.

| Directive | Description |
|---|---|
| `.program <name>` | Start a new program block. Name used in generated C identifiers. Required. |
| `.pio_version <0/1/RP2040/RP2350>` | Target PIO version. Before first `.program` = default for all; inside program = per-program override. RP2350 default is `1`. |
| `.origin <offset>` | Fix to a specific instruction memory offset. Use for programs with absolute JMP targets packed in few bits. `-1` = no fixed placement. |
| `.side_set <count> (opt) (pindirs)` | Declare side-set pins. `opt` = value optional per instruction (costs 1 extra bit). `pindirs` = side-set controls direction not state. |
| `.wrap_target` | Target instruction for zero-cost program wrap (default: program start). |
| `.wrap` | Last instruction of the wrapping loop (default: last instruction in program). |
| `.define (PUBLIC) <symbol> <value>` | Integer constant. `PUBLIC` exports as `#define <program>_<symbol> value`. Before first `.program` = global. |
| `.clock_div <divider>` | Default SM clock divider (float). Only affects `get_default_config()` output. |
| `.fifo <config>` | FIFO configuration (see table below). Restricts which instructions are valid. |
| `.mov_status rxfifo < <n>` | Configure `STATUS` source to RX FIFO level < n. |
| `.mov_status txfifo < <n>` | Configure `STATUS` source to TX FIFO level < n. |
| `.mov_status irq_(prev/next)_set <n>` | Configure `STATUS` source to IRQ flag n (PREV/NEXT are v1-only). |
| `.in <count> (left/right) (auto) (<threshold>)` | ISR bit count, shift direction, autopush enable, threshold. On v0, count must be 32. |
| `.out <count> (left/right) (auto) (<threshold>)` | OSR bit count, shift direction, autopull enable, threshold. |
| `.set <count>` | Number of SET pins. |
| `.lang_opt <lang> <name> <option>` | Language generator option (e.g. `.lang_opt python sideset_init = pico.PIO.OUT_HIGH`). |
| `.word <value>` | Store raw 16-bit value as an instruction. |

### `.fifo` configuration modes

| Mode | Effect |
|---|---|
| `txrx` (default) | 4 entries TX + 4 entries RX |
| `tx` | 8 entries TX (RX FIFO repurposed) |
| `rx` | 8 entries RX (TX FIFO repurposed) |
| `txput` | 4 entries TX + 4 RX entries as `mov rxfifo[idx], isr` targets (v1 only) |
| `txget` | 4 entries TX + 4 RX entries as `mov osr, rxfifo[idx]` sources (v1 only) |
| `putget` | All 4 RX entries as shared SM scratch registers (v1 only) |

In `txput`/`txget` mode the RX FIFO storage doubles as status registers accessible by both the SM (`mov rxfifo`) and the ARM CPU (`RXFx_PUTGET0-3`). Use case: a quadrature decoder that maintains a continuously-updated count the CPU can read without blocking.

---

## Values and expressions

| Type | Example |
|---|---|
| Decimal | `3`, `-7` |
| Hex | `0xf` |
| Binary | `0b1001` |
| Symbol | any `.define` name |
| Label | instruction offset within program |
| Expression | `(T1 + T2 + T3)` — must be parenthesised |

Expression operators: `+`, `-`, `*`, `/` (integer division), `<<`, `>>`, unary `-` (negate), `:: expr` (bit-reverse).

---

## Labels

```
myloop:
PUBLIC myexport:
```

A label is an automatic `.define` whose value is the current program instruction offset. `PUBLIC` labels export to generated C code like `PUBLIC .define`.

---

## Instruction syntax

All instructions follow the pattern:

```
<instruction> (side <side_set_value>) ([<delay_value>])
```

- `side <value>` — asserted on side-set pins at start of instruction. Required when `.side_set count` (non-optional) is declared; forbidden if no `.side_set`.
- `[delay]` — idle cycles after instruction completes; 0–31 total, reduced by number of side-set bits used.
- Instruction names, keywords, directives: **case-insensitive**.
- Commas in operand lists are **optional**: `out pins, 3` and `out pins 3` are both valid.

> Delay cycles on stalling instructions (`WAIT`, `IN` autopush full, `OUT` autopull empty, `PUSH block`, `PULL block`, `IRQ wait`) do **not** begin counting until after the wait condition is met.

---

## Pseudoinstructions

| Pseudoinstruction | Expands to | Notes |
|---|---|---|
| `nop` | `mov y, y` | No operation; useful for a side-set or extra delay with no data effect |

---

## Output pass-through

Text in the `.pio` file is passed verbatim to the generated output:

```pioasm
% c-sdk {
static inline void myprog_program_init(PIO pio, uint sm, uint offset, uint pin) {
    pio_gpio_init(pio, pin);
    pio_sm_config c = myprog_program_get_default_config(offset);
    sm_config_set_set_pins(&c, pin, 1);
    pio_sm_init(pio, sm, offset, &c);
    pio_sm_set_enabled(pio, sm, true);
}
%}
```

This embeds the init function directly in the generated `myprog.pio.h`. The convention makes a `.pio` file fully self-contained: it defines both the PIO program and the C setup code in one place. The RIA firmware uses this pattern in `ria.pio` and `vga.pio`.

Target `c-sdk` is the standard tag; `python` for MicroPython pass-through sections.

---

## Generated C header structure

A `myprog.pio` file assembled by pioasm generates `myprog.pio.h`:

```c
// Wrap points and PIO version
#define myprog_wrap_target 0
#define myprog_wrap 3
#define myprog_pio_version 1

// PUBLIC .define symbols
#define myprog_MY_CONST 10

// Binary instruction array
static const uint16_t myprog_program_instructions[] = { 0x... };

// pio_program struct
static const struct pio_program myprog_program = {
    .instructions = myprog_program_instructions,
    .length = 4,
    .origin = -1,                  // -1 = no fixed placement
    .pio_version = myprog_pio_version,
};

// Default config factory (always generated)
static inline pio_sm_config myprog_program_get_default_config(uint offset) {
    pio_sm_config c = pio_get_default_sm_config();
    sm_config_set_wrap(&c, offset + myprog_wrap_target, offset + myprog_wrap);
    sm_config_set_sideset(&c, 1, false, false);
    return c;
}

// Pass-through init function (if present in .pio file)
static inline void myprog_program_init(...) { ... }
```

Key elements:
- `get_default_config(offset)` — always generated; encodes `.wrap`, `.wrap_target`, `.side_set` settings.
- `origin = -1` — no fixed placement; `pio_add_program()` places it wherever it fits.
- `pio_version` field — SDK checks v0/v1 compatibility before loading.

---

## PIO ISA encoding summary (v0 / v1)

All instructions are 16 bits, execute in 1 cycle + optional delay. Bits 15–13 = opcode.

| Bits 15–13 | Mnemonic | v0 (RP2040) | v1 (RP2350) additions |
|---|---|---|---|
| `000` | `JMP` | Conditions: always/!X/X--/!Y/Y--/X!=Y/PIN/!OSRE | (unchanged) |
| `001` | `WAIT` | Sources: GPIO/PIN/IRQ; REL flag for SM-relative IRQ | JMPPIN source (wait on jmp_pin + offset); IRQ PREV/NEXT cross-PIO |
| `010` | `IN` | Sources: PINS/X/Y/NULL/ISR/OSR; 1–32 bits; autopush | (unchanged) |
| `011` | `OUT` | Dests: PINS/X/Y/NULL/PINDIRS/PC/ISR/EXEC; autopull | (unchanged) |
| `100` bit7=0 | `PUSH` | IfFull + Block flags; clears ISR on push | `MOV rxfifo[y/idx], isr` via previously-reserved encoding |
| `100` bit7=1 | `PULL` | IfEmpty + Block flags; noblock copies X to OSR | `MOV osr, rxfifo[y/idx]` via previously-reserved encoding |
| `101` | `MOV` | Dests: PINS/X/Y/EXEC/PC/ISR/OSR; Ops: None/Invert/Bit-reverse; Sources: PINS/X/Y/NULL/STATUS/ISR/OSR | Dest `011` = PINDIRS (v1 new) |
| `110` | `IRQ` | Set/wait/clear; REL mode (add SM index to flag); flags 0–3 visible to system | All 8 flags can assert system IRQs; PREV/NEXT cross-PIO modes |
| `111` | `SET` | Dests: PINS/X/Y/PINDIRS; 5-bit immediate data | (unchanged) |

### Delay/side-set tradeoff

Bits 12–8 (5 bits) are shared between delay and side-set count. With 0 side-set bits: up to 31 delay cycles. Each side-set pin costs 1 bit; `opt` costs 1 extra bit for the presence flag. Remaining bits = max delay.

### STATUS source in MOV

`MOV dest, STATUS` reads all-ones or all-zeros depending on `EXECCTRL_STATUS_SEL`:
- `0`: all-ones when TX FIFO is not full; all-zeros when full
- `1`: all-ones when RX FIFO is not empty; all-zeros when empty

Configured via `.mov_status` directive or `sm_config_set_mov_status()`.

### v1 (RP2350) PULL noblock behaviour

`PULL NOBLOCK` on an empty TX FIFO copies X to OSR instead of stalling. Equivalent to `MOV OSR, X`. Useful for protocols (e.g. I2S) that must clock continuously: preload X with a default value and `PULL NOBLOCK` before each `OUT`.

### v1 cross-PIO IRQ synchronisation

`IRQ PREV <n>` / `IRQ NEXT <n>` and `WAIT irq PREV <n>` / `WAIT irq NEXT <n>` reference IRQ flags in the adjacent lower/higher-numbered PIO block. Requires that cross-PIO SM clock dividers are identical and have been synchronised via `CTRL.NEXTPREV_CLKDIV_RESTART`. Cross-PIO connections are severed across Non-secure/Secure accessibility boundaries.

---

## Related pages

- [[pio-architecture]]
- [[sdk-architecture]]
- [[pico-c-sdk]]
