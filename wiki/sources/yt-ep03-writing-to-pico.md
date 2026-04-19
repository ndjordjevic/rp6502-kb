---
type: source
tags: [rp6502, youtube, pio, dma, hardware, glue-logic, chip-select, ac-chips, 6522]
related:
  - "[[development-history]]"
  - "[[pio-architecture]]"
  - "[[memory-map]]"
  - "[[ria-registers]]"
  - "[[known-issues]]"
  - "[[rp6502-board]]"
  - "[[youtube-playlist]]"
sources:
  - "[[youtube-playlist]]"
video_id: wxV6x5BUMH4
episode: 3
approx_date: 2023-01
created: 2026-04-17
updated: 2026-04-17
---

# Ep3 — Writing to the Raspberry Pi Pico - More PIO and DMA

**Summary**: The write path (6502 → RIA) is implemented, the glue logic is explained in full, and a critical speed barrier at 7.7 MHz is diagnosed (74HC propagation delay) and fixed by switching two chips to 74AC. The RIA name is coined.

**Video**: [https://www.youtube.com/watch?v=wxV6x5BUMH4](https://www.youtube.com/watch?v=wxV6x5BUMH4)

---

## Key topics

- **RIA name origin** — the interface adapter needed a name; "RIA wasn't taken," by analogy with PIA, CIA, TIA, and VIA. First use of the term "RIA."
- **Glue logic breakdown** — four groups: (1) RAM write synchronization NAND (prevents data corruption when address and R/W̄ change simultaneously); (2) interrupt OR (combines RIA and 6522 IRQ); (3) 7430 eight-input NAND for I/O page detection (`$FF00–$FFFF`); (4) address decoding for RIA at `$FFE0` (4 gates) and 6522 at `$FF00` (leverages 6522 internal CS logic to save a chip).
- **6522 VIA role** — provides timers and GPIO for legacy 6502 software; since USB handles HID, all 6522 GPIO pins are free for user expansion.
- **PIO write program** — must know both chip-select and R/W̄ to control data bus direction. Three-state truth table: not-selected (hi-Z), read (drive bus), write (hi-Z input). This is the `ria_cs_rwb` + `ria_write` pair in [[pio-architecture]].
- **AC-chip discovery** — HC-family chips (~15 ns/gate) through 4 gates = ~60 ns propagation. System failed at 7.7 MHz. Switching to AC-family reduced propagation to ~35 ns → stable at 8 MHz, tested to 9 MHz.
- **Design rule for 8 MHz** — "Requiring AC chips for 8 MHz is reasonable; HC chips fall back to 4 MHz." RIA can self-test and advertise available speed to software. See [[known-issues]].

## Historical context

> This episode established the final breadboard design. The [[rp6502-board]] production PCB later optimized the IC count from ~12 to 8 through further logic consolidation. The AC/HC speed distinction is a permanent hardware requirement still documented in [[known-issues]].

## Related pages

- [[development-history]] — Era A: RIA naming, AC-chip discovery, 8 MHz barrier
- [[known-issues]] — AC chips required for 8 MHz; HC chips default to 4 MHz
- [[pio-architecture]] — write-side PIO with chip-select gating (`ria_write`, `ria_cs_rwb`)
- [[ria-registers]] — the 32-byte register space decoded by this glue logic
- [[rp6502-board]] — final PCB (8 ICs, down from this breadboard's count)
- [[youtube-playlist]] — full episode list
