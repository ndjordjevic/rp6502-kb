# picocomputer/community wiki — Ingest Plan

**Source**: https://github.com/picocomputer/community/wiki (2 pages — fetch via WebFetch)
**Priority**: HIGH
**Approach**: Two wiki pages, small content. Single session. No submodule needed.

---

## Strategy

The community wiki has two pages. The *Incompatible USB and BLE Devices* page is the higher-value target — it contains hard-won community knowledge about hardware gotchas (XInput lock-out, USB hub crashes, specific gamepad quirks) that belongs in our wiki. The *Home* page is a project directory useful for a community-projects overview page.

---

## Reading order

- [ ] **Home page** — https://github.com/picocomputer/community/wiki/Home
  - Catalogue all listed projects by category (games, apps, BASIC, utilities, hardware)
  - Note any projects that reveal undocumented RP6502 features or APIs
  → Create `wiki/topics/community-projects.md`

- [ ] **Incompatible USB and BLE Devices** — https://github.com/picocomputer/community/wiki/Incompatible-USB-and-BLE-Devices
  - Extract every device/category listed (XInput, non-modern gamepads, Nintendo Switch Pro, USB hubs)
  - Note any workarounds (DInput mode, recommended alternatives)
  - Note author commentary on TinyUSB quality on Pi Pico (design context)
  - Recommended working devices: Xbox One/Series BLE, DS4/DS5 USB
  → Create `wiki/topics/usb-compatibility.md`
  → Update `wiki/concepts/gamepad-input.md` with compatibility notes (cross-link)

---

## Wiki pages to create or update

| Page | Action |
|------|--------|
| `wiki/sources/community-wiki.md` | Create — source summary page |
| `wiki/topics/community-projects.md` | Create — curated project directory |
| `wiki/topics/usb-compatibility.md` | Create — incompatible/compatible device list |
| `wiki/concepts/gamepad-input.md` | Update with USB compatibility cross-reference |
| `wiki/index.md` | Update with new pages |
| `wiki/overview.md` | Add note on community project ecosystem |
| `wiki/log.md` | Append ingest entry |
| `PROGRESS.md` | Flip status |

---

## Notes

- Key facts already known from fetch (use as starting point, do not re-derive):
  - XInput devices: all incompatible; TinyUSB driver was written but disabled ("TinyUSB is hot garbage on the Pi Pico")
  - Nintendo Switch Pro Controller: incompatible even on Windows
  - USB hubs: some crash the stack; specific models unknown
  - Recommended: Xbox One/Series (BLE), DS4/DS5 (USB)
  - Non-modern gamepads: strange button mappings; patches to `pad.c` requested
- The TinyUSB comment is a design-decision quote from `rumbledethumps` — cite as `(@rumbledethumps, community wiki, #Incompatible-USB-and-BLE-Devices)`.
- Check whether `wiki/sources/rumbledethumps-discord.md` already covers any of this; avoid duplication.
