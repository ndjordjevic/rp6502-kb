---
type: concept
tags: [rp6502, memory, address-space, rp2350]
related: [[w65c02s]], [[w65c22s]], [[rp6502-ria]], [[xram]], [[rp2350]], [[rp2040-memory]], [[pio-architecture]], [[hstx]]
sources: [[rp6502-os-docs]], [[rp2350-datasheet]]
created: 2026-04-15
updated: 2026-04-17
---

# Memory Map

**Summary**: How the 6502's address space and the RIA's extended RAM are arranged on the Picocomputer.

---

## 6502 address space (16-bit, byte-addressable)

| Address | Size | Content |
| --- | --- | --- |
| `$0000-$FEFF` | 63.75 K | RAM. Nothing reserved — zero page is yours. |
| `$FF00-$FFCF` | 208 B | **Unassigned.** For user expansion (extra VIAs, sound chips, etc.). |
| `$FFD0-$FFDF` | 16 B | [[w65c22s]] VIA registers |
| `$FFE0-$FFFF` | 32 B | [[rp6502-ria]] registers |

Notes:
- There is **no ROM** on the 6502 bus. Reset vector at `$FFFC/D` is in RAM and must be set up before reset goes high.
- The RIA's 32 registers include `RIA_OP`, `RIA_BUSY`, `RIA_A`, `RIA_X`, `RIA_SREG`, `RIA_ERRNO`, `RIA_XSTACK`, `RIA_SPIN`, `RIA_RW0`/`RIA_RW1`, etc. — the entry points for [[rp6502-abi]] OS calls and [[xram]] access.

## Extended address space (XRAM, RIA-side)

| Address | Size | Content |
| --- | --- | --- |
| `$10000-$1FFFF` | 64 K | **XRAM** — see [[xram]] |

XRAM is **not** mapped into the 6502's normal address space. The 6502 reaches it through the `RIA_RW0` / `RIA_RW1` register windows (auto-incrementing pointers) or via OS bulk-XRAM operations.

## Expansion example

The unassigned `$FF00-$FFCF` window is the place to wire your own chip selects. The OS docs sketch:

```
VIA0 at $FFD0  (mandatory — already there)
VIA1 at $FFC0
SID0 at $FF00
SID1 at $FF20
```

## Related pages

- [[w65c02s]] · [[w65c22s]] · [[rp6502-ria]] · [[xram]] · [[rp6502-abi]]
- [[rp2040-memory]] · [[rp2350]] — RP2350 peripheral address map

---

## RP2350 peripheral address map

The RP2350 (the MCU running the RIA and VGA firmware) has a separate 32-bit address space. Key peripheral base addresses from the datasheet:

### AHB peripherals (fast, 1-cycle access)

| Peripheral | Base address | Notes |
|---|---|---|
| DMA | `0x50000000` | 16-channel DMA controller (RP2350; RP2040 had 12) |
| USB | `0x50100000` | USB 1.1 DPRAM + registers |
| PIO0 | `0x50200000` | [[pio-architecture\|PIO]] block 0 (4 SMs) |
| PIO1 | `0x50300000` | PIO block 1 (4 SMs) |
| PIO2 | `0x50400000` | PIO block 2 (4 SMs) — RP2350 only |
| HSTX FIFO | `0x50600000` | [[hstx\|High-speed transmit]] data FIFO |

### APB peripherals (min 3 cycles read, 4 write)

| Peripheral | Base address |
|---|---|
| SYSINFO | `0x40000000` |
| CLOCKS | `0x40010000` |
| IO_BANK0 | `0x40028000` |
| PADS_BANK0 | `0x40038000` |
| XOSC | `0x40048000` |
| PLL_SYS | `0x40050000` |
| PLL_USB | `0x40058000` |
| UART0 / UART1 | `0x40070000` / `0x40078000` |
| SPI0 / SPI1 | `0x40080000` / `0x40088000` |
| TIMER0 / TIMER1 | `0x400b0000` / `0x400b8000` |
| HSTX_CTRL | `0x400c0000` |
| ROSC | `0x400e8000` |
| TICKS | `0x40108000` |

### Memory and core-local

| Region | Base address | Notes |
|---|---|---|
| ROM | `0x00000000` | 32 KB boot ROM |
| XIP (flash) | `0x10000000` | Execute-in-place, up to 64 MB |
| SRAM | `0x20000000` | 520 KB; SRAM0–7 word-striped, SRAM8–9 non-striped |
| SIO | `0xd0000000` | Single-Cycle IO; GPIO, spinlocks, FIFOs, TMDS |

All peripheral blocks support **atomic register access** via address aliases: `+0x1000` (XOR), `+0x2000` (set), `+0x3000` (clear). See [[rp2350]] for details.

Full RP2350 SRAM details in [[rp2040-memory]]; full address map in [[rp2350-datasheet]].
