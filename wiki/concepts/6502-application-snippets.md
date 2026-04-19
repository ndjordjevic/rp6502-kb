---
type: concept
tags: [6502, 65c02, assembly, string, ascii, code-conversion, snippets, crc, io-patterns, memory-clear, parity, bracket-test, max, sum, checksum, zero-count]
related:
  - "[[65c02-instruction-set]]"
  - "[[65c02-addressing-modes]]"
  - "[[6502-subroutine-conventions]]"
  - "[[6502-programming-idioms]]"
  - "[[6502-io-patterns]]"
sources:
  - "[[leventhal-6502-assembly]]"
  - "[[leventhal-subroutines]]"
  - "[[zaks-programming-6502]]"
created: 2026-04-18
updated: 2026-04-18
---

# 6502 Application Snippets

**Summary**: Reusable 6502/65C02 code patterns for string/character operations (Ch 6) and code conversion (Ch 7) from Leventhal. Each snippet is documented with purpose, registers used, and the key algorithm idea.

---

## ASCII fundamentals

The ASCII code has structure useful for 6502 manipulation:
- **Digits `0–9`**: `$30–$39`. Convert decimal ↔ ASCII with `ADC #'0` / `SBC #'0`.
- **Uppercase `A–Z`**: `$41–$5A`. Alphabetic sort = numeric sort.
- **Lowercase `a–z`**: `$61–$7A`. Toggle case by toggling bit 5 (`EOR #$20`).
- **Control characters**: `$00–$1F`. Carriage return = `$0D`, line feed = `$0A`, space = `$20`, DEL = `$7F`.
- The gap between `'9'` (`$39`) and `'A'` (`$41`) is 7 positions. Hex-to-ASCII conversions must bridge this gap.

---

## String operations (Ch 6)

### Length of a string (CR-terminated)

Scan until carriage return (`$0D`), count characters. Optimized form increments before checking:

```asm
; Input:  string starts at absolute address STRBASE (or via ZP pointer)
; Output: string length in A (and Y on exit)
; Registers used: A, Y

STLEN:
    LDY  #$FF
    LDA  #$0D       ; carriage return to compare
CHKCR:
    INY
    CMP  STRBASE,Y  ; check character
    BNE  CHKCR
    TYA             ; length → A
    RTS
```

> With a **ZP pointer** (`$40/$41`) and the 65C02 `(zp),Y` mode: replace `STRBASE,Y` with `($40),Y`. The string address is then dynamic (set by the caller before JSR).

**Notes**:
- Initialize Y to `$FF` (−1) so the first `INY` gives index 0.
- Placing a sentinel maximum count (`CPY #MAXLEN / BEQ DONE`) prevents infinite loops on unterminated strings.

### Skip leading blanks

Advance a pointer past leading space characters (`$20`):

```asm
; On entry: X = starting index into string at STRBASE
SKIPBL:
    LDA  STRBASE,X
    CMP  #$20
    BNE  DONE       ; non-blank found
    INX
    JMP  SKIPBL
DONE:
```

### Replace leading zeros with blanks

Useful for formatted numeric output — replace `'0'` with `' '` until the first non-zero digit:

```asm
    LDX  #0
LZERO:
    LDA  NUMSTR,X
    CMP  #'0
    BNE  DONE
    LDA  #$20       ; space
    STA  NUMSTR,X
    INX
    JMP  LZERO
DONE:
```

### Check parity (set/check bit 7)

Parity conventions vary (mark/space, even/odd). To **set odd parity** on a 7-bit ASCII character (bit 7 = 1 if even number of 1 bits):

```asm
; A = 7-bit character
; Sets bit 7 so total number of 1 bits is odd
    LDX  #7
    CLC
PAR:
    ROL  A          ; rotate into carry
    BCC  EVEN
    DEX             ; count 1 bits
EVEN:
    DEX             ; always decrement (handles 0 bit)
    BNE  PAR
    ; If X is odd → parity bit = 1
    ; Adjust bit 7 of A accordingly
```

### Pattern match (two equal-length strings)

Compare two strings of known length Y; result in A (0 = match, $FF = no match):

```asm
; $42/$43 = address of string 1
; $44/$45 = address of string 2
; Y = string length

PMTCH:
    LDX  #$FF       ; pre-load "no match" marker
CMPE:
    DEY
    LDA  ($42),Y    ; 65C02 indirect or ($42),Y indexed
    CMP  ($44),Y
    BNE  DONE
    TYA
    BNE  CMPE
    LDX  #0         ; match
DONE:
    TXA             ; result in A
    RTS
```

