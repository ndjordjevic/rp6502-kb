---
type: concept
tags: [rp6502, exec, process, os, api, argv]
related: [[rp6502-os]], [[fatfs]], [[rp6502-abi]], [[examples]]
sources: [[rp6502-os-docs]], [[examples]]
created: 2026-04-18
updated: 2026-04-18
---

# Process Exec API

**Summary**: `ria_execl()` replaces the running process with a new program loaded from the filesystem — analogous to POSIX `execl()`; the current program does not resume after the call.

---

## Basic usage

```c
#include <rp6502.h>

ria_execl(path, arg1, arg2, ..., NULL);   // NULL-terminated argument list
```

`exec.c` example — self-exec with one argument:

```c
int main(int argc, char *argv[])
{
    if (argc == 1) {
        char arg[] = "Foo";
        ria_execl(argv[0], arg, NULL);   // replace self; argv[0] = program path
    }
    if (argc == 2) {
        printf("Success\n");
        return 0;                         // second invocation exits normally
    }
}
```

---

## argc/argv opt-in

Programs must explicitly opt in to receive `argc`/`argv` by defining `argv_mem()`:

```c
// Required to enable argc/argv. Return malloc'd buffer or NULL.
void *__fastcall__ argv_mem(size_t size) { return malloc(size); }
```

If `argv_mem` is not defined, `argc = 0` and `argv = NULL`. This avoids wasting the 512-byte xstack allocation in programs that don't need command-line arguments.

After parsing arguments, the argv buffer can be freed:

```c
free(argv);   // optional — reclaims 512 bytes of heap
```

---

## Argument passing mechanism

Arguments are passed via the XSTACK (≤512 bytes). The OS packs all strings into the xstack before launching the new program. See [[rp6502-abi]] for the XSTACK protocol.

---

## Process model

- `ria_execl()` does not fork — there is only one running program at a time.
- The new program starts at its entry point with its own stack and heap.
- File descriptors are **not** inherited across exec (unlike POSIX). Each program opens its own files.
- `exit()` / `return` from `main()` returns to the OS launcher.

---

## Launcher hook

The OS [[launcher]] provides a persistent host ROM that can watch for child program exit and take action (re-launch, show menu, etc.). See [[launcher]] for the `SET BOOT` command and ROM-based launcher pattern.

---

## term.c — device paths and code page

The `term.c` example shows two more useful patterns:

```c
ria_attr_set(437, RIA_ATTR_CODE_PAGE);   // switch to CP437 (IBM PC OEM characters)
open("AT:", 0);                           // open Hayes modem device (RIA-W)
open("TTY:", 0);                          // raw keyboard (no line editing)
write_xstack(buf, len, fd);              // non-blocking write via xstack
read_xstack(buf, len, fd);               // non-blocking read via xstack
```

Device paths supported by RP6502-OS:
- `NFC:` — NFC reader
- `TTY:` — raw keyboard
- `AT:` — Hayes modem (RIA-W only)
- `ROM:name` — ROM asset
- Regular filenames → FatFS

---

## Related pages

- [[rp6502-os]] — OS API overview
- [[rp6502-abi]] — XSTACK protocol, fastcall convention
- [[launcher]] — process lifecycle and boot hook
- [[fatfs]] — filesystem device paths
