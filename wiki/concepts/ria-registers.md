---
type: concept
tags: [rp6502, ria, registers, abi, hardware]
related:
  - "[[rp6502-ria]]"
  - "[[rp6502-abi]]"
  - "[[api-opcodes]]"
  - "[[memory-map]]"
  - "[[xram]]"
  - "[[cc65]]"
  - "[[llvm-mos]]"
sources:
  - "[[rp6502-ria-docs]]"
  - "[[rp6502-github-repo]]"
  - "[[rumbledethumps-discord]]"
created: 2026-04-16
updated: 2026-04-18
---

# RIA Registers

**Summary**: The 32 memory-mapped registers at `$FFE0–$FFFF` that form the complete hardware interface between the 6502 and the RIA. These are the only addresses where the 6502 and RIA Pico actually communicate.

---

## Overview

The RIA exposes 32 registers at `$FFE0–$FFFF`. From the 6502 side, these are ordinary memory-mapped I/O — read with `LDA abs`, write with `STA abs`. On the RIA side, they live in **uninitialized RAM** that survives a soft reboot (a hard button press overwrites them, which may function as a security boundary).

Internally, any register address is accessed as `REGS(addr)` = `regs[(addr) & 0x1F]`, so only the low 5 bits matter.

---

## ACIA simulation — character I/O

The first three registers (`$FFE0–$FFE2`) implement a **simulated ACIA** (Asynchronous Communications Interface Adapter) for console character I/O. This is the lowest-level interface for terminal input/output and is used by EhBASIC's `V_INPT`/`V_OUTP` vectors.

| Register | Alias | Address | Description |
|----------|-------|---------|-------------|
| UART status | `RIA_READY` | `$FFE0` | Bit 7 = TX FIFO ready (safe to write); Bit 6 = RX byte available (safe to read) |
| UART TX | `RIA_TX` | `$FFE1` | Write a byte here to send to the console |
| UART RX | `RIA_RX` | `$FFE2` | Read a byte here from the console |

**Typical output pattern** (poll then write):
```asm
poll_tx:
    BIT   RIA_READY       ; test bit 7 (TX ready)
    BPL   poll_tx         ; branch if bit 7 clear (not ready)
    STA   RIA_TX          ; send character
```

**Typical input pattern** (poll then read):
```asm
poll_rx:
    BIT   RIA_READY       ; test bit 6 (RX available) — BIT sets V from bit 6
    BVC   poll_rx         ; branch if bit 6 clear (no byte waiting)
    LDA   RIA_RX          ; read character; SEC to indicate byte received
```

EhBASIC's `V_INPT` and `V_OUTP` use this ACIA simulation for all console I/O. When `LOAD`/`SAVE` redirects to a file, the character I/O is switched to `read_xstack`/`write_xstack` OS calls instead — see [[ehbasic]] for details.

---

## Register map

| Address | Name | Direction | Description |
| --- | --- | --- | --- |
| `$FFE0` | UART status | R | bit 7 = TX ready, bit 6 = RX data available |
| `$FFE1` | UART TX | W | Write a byte to transmit on the console UART |
| `$FFE2` | UART RX | R | Read a received byte from the console UART |
| `$FFE3` | `RIA_VSYNC` | R | VSYNC frame counter — incremented once per VGA frame (~60 Hz); preserved across soft resets; read-only from 6502 side |
| `$FFE4` | `RIA_RW0` | R/W | [[xram|XRAM]] read/write window 0 — reads/writes `xram[RIA_ADDR0]`; auto-increments `RIA_ADDR0` by `RIA_STEP0` |
| `$FFE5` | `RIA_STEP0` | R/W | Signed int8 auto-increment for window 0 (default 1; set to 0 for no increment, negative for decrement) |
| `$FFE6–$FFE7` | `RIA_ADDR0` | R/W | 16-bit XRAM address for window 0 (little-endian) |
| `$FFE8` | `RIA_RW1` | R/W | XRAM read/write window 1 — same behavior as RW0 but independent |
| `$FFE9` | `RIA_STEP1` | R/W | Signed int8 auto-increment for window 1 |
| `$FFEA–$FFEB` | `RIA_ADDR1` | R/W | 16-bit XRAM address for window 1 (little-endian) |
| `$FFEC` | `RIA_XSTACK` | R/W | Write = push byte onto XSTACK; Read = pop byte from XSTACK. Also reflects top-of-stack after each operation |
| `$FFED–$FFEE` | `RIA_ERRNO` | R (16-bit) | Error code from last failed OS call; platform-mapped ([[cc65]] or [[llvm-mos]] encoding) |
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

1. Push all arguments except the last onto XSTACK by writing to `RIA_XSTACK` (`$FFEC`) (see [[rp6502-abi]]).
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

> `API_EDOM` and `API_EILSEQ` are required by ISO C but [[cc65]] doesn't have them — they map to cc65's internal `EUNKNOWN`.

---

## Special device paths (from Discord / v0.18+)

The OS `open()` call accepts pseudo-device paths beyond filesystem filenames:

| Path syntax | Description |
|---|---|
| `open("ROM:filename", O_RDONLY)` | Open a named asset embedded inside the running ROM. Assets added to ROM with `rp6502_asset()` CMake macro. Debug builds can use real filesystem paths. |
| `open("VCP3:9600,7E2", 0)` | Open USB virtual COM port #3 at 9600 baud, 7 data bits, even parity, 2 stop bits. Up to 8 VCP devices (VCP0–VCP7). |
| `open("CON:", ...)` | Console device (stdin/stdout) |
| `open("TTY:", ...)` | TTY device |

**NFC device API**: NFC reader support added v0.21. `SET NFC 0/1/2` enables reader scanning. NDEF TEXT records containing filenames/commands auto-launch on tap. Low-level NFC API documented at `https://picocomputer.github.io/ria.html#nfc-device-api`. (@rumbledethumps, 2026-03-19)

---

## Related pages

- [[rp6502-abi]] · [[api-opcodes]] · [[memory-map]] · [[rp6502-ria]]
- [[rom-file-format]] — ROM asset embedding
- [[ehbasic]] — ACIA simulation usage (V_INPT/V_OUTP console I/O)
- [[rumbledethumps-discord]] — VCP and ROM asset open() examples
