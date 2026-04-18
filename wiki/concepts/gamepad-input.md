---
type: concept
tags: [rp6502, gamepad, input, hid, usb, controller]
related: [[rp6502-ria]], [[xram]], [[rp6502-ria-w]], [[examples]]
sources: [[rp6502-ria-docs]], [[examples]]
created: 2026-04-18
updated: 2026-04-18
---

# Gamepad Input

**Summary**: The RP6502-RIA supports up to 4 simultaneous USB gamepads via HID, exposing their state as a compact 10-byte-per-player data block in XRAM, addressed through `xreg_ria_gamepad()`.

---

## Enabling gamepad input

```c
xreg_ria_gamepad(0xFF00);   // place gamepad data at XRAM 0xFF00
```

After this call the RIA continuously updates the XRAM block. Data for all 4 players is stored sequentially starting at the given address.

> **Note**: `xreg_ria_gamepad` may not be in the cc65 headers by default. The `gamepad.c` example defines it manually: `#define xreg_ria_gamepad(...) xreg(0, 0, 2, __VA_ARGS__)`

---

## Reading gamepad state

```c
RIA.addr0 = 0xFF00;    // base address
RIA.step0 = 1;
for each player:
    hat    = RIA.rw0;  // dpad + connection + layout
    sticks = RIA.rw0;  // analog stick hat directions
    btns0  = RIA.rw0;  // face buttons + L1/R1
    btns1  = RIA.rw0;  // L2/R2 + menu buttons
    lx     = (int8_t)RIA.rw0;  // left stick X
    ly     = (int8_t)RIA.rw0;  // left stick Y
    rx     = (int8_t)RIA.rw0;  // right stick X
    ry     = (int8_t)RIA.rw0;  // right stick Y
    lt     = RIA.rw0;  // left trigger (0–255)
    rt     = RIA.rw0;  // right trigger (0–255)
```

---

## Data layout (10 bytes per player)

### `hat` byte

| Bit | Meaning |
|-----|---------|
| 7 | `1` = controller connected, `0` = disconnected |
| 6 | `1` = PlayStation button layout (Cross/Circle/Square/Triangle) |
| [3:0] | D-pad direction (see direction table below) |

### Direction encoding (hat bits [3:0], also used for sticks)

| Value | Direction |
|-------|-----------|
| 0x0 | Center / neutral |
| 0x1 | North |
| 0x2 | South |
| 0x4 | West |
| 0x5 | North-West |
| 0x6 | South-West |
| 0x8 | East |
| 0x9 | North-East |
| 0xA | South-East |
| Other | Error/invalid |

### `sticks` byte

| Bits | Meaning |
|------|---------|
| [3:0] | Left analog stick direction (same encoding as hat) |
| [7:4] | Right analog stick direction |

### `btns0` byte

| Bit | Xbox layout | PlayStation layout |
|-----|-------------|-------------------|
| 0 | A | Cross |
| 1 | B | Circle |
| 2 | C | — |
| 3 | X | Square |
| 4 | Y | Triangle |
| 5 | Z | — |
| 6 | L1 | L1 |
| 7 | R1 | R1 |

### `btns1` byte

| Bit | Meaning |
|-----|---------|
| 0 | L2 (digital, also see `lt`) |
| 1 | R2 (digital, also see `rt`) |
| 2 | Select / Back |
| 3 | Start |
| 4 | Home / Guide |
| 5 | L3 (left stick click) |
| 6 | R3 (right stick click) |
| 7 | (reserved) |

### Analog values

| Byte | Type | Range |
|------|------|-------|
| `lx` | int8_t | –128 (full left) to +127 (full right) |
| `ly` | int8_t | –128 (full up) to +127 (full down) |
| `rx` | int8_t | –128 / +127 |
| `ry` | int8_t | –128 / +127 |
| `lt` | uint8_t | 0 (released) to 255 (fully pressed) |
| `rt` | uint8_t | 0 to 255 |

---

## Checking connection

```c
if (!(hat & 0x80)) {
    // controller disconnected
}
```

---

## USB compatibility

Not all USB gamepads work. See [[usb-compatibility]] for the full list of known-incompatible and recommended devices.

**Summary**:
- **XInput devices** (Xbox 360 style wired): incompatible — TinyUSB driver disabled ("TinyUSB is hot garbage on the Pi Pico")
- **Nintendo Switch Pro Controller**: incompatible (even on Windows)
- **USB hubs**: some crash the USB stack
- **Non-modern gamepads** (console emulators): strange button mappings; patches to `pad.c` requested
- **Recommended**: Xbox One/Series via BLE (requires [[rp6502-ria-w]]), DualShock 4 / DualSense via USB

---

## Mouse input

Mouse is handled separately via `xreg_ria_mouse(xaddr)`. The `paint.c` example shows the full pattern: VIA timer at 125 Hz triggers a 6522 interrupt, the ISR reads relative X/Y deltas from XRAM, and accumulates absolute position. See [[vga-graphics]] for the paint demo detail and [[6522-via]] for VIA timer setup.

---

## Related pages

- [[rp6502-ria]] — RIA firmware, input subsystem
- [[xram]] — XRAM addressing
- [[6522-via]] — VIA timer used for mouse IRQ
- [[vga-graphics]] — mouse + paint demo
- [[usb-compatibility]] — full USB/BLE device compatibility list
