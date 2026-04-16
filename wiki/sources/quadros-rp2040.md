---
type: source
tags: [rp2040, rp2350, pio, gpio, dma, usb, uart, spi, interrupts, multicore]
related: [[pio-architecture]], [[gpio-pinout]], [[dual-core-sio]], [[rp6502-ria]], [[rp6502-os]]
sources: []
created: 2026-04-16
updated: 2026-04-16
---

# Source: "Knowing the RP2040" (Quadros, 2022)

**Summary**: Hardware-reference book covering the RP2040 microcontroller — architecture, PIO, GPIO, DMA, interrupts, USB, UART, SPI. The RIA firmware runs on the RP2350, whose peripherals are architecturally compatible with the RP2040.

**File**: `raw/pdfs/Knowing the RP2040 (Quadros).pdf` (253 pages)
**Author**: Daniel Quadros
**Year**: 2022 (updated edition with SIO register detail and GPIO interrupt chapter)
**Note**: PDF pages use a +5 offset from printed page numbers.

---

## Key facts

### RP2040 Architecture overview

- **Processor subsystem**: Two ARM Cortex-M0+ cores (Proc0, Proc1) + SIO (Single-cycle IO block). SIO gives both cores low-latency, deterministic access to memory-mapped peripherals including GPIO; designed for fast inter-core synchronization.
- **Bus fabric**: AHB-Lite Crossbar 4:10 — 4 upstream ports (two cores + DMA read + DMA write) to 10 downstream ports. Up to 4 AHB bus transfers per cycle. Slower peripherals on APB connected via APB bridge.
- **Address map**:

| Address | Resource |
|---|---|
| `0x00000000` | ROM (16 kB, startup firmware) |
| `0x10000000` | XIP/Flash cache (external QSPI flash, 16 kB cache) |
| `0x20000000` | SRAM |
| `0x40000000` | APB Peripherals (UART, SPI, I²C, ADC, PWM, Timer, RTC, Watchdog) |
| `0x50000000` | AHB-Lite Peripherals (PIO0, PIO1, USB) |
| `0xD0000000` | IOPORT Registers (SIO, fast GPIO access) |
| `0xE0000000` | Cortex-M0+ registers |

- **SRAM**: 6 banks — 4×64 kB + 2×4 kB = 264 kB total. Multiple banks allow two cores to access RAM without contention.
- **Clock generation**: Ring oscillator (~6–12 MHz, imprecise), 12 MHz crystal oscillator (feeds two PLLs for USB and system clock), external clocks up to 50 MHz. Ten configurable clock generators select source and divisor.

### PIO programmer's model

Each state machine has five registers:
- **OSR** (Output Shift Register): shifts data from TX FIFO to GPIO output pins
- **ISR** (Input Shift Register): shifts data from GPIO input pins to RX FIFO
- **X, Y** (scratch registers): general-purpose 32-bit counters/temporaries; used for loop counts, pin states, data buffering
- **PC** (Program Counter): points to executing instruction; JMP, IN, and MOV can change it

### PIO structure

- 2 PIO blocks (PIO0, PIO1) × 4 state machines each = **8 state machines total**
- Each PIO has **32-instruction shared program memory** — all 4 SMs in a PIO share this space
- Each SM has **TX FIFO (4×32-bit) + RX FIFO (4×32-bit)**; can be joined to a single 8×32-bit FIFO (TX-only or RX-only mode)
- Auto-push: ISR automatically pushed to RX FIFO when shift count reaches threshold
- Auto-pull: OSR automatically loaded from TX FIFO when shift count reaches threshold
- **8 shared IRQ flags** (0–7): lower 4 (IRQ 0–3) can trigger ARM core interrupt lines; all 8 accessible to all state machines for inter-SM synchronization

### PIO instruction set

Every instruction is **16 bits**, executes in **1 clock cycle**, plus optional delay.

| Instruction | Opcode | Operation |
|---|---|---|
| JMP | 000 | Jump if condition; 8 conditions: always, !X, X--, !Y, Y--, X≠Y, PIN, !OSRE |
| WAIT | 001 | Stall until condition: GPIO, PIN (mapped), IRQ |
| IN | 010 | Shift `bit_count` bits from source into ISR; sources: PINS, X, Y, NULL, ISR, OSR |
| OUT | 011 | Shift `bit_count` bits from OSR to destination; destinations: PINS, X, Y, PINDIR, PC, ISR, EXEC |
| PUSH | 100 | Push ISR to RX FIFO and clear ISR; IfFull and Block flags |
| PULL | 100 | Pull TX FIFO into OSR; IfEmpty and Block flags |
| MOV | 101 | Copy source to destination with optional invert or bit-reverse; can target EXEC |
| IRQ | 110 | Set, clear, or set-and-wait IRQ flag; supports relative addressing (adds SM index) |
| SET | 111 | Write immediate (0–31) to PINS, X, Y, or PINDIRS |

