---
type: topic
tags: [rp6502, bugs, workarounds, known-issues, rp2350, errata, hardware]
related: [[rp6502-ria]], [[rp6502-ria-w]], [[rp6502-vga]], [[release-notes]], [[dma-controller]], [[usb-controller]], [[rp6502-board]]
sources: [[release-notes]], [[rp2350-datasheet]], [[youtube-playlist]], [[rumbledethumps-discord]]
created: 2026-04-16
updated: 2026-04-18
---

# Known Issues

**Summary**: Bugs, workarounds, and things to watch out for — sourced from release notes v0.1–v0.23 and the RP2350 silicon errata (Appendix E of the RP2350 datasheet).

---

## Critical warnings

### v0.8 — DO NOT USE
v0.8 has a littlefs bug that **prevents formatting the internal filesystem on a brand-new Pi Pico**. If you flash v0.8 on a new Pico, it will fail to initialize and you'll need to reflash. Use v0.9 or later.

### Pi Pico 1 support dropped at v0.10
v0.10 migrated entirely to Pi Pico 2 (RP2350). **Pi Pico 1 boards are not supported in v0.10 or later.** There is no migration path — hardware upgrade required.

---

## Hardware requirements

### AC-family logic chips required for 8 MHz

**Source**: [[yt-ep03-writing-to-pico]] (Ep3); [[yt-ep02-pio-and-dma]] (Ep2)

The glue logic chips in the address decode path must be **74AC-family** (or equivalent fast CMOS) to run the 6502 at 8 MHz. 74HC-family chips have ~15 ns/gate propagation; at 4 gates deep, this creates ~60 ns delay — half a clock cycle at 8 MHz, causing read errors (first seen at 7.7 MHz in Ep3).

**74AC chips**: reduce propagation to ~35 ns → stable at 8 MHz (tested to 9 MHz).
**74HC chips**: limit the system to **4 MHz** (the default PHI2 setting).

> **Implication for builders**: When sourcing the [[rp6502-board]] BOM, the chips in the address decode logic path (notably the 7430 and address decode gates) must be AC-series, not HC-series. The RIA firmware auto-detects available speed via self-test. If you see the system running at 4 MHz when you expect 8 MHz, check the logic family on your glue chips.

See also: [[development-history]] Era A; [[rp6502-board]] BOM notes.

---

## Active known issues (as of v0.23)

