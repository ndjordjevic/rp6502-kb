# GitHub Sources — RP6502

Git submodule(s) from the official Picocomputer GitHub organization.

## Naming convention

Sub-folders mirror the GitHub org/repo structure:

```
<org>/<repo>/
```

Example: `picocomputer/rp6502/`

## Submodules

| Folder | Repo | Current tag | Commit | Pinned |
| --- | --- | --- | --- | --- |
| `picocomputer/rp6502/` | [github.com/picocomputer/rp6502](https://github.com/picocomputer/rp6502) | `v0.23` | `368ed8e` | 2026-04-16 |
| `picocomputer/examples/` | [github.com/picocomputer/examples](https://github.com/picocomputer/examples) | *(no tags)* | `95965c6` | 2026-04-18 |
| `picocomputer/pico-extras/` | [github.com/picocomputer/pico-extras](https://github.com/picocomputer/pico-extras) | *(no tags)* | `7f48b3f` | 2026-04-18 |
| `picocomputer/community/` | [github.com/picocomputer/community](https://github.com/picocomputer/community) | *(no tags)* | `348180a` | 2026-04-18 |
| `picocomputer/ehbasic/` | [github.com/picocomputer/ehbasic](https://github.com/picocomputer/ehbasic) | `v20240114` | `acd5deb` | 2026-04-18 |

Nested submodules inside `rp6502`: `src/littlefs`, `src/tinyusb` (per upstream).

Release notes (v0.1–v0.23) are in `picocomputer/rp6502/releases/`.

## Refresh procedure

To bump the submodule to a new release tag:

```bash
cd raw/github/picocomputer/rp6502
git fetch --tags origin
git checkout v0.xx   # new release tag
git submodule update --init --recursive
cd ../../../..
git add raw/github/picocomputer/rp6502
git commit -m "Bump rp6502 submodule to v0.xx"
```

After bumping, update the ## Submodules table above and `raw/README.md`.
