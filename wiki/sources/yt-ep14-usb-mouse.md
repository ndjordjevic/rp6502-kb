---
type: source
tags: [rp6502, youtube, input, mouse, hid, keyboard, stdio]
related: [[rp6502-os]], [[rp6502-ria]], [[xram]], [[development-history]]
sources: [[youtube-playlist]]
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep14 — USB Mouse on a 6502

**Summary**: Introduces the three input modes (UART stdio, HID keyboard bit-array, mouse integer counters), announces `fgets()` line editor addition, and demonstrates a paint program using direct mouse input.

---

## Key topics

- **Three input modes** — evolution of the input system:
  1. **UART stdio** (console): `printf()`/`fgets()` over standard I/O. `fgets()` was added in this release, completing the stdio system.
  2. **HID keyboard bit-array**: 256-bit array in XRAM (one bit per HID keycode); bit 0 = "no keys pressed". Enables detection of held keys and releases, not just key-down events.
  3. **Mouse integer counters**: X/Y integer counters increment/decrement with movement; subtract previous from current for delta. Set via xreg in XRAM.
- **Keyboard mode**: set XRAM location via `$0:0:00` xreg; check bits using RIA registers. No matrix decoding needed.
- **Community**: parallax scrolling demos appeared in forums less than a week after Ep13's canvas/plane system was released.
- **Paint program demo**: per-mouse-button color selection, draggable toolbar, eraser; demonstrates lag-free mouse movement ("as good as any modern system").
- **Hardware**: wireless USB optical mouse works directly via USB host.

## Related pages

- [[rp6502-os]] — input mode documentation
- [[rp6502-ria]] — XREG device map for input (keyboard $0:0:00, mouse $0:0:01)
- [[xram]] — bit-array and counter storage location
