---
type: concept
tags: [rp6502, xreg, pix, configuration]
related: [[pix-bus]], [[xram]], [[rp6502-ria]], [[rp6502-vga]], [[rp6502-os]], [[programmable-sound-generator]], [[opl2-fm-synth]]
sources: [[rp6502-ria-docs]], [[rp6502-vga-docs]], [[rp6502-os-docs]]
created: 2026-04-15
updated: 2026-04-15
---

# XREG — Extended Registers

**Summary**: How the 6502 configures any [[pix-bus]] device — a single OS call that broadcasts a "set register N on device D channel C to value V" frame.

---

## The mechanism

Every PIX device has up to **16 channels × 256 registers**, addressed `$device:$channel:register` (e.g. `$1:0:0F`). Setting one is done via an OS call:

```c
int xreg(char device, char channel, unsigned char address, ...);
int xregn(char device, char channel, unsigned char address, unsigned count, ...);
```

The variadic args are 16-bit values stored in successive registers starting at `address`. Use `xreg()` from C (it counts for you); `xregn()` is the explicit-count form for assembly.

OS op: `RIA_OP_XREG 0x01`. Errors: `EINVAL` (device NAK'd), `EIO` (timeout).

## What XREGs do

XREGs are **not** general-purpose RAM. They are configuration latches that turn features on/off and tell devices where to find their data structures in [[xram]]. The pattern across the entire RP6502 is:

1. Pick an XRAM address for the data structure (e.g. mouse state, OPL2 register image, VGA mode-3 framebuffer config).
2. `xreg(device, channel, addr, xram_pointer)` — install it.
3. Read/write the structure in XRAM as needed.
4. `xreg(device, channel, addr, 0xFFFF)` — disable (writing an invalid address).

## Concrete examples

### Enable keyboard / mouse / gamepads on the RIA (device 0)

```c
xreg(0, 0, 0x00, xaddr); // keyboard
xreg(0, 0, 0x01, xaddr); // mouse
xreg(0, 0, 0x02, xaddr); // gamepads (4× 10 bytes)
```

### Enable PSG / OPL2 on the RIA (device 0, channel 1)

```c
xreg(0, 1, 0x00, xaddr); // PSG (64-byte config, int-aligned, no page cross)
xreg(0, 1, 0x01, xaddr); // OPL2 (256-byte register image, page-aligned)
```

See [[programmable-sound-generator]] and [[opl2-fm-synth]] for the audio register layouts.

### Configure a VGA video mode (device 1)

```c
xreg(1, 0, 0, 1);                     // canvas: 320x240
xreg(1, 0, 1, 3, /*opt*/2, 0xFF00);   // mode 3 (bitmap), 4-bit color, config @ $FF00
```

### Use as feature detection

A device that doesn't support an XREG returns NAK (`EINVAL`). So calling a feature-specific XREG is a probe.

## Permission model

- `$device:0:..` is for application-level features.
- `$device:F:..` is the **control channel**, managed by the RIA — applications shouldn't write here. (e.g. `$1:F:00 DISPLAY` sets the display aspect ratio on the VGA.)

## Related pages

- [[pix-bus]] · [[xram]] · [[rp6502-ria]] · [[rp6502-vga]] · [[rp6502-os]]
