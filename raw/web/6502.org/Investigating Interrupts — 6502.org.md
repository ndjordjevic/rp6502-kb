---
title: "Investigating Interrupts — 6502.org"
source: "https://6502.org/tutorials/interrupts.html"
author: "John Pickens"
published:
created: 2026-04-18
description: "Comprehensive 6502/65C02 interrupt primer: IRQ/NMI/BRK mechanics, ISR setup, WAI for ultra-fast interrupt response (1-cycle latency), 65C02 interrupt bug fixes, VIA 6522 usage, RS-232 ring buffer, waveform generator, and comparative performance data."
tags:
  - "clippings"
---

# 6502.org Tutorials: Investigating Interrupts

## Table of Contents

1. **Learning about Interrupts**
   - 1.1 Introduction
   - 1.2 Scenarios Where Interrupts are Useful
   - 1.3 Getting to the Nuts and Bolts
   - 1.4 Setting Up an Interrupt

2. **Special Types of Interrupts**
   - 2.1 NMI: Non-Maskable Interrupt
   - 2.2 BRK: Software Interrupt
   - 2.3 WAI: Faster Interrupt Service on the 65C02

3. **Sample Applications**
   - 3.1 Interrupt Support for RS-232 Receive
   - 3.2 Interrupt-Driven Arbitrary Waveform Generator
   - 3.3 Using the 6522's Serial Port for Simple Analog Output

4. **Appendix A: Interrupt Performance**

---

## 1.1 INTRODUCTION

This primer addresses common misunderstandings about interrupts among 6502 enthusiasts. The author provides additional context beyond standard programming manuals, including:

- Practical examples demonstrating interrupt concepts
- Explanations of implementation rationale
- Real-world assembly-language examples covering setup, prioritization, and servicing
- Comparative interrupt performance data across processors

The document emphasizes that this serves as an introductory resource rather than exhaustive technical documentation. Interrupt-Service Routines (ISRs) vary from simple to complex, and the primer focuses on foundational principles relevant to typical hobbyist applications.

---

## 1.2 SCENARIOS WHERE INTERRUPTS ARE USEFUL

### Scenario A: Serial Port Data Reception

Without interrupts, the processor could only "poll" the serial port repeatedly, wasting computational resources. The polling approach forces a choice between dedicating all processor time to the port or accepting delayed data handling.

"The much better way to handle the situation uses interrupts. Set the serial port up to tell the processor when it needs attention."

This allows background programs to execute without embedded polling logic, and the port receives service without waiting for program control flow to reach specific subroutine calls.

### Scenario B: Time-Critical Periodic Tasks

Software timing loops using delay calculations become unreliable due to variable instruction execution times and conditional branching complexity. Hardware timers with interrupts maintain accurate, crystal-controlled timing regardless of processor workload.

"The timer's roll-over rate will remain at whatever value your program gave it, regardless of what the processor is doing."

### Scenario C: Multiple Simultaneous Requirements

Combining serial data reception with precise timing requirements becomes impossible without interrupts. Multiple interrupt sources allow independent handling of asynchronous and time-critical operations simultaneously.

### What IS an Interrupt?

The author provides everyday analogies:

- **Polling analogy**: Repeatedly checking the door to see if guests have arrived
- **Interrupt analogy**: Using a doorbell so guests notify you when they arrive
- **Alarm clock analogy**: Sleep soundly knowing an alarm will alert you to wake

"An interrupt is not when you decide to take a break from your work... An interrupt is not something the program does when it reaches a certain point."

Interrupts are fundamentally asynchronous events triggered by external hardware, not program control flow decisions. The processor may be at any instruction when an interrupt occurs.

---

## 1.3 GETTING TO THE NUTS AND BOLTS

### Interrupt Sequence Overview

When the IRQ line is pulled low, the currently executing instruction completes before the 7-clock interrupt sequence begins:

1. Internal operations: 2 clocks
2. Push return address high byte to stack: 1 clock
3. Push return address low byte to stack: 1 clock
4. Push processor status register P to stack: 1 clock
5. Fetch ISR starting address from $FFFE-FFFF: 2 clocks

The interrupt sequence automatically:
- Sets the interrupt-disable I flag
- Clears the decimal D flag (65C02 only)

