---
type: topic
tags: [rp2350, pio, gpio, clocks, dma, spi, uart, usb, sio, hstx, errata, ingestion-plan]
related: [[pio-architecture]], [[gpio-pinout]], [[dual-core-sio]], [[rp2040-clocks]], [[dma-controller]], [[usb-controller]], [[rp2040-spi]], [[rp2040-uart]], [[rp6502-vga]], [[known-issues]]
sources: []
created: 2026-04-17
updated: 2026-04-17
---

# Ingestion Plan: RP2350 Datasheet (RP-008373-DS-2)

**Summary**: Chapter-by-chapter relevance assessment for `raw/pdfs/RP-008373-DS-2-rp2350-datasheet.pdf` (1378 pages, build 2025-07-29). The RP2350 powers both the Pi Pico 2 (VGA firmware) and the Pi Pico 2 W (RIA-W firmware); key sections are the SIO TMDS encoder, 3-block PIO, GPIO function table, clocks, and all "Changes from RP2040" subsections to verify and extend the nine `rp2040-*.md` concept pages.

---

## Context

The RP2040 was the focus of prior sources (Quadros, Fairhead). This datasheet covers the RP2350, which is the successor chip and the MCU in the Pi Pico 2. It is directly relevant to the RP6502 in two ways:

1. **VGA firmware (Pi Pico 2)**: The VGA board uses RP2350. Its firmware generates VGA/DVI signals using PIO and likely the HSTX peripheral. Understanding RP2350-specific features — especially the TMDS encoder in SIO and the HSTX high-speed serial peripheral — is essential for understanding how VGA output works.

2. **Verifying the `rp2040-*.md` pages**: Nine concept pages were written from the Quadros RP2040 book. Many claims need checking: does the RP2350 change the PIO instruction set? Are clock sources the same? Does the GPIO function table match? The "Changes from RP2040" subsections throughout this datasheet are the authoritative source for these deltas.

Key RP2350-specific features not present in RP2040 (from Chapter 1 intro scan):
- **3 PIO blocks** (PIO0, PIO1, PIO2) = **12 state machines** total vs 8 in RP2040
- **TMDS encoder** in SIO (§3.1.9) — hardware TMDS encoding for DVI/HDMI output, used in VGA firmware
- **HSTX** peripheral (§12.11) — high-speed serial transmit, alternative to PIO for video output
- **Cortex-M33** (ARMv8-M with FPU, DSP, MPU, TrustZone) vs Cortex-M0+ in RP2040
- Optional **Hazard3 RISC-V** processor — dynamically swappable with Cortex-M33
- **520 KB SRAM** in 10 independent banks vs 264 KB in RP2040
- **LPOSC** low-power oscillator (new clock source)
- PIO **v1 instruction encoding** (RP2350) vs v0 (RP2040) — affects PIOASM assembler output
- **Boot signing** and encrypted boot via OTP
- Errata appendix with 28+ known silicon issues

The document is 1378 pages. We read ~260 pages across 14 sessions. Register-list sections ("List of registers") are skipped throughout unless the specific register content is relevant; they are identified in each session below.

---

## Chapter Map

### INGEST — High Priority

