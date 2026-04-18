---
type: concept
tags: [rp6502, ria, vga, pio, rp2350, hardware, firmware]
related: [[rp6502-ria]], [[rp6502-vga]], [[pix-bus]], [[gpio-pinout]], [[reset-model]], [[pioasm]], [[hardware-irq]]
sources: [[rp6502-github-repo]], [[quadros-rp2040]], [[fairhead-pico-c]], [[pico-c-sdk]], [[rp2350-datasheet]], [[youtube-playlist]]
created: 2026-04-16
updated: 2026-04-17

---

# PIO Architecture

**Summary**: How the RIA firmware uses RP2350 PIO state machines to bit-bang the 65C02 bus and drive the PIX bus — and how the VGA firmware uses PIO to receive PIX and output pixels.

---

## Why PIO?

The RP2350 has no dedicated 6502 bus controller. PIO (Programmable I/O) state machines fill that gap: they run tiny programs in hardware at deterministic cycle counts, independent of the main Cortex-M33 cores. The RIA uses PIO to sample the 65C02 address/data bus at exactly the right moment in the PHI2 cycle, decode chip-select and read/write, and drive data onto the bus — all without the Cortex touching the bus timing.

> **Historical origin ([[yt-ep02-pio-and-dma]], [[yt-ep03-writing-to-pico]]):** The PIO+DMA bus interface was developed in late 2022 during the breadboard bring-up phase. The alternative — bitbanging the 6502 — "uses 100% of a CPU to meet a hard real-time requirement; DMA+PIO use a fraction of those resources and none of the CPU." Ep2 introduced the read path (PIO reads address bus, chained DMA delivers register value to data bus); Ep3 added the write path and chip-select gating. Achieving 8 MHz required doubling the Pi Pico system clock (Ep2). See [[development-history]] Era A.

---

## RIA PIO layout (`src/ria/ria.pio`)

The RIA Pico runs **five PIO programs** across two PIO blocks:

| PIO | SM | Program | Role |
| --- | --- | --- | --- |
| pio0 | 0 | `ria_cs_rwb` | Chip-select and R/W̄ decoder; controls data bus direction (hi-Z vs driven) |
| pio0 | 1 | `ria_write` | Captures 6502 write cycles (address + data); **also generates PHI2** via side-set |
| pio0 | 2 | `ria_read` | Drives data bus for 6502 read cycles, timed to PHI2 |
| pio1 | 0 | `ria_action` | Event router — generates a FIFO message for every write and for periodic reads; feeds the Cortex task loop |
| pio1 | 1 | `pix_tx` | Transmits PIX bus frames (4 bits per PHI2 edge, DDR) — see [[pix-bus]] |

### `ria_write` generates PHI2

`ria_write` uses a **side-set pin** (GPIO 21) to produce PHI2. This means the 6502 clock is a by-product of the write-capture state machine — PHI2 stops if the state machine stops. When the RIA pauses the 6502 (RESB low), PHI2 also stops.

### `ria_action` — the event router

This program is the heart of the OS call mechanism:
- On every PHI2 cycle it checks for a write to the RIA address range.
- For writes: pushes `(address, data)` into the FIFO for the Cortex to process.
- For reads at specific variable addresses: also pushes a notification so the Cortex can update the data register in time.
- The Cortex's `api_task()` reads these FIFO entries and dispatches to the right OS call handler.

### `ria_cs_rwb` — bus direction

Controls `pindirs` on the data bus pins: when the 6502 is writing, the data bus is hi-Z (input); when the 6502 is reading, it's driven (output). Responds to PHI2 and the combined CS+R/W̄ signal.

### Timing sensitivity

Comments in the PIO source note tight timing windows at high PHI2:

- `ria_action`: "good range 4–15" cycles after PHI2 high for address arrival.
- `ria_read`: "good range 4–8" cycles — must wait long enough for address but short enough for DMA to finish before data is needed.
- These ranges narrow as PHI2 frequency increases, which is why 8 MHz is the practical limit.

### VGA backchannel RX

A sixth program (`vga_backchannel_rx`) is also defined in `ria.pio` — a minimal 8N1 UART receiver on pio1 that listens to the VGA Pico's VSYNC/ack backchannel.

---

## VGA PIO layout (`src/vga/vga.pio` + `scanvideo/scanvideo.pio`)

The VGA Pico runs its own PIO programs:

| PIO | SM | Role |
| --- | --- | --- |
| pio1 | 1 | `PIX_REGS_SM` — receives XREG messages from the PIX bus |
| pio1 | 2 | `PIX_XRAM_SM` — receives XRAM update messages from the PIX bus |
| — | — | Scanline output programs in `scanvideo.pio` — pixel DMA to VGA DAC |

The VGA Pico's PIX receiver uses **GPIO 11** as its PHI2 input (the PIX bus carries PHI2 as its clock). This is a different GPIO than the RIA's PHI2 output (GPIO 21) — they are on separate physical Picos.

---

## RP2350 clock

