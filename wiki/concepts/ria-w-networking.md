---
type: concept
tags: [rp6502, networking, wifi, ble, hayes, modem, telnet, rp6502-ria-w]
related: [[rp6502-ria-w]], [[rp6502-ria]], [[rp6502-os]]
sources: [[rp6502-ria-w-docs]], [[release-notes]], [[rumbledethumps-discord]]
created: 2026-04-18
updated: 2026-04-18
---

# RIA-W Networking

**Summary**: All network features provided by the RP6502-RIA-W firmware — WiFi configuration, NTP time sync, BLE HID input, telnet console access, and Hayes modem emulation for BBS/TCP connectivity.

---

## Overview

Networking is exclusive to the **[[rp6502-ria-w]]** (RIA firmware on a Raspberry Pi Pico 2 **W**). A plain RIA (non-W) has no wireless hardware and no networking. The RIA-W is a strict superset of the plain RIA — all non-networking features are identical.

All networking features are configured from the RP6502 monitor using `SET` commands. The 6502 application accesses networking indirectly: console I/O transparently routes over the active telnet session, and modem devices appear as file-like `AT:` / `AT0:`–`AT9:` handles opened via the OS `open()` call.

---

## WiFi configuration

| Monitor command | Effect |
|---|---|
| `SET RF 0` / `SET RF 1` | Disable / enable all radios (without forgetting settings) |
| `SET RFCC <cc>` or `-` | Country code (e.g. `US`, `GB`, `DE`); `-` = worldwide default |
| `SET SSID <name>` or `-` | WiFi network name |
| `SET PASS <pw>` or `-` | WiFi password |
| `status` | Show current association state |

WiFi connects on boot if SSID and PASS are set and RF is enabled. Once connected, NTP runs automatically.

### NTP time sync

- NTP syncs at **first WiFi connect** and every **24 hours** thereafter.
- Set timezone with `SET TZ <tz>` — accepts POSIX TZ strings or city names (e.g. `US/Eastern`, `Europe/Berlin`).
- DST is handled automatically (cc65 PR #2911).
- The 6502 reads current time via [[rp6502-os]] `clock()` and `time()` calls.

> **Note (v0.14 fix):** NTP previously synced only at power-on. After v0.14 it syncs on first association + every 24 h, so the clock stays correct after an overnight disconnect.

---

## Telnet console (v0.24+)

Provides remote terminal access to the RP6502 monitor (and running 6502 program stdio) over TCP.

| Command | Effect |
|---|---|
| `SET PORT <port>` or `0` | TCP listening port; `0` disables the telnet server; standard telnet port = 23 |
| `SET KEY <key>` or `-` | Passkey required from connecting clients; `-` clears the key requirement |

**Both PORT and KEY must be set** to enable the telnet console. Connections are **unencrypted** in transit — do not expose to untrusted networks without additional protection.

### rp6502.py telnet support (v0.24+)

The `rp6502.py` development tool (used by VSCode for ROM upload) gained telnet support in v0.24. This allows uploading ROMs wirelessly at approximately **56 KB/s** instead of requiring a USB cable. Configure the `.rp6502` project config file with the board's IP address and telnet port.

---

## Hayes modem emulation

Lets 6502 applications connect to BBSs or any TCP host, using the classic AT command set. The modem appears as a character device opened via `open("AT:", …)` or `open("AT0:", …)` through [[rp6502-os]].

### Device names

| Device | Storage | Description |
|---|---|---|
| `AT:` | None (transient) | Factory defaults, no profile storage |
| `AT0:`–`AT9:` | Flash-backed | 10 persistent profiles with settings and 4-slot phonebooks |

Up to **four modem devices** can be open simultaneously.

### AT command reference

| Command | Effect |
|---|---|
| `ATD<host>:<port>` | Dial (connect to) host:port |
| `ATDS=<0-3>` | Dial saved phonebook entry 0–3 |
| `ATA` | Answer incoming call (if listen port configured) |
| `ATH` | Hang up |
| `ATO` | Return to active call from command mode |
| `+++` | Escape sequence: enter command mode while connected |
| `ATE1` / `ATE0` | Echo on / off |
| `ATQ0` / `ATQ1` | Result codes enabled / suppressed |
| `ATV1` / `ATV0` | Verbose / numeric result codes |
| `ATX0` | Progress messaging mode |
| `ATSxxx?` / `ATSxxx=yyy` | Read / write AT register by number |
| `AT&F` | Factory reset (restore defaults) |
| `ATZ` | Reload saved profile |
| `AT&W` | Save current settings to profile |
| `AT&V` | View profile, phonebook, and network settings |
| `AT&Z<0-3>=<host>:<port>` | Save a phonebook entry |
| `AT\L=<port>` / `AT\L?` | Set / query modem listen port for incoming calls |
| `AT\N0` / `AT\N1` | Network mode: `0` = raw TCP, `1` = telnet |
| `AT\N?` | Query current network mode |
| `AT\T=<type>` / `AT\T?` | Set / query telnet terminal type advertisement |
| `AT+RF=`, `AT+RFCC=`, `AT+SSID=`, `AT+PASS=` | Read/write WiFi settings via AT |

Connections are **unencrypted**.

### Modem history

- **v0.12**: Raw TCP modem introduced (no telnet layer).
- **v0.24**: Telnet transport mode added (`AT\N1`); modem profiles expanded from transient-only to 10 flash-backed profiles (`AT0:`–`AT9:`); 4 simultaneous modems; phonebook per profile.

---

## Bluetooth (BLE)

- **BLE only** — Bluetooth Classic (BR/EDR) is not supported.
- `SET BLE 2` → enter pairing mode (board LED blinks). Place the BLE peripheral into pairing mode too.
- Bonds are remembered across reboots.
- Supported devices: BLE keyboards, mice, gamepads.
- BLE HID input (keyboard/mouse/gamepad) merged into the same XREG device map as USB input — the 6502 sees no difference.
- BLE added in **v0.13**.

> BLE has been available since Bluetooth 4.0 (2010) — all wireless keyboards/mice from roughly 2012+ support it.

---

## Development notes

From the 6502 application perspective:
- **Console I/O** (`RIA_TX`/`RIA_RX`, `CON:`, `TTY:`) transparently routes over the active telnet session. No code changes needed.
- **Modem I/O** uses `open("AT0:", O_RDWR)` then `read()`/`write()` like any file.
- WiFi, NTP, and BLE are entirely transparent — no 6502 application code is needed to initiate or maintain connectivity.

---

## Related pages

- [[rp6502-ria-w]] — hardware entity (configuration commands, AT command table, BLE pairing)
- [[rp6502-ria]] — base RIA (non-networking features)
- [[rp6502-os]] — OS API (file I/O used for modem access)
- [[release-notes]] — networking feature history per release
