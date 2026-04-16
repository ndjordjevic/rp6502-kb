---
type: concept
tags: [rp2040, dma, xram, pio, peripheral]
related: [[rp2040-memory]], [[pio-architecture]], [[xram]], [[rp6502-ria]]
sources: [[quadros-rp2040]]
created: 2026-04-16
updated: 2026-04-16 (audit: corrected DREQ_PWM_WRAP8→WRAP7 book typo)
---

# DMA Controller (RP2040)

**Summary**: The RP2040 DMA controller has 12 independent channels and can sustain one 32-bit read + one 32-bit write per clock cycle — faster than a single CPU core — making it the primary engine for bulk data movement in RIA firmware (XRAM ↔ 65C02 bus).

---

## Overview

The DMA controller moves data between memory and memory-mapped peripherals without CPU involvement. The CPU (or the other core) can keep running while DMA transfers proceed in parallel.

**Three transfer modes:**
- **Memory-to-peripheral**: DMA reads from SRAM/Flash and writes to a peripheral TX FIFO.
- **Peripheral-to-memory**: DMA reads from a peripheral RX FIFO and writes to SRAM.
- **Memory-to-memory**: DMA copies between two SRAM addresses.

**Peripherals that support DMA**: PIO, SPI, UART, PWM, I²C, ADC, XIP.

**Throughput**: up to one 32-bit read + one 32-bit write per `sys_clk` cycle. At 256 MHz (RIA clock), this is 1 GB/s theoretical maximum.

---

## Channel architecture

The RP2040 has **12 independent DMA channels** (`DMA_BASE` = `0x50000000`). Each channel operates independently and has four control registers:

| Register | Role |
|---|---|
| `READ_ADDR` | Address for the next read |
| `WRITE_ADDR` | Address for the next write |
| `TRANS_COUNT` | Number of transfers remaining (write to set count for next sequence) |
| `CTRL` | Channel configuration (enable, transfer size, address increment, DREQ, chain target) |

**Transfer sizes**: 8, 16, or 32 bits. Addresses must be aligned to the transfer size.

**Address increment control** (bits in `CTRL`):
- `INCR_READ` — increment read address after each transfer.
- `INCR_WRITE` — increment write address after each transfer.
- `RING_SEL` — which address the ring affects (1 = write, 0 = read).
- `RING_SIZE` — address wrap: 0 = off; N > 0 = only the lower N bits are incremented (creates a power-of-2 address ring).

> Always set READ_ADDR, WRITE_ADDR, and TRANS_COUNT at the start of each transfer sequence. If you don't, the channel reuses the values left over from the previous sequence.

---

## Triggering a channel

A channel starts when **triggered**. Three trigger methods:
1. **Trigger register write**: write a non-zero value to the channel's trigger-register alias (see alias table below). The write simultaneously configures and starts the channel.
2. **Channel chaining**: `CTRL` can name another channel that will be automatically triggered when the current channel finishes its `TRANS_COUNT` transfers.
3. **`MULTI_CHAN_TRIGGER`**: a single write starts multiple channels at once.

A trigger does nothing if the channel is disabled or already running.

### Register alias sets (trigger-on-write)

Each channel's four registers can be accessed through four **alias** address offsets. The last column in each alias is a **trigger register** — writing it also starts the channel. This allows compact control blocks.

| Base offset | +0x0 | +0x04 | +0x08 | +0x0C (Trigger) |
|---|---|---|---|---|
| `0x00` (Alias 0) | `READ_ADDR` | `WRITE_ADDR` | `TRANS_COUNT` | `CTRL_TRIG` |
| `0x10` (Alias 1) | `CTRL` | `READ_ADDR` | `WRITE_ADDR` | `TRANS_COUNT_TRIG` |
| `0x20` (Alias 2) | `CTRL` | `TRANS_COUNT` | `READ_ADDR` | `WRITE_ADDR_TRIG` |
| `0x30` (Alias 3) | `CTRL` | `WRITE_ADDR` | `TRANS_COUNT` | `READ_ADDR_TRIG` |

**Common use case**: a controller channel writes only the changing field (e.g. just `READ_ADDR_TRIG`) to start a data channel. The other parameters (write address, count, config) are pre-programmed and don't need to change.

---

## Control blocks and chaining

For complex multi-transfer sequences, store channel configuration in a **control block** in SRAM and use a second "controller" DMA channel to load it into the first channel's registers.

A **control block list** (array of control blocks in SRAM) enables fully automated sequences:
1. Controller channel reads next control block and writes it to data channel registers, triggering the data channel.
2. Data channel finishes → chains back to controller channel → next control block loaded.
3. **Null trigger**: put a control block with zero in the trigger field to end the chain.

