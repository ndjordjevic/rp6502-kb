---
type: source
tags: [via, 6522, wdc, w65c22s, hardware, datasheet]
related:
  - "[[w65c22s]]"
  - "[[6522-via]]"
  - "[[via-programming]]"
  - "[[6502-interrupt-patterns]]"
created: 2026-04-18
updated: 2026-04-18
---

# WDC W65C22S Datasheet (March 2004)

**Summary**: Official WDC datasheet for the W65C22S Versatile Interface Adapter — the authoritative hardware reference covering all register functions, timing, pin descriptions, and CMOS-vs-NMOS caveats.

---

## Scope

46-page datasheet, March 2004. All sections ingested.

| Section | Status | Coverage |
|---------|--------|----------|
| §1 — Function Description (pp 7–27) | [x] ingested | Peripheral ports, handshake control, T1/T2 timers, Shift Register, Interrupt operation |
| §2 — Pin Function Description (pp 28–34) | [x] ingested | Pin table, CA/CB control lines, IRQB, PA/PB buffers, RESB, CS, PHI2 |
| §3 — AC/DC Characteristics (pp 35–43) | [x] ingested | Absolute max ratings, DC characteristics (1.8V–5V), AC timing tables at 2/4/8/10/14 MHz |
| §4 — Caveats (p 44) | [x] ingested | 5 caveats distinguishing W65C22S from older 6522/65C22 |
| §5 — Hard Core Model (p 45) | [x] ingested | W65C22C core variant notes |
| §6 — Ordering Information (p 46) | [x] ingested | Part numbering, packages |

---

## Key facts

### Part identification

- Full part number for RP6502 use: **`W65C22S6PL-14`** (40-pin DIP, 14 MHz speed grade)
- Packages: 40-pin PDIP (P), 44-pin PLCC (PL), 44-pin QFP (Q)
- Speed grades: 14 MHz (5V), 10 MHz (3.3V), 8 MHz (3.0V), 4 MHz (2.5V), 2 MHz (1.8V)
- Operating temperature: −40°C to +85°C

### Electrical limits

- VDD: 1.8V to 5.0V (extended CMOS range)
- Absolute max: VDD −0.3 to +7.0V, VIN −0.3 to VDD+0.3V
- PA outputs: drive one standard TTL load
- PB outputs: source 3.0 mA at 1.5V — can directly drive Darlington transistors

### AC timing at 8 MHz (RP6502 operating point)

| Parameter | Symbol | Min | Max | Units |
|-----------|--------|-----|-----|-------|
| Cycle time | tCYC | 125 | — | ns |
| PHI2 pulse width high | tPWH | 62 | — | ns |
| PHI2 pulse width low | tPWL | 63 | — | ns |
| Data Bus Delay (read) | tCDR | — | 35 | ns |
| Peripheral Data Setup (read) | tPCR | 30 | — | ns |
| Data Bus Setup (write) | tDCW | 10 | — | ns |
| Peripheral Data Delay (write) | tCPW | — | 60 | ns |

### Timer timing precision

- **T1 first interrupt**: fires at **N + 1.5 PHI2 cycles** after writing T1C-H (both one-shot and free-run first timeout).
- **T1 free-run subsequent**: fires every **N + 2 PHI2 cycles** (counter reloads from latch after each timeout).
- Practical formula: `count = (PHI2_Hz / interrupt_Hz) - 2` gives correct free-run period.

### T2 one-shot rollover

After T2 reaches zero and sets IFR5, the counter **rolls over to $FFFF and continues decrementing** (two's complement). This allows software to measure elapsed time since the timeout by reading the counter. To re-arm T2, write a new value to T2C-H.

### Shift register direction

- **Shift out**: bit 7 is clocked out first on CB2; simultaneously rotated back to bit 0 (circular shift). IFR2 is NOT set in free-running mode (100).
- **Shift in**: bits enter at bit 0 first and shift toward bit 7.

### Reset behavior

RESB clears most internal registers. **Exceptions — NOT cleared by RESB:**
- T1 counters and latches
- T2 counter
- Shift Register (SR)

T1, T2, SR, and interrupt logic are **disabled** on reset but their register values are indeterminate. Bus holding devices maintain pin levels during reset.

---

## Section 4 — Caveats (W65C22S vs older 6522/65C22)

These five caveats describe important differences from the original NMOS 6522, G65C22, and R65C22:

**Caveat 1 — Internal chip-select to register $0F:**
When the W65C22S is not selected (CS1=0 or CS2B=1), it internally selects register $0F instead of random register reads that older chips produced. Safe for most designs but a compatibility note for software that relied on random-register side effects.

**Caveat 2 — CB1 output can be overdriven:**
When the shift clock is output on CB1, an external device can overpower CB1 without stopping the shift function (high currents result; not recommended). Added for compatibility with systems that arbitrate the clock.

**Caveat 3 — IRQB is totem-pole, NOT open-drain (CRITICAL):**
The W65C22S IRQB output is a **full totem-pole driver** (Logic 0 and Logic 1). The older NMOS and CMOS devices had open-drain IRQB allowing wire-OR to a common CPU IRQ line. **The W65C22S IRQB cannot be wire-OR'd.** If multiple VIAs or other open-drain devices share an IRQ line, the W65C22S must be kept separate or isolated via logic.

**Caveat 4 — Bus holding devices on all pins except PHI2:**
The W65C22S has bus holding devices on all pins (except PHI2). The original NMOS 6522, G65C22, and R65C22 did not. This prevents floating inputs when the bus is released.

**Caveat 5 — No output current limiting:**
W65C22S output pins have no current limiting. The original NMOS 6522 had current limiting resistors in series with PA and PB outputs. Adding series resistors (330Ω typical) is recommended when driving inductive or low-impedance loads from PB.

---

## RP6502-specific notes

- The RP6502 board uses the **W65C22S6TPG-14** (40-pin through-hole DIP, 14 MHz).
- PHI2 for the VIA comes from the RIA; at 8 MHz, one T1/T2 count = 125 ns.
- IRQB from the VIA connects to the 6502 IRQ line through the glue logic (see [[board-circuits]]). Because the W65C22S IRQB is totem-pole, it is routed through a buffer, not wire-OR'd directly.
- The OS and RIA never touch the VIA registers — it behaves as a bare 6522 to application code.

---

## Related pages

- [[w65c22s]] — RP6502-specific entity: address, package, OS interaction
- [[6522-via]] — Complete register reference (updated with datasheet caveats)
- [[via-programming]] — Practical programming guide for the VIA on RP6502
- [[6502-interrupt-patterns]] — ISR design for VIA interrupts
- [[board-circuits]] — How IRQB is routed on the RP6502 board
