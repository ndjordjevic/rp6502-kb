---
type: entity
tags: [rp6502, ria, firmware, rp2350, pico2]
related: [[rp6502-ria-w]], [[rp6502-vga]], [[rp6502-os]], [[pix-bus]], [[xram]], [[xreg]], [[memory-map]], [[reset-model]], [[rom-file-format]], [[sdk-architecture]]
sources: [[rp6502-ria-docs]], [[picocomputer-intro]], [[rp6502-github-repo]], [[pico-c-sdk]]
created: 2026-04-15
updated: 2026-04-17
---

# RP6502-RIA

**Summary**: The **RP6502 Interface Adapter** — a Raspberry Pi Pico 2 running RIA firmware. Provides every essential service the W65C02S needs: PHI2 clock, RESB control, memory-mapped registers, input devices, audio, NFC, and the protected OS.

---

## Hardware role

- Lives in the **"RIA" socket** on the [[rp6502-board]] (**U2** on the reference board, which on Rev B is populated with a Pi Pico 2 W → see [[rp6502-ria-w]]). Flashing plain RIA firmware onto a non-W Pi Pico 2 gives a wireless-less build.
- Must be installed at `$FFE0-$FFFF` and must own **RESB** and **PHI2**. These are the only hard requirements; everything else about the computer is optional.
- Hosts the 32-bit protected [[rp6502-os]] which uses **zero** 6502 RAM.
- RP2350 runs at **256 MHz / 1.15 V** (overclocked from the default 150 MHz). Required to handle 8 MHz PHI2 while running USB, audio, and networking simultaneously. See [[pio-architecture]].
- GPIO assignments: PIX0–3=GPIO 0–3, UART TX/RX=4–5, CS=6, RWB=7, D0–D7=8–15, A0–A4=16–20, PHI2=21, IRQB=22, RESB=26. See [[gpio-pinout]].

## Boot behaviour

A fresh RIA boots to the **RP6502 monitor** — an UEFI-like shell whose job is `load` / `install` / `set boot` for `.rp6502` ROMs (see [[rom-file-format]]).

Console reachable three ways:
1. [[rp6502-vga]] + USB/BT keyboard.
2. USB CDC-ACM presented by the [[rp6502-vga]] Pico.
3. **UART** on the RIA itself (115200 8N1) — for headless or VGA-less builds.

Monitor has extensive built-in help: `help`, `help set phi2`, `status`, etc.

## XREG device map (as PIX device 0)

Input, audio, and NFC devices are enabled by writing the XRAM start address into an extended register at `$0:0:xx` or `$0:1:xx`. Writing `0xFFFF` as the address disables. See [[xreg]] for the mechanism.

| XREG | Feature | Data structure in XRAM |
| --- | --- | --- |
| `$0:0:00` | Keyboard | 32-byte bit array of HID keycodes |
| `$0:0:01` | Mouse | `{buttons,x,y,wheel,pan}` delta struct |
| `$0:0:02` | Gamepads | 4× 10-byte controller state |
| `$0:1:00` | **PSG** | 64 bytes (8 × 8-byte oscillators) |
| `$0:1:01` | **OPL2** (YM3812) | 256-byte register image, page-aligned |

### PSG highlights

8 × 24 kHz 8-bit oscillators. Sine / Square / Sawtooth / Triangle / Noise. ADSR + stereo pan + PWM. Config changes are applied immediately → CPU-driven sweeps, slides, pans.

### OPL2 highlights

Full YM3812 register set (256 bytes). **Timers / interrupts / status register are not supported** — a computer has its own timers.

## Console, VCP, NFC

- Console stdio is via `"CON:"` (non-blocking cooked) or `"TTY:"` (non-blocking raw).
- VCP: USB-to-serial adapters open as `"VCP0:115200,8N1"` etc. Drivers for FTDI, CP210X, CH34X, PL2303, CDC ACM.
- NFC: PN532 over USB. Cards store NDEF text with a ROM filename and arguments, tap-to-launch. Applications can take over with `open("NFC:")`.

## Audio subsystem

The RIA firmware includes two audio synthesizers, both accessible via [[xreg]] + [[xram]]:

| Synthesizer | XREG | Config size | First available |
|---|---|---|---|
| **[[programmable-sound-generator]]** (PSG) | `$0:1:00` | 64 bytes (8 × 8-byte oscillators) | v0.6 |
| **[[opl2-fm-synth]]** (Yamaha YM3812-compatible) | `$0:1:01` | 256 bytes (must be page-aligned) | v0.16 |

Both synthesizers coexist and can be active simultaneously. Audio output is PWM → RC filter → 3.5mm audio jack. Upgraded to 10-bit DAC resolution in v0.17.

No hardware change required to enable audio — firmware-only. See [[programmable-sound-generator]] and [[opl2-fm-synth]] for details.

## Related pages

- [[rp6502-os]] — the OS that runs inside this firmware
- [[ria-registers]] · [[api-opcodes]] · [[pio-architecture]] · [[gpio-pinout]]
- [[pix-bus]] · [[xram]] · [[xreg]]
- [[reset-model]] · [[rom-file-format]]
- [[programmable-sound-generator]] · [[opl2-fm-synth]]
- [[usb-controller]] — USB 1.1 controller; RIA uses it in host mode for HID + VCP + NFC
- [[rp2040-clocks]] — clock subsystem: 256 MHz System PLL overclock, clk_peri (UART/SPI), timer, watchdog
- [[rp2040-uart]] — UART1 console on GPIO 4–5, 115200 8N1; SDK API and interrupt model
- [[sdk-architecture]] — CMake INTERFACE model, builder pattern, hardware claiming, atomic aliases used in RIA firmware
- [[rp6502-ria-w]] — wireless superset
