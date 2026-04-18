---
type: concept
tags: [6502, 65c02, assembly, tables, lists, queue, sort, jump-table, data-structures]
related: [[65c02-instruction-set]], [[6502-application-snippets]], [[6502-programming-idioms]], [[6502-subroutine-conventions]]
sources: [[leventhal-6502-assembly]]
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

## Related pages

- [[6502-application-snippets]] — character and string patterns
- [[6502-programming-idioms]] — arithmetic for index calculations
- [[6502-subroutine-conventions]] — packaging list/table routines as subroutines
- [[65c02-instruction-set]] — `JMP (a,x)` opcode `$7C`; `BRA` for short backward branches
- [[65c02-addressing-modes]] — `(a,x)` indexed absolute indirect addressing mode
