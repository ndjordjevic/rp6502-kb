---
type: concept
tags: [rp2040, rp2350, dma, pio2, xram, pio, peripheral, errata]
related:
  - "[[rp2040-memory]]"
  - "[[pio-architecture]]"
  - "[[xram]]"
  - "[[rp6502-ria]]"
sources:
  - "[[quadros-rp2040]]"
  - "[[pico-c-sdk]]"
  - "[[rp2350-datasheet]]"
created: 2026-04-16
updated: 2026-04-17 (S5 ingest: RP2350 DREQ table, encoded_transfer_count, self-trigger/endless DMA, new functions, errata IDs)
---

# DMA Controller

**Summary**: The RP2040 has 12 independent DMA channels; the RP2350 (used in current RIA firmware) expands this to 16. Each channel can sustain one 32-bit read + one 32-bit write per clock cycle — faster than a single CPU core — making DMA the primary engine for bulk data movement in RIA firmware (XRAM ↔ 65C02 bus).

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

The RP2040 has **12 independent DMA channels** (`DMA_BASE` = `0x50000000`); RP2350 expands this to **16 channels**. Each channel operates independently and has four control registers:

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
- `INCR_READ_REV` / `INCR_WRITE_REV` (**RP2350 only**) — decrement instead of increment, or increment by 2.

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
- **Pacing timer** — one of 4 fractional timers that run at `(X/Y) × sys_clk` (X, Y are 16-bit; `X/Y ≤ 1`). TREQ values 0x3b–0x3e select timers 0–3.
- **Permanent** (TREQ = 0x3f) — transfers as fast as possible (memory-to-memory).

> A DREQ must not be shared across more than one channel, and the peripheral FIFO must not be accessed by software while DMA is using it.

### DREQ table — RP2040 (40 sources)

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

### DREQ table — RP2350 (55 sources)

RP2350 adds **PIO2** (8 new DREQs), **HSTX**, **CORESIGHT**, **SHA256** and renames XIP SSI entries. All existing RP2040 DREQ names shift upward:

| DREQ | Name | DREQ | Name |
|---|---|---|---|
| 0–7 | `DREQ_PIO0_TX0–3`, `DREQ_PIO0_RX0–3` | 24 | `DREQ_SPI0_TX` |
| 8–15 | `DREQ_PIO1_TX0–3`, `DREQ_PIO1_RX0–3` | 25 | `DREQ_SPI0_RX` |
| 16 | `DREQ_PIO2_TX0` | 26 | `DREQ_SPI1_TX` |
| 17 | `DREQ_PIO2_TX1` | 27 | `DREQ_SPI1_RX` |
| 18 | `DREQ_PIO2_TX2` | 28 | `DREQ_UART0_TX` |
| 19 | `DREQ_PIO2_TX3` | 29 | `DREQ_UART0_RX` |
| 20 | `DREQ_PIO2_RX0` | 30 | `DREQ_UART1_TX` |
| 21 | `DREQ_PIO2_RX1` | 31 | `DREQ_UART1_RX` |
| 22 | `DREQ_PIO2_RX2` | 32–43 | `DREQ_PWM_WRAP0–11` (12 slices on RP2350) |
| 23 | `DREQ_PIO2_RX3` | 44–47 | `DREQ_I2C0_TX/RX`, `DREQ_I2C1_TX/RX` |
| 48 | `DREQ_ADC` | 49 | `DREQ_XIP_STREAM` |
| 50 | `DREQ_XIP_QMITX` | 51 | `DREQ_XIP_QMIRX` |
| 52 | `DREQ_HSTX` | 53 | `DREQ_CORESIGHT` |
| 54 | `DREQ_SHA256` | 59–62 | `DREQ_DMA_TIMER0–3` |
| 63 | `DREQ_FORCE` | | |

**RIA-relevant DREQs**: `DREQ_PIO0_RX*` and `DREQ_PIO1_RX*` pace XRAM-fill DMA from PIO bus capture FIFOs.

---

## Interrupts

