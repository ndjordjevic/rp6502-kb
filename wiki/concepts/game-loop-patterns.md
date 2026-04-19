---
type: concept
tags: [rp6502, vga, vsync, game-loop, interrupt, timing, animation]
related:
  - "[[vga-display-modes]]"
  - "[[rp6502-vga]]"
  - "[[xram]]"
  - "[[6502-interrupt-patterns]]"
  - "[[via-programming]]"
  - "[[rp6502-abi]]"
sources:
  - "[[rp6502-vga-docs]]"
  - "[[rp6502-ria-docs]]"
  - "[[rp6502-github-repo]]"
created: 2026-04-18
updated: 2026-04-18
---

# Game Loop Patterns

**Summary**: How to structure a game loop on the RP6502 Picocomputer — VSYNC synchronization, interrupt-driven updates, double-buffering in XRAM, and timing patterns for smooth 60 Hz animation.

---

## Overview

The RP6502-VGA outputs at approximately **60 Hz**. Each frame takes ~16.7 ms. For smooth animation, the 6502 should:
1. Update game state during the **vertical blanking interval** (vblank window just after VSYNC).
2. Write to XRAM (framebuffer / sprite data) **only during vblank** to avoid tearing.
3. Present the updated frame at the next VSYNC.

There are two approaches: **polling** (simple) and **interrupt-driven** (more responsive).

---

## Polling loop (simplest)

The `RIA.vsync` register is a byte counter that increments once per display frame (~60 Hz). Spin-wait for it to change:

```c
#include <rp6502.h>

void game_loop(void)
{
    uint8_t v = RIA.vsync;
    for (;;) {
        /* Wait for next frame */
        while (RIA.vsync == v)
            ;
        v = RIA.vsync;

        /* Update game state and XRAM here — we are in vblank */
        update_sprites();
        update_scroll();
    }
}
```

**Assembly equivalent:**
```asm
VSYNC = $FFE3     ; RIA.vsync register address (VSYNC frame counter)

game_loop:
    LDA VSYNC
    TAX              ; remember current frame count

wait_vsync:
    CPX VSYNC        ; has frame count changed?
    BEQ wait_vsync   ; no — keep waiting

    ; In vblank window now
    JSR update_sprites
    JSR update_scroll
    JMP game_loop
```

---

## Interrupt-driven VSYNC

For applications that need to handle input or perform work outside of the game loop, use the VSYNC interrupt. Set `RIA.irq = 1` to enable it.

```c
#include <rp6502.h>

volatile uint8_t frame_ready;

void vsync_isr(void)
{
    /* Called once per frame at VSYNC */
    frame_ready = 1;
    /* Acknowledge by reading/clearing IRQ flag */
}

void main(void)
{
    /* Install interrupt handler */
    set_irq(vsync_isr);
    RIA.irq = 1;       /* enable VSYNC IRQ */
    asm("CLI");        /* enable 6502 IRQ */

    for (;;) {
        if (frame_ready) {
            frame_ready = 0;
            update_game_state();
            render_frame();
        }
        /* Other work (AI, sound updates, input polling) here */
    }
}
```

**Note**: The VSYNC ISR runs during horizontal retrace, not necessarily at the start of vblank. If your update takes longer than the vblank window, you will see tearing. Profile your update time against the frame budget.

---

## Frame budget (60 Hz, 8 MHz PHI2)

At 8 MHz, one 60 Hz frame = ~133,333 CPU cycles.

Rough guidelines for update budget:
| Task | Approximate cycles |
|---|---|
| Move 16 sprites (4 registers each) | ~1,000 |
| Scroll a 40×25 tile map by 1 pixel | ~5,000–10,000 |
| Update 64-voice PSG note table | ~500 |
| `printf` one line to ANSI console | ~5,000–20,000 |
| `fread()` 512 bytes from FAT | ~50,000–100,000 |

Disk I/O (FAT / USB mass storage) is too slow to run inside vblank. Do file reads in the main loop between frames; use a double-buffer to keep vblank writes fast.

---

## Double-buffering pattern

XRAM is 64 KB. For small framebuffers, keep two copies at different XRAM offsets and swap which one the VGA firmware reads at each VSYNC.

```c
/* Two sprite tables at XRAM $0000 and $1000 */
#define BUF_A 0x0000
#define BUF_B 0x1000

uint32_t front = BUF_A;
uint32_t back  = BUF_B;

void swap_buffers(void)
{
    /* Tell VGA to read from 'back' (now the updated version) */
    xreg_vga_canvas(CANVAS_LAYER, back, ...);
    /* Swap for next frame */
    uint32_t tmp = front;
    front = back;
    back = tmp;
}
```

---

## Input polling inside game loop

Read keyboard / gamepad state from XRAM (set up via `xreg()` calls) inside the VSYNC window.

```c
#include <rp6502.h>

/* Set up keyboard XREG at XRAM offset 0x8000 before the loop */
xreg(0, 0, 0, 0x8000);    /* XREG device 0, channel 0, reg 0 = keyboard bitmap */

/* In the game loop: */
void handle_input(void)
{
    /* Read key bitmap from XRAM */
    /* HID keycode 0x4F = Right Arrow → bit 0x4F in the 32-byte bitmap */
    uint8_t byte_idx = HID_KEY_RIGHT / 8;
    uint8_t bit_mask = 1 << (HID_KEY_RIGHT % 8);
    if (xram[0x8000 + byte_idx] & bit_mask) {
        player_x++;
    }
}
```

See [[vga-display-modes]] for input XREG setup and [[rp6502-ria]] for the input device XREG addresses.

---

## Timing without VSYNC — VIA timer

If you do not use VGA output, or need a game clock independent of frame rate, use [[via-programming]] T1 in continuous mode:

```asm
; 60 Hz tick using T1 (8 MHz PHI2):
; count = 8000000 / 60 - 2 = 133331 = $2091 3
T1_LOW  = $13
T1_HIGH = $20

; Set T1 continuous mode (ACR bits 7:6 = 01)
; Enable T1 interrupt
; In T1 ISR: update tick counter, handle game state
```

This provides a game clock even when the display is off or running at a different refresh rate.

---

## Common gotchas

1. **Writing XRAM outside vblank** → visible tearing or flickering on sprite-heavy scenes.
2. **VSYNC counter overflow**: `RIA.vsync` is an 8-bit modulo counter — compare with `==` or `!=`, not `<` or `>`.
3. **ISR stack usage**: keep ISRs short; the 6502 hardware stack is only 256 bytes. Avoid deep calls from inside the VSYNC ISR.
4. **Mode switch memory leak**: calling `xreg_vga_mode()` inside the game loop repeatedly can slowly exhaust the VGA Pico's heap — see [[pico-extras]] for the patched fork.

---

## Related pages

- [[vga-display-modes]] — mode register setup, canvas structure, sprite registers
- [[rp6502-vga]] — VGA firmware entity
- [[xram]] — extended RAM used for framebuffers and device state
- [[via-programming]] — VIA T1 timer for frame-rate-independent timing
- [[6502-interrupt-patterns]] — ISR entry/exit protocol for the 6502
- [[rp6502-abi]] — `xreg()` and `set_irq()` OS calls
