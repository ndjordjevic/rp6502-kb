---
type: topic
tags: [rp6502, hardware, build, assembly, bom, pcb, setup]
related:
  - "[[rp6502-board]]"
  - "[[rp6502-ria]]"
  - "[[rp6502-ria-w]]"
  - "[[rp6502-vga]]"
  - "[[w65c02s]]"
  - "[[w65c22s]]"
  - "[[getting-started]]"
  - "[[known-issues]]"
sources:
  - "[[hardware]]"
  - "[[picocomputer-intro]]"
  - "[[yt-ep10-diy-build]]"
  - "[[yt-ep11-no-soldering]]"
created: 2026-04-18
updated: 2026-04-18
---

# Hardware Build Guide

**Summary**: Practical guide for building the RP6502 Picocomputer from scratch — PCB sourcing, BOM, assembly sequence, firmware flashing, and first-boot verification.

---

## Overview

The RP6502 reference board is a **150×100 mm, 2-layer, 100% through-hole design** with 8 ICs. It is specifically designed to be buildable by hobbyists with basic soldering skills. No SMD components. No special tools beyond a soldering iron and multimeter.

The only required module is the [[rp6502-ria]] (U2). The [[rp6502-vga]] (U4) is optional — you can use the UART on the RIA for a headless console.

Rev A and Rev B boards are **electrically identical**. Rev B only removed unused debug connectors under the RIA socket. Use Rev B gerbers for new builds.

---

## Step 1: Source the PCB

Three options:

### Option A — Order from PCBWay (easiest)
- PCBWay shared project page: https://www.pcbway.com/project/shareproject/Picocomputer_6502_RP6502_Rev_B_1f41cb0b.html
- PCBWay also offers PCBA (assembly) service — submit BOM + notes + photos zip, let them source parts. Min quantity 1.

### Option B — Upload gerbers to any fab
- Download `rp6502-revb-gerbers.zip` from the docs `_static/` folder.
- Upload to JLCPCB, PCBWay, Oshpark, or any 2-layer PCB fab. Standard 2-layer, 1.6mm, HASL finish.

### Option C — Buy a pre-made board
- The author sells finished boards via Ko-fi: `ko-fi.com/rumbledethumps`
- US shipping only; ships from USA (no import tariff concerns for US buyers).

---

## Step 2: Source the parts

### IC BOM

| Ref | Part | Role | Mouser # |
|-----|------|------|----------|
| U1 | WDC W65C02S | 65C02 CPU (14 MHz rated) | `955-W65C02S6TPG-14` |
| U5 | WDC W65C22S | VIA (14 MHz rated) | `955-W65C22S6TPG-14` |
| U2 | Raspberry Pi Pico 2 W (w/headers) | [[rp6502-ria-w]] | `358-SC1634` |
| U4 | Raspberry Pi Pico 2 (w/headers) | [[rp6502-vga]] | `358-SC1632` |
| U3 | Alliance AS6C1008-55PCN | 128 KB SRAM @ 55 ns | `913-AS6C1008-55PCN` |
| U6 | TI CD74AC00E | Quad 2-input NAND (AC-series) | `595-CD74AC00E` |
| U7 | TI CD74AC02E | Quad 2-input NOR (AC-series) | `595-CD74AC02E` |
| U8 | TI CD74HC30E | 8-input NAND (HC is fine here) | `595-CD74HC30E` |

**Full BOM** (including passives, connectors, sockets, rubber feet): download `rp6502-revb-full.csv` from the docs `_static/` folder.

### Critical sourcing rules

> ⚠️ **Glue logic must be true CMOS**: use **AC** or HC — **never ACT, HCT, or LS** series. Two of the three 74xx chips (U6, U7) must be AC for 8 MHz operation. U8 (CD74HC30E) can be HC.

> ⚠️ **No NMOS substitutes**: W65C02S and W65C22S must be WDC CMOS parts. Do NOT substitute original NMOS 6502/6522 chips — they have different electrical characteristics and cannot run at 8 MHz.

> ⚠️ **SRAM speed**: must be ≤70 ns access time for 8 MHz. The AS6C1008-55PCN (55 ns) has comfortable margin. Do not use 70 ns SRAM (it may work but leaves no timing margin).

### Headerless build option

Use `358-SC1633` (Pico 2 W, no headers) + `358-SC1631` (Pico 2, no headers) + separate 20-pin headers (`649-1012937892001BLF`, 2 per Pico). Lets you solder the headers to either the Pico or the PCB depending on your preference. See `rp6502-revb-picos.csv` on the docs site.

---

## Step 3: Assembly sequence

