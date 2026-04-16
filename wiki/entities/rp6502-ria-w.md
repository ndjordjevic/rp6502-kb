---
type: entity
tags: [rp6502, ria, wireless, wifi, bluetooth, pico2w]
related: [[rp6502-ria]], [[rp6502-board]]
sources: [[rp6502-ria-w-docs]], [[release-notes]]
created: 2026-04-15
updated: 2026-04-16
---

# RP6502-RIA-W

**Summary**: A **strict superset of [[rp6502-ria]]**: same firmware family, flashed onto a Raspberry Pi Pico 2 **W**, adds WiFi, BLE, NTP, and Hayes modem emulation.

---

## Hardware role

- Occupies slot **U2** on the [[rp6502-board]] (Raspberry Pi Pico 2 W — the only difference from slot U4 is that U2 has the wireless radio).
- All RIA features from [[rp6502-ria]] are present; this page only covers the wireless additions.

## WiFi (Wi-Fi 4 / 802.11n)

Configured from the monitor:

| Command | Effect |
| --- | --- |
| `SET RF 0`/`1` | Disable / enable all radios without touching settings |
| `SET RFCC <cc>` or `-` | Country code (e.g. `US`, `GB`); `-` = worldwide default |
| `SET SSID <name>` or `-` | Network SSID |
| `SET PASS <pw>` or `-` | Network password |
| `status` | Show current WiFi state |

Once associated, NTP runs automatically. Set time zone with `SET TZ`; DST handled automatically. See [[rp6502-os]] for the programmatic clock API.

## Hayes modem emulation

Lets 6502 apps dial into BBSs over raw TCP.

| AT command | Effect |
| --- | --- |
| `ATDexample.com:23` | "Dial" a host:port |
| `+++` | Escape to command mode |
| `ATH` | Hang up |
| `ATE1`, `ATV1`, `ATX0` | Echo / verbosity / progress messaging |
| `ATSxxx?` / `ATSxxx=yyy` | Register query / set |
| `AT&F` / `ATZ` / `AT&W` | Factory / NVRAM load / NVRAM save |
| `AT&V` | View profile |
| `AT&Z0=host:port` | Save "telephone number" to NVRAM (immediate, not per-profile) |
| `AT+RF=`, `AT+RFCC=`, `AT+SSID=`, `AT+PASS=` | Expose same-named RIA settings via AT |

> **Gotcha:** no telnet stack yet — all connections are **raw TCP**. Unencrypted in transit. The v0.12 release notes confirm: "modem supports raw TCP only — full Telnet layer is still in the works." `src/ria/net/tel.c` is the WIP implementation.

## Bluetooth

- **BLE only**. Bluetooth Classic (BR/EDR) is **not** supported.
- `set ble 2` → pairing mode (LED blinks). Put the peripheral into its own pairing mode; bond is remembered.
- Pairs with BLE keyboards, mice, gamepads. BLE has been ubiquitous since BT 4.0 (2010).

## Related pages

- [[rp6502-ria]] — everything else the RIA does
- [[rp6502-board]]
- [[known-issues]] — telnet WIP, BLE-only limitations, TinyUSB history
