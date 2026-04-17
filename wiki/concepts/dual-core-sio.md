---
type: concept
tags: [rp6502, ria, rp2040, rp2350, multicore, sio, firmware]
related: [[rp6502-ria]], [[pio-architecture]], [[reset-model]], [[xram]]
sources: [[quadros-rp2040]], [[rp6502-github-repo]], [[fairhead-pico-c]], [[pico-c-sdk]]
created: 2026-04-16
updated: 2026-04-17
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

Core 1 starts with the same interrupt vector table and stack base as core 0 (overridable via `multicore_launch_core1_with_stack()`).

All launch variants require core 1 to be reset first via `multicore_reset_core1()`:

| Function | Description |
|---|---|
| `multicore_reset_core1()` | Reset core 1 into its initial state (ready for re-launch); call only from core 0 |
| `multicore_launch_core1(entry)` | Wake core 1, run `entry(void)` using default core 1 stack (below core 0 stack) |
| `multicore_launch_core1_with_stack(entry, stack_bottom, stack_size_bytes)` | Wake core 1 with a caller-supplied stack; `stack_size_bytes` must be a multiple of 4 |
| `multicore_launch_core1_raw(entry, sp, vector_table)` | Low-level launch with explicit stack pointer and vector table; no stack guard even if `USE_STACK_GUARDS` is defined |

---

## SIO (Single-cycle IO block)

The SIO lives at `0xD0000000` (the IOPORT address). Both cores have single-cycle access via their private IOPORT buses — no arbitration, no wait states, no contention.

| Component | Per-core? | Purpose |
|---|---|---|
| **CPUID** | Yes (0/1) | Identifies which core is executing |
| **Inter-processor FIFOs** | Shared | 2 × 8-word queues (RP2040) / 2 × 4-word queues (RP2350) for core-to-core messaging |
| **Hardware spinlocks ×32** | Shared | Atomic test-and-set flags for short critical sections |
| **Integer divider** | Yes | Hardware 32-bit divide per core |
| **Interpolators 0/1** | Yes | Linear interpolation hardware (graphics/DSP use) |
| **GPIO registers** | Shared | Atomic SET/CLR/XOR for race-free GPIO state changes |

### CPUID

`SIO->CPUID` returns 0 on core 0 and 1 on core 1. Lets shared code identify which core it is running on in a single read — no SDK calls needed.

### Inter-processor FIFOs

Two independent FIFOs in opposite directions:
- **FIFO 0→1**: core 0 writes, core 1 reads.
- **FIFO 1→0**: core 1 writes, core 0 reads.

Depth: **8 entries (32-bit) on RP2040; 4 entries on RP2350.**

Data availability triggers an interrupt on the *reading* core. The IRQ number depends on platform:

```c
// RP2040: SIO_IRQ_PROC0 (fires on core 0), SIO_IRQ_PROC1 (fires on core 1)
// RP2350: both cores share SIO_IRQ_PROC but with different SIO outputs routed per core
// Portable:
irq_num_t irq = SIO_FIFO_IRQ_NUM(get_core_num());
```

This enables zero-polling communication: the sending core pushes a word; the receiving core wakes via interrupt and processes it. See [[pio-architecture]] for how PIO IRQ flags combine with this mechanism in the RIA, and [[quadros-rp2040]] for the full NVIC IRQ table.

> **SDK caution**: The inter-core FIFOs are a *precious resource* — the SDK uses them during core 1 launch and for lockout functions; FreeRTOS SMP also requires exclusive FIFO access. Prefer passing data via a shared queue unless you have specific reasons to use the FIFOs directly.

**FIFO SDK functions (`pico_multicore`/fifo):**

| Function | Description |
|---|---|
| `multicore_fifo_push_blocking(data)` | Block until space; push `data` |
| `multicore_fifo_push_blocking_inline(data)` | Inline variant of above |
| `multicore_fifo_push_timeout_us(data, us)` | Block up to `us` µs; true if pushed |
| `multicore_fifo_pop_blocking()` | Block until data available; return it |
| `multicore_fifo_pop_blocking_inline()` | Inline variant of above |
| `multicore_fifo_pop_timeout_us(us, *out)` | Block up to `us` µs; true if data read |
| `multicore_fifo_rvalid()` | True if read FIFO has data available |
| `multicore_fifo_wready()` | True if write FIFO has space |
| `multicore_fifo_drain()` | Discard all data in read FIFO |
| `multicore_fifo_clear_irq()` | Clear ROE/WOF sticky interrupt flags (not VLD) |
| `multicore_fifo_get_status()` | Return status bitfield: bit0=RX not empty, bit1=TX not full, bit2=WOF sticky, bit3=ROE sticky |

