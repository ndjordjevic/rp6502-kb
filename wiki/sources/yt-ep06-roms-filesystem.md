---
type: source
tags: [rp6502, youtube, filesystem, fatfs, littlefs, usb, rom, storage]
related:
  - "[[development-history]]"
  - "[[rp6502-os]]"
  - "[[rom-file-format]]"
  - "[[launcher]]"
  - "[[youtube-playlist]]"
sources:
  - "[[youtube-playlist]]"
video_id: 9u82Uy_458E
episode: 6
approx_date: 2023-04
created: 2026-04-17
updated: 2026-04-17
---

# Ep6 — ROMs and the filesystem - TinyUSB and FatFs

**Summary**: The dual filesystem strategy is explained (FatFs for USB drives, littlefs for internal flash), TinyUSB + FatFs integration is walked through, and the ROM concept debuts — programs installed to Pi Pico flash via littlefs that auto-run at boot.

**Video**: [https://www.youtube.com/watch?v=9u82Uy_458E](https://www.youtube.com/watch?v=9u82Uy_458E)

---

## Key topics

- **Why two filesystems** — FatFs handles USB drives and SD cards (which have built-in wear-leveling controllers), so any filesystem works there. The internal Pi Pico flash chip is a "naked" flash device with no wear-leveling controller — FAT would wear it out unevenly. Solution: **littlefs** for internal flash (designed by Arm specifically for bare flash), **FatFs** for removable USB media.
- **FatFs + TinyUSB integration** — three connection points: (1) IOCTL relaying disk geometry; (2) mount/unmount callbacks on USB plug/unplug; (3) read/write relay between FatFs and TinyUSB. Key quirk: TinyUSB is non-blocking/event-driven, so reads/writes must spin on the USB worker task until a callback clears a flag.
- **littlefs integration** — config struct with 4 callbacks (read/erase/write/sync), capacity/block-size parameters, memory buffers. Pi Pico flash is memory-mapped so reads = `memcpy`. On first boot: mount fails → auto-format and remount.
- **USB-only removable media** — no SD card slot; all removable media accessed via USB hub. "Modern retro 8-bit computers are only allowed to have one SD card slot and it cannot be on the front" (editorial). USB hubs/extension cables are cheap.
- **ROM concept introduced** — programs installed to the Pi Pico internal flash (via littlefs) are called "ROMs." They appear in the help listing, support per-ROM help text, and can be set as the boot target. Demonstrated: BASIC and Hello World installed as ROMs.
- **First USB-drive 6502 load** — author's claim: first time a genuine 6502 program was loaded and run from a USB flash drive (not SD card, not EPROM).
- **Live upload workflow** — Pi Pico connected over USB to development machine; `LS` / `LOAD` monitor commands; build script compiles and uploads binary to USB drive without swapping media.
- **PHI2 speed control** — `STATUS` shows all settings; clock speed changeable at runtime and saved automatically (no DIP switches).

## Historical context

> This episode introduced the ROM concept that became [[rom-file-format]] and the `INSTALL` / launcher mechanism. FatFs + littlefs coexistence rationale is the permanent design decision — still the architecture in current firmware. See [[development-history]] Era B.

## Related pages

- [[development-history]] — Era B: storage and filesystem design
- [[rp6502-os]] — filesystem API (`f_open`, `f_read`, etc.)
- [[rom-file-format]] — the ROM install mechanism introduced here
- [[launcher]] — boot ROM selection (`set boot basic`)
- [[youtube-playlist]] — full episode list