**Instruction format** (16 bits):
- Bits 15–13: opcode
- Bits 12–8: delay/side-set (5 bits shared — more side-set pins = fewer delay cycles available; max 31 delay cycles with no side-set, down to 15 with 1 side-set pin)
- Bits 7–0: operands

**Stalling instructions**: WAIT, IN (auto-push), OUT (auto-pull), PUSH (block), PULL (block), IRQ (wait). An instruction that stalls holds the SM in the same cycle indefinitely.

**Executing instructions from outside program memory** — three methods:
1. Write to `SMx_INSTR` register
2. `MOV EXEC, source` — execute a register value as instruction
3. `OUT EXEC, ...` — execute data from TX FIFO as instruction

### PIO configuration

**GPIO pin groups** (each SM configures independently):
- **Input**: base pin; used by WAIT, IN, MOV(PINS source)
- **Output**: base pin + count; used by OUT, MOV(PINS destination)
- **Set**: base pin + count (up to 5); used by SET PINS and SET PINDIRS
- **Side-Set**: base pin + count (up to 5); driven every instruction via instruction bits
- **Jump-Pin**: single pin tested by JMP PIN condition

**Program wrapping** — `EXECCTRL_WRAP_TOP` / `EXECCTRL_WRAP_BOTTOM`: when PC reaches WRAP_TOP (and next instruction is not a taken JMP), execution jumps to WRAP_BOTTOM with no timing penalty. Replaces an explicit JMP at end of loop.

**Clock**: 24-bit fractional divider (16-bit integer + 8-bit fraction, units of 1/256) applied to `clk_sys`. Each SM can have a different clock. Every PIO instruction executes in exactly 1 system-clock-adjusted cycle.

### PIO SDK functions (hardware_pio)

**State machine lifecycle**:
- `pio_claim_unused_sm(pio, required)` — allocate next free SM
- `pio_add_program(pio, program)` — load PIO program into shared instruction memory
- `pio_sm_init(pio, sm, initial_pc, config)` — reset and configure SM
- `pio_sm_set_enabled(pio, sm, enabled)` — start/stop SM

**FIFO access**:
- `pio_sm_get(pio, sm)` / `pio_sm_get_blocking(pio, sm)` — read from RX FIFO
- `pio_sm_put(pio, sm, data)` / `pio_sm_put_blocking(pio, sm, data)` — write to TX FIFO
- `pio_sm_get_rx_fifo_level(pio, sm)` / `pio_sm_get_tx_fifo_level(pio, sm)` — FIFO depth

**Configuration builders** (`pio_sm_config` struct, set via `sm_config_set_*`):
- `sm_config_set_clkdiv(c, div)` — clock divisor (float)
- `sm_config_set_in_shift(c, shift_right, autopush, threshold)`
- `sm_config_set_out_shift(c, shift_right, autopull, threshold)`
- `sm_config_set_fifo_join(c, join)` — `PIO_FIFO_JOIN_NONE`, `_TX`, `_RX`
- `sm_config_set_in_pins(c, in_base)`
- `sm_config_set_out_pins(c, out_base, out_count)`
- `sm_config_set_set_pins(c, set_base, set_count)`
- `sm_config_set_sideset(c, bit_count, optional, pindirs)`
- `sm_config_set_wrap(c, wrap_target, wrap)`
- `sm_config_set_jmp_pin(c, pin)`

**Miscellaneous**:
- `pio_interrupt_clear(pio, num)` / `pio_interrupt_get(pio, num)` — IRQ flag control
- `pio_sm_exec(pio, sm, instr)` — inject instruction into running SM
- `pio_gpio_init(pio, pin)` — connect GPIO pin to PIO (required for output; recommended for all)

### Reset and interrupt model

#### Chip reset

Full chip-level reset (*chip-level reset*) puts the RP2040 in its starting state. Causes:
1. Initial power-on
2. **Brown-out** event (supply drops below 0.86 V threshold; threshold adjustable, detector can be disabled)
3. **RUN pin** pulled LOW
4. **SWD Rescue DP** (debug port; only resets the chip when the chip is locked up, not when it itself causes the reset)

The RP2040 has a register recording the most recent reset cause. The reset controller allows software to reset individual peripherals via `hardware_resets`:

