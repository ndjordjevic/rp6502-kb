---
type: source
tags: [rp6502, vga, scanvideo, pico-extras, firmware, dependency, mode-change]
related: [[rp6502-vga]], [[vga-display-modes]], [[hstx]]
sources: [[rp6502-github-repo]]
created: 2026-04-18
updated: 2026-04-18
---

# picocomputer/pico-extras

**Summary**: A fork of the upstream `raspberrypi/pico-extras` library with two bug-fix commits by `rumbledethumps` that correct a memory leak and a debug `printf` that both appear during VGA mode changes at runtime.

---

## Fork purpose

The RP6502-VGA firmware calls `scanvideo_setup_with_timing()` **every time a user program switches display modes**. The upstream library was written with the assumption that this function is called once at startup — calling it repeatedly triggers two bugs that only manifest in the RP6502 use case.

This fork exists solely to fix those two bugs. It is a required dependency of the VGA firmware (`rp6502` repo references it in its CMake build).

## Fork base

The fork branched from upstream at approximately commit `ed98c7a` ("Merge branch 'master' into develop"), merged 2023-06-07 by graham sanderson (Raspberry Pi). No picocomputer-specific tags exist; HEAD is commit `7f48b3f`.

## Picocomputer-specific commits

Both commits landed on 2023-06-23. Only one file was modified: `src/rp2_common/pico_scanvideo_dpi/scanvideo.c`.

### 1. `eeefb73` — hide debug printf that shows on mode change

**Problem**: `setup_sm()` inside `scanvideo.c` contains a debug `printf("Setting up SM %d\n", sm)` guarded only by `#ifndef NDEBUG`. Every mode change triggers a re-initialization of PIO state machines, so the printf floods the terminal during normal operation.

**Fix**: Commented out the printf:
```c
// printf("Setting up SM %d\n", sm);
```

### 2. `7f48b3f` — fix memory leak on mode change

**Problem**: `scanvideo_setup_with_timing()` unconditionally allocates scanline buffers on every call:
```c
// upstream (leaks on mode change):
pico_buffer_alloc_in_place(&b, ...);
scanline_buffers[i].core.data = (uint32_t *)b.bytes;
```
Calling this a second time (mode switch) allocates new memory without freeing the previous allocation, leaking the old scanline buffers.

**Fix**: Wrapped all allocation code in a `if (!scanline_buffers[i].core.data)` guard — buffers are allocated once and reused on subsequent mode changes:
```c
if (!scanline_buffers[i].core.data) {
    pico_buffer_alloc_in_place(&b, ...);
    scanline_buffers[i].core.data = (uint32_t *)b.bytes;
    // ... plane 2/3 allocations also guarded
}
```

## Scope

| Item | Status |
|------|--------|
| `7f48b3f` fix memory leak on mode change | [x] ingested |
| `eeefb73` hide debug printf | [x] ingested |
| Upstream commits (Graham Sanderson / others) | [-] skipped — not RP6502 specific |

## Related pages

- [[rp6502-vga]] — the VGA firmware entity that depends on this fork
- [[vga-display-modes]] — mode switching at the API level; now safe thanks to this fix
- [[hstx]] — RP2350 HSTX peripheral used by the VGA firmware for DVI output
