---
type: concept
tags: [rp6502, os, process, launcher]
related: [[rp6502-os]], [[rp6502-ria]], [[rom-file-format]]
sources: [[rp6502-os-docs]], [[release-notes]]
created: 2026-04-15
updated: 2026-04-16
---

# Launcher

**Summary**: A mechanism in the RP6502 process manager that lets one ROM act as a persistent "host" for all the others — it gets re-executed automatically whenever the currently running ROM stops.

---

## The mechanism

A ROM registers itself as the launcher by setting `RIA_ATTR_LAUNCHER` to **1**. Once registered:

- When **any** subsequently launched ROM stops, the process manager **re-executes** the launcher ROM.
- When the **launcher ROM itself** stops, the chain ends, the registration is cleared, and control returns to the monitor.

The launcher decides what to run next by calling `ria_execl()` / `ria_execv()`, optionally passing arguments via `argv`. The launched ROM retrieves them via `_argv()`.

## Two stop keys

| Keystroke | Effect |
| --- | --- |
| **Alt-F4** | Stop the running ROM, return to the launcher (or to the monitor if no launcher is registered). Pressing Alt-F4 *while the launcher itself is running* does nothing. |
| **Ctrl-Alt-Del** | Stop the running ROM **and** clear the launcher registration; always returns to the monitor. |

Use Alt-F4 to bounce around inside your launcher framework; use Ctrl-Alt-Del when you need to do system maintenance.

## Why this is useful: a native 6502 OS

The launcher is the foundation for booting a real 6502 OS without sacrificing fault recovery:

1. A small launcher ROM is installed to the RIA as the boot ROM (`set boot launcher.rp6502 args...`).
2. On power-up the process manager loads the launcher first.
3. The launcher reads its own `argv`, finds the OS ROM on a mounted drive, and `ria_execl()`s it.
4. The OS runs as a separate ROM on top of the launcher.

This indirection gives you:

- **Fault recovery** — if the kernel hits a fatal error it can't handle, it `exit()`s and the process manager re-runs the launcher, which can choose to relaunch the kernel or recover differently.
- **Self-update** — an OS can stage its own ROM update, then `exit()`. The launcher detects the pending update, applies it, and boots the new OS ROM. In-place update with no manual reset.

> By design, the OS cannot alter the launcher ROM. Launchers are meant to stay simple and trustworthy.

> **Version history**: launcher mechanism introduced in v0.21; Alt-F4 keystroke formalized in v0.23. See [[release-notes]].

## Related pages

- [[rp6502-os]] · [[rp6502-ria]] · [[rom-file-format]] · [[release-notes]]
