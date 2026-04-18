# raw/

Immutable source documents. **Never modify, delete, or create files here during a wiki session.**

The LLM reads from this directory but never writes to it. All wiki content derived from these sources lives in `../wiki/`.

## Sub-folders

| Folder | Source type | Index file |
| --- | --- | --- |
| `pdfs/` | PDF datasheets and reference books | `pdfs/README.md` |
| `web/` | Clipped Picocomputer documentation pages | `web/README.md` |
| `github/` | Git submodule(s) pinned to release tags | `github/README.md` |
| `youtube/` | Auto-caption transcripts (markdown) | `youtube/README.md` |
| `discord/` | DiscordChatExporter `.txt` exports | `discord/README.md` |

## File naming conventions

### `pdfs/`
Free-form filenames as downloaded/supplied. Each file gets one row in `pdfs/README.md`.

### `web/picocomputer.github.io/`
Named by Obsidian Web Clipper using the pattern:
```
<Page Title> — <Site Name>.md
```
Example: `RP6502-RIA — Picocomputer  documentation.md`

No separate index — filenames are self-describing. When a new page is clipped, add an entry to `raw/README.md` "Added sources" table below.

### `youtube/`
One file per video transcript, named:
```
<video-id>-<sanitized-title>.md
```
Example: `GOEI2OpMncY-RP6502 Ep2 - 6502 reads Raspberry Pi Pico @ 8 MHz - PIO and DMA.md`

Index is `youtube/README.md` — update it when adding new transcripts.

### `discord/`
One file per channel export, named:
```
<server>-<channel>-<YYYY-MM-DD>--<YYYY-MM-DD>.txt
```
Example: `rumbledethumps-chat-2022-11-03--2026-04-18.txt`

- `server` = Discord server name (e.g. `rumbledethumps`)
- `channel` = channel name without `#`
- First date = earliest message, second date = last message
- Incremental exports pick up from the day after the previous file's last date

Index is `discord/README.md` — update it when adding new exports.

### `github/picocomputer/rp6502/`
Git submodule pinned to a release tag. No separate index; use `git log` / `git tag` inside the submodule. Release notes are in `releases/` within the submodule.

---

## Provenance rule

Each sub-folder should contain or reference a record of where the files came from (URL, commit SHA, export date). When in doubt, add a one-line comment to the "Added sources" table below.

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
| 2026-04-16 | `github/picocomputer/rp6502/` | Git submodule [github.com/picocomputer/rp6502](https://github.com/picocomputer/rp6502) pinned at tag **v0.23** (commit `368ed8e`); nested submodules `src/littlefs`, `src/tinyusb` |
| 2026-04-16 | `github/picocomputer/rp6502/releases/` | 23 release notes v0.1–v0.23 fetched via `gh release view` |
| 2026-04-17 | `youtube/` | 21 transcripts fetched via `yt-dlp` from the [Picocomputer 6502 playlist](https://www.youtube.com/playlist?list=PLvCRDUYedILfHDoD57Yj8BAXNmNJLVM2r); Ep5 skipped (no captions) |
| 2026-04-17 | `discord/rumbledethumps-chat-2022-11-03--2026-04-18.txt` | DiscordChatExporter export, #chat channel, Rumbledethumps server |
| 2026-04-17 | `discord/rumbledethumps-razemos-2026-03-17--2026-04-13.txt` | DiscordChatExporter export, #razemos channel, Rumbledethumps server |
| 2026-04-17 | `pdfs/` | Various 6502 / RP2040 / RP2350 reference books and datasheets; see `pdfs/README.md` |
| 2026-04-18 | `pdfs/2023-06-07-rp6502.pdf` | RP6502 schematic Rev A, fetched from [picocomputer/picocomputer.github.io `_static/`](https://github.com/picocomputer/picocomputer.github.io/tree/main/docs/source/_static) |
