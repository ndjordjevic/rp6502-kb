---
type: source
tags: [rp6502, discord, community, hardware, firmware, opl2, usb, cc65, llvm-mos, nfc, telnet, razemos, native-os]
related: [[rp6502-ria]], [[rp6502-vga]], [[known-issues]], [[version-history]], [[opl2-fm-synth]], [[community-projects]], [[release-notes]]
sources: []
created: 2026-04-18
updated: 2026-04-18
---

# Rumbledethumps Discord Server

**Summary**: Community Discord server for the RP6502 Picocomputer (`rumbledethumps` server). Single source page covering all exported channels. Ingested: `#chat` (2022-11-03–2026-04-18, 1,015 messages) and `#razemos` (2026-03-17–2026-04-13, 32 messages). Covers build tips, hardware quirks, firmware development, USB bug hunting, OPL2 FM synthesis, community projects, design philosophy, and the razemOS native OS project.

---

## Scope

| Channel | File | Date range | Messages | Status |
|---------|------|------------|----------|--------|
| #chat | `rumbledethumps-chat-2022-11-03--2026-04-18.txt` | 2022-11-03 → 2026-04-18 | 1,015 | [x] ingested |
| #razemos | `rumbledethumps-razemos-2026-03-17--2026-04-13.txt` | 2026-03-17 → 2026-04-13 | 32 | [x] ingested |

---

## Key facts

### Hardware

- **HC vs AC logic chips**: HC series works at default 4 MHz; AC series required at 8 MHz. (@rogerl3915, 2022-11-14)
- **Getting past 8 MHz**: Requires external logic to handle chip select and RWB signals. (@rumbledethumps, 2022-12-04)
- **PHI2 sampling**: RIA samples CS & RWB *after* PHI goes high — deliberate workaround for timing margin. (@rumbledethumps, 2022-12-04)
- **GPIO voltage**: All GPIO header pins run at 3.3V; 5V from USB is also available on the header for peripherals. (@rumbledethumps, 2023-12-23)
- **PIX bus speed**: Corrected to **64 Mbit/s** (not 32 Mbit/s). (@rumbledethumps, 2026-04-17)
- **Rev B board**: Removed the 2×3 SWD pin headers under the RIA socket. (@rumbledethumps, 2026-02-28)
- **Pico2 recommended**: Both RIA and VGA should use Pi Pico 2 (RP2350). A2 stepping confirmed working. (@jasonr1100, 2026-02-18)

### VGA cold boot bug (fixed in v0.18)

Symptom: `VGA Not Found` on first power-up; rebooting fixes it. Cause: UART noise from RP2350 on cold start corrupts the RIA–VGA backchannel. Fix added to `vga_connect()`:

```c
busy_wait_ms(5);
while (stdio_getchar_timeout_us(0) != PICO_ERROR_TIMEOUT)
    tight_loop_contents();
```

5 ms is the minimum reliable value on A2-stepping RP2350 hardware. (@ndjordjevic5067 + @rumbledethumps, 2026-02-26)

### Firmware / RIA internals

- **NOP padding in `api.h`**: For 32-bit ARM alignment — ARM goes boom on unaligned 32-bit access. (@rumbledethumps, 2025-08-24)
- **RP2350 M33 unaligned access**: Handled natively by M33 core; RP2040 AHB had partial support. (`REGSW` with misaligned pointer is safe on RP2350.) (@rumbledethumps, 2025-08-27)
- **`regs[]` in scratch_x**: The original `equ` hack to place register array in scratch_x was "hack and pray". Correct approach: `__attribute__((section(".scratch_x"))) volatile uint8_t regs[0x40];` — but fine in main RAM on RP2350. (@markrvm + @rumbledethumps, 2025-08-31)
- **`AUD_PWM_IRQ_PIN 14`**: GPIO 14 is used for PWM IRQ timing, **not** as a GPIO (comment: `/* No IO */`). (@rumbledethumps, 2025-09-06)
- **Race condition fixed (v0.23)**: Three-year-old race condition in the critical bus loop resolved; allows `-O3` on the action loop for the first time. (@rumbledethumps, 2026-03-22)
- **RIA RAM pressure**: ~32K bytes left in RIA firmware as of v0.24; paged memory will **never** be added. (@rumbledethumps, 2026-04-17)
- **Memory map link**: `https://github.com/picocomputer/llvm-mos-sdk/blob/main/mos-platform/rp6502/link.ld` — "it's all RAM, not much to map." (@rumbledethumps, 2024-01-27)

