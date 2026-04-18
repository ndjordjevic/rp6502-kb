# rp6502-kb

A personal knowledge base about the RP6502 Picocomputer — hardware, firmware, OS API, and toolchain.
Maintained by Claude Code following Karpathy's LLM Wiki pattern.

Claude maintains the wiki. The human curates sources, asks questions, and guides the analysis.

---

## Folder structure

```
raw/          -- source documents (immutable — never modify these)
wiki/         -- markdown pages maintained by Claude
wiki/index.md    -- table of contents for the entire wiki
wiki/log.md      -- append-only record of all operations
wiki/overview.md -- living synthesis across all sources
```

Sub-folders under `wiki/` grow as the wiki grows:

```
wiki/sources/    -- one summary page per raw source
wiki/entities/   -- named things: boards, chips, signals, buses
wiki/concepts/   -- mechanisms and ideas: protocols, instruction sets, modes
wiki/syntheses/  -- filed answers to queries worth keeping
wiki/topics/     -- operational: getting-started, known-issues, comparisons
wiki/inbox/      -- rough notes awaiting organization
```

---

## Directory rules

- `raw/` source documents are **immutable**: never edit, delete, or create source files here. Exception: `README.md` index files in each subfolder are LLM-maintained — always keep them up to date.
- `wiki/` is **LLM-owned**: create, update, and link pages freely.
- Always update `wiki/index.md`, `wiki/overview.md`, and `wiki/log.md` at the end of every session.
- **Raw folder indexes — maintenance rules**:
  - Every `raw/` subfolder has a `README.md` index. All five must stay in sync with folder contents.
  - When a file is **added**: add a row to the subfolder `README.md` and to the `raw/README.md` "Added sources" table.
  - When a file is **removed**: remove its row from the subfolder `README.md`.
  - When a **github repo is added** (plain clone): add a row to `raw/github/README.md` and clone the repo into `raw/github/<org>/<repo>/`.
  - When the **github repo is updated**: pull latest, update the commit and date in `raw/github/README.md`.
  - When **new YouTube transcripts** are fetched: add rows to `raw/youtube/README.md` and update the coverage line.
  - Subfolder conventions:

  | Folder | Naming convention | Index file |
  | --- | --- | --- |
  | `raw/pdfs/` | Free-form (as supplied) | `raw/pdfs/README.md` — one row per PDF |
  | `raw/discord/` | `<server>-<channel>-<YYYY-MM-DD>--<YYYY-MM-DD>.txt` | `raw/discord/README.md` — one row per export |
  | `raw/youtube/` | `<video-id>-<sanitized-title>.md` | `raw/youtube/README.md` — one row per video |
  | `raw/web/` | `<Page Title> — <Site Name>.md` (Obsidian Web Clipper) | `raw/web/README.md` — one row per clipped page |
  | `raw/github/` | Plain git clone — `<org>/<repo>/` folder (untracked by parent repo) | `raw/github/README.md` — one row per repo |

---

## Page format

Every wiki page must begin with YAML frontmatter followed by a summary line:

```markdown
---
type: source | entity | concept | synthesis | topic
tags: [rp6502, ria, hardware, ...]
related: [[page-name]], [[other-page]]
sources: [[source-name]], [[other-source]]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Page Title

**Summary**: One to two sentences describing this page.

---

Main content here. Use clear headings and short paragraphs.
Link to related pages using [[wikilinks]] throughout.

## Related pages

- [[related-concept-1]]
- [[related-concept-2]]
```

- Keep page names lowercase with hyphens: `ria-protocol.md`, `memory-map.md`.
- Use `[[wikilinks]]` for all cross-references inside the wiki.
- Use `[text](../raw/path/file.md)` only when pointing at a `raw/` file.

---

## Discord ingest workflow

Discord exports live in `raw/discord/` as plain-text files exported by DiscordChatExporter.
Each file covers one channel over a date range; see `raw/discord/README.md` for the file list.

**File naming convention:** `server-<channel-name>-<YYYY-MM-DD>--<YYYY-MM-DD>.txt`
- `server` = Discord server name (e.g. `rumbledethumps`)
- `channel-name` = channel name without the `#` (e.g. `chat`)
- First date = earliest message, second date = last message.
- Subsequent exports start from the day after the previous file's last date (incremental).

**When ingesting a Discord export:**

1. Skim the full file for recurring topics, named contributors, and technical threads.
2. Ignore off-topic chat, greetings, image-only posts, and link-dump messages with no discussion.
3. Focus on: bug reports, workarounds, hardware tips, firmware quirks, roadmap hints, and anything `rumbledethumps` (the author) says about design decisions.
4. Create or update `wiki/sources/<server-name>-discord.md` (e.g. `rumbledethumps-discord.md`). One source page per Discord server — covers all channels from that server.
5. Extract actionable facts → update relevant `wiki/entities/` and `wiki/concepts/` pages.
6. Flag anything that contradicts official docs with a `> **Conflict:**` block.
7. Cite individual messages as: `(@username, YYYY-MM-DD, #channel-name)`.
8. Follow standard housekeeping: update `wiki/index.md`, `wiki/overview.md`, `wiki/log.md`, and `PROGRESS.md`.
9. Update `raw/discord/README.md` if a new file was added (add a row to the file table).

