---
type: concept
tags: [rp6502, ria, rp2040, rp2350, multicore, sio, firmware]
related: [[rp6502-ria]], [[pio-architecture]], [[reset-model]], [[xram]]
sources: [[quadros-rp2040]], [[rp6502-github-repo]], [[fairhead-pico-c]]
created: 2026-04-16
updated: 2026-04-16
---

# Dual-Core and SIO

**Summary**: How the RP2040/RP2350 runs two ARM Cortex-M0+ (M33 on RP2350) cores in parallel, and the SIO (Single-cycle IO block) that connects them — inter-processor FIFOs, hardware spinlocks, and atomic GPIO registers used by the RIA firmware.

---

## Why two cores?

The RIA firmware partitions its work across both ARM cores:
- **Core 0**: Runs USB, networking, and peripheral drivers; feeds the OS call FIFO from PIO bus captures.
- **Core 1**: Runs `api_task()` — the OS call dispatcher. Woken by PIO IRQ or inter-processor FIFO data; executes OS calls on behalf of the 65C02.

This split keeps deterministic bus timing (PIO + core 0) isolated from the potentially variable OS call handler (core 1), and takes advantage of the full 256 MHz budget across both cores.

---

## Core startup model

After chip reset, the SDK boots `main()` on **core 0**. Core 1 is held asleep.

```c
multicore_reset_core1();              // reset before launch (good practice)
multicore_launch_core1(entry_fn);     // wake core 1 and run entry_fn(void) on it
```

Core 1 starts with the same interrupt vector table and stack base as core 0 (overridable via `multicore_launch_core1_with_config()`).

---

## SIO (Single-cycle IO block)

The SIO lives at `0xD0000000` (the IOPORT address). Both cores have single-cycle access via their private IOPORT buses — no arbitration, no wait states, no contention.

| Component | Per-core? | Purpose |
|---|---|---|
| **CPUID** | Yes (0/1) | Identifies which core is executing |
| **Inter-processor FIFOs** | Shared | 2 × 8-word queues for core-to-core messaging |
| **Hardware spinlocks ×32** | Shared | Atomic test-and-set flags for short critical sections |
| **Integer divider** | Yes | Hardware 32-bit divide per core |
| **Interpolators 0/1** | Yes | Linear interpolation hardware (graphics/DSP use) |
| **GPIO registers** | Shared | Atomic SET/CLR/XOR for race-free GPIO state changes |

### CPUID

`SIO->CPUID` returns 0 on core 0 and 1 on core 1. Lets shared code identify which core it is running on in a single read — no SDK calls needed.

### Inter-processor FIFOs

Two independent 8-word (8 × 32-bit) FIFOs in opposite directions:
- **FIFO 0→1**: core 0 writes, core 1 reads.
- **FIFO 1→0**: core 1 writes, core 0 reads.

Data availability triggers an interrupt on the *reading* core:
- `SIO_IRQ_PROC0` (IRQ 15) — fires on core 0 when FIFO 1→0 has data
- `SIO_IRQ_PROC1` (IRQ 16) — fires on core 1 when FIFO 0→1 has data

This enables zero-polling communication: the sending core pushes a word; the receiving core wakes via interrupt and processes it. See [[pio-architecture]] for how PIO IRQ flags combine with this mechanism in the RIA, and [[quadros-rp2040]] for the full NVIC IRQ table.

SDK functions (`pico_multicore`):

| Function | Description |
|---|---|
| `multicore_reset_core1()` | Reset core 1 (required before re-launch) |
| `multicore_launch_core1(entry)` | Wake core 1 and run `entry(void)` |
| `multicore_fifo_drain()` | Discard all data in read FIFO |
| `multicore_fifo_pop_blocking()` | Block until data available; return it |
| `multicore_fifo_pop_timeout_us(us, *out)` | Block up to `us` µs; true if data read |
| `multicore_fifo_push_blocking(data)` | Block until space; push `data` |
| `multicore_fifo_push_timeout_us(data, us)` | Block up to `us` µs; true if pushed |

