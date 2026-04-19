---
type: concept
tags: [rp6502, os, process, launcher]
related:
  - "[[rp6502-os]]"
  - "[[rp6502-ria]]"
  - "[[rom-file-format]]"
sources:
  - "[[rp6502-os-docs]]"
  - "[[release-notes]]"
  - "[[youtube-playlist]]"
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

## Boot BASIC example (from [[yt-ep17-basics-of-basic]])

> **Source**: [[yt-ep17-basics-of-basic]] (Ep17). A concrete demonstration of the `set boot` launcher pattern.

### Setting BASIC as the boot target

```
install basic.rp6502    ; copy EhBASIC ROM into Pi Pico flash
SET BOOT BASIC          ; configure it as the boot ROM
REBOOT                  ; restart the RIA — now boots into BASIC
```

After this setup, every power-on or reboot drops directly into BASIC — the "instant on" experience of classic 8-bit home computers.

### Reset vs. Reboot in this context

This is where the reboot/reset distinction (see [[reset-model]]) becomes user-visible:

| Action | Effect on BASIC |
|---|---|
| **REBOOT** (or hardware reset button) | Full RIA restart → BASIC reloads from flash, clean slate |
| **RESET** (from monitor `RESET` command) | 6502 reset only → BASIC interpreter **and any loaded program stay in RAM** |

**Practical workflow for disk access from BASIC**:

1. Press Ctrl+Alt+Del from BASIC → returns to monitor (BASIC + program preserved in RAM).
2. Use `LS`, `CD`, etc. to manage files.
3. Type `RESET` at the monitor prompt → BASIC interpreter restarts from `$0800` (or wherever it's mapped), finds its program still in RAM, and continues.

> *"You can stop BASIC at any time, use the monitor to manage disk access, and return to BASIC at any time without losing work."* — [[yt-ep17-basics-of-basic]]

## Related pages

- [[rp6502-os]] · [[rp6502-ria]] · [[rom-file-format]] · [[release-notes]]
- [[reset-model]] — reboot vs. reset detailed
- [[yt-ep17-basics-of-basic]] — BASIC setup walkthrough