"The stack grows down toward $100, and the stack pointer register S is decremented immediately after each byte is written onto the stack."

Example: If S contains $EE, after interrupt sequence S becomes $EB with values stored at $1EE, $1ED, and $1EC.

### RTI (Return from Interrupt)

The RTI instruction (opcode $40) reverses the interrupt sequence in 6 clocks:

1. Internal operations: 2 clocks
2. Pull processor status from stack: 1 clock
3. Pull return address low byte: 1 clock
4. Pull return address high byte: 1 clock
5. Resume execution at return address: 1 clock

Unlike RTS (return from subroutine), RTI automatically restores the processor status register, eliminating the need for manual flag restoration.

### ISR Requirements

Interrupt-service routines must remain invisible to the main program by preserving all borrowed resources:

```assembly
ISR:    PHA
        TXA
        PHA
    (actual programming to service the interrupt goes here)
        PLA
        TAX
        PLA
        RTI
```

CMOS 65C02 version using dedicated push/pull instructions:

```assembly
ISR:    PHA
        PHX
    (actual programming to service the interrupt goes here)
        PLX
        PLA
        RTI
```

### Hardware Interrupt Clearing Example

```assembly
CNT_ISR: BIT   VIA_T1CL ; Turn off interrupt early
         INC   CNT      ; Increment the low byte of the variable
         BNE   isr1$    ; Branch to end if no roll-over
         INC   CNT+1    ; Otherwise increment high byte
 isr1$:  RTI            ; Exit the ISR
```

### Open-Drain Interrupt Lines

Most 65-family I/O ICs use open-drain IRQ outputs connected via pull-up resistors (typically 3K). RC time constants determine how quickly the line rises after being released. Clearing the interrupt source early in the ISR prevents the IRQ line from remaining low until after RTI executes, which could cause immediate re-entry.

"If you put the IRQ-clearing instruction(s) at the end of the ISR, it's possible that there won't be enough time for the resistor to charge that capacitance up to a valid logic-high state before the RTI is done executing."

WDC's 65C22 uses active pull-up (not open-drain), requiring AND gate arrangements for multiple interrupt sources.

### Determining Interrupt Sources

When multiple devices share the IRQ line, polling the interrupt flag registers identifies which device requested service:

```assembly
ISR: BIT  VIA1_STATUS   ; Check 6522 VIA1's status without loading A
     BMI  SERVICE_VIA1  ; If bit 7 set, branch to service it
     BIT  VIA2_STATUS   ; Otherwise check VIA2's status
     BMI  SERVICE_VIA2  ; If that one caused interrupt, branch
     JMP  SERVICE_ACIA  ; Otherwise must be the 6551 ACIA
```

Higher-priority devices are polled first. If multiple interrupts occur simultaneously, the highest priority device gets serviced first. When its ISR exits with RTI, if lower-priority devices still hold the IRQ line low, the ISR will be re-entered immediately to service them.

### Masking Individual Interrupt Sources

Check both the interrupt flag register (IFR) and interrupt enable register (IER):

```assembly
LDA  VIA_IFR            ; Get the set of interrupt flags
BPL  <test next device> ; Skip if this 6522 not responsible
AND  VIA_IER            ; Zero flags that weren't allowed to pull IRQ
ASL
BMI  SERVICE_TIMER_1
ASL
BMI  SERVICE_TIMER_2
```

This prevents spurious branches on flags that are set but not enabled to generate interrupts.

---

## 1.4 SETTING UP AN INTERRUPT

### Three Essential Steps

1. Place the ISR in memory with the interrupt vector pointing to its starting address
2. Configure the I/O device(s) to generate interrupts
3. Clear the interrupt-disable bit (I) using CLI instruction

### Interrupt Vectors

The 6502 uses designated memory locations to find ISR addresses:

- **IRQ vector**: $FFFE-$FFFF (16-bit address)
- **NMI vector**: $FFFA-$FFFB (16-bit address)
- **Reset vector**: $FFFC-$FFFD (16-bit address)

```assembly
        .ORG   $FFFA    ; Start section at address $FFFA
NMIVEC: .WORD  NMI_ISR  ; NMI vector
RESVEC: .WORD  RESET    ; Reset vector
IRQVEC: .WORD  CNT_ISR  ; IRQ vector
```

