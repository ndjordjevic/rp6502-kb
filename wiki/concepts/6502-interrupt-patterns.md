---
type: concept
tags: [6502, 65c02, assembly, interrupts, irq, nmi, isr, rp6502, via, ring-buffer, real-time-clock]
related: [[65c02-instruction-set]], [[hardware-irq]], [[rp6502-abi]], [[w65c02s]], [[w65c22s]], [[6522-via]]
sources: [[leventhal-6502-assembly]], [[leventhal-subroutines]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Interrupt Patterns

**Summary**: How the 6502/65C02 interrupt system works from the programmer's side — interrupt vectors, the IRQ/NMI/BRK/RESET response sequence, saving and restoring registers in ISRs, polling vs. vectored dispatch, and design guidelines for reliable interrupt-driven code.

---

## The 6502 interrupt model

The 6502 has three interrupt inputs:

| Signal | Type | Vector address | Edge/Level |
|--------|------|---------------|------------|
| `IRQB` | Maskable (active-low) | `$FFFE/$FFFF` | Level-sensitive |
| `NMIB` | Non-maskable (active-low) | `$FFFA/$FFFB` | **Edge-sensitive** |
| `RESB` | Reset (active-low) | `$FFFC/$FFFD` | Level-sensitive |

`BRK` (software interrupt) shares the `IRQB` vector (`$FFFE/$FFFF`).

The CPU checks interrupt state at the **end of each instruction**. If `IRQB` is asserted and P.I=0, the CPU accepts the interrupt.

> **RP6502 note**: On the RP6502, `IRQB` and `NMIB` are driven by the RIA firmware to signal OS call completion and external events. The W65C22S VIA at `$FFD0–$FFDF` can also generate `IRQB`. See [[w65c22s]] and [[rp6502-abi]].

---

## Interrupt response sequence

When the CPU accepts an interrupt (IRQ, NMI, or BRK):

1. Complete the current instruction.
2. Push **PC high byte** onto stack.
3. Push **PC low byte** onto stack.
4. Push **P** (processor status) onto stack — with **B=0** for hardware interrupts (B=1 for BRK).
5. Set **P.I = 1** (disable further maskable interrupts).
6. **Clear P.D = 0** (65C02 only — NMOS leaves D unchanged).
7. Load **PC** from the vector pair (LSB at lower address, MSB at upper).

Stack layout after interrupt response:

```
SP+3  PCH   (high byte of interrupted address)
SP+2  PCL   (low byte)
SP+1  P     (status, B=0 for IRQ/NMI, B=1 for BRK)
SP    →     (next empty slot, SP now points here)
```

### RESET differs

RESET also loads `$FFFC/$FFFD` into PC, but does **not** push anything onto the stack. It simply sets P.I=1 and jumps to the reset vector.

---

## IRQ vs. BRK — distinguishing them

Both use vector `$FFFE/$FFFF`. Distinguish by examining the **B flag in the copy of P on the stack** (not in the live P register):

```asm
; At the start of the shared IRQ/BRK handler:
PLA             ; pull P from stack
AND #%00010000  ; test B flag (bit 4)
BNE BREAK       ; if B=1, it was BRK
; otherwise it was a hardware IRQ
; (must push P back, or use a peek approach)
```

A cleaner approach is to point the IRQ vector at a routine that immediately reads the saved P to dispatch:

```asm
IRQHND:
    PLA               ; pull P copy
    PHA               ; push it back (preserve stack balance)
    AND  #%00010000
    BNE  BRKRTN
    JMP  HWIRQ        ; hardware interrupt service
BRKRTN:
    JMP  MONITOR      ; BRK → return to monitor/debugger
```

---

## Register save/restore in ISRs

The 6502 automatically saves only **PC** and **P** on interrupt. Registers A, X, Y are **not** saved — the ISR must save anything it will modify.

### Standard save sequence

```asm
ISRENTRY:
    PHA         ; save A
    TXA
    PHA         ; save X (via A)
    TYA
    PHA         ; save Y (via A)
    ; ... interrupt service body ...
    PLA
    TAY         ; restore Y
    PLA
    TAX         ; restore X
    PLA         ; restore A
    RTI         ; restore P and PC
```

**Rule**: A must be saved first (because TXA/TYA overwrite it); restored last. The sequence is strictly LIFO (stack).

> With the **65C02**: `PHX` / `PHY` / `PLX` / `PLY` let you save/restore X and Y directly without routing through A, saving 2 instructions per register:
>
> ```asm
>     PHA
>     PHX         ; 65C02
>     PHY         ; 65C02
>     ; ... body ...
>     PLY
>     PLX
>     PLA
>     RTI
> ```

### Golden rule

**No ISR should ever alter any register without first saving it and later restoring it.** An ISR that trashes A, X, or Y will corrupt the main program in ways that are extremely difficult to debug (rare, timing-dependent failures).

---

## RTI — return from interrupt

`RTI` (opcode `40`) reverses the interrupt response:

1. Increment SP; pull **P** from stack (restoring I flag to its pre-interrupt value).
2. Increment SP; pull **PCL**.
3. Increment SP; pull **PCH**.

Key differences from `RTS`:
- `RTI` restores P (including the I flag) — so interrupts are **automatically re-enabled** if they were enabled before.
- `RTI` does **not** add 1 to the pulled address (unlike `RTS`, which compensates for JSR's off-by-one save).

To **prevent re-enabling interrupts** after RTI, set the I bit in the saved copy on the stack before `RTI`.

---

## Enabling and disabling interrupts

| Instruction | Effect |
|-------------|--------|
| `CLI` | Clear I flag — **enable** maskable interrupts |
| `SEI` | Set I flag — **disable** maskable interrupts |
| `RTI` | Restores I from the pre-interrupt P |
| `BRK` | Pushes P then sets I=1 |

**Initialization order**: always configure peripheral interrupt enable bits and load the stack pointer **before** issuing `CLI`. Enabling the CPU interrupt before the stack is set up leaves a window where an interrupt would corrupt random memory.

---

## Polling vs. vectored dispatch

### Polling (most 6502 systems)

Because the 6502 has only one external maskable interrupt line, all IRQ sources are ORed together onto `IRQB`. The ISR must poll each device to find the source:

```asm
; Poll VIA Interrupt Flag Register bit 7
; (bit 7 = 1 if any interrupt is both active and enabled)
ISRPOLL:
    BIT VIAIFR          ; test VIA first
    BMI VIAINT          ; bit 7 set → VIA has an interrupt
    BIT ACIASR          ; test ACIA
    BMI ACIAINT
    ; ... etc.
```

**Polling priority** = order of checking: the first device polled has the highest effective priority.

### Clearing peripheral interrupt flags

The ISR **must** clear the peripheral's own flag; `RTI` does not do this.

- **6522 VIA**: write 1 to the appropriate bit of IFR, or read/write the port register that caused the interrupt.
- **General**: each device has its own clearing mechanism — check the device datasheet.

Failure to clear the flag results in an immediate re-interrupt after `RTI`.

### Vectored interrupts (hardware-assisted)

Hardware can substitute a unique vector for each source when the 6502 acknowledges the interrupt (by monitoring `$FFFE/$FFFF` on the address bus and driving a different data byte). This is device-specific and not covered here.

---

## ISR design guidelines

1. **Keep ISRs short.** Long ISRs delay other interrupts, reduce timing precision, and increase the chance of stack overflow.
2. **Disable interrupts as briefly as possible.** Use `SEI`/`CLI` pairs around only the minimum critical section.
3. **Use the stack for all temporary storage.** This makes the ISR reentrant.
4. **Clear interrupt flags explicitly** in the ISR body for level-sensitive sources.
5. **Real-time clock ISRs** should be the highest priority (poll them first). The body should be as short as possible — typically just increment a counter and clear the flag.
6. **Double buffering**: while the ISR fills one buffer, the main program processes the other. Avoids CPU stalls and supports continuous streaming I/O.
7. **Changing the return address**: the saved PC is at `$0102,X` (LSB) and `$0103,X` (MSB) after `TSX`. Modify it to skip or redirect the return point.

---

## Non-maskable interrupt (NMI)

- **Edge-triggered** (falling edge of `NMIB`), so a single pulse triggers exactly one NMI regardless of duration.
- Cannot be disabled by P.I.
- Primary use: **power-fail detection** — save critical state to battery-backed RAM.
- The ISR body is the same structure as an IRQ ISR (save registers, service, restore, RTI).

---

## RP6502 context

On the RP6502, the RIA manages both `IRQB` and `NMIB` lines. User programs typically do not install their own interrupt handlers — OS calls complete asynchronously and signal via the `RIA_SPIN` stub (a polling mechanism, not a true interrupt). However, the W65C22S VIA can generate `IRQB` for user-defined timing or GPIO events. See [[rp6502-abi]] for the OS call model and [[w65c22s]] for VIA interrupt configuration.

---

## 6522 VIA unbuffered interrupt-driven I/O (PINTIO pattern)

Leventhal 1982 Ch. 11B documents a complete interrupt-driven I/O system for the **6522 VIA** with single-character buffers. This is the most RP6502-relevant interrupt pattern because the W65C22S VIA is the hardware interrupt source on the board.

### Architecture: 6 subroutines, 194 bytes, 7 bytes data

| Routine | Purpose | Cycles |
|---------|---------|--------|
| `INCH` | Read character from input buffer (waits) | 33 if char available |
| `INST` | Test input buffer non-blocking (Carry = 1 if char ready) | 12 |
| `OUTCH` | Write character to output buffer (waits for space) | 83 if buffer empty + VIA ready |
| `OUTST` | Test output buffer non-blocking (Carry = 1 if full) | 12 |
| `INIT` | Initialise VIA, interrupt vectors, software flags | 93 |
| `IOSRVC` | ISR: determines interrupt source, services input or output | 43/81/24 |

**Data variables** (7 bytes in RAM):
- `RECDAT` — last received byte (input buffer, 1 byte)
- `RECDF` — receive data flag: `$FF` = character ready, `0` = empty
- `TRNDAT` — byte to transmit (output buffer, 1 byte)
- `TRNDF` — transmit data flag: `$FF` = data waiting, `0` = buffer empty
- `OIE` — Output Interrupt Enable flag: `$FF` = interrupt has not fired unserviced, `0` = interrupt fired without data available
- `NEXTSR` — 2-byte pointer to next interrupt service routine (for chaining)

### ISR structure (IOSRVC)

```asm
IOSRVC:
    PHA
    CLD                      ; always binary mode in ISR
    LDA VIAIFR               ; read VIA Interrupt Flag Register
    AND #%00000010           ; test bit 1 = CA1 (input interrupt)
    BNE IINT                 ; → service input interrupt
    LDA VIAIFR
    AND #%00010000           ; test bit 4 = CB1 (output interrupt)
    BNE OINT                 ; → service output interrupt
    PLA
    JMP (NEXTSR)             ; not our interrupt → chain to next handler

IINT:
    LDA VIAADR               ; read Port A (clears CA1 flag + pulses CA2 handshake)
    STA RECDAT               ; store in input buffer
    LDA #$FF
    STA RECDF                ; signal data ready
    JMP EXIT

OINT:
    LDA TRNDF                ; any data to send?
    BNE NODATA
    JSR OUTDAT               ; → send TRNDAT to Port B, clear TRNDF, set OIE
    JMP EXIT
NODATA:
    LDA VIABDR               ; read Port B to clear CB1 interrupt without sending data
    LDA #0
    STA OIE                  ; record: interrupt fired but no data was available
EXIT:
    PLA
    RTI
```

### Key design decisions

1. **Unserviced output interrupt problem**: A VIA output interrupt can fire before the main program has data ready. Reading the Port B register clears the interrupt flag without actually sending data. The `OIE` flag records this situation so that `OUTCH` can send the data immediately (bypassing the wait for the next interrupt) when data later becomes available.

2. **Input interrupt auto-clears**: Reading `VIAADR` (Port A with handshake, Reg 1) both reads the data **and** pulses CA2 for the handshake acknowledgement. The CA1 IFR bit is automatically cleared by the read.

3. **Atomic flag access**: `OUTCH` and `INCH` use `SEI`/`PLP` around flag accesses to prevent the ISR from modifying the flags while the main program reads or writes them.

### INIT configuration (typical)

```asm
; Port A = input (DDR = $00), Port B = output (DDR = $FF)
; PCR: CA1 low-to-high active; CA2 pulse output (input acknowledge)
;      CB1 low-to-high active; CB2 write strobe
; ACR: enable Port A input latching
; IER: enable CA1 (input) and CB1 (output) interrupts

LDA #$00 : STA VIAADD        ; Port A = all inputs
LDA #$FF : STA VIABDD        ; Port B = all outputs
LDA #%10001010 : STA VIAPCR  ; CA2 pulse, CB2 write strobe
LDA #%00000001 : STA VIAACR  ; Port A latching enabled
LDA #%10010010 : STA VIAIER  ; enable CA1 (bit1) + CB1 (bit4)
```

---

## Buffered interrupt-driven I/O (ring-buffer pattern, Ch. 11C)

For sustained high-throughput I/O (e.g., a 6850 ACIA serial port), a ring buffer replaces the single-character flags. This pattern eliminates the need for the main program to keep pace with every character interrupt.

### Ring buffer layout

```
RDBUF:  .BLOCK BUFSIZ    ; circular receive buffer
RDHEAD: .BLOCK 1          ; index of next byte to read (consumer pointer)
RDTAIL: .BLOCK 1          ; index of next free slot (producer pointer, updated by ISR)
BUFSIZ = 16               ; must be a power of 2 for easy modulo
```

**ISR enqueue** (runs on each character received):
```asm
LDA ACIADAT              ; read received byte (clears ACIA interrupt)
LDX RDTAIL
STA RDBUF,X              ; store in buffer
INX
TXA
AND #(BUFSIZ-1)          ; wrap pointer (mod BUFSIZ)
STA RDTAIL               ; update tail
; (no overflow check in minimal form — add buffer-full detection as needed)
RTI
```

**Main program dequeue**:
```asm
GETCHAR:
    LDA RDHEAD
    CMP RDTAIL            ; head == tail → buffer empty
    BEQ GETCHAR           ; spin-wait for a character
    TAX
    LDA RDBUF,X           ; read the character
    INX
    TXA
    AND #(BUFSIZ-1)
    STA RDHEAD
    RTS
```

**Design notes**:
- Keep the ISR as short as possible — just enqueue and `RTI`.
- Buffer size must be large enough to absorb the burst rate × interrupt latency.
- On 65C02, `PHX`/`PLX` saves 2 instructions in the ISR compared to routing through A.
- Never modify both `RDHEAD` and `RDTAIL` from the same context (ISR owns `RDTAIL`; main program owns `RDHEAD`). No locking needed for a single-producer, single-consumer ring buffer.

---

## Real-time clock / calendar (CLOCK pattern, Ch. 11D)

Leventhal 1982 Ch. 11D provides a timer-interrupt–based clock that maintains seconds, minutes, hours, day, month, and year — driven by a configurable tick rate (typically 60 Hz or 100 Hz).

### Clock variable layout (18 bytes in RAM)

```
ACVAR:   ; base address (returned by CLOCK subroutine)
  TICK   .BLOCK 1   ; ticks remaining until next second (counts down from DTICK)
  SEC    .BLOCK 1   ; seconds   0–59
  MIN    .BLOCK 1   ; minutes   0–59
  HOUR   .BLOCK 1   ; hours     0–23
  DAY    .BLOCK 1   ; day       1–28/30/31 (depends on month)
  MONTH  .BLOCK 1   ; month     1–12
  YEAR   .BLOCK 2   ; year      (16-bit, LSB first)

DFLTS:   ; default initial values (8 bytes, same layout as ACVAR)
  DTICK  .BLOCK 1   ; ticks per second (e.g., 60 for 60 Hz timer)
  ; ... other defaults ...

NEXTSR   .BLOCK 2   ; chained interrupt service routine pointer
```

### CLKINT ISR structure

```asm
CLKINT:
    PHA : TXA : PHA : TYA : PHA    ; save all registers
    CLD                             ; force binary mode
    ; Check if this interrupt is ours (hardware-specific flag)
    LDA CLKPRT : AND #CLKIM
    BNE OURINT                      ; not ours → chain
    PLA : JMP (NEXTSR)

OURINT:
    DEC TICK
    BNE EXIT                        ; not yet a full second → done
    LDA DTICK : STA TICK            ; reset tick counter

    ; Cascade: seconds → minutes → hours → day → month → year
    INC SEC : LDA SEC : CMP #60 : BCC EXIT
    LDA #0 : STA SEC
    INC MIN : LDA MIN : CMP #60 : BCC EXIT
    LDA #0 : STA MIN
    INC HOUR : LDA HOUR : CMP #24 : BCC EXIT
    LDA #0 : STA HOUR
    INC DAY
    ; Check last day of month (using LASTDY table, with leap-year correction for Feb)
    LDX MONTH
    LDA DAY : CMP LASTDY-1,X : BCC EXIT
    ; Leap year check: if MONTH=2 and (YEAR AND $03)==0, Feb has 29 days
    CPX #2 : BNE INCMTH
    LDA YEAR : AND #$03 : BNE INCMTH  ; not a leap year
    LDA DAY : CMP #29 : BEQ EXIT       ; Feb 29 in leap year → ok
INCMTH:
    LDA #1 : STA DAY
    INC MONTH : LDA MONTH : CMP #13 : BCC EXIT
    LDA #1 : STA MONTH
    INC YEAR : BNE EXIT : INC YEAR+1  ; 16-bit year increment
EXIT:
    PLA : TAY : PLA : TAX : PLA
    RTI
```

### Design notes

- **Tick rate**: set `DTICK` to the interrupt frequency (60 for 60 Hz, 100 for 100 Hz). The ISR counts ticks down to zero; only when TICK reaches 0 does it update seconds and the cascade chain.
- **Worst case**: 184 cycles (year rollover). Average case: 33 cycles (tick decrement only).
- **Leap year test**: `YEAR AND $03 == 0` — checks only the two LSBs of the year (mod 4). Sufficient for dates within a 4-year window; does not handle century exceptions (years divisible by 100 but not 400).
- **Reading the clock**: call `CLOCK` to get the base address of ACVAR, then read variables with `SEI`/`CLI` bracketing to prevent a mid-read update:

```asm
JSR CLOCK             ; A:Y = address of ACVAR
STY CLKBASE : STA CLKBASE+1
SEI                   ; prevent clock update while reading
LDY #0
LDA (CLKBASE),Y       ; TICK
INY : LDA (CLKBASE),Y ; SEC
; ... etc.
CLI
```

- **RP6502 context**: the RIA firmware provides its own real-time clock via OS calls. This pattern is relevant for custom hardware or when timer interrupt precision is needed beyond what the OS provides. See [[rp6502-abi]].

---

## Related pages

- [[65c02-instruction-set]] — RTI, BRK, CLI/SEI opcodes
- [[hardware-irq]] — RP2350 NVIC (RIA firmware side of the same interrupt signals)
- [[rp6502-abi]] — RIA_SPIN polling model (alternative to true interrupts)
- [[w65c22s]] — VIA interrupt enable/flag registers (RP6502 specific)
- [[w65c02s]] — CPU interrupt pins and timing
- [[6522-via]] — full VIA register reference (IFR, IER, PCR, ACR, timers)
