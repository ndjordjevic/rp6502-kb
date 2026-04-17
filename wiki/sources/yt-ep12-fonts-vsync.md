---
type: source
tags: [rp6502, youtube, fonts, vsync, code-pages, versioning, fat]
related: [[code-pages]], [[pix-bus]], [[rp6502-vga]], [[rp6502-ria]], [[development-history]]
sources: [[youtube-playlist]]
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep12 — Fonts and Vsync and Versioning

**Summary**: Covers v0.1 release milestone ("more than a dozen working devices"), introduces code pages (CP437/CP850/CP855) and FAT short-name fallback behavior, and explains the UART-TX backchannel VSYNC mechanism.

---

## Key topics

- **v0.1 release context**: "more than a dozen working devices" in the community; first versioned release now that hardware was validated and people were writing software.
- **Code pages**: default CP850 (Latin-1); also CP437 (original IBM PC — English/German/Swedish) and CP855 (Cyrillic). Selecting a code page (1) swaps glyph set and (2) tells the FAT driver which short-name encoding to use.
- **FAT short-name fallback**: files with characters not in the active code page fall back to 8.3 short names with a `~1` suffix. Changing code pages reveals different filenames.
- **VSYNC mechanism**: no spare GPIO pin for VSYNC → backchannel solution. RIA moves UART TX data to PIX bus and reverses the UART TX pin direction. VGA Pico uses this reversed pin to send VSYNC ticks and version info back to the RIA.
- **Backchannel complexity**: required flushing all hardware FIFOs before pin-direction switch, handling different FIFO sizes for CDC and UART, and using a "phantom UART" (not connected to any GPIO pin) for flow control on the high-speed PIX side.
- **User-facing API**: just read the `vsync` register (increments 60×/second at VBI start); all the complexity is hidden.
- **MacOS workaround**: UART break workaround added; Lee Smith's Windows video linked.

## Related pages

- [[code-pages]] — detailed code page / FAT interaction
- [[pix-bus]] — backchannel mechanism details
- [[rp6502-vga]] — VGA system that sends VSYNC ticks
- [[development-history]] — Era C: v0.1 release context, VSYNC story
