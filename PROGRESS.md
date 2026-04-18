# rp6502-kb — Progress Tracker

Single source of truth for what's done, what's next, and in what order.
Claude updates this file whenever a step completes or a new one is added.

Legend: ✅ done · ⬜ pending · 👉 up next · ⏭ skipped/deferred

---

## Phase 0 — Scaffold

- ✅ Research sources and approach → `research-llm-wiki-rp6502-sources.md`
- ✅ Write `CLAUDE.md` (schema, workflows, domain vocabulary)
- ✅ Stub `raw/` tree (`pdfs/`, `web/picocomputer.github.io/`, `github/picocomputer/`, `youtube/`, `discord/`, `assets/`) with `raw/README.md`
- ✅ Stub `wiki/` tree (`sources/`, `entities/`, `concepts/`, `syntheses/`, `topics/`, `inbox/`) with `index.md`, `log.md`, `overview.md`
- ✅ Stub `raw/youtube/VIDEO_INDEX.md`

## Phase 1 — Collect raw sources

Human-driven. Claude does not write to `raw/`.

- ✅ **Clip picocomputer.github.io with Obsidian Web Clipper** → `raw/web/picocomputer.github.io/` (6 pages: Picocomputer 6502, Hardware, RP6502-RIA, RP6502-RIA-W, RP6502-VGA, RP6502-OS)
- ✅ **`picocomputer/rp6502` repo** → `raw/github/picocomputer/rp6502/` as Git submodule at tag **v0.23** (commit `368ed8e`, 2026-04-11); nested submodules (`src/littlefs`, `src/tinyusb`) initialized; SHA + bump instructions in `raw/README.md`
- ✅ **"Knowing the RP2040" (Quadros, 2022)** → `raw/pdfs/Knowing the RP2040 (Quadros).pdf`
- ✅ **"Programming The Raspberry Pi Pico/W In C" (Fairhead, 3rd ed. 2025)** → `raw/pdfs/Programming The Raspberry Pi Pico_W In C, Third Edition_nodrm.pdf` — all planned chapters ingested; plan file deleted
- ⏭ ~~Download **RP2040 datasheet**~~ — skipped; RP6502 migrated to RP2350 at v0.10; no RP2040 in the system
- ✅ **RP2350 datasheet** PDF → `raw/pdfs/RP-008373-DS-2-rp2350-datasheet.pdf`
- ✅ **Raspberry Pi Pico C SDK reference** PDF → `raw/pdfs/RP-009085-KB-1-raspberry-pi-pico-c-sdk (1).pdf`
- ✅ **W65C02S datasheet** PDF → `raw/pdfs/w65c02s.pdf` (WDC official, Feb 2024, 32 pp.)
- ✅ **6502 Assembly Language Programming (2nd Ed)** — Leventhal 1986 → `raw/pdfs/`
- ✅ **Assembly Lines Complete** — Roger Wagner 2014 → `raw/pdfs/`
- ✅ **Programming the 6502** — Rodnay Zaks 1983 → `raw/pdfs/`
- ✅ **6502 Assembly Language Subroutines** — Leventhal 1982 → `raw/pdfs/`
- ✅ Populate `raw/youtube/VIDEO_INDEX.md` with RP6502 videos and fetch captions via `yt-dlp` (21/22 transcripts; Ep5 has no captions)
- ✅ Export Discord RP6502 channels via DiscordChatExporter → `raw/discord/` (`#chat` 1,015 msgs + `#razemos` 32 msgs)

## Phase 2 — Ingest sessions

One source at a time. Each session follows the 9-step ingest workflow in `CLAUDE.md`.

