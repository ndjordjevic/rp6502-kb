---
type: concept
tags: [6502, 65c02, assembly, tables, lists, queue, sort, jump-table, data-structures, array, memory-fill, binary-search]
related: [[65c02-instruction-set]], [[6502-application-snippets]], [[6502-programming-idioms]], [[6502-subroutine-conventions]]
sources: [[leventhal-6502-assembly]], [[leventhal-subroutines]]
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Data Structures

**Summary**: 6502/65C02 patterns for tables, ordered lists, queues, bubble sort, and jump tables — from Leventhal Ch. 9. These are the building blocks for command dispatch, data management, and sorted collections.

---

## Lists

### Add entry to unordered list (no duplicates)

Search the list for the entry; add it only if absent.

```asm
; Input:  (0040) = new entry
;         (0041) = current list length
;         (0042..) = list
; After:  entry appended if absent; length incremented

        LDA  $40        ; get entry
        LDX  $41        ; index = length
SRLST:
        CMP  $41,X      ; compare with element at index
        BEQ  DONE       ; already in list
        DEX
        BNE  SRLST
        INC  $41        ; increment length
        LDX  $41
        STA  $41,X      ; append
DONE:
```

**Notes**:
- Does not work if list length is 0 — add an initial check `BEQ ADELM`.
- For long lists, use **hashing**: index into a sub-list based on a few bits of the entry (like selecting a dictionary page by first letter), then search only that sub-list.

### Check an ordered list

Binary items in ascending order. Search backward; stop when an element smaller than the entry is found (since further elements are smaller still).

```asm
; Input:  (0041) = search key
;         (0042) = list length
;         (0043..) = list (ascending order)
; Output: (0040) = $00 if found, $FF if not found

        LDA  $41        ; key
        LDX  $42        ; index = length
        LDY  #0         ; found marker
SRLST:
        CMP  $42,X      ; compare key with element
        BEQ  DONE       ; found
        BCS  NOTIN      ; key > element → not in list (ordered)
        DEX
        BNE  SRLST
NOTIN:
        LDY  #$FF       ; not found
DONE:
        STY  $40
```

**Binary search** (not shown): divide the remaining list in half each iteration — O(log N) instead of O(N).

---

## Queues (FIFO)

A queue needs a **head pointer** (next read position), **tail pointer** (next write position), and a **count** (or full/empty flags).

### Circular queue (ring buffer)

```asm
; QBUF: queue buffer (e.g., 16 bytes at $0050)
; QHEAD: index of next byte to read
; QTAIL: index of next byte to write
; QCOUNT: number of bytes currently in queue

; Enqueue (add to tail):
ENQUEUE:
    LDX  QCOUNT
    CPX  #QSIZE         ; full?
    BCS  QFULL
    LDX  QTAIL
    STA  QBUF,X
    INX
    CPX  #QSIZE
    BNE  NOTWR
    LDX  #0             ; wrap around
NOTWR:
    STX  QTAIL
    INC  QCOUNT
    RTS
QFULL: ...

; Dequeue (remove from head):
DEQUEUE:
    LDX  QCOUNT
    BEQ  QEMPTY         ; empty?
    LDX  QHEAD
    LDA  QBUF,X
    INX
    CPX  #QSIZE
    BNE  NOTRD
    LDX  #0             ; wrap around
NOTRD:
    STX  QHEAD
    DEC  QCOUNT
    RTS
QEMPTY: ...
```

**Interrupt-safe**: in interrupt-driven I/O the ISR enqueues received bytes; the main program dequeues them. Use `SEI`/`CLI` around the count check+update pair to prevent race conditions.

---

## Sorting

### Bubble sort (ascending → descending)

Compare adjacent pairs; swap if out of order; repeat until no swaps occur in a full pass.

