---
type: topic
tags: [rp6502, cc65, llvm-mos, toolchain, vscode, cmake, setup, windows, linux]
related: [[cc65]], [[llvm-mos]], [[rom-file-format]], [[rp6502-abi]], [[vscode-cc65]]
sources: [[vscode-cc65]], [[vscode-llvm-mos]]
created: 2026-04-18
updated: 2026-04-18
---

# Toolchain Setup

**Summary**: Step-by-step instructions for setting up the RP6502 development environment on Linux or Windows using cc65 and VSCode; covers tool install, project creation, CMake structure, and the build/flash/run workflow.

---

## Choosing a toolchain

Two compilers are supported:

| | cc65 | [[llvm-mos]] |
|---|---|---|
| Template repo | `picocomputer/vscode-cc65` | `picocomputer/vscode-llvm-mos` |
| Language | C (C89 style) + 6502 assembly | C, C++ |
| Float / double | ❌ | ✅ |
| 64-bit int | ❌ | ✅ |
| `int` width | 16 bits | 16 bits |
| Maturity | High (since 1998) | Medium (newer) |
| Best for | Most projects needing full stdlib | C++, floats, numerical code |

> **Start with cc65** unless you specifically need C++ or floating-point math.

---

## cc65 — Installation

### Linux

1. **VS Code** — download from https://code.visualstudio.com/ (own installer)
2. **cc65** — **must build from source** (package manager versions are years out of date):
   - Follow https://cc65.github.io/getting-started.html
   - Use the **picocomputer fork**: `github.com/picocomputer/cc65` (required until upstream PR #2844 merges)
3. System packages:
   ```bash
   sudo apt install cmake python3 git build-essential
   ```

### macOS

- Follow Linux steps above; `brew install cmake python3 git` instead of apt.
- Use `improve darwin` path in the rp6502.cmake toolchain (handled automatically from commit `a800adc`).

### Windows

```powershell
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Git.Git
winget install -e --id Kitware.CMake
winget install -e --id GnuWin32.Make
```
Add `C:\Program Files (x86)\GnuWin32\bin` to your `PATH`.

- **cc65** — download the current snapshot from https://cc65.github.io/getting-started.html. Add the `bin\` directory to your `PATH` (do not skip this step).
- **Python 3** — type `python3` in a command prompt; Windows will open the Microsoft Store installer if it is not already installed.

> **Do not** use `apt install cc65`, `brew install cc65`, or any package manager version — they are years out of date and lack `rp6502` platform support.

---

## cc65 — Creating a new project

1. Go to https://github.com/picocomputer/vscode-cc65
2. Click **"Use this template"** → **"Create a new repository"**
3. Clone your new repo and open it:
   ```bash
   git clone <your-repo-url>
   cd <repo-name>
   code .
   ```
4. When VS Code prompts, install the recommended extensions.
5. Decide: **C or assembly?** Edit `CMakeLists.txt` to point to `src/main.c` or `src/main.s`, then delete the other.

---

## cc65 — Build and run

- Connect a USB cable to the **RP6502-VGA USB port** (not the RIA port).
- Press **F5** ("Start Debugging") — this builds the project, packages the ROM, uploads it, and resets the Picocomputer to run it.
- A debug terminal opens labeled "Python Debug Console" (the `rp6502.py` tool):
  - `Ctrl-A` then `X` — exit
  - `Ctrl-A` then `B` — send break
- On first run, a `.rp6502` config file is auto-created in the project root (git-ignored). If you get a "device not found" error, edit this file to set the correct serial port.

---

## CMake project structure

```
project(MY-RP6502-PROJECT C ASM)

add_subdirectory(tools)          # imports rp6502_executable() and rp6502_asset()

add_executable(hello)
rp6502_asset(hello help src/help.txt)       # ← must come BEFORE rp6502_executable
rp6502_executable(hello DATA 0x200 RESET 0x200)
target_sources(hello PRIVATE src/main.c)
```

### `rp6502_executable()`

Packages a build target as a `.rp6502` ROM file.

```cmake
rp6502_executable(<name>
                  DATA  <addr>   # load address for program data (required)
                  RESET <addr>   # address written to $FFFC-$FFFD (required)
                  [NMI  <addr>]  # address written to $FFFA-$FFFB
                  [IRQ  <addr>]  # address written to $FFFE-$FFFF
                  [extra_roms…]) # additional pre-built .rp6502 files to merge
```

- `addr` values may be numeric or the keyword `file` (reads address from linker output).
- Must be called **after** all `rp6502_asset()` calls for the same target.

### `rp6502_asset()`

Adds a file to the ROM.

```cmake
rp6502_asset(<name> <addr> <in_file>)
```

- **Numeric `addr`** — file is loaded into 6502 RAM (`$0000–$FFFF`) or XRAM (`$10000–$1FFFF`) at boot.
- **Non-numeric `addr`** (e.g. `help`) — file is accessible via `open("ROM:help", …)` from a micro-filesystem embedded in the ROM.

> ⚠️ `rp6502_asset()` must be registered **before** `rp6502_executable()` for the same target.

---

## Minimal C program

```c
#include <rp6502.h>
#include <stdio.h>

void main()
{
    puts("Hello, world!");
}
```

**C89 constraints** (enforced by cc65):
- No `float`, `double`, or 64-bit integers.
- `int` is 16 bits.
- Declare variables at top of block (C89 style).
- Local stack limit: **256 bytes**.
- `xreg()` settings must be done in a single call.

---

## Minimal assembly program

```asm
.export _init, _exit
.export __STARTUP__ : absolute = 1

.include "rp6502.inc"

.segment "RODATA"
message:  .byte "Hello, world!", $0D, $0A, 0

.segment "CODE"
_init:
    ldx #$FF
    txs
    cld
@loop:
    lda message,x
    beq @done
@wait:
    bit RIA_READY       ; bit 7 = TX ready
    bpl @wait
    sta RIA_TX
    inx
    bne @loop
@done:
_exit:
    lda #RIA_OP_EXIT
    sta RIA_OP
```

The `_init` and `_exit` symbols are the standard entry/exit points. `RIA_READY`, `RIA_TX`, and `RIA_OP` are defined in `rp6502.inc` at the standard register addresses.

---

## rp6502.py tool

Python 3 script in `tools/rp6502.py`. No external dependencies — uses a custom cross-platform serial implementation (POSIX termios + Windows kernel32). Pyserial is **not** required (removed Jan 2026).

```bash
python3 tools/rp6502.py -c .rp6502 run hello.rp6502
```

Supports: serial port auto-detect, run, telnet mode (added Apr 2026), ROM packaging via `create` sub-command.

---

## IntelliSense notes

The `tools/cc65.cmake` toolchain file uses a wrapper shim to route `cl65` through CMake so VS Code problem matchers and IntelliSense work. The shim:
- Strips `-D__fastcall__=` and `-D__cdecl__=` defines (IntelliSense-only placeholders).
- Reformats cc65 error/warning lines to match VS Code's problem matcher regex.
- Auto-detects `__RP6502__` define by querying `cl65`.
- Adds the cc65 system include dir for header resolution.

Do not disable or override this wrapper — it is intentional.

---

---

## llvm-mos — Installation

### Linux

1. **VS Code** — download from https://code.visualstudio.com/
2. **LLVM-MOS SDK** — download from https://llvm-mos.org/wiki/Welcome. See PATH notes below.
3. System packages:
   ```bash
   sudo apt install cmake python3 git build-essential
   ```

### macOS

- Follow Linux steps; `brew install cmake python3 git` instead of apt.

### Windows

```powershell
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Git.Git
winget install -e --id Kitware.CMake
winget install -e --id GnuWin32.Make
```
Add `C:\Program Files (x86)\GnuWin32\bin` to your PATH.

- **LLVM-MOS SDK** — download from https://llvm-mos.org/wiki/Welcome. See PATH notes below.
- **Python 3** — type `python3` in a command prompt; Windows opens the Microsoft Store installer.

### ⚠️ PATH conflict warning

LLVM-MOS must be in PATH, but this **conflicts with any other LLVM installation** (system clang, Homebrew LLVM, etc.). Instead of editing your global PATH, scope it to CMake only by adding `.vscode/settings.json` to your project:

```json
{
    "cmake.environment": {
        "PATH": "~/llvm-mos/bin:${env:PATH}"
    }
}
```

Adjust the path to wherever you installed LLVM-MOS. This file is git-ignored by the template.

---

## llvm-mos — Creating a new project

1. Go to https://github.com/picocomputer/vscode-llvm-mos
2. Click **"Use this template"** → **"Create a new repository"**
3. Clone and open:
   ```bash
   git clone <your-repo-url>
   cd <repo-name>
   code .
   ```
4. When VS Code prompts, install the recommended extensions. When asked for a CMake kit, choose **`[Unspecified]`**.
5. Press **F5** to build, flash, and run. Connect USB to the **RP6502-VGA** port.

---

## llvm-mos — CMake project structure

```cmake
set(LLVM_MOS_PLATFORM rp6502)
find_package(llvm-mos-sdk REQUIRED)    # must come before project()

project(MY-RP6502-PROJECT C CXX ASM)  # note: CXX enabled

add_subdirectory(tools)

add_executable(hello)
rp6502_asset(hello help src/help.txt)
rp6502_executable(hello DATA file RESET file)   # 'file' = read addresses from linker output
target_sources(hello PRIVATE src/main.c)
```

Key differences from cc65:
- `find_package(llvm-mos-sdk REQUIRED)` must precede `project()`.
- `DATA file RESET file` — the `file` keyword reads the load and reset addresses from the linker map (no hard-coded addresses needed).
- `C CXX ASM` — C++ is enabled; you can use `.cpp` sources.
- No separate toolchain cmake file needed — llvm-mos integrates natively with CMake.

The `rp6502_executable()` and `rp6502_asset()` macros are **identical** to the cc65 template. Ordering rule is the same: `rp6502_asset()` before `rp6502_executable()`.

---

## llvm-mos — Minimal C program

```c
#include <rp6502.h>
#include <stdio.h>

int main(void)
{
    puts("Hello from LLVM-MOS");
}
```

**Differences from cc65**:
- Entry point is `int main(void)` (standard C), not `void main()`.
- `float`, `double`, `long long`, and C++ are all available.
- `int` is still 16 bits on the 6502 target.
- No C89 variable-declaration restriction.

---

## cc65 vs. llvm-mos — quick comparison

| | cc65 | llvm-mos |
|---|---|---|
| Template repo | `picocomputer/vscode-cc65` | `picocomputer/vscode-llvm-mos` |
| Languages | C + ASM | C, C++, ASM |
| `int` width | 16 bits | 16 bits |
| Float / double | ❌ | ✅ |
| 64-bit int | ❌ | ✅ |
| C++ | ❌ | ✅ |
| Standard library | Complete | Sparse (growing) |
| Entry point | `void main()` | `int main(void)` |
| Addresses in CMake | Explicit (`0x200`) | From linker (`file`) |
| IntelliSense shim | Yes (`tools/cc65.cmake`) | No |
| PATH gotcha | None | Conflicts with system LLVM |
| Binary size | Smaller | Larger |
| Performance | Good (tuned code) | Better out-of-the-box |
| Best for | Most projects, full stdlib | C++, floats, numerics |

---

## Related pages

- [[cc65]] — cc65 compiler entity: ABI, fork requirement
- [[llvm-mos]] — llvm-mos entity: performance, ABI differences, SDK version lock issue
- [[rom-file-format]] — `.rp6502` format produced by `rp6502_executable()`
- [[rp6502-abi]] — ABI conventions (differ between cc65 and llvm-mos)
- [[vscode-cc65]] — cc65 template source
- [[vscode-llvm-mos]] — llvm-mos template source