The RIA Pico runs at **256 MHz** (vs the RP2350's default 150 MHz), with the voltage regulator bumped to **1.15 V** (`VREG_VOLTAGE_1_15`). This overclock is required to give the PIO state machines enough cycles to handle the 65C02 bus at 8 MHz PHI2 while also managing USB, audio, and networking.

> One community member tested 280 MHz on default 1.10 V (see forum link in `src/ria/sys/cpu.h`).

---

## PIO hardware reference

*This section covers the RP2040/RP2350 PIO subsystem at the hardware level, based on [[quadros-rp2040]]. The RIA-specific section above shows how these primitives are used in `ria.pio`.*

### Structure

- **2 PIO blocks** (PIO0, PIO1) × **4 state machines each** = 8 total on RP2040
- **3 PIO blocks** × **4 state machines each** = 12 total on RP2350 — the RIA runs on RP2350; PIO2 is available but currently unused by the RIA firmware
- Each PIO has **32-instruction shared program memory** — all 4 SMs share it
- Each SM: TX FIFO (4×32-bit) + RX FIFO (4×32-bit); joinable to a single 8-word FIFO

### Programmer's model — per state machine

| Register | Role |
|---|---|
| **OSR** | Out Shift Register — shifts bits from TX FIFO to output pins |
| **ISR** | In Shift Register — shifts bits from input pins to RX FIFO |
| **X** | Scratch register — loop counter, data buffer, pin state |
| **Y** | Scratch register — second counter / comparand |
| **PC** | Program Counter — JMP, IN, MOV can change it |

### Instruction set

All instructions are **16-bit**, execute in **1 cycle** + optional delay. Instruction format: bits 15–13 = opcode, bits 12–8 = delay/side-set (5 shared bits), bits 7–0 = operands.

| Instruction | Notes |
|---|---|
| `JMP (cond) target` | Conditions: always, !X, X-- (decrement-and-test), !Y, Y--, X≠Y, PIN, !OSRE |
| `WAIT pol gpio/pin/irq idx` | Stall until GPIO/PIN/IRQ matches polarity; for IRQ: `rel` makes index relative to SM number; v1 adds JMPPIN source and PREV/NEXT cross-PIO |
| `IN source, bit_count` | Shift bits into ISR from PINS/X/Y/NULL/ISR/OSR; auto-push when threshold reached |
| `OUT dest, bit_count` | Shift bits from OSR to PINS/X/Y/PINDIR/PC/ISR/EXEC; auto-pull when threshold reached |
| `PUSH (iffull) (block)` | Push ISR to RX FIFO, clear ISR; IfFull: only if shift count reached threshold |
| `PULL (ifempty) (block)` | Load TX FIFO into OSR; IfEmpty: only if shift count reached threshold; PULL noblock from empty FIFO copies X to OSR |
| `MOV dest, (op,) source` | Copy with None/Invert/Bit-reverse; sources include STATUS (all-ones/zeros based on FIFO state); `MOV EXEC` runs source as instruction; v1 adds PINDIRS as destination |
| `IRQ (set/wait/clear) num (rel)` | Set, set-and-wait, or clear IRQ flag; `rel` adds SM index for portable multi-SM code; v1 adds PREV/NEXT cross-PIO; v1 all 8 flags can assert system IRQs (v0: only flags 0–3) |
| `SET dest, value` | Write immediate 0–31 to PINS/X/Y/PINDIRS |

Stalling instructions: WAIT, IN (auto-push full), OUT (auto-pull empty), PUSH (block), PULL (block), IRQ (wait). A stalled SM holds its position indefinitely until the condition is met.

> **Delay timing rule**: delay cycles on stalling instructions do **not** begin counting until after the wait condition clears. If an instruction completes without stalling, delay cycles run immediately.

### v1 (RP2350) ISA additions over v0 (RP2040)

These features are only available when using `.pio_version 1` (or targeting RP2350):

1. **`MOV PINDIRS`** — destination `011` in MOV encoding, previously reserved. Writes to pin directions using the OUT pin mapping.
2. **`MOV rxfifo[y/idx], isr`** — stores ISR into a selected RX FIFO entry (indexed by Y or immediate). Uses previously-reserved PUSH opcode (bit7=0) encodings. Requires `.fifo txput` or `.fifo putget`.
3. **`MOV osr, rxfifo[y/idx]`** — reads a selected RX FIFO entry into OSR. Uses previously-reserved PULL opcode (bit7=1) encodings. Requires `.fifo txget` or `.fifo putget`.
4. **`WAIT JMPPIN`** — waits on the pin indexed by `PINCTRL_JMP_PIN + offset (0–3)`, modulo 32. New WAIT source type.
5. **IRQ PREV/NEXT** — `IRQ PREV <n>` / `IRQ NEXT <n>` sets/clears an IRQ flag on the adjacent lower/higher PIO block. Enables synchronisation between PIO blocks without involving the Cortex.
6. **All 8 IRQ flags** can assert system-level interrupts. On v0, only flags 0–3 are routable to the NVIC; v1 lifts this restriction.

**New pioasm directives (v1 only)**:
- `.fifo txput` — 4 entries TX + 4 entries for random `MOV rxfifo[idx], ISR` writes (implements status registers readable by CPU)
- `.fifo txget` — 4 entries TX + 4 entries for random `MOV OSR, rxfifo[idx]` reads (implements control registers writable by CPU)
- `.fifo putget` — 4 entries for put + 4 entries for get (SM random access, CPU random access disabled)
- `.mov_status irq (prev|next) set <n>` — STATUS source based on an IRQ flag being set (cross-PIO)

See [[pioasm]] for the full assembler directive reference and `.fifo` mode descriptions.

### RP2350-specific register additions (v1 hardware)

| Register | Description |
|---|---|
| `DBG_CFGINFO.VERSION` | PIO ISA version — 0 for RP2040 (v0), 1 for RP2350 (v1). Use for runtime feature detection. |
| `GPIOBASE` | Shifts the 32-GPIO window for each PIO block. RP2350B has 48 GPIOs; set `GPIOBASE` to 16 to work with GPIOs 16–47. All GPIO indices in PIO programs are relative to `GPIOBASE`. |
| `CTRL.NEXT_PIO_MASK` / `.PREV_PIO_MASK` | Propagate CTRL operations (SM enable/disable, clkdiv restart) to state machines in the next-higher/next-lower PIO block simultaneously. Enables perfectly synchronised multi-block PIO startup. |
| `SM0_SHIFTCTRL.IN_COUNT` | Masks unneeded IN-mapped pins to zero — useful for `MOV x, PINS` which previously always returned a full 32-bit rotated value. |
| `RXF0_PUTGET0`–`RXF3_PUTGET3` | Expose each RX FIFO's internal 4×32-bit storage registers for random read/write from the system bus (not just push/pop order). Used by `.fifo txput/txget/putget` modes. |

**Delay/side-set tradeoff**: 5 bits are shared between delay and side-set count. With no side-set, up to 31 delay cycles per instruction. With 1 side-set pin: max 15 delay cycles. Each additional side-set pin costs 1 delay bit.

### GPIO pin groups

Each SM configures five independent pin groups:

| Group | Instructions | Description |
|---|---|---|
| **Input** | WAIT, IN, MOV(src) | Base pin for IN PINS; WAIT uses raw GPIO index directly |
| **Output** | OUT, MOV(dst) | Base + count for output data |
| **Set** | SET PINS/PINDIRS | Base + count (up to 5) for immediate writes |
| **Side-Set** | Every instruction | Base + count (up to 5); driven each cycle via instruction bits |
| **Jump-Pin** | JMP PIN | Single pin tested by the JMP PIN condition |

### IRQ flags and NVIC wiring

8 shared IRQ flags (0–7). All 8 are accessible to all state machines — used for inter-SM synchronization. The `rel` qualifier makes the IRQ number relative to the SM index, so the same program can run on multiple SMs without collision.

The lower 4 PIO IRQ flags (0–3) can be routed to two ARM NVIC interrupt lines per PIO block on RP2040 (v0). On RP2350 (v1), **all 8 flags** can be routed:

| NVIC IRQ | ARM IRQ# | Triggered by |
|---|---|---|
| `PIO0_IRQ_0` | 7 | Selected PIO0 SM IRQ flags (configured via `pio_set_irq0_source_enabled`) |
| `PIO0_IRQ_1` | 8 | Selected PIO0 SM IRQ flags (configured via `pio_set_irq1_source_enabled`) |
| `PIO1_IRQ_0` | 9 | Selected PIO1 SM IRQ flags |
| `PIO1_IRQ_1` | 10 | Selected PIO1 SM IRQ flags |

SDK routing functions (`hardware_pio`):
- `pio_set_irq0_source_enabled(pio, pis_interrupt0 + sm, true)` — enables PIO SM IRQ flag 0 to assert `PIOx_IRQ_0`
- `pio_set_irqn_source_enabled(pio, irq_index, source, true)` — generic version for IRQ 0 or 1
- `pio_interrupt_get(pio, sm)` — check if a specific SM's IRQ flag is set (must call in handler)
- `pio_interrupt_clear(pio, sm)` — clear the flag (must call in handler — **not automatic**)

The `pio_interrupt_source_t` enum lists all events that can be routed to PIO NVIC lines:

| Enum value | Meaning |
|---|---|
| `pis_interrupt0`–`pis_interrupt3` | PIO SM IRQ flags 0–3 (set by `IRQ` instruction) |
| `pis_sm0_tx_fifo_not_full`–`pis_sm3_tx_fifo_not_full` | TX FIFO has room |
| `pis_sm0_rx_fifo_not_empty`–`pis_sm3_rx_fifo_not_empty` | RX FIFO has data |

Use these with `pio_set_irq0_source_mask_enabled` (bitmask variant) for efficient multi-source routing.

> **RIA note**: The RIA firmware uses `PIO0_IRQ_0` (IRQ7) and `PIO1_IRQ_0` (IRQ9) for OS call dispatch. `ria_action` fires an IRQ flag → asserts the NVIC line → Cortex enters `api_task()` on the designated core. Each core has its own NVIC; the PIO interrupt should be enabled on only one core.

Inter-core related:
- `SIO_IRQ_PROC0` (IRQ15) / `SIO_IRQ_PROC1` (IRQ16): fired when the inter-core FIFO has data. Relevant to RIA's dual-core architecture where one core handles PIO bus capture and the other runs the OS dispatcher.

### GPIO output priority

When multiple state machines write the same GPIO on the same cycle, **higher-numbered SM wins**. This applies separately to output level and output enable (direction) writes. A state machine that doesn't write a GPIO on a given cycle leaves its current value unchanged.

If a side-set and an OUT/SET from the same SM target the same GPIO on the same cycle, **side-set takes precedence**.

### Input synchronisers

Each GPIO input has a **2-flipflop synchroniser** to prevent metastability issues. This adds **2 cycles of input latency** to PIO — important for timing-sensitive programs. The synchroniser ensures IN PINS always reads a clean 0 or 1, never a metastable intermediate.

The synchroniser can be **bypassed per-GPIO** via `INPUT_SYNC_BYPASS` register, reducing latency by 2 cycles. Only suitable for synchronous interfaces where the state machine won't sample during transitions. Bypassing for UART RX or other asynchronous interfaces **will cause incorrect reads**.



The `pio_mov_status_type` enum controls what the `STATUS` source returns in a `MOV dest, STATUS` instruction:

| Value | Meaning |
|---|---|
| `STATUS_TX_LESSTHAN` | All-ones when TX FIFO level < threshold; all-zeros otherwise |
| `STATUS_RX_LESSTHAN` | All-ones when RX FIFO level < threshold; all-zeros otherwise |

Configured via `sm_config_set_mov_status(&c, status_sel, n)`. Useful for PIO programs that auto-stall based on FIFO fullness without involving the Cortex.

### Compile-time macros

Useful for building configuration tables that resolve at compile time without runtime overhead:

| Macro | Returns |
|---|---|
| `PIO_NUM(pio)` | Integer index of a PIO instance (0, 1, or 2) |
| `PIO_INSTANCE(n)` | Hardware pointer for PIO instance n |
| `PIO_FUNCSEL_NUM(pio, gpio)` | `gpio_function_t` to select this PIO on a given GPIO |
| `PIO_DREQ_NUM(pio, sm, is_tx)` | `dreq_num_t` for DMA pacing (TX or RX) — compile-time equivalent of `pio_get_dreq` |
| `PIO_IRQ_NUM(pio, irqn)` | `irq_num_t` for the PIO's NVIC interrupt line (irqn = 0 or 1) |

`PIO_DREQ_NUM` and `PIO_IRQ_NUM` are the compile-time counterparts of `pio_get_dreq()` and `pio_get_irq_num()`.

### Default SM configuration

`pio_get_default_sm_config()` returns a `pio_sm_config` struct with these defaults (also what `pio_sm_init` applies when passed `NULL`):

| Setting | Default |
|---|---|
| Out Pins | 32 pins starting at GPIO 0 |
| Set Pins | 0 count starting at GPIO 0 |
| In Pins | 32 pins starting at GPIO 0 |
| Side Set Pins (base) | GPIO 0 |
| Side Set | disabled |
| Wrap | `wrap=31`, `wrap_target=0` (wraps entire 32-instruction space) |
| In Shift | right, autopush=false, threshold=32 |
| Out Shift | right, autopull=false, threshold=32 |
| Jmp Pin | GPIO 0 |
| Out Special | sticky=false, no enable pin |
| Mov Status | `STATUS_TX_LESSTHAN`, n=0 |

In practice, always call the appropriate `sm_config_set_*` functions after `get_default_config` — relying on defaults for anything other than trivial programs leads to subtle bugs (e.g. default `wrap=31` wraps at instruction 31, not at the end of your program).



`EXECCTRL_WRAP_TOP` / `EXECCTRL_WRAP_BOTTOM`: when PC reaches WRAP_TOP (and it is not a taken JMP), execution jumps to WRAP_BOTTOM with zero timing penalty. Replaces an explicit `JMP start` at loop end — saves one instruction and one cycle per loop iteration. Set via `.wrap` / `.wrap_target` directives.

### Clock

24-bit fractional divider (16-bit integer + 8-bit fraction, units of 1/256) applied to `clk_sys`. Each SM can have an independent clock. For the RIA at 256 MHz system clock, dividing by 32 gives each PIO cycle 125 ns — enough headroom to handle PHI2 at 8 MHz (125 ns/cycle × 32 cycles/PHI2 = 4 µs PHI2 period).

---

## SDK Programming Patterns

*This section covers the Pico C SDK API for configuring and running PIO programs, based on [[fairhead-pico-c]] Ch.12. It complements the hardware reference above with the actual function calls used in practice.*

### Standard setup sequence

Every PIO program in C follows this init pattern:

```c
// 1. Load the PIO program binary into PIO instruction memory
uint offset = pio_add_program(pio0, &myprog_program);

// 2. Claim a free state machine (panics if none available when second arg is true)
uint sm = pio_claim_unused_sm(pio0, true);

// 3. Get default config struct (auto-generated from .pio file)
pio_sm_config c = myprog_program_get_default_config(offset);

// 4. Configure pin groups and clock (see below) …

// 5. Set GPIO function and pin directions before enabling
pio_gpio_init(pio0, pin);                                         // equiv to gpio_set_function(pin, GPIO_FUNC_PIO0)
pio_sm_set_consecutive_pindirs(pio0, sm, base, count, is_out);   // set output/input direction

// 6. Apply config and start
pio_sm_init(pio0, sm, offset, &c);
pio_sm_set_enabled(pio0, sm, true);
```

**RP2350 GPIO-range-aware variant** (preferred for portability):

```c
// Automatically selects a PIO block that can address the required GPIO range.
// Required on RP2350B (GPIOs >= 32) or when GPIOBASE must be set correctly.
PIO pio; uint sm; uint offset;
bool success = pio_claim_free_sm_and_add_program_for_gpio_range(
    &myprog_program, &pio, &sm, &offset, first_gpio, gpio_count, true);
hard_assert(success);
```

This function replaces the manual `pio_add_program` + `pio_claim_unused_sm` sequence with an auto-selection that checks PIO GPIO range compatibility. Use this in new RP2350 code.

### GPIO pin group configuration

| Group | Config function | Used by instruction |
|---|---|---|
| OUT | `sm_config_set_out_pins(&c, base, count)` | `out pins, n` — shifts OSR bits to GPIO |
| SET | `sm_config_set_set_pins(&c, base, count)` | `set pins, n` — writes 5-bit immediate to GPIO |
| IN | `sm_config_set_in_pins(&c, base)` | `in pins, n` — samples GPIO into ISR |
| SIDESET | `sm_config_set_sideset_pins(&c, base)` | Side-effect of every instruction |
| JMP pin | `sm_config_set_jmp_pin(&c, pin)` | `jmp pin, target` — conditional branch |

Alternative pindir helpers (operate on all 32 GPIO, not PIO groups):
```c
pio_sm_set_consecutive_pindirs(pio, sm, base, count, is_out);
pio_sm_set_pindirs_with_mask(pio, sm, pin_dirs, pin_mask);
```

**Key rule**: OUT and SET groups can overlap with SIDESET; when they target the same GPIO, SIDESET has precedence.

**Sticky output** (`sm_config_set_out_special`): re-asserts the most recent OUT/SET pin values on cycles where no `OUT`/`SET` instruction executes. Useful for SPI-like protocols where the data pin must hold its last value between transfers. Also supports an auxiliary output-enable pin (`has_enable_pin`, `enable_bit_index`) that gates the other output pins using one bit of the data word.

**IN pin masking** (RP2350 only): `sm_config_set_in_pin_count(&c, n)` limits how many bits are read by `IN PINS` — bits beyond the count read as zero. On RP2040, this field does not exist and the effective count is always 32.

### Clock divider

```c
// Integer+fractional divider (16-bit int, 8-bit frac in 1/256 units)
sm_config_set_clkdiv_int_frac(&c, div_int, div_frac);

// Or at runtime:
pio_sm_set_clkdiv(pio, sm, (float)div);
pio_sm_set_clkdiv_int_frac(pio, sm, div_int, div_frac);
```

> **Jitter warning**: The fractional divider achieves its average frequency by inserting extra-length periods. This causes timing jitter. For protocols requiring precise inter-cycle timing (like the RIA's 65C02 bus sampling), use integer-only dividers (`div_frac = 0`).

At 256 MHz system clock, `sm_config_set_clkdiv_int_frac(&c, 255, 0)` gives ~1 MHz SM clock (lowest usable).

### TX FIFO (C → PIO) and OSR

The C program writes 32-bit words to the TX FIFO; the PIO `pull` instruction loads them into the OSR:

```c
pio_sm_put(pio, sm, data);           // non-blocking; sets TXOVER flag if full
pio_sm_put_blocking(pio, sm, data);  // blocks until space available

// Query FIFO state:
pio_sm_is_tx_fifo_full(pio, sm);
pio_sm_is_tx_fifo_empty(pio, sm);
pio_sm_get_tx_fifo_level(pio, sm);
```

**OSR autopull** — automatically reloads the OSR from TX FIFO when it empties past a threshold, eliminating explicit `pull` instructions:
```c
sm_config_set_out_shift(&c, shift_right, autopull, pull_threshold);
// shift_right: true = LSB-first; false = MSB-first
// autopull: true = enable auto-reload
// pull_threshold: reload when fewer than N bits remain (0 = 32)
```

In the PIO program, `out pins, n` presents n bits from OSR to the OUT GPIO group simultaneously (not serial).

### RX FIFO (PIO → C) and ISR

The PIO `push` instruction writes the ISR to the RX FIFO; C reads it:

```c
pio_sm_get_blocking(pio, sm);        // blocks until data available
pio_sm_get(pio, sm);                 // non-blocking; returns undefined if empty

// Query FIFO state:
pio_sm_is_rx_fifo_full(pio, sm);
pio_sm_is_rx_fifo_empty(pio, sm);
pio_sm_get_rx_fifo_level(pio, sm);
```

**ISR autopush** — automatically transfers ISR to RX FIFO when a bit-count threshold is reached:
```c
sm_config_set_in_shift(&c, shift_right, autopush, push_threshold);
```

### Edge detection pattern

PIO has no edge-triggered inputs. Edges are detected by waiting for two consecutive pin states:

```pio
wait 0 pin 0    ; wait for pin to go low
wait 1 pin 0    ; wait for pin to go high → rising edge detected
```

`wait state pin n` uses pin n relative to the IN group base. `wait state gpio n` uses absolute GPIO number.

At maximum SM clock rate, the latency from the actual edge to the first instruction that executes after the second `wait` is approximately **45 ns** (measured by Fairhead on a logic analyser). At lower clock rates the response is less accurate — the tradeoff between accuracy and other timing constraints must be managed by choosing the SM clock rate to suit the protocol.

This pattern is how the RIA's `ria_write` and `ria_action` PIO programs synchronize to PHI2 transitions.

### SIDESET directive

```pio
.side_set count opt pindirs
```
- `count`: number of SIDESET bits (reduces available delay bits)
- `opt`: makes side-set optional per instruction (uses 1 extra bit to flag presence)
- `pindirs`: side-set controls pin direction instead of pin state

Equivalent SDK call: `sm_config_set_sideset(&c, bit_count, optional, pindirs)`.

### CMake integration

To assemble a `.pio` file and make it available to C:

```cmake
pico_generate_pio_header(my_target ${CMAKE_CURRENT_LIST_DIR}/myprogram.pio)
target_link_libraries(my_target hardware_pio)
```

The build system runs `[[pioasm]]` → generates `myprogram.pio.h` containing:
- `static const uint16_t myprogram_program_instructions[]` — binary opcodes
- `static const struct pio_program myprogram_program` — struct with pointer, length, origin
- `static inline pio_sm_config myprogram_program_get_default_config(uint offset)` — default config factory

### FIFO joining

Each state machine has two independent 4-word FIFOs (TX and RX). When a program only moves data in one direction, both FIFOs can be pooled into a single 8-word FIFO:

```c
sm_config_set_fifo_join(&c, PIO_FIFO_JOIN_TX);   // 8-word TX FIFO; RX disabled
sm_config_set_fifo_join(&c, PIO_FIFO_JOIN_RX);   // 8-word RX FIFO; TX disabled
sm_config_set_fifo_join(&c, PIO_FIFO_JOIN_NONE); // default: 4 TX + 4 RX
```

Use `PIO_FIFO_JOIN_TX` for output-only programs (WS2812 LED driver, PIX bus transmitter). Use `PIO_FIFO_JOIN_RX` for input-only programs (logic analyser, PIX bus receiver). The doubled depth gives more latency tolerance between PIO and DMA service.

### State machine cleanup and restart

Before re-arming a state machine (e.g. re-triggering a capture), fully reset its state:

```c
pio_sm_set_enabled(pio, sm, false);   // stop SM
pio_sm_clear_fifos(pio, sm);          // flush TX+RX FIFO contents
pio_sm_restart(pio, sm);              // clear ISR shift counter + SM internal state
```

`pio_sm_restart` clears any partially-filled ISR — important when the SM stalled mid-shift during a previous run.

**`pio_sm_drain_tx_fifo`** is a separate utility that empties the TX FIFO by executing `pull` instructions on the SM until empty. Unlike `pio_sm_clear_fifos` (which simply discards FIFO contents), drain operates through the PIO instruction path and disturbs the OSR contents. Use `clear_fifos` when you want a clean slate without touching SM register state; use `drain_tx_fifo` when you need to flush in-flight data through the OSR (rare — typically for protocol flush scenarios).

### Dynamic program generation (`pio_encode_*`)

For very short programs or programs whose instruction parameters are only known at runtime, the SDK provides `pio_encode_*` helpers to generate 16-bit instruction words without writing a `.pio` file:

```c
// Generate `in pins, <n>` — n only known at runtime
uint16_t instr = pio_encode_in(pio_pins, pin_count);

// Wrap in a pio_program struct (origin = -1 → no fixed placement required)
struct pio_program prog = {
    .instructions = &instr,
    .length = 1,
    .origin = -1,
};
uint offset = pio_add_program(pio, &prog);

// Encode a `wait gpio <level> <pin>` for one-shot injection:
uint16_t wait_instr = pio_encode_wait_gpio(trigger_level, trigger_pin);
```

`pio_encode_*` variants cover all PIO opcodes. The generated 16-bit words are identical to what `[[pioasm]]` produces for the same instruction.

#### Composition helpers (not standalone instructions)

Three helpers return **bit patterns to OR with an instruction word** — they do NOT return a valid instruction on their own:

| Helper | Returns | Shares bits with |
|---|---|---|
| `pio_encode_delay(cycles)` | delay-slot bits (0–31, or less if sideset in use) | `pio_encode_sideset`, `pio_encode_sideset_opt` |
| `pio_encode_sideset(bit_count, value)` | side-set bits (non-optional mode) | `pio_encode_delay` |
| `pio_encode_sideset_opt(bit_count, value)` | side-set bits (optional `.sideset <n> opt` mode) | `pio_encode_delay` |

Usage:
```c
// SET pins, 1 with 5-cycle delay and sideset value 2 (2 sideset bits):
uint instr = pio_encode_set(pio_pins, 1)
           | pio_encode_delay(5)
           | pio_encode_sideset(2, 2);
```

#### Complete JMP variant table

| SDK function | Assembly equivalent | Condition |
|---|---|---|
| `pio_encode_jmp(addr)` | `JMP <addr>` | Unconditional |
| `pio_encode_jmp_not_x(addr)` | `JMP !X <addr>` | X == 0 |
| `pio_encode_jmp_x_dec(addr)` | `JMP X-- <addr>` | X != 0, then post-decrement X |
| `pio_encode_jmp_not_y(addr)` | `JMP !Y <addr>` | Y == 0 |
| `pio_encode_jmp_y_dec(addr)` | `JMP Y-- <addr>` | Y != 0, then post-decrement Y |
| `pio_encode_jmp_x_ne_y(addr)` | `JMP X!=Y <addr>` | X != Y |
| `pio_encode_jmp_pin(addr)` | `JMP PIN <addr>` | JMP pin is high |
| `pio_encode_jmp_not_osre(addr)` | `JMP !OSRE <addr>` | OSR not empty (autopull threshold not met) |

All return encoding with 0 delay and no side-set; compose with `pio_encode_delay`/`pio_encode_sideset` as needed.

#### `wait_pin` vs `wait_gpio`

Two WAIT helpers target pins differently:

| Helper | Assembly | Pin addressing |
|---|---|---|
| `pio_encode_wait_pin(polarity, pin)` | `WAIT <polarity> PIN <pin>` | Relative to SM's **input pin mapping** (`sm_config_set_in_pins`) |
| `pio_encode_wait_gpio(polarity, gpio)` | `WAIT <polarity> GPIO <gpio>` | **Absolute GPIO** number relative to the PIO's `GPIO_BASE` (0–31) |

For `wait_gpio` on RP2350 with a non-zero GPIO base: subtract `GPIO_BASE` from the physical GPIO number. E.g. GPIO 42 with `GPIO_BASE=16` → pass `42-16 = 26`.

#### `pio_src_dest` enum — source/destination values

Used as arguments to `pio_encode_in`, `pio_encode_out`, `pio_encode_mov`, etc.:

| Value | Constant | Valid for |
|---|---|---|
| `pio_pins` | 0 | IN src, OUT/SET dest |
| `pio_x` | 1 | IN/OUT/MOV src+dest, JMP condition |
| `pio_y` | 2 | IN/OUT/MOV src+dest, JMP condition |
| `pio_null` | 3 | IN src, OUT dest (discard) |
| `pio_pindirs` | 4 | OUT dest (set pin directions) |
| `pio_exec_mov` | 4 | MOV dest (execute from register) |
| `pio_status` | 5 | MOV src (FIFO status flag) |
| `pio_pc` | 5 | MOV dest (jump via register) |
| `pio_isr` | 6 | IN/MOV src+dest |
| `pio_osr` | 7 | MOV src+dest |
| `pio_exec_out` | 7 | OUT dest (execute shifted-out word) |

> **NOTE**: Not all values are valid for all functions. Validity is only checked in debug builds when `PARAM_ASSERTIONS_ENABLED_PIO_INSTRUCTIONS=1`.

### SM EXEC — one-shot instruction injection

`pio_sm_exec` runs a single instruction on a state machine immediately, without writing it to instruction memory:

```c
pio_sm_exec(pio, sm, pio_encode_wait_gpio(trigger_level, trigger_pin));
```

If the instruction stalls (e.g. a `wait` condition not yet met), the SM latches it and retries each clock cycle until the condition clears. This is the standard mechanism to arm a capture program on a trigger: the SM is enabled but holds on the injected `wait` until the pin transitions — no data floods the RX FIFO until the trigger fires.

Two further EXEC options (same underlying hardware):
- **`out exec`** — shift an instruction word out of the OSR and execute it immediately; the data stream itself directs the SM's behaviour.
- **`mov exec`** — execute an instruction stored in X, Y, ISR, or OSR; useful for data-defined dispatch tables.

> **RIA note**: `pio_sm_exec` is used to poke initial setup instructions into bus-capture SMs during firmware init, avoiding the need for setup-only code paths in the PIO program itself.

### DMA integration with PIO

DMA and PIO are designed to work together. The DMA paces itself using a **DREQ** (data request) signal from the state machine — the SM asserts DREQ when its RX FIFO has data (for memory captures) or its TX FIFO has room (for memory playback):

```c
// PIO → memory (RX FIFO drain — e.g. logic analyser, 65C02 bus capture)
dma_channel_config dc = dma_channel_get_default_config(dma_chan);
channel_config_set_read_increment(&dc, false);               // always read from same FIFO address
channel_config_set_write_increment(&dc, true);               // advance destination buffer
channel_config_set_dreq(&dc, pio_get_dreq(pio, sm, false));  // false → RX DREQ

dma_channel_configure(dma_chan, &dc,
    dest_buf,          // write destination
    &pio->rxf[sm],     // read source (RX FIFO register)
    num_words,         // total 32-bit words to transfer
    true               // start immediately
);

// Block until all transfers complete:
dma_channel_wait_for_finish_blocking(dma_chan);
```

For memory → PIO (TX FIFO feeding — e.g. DMA-fed pixel output), swap the increment flags and use `pio_get_dreq(pio, sm, true)` (TX DREQ).

**Bus priority**: at very high transfer rates (>16 bits per system clock), grant DMA elevated bus priority to prevent CPU accesses from starving the FIFO:

```c
bus_ctrl_hw->priority = BUSCTRL_BUS_PRIORITY_DMA_W_BITS | BUSCTRL_BUS_PRIORITY_DMA_R_BITS;
```

> **RIA relevance**: The RIA firmware uses DMA to move data between PIO RX FIFOs and RP2350 memory at 65C02 bus speed. The DREQ handshake is what makes zero-polling data capture possible — the DMA only transfers when the SM has produced data.

### Program claiming helpers

Higher-level SDK functions atomically claim a free SM and load a program in one call:

```c
// Find free PIO + SM that can address the required GPIO range, then load program
bool ok = pio_claim_free_sm_and_add_program_for_gpio_range(
    &my_program, &pio, &sm, &offset, gpio_base, gpio_count, true);

// Matching release (unload program + unclaim SM)
pio_remove_program_and_unclaim_sm(&my_program, pio, sm, offset);
```

The `_for_gpio_range` variant is essential on RP2350 where PIO2 can address GPIO ≥32. Without it, `pio0`/`pio1` might be selected on a board using extended GPIOs, causing silent failures. Always pair with `pio_remove_program_and_unclaim_sm` to allow other programs to reuse the resources.

### Multi-SM synchronization

When multiple state machines must run in exact lockstep (e.g. the RIA's five bus-handling SMs), the SDK provides mask-based variants that operate on all specified SMs simultaneously in a single register write:

```c
// Enable/disable multiple SMs atomically
pio_set_sm_mask_enabled(pio, (1u<<sm0)|(1u<<sm1), true);

// Restart multiple SMs simultaneously (clears ISR, shift counters, PC, etc.)
pio_restart_sm_mask(pio, (1u<<sm0)|(1u<<sm1));

// Restart clock dividers on multiple SMs from phase 0
pio_clkdiv_restart_sm_mask(pio, (1u<<sm0)|(1u<<sm1));

// Atomic: enable + clock-divider restart in one cycle (most useful for sync start)
pio_enable_sm_mask_in_sync(pio, (1u<<sm0)|(1u<<sm1));
```

`pio_enable_sm_mask_in_sync` is the preferred way to start multiple SMs that share a tight timing relationship. It is equivalent to calling `pio_set_sm_mask_enabled` and `pio_clkdiv_restart_sm_mask` on the same clock cycle, ensuring the divided clocks of all masked SMs are in phase from the first cycle.

> **Clock divider independence**: Disabling a SM does **not** halt its clock divider — it keeps counting in the background. This means re-enabling a SM after a pause may resume at an arbitrary phase within the divider cycle, introducing jitter. To avoid this, always call `pio_sm_clkdiv_restart` (single SM) or `pio_clkdiv_restart_sm_mask` (multi-SM) when timing precision matters.

The mask functions also make cooperative claiming efficient:

```c
pio_claim_sm_mask(pio, (1u<<0)|(1u<<1)|(1u<<2));  // claim SMs 0,1,2 atomically (panics if any taken)
```

### RP2350B GPIO base

On the RP2350B 80-pin variant, there are 48 GPIOs but each PIO instance can only address 32 at a time. The GPIO base determines which 32 are accessible:

```c
// Set PIO0 to access GPIO 16–47 (base=16); default is base=0 (GPIO 0–31)
pio_set_gpio_base(pio0, 16);
```

Valid values: 0 (accesses GPIO 0–31) or 16 (accesses GPIO 16–47). No single PIO instance can simultaneously access both GPIO 0–15 and GPIO 32–47. The `pio_claim_free_sm_and_add_program_for_gpio_range` helper handles base selection automatically.

On RP2040 and RP2350A (48-pin), `pio_get_gpio_base` always returns 0 and `pio_set_gpio_base` has no effect.

---

### Custom protocol design patterns

*Based on [[fairhead-pico-c]] Ch.13 (DHT22 sensor as a worked example of PIO custom protocol implementation).*

#### Sampling vs counting

There are two strategies for decoding pulse-width-encoded protocols (where bit value = pulse width):

| Strategy | How it works | Tradeoff |
|---|---|---|
| **Counting** | Count SM clock cycles while pin is high; transfer count to CPU for threshold comparison | Flexible, but CPU must post-process; packing 4-bit counts limits bits-per-FIFO-word |
| **Sampling** | Wait for rising edge + fixed delay; sample pin state once → 1 bit into ISR | Simpler PIO, no CPU math, packs 32 bits per FIFO word via autopush |

The sampling approach is preferred wherever the protocol allows it. The key insight: **a fixed delay after a rising edge will land in the "0 zone" for a short pulse and the "1 zone" for a long pulse** — no counting or thresholding needed in the PIO program.

```pio
bits:
    wait 1 pin 0 [25]   ; wait for rising edge, then delay 25 clock cycles
    in pins, 1          ; sample pin — 0 for short pulse, 1 for long pulse
    wait 0 pin 0        ; wait for pin to return low
    jmp y--, bits
```

The delay `[25]` on the `wait` instruction is counted from the cycle the edge is detected, positioning the sample at a fixed time into the bit frame. Choose the SM clock divider so that `25 × (1/SM_freq)` lands between the "0" and "1" pulse widths.

#### Parameterized PIO startup via TX FIFO

To pass a parameter (e.g. a loop count or timing value) from C into the PIO program at startup without hard-coding it:

```pio
again:
    pull block          ; stall until C writes a value
    mov x, osr          ; use it as loop counter / timing parameter
    ; ... use x ...
```

```c
pio_sm_set_enabled(pio, sm, true);
pio_sm_put_blocking(pio, sm, 1000);  // send parameter to start PIO running
```

This pattern lets C tune PIO timing constants (e.g. for Pico vs Pico 2 clock rate differences) without recompiling the `.pio` file. The RIA could use this pattern to pass PHI2 target frequency as a startup parameter.

#### Bidirectional / open-collector pin

For 1-wire-style buses where the Pico must both drive and receive on the same pin:

```pio
set pindirs, 1      ; switch pin to output (drive start pulse)
set pins, 0
; ... timed delay ...
set pindirs, 0      ; release to input (high-Z); pull-up takes line high
; ... receive data ...
```

Both SET and IN groups point to the same GPIO. The open-collector model requires an external pull-up resistor; when the PIO releases the pin direction, the line floats high. This same model applies anywhere the RIA needs to release a shared bus line after driving it.

---

## Related pages

- [[gpio-pinout]] · [[pix-bus]] · [[rp6502-ria]] · [[rp6502-vga]] · [[reset-model]] · [[rp2040-clocks]] · [[dma-controller]] · [[pioasm]] · [[hardware-irq]] · [[quadros-rp2040]] · [[fairhead-pico-c]] · [[pico-c-sdk]]