### Hardware spinlocks

32 one-bit flags, each at a distinct memory address. Protocol:
1. **Acquire**: write any value. If the next read returns non-zero, the lock is yours; if zero, retry.
2. **Release**: write any value to the same address.

Spinlocks are designed for very short critical sections — a few cycles. For anything longer, prefer `pico_sync` mutexes.

### SIO GPIO registers and speed

The SIO provides a fast path to GPIO that bypasses the general APB bus. The `sio_hw` struct (`hardware/structs/sio.h`) maps to `SIO_BASE` and provides named fields:

```c
sio_hw->gpio_set = 1ul << pin;   // set bit → GPIO high
sio_hw->gpio_clr = 1ul << pin;   // clear bit → GPIO low
sio_hw->gpio_in;                  // read all GPIO input states
```

Maximum toggle rate via `sio_hw` is approximately **50 MHz** (4 ns pulse width), versus ~6 ns using SDK `gpio_put()`. Both are fast enough for most uses; direct SIO access is preferred only when cycle accuracy matters.

**Pico vs Pico 2 SIO GPIO register offsets** (from `SIO_BASE`):

| Offset Pico 2 | Offset Pico | Name | Description |
|---|---|---|---|
| 0x004 | 0x004 | GPIO_IN | GPIO input value (read) |
| 0x010 | 0x010 | GPIO_OUT | GPIO output value |
| 0x018 | 0x014 | GPIO_OUT_SET | Set bits in GPIO_OUT |
| 0x020 | 0x018 | GPIO_OUT_CLR | Clear bits in GPIO_OUT |
| 0x028 | 0x01c | GPIO_OUT_XOR | XOR bits in GPIO_OUT |
| 0x030 | 0x020 | GPIO_OE | GPIO output enable |
| 0x038 | 0x024 | GPIO_OE_SET | Set bits in GPIO_OE |
| 0x040 | 0x028 | GPIO_OE_CLR | Clear bits in GPIO_OE |
| 0x048 | 0x02c | GPIO_OE_XOR | XOR bits in GPIO_OE |

The Pico 2 (RP2350) offsets differ from the Pico (RP2040). Use `sio_hw->gpio_set` etc. (struct fields resolve to the correct offset at compile time) rather than hardcoded offsets to write portable code.

### Atomic GPIO SET/CLR/XOR

A read-modify-write on a shared GPIO register can be interleaved by the other core or an interrupt handler, corrupting state. SIO exposes three address *aliases* for each register:
- **SET alias**: write a bitmask → those bits are set; others unchanged.
- **CLR alias**: write a bitmask → those bits are cleared; others unchanged.
- **XOR alias**: write a bitmask → those bits are toggled; others unchanged.

Each alias write is a single bus transaction — atomic by construction. The RIA uses this to safely assert/deassert `RESB` (GPIO 26) and `IRQB` (GPIO 22) from either core without needing a spinlock.

### GPIO Coprocessor (RP2350 / Pico 2 only)

The RP2350 adds a **GPIO coprocessor** accessible via ARM machine code instructions that write directly to SIO registers without a 32-bit address load. This reduces the overhead of single-pin GPIO operations. Access from C using GCC inline assembly:

```c
// Write 1-bit value to GPIO pin Rt at index Rt2
asm("mcrr p0, #4, %0, %1, c0" : : "r"(pin_number), "r"(pin_value));

// SDK macro equivalent:
pico_default_asm_volatile("mcrr p0, #4, %0, %1, c0" : : "r"(2), "r"(1));
```

In practice, performance is similar to `sio_hw->gpio_set` access — the coprocessor's value is in reduced instruction encoding, not raw speed. The RIA firmware currently uses the `sio_hw` struct approach.

---

## GPIO interrupt / event registers

*Relevant to RIA interrupt-driven bus sensing. Based on [[fairhead-pico-c]] Ch.17.*