This pattern is used in the SPI display example: three screen strips at non-contiguous addresses are sent via a control block list with a single trigger to start.

---

## DREQ pacing

Transfers are paced by **Transfer Requests (TREQ)**. Options per channel:

- **Device DREQ** — peripheral signals when its FIFO is ready. The RP2040 DMA supports a **credit-based DREQ** model: it tracks outstanding requests so the FIFO is always fully utilised without overflow.
- **Pacing timer** — one of 4 fractional timers that run at `(X/Y) × sys_clk` (X, Y are 16-bit; `X/Y ≤ 1`).
- **Permanent** — transfers as fast as possible (memory-to-memory).

> A DREQ must not be shared across more than one channel, and the peripheral FIFO must not be accessed by software while DMA is using it.

### DREQ table (40 sources)

| DREQ | Name | DREQ | Name |
|---|---|---|---|
| 0 | `DREQ_PIO0_TX0` | 20 | `DREQ_UART0_TX` |
| 1 | `DREQ_PIO0_TX1` | 21 | `DREQ_UART0_RX` |
| 2 | `DREQ_PIO0_TX2` | 22 | `DREQ_UART1_TX` |
| 3 | `DREQ_PIO0_TX3` | 23 | `DREQ_UART1_RX` |
| 4 | `DREQ_PIO0_RX0` | 24 | `DREQ_PWM_WRAP0` |
| 5 | `DREQ_PIO0_RX1` | 25 | `DREQ_PWM_WRAP1` |
| 6 | `DREQ_PIO0_RX2` | 26 | `DREQ_PWM_WRAP2` |
| 7 | `DREQ_PIO0_RX3` | 27 | `DREQ_PWM_WRAP3` |
| 8 | `DREQ_PIO1_TX0` | 28 | `DREQ_PWM_WRAP4` |
| 9 | `DREQ_PIO1_TX1` | 29 | `DREQ_PWM_WRAP5` |
| 10 | `DREQ_PIO1_TX2` | 30 | `DREQ_PWM_WRAP6` |
| 11 | `DREQ_PIO1_TX3` | 31 | `DREQ_PWM_WRAP7` |
| 12 | `DREQ_PIO1_RX0` | 32 | `DREQ_I2C0_TX` |
| 13 | `DREQ_PIO1_RX1` | 33 | `DREQ_I2C0_RX` |
| 14 | `DREQ_PIO1_RX2` | 34 | `DREQ_I2C1_TX` |
| 15 | `DREQ_PIO1_RX3` | 35 | `DREQ_I2C1_RX` |
| 16 | `DREQ_SPI0_TX` | 36 | `DREQ_ADC` |
| 17 | `DREQ_SPI0_RX` | 37 | `DREQ_XIP_STREAM` |
| 18 | `DREQ_SPI1_TX` | 38 | `DREQ_XIP_SSITX` |
| 19 | `DREQ_SPI1_RX` | 39 | `DREQ_XIP_SSIRX` |

> **Conflict:** The Quadros book (page 44) lists DREQ 31 as `DREQ_PWM_WRAP8`, skipping WRAP7. The RP2040 has 8 PWM slices numbered 0–7, and the RP2040 datasheet and SDK headers (`dreq.h`) confirm DREQ 31 = `DREQ_PWM_WRAP7`. Corrected here.

**RIA-relevant DREQs**: `DREQ_PIO0_RX*` and `DREQ_PIO1_RX*` pace XRAM-fill DMA from PIO bus capture FIFOs.

---

## Interrupts

A channel can fire an interrupt when:
- It completes its configured `TRANS_COUNT` transfers, **or**
- It receives a **null trigger** (zero written to a trigger register).

`CTRL` has an `irq_quiet` flag:
- `irq_quiet = false` (default): interrupt fires after every completed sequence.
- `irq_quiet = true`: interrupt fires **only** on null trigger — useful for suppress-all-but-last in a control-block chain.

Two system IRQ lines (routed to either core):
- `DMA_IRQ_0` (ARM IRQ 11)
- `DMA_IRQ_1` (ARM IRQ 12)

All 12 channels share 2 IRQ lines → use `dma_channel_get_irq0_status()` to identify the triggering channel.

---

## CRC sniffing

The DMA controller can compute a checksum on any channel's data stream in hardware. Modes:

| Mode | Calculation |
|---|---|
| `0x00` | CRC-32 (IEEE 802.3) |
| `0x01` | CRC-32 with bit-reversed data |
| `0x02` | CRC-16 (CCITT) |
| `0x03` | CRC-16 CCITT with bit-reversed data |
| `0x0E` | XOR / Parity (result = 1 if odd number of 1s) |
| `0x0F` | 32-bit checksum |

