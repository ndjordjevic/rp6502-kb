---
type: topic
tags: [rp2040, pio, gpio, dma, usb, ingestion-plan]
related: [[pio-architecture]], [[gpio-pinout]], [[rp6502-ria]]
sources: []
created: 2026-04-16
updated: 2026-04-16
---

# Ingestion Plan: "Knowing the RP2040" (Quadros, 2022)

**Summary**: Chapter-by-chapter relevance assessment for `raw/pdfs/Knowing the RP2040 (Quadros).pdf` (253 pages). Only the chapters marked **INGEST** are worth processing; the rest add noise for the RP6502 knowledge base.

---

## Context

The RP6502-RIA firmware runs on an RP2350 (Pi Pico 2), not the RP2040 — but the peripherals are architecturally compatible (same PIO, GPIO, DMA, USB, SPI, UART models). This book remains highly relevant as background for understanding how the RIA drives the 65C02 bus.

Key RIA firmware features that map to this book:
- **PIO**: Five state machines implement PHI2 generation, 65C02 bus capture, and PIX bus transmit. Core of [[pio-architecture]].
- **GPIO**: All 65C02 bus signals (A0–A4, D0–D7, CS, RWB, PHI2, IRQB, RESB) are GPIO pins. See [[gpio-pinout]].
- **DMA**: Used for fast XRAM transfers to/from the 65C02 data bus.
- **Interrupts**: Central to the OS call dispatch loop (`api_task()`).
- **USB**: HID for keyboard/mouse/gamepads; VCP for USB-to-serial adapters (FTDI, CH34X, etc.).
- **UART**: Console at 115200 8N1 on GPIO 4–5.
- **SPI**: SD card storage.
- **Dual cores + SIO**: One core handles the PIO bus loop; the other runs the OS task dispatcher.

---

## Chapter Map

PDF pages use a +5 offset from the book's printed page numbers (5 pages of front matter before content page 1).

### INGEST — High Priority

| Chapter | Book pages | PDF pages | Why relevant |
|---|---|---|---|
| The RP2040 Architecture | 4–7 | 9–12 | Foundational overview: bus fabric, address map, PIO, peripherals |
| The Cortex-M0+ Processor Cores | 8–21 | 13–26 | Dual-core model, SIO for inter-core comms, instruction set, Systick |
| Reset, Interrupts and Power Control | 22–36 | 27–41 | Interrupt handling drives the RIA's `api_task()` OS call loop |
| Memory, Addresses and DMA | 37–62 | 42–67 | DMA used for XRAM bus transfers; address map needed to understand firmware |
| GPIO, Pad and PWM | 84–126 | 89–131 | All 65C02 bus signals are GPIO; pad configuration affects signal integrity |
| The Programmable I/O (PIO) | 127–153 | 132–158 | **Most critical chapter.** PIO is the entire 65C02 bus interface. |
| A Brief Introduction to the USB Controller | 195–227 | 200–232 | USB HID (keyboard/gamepad), USB VCP (serial adapters), USB CDC |

### INGEST — Medium Priority

| Chapter | Book pages | PDF pages | Why relevant |
|---|---|---|---|
| Clock Generation, Timer, Watchdog and RTC | 63–83 | 68–88 | RIA overclocks to 256 MHz; understanding PLL and clock tree helps |
| Asynchronous Serial Communication: the UARTs | 167–178 | 172–183 | RIA console UART on GPIO 4–5 at 115200 8N1 |
| Communication Using SPI | 179–188 | 184–193 | SD card storage |

### SKIP — Low or No Relevance

| Chapter | Book pages | PDF pages | Reason to skip |
|---|---|---|---|
| Introduction | 1–3 | 6–8 | Author context, no technical content for the wiki |
| Communication Using I²C | 154–166 | 159–171 | NFC on RIA uses USB (PN532), not I²C; I²C not used elsewhere |
| Analog Input: the ADC | 189–194 | 194–199 | RP6502 has no analog input use case |
| Conclusion | 228 | 233 | Wrap-up only |
| Appendix A – CMake Files for RP2040 Programs | 229–231 | 234–236 | Build toolchain detail; RP6502 firmware uses its own CMake setup |
| Appendix B – Using stdio | 232–236 | 237–241 | SDK stdio abstraction; not relevant to RP6502 firmware internals |
| Appendix C – Debugging Using SWD | 237–253 | 242–253 | Useful for development but out of scope for the knowledge base |

---

## Suggested Ingest Order

- [x] **The RP2040 Architecture** (PDF 9–12) — orientation pass, fast
- [x] **The Programmable I/O (PIO)** (PDF 132–158) — most impactful for [[pio-architecture]]
- [x] **GPIO, Pad and PWM** (PDF 89–131) — fills gaps in [[gpio-pinout]]
- [x] **Reset, Interrupts and Power Control** (PDF 27–41) — fills gaps in OS call dispatch
- [x] **The Cortex-M0+ Processor Cores** (PDF 13–26) — dual-core / SIO context
- [x] **Memory, Addresses and DMA** (PDF 42–67) — DMA details for XRAM
- [ ] **A Brief Introduction to the USB Controller** (PDF 200–232) — USB HID/VCP details
- [ ] **Clock Generation, Timer, Watchdog and RTC** (PDF 68–88) — overclock context
- [ ] **Asynchronous Serial Communication: the UARTs** (PDF 172–183) — console UART
- [ ] **Communication Using SPI** (PDF 184–193) — SD card

Total to ingest: ~183 PDF pages out of 253 (skip ~70 pages).
**Delete this file when all boxes are checked.**

---

## Related pages

- [[pio-architecture]]
- [[gpio-pinout]]
- [[rp6502-ria]]
