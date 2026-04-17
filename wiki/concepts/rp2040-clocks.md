---
type: concept
tags: [rp2040, rp2350, clocks, pll, xosc, rosc, lposc, hstx, timer, watchdog, rtc, rp6502-ria]
related: [[pio-architecture]], [[gpio-pinout]], [[rp6502-ria]], [[dma-controller]], [[dual-core-sio]], [[hstx]]
sources: [[quadros-rp2040]], [[pico-c-sdk]], [[rp2350-datasheet]]
created: 2026-04-16
updated: 2026-04-18
---

# RP2040 Clock Generation, Timer, Watchdog and RTC

**Summary**: The RP2040 has a flexible multi-source clock subsystem feeding ten clock domains; three peripherals built on top of it — a 64-bit microsecond Timer, a Watchdog, and a Real-Time Clock — are directly relevant to how the RIA firmware times OS calls, drives UART/SPI, and overclocks to 256 MHz.

---

## Clock Sources

| Source | Chip | Typical Frequency | Characteristics |
|---|---|---|---|
| **ROSC** (Ring Oscillator) | RP2040/RP2350 | ~11 MHz (RP2350 boot) | On-chip, no external component, little power. Imprecise: RP2040 guaranteed 1.8–12 MHz; **RP2350 guaranteed 4.6–19.6 MHz**. Used at boot. |
| **XOSC** (Crystal Oscillator) | RP2040/RP2350 | 12 MHz (reference design) | Requires external crystal. RP2040: 1–15 MHz range. **RP2350: 1–50 MHz range**. Stable and accurate; preferred for clk_ref. |
| **LPOSC** (Low Power Oscillator) | RP2350 only | ~32 kHz | On-chip ultra-low-power oscillator. Starts automatically in the **always-on power domain** even when switched-core is off. Provides AON Timer tick and clk_pow. Tunable to ~1% accuracy. Can optionally drive clk_ref + clk_sys for low-power CPU-on mode. |
| **External clocks** | RP2040/RP2350 | up to 50 MHz | GPIO20/GPIO22 (GPIN0/1). Can feed clk_ref or clk_sys aux mux. |
| **USB PLL** | RP2040/RP2350 | 48 MHz | Multiplies XOSC to generate the 48 MHz clock required for USB and ADC. |
| **System PLL** | RP2040/RP2350 | 125 MHz (default) | Multiplies XOSC to generate `clk_sys`. Can be overclocked — **the RIA firmware sets it to 256 MHz**. |

### PLL parameter model

The System (and USB) PLL is programmed with three values:

- **VCO freq** — the voltage-controlled oscillator target (must be in the valid VCO range, 750–1600 MHz).
- **post_div1** — first post-divider (1–7). Applied after the VCO.
- **post_div2** — second post-divider (1–7). Applied after post_div1. Must be ≤ post_div1.

Full formula: `FOUTPOSTDIV = (FREF / REFDIV) × FBDIV / (POSTDIV1 × POSTDIV2)`

PLL constraints:
- FREF / REFDIV ≥ 5 MHz (minimum reference into VCO)
- VCO (FOUTVCO) must be in 750–1600 MHz
- FBDIV (feedback divider) must be in 16–320
- POSTDIV1 and POSTDIV2 each in 1–7
- System PLL max output: **150 MHz** (RP2350); USB PLL: **48 MHz**

For example, 256 MHz = VCO 1536 MHz / (3 × 2). The SDK function `check_sys_clock_hz()` validates a target and returns the three PLL parameters if attainable. Use `vcocalc.py` (`pico-sdk/src/rp2_common/hardware_clocks/scripts/vcocalc.py`) for parameter search.

**Jitter vs power**: Higher VCO → lower jitter but more power. E.g., `1500 MHz / 6 / 2 = 125 MHz` (low jitter) vs `750 MHz / 6 / 1 = 125 MHz` (low power).

### PLL mechanics

