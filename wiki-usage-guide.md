# How to Use `rp6502-kb`: From Simple Questions to Vibe Coding

A practical guide to getting value out of this wiki at every level of engagement —
from a quick hardware question to a full coding agent session on the Picocomputer.

---

## The Core Idea

This repo is a **compiled knowledge base**, not a search index. Claude reads raw sources
once, synthesises them into interconnected wiki pages, and those pages compound over time.
Every new source, question answered, or lint pass makes the entire base more useful.
Unlike RAG, which re-derives answers from raw chunks every time, the wiki is a standing
artifact that grows.

Three layers:

| Layer | Owned by | Role |
|---|---|---|
| `raw/` | You | Immutable source documents |
| `wiki/` | Claude | Compiled, linked, citeable knowledge |
| `CLAUDE.md` | You | Schema that governs how Claude maintains the wiki |

---

## Use Case 1 — Simple Question and Answer

**Scenario:** You're reading a datasheet, a Discord thread confuses you, or you just
forgot what the PIX bus clock rate is.

**Workflow:**

1. Open this repo in Claude Code.
2. Ask the question in plain English.

```
What registers does a 65C02 program write to in order to make an OS call?
```

Claude follows the **query workflow** defined in `CLAUDE.md`:

1. Reads `wiki/index.md` to find relevant pages.
2. Drills into `wiki/concepts/api-opcodes.md`, `wiki/concepts/ria-registers.md`, etc.
3. Answers with citations — wiki page names and raw source references.
4. Offers to file a non-trivial answer as a `wiki/syntheses/` page so it doesn't
   disappear into chat history.

**What makes this better than asking Claude without the wiki:**

- Answers are grounded in *your* curated sources, not general training data.
- Citations point to specific raw files and wiki pages you can verify.
- The 65C02/RP6502 vocabulary and domain conventions are pre-loaded — no need to
  paste hardware manuals into every session.

---

## Use Case 2 — Obsidian as a Browsable Vault

**Scenario:** You want to navigate the wiki as a human-readable graph, not just query it
via chat.

**Setup:**

```
Obsidian → Manage Vaults → Open folder as vault → select rp6502-kb/
```

**What you get:**

- **Graph view** — see how entity pages (`rp6502-ria`, `w65c02s`, `pix-bus`) connect
  to concept pages (`ria-registers`, `memory-map`, `pio-architecture`).
- **Backlink panel** — every page shows what links to it; orphans are immediately
  visible.
- **`[[wikilinks]]`** render as clickable links — the same links Claude creates are
  natively navigable in Obsidian.
- **Frontmatter** (`type:`, `tags:`, `related:`, `sources:`) renders in Obsidian's
  properties panel — filter by type or tag without any plugin.
- **Search** — Obsidian full-text search across all wiki pages and raw `.md` files.

**Recommended Obsidian plugins for this workflow:**

| Plugin | Value |
|---|---|
| Dataview | Query pages by frontmatter (`type: entity`, `tags contains rp6502`) |
| Templater | Stamp new pages with the correct YAML frontmatter skeleton |
| Omnisearch | Fuzzy full-text search across the entire vault |
| Graph Analysis | Weighted graph; surface under-linked concepts |

**Workflow tip:** Use Obsidian for *reading and navigating*; use Claude Code for
*writing and updating*. Don't edit wiki pages by hand — let Claude maintain them so
cross-references stay consistent.

---

## Use Case 3 — Vibe Coding on the Picocomputer

**Scenario:** You want to write a 65C02 program for the RP6502. You describe what you
want in natural language and the coding agent produces assembly or C — but it needs to
know the OS API, the ABI, the memory map, and the toolchain conventions without you
pasting documentation every time.

### 3a — Claude Code with the wiki as live context

Your **game or firmware repo** and **rp6502-kb** are usually two different folders (two
git roots). The agent only “sees” files that are in the **current workspace**. Pick one
of these patterns:

