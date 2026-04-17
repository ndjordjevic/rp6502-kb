---
type: source
tags: [rp6502, youtube, graphics, vga, bitmap, xreg, xram, planes, scanlines]
related: [[rp6502-vga]], [[xreg]], [[xram]], [[development-history]]
sources: [[youtube-playlist]]
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep13 — Graphics Programming

**Summary**: A hands-on tutorial for Picocomputer graphics programming: canvas/mode selection with `xreg`, config structure placement in XRAM, bitmap mode (mode 3), 3-plane compositing, scanline partitioning, tiling, and VSYNC-synchronized scrolling.

---

## Key topics

- **Canvas selection**: `xreg(1, 0, 0, 2)` → 320×180 canvas (canvas 0 = console only; canvas 2 = 320×180 for 16:9).
- **Bitmap mode**: `$1:0:01 = 3` (mode), `$1:0:02` (options/bit depth), `$1:0:03` (config structure address in XRAM). Config has: width, height, data pointer (at XRAM $0000), palette pointer (`$ffff` = built-in ANSI palette).
- **XRAM access**: set `RIA.addr0` + `step = 1`; sequential writes ~faster than system RAM; used for clearing/filling bitmap data.
- **16-bit color / alpha**: RGB555 + 1 alpha bit (opaque vs. transparent). Alpha enables per-pixel transparency between planes.
- **3 planes**: drawn in order 0→1→2; upper planes overwrite/blend onto lower. Enables parallax scrolling, bitmap + HUD overlay.
- **X/Y scrolling**: change `config.x` and `config.y` fields between frames; VSYNC register used to synchronize (increments 60×/second at VBI start; ~500 µs window before screen draws).
- **Tiling**: enable to make image repeat in X and/or Y → infinite seamless pattern.
- **Scanline partitioning**: `PLANE`, `BEGIN`, `END` registers at `$1:0:04–06`; split screen between bitmap (plane 0) and console text (plane 1) at an arbitrary scanline.
- **ANSI terminal upgrade**: console (mode 0) is now 16-bit color (256-color ANSI palette).
- **Image loading speed**: 56 K XRAM loaded in under 1 second; happens without involving 6502 → can stream assets while game runs.

## Related pages

- [[rp6502-vga]] — complete mode reference
- [[xreg]] — the extended register mechanism
- [[xram]] — 64 K extended RAM used for all graphics data
- [[development-history]] — Era C: graphics programming patterns