Both PLLs are *Phase Locked Loops* that multiply the XOSC (or an external clock at XIN) to produce a faster output. The USB PLL targets 48 MHz; the System PLL targets `clk_sys`. Changing the System PLL frequency is how the RP2040/RP2350 is overclocked. See [PLL parameter model](#pll-parameter-model) above.

**RP2350 change**: Added interrupt on PLL loss-of-lock (`CS.LOCK_N`). Flexible PLL routing — e.g., USB clock can come from system PLL (144 MHz / 3 = 48 MHz), freeing USB PLL for [[hstx|HSTX]] or GPOUT.

### `hardware_pll` SDK functions

The `hardware_pll` library exposes low-level PLL control. Normally called indirectly via `clock_configure` (which wraps PLL setup), but available for direct use:

| Function | Description |
|---|---|
| `pll_init(pll, ref_div, vco_freq, post_div1, post_div2)` | Configure and start a PLL. `pll` is `pll_sys` or `pll_usb`. `ref_div` divides the reference clock into the VCO. |
| `pll_deinit(pll)` | Power off a PLL. **Does not check if PLL is in use** — call only when you know the PLL output is no longer needed. |
| `PLL_RESET_NUM(pll)` | Macro → returns the `reset_num_t` value for reset-controller integration. Resolves at compile time. |

The two SDK handles: `pll_sys` (system clock PLL, up to 133 MHz on RP2040, 150 MHz on RP2350) and `pll_usb` (USB reference clock PLL, 48 MHz fixed).

> **Caution**: `pll_deinit` powers off the PLL immediately. If any peripheral or clock domain still references it, the system will hang. The RIA firmware sets `pll_sys` to 256 MHz at boot via `clock_configure`; never call `pll_deinit(pll_sys)` while the 6502 is running.

---

## XOSC Details

- Disabled at chip startup; RP2350 boots from ROSC. Must be explicitly enabled via `CTRL_ENABLE`.
- Uses `STARTUP_DELAY` register to hold chip in reset until crystal is stable (`STATUS_STABLE` flag).
- Required crystal frequency ≥ 5 MHz for PLL use.
- RP2350 range: **1–50 MHz** (vs RP2040 1–15 MHz). Reference design: 12 MHz.
- **DORMANT mode**: Write special value to `DORMANT` register to stop XOSC for ultra-low-power sleep. On wakeup, XOSC restarts (>1 ms startup delay). Configure wake interrupt before entering DORMANT.
- SDK counter: `COUNT` register counts down at XOSC frequency — useful for software delays without depending on core clock.
- **Changes from RP2040**: Maximum crystal frequency extended from 15 MHz to 50 MHz.

## ROSC Details

- Ring oscillator, 8 stages, each with programmable drive strength (0–3 bits set per stage).
- Frequency range settings: LOW (8 stages), MEDIUM (6), HIGH (4), TOOHIGH (2 — do not use).
- A3 silicon: randomization enabled by default (`DS0_RANDOM` / `DS1_RANDOM` bits set), DIV halved to 2. Result: `clk_sys` guaranteed 18.4–96 MHz; `clk_ref` maintained at nominal 11 MHz with higher divisor. Improves glitch detector sensitivity to protect boot ROM.
- **ROSC as RNG**: When cores clock from XOSC, read `RANDOMBIT` register once per bit. Not cryptographically secure.
- **COUNT register**: Write a value; counts down to zero at ROSC frequency. Good for frequency-independent software delays.
- **Changes from RP2040**: Frequency randomisation feature added.

## LPOSC Details

- Nominal 32.768 kHz, RC oscillator, no external components. Base address: `POWMAN_BASE` (0x40100000).
- Starts automatically when core power supply is available and POR released. Stabilises in ~1 ms.
- Initial accuracy: ±20%. Can be trimmed to **±1.5%** using TRIM field (63 trim steps, each 1–3% of initial freq).
- Frequency drift: ±14% with temperature, ±20% with supply voltage.
- External 32.768 kHz input alternative: GPIO 12, 14, 20, or 22 (also supports 1 kHz or 1 Hz tick input).
- Used by: AON Timer tick, `clk_pow`, optional `clk_ref`/`clk_sys` for low-power CPU-on mode.

## Tick Generators

- Base address: `TICKS_BASE` = `0x40108000`.
- Use `clk_ref` as reference; divide it to produce 1 µs tick for timers.
- For 12 MHz `clk_ref`: set cycle count to **12** → 1 µs tick.
- Destinations: TIMER0, TIMER1 (system timers), RISC-V platform timer, Cortex-M33 SysTick (core 0 + 1), Watchdog.
- Each destination has independent cycle-count setting. Stop tick generator (`TIMER0_CTRL.ENABLE = 0`) before changing cycle count.

---

## Clock Domains

### RP2040 clock numbers

Ten clock generators each select one of the sources (via muxes) and apply a divisor:

| Subsystem | Clock signal | Usual source |
|---|---|---|
| Processor cores, Bus fabric, Memories | `clk_sys` | System PLL |
| I²C | `clk_sys` | System PLL |
| SPI, UART | `clk_peri` | System PLL or XOSC |
| USB | `clk_usb` | USB PLL |
| ADC | `clk_adc` | USB PLL |
| RTC | `clk_rtc` | XOSC |
| Timer, Watchdog | `clk_ref` | XOSC |
| GPIO clock output | `clk_gpout0`–`clk_gpout3` | Any source + divisor |

**RP2040 enum**: `clk_gpout0–3`, `clk_ref`, `clk_sys`, `clk_peri`, `clk_usb`, `clk_adc`, `clk_rtc` (10 total, `CLK_COUNT = 10`).

### RP2350 clock numbers (differences from RP2040)

| Change | Detail |
|---|---|
| **`clk_rtc` removed** | RP2350 has no hardware RTC peripheral; use POWMAN for time-keeping instead. |
| **`clk_hstx` added** | New HSTX (High-Speed Transmit) peripheral clock, nominal 150 MHz. |
| **`clk_ref` can use LPOSC** | RP2350 adds `CLOCKS_CLK_REF_CTRL_SRC_VALUE_LPOSC_CLKSRC` as a main source. |
| **Clock divisor range** | RP2350 supports 1.0→65536.0 in steps of 1/65536 (16-bit fraction). RP2040 supports exactly 1.0 or 2.0→16777216.0 in steps of 1/256 (8-bit fraction). |
| **A3 silicon reset change** | RP2350 A3 changed CLK_SYS_CTRL.SRC default from 0→1 (select AUX) and CLK_SYS_CTRL.AUXSRC from 0→2 (ROSC as AUX source). Boot ROM changed accordingly. A2 hardware required explicit clock setup from ROSC before any PLL config; A3+ hardware starts with clk_sys already running from ROSC via AUX. |

**RP2350 clock generator nominal frequencies** (from datasheet Table 541):

| Clock | Nominal Freq | Notes |
|---|---|---|
| `clk_ref` | 6–12 MHz | Always running (not in DORMANT); ROSC at boot |
| `clk_sys` | 150 MHz | Always running; switched to PLL after boot |
| `clk_peri` | 12–150 MHz | UART, SPI peripheral clock |
| `clk_hstx` | 150 MHz | HSTX peripheral — RP2350 only |
| `clk_usb` | 48 MHz | Must be exactly 48 MHz |
| `clk_adc` | 48 MHz | Must be exactly 48 MHz |

**RP2350 enum**: `clk_gpout0–3`, `clk_ref`, `clk_sys`, `clk_peri`, `clk_hstx`, `clk_usb`, `clk_adc` (10 total, no `clk_rtc`).

**RIA-relevant**: `clk_sys` runs at **256 MHz** (see [[pio-architecture]] — overclock required for PIO to handle 8 MHz PHI2). `clk_peri` drives the UART console (GPIO 4–5, 115200 8N1) and the SPI peripheral. `clk_ref` from XOSC provides the precise timebase for the timer and watchdog.

---

## Mux Architecture

Each clock generator uses one or two *multiplexers* to select its source:

- **Aux mux** (all generators): glitchy when the source changes — for an instant the output is neither the old nor the new signal. For generators that can be stopped, disable the clock first, change source, re-enable.
- **Glitchless mux** (`clk_sys` and `clk_ref` only): a second mux after the aux mux. These clocks cannot be stopped, so the glitchless mux allows safe source switching by first moving to `clk_ref` (via glitchless mux), changing the aux mux source, then switching back via glitchless mux.

The SDK `clock_configure()` handles this sequence automatically.

---

## Clock Output on GPIO

Up to four clock signals can be routed to GPIO pins:
- **RP2040**: GPIO 21, 23, 24, 25 (connected to GPOUT0–3). On Raspberry Pi Pico only GPIO 21 is on a connector pin.
- **RP2350**: GPIO 13, 15, 21, 23, 24, 25 (GPOUT0 on 13/21; GPOUT1 on 15/23; GPOUT2/3 on 24/25).

Useful for testing or providing a clock to an external device. Use `clock_gpio_init()` or `clock_gpio_init_int_frac16()` (RP2350, 16-bit fraction) / `clock_gpio_init_int_frac8()` (RP2040, 8-bit fraction) for precise divisors.

---

## Frequency Counter

A hardware frequency counter measures a clock source by counting edges over a test interval defined in `clk_ref` cycles. 16 interval options from 1 µs (±2048 kHz accuracy) to 32 ms (±62.5 Hz accuracy). SDK function: `frequency_count_khz(src)`.

---

## Clock SDK (`hardware_clocks`)

| Function | Description |
|---|---|
| `clocks_init()` | Initialize the library (call first) |
| `clock_configure(clk, src, auxsrc, src_freq, freq)` | Configure a clock; handles mux sequencing; sets divisor automatically |
| `clock_configure_undivided(clk, src, auxsrc, src_freq)` | Configure clock at full src_freq (no division) |
| `clock_configure_int_divider(clk, src, auxsrc, src_freq, divider)` | Configure clock with integer-only divisor |
| `clock_configure_gpin(clk, gpio, src_freq, freq)` | Use GPIO 20 or 22 as external clock source |
| `clock_stop(clk)` | Stop a clock (power saving) |
| `clock_get_hz(clk)` | Return current frequency in Hz |
| `clock_set_reported_hz(clk, hz)` | Override reported frequency (when changed outside `clock_configure`) |
| `frequency_count_khz(src)` | Measure a source using the hardware frequency counter; ±1 kHz accuracy |
| `clock_gpio_init(gpio, src, div)` | Route a clock to a GPOUT GPIO (float divisor) |
| `clock_gpio_init_int_frac16(gpio, src, div_int, div_frac16)` | Route a clock to GPOUT GPIO (16-bit fraction; RP2350 native) |
| `clock_gpio_init_int_frac8(gpio, src, div_int, div_frac8)` | Route a clock to GPOUT GPIO (8-bit fraction; RP2040 wrapper) |
| `set_sys_clock_48mhz()` | Set clk_sys to 48 MHz from USB PLL (simple, no math required) |
| `set_sys_clock_pll(vco_freq, post_div1, post_div2)` | Set System PLL directly; caller computes VCO + dividers |
| `set_sys_clock_hz(freq_hz, required)` | Set clk_sys to target Hz; returns false (or panics if required=true) if unattainable |
| `set_sys_clock_khz(freq_khz, required)` | Set clk_sys to target kHz |
| `check_sys_clock_hz(freq_hz, &vco, &d1, &d2)` | Validate target; outputs PLL params if attainable |
| `check_sys_clock_khz(freq_khz, &vco, &d1, &d2)` | Validate target in kHz |
| `clocks_enable_resus(callback)` | Enable resus: auto-restarts clk_sys if it accidentally stops |
| `gpio_to_gpout_clock_handle(gpio, default)` | Return GPOUT clock handle for a GPIO, or default |

`clock_handle_t` / `clock_num_t` values: `clk_gpout0`–`clk_gpout3`, `clk_ref`, `clk_sys`, `clk_peri`, `clk_usb`, `clk_adc`, `clk_rtc` (RP2040 only), `clk_hstx` (RP2350 only).

### Resus (clock restart)

`clocks_enable_resus(callback)` watches `clk_sys`. If clk_sys falls below a minimum threshold or stalls (e.g., the feeding PLL is stopped by accident), the hardware automatically switches clk_sys back to `clk_ref` and invokes the user callback. This prevents a hard lock-up when experimenting with PLL configuration.

---

## Timer

The Timer peripheral provides a **64-bit monotonic microsecond counter** and four alarms.

- **RP2040**: one timer instance. Timebase derived from the Watchdog `clk_tick` (`clk_ref` / XOSC).
- **RP2350**: two independent timer instances (TIMER0 and TIMER1). Timebase generated by the tick block (`clk_ref`).

### Counter

- Counts microseconds since boot (monotonic — never wraps in practice: 2⁶⁴ µs ≈ 600,000 years).
- Read protocol: read the low 32 bits first; the hardware latches the high 32 bits at that moment, so the subsequent high-word read is coherent.

### Alarms

- 4 alarms per timer instance (alarm 0–3), each generating its own IRQ.
- Match on the **lower 32 bits** of the counter — fires when the counter's lower bits equal the alarm value.
- Since 2³² µs ≈ 72 minutes, alarms are suitable for delays of tens of microseconds to about one hour.
- Delays shorter than ~10 µs have significant imprecision; use PIO for sub-microsecond timing.

### Callback type

```c
typedef void (*hardware_alarm_callback_t)(uint alarm_num);
```

Invoked from the timer's IRQ handler when the alarm fires. The callback receives the alarm number.

### Low-level SDK (`hardware_timer`) — default-timer wrappers

These functions operate on `PICO_DEFAULT_TIMER_INSTANCE` (TIMER0 on RP2350, the single timer on RP2040).

| Function | Description |
|---|---|
| `time_us_32()` | Lower 32 bits of default timer counter |
| `time_us_64()` | Full 64-bit counter of default timer |
| `busy_wait_us_32(delay)` / `busy_wait_us(delay)` | Spin-wait for N microseconds |
| `busy_wait_ms(delay)` | Spin-wait for N milliseconds |
| `busy_wait_until(t)` | Spin-wait until absolute timestamp |
| `time_reached(t)` | Non-blocking: is counter ≥ t? |
| `hardware_alarm_claim(num)` | Claim exclusive use of alarm `num` on default timer |
| `hardware_alarm_claim_unused(required)` | Claim any unclaimed alarm; panics if none and `required=true` |
| `hardware_alarm_unclaim(num)` | Release claim on alarm `num` |
| `hardware_alarm_is_claimed(num)` | Returns true if alarm `num` is currently claimed |
| `hardware_alarm_set_callback(num, cb)` | Set IRQ callback + enable interrupt |
| `hardware_alarm_set_target(num, t)` | Arm alarm; returns `true` if `t` is already in the past |
| `hardware_alarm_cancel(num)` | Cancel a pending alarm |
| `hardware_alarm_force_irq(num)` | Immediately fire the alarm IRQ (testing/software-trigger) |
| `hardware_alarm_get_irq_num(num)` | Returns `irq_num_t` for alarm `num` on default timer |

### Compile-time macros (`hardware_timer`)

| Macro | Description |
|---|---|
| `TIMER_ALARM_IRQ_NUM(timer, alarm_num)` | Returns `irq_num_t` for a given alarm on a given timer instance |
| `TIMER_ALARM_NUM_FROM_IRQ(irq)` | Extracts alarm number from an IRQ number |
| `TIMER_NUM_FROM_IRQ(irq)` | Extracts timer instance number from an IRQ number |
| `PICO_DEFAULT_TIMER` | Index of the default timer (0 on both RP2040 and RP2350) |
| `PICO_DEFAULT_TIMER_INSTANCE` | `timer_hw_t *` pointer to the default timer registers |

### RP2350 multi-instance API (`timer_*` variants)

On RP2350, all functions exist in a `timer_*` form that takes an explicit `timer_hw_t *timer` parameter. The default-timer wrappers above call these with `PICO_DEFAULT_TIMER_INSTANCE`.

| Function | Description |
|---|---|
| `timer_time_us_32(timer)` | Lower 32 bits of given timer |
| `timer_time_us_64(timer)` | Full 64-bit counter of given timer |
| `timer_busy_wait_us_32(timer, delay)` | Spin-wait on given timer |
| `timer_busy_wait_us(timer, delay)` | Spin-wait (64-bit delay) on given timer |
| `timer_busy_wait_ms(timer, delay)` | Spin-wait ms on given timer |
| `timer_busy_wait_until(timer, t)` | Spin-wait until timestamp on given timer |
| `timer_time_reached(timer, t)` | Non-blocking: is given timer counter ≥ t? |
| `timer_hardware_alarm_claim(timer, num)` | Claim alarm `num` on given timer |
| `timer_hardware_alarm_claim_unused(timer, required)` | Claim any unclaimed alarm on given timer |
| `timer_hardware_alarm_unclaim(timer, num)` | Release alarm `num` on given timer |
| `timer_hardware_alarm_is_claimed(timer, num)` | True if alarm `num` claimed on given timer |
| `timer_hardware_alarm_set_callback(timer, num, cb)` | Set callback for alarm on given timer |
| `timer_hardware_alarm_set_target(timer, num, t)` | Arm alarm on given timer; returns true if past |
| `timer_hardware_alarm_cancel(timer, num)` | Cancel alarm on given timer |
| `timer_hardware_alarm_force_irq(timer, num)` | Force IRQ for alarm on given timer |
| `timer_hardware_alarm_get_irq_num(timer, num)` | Get IRQ number for alarm on given timer |
| `timer_get_index(timer)` | Returns the timer instance number (0 or 1) |
| `timer_get_instance(num)` | Returns `timer_hw_t *` for timer instance number |

### High-level SDK (`pico_time` library)

> **Important**: Do not modify the hardware timer directly when using `pico_time`. The library expects the timer to increase monotonically at 1 µs per tick. Shift time by adding/subtracting constants instead of touching the counter.

`pico_time` is split into four sub-modules:

#### absolute_time_t and timestamp API

`absolute_time_t` is an opaque type representing an instant in time (µs since boot). In SDK 2.0+ it defaults to a plain `uint64_t`; set `PICO_OPAQUE_ABSOLUTE_TIME_T=1` to enable type-checked wrapping.

**Sentinel values:**
- `at_the_end_of_time` — set to `0x7fffffff_ffffffff` µs (~300,000 years); used as "never fire" marker. **Note**: not the maximum uint64_t — avoids overflow in signed arithmetic.
- `nil_time` — the null timestamp (0).

| Function | Description |
|---|---|
| `get_absolute_time()` | Return current time as `absolute_time_t` |
| `to_us_since_boot(t)` | Convert `absolute_time_t` → `uint64_t` µs |
| `to_ms_since_boot(t)` | Convert `absolute_time_t` → `uint32_t` ms |
| `from_us_since_boot(us)` | Convert `uint64_t` µs → `absolute_time_t` |
| `update_us_since_boot(&t, us)` | Update an existing `absolute_time_t` in place |
| `delayed_by_us(t, us)` | Return `t + us` as a new timestamp |
| `delayed_by_ms(t, ms)` | Return `t + ms` as a new timestamp |
| `make_timeout_time_us(us)` | `get_absolute_time() + us` (convenience) |
| `make_timeout_time_ms(ms)` | `get_absolute_time() + ms` (convenience) |
| `absolute_time_diff_us(from, to)` | Signed difference in µs (positive if `to` is later); be careful diffing against `at_the_end_of_time` — may overflow |
| `absolute_time_min(a, b)` | Return the earlier of two timestamps |
| `is_at_the_end_of_time(t)` | True if `t == at_the_end_of_time` |
| `is_nil_time(t)` | True if `t == nil_time` |

#### sleep API

Low-power sleep using `__wfe()`. Requires the **default alarm pool** (if disabled, falls back to busy-wait).

> **Note**: Do NOT call sleep functions from an IRQ handler.

| Function | Description |
|---|---|
| `sleep_us(us)` | Sleep at least `us` µs (WFE-based if alarm pool available) |
| `sleep_ms(ms)` | Sleep at least `ms` ms |
| `sleep_until(t)` | Sleep until `absolute_time_t` |
| `best_effort_wfe_or_timeout(t)` | Do a `__wfe()` if possible; returns true when `t` is reached. Use in a polling loop: `do { check(); } while (!best_effort_wfe_or_timeout(timeout));` |

`busy_wait_us()`, `busy_wait_us_32()`, `busy_wait_ms()`, `busy_wait_until()` are the non-sleep equivalents (spin-wait; no alarm pool needed; returns slightly sooner after target).

#### alarm API

Alarm pools multiplex many software alarms onto a single hardware alarm. The **default pool** is created on core 0 using hardware alarm 3, with up to 16 concurrent alarms.

**Default pool compile-time config macros:**

| Macro | Default | Description |
|---|---|---|
| `PICO_TIME_DEFAULT_ALARM_POOL_DISABLED` | 0 | Set to 1 to disable the default pool (sleep becomes busy-wait; some SDK code won't compile) |
| `PICO_TIME_DEFAULT_ALARM_POOL_HARDWARE_ALARM_NUM` | 3 | Which hardware alarm backs the default pool |
| `PICO_TIME_DEFAULT_ALARM_POOL_MAX_TIMERS` | 16 | Max concurrent alarms (hard limit: 255 due to heap) |

**Callback type and return semantics:**

```c
typedef int64_t (*alarm_callback_t)(alarm_id_t id, void *user_data);
// Return  <0: reschedule |return_value| µs from the previous scheduled fire time
// Return  >0: reschedule return_value µs from the time this callback returns
// Return   0: do not reschedule
```

**alarm_id_t**: `int32_t` — positive = valid alarm; 0 = time already passed (and `fire_if_past=false`); negative = error (no slots available). IDs may eventually be reused — do not hold stale IDs for long.

**Pool management:**

| Function | Description |
|---|---|
| `alarm_pool_init_default()` | Create the default pool (if not already created or disabled) |
| `alarm_pool_get_default()` | Return the default pool pointer |
| `alarm_pool_create(hw_alarm_num, max_timers)` | Create a custom pool on a specific hardware alarm; callbacks fire on the calling core |
| `alarm_pool_create_with_unused_hardware_alarm(max_timers)` | Create pool claiming any free hardware alarm |
| `alarm_pool_timer_alarm_num(pool)` | Query which hardware alarm a pool uses |
| `alarm_pool_core_num(pool)` | Query which core the pool fires callbacks on |
| `alarm_pool_destroy(pool)` | Cancel all alarms and free the hardware alarm |

**Adding/cancelling alarms (pool variants):**

| Function | Description |
|---|---|
| `alarm_pool_add_alarm_at(pool, time, cb, data, fire_if_past)` | Fire at `absolute_time_t`; if time is past and `fire_if_past=true`, calls `cb` immediately |
| `alarm_pool_add_alarm_at_force_in_context(pool, time, cb, data)` | Guarantees `cb` is called from the pool's IRQ context even if time is already past (no `fire_if_past` parameter needed) |
| `alarm_pool_add_alarm_in_us(pool, us, cb, data, fire_if_past)` | Fire after `us` µs |
| `alarm_pool_add_alarm_in_ms(pool, ms, cb, data, fire_if_past)` | Fire after `ms` ms |
| `alarm_pool_cancel_alarm(pool, alarm_id)` | Cancel; returns true if found and cancelled |
| `alarm_pool_remaining_alarm_time_us(pool, id)` | µs until next fire (≥0); <0 if alarm gone/expired |
| `alarm_pool_remaining_alarm_time_ms(pool, id)` | ms until next fire; INT32_MAX if >INT32_MAX ms |

**Default pool convenience wrappers** (same semantics; use `alarm_pool_get_default()` internally):

| Function | Description |
|---|---|
| `add_alarm_at(time, cb, data, fire_if_past)` | |
| `add_alarm_in_us(us, cb, data, fire_if_past)` | |
| `add_alarm_in_ms(ms, cb, data, fire_if_past)` | |
| `cancel_alarm(alarm_id)` | |
| `remaining_alarm_time_us(alarm_id)` | |
| `remaining_alarm_time_ms(alarm_id)` | |

#### repeating_timer API

Periodic callbacks backed by the alarm pool. Unlike raw alarm rescheduling, `repeating_timer_t` stores the delay so the framework handles rescheduling automatically.

**Callback type:**
```c
typedef bool (*repeating_timer_callback_t)(repeating_timer_t *rt);
// Return true to continue repeating; false to stop.
```

**Delay sign convention** — same for both `_us` and `_ms` variants:
- **Positive delay**: interval is measured from when the callback **returns** (gap between callbacks).
- **Negative delay**: interval is measured from when the callback was **scheduled to fire** (fixed-rate, jitter-free). The absolute value is used as the period.

| Function | Description |
|---|---|
| `add_repeating_timer_us(delay_us, cb, data, out)` | Default pool; fires every `|delay_us|` µs |
| `add_repeating_timer_ms(delay_ms, cb, data, out)` | Default pool; fires every `|delay_ms|` ms |
| `alarm_pool_add_repeating_timer_us(pool, delay_us, cb, data, out)` | Specific pool |
| `alarm_pool_add_repeating_timer_ms(pool, delay_ms, cb, data, out)` | Specific pool |
| `cancel_repeating_timer(timer)` | Stop the repeating timer |

> **Caution**: The `repeating_timer_t` struct (pointed to by `out`) must outlive the repeating timer. Avoid storing it on the stack if the timer should survive the function that created it.

---

## Watchdog

The Watchdog resets the RP2040 if software fails to pet it within the configured timeout.

### How it works

- 24-bit counter driven by `clk_tick` (1 µs tick from `clk_ref`).
- **Hardware bug**: the counter is decremented **twice** per tick. SDK compensates internally.
- Maximum timeout: 8388 ms (24-bit counter / 2 decrements per µs).
- When the counter reaches zero, the chip is reset.
- Software must call `watchdog_update()` periodically to reload the counter before it expires.
- **No `watchdog_disable()` in the SDK** — once enabled, cannot be disabled in software.

### Scratch registers

The Watchdog has **8 × 32-bit scratch registers** (`SCRATCH0`–`SCRATCH7`). They are cleared on power-up or external reset, but **preserved through a watchdog-triggered reset**. The Bootrom uses these to distinguish a watchdog reset from a normal boot and to pass parameters to the second-stage bootloader.

### SDK (`hardware_watchdog`)

| Function | Description |
|---|---|
| `watchdog_enable(delay_ms, pause_on_debug)` | Enable watchdog; `pause_on_debug=true` disables it while debugger steps |
| `watchdog_update()` | Re-trigger (reload counter) |
| `watchdog_caused_reboot()` | Returns true if last boot was a watchdog reset |
| `watchdog_get_count()` | Microseconds remaining before reset |

---

## RTC (Real Time Clock)

The RTC maintains date and time while the RP2040 is powered, using `clk_rtc` from XOSC (~46875 Hz nominal).

### Fields updated every second

| Field | Range |
|---|---|
| Year | 0–4095 |
| Month | 1–12 |
| Day | 1–28/29/30/31 |
| Day of Week | 0 (Sun)–6 (Sat) |
| Hour | 0–23 |
| Minute | 0–59 |
| Seconds | 0–59 |

The day-of-week increments independently — there is no hardware check that it matches the calendar date. The RTC implements simplified leap years: years divisible by 4 are leap years (February 29 follows February 28). The full Gregorian rule (×100/×400 exception) is **not** implemented; software must handle this if needed.

The RTC does not have a battery — it only runs while the RP2040 is powered (or in SLEEP/DORMANT with external battery and `clk_rtc` kept alive). Firmware is responsible for loading a valid initial date/time.

### Alarm

The RTC alarm can match any combination of the seven fields. A field set to `-1` in the `datetime_t` struct is excluded from the match, making the alarm repeating on the remaining fields. If *any* field is `-1`, the alarm automatically re-arms after firing; call `rtc_disable_alarm()` in the callback to make it one-shot.

### SDK (`hardware_rtc`)

| Function | Description |
|---|---|
| `rtc_init()` | Initialize RTC and set up its clock |
| `rtc_set_datetime(dt)` | Load date/time; returns false if invalid |
| `rtc_get_datetime(dt)` | Read current date/time; false if RTC not running |
| `rtc_running()` | True if RTC is running |
| `rtc_set_alarm(dt, callback)` | Set alarm; fields = -1 → don't care (repeating) |
| `rtc_enable_alarm()` / `rtc_disable_alarm()` | Enable / disable the alarm |

IRQ: `RTC_IRQ` (IRQ 25).

---

## RIA Firmware Connections

| Clock/peripheral | RIA usage |
|---|---|
| **System PLL → 256 MHz** | `clk_sys` overclocked; required for PIO state machines to handle 8 MHz PHI2. See [[pio-architecture]]. |
| **`clk_peri`** | Drives UART console (GPIO 4–5, 115200 8N1) and SPI peripheral (SD card). |
| **`clk_ref` / Timer** | Provides the precise microsecond timebase for OS call timing and `sleep_ms()` / `sleep_us()` in the task loop. |
| **TIMER_IRQ_0–3** (IRQ 0–3) | Available for alarm-based scheduling within the RIA OS task dispatcher. |
| **Watchdog** | Confirmed in RIA firmware: `RIA_WATCHDOG_MS=250` action watchdog in `ria.c`; `watchdog_reboot()` in `sys.c` for fault recovery; VGA firmware also uses watchdog timers. |
| **XOSC 12 MHz** | Feeds `clk_ref` (timer/watchdog timebase) and `clk_rtc`; stable even when System PLL is overclocked. |

---

## Related pages

- [[pio-architecture]]
- [[rp6502-ria]]
- [[gpio-pinout]]
- [[dual-core-sio]]
- [[dma-controller]]
- [[usb-controller]]
- [[quadros-rp2040]]
