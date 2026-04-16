---
type: topic
tags: [rp2040, rp2350, pio, gpio, spi, uart, multicore, wifi, ingestion-plan]
related: [[pio-architecture]], [[gpio-pinout]], [[rp6502-ria]], [[rp6502-ria-w]]
sources: []
created: 2026-04-16
updated: 2026-04-16
---

# Ingestion Plan: "Programming The Raspberry Pi Pico/W In C" (Fairhead, 3rd ed. 2025)

**Summary**: Chapter-by-chapter relevance assessment for `raw/pdfs/Programming The Raspberry Pi Pico_W In C, Third Edition_nodrm.pdf` (417 pages). This is a hands-on SDK programming book covering RP2040 and RP2350 in C, with dedicated chapters on PIO, multicore, WiFi, and direct hardware access — all relevant to the RIA firmware.

---

## Context

This book covers both RP2040 and RP2350 (the chip the RIA actually uses). Unlike the Quadros book (which is reference-style), Fairhead is programming-oriented: SDK calls, example code, practical timing and race-condition advice. It complements Quadros well — Quadros explains *how* the hardware works, Fairhead explains *how to program it*.

Key differences that affect relevance scoring:
- The book includes a FreeRTOS chapter — highly relevant since the RIA's `api_task()` loop uses a cooperative task model.
- Chapter 17 "Direct To The Hardware" covers the SIO (Single-Cycle IO Block) used for inter-core communication in the RIA.
- Chapter 13 shows PIO implementing a custom 1-wire-style protocol — a close structural parallel to how the RIA's PIO programs decode the 65C02 bus.
- Chapter 16 covers the Pico W WiFi stack — directly relevant to [[rp6502-ria-w]].

PDF page numbers match printed page numbers directly (front matter uses the same numbering).

---

## Chapter Map

### INGEST — High Priority

| Chapter | PDF pages | Why relevant |
|---|---|---|
| Ch.3 – Using the GPIO Lines | 37–54 | GPIO API fundamentals — all 65C02 bus signals (PHI2, A0–A4, D0–D7, CS, RWB…) go through GPIO; speed and override sections map to [[gpio-pinout]] |
| Ch.6 – Advanced Input: Events And Interrupts | 99–114 | GPIO interrupts, raw IRQ, race conditions, starvation — directly mirrors timing concerns in `ria_action` FIFO dispatch and `api_task()` |
| Ch.12 – Using The PIO | 237–262 | PIO SDK: state machines, GPIO for PIO output, clock division, loops, data FIFOs, input, edges, advanced PIO — core reference for [[pio-architecture]] |
| Ch.17 – Direct To The Hardware | 355–370 | Register access patterns, Single-Cycle IO (SIO) block for inter-core, Events, IRQ control, GPIO coprocessor, Pico 2 security — maps to how RIA cores communicate |
| Ch.18 – Multicore and FreeRTOS | 371–404 | SDK multicore launch, FreeRTOS tasks/scheduling/queues/locks, race conditions — RIA runs two cores and the task model closely resembles a cooperative RTOS |

### INGEST — Medium Priority

| Chapter | PDF pages | Why relevant |
|---|---|---|
| Ch.1 – The Raspberry Pi Pico – Before We Begin | 13–24 | RP2040 v RP2350 comparison (p.14–17) is the key section — explains RP2350-specific differences that affect the RIA firmware |
| Ch.4 – Some Electronics | 55–82 | Drive type, slew rate, Schmitt trigger configuration (p.65–79) — relevant for understanding how RIA configures bus pins for reliable 8 MHz signal integrity |
| Ch.9 – Getting Started With The SPI Bus | 181–200 | SPI SDK usage — RIA uses SPI for SD card storage |
| Ch.13 – DHT22 Sensor: Implementing A Custom Protocol | 263–282 | PIO used to implement a proprietary 1-wire-like protocol — best practical parallel in the book to how RIA's PIO programs decode the 65C02 bus in real time |
| Ch.15 – The Serial Port | 313–324 | UART SDK: setup, data transfer, buffers — RIA console on GPIO 4–5 at 115200 8N1 |
| Ch.16 – Using the Pico W | 325–354 | WiFi stack (cyw43_arch), TCP/IP, web client/server — directly relevant to [[rp6502-ria-w]] Hayes modem and NTP features |

