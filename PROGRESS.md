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
- ✅ Shallow-clone `picocomputer/rp6502` at a pinned commit → `raw/github/picocomputer/rp6502/` + note SHA in `raw/README.md` (commit `368ed8e`, 2026-04-11)
- ✅ **"Knowing the RP2040" (Quadros, 2022)** → `raw/pdfs/Knowing the RP2040 (Quadros).pdf` — ingestion plan at `wiki/inbox/quadros-rp2040-ingest-plan.md` (10 chapters selected, 7 skipped)
- ✅ **"Programming The Raspberry Pi Pico/W In C" (Fairhead, 3rd ed. 2025)** → `raw/pdfs/Programming The Raspberry Pi Pico_W In C, Third Edition_nodrm.pdf` — ingestion plan at `wiki/inbox/fairhead-pico-c-ingest-plan.md` (11 chapters selected, 8 skipped)
- 👉 Download **RP2040 datasheet** PDF → `raw/pdfs/rp2040-datasheet.pdf`
- ⬜ Download **RP2350 datasheet** PDF → `raw/pdfs/rp2350-datasheet.pdf`
- ⬜ Download **W65C02S datasheet** PDF → `raw/pdfs/w65c02s-datasheet.pdf`
- ⬜ *(Optional)* Populate `raw/youtube/VIDEO_INDEX.md` with RP6502 videos and fetch captions via `yt-dlp`
- ⬜ *(Optional)* Export Discord RP6502 channels via DiscordChatExporter → `raw/discord/`

## Phase 2 — First ingest sessions

One source at a time. Each session follows the 9-step ingest workflow in `CLAUDE.md`.

- ✅ Ingest `raw/web/picocomputer.github.io/` (6 pages → 18 wiki pages: 6 sources, 7 entities, 8 concepts; overview + index revised)
- ✅ Ingest `raw/github/picocomputer/rp6502/` — structure, README, key source files (5 new pages: source + 4 concepts; 7 pages updated)
- ✅ Ingest `raw/github/picocomputer/rp6502/releases/` — 23 releases v0.1–v0.23 (3 new pages: release-notes, version-history, known-issues)
- ⬜ Ingest **Quadros** — "Knowing the RP2040" (10 chapters; follow `wiki/inbox/quadros-rp2040-ingest-plan.md`)
- ⬜ Ingest **Fairhead** — "Programming The Raspberry Pi Pico/W In C" (11 chapters; follow `wiki/inbox/fairhead-pico-c-ingest-plan.md`)
- ⬜ Ingest RP2040 datasheet — chapters relevant to RIA (PIO, USB, GPIO, clocks); ≤25 pages per session
- ⬜ Ingest RP2350 datasheet — chapters relevant to VGA firmware
- ⬜ Ingest W65C02S datasheet — instruction set, timing, pinout
- ⬜ Ingest YouTube captions (if collected)
- ⬜ Ingest Discord export (if collected)

## Phase 3 — Maintain & synthesize

- ✅ First lint pass (contradictions, orphans, gaps, missing cross-refs)
- ⬜ Revise `wiki/overview.md` into a real synthesis
- ⬜ File first query answer to `wiki/syntheses/` (suggested: "What does the RIA actually do?")
- ⬜ Backfill missing entity/concept pages surfaced by lint

---

## How to use this file

- Before starting work, ask Claude "what's next on PROGRESS.md?" — the `[>]` item is always the current target.
- After a step finishes, Claude flips `[>]` → `[x]` and promotes the next `[ ]` to `[>]`.
- New tasks go into the right phase; reorder freely. No need to keep history here — `wiki/log.md` is the permanent record.
