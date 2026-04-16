---
type: concept
tags: [rp6502, pix, bus, protocol]
related: [[rp6502-ria]], [[rp6502-vga]], [[xram]], [[xreg]]
sources: [[rp6502-ria-docs]], [[rp6502-vga-docs]], [[rp6502-github-repo]]
created: 2026-04-15
updated: 2026-04-16
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
- Pi Pico **PIO** (`pix_tx` program on pio1 SM1) drives the bus. On the receiver (VGA Pico), pio1 SM1 handles XREG messages and pio1 SM2 handles XRAM updates.
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

## Related pages

- [[rp6502-ria]] · [[rp6502-vga]] · [[xram]] · [[xreg]]
