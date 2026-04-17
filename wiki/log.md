# Wiki Log

Append-only record of all wiki operations. Most recent entry at the top.
Format: `## [YYYY-MM-DD] <operation> | <source or topic> | <what changed>`

Operations: `ingest`, `query`, `lint`, `setup`

---

## [2026-04-17] ingest | pico-c-sdk S14 | §5.2.13 pico_time (PDF pp.412–433)

- `wiki/concepts/rp2040-clocks.md`: replaced brief pico_time section with full reference — `absolute_time_t` type note (SDK 2.0+ defaults to uint64_t; `PICO_OPAQUE_ABSOLUTE_TIME_T=1` for type-checked mode); `at_the_end_of_time`/`nil_time` sentinels; full timestamp API (14 functions); sleep API with WFE/alarm-pool requirement + `best_effort_wfe_or_timeout()`; busy_wait variants; default pool config macros (`PICO_TIME_DEFAULT_ALARM_POOL_DISABLED`, `_HARDWARE_ALARM_NUM=3`, `_MAX_TIMERS=16`); `alarm_callback_t` return-value semantics (<0=reschedule from prev target, >0=reschedule from now, 0=cancel); `alarm_id_t` note; full pool management (create/destroy/query); `alarm_pool_add_alarm_at_force_in_context()`; default-pool convenience wrappers; repeating_timer API with delay sign convention (+ve=gap, -ve=fixed-rate)
- `wiki/sources/pico-c-sdk.md`: S14 row → `[x] ingested — S14`
- `wiki/inbox/pico-c-sdk-ingest-plan.md`: all 14 sessions `[x]` — **plan file deleted**

## [2026-04-17] ingest | pico-c-sdk S13 | §5.2.7 pico_multicore + §5.2.12 pico_sync (PDF pp.397–412)

- `wiki/concepts/dual-core-sio.md`: corrected core-launch section (removed non-existent `_with_config`, added `multicore_launch_core1_with_stack` + `multicore_launch_core1_raw` with full signatures); expanded FIFO section (RP2350 depth=4 vs RP2040 depth=8, SDK "precious resource" caution, full 11-function FIFO table incl. `rvalid/wready/clear_irq/get_status`, `SIO_FIFO_IRQ_NUM(core)` macro); added **Doorbell API** section (RP2350-only, 9 functions + `DOORBELL_IRQ_NUM` macro); added **Lockout API** section (7 functions); expanded pico_sync into full reference: `critical_section` (5 functions incl. `_with_lock_num`, `_deinit`, `_is_initialized`), `lock_core` internal model, `mutex` full API (12 functions + `auto_init_mutex`), `recursive_mutex` full API (8 functions + `auto_init_recursive_mutex`), `semaphore` full API (9 functions); updated RIA connections table (`SIO_FIFO_IRQ_NUM` replaces old RP2040-specific IRQ names)
- `wiki/sources/pico-c-sdk.md`: S13 row → `[x] ingested — S13`
- `wiki/inbox/pico-c-sdk-ingest-plan.md`: S13 checkbox → `[x]` (S14 still `[ ]`)

## [2026-04-17] ingest | pico-c-sdk S12 | §5.1.29 hardware_timer + §5.1.30 hardware_uart (PDF pp.349–397)

- `wiki/concepts/rp2040-clocks.md`: expanded Timer section — RP2350 two-timer architecture (TIMER0/TIMER1), updated timebase notes, full `hardware_alarm_callback_t` typedef, expanded default-timer wrappers table (5 new functions: `hardware_alarm_claim_unused`, `hardware_alarm_unclaim`, `hardware_alarm_is_claimed`, `hardware_alarm_force_irq`, `hardware_alarm_get_irq_num`), compile-time macros table (`TIMER_ALARM_IRQ_NUM`, `TIMER_ALARM_NUM_FROM_IRQ`, `TIMER_NUM_FROM_IRQ`, `PICO_DEFAULT_TIMER`, `PICO_DEFAULT_TIMER_INSTANCE`), full RP2350 multi-instance `timer_*` API table (21 functions)
- `wiki/concepts/rp2040-uart.md`: added `uart_deinit`, `uart_is_enabled`, `uart_get_index`, `uart_get_instance`, `uart_get_hw`, `uart_get_reset_num`, corrected `uart_set_irqs_enabled` (was `uart_set_irq_enables`), corrected `uart_get_dreq_num` (was `uart_get_dreq`); added compile-time macros table (7 macros: `UART_NUM`, `UART_INSTANCE`, `UART_DREQ_NUM`, `UART_CLOCK_NUM`, `UART_FUNCSEL_NUM`, `UART_IRQ_NUM`, `UART_RESET_NUM`); added `uart_init` GPIO setup pattern; added pause-duration warnings for format/baud/FIFO changes; updated sources to include `pico-c-sdk`
- `wiki/sources/pico-c-sdk.md`: S12 row → `[x] ingested — S12`
- `wiki/inbox/pico-c-sdk-ingest-plan.md`: S12 checkbox → `[x]`

