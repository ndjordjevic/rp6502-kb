---
type: source
tags: [6502, 65c02, assembly, opcodes, arithmetic, compare, decimal, bcd, interrupts, overflow, stack, nmos]
related:
  - "[[6502-compare-instructions]]"
  - "[[6502-decimal-mode]]"
  - "[[6502-overflow-flag]]"
  - "[[65c02-instruction-set]]"
  - "[[6502-interrupt-patterns]]"
  - "[[6502-stack-and-subroutines]]"
  - "[[6502-programming-idioms]]"
  - "[[6502-common-errors]]"
  - "[[learning-6502-assembly]]"
sources:
created: 2026-04-18
updated: 2026-04-18
---

# 6502.org Tutorials

**Summary**: Eight programming tutorials from 6502.org covering the 65C02/NMOS 6502 instruction set differences, compare techniques, BCD decimal mode, the overflow flag, interrupt handling, stack register preservation, and opcode references — all authoritative and peer-reviewed by the 6502 community.

---

## Source overview

| File | Author | Date | Key topic |
|------|--------|------|-----------|
| `6502 Compare Instructions` | (anonymous) | 2002-12-01 | CMP/CPX/CPY flag table, branch selection |
| `65C02 Opcodes` | Bruce Clark | — | Complete 65C02 vs NMOS diff |
| `Beyond 8-bit Unsigned Comparisons` | Bruce Clark | 2004-04-03 | 16/24-bit equality, unsigned, signed comparisons |
| `Decimal Mode` | Bruce Clark | — | BCD arithmetic, flag validity per processor |
| `Investigating Interrupts` | John Pickens | — | IRQ/NMI/BRK/WAI, RS-232, waveform generator |
| `NMOS 6502 Opcodes` | (anonymous) | — (updated 2020-10-17) | Complete NMOS opcode reference |
| `Register Preservation Using The Stack` | Bruce Clark | 2004-06-07 | A/X/Y save patterns, BRK/IRQ B-flag |
| `The Overflow (V) Flag Explained` | Bruce Clark | 2004-04-04 | V flag mechanics, SO pin, decimal mode |

URL base: `https://6502.org/tutorials/`

---

## Key facts extracted

### Compare instructions (CMP/CPX/CPY)

- All three perform `register − memory` without storing the result; only N, Z, C flags change.
- **CMP** has 8 addressing modes (like ADC/SBC); **CPX/CPY** have 3 (immediate, absolute, zero page).
- **CMP ignores the D flag** and **does not affect V** — distinguishing it from SBC.
- Flag results: `Z=1, C=1` means equal; `C=0` means less-than (unsigned); `C=1` means ≥.
- The N flag after CMP is **not** the signed comparison result — this is a common error.

### Multi-byte comparisons (Bruce Clark)

- **Equality**: compare bytes in any order with CMP/CPX/CPY; BNE on mismatch.
- **Unsigned multi-byte**: compare high bytes first, use BCC/BNE to short-circuit. Alternatively, multi-byte subtraction (CMP low, SBC high) leaves C as the unsigned result.
- **Signed comparison**: `N XOR V` is the correct signed less-than test. Use `SEC; SBC; BVC; EOR #$80` to make N equal N XOR V. The N flag after signed compare **does not** equal C (unsigned) — different misconception.
- **SO pin caveat**: hardware can set V via the SO pin (DIP-38); alternative signed comparison inverts MSB of both operands before unsigned CMP.
- **16-bit signed**: `CMP low; SBC high; BVC; EOR #$80` — V flag not needed until high bytes are processed.

### 65C02 vs NMOS 6502 (Bruce Clark)

See [[65c02-instruction-set]] for full detail. Key differences:

- **New (zp) mode**: 8 instructions (ADC/AND/CMP/EOR/LDA/ORA/SBC/STA) gain a zero-page indirect mode without Y — 5 cycles; STA (zp) is 1 cycle faster than STA (zp),Y.
- **BIT gains** immediate (Z only), zp,X, abs,X modes. Immediate does not affect N or V.
- **DEC/INC accumulator**: opcode $3A / $1A; 2 cycles; no operand needed.
- **JMP (abs,X)**: opcode $7C; 6 cycles; enables efficient jump tables without RTS trick.
- **BRA** (Branch Always): opcode $80; 3/4 cycles.
- **PHX/PHY/PLX/PLY**: push/pull X or Y directly; 3/4 cycles; PLX/PLY set N and Z.
- **STZ** (Store Zero): 4 modes; eliminates `LDA #0; STA` sequence.
- **TRB** (Test and Reset Bits): Z = (A AND mem) == 0; mem = mem AND (NOT A). Opcode $14/$1C.
- **TSB** (Test and Set Bits): Z = (A AND mem) == 0; mem = mem OR A. Opcode $04/$0C.
- **BBR0–BBR7 / BBS0–BBS7** (Rockwell + WDC): branch on zero-page bit; 3-byte zp,rel; 5+ cycles.
- **RMB0–RMB7 / SMB0–SMB7** (Rockwell + WDC): reset/set a single zero-page bit; 2-byte; 5 cycles.
- **STP** (WDC only): halts clock; resumes only on RESET.
- **WAI** (WDC only): sleep until IRQ/NMI; with I=1, next instruction executes inline — 1-cycle latency.
- **Bug fixes**: JMP (abs) page-boundary bug fixed (now 6 cycles vs 5). D flag cleared on BRK/IRQ/NMI/RESET.
- **Cycle savings**: ASL/LSR/ROL/ROR abs,X drops from always-7 to 6 cycles when no page crossing.
- **Undocumented opcodes**: all 105 are safe NOPs on 65C02; some read memory (risk I/O side effects); some are 1-cycle NOPs useful for precise timing.

