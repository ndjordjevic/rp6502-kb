# Wiki Log

Append-only record of all wiki operations. Most recent entry at the top.
Format: `## [YYYY-MM-DD] <operation> | <source or topic> | <what changed>`

Operations: `ingest`, `query`, `lint`, `setup`

---

## [2026-04-19] ingest | WojciechGw/cc65-rp6502os (razemOS + HASS) | new source page, new HASS entity, razemos updated

Cloned `WojciechGw/cc65-rp6502os` at commit `782ff15` (2026-04-19) to `raw/github/WojciechGw/cc65-rp6502os/`. Updated `raw/github/README.md`.

New: `wiki/sources/razemos-repo.md` — full source page covering razemOS shell architecture, all 20+ internal commands, ROM commands (dir/hex/pack/peek/roms/view/etc.), three program formats (.com/.exe/.rp6502), Intel HEX UART file transfer protocol (CRC32), extension command system via MSC0:/SHELL/, `razemOScmd.py` build tool.

New: `wiki/entities/hass.md` — complete HASS assembler reference: invocation, all 16 `@` interactive commands, @TRACE built-in W65C02S software emulator (single-step + run mode + cycle counting), directives (.ORG/.EQU/.BYTE/.WORD/.ASCII/.ASCIZ/.INCLUDE), full addressing mode table, complete 65C02+WDC instruction set listing, limits table (512 lines / 16 KB / 128 symbols).

Updated: `wiki/entities/razemos.md` — greatly expanded: full memory layout ($8000–$FCFF ~31 KB for user programs), three program formats, extension command system, UART file transfer protocol, HASS assembler summary, keyboard shortcuts, version history updated to commit 782ff15 (2026-04-19).

Updated: `wiki/index.md` — added [[razemos-repo]] source entry, [[hass]] entity entry; [[razemos]] description improved.

Key facts:
- razemOS user programs run at `$8000–$FCFF` (~31 KB)
- `.com` commands in `MSC0:/SHELL/` override ROM commands without rebuilding
- HASS has a **built-in W65C02S software emulator** (`@TRACE`) with single-step, run mode, and cycle counting
- File transfer uses Intel HEX over UART with CRC32
- Actively developed — commits as of 2026-04-19

---

## [2026-04-19] lint | wiki-wide | Obsidian frontmatter fix + contradiction fix + cross-ref + log formatting

- **Obsidian invalid properties fixed (134 files)**: `related:` and `sources:` frontmatter fields converted from inline `[[wikilinks]], [[wikilinks]]` (invalid YAML) to proper YAML list format (`- "[[wikilink]]"`). All wiki pages now render without "Invalid properties" in Obsidian Reading view.
- **CLAUDE.md updated**: Page format template updated to match new YAML list format for `related` and `sources`.
- **Contradiction fixed**: `wiki/concepts/rp2040-clocks.md` line 51 — clarified "System PLL official max output: 150 MHz (RP2350 rated spec)" vs RIA overclock to 256 MHz; added cross-ref to [[pio-architecture]].
- **Cross-reference added**: `wiki/concepts/usb-controller.md` — added `[[pico-c-sdk]]` to sources frontmatter and Related pages footer.
- **Log formatting fixed**: Added missing `---` separators between all log entries (1049 → 1189 lines).
- **raw/github/README.md updated**: `picocomputer/rp6502/` row corrected from `v0.23` / `368ed8e` → `v0.24` / `1f924cf` (2026-04-19).

---

## [2026-04-18] synthesis | hardware TRNG | new page wiki/syntheses/trng.md

New: `wiki/syntheses/trng.md` — RP2350 hardware TRNG mechanics (`get_rand_64()` via Pico SDK), `RIA_ATTR_LRAND` (0x04) attribute, cc65 `_randomize()` + `rand()` PRNG seeding pattern, llvm-mos `lrand()` true-random-per-call pattern, 65C02 assembly access, comparison table, and EhBASIC RND pitfall.
Updated: `wiki/index.md` — [[trng]] entry added to Syntheses; `PROGRESS.md` — TRNG item marked ✅.

---

## [2026-04-18] ingest | WDC W65C22S datasheet (wdc_w65c22s_mar_2004.pdf) | new source page + 5 wiki updates

New: `wiki/sources/wdc-w65c22s-datasheet.md` — full 46-page datasheet ingested.
Updated: `wiki/entities/w65c22s.md` — IRQB totem-pole, reset exception, bus holding, speed/voltage.
Updated: `wiki/entities/6522-via.md` — added "W65C22S-specific caveats" section: IRQB no wire-OR, T2 rollover, T1 N+2 timing, reset exception, shift direction, output current limits.
Updated: `wiki/concepts/via-programming.md` — added hardware caveats section.
Updated: `raw/pdfs/README.md` and `wiki/index.md` — added datasheet entry.

Key facts not previously in wiki: IRQB is totem-pole (cannot wire-OR), T1 fires at N+1.5/N+2 cycles, T2 rolls over to $FFFF after timeout, RESB does not clear T1/T2/SR, no output current limiting on PA/PB.

---

## [2026-04-18] lint + guide update | wiki-wide lint + learning-guide revision | 3 fixes, guide updated with Phase 4 pages

- **Factual error fixed**: `game-loop-patterns.md` had wrong VSYNC register address (`$FFF8` → `$FFE3`). Confirmed from source: `REGS(0xFFE3) = vga_vsync_frame` (ria/sys/vga.c:91) + `if (i != 3) // Skip VSYNC` (api/api.c:105).
- **Data gap fixed**: `ria-registers.md` marked `$FFE3` as "unassigned". Corrected to `RIA_VSYNC` (VSYNC frame counter, increments ~60 Hz, preserved across soft resets).
- **Broken wikilink fixed**: `razemos.md` had `[[hass]]` linking to non-existent page. Replaced with plain text "HASS assembler (native 65C02 on-device assembler)".
- **Learning guide updated** (`wiki/syntheses/learning-guide.md`): added all Phase 4 pages — `cc65-rp6502-platform` (D3), `monitor-reference` (C2), `via-programming` (D11), `game-loop-patterns` (D10), `ria-w-networking` (C19), `hardware-build-guide` (B3), `razemos`/`rptracker` (community section); added three orientation syntheses section; expanded Track B to 11 steps, Track C to 20, Track D to 21; added wireless learning sub-path.
- **Lint findings summary**: 1 broken wikilink (`[[hass]]`), 2 factual errors (VSYNC address + $FFE3 description). All fixed. Pages with low inbound links are now referenced from the updated learning guide.

---

## [2026-04-18] research + gap-fill | online research session | v0.24 update + 11 new pages

Deep online research (12+ web searches), v0.24 release verified, 11 new pages written, cc65 platform docs clipped.

**Updated existing pages:**
- `wiki/sources/release-notes.md`: Added v0.24 row to timeline table; expanded Networking and Monitor/UX sections; fixed stale "telnet planned" note → "added v0.24"
- `wiki/index.md`: Added 10 new page entries; updated release-notes count to 24; added Syntheses section entries
- `PROGRESS.md`: Phase 3b marked complete; Phase 4 gap-fill added; wiki size updated (129 total)

**New raw source:**
- `raw/web/cc65.github.io/Picocomputer 6502 — cc65 documentation.md` — clipped 2026-04-18
- `raw/web/README.md`: Added cc65.github.io section

**New wiki pages (11):**
- `wiki/sources/cc65-rp6502-platform.md` — cc65 RP6502 platform docs (binary format, memory layout, rp6502.h)
- `wiki/syntheses/what-does-ria-do.md` — RIA's three roles: hardware control, bus interface, protected OS
- `wiki/syntheses/getting-started.md` — hardware → firmware → toolchain → first C program
- `wiki/syntheses/cc65-vs-llvm-mos.md` — feature table, performance, binary size, decision guide
- `wiki/concepts/monitor-reference.md` — complete monitor command reference (LOAD/INSTALL/SET/filesystem/history)
- `wiki/concepts/ria-w-networking.md` — WiFi config, NTP, BLE, telnet console, Hayes modem AT commands
- `wiki/concepts/via-programming.md` — practical VIA: GPIO, T1/T2 interrupts, shift register, RTC
- `wiki/concepts/game-loop-patterns.md` — VSYNC polling, interrupt sync, frame budget, double-buffering
- `wiki/entities/rptracker.md` — OPL2 music tracker by jasonr1100 (9ch, 256 patches, effects)
- `wiki/entities/razemos.md` — razemOS native 65C02 OS by voidas_pl (v0.01/v0.02, HASS, multitasking roadmap)
- `wiki/topics/hardware-build-guide.md` — PCB sourcing, BOM, assembly sequence, firmware flashing, first-boot verification
- `wiki/topics/roadmap.md` — planned features, community wishes, design philosophy

---

## [2026-04-18] ingest | picocomputer/adventure (git clone, commit 6ac165f) | new source page

New: `wiki/sources/adventure.md`
Updated: `raw/github/README.md` (added adventure row), `wiki/index.md`, `PROGRESS.md`
Key facts: named ROM asset pattern (DATADIR "ROM:", 4 advent*.txt files), porting pattern for existing C programs, tools/ is identical to vscode-cc65 template, BIG ROM commit (2026-02-26) converted to v0.18 named-asset format

---

## [2026-04-18] ingest | picocomputer/vscode-llvm-mos (git clone, commit 17af418) | new source page; ingest plan deleted

New: `wiki/sources/vscode-llvm-mos.md`
Updated: `wiki/topics/toolchain-setup.md` (llvm-mos section + full cc65 vs llvm-mos comparison table), `wiki/entities/llvm-mos.md` (VSCode setup section added)
Key facts: PATH conflict fix via cmake.environment, CMake kit = [Unspecified], DATA file and RESET file addresses

---

## [2026-04-18] ingest | picocomputer/vscode-cc65 (git clone, commit 794a6f2) | 2 new pages; ingest plan deleted

New: `wiki/sources/vscode-cc65.md`, `wiki/topics/toolchain-setup.md`
Updated: `wiki/entities/cc65.md` (VSCode section rewritten with template details, rp6502.py, toolchain cmake)
Key facts: no pyserial needed since Jan 2026, rp6502_asset() must precede rp6502_executable(), IntelliSense shim in cc65.cmake

---

## [2026-04-18] ingest | picocomputer/pico-extras (git clone, commit 7f48b3f) | new source page; ingest plan deleted

New: `wiki/sources/pico-extras.md`
Updated: `wiki/entities/rp6502-vga.md` (pico-extras dependency section), `wiki/concepts/vga-display-modes.md` (mode-switching note + [[pico-extras]] link)
Key finding: only 2 rumbledethumps commits in fork — memory leak fix + debug printf fix in scanvideo_setup_with_timing()

---

## [2026-04-18] ingest | picocomputer/ehbasic (git clone, commit acd5deb) | 2 new pages; ingest plan deleted

New: `wiki/sources/ehbasic.md`, `wiki/entities/ehbasic.md`
Updated: `wiki/concepts/ria-registers.md` (ACIA simulation section + V_INPT/V_OUTP patterns)
Key finding: no RP6502-specific BASIC extensions — port is pure OS I/O glue

---

## [2026-04-18] ingest | picocomputer/community wiki (commit 348180a) | 3 new/updated pages; ingest plan deleted

New: `wiki/sources/community-wiki.md`, `wiki/topics/usb-compatibility.md`
Updated: `wiki/topics/community-projects.md` (expanded with wiki Home content), `wiki/concepts/gamepad-input.md` (USB compatibility section → [[usb-compatibility]])

---

## [2026-04-18] ingest | picocomputer/examples (git submodule, commit 95965c6) | 9 new pages; all 8 ingest groups complete; plan deleted

New: `wiki/sources/examples.md`, `wiki/concepts/vga-display-modes.md`, `wiki/concepts/vga-graphics.md`, `wiki/concepts/gamepad-input.md`, `wiki/concepts/rtc.md`, `wiki/concepts/nfc.md`, `wiki/concepts/exec-api.md`, `wiki/entities/ezpsg.md`, `wiki/topics/performance.md`
Updated: `wiki/concepts/programmable-sound-generator.md` (ezpsg section), `wiki/concepts/fatfs.md` (directory API)

---

## [2026-04-18] ingest | raw/pdfs/2023-06-07-rp6502.pdf | 2 new pages

New: `wiki/sources/schematic-2023.md`, `wiki/concepts/board-circuits.md`
Key facts: glue logic, VGA DAC, audio filter, IRQ merge, IORQ decode, dual power rail, connector pinouts

---

## [2026-04-18] update | picocomputer.github.io _static/ | rp6502-board + hardware source updated

Updated: `wiki/entities/rp6502-board.md`, `wiki/sources/hardware.md`
Added: Mouser BOM, schematic PDFs, headerless Pico build variant

---

## [2026-04-18] lint | wiki | post-razemos polish

**Re-check**: razemos ingest verified clean — all dates, version numbers, attributions correct.

**Contradictions fixed (2)**:
- `concepts/memory-map.md:63`: "12-channel DMA controller" → "16-channel DMA controller (RP2350; RP2040 had 12)"
- `entities/rp2350.md:63,129`: two occurrences of "12 channels / 12-channel DMA" → "16 channels / 16-channel DMA"

**Data gap filled (1)**:
- Created `wiki/concepts/fatfs.md` — FatFs r0.15+ filesystem driver: FAT32 over USB MSC, ExFAT readiness, open file limits, code-page/short-name interaction, littlefs history
- Linked from `rp6502-os.md`, `development-history.md`, `index.md`

**Cross-refs already present**: `pio-architecture.md` already links `[[hardware-irq]]`; `gpio-pinout.md` already links `[[pio-architecture]]` in footer — no action needed.

---

## [2026-04-18] ingest | rumbledethumps #razemos Discord export | 32 messages, 2026-03-17–2026-04-13

- `wiki/sources/rumbledethumps-discord.md`: Marked #razemos `[x] ingested`; updated summary; added `## #razemos channel` section with razemOS project, release history, architecture notes, OS exec pattern, ROM self-update pattern, keyboard exit convention (ALT-F4/CTRL-ALT-DEL)
- `wiki/topics/community-projects.md`: Expanded voidas_pl section — renamed cc65-rp6502os → razemOS with v0.01/v0.02 release details; added HASS and ctx.py/crx.py entries

---

## [2026-04-18] lint | gpio-pinout | VGA Pico full GPIO map resolved from scanvideo.c

