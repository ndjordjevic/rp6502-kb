---
type: concept
tags: [6502, 65c02, assembly, string, ascii, code-conversion, snippets]
related: [[65c02-instruction-set]], [[65c02-addressing-modes]], [[6502-subroutine-conventions]], [[6502-programming-idioms]]
sources: [[leventhal-6502-assembly]]
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

## Related pages

- [[6502-subroutine-conventions]] — how to package these as callable subroutines
- [[6502-programming-idioms]] — arithmetic: multi-precision, multiply, divide
- [[6502-data-structures]] — tables, lists, jump tables
- [[65c02-instruction-set]] — new 65C02 ops used here: `(zp)` addressing, `PHX`/`PHY`
