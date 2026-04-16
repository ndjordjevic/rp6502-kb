# raw/

Immutable source documents. **Never modify, delete, or create files here during a wiki session.**

The LLM reads from this directory but never writes to it. All wiki content derived from these sources lives in `../wiki/`.

## Contents

| Folder | Source type |
| --- | --- |
| `pdfs/` | PDF datasheets and reference books |
| `web/picocomputer.github.io/` | Clipped Picocomputer documentation pages |
| `github/picocomputer/` | Shallow clone of `picocomputer/rp6502` at a pinned commit |
| `youtube/` | Auto-caption transcripts + `VIDEO_INDEX.md` |
| `discord/` | DiscordChatExporter `.txt` exports |
| `assets/` | Downloaded images referenced by clipped pages |

## Provenance rule

Each sub-folder should contain or reference a record of where the files came from (URL, commit SHA, export date). When in doubt, add a one-line comment to this file.

## Added sources

| Date | File / folder | Origin |
| --- | --- | --- |
| 2026-04-15 | `web/picocomputer.github.io/` | 6 pages clipped with Obsidian Web Clipper from [picocomputer.github.io](https://picocomputer.github.io/): index, hardware, ria, ria_w, vga, os |
| 2026-04-16 | `github/picocomputer/rp6502/` | Shallow clone of [github.com/picocomputer/rp6502](https://github.com/picocomputer/rp6502) at commit `368ed8e` (2026-04-11, "fix usb race and tune std_api_read_xram") |
| 2026-04-16 | `github/picocomputer/rp6502/releases/` | 23 release notes v0.1–v0.23 fetched via `gh release view` |