### SKIP — Low or No Relevance

| Chapter | PDF pages | Reason to skip |
|---|---|---|
| Ch.2 – Getting Started | 25–36 | SDK install, VS Code setup, Hello World — toolchain basics not relevant to RP6502 concepts |
| Ch.5 – Simple Input | 83–98 | Polling and FSM patterns — covered more usefully in Ch.3 and Ch.6 |
| Ch.7 – Pulse Width Modulation | 115–144 | PWM not used in the RP6502 bus interface; RIA PSG/OPL2 audio is internal, not PWM-pin-based |
| Ch.8 – Controlling Motors And Servos | 145–180 | No motor/servo use in RP6502 |
| Ch.10 – A-To-D and The SPI Bus | 201–214 | Pico ADC + MCP3008 — RP6502 has no analog input use case |
| Ch.11 – Using The I2C Bus | 215–236 | I2C not used in RP6502; NFC (PN532) uses USB, not I2C |
| Ch.14 – The 1-Wire Bus And The DS1820 | 283–312 | Second PIO custom-protocol example; Ch.13 (DHT22) already covers this angle more concisely |
| Appendix I – Custom Projects: CMakeLists.txt | 405–417 | CMake setup; not specific to RP6502 firmware internals |

---

## Suggested Ingest Order

- [ ] **Ch.12 – Using The PIO** (PDF 237–262) — most critical, deepens [[pio-architecture]]
- [ ] **Ch.13 – DHT22 Custom Protocol** (PDF 263–282) — practical PIO follow-up
- [ ] **Ch.17 – Direct To The Hardware** (PDF 355–370) — SIO / inter-core detail
- [ ] **Ch.18 – Multicore and FreeRTOS** (PDF 371–404) — dual-core task model
- [ ] **Ch.3 – Using the GPIO Lines** (PDF 37–54) — GPIO API, fills [[gpio-pinout]] gaps
- [ ] **Ch.6 – Advanced Input: Events And Interrupts** (PDF 99–114) — interrupt/race condition context
- [ ] **Ch.16 – Using the Pico W** (PDF 325–354) — WiFi for [[rp6502-ria-w]]
- [ ] **Ch.1 – Before We Begin** (PDF 13–24) — RP2040 vs RP2350 diff (just pp.14–17)
- [ ] **Ch.4 – Some Electronics** (PDF 55–82) — drive/slew/Schmitt (pp.65–79 sufficient)
- [ ] **Ch.9 – Getting Started With The SPI Bus** (PDF 181–200) — SD card SPI
- [ ] **Ch.15 – The Serial Port** (PDF 313–324) — console UART

Total to ingest: ~201 PDF pages out of 417 (skip ~216 pages).
**Delete this file when all boxes are checked.**

---

## Comparison With Quadros Book

| Topic | Quadros coverage | Fairhead coverage |
|---|---|---|
| PIO | Reference-style: registers, ISA, timing diagrams | SDK-style: how to write and run PIO programs in C |
| GPIO | Pad config, function select, hardware details | SDK calls, speed measurements, practical use |
| Multicore | Cortex dual-core model, SIO registers | SDK `multicore_launch_core1`, FreeRTOS tasks |
| USB | HID, TinyUSB, CDC — good detail | Not covered (Fairhead omits USB entirely) |
| WiFi | Not covered | Pico W chapter — cyw43, LwIP, web client/server |
| DMA | Full chapter | Not covered directly |
| Interrupts | Reset/interrupt hardware | Events, raw GPIO IRQ, race conditions in SDK |

**Recommendation**: Ingest Quadros first for hardware understanding, then Fairhead for SDK programming patterns.

---

## Related pages

- [[pio-architecture]]
- [[gpio-pinout]]
- [[rp6502-ria]]
- [[rp6502-ria-w]]
