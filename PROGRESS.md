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
- ⬜ *(Optional)* Export Discord RP6502 channels via DiscordChatExporter → `raw/discord/`

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
- 👉 Ingest **Zaks Programming the 6502** (raw/pdfs/)
- ⬜ Ingest Discord export (if collected)

## Phase 3 — Maintain & synthesize

- ✅ First lint pass (contradictions, orphans, gaps, missing cross-refs)
- ✅ Second lint pass (stale open questions pruned, hub lists updated)
- ✅ Full source audit — all raw sources cross-checked against wiki; 4 fixes applied (ria-registers register map, XSTACK register name, RIA_SPIN stub size, DREQ_PWM_WRAP7 book typo)
- ✅ `wiki/overview.md` kept current (revised after every ingest session)
- ⬜ File first query answer to `wiki/syntheses/` (suggested: "What does the RIA actually do?")
- ⬜ Backfill missing entity pages: ~~[[cc65]], [[llvm-mos]]~~ ✅ done (Sessions 3–9)
- ⬜ VIA pinout / J1 GPIO header (requires schematic PDF — not yet in `raw/`)
- ⬜ VGA GPIO full pinout — DAC output and sync pins not yet confirmed

---

## Current wiki size

| Category | Count |
|---|---|
| Sources | 13 + 22 (youtube-playlist + ep01–ep22 except ep05) + 1 (leventhal-6502-assembly) + 1 (leventhal-subroutines) + 1 (wagner-assembly-lines) = **38** |
| Entities | 8 + 2 (cc65, llvm-mos) + 1 (6522-via) = **11** |
| Concepts | 23 + 3 (code-pages, programmable-sound-generator, opl2-fm-synth) + 2 (65c02-instruction-set, 65c02-addressing-modes) + 5 (6502-interrupt-patterns, 6502-subroutine-conventions, 6502-application-snippets, 6502-programming-idioms, 6502-data-structures) + 2 (6502-emulated-instructions, 6502-common-errors) + 1 (6502-io-patterns) + 3 (learning-6502-assembly, 6502-stack-and-subroutines, 6502-relocatable-and-self-modifying) = **39** |
| Topics | 4 (overview, version-history, known-issues, development-history) = **4** |
| Inbox | 1 (zaks-programming-6502-ingest-plan) |
| **Total pages** | **~92** |

---

## How to use this file

- Before starting work, ask Claude "what's next on PROGRESS.md?" — the `👉` item is always the current target.
- After a step finishes, Claude flips `👉` → `✅` and promotes the next `⬜` to `👉`.
- New tasks go into the right phase; reorder freely. No need to keep history here — `wiki/log.md` is the permanent record.
