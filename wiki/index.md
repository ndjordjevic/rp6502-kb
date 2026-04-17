# Wiki Index

Catalog of all pages in this wiki. Updated by Claude at the end of every session.
When answering a query, read this file first to find relevant pages, then drill in.

## Sources

*Pages summarizing raw source documents.*

| Page | Description |
| --- | --- |
| [[picocomputer-intro]] | Landing page: project pitch, specs, links to all subsystems |
| [[hardware]] | Build guide, schematic link, full BOM, parts substitution rules |
| [[rp6502-ria-docs]] | RIA firmware reference: monitor, PIX, XRAM, input, audio, NFC, ROM format |
| [[rp6502-ria-w-docs]] | Wireless additions: WiFi setup, NTP, Hayes modem, BLE pairing |
| [[rp6502-vga-docs]] | VGA module: 3-plane scanline video, 6 modes, control channel, ANSI terminal |
| [[rp6502-os-docs]] | Protected OS: memory map, ABI, full POSIX-flavored API surface |
| [[rp6502-github-repo]] | Monorepo source at commit 368ed8e: complete API op-codes, register map, GPIO pinout, PIO layout |
| [[release-notes]] | All 23 releases v0.1–v0.23: feature introduction dates, breaking changes, known issues |
| [[quadros-rp2040]] | "Knowing the RP2040" (Quadros, 2022): hardware reference — architecture, PIO ISA, GPIO, interrupts, dual-core/SIO, DMA, USB, clocks, UART, SPI (all planned chapters ingested) |
| [[fairhead-pico-c]] | "Programming the Raspberry Pi Pico/W in C" (Fairhead, 3rd ed. 2025): SDK programming — PIO, GPIO, multicore, FreeRTOS, WiFi, SPI, UART (all planned chapters ingested) |
| [[pico-c-sdk]] | Raspberry Pi Pico-series C/C++ SDK (RP-009085-KB-1, 2025): official API reference — function signatures, PIOASM encoding, RP2040/RP2350 compat table; all 14 sessions ingested ✅ |
| [[rp2350-datasheet]] | RP2350 datasheet (RP-008373-DS-2, 2025-07-29): authoritative RP2350 hardware reference — SIO/TMDS, clocks/LPOSC, GPIO F0–F11, PIO v1, DMA (16-ch), USB, UART, SPI, HSTX, errata E1–E28; all 14 sessions ingested ✅ |

## Entities

*Named things: boards, chips, signals, buses, firmware variants.*

| Page | Description |
| --- | --- |
| [[rp6502-board]] | Reference PCB (Rev B): 150×100 mm, 8 ICs, 100% through-hole |
| [[w65c02s]] | The actual 65C02 CPU (WDC, U1, 0.1–8.0 MHz) |
| [[w65c22s]] | 65C22 VIA at `$FFD0-$FFDF` (WDC, U5) |
| [[rp6502-ria]] | RP6502 Interface Adapter: Pi Pico 2 + RIA firmware. Required. |
| [[rp6502-ria-w]] | Wireless RIA superset: WiFi 4 + BLE HID + Hayes modem |
| [[rp6502-vga]] | Optional Pi Pico 2 + VGA firmware video adapter |
| [[rp6502-os]] | 32-bit protected OS running inside the RIA (POSIX-like API) |
| [[rp2350]] | RP2350 microcontroller: dual Cortex-M33 @ 150 MHz, 520 KB SRAM, 3 PIO blocks, TMDS encoder, HSTX; powers Pi Pico 2 |

## Concepts

*Mechanisms and ideas: protocols, instruction sets, timing, modes.*

