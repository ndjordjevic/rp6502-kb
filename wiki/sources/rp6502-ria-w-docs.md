---
type: source
tags: [rp6502, ria, wireless, bluetooth, wifi, source]
related: [[rp6502-ria-w]], [[rp6502-ria]]
sources: [picocomputer.github.io/ria_w]
created: 2026-04-15
updated: 2026-04-18
---

# Source — RP6502-RIA-W docs

**Summary**: Differences between the wireless RIA-W firmware and plain [[rp6502-ria]]. Covers WiFi setup, NTP, Telnet Console, Hayes modem emulation (with full telnet), and BLE HID pairing.

Raw: [RP6502-RIA-W](<../../raw/web/picocomputer.github.io/RP6502-RIA-W — Picocomputer  documentation.md>)

> **Note**: Raw file reflects the April 15 scrape. The live docs were updated April 18 ("networking" commit) adding the Telnet Console section and full telnet modem support. Wiki reflects the current live docs.

---

## Key facts

- [[rp6502-ria-w]] = Raspberry Pi Pico 2 **W** + RIA-W firmware. Is a **strict superset** of [[rp6502-ria]] — all RIA features plus wireless.
- **WiFi**: Wi-Fi 4 (802.11n). Configured from monitor: `SET RF`, `SET RFCC <country>`, `SET SSID`, `SET PASS`.
- **NTP**: RTC auto-syncs when online. `SET TZ` for local time; DST handled automatically.
- **Telnet Console** (added April 18): Remote network access to the monitor / 6502 stdio.
  - `SET PORT <n>` (0 = off) and `SET KEY <key>` — both required to enable. Unencrypted.
- **Hayes modem emulation** for BBS access:
  - Device names: `AT:` (transient) or `AT0:`–`AT9:` (10 persistent profiles, 4-slot phonebook).
  - Supports **raw TCP** (`AT\N0`) and **telnet** (`AT\N1`).
  - `AT\L=<port>` for inbound calls; `AT\T=<type>` for telnet terminal type.
  - Up to **4 simultaneous modem devices**.
  - `AT+SSID=`, `AT+PASS=`, `AT+RFCC=`, `AT+RF=` expose RIA settings via AT.
  - Unencrypted in transit.
- **Bluetooth**:
  - **BLE only**. Bluetooth Classic (BR/EDR) is **not** supported.
  - `set ble 2` enters pairing mode; LED blinks, device is bonded after pairing.
  - Pairs with BLE keyboards, mice, gamepads (widely available since BT 4.0, 2010).

## Notable claims / quirks

- Telephone numbers are saved **immediately**, not as part of an AT profile.

## Related pages

- [[rp6502-ria-w]] · [[rp6502-ria]]
