# raw/

Immutable source documents. **Never modify, delete, or create files here during a wiki session.**

The LLM reads from this directory but never writes to it. All wiki content derived from these sources lives in `../wiki/`.

## Contents

| Folder | Source type |
| --- | --- |
| `pdfs/` | PDF datasheets and reference books |
| `web/picocomputer.github.io/` | Clipped Picocomputer documentation pages |
| `github/picocomputer/` | Git submodule: [picocomputer/rp6502](https://github.com/picocomputer/rp6502), pinned to a release tag |
| `youtube/` | Auto-caption transcripts + `VIDEO_INDEX.md` |
| `discord/` | DiscordChatExporter `.txt` exports |
| `assets/` | Downloaded images referenced by clipped pages |

## Provenance rule

Each sub-folder should contain or reference a record of where the files came from (URL, commit SHA, export date). When in doubt, add a one-line comment to this file.

## Cloning this knowledge base

After `git clone`, initialize submodules (and nested submodules inside `rp6502`):

```bash
git clone --recurse-submodules https://github.com/ndjordjevic/rp6502-kb.git
# or, if already cloned:
git submodule update --init --recursive
```

## Bumping `picocomputer/rp6502` to a new release

```bash
cd raw/github/picocomputer/rp6502
git fetch --tags origin
git checkout v0.xx   # new release tag
git submodule update --init --recursive
cd ../../..
git add raw/github/picocomputer/rp6502
git commit -m "Bump rp6502 submodule to v0.xx"
```

## Added sources

| Date | File / folder | Origin |
| --- | --- | --- |
| 2026-04-15 | `web/picocomputer.github.io/` | 6 pages clipped with Obsidian Web Clipper from [picocomputer.github.io](https://picocomputer.github.io/): index, hardware, ria, ria_w, vga, os |
| 2026-04-16 | `github/picocomputer/rp6502/` | Git submodule [github.com/picocomputer/rp6502](https://github.com/picocomputer/rp6502) pinned at tag **v0.23** (commit `368ed8e`, 2026-04-11, "fix usb race and tune std_api_read_xram"); nested submodules `src/littlefs`, `src/tinyusb` per upstream |
| 2026-04-16 | `github/picocomputer/rp6502/releases/` | 23 release notes v0.1–v0.23 fetched via `gh release view` |
