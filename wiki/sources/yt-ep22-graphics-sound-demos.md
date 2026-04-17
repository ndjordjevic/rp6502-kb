---
type: source
tags: [rp6502, youtube, demos, graphics, sound, opl2, psg, community]
related: [[opl2-fm-synth]], [[programmable-sound-generator]], [[rp6502-vga]], [[rp6502-ria]], [[development-history]]
sources: [[youtube-playlist]]
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep22 — Graphics and Sound Demos

**Summary**: Community demo showcase spanning the full history of the platform, culminating in the OPL2 FM synthesizer addition story: a community member's FPGA experiment on the PIX bus inspired the author to add OPL2 directly to the RIA firmware.

---

## Key topics

- **Demo lineup** (chronological, showing platform maturity):
  - Tetris (silent; baseline)
  - Star Swarms (sprites with affine transforms: rotation, scaling, translation, occlusion)
  - Game of Life (640×480 monochrome bitmap — "Macintosh vibes")
  - Sliding blocks puzzle with irregular shapes and image backgrounds
  - Darts game
  - 3D Falling Blocks
  - Raycast engine (Wolfenstein-style; "8-bit adder doing all the math")
  - Space Invaders with PSG audio ("best port on any 8-bit platform")
  - Asteroids (vector display emulation using fast line drawing)
  - Sega Genesis / Mega Drive port (also PSG audio)
  - Two more games with PSG audio + music tracker — all by one community author
- **OPL2 origin story**: the prolific community author "strapped an FPGA to the PIX bus to experiment with OPL2 sound" and mentioned writing a tracker. This inspired the Picocomputer author to add OPL2 natively.
- **OPL2 FM synthesizer**: same chip as AdLib / Sound Blaster 8-bit era (Yamaha YM3812-compatible). Added to RIA firmware — flash new UF2, no hardware change.
- **Tried earlier with Pi Pico 1** but "multiple things were in the way." Pi Pico 2 unblocked it "except my motivation" — the FPGA experiment provided the final push.
- **Music tracker**: 20-page documentation; effects include arpeggio, portamento, vibrato, echo, tremolo, microtonal folds.
- **Vintage Computer Festival PNW 2026** announced (Seattle, May 2–3).

## Related pages

- [[opl2-fm-synth]] — OPL2 FM synthesizer technical details
- [[programmable-sound-generator]] — PSG used in most community demos
- [[rp6502-vga]] — graphics system shown across all demos
- [[development-history]] — Era E: OPL2 addition story, community software
