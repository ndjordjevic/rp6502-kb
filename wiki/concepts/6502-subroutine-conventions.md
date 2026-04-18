---
type: concept
tags: [6502, 65c02, assembly, subroutines, abi, calling-convention, stack]
related: [[rp6502-abi]], [[65c02-instruction-set]], [[65c02-addressing-modes]], [[memory-map]]
sources: [[leventhal-6502-assembly]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Subroutine Conventions

**Summary**: How 6502/65C02 subroutines are called, how parameters are passed, and the design properties (relocatability, reentrancy) that make subroutines reusable — from Leventhal Ch. 10. Cross-referenced with the RP6502 OS ABI.

---

## JSR / RTS mechanics

### JSR (Jump to Subroutine)
`JSR addr` (opcode `20`):
1. Push **MSB of (PC−1)** onto stack, decrement SP.
2. Push **LSB of (PC−1)** onto stack, decrement SP.
3. Load PC with `addr`.

The saved value is the address of the **last byte of the JSR instruction** (one less than the actual return address). This is an intentional CPU design choice that RTS compensates for.

### RTS (Return from Subroutine)
`RTS` (opcode `60`):
1. Increment SP; pull PCL from stack.
2. Increment SP; pull PCH from stack.
3. **Increment PC by 1** (compensating for the JSR offset).
4. Fetch next instruction.

> **Consequence**: if you push parameters onto the stack after JSR, you must be careful — the return address is buried underneath them. Access stack data relative to SP using `TSX` + indexed addressing with appropriate offsets.

### RTI vs. RTS
`RTI` (used in interrupt service routines) **also** pulls P from the stack before pulling PC, and does **not** add 1 to the return address. Never use RTI to return from a normal subroutine.

---

## Parameter passing — three methods

### Method 1: Registers

Simplest and fastest. A, X, Y hold up to 3 bytes of input/output.

```asm
; Caller:
LDA  $40       ; parameter in A
JSR  ASDEC     ; convert hex nibble → ASCII

; Callee returns ASCII char in A
```

**Limits**: only 3 single-byte slots. Addresses (16-bit) must be split across two registers, which is awkward.

### Method 2: Zero-page pseudo-registers

Reserve zero-page locations (e.g., `$40/$41`) to act as extra 16-bit address registers. Pass a pointer in ZP, then use indexed-indirect `(zp),Y` or indirect `(zp)` (65C02) inside the subroutine.

```asm
; Caller places string address in $40/$41:
LDA  #<STRADDR
STA  $40
LDA  #>STRADDR
STA  $41
JSR  STLEN       ; returns string length in A

; Callee:
STLEN:
    LDY  #$FF       ; length = -1
    LDA  #$0D       ; carriage return to compare
CHKCR:
    INY
    CMP  ($40),Y    ; compare char at (base+Y)
    BNE  CHKCR
    TYA             ; length in A
    RTS
```

**Pros**: passes 16-bit addresses cleanly; ZP instructions are 2 cycles faster than absolute.  
**Cons**: not reentrant unless callers treat these locations as saved registers.

> With **65C02 `(zp)` addressing**: eliminates the need to pre-load Y and the `($40),Y` construct — use `($40)` directly for the base access.

### Method 3: Stack

Caller pushes parameters before `JSR`; callee reads them via `TSX` and `$01xx,X` addressing. The return address sits at `$0101,X`/`$0102,X` (after TSX), so parameters pushed before JSR are at `$0103,X` and above.

```asm
; Caller pushes param, then JSR:
LDA  PARAM
PHA
JSR  MYFUNC

; Callee:
MYFUNC:
    TSX
    LDA  $0103,X    ; first parameter (below return address)
    ; ...
    RTS             ; caller must clean up stack if needed
```

**Pros**: stack is large (up to 256 bytes on page 1); not affected by nested calls.  
**Cons**: few 6502 instructions use the stack; awkward offset arithmetic; JSR's saved return address is at SP+1/SP+2 so you must add 2 to the SP-relative offset for each PHA done before JSR.

> The RP6502 OS uses the **XSTACK** (512-byte buffer inside the RIA) instead of the 6502 hardware stack for OS call parameters. This avoids the stack-pointer offset problem entirely. See [[rp6502-abi]].

---

## Subroutine documentation

Leventhal's required specification for every subroutine:

```
;SUBROUTINE <NAME>
;PURPOSE: <what it does>
;INITIAL CONDITIONS: <input parameters, registers, memory locations>
;FINAL CONDITIONS: <output — registers, memory locations, flags changed>
;REGISTERS USED: <A, X, Y, flags affected>
;MEMORY LOCATIONS USED: <any fixed ZP or other addresses>
;SAMPLE CASE:
;   INITIAL: ...
;   FINAL:   ...
```

If a subroutine changes any flag other than the ones explicitly documented, callers must save flags with `PHP` before the call and restore with `PLP` after.

---

## Preserving registers

To preserve a register across a subroutine call, the **caller** must save it (the callee may freely use any register unless its docs say otherwise).

Standard save/restore via stack:

```asm
; Save registers the caller needs after the call:
PHA          ; save A if needed
PHP          ; save flags if needed
TXA
PHA          ; save X
TYA
PHA          ; save Y
JSR  MYFUNC
PLA
TAY          ; restore Y
PLA
TAX          ; restore X
PLP          ; restore flags
PLA          ; restore A
```

With **65C02** `PHX`/`PHY`/`PLX`/`PLY`:

```asm
PHA
PHX          ; 65C02 — no detour through A
PHY          ; 65C02
JSR  MYFUNC
PLY
PLX
PLA
```

---

## Relocatability

A subroutine is **relocatable** if it uses no absolute addresses — only:
- Relative branch offsets (`BCC`, `BNE`, etc.)
- Stack-relative or ZP-relative addressing

An absolute `JMP` or `JSR` to a fixed address makes a routine non-relocatable.

```asm
; Relocatable loop:
LOOP:   INX
        CPX  #10
        BNE  LOOP   ; relative offset ← OK

; Non-relocatable:
        JMP  $C000  ; absolute ← NOT relocatable
```

---

## Reentrancy

A subroutine is **reentrant** if it can be interrupted, called again by the ISR, and both invocations get correct results.

**Requirements**:
1. Use only **registers** and the **stack** for temporary storage.
2. Use **no fixed memory locations** (zero-page pseudo-registers break reentrancy unless the ISR saves/restores them).

Reentrancy matters for subroutines used in both the main program and ISRs (e.g., output formatting, BCD conversion). Non-reentrant routines called from an ISR may corrupt in-progress calls from the main program.

The pattern is: treat ZP pseudo-registers as "live" data — the ISR saves and restores them on the stack just like A, X, Y:

```asm
ISR:
    PHA
    LDA  $40   ; save ZP pseudo-register used by shared subroutine
    PHA
    LDA  $41
    PHA
    ; ... use shared subroutine ...
    PLA
    STA  $41   ; restore
    PLA
    STA  $40
    PLA
    RTI
```

---

## Stack management

- The 6502 stack lives on **page 1** (`$0100–$01FF`).
- SP contains the address of the **next empty slot** (post-decrement push, pre-increment pull).
- Initialize with `LDX #$FF / TXS` to place the stack at `$01FF` (growing downward).
- Nesting subroutines is safe as long as the stack does not overflow into page 0.
- Saving SP: `TSX / STX TEMP` to save; `LDX TEMP / TXS` to restore. (Useful when jumping to a monitor and back.)

---

## RP6502 relationship

The RP6502 OS call ABI (documented in [[rp6502-abi]]) is modelled on the **cc65 fastcall convention**:
- Last argument in A/AX/AXSREG (closest to the cc65 register calling convention).
- Earlier arguments pushed left-to-right onto the **XSTACK** (a 512-byte buffer inside the RIA, not the 6502 hardware stack).
- Return value comes back in `RIA_A` / `RIA_X` / `RIA_SREG`.

This design avoids all the 6502 hardware-stack awkwardness for argument passing while remaining compatible with cc65-generated code.

---

## Related pages

- [[rp6502-abi]] — RP6502 OS call ABI (XSTACK, fastcall, RIA_SPIN)
- [[65c02-instruction-set]] — JSR (`20`), RTS (`60`), RTI (`40`), PHX/PHY/PLX/PLY
- [[65c02-addressing-modes]] — `(zp)` indirect addressing (65C02 new mode for parameter passing)
- [[6502-interrupt-patterns]] — reentrancy requirements for ISR-callable subroutines
- [[memory-map]] — page 1 stack location