```asm
; Input:  (0040) = array length N
;         (0041..) = array of unsigned bytes
; After:  array sorted in descending order

SORT:
        LDY  #0         ; Y = interchange flag (0 = sorted)
        LDX  $40
        DEX             ; N-1 pairs
PASS:
        LDA  $40,X      ; compare element at X
        CMP  $41,X      ; with element at X+1
        BCS  COUNT      ; already in order (A >= M → no swap)
        LDY  #1         ; set interchange flag
        PHA             ; swap via stack
        LDA  $41,X
        STA  $40,X
        PLA
        STA  $41,X
COUNT:
        DEX
        BNE  PASS
        DEY             ; Y = 0 → sorted; Y = $FF → did swaps
        BEQ  SORT       ; if swaps occurred, repeat
```

**Important edge cases**:
- Two equal elements: `BCS` (branch if A ≥ M) ensures equal elements are **not** swapped → avoids endless loop.
- Fewer than 2 elements: add guard `CPX #1 / BCC DONE` at entry.
- Use `PHA`/`PLA` for the swap — cheaper than a temp memory location, and the Stack has plenty of room.

**Alternative swap** (saves a PHA/PLA at the cost of a ZP byte):

```asm
        STA  TEMP
        LDA  $41,X
        STA  $40,X
        LDA  TEMP
        STA  $41,X
```

---

## Jump tables

### Pre-65C02 style (JMP via zero-page pointer)

Double the index (each entry = 2 bytes), fetch the target address into zero page, then `JMP (zp)`:

```asm
; Input:  (0042) = index (0-based)
; Jump table starts at JTBL (2 bytes per entry, LSB first)

        LDA  $42
        ASL  A          ; × 2 for 2-byte entries
        TAX
        LDA  JTBL,X     ; LSB of target
        STA  $40
        LDA  JTBL+1,X   ; MSB of target
        STA  $41
        JMP  ($40)      ; indirect jump
```

### 65C02 style (JMP absolute indexed indirect)

`JMP (JTBL,X)` — loads the target address directly from `JTBL+X` without needing a ZP intermediate. Three instructions instead of seven:

```asm
        LDA  $42
        ASL  A          ; × 2
        TAX
        JMP  (JTBL,X)   ; 65C02 opcode $7C — indexed absolute indirect
```

> This is one of the most impactful 65C02 improvements for real programs. Command dispatch, state machines, and menu systems become significantly cleaner. See [[65c02-instruction-set]] for the `JMP (a,x)` encoding.

### Self-modifying jump (pre-65C02 alternative)

Patch the operand of a `JMP abs` instruction directly in memory. Saves the ZP pointer at the cost of code self-modification (not ROMable):

```asm
        LDA  JTBL,X
        STA  JMPINST+1  ; patch LSB
        LDA  JTBL+1,X
        STA  JMPINST+2  ; patch MSB
JMPINST:
        JMP  $0000      ; operand is overwritten
```

---

## Table lookup patterns

| Use case | Pattern |
|----------|---------|
| Constant table (code conversion) | `LDA TABLE,X` — fastest; index in X |
| Dynamic base address | Load base into ZP pair; `LDA (ZP),Y` (indexed) or `(ZP)` (65C02, Y=0) |
| 2D table (row × col) | Multiply row by row-width; add column; use as index |
| Sparse lookup | Binary search on a sorted key table; parallel value table |

**Lookup table size**: a 256-entry byte table fits in one page (256 bytes). If the table must not straddle a page boundary, align it on a 256-byte boundary (`.ORG` to a `$xx00` address).

---

## Memory operations (Leventhal 1982, Ch. 5)

### MFILL — Memory fill

Fill an arbitrary area of memory with a constant byte value.

| Property | Value |
|----------|-------|
| Entry | Stack: return addr, fill-value byte, area-size (2 bytes), start-address (2 bytes) |
| Exit | Area `[base .. base+size-1]` written with value |
| Cycles | ~11 per byte + 93 overhead |
| Size | 68 bytes + 5 bytes RAM + 2 bytes page-zero pointer |

