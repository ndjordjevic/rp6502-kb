---
type: concept
tags: [rp6502, xram, memory]
related: [[memory-map]], [[pix-bus]], [[xreg]], [[rp6502-ria]], [[rp6502-vga]], [[dma-controller]]
sources: [[rp6502-ria-docs]], [[rp6502-os-docs]], [[quadros-rp2040]], [[youtube-playlist]]
created: 2026-04-15
updated: 2026-04-17
---

# XRAM (Extended RAM)

**Summary**: 64 KB of RAM that lives **inside** the [[rp6502-ria]] (not on the 6502 bus), accessed indirectly by the 6502 and broadcast to every [[pix-bus]] device.

---

## Address space

`$10000-$1FFFF` (64 K). **Not** part of the 6502's 16-bit address space — the 6502 reaches XRAM through register windows on the RIA, not absolute addressing.

## Why it exists

Two reasons:

1. **Bandwidth**. XRAM lets you stage video/audio/asset data faster than the 6502 could load it through normal MMIO.
2. **Sharing**. Every [[pix-bus]] device receives every XRAM write as a broadcast frame and keeps a local replica. That's how [[rp6502-vga]] sees what the 6502 wants drawn — there's no separate "send to GPU" path, just an XRAM write.

This is why the Picocomputer **has no paged memory**: bulk-XRAM operations transfer at ~512 KB/s, so a full 64 K page loads in ~150 ms with zero seek time. Disk effectively *is* RAM.

## How the 6502 reads/writes XRAM

- **Streaming**: `RIA_RW0` / `RIA_RW1` are auto-incrementing read/write windows. Set the address, then read or write a byte at a time.
- **Bulk OS calls**: [[rp6502-os]] provides `read_xram(buf, count, fildes)` / `write_xram(...)` that move file data straight into XRAM without touching 6502 RAM. Useful for loading assets the moment a ROM starts.
- **Bulk XSTACK** (≤512 B): for smaller blobs, pass over the OS xstack instead.

## The replica model

- The RIA owns the canonical XRAM.
- Every write is broadcast as a device-0 PIX frame (bits 15-0 = address, bits 23-16 = data).
- PIX devices maintain a local replica of whatever portion of XRAM they care about. Typically the whole 64 K is mirrored, and applications then install **virtual hardware** at chosen XRAM addresses by writing an [[xreg]] that points the device at that range.

Example: enabling the keyboard.
```c
xreg(0, 0, 0x00, 0x4000); // enable; keyboard data lives at $4000 in XRAM
```
After this the RIA continuously updates the 32 bytes at `$4000` with a HID-keycode bitfield, and the 6502 reads them via `RIA_RW0`.

## Multiple VGA modules

If you put more than one [[rp6502-vga]] on the same PIX bus, they all see the same 64 K of XRAM — but **only the first** one generates frame numbers and vsync interrupts. (Source: [[rp6502-vga-docs]].)

## DMA and XRAM

XRAM lives in one of the [[rp2350|RP2350]]'s SRAM banks. The RIA firmware uses [[dma-controller]] channels paced by PIO DREQ signals (`DREQ_PIOx_RX`, `DREQ_PIOx_TX`) to move data between the 65C02 bus capture FIFOs and XRAM. This is what gives XRAM its ~512 KB/s bandwidth without tying up either CPU core.

### Throughput vs. X16 (from Discord, 2026-04-12)

Comparison reported by @rumbledethumps vs. Commander X16:

| Metric | X16 | RP6502 |
|--------|-----|--------|
| System RAM load speed | ~140 KB/s (via KERNAL LOAD) | ~170 KB/s (via `load()` under llvm-mos) |
| Video RAM load speed | ~100–120 KB/s (VERA overhead) | — |
| XRAM load speed | — | **~800 KB/s** via `load_xram()` — **uses NO 6502 CPU** |

The RP6502 XRAM load is fully DMA-driven: the 6502 is free to do other work while the transfer runs.

## Related pages

- [[memory-map]] · [[pix-bus]] · [[xreg]] · [[rp6502-ria]] · [[rp6502-vga]] · [[dma-controller]]

---

## Shared ownership note (from [[yt-ep07-operating-system]])

> **Ep7 (2023)** gave the first explicit description of XRAM's shared ownership: *"another 64K we'll talk about in a bit … shared between userland, the kernel, video, and audio."* The 6502 cannot execute code from XRAM, but all four consumers read and write it — userland stages assets, the kernel updates input state, the VGA firmware reads frame data, and the audio engine reads waveform data. See [[development-history]] Era B.
