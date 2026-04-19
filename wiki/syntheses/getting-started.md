---
type: synthesis
tags: [rp6502, getting-started, setup, synthesis, tutorial]
related:
  - "[[rp6502-board]]"
  - "[[rp6502-ria]]"
  - "[[rp6502-vga]]"
  - "[[toolchain-setup]]"
  - "[[cc65]]"
  - "[[llvm-mos]]"
  - "[[rom-file-format]]"
  - "[[known-issues]]"
sources:
  - "[[hardware]]"
  - "[[vscode-cc65]]"
  - "[[rp6502-ria-docs]]"
  - "[[release-notes]]"
created: 2026-04-18
updated: 2026-04-18
---

# Getting Started with the RP6502 Picocomputer

**Summary**: A synthesis guide for getting from zero to a running C program on the RP6502 Picocomputer — covering hardware assembly, firmware flashing, toolchain setup, and your first program.

---

## Step 0: What you need

| Item | Notes |
|---|---|
| RP6502 board (or compatible) | Reference board is 150×100 mm through-hole. See [[rp6502-board]] for BOM. |
| Raspberry Pi Pico 2 W (with headers) | For **U2** (RIA slot) — must be Pico 2 W if you want WiFi |
| Raspberry Pi Pico 2 (with headers) | For **U4** (VGA slot) — standard Pico 2 is fine |
| W65C02S | CPU — Mouser `955-W65C02S6TPG-14` |
| W65C22S | VIA — Mouser `955-W65C22S6TPG-14` |
| SRAM (128K, ≤70 ns) | Alliance AS6C1008-55PCN — Mouser `913-AS6C1008-55PCN` |
| Glue logic | 2× AC quad NAND/NOR (must be **AC**, not HC) |
| USB cable | For connecting to PC (USB-A to Micro-USB or USB-C) |
| PC with VS Code | Linux, macOS, or Windows |

> **Critical**: Glue logic chips must be CD74**AC**-series. CD74HC or HCT will fail at 8 MHz.

---

## Step 1: Assemble the board

Follow the instructions at [picocomputer.github.io/hardware.html](https://picocomputer.github.io/hardware.html) for the current BOM and assembly order. Key tips:

- Insert the WDC chips (W65C02S, W65C22S) last, after all passive components are soldered.
- The Pico 2 W goes in **U2** (RIA socket); the plain Pico 2 goes in **U4** (VGA socket).
- Rev A and Rev B are electrically identical.

See [[rp6502-board]] for the full IC list and [[hardware]] source page.

---

## Step 2: Flash the firmware

### RIA firmware (U2 — Pico 2 W)

1. Download the latest `rp6502-ria.uf2` from [github.com/picocomputer/rp6502/releases](https://github.com/picocomputer/rp6502/releases) (latest is **v0.24**).
2. Hold BOOTSEL on the Pico 2 W, connect USB, release BOOTSEL — it appears as a USB drive.
3. Drag `rp6502-ria-w.uf2` onto the drive. The Pico resets automatically.

> If you have a plain Pico 2 (non-W) in U2, use `rp6502-ria.uf2` instead. WiFi features will not be available.

### VGA firmware (U4 — Pico 2)

1. Download `rp6502-vga.uf2` from the same releases page.
2. Hold BOOTSEL on the U4 Pico 2, connect USB to the **VGA USB port**, release BOOTSEL.
3. Drag `rp6502-vga.uf2` onto the drive.

---

## Step 3: Verify the hardware

1. Connect a USB keyboard to the RIA's USB port (or the VGA's USB port if using HDMI monitor).
2. Connect a VGA monitor to J3.
3. Power the board (USB-C to the RIA port or via barrel jack).

You should see the **RP6502 monitor** prompt on screen. Type `help` to see available commands.

If nothing appears: check your USB connection to the VGA Pico, verify firmware was flashed to the correct Pico, and check VGA cable.

---

## Step 4: Set PHI2 speed and timezone

In the monitor:
```
SET PHI2 8000     (8000 kHz = 8 MHz — default since v0.13)
SET TZ US/Eastern (or your city/timezone)
```

If you upgraded from an older firmware and the speed reset to 100 kHz, this fixes it.

---

## Step 5: Install the toolchain

Two options — **start with cc65** unless you need C++ or floats:

### cc65 (recommended)

```bash
# Linux / macOS
sudo apt install cmake python3 git build-essential
# Build picocomputer's cc65 fork:
git clone https://github.com/picocomputer/cc65
cd cc65 && make
# Add bin/ to your PATH
```

> Do NOT use `brew install cc65` or `apt install cc65` — those are years out of date.

### Windows

```powershell
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Git.Git
winget install -e --id Kitware.CMake
winget install -e --id GnuWin32.Make
```

Download cc65 snapshot from [cc65.github.io](https://cc65.github.io/getting-started.html) and add `bin\` to PATH.

For llvm-mos, see [[toolchain-setup]] or [[llvm-mos]].

---

## Step 6: Create your first project

1. Go to [github.com/picocomputer/vscode-cc65](https://github.com/picocomputer/vscode-cc65)
2. Click **"Use this template"** → **"Create a new repository"**
3. Clone your repo and open in VS Code:
   ```bash
   git clone <your-repo-url>
   cd <repo-name>
   code .
   ```
4. Install the recommended extensions when prompted.
5. Edit `src/main.c`:

```c
#include <rp6502.h>
#include <stdio.h>

void main()
{
    puts("Hello, Picocomputer!");
}
```

---

## Step 7: Build and run

1. Connect the **RP6502-VGA USB port** to your PC (not the RIA port).
2. Press **F5** in VS Code.
3. VS Code builds, packages as `.rp6502` ROM, uploads via `rp6502.py`, and resets the board.
4. You should see your program running on the VGA display.

**Troubleshooting:**
- "Device not found" → edit the auto-created `.rp6502` config file to set your serial port.
- "Build failed" → verify cc65 is in PATH; check CMake configuration.
- Black screen → verify firmware on VGA Pico; check VGA cable.

---

## What's in the 64 KB of RAM?

| Range | Use |
|---|---|
| `$0000–$00FF` | Zero page (fast pointer operations) |
| `$0100–$01FF` | Hardware stack (fixed 6502 location) |
| `$0200–...` | Program loads here by default |
| `...–$FEFF` | Heap grows up from program end; C stack grows down from `$FEFF` |
| `$FF00–$FFCF` | User I/O expansion |
| `$FFD0–$FFDF` | W65C22S VIA |
| `$FFE0–$FFFF` | RIA registers |

The OS uses no 6502 RAM — it runs entirely in the RP2350 inside the RIA.

---

## Next steps

- [[cc65-vs-llvm-mos]] — detailed toolchain comparison
- [[what-does-ria-do]] — understand the OS interface
- [[rp6502-abi]] — writing direct OS calls in assembly
- [[toolchain-setup]] — full setup reference with CMake macro docs
- [[known-issues]] — common gotchas and fixes
- [[cc65]] and [[llvm-mos]] — toolchain entity pages