- ✅ Ingest `raw/web/picocomputer.github.io/` (6 pages → 18 wiki pages: 6 sources, 7 entities, 8 concepts)
- ✅ Ingest `raw/github/picocomputer/rp6502/` — structure, key source files (5 new pages: source + 4 concepts; 7 pages updated)
- ✅ Ingest `raw/github/picocomputer/rp6502/releases/` — 23 releases v0.1–v0.23 (3 new pages: release-notes, version-history, known-issues)
- ✅ Ingest **Quadros** — "Knowing the RP2040" (all 10 selected chapters; 9 new concept pages: [[pio-architecture]], [[gpio-pinout]], [[dual-core-sio]], [[rp2040-memory]], [[dma-controller]], [[usb-controller]], [[rp2040-clocks]], [[rp2040-uart]], [[rp2040-spi]])
- ✅ Ingest **Fairhead** — "Programming The Raspberry Pi Pico/W In C" (all planned chapters ingested: PIO, GPIO, multicore, FreeRTOS, WiFi, SPI, UART)
- ⏭ ~~Ingest RP2040 datasheet~~ — skipped; no RP2040 in RP6502; covered architecturally by Quadros + Fairhead
- ✅ Ingest **RP2350 datasheet** — all 14 sessions complete: SIO/TMDS, PIO, GPIO, clocks, DMA, USB, SPI, UART, HSTX, errata (E1–E28); 1 new concept page ([[hstx]]), 9 concept pages updated with RP2350 differences, full errata table in [[known-issues]]; ingest plan deleted
- ✅ Ingest **W65C02S datasheet** — 1 source + 2 new concept pages ([[65c02-instruction-set]], [[65c02-addressing-modes]]); [[w65c02s]] entity greatly expanded with part decode, pin table, vectors, timing, WDC enhancements
- ✅ Ingest **YouTube playlist** — all 9 sessions complete; 21 source pages + 5 new concept/entity pages (code-pages, programmable-sound-generator, opl2-fm-synth, cc65, llvm-mos); development-history Eras A–E written
- ✅ Ingest **Leventhal 6502 Assembly Programming 2nd Ed** — 1 source + 6 new concept pages ([[6502-interrupt-patterns]], [[6502-subroutine-conventions]], [[6502-application-snippets]], [[6502-programming-idioms]], [[6502-data-structures]]); [[65c02-instruction-set]] augmented with Ch.17 pedagogical notes
- ✅ Ingest **Leventhal 6502 Assembly Language Subroutines** (raw/pdfs/) — All 3 passes complete. Pass 1 (Ch. 1–3 + Intro): 2 new concept pages ([[6502-emulated-instructions]], [[6502-common-errors]]), 2 augmented. Pass 2 (Ch. 6, 7, 11 + App B): 1 new entity ([[6522-via]]), 2 augmented ([[6502-programming-idioms]] + [[6502-interrupt-patterns]]). Pass 3 (Ch. 4, 5, 8, 9, 10): 1 new concept page ([[6502-io-patterns]]), 2 augmented ([[6502-application-snippets]] + [[6502-data-structures]])
- ✅ Ingest **Wagner Assembly Lines Complete** (raw/pdfs/) — All passes complete. Ch. 1/4/5/7/9/10/12/15/28/33 ingested. 3 new concept pages ([[learning-6502-assembly]], [[6502-stack-and-subroutines]], [[6502-relocatable-and-self-modifying]]); 2 augmented ([[6502-programming-idioms]] + [[65c02-addressing-modes]]); [[65c02-instruction-set]] augmented with Ch.33 Wagner perspective; [[wagner-assembly-lines]] source page
- ✅ Ingest **Zaks Programming the 6502** (raw/pdfs/) — Ch. II/III/V/VI/VIII/IX ingested. 1 new source page ([[zaks-programming-6502]]); 3 concept pages augmented ([[6502-programming-idioms]], [[6502-application-snippets]], [[6502-data-structures]]). Unique contributions: improved 8×8 multiply (10 instr), subroutine parameter passing comparison, 8 Ch.8 utility routines (ZEROM, bracket test, parity, ASCII↔BCD, find-max, 16-bit sum, EOR checksum, zero count), full data-structure library (linked list, circular, queue, tree, doubly-linked, binary search O(log₂N), hashing, merge)
- ✅ Ingest **Discord export** (raw/discord/) — `#chat` (1,015 msgs) and `#razemos` (32 msgs) fully ingested. 2 new pages ([[rumbledethumps-discord]], [[community-projects]]). Key additions from #chat: HC/AC chip selection, VGA cold-boot fix, TinyUSB silicon latch bug, cc65 Homebrew warning, PIX bus 64 Mbit/s correction, design philosophy quotes, community roster. Key additions from #razemos: razemOS project (v0.01/v0.02), HASS assembler, ALT-F4 exit convention, OS exec vs ria_exec() pattern, ROM self-update pattern.
- ✅ Ingest **picocomputer/examples** (raw/github/picocomputer/examples/, commit 95965c6) — 9 new pages: [[vga-display-modes]], [[vga-graphics]], [[gamepad-input]], [[rtc]], [[nfc]], [[exec-api]], [[ezpsg]], [[performance]], [[examples]] source; 2 updated: [[programmable-sound-generator]] (ezpsg section), [[fatfs]] (directory API)
- ✅ Ingest **picocomputer/pico-extras** (raw/github/picocomputer/pico-extras/, commit 7f48b3f) — New: [[pico-extras]] source page; Updated: [[rp6502-vga]] (pico-extras dependency section), [[vga-display-modes]] (mode-switching note). Only 2 rumbledethumps commits: memory leak fix + debug printf fix in `scanvideo_setup_with_timing()`
- ✅ Ingest **picocomputer/community wiki** (raw/github/picocomputer/community/, commit 348180a) — 2 pages: Home (project directory) + Incompatible USB and BLE Devices. New: [[community-wiki]] source, [[usb-compatibility]] topic; Updated: [[community-projects]] (full wiki project catalogue added), [[gamepad-input]] (USB compat section now links to [[usb-compatibility]])
- ✅ Ingest **picocomputer/ehbasic** (raw/github/picocomputer/ehbasic/, commit acd5deb) — New: [[ehbasic]] source + entity pages; Updated: [[ria-registers]] (ACIA simulation section). Key finding: no RP6502-specific BASIC extensions; I/O integration entirely in min_mon.s via ACIA registers and open()/close()/read_xstack()/write_xstack()

