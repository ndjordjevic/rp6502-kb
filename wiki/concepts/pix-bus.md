---
type: concept
tags: [rp6502, pix, bus, protocol]
related: [[rp6502-ria]], [[rp6502-vga]], [[xram]], [[xreg]], [[pio-architecture]]
sources: [[rp6502-ria-docs]], [[rp6502-vga-docs]], [[rp6502-github-repo]], [[youtube-playlist]], [[rumbledethumps-discord]]
created: 2026-04-15
updated: 2026-04-18
---

# PIX Bus

**Summary**: **Pico Information Exchange** — the 5-wire, double-data-rate, addressable broadcast bus that connects [[rp6502-ria]] to [[rp6502-vga]] and any other PIX device.

---

## Why it exists

The Pi Pico has very few GPIO pins. The RIA needs to ship high-bandwidth video/audio data to the VGA Pico without burning the rest of the 6502's bus. PIX gets that done in 5 wires (PHI2 + PIX0–3) with no addressing handshake — every device listens, decodes the broadcast frame, and acts only on its own device ID.

## Physical layer

- 5 wires: **PHI2** (clock) + **PIX0..PIX3** (data).
- **DDR**: PIX0–3 shifts **4 bits per PHI2 edge** — 4 bits on rising, 4 bits on falling → 8 bits per PHI2 cycle → 32 bits in 4 cycles.
- A frame is **32 bits** transmitted over **4 PHI2 cycles**.
- Pi Pico [[pio-architecture|PIO]] (`pix_tx` program on pio1 SM1) drives the bus. On the receiver (VGA Pico), pio1 SM1 handles XREG messages and pio1 SM2 handles XRAM updates.
- **GPIO assignments (source-confirmed)**: RIA drives PIX0–3 on GPIO 0–3. VGA receives PIX on its GPIO 0–3; PHI2 arrives on VGA GPIO 11.
- TX FIFO is joined to 8 entries deep. The RIA uses `pix_ready()` to check for free space before sending.
- Synchronization: ensure PIX0 is high on a low transition of PHI2; if not, stall a cycle.

## Frame format (32 bits)

| Bits | Mask | Meaning |
| --- | --- | --- |
| 31-29 | `0xE0000000` | **Device ID** (0–7) |
| 28 | `0x10000000` | **Framing bit** — set on every message |
| 27-24 | `0x0F000000` | **Channel ID** (0–15) |
| 23-16 | `0x00FF0000` | **Register address** (0–255) within the channel |
| 15-0 | `0x0000FFFF` | **Value** to store at that register |

Bit 28 being always-on is what receivers use as a sanity check; an all-zero payload at device 7 acts as an idle/sync beacon (`0xF0000000` is hard to miss on a logic analyzer).

## Device ID allocation

| ID | Owner |
| --- | --- |
| 0 | [[rp6502-ria]] (also broadcasts XRAM updates) |
| 1 | [[rp6502-vga]] |
| 2-6 | User expansion |
| 7 | Sync / idle marker |

Each device has 16 channels × 256 registers — the address space the OS calls [[xreg|extended registers]].

## XRAM broadcast (device 0)

The RIA broadcasts every change to its 64 K of [[xram]] as a device-0 frame:
- Bits 15-0 = XRAM **address**
- Bits 23-16 = XRAM **byte value**

Every PIX device that cares maintains its own local replica of (some or all of) XRAM — so XRAM works like a shared write-only bus with eventually-consistent caches at each receiver.

## Backchannel

PIX is **unidirectional** (RIA → others). For acks and VSYNC ticks, [[rp6502-vga]] reuses the **UART Tx pin** as a backchannel:

| Byte | Meaning |
| --- | --- |
| 0x00–0x7F | ASCII version string (boot message) |
| `0x80` + scalar (0x0F bits) | VSYNC tick → increments `RIA_VSYNC` |
| `0x90` + scalar | OP_ACK |
| `0xA0` + scalar | OP_NAK |

Application programmers don't see this; it's automatic.

## Design journey (from [[yt-ep08-vga-pix-bus]])

> **Source**: [[yt-ep08-vga-pix-bus]] (Ep8, ~2023). The following is how the author arrived at the PIX bus design — historical motivation context.

### Why not SPI