These vectors must reside in ROM (typically) to be available at power-up. For dynamic vector changes, place an indirect JMP instruction in ROM that points to a RAM-based vector.

### Timer Setup Example

Setting up Timer 1 in a 6522 VIA to interrupt every 50,000 clock cycles (producing 100 interrupts per second at 5MHz):

```assembly
TMR_SETUP: STZ  CNT         ; Initialize counter
           STZ  CNT+1

           LDA  #$4E        ; Load timer 1 low byte
           STA  VIA_T1CL
           LDA  #$C3        ; Load timer 1 high byte
           STA  VIA_T1CH

           LDA  VIA_ACR     ; Clear bit for PB7 toggle
           AND  #01111111B
           ORA  #01000000B  ; Set continuous interrupt bit
           STA  VIA_ACR

           LDA  #11000000B
           STA  VIA_IER     ; Enable T1 interrupt

           CLI              ; Clear interrupt disable bit
           RTS
```

### Interrupt Masking

Interrupts on the IRQ input can be masked using SEI (Set Interrupt-disable bit) when the processor must not be interrupted:

```assembly
SEI  ; Disable IRQ interrupts (2 clocks)
; Critical section
CLI  ; Enable IRQ interrupts (2 clocks)
```

Neither instruction acknowledges existing interrupts or affects external hardware. They only modify the I bit in the processor status register.

### Level-Sensitive IRQ Input

The 6502's IRQ input is level-sensitive, not edge-sensitive. "Anytime this input pin is low and the interrupt-disable bit is clear, the processor will finish up the currently executing instruction and begin the interrupt sequence."

Without the I flag protection, the IRQ line being held low would cause endless interrupt sequences, rapidly overflowing the stack. The interrupt sequence automatically sets the I flag after pushing the status register, preventing re-entry until CLI explicitly clears it or RTI restores the saved status.

### Ghost Interrupts

If an interrupt source is disabled while simultaneously asserting the IRQ line, the processor may begin the interrupt sequence before the hardware releases the line. By the time the ISR checks the interrupt flag register, the condition has cleared, producing a "ghost" interrupt.

Prevention technique:

```assembly
SEI
JSR  DISABLE_INTERRUPT_SOURCE
CLI
```

Alternatively, if the ISR finds no cause for the interrupt, it can simply exit without error.

### ISR Optimization

Keep ISRs minimal by performing only time-critical operations. Leave non-critical work for the main program:

"An ISR's job should normally be kept as small as practical in order to maximize overall interrupt performance and make sure all deadlines are met."

---

## 2.1 NMI: THE NON-MASKABLE INTERRUPT

The NMI input differs fundamentally from IRQ in both electrical characteristics and operational behavior:

### Edge vs. Level Sensitivity

NMI is edge-sensitive, not level-sensitive. It recognizes transitions from high to low, not the absolute level:

"The NMI line must be at a valid logic high state long enough to be seen by the processor at the time of one φ2 falling edge. It can be low again for the next φ2 falling edge, and the processor will recognize the new interrupt."

This requirement limits NMI to typically one interrupt source per system, or careful coordination of multiple sources to ensure no overlapping assertions.

### Non-Maskable Behavior

"Since it is not maskable, an interrupt on NMI can cut in on the servicing of an IRQ interrupt, even though the interrupt-disable I flag is set."

Neither SEI nor any other instruction prevents NMI processing. If NMI and IRQ occur simultaneously, NMI takes priority.

### Practical Applications

NMI is traditionally reserved for critical conditions like power loss, but hobbyist systems often use it creatively:

- Panic buttons for entering a monitor prompt
- Abort buttons for program reset without resetting I/O peripherals
- Real-time clock functions (when IRQ must remain available for other uses)

### Real-Time Clock Implementation

Complete NMI ISR example for 10ms RTC update:

```assembly
INCR10ms: PHA                   ; Save accumulator
          LDA   VIA1T1CL        ; Clear interrupt
          INC   cs_32           ; Increment 4-byte centisecond counter
          BNE   inc_TOD
          INC   cs_32+1
          BNE   inc_TOD
          INC   cs_32+2
          BNE   inc_TOD
          INC   cs_32+3

 inc_TOD: INC   CENTISEC        ; Increment hundredths of seconds
          LDA   CENTISEC
          CMP   #100
          BMI   end_NMI
          STZ   CENTISEC
          INC   SECONDS
          LDA   SECONDS
          CMP   #60
          BMI   end_NMI
          STZ   SECONDS
          INC   MINUTES
          LDA   MINUTES
          CMP   #60
          BMI   end_NMI
          STZ   MINUTES
          INC   HRS
          LDA   HRS
          CMP   #24
          BMI   end_NMI
          STZ   HRS
          INC   DAY

          LDA   MO
          CMP   #2                ; Check if February
          BNE   notfeb

          LDA   YR
          AND   #11111100B        ; Check leap year (divisible by 4)
          CMP   YR
          BNE   notfeb

          LDA   DAY
          CMP   #30               ; February limit
          BEQ   new_mo
          PLA
          RTI

 notfeb:  PHX
            LDX MO
            LDA MO_DAYS_TBL-1,X
          PLX
          CMP   DAY
          BNE   end_NMI

 new_mo:  LDA   #1
          STA   DAY
          INC   MO
          LDA   MO
          CMP   #13
          BNE   end_NMI
          LDA   #1
          STA   MO

          INC   YR
 end_NMI: PLA
          RTI
```

Month days table:

```assembly
MO_DAYS_TBL: DFB     32,  29,  32,  31,  32,  31,  32,  32,  31,  32,  31,  32
             ; Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec
```

### Performance Notes

In 98.6% of cases, only 10 instructions execute. The rare case of midnight on New Year's Day executes 45 instructions. To prevent unacceptable delays to IRQ servicing, CLI can re-enable IRQ interrupts after seconds have been incremented, allowing nested interrupt nesting.

"Any routine (including ISRs) that need the time and date variables should read the needed ones until it gets the same result twice in a row anyway."

This prevents reading partially-updated time values.

### RTC Setup

```assembly
RTC_SETUP:                 ; Called only once during boot
         LDA    #$4E       ; Set T1 for 10ms @ 5MHz
         STA    VIA1T1CL
         LDA    #$C3
         STA    VIA1T1CH

         LDA    VIA1ACR    ; Set T1 free-run mode
         AND    #$7F
         ORA    #$40
         STA    VIA1ACR

RTC_ON:  LDA    #$C0       ; Enable T1 interrupt
         BRA    ro2
RTC_OFF: LDA    #$40       ; Disable T1 interrupt
 ro2:    STA    VIA1IER
         RTS
```

---

## 2.2 BRK: THE SOFTWARE INTERRUPT

The BRK (break) instruction simulates an interrupt without external hardware signaling:

"The BRK instruction seems to mostly have outlived its usefulness. There is some use for it in multitasking operating systems, but the 6502 is not generally very well suited for that anyway."

### Distinguishing BRK from Hardware Interrupts

The BRK ISR must test the B (break) bit (bit 4) in the stacked processor status register to distinguish software from hardware interrupts:

```assembly
PLA          ; Pull stacked status byte
PHA          ; Push it back
AND  #00010000B  ; Isolate bit 4
BEQ  HARDWARE_IRQ
BNE  SOFTWARE_BRK
```

Critical caveat: Testing bit 4 directly from the processor status register using PHP/PLA/AND/BNE will always show it as set, providing incorrect results. The test must use PLA/PHA to read the stacked value.

### Technical Details

- BRK is a one-byte instruction requiring a padding byte after it
- The return address pushed to the stack points to the second byte after BRK
- RTI will resume execution at the padding byte location
- The padding byte can serve as a signature identifying which BRK executed
- BRK sets the interrupt-disable I flag like IRQ
- 65C02 also clears the decimal D flag

### NMOS 6502 Bug

One NMOS 6502 bug: if NMI occurs during BRK execution, the BRK interrupt never executes. The 65C02 fixes this and all other NMOS bugs.

---

## 2.3 WAI: FASTER INTERRUPT SERVICE ON THE 65C02

The 65C02's WAI (wait) instruction enables ultra-fast interrupt response in special cases:

"If the main part of the work can be paused until the next interrupt, you can set the interrupt-disable bit I-- yes, _set_ it-- execute WAI, and have the very next instruction to be the beginning of the ISR."

### Mechanism

The WAI instruction halts the processor after the current instruction completes. When IRQ (or NMI on some implementations) occurs:

1. The normal 7-clock interrupt sequence is bypassed
2. Execution resumes at the next instruction
3. No vector lookup occurs
4. No RTI is needed; normal code continues

### Setup and Usage

```assembly
STA VIA1IER     ; Pre-interrupt code
SEI             ; Set interrupt-disable bit (yes, SET it)
WAI             ; Pause, waiting for interrupt

LDA VIA1PB      ; First instruction of ISR—no vector lookup
    .           ; Service the interrupt with straight-line code
    .
xxx             ; Continues normally without RTI
xxx
```

### Latency Reduction

- Eliminates the 7-clock interrupt sequence
- Guarantees processor not mid-instruction when interrupt arrives
- No vector fetching required
- No RTI required at end
- Total latency reduced from 7-14 clocks to essentially one clock

### Constraints

- Only applicable when the main program can be paused until the next interrupt
- Requires setting the interrupt-disable I flag (unusual but intentional)
- Registers don't need saving before WAI if the ISR doesn't modify them
- Can't be used for multiple independent interrupt sources

---

## 3.1 INTERRUPT SUPPORT FOR RS-232 RECEIVE

### Buffer Design Philosophy

The 256-byte ring buffer operates like a holding tank:

- Tolerates varying data arrival rates
- Prevents buffer overflow when the main program temporarily can't consume data
- Handles PC-to-6502 scenarios where a few extra bytes arrive after CTS goes false

### Buffer Structure

```assembly
BUFFER: .DFS    $100    ; Reserve 256 bytes of RAM for the buffer
RD_PTR: .DFS    1       ; Read pointer
WR_PTR: .DFS    1       ; Write pointer
```

Using 256 bytes allows automatic wrap-around with 8-bit pointers. If pointers equal, the buffer is empty; if the write pointer is one byte behind the read pointer, the buffer is full.

### Write Operation

```assembly
WR_BUF:  LDX  WR_PTR     ; Start with A containing the data byte
         STA  BUFFER,X   ; Store data at write pointer location
         INC  WR_PTR     ; Increment for next write
         RTS
```

### Read Operation

```assembly
RD_BUF:  LDX  RD_PTR     ; Ends with A containing the byte read
         LDA  BUFFER,X   ; Get data from buffer
         INC  RD_PTR     ; Increment for next read
         RTS
```

### Buffer Fullness

```assembly
BUF_DIF: LDA  WR_PTR     ; Subtract read pointer from write pointer
         SEC             ; to get unread byte count
         SBC  RD_PTR
         RTS
```

### ACIA Interrupt Service Routine

```assembly
SERVICE_ACIA:
         PHA
         PHX

         LDA  ACIA_STAT   ; Get ACIA status register
         AND  #00000111B  ; Check for error conditions (bits 0-2)
         BNE  REPORT_ERR  ; Branch if error detected

         LDA  ACIA_DATA   ; Get received data byte
         JSR  WR_BUF      ; Write to buffer

         JSR  BUF_DIF     ; Check buffer fullness
         CMP  #$F0        ; If less than 240 bytes unread,
         BCC  end         ; exit here

         LDA  #1          ; Otherwise, set RTS false to tell
         STA  ACIA_COMM   ; sending computer to stop

 end:    PLX
         PLA
         RTI
```

---

## 3.2 INTERRUPT-DRIVEN ARBITRARY WAVEFORM GENERATOR

### Timer Interrupt Rates

Using a 5MHz clock, the required T1 latch values for various sample rates:

| Target | Actual | T1 Latch |
|--------|--------|----------|
| 12 kHz | 11.9904 kHz | $19F |
| 16 kHz | 15.9744 kHz | $137 |
| 20 kHz | Exact | $F8 |
| 24 kHz | 24.0385 kHz | $CE |
| 28 kHz | 28.0899 kHz | $B0 |
| 36 kHz | 35.9712 kHz | $89 |
| 40 kHz | Exact | $7B |
| 48 kHz | 48.0769 kHz | $66 |

Formula: f(IRQ) = f(φ2) / (n+2), therefore n = f(φ2) / f(IRQ) - 2

### Waveform Generator ISR

