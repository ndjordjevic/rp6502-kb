---
type: concept
tags: [rp6502, vga, display, modes, xram, xreg, canvas, vsync]
related: [[rp6502-vga]], [[xram]], [[xreg]], [[pix-bus]], [[vga-graphics]], [[programmable-sound-generator]]
sources: [[rp6502-vga-docs]], [[examples]]
created: 2026-04-18
updated: 2026-04-18
---

# VGA Display Modes

**Summary**: The RP6502-VGA firmware supports 6 compositable display modes (0–5) selected and configured via `xreg` calls; each mode reads its rendering parameters from an XRAM config struct, and multiple modes can be layered on a single canvas.

---

## Canvas

Before setting modes, choose a canvas resolution with `xreg_vga_canvas(n)`:

| Canvas | Resolution | Typical use |
|--------|------------|-------------|
| 1 | 320×240 | Sprites, tile graphics, game logic |
| 2 | 320×180 | Widescreen (16:9) bitmap, Altair demo |
| 3 | 640×480 | Text mode (mode 1 at 80×60 or 40×30) |

The canvas defines the coordinate space; all mode configs use pixel offsets within it.

---

## Mode 0 — Console / ANSI terminal

```c
xreg_vga_mode(0);       // clear/disable overlay
xreg_vga_mode(0, 1);    // enable color console
```

Built-in ANSI terminal. No XRAM config needed. Supports ANSI escape codes for color, cursor movement, and scrolling. See [[code-pages]] for character set selection.

---

## Mode 1 — Text / tile mode

Config struct: `vga_mode1_config_t`. Typically placed at `0xFF00` in XRAM.

| Field | Type | Description |
|-------|------|-------------|
| `x_wrap` / `y_wrap` | bool | Wrap scrolling at edges |
| `x_pos_px` / `y_pos_px` | int | Scroll offset in pixels |
| `width_chars` / `height_chars` | int | Tilemap dimensions (e.g. 40×30) |
| `xram_data_ptr` | uint16 | XRAM base of cell data |
| `xram_palette_ptr` | uint16 | XRAM palette (0xFFFF = default) |
| `xram_font_ptr` | uint16 | XRAM font bitmap (0xFFFF = default) |

**Cell format**: 3 bytes per cell — `char_code`, `fg_color`, `bg_color`.

```c
xreg_vga_canvas(3);                                         // 640×480 for text
xram0_struct_set(0xFF00, vga_mode1_config_t, width_chars, 40);
xram0_struct_set(0xFF00, vga_mode1_config_t, height_chars, 30);
xram0_struct_set(0xFF00, vga_mode1_config_t, xram_data_ptr, 0x0000);
xram0_struct_set(0xFF00, vga_mode1_config_t, xram_font_ptr, 0xFFFF); // default font
xreg_vga_mode(1, 3, 0xFF00);    // submode 3 = 40×30 text
```

Scrolling: update `x_pos_px`/`y_pos_px` each frame (synced to `RIA.vsync`).

---

## Mode 2 — Tile bitmap mode

Config struct: `vga_mode2_config_t`.

| Field | Type | Description |
|-------|------|-------------|
| `x_wrap` / `y_wrap` | bool | Scrolling wrap |
| `x_pos_px` / `y_pos_px` | int | Pixel scroll offset |
| `width_tiles` / `height_tiles` | int | Map dimensions in tiles |
| `xram_data_ptr` | uint16 | Cell index array |
| `xram_palette_ptr` | uint16 | Color palette |
| `xram_tile_ptr` | uint16 | Tile bitmap data |

Sub-modes:
- `xreg_vga_mode(2, 0, 0xFF00)` — 1bpp tiles (monochrome, 2 colors)
- `xreg_vga_mode(2, 8, 0xFF00)` — 8bpp tile cells (each cell is a 16×16 8-bit bitmap)

Tile data stored at `xram_tile_ptr`; cell indices in `xram_data_ptr`.

---

## Mode 3 — Planar / chunky bitmap