**A — Multi-root workspace (clearest “same window” meaning)**  
In Cursor / VS Code: **File → Add Folder to Workspace…** and add both directories, e.g.

- `~/CProjects/my-picocomputer-game`
- `~/CProjects/rp6502-kb`

Then **File → Save Workspace As…** → e.g. `my-picocomputer-game.code-workspace`. Open
that workspace when you work. Both trees appear in the sidebar; Claude Code can read
`rp6502-kb/wiki/…` and your code without copying anything.

**B — Single-folder workspace**  
If you only open `my-picocomputer-game`, the wiki is **not** on the path unless you
bring it in — use **§3b** (symlink or copy under your project) or occasionally `@`-reference
files by absolute path if your tools allow reading outside the workspace.

**C — Wiki-only session**  
Open `rp6502-kb` when maintaining the knowledge base; open your app repo when shipping
code. When coding, paste links or use **§3b** so your project’s `CLAUDE.md` still points
at stable wiki paths.

In setups **A** or **C** with `rp6502-kb` available, Claude reads `rp6502-kb/CLAUDE.md`
when that folder is in context and can follow rules for `wiki/`. Your **app** repo
should still have its **own** `CLAUDE.md` (build steps, your conventions); see **§3b**
to wire in “where RP6502 facts live.”

When `rp6502-kb` is on the path (multi-root **A**, or symlink/copy **§3b**), the agent
can consult pages such as:

- OS-call entry points — `rp6502-kb/wiki/concepts/api-opcodes.md` (paths relative to workspace root)
- Memory map — `rp6502-kb/wiki/concepts/memory-map.md`
- cc65 / llvm-mos ABI — `rp6502-kb/wiki/concepts/rp6502-abi.md`
- Known bugs — `rp6502-kb/wiki/topics/known-issues.md`

Example session:

```
Write a cc65 C function that opens a file, reads 512 bytes into a buffer at $0300,
and closes it. Follow RP6502-OS conventions.
```

Claude answers without hallucinating register addresses because those addresses live in
`rp6502-kb/wiki/concepts/ria-registers.md`, grounded in the official OS docs in
`rp6502-kb/raw/`.

### 3b — Reference the wiki from a repo that is *not* multi-root

If you prefer to open **only** your app folder (no second root), **embed a pointer** to
the wiki so paths are stable and searchable:

Copy or symlink the `rp6502-kb/wiki/` tree into your Picocomputer project:

```
my-picocomputer-project/
  CLAUDE.md          ← your project's own file
  src/
  ...
  .context/
    rp6502-wiki/     ← symlink or copy of rp6502-kb/wiki/
```

Add a line to your project's `CLAUDE.md`:

```markdown
## Domain knowledge
RP6502 API reference is in `.context/rp6502-wiki/`. When writing code that touches
OS calls, hardware registers, or the cc65 ABI, consult those pages first.
```

Now any coding session in your project automatically has the RP6502 reference loaded.
The wiki acts as a **project-level context file** — not your code, not your
documentation, but the *background knowledge* the agent needs to write correct code.

### 3c — Session-start hook (automatic context injection)