### cc65 requires a fork
v0.14 overhauled the errno system. The upstream `cc65` compiler does not yet include the matching changes — a [PR is pending](https://github.com/cc65/cc65/pull/2844). Until it merges, use the official fork at `github.com/picocomputer/cc65`.

### PHI2 may reset to 100 after upgrade from old firmware
Upgrading from certain older versions (noted in v0.16 release) may cause the stored PHI2 setting to read back as 100 kHz. Fix: `SET PHI2 8000` in the monitor.

### TinyUSB instability (historical, largely resolved)
TinyUSB host mode had long-standing instability issues (noted across v0.7–v0.18). The silicon-level fix arrived in v0.19. As of v0.19+, USB plug events no longer freeze the system. Quirky USB devices may still need special handling — report them upstream.

### TEAC floppy drive (CBI) not working
CBI support for floppy drives was added in v0.18, but the TEAC drive (still available as new-old-stock) does not work. Other 3.5" floppy drives do work as of v0.19. Power adequacy is important for floppy drives.

### Non-standard HID devices
All HID drivers were reworked for BLE support in v0.13. If a keyboard or mouse that worked in v0.12 stopped working, submit an issue with your HID report descriptor. Gamepad compatibility for non-standard devices requires community contributions (`pad.c` has breadcrumbs).

### Bluetooth BR/EDR not supported
Only **Bluetooth LE (BLE)** is supported for wireless HID (keyboards, joysticks, gamepads). Bluetooth Classic (BR/EDR) devices will not connect.

---

## RP2350 silicon errata

The RP2350 (Pi Pico 2) has a published silicon errata (Appendix E of the RP2350 datasheet). Below are all errata ordered by relevance to RP6502 development, with workaround notes. Errata IDs link to the affected silicon revision.

> **Silicon revisions**: A2 → A3 → A4. Check `CHIP_ID.REVISION` (0x4 = A2, 0x6 = A3, 0x8 = A4). Most A2-only errata are fixed in A3+.

### RP2350-E12 — USB: inadequate synchronisation of USB status signals ⚠️
**Affects**: A2, A3, A4 (mitigated on A3 bootrom)
**Critical for RP6502**: `clk_sys` must be **> 48 MHz** (not equal) when USB is active. The RP2350 VGA firmware must meet this requirement. The A3 bootrom mitigates the synchronisation issue for signals used during boot, but application software must not rely on the bootrom mitigation.
See also: [[usb-controller]] § RP2350 Changes.

### RP2350-E5 — DMA: CHAIN_TO fires unexpectedly during ABORT ⚠️
**Affects**: A2, A3, A4 (documentation only — no hardware fix)
**Summary**: Aborting an active DMA channel can trigger its `CHAIN_TO` target to fire unexpectedly. A re-trigger on the last ABORT cycle is also possible.
**Workaround**: Before aborting a channel, clear the `EN` bit (`CHx_CTRL_TRIG.EN`) of both the aborted channel *and* any channel it chains to.
See also: [[dma-controller]] § Channels and Control.

### RP2350-E8 — DMA: CHAIN_TO may not fire for zero-length transfers
**Affects**: A2, A3, A4 (documentation only)
**Summary**: If a DMA channel completes a transfer of zero bytes, the `CHAIN_TO` chaining may not trigger.
**Workaround**: Do not use `CHAIN_TO` with zero-length transfers. Replace zero-length transfers in control block lists with dummy transfers.

### RP2350-E1 — SIO: Interpolator OVERF bits broken by right-rotate behaviour
**Affects**: A2, A3, A4 (documentation only)
**Summary**: The interpolator overflow detection (`OVERF0`/`OVERF1`) does not work correctly when right-rotate is used (a new RP2350 feature).
**Workaround**: Compute overflow manually by checking `ACCUM0`/`ACCUM1` MSBs, or precompute bounds in advance.

### RP2350-E2 — SIO: SPINLOCK writes mirrored at +0x80 offset
**Affects**: A2, A3, A4 (documentation only)
**Summary**: Writing to a `SIO_SPINLOCK` register also writes to the spinlock 16 positions higher (due to address decode mirroring).
**Workaround**: Use processor atomic instructions instead of SIO spinlocks. The SDK `hardware_sync_spin_lock` library does this automatically.

### RP2350-E6 — Hazard3 RISC-V: PMPCFGx RWX fields are transposed
**Affects**: A2, A3, A4 (documentation only)
**Summary**: In the Hazard3 RISC-V CPU, the bit ordering of R, W, X in PMP configuration registers is reversed from the RISC-V spec.
**Workaround**: Use the bit order as-implemented. The SDK `hardware/regs/rvcsr.h` header provides correct bitfield definitions for RP2350.
*Note*: The RP6502 firmware runs the RP2040-compatible Arm Cortex-M33 cores, not Hazard3, so this primarily affects custom RISC-V firmware on the RIA.

### RP2350-E7 — Hazard3 RISC-V: U-mode doesn't ignore mstatus.mie
**Affects**: A2, A3, A4 (documentation only)
**Summary**: When in U-mode, `mstatus.mie` incorrectly affects interrupt masking (per RISC-V spec, U-mode should ignore `mie`).
**Workaround**: When returning to U-mode via `mret` with `mstatus.mpp == 0`, ensure `mstatus.mpie` is set so interrupts will be enabled.

### RP2350-E11 — XIP: cache clean by set/way corrupts dirty line tags
**Affects**: A2, A3, A4 (documentation only)
**Summary**: The "clean by set/way" XIP cache operation modifies dirty line tags, potentially causing spurious cache hits after cleaning.
**Workaround**: Choose cleaning addresses that cannot alias with cached QMI data. The SDK `xip_cache_clean_range()` function uses the correct workaround.

### RP2350-E17 — OTP: guarded read of single ECC row faults if adjacent row is invalid
**Affects**: A2, A3, A4 (documentation only)
**Summary**: A guarded (error-checked) read of a single ECC OTP row causes a fault if the adjacent row (in the same pair) contains invalid ECC data.
**Workaround**: Never mix ECC and RAW rows within the same pair (even-starting row pair). Never store two ECC rows in the same pair if only reading one.

### Bootrom-only errata (fixed in A3/A4 bootrom)

The following errata are present in A2 silicon but are **fixed or mitigated by the A3+ bootrom**. If you use A3/A4 silicon you generally don't need to work around these in application code:

| ID | Summary | Fixed in |
|----|---------|----------|
| RP2350-E10 | UF2 drag-and-drop doesn't work with partition tables | A3 bootrom |
| RP2350-E13 | Invalid IMAGE_DEF before valid IMAGE_DEF fails to boot | A3 bootrom |
| RP2350-E14 | `connect_internal_flash()` ignores CS1 pin config | A3 bootrom |
| RP2350-E15 | `otp_access()` wrong permissions for pages 62/63 | A3 bootrom |
| RP2350-E18 | Forever boot failure on invalid FLASH_PARTITION_SLOT_SIZE ECC | A4 bootrom |
| RP2350-E19 | Reboot hangs when certain FRCE_OFF bits are set | A3 bootrom |
| RP2350-E22 | Malformed lollipop block causes hang | A3 bootrom |
| RP2350-E23 | PICOBOOT GET_INFO returns zero for PACKAGE_SEL | A3 bootrom |
| RP2350-E3 | QFN-60: GPIO_NSMASK controls wrong PADS registers | A3 hardware |
| RP2350-E9 | Increased GPIO leakage when pad input enabled | A3 hardware |

### Security errata (physical attack vectors)

| ID | Summary | Affects |
|----|---------|---------|
| RP2350-E16 | USB_OTP_VDD disruption → corrupt OTP read | A2 (mitigated A3) |
| RP2350-E20 | Physical glitch → unsigned code on secured device via `reboot()` | A2 (mitigated A3) |
| RP2350-E21 | Physical glitch → extract OTP data in BOOTSEL mode | A2 (mitigated A3) |
| RP2350-E24 | Physical glitch → unsigned code execution | A2, A3 (mitigated A4) |
| RP2350-E25 | LOAD_MAP with non-word size doesn't error | A2, A3 (fixed A4) |
| RP2350-E26 | RCP random delays create side-channel | A2, A3, A4 (mitigation in bootrom) |
| RP2350-E27 | Bus priority controls apply to wrong managers | A2, A3, A4 |
| RP2350-E28 | OTP keys for pages 62/63 applied to all lock words | A2, A3, A4 |

---

## Resolved issues (historical reference)

| Version | Issue | Resolution |
| --- | --- | --- |
| v0.8 | littlefs fails to format new Pico | Fixed in v0.9 (littlefs 2.9.3) |
| v0.12 | VGA not always detected at boot | Fixed in v0.17 (UART startup timing) |
| v0.12 | XInput driver disabled | Re-enabled in v0.18 after TinyUSB stabilization |
| v0.13–v0.18 | USB plug-in momentarily freezes system | Fixed in v0.19 (silicon-level fix to TinyUSB) |
| v0.5 | Mode 2 rendering glitch | Fixed in v0.5 |
| v0.15 | Affine sprites show garbage line | Fixed in v0.15 |
| v0.5 | Hub support spotty | Fixed in v0.11 (hub-in-hub, 16 devices) |
| v0.12–v0.23 | Modem supports raw TCP only; telnet WIP (`tel.c`) | Fixed April 18 2026 (networking commit): full telnet via `AT\N1`, listen via `AT\L` |

---

## Build / toolchain notes

- **v0.15**: Requires updated `rp6502.py` from `picocomputer/vscode-cc65`. Refresh all `.vscode` and `tools` files from the project template.
- **v0.13+**: Only RIA-W firmware is released as a `.uf2`. Plain RIA must be compiled from source (`picocomputer/rp6502`).
- **v0.10**: Must upgrade Pi Pico 1 boards to Pi Pico 2 — no Pico 1 support.

## Code page / filename behavior

**Source**: [[yt-ep12-fonts-vsync]] (Ep12)

The Picocomputer uses a FAT filesystem with both long (Unicode/UCS-2) and short (8.3) filenames. The **active code page** tells the FAT driver which single-byte encoding to use for short names.

**Issue**: If a file's long name contains characters that are not in the active code page's glyph set, the 6502 program will only see the 8.3 short name — a truncated name with a `~1` suffix (e.g., `RESUMÉ~1.TXT` instead of `résumé.txt`).

**Behavior**: The file is still accessible; only the visible name is degraded. Switching to a code page that covers the necessary glyphs will reveal the full filename.

**Workaround**: Match the active code page to the language of your filenames:
- French/Spanish/Western European: CP850 (default)
- English/German/Swedish/box-drawing: CP437
- Cyrillic: CP855

See [[code-pages]] for the full code page / FAT interaction.

---

## Running vintage BASIC (EhBASIC)

**Source**: [[yt-ep17-basics-of-basic]] (Ep17)

### `RND(1)` vs `RND(0)` in EhBASIC

Lee Davison's Enhanced BASIC (EhBASIC) — the BASIC interpreter used on the Picocomputer — differs from Microsoft BASIC in one commonly-encountered function:

| Function call | EhBASIC behavior | Microsoft BASIC behavior |
|---|---|---|
| `RND(1)` | **Sets the random seed** (returns seeded value, not truly random) | Returns a random number |
| `RND(0)` | **Returns a random number** | Returns the last random number |

**Impact**: Classic BASIC program listings from books like "BASIC Computer Games" (David Ahl) use `RND(1)` expecting Microsoft BASIC semantics — they will produce the same "random" output every run.

**Fix**: Global search and replace `RND(1)` with `RND(0)` in any vintage listing that exhibits non-random behavior.

> **Note from Ep17**: This is described as the only systematic change needed to run programs from the BASIC Computer Games books on EhBASIC. Other differences exist but are program-specific.

### CONTINUE after unexpected stop

If a program unexpectedly stops (e.g., user pressed Enter on an `INPUT` prompt without typing anything — EhBASIC stops the program in this case, unlike Microsoft BASIC which repeats the prompt), use the `CONTINUE` command to resume.

---

## Community-reported issues (from Discord)

### VGA Not Found on cold boot — v0.16/v0.17 (fixed v0.18)

**Symptom**: `VGA Not Found` appears on first power-up; system works fine after any subsequent reboot.

**Cause**: Cold-boot UART noise from RP2350 A2-stepping hardware corrupts the RIA→VGA backchannel before the VGA firmware is ready. The `VGA_BACKCHANNEL_ACK_MS` timeout of 1 ms was insufficient on real hardware (vs. emulated/hot-reload).

**Fix** (merged v0.18 — `vga_connect()` in `ria/sys/vga.c`):
```c
busy_wait_ms(5);
while (stdio_getchar_timeout_us(0) != PICO_ERROR_TIMEOUT)
    tight_loop_contents();
```
Minimum reliable value is **5 ms** on RP2350 A2 boards. (@ndjordjevic5067 + @rumbledethumps, 2026-02-26)

### PHI2 reset to 100 kHz after config file truncation — v0.16 (fixed v0.17)

**Symptom**: System becomes extremely slow after a v0.16 flash; `STATUS` reports PHI2 at 100 kHz.

**Cause**: Config file containing `SET PHI2 8000` was zeroed out during firmware upgrade, reverting clock to default 100 kHz.

**Fix**: Enter `SET PHI2 8000` in the monitor manually, then `SAVE`. (@rumbledethumps, 2026-01-02)

### Raspberry Pi keyboard — num lock breaks right-side keys (fixed v0.18)

**Symptom**: On the Raspberry Pi official keyboard (no numpad, VID `04d9` PID `0006`), keys on the right side of the keyboard misbehave after the system forces num lock ON — the RP6502 firmware was enabling num lock globally, causing the RPi keyboard to enter a numpad emulation mode.

**Fix** (PR #118): Added a PID/VID exception in the HID driver so the RPi keyboard is not sent a num lock enable command. (@ndjordjevic5067, 2026-02-28; merged v0.18)

### USB freezes on device plug-in — v0.1–v0.18 (fixed v0.19)

**Symptom**: System hangs or behaves erratically when a USB device is plugged in, especially after a USB mass storage device triggers a mount event.

**Cause**: Silicon bug in the RP2040/RP2350 USB SIE: the SIE shares a single set of handshake latches across EPX and interrupt endpoint transactions. An interrupt poll occurring immediately after an EPX transfer overwrites the EPX handshake before the IRQ handler reads it.

**Fix** (v0.19): Required full rewrites of the HCD, MSC Transport, and SCSI layers (~200 engineering hours). Upstream TinyUSB PR submitted at `hathach/tinyusb#3582`. (@rumbledethumps, 2026-03-05)

### llvm-mos SDK version lock (fixed in llvm-mos-sdk commit 6d99981)

**Symptom**: `cmake` fails with error about mismatched clang version when using llvm-mos-sdk v22.

**Cause**: llvm-mos-sdk v22 hardcoded a specific clang version in its cmake files.

**Fix**: Update llvm-mos-sdk to a commit after `6d99981`. (@tonyvr0759, 2026-02-24)

### cc65 from package managers (Homebrew, apt, etc.) will not work

Package manager versions of cc65 (including v2.18 from Homebrew on macOS) are years out of date and lack RP6502 platform support. You **must** build cc65 from the picocomputer fork source or use a picocomputer-provided snapshot. (@rumbledethumps, 2026-04-17)

### Affine sprite line glitch on RP2350 — fixed in v0.16

**Cause**: RP2350 broke the hardware interpolator behaviour relied upon by the VGA affine sprite rotation ASM code.

**Fix**: Affine sprite rendering line replaced with equivalent C code (commit `2277d06`). (@rumbledethumps, 2025-12-04)

### Build folder cmake regression in vscode

Occasionally after a vscode extension update, cmake loses its configuration or intellisense breaks. **Fix**: Delete the `build/` folder and reconfigure. (@rumbledethumps, 2025-12-04)

---

## Related pages

- [[release-notes]] · [[rp6502-ria-w]] · [[rp6502-ria]] · [[rp6502-vga]]
- [[dma-controller]] — RP2350 DMA errata E5, E8
- [[usb-controller]] — RP2350 USB errata E12
- [[code-pages]] — full code page documentation
- [[yt-ep12-fonts-vsync]] · [[yt-ep17-basics-of-basic]]
- [[rumbledethumps-discord]] — Discord community bug reports and workarounds

