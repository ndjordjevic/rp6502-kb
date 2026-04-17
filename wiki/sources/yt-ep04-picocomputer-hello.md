---
type: source
tags: [rp6502, youtube, assembly, monitor, abi, ria, bootstrap, fast-load]
related: [[development-history]], [[rp6502-abi]], [[ria-registers]], [[pio-architecture]], [[memory-map]], [[youtube-playlist]]
sources: [[youtube-playlist]]
video_id: uL8BL7ZDdlk
episode: 4
approx_date: 2023-01
created: 2026-04-17
updated: 2026-04-17
---

# Ep4 — The Picocomputer says hello!

**Summary**: First working demo — a Hello World program runs in 6502 assembly at 8 MHz. The monitor architecture is explained; the early prototype of the `RIA_SPIN` fast-load pattern is described, requiring three CPUs, two PIOs, and DMA to copy a single byte across the bus.

**Video**: [https://www.youtube.com/watch?v=uL8BL7ZDdlk](https://www.youtube.com/watch?v=uL8BL7ZDdlk)

---

## Key topics

- **Schematic release** — "8-Bit Expeditionary Force" schematic published; breadboard builds possible from this episode onward.
- **Monitor architecture** — the monitor runs on the RIA Pico, not the 6502. Since only 5 address lines connect the Pi Pico to the bus, the RIA cannot directly address all 64 K. Instead it launches a 10-byte 6502 program to copy memory, intercepted in real time.
- **Fast-load pattern prototype** (genesis of `RIA_SPIN`) — a template program in the 32-byte register space loops writing `value` to `address` forever. The RIA modifies value, address, and the branch instruction in real time (< 200 ns window at 8 MHz) to drive each byte of a bulk transfer. Writing one byte requires three CPUs, two PIOs, and DMA. This became the `RIA_SPIN` stub at `$FFF0–$FFF7`. See [[rp6502-abi]] and [[ria-registers]].
- **6502 startup garbage** — first 7 clock cycles after RESB, the 6502 drives garbage onto the address bus. Fix: use a NOP for alignment and ensure the program counter is at a known location before each shutdown.
- **Early I/O addresses** — `$FFEE` = write to serial port (USB console); `$FFEF` = shut down 6502 (return control to monitor). Earliest documented RIA register assignments.
- **Third PIO program (`ria_action`)** — triggers on specific address accesses; consumed by a dedicated ARM Cortex core loop for real-time OS-call dispatch.
- **Hello World demo** — 6502 assembly, 8 opcodes (LDX, LDA abs,X, STA abs, INX, CMP #0, BNE, JMP). Demonstrated at both 8 MHz and 1 kHz.
- **Debugging lessons** — intermittent failure: (1) missing `volatile` caused compiler to optimize away instrumentation; (2) ground noise on breadboard.

## Historical context

> The fast-load pattern described here is the direct ancestor of the production `RIA_SPIN` stub. The 10-byte bootloader fit in the 26 usable bytes of the `$FFE0–$FFFF` space. See [[development-history]] Era A for the full context.

## Related pages

- [[development-history]] — Era A: first working demo, fast-load pattern origin
- [[rp6502-abi]] — `RIA_SPIN` stub at `$FFF0–$FFF7`: the production form of this prototype
- [[ria-registers]] — `$FFEE`/`$FFEF` early I/O; full register map including `RIA_SPIN`
- [[pio-architecture]] — `ria_action` (third PIO program) introduced here
- [[memory-map]] — memory layout used in this demo
- [[youtube-playlist]] — full episode list
