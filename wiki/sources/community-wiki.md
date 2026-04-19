---
type: source
tags: [rp6502, community, projects, usb, gamepad, compatibility]
related:
  - "[[community-projects]]"
  - "[[usb-compatibility]]"
  - "[[gamepad-input]]"
sources: []
created: 2026-04-18
updated: 2026-04-18
---

# Community Wiki

**Summary**: The picocomputer/community GitHub wiki (two pages) — a community-maintained directory of software/hardware projects and a compatibility list for USB and BLE input devices.

---

## Source details

| Field | Value |
|-------|-------|
| URL | https://github.com/picocomputer/community/wiki |
| Clone | `raw/github/picocomputer/community/` (commit `348180a`, 2026-04-18) |
| Pages | 2 — *Home*, *Incompatible USB and BLE Devices* |
| Authority | Community-maintained; curated by `rumbledethumps` |

---

## Key facts

### Home page — project directory

A volunteer-maintained list of games, applications, BASIC resources, utilities/techniques, and hardware cases built on RP6502. Organized by category. See [[community-projects]] for the full catalogue with descriptions.

### Incompatible USB and BLE Devices page

Documents hardware that does not work with the RP6502 input subsystem, and recommends alternatives. See [[usb-compatibility]] for the full device list.

Key design context quoted directly:

> "I wrote a driver, but TinyUSB is hot garbage on the Pi Pico so it's disabled."
> — `@rumbledethumps`, community wiki, #Incompatible-USB-and-BLE-Devices

This explains why XInput (Xbox 360-style wired) controllers are permanently disabled despite having a TinyUSB driver.

---

## Scope

- [x] Home page — project directory by category
- [x] Incompatible USB and BLE Devices — compatibility list + design rationale

---

## Related pages

- [[community-projects]] — full project catalogue
- [[usb-compatibility]] — USB/BLE device compatibility list
- [[gamepad-input]] — gamepad API + data layout
- [[rumbledethumps-discord]] — community discussion context
