---
type: concept
tags: [rp2350, hstx, dvi, tmds, vga, serial, output, pio]
related:
  - "[[rp6502-vga]]"
  - "[[pio-architecture]]"
  - "[[rp2040-clocks]]"
  - "[[dma-controller]]"
  - "[[rp2350]]"
sources:
  - "[[rp2350-datasheet]]"
created: 2026-04-17
updated: 2026-04-17
---

# HSTX — High-Speed Serial Transmit

**Summary**: HSTX is an RP2350-exclusive peripheral that streams data from the system clock domain to up to 8 GPIOs at a rate independent of `clk_sys`, with DDR output (2 bits per pin per cycle) — primarily used to generate DVI/TMDS video output on the [[rp6502-vga]] firmware.

---

## Overview

HSTX is output-only. It exists on one RP2350 instance (not replicated like PIO). Key characteristics:

- **GPIOs**: GPIO 12–19 are HSTX-capable on RP2350 (GPIO 0–7 on RP2350B variant).
- **Max clock**: `clk_hstx` up to 150 MHz (same as `clk_sys` max).
- **DDR outputs**: 2 bits per pin per HSTX clock cycle → max **300 Mb/s per pin**.
- **Timing balance**: all 8 GPIO output delays are matched within 300 ps — critical for pseudo-differential signalling (e.g. DVI TMDS).
- **DMA fed**: 8-entry × 32-bit async FIFO accessible from AHB FASTPERI arbiter; DMA can sustain one 32-bit write per `clk_sys` cycle.
- **DREQ**: `DREQ_HSTX` (52 on RP2350) paces DMA writes to the FIFO.
- **Register base**: `HSTX_CTRL_BASE = 0x400C0000` (accessed via async bus bridge; multiple cycles per access).
- **FIFO base**: separate AHB address for single-cycle DMA writes.

---

## Architecture

```
clk_sys domain             clk_hstx domain
─────────────────────────────────────────────────────────
DMA → Async FIFO → [Command Expander] → Output Shift Reg → Bit Crossbar → DDR Regs → GPIOs 12–19
       8×32b             (optional)        32b, shifts N×              /16          ×8
```

### Data FIFO

- 8-entry, 32-bit FIFO bridges `clk_sys` and `clk_hstx` clock domains.
- Single-cycle DMA write access via FASTPERI arbiter.
- If empty while HSTX is enabled, output stalls until data arrives.

### Output shift register

- 32 bits wide; shifts by `CSR.SHIFT` bits (right-rotate) per `clk_hstx` cycle.
- Refills from FIFO every `CSR.N_SHIFTS` cycles.
- Right-rotate by N is equivalent to left-shift by (32−N), enabling both directions.
- A product of `SHIFT × N_SHIFTS > 32` means some bits repeat — useful for repeating pixel data.

### Bit crossbar

Each of the 8 output pins (BIT0–BIT7) has a configuration register with:
- `SEL_P` (bits 4:0): which shift register bit to output in the first half of each HSTX cycle.
- `SEL_N` (bits 12:8): which shift register bit to output in the second half of each HSTX cycle.
- `INV` (bit 16): invert output (logical NOT) — used for differential pairs.
- `CLK` (bit 17): connect this pin to the clock generator instead of the shift register.

Set `SEL_N = SEL_P` to disable DDR (single-data-rate output).

### Clock generator

A programmable periodic signal output on any BITx pin with `CLK=1`:
- Period: 1–16 HSTX cycles (`CSR.CLKDIV`; 0 = 16).
- Initial phase: 0–15 half-cycles (`CSR.CLKPHASE`).
- Supports centre-aligned clocking (clock edge midway between data transitions).
- For differential clock: connect to two pins, set `INV=1` on one.
- The clock advances only on cycles where the shift register shifts.

**Centre-aligned clock settings** (common in DVI):
| Data rate | CLKDIV | CLKPHASE |
|---|---|---|
| SDR, rising edge active | 1 | 1 |
| SDR, falling edge active | 1 | 2 |
| DDR (both edges) | 2 | 1 |

---

## Command Expander

Enabled with `CSR.EXPAND_EN`. When enabled, the FIFO carries a mix of **commands** and **data words**. Each command is a 16-bit prefix in the lower 16 bits of a FIFO word:
- bits [15:12] — 4-bit opcode
- bits [11:0] — count (number of output shift register words to produce; 0 = infinite)

