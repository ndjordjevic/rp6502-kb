---
type: topic
tags: [rp2040, rp2350, pio, gpio, dma, clocks, spi, uart, multicore, sdk, ingestion-plan]
related: [[pio-architecture]], [[pioasm]], [[gpio-pinout]], [[dma-controller]], [[rp2040-clocks]], [[dual-core-sio]], [[rp6502-ria]], [[rp6502-vga]]
sources: []
created: 2026-04-17
updated: 2026-04-17
---

# Ingestion Plan: Raspberry Pi Pico-series C/C++ SDK (RP-009085-KB-1)

**Summary**: Chapter-by-chapter relevance assessment for `raw/pdfs/RP-009085-KB-1-raspberry-pi-pico-c-sdk (1).pdf` (743 pages, build 2025-07-30). This is the official API reference for the Pico SDK covering both RP2040 and RP2350; key sections are PIO architecture and assembler, hardware peripheral APIs, and multi-core primitives — all directly relevant to RIA and VGA firmware.

---

## Context

This document is the authoritative API reference for the Pico SDK. It differs from the two prior books:

- **Quadros** ("Knowing the RP2040") — hardware internals, registers, timing diagrams. Explains *how the silicon works*.
- **Fairhead** ("Programming the Pico/W in C") — hands-on programming guide. Explains *how to write programs*.
- **This SDK reference** — complete function-level API specification. Gives *exact function names and signatures* used in the firmware source, documents RP2040 vs RP2350 API deltas (§2.10), and contains the *authoritative PIOASM instruction set* specification with v0 (RP2040) and v1 (RP2350) encodings.

Key differences that affect relevance scoring:

- Chapter 2 §2.10 explicitly documents which SDK APIs are shared, RP2040-only, or RP2350-only — critical since the RIA uses RP2040 and the VGA firmware uses RP2350.
- Chapter 3 §3.4 (PIO instruction set reference) is the canonical source for PIOASM encoding details. Quadros and Fairhead both cover PIO conceptually but neither gives the full v0/v1 encoding tables.
- Chapter 5.1 `hardware_pio` gives the exact C function signatures used in the RIA firmware. Existing wiki coverage (Quadros + Fairhead) describes *what* PIO does but not the SDK call names.
- The SDK reference explicitly tags RP2350-only APIs (e.g., `hardware_dcp`, `hardware_hazard3`, `hardware_powman`, `hardware_riscv`) — useful for understanding which APIs appear in VGA firmware but not RIA.

The document is 743 pages. We read ~215 pages (14 sessions). The API reference sections (Chapter 5) are exhaustive function listings — reading is *selective*: extract key patterns, function signatures, and SDK conventions; skip individual function definitions unless they illuminate RIA/VGA firmware behavior.

---

## Chapter Map

### INGEST — High Priority

