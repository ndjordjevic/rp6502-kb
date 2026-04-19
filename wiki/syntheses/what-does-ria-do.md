---
type: synthesis
tags: [rp6502, ria, os, abi, xram, synthesis]
related:
  - "[[rp6502-ria]]"
  - "[[rp6502-os]]"
  - "[[rp6502-abi]]"
  - "[[ria-registers]]"
  - "[[xram]]"
  - "[[memory-map]]"
  - "[[xreg]]"
  - "[[pix-bus]]"
sources:
  - "[[rp6502-ria-docs]]"
  - "[[rp6502-github-repo]]"
created: 2026-04-18
updated: 2026-04-18
---

# What Does the RIA Do?

**Summary**: A synthesis explaining the complete role of the RP6502-RIA — the Raspberry Pi Pico 2 board that serves as the 6502's "operating system chip", providing clock, memory, I/O, and a protected OS within 32 memory-mapped registers.

---

## The short answer

The RIA is the **central nervous system** of the RP6502 Picocomputer. Without it, the W65C02S cannot even start — the RIA generates its clock and controls its reset line. With it, the 6502 gets a full POSIX-like operating system, 64 KB of extended RAM, USB peripherals, audio synthesis, and optionally WiFi — all without using a single byte of 6502 address space beyond 32 registers at `$FFE0–$FFFF`.

---

## Three layers of what the RIA does

### 1. Hardware control (clocking + reset)

The RIA's RP2350 generates the **PHI2 clock** via PIO at 8000 kHz default (up to 8 MHz max). It also drives the **RESB line** to control 6502 resets. No PHI2 = no 6502. The RIA must be installed and powered for the computer to function.

The RP2350 itself runs at **256 MHz / 1.15 V** (overclocked from the default 150 MHz) so it can serve the 6502 bus at 8 MHz while simultaneously handling USB, audio, and networking.

See [[pio-architecture]] for how PIO generates PHI2 at exact frequency.

### 2. Memory bus interface (32 registers)

The RIA watches the 6502's address bus via 5 address pins (A0–A4) plus a chip-select decoded from A5–A15. When the 6502 accesses `$FFE0–$FFFF`, the RIA intercepts the bus.

The 32 registers divide into:

| Address range | Group | Purpose |
|---|---|---|
| `$FFE0–$FFE2` | ACIA simulation | Console character I/O (TX/RX + status) |
| `$FFE3–$FFEF` | XSTACK, XRAM windows, counters | Argument passing + extended memory access |
| `$FFF0–$FFFF` | OS call stub (`RIA_SPIN`) + ABI registers | OP code, busy flag, return value, ERRNO |

The 6502 "calls the OS" by writing an op-code to `RIA_OP` (`$FFEF`). The RIA executes the requested function asynchronously on the RP2350 and signals completion by updating `RIA_BUSY` (`$FFF2`).

Full register breakdown: [[ria-registers]].

### 3. Protected OS (inside the RP2350)

The OS runs entirely inside the RP2350's own memory — it uses **zero bytes of 6502 RAM** and does not appear in the 6502's address space at all. The 6502 can only communicate with it via the 32 registers.

Available OS calls via [[rp6502-abi]]:
- File I/O: `open`, `close`, `read`, `write`, `seek`, `unlink`, `rename`, `stat`, `opendir`, `readdir`
- Process: `exec`, `exit`, `getargs`, `time`, `clock`
- Audio: PSG synthesis (8 oscillators), OPL2 (YM3812 emulation)
- Input: keyboard, mouse, gamepad (via XREG device map)

All system calls follow the **cc65 fastcall** convention: last argument in A/X, earlier args on XSTACK.

---

## The 64 KB XRAM extension

The RIA also hosts **XRAM** — 64 KB of extra RAM that lives inside the RP2350. The 6502 reaches it through two auto-incrementing window registers: `RIA_RW0` and `RIA_RW1` (addresses `$FFE4–$FFE9`). These function like address + data registers for a secondary address space.

XRAM is also broadcast over the **[[pix-bus]]** to peripherals like [[rp6502-vga]], which reads its video framebuffer from XRAM.

Full XRAM details: [[xram]].

---

## What the RIA does NOT do

- **No ROM in 6502 space** — there is no BIOS or monitor mapped into the 6502's 64 KB. The reset vector at `$FFFC/D` is in RAM and must be set before RESB goes high.
- **No clock for the 6502's timer** — the W65C22S VIA (`$FFD0`) provides T1/T2 timers driven by PHI2.
- **No video** — video output is handled by [[rp6502-vga]] (a separate Pi Pico 2) which reads XRAM over PIX bus.
- **No GPIO** — the VIA [[w65c22s]] at `$FFD0` provides the only programmable I/O pins the 6502 can directly address.

---

## Memory map summary

| Range | Owner | What's there |
|---|---|---|
| `$0000–$FEFF` | 6502 RAM | Program + data; stack grows down from `$FEFF` |
| `$FF00–$FFCF` | User expansion | Extra VIAs, SIDs, custom chips |
| `$FFD0–$FFDF` | W65C22S VIA | GPIO, timers, shift register |
| `$FFE0–$FFFF` | RIA | 32 registers — the entire OS interface |
| `$10000–$1FFFF` | XRAM (RIA-side) | 64 KB extra RAM, PIX-broadcast to VGA |

For the full breakdown see [[memory-map]].

---

## Related pages

- [[rp6502-ria]] — hardware entity (GPIO, boot, XREG map)
- [[ria-registers]] — complete 32-register reference
- [[rp6502-abi]] — calling convention for OS calls
- [[rp6502-os]] — OS call list (posix wrappers)
- [[xram]] — extended RAM and window registers
- [[xreg]] — extended register device map
- [[pix-bus]] — how XRAM is broadcast to peripherals
- [[memory-map]] — full address space layout
