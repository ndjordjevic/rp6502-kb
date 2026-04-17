---
type: source
tags: [rp2040, rp2350, pio, gpio, spi, uart, multicore, wifi, sdk]
related: [[pio-architecture]], [[gpio-pinout]], [[rp6502-ria]], [[rp6502-ria-w]], [[dual-core-sio]], [[rp2040-spi]], [[rp2040-uart]], [[rp2040-clocks]]
sources: []
created: 2026-04-16
updated: 2026-04-16
---

# "Programming The Raspberry Pi Pico/W In C" (Fairhead, 3rd ed. 2025)

**Summary**: Hands-on SDK programming book covering RP2040 and RP2350 in C. Complements [[quadros-rp2040]] (hardware reference) with the SDK API layer: function signatures, CMake integration, practical timing advice, FreeRTOS, and the Pico W WiFi stack.

---

## Key facts

- Full title: *Programming The Raspberry Pi Pico/W In C*, 3rd edition, Harry Fairhead, 2025.
- 417 pages. Covers both RP2040 (original Pico) and RP2350 (Pico 2).
- PDF page numbers match printed page numbers.
- Companion to Quadros: Quadros explains *how* the hardware works; Fairhead explains *how to program it*.

---

## Scope

| Chapter | Pages | Status |
|---|---|---|
| Ch.1 – Before We Begin (RP2040 vs RP2350 diff) | 13–24 | `[x]` ingested |
| Ch.2 – Getting Started | 25–36 | `[-]` skipped — SDK install/toolchain, not RP6502-relevant |
| Ch.3 – Using the GPIO Lines | 37–54 | `[x]` ingested |
| Ch.4 – Some Electronics (drive type, slew, Schmitt) | 55–82 | `[x]` ingested |
| Ch.5 – Simple Input | 83–98 | `[-]` skipped — superseded by Ch.3 and Ch.6 |
| Ch.6 – Advanced Input: Events And Interrupts | 99–114 | `[x]` ingested |
| Ch.7 – Pulse Width Modulation | 115–144 | `[-]` skipped — PWM not used in RP6502 bus interface |
| Ch.8 – Controlling Motors And Servos | 145–180 | `[-]` skipped — no motor/servo use |
| Ch.9 – Getting Started With The SPI Bus | 181–200 | `[x]` ingested |
| Ch.10 – A-To-D and The SPI Bus | 201–214 | `[-]` skipped — no ADC use in RP6502 |
| Ch.11 – Using The I2C Bus | 215–236 | `[-]` skipped — I2C not used in RP6502 |
| Ch.12 – Using The PIO | 237–262 | `[x]` ingested |
| Ch.13 – DHT22 Sensor: Implementing A Custom Protocol | 263–282 | `[x]` ingested |
| Ch.14 – The 1-Wire Bus And The DS1820 | 283–312 | `[-]` skipped — Ch.13 covers the same PIO angle |
| Ch.15 – The Serial Port (UART) | 313–324 | `[x]` ingested |
| Ch.16 – Using the Pico W (WiFi) | 325–354 | `[x]` ingested |
| Ch.17 – Direct To The Hardware (SIO, IRQ) | 355–370 | `[x]` ingested |
| Ch.18 – Multicore and FreeRTOS | 371–404 | `[x]` ingested |
| Appendix I – CMakeLists.txt | 405–417 | `[-]` skipped — not specific to RP6502 |

---

## Ch.9 – Getting Started With The SPI Bus: Key facts

**SPI clock range**: 125 MHz (max) to 3.8 kHz (min). `spi_set_baudrate()` returns the actual achieved frequency; `spi_init()` also returns actual baud.

**Pin assignment**: `gpio_set_function(n, GPIO_FUNC_SPI)` for MISO, MOSI, SCLK. CS is a plain GPIO managed by the application — not handled by the SPI peripheral in master mode.

**Full-duplex API**: `spi_write16_read16_blocking(spi, tx_buf, rx_buf, count)` — sends and receives simultaneously. 8-bit variant: `spi_write_read_blocking`. Write-only: `spi_write_blocking` / `spi_write16_blocking`. Read-only: `spi_read_blocking(spi, repeated_tx, dst, len)` — must provide a dummy byte to send while clocking in data.

**CS timing quirk**: CS deasserts ~0.7 µs before the final clock edge completes. Insert `sleep_us(1000000 / (2 * clock_hz))` between end-of-transfer and CS deassert to avoid last-bit loss on latching devices.

