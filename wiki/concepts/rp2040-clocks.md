---
type: concept
tags: [rp2040, rp2350, clocks, pll, xosc, rosc, timer, watchdog, rtc, rp6502-ria]
related: [[pio-architecture]], [[gpio-pinout]], [[rp6502-ria]], [[dma-controller]], [[dual-core-sio]]
sources: [[quadros-rp2040]]
created: 2026-04-16
updated: 2026-04-16
---

# RP2040 Clock Generation, Timer, Watchdog and RTC

**Summary**: The RP2040 has a flexible multi-source clock subsystem feeding ten clock domains; three peripherals built on top of it — a 64-bit microsecond Timer, a Watchdog, and a Real-Time Clock — are directly relevant to how the RIA firmware times OS calls, drives UART/SPI, and overclocks to 256 MHz.

---

## Clock Sources

| Source | Typical Frequency | Characteristics |
|---|---|---|
| **ROSC** (Ring Oscillator) | ~6 MHz (typical) | On-chip, no external component, little power. Imprecise: guaranteed range 1.8–12 MHz. Used at boot. |
| **XOSC** (Crystal Oscillator) | 12 MHz (reference design) | Requires external crystal (1–15 MHz range). Stable and accurate; preferred for clk_ref and clk_rtc. |
| **External clocks** | up to 50 MHz | GPIO0, GPIO1, or XIN pins. Can feed the PLLs. |
| **USB PLL** | 48 MHz | Multiplies XOSC to generate the 48 MHz clock required for USB and ADC. |
| **System PLL** | 125 MHz (default) | Multiplies XOSC to generate `clk_sys`. Can be overclocked — **the RIA firmware sets it to 256 MHz**. |

### PLL mechanics

Both PLLs are *Phase Locked Loops* that multiply the XOSC (or an external clock at XIN) to produce a faster output. The USB PLL targets 48 MHz; the System PLL targets `clk_sys`. Changing the System PLL frequency is how the RP2040/RP2350 is overclocked.

---

## Clock Domains

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

**RIA-relevant**: `clk_sys` runs at **256 MHz** (see [[pio-architecture]] — overclock required for PIO to handle 8 MHz PHI2). `clk_peri` drives the UART console (GPIO 4–5, 115200 8N1) and SPI (SD card). `clk_ref` from XOSC provides the precise timebase for the timer and watchdog.

---

## Mux Architecture

Each clock generator uses one or two *multiplexers* to select its source:

- **Aux mux** (all generators): glitchy when the source changes — for an instant the output is neither the old nor the new signal. For generators that can be stopped, disable the clock first, change source, re-enable.
- **Glitchless mux** (`clk_sys` and `clk_ref` only): a second mux after the aux mux. These clocks cannot be stopped, so the glitchless mux allows safe source switching by first moving to `clk_ref` (via glitchless mux), changing the aux mux source, then switching back via glitchless mux.

The SDK `clock_configure()` handles this sequence automatically.

---

## Clock Output on GPIO

Up to four clock signals can be routed to GPIO pins (GPIO 21, 23, 24, 25). On the Raspberry Pi Pico only **GPIO 21** is brought to a connector pin (GPIO 25 is the onboard LED; 23 and 24 are internal). Useful for testing or providing a clock to an external device.

---

## Frequency Counter

A hardware frequency counter measures a clock source by counting edges over a test interval defined in `clk_ref` cycles. 16 interval options from 1 µs (±2048 kHz accuracy) to 32 ms (±62.5 Hz accuracy). SDK function: `frequency_count_khz(src)`.

---

## Clock SDK (`hardware_clocks`)

| Function | Description |
|---|---|
| `clocks_init()` | Initialize the library (call first) |
| `clock_configure(clk_index, src, auxsrc, src_freq, freq)` | Configure a clock; handles mux sequencing |
| `clock_stop(clk_index)` | Stop a clock (power saving) |
| `clock_get_hz(clk_index)` | Return current frequency in Hz |
| `clock_set_reported_hz(clk_index, hz)` | Override reported frequency (when changed outside `clock_configure`) |
| `frequency_count_khz(src)` | Measure a source using the frequency counter; ±1 kHz accuracy (2 µs interval) |
| `clock_gpio_init(gpio, src, div)` | Route a clock to GPIO 21/23/24/25 |
| `clock_configure_gpin(clk_index, gpio, src_freq, freq)` | Use GPIO 20 or 22 as clock source |

