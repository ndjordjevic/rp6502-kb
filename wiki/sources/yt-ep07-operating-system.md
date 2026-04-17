---
type: source
tags: [rp6502, youtube, os, posix, memory, xram, protected-mode, colossal-cave]
related: [[development-history]], [[rp6502-os]], [[xram]], [[rp6502-abi]], [[memory-map]], [[pix-bus]], [[youtube-playlist]]
sources: [[youtube-playlist]]
video_id: kf-mvyL70bc
episode: 7
approx_date: 2023-06
created: 2026-04-17
updated: 2026-04-17
---

# Ep7 — The Operating System - featuring Colossal Cave Adventure

**Summary**: The author retrospectively declares RP6502-OS an operating system — not because it was a design goal, but because it emerged from wanting to run POSIX-like software. The OS architecture, memory model, and the "32 bytes is all I ask" philosophy are explained. Colossal Cave Adventure (a full Linux port) runs unmodified on the 6502.

**Video**: [https://www.youtube.com/watch?v=kf-mvyL70bc](https://www.youtube.com/watch?v=kf-mvyL70bc)

---

## Key topics

- **"I never set a goal of making an operating system"** — the OS emerged: "if you want to run POSIX-like software you'll eventually find yourself writing the kernel for a POSIX-like operating system." The OS has no formal name at this point; its creation is described as "mostly a retrospective declaration."
- **"All I ask for is 32 bytes"** — the RIA's entire claim on the 6502 address space. The last 256 bytes are reserved for I/O devices; within that, only the last 32 (`$FFE0–$FFFF`) are the RIA. Everything else is free RAM.
- **Memory model at Ep7**: 64 K RAM (minus last 256 bytes for I/O hardware) for userland. Second 64 K (**VRAM / XRAM**) is shared between userland, kernel, video, and audio — you can't run 6502 code from it directly, but you don't need to put graphics or audio data in program memory.
- **Protection model** — because all kernel calls go through the RIA, a crashing 6502 program cannot bring down the kernel. No memory manager or address isolation on the RP2040 ARM side (Cortex-M0+, at this time), but the hardware boundary between the 6502 bus and the RIA register space provides de-facto protection.
- **OS size** — over 1 MB when networking + code pages are linked in. Entirely optional: "it completely vanishes when you want some 8-bit challenges."
- **RIA hardware note (historical)** — Ep7 describes "two Arm Cortex-M0+ processors" (RP2040-era). The current [[rp6502-ria]] uses RP2350 (Cortex-M33). One core runs the hot RIA loop (no interrupts tolerated); the other runs the kernel. Architecture unchanged — only the silicon generation differs.
- **Device drivers listed** — HID (keyboard/mouse/joystick), USB mass storage, littlefs (internal flash), FatFs (USB drives), UART (stdin/stdout), configuration management. RTC and networking not yet started.
- **PIX bus status** — not yet working at this point; VGA limited to ANSI terminal emulation. "Getting the PIX bus working is the next priority."
- **Colossal Cave Adventure demo** — Crowther & Woods version ported to C, compiled for 6502, run directly from USB drive. 45 K executable; POSIX file reads for data files; save/load to USB drive works. No modifications to the source — the POSIX API compatibility made it work as-is.
- **No EPROMs ever** — development done entirely without EPROMs or programmers since the 1980s, never needed.

## Historical context

> At the time of Ep7 the design used RP2040 (Cortex-M0+). The RP2350 migration happened at v0.10. See [[version-history]] and [[development-history]] Era E. The "32 bytes" claim and POSIX-OS-emergence framing are stable and still accurate.

## Related pages

- [[development-history]] — Era B: OS emergence narrative
- [[rp6502-os]] — current OS entity page
- [[xram]] — the second 64 K shared between userland/kernel/video/audio
- [[rp6502-abi]] — calling convention through the 32-byte RIA window
- [[memory-map]] — 64 K + 64 K layout
- [[pix-bus]] — "next priority" at this episode
- [[youtube-playlist]] — full episode list