## Phase 3 — Learn, share, and apply

### 3b — Learn the wiki

- 👉 Open in Obsidian; explore graph view, backlinks, frontmatter filters
- ⬜ Ask Claude questions; get a feel for what the wiki knows and doesn't
- ⬜ File first synthesis page (`wiki/syntheses/`) — suggested: "What does the RIA actually do?"

### 3c — Share with the community

- ⬜ Polish `README.md` for public audience
- ⬜ Push to public GitHub and post link in RP6502 Discord

### 3d — RP6502 emulator project

- ⬜ New emulator repo; wire wiki in via multi-root workspace or `.context/` symlink
- ⬜ Add session-start hook to inject `overview.md` + `index.md` automatically
- ⬜ Vibe code with Claude citing wiki; feed new findings back into `wiki/`

---

## Current wiki size

| Category | Count |
|---|---|
| Sources | 43 + 1 (pico-extras) = **44** |
| Entities | **13** (rp6502-vga updated) |
| Concepts | **45** (vga-display-modes updated) |
| Topics | **7** |
| Inbox | 2 (vscode-cc65, vscode-llvm-mos ingest plans) |
| **Total pages** | **~109** |

---

## How to use this file

- Before starting work, ask Claude "what's next on PROGRESS.md?" — the `👉` item is always the current target.
- After a step finishes, Claude flips `👉` → `✅` and promotes the next `⬜` to `👉`.
- New tasks go into the right phase; reorder freely. No need to keep history here — `wiki/log.md` is the permanent record.