### Doorbell interrupts (RP2350 only)

RP2350 adds a **doorbell** mechanism: named interrupt signals a core can raise on itself or the other core, without using the FIFOs. Each doorbell is just an IRQ trigger; no data is transferred.

| Function | Description |
|---|---|
| `multicore_doorbell_claim(num, core_mask)` | Cooperatively claim a doorbell number; panics if already claimed |
| `multicore_doorbell_claim_unused(core_mask, required)` | Claim an unused doorbell; returns -1 (or panics if `required`) if none free |
| `multicore_doorbell_unclaim(num, core_mask)` | Release claim on a doorbell |
| `multicore_doorbell_set_other_core(num)` | Activate doorbell IRQ on the *other* core |
| `multicore_doorbell_clear_other_core(num)` | Deactivate doorbell on the other core |
| `multicore_doorbell_set_current_core(num)` | Activate doorbell IRQ on *this* core |
| `multicore_doorbell_clear_current_core(num)` | Deactivate doorbell on this core |
| `multicore_doorbell_is_set_current_core(num)` | Check if doorbell is active on this core |
| `multicore_doorbell_is_set_other_core(num)` | Check if doorbell is active on the other core |

`DOORBELL_IRQ_NUM(doorbell_num)` — compile-time macro returning the `irq_num_t` for the doorbell's processor interrupt.

`core_mask` values: `0b01` = core 0 only, `0b10` = core 1 only, `0b11` = both cores.

### Lockout (pause the other core)

The lockout mechanism enables one core to force the other into a **known paused state** (tight RAM loop, interrupts disabled). Primary use case: writing to flash when no flash code may execute.

> **Important**: Lockout uses the inter-core FIFOs. The FIFOs cannot be used for any other purpose while lockout is active.

Setup: the *victim* core calls `multicore_lockout_victim_init()` to hook the FIFO IRQ. Either or both cores can do this.

| Function | Description |
|---|---|
| `multicore_lockout_victim_init()` | Hook the FIFO IRQ so this core can be locked out; FIFO unavailable for other use after this |
| `multicore_lockout_victim_deinit()` | Unhook FIFO IRQ; FIFO usable again for other purposes |
| `multicore_lockout_victim_is_initialized(core_num)` | Query whether `victim_init` was called on a given core (state persists across core reset — always reinit after reset) |
| `multicore_lockout_start_blocking()` | Interrupt the other core and wait until it is paused |
| `multicore_lockout_start_timeout_us(us)` | Same but with timeout; returns false if other core did not pause in time |
| `multicore_lockout_end_blocking()` | Release the other core from lockout |
| `multicore_lockout_end_timeout_us(us)` | Release with timeout; returns false if the lockout mutex could not be acquired |

Note: `lockout_start_*` functions are not nestable; must be paired with a corresponding `lockout_end_*`.

### Hardware spinlocks

32 one-bit flags, each at a distinct memory address. Protocol:
1. **Acquire**: write any value. If the next read returns non-zero, the lock is yours; if zero, retry.
2. **Release**: write any value to the same address.

Spinlocks are designed for very short critical sections — a few cycles. For anything longer, prefer `pico_sync` mutexes.

**Spinlock number assignments** (SDK defaults):

| Range | Constants | Ownership |
|---|---|---|
| 0–13 | `PICO_SPINLOCK_ID_*` (various) | Reserved for exclusive SDK/library use — do not claim directly |
| 14–15 | `PICO_SPINLOCK_ID_OS1`, `PICO_SPINLOCK_ID_OS2` | Reserved for OS-level software co-existing with the SDK |
| 16–23 | `PICO_SPINLOCK_ID_STRIPED_FIRST`–`PICO_SPINLOCK_ID_STRIPED_LAST` | Shared striped pool — allocated round-robin via `next_striped_spin_lock_num()` |
| 24–31 | `PICO_SPINLOCK_ID_CLAIM_FREE_FIRST`–`PICO_SPINLOCK_ID_CLAIM_FREE_LAST` | Exclusive-use pool — allocated first-come via `spin_lock_claim_unused()` |

> **RP2350-E2 erratum**: On RP2350 A2 silicon, writes to SIO registers at offset `+0x180` and above alias the spinlock registers, causing spurious lock releases. The SDK works around this by using atomic memory accesses for all `hardware_sync` spin lock operations by default.

**`hardware_sync` SDK API:**