## [2026-04-17] ingest | pico-c-sdk S11 | §5.1.25 hardware_spi + §5.1.27 hardware_sync (PDF pp.329–349)

- `wiki/concepts/rp2040-spi.md`: added `spi_deinit`, `spi_get_baudrate`, `spi_get_index` to SDK table; added DMA compile-time macros table (`SPI_DREQ_NUM`, `SPI_NUM`, `SPI_INSTANCE`); updated sources to include `pico-c-sdk`
- `wiki/concepts/dual-core-sio.md`: expanded hardware spinlocks section — spinlock number assignment table (0-13/14-15/16-23/24-31 ranges), RP2350-E2 erratum note, full `hardware_sync` spinlock SDK API table (14 functions); added memory barrier section (`__dmb`/`__dsb`/`__isb`/`__mem_fence_acquire`/`__mem_fence_release`); added processor events section (`__sev`/`__wfe`/`__wfi`/`__nop`); added interrupt control section (`save_and_disable_interrupts`/`restore_interrupts`/`restore_interrupts_from_disabled`)
- `wiki/sources/pico-c-sdk.md`: S11 row → `[x] ingested — S11`
- `wiki/inbox/pico-c-sdk-ingest-plan.md`: S11 checkbox → `[x]`

## [2026-04-17] ingest | pico-c-sdk S10 | §5.1.16 hardware_pio end + §5.1.17 hardware_pll (PDF pp.254–264)

- `wiki/concepts/pio-architecture.md`: expanded `pio_encode_*` section — composition helpers (`pio_encode_delay`/`sideset`/`sideset_opt` return ORable bits, not instructions), complete JMP variant table (8 variants), `wait_pin` vs `wait_gpio` addressing distinction, `pio_src_dest` enum reference table
- `wiki/concepts/rp2040-clocks.md`: added `hardware_pll` SDK functions section — `pll_init`, `pll_deinit`, `PLL_RESET_NUM` macro, `pll_sys`/`pll_usb` handles; caution re `pll_deinit` not checking if PLL is in use
- `wiki/sources/pico-c-sdk.md`: S10 row → `[x] ingested — S10`
- `wiki/inbox/pico-c-sdk-ingest-plan.md`: S10 checkbox → `[x]`

## [2026-04-17] ingest | pico-c-sdk S9 | §5.1.16 hardware_pio pt.2 (PDF pp.236–254)

Updated `wiki/concepts/pio-architecture.md`. No new pages created.

**New content:**
1. **Multi-SM synchronization** — `pio_enable_sm_mask_in_sync` (atomic enable + clock-divider restart); `pio_clkdiv_restart_sm_mask`; `pio_restart_sm_mask`; `pio_set_sm_mask_enabled`; `pio_claim_sm_mask`. Note: disabling a SM does not halt its clock divider — use clkdiv_restart on re-enable if timing precision matters.
2. **`pio_sm_drain_tx_fifo`** — empties TX FIFO via `pull` instructions (disturbs OSR); contrast with `pio_sm_clear_fifos` (discards FIFO without touching SM registers).
3. **Sticky output** (`sm_config_set_out_special`) — re-asserts last OUT/SET value on idle cycles; auxiliary enable pin option.
4. **IN pin masking** (`sm_config_set_in_pin_count`) — RP2350 feature to mask unused IN pins to zero; RP2040 always reads 32 bits.
5. **Default SM config table** — all `pio_get_default_sm_config` defaults documented; warning about `wrap=31` default.
6. **RP2350B GPIO base** — `pio_set_gpio_base(pio, 0|16)` for 48-pin RP2350B; 64-bit pin variants (`pio_sm_set_pindirs_with_mask64`, etc.).

## [2026-04-17] ingest | pico-c-sdk S8 | §5.1.15 hardware_irq + §5.1.16 hardware_pio pt.1 (PDF pp.216–236)

Created `wiki/concepts/hardware-irq.md` (new page). Updated `wiki/concepts/pio-architecture.md`.

**New content:**
1. **hardware-irq.md (new)** — NVIC per-core architecture; IRQ number tables for RP2040 (0–25) and RP2350 (0–51); three handler installation patterns (`irq_set_exclusive_handler`, `irq_add_shared_handler`, static symbol); full API function table; priority model (0–255 inverted, default 0x80; RP2040 top 2 bits, RP2350 top 4 bits); shared `order_priority` (higher = called first, opposite of IRQ priority); vector table dual-core caveat; user IRQs (`irq_set_pending`, core-local, claim/unclaim); `irq_clear` hardware-IRQ limitation.
2. **pio-architecture.md** — added `pio_interrupt_source` enum table (pis_interrupt0-3, pis_smN_tx_fifo_not_full, pis_smN_rx_fifo_not_empty); `pio_set_irqn_source_enabled` generic variant; `pio_mov_status_type` enum (STATUS_TX_LESSTHAN, STATUS_RX_LESSTHAN); compile-time macros section (PIO_NUM, PIO_INSTANCE, PIO_FUNCSEL_NUM, PIO_DREQ_NUM, PIO_IRQ_NUM); added [[hardware-irq]] to related pages.

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

