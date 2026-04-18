---
type: concept
tags: [6502, 65c02, assembly, io, terminal, parity, crc, device-table, rdline]
related: [[6502-application-snippets]], [[6502-interrupt-patterns]], [[6502-subroutine-conventions]], [[6522-via]]
sources: [[leventhal-subroutines]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 I/O Patterns

**Summary**: Terminal character I/O, parity generation/checking, CRC-16, and a device-independent I/O handler — all from Leventhal & Saville Ch. 10. These patterns are higher-level building blocks that sit above the interrupt-driven raw I/O covered in [[6502-interrupt-patterns]].

---

## Terminal line I/O (RDLINE / WRLINE)

### RDLINE — Read a line from a terminal

Reads characters into a buffer until carriage return (`$0D`). Supports two editing control characters:

| Control | Key code | Action |
|---------|----------|--------|
| Control-H | `$08` | Delete previous character (sends destructive backspace: cursor-left, space, cursor-left) |
| Control-X | `$18` | Delete entire line (repeats Control-H for all buffered characters) |

On buffer full: sends Bell (`$07`), discards incoming character, continues.

| Property | Value |
|----------|-------|
| Entry | `A`:`Y` = high:low of buffer address; `X` = buffer size (max characters) |
| Exit | `X` = number of characters in buffer (carriage return excluded) |
| Cycles | ~67 per ordinary character (excluding RDCHAR/WRCHAR time) |
| Size | 138 bytes + 4 bytes RAM + 2 bytes page-zero buffer pointer |

**System dependencies**: RDLINE expects three platform-specific subroutines:
- `RDCHAR` — read one character into `A` (no echo)
- `WRCHAR` — write character from `A` to output device
- `WRNEWL` — issue newline sequence (CR+LF on most systems; CR-only on Apple II)

**Design note**: the carriage return itself is **not** stored in the buffer. The buffer contains only the printable characters. Exit value `X` = exact character count.

**RP6502 relevance**: a functional terminal line editor is exactly what any interactive RP6502 program (BASIC, monitor, command shell) needs at the input layer. Replace the three platform subroutines with RP6502-OS `$FF` ROM calls.

### WRLINE — Write a line to output device

Write `X` characters from a buffer to an output device using a caller-supplied `WRCHAR`.

| Property | Value |
|----------|-------|
| Entry | `A`:`Y` = high:low of buffer; `X` = character count |
| Cycles | 24 overhead + 25 per character (excluding WRCHAR time) |
| Size | 37 bytes + 2 bytes RAM + 2 bytes page-zero buffer pointer |

---

## Parity (GEPRTY / CKPRTY)

### GEPRTY — Generate even parity in bit 7

Counts the 1-bits in the low 7 bits of `A` and places the even-parity bit in bit 7. Even parity = bit 7 set so that total 1-bit count is even.

| Property | Value |
|----------|-------|
| Entry | `A` = 7-bit character (bit 7 ignored) |
| Exit | `A` = character with even parity in bit 7 |
| Cycles | 114 max (exits earlier if remaining bits are all zeros) |
| Size | 39 bytes + 1 byte RAM |

**Algorithm**: shift left logically, increment count if carry; repeat until remaining data is zero; shift LSB of count into bit 7 of original data.

### CKPRTY — Check parity of a byte

| Property | Value |
|----------|-------|
| Entry | `A` = byte including parity in bit 7 |
| Exit | `C`=0 even parity; `C`=1 odd parity |
| Cycles | 111 max |
| Size | 25 bytes + 1 byte RAM |

Same bit-counting algorithm as GEPRTY; shifts count LSB to Carry instead of OR-ing into the data byte.

---

## CRC-16 (ICRC16 / CRC16 / GCRC16)

Three co-operating entry points implement IBM BSC (Bisync) CRC-16 using the polynomial **X¹⁶ + X¹⁵ + X² + 1**.

| Entry | Purpose | Cycles | Size |
|-------|---------|--------|------|
| `ICRC16` | Initialise CRC to 0, load polynomial | 28 | 19 bytes |
| `CRC16` | Update CRC with one data byte in `A` | 302–454 | 53 bytes |
| `GCRC16` | Retrieve current CRC into `A`:`Y` | 14 | 7 bytes |

**Usage pattern**:
```
JSR ICRC16          ; initialise
loop:
  LDA next_byte
  JSR CRC16         ; fold in each byte
end loop:
JSR GCRC16          ; A = high byte, Y = low byte of CRC
```

**CRC16 algorithm**: for each of the 8 bits of the data byte, shift data and CRC left one bit; if `data_bit XOR CRC_MSB == 1` then `CRC := CRC XOR polynomial`. Worst case = 302 + 19×8 = 454 cycles per byte.

**Data memory**: 5 bytes — `CRC` (2 bytes), `PLY` (2 bytes, set by `ICRC16`), `VALUE` (1 byte scratch).

**Changing the polynomial**: only `ICRC16` is polynomial-specific. To use a different CRC polynomial (e.g. CRC-CCITT = X¹⁶ + X¹² + X⁵ + 1), modify only the constant loaded into `PLY`/`PLY+1`.

**Use case**: serial data integrity on 6502 comms systems. On RP6502, relevant for file transfer protocols or custom UART-based peripherals.

---

## Device-independent I/O handler (IOHDLR)

The most architectural piece of Ch. 10 — a linked-list device table that decouples programs from specific I/O hardware.

### Structure overview

Three data structures:

**I/O Control Block (IOCB)** — 7 bytes, filled by the caller:

| Offset | Content |
|--------|---------|
| 0 | Device number |
| 1 | Operation number (0–6, see table below) |
| 2 | Status byte (written by IOHDLR) |
| 3–4 | Buffer address (low, high) |
| 5–6 | Buffer length (low, high) |

**Device Table Entry** — 17 bytes, one per registered device:

| Offsets | Content |
|---------|---------|
| 0–1 | Link to next entry (linked list) |
| 2 | Device number |
| 3–4 | Initialize routine address |
| 5–6 | Input status routine address |
| 7–8 | Read-1-byte routine address |
| 9–10 | Read-N-bytes routine address |
| 11–12 | Output status routine address |
| 13–14 | Write-1-byte routine address |
| 15–16 | Write-N-bytes routine address |

Set unimplemented fields to `$0000`. If IOHDLR is asked for a zero-addressed operation, it returns error code 2 (operation not supported for this device).

**Operations**:

| Number | Description |
|--------|-------------|
| 0 | Initialize device |
| 1 | Input status |
| 2 | Read 1 byte |
| 3 | Read N bytes (line) |
| 4 | Output status |
| 5 | Write 1 byte |
| 6 | Write N bytes (line) |

**Status codes**: 0 = no error; 1 = bad device number; 2 = unsupported operation; 3 = output device ready.

### IOHDLR entry points

| Name | Purpose |
|------|---------|
| `IOHDLR` | Dispatch I/O: walk device list, find device, call operation routine |
| `INITIO` | Initialise device list (set `DVLST` = 0, empty list) |
| `ADDDL` | Add a device table entry to the list |

**IOHDLR call protocol**: `A`:`Y` = high:low of IOCB address; `X` = data byte for write-1-byte operations. Returns `A` = status byte from IOCB.

**Timing**: 93 cycles minimum + 59 cycles × number of devices searched before finding a match.

### Design pattern

```
; One-time initialisation:
JSR INITIO
LDA #>DEV1_TABLE : LDY #<DEV1_TABLE : JSR ADDDL
LDA #>DEV2_TABLE : LDY #<DEV2_TABLE : JSR ADDDL

; I/O request:
LDA #1          : STA IOCB+IOCBDN  ; device 1
LDA #3          : STA IOCB+IOCBOP  ; operation 3 = read N bytes
LDA #>BUF       : STA IOCB+IOCBBA+1
LDA #<BUF       : STA IOCB+IOCBBA
LDA #0          : STA IOCB+IOCBBL+1
LDA #64         : STA IOCB+IOCBBL  ; buffer length = 64
LDA #>IOCB : LDY #<IOCB : JSR IOHDLR
LDA IOCB+IOCBST : BNE ERROR
```

**RP6502 relevance**: This pattern is the 6502 equivalent of a POSIX `read(fd, buf, len)` / `write(fd, buf, len)` model. Adapting it to RP6502-OS's `$FF` API calls would give 65C02 programs a portable device abstraction layer. The RP6502-OS already provides a similar abstraction, but understanding IOHDLR explains the design motivations behind any I/O abstraction layer.

---

## Summary table

| Routine | Purpose | Key feature |
|---------|---------|-------------|
| `RDLINE` | Read edited line from terminal | Control-H/X editing, bell on overflow |
| `WRLINE` | Write line to output device | Simple count-driven output |
| `GEPRTY` | Generate even parity in bit 7 | Bit-counting via shift-and-count |
| `CKPRTY` | Check byte parity | Returns Carry flag |
| `ICRC16` | Init CRC-16 (IBM BSC polynomial) | Polynomial = X¹⁶+X¹⁵+X²+1 |
| `CRC16` | Update CRC with one byte | 302–454 cycles/byte |
| `GCRC16` | Get current CRC into `A`:`Y` | 14 cycles |
| `IOHDLR` | Device-independent I/O dispatch | Linked-list device table |
| `INITIO` | Initialise device list | — |
| `ADDDL` | Register a device | Prepends to linked list |

---

## Related pages

- [[6502-application-snippets]] — character operations, string routines, code conversion
- [[6502-interrupt-patterns]] — lower-level: interrupt-driven VIA I/O, ring buffers
- [[6522-via]] — VIA register reference (for hardware-level I/O)
- [[6502-subroutine-conventions]] — parameter passing, register preservation