```c
void reset_block(uint32_t bits);       // assert reset; stays until unreset called
void unreset_block(uint32_t bits);     // de-assert reset (may take time to complete)
void unreset_block_wait(uint32_t bits); // de-assert and wait for completion
```

Key peripheral reset bits (RIA-relevant):

| Peripheral | Bit | Peripheral | Bit |
|---|---|---|---|
| PIO 0 | 10 | DMA | 2 |
| PIO 1 | 11 | IO Bank 0 | 5 |
| USB | 24 | Pads – Bank 0 | 8 |
| UART 0 | 22 | SPI 0 | 16 |
| UART 1 | 23 | PLL System | 12 |

#### NVIC interrupt table

The NVIC (Nested Vectored Interrupt Controller) handles interrupts for each ARM core. Priorities are 0–255 (lower = higher priority); default is `PICO_DEFAULT_IRQ_PRIORITY` = 0x80. Each core has its own NVIC — **an interrupt should be enabled in only one core**.

The WIC (Wakeup Interrupt Controller) identifies interrupts when the processor is in DORMANT state.

All 26 RP2040 IRQs (names from `intctrl.h`):

| IRQ# | Source | IRQ# | Source |
|---|---|---|---|
| 0 | `TIMER_IRQ_0` | 13 | `IO_IRQ_BANK0` |
| 1 | `TIMER_IRQ_1` | 14 | `IO_IRQ_QSPI` |
| 2 | `TIMER_IRQ_2` | 15 | `SIO_IRQ_PROC0` |
| 3 | `TIMER_IRQ_3` | 16 | `SIO_IRQ_PROC1` |
| 4 | `PWM_IRQ_WRAP` | 17 | `CLOCKS_IRQ` |
| 5 | `USBCTRL_IRQ` | 18 | `SPI0_IRQ` |
| 6 | `XIP_IRQ` | 19 | `SPI1_IRQ` |
| 7 | `PIO0_IRQ_0` | 20 | `UART0_IRQ` |
| 8 | `PIO0_IRQ_1` | 21 | `UART1_IRQ` |
| 9 | `PIO1_IRQ_0` | 22 | `ADC0_IRQ_FIFO` |
| 10 | `PIO1_IRQ_1` | 23 | `I2C0_IRQ` |
| 11 | `DMA_IRQ_0` | 24 | `I2C1_IRQ` |
| 12 | `DMA_IRQ_1` | 25 | `RTC_IRQ` |

SDK functions (`hardware_irq`):

| Function | Description |
|---|---|
| `irq_set_exclusive_handler(num, handler)` | Attach single handler; asserts if one already exists |
| `irq_add_shared_handler(num, handler, order_priority)` | Attach one of multiple handlers; called in descending `order_priority` order |
| `irq_remove_handler(num, handler)` | Remove a shared handler |
| `irq_set_enabled(num, enabled)` | Enable or disable an IRQ |
| `irq_set_priority(num, priority)` | Set 0–255 priority (lower = higher priority) |
| `irq_set_mask_enabled(mask, enabled)` | Batch enable/disable by bitmask |
| `irq_clear(int_num)` | Clear a pending interrupt |
| `irq_set_pending(num)` | Programmatically trigger an interrupt |

> Shared handlers: all registered handlers are called; each must check its specific cause and clear it. Use `irq_add_shared_handler` for `IO_IRQ_BANK0` (shared across all GPIO interrupts) and PIO IRQ lines shared across multiple SMs.

#### Power control (not RIA-relevant)

Two sleep states: **SLEEP** (both cores idle, no DMA; exited by any interrupt; clock-gated peripherals) and **DORMANT** (all clocks + oscillators off; exited only by GPIO edge or RTC interrupt). RIA runs at 256 MHz continuously — these states are not used.

### Cortex-M0+ core features (RIA-relevant subset)

- **ARMv6-M** (Thumb instruction set): 16-bit instructions, 32-bit registers R0–R15. R13 = stack pointer (MSP or PSP), R14 = link register, R15 = PC.
- **PRIMASK**: single-bit interrupt mask; when set, prevents all exceptions except NMI and HardFault. Used by `critical_section_enter_blocking()`.
- **SysTick**: 24-bit countdown timer clocked at 1 MHz (`timer_tick`). Generates an interrupt on zero. SDK uses this for `sleep_ms()` / `sleep_us()`.
- **WFI / WFE instructions**: "Wait For Interrupt / Event" — core halts until an interrupt or event arrives. Used in idle loops to avoid burning cycles at full clock.
- **SVC instruction**: Supervisor Call — generates a synchronous exception with an 8-bit immediate. Not used in RIA bare-metal firmware.