| Page | Description |
| --- | --- |
| [[memory-map]] | 6502 address space + extended XRAM space |
| [[pix-bus]] | 5-wire DDR broadcast bus between RIA and PIX devices, 32-bit frame format |
| [[xram]] | 64 K extended RAM inside the RIA, broadcast-replicated across PIX devices |
| [[xreg]] | The "extended register" config mechanism (`xreg(device, channel, addr, val)`) |
| [[rom-file-format]] | `.rp6502` shebang + asset chunks; named ROM-asset filesystem |
| [[rp6502-abi]] | Fastcall-style ABI: XSTACK, short stacking, bulk XRAM, RIA_SPIN |
| [[reset-model]] | RESB is a state, not a pulse; reboot ≠ reset; only the RIA may drive RESB |
| [[launcher]] | Process manager hook for persistent host ROM + native-OS boot pattern |
| [[ria-registers]] | Exact register addresses $FFE0–$FFFF, return stub, full errno table |
| [[api-opcodes]] | Complete OS call dispatch table (op-codes 0x01–0x2E) from main.c |
| [[pio-architecture]] | PIO state machine layout for 65C02 bus interface and PIX; RP2350 overclock; DMA-DREQ integration; dynamic program generation (`pio_encode_*` composition, full JMP variants, `pio_src_dest` enum, wait_pin vs wait_gpio); SM EXEC; v0/v1 ISA encoding; v1-only additions; `pio_interrupt_source` enum; compile-time macros; MOV STATUS type; multi-SM synchronization; sticky output; RP2350B GPIO base |
| [[pioasm]] | PIOASM assembler: complete directive reference, value/expression syntax, output pass-through, generated header structure, v0/v1 ISA opcode table |
| [[gpio-pinout]] | GPIO pin assignments for RIA/VGA Pico confirmed from source; RP2040/RP2350 function select tables; full SDK API (pull state queries, PAD config, interrupt model, concurrency-safe gpio_put_masked, raw handler notes); 64-bit/bank-n RP2350 variants; Erratum E9 |
| [[hardware-irq]] | `hardware_irq` SDK: NVIC per-core semantics, IRQ number tables (RP2040 + RP2350), three handler-install patterns, priority model, user (software) IRQs |
| [[dual-core-sio]] | Two-core ARM model, SIO FIFOs (RP2040: 8 deep, RP2350: 4 deep), lockout mechanism, doorbell API (RP2350), hardware spinlocks (32 locks, number assignment table, RP2350-E2 erratum), memory barriers, processor events, interrupt control, atomic GPIO, full `pico_multicore` + `pico_sync` SDK (critical_section, mutex, recursive_mutex, semaphore with all timeout variants) |
| [[rp2040-memory]] | RP2040 memory types (ROM/SRAM/Flash), SRAM banking, XIP, full APB/AHB address map |
| [[dma-controller]] | 16-channel DMA (RP2350) / 12-channel (RP2040): DREQ tables, control blocks, chaining, CRC sniffing, RP2350 encoded_transfer_count/endless/self-trigger/4-IRQ-lines, SDK API |
| [[usb-controller]] | RP2040/RP2350 USB 1.1 controller: host/device modes, HID boot protocol, CDC VCP, TinyUSB API, RIA host usage; RP2350 PHY_ISO startup requirement |
| [[rp2040-clocks]] | RP2040/RP2350 clock subsystem: ROSC/XOSC/LPOSC/PLLs, clock domains, divisor precision, resus; 256 MHz overclock; `pll_init`/`pll_deinit` SDK functions; Timer (RP2350 two instances, 64-bit µs, full alarm API, compile-time macros); full `pico_time` API (absolute_time_t, sleep/busy_wait, alarm pools, repeating timers); Watchdog, RTC |
| [[rp2040-uart]] | RP2040 UARTs: framing, 32-entry FIFOs + error flags, fractional baud rate, interrupts, hardware flow control, full SDK API (incl. macros `UART_FUNCSEL_NUM` etc.), `uart_deinit`; RIA uses UART1/GPIO4-5/115200 |
| [[rp2040-spi]] | RP2040 SPI: master/slave, 4–16-bit words, CPOL/CPHA modes, manual SS in master mode, DMA DREQ macros, full SDK API (`spi_init`/`spi_deinit`/`spi_get_baudrate`/`spi_get_index`/blocking transfer variants); RIA uses USB MSC (not SPI) for storage |
| [[sdk-architecture]] | Pico SDK build model: CMake INTERFACE libraries, library tiers, hardware claiming, builder pattern, RP2040/RP2350 platform split |
| [[hstx]] | RP2350 HSTX peripheral: DDR serial output up to 300 Mb/s/pin, async FIFO, output shift register, bit crossbar, clock generator, command expander (RAW/TMDS/REPEAT opcodes), PIO-coupled mode, DVI/TMDS example; used by RP6502 VGA firmware |

## Inbox

*Rough notes and planning documents awaiting full organization.*

| Page | Description |
| --- | --- |
## Syntheses

*Answers to queries worth keeping; comparisons; analyses.*

| Page | Description |
| --- | --- |

## Topics

*Operational pages: getting-started, known-issues, toolchain guides.*

| Page | Description |
| --- | --- |
| [[overview]] | Living synthesis across all sources (revised after every ingest) |
| [[version-history]] | Narrative history from v0.1 (2023) to v0.23 (2026), organized by era |
| [[known-issues]] | Bugs, workarounds, and things to watch out for — from release notes + full RP2350 silicon errata (E1–E28) |