---

## Code conversion (Ch 7)

### Hex nibble → ASCII character

Convert a 0–15 value in A to its ASCII hex representation (`'0'–'9'`, `'A'–'F'`):

```asm
; Input:  A = hex nibble (0–15, upper nibble must be 0)
; Output: A = ASCII character ('0'–'9' or 'A'–'F')
; Registers used: A, Carry

HEXASC:
    CMP  #10
    BCC  ASCZ        ; 0–9: just add ASCII '0'
    ADC  #('A'-'9'-2) ; bridge gap (carry=1 from CMP, so offset−1)
ASCZ:
    ADC  #'0
    RTS
```

**Why the gap offset?** ASCII `'9'` = `$39`, ASCII `'A'` = `$41`. The gap is 7 characters (`$3A`–`$40`). After `CMP #10` with a value ≥ 10, Carry is set (=1), so the effective addition is `'A'-'9'-2 + 1 = 'A'-'9'-1 = 7`. Then `ADC #'0` adds `$30`, yielding `$41` for A (value 10). ✓

Alternative (no branch, uses decimal mode):

```asm
    SED
    CLC
    ADC  #$90    ; decimal add: produces extra carry for A–F
    ADC  #$40    ; completes ASCII offset
    CLD
```

### ASCII hex digit → nibble value

Reverse conversion — ASCII `'0'–'9'`/`'A'–'F'` → 0–15:

```asm
; Input:  A = ASCII hex character
; Output: A = nibble (0–15)
    SEC
    SBC  #'0
    CMP  #10
    BCC  DONE    ; was '0'–'9'
    SBC  #('A'-'9'-2)  ; was 'A'–'F': remove gap
DONE:
    RTS
```

### Decimal to 7-segment code (table lookup)

Convert a decimal digit (0–9) to a 7-segment display code. Input validation: if A ≥ 10, return 0 (blank display).

```asm
; Input:  X = decimal digit (0–9)
; Output: A = 7-segment code, or 0 if invalid

SEVSEG:
    LDA  #0         ; error code (blank)
    CPX  #10
    BCS  DONE       ; X ≥ 10 → invalid
    LDA  SSEG,X     ; lookup
DONE:
    RTS

SSEG:   .BYTE $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F
;         0     1     2     3     4     5     6     7     8     9
```

Segment layout (bit positions in code byte): `g f e d c b a` (bit 0 = segment a).

### BCD byte → two decimal digits

Unpack a BCD byte (two packed digits) to two ASCII characters:

```asm
; Input:  A = packed BCD byte (e.g., $47 → '4','7')
; Output: $40 = ASCII high digit, $41 = ASCII low digit

    PHA
    LSR  A
    LSR  A
    LSR  A
    LSR  A          ; high nibble → low nibble
    ORA  #'0
    STA  $40
    PLA
    AND  #$0F       ; low nibble
    ORA  #'0
    STA  $41
```

### Binary byte → three decimal digits

Convert an 8-bit value (0–255) to three ASCII decimal digits. Strategy: repeated subtraction by powers of 10, or divide by 10 twice.

```asm
; Quick approach using comparison:
; Hundreds: subtract 100 while >= 0, count subtractions
; Tens: subtract 10 while >= 0
; Units: remainder
```

(Full implementation uses the divide routine from [[6502-programming-idioms]].)

---

## Key patterns from these chapters

| Pattern | Key instruction(s) | Notes |
|---------|-------------------|-------|
| ASCII digit arithmetic | `ADC #'0` / `SBC #'0` | Exploit ordered ASCII codes |
| Hex-to-ASCII | `CMP #10 / BCC / ADC #offset` | Bridge `'9'`→`'A'` gap |
| Table lookup | `LDA TABLE,X` | Fastest for fixed-size conversions |
| BCD arithmetic | `SED` / `ADC` / `CLD` | Always `CLD` at end |
| String scan | `INX/INY + CMP + BNE` loop | Null/CR as terminator |
| Character class test | `CMP #' ' / BCC` (control char) | Exploit ASCII ordering |

---

## Code conversion routines (Leventhal 1982, Ch. 4)

These are the formal subroutines from Leventhal & Saville. Each uses stack-based parameter passing unless otherwise noted (see [[6502-subroutine-conventions]]).