| Section | PDF pages | Why relevant |
|---|---|---|
| Ch.1 + Ch.2 §2.1–2.11 | 10–33 | SDK build model (CMake INTERFACE libraries), library naming (`hardware_` vs `pico_`), library claiming, multi-core model §2.8, C++ §2.9, §2.10 RP2040/RP2350 compat — foundation for understanding every API call in the firmware |
| Ch.3 §3.1–3.2 | 34–53 | PIO conceptual background (§3.1), first PIO app (§3.2.1 p.37), WS2812 LED driver DMA feed (§3.2.2 p.41), logic-analyser DMA pattern (§3.2.3 p.49), further examples (§3.2.4 p.54) — practical SDK patterns that appear directly in RIA PIO programs |
| Ch.3 §3.3–3.4 | 54–78 | §3.3 PIOASM assembler: directives, pseudoinstructions, language generators (pp.54-64); §3.4 full PIO instruction set reference (JMP, WAIT, IN, OUT, PUSH, PULL, MOV, IRQ, SET) with v0 (RP2040) and v1 (RP2350) encodings (pp.65-78) — authoritative; Quadros/Fairhead coverage is incomplete |
| §5.1.5 `hardware_clocks` | 95–112 | `clock_configure()`, PLL setup, XOSC/ROSC, frequency measurement — RIA requires precise PHI2 clock delivery to the 65C02; SDK clock API bridges [[rp2040-clocks]] register knowledge to callable functions |
| §5.1.8 `hardware_dma` | 122–147 | DMA channel config, transfer types, DREQ sources, chaining — RIA uses DMA for high-speed data movement between the 65C02 data bus and RP2040 memory; bridges [[dma-controller]] to SDK |
| §5.1.11 `hardware_gpio` | 155–186 | `gpio_init`, `gpio_set_dir`, `gpio_set_function`, `gpio_set_pulls`, `gpio_set_irq_enabled`, slew rate/Schmitt/drive-strength config — every 65C02 bus signal (PHI2, A0–A4, D0–D7, RWB, CS) goes through GPIO; bridges [[gpio-pinout]] to SDK |
| §5.1.15 `hardware_irq` | 206–219 | IRQ handler installation, priority, enabling/forcing — RIA dispatches to api_task via IRQ from PIO FIFO; needed to understand the interrupt side of the firmware dispatch loop |
| §5.1.16 `hardware_pio` | 220–263 | Full PIO SDK: `pio_sm_set_*`, `pio_sm_exec`, FIFO operations, DMA integration, `pio_gpio_init`, clock-div configuration — authoritative API layer over PIO hardware; directly used in the RIA PIO programs |
| §5.1.17 `hardware_pll` | 264 | PLL init/deinit, VCO config (single-page reference) — supplements `hardware_clocks`; RIA's PLL setup affects all firmware timing |
| §5.1.25 `hardware_spi` | 297–304 | SPI init, config, blocking/DMA transfers — PIX bus is SPI; bridges [[rp2040-spi]] to SDK; relevant for both RIA (SPI master) and VGA (SPI receiver) |
| §5.1.27 `hardware_sync` | 309–316 | Spinlocks, memory barriers, critical sections — multi-core safety in RIA firmware (both cores share state) |
| §5.1.29 `hardware_timer` | 319–333 | `hardware_alarm_*`, timer-pool IRQ model — RIA uses hardware alarms for OS tick and scheduled callbacks |
| §5.1.30 `hardware_uart` | 334–343 | `uart_init`, baud/format config, TX/RX — RIA console at 115200 8N1 on GPIO 4/5; bridges [[rp2040-uart]] to SDK |
| §5.2.7 `pico_multicore` | 374–384 | `multicore_launch_core1`, FIFO, reset — both RIA and VGA run split workloads on two cores |
| §5.2.12 `pico_sync` | 398–411 | Mutex, semaphore, critical section, recursive mutex — inter-core synchronization patterns in RIA firmware |
| §5.2.13 `pico_time` | 412–433 | `sleep_ms/us`, `get_absolute_time`, `add_alarm_in_ms`, repeating timers — timing infrastructure used throughout both firmwares |

### SKIP — Low or No Relevance