A channel can fire an interrupt when:
- It completes its configured `TRANS_COUNT` transfers, **or**
- It receives a **null trigger** (zero written to a trigger register).

`CTRL` has an `irq_quiet` flag:
- `irq_quiet = false` (default): interrupt fires after every completed sequence.
- `irq_quiet = true`: interrupt fires **only** on null trigger — useful for suppress-all-but-last in a control-block chain.

**RP2040**: Two system IRQ lines (routed to either core):
- `DMA_IRQ_0` (ARM IRQ 11)
- `DMA_IRQ_1` (ARM IRQ 12)

All 12 channels share 2 IRQ lines → use `dma_channel_get_irq0_status()` to identify the triggering channel.

**RP2350**: Four system IRQ lines (`DMA_IRQ_0`–`DMA_IRQ_3`), each with independent channel-enable masks (`INTE0`–`INTE3`). All 16 channels can be independently routed to any IRQ. This allows:
- Routing time-critical channels to a dedicated higher-priority IRQ
- Sending different channel interrupts to different processor cores in multicore setups
- Assigning IRQs to security domains (Secure / Non-secure)

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
void dma_unclaim_mask(uint32_t channel_mask);   // unclaim multiple at once
bool dma_channel_is_claimed(uint channel);
bool dma_channel_is_busy(uint channel);         // true if transfer in progress
```

### Configuration

```c
// Start from defaults, then modify
dma_channel_config c = dma_channel_get_default_config(channel);

// Modifiers
channel_config_set_transfer_data_size(&c, DMA_SIZE_8 | DMA_SIZE_16 | DMA_SIZE_32);
channel_config_set_read_increment(&c, bool incr);
channel_config_set_write_increment(&c, bool incr);
// Or use the typed variants (RP2350 adds DMA_ADDRESS_UPDATE_NONE / _INCREMENT enum):
channel_config_set_read_address_update_type(&c, dma_address_update_type_t);
channel_config_set_write_address_update_type(&c, dma_address_update_type_t);
channel_config_set_dreq(&c, uint dreq);              // use dma_get_xxx_dreq() helpers
channel_config_set_chain_to(&c, uint chain_to);
// Disable chaining: set chain_to == the channel itself
channel_config_set_ring(&c, bool write, uint size_bits);
// size_bits 1–15: wraps on (1<<size_bits) byte boundary; 0 = off
channel_config_set_bswap(&c, bool bswap);
// No effect for byte transfers; swaps 2 bytes for halfword; reverses 4 bytes for word.
// Note: if both channel bswap and dma_sniffer_set_byte_swap_enabled are true, effects cancel for sniffer.
channel_config_set_irq_quiet(&c, bool irq_quiet);
channel_config_set_high_priority(&c, bool high);
// High priority: in each scheduling round, ALL high-priority channels run first, then ONE low-priority channel.
// Does NOT change the DMA's bus priority — only affects scheduling order between channels.
channel_config_set_enable(&c, bool enable);
channel_config_set_sniff_enable(&c, bool sniff_enable);
uint32_t channel_config_get_ctrl_value(&c);  // get raw CTRL register value
```

### Configure and start

```c
// Main setup call
// encoded_transfer_count: on RP2040 = plain count (0..2^32-1)
// on RP2350 = low 28 bits count (0..2^28-1), top 4 bits encode options
// Best practice: always use dma_encode_transfer_count() etc. (see below)
dma_channel_configure(channel, &config, write_addr, read_addr, encoded_count, trigger);

// Partial updates (trigger = start immediately)
dma_channel_set_read_addr(channel, read_addr, trigger);
dma_channel_set_write_addr(channel, write_addr, trigger);
dma_channel_set_transfer_count(channel, encoded_count, trigger);
dma_channel_set_config(channel, &config, trigger);  // update config only

// Transfer count helpers (always use these for portability)
uint32_t dma_encode_transfer_count(uint count);                       // RP2040: 0..2^32-1; RP2350: 0..2^28-1
uint32_t dma_encode_transfer_count_with_self_trigger(uint count);     // RP2350 only: channel re-triggers itself
uint32_t dma_encode_endless_transfer_count(void);                     // RP2350 only: continuous (never stops)