### Decimal mode (Bruce Clark)

See [[6502-decimal-mode]] for full detail. Key facts:

- Only ADC and SBC respond to the D flag; all others (ASL, INC, DEC…) always use binary.
- **6502**: only C is guaranteed valid after decimal ADC/SBC; N, V, Z are undocumented.
- **65C02/65816**: C, N, Z are valid; V is still undocumented (but consistent).
- **65C02 costs 1 extra cycle** in decimal mode for ADC/SBC (all modes).
- **65C02/65816 auto-clear D on interrupt**: saves CLD instruction in every ISR.
- BCD comparison: CMP works correctly for valid BCD ($00–$99) because byte ordering is preserved.
- Technique to force valid N/Z on 6502: follow decimal ADC/SBC with `EOR #0` (1 byte, 1 cycle).

### Overflow (V) flag (Bruce Clark)

See [[6502-overflow-flag]] for full detail. Key facts:

- Only 6 instructions affect V: **ADC, BIT, CLV, PLP, RTI, SBC**.
- V = 1 when signed two's-complement result is out of −128…+127 range.
- **BIT**: immediate mode (65C02/65816 only) does **not** affect V; all other BIT modes copy bit 6 of memory into V.
- **SO pin** (DIP-38): hardware negative edge sets V; rarely used; the 65816 removes this pin.
- `CLV + BVC` = forced branch for relocatable code (before BRA was added on 65C02).

### Interrupts (John Pickens + Bruce Clark)

See [[6502-interrupt-patterns]] for full detail. Key facts:

- IRQ line is **level-sensitive** (not edge); NMI is **edge-sensitive** (negative edge).
- Interrupt sequence: 7 clocks — 2 internal + 2 push PC + 1 push P + 2 fetch vector.
- RTI restores P from stack automatically — unlike JSR/RTS which don't touch flags.
- Open-drain IRQ lines need pull-up resistors; clear interrupt source **early** in ISR to avoid re-entry after RTI.
- Ghost interrupts: if interrupt source is disabled while asserting IRQ, ISR sees no flags set — handle gracefully.
- **WAI** (65C02 WDC): with I=0, normal ISR; with I=1, next instruction executes inline after 1 clock — total latency 1 clock vs. 7–14 normally.
- 6502 performance: min 7, max 14, average ~9 clocks at any speed; RTI = 6 clocks.
- NMI for RTC: 10ms timer example with 4-byte centisecond counter + proper month/leap-year handling.
- RS-232 ring buffer: 256-byte, dual pointer, 8-bit auto-wrap; fullness check via `WR_PTR − RD_PTR`.
- Waveform generator ISR: VIA T1 at configurable rate (formula: n = f(φ2)/f(IRQ) − 2).
- 6522 serial shift register (mode 100): 9 discrete voltage levels ≈ 3-bit D/A for DTMF/audio.

### Register preservation (Bruce Clark)

See [[6502-stack-and-subroutines]] for full detail. Key facts:

- **65C02**: `PHA; PHX; PHY` / `PLY; PLX; PLA` — cleanest form; no accumulator side-effect.
- **6502** (no PHX/PLX/PHY/PLY): either use TXA/TYA with PHA (overwrites A temporarily), or extract A from stack via TSX + `LDA $100,X+1`.
- **BRK vs. IRQ disambiguation**: must examine the stacked P register (TSX + `LDA $100,X+2` + `AND #$10`), **not** the current P register via PHP/PLA — that always shows B=1.
- 65C02 BRK/IRQ handler is 1 byte, 2 cycles shorter in both entry and exit vs. 6502 equivalent.

---

## Related pages

- [[6502-compare-instructions]]
- [[6502-decimal-mode]]
- [[6502-overflow-flag]]
- [[65c02-instruction-set]]
- [[6502-interrupt-patterns]]
- [[6502-stack-and-subroutines]]
- [[6502-programming-idioms]]
- [[6502-common-errors]]
- [[learning-6502-assembly]]