### USB stack (TinyUSB)

- **Root silicon bug (fixed v0.19)**: The USB SIE shares a single set of handshake latches across EPX and interrupt endpoint transactions. When SIE finishes EPX and immediately starts an interrupt poll, the poll's handshake overwrites EPX latches before IRQ handler reads them. Required ~200 hours and custom HCD/MSC rewrites to diagnose and fix. (@rumbledethumps, 2026-03-05)
- **MSC speed (v0.22)**: Flash drives ~512 KB/s; floppy drives ~15 KB/s. DMA-assisted; uses **no 6502 CPU**. (@rumbledethumps, 2026-04-05)
- **MSC speed (v0.23)**: Flash drives ~800–1000 KB/s in benchmarks; varies by drive. (@voidas_pl, 2026-04-12)
- **VCP driver (v0.18)**: Up to 8 USB-to-serial adapters accessible via `open("VCP3:9600,7E2", 0)`. (@rumbledethumps, 2026-02-09)
- **NFC reader support (v0.21+)**: PN532-based readers via CDC serial (CH34X adapter); `SET NFC 0/1/2`. Write NDEF TEXT record from phone app; RP6502 auto-launches named ROM on tap. (@rumbledethumps, 2026-03-19; @jasonr1100, 2026-03-30)
- **Floppy disk**: 3.5" USB floppy drives work at ~15 KB/s. (@rumbledethumps, 2026-02-12)
- **TinyUSB PR**: Fixes submitted upstream at `hathach/tinyusb#3582`.

### OPL2 FM synthesis (v0.16+)

- Native OPL2 added to RIA firmware in v0.16 using `emu8950` emulator (Doom version + PicoGUS fix). Runs on RP2350 at 256 MHz, ~16K RAM. See [[opl2-fm-synth]].
- PSG is **disabled** when native OPL2 is active — one sound card at a time. (@rumbledethumps, 2026-01-10)
- Audio upgraded 8-bit → 10-bit PWM in v0.17; BLE audio noise fixed; OPL level boosted 12 dB.
- FPGA OPL2 extension card possible via PIX bus (jasonr1100 built one with JTOPL + Y3014B DAC).

### Telnet & networking (v0.24)

- Telnet console: reach monitor and running 6502 from remote telnet client. `SET PORT`, `SET KEY`.
- Hayes modem: dial out, answer calls, over raw TCP or telnet. 10 persistent modem configs.
- Telnet upload speed: ~56 KB/s vs serial ~11 KB/s (not throttled by UART).
- Multi-user BBS possible: up to 4 modems simultaneously; headless operation (USB drive + power only).

### ROM format extensions (v0.21+)

- ROM-embedded assets: `rp6502_asset(name alias src)` → accessible via `open("ROM:filename", O_RDONLY)`.
- ROM launching ROMs: `ria_execl()` with argc/argv support.
- Debug builds can use filesystem path (`/myapp/assets/`); release builds use `ROM:` prefix.

### cc65 / llvm-mos toolchain

