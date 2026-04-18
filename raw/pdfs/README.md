# PDFs — RP6502

Reference books and datasheets relevant to the RP6502 Picocomputer project.

## Naming convention

Free-form — files are named as downloaded or supplied. Add one row per file to the ## Files table below.

## Files

| File | Brief context |
|------|---------------|
| `6502 Assembly Language Subroutines Lance Leventhal 1982.pdf` | Companion to Leventhal's main 6502 book. A library of ready-to-use subroutines (math, string, I/O) with explanations — practical reference for building 6502 programs. |
| `6502 Assembly Language Programming (2nd Edition) Lance Leventhal 1986.pdf` | The definitive 6502 assembly reference. 2nd edition (1986) — covers all opcodes, addressing modes, and common programming patterns. Platform-agnostic. |
| `Assembly Lines Complete Rodger Wagner 2014.pdf` | Compilation of Roger Wagner's classic *Assembly Lines* column from Softalk magazine. Progressive, practical 6502 tutorial. 2014 edition is the newest collected form. |
| `Knowing the RP2040 (Quadros).pdf` | Deep-dive technical guide to the RP2040 chip — PIO, interrupts, DMA, clocks. Relevant to understanding the RIA firmware that runs on the RP2040. |
| `Programming the 6502 Rodnay Zaks 1983.pdf` | Thorough foundational 6502 book by Zaks (Sybex). Covers architecture, instruction set, and practical programming techniques. High-quality scan (71MB). |
| `Programming The Raspberry Pi Pico_W In C, Third Edition_nodrm.pdf` | Official-style guide to Pico/Pico W C SDK — GPIO, PIO, multicore, Wi-Fi. Useful context for RP6502 RIA firmware development. |
| `RP-008373-DS-2-rp2350-datasheet.pdf` | Official RP2350 datasheet — the chip used on Pi Pico 2 / RP6502-VGA board. Covers cores, peripherals, PIO, and pinout. |
| `RP-009085-KB-1-raspberry-pi-pico-c-sdk (1).pdf` | Official Raspberry Pi Pico C/C++ SDK reference. API docs for hardware access, PIO programming, and multicore — directly relevant to RIA firmware. |
| `w65c02s.pdf` | WDC W65C02S datasheet — the CPU at the heart of the RP6502 Picocomputer. Covers instruction set, timing, pinout, and electrical specs. |
| `wdc_w65c22s_mar_2004.pdf` | WDC W65C22S VIA datasheet (March 2004, 46 pp.) — authoritative reference for the VIA used on RP6502 U5. Covers register functions, handshake control, timer timing, shift register modes, caveats (IRQB totem-pole, reset exceptions), AC/DC characteristics at 8 MHz. |
| `2023-06-07-rp6502.pdf` | Official RP6502 schematic (Rev A, electrically identical to Rev B). Single-page KiCad export: all 8 ICs, glue logic, VGA DAC, audio filter, connector pinouts. Also available as `2026-01-26-rp6502.pdf` (Rev B, minor cosmetic change). |
