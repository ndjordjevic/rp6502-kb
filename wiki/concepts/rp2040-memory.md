---
type: concept
tags: [rp2040, rp2350, memory, sram, flash, rom, xip, address-map]
related: [[dma-controller]], [[pio-architecture]], [[rp6502-ria]], [[xram]], [[rp2350]]
sources: [[quadros-rp2040]], [[rp2350-datasheet]]
created: 2026-04-16
updated: 2026-04-17
---

# RP2040 Memory and Address Map

**Summary**: The RP2040 has three memory types (ROM, SRAM, Flash) and a fixed address map; the SRAM banking model is critical for understanding DMA and multi-core performance.

---

## Memory types

| Type | Size | Address | Notes |
|---|---|---|---|
| ROM | 16 kB | `0x00000000` | Read-only; programmed at manufacture |
| SRAM | 264 kB | `0x20000000` | Six physical banks; main working memory |
| Flash | up to 16 MB | `0x10000000` | External QSPI; accessed via XIP hardware |

### ROM

The ROM contains two things:
- **Boot code**: executed on every reset; loads firmware from Flash or enters device mode.
- **Utility functions**: fast floating-point (M0+ has no FPU), bit counting/manipulation, memory fill/copy. These are called at runtime by the SDK; applications get float support "for free" through ROM dispatch tables.

Three startup paths:
1. **Normal**: ROM loads and runs code from Flash.
2. **Device mode** (Flash CSn pulled low, e.g. BOOTSEL button): RP2040 appears as USB Mass Storage; drag-and-drop `.uf2` to program Flash.
3. **Watchdog boot-to-RAM**: Watchdog scratch register redirects boot to a RAM address (used for OTA-style updates).

### SRAM

264 kB total, physically divided into **6 banks** — four 64 kB banks (SRAM0–3) and two 4 kB banks (SRAM4–5). Banking matters for performance: multiple bus masters (CPU core 0, CPU core 1, DMA read, DMA write) can access different banks simultaneously without stalling.

Two address views for the main four banks:

**Striped (interleaved) — `0x20000000`–`0x2003FFFF`**
Sequential words are distributed round-robin across banks:
- `0x20000000` → word 0 from bank 0
- `0x20000001` → word 0 from bank 1
- `0x20000002` → word 0 from bank 2
- `0x20000003` → word 0 from bank 3
- `0x20000004` → word 1 from bank 0
- …

This is the default linker layout. Sequential memory access is spread across banks, maximising the chance that DMA and a CPU core hit different banks.

**Non-striped (per-bank) — `0x21000000`–`0x2103FFFF`**
Each bank is a contiguous 64 kB region:
- `0x21000000` → SRAM0 (bank 0)
- `0x21010000` → SRAM1 (bank 1)
- `0x21020000` → SRAM2 (bank 2)
- `0x21030000` → SRAM3 (bank 3)

The small banks are always non-striped:
- `0x20040000` → SRAM4 (4 kB)
- `0x20041000` → SRAM5 (4 kB)

> **Rule of thumb**: for most code, use striped SRAM as a single 264 kB region — the SDK linker does this by default. Banking only matters when squeezing maximum throughput from simultaneous DMA + CPU access.

**Special RAM blocks** (rarely used but occasionally useful):

| Region | Size | Address | Condition |
|---|---|---|---|
| XIP SRAM | 16 kB | `0x15000000` | Available only if XIP cache is disabled |
| USB DPRAM | 4 kB | `0x50100000` | Available only if USB is not in use |

### Flash (XIP)

The RP2040 has no internal Flash. External Flash (up to 16 MB) is connected via **QSPI** (Quad SPI — 4 bits per clock pulse; a full 32-bit word takes 8 clocks).

Access is transparent through the **XIP (Execute-In-Place)** hardware at `0x10000000`:
- Reads trigger a cache lookup; cache miss generates a QSPI serial fetch.
- The 16 kB XIP cache keeps hot code in fast SRAM-speed storage.
- For data that will be DMA'd frequently, **copy it to SRAM first** — DMA from Flash causes cache thrash and is slower than DMA from SRAM.

XIP address sub-regions:

| Address | Name | Notes |
|---|---|---|
| `0x10000000` | `XIP_BASE` | Normal cached access |
| `0x11000000` | `XIP_NOALLOC_BASE` | Hit uses cache; miss does not allocate cache line |
| `0x12000000` | `XIP_NOCACHE_BASE` | Bypasses cache entirely |
| `0x13000000` | `XIP_NOCACHE_NOALLOC_BASE` | Bypass + no alloc |
| `0x14000000` | `XIP_CTRL_BASE` | XIP control registers |
| `0x15000000` | `XIP_SRAM_BASE` | XIP cache as RAM (if cache disabled) |
| `0x18000000` | `XIP_SSI_BASE` | QSPI SSI registers |