Using Claude Code hooks (configured in `.claude/settings.json` — project-scoped — or
`~/.claude/settings.json` for all projects):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cat wiki/overview.md wiki/index.md"
          }
        ]
      }
    ]
  }
}
```

The hook runs from the project root (the folder containing `.claude/`), so paths are
relative to that root. If `rp6502-kb` is a second workspace folder, use its absolute
path instead.

Every new coding session injects `overview.md` (the living synthesis of everything the
wiki knows) and `index.md` (the page catalog) into the context automatically. The agent
is oriented before you type a single message.

### 3d — Slash commands for in-session queries

`.claude/commands/` is empty in this repo today — these are commands you can define
(drop a markdown file per command into `.claude/commands/`; the filename becomes the
slash-command name). Suggested starter set:

| Command | What it does |
|---|---|
| `/wiki-query <question>` | Search the wiki for an answer; file to `syntheses/` if non-trivial |
| `/wiki-ingest <file>` | Ingest a new raw source into the wiki mid-session |
| `/wiki-lint` | Run a health check for orphans, contradictions, data gaps |

Once defined, you can ask mid-task:

```
/wiki-query what are the XRAM addressing rules for buffers above $8000
```

without breaking your flow or pasting documentation.

---

## Use Case 4 — Multi-Session Project Memory

**Scenario:** You work on the Picocomputer across multiple days. Each new Claude Code
session starts cold and knows nothing about yesterday's discoveries.

The wiki solves this. Instead of pasting context at the start of every session, the
wiki **persists** what you've learned:

- Bugs you hit → `wiki/topics/known-issues.md`
- Undocumented behaviors you discovered → filed in `wiki/syntheses/`
- Architecture decisions → added to `wiki/overview.md`
- Discord tips → extracted during Discord ingest, linked from entity pages

**At the end of each discovery session**, ask Claude to crystallize:

```
Summarise what we discovered about VIA timer interrupts today and file it
in the wiki in the right place.
```

The wiki accumulates. Six months later, you open a new session and the agent already
knows the interrupt behavior — you discovered it once, you never re-explain it.

---

## Use Case 5 — Deep research (one chat, three beats)

**Idea:** You have a narrow technical question. In **one** Claude Code session you ask the
model to (1) state what it is trying to prove, (2) read **official → code → community**
in that order, (3) write one synthesis page under `wiki/syntheses/` and update
`wiki/index.md` + `wiki/log.md` per `CLAUDE.md`.

**Concrete example — question:** *“How does RP6502-OS expose file I/O to a cc65 C program?”*

**Concrete example — prompt** (paste as one message; use `@` to attach files if needed):

```text
Question: How does RP6502-OS expose file I/O to a cc65 C program?

Follow CLAUDE.md for frontmatter and citations.

1) One sentence: what exact claim are we checking?

2) Read and take short notes only:
   - Official: raw/web/picocomputer.github.io/RP6502-OS — Picocomputer  documentation.md
   - Code: raw/github/picocomputer/rp6502/ (headers or .c that implement the file API), if present
   - Community: wiki/topics/known-issues.md and raw/discord/ only if they mention file I/O bugs

3) Write wiki/syntheses/os-file-io-cc65.md reconciling (2). If official vs code disagree, say so and cite paths.
   Update wiki/index.md and wiki/log.md.
```

**What you get:** one durable answer in `wiki/syntheses/`, grounded in `raw/`, instead of
chat-only text that disappears.

Swap the question and file paths for any other topic (VGA timing, RIA registers, etc.):
always the same **claim → layered sources → one synthesis file** rhythm.

---

## Use Case 6 — Lint and Knowledge Maintenance

**Scenario:** After several ingest sessions, the wiki has 30–50 pages. Things drift:
a page gets orphaned, two pages contradict each other on a register address, a concept
is mentioned but never given its own page.

Run the lint workflow:

```
Run a full wiki health check.
```

Claude scans for:

1. **Contradictions** — conflicting register addresses, incompatible OS call signatures.
   Ranks the likely-correct claim by source authority (official docs > repo > Discord).
2. **Orphans** — pages with no inbound `[[wikilinks]]`. Links them from a hub page or
   moves them to `wiki/inbox/`.
3. **Data gaps** — OS calls or hardware signals mentioned in passing but lacking their
   own concept page.
4. **Missing cross-references** — `rp6502-ria.md` mentions PIX bus but doesn't link
   to `[[pix-bus]]`.

**Combine with web search** during lint to fill gaps:

```
I found a gap: there's no page on the RP6502-VGA colour palette modes. Search the
web and the raw/ files and create one.
```

---

## Use Case 7 — Publishing and Sharing

The wiki is plain markdown with YAML frontmatter — it can be published without any
transformation:

| Target | How |
|---|---|
| **GitHub Pages** | Push `wiki/` as a Jekyll or MkDocs site |
| **Obsidian Publish** | One-click from your vault |
| **Docusaurus** | Drop the `wiki/` folder in `docs/`; frontmatter maps cleanly |
| **Static HTML** | `pandoc` can convert the entire folder |

Because every page has `sources:` frontmatter and inline citations, the published wiki
is a **citable reference**, not just notes.

---

## Recommended Starting Workflow

```
Day 1
  → Ask a few questions; get a feel for what the wiki already knows
  → Identify one gap and ask Claude to fill it from raw/

