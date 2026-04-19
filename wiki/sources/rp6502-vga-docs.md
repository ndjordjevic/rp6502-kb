---
type: source
tags: [rp6502, vga, video, source]
related:
  - "[[rp6502-vga]]"
  - "[[pix-bus]]"
  - "[[xreg]]"
  - "[[xram]]"
sources: [picocomputer.github.io/vga]
created: 2026-04-15
updated: 2026-04-15
---

# Source — RP6502-VGA docs

**Summary**: Official reference for the optional VGA module: hardware role, scanline-programmable 3-plane video system, six video modes, and the ANSI terminal.

Raw: [RP6502-VGA](<../../raw/web/picocomputer.github.io/RP6502-VGA — Picocomputer  documentation.md>)

---

## What this source establishes

- [[rp6502-vga]] = Raspberry Pi Pico 2 + VGA firmware. Its primary data input is a 5-wire [[pix-bus]] from the RIA.
- VGA is [[pix-bus]] **device ID 1**. Configuration is done entirely via [[xreg]] writes (no memory-mapped registers on the 6502 side).
- Built on a **modified scanvideo** library from Pi Pico Extras; mode 4 sprites come from Pi Pico Playground.
- **Multiple VGA modules** may coexist on one PIX bus, but they all share the same 64 K of [[xram]], and only the **first** one generates frame numbers and vsync interrupts.

## Video architecture (one-liners)

- **3 planes × 2 layers each**: fill layer + sprite layer per plane.
- Per-scanline mode programming — you can change mode on any scanline range `[BEGIN, END)` within a plane.
- **16-bit RGB555 + 1 alpha bit** (binary transparent/opaque, not a blend factor).
- Built-in ANSI palette (16 colors + 216 6×6×6 + 24 greys), 8×8 and 8×16 fonts, accessed via special XRAM pointer `$FFFF`.

## Video modes

| Mode | Name | Use |
| --- | --- | --- |
| 0 | Console | ANSI terminal on any plane |
| 1 | Character | Text w/ per-cell color (1/4/8/16 bpp) |
| 2 | Tile | Playfield: 8×8 or 16×16 tiles, 1/2/4/8 bpp |
| 3 | Bitmap | Direct pixels; 64 K XRAM caps depth (1 bpp @640×480, 4 @320×240, 8 @320×180) |
| 4 | Sprite 16-bit | Affine-capable sprites from Pi Pico Playground |
| 5 | Sprite 1/2/4/8-bit | Memory-efficient palette sprites, up to 512×512 |

Each mode is configured by writing an XREG block at `$1:0:01..` (MODE, OPTIONS, CONFIG pointer, PLANE, BEGIN, END).

## Control channel `$1:F:xx`

| Addr | Name | Notes |
| --- | --- | --- |
| 00 | DISPLAY | 0=VGA 4:3, 1=HD 16:9, 2=SXGA 5:4 |
| 01 | CODE_PAGE | Matches `RIA_ATTR_CODE_PAGE` |
| 02 | UART | Reserved |
| 03 | UART_TX | Alt path for Tx when backchannel enabled |
| 04 | BACKCHAN | 0=off, 1=on, 2=request |

*"Do not distribute applications that set these — the RIA manages them."*

## Backchannel (worth noting)

PIX is one-way (RIA → VGA). The VGA sends data back to the RIA by reusing the **UART Tx pin** as a backchannel:
- ASCII (0x00–0x7F): version string for the boot message.
- `0x80` = VSYNC tick; `0x90` = OP_ACK; `0xA0` = OP_NAK.

See [[pix-bus]] § backchannel for details.

## Terminal

A complete color ANSI terminal is built into mode 0: C0 controls, CSI sequences (CUU/CUD/CUF/CUB/CUP/ED/EL/SGR/DSR/SCP/RCP/DECTCEM), SGR 30–37 / 40–47 / 90–97 / 100–107, bold, blink, etc. No hardware flow control needed at 115200.

## Related pages

- [[rp6502-vga]] · [[pix-bus]] · [[xreg]] · [[xram]]