**Algorithm**: fill complete pages first (using an 8-bit inner loop), then the remaining partial page. Avoids a 16-bit counter in the inner loop for speed. Size = `$0000` causes immediate exit without writing.

**Use case**: screen clear (fill video RAM with space character), zero-initialise a buffer, install NOP sled.

**Caution**: filling any part of page-zero or the stack page (`$0100–$01FF`) causes unpredictable results if this routine itself uses those areas.

### BLKMOV — Block move

Move a block of data from a source area to a destination area. Handles overlapping regions correctly.

| Property | Value |
|----------|-------|
| Entry | Stack: return addr, byte-count (2 bytes), source-address (2 bytes), dest-address (2 bytes) |
| Exit | `byte-count` bytes copied from source to dest |
| Cycles | 128 overhead + 20 + 4622×(high byte) + 18×(low byte) for left move; higher for overlap/right move |
| Size | 157 bytes + 2 bytes RAM + 4 bytes page-zero (two pointers) |

**Algorithm**: if dest start falls inside the source range, copy right-to-left (high-address-first, "move right") to avoid overwriting unread source data. Otherwise copy left-to-right (low-address-first). Both paths handle complete pages separately from a partial-page tail.

**Use case**: sprite/tile DMA substitute on 6502 systems; scrolling text buffers by shifting lines up or down.

---

## Multi-dimensional array indexing (Leventhal 1982, Ch. 5)

All routines use stack-based parameter passing. Elements are zero-indexed. Arrays stored in row-major order.

### D1BYTE — 1D byte array element address

```
address = BASE + SUBSCRIPT
```

| Cycles | Size |
|--------|------|
| 73 | 37 bytes + 4 bytes RAM |

Entry: stack `(return-addr, subscript 2 bytes, base-address 2 bytes)`. Exit: `A`:`Y` = high:low of element address.

### D1WORD — 1D word (16-bit) array element address

```
address = BASE + SUBSCRIPT × 2
```

| Cycles | Size |
|--------|------|
| 78 | 39 bytes + 4 bytes RAM |

Uses a single left-shift to multiply subscript by 2. Exit: `A`:`Y` = high:low of element address (element occupies address and address+1).

### D2BYTE — 2D byte array element address

```
address = BASE + ROW_SUBSCRIPT × ROW_SIZE + COL_SUBSCRIPT
```

| Cycles | ~1500 (dominated by multiply) |
|--------|------|
| Size | 119 bytes + 10 bytes RAM |

Parameters: col-subscript (2 bytes), row-size (2 bytes), row-subscript (2 bytes), base-address (2 bytes). Row-size = number of columns. Uses the Ch. 6 16-bit multiplication subroutine MUL16.

### D2WORD — 2D word array element address

```
address = BASE + (ROW_SUBSCRIPT × ROW_SIZE + COL_SUBSCRIPT) × 2
```

Extends D2BYTE with an extra left-shift for 2-byte elements.

### NDIM — N-dimensional array element address

For arrays declared with Pascal-like bounds `A: ARRAY[0..K₁, 0..K₂, ..., 0..Kₙ] OF BYTE`:

```
offset = (((...(S₁ × D₂ + S₂) × D₃ + S₃) × D₄ + S₄) ...) × Dₙ + Sₙ
```

where `Sᵢ` = subscript i, `Dᵢ` = size of dimension i.

Parameters are pushed as pairs `(subscript_i, dimension_size_i)` for each dimension, then the base address. The routine applies the Horner evaluation loop. Cycle count scales linearly with number of dimensions and quadratically with the magnitude of each dimension size.

**RP6502 relevance**: 2D byte array indexing maps directly to screen-buffer access. A 320×240 framebuffer cell at `(row, col)` = `VRAM_BASE + row × 320 + col` — exactly the D2BYTE formula with `ROW_SIZE = 320`.

---

## Array operations (Leventhal 1982, Ch. 9)