**RIA relevance**: The ingest plan cited "SPI for SD card storage" but the RIA firmware uses USB MSC + FatFS rather than SPI for storage. The SDK patterns and CS timing note still document the SPI peripheral accurately. See [[rp2040-spi]].

---

## Ch.13 – DHT22 Custom Protocol: Key facts

Structural parallel to RIA's 65C02 bus decoding — PIO implementing a timing-sensitive proprietary protocol.

**Sampling vs counting**: Two strategies for pulse-width-encoded protocols:
- *Counting*: count SM clock cycles while pin is high → CPU applies threshold. Flexible but more CPU work.
- *Sampling* (preferred): `wait 1 pin 0 [N]` + `in pins, 1` — wait for rising edge, delay N cycles, sample once. Simpler PIO, full 32-bit FIFO words, no CPU math. Choose clock divider so N cycles land between the "0" and "1" pulse widths.

**Parameterized PIO startup**: `pull block` at program start stalls until C writes a value via `pio_sm_put_blocking()`; use `mov x, osr` to load it as a loop counter. Allows C to pass timing constants at runtime without recompiling the `.pio` file.

**Bidirectional / open-collector pin**: `set pindirs, 1` / `set pindirs, 0` within the PIO program to switch a pin between output (drive start pulse) and input (receive data). Same SET and IN groups point to the same GPIO; requires external pull-up resistor.

**`jmp pin`**: branches based on raw GPIO state without consuming the `in` instruction — used for per-bit conditional logic. Must configure with `sm_config_set_jmp_pin()`.

---

## Ch.12 – Using The PIO: Key facts

**SDK setup sequence** — every PIO program in C:
1. `pio_add_program(pio, &prog)` — load binary into PIO instruction memory
2. `pio_claim_unused_sm(pio, true)` — claim first free state machine
3. `prog_get_default_config(offset)` — get auto-generated config struct
4. Configure via `sm_config_set_*()` functions
5. `pio_gpio_init()` + `pio_sm_set_consecutive_pindirs()` — set GPIO mode/direction
6. `pio_sm_init()` + `pio_sm_set_enabled()` — load config and start

**GPIO pin groups**: OUT (data, driven by `out` + OSR), SET (control, driven by `set` + 5-bit immediate), IN (input, read by `in` into ISR), SIDESET (side-effect per-instruction), JMP-pin (condition for `jmp pin`). SIDESET has precedence when groups overlap.

**OSR (Output Shift Register)**: bridge between TX FIFO and GPIO output. `out pins, n` presents n bits from OSR to OUT group simultaneously. Autopull (`sm_config_set_out_shift`) reloads OSR from TX FIFO automatically at threshold.

**ISR (Input Shift Register)**: bridge between GPIO input and RX FIFO. `in pins, n` reads n bits from IN group. Autopush (`sm_config_set_in_shift`) transfers ISR to RX FIFO at threshold.

**Clock divider**: `sm_config_set_clkdiv_int_frac(&c, int, frac)`. Fractional divider introduces jitter — use integer-only (`frac=0`) for timing-critical protocols like the 65C02 bus.

**Edge detection**: `wait 0 pin 0` then `wait 1 pin 0` simulates a rising-edge trigger. Latency ≈ 45 ns at maximum SM clock. This is the technique used in `ria_write` to synchronize to PHI2.

**Wrap**: `.wrap_target` / `.wrap` directives make the PC wrap automatically with zero timing cost — eliminates the end-of-loop `jmp` instruction.

**CMake**: `pico_generate_pio_header(target path/to/prog.pio)` + `target_link_libraries(target hardware_pio)` assembles the `.pio` file and generates a `.pio.h` header.

---

## Ch.4 – Some Electronics: Key facts

**Output drive modes**: push-pull (default, active drive both directions), pull-up (transistor+resistor, open-collector compatible), pull-down (OR bus). SDK: `gpio_pull_up/down()`, `gpio_set_pulls(gpio, up, down)`, `gpio_disable_pulls()`. Internal pull resistors 50–80kΩ.

**Drive strength**: `gpio_set_drive_strength(gpio, GPIO_DRIVE_STRENGTH_2/4/8/12MA)`. Internal resistance ~130Ω at 2mA. If load draws more current than rating, output voltage < 2.7V — unreliable as logic 1 for 3.3V devices.