// Convenience
dma_channel_transfer_from_buffer_now(channel, read_addr, encoded_count);
dma_channel_transfer_to_buffer_now(channel, write_addr, encoded_count);

// Start multiple channels simultaneously
dma_start_channel_mask(uint32_t chan_mask);
dma_channel_start(channel);
dma_channel_wait_for_finish_blocking(channel);  // spin-wait until not busy
dma_channel_abort(channel);   // stops transfer; see errata below
dma_channel_cleanup(channel); // disables IRQs, aborts, clears IRQ flag — use before unclaim
```

### Interrupt handling

```c
dma_channel_set_irq0_enabled(channel, true);
dma_channel_set_irq1_enabled(channel, true);
// Or set/clear multiple at once:
dma_set_irq0_channel_mask_enabled(uint32_t mask, bool enabled);
dma_set_irq1_channel_mask_enabled(uint32_t mask, bool enabled);
dma_irqn_set_channel_enabled(irq_index, channel, enabled);       // generic index 0 or 1
dma_irqn_set_channel_mask_enabled(irq_index, mask, enabled);

int dma_get_irq_num(irq_index);  // returns actual IRQ number for DMA_IRQ_0 or DMA_IRQ_1

irq_set_exclusive_handler(DMA_IRQ_0, handler);
irq_set_enabled(DMA_IRQ_0, true);

// In handler:
bool dma_channel_get_irq0_status(channel);   // check if this channel caused IRQ0
dma_channel_acknowledge_irq0(channel);        // clear the channel's interrupt flag
// Generic:
bool dma_irqn_get_channel_status(irq_index, channel);
dma_irqn_acknowledge_channel(irq_index, channel);
```

### Pacing timers

```c
int  dma_claim_unused_timer(bool required);
void dma_timer_claim(uint timer);           // claim a specific timer; panics if already claimed
void dma_timer_unclaim(uint timer);
bool dma_timer_is_claimed(uint timer);
void dma_timer_set_fraction(uint timer, uint16_t numerator, uint16_t denominator);
     // runs at (numerator/denominator) * sys_clk; denominator >= numerator
uint dma_get_timer_dreq(uint timer_num);   // use as DREQ
```

### CRC sniffer

```c
dma_sniffer_enable(channel, mode, force_channel_enable);
// force_channel_enable=true sets sniff_enable in the channel config too (usually what you want)
// If both channel bswap AND sniffer byte swap are enabled, their effects cancel for the sniffer.
dma_sniffer_set_byte_swap_enabled(bool swap);
dma_sniffer_set_output_invert_enabled(bool invert);    // bit-invert result when reading
dma_sniffer_set_output_reverse_enabled(bool reverse);  // bit-reverse result when reading
dma_sniffer_disable();
// Accumulator (CRC-32 seed typically 0xFFFFFFFF, CRC-16 seed 0xFFFF):
dma_sniffer_set_data_accumulator(uint32_t seed);
uint32_t dma_sniffer_get_data_accumulator(void);  // read computed checksum
// Also: dma_channel_config_t channel_config_get_ctrl_value(&config) — get raw CTRL word
// Also: dma_channel_config_t dma_get_channel_config(channel)        — read current HW config
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

> **Note**: `dma_channel_abort()` has chip-specific errata:
> - **RP2040 (errata RP2040-E13)**: aborting a channel with in-flight transfers (read done but write pending) clears ABORT prematurely, and those in-flight transfers fire a spurious completion IRQ. Workaround: disable the channel IRQ before abort, call abort, acknowledge IRQ, re-enable.
> - **RP2350 (errata RP2350-E5)**: clear the enable bit in the CTRL register of the aborted channel *and any chained channels* before calling `dma_channel_abort()`, to prevent automatic re-triggering.

## Related pages

- [[rp2040-memory]]
- [[pio-architecture]]
- [[xram]]
- [[rp6502-ria]]
