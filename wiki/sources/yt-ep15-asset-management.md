---
type: source
tags: [rp6502, youtube, assets, cmake, sprites, rom, graphics]
related:
  - "[[rom-file-format]]"
  - "[[rp6502-vga]]"
  - "[[xram]]"
  - "[[rp6502-abi]]"
  - "[[development-history]]"
sources:
  - "[[youtube-playlist]]"
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep15 — Asset Management and More Graphics

**Summary**: Introduces the CMake-based asset packaging workflow (`rp6502_asset` / `rp6502_executable`), demonstrates sprite/bitmap ROM loading, help-text shebang format, and shows the now-complete graphics system (characters, tiles, sprites with affine transforms).

---

## Key topics

- **Graphics system complete**: character, tile, sprite modes all now working.
- **Sprites with affine transforms**: scale, rotation, translation, occlusion. Up to 24 sprites at 128×128 px; more with smaller sizes. Linear algebra on the 6502 — uncommon historically, normal in modern game dev.
- **CMake asset workflow**:
  - `rp6502_asset(target, address, file)` — packages a binary file as a ROM asset; address starting with `0x10000` = extended RAM (for graphics/palette data).
  - `rp6502_executable()` — links code + all asset ROMs into a single `.rp6502` file.
  - Assets are already in correct memory location when program starts — no copy needed.
- **Help text asset**: create a text file with `#!RP6502` on line 1, then `# text` lines. This IS the ROM format; just add directly to `rp6502_executable()` (no `rp6502_asset` needed).
- **`rp6502.py` upload command**: upload any file to Picocomputer over USB without unplugging.
- **Memory layout**: 64 K system RAM (code/stack/heap) + 64 K extended RAM (graphics, audio, assets).
- **`install` workflow**: copy ROM to USB drive → `install name.rp6502` → available from monitor forever (stored in Pi Pico flash).
- **Tony VR's case**: community 3D-printed case with integrated USB hub.

## Related pages

- [[rom-file-format]] — complete ROM format specification and CMake integration
- [[rp6502-vga]] — graphics modes used by the demo
- [[xram]] — extended RAM where assets are loaded
- [[development-history]] — Era D: asset management workflow
