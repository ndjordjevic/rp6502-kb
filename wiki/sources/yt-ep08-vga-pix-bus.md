---
type: source
tags: [rp6502, youtube, vga, pix-bus, ddr, pio, dma]
related: [[pix-bus]], [[rp6502-vga]], [[rp6502-ria]], [[pio-architecture]], [[dma-controller]], [[development-history]]
sources: [[youtube-playlist]]
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep08 — VGA Graphics and the PIX bus

**Summary**: Explains why a custom DDR 4-wire bus (PIX) was designed instead of SPI, walks through the frame format and PIO implementation, covers the DMA priority discovery, and demonstrates Mandelbrot in bitmap graphics mode.

---

## Key topics

- **GPIO constraint** forced dual-Pico design: not enough pins for both VGA and the 6502 bus on one Pico.
- **PIX bus design rationale**: SPI rejected (multiple video cards need extra GPIOs, impedance issues for off-board); DDR four-wire solution chosen — 4 bits per PHI2 edge, 32 bits in 4 cycles.
- **Bandwidth math**: 6502 `STA abs` = 4 cycles; at 8 MHz → 16 Mb/s theoretical peak; PIX must handle 24-bit messages (8-bit data + 16-bit address) plus framing overhead.
- **"Brain fart" / sunglasses story**: author got stuck thinking in single-edge terms; realizing DDR was valid was described as "like forgetting your sunglasses are tipped up on your head."
- **PIO resource cost**: transmitter = 5 instructions; receiver = 14 instructions (framing + channel filter); full PIX receiver uses all 32 instructions + all 4 state machines of one PIO block on the VGA Pico.
- **DMA priority discovery**: ~1-in-1000 writes failed until PIX DMA priority was raised above CPU, and PIX DMA set higher than VGA DMA. Required because VGA output competes for the same DMA resources with a 500 ns hard deadline.
- **Demo**: 16-color Mandelbrot set at 320×180, written in C.

## Related pages

- [[pix-bus]] — complete frame format, device ID table, backchannel
- [[rp6502-vga]] — the VGA module this bus connects to
- [[pio-architecture]] — PIX transmitter/receiver PIO programs
- [[development-history]] — Era C: PIX bus design journey