```assembly
ARB_GEN_SAMPLER:         ; Interrupt service routine
        PHA
           LDA  VIA_IFR  ; Check if timer caused interrupt
           BMI  ags$     ; If so, play another sample
        PLA
        JMP  _______     ; Test next interrupt source

 ags$:  LDA  VIA_T1CL    ; Clear timer interrupt flag first

        LDA  (CUR_ADR)   ; Read sample from current address
        STA  VIA_PA      ; Output to D/A converter on port A

        INC  CUR_ADR     ; Increment low byte of address
        BNE  ags1$       ; If no roll-over,
        INC  CUR_ADR+1   ; increment high byte

 ags1$: LDA  CUR_ADR     ; Check if at end of sample buffer
        CMP  END_ADR     ; Compare low bytes
        BNE  end$        ; If different, continue
        LDA  CUR_ADR+1   ; Compare high bytes
        CMP  END_ADR+1
        BNE  end$        ; If different, continue

        LDA  BEG_ADR     ; Reached end, restart at beginning
        STA  CUR_ADR
        LDA  BEG_ADR+1
        STA  CUR_ADR+1

 end$:  PLA              ; Restore accumulator
        RTI              ; Exit interrupt
```

---

## 3.3 USING THE 6522'S SERIAL PORT FOR SIMPLE ANALOG OUTPUT

Using the 6522's serial shift register in mode 100 (shift out free-running at T2 rate) provides a simple analog output method with 9 discrete voltage levels (approximately 3-bit resolution).

### Voltage Levels

Example using patterns for 65C22 (CMOS):

| Level | Pattern | Voltage |
|-------|---------|---------|
| 0 | 00000000 | 0.000V |
| 1 | 00010000 | 0.625V |
| 2 | 00100010 | 1.250V |
| 3 | 01010010 | 1.875V |
| 4 | 10101010 | 2.500V |
| 5 | 10101101 | 3.125V |
| 6 | 11011101 | 3.750V |
| 7 | 11101111 | 4.375V |
| 8 | 11111111 | 5.000V |

### Applications

This D/A method proves adequate for:
- DTMF (Dual-Tone Multi-Frequency) telephone signaling
- Low-resolution audio signals
- Speech synthesis with intelligible output

---

## APPENDIX A: INTERRUPT PERFORMANCE

### Performance Metrics

Interrupt latency comprises multiple components:

- **(A) Instruction completion time**: Finish currently-executing instruction (0-7 clocks max on 6502)
- **(B) Acknowledge sequence**: Some processors require separate interrupt acknowledgment
- **(C) Interrupt sequence**: Push return address and status, fetch vector (7 clocks on 6502)
- **(D) Interrupt vector fetch**: Included in sequence on 6502, separate on some processors
- **(E) Return-from-interrupt**: Restore status and address (6 clocks on 6502)

### 6502 Performance Characteristics

**Normal operation:**
- Minimum latency (C only): 7 clocks (0.35μs @ 20MHz)
- Maximum latency (A+C): 14 clocks (0.7μs @ 20MHz)
- Average latency: ~9 clocks
- RTI instruction: 6 clocks (0.3μs @ 20MHz)

**Special WAI case:**
- IRQ latency with WAI and I bit set: 1 clock (0.05μs @ 20MHz)
- Total interrupt-to-service-beginning: essentially instantaneous

### Comparative Data

**Processors comparable to 65C02:**

| Processor | Latency | Clock Speed |
|-----------|---------|-------------|
| 65C02 | 7-14 cy / 0.35-0.7μs | 20MHz |
| 68HC12 | 2.63μs | 8MHz |
| 68HC16 | 2.25μs | 16MHz |

**Slower processors:**

| Processor | Latency | Clock Speed |
|-----------|---------|-------------|
| 6800 | 13 cy | 2MHz |
| 6809 | 19 cy | 2MHz |
| Z80 | 11-19 cy | 4MHz |
| 68000 | 46 cy | 16MHz |

### Efficiency Analysis

The 6502's competitive interrupt performance stems from:

1. Minimal stack pushes (only return address and status)
2. No separate acknowledge sequence
3. Simple vector fetch mechanism
4. Fast RTI recovery
5. Ability to service with minimal register saves

The exceptional WAI instruction feature on 65C02, reducing interrupt latency to one clock under optimal conditions, remains unmatched by most contemporary processors.

---

Last Updated: May 17, 2014