| Section | PDF pages | Reason to skip |
|---|---|---|
| Ch.4 Signing and encrypting | 79–83 | RP2350 secure boot feature; RP6502 firmware does not use binary signing |
| §5.1 `hardware_adc` | 86–90 | Pico ADC; RP6502 has no analog input path |
| §5.1 `hardware_base` | 91–92 | Low-level base defs; already represented in existing register-level wiki pages |
| §5.1 `hardware_boot_lock` | 93 | RP2350-only boot-time hardware lock; not in RIA firmware |
| §5.1 `hardware_claim` | 93–94 | Resource-claiming API; SDK convention documented in Ch.2 §2.3.3 (S1) |
| §5.1 `hardware_divider` | — | Hardware divider; covered in Quadros; not firmware-critical |
| §5.1 `hardware_dcp` | 122 (RP2350) | RP2350 double-co-processor; not in RIA |
| §5.1 `hardware_exception` | 148–150 | Cortex-M exception vectors; not directly relevant at SDK level |
| §5.1 `hardware_flash` | 151–154 | Flash XIP/erase; firmware update path; not needed for understanding RIA/VGA operation |
| §5.1 `hardware_hazard3` | 187 (RP2350) | RP2350 RISC-V hazard unit; out of scope |
| §5.1 `hardware_i2c` | 187–196 | I2C not used in RIA or VGA firmware |
| §5.1 `hardware_interp` | 197–205 | Interpolator; not used in RIA/VGA firmware |
| §5.1 `hardware_powman` | 265 (RP2350) | RP2350 power management; no low-power use in RP6502 |
| §5.1 `hardware_pwm` | 272–285 | PWM not used in RIA/VGA bus interface |
| §5.1 `hardware_resets` | 286–291 | Peripheral reset control; SDK detail not needed for wiki |
| §5.1 `hardware_riscv*` | 292–296 (RP2350) | RISC-V platform; RP6502 targets Arm cores only |
| §5.1 `hardware_rtc` | 294 (RP2040) | RTC deprecated in RP2350 SDK; not used in RP6502 |
| §5.1 `hardware_rcp` | 297 (RP2350) | RP2350 crypto processor; not relevant |
| §5.1 `hardware_sha256` | 305 (RP2350) | RP2350 SHA-256 accelerator; not used |
| §5.1 `hardware_ticks` | 317–318 | Tick generator; covered adequately in hardware_timer |
| §5.1 `hardware_vreg` | 344 | Voltage regulator control; not relevant |
| §5.1 `hardware_watchdog` | 345–347 | Watchdog; not a focus for RP6502 firmware concepts |
| §5.1 `hardware_xip_cache` | 348–350 | XIP cache management; not relevant |
| §5.1 `hardware_xosc` | 351 | XOSC low-level; covered in hardware_clocks (S4) |
| §5.2 `pico_aon_timer` | 353–357 | RP2350 always-on timer; not used in RIA |
| §5.2 `pico_async_context` | 358–368 | Async context framework; not used in RP6502 firmware |
| §5.2 `pico_bootsel_via_double_reset` | 369 | Board-level bootsel; not relevant |
| §5.2 `pico_fix` | 369 | Silicon errata workarounds; not concept-level |
| §5.2 `pico_flash` | 370–371 | Flash helper; not needed |
| §5.2 `pico_i2c_slave` | 372–373 | I2C slave; not used |
| §5.2 `pico_rand` | 385–386 | RNG; not used in RP6502 firmware |
| §5.2 `pico_sha256` | 387–391 | RP2350 SHA-256; not used |
| §5.2 `pico_status_led` | 392–396 | Onboard LED helper; not relevant |
| §5.2 `pico_stdlib` | 397 | Umbrella header; documented in Ch.1 |
| §5.2 `pico_unique_id` | 434 | Board unique ID; not a firmware concept |
| §5.2 `pico_util` | 435–444 | Utility data structures; not needed |
| §5.3 Third-party libraries | 445 | TinyUSB, mbedTLS — out of scope for this wiki's level |
| §5.4 Networking libraries | 445–492 | WiFi/BT — not in RP6502 RIA or VGA firmware |
| §5.5 Runtime infrastructure | 493–547 | `pico_bootrom`, `pico_bit_ops`, `pico_divider`, etc. — implementation plumbing, not hardware concepts |
| §5.6 External API headers | 547–548 | picobin/picoboot headers; not needed |
| Ch.6 SDK configuration defines | 549–565 | Reference list; no concept-level content |
| Ch.7 CMake build config | 566–572 | Build tooling; not hardware concepts |
| Ch.8 CMake build functions | 573–583 | Build tooling; not hardware concepts |
| Ch.9 Board configuration | 584–586 | Custom board files; not relevant |
| Ch.10 Embedded binary info | 587–591 | Binary metadata; not relevant |
| Appendix A: App Notes | 592–681 | Sensor wiring (DHT11, BME280, MPU9250, etc.); entirely out of scope |
| Appendix B: Building SDK docs | 682–683 | Documentation tooling; not relevant |
| Appendix C: SDK release history | 684–743 | Release notes; SDK evolution not needed in wiki |

---

## Suggested Ingest Order

Sessions follow natural dependency order: SDK concepts first, then PIO (core of the RIA), then hardware APIs by decreasing importance to the firmware, then high-level multi-core/time APIs.

