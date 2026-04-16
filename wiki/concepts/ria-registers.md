---
type: concept
tags: [rp6502, ria, registers, abi, hardware]
related: [[rp6502-ria]], [[rp6502-abi]], [[api-opcodes]], [[memory-map]]
sources: [[rp6502-ria-docs]], [[rp6502-github-repo]]
created: 2026-04-16
updated: 2026-04-16
---

# RIA Registers

**Summary**: The 32 memory-mapped registers at `$FFE0–$FFFF` that form the complete hardware interface between the 6502 and the RIA. These are the only addresses where the 6502 and RIA Pico actually communicate.

---

## Overview

The RIA exposes 32 registers at `$FFE0–$FFFF`. From the 6502 side, these are ordinary memory-mapped I/O — read with `LDA abs`, write with `STA abs`. On the RIA side, they live in **uninitialized RAM** that survives a soft reboot (a hard button press overwrites them, which may function as a security boundary).

Internally, any register address is accessed as `REGS(addr)` = `regs[(addr) & 0x1F]`, so only the low 5 bits matter.

---

## Register map

| Address | Name | Direction | Description |
| --- | --- | --- | --- |
| `$FFE0–$FFEB` | — | — | *(not assigned in current firmware; 12 bytes available for future use)* |
| `$FFEC` | `RIA_STACK` | R | Top byte of the XSTACK — used to read the first pushed arg back after a call |
| `$FFED–$FFEE` | `RIA_ERRNO` | R (16-bit) | Error code from last failed OS call; platform-mapped (cc65 or llvm-mos encoding) |
| `$FFEF` | `RIA_OP` | W | Write an op-code here to trigger an OS call; the RIA sees this and dispatches |
| `$FFF0` | — | R | `$EA` (NOP) — first byte of the return stub |
| `$FFF1–$FFF2` | — | R | `$80 $FE` (BRA -2) while busy; `$80 $00` (BRA +0, i.e. NOP) when done |
| `$FFF3–$FFF4` | `RIA_A` | R | `$A9 xx` (LDA #val) — load return value low byte into A |
| `$FFF5–$FFF6` | `RIA_X` | R | `$A2 xx` (LDX #val) — load return value high byte into X |
| `$FFF7` | — | R | `$60` (RTS) — return from the call |
| `$FFF8–$FFF9` | `RIA_SREG` | R (16-bit) | 32-bit return value extension (upper 16 bits beyond AX) |
| `$FFFA–$FFFB` | NMI vector | — | Standard 6502 vectors (managed by RIA) |
| `$FFFC–$FFFD` | RESET vector | — | Points to `$FFE0` / the RIA on reset |
| `$FFFE–$FFFF` | IRQ/BRK vector | — | Standard 6502 vectors (managed by RIA) |

> The address decoding uses only 5 bits, so `REGS(0xFFF2) & 0x80` is the same as checking bit 7 of the BRA instruction byte — when it's `$FE` (busy) the sign bit is set; when `$00` (done) it's clear. `RIA_BUSY` is thus defined as `REGS(0xFFF2) & 0x80`.

---

## The return stub

The RIA return mechanism is elegant and avoids needing a dedicated "complete" signal. The 8 bytes at `$FFF0–$FFF7` form executable 6502 code:

```
$FFF0  EA        NOP
$FFF1  80 FE     BRA -2      ← spins here while RIA_BUSY (byte is $FE → sign bit set)
$FFF3  A9 xx     LDA #val    ← return value low byte (API_A)
$FFF5  A2 xx     LDX #val    ← return value high byte (API_X)
$FFF7  60        RTS
```

**While busy**: byte at `$FFF2` is `$FE` → `BRA -2` loops forever (RIA_SPIN).  
**When done**: byte at `$FFF2` is `$00` → `BRA +0` falls through to `LDA`, `LDX`, `RTS`.

So `JSR RIA_SPIN` ($FFF0) both waits *and* collects the return value in a single call. Alternatively, the 6502 can poll `RIA_BUSY` (`$FFF2` bit 7) manually and branch away to do other work.

---

## Making an OS call — step by step

1. Push all arguments except the last onto XSTACK via `RIA_RW0` or `RIA_RW1` (see [[rp6502-abi]]).
2. Load the last argument into `A` (and `X`/`RIA_SREG` if wider than 8 bits).
3. `STA $FFEF` — write the op-code to `RIA_OP`. This releases the BRA-self spin and starts the RIA handler.
4. Either:
   - `JSR $FFF0` (RIA_SPIN) — blocks until done, returns with A/X/SREG loaded, then `RTS` back to caller.
   - Poll `LDA $FFF2` / `BMI poll_loop` — check bit 7, loop until clear, then read `RIA_A`/`RIA_X`.
5. On error, return value is `$FFFF` (−1 as uint16) and `RIA_ERRNO` holds the platform errno.

---

## Error codes

The internal `api_errno` enum (from `src/ria/api/api.h`) has 19 entries. They are translated to platform-specific values based on the `errno_opt` attribute:

| Internal name | Meaning |
| --- | --- |
| `API_ENOENT` | No such file or directory |
| `API_ENOMEM` | Not enough space |
| `API_EACCES` | Permission denied |
| `API_ENODEV` | No such device |
| `API_EMFILE` | Too many open files |
| `API_EBUSY` | Device or resource busy |
| `API_EINVAL` | Invalid argument |
| `API_ENOSPC` | No space left on device |
| `API_EEXIST` | File exists |
| `API_EAGAIN` | Resource unavailable, try again |
| `API_EIO` | I/O error |
| `API_EINTR` | Interrupted system call |
| `API_ENOSYS` | Function not supported |
| `API_ESPIPE` | Illegal seek |
| `API_ERANGE` | Result too large |
| `API_EBADF` | Bad file descriptor |
| `API_ENOEXEC` | Executable file format error |
| `API_EDOM` | Math argument out of domain |
| `API_EILSEQ` | Invalid/incomplete multibyte character |

> `API_EDOM` and `API_EILSEQ` are required by ISO C but cc65 doesn't have them — they map to cc65's internal `EUNKNOWN`.

---

## Data gap

`RIA_RW0` and `RIA_RW1` (auto-incrementing XRAM read/write windows) are mentioned in [[memory-map]], [[xram]], and [[rp6502-abi]] but their exact addresses are not yet confirmed — they require reading `src/ria/sys/ria.h`. They are the primary mechanism for the 6502 to access XRAM byte-by-byte and for pushing data onto the XSTACK.

## Related pages

- [[rp6502-abi]] · [[api-opcodes]] · [[memory-map]] · [[rp6502-ria]]
