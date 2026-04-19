---
type: source
tags: [rp6502, youtube, game-of-life, graphics, bitmap, programming-demo]
related:
  - "[[rp6502-vga]]"
  - "[[xram]]"
  - "[[development-history]]"
sources:
  - "[[youtube-playlist]]"
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep19 — Programming the Game of Life on a 6502

**Summary**: A coding walkthrough implementing Conway's Game of Life in C using the Picocomputer graphics system — demonstrates 640×480 monochrome bitmap mode, XRAM double-buffering, and the graphics setup/access patterns.

---

## Key topics

- **Graphics mode**: 640×480 monochrome bitmap (1 bit per pixel = live/dead), configured with `xreg`.
- **Double buffering**: the Game of Life rules require simultaneous update — copy XRAM bitmap data to system RAM buffer, apply logic, write back.
- **XRAM access pattern**: set `RIA.addr0` + `step = 1`, then loop over bytes — same pattern for clear, copy, and write.
- **Canvas/mode setup**: canvas selection → mode 3 bitmap → config structure at `$ff00` → data at XRAM `$0000`.
- **Tutorial content**: primarily a coding walkthrough; no new hardware or API concepts introduced.

## Related pages

- [[rp6502-vga]] — bitmap mode used
- [[xram]] — extended RAM used for bitmap data and copy buffer
