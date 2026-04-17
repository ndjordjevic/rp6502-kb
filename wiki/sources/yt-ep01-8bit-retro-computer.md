---
type: source
tags: [rp6502, youtube, hardware, vga, usb, monitor, prototype]
related: [[development-history]], [[rp6502-board]], [[rp6502-ria]], [[rp6502-vga]], [[memory-map]], [[youtube-playlist]]
sources: [[youtube-playlist]]
video_id: SVZaSRUhIjo
episode: 1
approx_date: 2022-11
created: 2026-04-17
updated: 2026-04-17
---

# Ep1 — The start of an 8-bit Retro Gaming Computer

**Summary**: Series introduction — the author presents the Picocomputer vision: Pi Pico + 6502 + 64 K RAM with 12 glue chips, VGA video, USB HID, and PWM audio. The USB stack and VGA terminal are already working on the breadboard.

**Video**: [https://www.youtube.com/watch?v=SVZaSRUhIjo](https://www.youtube.com/watch?v=SVZaSRUhIjo)

---

## Key topics

- **Initial design targets** — Pi Pico + 6502 + 64 K RAM + 12 glue chips. No ROM, no PS/2, no RS-232 required. Planned features: VGA video, PWM audio, USB keyboard/mouse/joystick/storage, expansion slots.
- **Two Pi Picos on breadboard** — main Pi Pico (USB host) + second Pi Pico as debug probe/console (USB device). Author notes this was "never my intention for the final design" — a detail that changes by Ep2.
- **VGA output** — 640×480 hi-res and 320×240 lo-res; both can letterbox to 16:9 for 720p output via a VGA-to-HDMI adapter. No old-television support by design (expansion slots exist for that).
- **Monitor on the Pi Pico** — the Pi Pico (RIA) serves as the system monitor, accessible via serial port and via USB keyboard + VGA terminal simultaneously. Claimed as the first color ANSI terminal emulator for the Pi Pico.
- **Separate video memory** — video RAM is 64 K inside the Pi Pico, separate from the 6502's 64 K. DMA planned to move data between USB storage, video RAM, and 6502 RAM.
- **USB device demo** — keyboard, mouse, PS4 controller, USB flash drive, SD card reader all recognized via USB hub.
- **Scroll Lock key** — toggles the built-in ANSI terminal on/off; lo-res mode shows a Commodore PETSCII font mock-up.

## Historical context

> At this time (Ep1), the design had 12 glue chips and used the second Pi Pico only as a debug probe. By Ep2, the dual-Pico design was intentional. The production [[rp6502-board]] uses 8 ICs. See [[development-history]] Era A.

## Related pages

- [[development-history]] — Era A: the 12-glue-chip count, single-Pico concept, pivot to dual-Pico
- [[rp6502-board]] — final reference PCB (8 ICs, not 12)
- [[rp6502-ria]] — what became the "Pi Pico monitor / DMA controller"
- [[rp6502-vga]] — the VGA subsystem
- [[memory-map]] — separate 64 K video RAM + 6502 RAM layout
- [[youtube-playlist]] — full episode list
