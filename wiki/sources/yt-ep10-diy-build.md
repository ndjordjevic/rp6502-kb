---
type: source
tags: [rp6502, youtube, hardware, soldering, assembly, board]
related: [[rp6502-board]], [[rp6502-ria]], [[rp6502-vga]], [[known-issues]], [[development-history]]
sources: [[youtube-playlist]]
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep10 — DIY Build with Soldering

**Summary**: Full walkthrough of through-hole PCB assembly of the Picocomputer reference board, including parts sourcing, soldering order, firmware loading, bring-up testing, and a "Founders Edition" board reveal for patrons.

---

## Key topics

- **BOM sourcing**: Mouser CSV upload → shopping cart; ~$59.51 for parts (not including PCB) at time of recording.
- **"Founders Edition"**: boards were a surprise for Patreon supporters; silkscreen marked as such.
- **Solder order**: axial capacitors → resistors → sockets → Pi Pico sockets (two-part; cut 20-pin socket for 3-pin) → connectors/button → large capacitors.
- **3-phase bring-up**: (1) VGA Pico only; (2) RIA Pico; (3) 6502 + other ICs. Never test with ICs in place before checking for solder shorts.
- **Firmware load**: hold BOOTSEL, plug in USB, copy UF2 file — LED indicates success.
- **Default PHI2**: 4 MHz; `SET PHI2 8000` for 8 MHz (saved to EEPROM); "if you bought the correct parts" it'll run at 8 MHz (AC-family logic chips required — see [[known-issues]]).
- **OTG adapter**: needed for USB hub connection to RIA.
- **Mandelbrot demo** via serial: Colossal Cave Adventure loaded from USB drive.

## Related pages

- [[rp6502-board]] — the PCB being assembled
- [[known-issues]] — AC-family logic chips required for 8 MHz
- [[development-history]] — Era D: PCBWay manufacturing, viewer builds