- [ ] **S1** — SDK architecture (PDF 10–33, 24p): Ch.1+2 — build system, `INTERFACE` library model, naming conventions, hardware claiming, multi-core §2.8, C++ §2.9, RP2040/RP2350 compat §2.10
- [ ] **S2** — PIO getting started (PDF 34–53, 20p): §3.1 PIO concepts + §3.2 getting started — first program (p.37), WS2812 LED DMA feed (p.41), logic-analyser DMA pattern (p.49)
- [ ] **S3** — PIOASM + PIO ISA (PDF 54–78, 25p): §3.3 PIOASM assembler spec (pp.54-64: directives, pseudoinstructions, generators) + §3.4 complete PIO instruction set reference (pp.65-78: v0 RP2040 / v1 RP2350 encodings, all opcodes)
- [ ] **S4** — `hardware_clocks` (PDF 95–112, 18p): `clock_configure`, PLL setup, XOSC/ROSC, frequency measurement; `hardware_divider` at pp.113-121 is skipped
- [ ] **S5** — `hardware_dma` (PDF 122–147, 26p): channel config, transfer types, DREQ sources, chaining, sniff
- [ ] **S6** — `hardware_gpio` part 1 (PDF 155–170, 16p): `gpio_init`, `gpio_set_dir`, `gpio_put/get`, `gpio_set_function`, pull configuration
- [ ] **S7** — `hardware_gpio` part 2 (PDF 170–186, 17p): IRQ callbacks (`gpio_set_irq_enabled_with_callback`), slew rate, Schmitt trigger, drive strength
- [ ] **S8** — `hardware_irq` + `hardware_pio` pt.1 (PDF 206–230, 25p): IRQ handler install/priority (pp.206-219) + PIO SM init, clock-div, pin config, FIFO (pp.220-230)
- [ ] **S9** — `hardware_pio` pt.2 (PDF 230–254, 25p): SM execution control, `pio_sm_exec`, DMA integration, `pio_encode_*` helpers
- [ ] **S10** — `hardware_pio` end + `hardware_pll` (PDF 254–264, 11p): remaining hardware_pio functions (pp.254-263) + hardware_pll single-page reference (p.264); `hardware_powman` (pp.265-271) is RP2350-only and skipped
- [ ] **S11** — `hardware_spi` + `hardware_sync` (PDF 297–316, 16p content): SPI init/config/transfers (pp.297-304) + spinlocks, memory barriers, critical sections (pp.309-316); skip `hardware_sha256` at pp.305-308
- [ ] **S12** — `hardware_timer` + `hardware_uart` (PDF 319–343, 25p): hardware alarm pool, timer-IRQ model (pp.319-333) + UART init, baud/format, TX/RX (pp.334-343)
- [ ] **S13** — `pico_multicore` + `pico_sync` (PDF 374–411, 25p content): `multicore_launch_core1`, core FIFO, reset (pp.374-384) + mutex, semaphore, critical section (pp.398-411); skip `pico_rand/sha256/status_led/stdlib` at pp.385-397
- [ ] **S14** — `pico_time` (PDF 412–433, 22p): `sleep_ms/us`, `get_absolute_time`, `add_alarm_in_ms`, repeating timers

**Total: ~315 PDF pages across range; ~275 pages actually read (hardware_divider, hardware_sha256, hardware_powman, pico_rand/sha256/status_led/stdlib skipped); 14 sessions.**
**Delete this file when all boxes above are checked.**

---

## Wiki Pages Created / Updated

| Session | New pages | Updated pages |
|---|---|---|
| S1 | `wiki/concepts/sdk-architecture.md` | `wiki/entities/rp6502-ria.md`, `wiki/entities/rp6502-vga.md` |
| S2 | — | `wiki/concepts/pio-architecture.md` |
| S3 | `wiki/concepts/pioasm.md` | `wiki/concepts/pio-architecture.md` |
| S4 | — | `wiki/concepts/rp2040-clocks.md` |
| S5 | — | `wiki/concepts/dma-controller.md` |
| S6–S7 | — | `wiki/concepts/gpio-pinout.md` |
| S8–S10 | — | `wiki/concepts/pio-architecture.md`, `wiki/concepts/rp2040-clocks.md` |
| S11 | — | `wiki/concepts/rp2040-spi.md` |
| S12 | — | `wiki/concepts/rp2040-uart.md` |
| S13–S14 | — | `wiki/concepts/dual-core-sio.md` |
| All | `wiki/sources/pico-c-sdk.md` (created in S1) | `wiki/overview.md`, `wiki/index.md`, `wiki/log.md` |

---

## Comparison With Prior Sources

| Topic | Quadros | Fairhead | SDK reference (this) |
|---|---|---|---|
| PIO | Hardware ISA + register detail | SDK programming examples | **Authoritative PIOASM spec + v0/v1 encoding tables** |
| GPIO | Pad config, function table, hardware | SDK calls, slew/drive practical | **Complete function signature set** |
| Clocks/PLL | PLL arithmetic, divider registers | Brief (clock_get_hz examples) | **Full clock_configure API + measurement** |
| DMA | Full hardware chapter | Not covered | **Full SDK channel/DREQ/chaining API** |
| Multi-core | SIO registers, Cortex model | FreeRTOS + multicore_launch | **Mutex/semaphore/spinlock SDK APIs** |
| RP2040 vs RP2350 | RP2040 only | Brief Pico vs Pico 2 | **Explicit SDK-level compat table §2.10** |
| USB | TinyUSB/CDC full chapter | Not covered | Skip (out of scope) |
| WiFi | Not covered | Pico W chapter | Skip (not in RIA/VGA firmware) |

---

## Related pages

- [[pio-architecture]]
- [[pioasm]]
- [[gpio-pinout]]
- [[dma-controller]]
- [[rp2040-clocks]]
- [[dual-core-sio]]
- [[rp6502-ria]]
- [[rp6502-vga]]
