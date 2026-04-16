---
type: concept
tags: [rp6502, rom, file-format]
related: [[rp6502-ria]], [[rp6502-os]], [[xram]]
sources: [[rp6502-ria-docs]], [[release-notes]]
created: 2026-04-15
updated: 2026-04-16
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

## Related pages

- [[rp6502-ria]] · [[rp6502-os]] · [[xram]] · [[release-notes]]