| Opcode | Name | Description |
|---|---|---|
| `0x0` | RAW | Pass data through to shift register without encoding |
| `0x1` | RAW_REPEAT | Circulate the same data word (useful for blanking fill) |
| `0x2` | TMDS | TMDS-encode data before shift register |
| `0x3` | TMDS_REPEAT | TMDS-encode and repeat (blanking control symbols) |
| `0xf` | NOP | No data, no output |

- RAW/TMDS commands pop one data word from FIFO per `ENC_N_SHIFTS` / `RAW_N_SHIFTS` output words.
- `x_REPEAT` commands never refill from FIFO — rotate the expansion shift register instead.
- The EXPAND_SHIFT register has separate `RAW_*` and `ENC_*` variants for each field.

**TMDS encoder** implements TMDS 8b/10b encoding (as used in DVI/HDMI). The encoder receives 8-bit pixel data and outputs 10-bit TMDS symbols. Three 10-bit symbols fit in 32 bits (3×10 = 30 used, 2 bits unused) — this is the standard HSTX TMDS packing for DVI.

---

## PIO-to-HSTX Coupled Mode

When `clk_hstx` is directly sourced from `clk_sys` (not just the same frequency — must select `clk_sys` as AUXSRC), PIO outputs 12–19 can be coupled into the HSTX bit crossbar:

- Set `CSR.COUPLED_MODE = 1`; select PIO instance with `CSR.COUPLED_SEL` (0–2).
- PIO outputs 12–19 appear at bit crossbar indices `SEL_P/SEL_N` 31:24, replacing the MSB of the shift register.
- The PIO program is not affected; it drives GPIOs normally. HSTX adds one extra `clk_sys` delay.
- Use case: PIO generates a high-speed clock; HSTX handles the data serialisation.

---

## DVI / TMDS Video Output

HSTX is the engine behind `clk_hstx`-driven DVI on the [[rp6502-vga]] firmware. Typical DVI TMDS configuration for 3 differential pairs + 1 clock pair:

```
N_SHIFTS = 5, SHIFT = 2   (5 shifts × 2 bits = 10 bits per 32-bit slot, for 3 × 10-bit symbols)

BIT0: SEL_P=0,  SEL_N=1,  INV=0   ← TMDS channel 0, positive
BIT1: SEL_P=0,  SEL_N=1,  INV=1   ← TMDS channel 0, negative
BIT2: SEL_P=10, SEL_N=11, INV=0   ← TMDS channel 1, positive
BIT3: SEL_P=10, SEL_N=11, INV=1   ← TMDS channel 1, negative
BIT4: SEL_P=20, SEL_N=21, INV=0   ← TMDS channel 2, positive
BIT5: SEL_P=20, SEL_N=21, INV=1   ← TMDS channel 2, negative
BIT6: CLK=1, INV=0                 ← pixel clock, positive
BIT7: CLK=1, INV=1                 ← pixel clock, negative
CLKDIV=5, CLKPHASE=1               ← 5 HSTX cycles per TMDS symbol, centre-aligned
```

Each 32-bit FIFO word carries 3 × 10-bit TMDS symbols: bits [9:0] = channel 0, [19:10] = channel 1, [29:20] = channel 2. DMA feeds pixels pre-encoded or the HSTX TMDS encoder handles pixel→TMDS in hardware.

---

## SDK / Register Reference

| Register | Offset | Description |
|---|---|---|
| `CSR` | 0x00 | Main control: `EN`, `EXPAND_EN`, `COUPLED_MODE`, `COUPLED_SEL`, `SHIFT`, `N_SHIFTS`, `CLKDIV`, `CLKPHASE` |
| `BIT0`–`BIT7` | 0x04–0x20 | Per-pin config: `SEL_P`, `SEL_N`, `INV`, `CLK` |
| `EXPAND_SHIFT` | 0x24 | Command expander shift/repeat: `RAW_N_SHIFTS`, `RAW_SHIFT`, `ENC_N_SHIFTS`, `ENC_SHIFT` |
| `EXPAND_TMDS` | 0x28 | TMDS encoder lane assignments |

> All control registers are accessed through an async bus bridge (several cycles per access). Use `HSTX_FIFO_BASE` for single-cycle DMA writes to the data FIFO.

---

## Related pages

- [[rp6502-vga]]
- [[pio-architecture]]
- [[rp2040-clocks]]
- [[dma-controller]]
- [[rp2350]]
