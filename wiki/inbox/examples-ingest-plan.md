# picocomputer/examples — Ingest Plan

**Source**: https://github.com/picocomputer/examples (not yet a submodule — fetch files via WebFetch)
**Priority**: HIGH
**Approach**: Read each source file via WebFetch on `raw.githubusercontent.com`. Group by topic; extract API patterns and document in wiki concept/entity pages.

---

## Strategy

The examples repo is the canonical usage reference for every major RP6502 API. Each `.c` file in `src/` demonstrates a specific subsystem. Ingest by topic group rather than file-by-file; one wiki concept page per topic group is the target output.

The shared PSG library (`ezpsg.c/h`) should get its own entity page since it is used by multiple programs.

---

## Reading order

### Group 1 — VGA display modes
- [ ] `src/mode1.c` — text/tile mode
- [ ] `src/mode2.c` — bitmap mode
- [ ] `src/mode3.c` — another bitmap variant
- [ ] `src/mode5.c` — sprite/tile mode
- [ ] `src/vsync.c` — VSYNC synchronisation pattern
→ Create/update `wiki/concepts/vga-display-modes.md`

### Group 2 — VGA graphics techniques
- [ ] `src/affine.c` — affine transform API
- [ ] `src/attr.c` — character/tile attributes
- [ ] `src/palette.c` — palette manipulation
- [ ] `src/mandelbrot.c` — full-screen pixel rendering
- [ ] `src/paint.c` — interactive drawing
- [ ] `src/raspberry.c` — blit image from data array
→ Create/update `wiki/concepts/vga-graphics.md`

### Group 3 — Audio (PSG)
- [ ] `src/ezpsg.h` — PSG library API surface
- [ ] `src/ezpsg.c` — PSG driver implementation
- [ ] `src/furelise.c` — music playback example
- [ ] `src/poprock.c` — procedural audio example
→ Create `wiki/concepts/audio-psg.md`, `wiki/entities/ezpsg.md`

### Group 4 — Input peripherals
- [ ] `src/gamepad.c` — gamepad polling API
→ Create/update `wiki/concepts/gamepad-input.md`

### Group 5 — External peripherals
- [ ] `src/rtc.c` — real-time clock via I²C/SPI
- [ ] `src/nfc.c` — NFC reader integration
→ Create `wiki/concepts/rtc.md`, `wiki/concepts/nfc.md`

### Group 6 — OS / filesystem API
- [ ] `src/dir.c` — directory listing (FatFS OS calls)
- [ ] `src/exec.c` — launching child programs
→ Update `wiki/concepts/fatfs.md`, create `wiki/concepts/exec-api.md`

### Group 7 — Performance & benchmarking
- [ ] `src/bench.c` — CPU/IO throughput benchmark
→ Update `wiki/topics/performance.md` (create if absent)

### Group 8 — Complex applications
- [ ] `src/altair1.c` + `src/altair2.c` — Altair 8800 emulator (multi-file app structure)
- [ ] `src/term.c` — terminal emulator
→ Update `wiki/sources/examples.md` with app architecture notes; no dedicated concept page needed

---

## Wiki pages to create or update

| Page | Action |
|------|--------|
| `wiki/sources/examples.md` | Create — source summary page |
| `wiki/concepts/vga-display-modes.md` | Create or update |
| `wiki/concepts/vga-graphics.md` | Create or update |
| `wiki/concepts/audio-psg.md` | Create |
| `wiki/entities/ezpsg.md` | Create |
| `wiki/concepts/gamepad-input.md` | Create or update |
| `wiki/concepts/rtc.md` | Create |
| `wiki/concepts/nfc.md` | Create |
| `wiki/concepts/exec-api.md` | Create |
| `wiki/topics/performance.md` | Create if absent, else update |
| `wiki/index.md` | Update with new pages |
| `wiki/overview.md` | Revise to mention examples as API reference |
| `wiki/log.md` | Append ingest entry |
| `PROGRESS.md` | Flip status |

---

## Notes

- `raw.githubusercontent.com/picocomputer/examples/main/src/<file>` — use this URL pattern for WebFetch.
- Optionally add as a git submodule under `raw/github/picocomputer/examples/` after ingest; update `raw/github/README.md` and `raw/README.md` if so.
- If a VGA modes concept page already exists from the RIA/VGA web clip ingest, update it rather than creating anew.