| Function | Description |
|---|---|
| `spin_lock_init(lock_num)` | Initialise a spin lock; returns its instance pointer |
| `spin_lock_instance(lock_num)` | Get `spin_lock_t *` from lock number |
| `spin_lock_get_num(lock)` | Get lock number from `spin_lock_t *` |
| `spin_lock_blocking(lock)` | Acquire safely — disables IRQs; returns saved IRQ state for unlock |
| `spin_unlock(lock, saved_irq)` | Release safely — restores IRQ state |
| `spin_lock_unsafe_blocking(lock)` | Acquire without disabling IRQs (caller must ensure IRQ safety) |
| `spin_unlock_unsafe(lock)` | Release without re-enabling IRQs |
| `is_spin_locked(lock)` | Non-blocking check: true if currently acquired elsewhere |
| `spin_lock_claim(lock_num)` | Mark a lock as used; panics if already claimed |
| `spin_lock_claim_mask(mask)` | Mark multiple locks as used via bitmask |
| `spin_lock_unclaim(lock_num)` | Mark a lock as no longer used |
| `spin_lock_claim_unused(required)` | Allocate a free lock; panics if `required` and none free |
| `spin_lock_is_claimed(lock_num)` | Query whether a lock is claimed |
| `next_striped_spin_lock_num()` | Return next number from the striped range (16–23), round-robin |
| `spin_locks_reset()` | Release ALL spin locks (use only during reset/restart) |

Typical safe usage pattern:
```c
spin_lock_t *lock = spin_lock_init(spin_lock_claim_unused(true));

uint32_t save = spin_lock_blocking(lock);   // acquire + save IRQ state
// ... critical section ...
spin_unlock(lock, save);                     // release + restore IRQ state
```

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

### Memory barriers (`hardware_sync`)

ARM memory barrier instructions exposed as C inlines. Critical when ordering access to memory-mapped hardware registers or shared variables across cores.

| Function | ARM instruction | Effect |
|---|---|---|
| `__dmb()` | `DMB` | Data memory barrier — all prior memory accesses globally visible before any after |
| `__dsb()` | `DSB` | Data sync barrier — all prior explicit memory accesses **complete** before continuing |
| `__isb()` | `ISB` | Instruction sync barrier — flushes pipeline; instructions after ISB re-fetched from memory |
| `__mem_fence_acquire()` | `DMB` | Acquire fence — prevents later loads from appearing before this point |
| `__mem_fence_release()` | `DMB` | Release fence — prevents earlier stores from appearing after this point |

Use `__mem_fence_acquire()` / `__mem_fence_release()` as the preferred portable pair for cross-core data sharing (e.g. producer/consumer with a shared flag). Use `__dmb()`/`__dsb()` when directly manipulating hardware registers where ordering guarantees are needed.

### Processor event instructions (`hardware_sync`)

| Function | ARM instruction | Effect |
|---|---|---|
| `__sev()` | `SEV` | Send event — wakes both cores from WFE |
| `__wfe()` | `WFE` | Wait for event — idles the core until an event (SEV, interrupt, etc.) arrives |
| `__wfi()` | `WFI` | Wait for interrupt — idles the core until an interrupt fires |
| `__nop()` | `NOP` | No-op — one idle cycle; on RP2350 Arm binaries forced to 32-bit to avoid dual-issue |

`__wfe()` / `__sev()` together form an efficient cross-core notification primitive:
```c
// Core 1 — signal that data is ready
data_ready = true;
__sev();

// Core 0 — sleep until woken (does not spin)
while (!data_ready) __wfe();
```

### Interrupt control (`hardware_sync`)

| Function | Description |
|---|---|
| `save_and_disable_interrupts()` | Disables IRQs on calling core; returns prior PRIMASK for later restore |
| `restore_interrupts(status)` | Restores IRQ state to `status` returned by `save_and_disable_interrupts()` |
| `restore_interrupts_from_disabled(status)` | As above, but only valid when current state is **already disabled** (more efficient) |
| `disable_interrupts()` | Unconditionally disable IRQs (no state returned) |
| `enable_interrupts()` | Unconditionally enable IRQs |

`save_and_disable_interrupts()` + `restore_interrupts_from_disabled()` is the canonical pattern for short atomic sections in both task and IRQ context:
```c
uint32_t save = save_and_disable_interrupts();
// ... atomic region ...
restore_interrupts_from_disabled(save);
```

---

## pico_sync — Higher-level synchronization primitives

Built on top of spinlocks and interrupt masking. Choose by context:

| Primitive | When to use |
|---|---|
| `critical_section` | Interrupt-level mutual exclusion; disables interrupts on this core while held. Keep sections **very short**. |
| `mutex` | Task-level mutual exclusion for data structures. Not re-entrant. Do not call blocking mutex functions from IRQ handlers. |
| `recursive_mutex` | As mutex, but the same owner may acquire it multiple times (re-entrant). Higher overhead. |
| `semaphore` | Counting resource guard. Acquire in normal code; `sem_release()` is safe to call from IRQ handlers. |