Day 2–5
  → Open Obsidian; explore the graph
  → Start a small coding project; point CLAUDE.md at the wiki
  → Notice what the coding agent gets wrong; file the correction as a new wiki page

Week 2+
  → Run lint; fix orphans and contradictions
  → Add one new raw source (a PDF chapter, a Discord export, a release notes page)
  → Ask the hardest question you have about the OS API; file the synthesis
```

The compounding effect kicks in around 30–40 pages. By then the wiki knows more
RP6502-specific context than you can hold in your head, and the coding agent stops
making the class of mistakes that come from not knowing the platform.

---

## The rp6502-kb Advantage for Picocomputer Coding

Most coding agents hallucinate RP6502 details because the platform is niche, the docs
are sparse, and the community knowledge lives in Discord threads that were never
indexed. This wiki fixes all three:

- **Niche platform** — the wiki is domain-specific; every page is RP6502.
- **Sparse docs** — the wiki synthesises across docs + repo + Discord; it knows things
  no single source says.
- **Community knowledge** — Discord tips and workarounds are ingested and cross-linked
  to the hardware entities they affect.

When you vibe code on the Picocomputer with this wiki loaded, the agent is not
guessing. It's citing.

---

## Sources

- [Karpathy's original LLM wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [VentureBeat: Karpathy shares LLM Knowledge Base architecture](https://venturebeat.com/data/karpathy-shares-llm-knowledge-base-architecture-that-bypasses-rag-with-an)
- [MindStudio: What Is Karpathy's LLM Wiki?](https://www.mindstudio.ai/blog/andrej-karpathy-llm-wiki-knowledge-base-claude-code)
- [MindStudio: LLM Wiki Pattern](https://www.mindstudio.ai/blog/karpathy-llm-wiki-pattern-personal-knowledge-base-without-rag)
- [MindStudio: LLM Wiki vs RAG for Internal Codebase Memory](https://www.mindstudio.ai/blog/llm-wiki-vs-rag-internal-codebase-memory)
- [AgriciDaniel/claude-obsidian — Claude Code + Obsidian integration](https://github.com/AgriciDaniel/claude-obsidian)
- [ekadetov/llm-wiki — Claude Code plugin for Obsidian vaults](https://github.com/ekadetov/llm-wiki)
- [nvk/llm-wiki — Multi-agent research and artifact generation](https://github.com/nvk/llm-wiki)
- [rohitg00: LLM Wiki v2 — agent memory extensions](https://gist.github.com/rohitg00/2067ab416f7bbe447c1977edaaa681e2)
- [SamurAIGPT/llm-wiki-agent](https://github.com/SamurAIGPT/llm-wiki-agent)
- [ussumant/llm-wiki-compiler](https://github.com/ussumant/llm-wiki-compiler)
- [zerowing113/llm-knowledge-base-template](https://github.com/zerowing113/llm-knowledge-base-template)
- [MIT Technology Review: From vibe coding to context engineering](https://www.technologyreview.com/2025/11/05/1127477/from-vibe-coding-to-context-engineering-2025-in-software-development/)
- [LLM Wiki Revolution — Analytics Vidhya](https://www.analyticsvidhya.com/blog/2026/04/llm-wiki-by-andrej-karpathy/)
- [Balu Kosuri: I used Karpathy's LLM Wiki (Medium)](https://medium.com/@k.balu124/i-used-karpathys-llm-wiki-to-build-a-knowledge-base-that-maintains-itself-with-ai-df968e4f5ea0)