Write the `sniff_data` register to initialise the accumulator. The result register supports optional bit inversion and byte swap. To use: enable in both the channel config (`channel_config_set_sniff_enable`) and the DMA sniffer (`dma_sniffer_enable`).

---

## SDK API summary (`hardware_dma`)

### Channel allocation

```c
int  dma_claim_unused_channel(bool required);   // preferred way to pick a channel
void dma_channel_claim(uint channel);           // claim by fixed number
void dma_claim_mask(uint32_t channel_mask);     // claim multiple at once
void dma_channel_unclaim(uint channel);
bool dma_channel_is_claimed(uint channel);
```

### Configuration

```c
// Start from defaults, then modify
dma_channel_config c = dma_channel_get_default_config(channel);

// Modifiers
channel_config_set_transfer_data_size(&c, DMA_SIZE_8 | DMA_SIZE_16 | DMA_SIZE_32);
channel_config_set_read_increment(&c, bool incr);
channel_config_set_write_increment(&c, bool incr);
channel_config_set_dreq(&c, uint dreq);              // use dma_get_xxx_dreq() helpers
channel_config_set_chain_to(&c, uint chain_to);
channel_config_set_ring(&c, bool write, uint size_bits);
channel_config_set_bswap(&c, bool bswap);
channel_config_set_irq_quiet(&c, bool irq_quiet);
channel_config_set_high_priority(&c, bool high);
channel_config_set_enable(&c, bool enable);
channel_config_set_sniff_enable(&c, bool sniff_enable);
```

### Configure and start

```c
// Main setup call
dma_channel_configure(channel, &config, write_addr, read_addr, count, trigger);

// Partial updates (trigger = start immediately)
dma_channel_set_read_addr(channel, read_addr, trigger);
dma_channel_set_write_addr(channel, write_addr, trigger);
dma_channel_set_trans_count(channel, count, trigger);

// Convenience
dma_channel_transfer_from_buffer_now(channel, read_addr, count);
dma_channel_transfer_to_buffer_now(channel, write_addr, count);

// Start multiple channels simultaneously
dma_start_channel_mask(uint32_t chan_mask);
dma_channel_start(channel);
dma_channel_abort(channel);  // stops transfer (may fire completion interrupt — RP2040 bug)
```

### Interrupt handling

```c
dma_channel_set_irq0_enabled(channel, true);
irq_set_exclusive_handler(DMA_IRQ_0, handler);
irq_set_enabled(DMA_IRQ_0, true);

// In handler:
bool dma_channel_get_irq0_status(channel);   // check if this channel caused IRQ
dma_channel_acknowledge_irq0(channel);        // clear the channel's interrupt flag

// Generic (irq_index = 0 or 1):
dma_irqn_set_channel_enabled(irq_index, channel, enabled);
dma_irqn_get_channel_status(irq_index, channel);
dma_irqn_acknowledge_channel(irq_index, channel);
```

### Pacing timers

```c
int  dma_claim_unused_timer(bool required);
void dma_timer_set_fraction(uint timer, uint16_t numerator, uint16_t denominator);
     // runs at (numerator/denominator) * sys_clk; denominator >= numerator
uint dma_get_timer_dreq(uint timer_num);   // use as DREQ
```

### CRC sniffer

```c
dma_sniffer_enable(channel, mode, force_channel_enable);
dma_sniffer_set_byte_swap_enabled(bool swap);
dma_sniffer_disable();
// Accumulator is at dma_hw->sniff_data (write to init, read for result)
```

---

## RIA firmware relevance

The DMA controller is the backbone of XRAM throughput in [[rp6502-ria]] firmware:

| DMA role | Detail |
|---|---|
| **XRAM fill (bus write)** | PIO state machine captures 65C02 data bus byte → RX FIFO → DMA (DREQ_PIOx_RX) → SRAM (XRAM region) |
| **XRAM drain (bus read)** | DMA reads XRAM → PIO TX FIFO → state machine drives 65C02 data bus |
| **XRAM broadcast** | XRAM writes replicated to PIX bus devices (VGA); DMA may assist with high-bandwidth frames |

The two-core design (Core 0: bus loop; Core 1: OS task dispatcher) means DMA transfers can be set up from either core and will proceed independently — the bus loop core doesn't have to poll for completion.

> **Note**: `dma_channel_abort()` has a known RP2040 bug — it may generate a spurious completion interrupt even when the transfer was not complete.

## Related pages

- [[rp2040-memory]]
- [[pio-architecture]]
- [[xram]]
- [[rp6502-ria]]
