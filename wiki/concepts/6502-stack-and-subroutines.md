---
type: concept
tags: [6502, 65c02, assembly, stack, subroutines, pha, pla, jsr, rts]
related: [[learning-6502-assembly]], [[6502-subroutine-conventions]], [[65c02-instruction-set]], [[6502-programming-idioms]]
sources: [[wagner-assembly-lines]], [[leventhal-subroutines]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Stack and Subroutines

**Summary**: The 6502 stack is a fixed-size LIFO region in page 1 ($0100–$01FF), used automatically by JSR/RTS for subroutine calls and manually by PHA/PLA for temporary storage. Understanding the stack is essential to writing correct subroutines.

---

## What is the stack?

Think of the stack like spring-loaded plate holders in a restaurant. Plates are loaded on top; the spring pushes existing plates down. Plates must always be removed in the **reverse** order they were added. This is called **LIFO** — Last In, First Out.

The 6502 stack occupies **page 1** of memory: addresses `$0100` through `$01FF` — exactly 256 bytes. The **Stack Pointer (SP)** register tracks the current top. It auto-decrements when data is pushed (stack grows downward from `$01FF`) and auto-increments when data is pulled.

The stack is pre-allocated hardware — there is no `malloc`. The only way to "allocate" stack space is to push values with `PHA` (and eventually pop them with `PLA`).

---

## PHA and PLA — manual stack use

| Instruction | Operation | Flags |
|-------------|-----------|-------|
| `PHA` | Push Accumulator: copy A to `$0100 + SP`, then SP-- | None |
| `PLA` | Pull Accumulator: SP++, then A = `$0100 + SP` | N, Z |
| `PHP` | Push Status Register | None |
| `PLP` | Pull Status Register (restores all flags) | All |
| `PHX` | Push X register (65C02 only) | None |
| `PLX` | Pull X register (65C02 only) | N, Z |
| `PHY` | Push Y register (65C02 only) | None |
| `PLY` | Pull Y register (65C02 only) | N, Z |

**PHA does not modify the Accumulator** — the value is copied, not moved.  
**PLA conditions the Z flag** — Z=1 if the pulled value is $00.

### Using PHA/PLA for temporary storage

Instead of wasting a zero-page location to hold a temporary value:

```asm
    ; save A value while doing something else
    PHA              ; push A onto stack
    JSR  SOME_ROUTINE ; A is now clobbered
    PLA              ; restore original A value
```

This avoids committing a specific zero-page address to temporary use.

### PHX/PHY/PLX/PLY (65C02)

On NMOS 6502, saving/restoring X and Y required round-trips through the Accumulator:
```asm
; 6502 idiom to save/restore X:
    TXA : PHA        ; save X
    ; ... clobbers X ...
    PLA : TAX        ; restore X
```

The 65C02 adds direct `PHX`, `PLX`, `PHY`, `PLY` — more compact and faster, no Accumulator involvement:
```asm
; 65C02:
    PHX              ; save X directly
    ; ... clobbers X ...
    PLX              ; restore X
```

---

## JSR and RTS — subroutine calls

The 6502 has no "call instruction" with explicit argument passing. `JSR` (Jump to SubRoutine) and `RTS` (ReTurn from Subroutine) work through the stack:

1. **JSR addr**: pushes PC−1 (last byte of JSR) to the stack (high byte first), then jumps to `addr`.
2. **RTS**: pops 2 bytes from the stack, adds 1, sets PC to the result (returns to the instruction after the JSR).

**Important quirk**: `JSR` saves `PC−1` (the address of its own last byte), not the next instruction. `RTS` adds 1 to compensate. This means if you want to use the saved return address as a data pointer (e.g., for inline data after JSR), the pointer byte must be incremented before reading data. See [[6502-subroutine-conventions]] for full parameter-passing conventions.

---

## Stack rules you must follow

1. **Every PHA must have exactly one matching PLA before the RTS.** If you push more than you pull, the RTS will pop garbage as the return address and jump to the wrong place.

2. **Values come back in reverse order.** If you push A, then B, you get B first when pulling.

3. **Stack is shared.** JSR automatically uses 2 bytes of stack per call. Each PHA uses 1 more. Nested subroutines and PHA use stack depth additively.

4. **Never leave extra values on the stack.** They persist across calls and corrupt subsequent pops.

5. **PLA conditions Z.** If you need to test the pulled value, branch right after PLA.

---

## Saving registers across subroutines

Standard idiom to save/restore all registers at a subroutine entry:

```asm
MYSUB:
    PHA              ; save A
    TXA : PHA        ; save X (via A)
    TYA : PHA        ; save Y (via A)
    ; ... body of subroutine ...
    PLA : TAY        ; restore Y
    PLA : TAX        ; restore X
    PLA              ; restore A
    RTS
```

On 65C02, use PHX/PHY and PLY/PLX:
```asm
MYSUB:
    PHA              ; save A
    PHX              ; save X
    PHY              ; save Y
    ; ... body ...
    PLY              ; restore Y
    PLX              ; restore X
    PLA              ; restore A
    RTS
```

---

## Stack depth limits

The stack can hold a maximum of **256 one-byte values** or **128 two-byte JSR return addresses** — shared with any other stack users in the system.

In practice, the operating system, BASIC interpreter, and interrupt handlers may also use the stack. This effectively limits user programs to fewer levels of nesting. Deep recursion or many levels of JSR can overflow the stack — the stack pointer wraps to $01FF and starts overwriting previous stack frames. There is no hardware overflow detection.

As a guideline: keep nesting depth shallow (typically ≤ 8–10 levels on a standalone 6502 system), avoid unnecessary PHA/PLA pairs inside tight loops, and watch stack usage when mixing BASIC and machine code calls.

---

## How JSR/RTS use the stack (internal detail)

The stack diagram at a JSR call to address $0350:

```
Before JSR:       After JSR $0350:
SP = $FE          SP = $FC

$01FF: ...        $01FF: ...
$01FE: ...        $01FE: PCH (high byte of PC-1)
$01FD: ...        $01FD: PCL (low byte of PC-1)
$01FC: ...        $01FC: ← SP now points here (next free)
```

Executing RTS: pops $01FD then $01FE to reconstruct the return address, adds 1, jumps there.

---

## Stack and interrupts

When an **IRQ or NMI** fires, the 6502 automatically pushes 3 bytes: PCH, PCL, P (Status Register). This happens whether or not the current code was using the stack. Every ISR (Interrupt Service Routine) must end with `RTI` (not `RTS`) to restore P, PCL, PCH properly. See [[6502-interrupt-patterns]] for complete interrupt handling patterns.

---

## Related pages

- [[learning-6502-assembly]] — loop patterns and Status Register basics
- [[6502-subroutine-conventions]] — parameter passing via stack, Leventhal formal conventions
- [[65c02-instruction-set]] — full instruction table including PHX/PHY/PLX/PLY (65C02)
- [[6502-interrupt-patterns]] — interrupt-driven stack usage (ISR entry/exit)
- [[6502-programming-idioms]] — arithmetic idioms using the Carry chain