| Section | PDF pages | Why relevant |
|---|---|---|
| Ch.1 Introduction + Ch.2 §2.2 Address map | 13–34 | Chip overview, RP2350A/B variants, GPIO function tables (Banks 0+1) — authoritative pinout; verify [[gpio-pinout]] and [[memory-map]] against RP2350 address map |
| §3.1 SIO programmer's model | 36–53 | CPUID, GPIO control, hardware spinlocks, inter-proc FIFOs (mailboxes), doorbells, TMDS encoder (§3.1.9 p.44!), interpolator — TMDS encoder is entirely new, directly used in VGA firmware; extends [[dual-core-sio]] |
| §8.1 Clocks overview | 513–528 | Clock sources, generators, frequency counter, resus, programmer's model, §8.1.1 changes between RP2350 revisions; verify [[rp2040-clocks]] accuracy and add RP2350 specifics |
| §8.2 XOSC + §8.3 ROSC + §8.4 LPOSC + §8.5 Tick generators + §8.6 PLL | 554–583 (skip register lists at pp.559-560, 565-568, 570-574, 583; ~19p content) | Each subsection has "Changes from RP2040"; LPOSC is new; extends [[rp2040-clocks]] |
| Ch.9 GPIO §9.1–9.10 | 587–603 | §9.2 Changes from RP2040, §9.4 function select (12-function model vs 9 in RP2040), §9.5 interrupts, §9.6 pads; register list §9.11 starts at p.604; verify and update [[gpio-pinout]] |
| Ch.11 PIO §11.1–11.4.7 | 876–895 | Overview, §11.1.1 changes from RP2040 (3 PIO blocks, v1 encoding, IRQ changes), programmer's model, pioasm directives/pseudo-instructions, instruction set pt.1 (JMP through PULL) |
| Ch.11 PIO §11.4.8–11.5 | 896–914 | Instruction set pt.2 (MOV to/from RX p.896-897, MOV p.898, IRQ p.900, SET p.901) + all §11.5 functional details (side-set, wrapping, FIFO joining, autopush/pull, clock dividers, GPIO mapping, EXEC'd instructions) |
| Ch.11 PIO §11.6 Examples (selective) | 915–938 | Duplex SPI (p.915), WS2812 LEDs (p.919), UART TX (p.921), UART RX (p.923) — structural patterns applicable to VGA PIO programs; skim Manchester/BMC/I2C/PWM/Addition (pp.926-938) |
| §12.1 UART §12.1.1–12.1.7 | 961–971 | §12.1.1 overview, §12.1.2 functional description, §12.1.3 operation, §12.1.7 programmer's model; note any RP2350 changes; verify [[rp2040-uart]]; register list §12.1.8 starts at p.972 |
| §12.3 SPI §12.3.1–12.3.4 | 1046–1059 | §12.3.1 changes from RP2040, §12.3.2 overview, §12.3.3 functional description, §12.3.4 operation; verify [[rp2040-spi]]; register list §12.3.5 starts at p.1060 |
| §12.6 DMA §12.6.1–12.6.9 | 1094–1111 | §12.6.1 changes from RP2040, §12.6.2 configuring channels, §12.6.3 triggering, §12.6.4 DREQ, §12.6.5 interrupts, §12.6.8 additional features, §12.6.9 example use cases; verify [[dma-controller]]; register list §12.6.10 starts at p.1112 |
| §12.7 USB §12.7.1–12.7.4 | 1141–1158 | §12.7.2 changes from RP2040, §12.7.3 architecture, §12.7.4 programmer's model; verify [[usb-controller]]; register list §12.7.5 starts at p.1159 |
| §12.11 HSTX §12.11.1–12.11.7 | 1202–1211 | Data FIFO, output shift register, bit crossbar, clock generator, command expander, PIO-to-HSTX coupling, control registers — entirely new RP2350 peripheral, likely used in VGA firmware for high-speed serial video output; NEW concept page; §12.11.8 FIFO register list at p.1212 |
| Appendix C: Hardware revision history + Appendix E: Errata | 1354–1376 | RP2350 A2→A3→A4 hardware changes; errata RP2350-E1 through E28+ (silicon bugs); update [[known-issues]] |

### INGEST — Medium Priority

| Section | PDF pages | Why relevant |
|---|---|---|
| Ch.2 §2.1 Bus fabric + §2.3 Atomic register access | 24–29 | Atomic set/clear/XOR aliases (used in SDK `hw_set_alias`); verify existing wiki claims about atomic access; adds 6 pages only |
| §3.2 Interrupts overview | 82–83 | Brief 2-page overview; verify [[ria-registers]] interrupt model |
| §4.2 SRAM + §4.4 XIP | 337–352 | 520KB SRAM in 10 banks, XIP cache; verify/update [[rp2040-memory]] and [[memory-map]] |
| §12.8 System timers | 1182–1188 | Overview, counter, alarms, programmer's model; verify timing claims in existing pages |

### SKIP — Low or No Relevance

| Section | PDF pages | Reason to skip |
|---|---|---|
| Ch.2 §2.1.2 Bus security filtering | 25 | RP2350 TrustZone bus security; not relevant to RP6502 firmware concepts |
| Ch.2 §2.1.5–2.1.7 (Narrow IO, Global Exclusive Monitor, Bus perf counters) | 27–30 | Low-level bus features; not relevant |
| §3.1.7 List of registers (SIO) | 54–81 | 27 pages of SIO register tables; concepts covered in programmer's model |
| §3.3–3.5 Interrupts, Events, Debug | 82–93 | Hardware debug ports, SWD — not needed for firmware concepts |
| §3.6 Cortex-M33 coprocessors (GPIOC, DCP, RCP) | 100–122 | Security coprocessors; DCP/RCP not used in RP6502 firmware |
| §3.7 Cortex-M33 programmer's model | 123–232 | Full ARMv8-M register reference (109 pages); not needed |
| §3.8 Hazard3 RISC-V processor | 233–334 | Full RISC-V ISA reference; RP6502 firmware uses Arm cores only |
| §3.9 Arm/RISC-V architecture switching | 335–336 | Dynamic switching mechanism; not used in RP6502 firmware |
| Ch.4 §4.1 ROM + §4.3 Boot RAM + §4.5 OTP | 337–352 | Boot infrastructure; not needed for wiki concepts |
| Ch.5 Bootrom | 353–440 | Boot sequence, UF2, PICOBOOT, UART boot — out of scope for hardware-concept wiki |
| Ch.6 Power | 441–491 | Power management, DORMANT/SLEEP states; not used in RP6502 firmware |
| Ch.7 Resets | 494–512 | Reset sequences; §7.2 "Changes from RP2040" (2p) is medium priority but very brief |
| §8.1.7 List of registers (Clocks) | 529–553 | 25 pages of clock register tables; skip |
| §8.2–8.6 List of registers sub-sections | various | Skip register list sub-sections within each XOSC/ROSC/PLL section |
| Ch.9 §9.11 List of registers (GPIO) | 604–815 | 212 pages of GPIO IO/Pad register tables; skip entirely |
| Ch.10 Security | 816–875 | Secure boot, TrustZone, OTP key storage, glitch detector — RP6502 firmware does not use security features |
| §11.7 List of registers (PIO) | 939–960 | 22 pages of PIO state-machine register tables; skip |
| §12.2 I2C | 983–1045 | I2C not used in RIA or VGA firmware |
| §12.4 ADC and Temperature Sensor | 1066–1075 | RP6502 has no analog input path |
| §12.5 PWM | 1076–1093 | PWM not used in RIA/VGA bus interface |
| §12.3 List of registers (SPI) | 1060–1065 | Skip register table |
| §12.6 List of registers (DMA) | 1112–1140 | 29 pages of DMA register tables; skip |
| §12.7 List of registers (USB) | 1159–1181 | 23 pages of USB register tables; skip |
| §12.9 Watchdog | 1193–1196 | Not critical for RP6502 firmware concepts |
| §12.10 AON timer | 1197–1201 | RP2350 always-on timer; not used in VGA firmware |
| §12.12 TRNG | 1212–1220 | True random number generator; not used |
| §12.13 SHA-256 accelerator | 1221–1225 | RP2350 security hardware; not used |
| §12.14 QSPI memory interface (QMI) | 1226–1267 | QSPI flash controller; bootloader concern |
| §12.15 System Control Registers | 1249–1267 | Low-level SoC config; not needed |
| Ch.13 OTP | 1268–1326 | One-time programmable storage; not relevant |
| Ch.14 Electrical and mechanical | 1327–1348 | Physical package specs; not needed for wiki |
| Appendix A: Register field types | 1349–1350 | Format reference; not needed |
| Appendix B: Units | 1351–1353 | Reference only |
| Appendix H: Documentation release history | 1377–1378 | Not relevant |

---

## Suggested Ingest Order

Sessions follow natural dependency order: chip overview first, then SIO (TMDS encoder is high urgency), then peripheral "Changes from RP2040" passes to verify existing pages, then new-in-RP2350 features (HSTX), then errata.

- [ ] **S1** — Introduction + Address map (PDF 13–34, 22p): Ch.1 chip features, RP2350 device family table, pinout, GPIO function tables Bank 0 + Bank 1 (pp.17-21), Ch.2 §2.1 bus fabric overview + §2.2 address map
- [ ] **S2** — SIO programmer's model (PDF 36–53, 18p): CPUID, GPIO control, spinlocks, inter-proc FIFOs, doorbells, integer divider, TMDS encoder (§3.1.9 p.44), interpolator; register list §3.1.11 at p.54 (skip)
- [ ] **S3** — Clocks overview (PDF 513–528, 16p): §8.1 overview, changes between RP2350 revisions, clock sources, generators, resus, programmer's model; register list §8.1.7 at p.529 (skip)
- [ ] **S4** — XOSC / ROSC / LPOSC / Tick / PLL (PDF 554–583, 30p inclusive / ~19p content): §8.2-8.6 with focus on "Changes from RP2040" in each section; skip register lists at pp.559-560, 565-568, 570-574, 583
- [ ] **S5** — GPIO (PDF 587–603, 17p): §9.1-9.10; focus on §9.2 changes from RP2040, §9.4 function select (F0-F11 table, pp.589-593), §9.5 interrupts, §9.6 pads (incl. bus keeper mode), §9.8 SIO control, §9.9 GPIO coprocessor port; register list §9.11 at pp.604-815 (skip)
- [ ] **S6** — PIO pt.1 (PDF 876–895, 20p): §11.1 overview + §11.1.1 changes from RP2040 + §11.2 programmer's model + §11.3 pioasm + §11.4.1-11.4.7 instruction set pt.1 (Summary, JMP, WAIT, IN, OUT, PUSH, PULL)
- [ ] **S7** — PIO pt.2 (PDF 896–914, 19p): §11.4.8-11.4.12 instruction set pt.2 (MOV to RX, MOV from RX, MOV, IRQ, SET) + §11.5 functional details (side-set, program wrapping, FIFO joining, autopush/pull, clock dividers, GPIO mapping, Forced and EXEC'd instructions)
- [ ] **S8** — PIO examples (PDF 915–938, 24p): §11.6.1 Duplex SPI (p.915) + §11.6.2 WS2812 LEDs (p.919) + §11.6.3 UART TX (p.921) + §11.6.4 UART RX (p.923) priority; skim §11.6.5-11.6.10 (Manchester, BMC, I2C, PWM, Addition)
- [ ] **S9** — UART (PDF 961–971, 11p): §12.1.1 overview, §12.1.2 functional description, §12.1.3 operation, §12.1.4 hardware flow control, §12.1.5 DMA interface, §12.1.6 interrupts, §12.1.7 programmer's model; register list §12.1.8 at p.972 (skip)
- [ ] **S10** — SPI (PDF 1046–1059, 14p): §12.3.1 changes from RP2040, §12.3.2 overview, §12.3.3 functional description, §12.3.4 operation; register list §12.3.5 at p.1060 (skip)
- [ ] **S11** — DMA (PDF 1094–1111, 18p): §12.6.1-12.6.9 changes from RP2040, channel config, DREQ, interrupts, bus error handling, additional features, example use cases; register list §12.6.10 at p.1112 (skip)
- [ ] **S12** — USB (PDF 1141–1158, 18p): §12.7.1 overview, §12.7.2 changes from RP2040, §12.7.3 architecture, §12.7.4 programmer's model; register list §12.7.5 at p.1159 (skip)
- [ ] **S13** — HSTX (PDF 1202–1211, 10p): §12.11 complete readable section — data FIFO, output shift register, bit crossbar, clock generator, command expander, PIO-to-HSTX coupled mode, list of control registers; FIFO register list §12.11.8 at p.1212 (skip)
- [ ] **S14** — Errata + revision history (PDF 1354–1376, 23p): Appendix C RP2350 A2/A3/A4 hardware changes + Appendix E all errata entries (RP2350-E1 through E28)

**Total: ~1200 PDF pages across ingest range; ~260 pages actually read (register lists skipped); 14 sessions.**
**Delete this file when all boxes above are checked.**

---

## Wiki Pages Created / Updated

| Session | New pages | Updated pages |
|---|---|---|
| S1 | `wiki/entities/rp2350.md` | `wiki/concepts/memory-map.md`, `wiki/concepts/gpio-pinout.md` (function table) |
| S2 | — | `wiki/concepts/dual-core-sio.md` (TMDS encoder, doorbells, RP2350 FIFOs) |
| S3–S4 | — | `wiki/concepts/rp2040-clocks.md` (rename/expand to cover RP2350; add LPOSC, RP2350 PLL changes) |
| S5 | — | `wiki/concepts/gpio-pinout.md` (RP2350 function select F0-F11, pad changes) |
| S6–S8 | — | `wiki/concepts/pio-architecture.md` (3rd PIO block, v1 encoding, RP2350 PIO examples) |
| S9 | — | `wiki/concepts/rp2040-uart.md` |
| S10 | — | `wiki/concepts/rp2040-spi.md` |
| S11 | — | `wiki/concepts/dma-controller.md` |
| S12 | — | `wiki/concepts/usb-controller.md` |
| S13 | `wiki/concepts/hstx.md` | `wiki/entities/rp6502-vga.md` (VGA output mechanism via HSTX) |
| S14 | — | `wiki/topics/known-issues.md` (RP2350 errata entries) |
| All | `wiki/sources/rp2350-datasheet.md` (created in S1) | `wiki/overview.md`, `wiki/index.md`, `wiki/log.md` |

---

## Comparison With Prior Sources

| Topic | Quadros (RP2040) | Fairhead (RP2040/RP2350) | RP2350 Datasheet (this) |
|---|---|---|---|
| PIO | Hardware ISA, registers, timing (RP2040 only) | SDK programming examples | **Authoritative RP2350 v1 encoding, 3-block changes, EXEC'd instruction details** |
| GPIO | Pad config, function table RP2040 | SDK calls, drive strength | **F0-F11 function table, GPIO coprocessor port, RP2350 bus keeper mode** |
| Clocks | PLL arithmetic, divider registers (RP2040) | Brief SDK examples | **LPOSC, changes between RP2350 revisions, updated PLL parameters** |
| DMA | Full RP2040 chapter | Not covered | **RP2350 DMA changes from RP2040, DREQ updates** |
| USB | TinyUSB/CDC RP2040 | Not covered | **RP2350 USB changes from RP2040** |
| SIO | RP2040 CPUID, spinlocks, FIFOs | SDK multicore launch | **TMDS encoder (new!), doorbells (new!), GPIO coprocessor** |
| HSTX | Not present in RP2040 | Not covered | **Complete new peripheral — VGA/DVI output mechanism** |
| Errata | Not applicable | Not covered | **RP2350-E1 through E28+ known silicon bugs** |

---

## RP2350 vs RP2040 — Quick Reference

Key differences of direct relevance to RP6502 wiki pages:

| Feature | RP2040 | RP2350 |
|---|---|---|
| CPU | 2× Cortex-M0+ @ 133 MHz | 2× Cortex-M33 (or Hazard3 RISC-V) @ 150 MHz |
| SRAM | 264 KB (6 banks) | 520 KB (10 banks) |
| PIO blocks | 2 (PIO0, PIO1) | 3 (PIO0, PIO1, PIO2) |
| PIO state machines | 8 | 12 |
| PIO ISA | v0 | v1 (new MOV-to/from-RX instructions) |
| SIO TMDS encoder | No | Yes (§3.1.9) |
| HSTX peripheral | No | Yes (§12.11) |
| Low-power oscillator | No | LPOSC (§8.4) |
| GPIO functions | F0–F8 (9 functions) | F0–F11 (12 functions) |
| Boot security | No | Signed/encrypted boot, OTP keys |
| Max clock | 133 MHz | 150 MHz (200 MHz with RP2350 B2+) |

---

## Related pages

- [[pio-architecture]]
- [[gpio-pinout]]
- [[dual-core-sio]]
- [[rp2040-clocks]]
- [[dma-controller]]
- [[usb-controller]]
- [[rp2040-spi]]
- [[rp2040-uart]]
- [[rp6502-vga]]
- [[known-issues]]