**Incremental exports:** When the user adds a follow-up export (same channel, later dates), ingest only the new messages and update existing source/entity/concept pages in place. Do not duplicate content.

---

## Ingest workflow

When the user adds a source to `raw/` and asks you to ingest it:

0. **Check `wiki/inbox/` for a pre-existing ingestion plan** (e.g. `*-ingest-plan.md`) matching the source. If one exists, read it and follow its chapter list and suggested order instead of reading the whole source. As each chapter is completed, mark it with `[x]` in the plan. Once **all** planned chapters are ingested, **delete the plan file** from `wiki/inbox/` — it is superseded by the `wiki/sources/` page and `wiki/log.md` entries.
1. Read the full source (or the assigned chapter/section for large PDFs — ~25 pages max per session).
2. Discuss key takeaways with the user before writing anything.
3. Create or update `wiki/sources/<short-name>.md` with a summary + key facts + frontmatter. For multi-chapter sources (books, large PDFs), include a **## Scope** section listing every chapter with its status: `[x] ingested` or `[-] skipped — <reason>`. This is the permanent record the linter uses to verify coverage.
4. Extract named things → create or update pages in `wiki/entities/`.
5. Extract mechanisms and ideas → create or update pages in `wiki/concepts/`.
6. Revise `wiki/overview.md` to reflect any new synthesis.
7. Update `wiki/index.md` with new pages and one-line descriptions.
8. Append to `wiki/log.md`: `## [YYYY-MM-DD] ingest | <source name> | <what changed>`.
9. If the new source contradicts an existing page, flag with a `> **Conflict:**` block citing both sources.
10. Update `PROGRESS.md`: flip the ingested source from `👉` → `✅` (with a brief result note), promote the next `⬜` item to `👉`, and update the **Current wiki size** table.
11. Update `CLAUDE.md` if the ingest introduces new source categories, raw-folder conventions, domain vocabulary, or workflow changes that future sessions need to know about.

A single source may touch 10–15 wiki pages. That is normal.

---

## Query workflow

When the user asks a question:

1. Read `wiki/index.md` first to identify relevant pages.
2. Drill into those pages; follow `[[wikilinks]]`.
3. Answer with citations — wiki page names and raw source references.
4. If the answer is not in the wiki, say so clearly.
5. If the answer is non-trivial, offer to file it to `wiki/syntheses/<short-name>.md`.

Good answers filed back into the wiki compound over time.

---

## Lint workflow

When the user asks for a lint or health check, scan the entire wiki for:

1. **Contradictions** — pages with directly conflicting claims. Rank the likely-correct claim by: source recency, source authority (official docs > repo > community chat), number of supporting observations.
2. **Orphans** — pages with no inbound `[[wikilinks]]`. Link them from a relevant hub page or move to `wiki/inbox/`.
3. **Data gaps** — concepts or OS calls mentioned in passing but lacking their own page.
4. **Missing cross-references** — pages that mention related entities/concepts without linking to them.
5. **Incomplete ingestion** — for each `wiki/sources/` page that has a `## Scope` section, check whether all `[x] ingested` chapters have corresponding wiki pages covering their key topics. Flag any chapter marked `[x]` with no evident wiki coverage.

Report findings as a numbered list with suggested fixes. Optionally use web search to fill data gaps and propose new questions to investigate.

---

## Citation format

- Raw source file: `([hardware.html](../raw/web/picocomputer.github.io/hardware.html.md))`
- Wiki page: `[[ria-protocol]]`
- Discord message: `(@username, YYYY-MM-DD, #channel-name)`
- Source authority: official docs > repo source > YouTube > Discord.

---

## Domain vocabulary

Always use these spellings exactly:

`RP6502`, `RP6502-RIA`, `RP6502-RIA-W`, `RP6502-VGA`, `RP6502-OS`, `RIA`, `PHI2`, `PIX bus`,
`65C02`, `W65C02S`, `cc65`, `llvm-mos`, `RP2040`, `RP2350`, `Pi Pico 2`, `PIO`, `VGA`, `VSYNC`, `HSYNC`

---

## What this wiki covers

- **Hardware:** RP6502 board, RIA firmware (RP2040), VGA firmware (RP2350/Pi Pico 2), PIX bus.
- **Software:** 65C02 assembly, cc65 C toolchain, llvm-mos, RP6502-OS API.
- **Community:** Discord tips, known bugs, workarounds, recommended resources.

Out of scope: general Pico/RP2040 topics not specific to RP6502 (covered better by upstream docs).

---

## Source priority

When facts conflict, trust sources in this order:

1. Official Picocomputer docs (`picocomputer.github.io`)
2. `picocomputer/rp6502` source and release notes
3. YouTube (official channel)
4. Discord community chat
