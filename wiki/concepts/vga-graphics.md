---
type: concept
tags: [rp6502, vga, sprites, affine, blit, dual-port, bgar5515, graphics]
related: [[vga-display-modes]], [[xram]], [[rp6502-vga]], [[examples]]
sources: [[examples]]
created: 2026-04-18
updated: 2026-04-18
---

# VGA Graphics Techniques

**Summary**: Practical patterns for sprite blitting, affine transforms, palette manipulation, and high-throughput XRAM writes — all derived from the official picocomputer/examples source code.

---

## Sprite data format (BGAR5515)

Mode-4 sprites use a 16-bit-per-pixel format called **BGAR5515**:

| Bits | Field | Size |
|------|-------|------|
| [15:11] | Blue | 5 bits |
| [10:6] | Green | 5 bits |
| [5] | Alpha (opacity) | 1 bit — **must be 1 for opaque pixels** |
| [4:0] | Red | 5 bits |

Macro from `mode5.c`:
```c
#define COLOR_FROM_RGB5(r, g, b) \
    (((unsigned)(b) << 11) | ((unsigned)(g) << 6) | (unsigned)(r))
#define COLOR_ALPHA (1u << 5)

// Usage:
unsigned color = COLOR_FROM_RGB5(28, 20, 16) | COLOR_ALPHA;  // opaque skin tone
```

The `has_opacity_metadata` field in the sprite config tells the VGA whether to perform per-pixel alpha testing.

---

## Mode-4 simple sprite (vga_mode4_sprite_t)

8-byte struct in XRAM per sprite:

| Field | Type | Description |
|-------|------|-------------|
| `x_pos_px` | int16 | X screen position |
| `y_pos_px` | int16 | Y screen position |
| `xram_sprite_ptr` | uint16 | XRAM address of pixel data |
| `log_size` | uint8 | Log₂ of sprite edge length (e.g. 7 = 128×128) |
| `has_opacity_metadata` | bool | Enable alpha testing |

```c
xram0_struct_set(ptr, vga_mode4_sprite_t, log_size, 7);   // 128×128
xram0_struct_set(ptr, vga_mode4_sprite_t, has_opacity_metadata, true);
xreg_vga_mode(4, 0, SPRITE_CONFIG, SPRITE_LENGTH);
```

---

## Mode-4 affine sprite (vga_mode4_asprite_t)

Same as simple but adds a 2×3 affine transform matrix (6 `int16` values). Identity matrix = no transformation:

```
transform[0..5] = { scale_x, shear_x, tx, shear_y, scale_y, ty }
identity        = { 256, 0, 0, 0, 256, 0 }   // 256 = 1.0 in Q8 fixed-point
```

Uniform scale — larger value = smaller sprite (inverse scale):

```c
int scale = 256;   // 1× — range 256–768 = 0.5× to 3× in affine.c demo
xram0_struct_set(ptr, vga_mode4_asprite_t, transform[0], scale);
xram0_struct_set(ptr, vga_mode4_asprite_t, transform[4], scale);
xram0_struct_set(ptr, vga_mode4_asprite_t, transform[1], 0);   // no shear
xram0_struct_set(ptr, vga_mode4_asprite_t, transform[3], 0);
```

Enable affine sprites: `xreg_vga_mode(4, 1, config, count)`.

---

## Dual-port XRAM write (high throughput)

The RIA has two independent XRAM access ports (`addr0/step0`, `addr1/step1`). Writing interleaved values over both ports doubles effective bandwidth:

```c
// Update all X positions in one pass, then all Y positions.
// step = sizeof(struct) strides through the sprite array.
RIA.step0 = sizeof(vga_mode4_sprite_t);
RIA.step1 = sizeof(vga_mode4_sprite_t);
RIA.addr0 = SPRITE_CONFIG;        // x_pos_px low byte
RIA.addr1 = SPRITE_CONFIG + 1;    // x_pos_px high byte
for (i = 0; i < SPRITE_LENGTH; i++) {
    int val = sprites[i].x;
    RIA.rw0 = val & 0xff;
    RIA.rw1 = (val >> 8) & 0xff;
}
// Then repeat for y_pos_px (offset +2/+3)
```

This is the standard pattern for updating many sprites per frame within the vblank window.

---

## Pixel-level XRAM writes (mode 3)

8bpp — linear, one byte per pixel:
```c
RIA.addr0 = y * width + x;
RIA.step0 = 1;
RIA.rw0 = color;
```

4bpp read-modify-write — two pixels per byte (upper nibble = left pixel):
```c
RIA.step0 = 0;
RIA.addr0 = y * (width/2) + x/2;
if (x & 1)
    RIA.rw0 = (RIA.rw0 & 0xF0) | color;     // right nibble
else
    RIA.rw0 = (RIA.rw0 & 0x0F) | (color << 4);  // left nibble
```

16bpp — two bytes per pixel, little-endian:
```c
RIA.addr0 = y * 2*width + x*2;
RIA.step0 = 1;
RIA.rw0 = color & 0xFF;
RIA.rw0 = color >> 8;
```

---

## Mandelbrot: fixed-point arithmetic for 8-bit

`mandelbrot.c` uses Q12 signed fixed-point (`fint32_t = int32_t`, 12 fractional bits) to render the full 320×240 set in 16 iterations per pixel. Key macro:

```c
#define FRAC_BITS 12
#define FINT32(whole, frac) (((fint32_t)whole << FRAC_BITS) | (frac >> (16 - FRAC_BITS)))
```

Unrolled XRAM writes (groups of 8) significantly speed up screen clearing:

```c
for (i = 0x1300; --i;) {
    RIA.rw0 = 0; RIA.rw0 = 0; RIA.rw0 = 0; RIA.rw0 = 0;
    RIA.rw0 = 0; RIA.rw0 = 0; RIA.rw0 = 0; RIA.rw0 = 0;
}
```

---

## Mouse input + VGA overlay (paint.c)

The `paint.c` example shows the full mouse + VGA pattern:

1. **VIA timer** generates 125 Hz interrupts: `timer_val = (ria_attr_get(RIA_ATTR_PHI2_KHZ) * 8) - 2`
2. **Mouse ISR** reads `MOUSE_INPUT + 1/2` from XRAM for delta X/Y; updates `mouse_pos_x/y`
3. **Pointer sprite** is a mode-3 layer at `POINTER_STRUCT` (10×10 px, 4bpp)
4. **Canvas** = mode-3 8bpp at full canvas size
5. **Color picker** = third mode-3 layer, dragable

See [[vga-display-modes]] for the mode-3 layer stacking call:
```c
xreg_vga_mode(3, 2, CANVAS_STRUCT, 0);
xreg_vga_mode(3, 3, PICKER_STRUCT, 1);
xreg_vga_mode(3, 3, POINTER_STRUCT, 2);
```

---

## CMake asset loading (altair example)

Binary assets can be embedded in a ROM and loaded directly to XRAM at program start:

```cmake
rp6502_asset(altair 0x10000 src/altair.pal.bin)   # palette to XRAM 0x0000
rp6502_asset(altair 0x10200 src/altair.dat.bin)   # bitmap data to XRAM 0x0200
```

In C: the assets are available immediately — no `fopen`/`read` needed. See [[rom-file-format]] for asset chunk structure.

---

## Related pages

- [[vga-display-modes]] — mode 0–5 reference, canvas, VSYNC
- [[xram]] — XRAM addressing and bandwidth
- [[rp6502-vga]] — VGA firmware entity
- [[rom-file-format]] — CMake asset embedding