---

## Full address map

### Top-level

| Address | Resource |
|---|---|
| `0x00000000` | ROM |
| `0x10000000` | XIP (Flash) |
| `0x20000000` | SRAM |
| `0x40000000` | APB Peripherals |
| `0x50000000` | AHB-Lite Peripherals |
| `0xD0000000` | IOPORT Registers (SIO) |
| `0xE0000000` | Cortex-M0+ internal registers |

### APB Peripherals (`0x40000000`)

| Name | Address |
|---|---|
| `SYSINFO_BASE` | `0x40000000` |
| `SYSCFG_BASE` | `0x40004000` |
| `CLOCKS_BASE` | `0x40008000` |
| `RESETS_BASE` | `0x4000C000` |
| `PSM_BASE` | `0x40010000` |
| `IO_BANK0_BASE` | `0x40014000` |
| `IO_QSPI_BASE` | `0x40018000` |
| `PADS_BANK0_BASE` | `0x4001C000` |
| `PADS_QSPI_BASE` | `0x40020000` |
| `XOSC_BASE` | `0x40024000` |
| `PLL_SYS_BASE` | `0x40028000` |
| `PLL_USB_BASE` | `0x4002C000` |
| `BUSCTRL_BASE` | `0x40030000` |
| `UART0_BASE` | `0x40034000` |
| `UART1_BASE` | `0x40038000` |
| `SPI0_BASE` | `0x4003C000` |
| `SPI1_BASE` | `0x40040000` |
| `I2C0_BASE` | `0x40044000` |
| `I2C1_BASE` | `0x40048000` |
| `ADC_BASE` | `0x4004C000` |
| `PWM_BASE` | `0x40050000` |
| `TIMER_BASE` | `0x40054000` |
| `WATCHDOG_BASE` | `0x40058000` |
| `RTC_BASE` | `0x4005C000` |
| `ROSC_BASE` | `0x40060000` |
| `VREG_AND_CHIP_RESET_BASE` | `0x40064000` |
| `TBMAN_BASE` | `0x4006C000` |

### AHB-Lite Peripherals (`0x50000000`)

| Name | Address |
|---|---|
| `DMA_BASE` | `0x50000000` |
| `USBCTRL_BASE` / `USBCTRL_DPRAM_BASE` | `0x50100000` |
| `USBCTRL_REGS_BASE` | `0x50110000` |
| `PIO0_BASE` | `0x50200000` |
| `PIO1_BASE` | `0x50300000` |
| `XIP_AUX_BASE` | `0x50400000` |

> PIO and DMA are on the AHB-Lite bus (faster, higher bandwidth than APB). This is why PIO FIFOs connected to DMA can saturate system bandwidth.

---

## RIA firmware relevance

- The **striped SRAM layout** lets DMA (filling XRAM from PIO FIFOs) and Core 0 (running the bus loop) access different banks without stalling each other.
- **XRAM** lives in SRAM (one of the 64 kB banks). DMA channels move data between PIO RX FIFOs and this SRAM region.
- The RIA runs at 256 MHz — it never sleeps, so Flash execution and power modes are irrelevant to RIA firmware.
- DMA addresses are in the AHB-Lite space (`0x50000000`) alongside PIO — both are on the fast crossbar.

## Related pages

- [[dma-controller]]
- [[pio-architecture]]
- [[xram]]
- [[rp6502-ria]]
- [[rp2350]] — RP2350 successor chip

---

## RP2350 SRAM (vs RP2040)

The RP2350 expands SRAM to **520 KB in 10 banks**:

| Region | Banks | Size | Base address | Layout |
|---|---|---|---|---|
| SRAM0–3 | 4 | 4×64 KB | `0x20000000` | Word-striped (bits [3:2]) |
| SRAM4–7 | 4 | 4×64 KB | `0x20040000` | Word-striped (bits [3:2]) |
| SRAM8–9 | 2 | 2×4 KB | `0x20080000` | Non-striped |

SRAM0–3 are in power domain SRAM0; SRAM4–9 are in SRAM1. The two small non-striped banks (SRAM8–9) are useful for hoisting processor stacks to avoid bank conflicts with DMA-heavy SRAM0–7.

> **RP2350 vs RP2040 SRAM note**: RP2350 striped SRAM spans `0x20000000`–`0x2007ffff` (512 KB) with both 256 KB halves striped over 4 banks each. The RP2040's striped/non-striped regions at `0x21000000` do not exist on RP2350 — it only has the main striped access at `0x20000000`.

RP2350 address map (key bases) also in [[memory-map]].