### BN2BCD — Binary byte → two BCD bytes

| Property | Value |
|----------|-------|
| Entry | `A` = binary byte |
| Exit | `A` = hundreds digit, `Y` = packed tens+ones |
| Cycles | 133 max (depends on number of subtractions) |
| Size | 38 bytes + 1 byte TEMP in RAM |

**Algorithm**: subtract 100 repeatedly to get hundreds; subtract 10 repeatedly for tens; remainder = ones. Shift tens into high nibble; pack with ones.

Suitable for displaying a 0–99 or 0–255 decimal value.

### BCD2BN — BCD byte → binary byte

| Property | Value |
|----------|-------|
| Entry | `A` = packed BCD byte |
| Exit | `A` = binary |
| Cycles | 38 |
| Size | 24 bytes + 1 byte TEMP |

**Algorithm**: `high_nibble × 10 + low_nibble`. Multiply by 10 as `(value × 8) + (value × 2)` using shifts.

### BN2HEX — Binary byte → two ASCII hex characters

| Property | Value |
|----------|-------|
| Entry | `A` = binary byte |
| Exit | `A` = high-nibble ASCII, `Y` = low-nibble ASCII |
| Cycles | ~77 |
| Size | 31 bytes |

**Algorithm**: mask each nibble separately; add `$30` if decimal digit; add additional `$07` to bridge the `'9'`→`'A'` gap. (Same approach as the Leventhal 1986 snippet in this page's "Hex nibble → ASCII" section but now applied to a full byte in one call.)

### HEX2BN — Two ASCII hex chars → binary byte

| Property | Value |
|----------|-------|
| Entry | `A` = high-nibble ASCII, `Y` = low-nibble ASCII |
| Exit | `A` = binary byte |
| Cycles | ~74 + 3 per non-decimal digit |
| Size | 30 bytes + 1 byte TEMP |

**Algorithm**: reverse of BN2HEX — subtract `$30`; if result ≥ 10 subtract `$07` more. Shift high nibble left 4 and OR with low.

Note: does **not** validate that the characters are legal hex digits.

### BN2DEC — 16-bit signed binary → ASCII decimal string

| Property | Value |
|----------|-------|
| Entry | Stack (low-byte-first): return addr, buffer addr, signed 16-bit value |
| Exit | Buffer: length byte, optional `'-'`, ASCII digits (most-significant first) |
| Cycles | ~7,000 |
| Size | 174 bytes + 7 bytes RAM + 2 bytes page-zero buffer pointer |

**Algorithm**: negate if negative (record sign flag); divide by 10 repeatedly (collecting remainders = digits); convert remainders to ASCII with `ADC #'0`; concatenate in reverse; prepend sign if needed. Length byte is stored in buffer position 0.

**Use case**: formatted decimal display on terminal or VGA screen — the only way to show a signed 16-bit value as decimal text.

### DEC2BN — ASCII decimal string → 16-bit signed binary

| Property | Value |
|----------|-------|
| Entry | `A`:`Y` = high:low byte of string address |
| Exit | `A`:`Y` = high:low byte of 16-bit result; `C`=0 valid, `C`=1 invalid |
| Cycles | ~670 |
| Size | 171 bytes + 4 bytes RAM + 2 bytes page-zero string pointer |

**Algorithm**: check for leading sign (`+`/`-`); accumulate digits as `ACCUM = ACCUM × 10 + digit` (multiply by 10 as shifts+adds); negate result if minus sign seen. Sets Carry if non-sign/non-digit character is found.

**Use case**: keyboard input parsing — convert typed decimal number to binary for computation.

---

## String manipulation (Leventhal 1982, Ch. 8)

All routines use a **length-prefixed string format**: the first byte of the string is a binary length (0–255), followed by the actual characters. Not null-terminated. Strings live anywhere in RAM; addresses are passed on the stack.

### STRCMP — Compare two strings

| Property | Value |
|----------|-------|
| Entry | Stack: return addr, string-2 address, string-1 address |
| Exit | `Z`=1 identical; `C`=0 string-2 larger; `C`=1 string-1 ≥ string-2 |
| Cycles | 81 + 19 × chars compared (until first mismatch) or 93 + 19 × shorter length (if equal through shorter) |
| Size | 52 bytes + 4 bytes page-zero (two string pointers) |

**Algorithm**: determine shorter length; compare byte-by-byte; if any mismatch found compare lengths to set flags; if equal through shorter treat the longer string as larger.

Spaces are treated as ordinary characters — `"SPRING MAID"` < `"SPRINGMAID"` (space = `$20` < `M` = `$4D`).

### CONCAT — Concatenate two strings

| Property | Value |
|----------|-------|
| Entry | Stack: return addr, max-length-of-string-1, string-2 addr, string-1 addr |
| Exit | String-1 extended with string-2 content; `C`=0 if complete, `C`=1 if string-2 was truncated |
| Cycles | ~40 × chars appended + 164 overhead |
| Size | 141 bytes + 7 bytes RAM + 4 bytes page-zero |

**Algorithm**: if combined length ≤ max, copy all of string-2 after string-1 and update length byte; else copy only enough characters to reach max and set Carry. String-2 length of zero exits cleanly. If string-1 already exceeds max, exits with Carry set (error).

### POS — Find substring position

| Property | Value |
|----------|-------|
| Entry | Stack: return addr, substring address, string address |
| Exit | `A` = 1-based index of first occurrence; `A`=0 if not found |
| Cycles | 135 overhead + 47/char match + 50/char mismatch |
| Size | 124 bytes + 6 bytes RAM + 4 bytes page-zero |

**Algorithm**: scan string for first character of substring; on match compare remaining characters; restart search after mismatch. Returns index of first occurrence only.

**Special cases**: substring length 0 → returns 0; substring longer than string → returns 0; index 1 means substring is a prefix (useful for command abbreviation matching in BASIC interpreters).

**Worst case** (string = `"AAAAAAB"`, substring = `"AAB"`): `(len_str − len_sub + 1) × (47 × (len_sub−1) + 50) + 135` cycles.

---

## Utility routines (Zaks Ch. 8)

### Memory clear (ZEROM)

Fill a region of memory with zero. The region runs from `BASE+1` to `BASE+LENGTH` (max 255 bytes). Register X counts down from LENGTH to 0.

```asm
ZEROM   LDX  #LENGTH
        LDA  #0
CLEAR   STA  BASE,X    ; store 0 at BASE+X
        DEX
        BNE  CLEAR
        RTS
```

**Cycle trick**: loading the accumulator only once, then using absolute indexed addressing to write each location. Loop overhead is 5 cycles per byte (DEX=2, BNE=3). For a 256-byte page, put the count in a zero-page byte to allow X=0 as the exit condition cleanly.

**Extension**: for a memory test (POST), follow with a read-verify pass, then write `$AA`/`$55` and verify again.

---

### Range test (bracket testing)

Determine whether the ASCII character in A is in the range `['0','9']`. Uses C and V flags as status outputs — no branch-return needed; caller tests flags directly.

```asm
; Uses ORA #$80 to set bit 7, then compares against $B0/$B9 (ASCII with parity).
; On return: C=0 and V=0 → digit in range; V=0, C=1 → too high; C=0, V=0 (TOOLOW branch) → too low.

BRACK   LDA  #$40
        ADC  #$40      ; force V flag — mark "too low" condition
        LDA  LOC
        ORA  #$80      ; set bit 7 = 1
        CMP  #$B0      ; $B0 = ASCII '0' with parity
        BCC  TOOLOW
        CMP  #$B9      ; $B9 = ASCII '9' with parity
        BEQ  OUT
        BCS  TOOHIGH
OUT     CLC            ; C=0, V=0 → in range [0..9]
        CLV
        RTS
TOOLOW  SEC            ; C=1, V=0 → too low
        CLV
        RTS
TOOHIGH RTS            ; C=1 (set by CMP), no V change → too high
```

> **Note on `CMP`**: after `CMP`, carry is SET if `A >= operand`. Reset (clear) if `A < operand`.

---

### Parity generation

Generate even parity for a 7-bit character; install result in bit 7.

```asm
PARITY  LDX  #$07     ; count 7 data bits
        LDA  #$00
        STA  ONECNT   ; count of 1s
        LDA  CHAR
        ROL  A        ; discard existing bit 7
NEXT    ROL  A        ; shift next bit into carry
        BCC  ZERO     ; if carry=0, bit is 0
        INC  ONECNT   ; bit is 1
ZERO    DEX
        BNE  NEXT
        ROL  A        ; restore bit 0 to its original position
        ROL  A        ; discard again
        LSR  ONECNT   ; parity bit → carry (even parity: 0 if even number of 1s)
        ROR  A        ; install carry into bit 7
        RTS
```

---

### ASCII to BCD (simple)

When ASCII digits have parity bit set, their hex codes are `$B0`–`$B9`. Without parity, they are `$30`–`$39`. In both cases, masking off the upper nibble gives the BCD digit 0–9.

```asm
        LDA  CHAR
        AND  #$0F     ; mask upper nibble → BCD digit 0-9
        STA  BCDCHAR
```

For the reverse (BCD to ASCII): `ORA #$30` (no parity) or `ORA #$B0` (with odd parity for bit 7).

**BCD to binary hint** (Zaks): for `N3 N2 N1 N0` packed BCD, the binary value is `((N3×10 + N2)×10 + N1)×10 + N0`. Multiply by 10 in 6502:

```asm
; Multiply A by 10:  ((A << 1) << 1 + A) << 1
        ASL  A        ; ×2
        ASL  A        ; ×4
        ADC  ORIG     ; ×4 + ×1 = ×5 (ORIG was saved before shifts)
        ASL  A        ; ×10
```

---

### Find largest element

Search a table for its maximum value. Table layout: first byte is count N, followed by N bytes of data. Pointer `BASE` in zero page uses `(BASE),Y` indirect indexed addressing to reach any table anywhere in memory.

```asm
MAX     LDY  #0
        LDA  (BASE),Y  ; get N (count)
        TAY
        LDA  #0
        STA  INDEX     ; initialize max = 0
LOOP    CMP  (BASE),Y  ; compare current max against element Y
        BCS  NOSWITCH  ; current max ≥ element — no update
        LDA  (BASE),Y  ; new max found
        STY  INDEX     ; remember its position
NOSWITCH DEY
        BNE  LOOP
        RTS
```

Works for unsigned (positive) integers. **For signed integers**: initialize max to `$80` (most negative) and compare with signed branch `BGE` / `BLT`.

---

### 16-bit sum of table

Sum all N elements; result in `SUMLO`/`SUMHI`. Uses carry propagation via `INC SUMHI` to extend naturally to 16 bits.

```asm
        LDA  #0
        STA  SUMLO
        STA  SUMHI
        TAY
        LDA  (BASE),Y  ; get N
        TAY
        CLC
ADLOOP  LDA  (BASE),Y
        ADC  SUMLO
        STA  SUMLO
        BCC  NOCARRY
        INC  SUMHI
        CLC
NOCARRY DEY
        BNE  ADLOOP
        RTS
```

**Note**: after `BCC NOCARRY`, `SUMHI` is incremented by one to handle the carry out of the 8-bit `ADC`. This is a compact alternative to using `ADC #0` on SUMHI: it avoids a register load/store, but requires the explicit `CLC` after the `INC`.

---

### EOR checksum

XOR all bytes in a table; result in A. N is stored as the first byte.

```asm
CHECKSUM LDY  #0
         LDA  (BASE),Y  ; get N
         TAY
         LDA  #0        ; initialize checksum
CHLOOP   EOR  (ADDR),Y  ; XOR next element
         DEY
         BNE  CHLOOP
         RTS            ; A = checksum
```

EOR-based checksums detect any single-bit error and many multi-bit errors, but miss even numbers of identical errors on the same bit position. For stronger integrity use CRC-16 (see [[6502-io-patterns]] — Leventhal 1982 Ch. 10).

---

### Count zeroes

Count the number of zero-valued bytes in a table. N is stored as the first byte; count returned in X.

```asm
ZEROES  LDY  #0
        LDA  (ADDR),Y  ; get N
        TAY
        LDX  #0        ; zero counter
ZLOOP   LDA  (ADDR),Y
        BNE  NOTZ
        INX
NOTZ    DEY
        BNE  ZLOOP
        RTS            ; X = count of zeros
```

**Generalisation**: replace `BNE NOTZ` / `INX` with any test/action to count any character class (digits, spaces, letters). See also the parity generator above for a similar count-of-ones pattern.

---

## Related pages

- [[6502-subroutine-conventions]] — how to package these as callable subroutines
- [[6502-programming-idioms]] — arithmetic: multi-precision, multiply, divide
- [[6502-data-structures]] — tables, lists, jump tables
- [[65c02-instruction-set]] — new 65C02 ops used here: `(zp)` addressing, `PHX`/`PHY`
- [[6502-io-patterns]] — terminal I/O, CRC-16, device table handler (Leventhal 1982, Ch. 10)
