---
type: concept
tags: [6502, 65c02, assembly, relocatable, self-modifying, indirect-jump, jsr-simulation, advanced]
related: [[learning-6502-assembly]], [[65c02-instruction-set]], [[6502-stack-and-subroutines]], [[6502-subroutine-conventions]]
sources: [[wagner-assembly-lines]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Relocatable and Self-Modifying Code

**Summary**: Techniques to write 6502 code that runs at any memory address (relocatable code), replace absolute JMP/JSR with position-independent equivalents, simulate JSR with a stack-based trick, and use indirect jumps for dispatch tables.

---

## Relocatable vs non-relocatable code

**Non-relocatable code** is tied to a specific address at assembly time. Any statement that uses an absolute address *within* the code block creates a fixed dependency:

```asm
; Non-relocatable examples:
    JMP  $030D        ; jumps to exact address $030D
    JSR  SUBROUTINE   ; if SUBROUTINE is in the same code block
    DATA: .BYTE $41   ; data table access via LDA DATA,X
```

If the code block is moved to a different address ($0400, say), those absolute references still point to the old location and the program crashes.

**Relocatable code** contains no internal absolute references. The only absolute calls allowed are to routines *outside* the block (OS routines, ROM calls) — those stay fixed regardless of where the calling code lives.

The key principle: **any code that references absolute addresses within itself is non-relocatable**. The most common culprits are `JMP`, `JSR`, and data table labels.

---

## Replacing JMP with forced branches

The forced-branch technique substitutes a non-relocatable `JMP $xxxx` with a short relocatable alternative:

### Using CLV + BVC (preferred)

```asm
    CLV             ; clear overflow flag (non-destructive to other flags)
    BVC  DESTINATION ; branch always (V=0 after CLV, so BVC always taken)
```

- Only 3 bytes total (same as JMP).
- Uses V flag — does not affect C flag (safe in carry chains).
- Limitation: destination must be within −128 to +127 bytes of the instruction after BVC.

### Using CLC + BCC

```asm
    CLC             ; clear carry
    BCC  DESTINATION ; branch always (C=0 after CLC, so BCC always taken)
```

- Same size but destroys the Carry flag — **not safe inside arithmetic carry chains**.
- Prefer CLV+BVC when Carry matters.

### On 65C02: use BRA

The 65C02 adds `BRA` (Branch Always) — a direct unconditional relative branch that doesn't require clearing any flag first:

```asm
    BRA  DESTINATION ; 2 bytes, always branches, no flag side-effects
```

`BRA` replaces `CLV; BVC` in any 65C02 program. It is the preferred relocatable short-jump on RP6502.

### Extending beyond 127 bytes — the stepping technique

When the destination is more than 127 bytes away, use **stepping**: plant a series of forced branches throughout the code that act as relay points:

```asm
; Long relocatable jump by stepping:
    CLV
    BVC  STEP1      ; first relay (within 127 bytes)
    ; ... other code ...
STEP1:
    CLV
    BVC  STEP2      ; second relay
    ; ...
STEP2:
    CLV
    BVC  DESTINATION ; final relay to target
```

---

## Simulating JSR (relocatable subroutine call)

`JSR addr` is non-relocatable (it encodes the absolute target address). To call a fixed subroutine in a relocatable way, use a **stack-based JSR simulation**:

```asm
; Relocatable JSR simulation — push return address manually
; then JMP (indirect) to destination

JSRRTRN:
    ; 1. Calculate destination address and push it as a 16-bit pointer
    ; 2. Push return address (via stack + offset arithmetic)
    ; 3. JMP() indirect to destination
```

The general idea:
1. Push the return address (address of instruction after the indirect jump) onto the stack.
2. Use an indirect JMP through a zero-page pointer to reach the destination.

This avoids `JSR addr` entirely. The subroutine ends with `RTS` as normal; `RTS` pops the synthesised return address and returns correctly.

**Trade-off**: more code bytes and cycles than a plain `JSR`. Typically worth it only when a whole block of code containing many calls must float freely in memory (e.g., code appended to the end of a BASIC program or code stored in a ROM that may be mapped to different locations).

---

## Indirect JMP — the dispatch table

`JMP ($addr)` fetches a 2-byte pointer from `$addr`/`$addr+1` and jumps there. This allows a jump-table dispatch:

```asm
; Dispatch based on value in A (0, 1, 2 → three handlers)
    ASL  A           ; × 2 (each entry is 2 bytes)
    TAX
    LDA  TABLE,X     ; low byte of handler address
    STA  PTR
    LDA  TABLE+1,X   ; high byte
    STA  PTR+1
    JMP  (PTR)        ; indirect jump via zero-page pointer
    ; --- or on 65C02:
    JMP  (TABLE,X)    ; Indexed Absolute Indirect — NEW 65C02 mode

TABLE:
    .WORD HANDLER0
    .WORD HANDLER1
    .WORD HANDLER2
```

The 65C02 provides `JMP ($addr,X)` (Absolute Indexed Indirect) as a single instruction — the whole pattern above collapses to one instruction. See [[65c02-addressing-modes]].

### Advantages over a string of BEQ/BNE tests

A JMP table is O(1) regardless of the number of cases. A chain of comparisons is O(N). Use indirect jumps for command interpreters, state machines, and opcode dispatch tables.

The pointer table does not need to be on page zero — it can be anywhere in memory. The **zero-page pointer** (`PTR`) must be on page zero for the indirect modes.

---

## The JMP ($xxxx) page-boundary bug (NMOS 6502)

The NMOS 6502 has a well-known bug in indirect JMP: if the pointer address straddles a page boundary, the high byte is fetched from the wrong location.

```
JMP ($3FF)  → reads $3FF (expected low) and $300 (BUG: should be $400)
JMP ($380)  → reads $380 and $381 (correct, no page boundary)
JMP ($06)   → reads $06 and $07 (correct, page 0)
```

The high byte is not properly incremented when the low byte is at `$xxFF`.

**Fix**: avoid placing the 2-byte pointer at a page boundary. Choose pointer addresses where low byte ≠ `$FF`.

**65C02 fix**: this bug is corrected on the W65C02S (and all CMOS 65C02 variants). `JMP ($3FF)` correctly reads `$3FF` and `$400` on a 65C02. The fix costs one extra cycle. On RP6502, the CPU is a 65C02, so the bug does not exist.

---

## Self-modifying code (SMC)

Self-modifying code writes to its own instructions at runtime. Classic 6502 SMC uses `STA addr` to patch the operand byte of a subsequent `LDA`, `STA`, or branch instruction:

```asm
; Patch the operand of an LDA instruction at runtime:
    LDA  DEST_ADDR_LO   ; calculate new target address
    STA  LOAD_INST+1    ; overwrite low byte of operand in LOAD_INST
    LDA  DEST_ADDR_HI
    STA  LOAD_INST+2    ; overwrite high byte of operand

LOAD_INST:
    LDA  $0000          ; this operand gets patched at runtime
```

**Uses in RP6502 context**:
- Updating the base address in an inner loop without recalculating it each iteration.
- Patching branch targets for fast state machines.
- Writing compact ROM utilities that configure themselves for the calling context.

**Caveats**:
- Code must be in RAM (not ROM). RP6502 application code runs in SRAM — fine.
- Not cache-safe on modern CPUs — not an issue on 6502 (no instruction cache).
- Makes code harder to read and debug; use sparingly.

---

## Summary: relocatability quick reference

| Technique | Size | Flag side effect | Range | Notes |
|-----------|------|-----------------|-------|-------|
| `JMP abs` | 3 | None | Anywhere | Non-relocatable |
| `CLV; BVC` | 3 | Clears V | ±127 | Relocatable; safe with Carry |
| `CLC; BCC` | 3 | Clears C | ±127 | Relocatable; destroys Carry |
| `BRA` (65C02) | 2 | None | ±127 | Best option on 65C02 / RP6502 |
| Stepping | N×3 | V or C | Unlimited | Relay chain; code size grows |
| `JMP (ptr)` | 3 | None | Anywhere | Indirect; PTR on page 0 |
| `JMP (abs,X)` (65C02) | 3 | None | Anywhere | Jump table; one instruction |

---

## Related pages

- [[learning-6502-assembly]] — branch instructions and addressing modes
- [[65c02-addressing-modes]] — `JMP (abs,X)` mode details and cycle counts
- [[65c02-instruction-set]] — BRA instruction (65C02)
- [[6502-stack-and-subroutines]] — stack mechanics, JSR/RTS, PHA/PLA
- [[6502-subroutine-conventions]] — formal parameter-passing conventions
