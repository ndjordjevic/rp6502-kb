---
type: topic
tags: [rp6502, bugs, workarounds, known-issues]
related: [[rp6502-ria]], [[rp6502-ria-w]], [[rp6502-vga]], [[release-notes]]
sources: [[release-notes]]
created: 2026-04-16
updated: 2026-04-16
---

# Known Issues

**Summary**: Bugs, workarounds, and things to watch out for — sourced from release notes v0.1–v0.23.

---

## Critical warnings

### v0.8 — DO NOT USE
v0.8 has a littlefs bug that **prevents formatting the internal filesystem on a brand-new Pi Pico**. If you flash v0.8 on a new Pico, it will fail to initialize and you'll need to reflash. Use v0.9 or later.

### Pi Pico 1 support dropped at v0.10
v0.10 migrated entirely to Pi Pico 2 (RP2350). **Pi Pico 1 boards are not supported in v0.10 or later.** There is no migration path — hardware upgrade required.

---

## Active known issues (as of v0.23)

### Telnet not yet implemented
The Hayes modem (RIA-W) supports **raw TCP connections only**. A full Telnet protocol layer is planned but not yet complete (first noted in v0.12 release notes). The `tel.c` source file is the WIP implementation. For BBS access, raw TCP works with most modern BBS software.

### cc65 requires a fork
v0.14 overhauled the errno system. The upstream `cc65` compiler does not yet include the matching changes — a [PR is pending](https://github.com/cc65/cc65/pull/2844). Until it merges, use the official fork at `github.com/picocomputer/cc65`.

### PHI2 may reset to 100 after upgrade from old firmware
Upgrading from certain older versions (noted in v0.16 release) may cause the stored PHI2 setting to read back as 100 kHz. Fix: `SET PHI2 8000` in the monitor.

### TinyUSB instability (historical, largely resolved)
TinyUSB host mode had long-standing instability issues (noted across v0.7–v0.18). The silicon-level fix arrived in v0.19. As of v0.19+, USB plug events no longer freeze the system. Quirky USB devices may still need special handling — report them upstream.

### TEAC floppy drive (CBI) not working
CBI support for floppy drives was added in v0.18, but the TEAC drive (still available as new-old-stock) does not work. Other 3.5" floppy drives do work as of v0.19. Power adequacy is important for floppy drives.

### Non-standard HID devices
All HID drivers were reworked for BLE support in v0.13. If a keyboard or mouse that worked in v0.12 stopped working, submit an issue with your HID report descriptor. Gamepad compatibility for non-standard devices requires community contributions (`pad.c` has breadcrumbs).

### Bluetooth BR/EDR not supported
Only **Bluetooth LE (BLE)** is supported for wireless HID (keyboards, joysticks, gamepads). Bluetooth Classic (BR/EDR) devices will not connect.

---

## Resolved issues (historical reference)

| Version | Issue | Resolution |
| --- | --- | --- |
| v0.8 | littlefs fails to format new Pico | Fixed in v0.9 (littlefs 2.9.3) |
| v0.12 | VGA not always detected at boot | Fixed in v0.17 (UART startup timing) |
| v0.12 | XInput driver disabled | Re-enabled in v0.18 after TinyUSB stabilization |
| v0.13–v0.18 | USB plug-in momentarily freezes system | Fixed in v0.19 (silicon-level fix to TinyUSB) |
| v0.5 | Mode 2 rendering glitch | Fixed in v0.5 |
| v0.15 | Affine sprites show garbage line | Fixed in v0.15 |
| v0.5 | Hub support spotty | Fixed in v0.11 (hub-in-hub, 16 devices) |

---

## Build / toolchain notes

- **v0.15**: Requires updated `rp6502.py` from `picocomputer/vscode-cc65`. Refresh all `.vscode` and `tools` files from the project template.
- **v0.13+**: Only RIA-W firmware is released as a `.uf2`. Plain RIA must be compiled from source (`picocomputer/rp6502`).
- **v0.10**: Must upgrade Pi Pico 1 boards to Pi Pico 2 — no Pico 1 support.

---

## Related pages

- [[release-notes]] · [[rp6502-ria-w]] · [[rp6502-ria]] · [[rp6502-vga]]
