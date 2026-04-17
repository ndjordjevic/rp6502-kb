---
type: source
tags: [rp2350, rp2040, pio, gpio, dma, clocks, spi, uart, multicore, sdk]
related: [[sdk-architecture]], [[pio-architecture]], [[gpio-pinout]], [[dma-controller]], [[rp2040-clocks]], [[dual-core-sio]], [[rp6502-ria]], [[rp6502-vga]]
sources: []
created: 2026-04-17
updated: 2026-04-17
---

# Raspberry Pi Pico-series C/C++ SDK (RP-009085-KB-1)

**Summary**: Official SDK API reference for the Pico SDK covering both RP2040 and RP2350. 743 pages. Authoritative source for PIOASM instruction set encoding, all `hardware_xxx` and `pico_xxx` function signatures, and the explicit RP2040/RP2350 compatibility model.

---

## Key facts

- Build date: 2025-07-30. Covers SDK 2.x (GCC arm-none-eabi v9+ required for RP2350, v6+ for RP2040).
- Both RIA and VGA firmwares run on **RP2350** (Pi Pico 2) — `rp2350-arm-s` platform applies to both.
- Differs from prior sources: Quadros explains silicon internals; Fairhead shows programming patterns; this reference gives exact function signatures and compat tables.
- Ch.2 §2.10 documents RP2040 vs RP2350 API split explicitly.
- Ch.3 §3.4 contains the authoritative PIO ISA v0 (RP2040) and v1 (RP2350) encoding tables — the most complete treatment of PIOASM in any source.
- `static inline` builder pattern in `hardware_xxx` allows complex peripheral config to compile to a single register write via constant folding.

---

## Scope

| Chapter / Section | Status |
|---|---|
| Ch.1 About the SDK + Ch.2 §§2.1–2.10 SDK Architecture | [x] ingested — S1 |
| Ch.3 §3.1–3.2 PIO getting started | [ ] pending S2 |
| Ch.3 §3.3–3.4 PIOASM + PIO ISA | [ ] pending S3 |
| Ch.4 Signing and encrypting | [-] skipped — RP2350 secure boot, not used in RP6502 |
| §5.1.1 `hardware_adc` | [-] skipped — no analog input in RP6502 |
| §5.1.2–3 `hardware_base`, `hardware_boot_lock` | [-] skipped — low-level defs / RP2350-only boot lock |
| §5.1.4 `hardware_claim` | [-] skipped — claiming API documented in Ch.2 §2.3.3 (S1) |
| §5.1.5 `hardware_clocks` | [ ] pending S4 |
| §5.1.6–7 `hardware_divider`, `hardware_dcp` | [-] skipped — HW divider covered by Quadros; DCP is RP2350-only extra |
| §5.1.8 `hardware_dma` | [ ] pending S5 |
| §5.1.9–10 `hardware_exception`, `hardware_flash` | [-] skipped — exception vectors / flash XIP, not firmware-critical |
| §5.1.11 `hardware_gpio` pt.1 | [ ] pending S6 |
| §5.1.11 `hardware_gpio` pt.2 | [ ] pending S7 |
| §5.1.12 `hardware_hazard3` | [-] skipped — RP2350 RISC-V hazard unit, out of scope |
| §5.1.13 `hardware_i2c` | [-] skipped — I2C not used in RIA or VGA |
| §5.1.14 `hardware_interp` | [-] skipped — interpolator not used in RIA/VGA |
| §5.1.15 `hardware_irq` + §5.1.16 `hardware_pio` pt.1 | [ ] pending S8 |
| §5.1.16 `hardware_pio` pt.2 | [ ] pending S9 |
| §5.1.16 `hardware_pio` end + §5.1.17 `hardware_pll` | [ ] pending S10 |
| §5.1.18–24 (`hardware_powman` … `hardware_rcp`) | [-] skipped — RP2350-only power/crypto, not used |
| §5.1.25 `hardware_spi` + §5.1.27 `hardware_sync` | [ ] pending S11 |
| §5.1.26 `hardware_sha256` | [-] skipped — RP2350 SHA-256, not used |
| §5.1.28 `hardware_ticks` | [-] skipped — covered adequately in hardware_timer |
| §5.1.29 `hardware_timer` + §5.1.30 `hardware_uart` | [ ] pending S12 |
| §5.1.31–41 (`hardware_vreg` … `hardware_xosc`) | [-] skipped — voltage reg / watchdog / XIP cache, not relevant |
| §5.2.1–6 (`pico_aon_timer` … `pico_i2c_slave`) | [-] skipped — RP2350-only / I2C / bootsel, not relevant |
| §5.2.7 `pico_multicore` + §5.2.12 `pico_sync` | [ ] pending S13 |
| §5.2.8–11 (`pico_rand` … `pico_stdlib`) | [-] skipped — RNG / SHA / LED / stdlib umbrella |
| §5.2.13 `pico_time` | [ ] pending S14 |
| §5.2.14+ `pico_unique_id`, `pico_util` | [-] skipped — utility only |
| Ch.5.3–5.6 (third-party / networking / runtime / external API) | [-] skipped — TinyUSB, WiFi, BT, plumbing out of scope |
| Ch.6–10 (config defines / CMake build / board config / binary info) | [-] skipped — tooling, not hardware concepts |
| Appendix A–C (app notes / doc build / release history) | [-] skipped — sensor wiring / tooling / SDK release history |

---

## Related pages

- [[sdk-architecture]] — concept page synthesising Ch.1–2
- [[pio-architecture]]
- [[gpio-pinout]]
- [[dma-controller]]
- [[rp2040-clocks]]
- [[dual-core-sio]]
- [[rp6502-ria]]
- [[rp6502-vga]]
