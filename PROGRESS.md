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
- ⬜ Download **W65C02S datasheet** PDF → `raw/pdfs/w65c02s-datasheet.pdf`
- ⬜ *(Optional)* Populate `raw/youtube/VIDEO_INDEX.md` with RP6502 videos and fetch captions via `yt-dlp`
- ⬜ *(Optional)* Export Discord RP6502 channels via DiscordChatExporter → `raw/discord/`

## Phase 2 — Ingest sessions

One source at a time. Each session follows the 9-step ingest workflow in `CLAUDE.md`.

- ✅ Ingest `raw/web/picocomputer.github.io/` (6 pages → 18 wiki pages: 6 sources, 7 entities, 8 concepts)
- ✅ Ingest `raw/github/picocomputer/rp6502/` — structure, key source files (5 new pages: source + 4 concepts; 7 pages updated)
- ✅ Ingest `raw/github/picocomputer/rp6502/releases/` — 23 releases v0.1–v0.23 (3 new pages: release-notes, version-history, known-issues)
- ✅ Ingest **Quadros** — "Knowing the RP2040" (all 10 selected chapters; 9 new concept pages: [[pio-architecture]], [[gpio-pinout]], [[dual-core-sio]], [[rp2040-memory]], [[dma-controller]], [[usb-controller]], [[rp2040-clocks]], [[rp2040-uart]], [[rp2040-spi]])
- ✅ Ingest **Fairhead** — "Programming The Raspberry Pi Pico/W In C" (all planned chapters ingested: PIO, GPIO, multicore, FreeRTOS, WiFi, SPI, UART)
- ⏭ ~~Ingest RP2040 datasheet~~ — skipped; no RP2040 in RP6502; covered architecturally by Quadros + Fairhead
- 👉 Ingest **RP2350 datasheet** — plan in `wiki/inbox/rp2350-datasheet-ingest-plan.md` (14 sessions: SIO/TMDS, PIO, GPIO, clocks, DMA, USB, SPI, UART, HSTX, errata; also verifies the nine `rp2040-*.md` pages)
- ⬜ Ingest **Pico C SDK reference** (`RP-009085-KB-1`) — plan in `wiki/inbox/pico-c-sdk-ingest-plan.md` (14 sessions: SDK architecture, PIO/PIOASM, hardware APIs, multicore/sync)
- ⬜ Ingest W65C02S datasheet — instruction set, timing, pinout
- ⬜ Ingest YouTube captions (if collected)
- ⬜ Ingest Discord export (if collected)

## Phase 3 — Maintain & synthesize

- ✅ First lint pass (contradictions, orphans, gaps, missing cross-refs)
- ✅ Second lint pass (stale open questions pruned, hub lists updated)
- ✅ Full source audit — all raw sources cross-checked against wiki; 4 fixes applied (ria-registers register map, XSTACK register name, RIA_SPIN stub size, DREQ_PWM_WRAP7 book typo)
- ✅ `wiki/overview.md` kept current (revised after every ingest session)
- ⬜ File first query answer to `wiki/syntheses/` (suggested: "What does the RIA actually do?")
- ⬜ Backfill missing entity pages: [[cc65]], [[llvm-mos]] (both toolchains have first-class support but no pages)
- ⬜ VIA pinout / J1 GPIO header (requires schematic PDF — not yet in `raw/`)
- ⬜ VGA GPIO full pinout — DAC output and sync pins not yet confirmed

---

## Current wiki size

| Category | Count |
|---|---|
| Sources | 10 |
| Entities | 7 |
| Concepts | 19 |
| Topics | 3 (overview, version-history, known-issues) |
| Inbox | 2 (rp2350-datasheet-ingest-plan, pico-c-sdk-ingest-plan) |
| **Total pages** | **~39** |

---

## How to use this file

- Before starting work, ask Claude "what's next on PROGRESS.md?" — the `👉` item is always the current target.
- After a step finishes, Claude flips `👉` → `✅` and promotes the next `⬜` to `👉`.
- New tasks go into the right phase; reorder freely. No need to keep history here — `wiki/log.md` is the permanent record.
