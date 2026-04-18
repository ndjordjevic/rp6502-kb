# picocomputer/pico-extras — Ingest Plan

**Source**: https://github.com/picocomputer/pico-extras (fetch via WebFetch; diff-focused approach)
**Priority**: MEDIUM
**Approach**: Do NOT read the full fork (it is a large upstream project). Focus only on commits unique to the picocomputer fork and the specific files modified. The goal is to understand what video mode switching fixes were needed for RP6502-VGA.

---

## Strategy

This fork exists solely to fix video mode switching with RP6502. The changes are in `pico_scanvideo` and `pico_scanvideo_dpi`. Rather than reading the whole library, compare picocomputer fork commits against upstream. The wiki output is a short addition to the VGA entity/concept pages explaining *why* this fork is needed and what it fixes.

---

## Reading order

- [ ] **Commit history** — https://github.com/picocomputer/pico-extras/commits/master/
  - Already partially known: memory leak on mode change, debug printf on mode change, scanvideo DMA interrupt priority, audio buffer free on disable, non-RGB555 format support, higher res modes (1024×768, 1280×1024)
  - Read full commit list to identify all picocomputer-specific commits vs upstream merges
  - Note exact commit messages and dates
  → Draft summary of fixes for `wiki/entities/rp6502-vga.md`

- [ ] **Key changed files** — identify from commit history which files were patched, then read them:
  - Likely: `src/rp2_common/pico_scanvideo/scanvideo.c` or similar
  - Focus on the mode-change memory leak fix and DMA interrupt priority fix
  - Read only the diff sections (look for picocomputer-authored changes)
  → Extract: what exactly was leaking? what was the DMA interrupt priority bug?

- [ ] **Releases / tags** — https://github.com/picocomputer/pico-extras/tags
  - Note which upstream pico-extras version this fork branched from
  - Note if there are any picocomputer-specific tags/releases
  → Record fork base version in source page

---

## Wiki pages to create or update

| Page | Action |
|------|--------|
| `wiki/sources/pico-extras.md` | Create — brief source page documenting fork purpose and patches |
| `wiki/entities/rp6502-vga.md` | Update — add section on pico-extras dependency and why the fork is needed |
| `wiki/concepts/vga-display-modes.md` | Update — note mode-switching requirement and the DMA/memory fix |
| `wiki/index.md` | Update |
| `wiki/log.md` | Append ingest entry |
| `PROGRESS.md` | Flip status |

---

## Notes

- Key facts already known (from commit history fetch):
  - "fix memory leak on mode change" — June 2023
  - "hide debug printf that shows on mode change" — June 2023
  - "Free audio buffer on audio_i2s_set_enabled(false)" — Feb 2023
  - Scanvideo DMA interrupt priority correction and linked mode fixes
  - Added 1024×768 and 1280×1024 resolution modes
  - Non-RGB555 color format support
  - Removed lwip (integrated into main SDK)
- This is a dependency of the `rp6502` firmware, not a standalone tool. The wiki page should frame it as "required fork of pico-extras used by RP6502-VGA firmware."
- Do not ingest the full pico-extras library — it is a large upstream Raspberry Pi project outside our scope.
- If `wiki/entities/rp6502-vga.md` does not yet exist, create a minimal version as part of this ingest.
