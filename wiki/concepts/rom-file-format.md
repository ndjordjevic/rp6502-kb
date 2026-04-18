---
type: concept
tags: [rp6502, rom, file-format]
related: [[rp6502-ria]], [[rp6502-os]], [[xram]], [[adventure]]
sources: [[rp6502-ria-docs]], [[release-notes]], [[youtube-playlist]]
created: 2026-04-15
updated: 2026-04-18
---

# `.rp6502` ROM File Format

**Summary**: A `.rp6502` file is a text shebang followed by one or more raw-binary chunks ("assets"). Loaded by the RP6502 monitor's `load`, `install`, and `set boot` commands.

> "These aren't ROMs in the traditional (obsolete) sense. A ROM is a file that contains a memory image to be loaded in RAM before starting the 6502."

---

## Structure

```
#!RP6502           ← shebang (literal, first line)
#>len crc          ← null-named asset header → binary data follows
addr len crc
<len bytes of binary>
addr len crc
<len bytes of binary>
...
#>len crc name     ← named asset header → binary data follows
<len bytes of binary>
...
```

Numbers may be written in decimal (`255`), C hex (`0xFF`), or MOS hex (`$FF`). Line endings are `\r`, `\n`, or both.

## Two kinds of assets

### Null-named (memory chunks)

A header `#>len crc` introduces a group, then one or more chunks `addr len crc` followed by exactly `len` bytes of raw binary:

| Field | Meaning |
| --- | --- |
| `addr` | Destination — 6502 RAM `0x0000-0xFEFF` or [[xram]] `0x10000-0x1FFFF` |
| `len` | Bytes that immediately follow |
| `crc` | CRC of the payload (**checked**) |

These get loaded directly into RAM/XRAM before the 6502 starts.

### Named (data blobs)

A header `#>len crc name` followed by `len` bytes is a named asset. CRC is **ignored**. Once the ROM is running, named assets become files in a virtual ROM filesystem:

```c
fd = open("ROM:help", O_RDONLY); // open the asset called "help"
```

Multiple ROM assets may be open at once; they are read-only. The lookup is a linear scan, so cost is O(n) in the number of assets ahead of the one you want.

### Special asset names

- **`help`** — shown by the monitor's `HELP` and `INFO` commands.

## Tooling

The `rp6502.py` script (shipped with the templates) wraps file packaging and CMake integration:

```cmake
rp6502_asset(your_project 0x10000 img/intro.bin)   # memory chunk into XRAM @ $10000
rp6502_asset(your_project help    src/help.txt)    # named asset
```

## Lifecycle

1. `load /game.rp6502` — load (or run via NFC tap) without persisting.
2. `install /game.rp6502` — copy into the RIA's 1 MB onboard flash.
3. `set boot game` — make it the auto-boot ROM at next reset.

> **Added in v0.18**: Named asset support in ROM files was introduced in v0.18 (Feb 2026). Earlier versions only supported null-named memory chunks. The CMake tooling was also simplified in v0.18 — `rp6502_asset()` automatically includes the asset in the executable without needing to list it separately in `rp6502_executable()`.

## CMake asset workflow (from [[yt-ep15-asset-management]])

> **Source**: [[yt-ep15-asset-management]] (Ep15). This workflow was introduced alongside the completion of all graphics modes.

### CMake commands

```cmake
# Package a binary file as a ROM asset chunk
rp6502_asset(target 0x10000 path/to/image.bin)    # loads into XRAM at $10000
rp6502_asset(target 0x11000 path/to/palette.bin)  # loads into XRAM at $11000

# Link code + all declared assets into a single .rp6502 file
rp6502_executable(target)
```

**Address convention**: a 5-digit address starting with `1` (e.g., `0x10000`) places the data in extended RAM ([[xram]]). A standard 16-bit address (`0x0200`) places it in 6502 system RAM.

### How it works at boot

When the ROM loads:
1. Each asset chunk is copied to its declared address in XRAM or system RAM.
2. When the 6502 program starts, all asset data is already at its final location.
3. No `memcpy` needed — just reference the XRAM addresses directly.

### Help text asset

A help-text file is the ROM format itself — no `rp6502_asset` packaging needed:

```
#!RP6502
# My Application v1.0
# A brief description of what this does.
# Usage: LOAD myapp.rp6502
```

Add directly to `rp6502_executable()`:
```cmake
rp6502_executable(target help_text.rp6502)
```

The monitor `HELP myapp` and `INFO myapp` commands will display this text.

### rp6502.py upload command

`rp6502.py upload <file>` sends any file to the Picocomputer over USB without unplugging — works for ROM files and also arbitrary data files (sprites, palettes, levels) that will be loaded from disk at runtime.

### Installing ROMs into flash

```
LOAD /game.rp6502      # load and run from USB (temporary)
install /game.rp6502   # copy to Pi Pico flash via littlefs
```

Installed ROMs appear in `HELP` and persist across power cycles with no USB drive required.

## Real-world example: Colossal Cave Adventure ([[adventure]])

The `picocomputer/adventure` repo is the canonical example of named ROM assets in practice:

```cmake
rp6502_asset(adventure /advent1.txt troglobit/src/advent1.txt)
rp6502_asset(adventure /advent2.txt troglobit/src/advent2.txt)
rp6502_asset(adventure /advent3.txt troglobit/src/advent3.txt)
rp6502_asset(adventure /advent4.txt troglobit/src/advent4.txt)
rp6502_executable(adventure DATA 0x200 RESET 0x200)
```

The game code opens these files with:
```c
// config.h
#define DATADIR "ROM:"

// game code (unchanged upstream)
fd = fopen(DATADIR "advent1.txt", "r");
```

Changing `DATADIR` to `"ROM:"` is the **entire RP6502 port** for file access — zero changes to upstream game code. The OS resolves `"ROM:advent1.txt"` to the named asset packed in the `.rp6502` file.

## Related pages

- [[rp6502-ria]] · [[rp6502-os]] · [[xram]] · [[release-notes]]
- [[adventure]] — canonical named-asset example (Colossal Cave Adventure)
- [[yt-ep15-asset-management]] — live walkthrough of the CMake workflow