Config struct: `vga_mode3_config_t`. Most flexible bitmap mode — supports 5 color depths and multiple simultaneous layers.

| Field | Type | Description |
|-------|------|-------------|
| `x_wrap` / `y_wrap` | bool | Torus wrap |
| `x_pos_px` / `y_pos_px` | int | Pixel scroll offset |
| `width_px` / `height_px` | int | Bitmap dimensions in pixels |
| `xram_data_ptr` | uint16 | Pixel data in XRAM |
| `xram_palette_ptr` | uint16 | Palette (0xFFFF = default 256-entry) |

Color depths via submode argument:

| Submode | BPP | Colors | Byte address formula |
|---------|-----|--------|----------------------|
| 0 | 1 | 2 | `row*width/8 + col/8` (bitfield) |
| 1 | 2 | 4 | `row*width/4 + col/4` (2 bits/pixel) |
| 2 | 4 | 16 | `row*width/2 + col/2` (nibble) |
| 3 | 8 | 256 | `row*width + col` |
| 4 | 16 | 65535 | `row*2*width + col*2` (2 bytes/pixel) |
| 10 | 4 | 16 | Used in mandelbrot.c full-screen |

```c
xreg_vga_mode(3, 3, 0xFF00);   // 8bpp, config at 0xFF00
```

Multiple mode-3 layers (different config pointers, incrementing layer index) can be composited. The `paint.c` example uses 3 simultaneous mode-3 layers (canvas + picker + pointer).

**16bpp pixel format**: BGAR5515 (Blue 5 bits, Green 5 bits, Alpha 1 bit, Red 5 bits). Transparency bit set = opaque.

---

## Mode 4 — Sprite mode

Two sprite sub-types: simple (`vga_mode4_sprite_t`) and affine (`vga_mode4_asprite_t`). See [[vga-graphics]] for the full struct layout.

```c
xreg_vga_mode(4, 0, config_ptr, sprite_count);   // simple sprites
xreg_vga_mode(4, 1, config_ptr, sprite_count);   // affine sprites
```

---

## Mode 5 — Multi-sprite mode

High-performance sprite layer that accepts an array of compact 8-byte configs. Sprite data can be 1bpp (monochrome) or 2bpp (4-color). Sprite size encoded in submode bits [5:3] as a power-of-two exponent (0=none, 1=16×16, ..., 5=256×256).

```c
xreg_vga_mode(5, 0x00, config_ptr, count, layer);   // 1bpp 8×8 sprites
xreg_vga_mode(5, 0x0A, config_ptr, count, layer);   // 16×16 4bpp sprites
```

8-byte sprite config: `x_pos(2), y_pos(2), xram_bitmap_ptr(2), xram_palette_ptr(2)`.

Color format for 2bpp: 4-entry palette of BGAR5515 values, index 0 = transparent.

---

## VSYNC synchronization

`RIA.vsync` is a byte counter that increments once per display frame (~60 Hz). Spin-wait for change to sync to the next frame:

```c
uint8_t v = RIA.vsync;
while (RIA.vsync == v)  // wait for next frame
    ;
v = RIA.vsync;
// update XRAM here (vblank window)
```

For interrupt-driven sync, set `RIA.irq = 1` and install an ISR with `set_irq()`.

---

## Compositing multiple modes

Modes are drawn in layer order. A typical scene:

```c
xreg_vga_mode(0, 1);              // layer 0: ANSI console
xreg_vga_mode(5, ..., layer=1);   // layer 1: background sprites
xreg_vga_mode(4, ..., layer=2);   // layer 2: foreground sprites
```

Each `xreg_vga_mode()` call adds one render pass per frame. There is no hard limit on layers but each consumes scanline time.

---

## Related pages

- [[rp6502-vga]] — VGA firmware entity
- [[vga-graphics]] — VGA graphics techniques (sprites, affine transforms, dual-port writes)
- [[xram]] — where all display config structs and pixel data live
- [[xreg]] — how `xreg_vga_mode()` and `xreg_vga_canvas()` work
- [[pix-bus]] — broadcast path from 6502 writes to VGA firmware
