# Research: sourcing `rp6502-kb` for an LLM-maintained wiki

This note compares ways to populate **`raw/`** (immutable sources) and **`wiki/`** (LLM-compiled markdown), following the pattern in [`llm-wiki.md`](llm-wiki.md). It also relates the existing **PinRAG** project at `/Users/nenaddjordjevic/PythonProjects/pinrag`, which already knows how to load PDFs, Discord exports, web docs, GitHub trees, and YouTube.

**Official Picocomputer docs:** [picocomputer.github.io](https://picocomputer.github.io/) (Sphinx-generated static site with **flat URLs**: [`index.html`](https://picocomputer.github.io/index.html), [`hardware.html`](https://picocomputer.github.io/hardware.html), [`ria.html`](https://picocomputer.github.io/ria.html), [`ria_w.html`](https://picocomputer.github.io/ria_w.html), [`vga.html`](https://picocomputer.github.io/vga.html), [`os.html`](https://picocomputer.github.io/os.html)) — **six** top-level pages, not hundreds.

**Official source:** [github.com/picocomputer/rp6502](https://github.com/picocomputer/rp6502) — **single monorepo** containing RP6502-RIA, RP6502-RIA-W (wireless), and RP6502-VGA firmware. BSD-3-Clause, ~99% C, source in `src/`. Not three separate repos.

---

## How this fits the three-layer model

| Layer | Role for this project |
| --- | --- |
| **Raw sources** | PDFs, mirrored/clipped docs, repo snapshots or exports, transcripts, Discord `.txt` exports — **never edited by the LLM** after ingest. |
| **Wiki** | Summaries, concept pages, hardware/OS API notes, cross-links — **LLM-owned**, updated when new raw material arrives. |
| **Schema** | `CLAUDE.md` / `AGENTS.md`: folder layout, naming, ingest checklist, how to cite `raw/` paths vs wiki pages. |

**PinRAG vs LLM wiki:** PinRAG optimizes **chunk retrieval + Q&A** over embeddings. The LLM wiki optimizes **persistent structure and compounding synthesis**. They solve different problems and compose well:

- **Wiki-only:** everything lands in `raw/` as files; one agent maintains `wiki/` (Karpathy-style). Good starting point.
- **Parallel:** same files in `raw/`; PinRAG indexes them for fast semantic search; the wiki agent compiles durable pages. PinRAG does not replace `index.md` / cross-links — it accelerates retrieval within them.
- **PinRAG-first export:** use PinRAG loaders to **materialize** markdown/text under `raw/docs-mirror/` once, then treat those files as immutable sources for the wiki agent. Avoids hand-clipping hundreds of pages.

**Recommended starting point:** wiki-only, pure markdown. Add PinRAG search later when the wiki exceeds ~200 pages and raw `index.md` lookups feel slow.

---

## Ingest order (priority ladder)

Not all sources are equal. Start where the signal-to-noise ratio is highest:

1. **Official Picocomputer web docs** — authoritative, clean, text-heavy. Highest ROI per page. Six top-level pages, so this is a one-session task.
2. **`picocomputer/rp6502` repo** — README + `src/` tree (especially any `.h` headers and the API source files). The canonical API surface. Ingest early to ground the wiki's technical vocabulary.
3. **PDF references** — dense but slow to ingest chapter by chapter. Start with the **RP2350** datasheet (PIO, DMA, clocks, GPIO — all RP6502 firmware targets use **Raspberry Pi Pico 2** class boards) and a 65C02 programming reference. Defer full textbooks until the wiki skeleton exists.
4. **YouTube videos** — useful for context and build walkthroughs, but captions are noisy. Treat as supplementary after core docs are in.
5. **Discord exports** — highest noise, highest tribal knowledge density. Ingest last, after the wiki has entity pages to attach findings to.

**Rule of thumb:** the first two items alone (web docs + repo) will give you a usable wiki in one afternoon. Everything else is depth on top of that skeleton.

---

## 1. PDF books (Raspberry Pi Pico 2 / RP2350, 6502/65C02, cc65/llvm-mos)

**Recommendation:** Copy PDFs into `raw/pdfs/` with a **stable filename** (`author-year-short-title.pdf`). Keep a one-line `raw/pdfs/README.md` listing license / source URL.

| Approach | Pros | Cons |
| --- | --- | --- |
| **Files in `raw/pdfs/`** | Matches `llm-wiki.md` exactly; trivial provenance; works offline. | Large PDFs burn context if read whole; ingest must be chapter-scoped in the schema. |
| **PinRAG `index_pdf`** | Good chunk boundaries for Q&A; already implemented. | Stores vectors in Chroma, not automatically your wiki. Still use PDFs in `raw/` as truth. |

**Practical ingest protocol:**

- Ingest **one chapter or ~25 pages per session** — never "read entire book at once." After each chunk the agent updates relevant entity pages (opcodes, registers, memory maps, PIO state machines, etc.) and appends to `log.md`.
- Seed the wiki with an `entities/` directory for the major 6502 and **RP2350** concepts *before* ingesting the first PDF — it gives the agent clear filing targets.
- For the **RP2350 datasheet**: prioritize chapters on PIO, DMA, clocks, and GPIO over the full chip reference. **RP6502-RIA** runs on **Raspberry Pi Pico 2**, **RP6502-RIA-W** on **Pico 2 W** (same silicon family, wireless added), and **RP6502-VGA** on Pico 2 — all are RP2350. RIA firmware uses PIO heavily to bit-bang the 65C02 bus (PHI2, R/W, address decode); VGA firmware uses PIO for pixel output — those chapters are foundational for every variant.
- For **65C02 references**: the opcode table, addressing modes, and stack/interrupt behavior are the highest-value pages. File them into `concepts/6502-instruction-set.md`.
- Optional: keep the **RP2040** datasheet at **low** priority only for Pico 1 / older community write-ups that still reference it; it is **not** the primary chip for current RP6502 builds.

**Suggested PDFs to start with:**

| File | Priority | Notes |
| --- | --- | --- |
| `rp2350-datasheet.pdf` | High | **All** firmware targets (RIA on Pico 2, RIA-W on Pico 2 W, VGA on Pico 2). Focus: PIO, DMA, clocks, GPIO |
| `rp2040-datasheet.pdf` | Low | Pico 1 / legacy tutorials only; not the primary reference for current RP6502 boards |
| `w65c02s-datasheet.pdf` | High | Core CPU reference (WDC 65C02) |
| `cc65-users-guide.pdf` | Medium | Toolchain docs are sparse online |
| `llvm-mos-reference.pdf` | Low/later | Only if you use llvm-mos over cc65 |

---

## 2. Web documentation ([picocomputer.github.io](https://picocomputer.github.io/))

The site is Sphinx-generated, hosted on GitHub Pages — static HTML, crawler-friendly, no JavaScript rendering required. **Critically: the doc set is small.** There are **six** top-level doc pages — the same six already mirrored under `raw/web/picocomputer.github.io/`:

1. **Picocomputer 6502** (site index / overview)  
2. **Hardware**  
3. **RP6502-RIA**  
4. **RP6502-RIA-W** (wireless / Pico 2 W)  
5. **RP6502-VGA**  
6. **RP6502-OS**  

Each is a few screens long. This keeps ingestion tractable without a crawler: a manual clip of all six pages is still a single short session.

### Option A — Obsidian Web Clipper (manual / semi-manual) — RECOMMENDED

| Pros | Cons |
| --- | --- |
| High-quality markdown for **individual** articles; you curate what matters. | Does not scale to entire Sphinx sites without repetitive work; easy to miss pages. |
| Respects your judgment (skip boilerplate). | Hard to re-sync when docs change unless you repeat work. |

**Best for:** the entire Picocomputer doc site, actually. Six pages is tractable manually and gives you clean extraction every time. Reserve a crawler for when you expand into upstream sources (Raspberry Pi docs, cc65 online manual, etc.) that are much larger.

### Option B — CLI crawl / export (PinRAG-style or dedicated mirror script)

PinRAG's `web_loader` is designed around scoped discovery (`llms.txt` / `llms-full.txt`, `sitemap.xml`, then bounded BFS) and main-text extraction (trafilatura + markdownify), with host + path prefix limits.

**Seed URL:** `https://picocomputer.github.io/` — BFS bounded to `picocomputer.github.io`. The sitemap at `/sitemap.xml` (if present) or the nav tree is the fastest way to enumerate all pages.

| Pros | Cons |
| --- | --- |
| **Reproducible** snapshot; one markdown file per URL under `raw/web/`. | Needs polite rate limits; Sphinx nav chrome can be noisy — verify extractor output quality on a few pages first. |
| Easy to re-run when docs update. | JS-heavy sites are out of scope for a pure-Python crawler — not an issue here. |

**Best for:** baseline full-site capture into `raw/web/picocomputer.github.io/...`, then wiki ingest in batches by section (Hardware → RIA → RIA-W → VGA → OS).

**Implementation paths (choose one):**

1. **Small script in `rp6502-kb`** calling PinRAG's loader logic but **writing** `.md` files to `raw/web/` instead of pushing to Chroma.
2. **One-off export** from PinRAG: run crawl, serialize documents to disk, copy tree into `rp6502-kb/raw/web/`.

Check `robots.txt` at `picocomputer.github.io/robots.txt` before crawling; GitHub Pages sites generally allow indexing.

### Option C — AI web search to fill `raw/` or `wiki/`

| Pros | Cons |
| --- | --- |
| Fast for **spot** answers ("what is PHI2 on RP6502?"). | Not a faithful mirror; models may omit, merge, or hallucinate vs. official docs. |
| Good for **lint** steps: filling gaps, finding related links. | Poor as sole ingestion for a hardware/OS reference where accuracy matters. |

**Best for:** supplementary passes **after** official text is in `raw/`, not as primary archive.

### Suggested combo

Because the Picocomputer doc site is so small, the combo inverts what you'd do for a large site:

1. **Primary:** Option A — clip all six pages by hand into `raw/web/picocomputer.github.io/`. One session (or keep the mirror in sync with that folder layout).
2. **Ongoing:** Re-clip individual pages after upstream doc releases.
3. **Expansion:** Option B (crawler) only when you add larger external sources — cc65 manual, Raspberry Pi Pico docs, 6502.org, etc.
4. **Maintenance:** Option C during wiki **lint** to find new upstream pages or fill gaps.

### Wiki ingest order for Picocomputer docs

Ingest in this order — each page grounds the next (matches the six clipped files in `raw/web/picocomputer.github.io/`):

1. **Picocomputer 6502** (`index`) — project scope, mental model  
2. **Hardware** — board pinout, signals, PHI2, IRQ wiring  
3. **RP6502-RIA** — the core firmware interface (most critical)  
4. **RP6502-RIA-W** — wireless stack on top of RIA (Pico 2 W)  
5. **RP6502-VGA** — VGA output + PIX bus protocol  
6. **RP6502-OS** — kernel API

---

## 3. GitHub repositories (picocomputer org and related)

**Reality check:** `picocomputer/rp6502` is a **single monorepo**, not split into SDK/VGA/RIA repos. All three firmware variants (RIA, RIA-W, VGA) share one `src/` tree. The repo is ~99% C, BSD-3-Clause.

**Target repos (start with these):**

| Repo | What to capture | Priority |
| --- | --- | --- |
| [`picocomputer/rp6502`](https://github.com/picocomputer/rp6502) | `README.md`, `src/` headers and API-surface `.c` files, build docs | High |
| [`picocomputer/vscode-cc65`](https://github.com/picocomputer) | README, `package.json` task definitions | Medium |
| [`picocomputer/vscode-llvm-mos`](https://github.com/picocomputer) | README, `package.json` task definitions | Low |
| `cc65/cc65` (upstream) | `doc/` and 6502 platform docs only | Low — very large repo |
| `llvm-mos/llvm-mos-sdk` | README, platform docs | Low — only if you use it |

**Firmware releases:** [github.com/picocomputer/rp6502/releases](https://github.com/picocomputer/rp6502/releases) ships `.uf2` files for the Pi Pico / Pico 2. The release notes themselves are a valuable source — they document behavioral changes and new OS calls. Ingest each release's notes into `wiki/sources/release-<version>.md`.

| Approach | Pros | Cons |
| --- | --- | --- |
| **PinRAG `github_loader`** | Filtered text files by extension; API-based. | Metadata is file paths, not narrative — wiki agent must synthesize. |
| **Shallow clone + selective copy** | Simple; works offline; full git history optional. | Must choose paths manually; easy to include too much firmware noise. |
| **Release tarballs / tagged snapshots** | Reproducible "as shipped." | May miss latest `main` fixes. |

**Recommendation:**

- Shallow clone `picocomputer/rp6502` into `raw/github/picocomputer/rp6502-<sha>/` (pin the commit SHA in the folder name).
- Capture: `README.md`, `LICENSE`, everything under `src/`, release notes for recent tags. The repo has no separate `docs/` or `examples/` tree — the source itself is the documentation.
- In schema: "for `src/` files, prefer `.h` headers and top-level `.c` files over low-level firmware internals; ingest any file whose header comment block describes an API."
- Because the repo is C-heavy and doesn't follow a "docs/" convention, you'll need to actually read some source. Headers that expose OS calls and register maps are the highest-value files — these define the API surface a 6502 program sees.

### Updating the repo snapshot

**When to update:** After each new GitHub release. The release notes page is the trigger signal — when a new tag appears, update both the repo snapshot and the release notes folder together.

**How to update:**

```bash
# 1. Advance the shallow clone to the new commit
cd raw/github/picocomputer/rp6502
git fetch --depth=1
git checkout <new-commit-sha>

# 2. Fetch the new release notes file
cd raw/github/picocomputer/rp6502/releases
gh release view v0.24 --repo picocomputer/rp6502 > v0.24.md

# 3. Update raw/README.md with the new commit SHA and date
```

**What to ingest after an update:**

A point release typically needs only a partial re-ingest — not the whole repo. The release notes file is the guide:

1. **Always ingest the new release notes file** — it's the changelog and documents every behavioral change.
2. **Re-read specific source files only if the release notes mention** new API op-codes, new registers, new PIO programs, new GPIO assignments, or renamed/removed calls. Use the release notes as the filter.
3. **Skip unchanged source files** — the existing wiki pages remain valid. Only update a wiki page if the source it's based on actually changed.

**Release cadence:** The project has averaged roughly one release every 1–3 months (v0.1 in 2023 through v0.23 in early 2026). This is infrequent enough that updates are a deliberate session, not an automated concern.

---

## 4. YouTube (~20 build / topic videos)

**Recommended pipeline:** `yt-dlp` subtitles → `.md` transcript files → wiki ingest.

| Approach | Pros | Cons |
| --- | --- | --- |
| **Automated captions** (`yt-dlp --write-auto-sub`) → `.vtt`/`.srt` → `.md` | Scales to dozens of videos; timestamps preserved for citations. | Auto-captions for technical retro/hardware content are particularly error-prone: chip names, register numbers, model numbers get mangled. |
| **PinRAG YouTube pipeline** | Centralized indexing; optional vision paths for diagrams. | Same caption quality limits. |
| **Manual transcript** | Highest accuracy for one critical video. | Poor ROI × 20. |

**A practical note on caption quality for this domain:** words like "RIA," "PHI2," "65C02," "cc65," "GPIO," and chip model numbers are routinely garbled. The video title, description, and chapter markers are often *more reliable* than captions for understanding what a video covers — always capture these.

**Practical workflow:**

1. Create `raw/youtube/VIDEO_INDEX.md`: one row per video — title, channel, date, URL, video ID, one-line human summary (you write this; it's 10 words per video). This is the LLM's entry point for the source set.
2. Batch-download subtitles: `yt-dlp --write-auto-sub --sub-format vtt --skip-download -o "raw/youtube/%(id)s-%(title)s.%(ext)s" <URL>`.
3. Convert `.vtt` to `.md` (strip timestamps for prose, keep them for citations in a second pass).
4. In wiki ingest, tag pages with `source_type: youtube` and `video_id` frontmatter.
5. For **high-signal** videos (e.g., official bring-up, hardware deep-dives), spot-fix transcript in `raw/` and add an `errata:` note in the wiki page — keeps corrections out of the immutable raw file while documenting the correction.

---

## 5. Discord channel export (DiscordChatExporter-style `.txt`)

The sample in this repo — `Retro Tinkering - amiga - alicia-1200-pcb [1404852770154217664].txt` — matches the format PinRAG's `discord_loader` expects (guild/channel header, `[date] user` lines, `{Reactions}`, `{Attachments}`, `{Embed}` blocks). **Note: this file is about an Amiga PCB project, not RP6502** — it's a format reference only, not an RP6502 source. The actual Discord exports you'll want for this wiki are from the Picocomputer / RP6502-related channels.

| Pros | Cons |
| --- | --- |
| Rich **tribal knowledge**: bugs, workarounds, BOM hints, community links. | Noisy threads, jokes, off-topic; high token count per channel. |
| PinRAG can chunk with windowing for RAG. | For wiki synthesis, the agent should **summarize threads** into concepts, not paste chat verbatim. |

**Recommendation:**

- Store exports under `raw/discord/<guild-slug>/<channel-slug>_<channel-id>.txt`.
- In schema: "Discord is **secondary** evidence; prefer official docs/repo for facts; use chat for **tips, warnings, community consensus** and always link back to message timestamp + author in wiki notes if cited."
- **Expiring CDN URLs** are a real problem: Discord attachment URLs (`cdn.discordapp.com/attachments/...`) expire. Either download the images at export time (before URLs rot) or note in wiki that attachment links may be dead and strip them from ingested text to avoid noise.
- Discord is the best place to find **undocumented behaviors**, known bugs, and workarounds — the wiki agent should be specifically prompted to extract these into a `topics/known-issues.md` or similar page during Discord ingest.

---

## 6. `raw/` directory layout

```
rp6502-kb/
  raw/
    README.md                         # immutability rule, provenance policy
    pdfs/
      rp2350-datasheet.pdf
      65c02-programming-reference.pdf
      ...
    web/
      picocomputer.github.io/         # one .md per URL, mirroring path structure
    github/
      picocomputer/
        rp6502/
          main-<sha>/                 # or v1.2.3/
        rp6502-sdk/
          main-<sha>/
    youtube/
      VIDEO_INDEX.md                  # human-written, one row per video
      <video-id>-<title>.md           # auto-caption → markdown
    discord/
      picocomputer/
        general_<channel-id>.txt
        firmware-dev_<channel-id>.txt
    assets/                           # downloaded images (from web clips, Discord)
  wiki/                               # LLM-maintained (created when ingest begins)
    index.md                          # catalog of all pages, updated on every ingest
    log.md                            # append-only chronological record
    overview.md                       # living synthesis across all sources
    inbox/                            # rough notes awaiting organization
    sources/                          # one summary page per raw source
    entities/                         # named things: chip, board, register, signal
    concepts/                         # 6502 addressing, PIO state machines, VGA modes…
    syntheses/                        # filed query answers (comparisons, analyses)
    topics/                           # operational: known issues, getting-started, etc.
  .claude/
    commands/                         # custom slash commands: /wiki-ingest, /wiki-query, /wiki-lint
  llm-wiki.md
  karpathy-tweet-2039805659525644595.md
  research-llm-wiki-rp6502-sources.md
  CLAUDE.md                           # schema (add before first ingest session)
```

**Four additions over the original layout, borrowed from community implementations:**

- **`overview.md`** — a living synthesis that the agent revises on every ingest. Acts as the "home page" — a human-readable summary of everything the wiki currently knows.
- **`inbox/`** — for rough notes (quick observations, half-formed thoughts). The agent processes and files these during lint.
- **`syntheses/`** — when you ask a question and get a good answer, the agent files that answer here. Explorations compound instead of vanishing into chat history.
- **`.claude/commands/`** — custom slash commands (`/wiki-ingest`, `/wiki-query`, `/wiki-lint`) so the workflow is one keystroke instead of a long prompt each time.

---

## 7. Schema / CLAUDE.md starter

The schema is the most important file you haven't written yet. Without it, the LLM produces inconsistent output; with it, the LLM becomes a disciplined wiki maintainer. The patterns below are converged from several public implementations (see §7.5).

```markdown
# rp6502-kb schema

## Directory rules
- `raw/` is **immutable**: read-only. Never edit, delete, or create files here.
- `wiki/` is **LLM-owned**: create, update, and link pages freely.
- Always update `wiki/index.md`, `wiki/overview.md`, and `wiki/log.md` at the end of every session.

## Page frontmatter (required on every wiki page)

    ---
    type: source | entity | concept | synthesis | topic
    tags: [rp6502, ria, hardware, ...]
    related: [[page-name]], [[other-page]]
    sources: [[source-name]], [[other-source]]
    created: YYYY-MM-DD
    updated: YYYY-MM-DD
    ---

## Cross-linking: use Obsidian `[[wikilinks]]`, not markdown links
- `[[ria-protocol]]` — canonical inside the wiki
- `[source.md](../raw/web/ria.html.md)` — only when pointing at `raw/`
- Every entity or concept page must link back to at least one source page in its `sources:` frontmatter field.

## Ingest workflow (one source at a time)
1. Read the source (or the assigned chapter/section).
2. If interactive, discuss key takeaways with user before writing.
3. Create/update `wiki/sources/<short-name>.md` with summary + key facts + frontmatter.
4. Extract entities → create/update `wiki/entities/<name>.md`.
5. Extract concepts → create/update `wiki/concepts/<name>.md`.
6. Revise `wiki/overview.md` to reflect any new synthesis.
7. Update `wiki/index.md` with new pages.
8. Append to `wiki/log.md`: `## [YYYY-MM-DD] ingest | <source name>`.
9. If the new source contradicts an existing page, flag with a `> **Conflict:**` block citing both sources.

## Query workflow
1. Read `wiki/index.md` to identify relevant pages.
2. Drill into those pages; follow `[[wikilinks]]`.
3. Answer with citations (page names + source references).
4. If the answer is non-trivial, offer to file it to `wiki/syntheses/<short-name>.md`.

## Lint workflow (health check, run periodically)
Scan the entire wiki for these four issues:
1. **Contradictions** — pages that make directly conflicting claims. Rank the likely-correct claim by source recency, source authority (official > community), and number of supporting observations.
2. **Orphans** — pages with no inbound `[[wikilinks]]`. Either link them from a relevant hub page or move them to `inbox/`.
3. **Data gaps** — concepts mentioned in passing but lacking their own page; registers or OS calls referenced but never defined.
4. **Missing cross-references** — pages that mention related entities/concepts without linking to them.

Optionally: use web search to fill data gaps, and propose new questions to investigate.

## Citation format
- Raw source: `([hardware.html](../raw/web/picocomputer.github.io/hardware.html.md))`
- Wiki page: `[[ria-protocol]]`
- Discord: `(@username, YYYY-MM-DD, [[discord-summary]])`
- Prefer official docs > repo source > community chat.

## Domain vocabulary (always prefer these spellings)
RP6502, RP6502-RIA, RP6502-RIA-W, RP6502-VGA, RP6502-OS, RIA, PHI2, PIX bus,
65C02, W65C02S, cc65, llvm-mos, RP2350, Raspberry Pi Pico 2, Pico 2 W, RP2040 (legacy Pico 1 only), PIO, VGA, VSYNC, HSYNC

## What this wiki covers
- **Hardware:** RP6502 board, RIA / RIA-W / VGA firmware, **RP2350** (Pico 2 and Pico 2 W), PIX bus.
- **Software:** 65C02 assembly, cc65 C toolchain, llvm-mos, RP6502-OS API.
- **Community:** Discord tips, known bugs, workarounds, recommended resources.
```

Co-evolve the schema with the agent over time. Every `> **Conflict:**` block you manually resolve, every time you restate a convention — that's a candidate for a new schema rule.

---

## 7.5. Community implementations to borrow from

Several open-source LLM-wiki projects have shipped since Karpathy's post. Skim them before writing your `CLAUDE.md` — each encodes slightly different conventions you can steal:

| Repo | Notable pattern |
| --- | --- |
| [`SamurAIGPT/llm-wiki-agent`](https://github.com/SamurAIGPT/llm-wiki-agent) | `sources/`/`entities/`/`concepts/`/`syntheses/` layout; frontmatter spec; graph generation with Louvain community detection |
| [`kfchou/wiki-skills`](https://github.com/kfchou/wiki-skills) | Claude Code Skills-compatible; implements ingest/query/lint as skills |
| [`Astro-Han/karpathy-llm-wiki`](https://github.com/Astro-Han/karpathy-llm-wiki) | Agent Skills format; explicit citation and lint workflows |
| [`ussumant/llm-wiki-compiler`](https://github.com/ussumant/llm-wiki-compiler) | Claude Code plugin that compiles markdown into a topic-based wiki |
| [`Ar9av/obsidian-wiki`](https://github.com/Ar9av/obsidian-wiki) | Tight Obsidian integration; vault layout |
| [`Pratiyush/llm-wiki`](https://github.com/Pratiyush/llm-wiki) | Multi-agent support (Claude, Codex, Cursor, Gemini) |

**What to copy:** the frontmatter schema, the slash-command pattern, the four-point lint checklist, and the `overview.md` + `syntheses/` convention.

**What to skip (for now):** heavy graph-generation tooling. At the scale of the RP6502 domain (likely <200 pages), Obsidian's native graph view is sufficient and free.

---

## 8. Wiki page taxonomy (RP6502 domain)

Before the first ingest, stub out these pages so the agent has clear filing targets:

**Entities (named things):**
- `rp6502-board.md` — the overall board, revisions
- `rp6502-ria.md` — the RIA firmware on **Raspberry Pi Pico 2** (RP2350)
- `rp6502-ria-w.md` — RIA-W on **Pico 2 W** (RP2350 + wireless)
- `rp6502-vga.md` — the VGA firmware on **Pico 2** (RP2350)
- `rp6502-os.md` — the operating system running on the RIA
- `65c02-cpu.md` — WDC W65C02S, the actual CPU on the board
- `phi2-clock.md` — the PHI2 timing signal, generated by the RIA
- `pix-bus.md` — the 5-wire serial bus between RIA and VGA

**Concepts (ideas / mechanisms):**
- `ria-protocol.md` — how the 65C02 communicates with the RIA over the shared bus
- `pix-protocol.md` — the RIA → VGA serialization format
- `6502-instruction-set.md` — opcodes, addressing modes, cycle counts
- `pio-state-machines.md` — RP2350 PIO usage (bus emulation, pixel output); cite RP2040 docs only when comparing legacy Pico 1 examples
- `memory-map.md` — 6502 address space layout on RP6502
- `os-api.md` — the RP6502-OS kernel call surface
- `cc65-toolchain.md` — compiler, linker, libraries for the 6502
- `llvm-mos-toolchain.md` — alternative LLVM-based 6502 toolchain
- `vga-modes.md` — supported resolutions, timing parameters

**Topics (synthesized / operational):**
- `known-issues.md` — bugs and workarounds from Discord / forums / release notes
- `getting-started.md` — minimal dev environment setup (flash RIA, compile hello world, run)
- `toolchain-comparison.md` — cc65 vs llvm-mos tradeoffs
- `pinout-cheatsheet.md` — quick reference for board pinout

---

## 9. Resolved decisions (formerly "open decisions")

1. **Single machine vs split:** Start wiki-only on the same machine as Obsidian. Add PinRAG search once the wiki has >100 pages and raw index lookups feel slow. Avoid symlinks across projects — copy materialized `.md` files into `raw/` instead.

2. **Refresh policy:** Re-crawl `picocomputer.github.io` on **tagged releases only** (check the GitHub repo's releases page). Between releases, use Option A (Obsidian Web Clipper) for any specific pages that changed. Don't crawl monthly — the docs update slowly.

3. **License and redistribution:** PDFs and Discord exports are personal use only. Wiki text should **summarize and cite**, not republish verbatim. For Discord: name the author in citations (community norm), but don't publish the raw export. For PDFs: keep `raw/pdfs/` out of any public git remote.

4. **Wiki scope:** Full stack — Hardware + OS API + cc65/llvm-mos toolchain + 6502 CPU. Rationale: RP6502 is only useful as a target if you can actually program it; the toolchain docs are as important as the hardware reference. Excludes: generic Pico material not specific to RP6502 (covered better by existing resources); treat **RP2040 / Pico 1** as peripheral unless you are debugging old posts.

---

## 10. Summary table

| Source type | Preferred primary tactic | PinRAG alignment | Wiki ingest note |
| --- | --- | --- | --- |
| PDF references | Files in `raw/pdfs/`; ingest chapter-scoped | `index_pdf` for Q&A | ~25 pages/session; prioritize **RP2350** PIO/DMA/clocks chapters + 65C02 opcode table |
| Picocomputer web docs | **Manual clip** (six top-level pages) → `raw/web/` | Not worth a crawler | Ingest in order: index → hardware → ria → ria-w → vga → os |
| GitHub — `picocomputer/rp6502` | Shallow clone at pinned SHA → `raw/github/` | `github_loader` | Single monorepo; focus on `src/` headers and API-surface `.c`; ingest release notes |
| YouTube | Subtitles → `raw/youtube/`; `VIDEO_INDEX.md` | YouTube indexer optional | Captions mangle "RIA"/"PHI2"/"65C02"; capture title/description too |
| Discord | `.txt` export in `raw/discord/` | `discord_loader` patterns | Secondary source; extract `known-issues.md` during ingest |

---

## Sources (web research)

Consulted for best practices and to verify RP6502 repository structure:

- [Picocomputer documentation](https://picocomputer.github.io/) — official docs
- [github.com/picocomputer/rp6502](https://github.com/picocomputer/rp6502) — canonical monorepo
- [RP6502 releases](https://github.com/picocomputer/rp6502/releases) — `.uf2` firmware drops
- [Karpathy's original gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — the idea file
- [SamurAIGPT/llm-wiki-agent](https://github.com/SamurAIGPT/llm-wiki-agent) — folder layout, frontmatter, lint patterns
- [kfchou/wiki-skills](https://github.com/kfchou/wiki-skills) — Claude Code Skills implementation
- [Astro-Han/karpathy-llm-wiki](https://github.com/Astro-Han/karpathy-llm-wiki) — citation and lint workflows
- [ussumant/llm-wiki-compiler](https://github.com/ussumant/llm-wiki-compiler) — Claude Code plugin
- [Ar9av/obsidian-wiki](https://github.com/Ar9av/obsidian-wiki) — Obsidian integration
- [Pratiyush/llm-wiki](https://github.com/Pratiyush/llm-wiki) — multi-agent support
- [MindStudio: Karpathy LLM Wiki + Claude Code](https://www.mindstudio.ai/blog/andrej-karpathy-llm-wiki-knowledge-base-claude-code)
- [Starmorph: Complete Guide to AI-Maintained Knowledge Bases](https://blog.starmorph.com/blog/karpathy-llm-wiki-knowledge-base-guide)
- [DAIR.AI: LLM Knowledge Bases](https://academy.dair.ai/blog/llm-knowledge-bases-karpathy)
- [Sangam Pandey: The LLM Wiki Pattern](https://www.sangampandey.info/blog/llm-wiki-pattern-personal-knowledge-base)
- [DEV: What Karpathy's LLM Wiki Is Missing](https://dev.to/penfieldlabs/what-karpathys-llm-wiki-is-missing-and-how-to-fix-it-1988)

---

*This document is research and planning only — no ingestion automation was added to the repo in this step. Next action: write `CLAUDE.md` (use §7 as the starting template), stub out the `wiki/` and `raw/` directory structure, and ensure all six Picocomputer doc pages are present under `raw/web/picocomputer.github.io/` for the first ingest session.*
