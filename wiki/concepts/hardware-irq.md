---
type: concept
tags: [rp6502, ria, rp2040, rp2350, hardware, firmware, irq, nvic]
related: [[pio-architecture]], [[gpio-pinout]], [[dma-controller]], [[dual-core-sio]], [[rp2040-clocks]]
sources: [[pico-c-sdk]]
created: 2026-04-17
updated: 2026-04-17
---

# Hardware IRQ

**Summary**: The Pico SDK `hardware_irq` API for installing and managing NVIC interrupt handlers on the RP2040/RP2350 — covering per-core NVIC semantics, three handler-installation patterns, priority model, and user (software) IRQs.

---

## NVIC architecture

Both RP2040 and RP2350 use the ARM NVIC (Nested Vectored Interrupt Controller). Key characteristics:

- Each core has its **own NVIC** with independent enable/disable/priority registers.
- The same hardware interrupt lines are routed to both cores, **except** IO bank interrupts — each bank has one IRQ per core (so GPIO bank 0 can independently interrupt core 0 and core 1 on different GPIOs).
- **All `hardware_irq` API calls affect the executing core only.**
- Do **not** enable the same shared IRQ number on both cores — this causes race conditions or starvation. Exception: use `get_core_num()` inside a single handler when the same IRQ genuinely needs to fire on both cores.

On RP2040: 32 IRQ lines; only the lower 26 (IRQ 0–25) are connected to hardware; IRQs 26–31 are software-only ("user IRQs").  
On RP2350: 52+ IRQ lines defined; additional timers, DMA channels, and a third PIO block.

---

## IRQ number tables

### RP2040

| IRQ | Name | IRQ | Name |
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
| 9 | `PIO1_IRQ_0` | 22 | `ADC_IRQ_FIFO` |
| 10 | `PIO1_IRQ_1` | 23 | `I2C0_IRQ` |
| 11 | `DMA_IRQ_0` | 24 | `I2C1_IRQ` |
| 12 | `DMA_IRQ_1` | 25 | `RTC_IRQ` |

IRQs 26–31 are spare/user IRQs (not connected to hardware).

### RP2350 (selected)

| IRQ | Name | IRQ | Name |
|---|---|---|---|
| 0–3 | `TIMER0_IRQ_0`–`3` | 21 | `IO_IRQ_BANK0` |
| 4–7 | `TIMER1_IRQ_0`–`3` | 22 | `IO_IRQ_BANK0_NS` |
| 8–9 | `PWM_IRQ_WRAP_0`–`1` | 23–24 | `IO_IRQ_QSPI`, `IO_IRQ_QSPI_NS` |
| 10–13 | `DMA_IRQ_0`–`3` | 25 | `SIO_IRQ_FIFO` |
| 14 | `USBCTRL_IRQ` | 26 | `SIO_IRQ_BELL` |
| 15–16 | `PIO0_IRQ_0`–`1` | 30 | `CLOCKS_IRQ` |
| 17–18 | `PIO1_IRQ_0`–`1` | 31–34 | `SPI0/1_IRQ`, `UART0/1_IRQ` |
| 19–20 | `PIO2_IRQ_0`–`1` | 35 | `ADC_IRQ_FIFO` |

On RP2350, `SIO_IRQ_FIFO` is a single IRQ number for both cores (unlike RP2040 where `SIO_IRQ_PROC0/1` were separate). IRQs 46–51 are spare.

> **RP6502 relevance**: The RIA runs on RP2350. The IRQ numbers that matter most are `IO_IRQ_BANK0` (GPIO callbacks), `PIO0_IRQ_0`, `PIO1_IRQ_0` (OS call dispatch from PIO state machines), and `SIO_IRQ_FIFO` (inter-core communication).

---

## Three handler installation methods

### 1. `irq_set_exclusive_handler` — single-owner handler

```c
irq_set_exclusive_handler(IRQ_NUM, my_handler);
irq_set_enabled(IRQ_NUM, true);
```

Use when your code is the only consumer of the IRQ. Panics if any handler (exclusive or shared) is already installed.  
Best for: DMA channels, SPI, UART, timer alarms — peripherals with one clear owner.

### 2. `irq_add_shared_handler` — multiplexed handler

```c
irq_add_shared_handler(IO_IRQ_BANK0, gpio_bank_handler, PICO_SHARED_IRQ_HANDLER_DEFAULT_ORDER_PRIORITY);
irq_set_enabled(IO_IRQ_BANK0, true);
```

Use when multiple drivers share one IRQ number (e.g. all GPIO pins share `IO_IRQ_BANK0`, all DMA channels can share `DMA_IRQ_0`). **Each handler must check and clear only its own hardware interrupt source.**

The `order_priority` argument controls call order:
- **Higher value = called first** (opposite of the CPU priority scale)
- Use `PICO_SHARED_IRQ_HANDLER_DEFAULT_ORDER_PRIORITY` (mid-range) if order doesn't matter
- Handlers with identical priority are called in undefined order

### 3. Static definition (weakly linked symbol override)

```c
void isr_dma_0(void) { … }   // core 0 DMA_IRQ_0 handler — overrides weak default
```

