---
type: concept
tags: [rp6502, memory, address-space]
related: [[w65c02s]], [[w65c22s]], [[rp6502-ria]], [[xram]]
sources: [[rp6502-os-docs]]
created: 2026-04-15
updated: 2026-04-15
---

# Memory Map

**Summary**: How the 6502's address space and the RIA's extended RAM are arranged on the Picocomputer.

---

## 6502 address space (16-bit, byte-addressable)

| Address | Size | Content |
| --- | --- | --- |
| `$0000-$FEFF` | 63.75 K | RAM. Nothing reserved — zero page is yours. |
| `$FF00-$FFCF` | 208 B | **Unassigned.** For user expansion (extra VIAs, sound chips, etc.). |
| `$FFD0-$FFDF` | 16 B | [[w65c22s]] VIA registers |
| `$FFE0-$FFFF` | 32 B | [[rp6502-ria]] registers |

Notes:
- There is **no ROM** on the 6502 bus. Reset vector at `$FFFC/D` is in RAM and must be set up before reset goes high.
- The RIA's 32 registers include `RIA_OP`, `RIA_BUSY`, `RIA_A`, `RIA_X`, `RIA_SREG`, `RIA_ERRNO`, `RIA_XSTACK`, `RIA_SPIN`, `RIA_RW0`/`RIA_RW1`, etc. — the entry points for [[rp6502-abi]] OS calls and [[xram]] access.

## Extended address space (XRAM, RIA-side)

| Address | Size | Content |
| --- | --- | --- |
| `$10000-$1FFFF` | 64 K | **XRAM** — see [[xram]] |

XRAM is **not** mapped into the 6502's normal address space. The 6502 reaches it through the `RIA_RW0` / `RIA_RW1` register windows (auto-incrementing pointers) or via OS bulk-XRAM operations.

## Expansion example

The unassigned `$FF00-$FFCF` window is the place to wire your own chip selects. The OS docs sketch:

```
VIA0 at $FFD0  (mandatory — already there)
VIA1 at $FFC0
SID0 at $FF00
SID1 at $FF20
```

## Related pages

- [[w65c02s]] · [[w65c22s]] · [[rp6502-ria]] · [[xram]] · [[rp6502-abi]]
