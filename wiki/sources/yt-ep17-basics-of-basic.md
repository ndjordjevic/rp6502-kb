---
type: source
tags: [rp6502, youtube, basic, ehbasic, boot, reset, reboot]
related:
  - "[[launcher]]"
  - "[[reset-model]]"
  - "[[rp6502-os]]"
  - "[[known-issues]]"
  - "[[development-history]]"
sources:
  - "[[youtube-playlist]]"
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep17 — The Basics of BASIC

**Summary**: Sets up Lee Davison's Enhanced BASIC (EhBASIC) as an installable ROM, configures it as the auto-boot target, explains the critical reboot vs. reset distinction, and demonstrates running classic BASIC games including a maze generator fix.

---

## Key topics

- **BASIC ROM**: Lee Davison's Enhanced BASIC (EhBASIC) — free and open source; not Microsoft BASIC or BBC BASIC (not FOSS).
- **Install workflow**: copy `basic.rp6502` to USB → `install basic.rp6502` → ROM stored in Pi Pico flash → `SET BOOT BASIC` → boots directly into BASIC every power-on.
- **Reboot vs. Reset** (critical distinction):
  - **Reboot** = full Pi Pico RIA restart (same as `reboot` command or pressing the on-board button); reloads boot ROM from flash.
  - **Reset** = 6502 reset only (RESB toggles); BASIC interpreter and any program in RAM are preserved.
- **Workaround for disk access from BASIC**: EhBASIC doesn't know about disk drives (from punched-tape era); use Ctrl+Alt+Del to reach monitor, do `LS` etc., then `RESET` to return to BASIC without losing program.
- **RND(1) vs RND(0)**: In EhBASIC, `RND(1)` sets the random seed (does NOT return a random number); `RND(0)` returns a random number. In Microsoft BASIC it's reversed. Classic BASIC listings using `RND(1)` will need this one-line fix.
- **CONTINUE**: if a program stops unexpectedly (e.g., empty input to INPUT statement), `CONTINUE` resumes.
- **Goal**: "instant on" — boot directly into BASIC like classic home computers.
- **Books referenced**: "BASIC Computer Games" by David Ahl (first computer book to sell 1 million copies).

## Related pages

- [[launcher]] — `SET BOOT` mechanism demonstrated
- [[reset-model]] — reboot vs. reset distinction detailed
- [[known-issues]] — EhBASIC `RND(1)` quirk
- [[development-history]] — Era E: BASIC introduction