### ASUM8 — 8-bit array summation

Sum an array of up to 255 unsigned bytes; produce a 16-bit result.

| Property | Value |
|----------|-------|
| Entry | `A`:`Y` = high:low start address; `X` = array size (bytes) |
| Exit | `A` = high byte of sum; `Y` = low byte |
| Cycles | ~16 per byte + 39 overhead |
| Size | 30 bytes + 2 bytes page-zero pointer |

**Algorithm**: clear 16-bit sum; add each byte to low byte; propagate carry to high byte on each overflow. Processes from highest address downward.

### ASUM16 — 16-bit array summation

Sum an array of up to 255 unsigned 16-bit words; produce a 24-bit result.

| Property | Value |
|----------|-------|
| Entry | `A`:`Y` = high:low start address; `X` = array size (words) |
| Exit | `X`:`A`:`Y` = high/mid/low bytes of 24-bit sum |
| Cycles | ~43 per word + 46 overhead |
| Size | 60 bytes + 3 bytes RAM + 2 bytes page-zero pointer |

**Algorithm**: 24-bit memory accumulator; add each 16-bit element; increment MSB on second carry. Elements stored in 6502 little-endian style (LSB first).

### BINSCH — Binary search

Search a sorted array of unsigned bytes for a target value. Returns index or "not found".

| Property | Value |
|----------|-------|
| Entry | Stack: return addr, value, array-size, array-address |
| Exit | `C`=0 found (`A` = 0-based index); `C`=1 not found |
| Cycles | ~52 per iteration + 80 overhead; iterations ≈ log₂(N) |
| Size | 89 bytes + 3 bytes RAM + 2 bytes page-zero pointer |

**Algorithm**: maintain lower and upper bound indices; each iteration guesses `(lower + upper) / 2`; compare value with guess element; discard half the remaining array based on ordering; repeat until match or bounds cross.

For N=32: ~5 iterations → ~340 cycles. Compare with linear search at up to 16 cycles × 32 = 512 cycles worst case.

**Requirement**: array must be sorted in ascending order. If sorted descending, reverse the bound-update logic.

### BUBSRT — Bubble sort (ascending)

Sort an array of up to 255 unsigned bytes in ascending order using bubble sort.

| Property | Value |
|----------|-------|
| Entry | Stack: return addr, sort-value, array-size, array-address |
| Cycles | ~34 × N² + 25 × N + 70 (N = array length) |
| Size | 79 bytes + 2 bytes RAM + 4 bytes page-zero |

**Algorithm**: outer loop iterates until no interchange occurs; inner loop compares adjacent pairs; swaps if out of order; sets an interchange flag. Equal elements are not swapped (stable with respect to equal elements).

For N=32: ~35,686 cycles ≈ 34ms at 1 MHz. Bubble sort is fine for small arrays on 6502; use binary search + insertion for larger data sets.

### RAMTST — RAM test

Non-destructive RAM test verifying that each byte can store both `$55` and `$AA`.

| Property | Value |
|----------|-------|
| Entry | Stack: return addr, test-value, area-size, start-address |
| Exit | `C`=0 RAM good; `C`=1 failure (`A`:`Y` = failing address) |
| Size | ~110 bytes |

**Algorithm**: for each byte: save original value; write `$55`; read back and compare; write `$AA`; read back and compare; restore original. Failure returns the address of the first bad cell.

**Use case**: power-on self test (POST) for 6502 systems. The RP6502-OS could use this style of test during boot to verify working RAM before running user programs.

---

## Related pages

- [[6502-application-snippets]] — character and string patterns
- [[6502-programming-idioms]] — arithmetic for index calculations
- [[6502-subroutine-conventions]] — packaging list/table routines as subroutines
- [[65c02-instruction-set]] — `JMP (a,x)` opcode `$7C`; `BRA` for short backward branches
- [[65c02-addressing-modes]] — `(a,x)` indexed absolute indirect addressing mode