**Schmitt trigger**: `gpio_set_input_hysteresis_enabled(gpio, true)`. At 3.3V: rises above 2.0V → 1; must fall below 1.8V → 0 (0.2V hysteresis).

**Slew rate**: `gpio_set_slew_rate(gpio, GPIO_SLEW_RATE_SLOW/FAST)`. FAST for high-speed bus signals; SLOW reduces EMI on long lines.

**RP2350 Erratum E9 (critical)**: GPIO input leakage causes pull-down latch bug. After a pin is driven high and released, internal pull-down (50–80kΩ) latches line at ~2V (reads as 1). Affects all 30 user GPIO in all modes including PIO. Workarounds: external pull-down ≤8kΩ; or software disable input buffer while driving (`padsbank0_hw->io[gpio]` bit 6); or use pull-up. **RIA implication**: avoid internal pull-downs on bidirectional 65C02 bus lines (D0–D7).

---

## Ch.1 – Before We Begin: Key facts

**RP2040 vs RP2350 comparison** (most relevant differences for RIA firmware):

| Feature | RP2040 (Pico 1) | RP2350 (Pico 2) — RIA target |
|---|---|---|
| Cores | Dual Cortex-M0+ @ 133 MHz | Dual Cortex-M33 @ 150 MHz (or Hazard3 RISC-V) |
| SRAM | 264 KB | 520 KB |
| Flash | 2 MB | 4 MB |
| PIO blocks | 2 (8 SMs total) | **3 (12 SMs total)** |
| GPIO | 26 | 26 (same, same pinout) |
| Security | None | OTP 8KB, TrustZone, SHA-256, Glitch Detector, Secure Boot |
| Flash interface | SSI | QSPI/QMI |
| HSTX | No | Yes |

**Key firmware implications**: RP2350's extra PIO block (PIO2) is unused by RIA firmware but available for future use. Higher clock (150 MHz vs 133 MHz) and more SRAM (520KB vs 264KB) benefit XRAM capacity and timing margins. Cortex-M33 adds hardware FPU, DSP extensions, and TrustZone (not currently used by RIA).

**RISC-V (Hazard3)**: RP2350 can run Hazard3 RISC-V cores at the same 150 MHz. Fairhead recommends ARM unless RISC-V assembly is the goal. RIA firmware uses Cortex-M33.

**Pinout**: Pico 1 and Pico 2 have identical external pinouts — all 26 GPIO pins compatible. RIA firmware GPIO assignments work on both without modification.

---

## Ch.16 – Using the Pico W: Key facts

**CYW43439 hardware**: SD 1-bit SPI on GPIO23–29. GPIO25 (LED) unavailable — LED now on CYW43439 WL_GPIO0. Control: `cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, v)`. Pico W detection: ADC3 (GPIO29) reads near 0 on Pico W vs VSYS/3 on Pico 1/2.

**Three WiFi modes** (selected by CMakeLists library): polling (`cyw43_arch_lwip_poll`, call `cyw43_arch_poll()` every ~1ms, not multicore-safe), background interrupt (`pico_cyw43_arch_lwip_threadsafe_background`, multi-core safe, LwIP calls must be bracketed by `cyw43_arch_lwip_begin()`/`end()`), FreeRTOS.

**RIA-W uses background mode** (two cores). Auth: `CYW43_AUTH_WPA2_MIXED_PSK` recommended. Country: `CYW43_COUNTRY_WORLDWIDE` for max compatibility.

**LwIP NETIF**: `netif_default` populated after connect; access via `netif_ip_addr4()`, `netif_ip_netmask4()`, `netif_ip_gw4()`, `netif_get_hostname()`. Set hostname before connect; static IP after connect.

**HTTP client**: `httpc_get_file_dns(hostname, port, uri, settings, recv_fn, arg, conn)`. Three async callbacks: body (`recv_fn`), headers (`headers_done_fn`), completion (`result_fn`). Use `pbuf_copy_partial()`. CMake: add `pico_lwip_http`.

**HTTP server**: `httpd_init()` + web content in `fsdata.c` (generated by `htmlgen` from `fs/` dir). Dynamic content via SSI tags `<!--#tagname-->` in `.shtml`/`.ssi` files + `http_set_ssi_handler()` + `#define LWIP_HTTPD_SSI 1`.

---

## Ch.6 – Advanced Input: Events And Interrupts: Key facts

