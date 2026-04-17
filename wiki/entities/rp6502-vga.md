---
type: entity
tags: [rp6502, vga, video, firmware, pico2, hstx, dvi, tmds]
related: [[rp6502-ria]], [[pix-bus]], [[xreg]], [[xram]], [[sdk-architecture]], [[hstx]]
sources: [[rp6502-vga-docs]], [[pico-c-sdk]], [[rp2350-datasheet]]
created: 2026-04-15
updated: 2026-04-17
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

## Related pages

- [[rp6502-ria]] · [[pix-bus]] · [[xreg]] · [[xram]]
- [[sdk-architecture]] — CMake INTERFACE model, RP2350 platform, builder pattern used in VGA firmware
- [[hstx]] — the RP2350 HSTX peripheral used to generate DVI/TMDS video output on Pi Pico 2
