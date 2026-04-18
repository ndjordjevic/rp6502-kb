---
type: concept
tags: [rp6502, via, timer, interrupt, gpio, 6522, w65c22s]
related: [[6522-via]], [[w65c22s]], [[6502-interrupt-patterns]], [[memory-map]], [[rp6502-abi]]
sources: [[rp6502-ria-docs]], [[leventhal-subroutines]]
created: 2026-04-18
updated: 2026-04-18
---

# VIA Programming

**Summary**: Practical guide to programming the W65C22S Versatile Interface Adapter on the RP6502 — GPIO configuration, timer-driven interrupts, shift register, and real-time clock patterns.

---

## Overview

The RP6502 includes a **W65C22S VIA** at base address `$FFD0`. It provides:
- 2 bidirectional 8-bit I/O ports (**Port A** and **Port B**)
- 2 programmable 16-bit timers (**T1** and **T2**)
- 1 shift register (**SR**) for serial bit-banging
- Flexible interrupt system — any combination of sources can assert **IRQB**

The VIA's PHI2 clock comes from the RIA, so timer counts directly relate to CPU cycles and thus to wall-clock time.

For the complete internal register map, see [[6522-via]].

---

## Base address and register aliases

```asm
VIA     = $FFD0    ; W65C22S base address on RP6502

; Port registers
VIABDR  = VIA+0    ; Port B data (ORB / IRB)
VIAADR  = VIA+1    ; Port A data with handshake (ORA / IRA)
VIABDD  = VIA+2    ; Port B data direction
VIAADD  = VIA+3    ; Port A data direction
; Timer 1
VIAT1CL = VIA+4    ; T1 counter low (read clears T1 flag)
VIAT1CH = VIA+5    ; T1 counter high (write starts T1)
VIAT1LL = VIA+6    ; T1 latch low
VIAT1LH = VIA+7    ; T1 latch high
; Timer 2
VIAT2CL = VIA+8    ; T2 counter/latch low
VIAT2CH = VIA+9    ; T2 counter high (write starts T2)
; Serial + control
VIASR   = VIA+10   ; Shift register
VIAACR  = VIA+11   ; Auxiliary control register
VIAPCR  = VIA+12   ; Peripheral control register
VIAIFR  = VIA+13   ; Interrupt flag register
VIAIER  = VIA+14   ; Interrupt enable register
```

---

## GPIO — simple output

```asm
; Configure Port B as full output and write $AA
LDA #$FF
STA VIABDD       ; all Port B pins = outputs (DDRB = $FF)
LDA #$AA
STA VIABDR       ; write $AA to Port B output register
```

```asm
; Configure Port A as full input
LDA #$00
STA VIAADD       ; all Port A pins = inputs (DDRA = $00)
LDA VIAADR       ; read Port A (with CA2 handshake)
; ...or use VIA+15 to read Port A without handshake
```

---

## Timer 1 — periodic interrupt

T1 in **continuous mode** (ACR bit 7 = 0, bit 6 = 1) generates a periodic interrupt at a frequency determined by the 16-bit reload value.

**Formula:** `count = (PHI2_Hz / interrupt_Hz) - 2`

At 8 MHz PHI2 and 100 Hz interrupt rate: `count = 8000000 / 100 - 2 = 79998`

```asm
; Set T1 to generate 100 Hz interrupt (8 MHz PHI2)
; count = 79998 = $1387E
T1_LOW  = $7E
T1_HIGH = $38

; Set continuous mode: ACR bits 7:6 = 01
LDA VIAACR
AND #$3F         ; clear bits 7:6
ORA #$40         ; set bit 6 only = continuous mode
STA VIAACR

; Load T1 — write low first, then high triggers the counter
LDA #T1_LOW
STA VIAT1LL      ; write latch low
LDA #T1_HIGH
STA VIAT1CH      ; write counter high — starts timer, loads latch too

; Enable T1 interrupt (bit 6) — bit 7 = 1 means "enable"
LDA #%11000000   ; bit 7 = 1 (enable), bit 6 (T1)
STA VIAIER

; Enable IRQ in 6502
CLI
```

**In the ISR:**

```asm
irq_handler:
    PHA
    PHX

    LDA VIAIFR        ; read interrupt flags
    AND #%01000000    ; check T1 bit
    BEQ not_t1
    LDA VIAT1CL       ; clear T1 flag (reading T1C-L clears it)
    ; ... do periodic work ...

not_t1:
    PLX
    PLA
    RTI
```

See [[6502-interrupt-patterns]] for the full ISR entry/exit protocol.

---

## Timer 1 — one-shot timeout