Each GPIO line has four event bits, packed 8 lines per 32-bit register in `iobank0_hw->intr[n]`:

| Bit offset (per GPIO) | Name | Type | Description |
|---|---|---|---|
| 3 | GPIO_EDGE_HIGH | WC (write-to-clear) | A rising edge occurred |
| 2 | GPIO_EDGE_LOW | WC | A falling edge occurred |
| 1 | GPIO_LEVEL_HIGH | RO | Pin is currently high |
| 0 | GPIO_LEVEL_LOW | RO | Pin is currently low |

To read the events for GPIO `n`:
```c
uint32_t mask = 0xFu << (4 * (n % 8));
uint32_t events = (iobank0_hw->intr[n / 8] & mask) >> (4 * (n % 8));
```

To enable an interrupt for GPIO `n` on the current core:
```c
io_bank0_irq_ctrl_hw_t *irq_ctrl = get_core_num()
    ? &iobank0_hw->proc1_irq_ctrl
    : &iobank0_hw->proc0_irq_ctrl;
io_rw_32 *en_reg = &irq_ctrl->inte[n / 8];
hw_set_bits(en_reg, events_mask << (4 * (n % 8)));
```

Each core has its own `proc0_irq_ctrl` / `proc1_irq_ctrl` — interrupts must be enabled on the core that will handle them.

---

## pico_sync — higher-level synchronization

Built on top of spinlocks and interrupt masking:

| Primitive | When to use |
|---|---|
| `critical_section` | Interrupt-level mutual exclusion; disables interrupts on this core while held. Keep sections very short. |
| `mutex` / `recursive_mutex` | Task-level mutual exclusion for data structures. Blocks (spin-waits) if held by other core. |
| `semaphore` | Counting resource guard. Acquire in normal code; release can come from interrupt handlers. |

Key API:
```c
// Critical section
critical_section_init(&cs);
critical_section_enter_blocking(&cs);  // spin-wait + disable local interrupts
critical_section_exit(&cs);             // release + re-enable interrupts

// Mutex
mutex_init(&mtx);
mutex_enter_blocking(&mtx);            // blocks until ownership acquired
mutex_exit(&mtx);

// Semaphore
sem_init(&sem, initial_permits, max_permits);
sem_acquire_blocking(&sem);            // decrement; blocks if count == 0
sem_release(&sem);                     // increment
```

---

## RIA firmware connections

| SIO feature | RIA usage |
|---|---|
| `multicore_launch_core1()` | Starts `api_task()` OS dispatcher on core 1 |
| Inter-processor FIFOs | Primary signaling path between PIO bus capture (core 0) and OS dispatcher (core 1) |
| `SIO_IRQ_PROC0` / `SIO_IRQ_PROC1` | Interrupt wakeup for FIFO-based cross-core signaling |
| Atomic GPIO SET/CLR/XOR | Race-free `RESB` / `IRQB` control from either core |
| Hardware spinlocks | Short critical sections protecting shared OS call state |
| CPUID | Entry functions can identify which core they are running on |

> **RP2350 note**: The RIA runs on an RP2350 (Pi Pico 2), which uses Cortex-M33 cores rather than Cortex-M0+. The SIO block is architecturally identical; the inter-processor FIFOs, spinlocks, and atomic GPIO aliases work the same way.

---

---

## Race conditions and memory atomicity

*Based on [[fairhead-pico-c]] Ch.18.*

On the Pico, **32-bit memory accesses are atomic** — they cannot be interrupted mid-read or mid-write. This means a 32-bit shared variable accessed from both cores is safe from "tearing" (reading a mix of old and new bytes). However:

- **64-bit accesses are NOT atomic**: two separate 32-bit bus transactions, so concurrent reads can return a torn value (e.g. low word from before a write, high word from after).
- **Read-modify-write is NOT atomic** even for 32-bit values: `count++` involves read → increment → write. If both cores execute this sequence concurrently on the same variable, one increment is lost ("update loss").

