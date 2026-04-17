---
type: concept
tags: [rp6502, ria, vga, pio, rp2350, hardware, firmware]
related: [[rp6502-ria]], [[rp6502-vga]], [[pix-bus]], [[gpio-pinout]], [[reset-model]]
sources: [[rp6502-github-repo]], [[quadros-rp2040]], [[fairhead-pico-c]]
created: 2026-04-16
updated: 2026-04-16
---

# PIO Architecture

**Summary**: How the RIA firmware uses RP2350 PIO state machines to bit-bang the 65C02 bus and drive the PIX bus — and how the VGA firmware uses PIO to receive PIX and output pixels.

---

## Why PIO?

The RP2350 has no dedicated 6502 bus controller. PIO (Programmable I/O) state machines fill that gap: they run tiny programs in hardware at deterministic cycle counts, independent of the main Cortex-M33 cores. The RIA uses PIO to sample the 65C02 address/data bus at exactly the right moment in the PHI2 cycle, decode chip-select and read/write, and drive data onto the bus — all without the Cortex touching the bus timing.

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
| `WAIT pol gpio/pin/irq idx` | Stall until GPIO/PIN/IRQ matches polarity; for IRQ: `rel` makes index relative to SM number |
| `IN source, bit_count` | Shift bits into ISR from PINS/X/Y/NULL/ISR/OSR; auto-push when threshold reached |
| `OUT dest, bit_count` | Shift bits from OSR to PINS/X/Y/PINDIR/PC/ISR/EXEC; auto-pull when threshold reached |
| `PUSH (iffull) (block)` | Push ISR to RX FIFO, clear ISR; IfFull: only if shift count reached threshold |
| `PULL (ifempty) (block)` | Load TX FIFO into OSR; IfEmpty: only if shift count reached threshold |
| `MOV dest, (op,) source` | Copy with None/Invert/Bit-reverse; `MOV EXEC` runs source as instruction |
| `IRQ (set/wait/clear) num (rel)` | Set, set-and-wait, or clear IRQ flag; `rel` adds SM index for portable multi-SM code |
| `SET dest, value` | Write immediate 0–31 to PINS/X/Y/PINDIRS |

Stalling instructions: WAIT, IN (auto-push full), OUT (auto-pull empty), PUSH (block), PULL (block), IRQ (wait). A stalled SM holds its position indefinitely until the condition is met.

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

The lower 4 PIO IRQ flags (0–3) can be routed to two ARM NVIC interrupt lines per PIO block:

| NVIC IRQ | ARM IRQ# | Triggered by |
|---|---|---|
| `PIO0_IRQ_0` | 7 | Selected PIO0 SM IRQ flags (configured via `pio_set_irq0_source_enabled`) |
| `PIO0_IRQ_1` | 8 | Selected PIO0 SM IRQ flags (configured via `pio_set_irq1_source_enabled`) |
| `PIO1_IRQ_0` | 9 | Selected PIO1 SM IRQ flags |
| `PIO1_IRQ_1` | 10 | Selected PIO1 SM IRQ flags |

SDK routing functions (`hardware_pio`):
- `pio_set_irq0_source_enabled(pio, pis_interrupt0 + sm, true)` — enables PIO SM IRQ flag 0 to assert `PIOx_IRQ_0`
- `pio_interrupt_get(pio, sm)` — check if a specific SM's IRQ flag is set (must call in handler)
- `pio_interrupt_clear(pio, sm)` — clear the flag (must call in handler — **not automatic**)

> **RIA note**: The RIA firmware uses `PIO0_IRQ_0` (IRQ7) and `PIO1_IRQ_0` (IRQ9) for OS call dispatch. `ria_action` fires an IRQ flag → asserts the NVIC line → Cortex enters `api_task()` on the designated core. Each core has its own NVIC; the PIO interrupt should be enabled on only one core.

Inter-core related:
- `SIO_IRQ_PROC0` (IRQ15) / `SIO_IRQ_PROC1` (IRQ16): fired when the inter-core FIFO has data. Relevant to RIA's dual-core architecture where one core handles PIO bus capture and the other runs the OS dispatcher.

### Program wrapping

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

The build system runs `pioasm` → generates `myprogram.pio.h` containing:
- `static const uint16_t myprogram_program_instructions[]` — binary opcodes
- `static const struct pio_program myprogram_program` — struct with pointer, length, origin
- `static inline pio_sm_config myprogram_program_get_default_config(uint offset)` — default config factory

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

- [[gpio-pinout]] · [[pix-bus]] · [[rp6502-ria]] · [[rp6502-vga]] · [[reset-model]] · [[rp2040-clocks]] · [[quadros-rp2040]] · [[fairhead-pico-c]]
