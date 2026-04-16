# Wiki Log

Append-only record of all wiki operations. Most recent entry at the top.
Format: `## [YYYY-MM-DD] <operation> | <source or topic> | <what changed>`

Operations: `ingest`, `query`, `lint`, `setup`

---

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Communication Using SPI (PDF 184–193) — FINAL CHAPTER | new page: [[rp2040-spi]] (SPI basics, CPOL/CPHA modes, 8-entry FIFOs, two-stage clock divider from clk_peri, manual SS in master mode, GPIO pin tables, full SDK API, correction: RIA uses USB MSC not SPI for storage); updated: [[quadros-rp2040]] scope + SPI facts section, [[index]] (all chapters ingested), [[overview]]; deleted ingest plan from wiki/inbox (all chapters complete)

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Asynchronous Serial Communication: the UARTs (PDF 172–183) | new page: [[rp2040-uart]] (framing, TX/RX FIFOs + error flags, fractional baud rate from clk_peri, 5 interrupt sources, RTS/CTS flow control, GPIO pin options, full SDK API, RIA UART1/GPIO4-5/115200 8N1); updated: [[quadros-rp2040]] scope + UART facts section, [[index]] (9/10 chapters done), ingest plan

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Clock Generation, Timer, Watchdog and RTC (PDF 68–88) | new page: [[rp2040-clocks]] (ROSC/XOSC/PLLs, 10 clock domains, mux architecture, 256 MHz System PLL overclock, 64-bit Timer + alarm pools + pico_time, Watchdog + scratch registers, RTC + repeating alarm); updated: [[quadros-rp2040]] scope + clock facts section, [[index]], ingest plan (8/10 chapters done)

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — USB Controller (PDF 200–232) | new pages: [[usb-controller]] (USB 1.1 PHY, TinyUSB host/device API, HID boot protocol keyboard/mouse/gamepad, CDC VCP, RP6502-RIA USB host usage table); updated: [[quadros-rp2040]] scope + USB key facts section, [[rp6502-ria]] related links, [[index]], [[overview]]

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Memory, Addresses and DMA (PDF 42–67) | new pages: [[rp2040-memory]] (ROM/SRAM banking/Flash/XIP/full address map), [[dma-controller]] (12 channels, DREQ table, control blocks, chaining, CRC sniffing, SDK API); updated: [[xram]] (DMA section added), [[quadros-rp2040]] scope, [[index]]

## [2026-04-16] setup | Git: `picocomputer/rp6502` as submodule | vendored tree → submodule at v0.23

Replaced the vendored copy under `raw/github/picocomputer/rp6502/` with a **Git submodule** pointing at [picocomputer/rp6502](https://github.com/picocomputer/rp6502), checked out at tag **v0.23** (commit `368ed8e`, same pin as before). Added root `.gitmodules`; nested upstream submodules (`src/littlefs`, `src/tinyusb`) initialized locally. Updated `raw/README.md` with clone (`--recurse-submodules` / `git submodule update --init --recursive`) and bump instructions for future releases.

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

## [2026-04-16] plan | Programming the Raspberry Pi Pico/W in C (Fairhead, 3rd ed.) | created ingestion plan in wiki/inbox/fairhead-pico-c-ingest-plan.md — 11 of 19 chapters marked for ingest, 8 skipped; includes Quadros comparison table

## [2026-04-16] plan | Knowing the RP2040 (Quadros) | created ingestion plan in wiki/inbox/quadros-rp2040-ingest-plan.md — 10 of 17 chapters marked for ingest, 7 skipped

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

## [2026-04-15] setup | initial scaffold | created directory structure, CLAUDE.md, wiki stubs
