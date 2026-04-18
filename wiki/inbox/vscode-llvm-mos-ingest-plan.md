# picocomputer/vscode-llvm-mos — Ingest Plan

**Source**: https://github.com/picocomputer/vscode-llvm-mos (fetch via WebFetch)
**Priority**: MEDIUM
**Approach**: README and CMakeLists.txt are the primary assets. Ingest alongside or immediately after `vscode-cc65` so both land in the same toolchain-setup page.

---

## Strategy

Mirror of the cc65 template ingest but for the LLVM-MOS toolchain. The README contains Linux/Windows setup instructions and notes about PATH conflicts with other LLVM installations (a unique gotcha vs cc65). The CMake structure may differ slightly. Both compiler paths should live in a unified `wiki/topics/toolchain-setup.md` with a side-by-side comparison table if the information supports it.

---

## Reading order

- [ ] **README.md** — https://raw.githubusercontent.com/picocomputer/vscode-llvm-mos/main/README.md
  - Linux setup steps (VSCode, llvm-mos, cmake, git)
  - Windows setup steps
  - PATH conflict warning with existing LLVM installations — extract exact guidance
  - Project init workflow (clone → VSCode → F5)
  → Update `wiki/topics/toolchain-setup.md` with llvm-mos section

- [ ] **CMakeLists.txt** — https://raw.githubusercontent.com/picocomputer/vscode-llvm-mos/main/CMakeLists.txt
  - Compare structure to cc65 CMakeLists.txt — note differences
  - Note mos_* cmake functions vs cc65_* equivalents
  → Add CMake diff notes to `wiki/topics/toolchain-setup.md`

- [ ] **src/ hello-world file(s)**
  - Note entry point convention for llvm-mos vs cc65 (may differ)
  → Add to toolchain-setup.md minimal program section

- [ ] **GitHub Actions workflow** (if present under `.github/workflows/`)
  - https://github.com/picocomputer/vscode-llvm-mos/tree/main/.github
  - CI build steps reveal any non-obvious build dependencies
  → Extract if useful; add to toolchain notes

---

## Wiki pages to create or update

| Page | Action |
|------|--------|
| `wiki/sources/vscode-llvm-mos.md` | Create — source summary page |
| `wiki/topics/toolchain-setup.md` | Update — add llvm-mos section; add comparison table |
| `wiki/index.md` | Update |
| `wiki/log.md` | Append ingest entry |
| `PROGRESS.md` | Flip status |

---

## Notes

- Do this session immediately after or in the same session as `vscode-cc65` so the comparison table can be written with both sets of facts in hand.
- The LLVM-MOS SDK is a large upstream project; this template only pins to the picocomputer fork (`picocomputer/llvm-mos-sdk`). Note the fork URL and any RP6502-specific target name (e.g. `mos-rp6502` or similar).
- PATH conflict with system LLVM is a known gotcha — make sure it gets a callout in the toolchain-setup page.
- Check `.github/workflows/` for the CI YAML; it often lists exact package versions and reveals install order dependencies.
