# picocomputer/vscode-cc65 — Ingest Plan

**Source**: https://github.com/picocomputer/vscode-cc65 (fetch via WebFetch)
**Priority**: MEDIUM
**Approach**: README is the primary asset; also read the hello-world C and assembly starters and CMakeLists.txt template.

---

## Strategy

This is the official project template for cc65-based RP6502 development. The README contains the authoritative toolchain setup procedure for both Linux and Windows. The hello-world starters show the minimal project structure. Ingest feeds a `wiki/topics/toolchain-setup.md` page covering the cc65 path; the llvm-mos plan covers the other path. Both topic contributions should live in a single combined toolchain page.

---

## Reading order

- [ ] **README.md** — https://raw.githubusercontent.com/picocomputer/vscode-cc65/main/README.md
  - Linux setup steps (VSCode, cc65 from source, cmake, python3, pyserial)
  - Windows setup steps (winget packages, GNU Make PATH, cc65 snapshot)
  - Project init workflow (clone template → open in VSCode → F5 to flash)
  - CMake launch target selection for choosing which program to run
  → Update `wiki/topics/toolchain-setup.md` (create if absent) with cc65 section

- [ ] **CMakeLists.txt** — https://raw.githubusercontent.com/picocomputer/vscode-cc65/main/CMakeLists.txt
  - Note the project() macro, target names, required cc65 integration points
  - Note how to add new source files
  → Add CMake project structure notes to `wiki/topics/toolchain-setup.md`

- [ ] **src/ hello-world files** (C and assembly variants)
  - https://raw.githubusercontent.com/picocomputer/vscode-cc65/main/src/hello.c (or similar)
  - Note minimum viable program structure, includes, entry point convention
  → Add "minimal program" snippet to `wiki/topics/toolchain-setup.md`

---

## Wiki pages to create or update

| Page | Action |
|------|--------|
| `wiki/sources/vscode-cc65.md` | Create — source summary page |
| `wiki/topics/toolchain-setup.md` | Create (or update) — cc65 section |
| `wiki/index.md` | Update |
| `wiki/log.md` | Append ingest entry |
| `PROGRESS.md` | Flip status |

---

## Notes

- Ingest this alongside `vscode-llvm-mos` so both compilers appear in the same `toolchain-setup.md` page for easy comparison.
- cc65 is the C compiler; llvm-mos is the LLVM-based alternative — note their tradeoffs if visible in the README.
- The template points to the cc65 picocomputer fork (custom build from source), not the upstream cc65 package. Note the fork URL.
- Check `wiki/sources/` for any existing toolchain notes from the RIA web clip ingest; update rather than duplicate.