**Hardware events**: 4 event bits per GPIO (`GPIO_IRQ_LEVEL_LOW/HIGH` not latched; `GPIO_IRQ_EDGE_FALL/RISE` latched, WC). No SDK read function — use `gpio_get_events()` helper via `iobank0_hw->intr[gpio/8]`. Clear with `gpio_acknowledge_irq()`.

**Single interrupt for all GPIO**: `IO_IRQ_BANK0` fires for any GPIO event. Unique: GPIO interrupts are independently maskable per core via `proc0_irq_ctrl`/`proc1_irq_ctrl`.

**SDK callback API**: `gpio_set_irq_enabled_with_callback(gpio, events, enabled, callback)` — only ONE callback active globally; the SDK's default handler scans all GPIO lines before calling it. `gpio_set_irq_enabled()` separately enables/disables without changing callback.

**Raw interrupt handler**: `gpio_add_raw_irq_handler_masked(mask, handler)` — bypasses SDK default handler; must manually call `gpio_acknowledge_irq()` and `irq_set_enabled(IO_IRQ_BANK0, true)`. Can resolve pulses ≥ ~4 µs; polling resolves to ~1 µs.

**Starvation**: interrupt handler firing > ~200 Hz with slow handlers starves the main loop. Interrupt handler must be short; push data to a queue processed by the main loop.

**Silent event loss bug**: `gpio_set_irq_enabled()` discards pending events when re-enabling. Fix: use `gpio_set_irq_active()` custom function with `hw_set_bits()`/`hw_clear_bits()` on `irq_ctrl_base->inte[]` — toggles enable without touching event status.

**RIA implication**: confirms PIO-based bus capture is the correct design; GPIO interrupts are only appropriate for low-frequency signals like RESB detection.

---

## Ch.3 – Using the GPIO Lines: Key facts

**Function select**: `gpio_set_function(n, GPIO_FUNC_SIO/PIO0/PIO1/UART/SPI/...)` — ten constants; `GPIO_FUNC_NULL` isolates pin. `GPIO_FUNC_SIO` is the default CPU-controlled mode for `gpio_put`/`gpio_get`.

**Basic API**: `gpio_init(n)`, `gpio_set_dir(n, GPIO_OUT)`, `gpio_get(n)`, `gpio_put(n, val)`, `gpio_set_input_enabled(n, enabled)`.

**Mask API**: `gpio_set_mask(mask)`, `gpio_clr_mask(mask)`, `gpio_xor_mask(mask)`, `gpio_put_masked(mask, val)`, `gpio_get_all()`, `gpio_put_all(val)`. Note: `gpio_put_masked` is read-modify-write — use `sio_hw->gpio_set/clr` for atomic multi-core GPIO.

**Speed**: ~6 ns/call for `gpio_put` in Release at 150 MHz; direct `sio_hw` ~4 ns; `gpio_put_masked` slower.

**Timing functions**: `sleep_us(us)` (power-saving), `busy_wait_us(us)` (~1 µs accurate spin), `sleep_until(t)` / `busy_wait_until(t)` for fixed-duration windows using `time_us_64()` deadlines.

**Overrides**: `gpio_set_outover(n, GPIO_OVERRIDE_NORMAL/INVERT/LOW/HIGH)`, `gpio_set_inover()`, `gpio_set_oeover()`.

**Pico W GPIO**: GPIO23–29 internal functions (SMPS, VBUS, LED, VSYS) relocated to CYW43439 WiFi chip's `WL_GPIO0/1/2`. RIA-W uses `WL_GPIO0` for LED instead of GPIO25.

---

## Ch.15 – The Serial Port: Key facts

**Protocol**: asynchronous; line idles HIGH; start bit (LOW) sets timing; data bits LSB first; optional parity; 1–2 stop bits. Notation: `115200 8n1` = 115200 baud, 8 data bits, no parity, 1 stop bit.

**Baud vs data rate**: baud = raw bit rate; actual byte throughput lower due to start/stop/parity overhead.