1. **Resistors and ceramic capacitors first** — lowest profile
2. **Electrolytic capacitors** — observe polarity (stripe = negative)
3. **Crystal** (if your board has one — not required if Pico provides the clock)
4. **IC sockets** — install all DIP sockets before ICs (easier to solder flat; allows chip swapping later)
5. **Connectors** — J1 (GPIO), J2 (PIX), J3 (VGA), J4 (audio), SW1 (reboot)
6. **Pico headers** — the Pico 2 W (U2) and Pico 2 (U4) mount on 20-pin headers
7. **Insert ICs into sockets last** — reduces risk of static damage during soldering
   - U1: W65C02S (notch toward J2/PIX side)
   - U5: W65C22S
   - U3: AS6C1008-55PCN (notch per silkscreen)
   - U6, U7, U8: 74xx logic chips

> **From Ep10**: The three-phase bring-up approach: (1) flash firmware before assembly — confirm Picos work; (2) install Picos without other ICs — confirm power; (3) install remaining ICs and test.

---

## Step 4: Flash firmware (before final assembly)

Flash both Picos **before** inserting them into the board. This lets you confirm each Pico works and simplifies recovery if you need to reflash.

### RIA (U2 — Pico 2 W)

1. Download `rp6502-ria-w.uf2` from [github.com/picocomputer/rp6502/releases](https://github.com/picocomputer/rp6502/releases) (current: **v0.24**)
2. Hold BOOTSEL on the Pico 2 W, connect USB to your PC, release BOOTSEL
3. The Pico appears as a USB mass storage device
4. Drag `rp6502-ria-w.uf2` onto it — LED turns on when complete, Pico resets

### VGA (U4 — Pico 2)

1. Download `rp6502-vga.uf2` from the same releases page
2. Same procedure with the plain Pico 2 + the **VGA USB port** on the board (or directly if flashing before assembly)
3. Drag `rp6502-vga.uf2` onto it

> **Plain RIA vs RIA-W**: If you use a plain Pico 2 (non-W) in U2, use `rp6502-ria.uf2` instead. WiFi/BLE features will not be available.

---

## Step 5: First boot verification

1. Connect USB keyboard to the RIA USB port
2. Connect VGA monitor to J3 (VGA cable, or VGA-to-HDMI adapter — zero-lag, works fine)
3. Power the board (USB-C on the RIA, or via barrel jack if your board has one)

**Expected result**: RP6502 monitor prompt appears on screen.

```
RP6502 Monitor vX.XX
Type 'help' for a list of commands.
>
```

If nothing appears:
- Check VGA cable / HDMI adapter
- Verify firmware was flashed to the correct Pico (VGA Pico controls the display)
- Check USB keyboard connection to RIA USB port
- Try `help` on a serial terminal at 115200 8N1 on the RIA UART pins (GPIO4/GPIO5) — this works without VGA

---

## Step 6: Initial configuration

In the monitor, configure system speed and timezone:

```
SET PHI2 8000     ; 8 MHz CPU clock (8000 kHz)
SET TZ US/Eastern ; or your timezone
```

If you have a Pico 2 W (RIA-W) and want WiFi:
```
SET RFCC US       ; your country code
SET SSID MyNetwork
SET PASS MyPassword
SET RF 1          ; enable radios
```

For telnet remote access (v0.24+):
```
SET PORT 23       ; standard telnet port
SET KEY mypasskey ; required passkey
```

---

## Connectors reference

| Connector | Description |
|-----------|-------------|
| J1 | 2×12 GPIO expansion header (access to VIA GPIO, RIA GPIO) |
| J2 | 2×6 [[pix-bus]] header (connect additional PIX devices) |
| J3 | VGA DE-15 (standard VGA output; VGA-to-HDMI adapters work) |
| J4 | 3.5 mm audio output |
| SW1 | Reboot button (wired to RIA RUN pin — see [[reset-model]]) |

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| No display | VGA firmware not flashed, or VGA cable issue | Reflash VGA Pico; try different cable/adapter |
| Running at 100 kHz (sluggish) | PHI2 reset after firmware upgrade | `SET PHI2 8000` in monitor |
| Board doesn't boot after assembly | Wrong IC orientation or wrong logic family | Check IC notches; verify AC chips in U6/U7 |
| No keyboard input | Wrong USB port | Keyboard goes to **RIA** USB port (U2), not VGA |
| WiFi not connecting | RF disabled or no credentials | `SET RF 1`, `SET SSID`, `SET PASS` |
| `make` errors building cc65 | Wrong cc65 version | Build from `picocomputer/cc65` fork, not package manager |

For more issues see [[known-issues]].

---

## Related pages

- [[rp6502-board]] — board entity (full IC/connector table)
- [[hardware]] — official hardware docs source
- [[getting-started]] — software side (toolchain, first program)
- [[monitor-reference]] — all monitor commands
- [[rp6502-ria-w]] — WiFi/BLE configuration
- [[known-issues]] — common gotchas
- [[board-circuits]] — glue logic, VGA DAC, audio filter detail