- **Homebrew cc65 is too old**: Package manager versions (v2.18/v2.19) will not work. Must build from picocomputer/cc65 source or use a snapshot. (@rumbledethumps, 2026-04-17)
- **vscode-cc65 template**: Recommended starting point; workspace config (`.rp6502`) for serial port — do not check in workstation config.
- **llvm-mos**: Keep llvm-mos-sdk updated; `lseek()` broken in old SDK (v22.4.0 fixes it). (@voidas_pl, 2025-12-28)
- **cc65 vs llvm-mos binary size**: cc65 makes smaller binaries, slightly slower. llvm-mos: larger binaries, no good size optimizations yet. (@rumbledethumps, 2025-12-02)
- **`lrand()`**: Available in recent llvm-mos-sdk (replaces `rand()` for hardware entropy).
- **DST / time zone support**: `localtime()` DST fix contributed upstream to cc65 (PR #2911, merged 2026-01-04); `SET TZ` accepts POSIX TZ strings or city names.
- **Intellisense with cc65**: `"C_Cpp.default.configurationProvider": "ms-vscode.cmake-tools"` setting in vscode; cmake path auto-resolved.

### Development tips

- **No hardware debugger for 6502**: Print debug is the only option. `printf()` still works in graphics mode (appears in vscode console).
- **`__breakpoint()` trick**: Place `__breakpoint()` at entry to debug init code — workaround for debugger not breaking at `main()`.
- **`phi2()` runtime check**: Call `phi2()` and bail if not 8000 for games near the PHI2 speed limit. (@rumbledethumps, 2025-12-03)
- **`read_xram()`**: Loads 64K without blocking 6502; use for large asset streaming. (@rumbledethumps, 2025-12-02)
- **VGA mode switching**: `SET VGA 1` for 16:9 widescreen; monitors default to "Grandma mode" (letterbox). (@rumbledethumps, 2026-02-07)
- **Build folder regression**: If vscode plugins update and break build, delete the build folder and reconfigure.
- **`remove()` vs `unlink()`**: llvm-mos uses `remove()`; cc65 uses `unlink()` — check when porting code.

### Design philosophy (from rumbledethumps)

- "The combo of 'DIY no solder homebrew made in china' and 'all through hole' is my flex." (2025-07-30)
- "Paged memory will also never be added." (2026-04-17)
- "Cheating to get I/O that doesn't suck is one thing. Doing all the heavy ALU work outside the 6502 is another thing entirely." (2026-04-17)
- "The community gets stronger when more people take initiative — not just by asking for things, but by doing them." (2025-07-17)
- "The stable resting state for all modern retro projects involves both a microcontroller and an FPGA. — Rumble's law" (2025-12-23)
- RP6502 is the **only** known project running 6502 bus at 8 MHz as of late 2022. (@rumbledethumps, 2022-12-04)

### Community use cases

- pjf. teaches college microprocessor application development using RP6502 (built a dozen boards).
- stephanh80 built a wire-wrapped RP6502 (no PCB).
- jasonr1100: professor at liberal arts university; works on space telescope missions; prolific game/demo developer.

---

## #razemos channel (2026-03-17–2026-04-13)

Topic: "Come together and build a native OS for the RP6502."

### razemOS project

- **Name**: "razemos" = "togetherOS" in Polish (voidas_pl); also contains "MOS". Channel name bikeshedded and approved by community. (@voidas_pl + @rumbledethumps, 2026-03-17)
- **Developer**: `voidas_pl` (Discord) = `WojciechGw` (GitHub); repo: `https://github.com/WojciechGw/cc65-rp6502os`
- **Starting point**: WojciechGw's `cc65-rp6502os` repo; rumbledethumps also cited GeckOS and LUnix as inspiration.

#### Release history

| Version | Date | Highlights |
|---------|------|-----------|
| 0.01-pre | 2026-03-18 | Working pre-release |
| 0.01 | 2026-04-10 | razemOS kernel + **HASS** (Handy ASSembler for 65C02) as standalone `.rp6502`; `ctx.py`/`crx.py` PC transfer scripts |
| 0.02 | 2026-04-12 | Bug fixes; `pack` command (zip STORE+DEFLATE); `roms` command (.rp6502 launchpad in current directory) |

#### Architecture notes

- razemOS kernel fits entirely below `0x8000`. (@voidas_pl, 2026-04-10)
- **HASS** separated out as standalone `.rp6502` because it needs memory from `0x7B00` to run as a `.com` program.
- Goal: multitasking support (in progress as of 2026-04-10).
- **v0.21 non-blocking CON: and TTY:** useful building blocks for multitasking. (@rumbledethumps, 2026-03-29)
- Launcher integration: https://picocomputer.github.io/os.html#launcher explains how the launcher can serve as supervisor for a native OS boot sequence.

#### OS exec vs ria_exec()

> Use the OS `exec` (not `ria_exec()`) to load OS apps — this leaves the launcher system free to supervise OS restarts. (@rumbledethumps, 2026-04-10)

#### ROM self-update pattern

> You can't update a ROM that's running. If you're booting your OS as a ROM, that's how you can self-update. (@rumbledethumps, 2026-04-10)

### Keyboard exit convention (proposed)

Discussed in the context of razemOS needing a clean way to exit ROMs:

- **ESC** should NOT be used as exit: raw ESC byte crashes games expecting menu input.
- **ALT-F4** = exit to launcher (universal "clean exit").
- **CTRL-ALT-DEL** = exit to monitor (force restart).
- Community consensus reached; jasonr1100 agreed to add ALT-F4 to existing ROMs. (@rumbledethumps + @jasonr1100, 2026-04-10)

---

## Related pages

- [[version-history]]
- [[known-issues]]
- [[opl2-fm-synth]]
- [[community-projects]]
- [[release-notes]]
- [[rp6502-ria]]
- [[rp6502-vga]]
