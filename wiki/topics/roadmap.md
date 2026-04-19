---
type: topic
tags: [rp6502, roadmap, future, plans, releases]
related:
  - "[[version-history]]"
  - "[[release-notes]]"
  - "[[rp6502-ria]]"
  - "[[rp6502-ria-w]]"
  - "[[rp6502-vga]]"
  - "[[rp6502-os]]"
  - "[[known-issues]]"
sources:
  - "[[release-notes]]"
  - "[[rumbledethumps-discord]]"
created: 2026-04-18
updated: 2026-04-18
---

# Roadmap

**Summary**: Known planned features, community wishes, and design direction for the RP6502 Picocomputer project — synthesized from release notes, Discord discussions, and stated design philosophy.

---

> **Important caveat**: The RP6502 has no formal public roadmap. All "planned" items below come from: (a) features explicitly noted as planned in release notes, (b) statements by @rumbledethumps in Discord, (c) the natural continuation of existing trajectories. Treat this as informed speculation, not a commitment.

---

## Current state (v0.24, April 2026)

As of v0.24 the project has:
- **30,000+ lines** of code unique to the project (not counting FatFs, TinyUSB, etc.)
- Full WiFi networking — Hayes modem over TCP+Telnet, telnet console access
- 6-mode VGA display (modes 0–5 including sprites)
- Complete POSIX-flavored OS with file I/O, process exec, NFC, audio (PSG + OPL2)
- Two supported toolchains (cc65, llvm-mos) with VSCode templates
- Community projects across games, demos, trackers, and community OS (razemOS)

---

## Near-term trajectory (based on recent release cadence)

The project has been releasing approximately monthly. Recent themes:

| Era | Theme | Key releases |
|-----|-------|-------------|
| Era 7 | Process/exec model | v0.18–v0.21 |
| Era 8 | Display completeness | v0.22–v0.23 |
| Era 9 | Networking | v0.24 |

**Likely next themes:**
- Networking polish (multi-user BBS, more modem features)
- Additional VGA display features
- cc65/llvm-mos stdlib improvements

---

## Explicitly stated plans (from official sources)

### Telnet (now completed — v0.24)
- v0.12 release notes: "Telnet layer is a planned future feature" → **Delivered v0.24** (Apr 2026)

### llvm-mos standard library
- From Ep18 (2025): "I expect it to catch up this year, at which point LLVM-MOS would be generally preferable for new projects." — @rumbledethumps
- Status: llvm-mos stdlib was "sparse" in 2025; actively improving in 2026

### cc65 upstream errno merge
- PR #2844 (errno rework) was merged upstream but requires testing before dropping the picocomputer/cc65 fork requirement
- Status: picocomputer/cc65 fork still required as of v0.24

---

## Community wish list (from Discord + GitHub Discussions)

These items appeared in community discussion but have no official commitment:

### Hardware

| Feature | Notes |
|---------|-------|
| **65816 support** | tonyvr0759 ran a WDC 65816 on an RP6502-style board at 6 MHz on a breadboard. Not an official project target. |
| **Alternative board form factors** | Pimoroni PGA2350 + breadboard builds explored by community |
| **FPGA OPL2 hardware** | jasonr1100 built an FPGA OPL2 card via PIX bus at `$1FF00`; not integrated into official firmware |
| **eInk display** | jjjacer built an RP6502 laptop with ESP32-driven eInk display over UART |

### Software / OS

| Feature | Notes |
|---------|-------|
| **Disk-aware BASIC** | EhBASIC predates disk drives; a future disk-aware BASIC port would remove the `RESET` workaround for disk access |
| **Multitasking OS** | razemOS (community) is working toward this; not an official firmware target |
| **Math coprocessor** | voidas_pl proposed float32 via RIA registers `$FFEF`/`$FFF1`; PR not merged |
| **Additional VCP drivers** | More USB-to-serial adapter support (currently FTDI, CP210X, CH34X, PL2303, CDC ACM) |

---

## Design philosophy (shapes future direction)

Statements from @rumbledethumps that imply future direction:

> "32 bytes is all I ask" — the entire 6502↔OS interface fits in 32 registers. Simplicity is a core value. New features that require expanding the register map are unlikely.

> "The OS uses zero 6502 RAM" — the RIA firmware's zero-footprint design is fundamental. Any future OS features will maintain this guarantee.

> "You can make a BBS server" — v0.24's 4-simultaneous-modems + headless operation (USB drive + power only) enables multi-user server applications. This is an officially acknowledged use case.

> "The RIA-W is a strict superset" — networking features always land in RIA-W without changing the base RIA behavior.

---

## What will likely NOT change

Based on stated design principles:

- **No ROM in 6502 space** — fundamental to the design
- **No OS RAM in 6502 space** — the RIA runs in RP2350, not 6502 memory
- **Reset vector in RAM** — the 6502 has no hardwired boot ROM
- **32 register interface** — adding registers would require hardware changes
- **PHI2 cap at 8 MHz** — limited by W65C02S electrical specifications

---

## Version numbering

The project uses simple incrementing v0.x releases. There is no stated plan for a "v1.0". The minor version number has been incrementing for 2+ years; "1.0" may coincide with a feature freeze or community milestone, but nothing is announced.

---

## Related pages

- [[version-history]] — narrative history by era (v0.1–v0.24)
- [[release-notes]] — chronological feature table
- [[community-projects]] — community roadmaps (razemOS multitasking, etc.)
- [[known-issues]] — current bugs and limitations
- [[rp6502-ria-w]] — networking features (v0.24 Telnet/Hayes)
