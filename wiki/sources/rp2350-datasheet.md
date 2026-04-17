---
type: source
tags: [rp2350, hardware, datasheet, reference, pio, gpio, clocks, dma, usb, spi, uart, hstx, errata]
related: [[rp2350]], [[pio-architecture]], [[gpio-pinout]], [[dual-core-sio]], [[rp2040-clocks]], [[dma-controller]], [[usb-controller]], [[rp2040-spi]], [[rp2040-uart]], [[rp6502-vga]], [[known-issues]], [[hstx]]
sources: []
created: 2026-04-17
updated: 2026-04-17
---

# RP2350 Datasheet (RP-008373-DS-2)

**Summary**: Official Raspberry Pi RP2350 datasheet (1378 pages, build 2025-07-29). Authoritative reference for RP2350 hardware — the chip that powers both the Pi Pico 2 (VGA firmware) and Pi Pico 2 W (RIA-W firmware) in the RP6502 Picocomputer.

---

## Document info

- **File**: `raw/pdfs/RP-008373-DS-2-rp2350-datasheet.pdf`
- **Build date**: 2025-07-29
- **Pages**: 1378
- **Authority**: Official Raspberry Pi documentation (highest trust tier)

## Key facts

- RP2350 family: RP2350A (QFN-60, 30 GPIO), RP2350B (QFN-80, 48 GPIO), RP2354A/B (with 2 MB flash)
- Production silicon: A4; prior versions A0–A3 were internal/limited
- 2× Cortex-M33 (ARMv8-M) or 2× Hazard3 (RISC-V RV32IMAC+) — architecture dynamically switchable
- 520 KB SRAM in 10 banks (vs 264 KB / 6 banks in RP2040)
- 3 PIO blocks (PIO0, PIO1, PIO2) = 12 state machines; PIO ISA v1 (adds MOV-to/from-RX)
- SIO TMDS encoder (§3.1.9) — hardware DVI pixel encoding, used in VGA firmware
- HSTX peripheral (§12.11) — high-speed serial transmit, alternative video output path
- GPIO F0–F11 (12 functions vs 9 in RP2040); HSTX on GPIO12–19 (F0)
- 2× hardware timers (TIMER0 + TIMER1); tick generators (§8.5)
- LPOSC (low-power oscillator, §8.4) — new clock source vs RP2040
- 28+ silicon errata (E1–E28); critical for RP6502: E12 (USB clk_sys > 48 MHz), E5 (DMA CHAIN_TO/ABORT), E2 (SIO spinlock), E9 (GPIO leakage); all documented in [[known-issues]]

## Scope

