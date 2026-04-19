---
type: source
tags: [rp6502, firmware, source, ria, vga, pio, api]
related:
  - "[[rp6502-ria]]"
  - "[[rp6502-vga]]"
  - "[[rp6502-os]]"
  - "[[ria-registers]]"
  - "[[api-opcodes]]"
  - "[[pio-architecture]]"
  - "[[gpio-pinout]]"
sources: []
created: 2026-04-16
updated: 2026-04-16
---

# rp6502-github-repo

**Summary**: Shallow clone of the `picocomputer/rp6502` monorepo at commit `368ed8e` (2026-04-11). Canonical source for all three firmware variants (RIA, RIA-W, VGA), build system, and the complete OS API surface.

---

## What this source establishes

- All three firmwares ship from a single monorepo under `src/ria/` and `src/vga/`. There is no separate SDK repo.
- The complete [[api-opcodes]] dispatch table lives in `src/ria/main.c` — every OS call has a numeric op-code.
- Exact register addresses (from `src/ria/api/api.h`) — fills in what the web docs described functionally.
- GPIO [[gpio-pinout]] for the RIA Pico — not in the web docs.
- PIO state machine layout ([[pio-architecture]]) — how the RIA bit-bangs the 65C02 bus.
- RP2350 runs at **256 MHz / 1.15 V** — not mentioned in the web docs.
- Full [[rp6502-abi]] detail: xstack = 512 bytes, mbuf = 1 KB.
- Complete errno list (19 codes) — the web docs only showed a partial sample.

## Repo layout

```
src/
  ria/          RIA (and RIA-W) firmware
    sys/        Core: ria.c, cpu.c, pix.c, mem.c, cfg.c, com.c, vga.c, sys.c, led.c, lfs.c
    api/        OS API handlers: api.c, std.c, atr.c, clk.c, dir.c, oem.c, pro.c
    mon/        Monitor CLI: mon.c, fil.c, rom.c, ram.c, set.c, vip.c, hlp.c
    aud/        Audio: aud.c, psg.c, opl.c, bel.c
    hid/        Input: kbd.c, mou.c, pad.c + keyboard layout headers
    net/        Networking (RIA-W only): ble.c, cyw.c, mdm.c, ntp.c, wfi.c, tel.c, cmd.c
    usb/        USB host/device: usb.c, msc.c, nfc.c, vcp.c, xin.c
    str/        Strings/i18n: rln.c, str.c
    ria.pio     PIO programs for 6502 bus interface + PIX + VGA backchannel RX
    main.c      Entry point, API dispatch table, OS scheduler
  vga/          VGA firmware
    sys/        Core: sys.c, pix.c, ria.c, vga.c, com.c, led.c, mem.c
    modes/      Video mode renderers: mode1–5 + modes.h (1bpp render utils)
    scanvideo/  Scanline output: scanvideo.c/h + scanvideo.pio
    term/       ANSI terminal: term.c, color.c, font.c
    usb/        CDC USB: usb.c, cdc.c, descriptors.c
    vga.pio     PIO programs for VGA pixel output
  fatfs/        FatFs r0.15+ (BSD-3-Clause) — FAT12/16/32 for USB MSC
  emu8950/      OPL2 software emulator (BSD-2-Clause)
  tinyusb_rp6502/  Custom TinyUSB patches for USB host on RP2350
```

## Key source files for wiki reference

| File | What it defines |
| --- | --- |
| `src/ria/api/api.h` | Register addresses, xstack API, return helpers, full errno enum |
| `src/ria/main.c` | Complete API op-code dispatch (0x01–0x2E), XREG RIA dispatch, OS scheduler |
| `src/ria/sys/ria.h` | RIA PIO assignments, GPIO base pins, mbuf operations |
| `src/ria/sys/cpu.h` | RP2350 clock (256 MHz/1.15 V), PHI2/RESB/IRQB pin numbers, PHI2 range |
| `src/ria/sys/pix.h` | PIX frame format macro, device IDs, send helpers |
| `src/ria/sys/mem.h` | xram, xstack (512 B), mbuf (1 KB), regs[] layout |
| `src/ria/ria.pio` | pix_tx, ria_action, ria_read, ria_write, ria_cs_rwb, vga_backchannel_rx |
| `src/ria/api/std.h` | open/close/read/write/lseek/syncfs declarations |
| `src/ria/api/dir.h` | Full directory API (stat, opendir, readdir, chmod, utime, mkdir, chdir…) |
| `src/ria/api/pro.h` | Process manager, argv, exec, launcher state |
| `src/vga/sys/pix.h` | VGA-side PIX receiver PIO (pio1 SM1=regs, SM2=xram), PHI2 pin on VGA Pico |

## Notable quirks / things not in the web docs

- **256 MHz / 1.15 V**: The RIA Pico is overclocked with a voltage boost. One community member tested 280 MHz on default 1.10 V.
- **`regs[]` survives soft reboot**: RIA registers live in uninitialized RAM. A hard reboot with the physical button overwrites this — may function as a security feature.
- **`tel.c` exists**: A telnet module is present in `src/ria/net/` alongside the Hayes modem. The web docs state the modem doesn't expose a telnet shell; `tel.c` likely implements the underlying TCP/telnet transport for modem connections, not a user-facing shell. See [[rp6502-ria-w-docs]] for the documented boundary.
- **Deprecated attributes**: Op-codes 0x02 (phi2), 0x03 (code_page), 0x04 (lrand), 0x06 (errno_opt) are marked deprecated in `atr.h`; replaced by the generic 0x0A/0x0B get/set attribute calls.
- **mbuf also used as littlefs buffer**: The 1 KB misc buffer doubles as the read/write buffer for the internal LittleFS filesystem (config storage on Pico flash).
- **OEM driver**: `oem.c` manages IBM/DOS-style code pages and affects VGA rendering, FatFs filename encoding, and keyboard layouts simultaneously.

## Related pages

- [[ria-registers]] · [[api-opcodes]] · [[pio-architecture]] · [[gpio-pinout]]
- [[rp6502-abi]] · [[xram]] · [[pix-bus]] · [[rp6502-os]]
- [[rp6502-ria]] · [[rp6502-vga]] · [[rp6502-ria-w]]