**UART GPIO assignment** (from Fairhead's pin tables):
- UART0: TX=GPIO0/12/16/28, RX=GPIO1/13/17/29, CTS=GPIO2/14/18, RTS=GPIO3/15/19
- UART1: TX=GPIO4/8/20/24, RX=GPIO5/9/21/25, CTS=GPIO6/10/22/26, RTS=GPIO7/11/23/27
- Function select: `gpio_set_function(n, GPIO_FUNC_UART)`

**Setup sequence**:
```c
uart_init(uart1, 115200);
gpio_set_function(4, GPIO_FUNC_UART);  // TX
gpio_set_function(5, GPIO_FUNC_UART);  // RX
uart_set_format(uart1, 8, 1, UART_PARITY_NONE);
```

**FIFO**: 32-element on both TX and RX. Disable with `uart_set_fifo_enabled(uart, false)` for single-char immediate mode.

**stdio layer**: `stdio_init_all()` routes `printf` to UART0 (GPIO0/1) by default. Use `stdio_uart_init_full(uart, baud, tx, rx)` for custom routing. Default UART: `PICO_DEFAULT_UART=0`, `PICO_DEFAULT_UART_TX_PIN=0`, `PICO_DEFAULT_UART_RX_PIN=1`.

**Small buffer stall**: calling `printf` while receiving data on another UART can overflow the 32-entry RX FIFO while TX stalls. Fix: relay char-by-char with `uart_putc` rather than batch-then-print.

**RIA relevance**: UART1 on GPIO4/5 is the RIA console at 115200 8N1. See [[rp2040-uart]].

---

## Ch.17 – Direct To The Hardware: Key facts

**SIO (Single-cycle IO)**: GPIO_OUT, GPIO_OE, GPIO_IN registers — one bit per pin. `gpio_get_all()` reads all 30 pins in a single cycle. Atomic set/clear/XOR aliases avoid read-modify-write races between cores.

**Hardware divider**: SIO contains a hardware integer divider — 8 cycles for signed/unsigned 32÷32. SDK `hardware_divider` wraps it; compiler auto-uses it for `/` and `%` operators on ARM. Each core has its own divider instance (no contention).

**Interpolator**: Two per core in SIO. Lane-based multiply-accumulate for audio, texture mapping, linear interpolation. Dedicated to each core — no locking needed.

**NVIC interrupts**: Cortex-M0+ has 32 IRQ lines. `irq_set_exclusive_handler(irq, fn)` or `irq_add_shared_handler(irq, fn, priority)`. Priority 0–3 (0 = highest) on M0+; 0–255 on M33. `irq_set_enabled(irq, true)` arms the line.

**RIA implication**: atomic GPIO aliases (`sio_hw->gpio_set`, `gpio_clr`) are critical for safe multi-core bus control. See [[dual-core-sio]], [[gpio-pinout]].

---

## Ch.18 – Multicore and FreeRTOS: Key facts

**Launch**: `multicore_launch_core1(entry_fn)` — core 1 starts executing `entry_fn`. Core 0 continues. `multicore_reset_core1()` stops core 1.

**Inter-core FIFOs**: 8-entry hardware FIFOs in SIO. `multicore_fifo_push_blocking(val)` / `multicore_fifo_pop_blocking()`. `multicore_fifo_rvalid()` checks for data. IRQ-based: `multicore_fifo_set_irq_handler(fn)`.

**Spinlocks**: 32 hardware spinlocks in SIO. `spin_lock_claim(n)` / `spin_lock_blocking(lock)` / `spin_unlock(lock, saved)`. SDK wraps these in `mutex_init()`/`mutex_enter_blocking()`/`mutex_exit()` and `critical_section_init()`/`critical_section_enter_blocking()`/`critical_section_exit()` (disables IRQs + spinlock).

**FreeRTOS on Pico**: SMP port runs tasks across both cores. `xTaskCreate(fn, name, stack, param, priority, &handle)`. Mutexes: `xSemaphoreCreateMutex()`. Queues for inter-task communication. Requires `FreeRTOS-Kernel` submodule + CMake config. WiFi: use `pico_cyw43_arch_lwip_sys_freertos` library.

**RIA firmware**: uses raw `pico_multicore` (no FreeRTOS). Core 0 handles USB + OS dispatch; core 1 runs the 65C02 bus engine. See [[dual-core-sio]].

---

## Related pages

- [[pio-architecture]] — SDK patterns from Ch.12 added to "SDK Programming Patterns" section
- [[gpio-pinout]] — Ch.3/4/6 SDK API sections added
- [[dual-core-sio]] — Ch.17/18 SIO, multicore, spinlocks
- [[rp2040-uart]] — Ch.15 UART protocol and SDK
- [[rp2040-spi]] — Ch.14 SPI protocol and SDK
- [[rp2040-clocks]] — Ch.11 clocks, timer, watchdog
- [[rp6502-ria]]
- [[rp6502-ria-w]]
