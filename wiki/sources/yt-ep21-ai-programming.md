---
type: source
tags: [rp6502, youtube, ai, copilot, cc65, programming-demo]
related:
  - "[[cc65]]"
  - "[[rp6502-abi]]"
  - "[[development-history]]"
sources:
  - "[[youtube-playlist]]"
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep21 — Programming a 6502 with AI

**Summary**: Demonstrates using GitHub Copilot (Anthropic models) to write Picocomputer programs in real time, highlighting both successes and failure modes — particularly the tendency to ignore documentation.

---

## Key topics

- **AI workflow**: GitHub Copilot (Anthropic models) in VS Code; cc65 template used (LLVM-MOS template also available).
- **Successful demos**: Fibonacci, Mandelbrot (fixed-point, AI correctly deduced 16-bit int constraint), guessing game (with seed fix), sprite animation (dragon), PSG music (Mary Had a Little Lamb after hints).
- **Key observation**: "the AI loves ignoring the documentation." Whenever the AI reads the docs first, it succeeds; when it doesn't, it usually fails. Explicitly prompting the AI to read docs helps.
- **Header file anchoring**: AI spent time searching the file system for headers that the IDE already knew about. Workaround: manually anchor the header file in the chat context.
- **Required hints**: (1) tell AI that cc65 ints are 16-bit (it tried 16.16 fixed-point which requires 64-bit ops); (2) tell AI `randomize()` is the cc65 function for seeding RNG; (3) for PSG, tell AI to add a note-off period between notes.
- **Tutorial content**: primarily meta-commentary on AI-assisted development for niche hardware.

## Related pages

- [[cc65]] — the compiler used
- [[rp6502-abi]] — the hardware interface the AI had to learn
