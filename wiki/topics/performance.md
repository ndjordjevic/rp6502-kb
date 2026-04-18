---
type: topic
tags: [rp6502, performance, benchmark, storage, throughput, phi2]
related: [[fatfs]], [[xram]], [[rp6502-abi]], [[examples]]
sources: [[examples], [release-notes]]
created: 2026-04-18
updated: 2026-04-18
---

# Performance

**Summary**: RP6502 storage and CPU throughput benchmarks — the `bench.c` example measures USB mass storage read/write speeds; [[xram]] load speeds are documented separately.

---

## USB mass storage benchmark (bench.c)

The `bench.c` program measures sequential read/write throughput via `write_xram()` / `read_xram()`:

- **Chunk size**: 32,256 bytes (32 KB − 512 B) per pass
- **Method**: 9 passes; final score = average of middle 7 (min and max discarded)
- **Metric**: KB/s

```c
write_xram(0, CHUNK_SIZE, fd);   // XRAM 0x0000 → file, CHUNK_SIZE bytes
read_xram(0, CHUNK_SIZE, fd);    // file → XRAM 0x0000
```

Bench data is randomized beforehand via `_randomize()` + `rand()` writes to XRAM.

Typical USB thumb drive results vary by media. The `bench.c` output reports per-second buckets plus a final score:

```
MSC BENCHMARK
-------------
W1: 1200 KB/s   W2: 1350 KB/s  ...
R1: 2800 KB/s   R2: 3100 KB/s  ...

Write: 1280 KB/s
Read:  3050 KB/s
```

(Actual values depend on drive speed and USB host controller.)

---

## XRAM throughput

From [[xram]] (Discord benchmark, @rumbledethumps):

| Operation | Speed |
|-----------|-------|
| System RAM load (`load()` llvm-mos) | ~170 KB/s |
| XRAM load via `load_xram()` | **~800 KB/s** (DMA, no 6502 CPU used) |

The 6502 is free during `load_xram()` — the transfer is entirely DMA-driven.

---

## CPU clock scaling

The 65C02 clock (PHI2) is adjustable at runtime:

```c
ria_attr_set(1000, RIA_ATTR_PHI2_KHZ);   // 1 MHz
ria_attr_set(8000, RIA_ATTR_PHI2_KHZ);   // 8 MHz
```

From `attr.c`: a 2048-iteration busy loop at 1 MHz takes ~14–15 clock() ticks; the same loop at 8 MHz completes ~8× faster per wall-clock second.

Default clock: configurable via monitor. Max clock: 8 MHz (W65C02S rated limit).

---

## cc65 vs llvm-mos performance

From [[yt-ep18-llvm-mos]]:

| Compiler | Relative performance |
|----------|---------------------|
| cc65 | Baseline |
| llvm-mos | Faster (LLVM optimization, better code generation) |

llvm-mos has higher optimization quality for C code. cc65 is generally simpler to set up. See [[cc65]] and [[llvm-mos]] for toolchain details.

---

## Related pages

- [[xram]] — XRAM bulk I/O and DMA-load throughput
- [[fatfs]] — FatFS filesystem; `write_xram`/`read_xram` write through FatFS
- [[rp6502-abi]] — `write_xram`, `read_xram`, `write_xstack`, `read_xstack` OS calls
- [[cc65]] / [[llvm-mos]] — compiler toolchains