| Session | Content | PDF pages | Status |
|---|---|---|---|
| S1 | Ch.1 Introduction + Ch.2 §2.1 bus fabric + §2.2 address map | 13–34 | [x] ingested |
| S2 | §3.1 SIO programmer's model (CPUID, GPIO, spinlocks, FIFOs, doorbells, TMDS, interpolator) | 36–53 | [x] ingested |
| S3 | §8.1 Clocks overview (sources, generators, resus, programmer's model) | 513–528 | [x] ingested |
| S4 | §8.2 XOSC + §8.3 ROSC + §8.4 LPOSC + §8.5 Tick generators + §8.6 PLL | 554–583 | [x] ingested |
| S5 | Ch.9 GPIO §9.1–9.10 (changes from RP2040, F0–F11, pads, SIO control, GPIO coprocessor) | 587–603 | [x] ingested |
| S6 | Ch.11 PIO §11.1–11.4.7 (overview, changes, programmer's model, pioasm, JMP–PULL) | 876–895 | [x] ingested |
| S7 | Ch.11 PIO §11.4.8–11.5 (MOV–SET, functional details: wrapping, FIFO, autopush, clock div) | 896–914 | [x] ingested |
| S8 | Ch.11 PIO §11.6 examples (Duplex SPI, WS2812, UART TX/RX; skim rest) | 915–938 | [x] ingested |
| S9 | §12.1 UART §12.1.1–12.1.7 (changes from RP2040, operation, programmer's model) | 961–971 | [x] ingested |
| S10 | §12.3 SPI §12.3.1–12.3.4 (changes from RP2040, functional description, operation) | 1046–1059 | [x] ingested |
| S11 | §12.6 DMA §12.6.1–12.6.9 (changes, channel config, DREQ, interrupts, features, examples) | 1094–1111 | [x] ingested |
| S12 | §12.7 USB §12.7.1–12.7.4 (changes from RP2040, architecture, programmer's model) | 1141–1158 | [x] ingested |
| S13 | §12.11 HSTX complete readable section (data FIFO, OSR, crossbar, clk gen, command expander) | 1202–1211 | [x] ingested |
| S14 | Appendix C revision history + Appendix E errata (E1–E28+) | 1354–1376 | [x] ingested |

## Wiki pages created / updated

| Session | New pages | Updated pages |
|---|---|---|
| S1 | `wiki/entities/rp2350.md` | `wiki/concepts/memory-map.md` (RP2350 address map), `wiki/concepts/rp2040-memory.md` (RP2350 SRAM notes) |
| S2 | — | `wiki/concepts/dual-core-sio.md` (TMDS encoder, RP2350 FIFO depth, doorbells) |
| S3–S4 | — | `wiki/concepts/rp2040-clocks.md` (LPOSC, RP2350 clock changes) |
| S5 | — | `wiki/concepts/gpio-pinout.md` (RP2350 F0–F11 detail, pad changes) |
| S6–S8 | — | `wiki/concepts/pio-architecture.md` (PIO2, v1 encoding, examples) |
| S9 | — | `wiki/concepts/rp2040-uart.md` |
| S10 | — | `wiki/concepts/rp2040-spi.md` |
| S11 | — | `wiki/concepts/dma-controller.md` |
| S12 | — | `wiki/concepts/usb-controller.md` |
| S13 | `wiki/concepts/hstx.md` | `wiki/entities/rp6502-vga.md` |
| S14 | — | `wiki/topics/known-issues.md` (RP2350 errata) |
| All | `wiki/sources/rp2350-datasheet.md` | `wiki/overview.md`, `wiki/index.md`, `wiki/log.md` |

## Comparison with prior sources

| Topic | Quadros (RP2040) | Fairhead (RP2040/RP2350) | Pico C SDK | **This datasheet** |
|---|---|---|---|---|
| PIO | Hardware ISA v0, registers | SDK examples | Full SDK API | **v1 encoding, 3 blocks, EXEC'd details** |
| GPIO | Pad config, F0-F8 | SDK calls | Full SDK API | **F0-F11 table, GPIO coprocessor, bus keeper** |
| Clocks | PLL arithmetic, RP2040 | Brief examples | SDK clock API | **LPOSC, RP2350 revision changes, updated PLL** |
| DMA | Full RP2040 chapter | Not covered | SDK DMA API | **RP2350 DMA changes, DREQ updates** |
| USB | TinyUSB/CDC RP2040 | Not covered | SDK USB notes | **RP2350 USB changes** |
| SIO | RP2040 SIO/spinlocks | SDK multicore | pico_multicore | **TMDS encoder, doorbells, GPIO coprocessor** |
| HSTX | Not present | Not covered | Not covered | **Complete new peripheral** |
| Errata | N/A | Not covered | Not covered | **E1–E28+ silicon bugs** |

## Related pages

- [[rp2350]] — entity page for the RP2350 chip
- [[pio-architecture]] — PIO ISA v1, 3 blocks
- [[gpio-pinout]] — F0–F11 function table
- [[dual-core-sio]] — SIO, TMDS encoder, doorbells
- [[hstx]] — high-speed transmit peripheral
- [[rp2040-clocks]] — LPOSC, PLL, clock domains
- [[dma-controller]] — DMA changes from RP2040
- [[usb-controller]] — USB changes from RP2040
- [[known-issues]] — RP2350 errata
