---
type: entity
tags: [rp6502, vga, video, firmware, pico2, hstx, dvi, tmds]
related: [[rp6502-ria]], [[pix-bus]], [[xreg]], [[xram]], [[sdk-architecture]], [[hstx]]
sources: [[rp6502-vga-docs]], [[pico-c-sdk]], [[rp2350-datasheet]], [[youtube-playlist]]
created: 2026-04-15
updated: 2026-04-18
---

# RP6502-VGA

**Summary**: The optional video module — a Raspberry Pi Pico 2 running VGA firmware. Talks to [[rp6502-ria]] over a 5-wire [[pix-bus]] and exposes a scanline-programmable, 3-plane video system.

---

## Hardware role

- Occupies slot **U4** on the [[rp6502-board]] — a plain Raspberry Pi Pico 2 (no WiFi). U2 holds the Pi Pico 2 **W** running [[rp6502-ria-w]].
- Flashing the VGA UF2 onto a Pi Pico 2 turns it into an [[rp6502-vga]]; flashing the RIA-W UF2 onto a Pi Pico 2 W turns it into an [[rp6502-ria-w]]. Sockets and firmware are paired on the reference board: U2 → RIA(-W), U4 → VGA.

## Data path

- Primary input = 5-wire [[pix-bus]] from the RIA (PHI2 + PIX0–3).
- VGA is **PIX device ID 1**. All config goes through [[xreg]] writes at `$1:C:A` addresses.
- Multiple VGA modules may share one PIX bus; they all see the same 64 K of [[xram]], but only the **first** one generates frame numbers / vsync interrupts.
- Back-path to the RIA reuses the UART Tx pin as a **backchannel** (VSYNC ticks, OP_ACK / OP_NAK, version string).

## Video system

- 3 planes × 2 layers each (fill + sprite).
- Per-scanline mode programming: any mode can be applied to any `[BEGIN, END)` range of scanlines in a chosen plane.
- 16-bit color = RGB555 + 1 alpha bit (binary: opaque or transparent, not a blend).
- Built-in fonts (8×8, 8×16) and ANSI palettes via special XRAM pointer `$FFFF`.

## Modes

| # | Name | Short use |
| --- | --- | --- |
| 0 | Console | ANSI terminal on any plane |
| 1 | Character | Text with per-cell color |
| 2 | Tile | Game playfield (8×8 or 16×16 tiles) |
| 3 | Bitmap | Direct pixels; 64 K XRAM caps depth |
| 4 | Sprite 16-bit | Affine-capable sprites |
| 5 | Sprite N-bit | Memory-efficient palette sprites, up to 512×512 |

Config register block for modes 1–5: `MODE, OPTIONS, CONFIG, PLANE, BEGIN, END` at `$1:0:01–06`; mode 0 is shorter (MODE, PLANE, BEGIN, END).

## Displays

`$1:F:00 DISPLAY`:
- 0 = VGA 4:3 (640×480)
- 1 = HD 16:9 (640×480 and 1280×720)
- 2 = SXGA 5:4 (1280×1024)

## ANSI terminal (mode 0)

Full-color ANSI terminal with C0 controls (BS, HT, LF, FF, CR, ESC), Fe escapes (CSI, RIS), standard CSI sequences (CUU/CUD/CUF/CUB/DCH/CUP/ED/EL/SGR/DSR/SCP/RCP/DECTCEM), SGR 30–37/40–47/90–97/100–107, bold, blink. Does not need hardware flow control at 115200.

## Graphics system details (from Ep8, Ep13)

> **Sources**: [[yt-ep08-vga-pix-bus]] (Ep8), [[yt-ep13-graphics-programming]] (Ep13), [[yt-ep15-asset-management]] (Ep15).

### Color model

- **16-bit color** = RGB555 + 1 alpha bit. The alpha bit is binary: opaque or fully transparent (not a blend). This is why 16-bit systems often advertised "32,767 colors" — the 16th bit is the transparency flag.
- Transparency enables each plane to composite cleanly over lower planes.

### Canvas and mode config registers

Extended registers at device `$1`, channel `$0`:

| Addr | Register | Usage |
|---|---|---|
| `$1:0:00` | CANVAS | Selects resolution (0 = console only; 2 = 320×180) |
| `$1:0:01` | MODE | Mode select (0 = console, 3 = bitmap, etc.) |
| `$1:0:02` | OPTIONS | Bit depth and other mode options |
| `$1:0:03` | CONFIG | XRAM address of mode config structure |
| `$1:0:04` | PLANE | Plane number for this mode block |
| `$1:0:05` | BEGIN | First scanline of this mode block |
| `$1:0:06` | END | Last scanline (exclusive) of this mode block |

The `xreg()` OS call is variadic — can set multiple consecutive registers in one call.

### Mode config structure (bitmap example)

Placed in XRAM at any address (must be in extended RAM, not 6502 system RAM):

| Field | Meaning |
|---|---|
| `width` | Bitmap width in pixels |
| `height` | Bitmap height in pixels |
| `x` | Horizontal scroll offset (change live for scrolling) |
| `y` | Vertical scroll offset (change live for scrolling) |
| `data` | XRAM address of pixel data |
| `palette` | XRAM address of palette; `$FFFF` = built-in ANSI palette |

### Scanline-partitioned screens

The `PLANE`, `BEGIN`, and `END` registers allow any scanline range of a plane to use a different mode. Example from Ep13:
- Scanlines 0–139: bitmap mode (plane 0)
- Scanlines 140–179: console/text mode (plane 1)

This technique enables RPG dialogue boxes, HUDs, visual novel lower thirds, and SCUMM-style verb areas — all on a single display frame without sprite/overlay tricks.

### Live X/Y updates during VBLANK

The `x` and `y` fields of the config structure can be changed at any time. For smooth animation, update them inside the VSYNC window (the ~500 µs vertical blanking interval, triggered by the `vsync` register incrementing at 60 Hz). Applications for this:
- Horizontal/vertical scrolling playfields (shooters, platformers)
- Screen shake effects on player hit
- Tiled infinite-repeat backgrounds

### Tiling

Set the tile enable bits in OPTIONS to make the canvas image repeat horizontally and/or vertically. Combined with X/Y scrolling, this creates seamless infinite playfields from a small source image.

### ANSI terminal upgrade (from Ep13)

Console mode (mode 0) was upgraded to **16-bit color** (256-color ANSI palette). Previously 16-color. The 256-color ANSI palette is built in and accessible via `palette = $FFFF`.

### Sprite capabilities (from Ep15)

**Mode 4** sprites support **affine transforms** (3×2 signed 8.8 fixed-point matrix): scale, rotation, translation, occlusion. Up to 24 sprites at 128×128 px; more with smaller sizes.

**Mode 5** sprites do **not** support affine transforms. They use a simpler `(x_pos, y_pos, xram_ptr, palette_ptr)` config and support 1/2/4/8-bit palette color. Sizes: 8×8 to 512×512. You can layer all three planes — e.g. plane 0 = mode 4 affine explosions, plane 1 = mode 5 enemy sprites, plane 2 = mode 5 bullets.

## Related pages

- [[rp6502-ria]] · [[pix-bus]] · [[xreg]] · [[xram]]
- [[sdk-architecture]] — CMake INTERFACE model, RP2350 platform, builder pattern used in VGA firmware
- [[hstx]] — the RP2350 HSTX peripheral used to generate DVI/TMDS video output on Pi Pico 2
- [[yt-ep08-vga-pix-bus]] · [[yt-ep13-graphics-programming]] · [[yt-ep15-asset-management]]