> **RP2350 note**: The RIA runs on RP2350, which uses Cortex-M33 cores, not Cortex-M0+. The instruction set and SIO architecture are compatible; the differences (FPU, DSP, TrustZone) are not used by the RIA firmware.

### SIO (Single-cycle IO block)

The SIO lives at `0xD0000000` (IOPORT). Both cores have single-cycle, contention-free access. Provides:

- **CPUID registers** (one per core): read to identify current core (0 or 1).
- **Inter-processor FIFOs**: two 8-word (8 × 32-bit) queues — FIFO 0→1 and FIFO 1→0. Data arrival interrupts the reading core via `SIO_IRQ_PROC0` (IRQ 15) or `SIO_IRQ_PROC1` (IRQ 16). SDK: `pico_multicore` (`multicore_fifo_push_blocking`, `multicore_fifo_pop_blocking`, etc.).
- **Hardware spinlocks ×32**: each a one-bit flag at its own address. Write=claim, read=check (non-zero = owned by you), write=release. For short critical sections across cores.
- **Atomic GPIO aliases**: SET/CLR/XOR address aliases for SIO GPIO registers allow single-write atomic bit operations — eliminates read-modify-write races between cores.
- **Integer divider** (per-core) and **Interpolators** (per-core): hardware arithmetic — not directly relevant to RIA.

#### Core startup

After reset, `main()` runs on core 0; core 1 sleeps. To start core 1:
```c
multicore_reset_core1();
multicore_launch_core1(entry_fn);  // entry_fn(void) runs on core 1
```

See [[dual-core-sio]] for the full SDK API and RIA usage breakdown.

---

## RIA firmware connections

| Quadros concept | RIA usage in `ria.pio` |
|---|---|
| `WAIT GPIO/PIN` | `ria_write` and `ria_read` wait for PHI2 rising/falling edge |
| `IN PINS` | Address and data bits shifted into ISR during bus capture |
| `SET PINDIRS` | `ria_cs_rwb` switches data bus between input and output |
| Side-set | `ria_write` generates PHI2 as a side-effect of the write-capture loop |
| IRQ flags | Inter-SM synchronization (e.g., cs_rwb signals write_SM for bus direction changes) |
| `OUT PINS` + side-set | Structural parallel: PIX bus TX (`pix_tx`) shifts data with PHI2 as side-set clock |
| Program wrapping | All RIA programs loop continuously with `.wrap`/`.wrap_target` |
| FIFO → DMA | TX/RX FIFOs connected to DMA for XRAM bulk transfers |

---

## Scope

Chapters marked `[x]` have been ingested; `[-]` are skipped.

| Status | Chapter | PDF pages | Notes |
|---|---|---|---|
| [x] | The RP2040 Architecture | 9–12 | Address map, bus fabric, memory, clock overview |
| [-] | Introduction | 6–8 | Author context — skipped |
| [-] | (session 1 ends here; remaining chapters below) | | |
| [x] | The Cortex-M0+ Processor Cores | 13–26 | Dual-core model, SIO inter-processor FIFOs, hardware spinlocks, atomic GPIO, `pico_multicore` / `pico_sync` SDK |
| [x] | Reset, Interrupts and Power Control | 27–41 | Reset causes, NVIC IRQ table (26 IRQs), PIO→ARM interrupt wiring, SDK irq_* functions |
| [ ] | Memory, Addresses and DMA | 42–67 | DMA for XRAM transfers |
| [ ] | Clock Generation, Timer, Watchdog and RTC | 68–88 | Overclock context |
| [x] | GPIO, Pad and PWM | 89–131 | Function select, PAD config (drive strength, slew, Schmitt trigger), interrupt model |
| [x] | The Programmable I/O (PIO) | 132–158 | Full ISA, programmer's model, SDK API |
| [ ] | Asynchronous Serial Communication: the UARTs | 172–183 | Console UART |
| [ ] | Communication Using SPI | 184–193 | SD card |
| [ ] | A Brief Introduction to the USB Controller | 200–232 | HID, VCP |
| [-] | Communication Using I²C | 159–171 | Not used in RP6502 — skipped |
| [-] | Analog Input: the ADC | 194–199 | No analog use case — skipped |
| [-] | Conclusion | 233 | Wrap-up — skipped |
| [-] | Appendix A – CMake | 234–236 | Build toolchain — skipped |
| [-] | Appendix B – Using stdio | 237–241 | SDK stdio — skipped |
| [-] | Appendix C – Debugging Using SWD | 242–253 | Out of scope — skipped |

---

## Related pages

- [[pio-architecture]]
- [[gpio-pinout]]
- [[rp6502-ria]]
- [[rp6502-os]]