`clock_index` values: `clk_gpout0`–`clk_gpout3`, `clk_ref`, `clk_sys`, `clk_peri`, `clk_usb`, `clk_adc`, `clk_rtc`.

---

## Timer

The Timer peripheral provides a **64-bit monotonic microsecond counter** and four alarms.

### Counter

- Counts microseconds since boot (monotonic — never wraps in practice: 2⁶⁴ µs ≈ 600,000 years).
- Timebase: derived from the Watchdog `clk_tick` (from `clk_ref`, nominally XOSC).
- Read protocol: read the low 32 bits first; the hardware latches the high 32 bits at that moment, so the subsequent high-word read is coherent.

### Alarms

- 4 alarms (alarm 0–3), generating **IRQs 0–3** respectively.
- Match on the **lower 32 bits** of the counter — fires when the counter's lower bits equal the alarm value.
- Since 2³² µs ≈ 72 minutes, alarms are suitable for delays of tens of microseconds to about one hour.
- Delays shorter than ~10 µs have significant imprecision; use PIO for sub-microsecond timing.

### Low-level SDK (`hardware_timer`)

| Function | Description |
|---|---|
| `time_us_32()` | Lower 32 bits of timer counter |
| `time_us_64()` | Full 64-bit counter |
| `busy_wait_us_32(delay)` / `busy_wait_us(delay)` | Spin-wait for N microseconds |
| `busy_wait_ms(delay)` | Spin-wait for N milliseconds |
| `busy_wait_until(t)` | Spin-wait until absolute timestamp |
| `time_reached(t)` | Non-blocking: is counter ≥ t? |
| `hardware_alarm_claim(num)` | Claim exclusive use of an alarm |
| `hardware_alarm_set_callback(num, cb)` | Set IRQ callback + enable interrupt |
| `hardware_alarm_set_target(num, t)` | Arm alarm to fire at timestamp t |
| `hardware_alarm_cancel(num)` | Cancel a pending alarm |

### High-level SDK (`pico_time` in `pico_stdlib`)

`pico_time` wraps the hardware timer in four modules:

**timestamp** — `absolute_time_t` type (opaque uint64_t) representing instants. `get_absolute_time()` returns "now". `delayed_by_us()` / `delayed_by_ms()` add an offset.

**sleep** — delay in low-power state. `sleep_us(n)`, `sleep_ms(n)`, `sleep_until(t)`.

**alarm** — builds *alarm pools* on top of hardware alarms. Each pool is backed by one hardware alarm and supports multiple concurrent software alarms.

| Function | Description |
|---|---|
| `alarm_pool_init_default()` | Initialize default pool (uses hardware alarm 3, max 16 alarms) |
| `alarm_pool_create(hw_alarm, max)` | Custom pool |
| `alarm_pool_add_alarm_at(pool, time, cb, data, fire_if_past)` | Fire at absolute timestamp |
| `alarm_pool_add_alarm_in_us/ms(pool, delay, cb, data, fire_if_past)` | Fire after delay |
| `alarm_pool_cancel_alarm(pool, id)` | Cancel alarm |

Callbacks run from the timer interrupt handler on **core 0**. If the callback returns a non-zero positive value, the alarm re-fires that many µs after the current timestamp; negative re-fires relative to the previous target.

**repeating_timer** — simplifies periodic callbacks.

| Function | Description |
|---|---|
| `add_repeating_timer_us(delay, cb, data, out)` | Repeating callback every `delay` µs (default pool) |
| `add_repeating_timer_ms(delay, cb, data, out)` | Every `delay` ms |
| `cancel_repeating_timer(timer)` | Stop |

Positive delay → counted from callback return; negative delay → counted from previous target (jitter-free).

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
| **Watchdog** | Likely used in RIA firmware for fault recovery — a hung OS task loop or USB stack would trigger a reset. |
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
