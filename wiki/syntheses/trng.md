---
type: synthesis
tags: [rp6502, trng, random, ria, rp2350, cc65, llvm-mos, api]
related:
  - "[[rp6502-board]]"
  - "[[w65c02s]]"
  - "[[rp6502-ria]]"
  - "[[rp2350]]"
  - "[[dual-core-sio]]"
  - "[[rp6502-os]]"
  - "[[ria-registers]]"
  - "[[cc65]]"
  - "[[llvm-mos]]"
  - "[[cc65-vs-llvm-mos]]"
  - "[[api-opcodes]]"
sources:
  - "[[rp6502-os-docs]]"
  - "[[rp6502-github-repo]]"
  - "[[cc65-rp6502-platform]]"
  - "[[rumbledethumps-discord]]"
created: 2026-04-18
updated: 2026-04-18
---

# Hardware TRNG and Random Numbers

**Summary**: The RP6502 exposes the RP2350's hardware True Random Number Generator (TRNG) to 65C02 programs via the RIA attribute API; cc65 uses it to seed `rand()` with `_randomize()`, while llvm-mos calls hardware directly on every `lrand()` invocation.

---

## How it works

The RP2350 contains a dedicated hardware TRNG peripheral. The Pico SDK exposes this as `get_rand_64()` (from `<pico/rand.h>`). RIA firmware calls this function when the 65C02 requests a random number:

```c
// src/ria/api/atr.c
case ATR_LRAND:
    return api_return_axsreg(get_rand_64() & 0x7FFFFFFF);
```

The 64-bit hardware value is masked to 31 bits, matching the POSIX `lrand48()` range: **0x00000000 – 0x7FFFFFFF**.

The attribute is **read-only** — writing to `RIA_ATTR_LRAND` returns `EINVAL`.

---

## RIA attribute

| Attribute | ID | Value | Notes |
|---|---|---|---|
| `RIA_ATTR_LRAND` | `0x04` | 31-bit unsigned | Hardware entropy, read-only |

Access via `ria_attr_get(RIA_ATTR_LRAND)`.

> **Deprecated**: Opcode `0x04` in the old dispatch (`atr_api_lrand`) does the same thing but is deprecated. Prefer `ria_attr_get()`.

---

## cc65: seeding with hardware entropy

In cc65, `rand()` is a 16-bit PRNG. It starts deterministic (same seed every run) unless you seed it first. The `_randomize()` function calls `ria_attr_get(RIA_ATTR_LRAND)` **once** to seed the PRNG:

```c
#include <stdlib.h>

int main(void) {
    _randomize();       // seed rand() with hardware entropy
    int r = rand();     // subsequent calls are PRNG, not hardware
    return 0;
}
```

**When to use this pattern**: Games and simulations that need reproducible-from-a-seed randomness with low overhead. Each `rand()` call is cheap (no RIA round-trip). The seed is truly random, so runs differ every time.

**Limitation**: `rand()` returns only 0–32767 (16-bit). For wider ranges, combine two `rand()` calls or use `lrand()` via llvm-mos.

---

## llvm-mos: true random on every call

In llvm-mos, `lrand()` calls the hardware TRNG on **every invocation** — no PRNG state involved:

```c
#include <rp6502.h>

long r = lrand();   // hits RP2350 TRNG every time
```

This returns a full 31-bit hardware-random value each call. Use this when:
- You need true randomness (cryptographic seeds, shuffling, nonces)
- You cannot tolerate PRNG correlation between values
- 16-bit range is insufficient

> **Do not use `rand()` in llvm-mos** if true randomness is required. `rand()` is a PRNG seeded at startup with a fixed value unless you call `srand()` manually. (@rumbledethumps, 2026-04-02)

---

## 65C02 assembly

For assembly programs, use the `ria_attr_get` API:

```asm
; Get a 31-bit random number via ria_attr_get(RIA_ATTR_LRAND)
; RIA_ATTR_LRAND = $04
    lda #$04        ; attribute ID
    sta RIA_A       ; $FFE2
    jsr ria_attr_get
    ; result: A = low byte, X = high byte (31-bit in X:A)
```

The result arrives in the A and X registers (low/high bytes of the 16-bit portion), with the full 31-bit value reconstructed from the `axsreg` return convention.

---

## Comparison

| Aspect | cc65 `_randomize()` + `rand()` | llvm-mos `lrand()` |
|---|---|---|
| Entropy source | Hardware (once, at seed) | Hardware (every call) |
| Return range | 0–32767 (16-bit) | 0–0x7FFFFFFF (31-bit) |
| RIA round-trip per call | No (after seed) | Yes |
| PRNG state | Yes | No |
| True random each call | No | Yes |
| Typical use | Games, simulations | Security seeds, shuffles |

---

## Pitfalls

- **EhBASIC `RND(1)` confusion**: In EhBASIC, `RND(1)` *sets* the random seed (it does NOT return a random number). `RND(0)` returns a random number. This is the reverse of Microsoft BASIC. See [[known-issues]].
- **`rand()` without `_randomize()`** (cc65): starts with a fixed seed — same sequence every run. Always call `_randomize()` at program start.
- **`rand()` in llvm-mos**: does not use hardware entropy unless you call `srand()` with a value from `lrand()`.

---

## Related pages

- [[rp6502-os]] — full attribute table, including `RIA_ATTR_LRAND`
- [[api-opcodes]] — deprecated opcode 0x04 (`atr_api_lrand`)
- [[cc65]] — `_randomize()`, `rand()` behavior
- [[llvm-mos]] — `lrand()` function
- [[cc65-vs-llvm-mos]] — side-by-side toolchain comparison
- [[known-issues]] — EhBASIC `RND(1)` vs `RND(0)` quirk
