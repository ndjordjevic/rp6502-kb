# picocomputer/ehbasic — Ingest Plan

**Source**: https://github.com/picocomputer/ehbasic (fetch via WebFetch)
**Priority**: MEDIUM
**Approach**: README + doc/help.rp6502 + key Assembly source files. Focus on what was changed from upstream ehBASIC to support RP6502-OS, and what extensions the BASIC interpreter exposes.

---

## Strategy

Lee Davison's Enhanced BASIC was ported to RP6502 using the cc65 toolchain. Two things are interesting for the wiki: (1) what RP6502-specific BASIC extensions exist (from `doc/help.rp6502`), and (2) how the port uses RP6502-OS system calls from Assembly — a concrete example of low-level OS API usage. The BASIC interpreter itself is not the focus; the RP6502 glue layer is.

---

## Reading order

- [ ] **README.md** — https://raw.githubusercontent.com/picocomputer/ehbasic/main/README.md
  - Note the reference manual link (Lee Davison's original docs)
  - Note cc65 dependency on picocomputer fork specifically
  - Note any RP6502-specific build or hardware requirements
  → Create `wiki/sources/ehbasic.md`

- [ ] **doc/help.rp6502** — https://raw.githubusercontent.com/picocomputer/ehbasic/main/doc/help.rp6502
  - Extract all RP6502-specific BASIC extensions (new keywords, graphics/sound/IO commands)
  - Note syntax for any VGA, audio, or filesystem BASIC commands
  - Note any BASIC commands that map to RP6502-OS API calls
  → Create `wiki/entities/ehbasic.md` with extensions reference
  → Cross-link to relevant concept pages (vga-display-modes, audio-psg, fatfs, etc.)

- [ ] **Key Assembly source files** — browse https://github.com/picocomputer/ehbasic/tree/main/src
  - Identify the RP6502-OS integration file(s) — likely handles character I/O and memory mapping
  - Read the OS call stubs: how does BASIC invoke RP6502-OS CHAR_IN / CHAR_OUT / etc.?
  - Note any custom zero-page usage or memory map decisions
  → Update `wiki/concepts/os-api.md` with BASIC integration notes

- [ ] **Releases** (2 releases) — https://github.com/picocomputer/ehbasic/releases
  - Note version history and what changed between releases
  → Add to `wiki/sources/ehbasic.md` version table

---

## Wiki pages to create or update

| Page | Action |
|------|--------|
| `wiki/sources/ehbasic.md` | Create — source summary + version history |
| `wiki/entities/ehbasic.md` | Create — BASIC extensions reference for RP6502 |
| `wiki/concepts/os-api.md` | Update — note how BASIC calls OS character I/O |
| `wiki/index.md` | Update |
| `wiki/overview.md` | Mention ehBASIC as the primary BASIC option |
| `wiki/log.md` | Append ingest entry |
| `PROGRESS.md` | Flip status |

---

## Notes

- The only doc file is `doc/help.rp6502` — read it in full, it is small.
- Assembly source in `src/` is ~90% of the codebase. Focus on the RP6502 integration layer, not the BASIC interpreter core (which is Lee Davison's unmodified code).
- Two releases exist (latest Jan 2024) — release notes may document what RP6502 features were added.
- If BASIC extensions include VGA graphics commands, cross-link to `wiki/concepts/vga-display-modes.md`.
- Cite the retro computing reference manual link from the README as an external reference in the source page.
