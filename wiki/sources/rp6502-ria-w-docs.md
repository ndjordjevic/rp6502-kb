---
type: source
tags: [rp6502, ria, wireless, bluetooth, wifi, source]
related: [[rp6502-ria-w]], [[rp6502-ria]]
sources: [picocomputer.github.io/ria_w]
created: 2026-04-15
updated: 2026-04-15
---

# Source — RP6502-RIA-W docs

**Summary**: Differences between the wireless RIA-W firmware and plain [[rp6502-ria]]. Covers WiFi setup, NTP, Hayes modem emulation, and BLE HID pairing.

Raw: [RP6502-RIA-W](<../../raw/web/picocomputer.github.io/RP6502-RIA-W — Picocomputer  documentation.md>)

---

## Key facts

- [[rp6502-ria-w]] = Raspberry Pi Pico 2 **W** + RIA-W firmware. Is a **strict superset** of [[rp6502-ria]] — all RIA features plus wireless.
- **WiFi**: Wi-Fi 4 (802.11n). Configured from monitor: `SET RF`, `SET RFCC <country>`, `SET SSID`, `SET PASS`.
- **NTP**: RTC auto-syncs when online. `SET TZ` for local time; DST handled automatically.
- **Hayes modem emulation** for BBS access, with familiar AT commands:
  - `ATDexample.com:23` dial, `+++` escape, `ATH` hang up, `AT&W` save to NVRAM, `AT&Z0=host:port` save as "telephone number".
  - `AT+SSID=`, `AT+PASS=`, `AT+RFCC=`, `AT+RF=` expose the same RIA settings via AT.
  - **No full telnet stack** yet — all connections are **raw TCP**; unencrypted on the wire.
- **Bluetooth**:
  - **BLE only**. Bluetooth Classic (BR/EDR) is **not** supported.
  - `set ble 2` enters pairing mode; LED blinks, device is bonded after pairing.
  - Pairs with BLE keyboards, mice, gamepads (widely available since BT 4.0, 2010).

## Notable claims / quirks

- Telephone numbers are saved **immediately**, not as part of an AT profile.
- Full telnet negotiation is **not** implemented.

## Related pages

- [[rp6502-ria-w]] · [[rp6502-ria]]
