# GitHub Sources — RP6502

Git repos from the official Picocomputer GitHub organization. All are plain clones — not git submodules. The parent `rp6502-kb` repo does not track them; they live in `raw/github/` as untracked nested repos (listed in `.gitignore`).

## Naming convention

Sub-folders mirror the GitHub org/repo structure:

```
<org>/<repo>/
```

Example: `picocomputer/rp6502/`

## Repos

| Folder | Repo | Current tag | Commit | Cloned |
| --- | --- | --- | --- | --- |
| `picocomputer/rp6502/` | [github.com/picocomputer/rp6502](https://github.com/picocomputer/rp6502) | `v0.24` | `1f924cf` | 2026-04-19 |
| `picocomputer/examples/` | [github.com/picocomputer/examples](https://github.com/picocomputer/examples) | *(no tags)* | `95965c6` | 2026-04-18 |
| `picocomputer/community/` | [github.com/picocomputer/community](https://github.com/picocomputer/community) | *(no tags)* | `348180a` | 2026-04-18 |
| `picocomputer/ehbasic/` | [github.com/picocomputer/ehbasic](https://github.com/picocomputer/ehbasic) | `v20240114` | `acd5deb` | 2026-04-18 |
| `picocomputer/pico-extras/` | [github.com/picocomputer/pico-extras](https://github.com/picocomputer/pico-extras) | *(no tags)* | `7f48b3f` | 2026-04-18 |
| `picocomputer/vscode-cc65/` | [github.com/picocomputer/vscode-cc65](https://github.com/picocomputer/vscode-cc65) | *(no tags)* | `794a6f2` | 2026-04-18 |
| `picocomputer/vscode-llvm-mos/` | [github.com/picocomputer/vscode-llvm-mos](https://github.com/picocomputer/vscode-llvm-mos) | *(no tags)* | `17af418` | 2026-04-18 |
| `picocomputer/adventure/` | [github.com/picocomputer/adventure](https://github.com/picocomputer/adventure) | `v20260225` | `6ac165f` | 2026-04-18 |

Nested submodules inside `rp6502`: `src/littlefs`, `src/tinyusb` (per upstream — init separately if needed).

Release notes (v0.1–v0.24) are in `picocomputer/rp6502/releases/`.

## Refresh / re-clone procedure

If `raw/github/picocomputer/` is missing (fresh checkout of `rp6502-kb`), clone all repos manually:

```bash
cd raw/github/picocomputer
git clone https://github.com/picocomputer/rp6502.git
git clone https://github.com/picocomputer/examples.git
git clone https://github.com/picocomputer/community.git
git clone https://github.com/picocomputer/ehbasic.git
git clone https://github.com/picocomputer/pico-extras.git
git clone https://github.com/picocomputer/vscode-cc65.git
git clone https://github.com/picocomputer/vscode-llvm-mos.git
git clone https://github.com/picocomputer/adventure.git
```

To pull a repo to the latest commit:

```bash
cd raw/github/picocomputer/<repo>
git pull origin main   # or: git checkout <tag>
```

After updating, record the new commit hash in the Repos table above.