The author first considered SPI for the RIA↔VGA link. SPI would handle the bandwidth, but:
- Supporting multiple video cards requires one additional GPIO per card (chip selects) — GPIO is already scarce.
- Running 50–100 MHz SPI down a ribbon cable to multiple off-board devices requires careful impedance control ("plan B").

The goal was to match the electrical characteristics of the 6502 bus: nothing faster than PHI2 (8 MHz), same low-speed signaling.

### Bandwidth derivation

`STA abs` (absolute memory store) takes **4 PHI2 cycles** — the fastest a 6502 can write to any non-zero-page address. At 8 MHz: **1 byte every 4 cycles = 16 Mb/s theoretical peak burst**. Adding a 16-bit address to each 8-bit data byte makes the message 24 bits.

Six parallel wires × 4 cycles = 24 bits — almost enough. But framing and multi-device addressing needed one more wire → 7 wires → more than available.

### The DDR "brain fart" insight

> *"I got hung up on this for a bit then I realized using both transitions of the clock doesn't change the electrical requirements. I'm not sure why this needed a second thought. It was some kind of brain fart. Like forgetting your sunglasses are tipped up on your head."*

With **DDR (Double Data Rate)** — shifting on both rising and falling PHI2 edges — 4 wires carry 8 bits per cycle → 32 bits in 4 cycles. The same electrical speed, twice the bandwidth. This is the PIX bus.

At 8 MHz PHI2: **4 bits × 2 edges × 8 MHz = 64 Mbit/s** raw throughput. (@rumbledethumps confirmed 64 Mbit/s in Discord, 2026-04-17)

### PIO resource cost

| Component | PIO cost |
|---|---|
| Transmitter (`pix_tx`) | 5 instructions |
| Receiver (frame sync + channel filter + data) | 14 instructions |
| Full receiver on VGA Pico | All 32 instructions + all 4 state machines of one PIO block |

Both PIO blocks on the VGA Pico are full.

### DMA priority discovery

About 1 in 1,000 writes produced display corruption. The root cause: VGA output DMA competes with PIX DMA for the same bus, with a hard 500 ns deadline. The fix:

**PIX DMA priority > VGA DMA priority > CPU**

This is not unusual — microcontrollers provide priority controls precisely for these real-time multi-source situations.

### VSYNC backchannel (from [[yt-ep12-fonts-vsync]])

PIX is one-directional (RIA→devices), but the VGA Pico needs a path back for VSYNC ticks and version information. No spare GPIO pins existed for a dedicated wire.

**Solution**: move UART TX data to the PIX bus, then reverse the direction of the UART TX pin. The VGA Pico uses this reversed pin as a backchannel.

- **VSYNC tick** sent by VGA Pico over backchannel at the start of each vertical blanking interval (~60 Hz) → increments `RIA_VSYNC` register on the RIA.
- **Version string** sent at boot via the same path.
- Backchannel only activates when the RIA detects a VGA device on the PIX bus (VGA is optional).

**Complexity hidden from users**: the pin-reversal requires flushing all hardware FIFOs (different depths for UART vs. CDC), handling re-sync when either device reboots independently, and using a "phantom UART" (not connected to any physical GPIO pin) as a flow-control barrier for the PIX bus side. From the 6502 programmer's perspective: just read the `vsync` register.

## Community PIX devices

The PIX bus is open for expansion. Community members have connected second PIX devices:

- **FPGA OPL2 sound card** (jasonr1100): FPGA board attached to PIX bus; OPL2 registers written at `$1FF00–$1FF01`. Used a 6522 VIA IRQ for timing. Predated native OPL2 support and inspired its addition.
- **eInk display** (jjjacer): rumbledethumps described how a Pi Pico (not ESP32) could act as a second PIX device, receive console output + XRAM data, and drive an eInk panel with custom video modes. "You'll have access to XRAM so pretty much anything you can imagine is possible."
- PIX also handles `SET VGA` (canvas/mode) commands over its device control channel, which any attached device can listen on.

## Related pages

- [[rp6502-ria]] · [[rp6502-vga]] · [[xram]] · [[xreg]]
- [[yt-ep08-vga-pix-bus]] · [[yt-ep12-fonts-vsync]] · [[development-history]]
- [[community-projects]] · [[rumbledethumps-discord]]