Practical rules for the RIA:
- Shared 32-bit status flags between cores: safe if each has exclusive write authority. The `ria_action` FIFO is the preferred mechanism — avoid direct shared-variable communication.
- Use the SIO atomic SET/CLR/XOR aliases for GPIO — these are single-bus-transaction writes, inherently race-free.
- Prefer the inter-core FIFOs (`multicore_fifo_push_blocking`) for data passing; they are inherently thread-safe.

**Pico-specific atomicity facts**:
| Access | Atomic? | Notes |
|---|---|---|
| 32-bit load/store | Yes | Single bus transaction |
| 64-bit load/store | No | Two 32-bit transactions; can be torn |
| SIO SET/CLR/XOR writes | Yes | Single-transaction alias |
| Hardware spinlock acquire | Yes | Atomic test-and-set by design |

---

## FreeRTOS (SMP variant) — overview

*The RIA firmware does NOT use FreeRTOS — it uses raw SDK multicore. This section documents the FreeRTOS model as contrast, and because the RIA-W may need it for WiFi.*

The Raspberry Pi Foundation distributes an SMP (Symmetric Multi-Processing) port of FreeRTOS that runs across both Pico cores simultaneously.

**Key concepts**:
- Tasks are functions written as infinite loops: `void task(void *arg) { for(;;) { ... } }`
- `xTaskCreate(fn, name, stack_bytes, params, priority, &handle)` — create a task
- `vTaskStartScheduler()` — start FreeRTOS; never returns to caller
- Scheduler: priority-based preemptive, 1 ms tick. Equal-priority tasks share each core round-robin.
- Tasks can be pinned to a core via `vTaskCoreAffinitySet(handle, 1u << core_num)`.
- Standard system tasks: IDLE0/IDLE1 (priority 0, one per core), Timer Service (core 0).

**Why RIA doesn't use FreeRTOS**: Fairhead explicitly notes that for timing-critical work, a polling loop in a single task provides more predictable latency than a task-per-event architecture. FreeRTOS preemption adds up to 1 ms latency at every tick; PIO bus timing requires responses within a few hundred nanoseconds. The RIA's `api_task()` polling loop on core 1 reflects this design choice.

**WiFi + FreeRTOS (RP6502-RIA-W relevant)**:
- Replace `pico_cyw43_arch_lwip_threadsafe_background` with `pico_cyw43_arch_lwip_sys_freertos`
- Add `#define NO_SYS 0` to `lwipopts.h`; also add `TCPIP_THREAD_STACKSIZE 1024` and `TCPIP_MBOX_SIZE 8`
- `cyw43` high-level API (`cyw43.h`) is safe to call from FreeRTOS tasks but NOT from IRQ handlers
- lwIP RAW API is not thread-safe: bracket calls with `cyw43_arch_lwip_begin()` / `cyw43_arch_lwip_end()`

**FreeRTOS synchronization primitives** (contrast with `pico_sync`):

| Primitive | FreeRTOS API | pico_sync equivalent |
|---|---|---|
| Critical section (single-core) | `taskENTER_CRITICAL()` | `critical_section_enter_blocking()` |
| Mutex (cross-core) | `xSemaphoreCreateMutex()` | `mutex_enter_blocking()` |
| Counting semaphore | `xSemaphoreCreateCounting(max, init)` | `sem_init()` |
| Thread-safe queue | `xQueueCreate(n, size)` | — (no direct equivalent) |

**FreeRTOS `xQueue`** is the recommended alternative to shared variables for cross-task producer-consumer communication. It is internally race-safe; no additional lock needed. `xQueueSendToBack()` / `xQueueReceive()` block the calling task if the queue is full/empty, yielding the core to other tasks.

---

## Related pages

- [[pio-architecture]] · [[reset-model]] · [[rp6502-ria]] · [[xram]] · [[quadros-rp2040]] · [[fairhead-pico-c]] · [[rp6502-ria-w]]
