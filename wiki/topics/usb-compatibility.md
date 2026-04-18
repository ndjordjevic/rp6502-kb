---
type: topic
tags: [rp6502, usb, ble, gamepad, compatibility, xinput, dinput, tinyusb]
related: [[gamepad-input]], [[rp6502-ria]], [[rp6502-ria-w]], [[usb-controller]]
sources: [[community-wiki]], [[rumbledethumps-discord]]
created: 2026-04-18
updated: 2026-04-18
---

# USB and BLE Device Compatibility

**Summary**: Not all USB gamepads and BLE controllers work with the RP6502. This page lists known-incompatible categories and recommended alternatives, with design context from `rumbledethumps`.

---

## Known-incompatible devices

### USB XInput devices (all)

All USB XInput devices (Xbox 360-style wired controllers and any gamepad exposing an XInput interface) are **incompatible**.

A TinyUSB XInput driver was written but is permanently disabled. Reason given by `rumbledethumps`:

> "TinyUSB is hot garbage on the Pi Pico so it's disabled."
> — `(@rumbledethumps, community wiki, #Incompatible-USB-and-BLE-Devices)`

**Workaround**: Many controllers that default to XInput can be switched to **DInput mode** — check the controller manual for a DInput mode button combination.

### Non-modern gamepads (console emulation)

Gamepads designed to emulate old game consoles (NES, SNES, etc.) often have strange button mappings and may not be recognized correctly.

**Workaround**: Submit a patch to `pad.c` in the RP6502 firmware to add support.

### Nintendo Switch Pro Controller

Incompatible, despite being technically plain HID.

> "These are supposed to be plain HID but mine doesn't even work on Windows."
> — `(@rumbledethumps, community wiki, #Incompatible-USB-and-BLE-Devices)`

No known workaround.

### USB hubs (some)

Some USB hubs crash the USB stack when inserted between the RP6502 and the gamepad. Specific hub models have not been documented — affected users typically solved the issue by removing the hub.

**Workaround**: Connect the gamepad directly to the RP6502 USB port without a hub.

---

## Recommended devices

| Device | Connection | Notes |
|--------|-----------|-------|
| Microsoft Xbox One / Xbox Series S\|X controller | **BLE** (Bluetooth LE) | Official Microsoft hardware; requires [[rp6502-ria-w]] for BLE support |
| Sony DualShock 4 (DS4) | **USB** | Works on standard RP6502-RIA |
| Sony DualSense (DS5) | **USB** | Works on standard RP6502-RIA |

> "Any gamepad that looks like it belongs on XBox, Windows or PlayStation is a recommended gamepad."
> — `(@rumbledethumps, community wiki, #Incompatible-USB-and-BLE-Devices)`

---

## Design context

The XInput incompatibility is a permanent firmware decision, not a bug. The TinyUSB USB host stack running on RP2040/RP2350 has quality issues that made the XInput driver unreliable. Rather than ship a broken driver, `rumbledethumps` disabled it. DInput-mode controllers use the standard HID path which is unaffected.

For BLE controllers, the wireless stack is only available on the [[rp6502-ria-w]] variant.

---

## Related pages

- [[gamepad-input]] — API, data layout, reading gamepad state
- [[rp6502-ria]] — standard RIA with USB host
- [[rp6502-ria-w]] — wireless RIA with BLE support
- [[usb-controller]] — TinyUSB USB host internals
- [[community-wiki]] — source page