### lock_core (internal)

All `pico_sync` primitives (except `critical_section`) embed a `lock_core_t` member that holds a spin lock protecting the primitive's internal state. The spin lock is always released before returning from any API call — it is **not** held across a block/wait. The `lock_internal_spin_unlock_with_wait/notify` macros implement the atomic "unlock + wait" and "unlock + notify" patterns needed for correct cross-core blocking; they default to `spin_unlock + __wfe()` / `spin_unlock + __sev()` but can be overridden for RTOS integration.

### critical_section API

```c
critical_section_t cs;
critical_section_init(&cs);                            // auto-assigns a spin lock number
critical_section_init_with_lock_num(&cs, lock_num);   // explicit spin lock number (needed when nesting)
critical_section_enter_blocking(&cs);                  // spin-wait for spin lock + disable local IRQs
critical_section_exit(&cs);                            // release spin lock + re-enable IRQs
critical_section_deinit(&cs);                          // free the associated spin lock (only for auto-init)
bool ok = critical_section_is_initialized(&cs);
```

> **Note**: `critical_section_init` uses a shared (striped) spin lock, so nested critical sections will deadlock. Use `critical_section_init_with_lock_num` with distinct lock numbers when nesting is required.

### mutex API

```c
mutex_t mtx;
mutex_init(&mtx);                                          // initialize
mutex_enter_blocking(&mtx);                               // blocks until ownership acquired (not re-entrant)
bool ok = mutex_try_enter(&mtx, &owner_out);              // non-blocking attempt; fills owner_out if already locked
bool ok = mutex_try_enter_block_until(&mtx, until);       // non-blocking if caller owns it, else waits until absolute_time_t
bool ok = mutex_enter_timeout_ms(&mtx, ms);               // block up to ms milliseconds
bool ok = mutex_enter_timeout_us(&mtx, us);               // block up to us microseconds
bool ok = mutex_enter_block_until(&mtx, until);           // block until absolute_time_t
mutex_exit(&mtx);                                         // release ownership
bool ok = mutex_is_initialized(&mtx);
```

**`auto_init_mutex(name)`** — places mutex in `.mutex_array` section; SDK runtime automatically calls `mutex_init()` before `main()`. Equivalent to a static mutex + manual init call.

### recursive_mutex API

All the same functions as mutex but prefixed `recursive_mutex_` and taking `recursive_mutex_t *`:

```c
recursive_mutex_t rmtx;
recursive_mutex_init(&rmtx);
recursive_mutex_enter_blocking(&rmtx);       // same owner can call multiple times without deadlock
recursive_mutex_try_enter(&rmtx, &owner_out);
recursive_mutex_enter_timeout_ms(&rmtx, ms);
recursive_mutex_enter_timeout_us(&rmtx, us);
recursive_mutex_enter_block_until(&rmtx, until);
recursive_mutex_exit(&rmtx);                 // each exit decrements the re-entry count
bool ok = recursive_mutex_is_initialized(&rmtx);
```

**`auto_init_recursive_mutex(name)`** — static definition with automatic initialization.

> **Important**: A regular `mutex_t` will deadlock if the same core tries to acquire it twice. Use `recursive_mutex_t` whenever re-entrancy is possible (e.g., if a callback might call back into code that already holds the lock).

### semaphore API

```c
semaphore_t sem;
sem_init(&sem, initial_permits, max_permits);  // initial_permits: available count; max_permits: cap
sem_acquire_blocking(&sem);                    // decrement count; blocks if count == 0
bool ok = sem_try_acquire(&sem);               // non-blocking; returns false if count == 0
bool ok = sem_acquire_timeout_ms(&sem, ms);    // block up to ms milliseconds
bool ok = sem_acquire_timeout_us(&sem, us);    // block up to us microseconds
bool ok = sem_acquire_block_until(&sem, until); // block until absolute_time_t
bool released = sem_release(&sem);             // increment count (capped at max_permits); safe from IRQ
sem_reset(&sem, permits);                      // reset count to specific value
int count = sem_available(&sem);               // query current available count
```

> Calling `sem_release()` beyond `max_permits` is silently capped — the count will not exceed the configured maximum.

---

## RIA firmware connections

| SIO feature | RIA usage |
|---|---|
| `multicore_launch_core1()` | Starts `api_task()` OS dispatcher on core 1 |
| Inter-processor FIFOs | Primary signaling path between PIO bus capture (core 0) and OS dispatcher (core 1) |
| `SIO_FIFO_IRQ_NUM(core)` | Portable IRQ number for FIFO interrupt on given core (RP2040: distinct per core; RP2350: shared `SIO_IRQ_PROC`) |
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
