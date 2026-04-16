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
| [[pio-architecture]] | PIO state machine layout for 65C02 bus interface and PIX; RP2350 overclock |
| [[gpio-pinout]] | GPIO pin assignments for RIA Pico and VGA Pico confirmed from source |
| [[dual-core-sio]] | Two-core ARM model, SIO FIFOs, hardware spinlocks, atomic GPIO, `pico_multicore`/`pico_sync` SDK |
| [[rp2040-memory]] | RP2040 memory types (ROM/SRAM/Flash), SRAM banking, XIP, full APB/AHB address map |
| [[dma-controller]] | 12-channel DMA: DREQ table, control blocks, chaining, CRC sniffing, SDK API |
| [[usb-controller]] | RP2040 USB 1.1 controller: host/device modes, HID boot protocol (keyboard/gamepad), CDC VCP, TinyUSB API, RIA host usage |
| [[rp2040-clocks]] | RP2040 clock subsystem: ROSC/XOSC/PLLs, 10 clock domains, 256 MHz overclock; Timer (64-bit µs, alarm pools), Watchdog, RTC |
| [[rp2040-uart]] | RP2040 UARTs: framing, 32-entry FIFOs + error flags, fractional baud rate, interrupts, hardware flow control, SDK API; RIA uses UART1/GPIO4-5/115200 |
| [[rp2040-spi]] | RP2040 SPI: master/slave, 4–16-bit words, CPOL/CPHA modes, manual SS in master mode, DMA, SDK API; RIA uses USB MSC (not SPI) for storage |

## Inbox

*Rough notes and planning documents awaiting full organization.*

| Page | Description |
| --- | --- |
| [[fairhead-pico-c-ingest-plan]] | Chapter-by-chapter relevance map for "Programming the Raspberry Pi Pico/W in C" (Fairhead, 3rd ed.) |

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
| [[known-issues]] | Bugs, workarounds, and things to watch out for — from release notes |