Defines the handler at link time. **Generally not recommended** — causes link conflicts if any SDK code also registers a handler for the same IRQ, and provides no runtime performance benefit. Use `irq_set_exclusive_handler` instead.

---

## Key API functions

| Function | Description |
|---|---|
| `irq_set_exclusive_handler(num, handler)` | Install sole handler; panics if already installed |
| `irq_add_shared_handler(num, handler, order)` | Add shared handler; called in order_priority order |
| `irq_remove_handler(num, handler)` | Remove a handler (exclusive or shared); may be called from within the handler |
| `irq_get_exclusive_handler(num)` | Returns handler if exclusive, NULL otherwise |
| `irq_has_handler(num)` | True if any handler installed |
| `irq_has_shared_handler(num)` | True if shared handlers installed |
| `irq_get_vtable_handler(num)` | Returns address stored in VTOR for the IRQ |
| `irq_set_enabled(num, enabled)` | Enable/disable IRQ in NVIC on executing core |
| `irq_is_enabled(num)` | True if IRQ enabled on executing core |
| `irq_set_mask_enabled(mask, enabled)` | Enable/disable multiple IRQs via 32-bit bitmask |
| `irq_set_mask_n_enabled(n, mask, enabled)` | Enable/disable IRQs in group n (n=0 → IRQs 0–31, n=1 → 32–63) |
| `irq_set_priority(num, priority)` | Set hardware priority (0 = highest, 255 = lowest) |
| `irq_get_priority(num)` | Get current hardware priority |
| `irq_clear(num)` | Clear pending IRQ — **only useful for software IRQs**; hardware IRQs must clear via their peripheral register |
| `irq_set_pending(num)` | Force IRQ pending — mainly for software IRQs |

---

## Priority model

Priorities range 0 (highest) to 255 (lowest). **Numerically lower = higher priority** (ARM convention).

- All IRQ priorities are initialized to `PICO_DEFAULT_IRQ_PRIORITY` (default `0x80`) at startup.
- On RP2040 (Cortex-M0+): **only the top 2 bits** are significant → 4 effective levels (0x00, 0x40, 0x80, 0xC0).
- On RP2350 (Cortex-M33 or Hazard3 RISC-V): **top 4 bits** are significant → 16 levels. The RISC-V core uses the same (inverted) ordering as ARM.

> **Note**: The `order_priority` argument to `irq_add_shared_handler` uses **higher = first** (opposite of CPU priority). These are independent systems.

---

## Vector table and dual-core

By default the SDK uses a **single shared vector table** for both cores. Consequence:
- `irq_set_exclusive_handler` / `irq_add_shared_handler` installs the handler for **both cores** (it's in the shared table).
- Enabling the same IRQ on both cores (`irq_set_enabled` called on both) means the handler races — avoid unless the IRQ is core-local (user IRQs, RP2350 `SIO_IRQ_FIFO`).
- For core-local IRQs, install the handler once, call `get_core_num()` inside it to distinguish cores.

`PICO_VTABLE_PER_CORE` indicates separate vector tables, but as of SDK 2.1.1 this is not fully supported — not user-configurable.

---

## User IRQs (software-only)

On RP2040, IRQs 26–31. On RP2350, `SPARE_IRQ_0`–`SPARE_IRQ_5`.

- Not connected to any hardware — triggered only by `irq_set_pending(num)`.
- **Core-local**: each core has independent user IRQs; they cannot communicate between cores.
- Use the claim/unclaim helpers to avoid collisions between libraries:

```c
int irq_num = user_irq_claim_unused(true);   // claim a free user IRQ (panics if none)
irq_set_exclusive_handler(irq_num, my_sw_handler);
irq_set_enabled(irq_num, true);
irq_set_pending(irq_num);                    // trigger immediately

// When done:
irq_set_enabled(irq_num, false);
irq_remove_handler(irq_num, my_sw_handler);
user_irq_unclaim(irq_num);
```

---

## `irq_clear` usage

`irq_clear` only works for software IRQs (e.g. user IRQs) that are not connected to hardware. For hardware-connected IRQs, the NVIC reflects the current hardware state — to clear the interrupt, clear the **peripheral's own register** (e.g. the DMA interrupt status register, GPIO interrupt acknowledge register). Calling `irq_clear` on a hardware IRQ has no effect.

---

## Related pages

- [[pio-architecture]] — PIO IRQ flags and routing to NVIC via `pio_set_irq0_source_enabled`
- [[gpio-pinout]] — GPIO IRQ callbacks (`gpio_set_irq_enabled_with_callback`) install to `IO_IRQ_BANK0`
- [[dma-controller]] — DMA channel interrupts (`DMA_IRQ_0`, `DMA_IRQ_1`)
- [[dual-core-sio]] — `SIO_IRQ_PROC0/1` (RP2040) / `SIO_IRQ_FIFO` (RP2350) for inter-core FIFO interrupts
- [[6502-interrupt-patterns]] — **6502 CPU side**: IRQ/NMI vectors, ISR register save/restore, polling vs. vectored dispatch
