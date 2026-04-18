---
type: source
tags: [rp6502, examples, vga, audio, psg, gamepad, nfc, fatfs, exec]
related: [[rp6502-vga]], [[programmable-sound-generator]], [[fatfs]], [[xram]], [[xreg]], [[rp6502-ria]]
sources: []
created: 2026-04-18
updated: 2026-04-18
---

# picocomputer/examples

**Summary**: The official RP6502 examples repository — ~20 C source programs covering every major subsystem API; the canonical usage reference for VGA modes, audio PSG, gamepad input, NFC, FatFS, process exec, and performance benchmarking.

---

## Source

- GitHub: `https://github.com/picocomputer/examples`
- Local submodule: `raw/github/picocomputer/examples/` (commit `95965c6`)
- No tags; latest commit adds telnet support to `term.c`
- License: BSD-3-Clause / Unlicense (dual)

## Contents

All programs live in `src/`. See individual concept pages for API details.

| File | Subsystem | What it demonstrates |
|------|-----------|----------------------|
| `mode1.c` | VGA | Text/tile mode (40×30 chars, scrolling) |
| `mode2.c` | VGA | Tile bitmap mode (1bpp and 8bpp tiles) |
| `mode3.c` | VGA | Planar bitmap mode (1/2/4/8/16 bpp) |
| `mode5.c` | VGA | Multi-sprite mode (stars, runners, asteroid) |
| `vsync.c` | VGA | VSYNC and IRQ correctness test |
| `affine.c` | VGA | Affine-transform sprites (mode 4 asprite) |
| `raspberry.c` | VGA | Simple sprites (mode 4 sprite, BGAR5515) |
| `paint.c` | VGA + Input | Mouse-driven paint app (3 overlaid mode-3 layers) |
| `mandelbrot.c` | VGA | Full-screen mode-3 pixel rendering |
| `palette.c` | VGA | ANSI escape-code palette test (256-color + RGB) |
| `attr.c` | RIA | RIA attributes: PHI2_KHZ, LRAND, RLN_LENGTH |
| `ezpsg.h/.c` | Audio | Easy PSG library: tracker + note playback engine |
| `furelise.c` | Audio | Für Elise played via ezpsg |
| `poprock.c` | Audio | Procedural pop/rock track via ezpsg |
| `gamepad.c` | Input | Gamepad polling (4 players, all buttons/axes) |
| `rtc.c` | Time | POSIX `time()`/`gmtime()`/`localtime()` demo |
| `nfc.c` | NFC | NDEF read/write via `NFC:` device |
| `dir.c` | FatFS | Directory listing + disk free space |
| `exec.c` | OS | `ria_execl()` process replacement |
| `bench.c` | Performance | USB mass storage read/write benchmark |
| `altair1.c` + `altair2.c` | App | Altair 8800 emulator (CMake asset loading) |
| `term.c` | App | Hayes modem terminal (`AT:` device, code page 437) |

## Related pages

- [[vga-display-modes]] — VGA mode APIs
- [[vga-graphics]] — VGA graphics techniques
- [[programmable-sound-generator]] — PSG reference + ezpsg library
- [[ezpsg]] — ezpsg entity page
- [[gamepad-input]] — gamepad data layout
- [[nfc]] — NFC device API
- [[fatfs]] — FatFS directory API
- [[exec-api]] — process exec API
- [[performance]] — storage benchmark results