- `wiki/concepts/gpio-pinout.md`: Filled in VGA Pico DAC and sync pins from `src/vga/scanvideo/scanvideo.c` + `scanvideo.h`: R=GPIO 6–10, G=GPIO 12–16, B=GPIO 17–21 (RGB555, `COLOR_PIN_BASE=6`), HSYNC=GPIO 26, VSYNC=GPIO 27 (`SYNC_PIN_BASE=26`); removed "not yet read" note
- `wiki/overview.md`: Open question #5 marked resolved with pin summary
- `PROGRESS.md`: VGA item flipped to ✅; VIA/J1 item updated to note KiCad schematic specifically required

---

## [2026-04-18] lint | wiki | post-discord-chat polish

- `wiki/sources/rumbledethumps-discord.md`: Expanded Scope section from a single bullet into a proper channel table — `#razemos` (32 messages, 2026-03-17–2026-04-13) was in `raw/discord/` but not acknowledged as pending ingestion
- `PROGRESS.md`: Updated `⬜ *(Optional)* Export additional Discord channels` → `👉 Ingest #razemos channel export` with file path and message count (channel is already collected)

---

## [2026-04-18] lint | wiki | post-zaks polish

- `wiki/concepts/6502-programming-idioms.md`: Added missing `## Multi-precision binary addition (Leventhal 1982, Ch. 6)` heading — section was floating after a `---` divider with no heading
- `wiki/concepts/6502-application-snippets.md`: Fixed self-referential link `[[6502-application-snippets]]` → `[[6502-io-patterns]]` in EOR checksum section (CRC-16 lives in io-patterns, not in this page)
- `wiki/overview.md`: Removed duplicate "Interrupt system" bullet — appeared twice (plain and augmented); merged into single consolidated entry
- `wiki/index.md`: Removed dead Inbox entry for deleted Zaks ingest plan (file no longer exists)
- `wiki/concepts/6502-subroutine-conventions.md`: Added missing `### Method 3: Stack (push before JSR)` heading — Method 3 content was present but unlabelled, appearing under Method 4's heading

---

## [2026-04-18] ingest | Zaks — Programming the 6502 (1983) | full ingest complete

**Source**: `raw/pdfs/Programming the 6502 Rodnay Zaks 1983.pdf` (70.6 MB, ~420 pp.)
**Chapters ingested**: II (Hardware/stack/paging), III (Arithmetic/BCD/multiply/divide/subroutines), V (Addressing modes taxonomy), VI (I/O scheduling, polling vs. interrupts), VIII (Application examples), IX (Data structures — Parts I and II)
**Chapters skipped**: I (binary/hex background), IV (instruction set — covered by W65C02S datasheet), VII (6520/6522/6530 I/O devices — not used in RP6502), X (assembler/macro), XI (conclusion), Appendix (exercise answers)

**New pages created:**
- `wiki/sources/zaks-programming-6502.md` — source summary, 15+ unique contributions table, full chapter scope section

