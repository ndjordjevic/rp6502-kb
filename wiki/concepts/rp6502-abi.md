---
type: concept
tags: [rp6502, abi, os, fastcall, assembly]
related: [[rp6502-os]], [[rp6502-ria]], [[xram]], [[memory-map]]
sources: [[rp6502-os-docs]], [[rp6502-github-repo]]
created: 2026-04-15
updated: 2026-04-16 (audit: fixed 7→8-byte stub)
---

# RP6502 ABI

**Summary**: How the 6502 calls into the protected OS that runs inside [[rp6502-ria]]. Modeled on **cc65 fastcall** so it works identically from C and assembly.

---

## Memory buffers

| Buffer | Size | Location | Purpose |
| --- | --- | --- | --- |
| **XSTACK** | 512 bytes | Inside RIA Pico RAM | Argument passing for OS calls |
| **mbuf** | 1 KB | Inside RIA Pico RAM | Bulk transfer buffer (6502↔RAM, USB↔RAM, UART↔RAM); also doubles as littlefs r/w buffer |
| **XRAM** | 64 KB | Inside RIA Pico RAM | Extended RAM, broadcast to PIX devices — see [[xram]] |

XSTACK size (512 B) is chosen to hold: a cc65 stack frame, two strings for a file rename, or a disk sector. The byte immediately past the end of XSTACK is always zero, making it safe to use as a null-terminated C string buffer without explicitly pushing the terminator.

## Four rules

1. Stack args are pushed **left to right** on the **XSTACK** (a top-down stack of up to 512 bytes inside the RIA).
2. The **last** argument is passed in register `A` / `AX` / `AXSREG`, copied to `RIA_A` / `RIA_X` / `RIA_SREG`.
3. Return value comes back in `RIA_A` / `RIA_X` / `RIA_SREG`.
4. Some ops also return data on the XSTACK (you must drain it before the next call — see "tail call" below).

`A` and `X` are 6502 registers; `AX` is the conceptual A:X 16-bit pair; `AXSREG` adds 16 more bits via the cc65 `SREG` pseudo-register.

## Making a call

```
; push xstack args left-to-right (writes to RIA_XSTACK push bytes)
; load last arg into A/X
LDA #op_id
STA $FFEF         ; RIA_OP — operation begins immediately

; option 1: poll
wait:
    LDA $FFF2     ; RIA_BUSY byte (the BRA offset)
    BMI wait      ; bit 7 set = BRA -2 = busy
    LDA $FFF4     ; RIA_A (the LDA #val byte)
    LDX $FFF6     ; RIA_X (the LDX #val byte)

; option 2: block (preferred)
JSR $FFF0         ; RIA_SPIN — unblocks and falls through to LDA/LDX/RTS
```

`RIA_SPIN` (`$FFF0`) is an 8-byte stub the RIA overwrites in-place:

```
$FFF0  EA        NOP
$FFF1  80 FE     BRA -2      ← loops here while busy ($FE → sign bit set)
$FFF3  A9 xx     LDA #val    ← return value low byte (set by RIA on completion)
$FFF5  A2 xx     LDX #val    ← return value high byte
$FFF7  60        RTS
```

When the RIA finishes it changes byte `$FFF2` from `$FE` to `$00`, turning `BRA -2` into `BRA +0` (fall-through). The same stub handles both polling and JSR — they read the same physical bytes. See [[ria-registers]] for the full register map.

## Errors

- 16-bit returns: `RIA_A` / `RIA_X`.
- 32-bit returns: also `RIA_SREG`.
- `RIA_ERRNO` is updated only on error. Maps to `errno` in C. Error namespace depends on `RIA_ATTR_ERRNO_OPT` (cc65 vs. llvm-mos vs. raw FatFs codes); C runtimes set this automatically, assembly programs must set it manually.

## Short stacking

The first stack arg may be **partially pushed** if it doesn't need its full width. Example: `f_lseek` takes a `long offset`, but if your real offset fits in 16 bits, push just 2 bytes instead of 4. The OS's stack pointer tracks the actual length.

## Shorter AX

Many calls ignore `RIA_X` on input — only `RIA_A` matters. Returns are still 16-bit-promoted in `RIA_X` for C integer-promotion compatibility, but the doc tags such calls "A regs" so you can skip the `LDX` on assembly fast paths.

## Bulk data: two flavors

The RIA cannot read 6502 RAM — it would need bus mastership it doesn't have. So bulk data uses one of:

### Bulk XSTACK (≤ 512 bytes)

The function prototype takes a `void *` pointer, but on the wire the data is pushed/popped through `RIA_XSTACK`. C wrappers do this transparently. From assembly you push bytes yourself.

Examples: `read_xstack(buf, count, fildes)`, `write_xstack(...)`, `open(path, oflag)` (path goes via xstack).

### Bulk XRAM (no upper limit short of 64 K)

The data lives in [[xram]] from start to finish. The 6502 sends a `(buf, count)` pair as `unsigned int`s, the OS does an internal `&XRAM[buf]`, and the data moves at ~512 KB/s.

Examples: `read_xram(buf, count, fildes)`, `write_xram(...)`. This is how the Picocomputer can refill the entire XRAM in ~150 ms — disk effectively *is* RAM.

## Tail-call optimization

You can chain calls without draining the xstack between them when the leftover bytes happen to *be* the next call's first arg. The canonical example: `read_xstack` → `write_xstack` to copy a file with no RAM at all.

## C library integration

`stdio.h`, `unistd.h`, `fcntl.h`, `stdlib.h`, `time.h` are provided for both [[cc65]] and [[llvm-mos]]. The familiar POSIX functions (`open`, `read`, `write`, `lseek`, `chdir`, etc.) are wrappers that pick the right ABI variant (e.g. `lseek` calls `f_lseek` with reordered args).

## Related pages

- [[ria-registers]] · [[api-opcodes]] · [[rp6502-os]] · [[rp6502-ria]] · [[xram]] · [[memory-map]]
