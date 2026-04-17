---
type: source
tags: [rp6502, ria, source]
related: [[rp6502-ria]], [[pix-bus]], [[xram]], [[xreg]], [[rom-file-format]], [[reset-model]]
sources: [picocomputer.github.io/ria]
created: 2026-04-15
updated: 2026-04-15
---

# Source — RP6502-RIA docs

**Summary**: Official reference for the **RP6502 Interface Adapter** — its role, the monitor, the PIX bus, input/audio devices, NFC, and ROM file format.

Raw: [RP6502-RIA](<../../raw/web/picocomputer.github.io/RP6502-RIA — Picocomputer  documentation.md>)

---

## What this source establishes

- [[rp6502-ria]] = a **Raspberry Pi Pico 2** + RIA firmware. Provides *all* essential services to the W65C02S.
- RIA **must** live at `$FFE0-$FFFF` and **must** own `RESB` and `PHI2`. These are the only hard requirements of the design; everything else (including [[rp6502-vga]]) is optional.
- A fresh RIA boots to the **RP6502 monitor**, analogous to a UEFI shell — not an OS shell. Primary job: `load` / `install` / `set boot` for `.rp6502` ROMs.
- Console is reachable three ways:
  1. VGA + USB/BT keyboard (needs [[rp6502-vga]]).
  2. USB CDC-ACM from the VGA Pico (headless).
  3. UART on the RIA at **115200 8N1** (no VGA).

## Major sections in the source

| Section | Page in wiki |
| --- | --- |
| Reset semantics | [[reset-model]] |
| Pico Information Exchange (PIX) | [[pix-bus]] |
| PIX Extended RAM (XRAM) | [[xram]] |
| Keyboard / Mouse / Gamepad XREG blocks | [[rp6502-ria]] |
| PSG (8× 24 kHz oscillators, ADSR) | [[programmable-sound-generator]] |
| YM3812 OPL2 FM (256 registers) | [[opl2-fm-synth]] |
| Console / VCP / NFC | [[rp6502-ria]] |
| ROM file format | [[rom-file-format]] |

## Notable claims / quirks

- PIX is **double-data-rate** over PHI2; 32-bit frames in 4 PHI2 cycles. Bit 28 is always-on framing; bits 31-29 are device ID.
- PIX **device 0** = RIA (and "XRAM broadcast"). **Device 1** = VGA. **Devices 2-6** user. **Device 7** = sync.
- Mouse poll is VSync-locked by default; for precision use an ISR at ≥125 Hz.
- [[opl2-fm-synth|OPL2]] status/timers/interrupts are **not supported** (not needed on a computer that has its own timers).
- Input/audio are enabled by **mapping into XRAM** via [[xreg]] writes — writing `0xFFFF` as the address disables.
- NFC: PN532 over USB; cards store filenames as NDEF text and auto-`load` the ROM on tap.

## Related pages

- [[rp6502-ria]] · [[pix-bus]] · [[xram]] · [[xreg]] · [[rom-file-format]] · [[reset-model]]