**Pages augmented:**
- `wiki/concepts/6502-programming-idioms.md` — Zaks improved 8×8 multiply (10 instr, accumulator = partial product high); subroutine parameter passing 3-method comparison + pointer hybrid guideline
- `wiki/concepts/6502-application-snippets.md` — Zaks Ch.8: memory clear (ZEROM), bracket test (range test via V+C), parity generation (ROL-based), ASCII↔BCD (AND #$0F + BCD-to-binary ×10 hint), find-max, 16-bit sum, EOR checksum, count zeroes
- `wiki/concepts/6502-data-structures.md` — Zaks Ch.9: pointers/directories, linked lists (O(1) insert/delete), circular list (round-robin), queue (FIFO), trees, doubly-linked lists, binary search (O(log₂N)), hashing (XOR+rotate hash, 80% fullness rule), merge algorithm

**Supporting file changes:**
- `wiki/index.md` — zaks-programming-6502 source row added; 3 concept page descriptions updated; inbox entry for Zaks plan marked completed
- `wiki/overview.md` — "6502 programmer's library" intro updated for 4 books; 3 concept bullets revised with Zaks content; hub sources list updated
- `wiki/inbox/zaks-programming-6502-ingest-plan.md` — **deleted** (superseded by source page and this log entry)
- `PROGRESS.md` — Zaks `👉` → `✅`; Discord export promoted to `👉`; wiki size updated to ~95 pages

---

## [2026-04-18] lint | wiki | post-wagner-assembly-lines polish

- `wiki/concepts/6502-subroutine-conventions.md`: added `[[6502-stack-and-subroutines]]` to frontmatter and Related pages footer (missing cross-ref to stack mechanics page)
- `wiki/concepts/6502-interrupt-patterns.md`: added `[[6502-stack-and-subroutines]]` to frontmatter and Related pages footer (ISR entry/exit directly depends on stack mechanics)

---

## [2026-04-18] lint | wiki | post-leventhal-subroutines polish

- `wiki/index.md`: removed duplicate `[[6502-io-patterns]]` entry (appeared twice in Concepts table); added `[[zaks-programming-6502-ingest-plan]]` and `[[wagner-assembly-lines-ingest-plan]]` to Inbox section (were present as files but missing from index)
- `wiki/entities/w65c22s.md`: added `[[6522-via]]` to frontmatter `related`, replaced external WDC datasheet URL with `[[6522-via]]` wikilink, added `[[6522-via]]` to Related pages footer

---

## [2026-04-18] ingest | leventhal-subroutines | Leventhal 1982 Pass 3 (Ch. 4, 5, 8, 9, 10)

- `wiki/concepts/6502-application-snippets.md`: AUGMENTED — Ch. 4 code-conversion section (BN2BCD 133 cycles/38 bytes; BCD2BN 38 cycles/24 bytes; BN2HEX ~77 cycles/31 bytes; HEX2BN ~74 cycles/30 bytes; BN2DEC ~7000 cycles/174 bytes for 16-bit signed→ASCII; DEC2BN ~670 cycles/171 bytes for ASCII decimal→16-bit signed); Ch. 8 string manipulation section (STRCMP with Z/C flag protocol; CONCAT with overflow truncation/Carry; POS substring search with 1-based index); updated frontmatter tags + sources + related
- `wiki/concepts/6502-data-structures.md`: AUGMENTED — Ch. 5 memory operations (MFILL ~11 cycles/byte; BLKMOV with direction-detection for overlapping regions); Ch. 5 multi-dimensional array indexing (D1BYTE 73cy/37B; D1WORD 78cy/39B; D2BYTE ~1500cy/119B; D2WORD; NDIM N-dim Horner evaluation — RP6502 2D framebuffer indexing note included); Ch. 9 array operations (ASUM8 ~16cy/byte + 39 overhead; ASUM16 ~43cy/word + 46 overhead with 24-bit result; BINSCH binary search O(log₂N) iterations; BUBSRT O(N²) stable sort; RAMTST $55/$AA non-destructive RAM test); updated frontmatter tags + sources
- `wiki/concepts/6502-io-patterns.md`: CREATED — new concept page; RDLINE terminal line editor (138B, Control-H/X editing, bell on overflow, three platform-specific subroutine hooks); WRLINE (37B); GEPRTY even-parity generator (114 cycles/39B); CKPRTY parity checker (111 cycles/25B); CRC-16 three entry points (ICRC16/CRC16/GCRC16, IBM BSC polynomial X¹⁶+X¹⁵+X²+1, 302–454 cycles/byte for CRC16); IOHDLR device-independent I/O handler with I/O Control Block (7 bytes) + device table linked list (17 bytes/entry, operations 0–6), INITIO/ADDDL subroutines, 93 + 59×N cycles
- `wiki/sources/leventhal-subroutines.md`: Scope table — Ch. 4, 5, 8, 9, 10 all marked [x] ingested
- `wiki/index.md`: added [[6502-io-patterns]] entry; updated descriptions for 6502-application-snippets and 6502-data-structures
- `wiki/overview.md`: Leventhal 1982 bullets updated with Pass 3 content; 6502-io-patterns added to concepts hub list
- `wiki/inbox/leventhal-subroutines-ingest-plan.md`: Pass 3 chapters [x]; plan file deleted (all passes complete)
- `PROGRESS.md`: Leventhal Subroutines item flipped to ✅; Wagner promoted to 👉; wiki size updated

---

## [2026-04-18] ingest | leventhal-subroutines | Leventhal 1982 Pass 2 (Ch. 6, 7, 11 + App B)

- `wiki/entities/6522-via.md`: CREATED — full 6522 VIA register reference: 16-register table (ORB, ORA, DDRB, DDRA, T1/T2 timers, SR, ACR, PCR, IFR, IER), Port A/B I/O behaviour, T1 continuous/one-shot modes, T2 countdown/pulse-count modes, Shift Register modes (ACR bits 4:2), PCR CA1/CA2/CB1/CB2 control, IFR bit assignments with clear mechanisms, IER enable/disable convention, typical initialisation sequence, Port A vs Port B differences table
- `wiki/concepts/6502-programming-idioms.md`: AUGMENTED — 16-bit arithmetic section (Ch. 6): ADD16 (80 cycles, CLC/ADC chain), SUB16 (80 cycles, SEC/SBC chain), MUL16 (650–1100 cycles, 238 bytes, 32-bit intermediate product, shift-and-add algorithm), DIV16 with 4 entry points (SDIV16/UDIV16/SREM16/UREM16, ~1000–1160 cycles, 293 bytes, shift-and-subtract), CMP16 (~90 cycles, overflow-corrected flags); Bit manipulation section (Ch. 7): BITSET/BITCLR/BITTST (57/57/50 cycles, 16-bit words, mask table lookup), BFE/BFI (bit field extraction/insertion), multi-precision shifts table (logical left/right, arithmetic right, rotate left/right); updated frontmatter tags + related; added [[6522-via]] to related
- `wiki/concepts/6502-interrupt-patterns.md`: AUGMENTED — PINTIO pattern (Ch. 11B): complete 6522 VIA interrupt I/O architecture (6 subroutines: INCH/INST/OUTCH/OUTST/INIT/IOSRVC, 194 bytes, 7 bytes data), IOSRVC ISR code showing IFR bit-1/bit-4 polling, input interrupt auto-clear via VIAADR read (pulses CA2 handshake), OIE unserviced-output-interrupt flag design, INIT configuration template; ring-buffer pattern (Ch. 11C): circular receive/transmit buffers with ISR enqueue + main-loop dequeue, 65C02 PHX/PHY optimisation note; real-time clock/calendar (Ch. 11D): CLKINT ISR cascade chain (tick → seconds → minutes → hours → day → month → year), LASTDY table, leap-year test (YEAR AND $03), clock variable layout (18 bytes), tick-rate configuration, atomic read idiom; updated frontmatter tags + related; added [[6522-via]] to related
- `wiki/sources/leventhal-subroutines.md`: Scope table updated — Ch. 6, 7, 11, App B all marked [x] ingested
- `wiki/index.md`: updated descriptions for 6502-programming-idioms and 6502-interrupt-patterns; 6522-via entity already present
- `wiki/overview.md`: 6502-interrupt-patterns bullet updated with Pass 2 content; 6502-programming-idioms bullet updated with 16-bit arithmetic and bit manipulation; [[6522-via]] added to entities hub list
- `wiki/inbox/leventhal-subroutines-ingest-plan.md`: Pass 2 chapters marked [x]
- `PROGRESS.md`: wiki size updated; Pass 2 progress noted

---

## [2026-04-18] ingest | leventhal-subroutines | Leventhal 1982 Pass 1 (Ch. 1–3 + Intro to Program Section)

- `wiki/sources/leventhal-subroutines.md`: CREATED — source page with Scope table (Ch. 1–3 + Intro ingested; Ch. 4–11 and App B pending; App A/C skipped), key facts, key takeaways
- `wiki/concepts/6502-emulated-instructions.md`: CREATED — comprehensive catalogue of 6502 instruction emulations: add/sub without carry, decimal arithmetic, 16-bit add/sub, 16-bit immediate add, negate, reverse subtract, multiply/divide (cross-ref to idioms), arithmetic shift right, 16-bit shifts, rotate, indirect addressing, autoincrement patterns, interrupt flag save/restore, decimal mode flag save/restore; quick reference table of all missing instructions and their emulations; NMOS JMP page-boundary bug conflict note
- `wiki/concepts/6502-common-errors.md`: CREATED — systematic error guide: Carry misuse (CMP/SBC/ADC conventions, INC/DEC don't affect Carry, 16-bit increment/decrement patterns), flag side effects (STA doesn't set flags, BIT Overflow/Negative side effects, CMP doesn't set Overflow, which instructions affect V/C), addressing confusion (immediate vs. zero-page, indirect alignment, NMOS JMP bug), format errors (hex notation, ASCII↔BCD), array off-by-one, 8-bit index overflow, implicit instruction effects table, initialisation errors (decimal mode, Carry chains, indirect addresses), assembler vs. silent errors, I/O driver errors, ISR errors
- `wiki/concepts/6502-subroutine-conventions.md`: AUGMENTED — added Leventhal 1982 formal 10-field documentation template (Purpose/Procedure/Registers/Execution time/Program size/Data memory/Special cases/Entry/Exit/Examples); added inline-parameter (Method 4) with complete example; added Leventhal 1982 standardised register conventions (1 × 8-bit in A+Y, 1 × 16-bit in A+Y+X, larger in stack); added error convention (Carry=1 on error); updated related section and frontmatter sources
- `wiki/concepts/6502-programming-idioms.md`: AUGMENTED — added "14 6502 quirks quick reference" section from Leventhal 1982 Ch. 1; updated related section; updated frontmatter sources
- `wiki/index.md`: added leventhal-subroutines source entry; added 6502-emulated-instructions and 6502-common-errors concept entries; updated descriptions for 6502-subroutine-conventions and 6502-programming-idioms
- `wiki/inbox/leventhal-subroutines-ingest-plan.md`: Pass 1 chapters marked `[x]` (plan retained — Passes 2 and 3 pending)
- `PROGRESS.md`: wiki size updated; Pass 1 progress noted

---

## [2026-04-18] ingest | leventhal-6502-assembly | Leventhal 2nd Ed. Ch.6-10, 12, 17

- `wiki/sources/leventhal-6502-assembly.md`: CREATED — source page with full Scope table (Ch.1–17), key facts, key takeaways for all ingested chapters (65C02 enhancements, interrupt system, subroutine conventions, string/arithmetic/table idioms)
- `wiki/concepts/6502-interrupt-patterns.md`: CREATED — IRQ/NMI/BRK/RESET vectors, interrupt response sequence, IRQ vs BRK distinguish, register save/restore (PHA/TXA/PHA/TYA/PHA → PLA/TAY/PLA/TAX/PLA), RTI semantics, polling dispatch with 6522 VIA IFR, ISR design guidelines, 65C02 decimal-flag-cleared-on-interrupt improvement, RP6502 context
- `wiki/concepts/6502-subroutine-conventions.md`: CREATED — JSR/RTS off-by-one mechanics, three parameter-passing methods (registers / ZP pseudo-registers / stack), reentrancy requirements, relocatability, subroutine documentation format, 65C02 PHX/PHY improvements, RP6502 XSTACK relationship
- `wiki/concepts/6502-application-snippets.md`: CREATED — ASCII structure, string length, leading-blank skip, leading-zero replace, parity, pattern match; hex↔ASCII conversion (with gap offset explained), BCD-to-7-segment table lookup, BCD unpacking (Ch.6–7)
- `wiki/concepts/6502-programming-idioms.md`: CREATED — multi-precision binary addition (MSB-first, CLC once + loop ADC), multi-precision BCD addition (SED/CLD wrap), 8-bit multiply (shift-and-add, ~250 cycles), 8-bit divide (shift-and-subtract), carry-chain instruction table (Ch.8)
- `wiki/concepts/6502-data-structures.md`: CREATED — add-to-list (with duplicate check), check-ordered-list (backward scan, early exit), circular queue (enqueue/dequeue with wrap), bubble sort (PHA/PLA swap, equal-element safety), jump table pre-65C02 (7 instructions) vs 65C02 `JMP (JTBL,X)` (3 instructions), table lookup patterns (Ch.9)
- `wiki/concepts/65c02-instruction-set.md`: AUGMENTED — added Leventhal Ch.17 section: indirect addressing for arithmetic/logic, `JMP (a,x)` jump tables, bit-manipulation (SMB/RMB/BBS/BBR) examples, BRA, PHX/PHY/PLX/PLY cycle counts, STZ vs LDA#0/STA, INC A/DEC A, TRB/TSB masking patterns, decimal-flag-cleared-on-interrupt fix, JMP indirect page-boundary fix
- `wiki/concepts/hardware-irq.md`: cross-link added → `[[6502-interrupt-patterns]]`
- `wiki/concepts/rp6502-abi.md`: cross-link added → `[[6502-subroutine-conventions]]`
- `wiki/index.md`: added 1 source entry + 7 concept entries (6 new, 1 updated description)
- `wiki/overview.md`: updated — 65C02 programming section expanded; new 6502 programmer's library section
- `wiki/inbox/leventhal-6502-assembly-ingest-plan.md`: DELETED (all planned chapters ingested)
- `PROGRESS.md`: Leventhal ingest flipped 👉 → ✅; wiki size updated

---

## [2026-04-17] ingest | w65c02s-datasheet | full PDF (32 pp., WDC Feb 2024)

- `wiki/sources/w65c02s-datasheet.md`: CREATED — source page with Scope table (Ch.1–7, 10 ingested; Ch.8/9 hard-core/RTL skipped), key facts, NMOS-vs-CMOS caveats summary, pin-function highlights, packages
- `wiki/concepts/65c02-instruction-set.md`: CREATED — all 70 mnemonics (Table 5-1), new CMOS instructions list, new addressing modes per opcode, opcode matrix highlights, reserved-NOP table (Ch.7), flag semantics, RP6502 toolchain notes
- `wiki/concepts/65c02-addressing-modes.md`: CREATED — all 16 modes with cycles/bytes (Table 4-1), per-mode descriptions, new-vs-NMOS summary
- `wiki/entities/w65c02s.md`: expanded from stub — part-number decode (W65C02S6TPG-14), architecture/registers, full pin table, interrupt vector table, VDD-vs-fmax table, WDC enhancements summary; added `[[w65c02s-datasheet]]` and new concept pages to related/sources
- `wiki/index.md`: added 1 source entry + 2 concept entries
- `wiki/overview.md`: added W65C02S to hub pages; updated open-question #1 (WAI/STP) with datasheet-confirmed behavior
- `PROGRESS.md`: W65C02S datasheet flipped 👉 → ✅; wiki size updated

---

## [2026-04-17] ingest | rp2350-datasheet S14 | Appendix C+E: revision history + errata (PDF pp.1354–1376)

- `wiki/topics/known-issues.md`: added full **RP2350 silicon errata** section — all 28 errata (E1–E28) with summaries, affected revisions, and workarounds; grouped into: critical (E12, E5, E8), SIO/interpolator (E1, E2), CPU errata (E6, E7), XIP (E11), OTP (E17), bootrom-fixed (E3, E9, E10, E13–E15, E18–E23), security (E16, E20, E21, E24–E28); updated frontmatter tags/related/sources
- `wiki/sources/rp2350-datasheet.md`: S14 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S14 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S13 | §12.11 HSTX (PDF pp.1202–1211)

- `wiki/concepts/hstx.md`: CREATED — comprehensive HSTX reference: overview, DDR output (300 Mb/s/pin), async FIFO, output shift register, bit crossbar, clock generator, command expander (RAW/TMDS/REPEAT opcodes), PIO-to-HSTX coupled mode, DVI/TMDS example config
- `wiki/entities/rp6502-vga.md`: added `[[hstx]]` to tags/related/related pages section; added `[[rp2350-datasheet]]` to sources
- `wiki/sources/rp2350-datasheet.md`: S13 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S13 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S12 | §12.7 USB (PDF pp.1141–1158)

- `wiki/concepts/usb-controller.md`: added RP2350 Changes section — PHY_ISO startup requirement; RP2350-E12 clk_sys > 48 MHz; DPRAM base address 0x50100000; list of RP2040 USB errata fixed; new features (GPIO DP/DM, NAK-stop); updated `sources:` frontmatter
- `wiki/sources/rp2350-datasheet.md`: S12 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S12 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S11 | §12.6 DMA (PDF pp.1094–1111)

- `wiki/concepts/dma-controller.md`: updated channel count to 16 (RP2350); updated interrupt section — 4 IRQ lines on RP2350 with per-channel independent routing; added INCR_READ_REV/WRITE_REV to address increment section; updated `sources:` frontmatter
- `wiki/sources/rp2350-datasheet.md`: S11 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S11 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S10 | §12.3 SPI (PDF pp.1046–1059)

- `wiki/concepts/rp2040-spi.md`: added RP2350 nSSPOE automatic tristate change note; added peak bit rate at 150 MHz (master 70.5 Mb/s, slave 12.5 Mb/s); updated `sources:` frontmatter
- `wiki/sources/rp2350-datasheet.md`: S10 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S10 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S9 | §12.1 UART (PDF pp.961–971)

- `wiki/concepts/rp2040-uart.md`: confirmed PL011 details match existing page; added RP2350 note — only combined UARTINTR connected; updated `sources:` frontmatter to include `[[rp2350-datasheet]]`
- `wiki/sources/rp2350-datasheet.md`: S9 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S9 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S8 | §11.6 PIO examples (PDF pp.915–938)

- `wiki/concepts/pio-architecture.md`: added `pio_claim_free_sm_and_add_program_for_gpio_range()` to setup section with example and note about RP2350B GPIO range selection
- `wiki/sources/rp2350-datasheet.md`: S8 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S8 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S7 | §11.4.8–11.5 PIO pt.2 (PDF pp.896–914)

- `wiki/concepts/pio-architecture.md`: added GPIO output priority section (highest-numbered SM wins per-cycle); added input synchroniser section (2-flipflop, 2-cycle latency, INPUT_SYNC_BYPASS register, warning for async interfaces)
- `wiki/sources/rp2350-datasheet.md`: S7 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S7 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S6 | §11.1–11.4.6 PIO pt.1 (PDF pp.876–895)

- `wiki/concepts/pio-architecture.md`: expanded v1 ISA additions section with new pioasm directives (.fifo txput/txget/putget, .mov_status irq); added RP2350-specific registers table (DBG_CFGINFO.VERSION, GPIOBASE, CTRL.NEXT_PIO_MASK, IN_COUNT, RXF0_PUTGET0); updated IRQ routing note to mention v1 exposes all 8 flags
- `wiki/sources/rp2350-datasheet.md`: S6 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S6 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S5 | §9.1–9.10 GPIO (PDF pp.587–603)

- `wiki/concepts/gpio-pinout.md`: added RP2350 pad isolation latches section (ISO bit, `gpio_set_function()` auto-clear, power domain relationship); added bus keeper mode section (PDE+PUE simultaneously); added RP2350 interrupt changes (12 outputs, Secure/NS split, summary registers); added VOLTAGE_SELECT section; added GPIO coprocessor port section
- `wiki/sources/rp2350-datasheet.md`: S5 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S5 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S4 | §8.2–8.6 XOSC/ROSC/LPOSC/Tick/PLL (PDF pp.554–583)

- `wiki/concepts/rp2040-clocks.md`: expanded PLL section with full formula and constraints; added XOSC detail section (1–50 MHz range, DORMANT, startup delay); added ROSC detail section (8-stage architecture, A3 randomization change, RNG, COUNT); added LPOSC detail section (trim accuracy, external clock option); added Tick Generators section (TICKS_BASE, 1 µs tick configuration)
- `wiki/sources/rp2350-datasheet.md`: S4 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S4 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S3 | §8.1 Clocks overview (PDF pp.513–528)

- `wiki/concepts/rp2040-clocks.md`: corrected ROSC range (RP2350: 4.6–19.6 MHz), XOSC range (RP2350: 1–50 MHz), LPOSC details (32 kHz, starts in always-on domain, tunable to 1%, AON timer tick); added RP2350 A3 silicon reset change note (CLK_SYS_CTRL AUXSRC default changed); added nominal clock frequency table for RP2350
- `wiki/sources/rp2350-datasheet.md`: S3 → `[x] ingested`
- `wiki/inbox/rp2350-datasheet-ingest-plan.md`: S3 → `[x]`

---

## [2026-04-17] ingest | rp2350-datasheet S2 | §3.1 SIO programmer's model (PDF pp.36–53)

- `wiki/concepts/dual-core-sio.md`: corrected SIO overview table (integer divider absent on RP2350; added TMDS encoder, RISC-V timer, updated FIFO/Doorbell IRQ numbers); added SIO Secure/Non-secure banking note to CPUID section; updated FIFO IRQ numbers (SIO_IRQ_FIFO=25, NS=27); updated Doorbell IRQ numbers (SIO_IRQ_BELL=26, NS=28); added **TMDS encoder** section (DVI 1.0 TMDS encoding, TMDS_CTRL/WDATA/PEEK_SINGLE/POP_SINGLE, security assignment); added **Interpolators** section (INTERP0 blend mode, INTERP1 clamp mode, 3-result outputs, use cases); added **RISC-V platform timer** section (MTIME/MTIMECMP, SIO_IRQ_MTIMECMP); updated RIA connections table
- `wiki/sources/rp2350-datasheet.md`: S2 row → `[x] ingested`

---

## [2026-04-17] ingest | rp2350-datasheet S1 | Ch.1 Introduction + §2.1–2.2 bus fabric/address map (PDF pp.13–34)

- `wiki/entities/rp2350.md`: **created** — RP2350 family table (A/B/4A/4B variants), version history (A0–A4), key feature comparison vs RP2040, architecture overview, SRAM layout (520 KB in 10 banks), atomic register access, full address map table, RP6502 relevance notes
- `wiki/sources/rp2350-datasheet.md`: **created** — source page with full scope table (14 sessions), key facts, wiki pages map, comparison with prior sources
- `wiki/concepts/memory-map.md`: added **RP2350 peripheral address map** section with AHB (DMA, USB, PIO0–2, HSTX FIFO) and APB (CLOCKS, GPIO, XOSC, PLL, UART, SPI, TIMER, HSTX_CTRL, ROSC, TICKS) base addresses; atomic access alias notes; updated frontmatter tags/sources/related
- `wiki/concepts/rp2040-memory.md`: added **RP2350 SRAM** section — 10-bank layout, striping model, non-striped SRAM8–9, power domains, note on RP2040 vs RP2350 striped region differences; updated frontmatter
- `wiki/concepts/gpio-pinout.md`: added **GPIO Bank 1** section — USB DP/DM and QSPI pin function table from datasheet §1.2.4; note that Erratum E9 does not affect Bank 1

---

## [2026-04-17] ingest | pico-c-sdk S14 | §5.2.13 pico_time (PDF pp.412–433)

- `wiki/concepts/rp2040-clocks.md`: replaced brief pico_time section with full reference — `absolute_time_t` type note (SDK 2.0+ defaults to uint64_t; `PICO_OPAQUE_ABSOLUTE_TIME_T=1` for type-checked mode); `at_the_end_of_time`/`nil_time` sentinels; full timestamp API (14 functions); sleep API with WFE/alarm-pool requirement + `best_effort_wfe_or_timeout()`; busy_wait variants; default pool config macros (`PICO_TIME_DEFAULT_ALARM_POOL_DISABLED`, `_HARDWARE_ALARM_NUM=3`, `_MAX_TIMERS=16`); `alarm_callback_t` return-value semantics (<0=reschedule from prev target, >0=reschedule from now, 0=cancel); `alarm_id_t` note; full pool management (create/destroy/query); `alarm_pool_add_alarm_at_force_in_context()`; default-pool convenience wrappers; repeating_timer API with delay sign convention (+ve=gap, -ve=fixed-rate)
- `wiki/sources/pico-c-sdk.md`: S14 row → `[x] ingested — S14`
- `wiki/inbox/pico-c-sdk-ingest-plan.md`: all 14 sessions `[x]` — **plan file deleted**

---

## [2026-04-17] ingest | pico-c-sdk S13 | §5.2.7 pico_multicore + §5.2.12 pico_sync (PDF pp.397–412)

- `wiki/concepts/dual-core-sio.md`: corrected core-launch section (removed non-existent `_with_config`, added `multicore_launch_core1_with_stack` + `multicore_launch_core1_raw` with full signatures); expanded FIFO section (RP2350 depth=4 vs RP2040 depth=8, SDK "precious resource" caution, full 11-function FIFO table incl. `rvalid/wready/clear_irq/get_status`, `SIO_FIFO_IRQ_NUM(core)` macro); added **Doorbell API** section (RP2350-only, 9 functions + `DOORBELL_IRQ_NUM` macro); added **Lockout API** section (7 functions); expanded pico_sync into full reference: `critical_section` (5 functions incl. `_with_lock_num`, `_deinit`, `_is_initialized`), `lock_core` internal model, `mutex` full API (12 functions + `auto_init_mutex`), `recursive_mutex` full API (8 functions + `auto_init_recursive_mutex`), `semaphore` full API (9 functions); updated RIA connections table (`SIO_FIFO_IRQ_NUM` replaces old RP2040-specific IRQ names)
- `wiki/sources/pico-c-sdk.md`: S13 row → `[x] ingested — S13`
- `wiki/inbox/pico-c-sdk-ingest-plan.md`: S13 checkbox → `[x]` (S14 still `[ ]`)

---

## [2026-04-17] ingest | pico-c-sdk S12 | §5.1.29 hardware_timer + §5.1.30 hardware_uart (PDF pp.349–397)

- `wiki/concepts/rp2040-clocks.md`: expanded Timer section — RP2350 two-timer architecture (TIMER0/TIMER1), updated timebase notes, full `hardware_alarm_callback_t` typedef, expanded default-timer wrappers table (5 new functions: `hardware_alarm_claim_unused`, `hardware_alarm_unclaim`, `hardware_alarm_is_claimed`, `hardware_alarm_force_irq`, `hardware_alarm_get_irq_num`), compile-time macros table (`TIMER_ALARM_IRQ_NUM`, `TIMER_ALARM_NUM_FROM_IRQ`, `TIMER_NUM_FROM_IRQ`, `PICO_DEFAULT_TIMER`, `PICO_DEFAULT_TIMER_INSTANCE`), full RP2350 multi-instance `timer_*` API table (21 functions)
- `wiki/concepts/rp2040-uart.md`: added `uart_deinit`, `uart_is_enabled`, `uart_get_index`, `uart_get_instance`, `uart_get_hw`, `uart_get_reset_num`, corrected `uart_set_irqs_enabled` (was `uart_set_irq_enables`), corrected `uart_get_dreq_num` (was `uart_get_dreq`); added compile-time macros table (7 macros: `UART_NUM`, `UART_INSTANCE`, `UART_DREQ_NUM`, `UART_CLOCK_NUM`, `UART_FUNCSEL_NUM`, `UART_IRQ_NUM`, `UART_RESET_NUM`); added `uart_init` GPIO setup pattern; added pause-duration warnings for format/baud/FIFO changes; updated sources to include `pico-c-sdk`
- `wiki/sources/pico-c-sdk.md`: S12 row → `[x] ingested — S12`
- `wiki/inbox/pico-c-sdk-ingest-plan.md`: S12 checkbox → `[x]`

---

## [2026-04-17] ingest | pico-c-sdk S11 | §5.1.25 hardware_spi + §5.1.27 hardware_sync (PDF pp.329–349)

- `wiki/concepts/rp2040-spi.md`: added `spi_deinit`, `spi_get_baudrate`, `spi_get_index` to SDK table; added DMA compile-time macros table (`SPI_DREQ_NUM`, `SPI_NUM`, `SPI_INSTANCE`); updated sources to include `pico-c-sdk`
- `wiki/concepts/dual-core-sio.md`: expanded hardware spinlocks section — spinlock number assignment table (0-13/14-15/16-23/24-31 ranges), RP2350-E2 erratum note, full `hardware_sync` spinlock SDK API table (14 functions); added memory barrier section (`__dmb`/`__dsb`/`__isb`/`__mem_fence_acquire`/`__mem_fence_release`); added processor events section (`__sev`/`__wfe`/`__wfi`/`__nop`); added interrupt control section (`save_and_disable_interrupts`/`restore_interrupts`/`restore_interrupts_from_disabled`)
- `wiki/sources/pico-c-sdk.md`: S11 row → `[x] ingested — S11`
- `wiki/inbox/pico-c-sdk-ingest-plan.md`: S11 checkbox → `[x]`

---

## [2026-04-17] ingest | pico-c-sdk S10 | §5.1.16 hardware_pio end + §5.1.17 hardware_pll (PDF pp.254–264)

- `wiki/concepts/pio-architecture.md`: expanded `pio_encode_*` section — composition helpers (`pio_encode_delay`/`sideset`/`sideset_opt` return ORable bits, not instructions), complete JMP variant table (8 variants), `wait_pin` vs `wait_gpio` addressing distinction, `pio_src_dest` enum reference table
- `wiki/concepts/rp2040-clocks.md`: added `hardware_pll` SDK functions section — `pll_init`, `pll_deinit`, `PLL_RESET_NUM` macro, `pll_sys`/`pll_usb` handles; caution re `pll_deinit` not checking if PLL is in use
- `wiki/sources/pico-c-sdk.md`: S10 row → `[x] ingested — S10`
- `wiki/inbox/pico-c-sdk-ingest-plan.md`: S10 checkbox → `[x]`

---

## [2026-04-17] ingest | pico-c-sdk S9 | §5.1.16 hardware_pio pt.2 (PDF pp.236–254)

Updated `wiki/concepts/pio-architecture.md`. No new pages created.

**New content:**
1. **Multi-SM synchronization** — `pio_enable_sm_mask_in_sync` (atomic enable + clock-divider restart); `pio_clkdiv_restart_sm_mask`; `pio_restart_sm_mask`; `pio_set_sm_mask_enabled`; `pio_claim_sm_mask`. Note: disabling a SM does not halt its clock divider — use clkdiv_restart on re-enable if timing precision matters.
2. **`pio_sm_drain_tx_fifo`** — empties TX FIFO via `pull` instructions (disturbs OSR); contrast with `pio_sm_clear_fifos` (discards FIFO without touching SM registers).
3. **Sticky output** (`sm_config_set_out_special`) — re-asserts last OUT/SET value on idle cycles; auxiliary enable pin option.
4. **IN pin masking** (`sm_config_set_in_pin_count`) — RP2350 feature to mask unused IN pins to zero; RP2040 always reads 32 bits.
5. **Default SM config table** — all `pio_get_default_sm_config` defaults documented; warning about `wrap=31` default.
6. **RP2350B GPIO base** — `pio_set_gpio_base(pio, 0|16)` for 48-pin RP2350B; 64-bit pin variants (`pio_sm_set_pindirs_with_mask64`, etc.).

---

## [2026-04-17] ingest | pico-c-sdk S8 | §5.1.15 hardware_irq + §5.1.16 hardware_pio pt.1 (PDF pp.216–236)

Created `wiki/concepts/hardware-irq.md` (new page). Updated `wiki/concepts/pio-architecture.md`.

**New content:**
1. **hardware-irq.md (new)** — NVIC per-core architecture; IRQ number tables for RP2040 (0–25) and RP2350 (0–51); three handler installation patterns (`irq_set_exclusive_handler`, `irq_add_shared_handler`, static symbol); full API function table; priority model (0–255 inverted, default 0x80; RP2040 top 2 bits, RP2350 top 4 bits); shared `order_priority` (higher = called first, opposite of IRQ priority); vector table dual-core caveat; user IRQs (`irq_set_pending`, core-local, claim/unclaim); `irq_clear` hardware-IRQ limitation.
2. **pio-architecture.md** — added `pio_interrupt_source` enum table (pis_interrupt0-3, pis_smN_tx_fifo_not_full, pis_smN_rx_fifo_not_empty); `pio_set_irqn_source_enabled` generic variant; `pio_mov_status_type` enum (STATUS_TX_LESSTHAN, STATUS_RX_LESSTHAN); compile-time macros section (PIO_NUM, PIO_INSTANCE, PIO_FUNCSEL_NUM, PIO_DREQ_NUM, PIO_IRQ_NUM); added [[hardware-irq]] to related pages.

---

## [2026-04-17] ingest | pico-c-sdk S7 | §5.1.11 hardware_gpio pt.2 (PDF pp.170–186)

Updated `wiki/concepts/gpio-pinout.md` with SDK-authoritative content. No new pages created.

**New content / corrections to gpio-pinout.md:**
1. **`gpio_put_masked()` correction** — wiki incorrectly stated "not atomic". SDK confirms it uses hardware TOGL alias and IS concurrency-safe with IRQ on the same core; only unsafe for two-core simultaneous access.
2. **Speed benchmark table corrected** — `gpio_put_masked` entry updated to reflect TOGL alias behavior.
3. **`gpio_set_irq_enabled_with_callback` decomposition** — SDK explicit equivalence: `gpio_set_irq_enabled` + `gpio_set_irq_callback` + `irq_set_enabled(IO_IRQ_BANK0, true)`.
4. **Pull-state query functions** — added `gpio_is_pulled_up()`, `gpio_is_pulled_down()`, `gpio_disable_pulls()`, `gpio_pull_up()`, `gpio_pull_down()`, `gpio_set_pulls()` to basic API section.
5. **PAD config functions** — consolidated `gpio_set_drive_strength`, `gpio_get_drive_strength`, `gpio_set_slew_rate`, `gpio_get_slew_rate`, `gpio_set_input_hysteresis_enabled`, `gpio_is_input_hysteresis_enabled` into basic API section.
6. **Hysteresis note** — disabling Schmitt trigger slightly reduces input delay but risks inconsistent readings for slow-rising signals.
7. **`gpio_remove_raw_irq_handler_masked` same-mask requirement** — must use same `gpio_mask` as when adding the handler.
8. **`gpio_set_irqover`** — added to GPIO overrides section (can invert/force IRQ signal).
9. **`gpio_is_dir_out`** — clarified description in basic API.

---

## [2026-04-17] ingest | pico-c-sdk S6 | §5.1.11 hardware_gpio pt.1 (PDF pp.155–170)

Updated `wiki/concepts/gpio-pinout.md` with SDK-authoritative content. No new pages created; existing page substantially expanded.

**New content added to gpio-pinout.md:**
1. **RP2350 package variants** — QFN-60 (RP2350A, 30 GPIO, ADC26–29) vs QFN-80 (RP2350B, 48 GPIO GPIO0–47, ADC40–47); updated GPIO structure table.
2. **RP2350 function select enum** — `GPIO_FUNC_HSTX=0` (GPIO12–19), `GPIO_FUNC_PIO2=8`, `GPIO_FUNC_XIP_CS1=9`, `GPIO_FUNC_CORESIGHT_TRACE=9`, `GPIO_FUNC_UART_AUX=11`; expanded function select table with RP2040/RP2350 columns.
3. **HSTX on GPIO12–19** — High-Speed Serial Transmit function (display interfaces); RP2350 only.
4. **64-bit API variants** — `gpio_get_all64()`, `gpio_set_mask64()`, `gpio_clr_mask64()`, `gpio_xor_mask64()`, `gpio_put_masked64()`, `gpio_put_all64()`, plus direction variants `64`; for RP2350 QFN-80.
5. **Bank-n API variants** — `gpio_set_mask_n(n, mask)`, `gpio_clr_mask_n()`, `gpio_xor_mask_n()`, `gpio_put_masked_n()`; operate on 32-bit GPIO bank indexed by n.
6. **`gpio_set_function_masked()`/`gpio_set_function_masked64()`** — set function for multiple pins at once.
7. **`gpio_deinit()`** — reset to NULL function (disables pin to high-Z).
8. **`gpio_get_out_level()`** — returns current driven output state (vs `gpio_get()` which reads input).
9. **`gpio_set_dormant_irq_enabled()`** — enable dormant mode wake-up interrupt.
10. **`gpio_set_irq_callback()`** — set per-core callback without affecting enable state (separates from `gpio_set_irq_enabled_with_callback()`).
11. **Order-priority raw handler variants** — `gpio_add_raw_irq_handler_with_order_priority[_masked][64]()`.
12. **`gpio_remove_raw_irq_handler*()` variants** — clean up raw handler registrations.
13. **IRQ latch behavior** — level events not latched; edge events stored in INTR register, must be cleared.

---

## [2026-04-17] ingest | pico-c-sdk S5 | §5.1.8 hardware_dma (PDF pp.122–147)

Updated `wiki/concepts/dma-controller.md` with SDK-authoritative content. No new pages created; existing page substantially expanded.

**New content added to dma-controller.md:**
1. **RP2350 DREQ table** — 55 sources vs RP2040's 40; PIO2 adds DREQ 16–23 (shifts all RP2040 non-PIO DREQs up by 8); new entries: HSTX (52), CORESIGHT (53), SHA256 (54); XIP_QMITX/QMIRX replace XIP_SSITX/SSIRX; RP2350 has 12 PWM slices (WRAP0–11) vs 8 on RP2040.
2. **RP2350 encoded_transfer_count** — only 28-bit count on RP2350 (top 4 bits = options); use `dma_encode_transfer_count()`, `dma_encode_transfer_count_with_self_trigger()`, `dma_encode_endless_transfer_count()` for portability.
3. **Self-triggering DMA (RP2350 only)** — `dma_encode_transfer_count_with_self_trigger()`: channel automatically re-triggers itself on completion.
4. **Endless DMA (RP2350 only)** — `dma_encode_endless_transfer_count()`: continuous non-terminating transfer; not supported on RP2040.
5. **Errata IDs** — RP2040-E13 (abort spurious IRQ) and RP2350-E5 (must clear enable bit of aborted+chained channels before abort) documented with names.
6. **New functions** — `dma_channel_cleanup()`, `dma_channel_wait_for_finish_blocking()`, `dma_channel_is_busy()`, `dma_unclaim_mask()`, `dma_channel_set_config()`, `dma_sniffer_get/set_data_accumulator()`, `dma_sniffer_set_output_invert/reverse_enabled()`, `dma_timer_claim/unclaim/is_claimed()`, `dma_get_irq_num()`, `dma_irqn_set_channel_mask_enabled()`, `dma_set_irq0/1_channel_mask_enabled()`, `channel_config_set_read/write_address_update_type()`, `channel_config_get_ctrl_value()`, `dma_get_channel_config()`.
7. **chain_to = self to disable**, **high-priority scheduling detail** (all high-prio run before one low-prio per round; bus priority unchanged), **bswap note** (no effect on bytes; swaps bytes within halfwords/words; bswap + sniffer byte swap cancel for sniffer).
8. **Updated frontmatter** — added `[[pico-c-sdk]]` to sources; added `rp2350`, `pio2`, `errata` to tags.

---

## [2026-04-17] ingest | pico-c-sdk S4 | §5.1.5 hardware_clocks (PDF pp.95–112)

Updated `wiki/concepts/rp2040-clocks.md` with SDK-authoritative content. No new pages created; existing page substantially expanded.

**New content added to rp2040-clocks.md:**
1. **LPOSC source (RP2350 only)** — Low Power Oscillator ~32 kHz; can feed clk_ref on RP2350. Added to sources table.
2. **PLL parameter model** — VCO freq, post_div1, post_div2 explained; formula `output = vco_freq / (post_div1 × post_div2)`; example: 256 MHz = 1536 MHz VCO / (3 × 2).
3. **RP2350 clock domain differences** — `clk_rtc` removed; `clk_hstx` added; LPOSC available for clk_ref; divisor range 1.0→65536.0 in 1/65536 steps (vs RP2040: 1/256 steps, max 16777216).
4. **GPOUT GPIO differences** — RP2350 adds GPIO 13 (GPOUT0) and GPIO 15 (GPOUT1); RP2040 only had 21/23/24/25.
5. **New SDK functions** — `clock_configure_undivided()`, `clock_configure_int_divider()`, `clock_gpio_init_int_frac16()`, `clock_gpio_init_int_frac8()`, `set_sys_clock_48mhz()`, `set_sys_clock_pll()`, `set_sys_clock_hz()`, `set_sys_clock_khz()`, `check_sys_clock_hz()`, `check_sys_clock_khz()`, `clocks_enable_resus()`, `gpio_to_gpout_clock_handle()`.
6. **Resus feature** — `clocks_enable_resus(callback)` auto-restarts clk_sys from clk_ref when it stalls; invokes user callback; safety net for PLL experiments.
7. **Sources frontmatter** — added `[[pico-c-sdk]]` to sources; added `lposc`, `hstx` to tags.

---

## [2026-04-17] ingest | pico-c-sdk S3 | Ch.3 §§3.3–3.4 PIOASM + PIO ISA (PDF pp.54–78)

Created `wiki/concepts/pioasm.md` (new page). Updated `wiki/concepts/pio-architecture.md` with v1 ISA additions.

**pioasm.md** covers §3.3 in full:
1. **Tool overview** — output formats (c-sdk/python/hex), `-v` version flag, CMake `pico_generate_pio_header` integration.
2. **Directives** — complete table: `.program`, `.pio_version`, `.origin`, `.side_set`, `.wrap`/`.wrap_target`, `.define PUBLIC`, `.clock_div`, `.fifo`, `.mov_status`, `.in`/`.out`/`.set`, `.lang_opt`, `.word`.
3. **`.fifo` extended modes (v1 only)** — `txput`/`txget`/`putget` repurpose RX FIFO as random-access status registers; both SM and Cortex can read/write independently.
4. **Values and expressions** — integer/hex/binary/symbol/label; full arithmetic + bit-reverse `::` operator.
5. **`nop` pseudoinstruction** — expands to `mov y, y`.
6. **Output pass-through** — `% c-sdk { ... %}` embeds C init code directly in generated header; makes `.pio` files fully self-contained.
7. **Generated header structure** — instruction array, `pio_program` struct, `get_default_config()` factory, pass-through functions.
8. **v0/v1 opcode table** — all 8 opcodes with 3-bit encoding and v1 additions column.

**pio-architecture.md** additions from §3.4:
- PULL noblock → copies X to OSR (default value pattern for continuous-clock protocols like I2S).
- STATUS source in MOV → controlled by `EXECCTRL_STATUS_SEL`; all-ones/zeros based on TX/RX FIFO fullness.
- Delay timing rule: delay cycles on stalling instructions don't start until the wait condition clears.
- v1 ISA additions section: MOV PINDIRS destination; `MOV rxfifo[y/idx], isr`; `MOV osr, rxfifo[y/idx]`; WAIT JMPPIN; IRQ PREV/NEXT; all 8 IRQ flags assertable on v1.
- Cross-reference link to `[[pioasm]]` added to ISA section and related pages.

---



Updated `wiki/concepts/pio-architecture.md` — added six new SDK subsections under "SDK Programming Patterns":

1. **FIFO joining** — `sm_config_set_fifo_join()` with `PIO_FIFO_JOIN_TX` / `_RX` / `_NONE`; when to use each; doubled-depth latency benefit.
2. **State machine cleanup and restart** — `pio_sm_set_enabled`, `pio_sm_clear_fifos`, `pio_sm_restart`; importance of clearing ISR shift counter.
3. **Dynamic program generation** — `pio_encode_*` helpers (all opcodes covered); `struct pio_program` with `origin = -1`; equivalent to pioasm output.
4. **SM EXEC — one-shot instruction injection** — `pio_sm_exec`; stall-and-latch behaviour for trigger-armed captures; `out exec` and `mov exec` paths.
5. **DMA integration with PIO** — full RX drain pattern with DREQ (`pio_get_dreq`), `dma_channel_configure`, `dma_channel_wait_for_finish_blocking`; TX feed inversion; bus priority register for high-bandwidth use.
6. **Program claiming helpers** — `pio_claim_free_sm_and_add_program_for_gpio_range`; `pio_remove_program_and_unclaim_sm`; necessity of `_for_gpio_range` on RP2350.

Also updated `pico-c-sdk.md` Scope table (S2 → `[x]`), `pico-c-sdk-ingest-plan.md` (S2 → `[x]`), frontmatter `sources:` and `related:` in `pio-architecture.md`.

Key findings: §3.1 confirms PIO was designed precisely for the sub-1/1000-of-clock-speed I/O problem the RIA faces with the 65C02 bus. The DMA-DREQ pattern (§3.2.3 logic analyser) is the exact mechanism used in the RIA for zero-CPU-overhead bus data capture. `pio_sm_exec` + `pio_encode_wait_gpio` is the authoritative way to arm a PIO SM on a hardware trigger without pre-flooding the FIFO.



Created `wiki/sources/pico-c-sdk.md` (source summary with full 14-session scope table). Created `wiki/concepts/sdk-architecture.md` covering: CMake INTERFACE library model, library naming tiers (`hardware_` vs `pico_`), hardware structs and atomic register aliases, hardware claiming, builder pattern for peripheral config, function naming conventions, error handling, directory/platform split (RP2040 vs RP2350), multi-core model, runtime, floating point, and board customisation. Updated `rp6502-ria.md` and `rp6502-vga.md` to reference `pico-c-sdk` and `sdk-architecture`. Updated `index.md`, `overview.md`.

Key finding: ingest plan incorrectly stated "RIA uses RP2040" — both RIA and VGA run on **RP2350** (Pi Pico 2). The `rp2350-arm-s` platform applies to both firmwares. This is now correctly reflected in `sdk-architecture.md` and `pico-c-sdk.md`.

---

## [2026-04-17] lint | full wiki audit | 8 fixes across 5 files

Full lint pass across all 40 wiki pages, cross-checked against raw firmware source (api.h, cpu.h, ria.h, mem.h, main.c, sys.c, ria.c). Findings and fixes:

1. **gpio-pinout.md**: corrected total GPIO current budget from 30 mA to **50 mA** (RP2040 datasheet value; wiki log from Quadros ingest already noted 50 mA).
2. **rp2040-clocks.md**: removed erroneous "(SD card)" from SPI reference — RIA uses USB MSC for storage, not SPI. Same error was caught in other pages in prior lint passes but missed here.
3. **rp2040-clocks.md**: changed watchdog from speculative "Likely used" to **confirmed** — grep found `RIA_WATCHDOG_MS=250` in ria.c, `watchdog_reboot()` in sys.c, VGA watchdog timers in vga.c.
4. **fairhead-pico-c.md**: added `[[rp2040-spi]]`, `[[rp2040-uart]]`, `[[rp2040-clocks]]` to frontmatter `related:` field (concept pages already cited Fairhead as source but source page didn't backlink).
5. **fairhead-pico-c.md**: added missing Key facts sections for Ch.17 (SIO, NVIC, hardware divider, interpolator) and Ch.18 (multicore launch, FIFOs, spinlocks, FreeRTOS). Updated Related pages list.
6. **pio-architecture.md**: removed duplicate `---` separators (2 instances).
7. **gpio-pinout.md**: removed duplicate `---` separator.
8. **xram.md**: updated stale date from 2026-04-15 to 2026-04-16.

**Data gaps carried forward** (unresolvable without new sources):
- cc65 / llvm-mos entity pages — both toolchains referenced but no dedicated wiki pages yet.
- VGA full GPIO pinout — only GPIO 0–3 (PIX in) and GPIO 11 (PHI2 in) confirmed; DAC/sync pins need VGA source or schematic.
- VIA pinout / J1 GPIO header — needs schematic PDF.

**Confirmed correct** (spot-checked against raw source):
- All register addresses ($FFE0–$FFFF), GPIO pin assignments, API op-code dispatch table (0x01–0x2E), XSTACK_SIZE=512, MBUF_SIZE=1024, overclock settings (256 MHz / 1.15V), PIO state machine assignments — all match wiki.

---

## [2026-04-16] ingest | Fairhead Ch.15 – The Serial Port | stdio layer and small-buffer stall warning added to rp2040-uart

- Updated `wiki/concepts/rp2040-uart.md` — added "## stdio Layer" section (stdio_init_all, stdio_uart_init_full, defaults, printf/snprintf), "## Small Buffer Warning" section with char-by-char relay pattern.
- Updated `wiki/sources/fairhead-pico-c.md` — marked Ch.15 `[x]`, added key facts section.
- Updated `wiki/inbox/fairhead-pico-c-ingest-plan.md` — marked Ch.15 `[x]` (final chapter; plan file then deleted).
- Deleted `wiki/inbox/fairhead-pico-c-ingest-plan.md` — all chapters ingested.
- Updated `wiki/index.md` — removed ingest-plan entry; updated fairhead-pico-c description to "all planned chapters ingested".
- Updated `wiki/overview.md` — added `[[fairhead-pico-c]]` to sources hub.

---

## [2026-04-16] ingest | Fairhead Ch.9 – Getting Started With The SPI Bus | CS timing quirk added to rp2040-spi

- Updated `wiki/concepts/rp2040-spi.md` — added "## CS Timing Quirk" section (0.7 µs pre-deassert hazard, half-period delay fix); added `[[fairhead-pico-c]]` to sources.
- Updated `wiki/sources/fairhead-pico-c.md` — marked Ch.9 `[x]`, added key facts section (note: RIA uses USB MSC, not SPI, for storage).

---

## [2026-04-16] ingest | Fairhead Ch.18 – Multicore and FreeRTOS | race conditions and FreeRTOS model added to dual-core-sio

- Updated `wiki/concepts/dual-core-sio.md` — added "Race conditions and memory atomicity" section (tearing, update loss, 32-bit atomicity table), "FreeRTOS SMP overview" section (task model, why RIA avoids RTOS, WiFi+FreeRTOS integration notes, synchronization comparison table, xQueue producer-consumer pattern).
- Updated `wiki/sources/fairhead-pico-c.md` — marked Ch.18 `[x]`.

---

## [2026-04-16] ingest | Fairhead Ch.17 – Direct To The Hardware | SIO GPIO registers and GPIO coprocessor added to dual-core-sio

- Updated `wiki/concepts/dual-core-sio.md` — added SIO GPIO register offset table (Pico vs Pico 2 diff), SIO speed benchmark (4 ns at 50 MHz), GPIO coprocessor (RP2350 inline asm), GPIO event register format (4 bits per GPIO), per-core IRQ control register.
- Updated `wiki/sources/fairhead-pico-c.md` — marked Ch.17 `[x]`.

---

## [2026-04-16] ingest | Fairhead Ch.13 – DHT22 Custom Protocol | PIO design patterns added to pio-architecture

- Updated `wiki/concepts/pio-architecture.md` — added "Custom protocol design patterns" subsection: sampling vs counting, parameterized PIO startup via TX FIFO, bidirectional/open-collector pin pattern, `jmp pin` usage.
- Updated `wiki/sources/fairhead-pico-c.md` — added Ch.13 key facts section; marked `[x]` ingested.
- Marked Ch.13 `[x]` in ingestion plan.

---

## [2026-04-16] ingest | Fairhead "Programming the Raspberry Pi Pico/W in C" Ch.12 | new source page + SDK patterns added to pio-architecture

- Created `wiki/sources/fairhead-pico-c.md` — source summary for the Fairhead book (417 pages, 11 chapters planned for ingest).
- Updated `wiki/concepts/pio-architecture.md` — added "SDK Programming Patterns" section: standard setup sequence, GPIO group config functions, clock divider (with jitter warning), TX/RX FIFO and OSR/ISR API, edge detection pattern (45 ns latency at max clock), SIDESET directive, CMake integration.
- Updated `wiki/index.md` — added `[[fairhead-pico-c]]` to Sources table.
- Marked Ch.12 `[x]` in ingestion plan.

---

## [2026-04-16] lint | full audit against all raw sources | 4 fixes

Cross-checked all wiki pages against 3 raw source types (6 web docs, github repo at v0.23, Quadros PDF).

Fixes:
- [[ria-registers]]: filled in register map `$FFE0–$FFEB` (UART TX/RX/status, RIA_RW0/RW1, STEP0/STEP1, ADDR0/ADDR1) — previously marked "not assigned". Removed stale "Data gap" section. Fixed XSTACK push instruction (was `RIA_RW0` → now `RIA_XSTACK` at `$FFEC`).
- [[rp6502-abi]]: corrected "7-byte stub" → "8-byte stub" (`$FFF0–$FFF7` = 8 bytes).
- [[dma-controller]]: corrected `DREQ_PWM_WRAP8` → `DREQ_PWM_WRAP7` (Quadros book typo on page 44; RP2040 has PWM slices 0–7). Added `> **Conflict:**` note citing the book error.

Everything else verified correct: op-code table, PIX bus protocol, memory map, VGA modes, ABI rules, PIO layout, GPIO pinout, reset model, all Quadros-derived concept pages.

---

## [2026-04-16] lint | full wiki | second lint pass (9 sources, 40 pages)

Scope: all 40 wiki pages (9 sources, 7 entities, 18 concepts, 2 topics, 1 inbox, overview, index, log).

**Contradictions fixed (2):**
- `dma-controller.md`: removed false claim that SPI DMA paces SD card transfers (RIA uses USB MSC, not SPI).
- `gpio-pinout.md`: corrected `GPIO_FUNC_SPI` note from "SD card on RIA" to "not used by current RIA firmware."

**Stale content fixed (3):**
- `overview.md`: removed resolved open question #5 (tel.c/telnet — resolved in first lint) and stale #7 (release notes — already ingested).
- `quadros-rp2040.md`: updated frontmatter from "clock chapter ingest" to "all chapters ingested."

**Typos fixed (1):**
- `usb-controller.md` frontmatter: `[[pia-registers]]` → `[[ria-registers]]`.

**Wrong link target fixed (1):**
- `dual-core-sio.md`: "see [[reset-model]] for NVIC IRQ table" → [[quadros-rp2040]] (where the table actually lives).

**Missing cross-references fixed (2):**
- `quadros-rp2040.md`: added [[rp2040-clocks]], [[rp2040-uart]], [[rp2040-spi]] to frontmatter and related pages.
- `overview.md` hub: added 6 missing concept pages and [[quadros-rp2040]] source to hub lists.

**Data gaps (2, carried forward):**
- `[[cc65]]` entity page still missing — referenced in 6+ pages. Deferred until toolchain source available.
- `[[llvm-mos]]` entity page still missing — referenced in 4+ pages. Deferred.

Pages modified (6): dma-controller.md, gpio-pinout.md, overview.md, quadros-rp2040.md, usb-controller.md, dual-core-sio.md.

Also fixed: log.md formatting — 5 recent entries reformatted from single-line headings to heading + body style.

---

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Communication Using SPI (PDF 184–193) — FINAL CHAPTER

New page: [[rp2040-spi]] (SPI basics, CPOL/CPHA modes, 8-entry FIFOs, two-stage clock divider from clk_peri, manual SS in master mode, GPIO pin tables, full SDK API; correction: RIA uses USB MSC not SPI for storage). Updated: [[quadros-rp2040]] scope + SPI facts section, [[index]] (all chapters ingested), [[overview]]. Deleted ingest plan from wiki/inbox — all chapters complete.

---

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Asynchronous Serial Communication: the UARTs (PDF 172–183)

New page: [[rp2040-uart]] (framing, TX/RX FIFOs + error flags, fractional baud rate from clk_peri, 5 interrupt sources, RTS/CTS flow control, GPIO pin options, full SDK API, RIA UART1/GPIO4-5/115200 8N1). Updated: [[quadros-rp2040]] scope + UART facts section, [[index]] (9/10 chapters done), ingest plan.

---

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Clock Generation, Timer, Watchdog and RTC (PDF 68–88)

New page: [[rp2040-clocks]] (ROSC/XOSC/PLLs, 10 clock domains, mux architecture, 256 MHz System PLL overclock, 64-bit Timer + alarm pools + pico_time, Watchdog + scratch registers, RTC + repeating alarm). Updated: [[quadros-rp2040]] scope + clock facts section, [[index]], ingest plan (8/10 chapters done).

---

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — USB Controller (PDF 200–232)

New pages: [[usb-controller]] (USB 1.1 PHY, TinyUSB host/device API, HID boot protocol keyboard/mouse/gamepad, CDC VCP, RP6502-RIA USB host usage table). Updated: [[quadros-rp2040]] scope + USB key facts section, [[rp6502-ria]] related links, [[index]], [[overview]].

---

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Memory, Addresses and DMA (PDF 42–67)

New pages: [[rp2040-memory]] (ROM/SRAM banking/Flash/XIP/full address map), [[dma-controller]] (12 channels, DREQ table, control blocks, chaining, CRC sniffing, SDK API). Updated: [[xram]] (DMA section added), [[quadros-rp2040]] scope, [[index]].

---

## [2026-04-16] setup | Git: `picocomputer/rp6502` as submodule | vendored tree → submodule at v0.23

Replaced the vendored copy under `raw/github/picocomputer/rp6502/` with a **Git submodule** pointing at [picocomputer/rp6502](https://github.com/picocomputer/rp6502), checked out at tag **v0.23** (commit `368ed8e`, same pin as before). Added root `.gitmodules`; nested upstream submodules (`src/littlefs`, `src/tinyusb`) initialized locally. Updated `raw/README.md` with clone (`--recurse-submodules` / `git submodule update --init --recursive`) and bump instructions for future releases.

---

## [2026-04-16] ingest | Knowing the RP2040 (Quadros) — session 4 | Cortex-M0+ Processor Cores chapter

Chapter ingested: The Cortex-M0+ Processor Cores (PDF 13–26).

Pages created (1):
- `wiki/concepts/dual-core-sio.md` — new concept page: SIO architecture, inter-processor FIFOs, hardware spinlocks, atomic GPIO SET/CLR/XOR, `pico_multicore` SDK table, `pico_sync` primitives (critical section, mutex, semaphore), RIA firmware connections table

Pages updated (3):
- `wiki/sources/quadros-rp2040.md` — added "### Cortex-M0+ core features" (RIA-relevant subset: PRIMASK, SysTick, WFI/WFE, RP2350 note) and "### SIO" section (CPUID, FIFOs, spinlocks, atomic GPIO, core startup pattern); Scope: Cortex chapter marked [x]; frontmatter: added [[dual-core-sio]] to related
- `wiki/inbox/quadros-rp2040-ingest-plan.md` — Cortex chapter marked [x]; 5 of 10 done
- `wiki/index.md` — added [[dual-core-sio]] to concepts; updated quadros-rp2040 description to 5/10

Key additions:
- SIO at `0xD0000000`: single-cycle access from both cores via IOPORT — no bus contention
- Inter-processor FIFOs: 2 × 8-word (8×32-bit) queues; `SIO_IRQ_PROC0` (IRQ15) / `SIO_IRQ_PROC1` (IRQ16) fire on data arrival — interrupt-driven cross-core wakeup without polling
- `multicore_launch_core1(entry_fn)` — how the RIA starts its OS dispatcher on core 1; must call `multicore_reset_core1()` first
- Hardware spinlocks ×32: write=acquire, non-zero read=owned, write=release — for sub-µs critical sections
- Atomic GPIO aliases: SET/CLR/XOR writes are single-bus-transaction atomic — eliminates read-modify-write races for `RESB`/`IRQB` lines
- `pico_sync`: critical_section (blocks interrupts), mutex (task-level ownership), semaphore (counting resource guard)
- Instruction table (pages 10–13): not extracted — ARM Thumb ISA, not RP6502-specific
- WFI instruction noted: used in idle loops; relevant if OS dispatcher parks on WFI between OS calls

Remaining chapters: 5 (Memory/DMA, Clock, UART, SPI, USB)

---

## [2026-04-16] ingest | Knowing the RP2040 (Quadros) — session 3 | Reset, Interrupts and Power Control chapter

Chapter ingested: Reset, Interrupts and Power Control (PDF 27–41).

Pages updated (2):
- `wiki/concepts/pio-architecture.md` — expanded "## IRQ flags" into "## IRQ flags and NVIC wiring": exact ARM IRQ numbers for PIO0_IRQ_0 (IRQ7), PIO0_IRQ_1 (IRQ8), PIO1_IRQ_0 (IRQ9), PIO1_IRQ_1 (IRQ10); `pio_set_irq0_source_enabled` / `pio_interrupt_get` / `pio_interrupt_clear` SDK functions; added SIO_IRQ_PROC0/1 (IRQ15/16) inter-core FIFO note; RIA note on which core enables PIO IRQs
- `wiki/sources/quadros-rp2040.md` — added "### Reset and interrupt model" section: 4 reset causes, peripheral reset bits table (PIO0=10, PIO1=11, DMA=2, USB=24), full 26-IRQ NVIC table, dual-NVIC per core rule, complete `hardware_irq` SDK function table, power control note (SLEEP/DORMANT — not RIA-relevant); Scope: Reset/Interrupts chapter marked [x]

Key additions:
- Full NVIC IRQ table: PIO0_IRQ_0=7, PIO0_IRQ_1=8, PIO1_IRQ_0=9, PIO1_IRQ_1=10 — these are the lines `api_task()` runs on
- PIO→NVIC wiring: `pio_set_irq0_source_enabled(pio, pis_interrupt0 + sm, true)` routes SM IRQ flag → PIO IRQ line; handler must explicitly call `pio_interrupt_clear()` — not automatic
- Each core has its own NVIC; interrupt should be enabled in only one core — explains RIA's core assignment (PIO bus loop on one core, OS dispatcher on the other)
- SIO_IRQ_PROC0/1 (IRQ15/16): inter-core FIFO interrupts — mechanism for the two cores to exchange data without polling
- `irq_add_shared_handler` vs `irq_set_exclusive_handler`: shared required for `IO_IRQ_BANK0` and multi-SM PIO lines; each handler must check and clear its own source
- Power control (SLEEP/DORMANT) ingested but not extracted — not relevant to RIA

Remaining chapters: 6 (Cortex, Memory/DMA, Clock, UART, SPI, USB)

---

## [2026-04-16] ingest | Knowing the RP2040 (Quadros) — session 2 | GPIO, Pad and PWM chapter

Chapter ingested: GPIO, Pad and PWM (PDF 89–131).

Pages updated (2):
- `wiki/concepts/gpio-pinout.md` — added "## GPIO hardware reference" section: GPIO structure (30 user-bank pins), function select table (GPIO_FUNC_SIO/PIO0/PIO1/UART/SPI), PAD configuration (drive strength 2/4/8/12mA, slew rate, Schmitt trigger, pull resistors, 50mA total budget), SIO digital I/O registers (GPIO_OUT/OE/IN), GPIO interrupt model (IO_IRQ_BANK0, normal vs raw callbacks); updated sources frontmatter
- `wiki/sources/quadros-rp2040.md` — scope: GPIO chapter marked [x]

Key additions:
- All GPIO0-GPIO29 assignable to PIO0 (F6) or PIO1 (F7) via gpio_set_function — explains how RIA firmware claims bus pins
- PAD drive strength: data bus (D0-D7) likely configured >4mA default; total 50mA budget across all GPIOs
- Schmitt trigger (hysteresis): default-enabled on inputs; essential for clean 65C02 bus signal capture at 8MHz
- GPIO interrupt model: IO_IRQ_BANK0 is the single NVIC source for all GPIO0-GPIO29 interrupts; PIO IRQ flags 0-3 also trigger this same line
- RIA note: bus capture uses PIO exclusively (not GPIO interrupts); GPIO_IN register readable from both cores via SIO

PWM section (printed pp. 109-126): 16 slices, 8.4 fractional divider — not relevant to RP6502 (no PWM-based audio or bus signals). Ingested but not extracted to wiki.

Remaining chapters: 7 (Cortex, Reset/Interrupts, Memory/DMA, Clock, UART, SPI, USB)

---

## [2026-04-16] ingest | Knowing the RP2040 (Quadros) — session 1 | 2 of 10 chapters ingested

Chapters ingested: The RP2040 Architecture (PDF 9–12), The Programmable I/O (PDF 132–158).

Pages created (1):
- **Source** (1): quadros-rp2040 — with full Scope section (10 chapters tracked)

Pages updated (2):
- `wiki/concepts/pio-architecture.md` — added "## PIO hardware reference" section: programmer's model (OSR/ISR/X/Y/PC), full 9-instruction ISA table (JMP/WAIT/IN/OUT/PUSH/PULL/MOV/IRQ/SET), GPIO pin groups, IRQ flags, program wrapping, fractional clock; updated sources frontmatter
- `wiki/inbox/quadros-rp2040-ingest-plan.md` — marked Architecture and PIO chapters [x]

Key additions:
- RP2040 address map: SRAM 0x20000000, AHB-Lite peripherals 0x50000000, IOPORT 0xD0000000
- SRAM: 264 kB total (4×64 kB + 2×4 kB in 6 banks)
- PIO: 2 blocks × 4 SMs = 8 total; 32-instruction shared memory per PIO
- WAIT PIN/GPIO = how ria_write waits for PHI2 edge; IN PINS = bus address/data capture; SET PINDIRS = ria_cs_rwb bus direction; side-set = PHI2 as side-effect of ria_write
- Clock divider math: at 256 MHz, divider=32 gives 32 cycles per 65C02 bus half-cycle

Remaining chapters: 8 (Cortex, Reset/Interrupts, Memory/DMA, Clock, GPIO, UART, SPI, USB)

---

## [2026-04-16] plan | Programming the Raspberry Pi Pico/W in C (Fairhead, 3rd ed.) | created ingestion plan in wiki/inbox/fairhead-pico-c-ingest-plan.md — 11 of 19 chapters marked for ingest, 8 skipped; includes Quadros comparison table

---

## [2026-04-16] plan | Knowing the RP2040 (Quadros) | created ingestion plan in wiki/inbox/quadros-rp2040-ingest-plan.md — 10 of 17 chapters marked for ingest, 7 skipped

---

## [2026-04-16] lint | full wiki | first lint pass (3 sources ingested)

Scope: all 30 wiki pages (8 sources, 7 entities, 12 concepts, 2 topics, overview, index, log).

Findings:

**Contradictions (1 fixed):**
- `ria-registers.md` register map: `$FFE0–$FFCF` was a typo (impossible range). Fixed to `$FFE0–$FFEB` (12 unassigned bytes before first named register RIA_STACK at $FFEC).

**Orphans (0):** No true orphans. Three source pages (`picocomputer-intro`, `rp6502-ria-docs`, `rp6502-os-docs`) have no body-text links from entity/concept pages — only hub/frontmatter references. Acceptable for source pages.

**Data gaps (4):**
- `[[cc65]]` entity page missing — referenced in 6 pages. Deferred until toolchain source available.
- `[[llvm-mos]]` entity page missing — referenced in 4 pages. Deferred.
- `RIA_RW0`/`RIA_RW1` addresses unknown — mentioned in 5 pages but absent from register map. Added gap note to `ria-registers.md`. Needs `src/ria/sys/ria.h`.
- VGA Pico full GPIO (DAC/sync pins) — already flagged, deferred to `src/vga/sys/vga.h`.

**Missing cross-references (4 fixed):**
- `launcher.md` — added [[release-notes]] to sources; added version note (v0.21 + v0.23).
- `reset-model.md` — added "Interaction with the launcher" section linking to [[launcher]].
- `rp6502-ria-w.md` — added [[known-issues]] to related pages.
- `version-history.md` Era 4 — corrected "256 MHz vs RP2040's 133 MHz"; added RP2350 default 150 MHz context and [[pio-architecture]] link.

Pages modified (5): ria-registers.md, launcher.md, reset-model.md, rp6502-ria-w.md, version-history.md

---

## [2026-04-16] ingest | picocomputer/rp6502 release notes (v0.1–v0.23) | 23 releases

Pages created (3 total):
- **Source** (1): release-notes
- **Topics** (2): version-history, known-issues

Pages updated (4):
- `wiki/entities/rp6502-ria-w.md` — telnet conflict resolved: raw TCP only, `tel.c` is WIP
- `wiki/concepts/rom-file-format.md` — named asset support introduced in v0.18
- `wiki/overview.md` — telnet open question resolved; topics hub added
- `wiki/index.md` — release-notes source, version-history and known-issues topics added

Key findings:
- **Telnet resolved**: v0.12 explicitly states "raw TCP only, telnet in the works" — resolves the `tel.c` mystery
- **PHI2 default history**: 4000 kHz through v0.12, changed to 8000 in v0.13
- **Non-W RIA dropped**: as of v0.13, only RIA-W released; plain RIA requires building from source
- **v0.8 is broken**: corrupts new Pico flash — known bad release, skip to v0.9
- **v0.10 = Pi Pico 2 migration**: hard hardware break; Pico 1 unsupported from v0.10 onward
- **Errno history**: `oserror`/`mappederrno` system existed before v0.14 (now completely replaced)
- **ROM asset filesystem**: named assets in `.rp6502` added v0.18 (not in original design)
- **Launcher + Alt-F4**: v0.21 (launcher mechanism), v0.23 (Alt-F4 keystroke)

---

## [2026-04-16] ingest | picocomputer/rp6502 monorepo (commit 368ed8e) | firmware source ingest

Source ingested:
- `raw/github/picocomputer/rp6502/` at commit `368ed8e` (2026-04-11)

Key files read: `src/ria/api/api.h`, `main.c`, `sys/ria.h`, `sys/cpu.h`, `sys/pix.h`, `sys/mem.h`, `sys/com.h`, `sys/cfg.h`, `ria.pio`, `api/std.h`, `api/pro.h`, `api/atr.h`, `api/clk.h`, `api/dir.h`, `api/oem.h`, `mon/mon.h`, `vga/sys/pix.h`, `vga/modes/modes.h`

Pages created (5 total):
- **Source** (1): rp6502-github-repo
- **Concepts** (4): ria-registers, api-opcodes, pio-architecture, gpio-pinout

Pages updated (7):
- `wiki/concepts/rp6502-abi.md` — exact register addresses, updated call example, xstack/mbuf size table, [[ria-registers]] link
- `wiki/concepts/pix-bus.md` — confirmed GPIO pin numbers, PIO SM assignments, TX FIFO depth
- `wiki/entities/rp6502-ria.md` — RP2350 256 MHz / 1.15 V, GPIO pinout summary, [[pio-architecture]] / [[gpio-pinout]] links
- `wiki/entities/rp6502-os.md` — full errno list pointer, complete API surface summary, [[api-opcodes]] link
- `wiki/overview.md` — open questions revised, hub pages updated
- `wiki/index.md` — 1 new source, 4 new concepts added
- `PROGRESS.md` — GitHub repo ingest flipped to ✅; next item promoted

Notes / open questions surfaced:
- `tel.c` present alongside modem — may be TCP transport for Hayes modem, not a user-facing telnet shell. Web docs say "no telnet shell." Needs verification.
- VGA Pico full GPIO map not yet read (DAC/sync pins). `vga/sys/vga.h` deferred.
- Release notes not yet ingested — each release documents new OS calls and behavioral changes.
- `cc65` and `llvm-mos` still have no entity pages; both are deeply integrated (separate lseek op-codes, separate errno-opt).

---

## [2026-04-15] ingest | picocomputer.github.io (6 clipped pages) | first content ingest

Sources ingested:
- `Picocomputer 6502` → [[picocomputer-intro]]
- `Hardware` → [[hardware]]
- `RP6502-RIA` → [[rp6502-ria-docs]]
- `RP6502-RIA-W` → [[rp6502-ria-w-docs]]
- `RP6502-VGA` → [[rp6502-vga-docs]]
- `RP6502-OS` → [[rp6502-os-docs]]

Pages created (18 total):
- **Sources** (6): picocomputer-intro, hardware, rp6502-ria-docs, rp6502-ria-w-docs, rp6502-vga-docs, rp6502-os-docs
- **Entities** (7): rp6502-board, w65c02s, w65c22s, rp6502-ria, rp6502-ria-w, rp6502-vga, rp6502-os
- **Concepts** (8): memory-map, pix-bus, xram, xreg, rom-file-format, rp6502-abi, reset-model, launcher

Pages revised:
- `wiki/overview.md` — first real synthesis: what is RP6502, hardware components, firmware variants, software stack, key open questions.
- `wiki/index.md` — populated all four sections.

Notes / open questions surfaced:
- Slot mapping confirmed: U2 = Pi Pico 2 W (RIA-W), U4 = Pi Pico 2 (VGA).
- `[[cc65]]` and `[[llvm-mos]]` referenced repeatedly but no entity pages yet — gap to fill from the GitHub repo or upstream docs.
- The OS source contains many more API entries than were summarized; only a representative sampling was lifted to keep this session focused. A future ingest pass should walk the rest of the file (Process control, Time, full file/dir API, attributes table, errno table) and expand `[[rp6502-os-docs]]`.

---

## [2026-04-15] setup | initial scaffold | created directory structure, CLAUDE.md, wiki stubs

---

## [2026-04-17] ingest | YouTube playlist — Sessions 0 + 1 | Ep1–Ep4 ingested; scaffolding created

Sessions completed: 0 (scaffolding) and 1 (Era A: Prototype).

### Session 0 — Scaffolding
- Created `wiki/topics/development-history.md` — topic page with Era A written, Eras B–E stub headings.
- Created `wiki/sources/youtube-playlist.md` — hub page with episode table and Scope tracker.
- Updated `wiki/index.md` — added youtube-playlist, yt-ep01–04 under Sources; development-history under Topics.

### Session 1 — Era A: Prototype (Ep1–Ep4, late 2022 – early 2023)
Source pages created (4):
- `wiki/sources/yt-ep01-8bit-retro-computer.md`
- `wiki/sources/yt-ep02-pio-and-dma.md`
- `wiki/sources/yt-ep03-writing-to-pico.md`
- `wiki/sources/yt-ep04-picocomputer-hello.md`

Pages updated (3):
- `wiki/concepts/pio-architecture.md` — added historical origin note (Ep2/Ep3) to "Why PIO?" section; added youtube-playlist to sources.
- `wiki/topics/known-issues.md` — added "Hardware requirements" section with AC-chip/8 MHz rule (Ep3).
- `wiki/concepts/rp6502-abi.md` — added historical note on `RIA_SPIN` prototype origin (Ep4); added youtube-playlist to sources.

Key facts captured:
- Initial design: 12 glue chips, single-Pico concept (Ep1).
- Dual-Pico pivot formalized at Ep2 → became [[rp6502-ria]] + [[rp6502-vga]] architecture.
- PIO+DMA bus interface introduced Ep2 (read path) and Ep3 (write path + chip-select gating).
- 8 MHz achieved by doubling Pi Pico clock (Ep2); AC-family chips required for 8 MHz glue logic (Ep3); HC family defaults to 4 MHz.
- RIA name coined in Ep3.
- Fast-load (`RIA_SPIN`) prototype described in Ep4; 6502 startup garbage (first 7 cycles) quirk documented.

---

## [2026-04-17] ingest | YouTube playlist — Session 2 | Ep6–Ep7 ingested (Era B)

### Session 2 — Era B: Storage and OS emergence (Ep6, Ep7, 2023)

Source pages created (2):
- `wiki/sources/yt-ep06-roms-filesystem.md`
- `wiki/sources/yt-ep07-operating-system.md`

Pages updated (4):
- `wiki/topics/development-history.md` — wrote Era B section: dual-filesystem rationale, ROM concept, OS emergence narrative, XRAM memory model clarification, RP2040-era context
- `wiki/entities/rp6502-os.md` — added design philosophy section from Ep7 ("32 bytes", "OS emerged", protection model, third-party composition)
- `wiki/concepts/xram.md` — added shared-ownership note from Ep7 (userland/kernel/video/audio all share XRAM)
- `wiki/index.md` — added yt-ep06 and yt-ep07 entries

Key facts captured:
- FatFs (USB media) + littlefs (internal flash) coexistence rationale: wear-leveling divide
- ROM concept introduced in Ep6: programs installed to internal flash, bootable
- "I never set a goal of making an operating system" — emerged from POSIX intent (Ep7)
- "All I ask for is 32 bytes" — RIA's only footprint in 6502 address space
- XRAM shared by userland/kernel/video/audio (first explicit statement, Ep7)
- At Ep7, RP2040/Cortex-M0+ was the hardware; migrated to RP2350 at v0.10
- PIX bus not yet working at Ep7; VGA = ANSI terminal only

---

## [2026-04-17] lint | full wiki lint pass | cross-ref gaps closed

**Scope**: contradictions, orphans, data gaps, missing cross-refs, ingestion completeness across 76 wiki pages.

**Findings + fixes**:
- **Contradictions**: none surfaced.
- **Orphans**: none. Lowest inbound is `[[yt-ep19-game-of-life]]` (1 ref from `youtube-playlist`); acceptable for a tutorial-only episode source.
- **Data gaps**: none — every domain term mentioned in body has a corresponding page.
- **Missing cross-refs**: ~40 candidates surfaced from heuristic scan; high-value ones fixed:
  - `wiki/concepts/api-opcodes.md` — added `[[cc65]]` / `[[llvm-mos]]` links in errno-opt and lseek rows; expanded `related:`.
  - `wiki/concepts/xreg.md` — pointed PSG/OPL2 example block to `[[programmable-sound-generator]]` / `[[opl2-fm-synth]]`; expanded `related:`.
  - `wiki/concepts/pix-bus.md` — first PIO mention now links to `[[pio-architecture]]`.
  - `wiki/concepts/opl2-fm-synth.md` — first XRAM and PIX-bus mentions now linked.
  - `wiki/concepts/ria-registers.md` — XRAM, cc65, llvm-mos first mentions now linked; expanded `related:`.
  - `wiki/concepts/memory-map.md` — first PIO + HSTX rows now wikilinked; expanded `related:`.
  - `wiki/concepts/rp2040-clocks.md` — first HSTX mention now linked; added to `related:`.
  - `wiki/topics/development-history.md` — first cc65/llvm-mos mentions in Eras D and toolchain split section now linked.
  - `wiki/sources/rp6502-ria-docs.md` — PSG/OPL2 table rows now point at the dedicated concept pages.
  - `wiki/sources/release-notes.md` — added `[[cc65]]` / `[[opl2-fm-synth]]` / `[[programmable-sound-generator]]` to `related:`.
- **Ingestion completeness**: every `## Scope` table across all source pages is fully checked off (0 unchecked items).
- **Frontmatter**: 1 strict-YAML violation in `wiki/overview.md` (colon inside `updated:` parenthetical) — fixed by simplifying to `updated: 2026-04-17`. The wiki-style `related: [[a]], [[b]]` syntax is per CLAUDE.md spec and is treated as wiki convention, not a YAML error.

**Remaining low-priority gaps** (intentionally not fixed — repeated mentions inside the same paragraph or table; first mention is already linked elsewhere):
- `youtube-playlist.md` body table reuses cc65/llvm-mos/PIX bus/PIO terms across many rows; episode source pages already link them where they're discussed in depth.
- `quadros-rp2040.md`, `fairhead-pico-c.md`, `pico-c-sdk.md` use HSTX/PIX bus/XRAM in scope-listing context; no new fact would be reached by adding more links.

---

## [2026-04-17] lint | post-YouTube polish pass | audio section + small fixes

- `wiki/overview.md` — added "## Audio" section (PSG + OPL2 coexistence, v0.6 / v0.16 anchors, XREG+XRAM pathway); removed duplicate "Topics" line at EOF
- `wiki/sources/yt-ep19-game-of-life.md` — added `[[development-history]]` to related
- `wiki/sources/yt-ep21-ai-programming.md` — added `[[development-history]]` to related
- Broken-link scan: 0 broken wikilinks across 76 pages (only `[[pia-registers]]` in this log, which is a historical record of a past typo fix)

---

## [2026-04-17] ingest | YouTube playlist Sessions 3–9 | Eps 8–22 fully ingested

**All 15 remaining transcript files ingested (Ep8–Ep22, except Ep5 no-captions).**

### New pages created (20)

**Source pages** (15):
- `wiki/sources/yt-ep08-vga-pix-bus.md` — PIX bus design, DDR insight, PIO cost, DMA priority
- `wiki/sources/yt-ep09-c-programming-setup.md` — cc65 + VSCode template workflow
- `wiki/sources/yt-ep10-diy-build.md` — PCB soldering assembly, Founders Edition boards
- `wiki/sources/yt-ep11-no-soldering.md` — PCBWay single-unit manufacturing
- `wiki/sources/yt-ep12-fonts-vsync.md` — v0.1 release, code pages, VSYNC backchannel
- `wiki/sources/yt-ep13-graphics-programming.md` — canvas/mode/xreg/planes/scanlines tutorial
- `wiki/sources/yt-ep14-usb-mouse.md` — 3 input modes, fgets() added, paint demo
- `wiki/sources/yt-ep15-asset-management.md` — CMake asset workflow, sprites with affine transforms
- `wiki/sources/yt-ep16-psg-intro.md` — PSG: 8ch, 5 waveforms, ADSR, PWM
- `wiki/sources/yt-ep17-basics-of-basic.md` — EhBASIC install, SET BOOT, reset vs. reboot, RND quirk
- `wiki/sources/yt-ep18-llvm-mos.md` — cc65 vs LLVM-MOS comparison and Mandelbrot benchmark
- `wiki/sources/yt-ep19-game-of-life.md` — 640×480 monochrome bitmap tutorial (thin)
- `wiki/sources/yt-ep20-bbs.md` — Pi Pico 2 upgrade, WiFi BBS, NTP+DST
- `wiki/sources/yt-ep21-ai-programming.md` — GitHub Copilot demos, documentation anchoring (thin)
- `wiki/sources/yt-ep22-graphics-sound-demos.md` — community demos, OPL2 FM synth origin story

**Concept pages** (3):
- `wiki/concepts/code-pages.md` — CP437/CP850/CP855, FAT short-name fallback, SET CODEPAGE
- `wiki/concepts/programmable-sound-generator.md` — 8ch, 5 waveforms, ADSR, PWM, stereo pan, XREG
- `wiki/concepts/opl2-fm-synth.md` — YM3812-compatible, firmware emulation, origin story, FPGA experiment

**Entity pages** (2):
- `wiki/entities/cc65.md` — 1998+, stable stdlib, fastcall ABI, VSCode template, fork requirement
- `wiki/entities/llvm-mos.md` — LLVM fork, C++/floats/64-bit, better optimization, sparse stdlib

### Pages updated (16)

- `wiki/concepts/pix-bus.md` — added "Design journey" section: SPI rationale, DDR brain-fart story, PIO cost, DMA priority, VSYNC backchannel complexity
- `wiki/entities/rp6502-vga.md` — added graphics system details: color model, xreg register map, config structure fields, scanline partitioning, tiling, affine sprites, ANSI 16-bit upgrade
- `wiki/topics/development-history.md` — wrote Era C (PIX bus + graphics), Era D (productization + CMake assets), Era E (RP2350 migration, BBS, BASIC, toolchains, PSG, OPL2, community)
- `wiki/topics/known-issues.md` — added code page / filename fallback note; added EhBASIC RND(1) vs RND(0) quirk; added CONTINUE note
- `wiki/topics/version-history.md` — added v0.1 "dozen working devices" trigger note
- `wiki/concepts/rom-file-format.md` — added CMake asset workflow section (rp6502_asset, rp6502_executable, help shebang, install workflow)
- `wiki/concepts/rp6502-abi.md` — added developer workflow section (template→compile→upload→run, rp6502.py, CMake structure)
- `wiki/entities/rp6502-os.md` — added input modes section (UART stdio, HID bit-array, mouse counters)
- `wiki/concepts/launcher.md` — added boot BASIC example (SET BOOT BASIC, reset vs. reboot workaround)
- `wiki/concepts/reset-model.md` — added user-visible consequence: BASIC + disk access (Ctrl+Alt+Del → RESET workflow)
- `wiki/entities/rp6502-ria-w.md` — added BBS demo section (Hayes modem, ANSI+CP437, NTP+DST, Pi Pico 2 upgrade path)
- `wiki/entities/rp6502-ria.md` — added audio subsystem section (PSG + OPL2 coexistence, XREG addresses, 10-bit DAC upgrade note)
- `wiki/sources/youtube-playlist.md` — updated all episode wikilinks + notes; marked all episodes [x] ingested in Scope table
- `wiki/index.md` — added all new pages (15 source, 3 concept, 2 entity)
- `wiki/overview.md` — added development-history and youtube-playlist to hub pages; added audio section (PSG+OPL2); added cc65/llvm-mos to entities; resolved open question #3 (toolchain pages now exist)
- `PROGRESS.md` — updated YouTube ingest line to ✅; backfill items marked done; wiki size table updated (~74 pages)

### Deleted
- `wiki/inbox/youtube-rp6502-ingest-plan.md` — all sessions complete; superseded by source pages and log.md

### [2026-04-18] ingest | Assembly Lines: The Complete Book (Wagner/Torrence 2014) | 3 new concept pages, 2 augmented, 1 new source page; 65c02-instruction-set augmented with Ch.33 Wagner notes

#### New pages
- `wiki/concepts/learning-6502-assembly.md` — beginner scaffold: registers, Status Register flags, binary numbers, counter/loop patterns (BNE/BEQ), all 8 branch instructions, addressing modes overview, X vs Y non-interchangeability
- `wiki/concepts/6502-stack-and-subroutines.md` — stack LIFO mechanics ($0100–$01FF), PHA/PLA rules, PHX/PHY/PLX/PLY (65C02), JSR saves PC−1, RTS adds 1, register save/restore idioms, stack depth limits
- `wiki/concepts/6502-relocatable-and-self-modifying.md` — relocatable vs non-relocatable code, forced branch patterns (CLV+BVC, BRA on 65C02), stepping, JSR simulation, indirect JMP dispatch tables, NMOS page-boundary bug + 65C02 fix, self-modifying code

#### Augmented pages
- `wiki/concepts/65c02-addressing-modes.md` — added Wagner Ch.7 sidebar: X vs Y non-interchangeability in indirect modes; pre-indexing (zp,X) vs post-indexing (zp),Y with examples
- `wiki/concepts/6502-programming-idioms.md` — added shift/rotate operators section (ASL/LSR/ROL/ROR), logical operators section (AND/ORA/EOR/BIT with 65C02 extended modes), BCD fundamentals section (SED/CLD, decimal arithmetic, printing, limitations, 65C02 improvements)
- `wiki/concepts/65c02-instruction-set.md` — added Wagner Ch.33 beginner perspective: PHX/PHY vs NMOS workaround, STZ vs LDA#0/STA, BRA vs CLV+BVC, TSB/TRB practical patterns, compatibility notes

#### Deleted
- `wiki/inbox/wagner-assembly-lines-ingest-plan.md` — all chapters complete; superseded by source page and log.md

### [2026-04-18] update | picocomputer.github.io re-clip (all 6 pages) | Mode 5 affine correction + hardware page updates

#### Fixed
- `wiki/entities/rp6502-vga.md` — **Corrected error**: Mode 5 does NOT support affine transforms (only Mode 4 does). Rewrote sprite section to document Mode 4 (affine) and Mode 5 (palette, 8×8–512×512, no affine) separately.

#### Updated
- `wiki/sources/hardware.md` — Added ordering section: PCBWay Rev B link, Ko-fi US store, Mouser CSV BOM link; added "boot message no longer says COLOR" gotcha warning.

---

### [2026-04-18] update | picocomputer.github.io "networking" commit | RIA-W telnet console + full modem telnet

#### Changed pages
- `wiki/entities/rp6502-ria-w.md` — added Telnet Console section (`SET PORT`/`SET KEY`); updated modem section: full telnet now live (`AT\N0`/`AT\N1`), added `AT\L`, `AT\T`, `ATA`, `ATDS`, 10-profile device names, 4-slot phonebook, 4 simultaneous connections; removed "raw TCP only" limitation
- `wiki/sources/rp6502-ria-w-docs.md` — updated summary and key facts; noted raw file is pre-April-18; removed stale "no telnet" claims
- `wiki/topics/known-issues.md` — moved "Telnet not yet implemented" to resolved; removed from active issues

---

### [2026-04-18] ingest | Discord #chat export (2022-11-03–2026-04-18) | 2 new pages, 3 augmented pages, major known-issues expansion

#### New pages
- `wiki/sources/rumbledethumps-discord.md` — source summary: hardware tips (HC vs AC logic, PHI2 sampling, PIX bus 64Mbit/s, GPIO voltages, Rev B board), firmware internals (NOP alignment, regs[] scratch_x, AUD_PWM_IRQ_PIN), USB silicon bug (TinyUSB EPX/interrupt latch race), TinyUSB PR #3582, OPL2 native details, telnet+Hayes modem (v0.24), cc65 toolchain tips (homebrew warning, binary size comparison), community design philosophy quotes, ROM asset format, NFC reader support
- `wiki/topics/community-projects.md` — jasonr1100 (RPTracker, RPMegaFighter, RPMegaChopper, RPMegaRacer, RPGalaxy, RP6502_OPL2 FPGA card, MovieTime6502), voidas_pl (cc65-rp6502os, PicoMatrix), tonyvr0759 (RP6502-TextEditor, 65816 adaptation), jjjacer (eInk laptop), markrvm (RP6809), ndjordjevic5067 (VGA cold-boot fix, RPi keyboard PR)

#### Augmented pages
- `wiki/topics/known-issues.md` — added Community-reported issues section: VGA cold-boot (busy_wait_ms 5ms), PHI2 100kHz after config truncation, RPi keyboard num-lock bug, TinyUSB silicon bug (EPX/interrupt latch), llvm-mos SDK version lock, cc65 package manager warning, affine sprite RP2350 glitch, build folder cmake regression
- `wiki/topics/version-history.md` — added Era 9 (v0.24): Telnet console, Hayes modem, telnet upload 56KB/s, multi-user BBS; updated v0.23 summary; added community context links
- `wiki/concepts/opl2-fm-synth.md` — replaced generic tracker entry with RPTracker full details (9ch, 256 patches, effects list); added PSG/OPL2 mutual exclusion note; added FPGA OPL2 extension (jasonr1100 PIX bus hardware)

#### Housekeeping
- `wiki/index.md` — added rumbledethumps-discord source row; updated known-issues and version-history descriptions; added community-projects topic row
- `PROGRESS.md` — Discord ingest flipped 👉 → ✅; next item promoted; wiki size table updated

---

## [2026-04-18] lint | deep wiki health check | 118 pages scanned

### Contradictions fixed
- `wiki/concepts/xram.md:53` — "RP2040's six SRAM banks" corrected to "RP2350's SRAM banks"; added [[rp2350]] wikilink
- `wiki/topics/known-issues.md:101` — removed incorrect "RP2040-compatible" from Cortex-M33 description; added [[rp2350]] link
- `wiki/concepts/dma-controller.md` — title and summary updated to clarify RP2040 (12 ch) vs RP2350 (16 ch, live firmware)
- `wiki/concepts/rp2040-uart.md`, `rp2040-clocks.md`, `usb-controller.md` — summary lines updated from "RP2040 has" to "RP2040/RP2350 have"

### Broken links fixed
- `wiki/sources/w65c02s-datasheet.md:68` — broken `[[65c02-pinout]]` replaced with `[[w65c02s]]#pin-function-highlights`

### Naming collision resolved
- `wiki/sources/ehbasic.md` renamed to `wiki/sources/ehbasic-repo.md` to eliminate disambiguation ambiguity with `wiki/entities/ehbasic.md`
- Updated `wiki/index.md`, `wiki/overview.md`, `wiki/entities/ehbasic.md` to use `[[ehbasic-repo]]` for source references

### Missing wikilinks added (MR1–MR12)
- `wiki/concepts/65c02-instruction-set.md` — `cc65`/`llvm-mos` inline mentions now linked
- `wiki/concepts/fatfs.md` — `cc65`/`llvm-mos` linked
- `wiki/concepts/rp2040-spi.md` — FatFS linked
- `wiki/overview.md` — "65C22 VIA" linked to [[w65c22s]]
- `wiki/concepts/6502-interrupt-patterns.md` — "W65C22S VIA" linked
- `wiki/topics/development-history.md` — FatFs linked
- `wiki/topics/version-history.md` — PIX bus linked
- `wiki/concepts/pio-architecture.md` — bare `pioasm` at lines 431/482 linked
- `wiki/concepts/exec-api.md` — "code page" heading linked to [[code-pages]]
- `wiki/concepts/opl2-fm-synth.md` — "6522 VIA" linked to [[w65c22s]]
- `wiki/topics/known-issues.md` — section headings mentioning cc65 now linked

### PROGRESS.md updated
- Wiki size table corrected: Sources 48, Concepts 47, Topics 7, Total ~118

---

## [2026-04-18] ingest | 6502.org tutorials (8 pages) | 4 new pages + 4 pages updated

**Source**: `raw/web/6502.org/` — 8 Obsidian Web Clipper exports, primary author Bruce Clark; other authors anonymous/John Pickens.

**New pages created**:
- `wiki/sources/6502org-tutorials.md` — master source summary for all 8 tutorials
- `wiki/concepts/6502-compare-instructions.md` — CMP/CPX/CPY, branch selection, multi-byte comparisons, N XOR V signed method
- `wiki/concepts/6502-decimal-mode.md` — BCD, D flag, flag validity per CPU variant, interrupt D-clear
- `wiki/concepts/6502-overflow-flag.md` — V flag mechanics, BIT immediate exception, SO pin, signed comparison pattern

**Pages updated**:
- `wiki/concepts/6502-interrupt-patterns.md` — added WAI I=1 inline interrupt, ghost interrupts, open-drain timing, cross-CPU performance table, Pickens 256-byte ring buffer, waveform generator ISR
- `wiki/concepts/65c02-instruction-set.md` — added NMOS ZP wrap-around, ASL/LSR/ROL/ROR cycle correction, undocumented NOP skip, BRK PC+2 detail, BIT-as-skip, RTS jump table; updated sources + related
- `wiki/concepts/6502-stack-and-subroutines.md` — added TSX-based register preservation (no temp storage), BRK/IRQ B-flag disambiguation (correct stack-read vs. wrong PHP); updated sources + related
- `wiki/concepts/6502-programming-idioms.md` — updated sources frontmatter + related links to new pages

**No conflicts found**: 6502.org facts align with existing content from Leventhal/Wagner/Zaks. BRK/IRQ disambiguation clarification agrees with Leventhal (uses PLA/PHA correctly).

**Index/overview/PROGRESS updated**: 4 new index entries, overview §6502-assembly extended with 3 new concept bullets, PROGRESS wiki size updated (Sources 50, Concepts 54, Total ~136).

---

## [2026-04-18] lint | deep wiki health check (post-6502.org ingest) | 12 fixes applied

### Contradictions
None found. All 6 checked pairs consistent. ✅

### Broken links fixed (B1–B2)
- `wiki/concepts/memory-map.md` lines 65, 68 — backslash escapes in `[[pio-architecture\|PIO]]` and `[[hstx\|High-speed transmit]]` replaced with correct pipe syntax

### Orphans resolved (O1–O2)
- `wiki/syntheses/learning-guide.md` — added inbound link from `learning-6502-assembly.md` Related pages
- `wiki/syntheses/trng.md` — added inbound link from `rp2350.md` Related pages; updated trng.md frontmatter with broader related set

### Missing cross-refs fixed (MR1–MR6)
- `6502-compare-instructions.md` — added `[[6502-decimal-mode]]` to Related pages
- `6502-emulated-instructions.md` — added `[[6502-compare-instructions]]` + `[[6502-overflow-flag]]` to Related pages and frontmatter
- `65c02-instruction-set.md` — added `[[6502-decimal-mode]]` + `[[6502-interrupt-patterns]]` to Related pages
- `6502-common-errors.md` — added `[[6502-decimal-mode]]`, `[[6502-compare-instructions]]`, `[[6502-overflow-flag]]` to Related pages and frontmatter
- `learning-guide.md` — inserted A3b/A7b/A7c rows for new concept pages; updated frontmatter related

### Data gaps fixed (DG1–DG2)
- `w65c02s.md` — added `[[6502-compare-instructions]]`, `[[6502-decimal-mode]]`, `[[6502-overflow-flag]]`, `[[6502-interrupt-patterns]]` to Related pages and frontmatter
- `6502-common-errors.md` — inline links and Related pages updated (same edit as MR above)

### Incomplete ingestion
None found — all 8 checked source Scope sections fully covered. ✅