```asm
; One-shot: ACR bits 7:6 = 00
LDA VIAACR
AND #$3F         ; clear bits 7:6
STA VIAACR

LDA #<TIMEOUT
STA VIAT1LL
LDA #>TIMEOUT
STA VIAT1CH      ; starts T1 countdown; interrupt fires once when it reaches 0
```

---

## Timer 2 — one-shot delay / pulse counter

T2 operates as a 16-bit one-shot (ACR bit 5 = 0) or as a pulse counter on PB6 (ACR bit 5 = 1).

```asm
; One-shot delay of N cycles:
LDA #<N
STA VIAT2CL      ; write low latch
LDA #>N
STA VIAT2CH      ; write high, loads counter and clears T2 flag

; Poll for T2 completion:
wait_t2:
    LDA VIAIFR
    AND #%00100000   ; T2 bit (bit 5)
    BEQ wait_t2
    LDA VIAT2CL      ; clear T2 flag
```

---

## Shift register — serial output

The VIA shift register (SR, `VIA+10`) can clock bits out of the CB2 pin. ACR bits 4:2 = `101` → shift out under T2 control (one-shot, 8 bits at T2 rate).

```asm
; Shift out a byte at T2-derived rate:
LDA VIAACR
AND #$E3         ; clear ACR bits 4:2
ORA #$14         ; ACR[4:2] = 101 (shift out under T2, one-shot)
STA VIAACR

LDA #<BAUD_HALF  ; T2 count = half-bit period
STA VIAT2CL
LDA #>BAUD_HALF
STA VIAT2CH

LDA #$B3         ; byte to shift
STA VIASR        ; loading SR starts the shift (CB2 = data, CB1 = clock)
```

---

## Interrupt sources

| IFR bit | Source | Clear method |
|---------|--------|-------------|
| 6 | T1 timeout | Read T1C-L (VIA+4) |
| 5 | T2 timeout | Read T2C-L (VIA+8) |
| 4 | CB1 active edge | Read/write ORB (VIA+0) |
| 3 | CB2 active edge | Read/write ORB (VIA+0) |
| 2 | Shift register complete | Read/write SR (VIA+10) |
| 1 | CA1 active edge | Read/write ORA (VIA+1) |
| 0 | CA2 active edge | Read/write ORA (VIA+1) |

Enable/disable with IER (`VIA+14`): write with bit 7 = 1 to enable, bit 7 = 0 to disable.

---

## Real-time clock pattern

Use T1 in continuous mode to maintain a software clock updated at a known rate (e.g. 60 Hz = VSYNC, or 100 Hz). Increment tick counters in the T1 ISR and derive seconds/minutes from tick count.

```asm
; In T1 ISR (100 Hz assumed):
inc TICKS        ; 8-bit tick accumulator
bne .exit
inc SECONDS      ; overflow → 1 second elapsed (256 / 100 is wrong; use proper countdown)
; Proper approach: count down 100 ticks to SECONDS
```

For a precise software RTC, decrement a `ticks_until_second` counter; when it reaches 0, reload from 100 (at 100 Hz) and increment the BCD seconds register. See [[6502-interrupt-patterns]] for the full real-time clock example from Leventhal.

---

## Hardware caveats (W65C22S vs original 6522)

These matter when writing VIA code on the RP6502:

- **IRQB cannot be wire-OR'd.** The W65C22S IRQB is totem-pole, not open-drain. Multiple VIAs cannot share an IRQ bus without isolation logic. On RP6502 this is handled by the board's glue logic.
- **T1 period formula:** `count = (PHI2_Hz / interrupt_Hz) - 2`. The "-2" accounts for the N+2 cycle reload delay in free-run mode. First timeout fires at N+1.5 cycles after writing T1C-H.
- **T2 rollover:** after T2 fires, the counter wraps to $FFFF and continues decrementing. Write T2C-H again to re-arm.
- **Reset does not clear T1/T2/SR.** The timers and SR are disabled by RESB but not cleared — initialize explicitly before use.
- **No output current limiting on PA/PB.** The W65C22S lacks series resistors present in NMOS 6522. Add ~330Ω series protection when driving inductive loads.

See [[wdc-w65c22s-datasheet]] for the full caveat list and AC timing tables.

---

## Related pages

- [[6522-via]] — complete internal register map and bit-field reference
- [[w65c22s]] — RP6502-specific VIA instance (mapped address, OS interaction)
- [[6502-interrupt-patterns]] — ISR entry/exit, VIA-driven polling and interrupt I/O
- [[memory-map]] — VIA address in the 6502 address space (`$FFD0`)
- [[rp6502-abi]] — OS calls that complement VIA (time, audio, file I/O)
- [[wdc-w65c22s-datasheet]] — official W65C22S datasheet summary