## [2026-04-16] ingest | Fairhead Ch.9 – Getting Started With The SPI Bus | CS timing quirk added to rp2040-spi

- Updated `wiki/concepts/rp2040-spi.md` — added "## CS Timing Quirk" section (0.7 µs pre-deassert hazard, half-period delay fix); added `[[fairhead-pico-c]]` to sources.
- Updated `wiki/sources/fairhead-pico-c.md` — marked Ch.9 `[x]`, added key facts section (note: RIA uses USB MSC, not SPI, for storage).

## [2026-04-16] ingest | Fairhead Ch.18 – Multicore and FreeRTOS | race conditions and FreeRTOS model added to dual-core-sio

- Updated `wiki/concepts/dual-core-sio.md` — added "Race conditions and memory atomicity" section (tearing, update loss, 32-bit atomicity table), "FreeRTOS SMP overview" section (task model, why RIA avoids RTOS, WiFi+FreeRTOS integration notes, synchronization comparison table, xQueue producer-consumer pattern).
- Updated `wiki/sources/fairhead-pico-c.md` — marked Ch.18 `[x]`.

## [2026-04-16] ingest | Fairhead Ch.17 – Direct To The Hardware | SIO GPIO registers and GPIO coprocessor added to dual-core-sio

- Updated `wiki/concepts/dual-core-sio.md` — added SIO GPIO register offset table (Pico vs Pico 2 diff), SIO speed benchmark (4 ns at 50 MHz), GPIO coprocessor (RP2350 inline asm), GPIO event register format (4 bits per GPIO), per-core IRQ control register.
- Updated `wiki/sources/fairhead-pico-c.md` — marked Ch.17 `[x]`.

## [2026-04-16] ingest | Fairhead Ch.13 – DHT22 Custom Protocol | PIO design patterns added to pio-architecture

- Updated `wiki/concepts/pio-architecture.md` — added "Custom protocol design patterns" subsection: sampling vs counting, parameterized PIO startup via TX FIFO, bidirectional/open-collector pin pattern, `jmp pin` usage.
- Updated `wiki/sources/fairhead-pico-c.md` — added Ch.13 key facts section; marked `[x]` ingested.
- Marked Ch.13 `[x]` in ingestion plan.

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

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Communication Using SPI (PDF 184–193) — FINAL CHAPTER

New page: [[rp2040-spi]] (SPI basics, CPOL/CPHA modes, 8-entry FIFOs, two-stage clock divider from clk_peri, manual SS in master mode, GPIO pin tables, full SDK API; correction: RIA uses USB MSC not SPI for storage). Updated: [[quadros-rp2040]] scope + SPI facts section, [[index]] (all chapters ingested), [[overview]]. Deleted ingest plan from wiki/inbox — all chapters complete.

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Asynchronous Serial Communication: the UARTs (PDF 172–183)

New page: [[rp2040-uart]] (framing, TX/RX FIFOs + error flags, fractional baud rate from clk_peri, 5 interrupt sources, RTS/CTS flow control, GPIO pin options, full SDK API, RIA UART1/GPIO4-5/115200 8N1). Updated: [[quadros-rp2040]] scope + UART facts section, [[index]] (9/10 chapters done), ingest plan.

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Clock Generation, Timer, Watchdog and RTC (PDF 68–88)

New page: [[rp2040-clocks]] (ROSC/XOSC/PLLs, 10 clock domains, mux architecture, 256 MHz System PLL overclock, 64-bit Timer + alarm pools + pico_time, Watchdog + scratch registers, RTC + repeating alarm). Updated: [[quadros-rp2040]] scope + clock facts section, [[index]], ingest plan (8/10 chapters done).

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — USB Controller (PDF 200–232)

New pages: [[usb-controller]] (USB 1.1 PHY, TinyUSB host/device API, HID boot protocol keyboard/mouse/gamepad, CDC VCP, RP6502-RIA USB host usage table). Updated: [[quadros-rp2040]] scope + USB key facts section, [[rp6502-ria]] related links, [[index]], [[overview]].

## [2026-04-16] ingest | Quadros "Knowing the RP2040" — Memory, Addresses and DMA (PDF 42–67)

New pages: [[rp2040-memory]] (ROM/SRAM banking/Flash/XIP/full address map), [[dma-controller]] (12 channels, DREQ table, control blocks, chaining, CRC sniffing, SDK API). Updated: [[xram]] (DMA section added), [[quadros-rp2040]] scope, [[index]].

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
