---
type: concept
tags: [rp6502, reset, control]
related: [[rp6502-ria]], [[w65c02s]], [[rp6502-board]]
sources: [[rp6502-ria-docs]]
created: 2026-04-15
updated: 2026-04-15
---

# Reset Model

**Summary**: On the RP6502 there is no "press reset" — RESB is a **state**, not a pulse, and only [[rp6502-ria]] is allowed to drive it. Get this wrong and you'll fight the firmware.

---

## RESB has two states

| RESB | What it means |
| --- | --- |
| **Low** | 6502 stopped. Console = the RP6502 monitor (UEFI-like shell). |
| **High** | 6502 running. Console = stdio in [[rp6502-os]] and the RIA UART TX/RX registers. |

Driving RESB high → low always returns control to the monitor. Driving low → high either runs a `load`'d ROM's reset vector, or just runs whatever your RAM is set up to do (use the monitor `reset` command).

## How to actually reset

### Low → high (start the 6502)

- `load /something.rp6502` then it runs automatically.
- `reset` from the monitor if you've prepared RAM another way.

### High → low (return to the monitor)

Two options, both work even with a hung or crashed 6502:

1. **CTRL-ALT-DEL** on a USB or BT keyboard.
2. **Send a break** on the RIA UART.

## Reboot vs. reset

A **reboot** is different — it's a reset of the **RIA** itself via the **RIA RUN pin**, *not* a reset of the 6502 via RESB. Rebooting the RIA reloads any configured boot ROM, just like power-on. The reference [[rp6502-board]] has its `SW1` reset button wired to the RIA RUN pin, so when you press the on-board "reset" you are rebooting the RIA, not toggling RESB.

## Caution from the docs

> "Do not hook up a physical button to RESB. The RIA must remain in control of RESB. What you probably want is the reset that happens from the RIA RUN pin."

## Interaction with the launcher

The two stop keys (Ctrl-Alt-Del and Alt-F4) have different effects on the [[launcher]] registration:
- **Alt-F4** — stops the running ROM and returns to the launcher (if one is registered), or to the monitor if none.
- **Ctrl-Alt-Del** — stops the running ROM **and clears** the launcher registration; always returns to the monitor.

See [[launcher]] for the full pattern.

## Related pages

- [[rp6502-ria]] · [[w65c02s]] · [[rp6502-board]] · [[launcher]]
