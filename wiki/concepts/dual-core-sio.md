---
type: concept
tags: [rp6502, ria, rp2040, rp2350, multicore, sio, firmware]
related: [[rp6502-ria]], [[pio-architecture]], [[reset-model]], [[xram]]
sources: [[quadros-rp2040]], [[rp6502-github-repo]]
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

This enables zero-polling communication: the sending core pushes a word; the receiving core wakes via interrupt and processes it. See [[pio-architecture]] for how PIO IRQ flags combine with this mechanism in the RIA, and [[reset-model]] for the full NVIC IRQ table.

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

### Atomic GPIO SET/CLR/XOR

A read-modify-write on a shared GPIO register can be interleaved by the other core or an interrupt handler, corrupting state. SIO exposes three address *aliases* for each register:
- **SET alias**: write a bitmask → those bits are set; others unchanged.
- **CLR alias**: write a bitmask → those bits are cleared; others unchanged.
- **XOR alias**: write a bitmask → those bits are toggled; others unchanged.

Each alias write is a single bus transaction — atomic by construction. The RIA uses this to safely assert/deassert `RESB` (GPIO 26) and `IRQB` (GPIO 22) from either core without needing a spinlock.

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

## Related pages

- [[pio-architecture]] · [[reset-model]] · [[rp6502-ria]] · [[xram]] · [[quadros-rp2040]]
