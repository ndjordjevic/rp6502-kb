---
type: topic
tags: [rp6502, history, hardware, development, prototype, dual-pico, pio, dma, ac-chips]
related: [[rp6502-board]], [[rp6502-ria]], [[rp6502-vga]], [[pio-architecture]], [[pix-bus]], [[known-issues]], [[rp6502-os]], [[version-history]], [[youtube-playlist]], [[cc65]], [[llvm-mos]], [[programmable-sound-generator]], [[opl2-fm-synth]], [[code-pages]]
sources: [[youtube-playlist]]
created: 2026-04-17
updated: 2026-04-17
---

# Development History

**Summary**: A chronological narrative of how the RP6502 Picocomputer evolved from a breadboard prototype (late 2022) to the current RP2350/OPL2-FM-capable system (2026), organized by development era.

---

> **Reading note:** This page captures design decisions and technical claims *as they were at the time of each episode*. Where an early claim has since been superseded by current reality, the current state is documented on the primary entity/concept page — only the historical context and motivation live here.

---

## Era A — Prototype (Ep1–Ep4, late 2022 – early 2023)

### The single-Pico concept and pivot to dual-Pico

In the opening episode ([[yt-ep01-8bit-retro-computer]], [Ep1](https://www.youtube.com/watch?v=SVZaSRUhIjo)), the author stated the design goal: a Pi Pico + 6502 + 64 K RAM with **12 glue chips**, providing VGA video, PWM audio, and USB input. A second Pi Pico appeared on the breadboard as a debug probe — described as "never my intention for the final design."

By [[yt-ep02-pio-and-dma]] ([Ep2](https://www.youtube.com/watch?v=GOEI2OpMncY)), the dual-Pico design was formalized. The author decided to "go all in" on two Pi Picos, yielding fewer parts overall, more RAM, lower cost, higher performance, and better video and sound. The debug-probe Pico became the dedicated video Pico. This pivot locked in the architecture that ships today as the [[rp6502-ria]] + [[rp6502-vga]] pair.

The production [[rp6502-board]] (Rev B) uses **8 ICs** total — significantly fewer than the 12 glue chips of the initial breadboard, reflecting ongoing design optimization between Era A and the final reference PCB.

### Breadboard bring-up and the PIO+DMA bus interface

[[yt-ep02-pio-and-dma]] documents the 6502 read path. Key bring-up steps:

- PHI2 clock generated from GPIO; RESB held low for ≥ 2 clock cycles.
- PIO program reads the 5-bit 6502 address bus, constructs a full 32-bit pointer into the 32-byte register space, and passes it to DMA via FIFO.
- **Chained DMA read loop** (8-step cycle): PIO builds address → pushes to FIFO → address DMA reads FIFO → writes result as source pointer into data DMA's control block → data DMA reads register value → pushes to FIFO → PIO reads FIFO → drives data bus. Both ARM cores can halt and the loop keeps running.
- Initial access time was adequate for 1 MHz; 4 MHz required synchronizing the PIO to PHI2 falling edge (empirically tuned 2-cycle delay); 8 MHz required doubling the Pi Pico system clock.

Ep2 explicitly contrasts the PIO approach with bitbanging: "bitbanging uses 100% of a CPU to meet a hard real-time requirement; DMA and PIO use a fraction of those systems and none of the CPU." This is the design insight that makes the RP6502 viable.

[[yt-ep03-writing-to-pico]] added the write path (6502 → RIA), the chip-select decode logic, and the 6522 VIA. The **RIA name was coined** here: "RIA wasn't taken," by analogy with the PIA, CIA, TIA, and VIA.

### AC-chip discovery: the 8 MHz speed barrier

In [[yt-ep03-writing-to-pico]] ([Ep3](https://www.youtube.com/watch?v=wxV6x5BUMH4)), the system failed at 7.7 MHz after the write-side chip-select logic was added. Investigation with an oscilloscope revealed 74HC glue logic gates (~15 ns/gate) created ~60 ns of propagation through a 4-gate-deep path — half a clock cycle at 8 MHz.

Switching two chips from **74HC → 74AC** (same CMOS logic, faster process, ~12 ns/gate) reduced propagation to ~35 ns, enabling stable 8 MHz operation (and 9 MHz in testing).

The author's conclusion: **AC-family chips are required to run at 8 MHz; HC-family chips limit the system to 4 MHz.** The RIA firmware auto-detects available speed and defaults to 4 MHz on HC hardware. See [[known-issues]] for the hardware implication.

### First working demo and the fast-load pattern prototype

[[yt-ep04-picocomputer-hello]] ([Ep4](https://www.youtube.com/watch?v=uL8BL7ZDdlk)) achieved the first Hello World in 6502 assembly and published the schematic ("8-Bit Expeditionary Force"). It also documented the earliest form of what became the [[rp6502-abi]] `RIA_SPIN` stub:

The RIA cannot directly address all 64 K of 6502 RAM (only 5 address lines connect to the Pi Pico). Instead the RIA places a 10-byte **fast-load template** in its register space (`$FFE0–$FFFF`). This template loops writing a single value to a single address. The RIA modifies the value, the address, and the branch instruction in real time — within a < 200 ns window at 8 MHz — to drive each byte of a bulk transfer. Writing one byte requires three CPUs, two PIOs, and DMA in parallel.

This pattern matured into the `RIA_SPIN` stub at `$FFF0–$FFF7`. See [[rp6502-abi]] for the current form and [[ria-registers]] for the register map.

A third PIO program (`ria_action`) was introduced in Ep4 to trigger actions when specific register addresses are accessed. One full ARM Cortex core is dedicated to consuming its FIFO for real-time OS-call dispatch — this is the genesis of [[rp6502-os]].

Notable bring-up quirk: the **first 7 clock cycles after RESB**, the 6502 drives garbage onto the address bus. The fix: ensure the 6502 shuts down in a deterministic location (NOP for alignment; known PC before shutdown).

---

## Era B — Storage and OS emergence (Ep6–Ep7, 2023)

### The dual filesystem decision

[[yt-ep06-roms-filesystem]] ([Ep6](https://www.youtube.com/watch?v=9u82Uy_458E)) documented the reasoning behind using two file systems simultaneously — a decision that has remained unchanged to the present day:

- **[[fatfs|FatFs]]** for removable USB media (drives and SD cards via USB adapter). USB drives and SD cards have built-in wear-leveling controllers, so any filesystem works. FAT is the right choice for maximum compatibility.
- **littlefs** for the Pi Pico's internal flash chip. A "naked" flash chip has no wear-leveling controller; FAT's block allocation would wear it out unevenly over time. littlefs was designed by Arm specifically for bare flash memory.

The divide is physical: if a media controller manages the wear leveling for you, use FAT; if the flash chip is directly exposed, use littlefs. This logic remains load-bearing in the current firmware.

### ROM concept and the install workflow

Ep6 also introduced the **ROM concept**: programs installed to internal flash (via littlefs) that appear in the system help, support per-ROM help text, and can be selected as the boot target. This became the [[rom-file-format]] and [[launcher]] mechanism. The live-upload workflow — build on a connected Linux machine, upload directly to the Picocomputer's USB drive, run with `LOAD` — also dates from this episode.

The author noted that running a genuine 6502 program from a USB flash drive (not an SD card) appeared to be a first.

### The OS that wasn't a goal

[[yt-ep07-operating-system]] ([Ep7](https://www.youtube.com/watch?v=kf-mvyL70bc)) is the retrospective framing episode. The author's summary: **"I never set a goal of making an operating system. Turns out if you want to run POSIX-like software you'll eventually find yourself writing the kernel for a POSIX-like operating system."**

The OS had no name at this point; declaring it an OS was described as "mostly a retrospective declaration." Key design principles articulated:

- **"All I ask for is 32 bytes"** — the RIA's entire footprint in the 6502 address space (`$FFE0–$FFFF`). The last 256 bytes are for I/O; everything else is free user RAM.
- **Protection via isolation** — because all kernel calls go through the RIA register interface, a crashing 6502 program cannot bring down the kernel. No memory manager needed; the hardware boundary is the protection mechanism.
- **OS size vs. visibility** — over 1 MB with networking and code pages linked in, but "completely vanishes" from the 6502's perspective when not called.
- **Kernel built from third-party code** — [[fatfs|FatFs]], littlefs, TinyUSB, and other libraries are the bulk of the OS. "There's other people who have more code in the Picocomputer than me and they probably don't even know."

### Memory model clarified

Ep7 gave the first explicit statement of the two-bank memory model: 64 K of RAM for the 6502 (minus last 256 bytes for I/O), plus another **64 K of VRAM/XRAM** shared between userland, the kernel, video, and audio. The 6502 cannot execute code from XRAM directly, but it can stage graphics, audio, and asset data there — freeing all 64 K of main RAM for program use. See [[xram]].

At this point (Ep7, RP2040 era), the RIA was described as "two Arm Cortex-M0+ processors" — one dedicated to the hot RIA loop (no interrupt tolerance), one running the kernel. The architecture is unchanged; the silicon upgraded from RP2040 to RP2350 at v0.10 (see [[version-history]] and Era E).

### State of the system at Era B

At the end of Ep7, the [[pix-bus]] was not yet working; VGA was limited to ANSI terminal emulation. The demo milestone — Colossal Cave Adventure running unmodified from a USB drive — validated the POSIX filesystem API.

---

## Era C — Graphics and PIX bus (Ep8, Ep12, Ep13, 2023–2024)

### "I ran out of GPIO pins" — the driver for PIX bus design

[[yt-ep08-vga-pix-bus]] (Ep8) opens with a stark constraint: there are not enough GPIO pins to run both VGA output and the 6502 bus from a single Pi Pico. The Doom-on-Pico demo exists, but it doesn't talk to a real 6502. Two Picos were required, and that meant a custom inter-Pico link.

The author first considered SPI but rejected it: multiple video cards require a chip select GPIO each (already scarce), and running 50–100 MHz signals off-board to multiple devices requires impedance engineering. The design goal was to match or stay below the electrical speed of the 6502 bus.

### The DDR insight

Working through the problem: a 6502 `STA abs` takes 4 PHI2 cycles — the bandwidth ceiling. One byte + a 16-bit address = 24 bits. Six parallel wires × 4 cycles = 24 bits — almost enough, but framing and multi-device addressing needed a 7th wire. The author didn't have 7 free GPIOs; he had 4.

> *"I got hung up on this for a bit then I realized using both transitions of the clock doesn't change the electrical requirements. I'm not sure why this needed a second thought. It was some kind of brain fart. Like forgetting your sunglasses are tipped up on your head."*

DDR (Double Data Rate) — shifting on both PHI2 edges — doubles the bandwidth without changing the electrical speed. 4 wires × 2 edges × 4 cycles = 32 bits per 4 cycles. The PIX bus was born.

### PIO resource cost

Building the protocol inside the PIO state machine system:
- Transmitter (`pix_tx`): 5 PIO instructions — concise.
- Receiver (frame sync + channel filter + shift-in): 14 PIO instructions.
- Full VGA Pico PIX receiver consumes all 32 instructions and all 4 state machines of one complete PIO block.

Both PIO blocks on the VGA Pico are fully utilized.

### DMA priority debugging

After the PIX bus was running, about 1 in 1,000 writes produced display corruption. The culprit was VGA DMA competing with PIX DMA for bus access at the 500 ns PHI2 window. The fix required establishing a priority hierarchy:

**PIX DMA priority > VGA DMA priority > CPU**

This is standard practice in real-time microcontroller systems. The hardware provides these priority controls precisely because multiple DMA channels with different deadlines coexist.

### VSYNC backchannel (v0.1 / Ep12)

[[yt-ep12-fonts-vsync]] (Ep12) addressed the next graphics requirement: vertical sync. Graphics applications need VSYNC to update moving content between frames (to avoid tearing). But no GPIO pins remained for a VSYNC wire.

The solution: move UART TX data to the PIX bus, then reverse the UART TX pin direction. The VGA Pico uses the reversed pin as a **backchannel** to send VSYNC ticks (~60 Hz) and version info back to the RIA. A "phantom UART" (not connected to any physical GPIO) handles flow control for the high-speed PIX side.

This complexity is entirely hidden from 6502 programmers — they just read the `vsync` register (increments 60× per second at the start of the VBI). The author noted: *"You can forget about it. I'll always be scarred from a week of work on a state machine that increments a counter."*

### v0.1 release milestone

Ep12 also marks the first formal versioned release. The trigger: "more than a dozen working devices out there and people are starting to explore writing software." The v0.1 release included fonts (code pages CP850/CP437/CP855), VSYNC, and SDK documentation improvements.

See [[code-pages]] for the code page / FAT short-name interaction documented in Ep12.

### Graphics programming (Ep13)

[[yt-ep13-graphics-programming]] (Ep13) is the first hands-on tutorial for the graphics system now that PIX and VSYNC were working:

- **Canvas selection** via `xreg(1, 0, 0, canvas_id)` — canvas 2 = 320×180 for 16:9 displays.
- **Bitmap mode**: `MODE=3`, `OPTIONS` for bit depth, `CONFIG` = XRAM address of a config structure.
- **Config structure** fields: width, height, x (scroll), y (scroll), data pointer (XRAM), palette pointer (`$FFFF` = built-in ANSI).
- **Planes**: 3 planes drawn front-to-back. Alpha bit enables see-through to lower planes. Used for bitmap + console overlay and parallax layers.
- **Scanline partitioning**: `PLANE`, `BEGIN`, `END` registers split the screen between modes at any scanline boundary.
- **VSYNC-synced scrolling**: change `config.x` and `config.y` inside the ~500 µs VBI window for smooth, tear-free animation.
- **Tiling**: repeat the canvas image in X and/or Y.
- **ANSI terminal upgrade**: mode 0 (console) upgraded to 16-bit color (256-color ANSI palette).

Community response was immediate: parallax scrolling demos appeared in the forums less than a week after Ep13.

---

## Era D — Productization (Ep9–Ep11, Ep15, 2024)

### CC65 SDK and VSCode template

[[yt-ep09-c-programming-setup]] (Ep9) formalized the developer onboarding path:
- **[[cc65]]** chosen as the primary toolchain (C compiler + assembler + linker targeting 6502).
- **VSCode template project** on GitHub: stamp out a new repo from the template, init SDK submodule, open in VSCode.
- **Ctrl+Shift+B**: single keystroke builds, packages as `.rp6502` ROM, uploads over USB, runs on Picocomputer.
- **`rp6502.py`**: Python script underlying all VSCode automation; also usable directly for ROM packaging and upload.
- Standard POSIX C code ("boring is good") — `fopen`/`fread`/`fwrite` work unchanged over the FAT USB drive.

This was the first complete developer workflow, establishing the pattern that all subsequent toolchain work builds on.

### PCBWay manufacturing milestone (Ep10/Ep11)

The author's hardware design philosophy was validated in Ep10–11:

- **Ep10** ([[yt-ep10-diy-build]]): complete through-hole soldering walkthrough. Mouser BOM; ~$59.51 for parts at time of recording. **"Founders Edition"** boards were a surprise for Patreon supporters.
- **Ep11** ([[yt-ep11-no-soldering]]): PCBWay sponsorship demonstrated single-unit contract assembly for $30 (2 units = $15 each). First time a single-unit Picocomputer was manufactured by a factory.

The key demonstration: if you design for manufacturing, sending the design to a factory should be straightforward. The author had done the design work; viewers just needed to send files.

> *"I've done all the work so anyone can make this anywhere in the world."*

The progression: breadboard (Era A, Ep1–4) → viewer breadboard builds (Era B, viewer photos) → Founders Edition PCBs (Era D, Ep10) → PCBWay single-unit production (Ep11).

### AC-chip hardware requirement (from Ep10)

Ep10 confirms the 8 MHz barrier: *"The Pi Pico defaults to running the 6502 at four megahertz. If you bought the correct parts, it'll run at eight megahertz."* "Correct parts" = AC-family logic chips in the address decode path (established in Era A, Era C's prototype builds validated this in production PCBs). See [[known-issues]].

### Asset management CMake workflow (Ep15)

[[yt-ep15-asset-management]] (Ep15) completed the graphics system (all modes working: characters, tiles, sprites) and introduced the CMake-based asset packaging workflow:

- `rp6502_asset(target, address, file)` — packages a binary file as a ROM chunk. Address `0x10000+` = extended RAM (for graphics/audio data accessible to the VGA system).
- `rp6502_executable()` — links code + all asset ROMs into a single `.rp6502` file.
- Assets land in the correct memory location at boot — no `memcpy` needed in the 6502 program.
- Help text: first line `#!RP6502`, subsequent lines `# text` — the ROM format directly; link into `rp6502_executable()` without a packaging step.
- `rp6502.py upload` — upload any file to the Picocomputer over USB without unplugging.

Sprites now support **affine transforms** (scale, rotation, translation, occlusion) — 24 sprites at 128×128 px, more with smaller sizes.

---

## Era E — RP2350 and network era (Ep17, Ep18, Ep20–22, 2025–2026)

### Pi Pico 1 → Pi Pico 2 migration (v0.10, Apr 2025)

[[yt-ep20-bbs]] (Ep20) announced the hardware upgrade path: swap both Pi Picos for Pi Pico 2. The VGA slot takes a plain Pico 2; the RIA slot takes a **Pico 2 W** (with WiFi radio). This mapped to v0.10 in the release timeline — a hard hardware break (no Pico 1 support in v0.10+).

The RP2350 (Cortex-M33 at 256 MHz overclocked) was required to handle 8 MHz PHI2 + USB + audio + WiFi simultaneously. The Cortex-M0+ in the RP2040 had already been running at its headroom limit.

### BBS/Telnet demo (WiFi + Hayes modem)

WiFi radio in the Pico 2 W enabled internet connectivity from a 6502. Ep20 demonstrated connecting to **BBS (Bulletin Board Systems)** — interactive ANSI-color ASCII art terminals. ANSI escape sequences and CP437 fonts were already in the Picocomputer stack, making it a natural BBS terminal.

Additional internet features:
- **NTP**: fetch current time and handle DST adjustments automatically.
- **Hayes modem `ATD` command**: dial a BBS by hostname/IP, same interface as 1980s/90s modem usage.

Note: Telnet protocol (RFC 854 negotiation) was not yet implemented as of v0.12 — raw TCP only. See [[known-issues]].

### BASIC interpreter (Ep17)

[[yt-ep17-basics-of-basic]] (Ep17) introduced **Lee Davison's Enhanced BASIC (EhBASIC)** as an installable ROM:
- Free and open source (unlike Microsoft BASIC or BBC BASIC).
- Install: copy `basic.rp6502` to USB → `install basic.rp6502` → `SET BOOT BASIC`.
- On next reboot, the Picocomputer drops directly into BASIC — "instant on" like classic home computers.

**Critical reboot vs. reset distinction** (user-facing, documented in Ep17):
- **Reboot** = full Pi Pico RIA restart; reloads boot ROM from flash.
- **Reset** = 6502 reset only; BASIC interpreter and program remain in RAM.

This lets users exit to the monitor (via Ctrl+Alt+Del), manage files, then `RESET` back into BASIC without losing their program. See [[reset-model]] for the detailed model.

EhBASIC limitation: doesn't know about disk drives (heritage from punched-tape era). The `RESET` workaround covers this gap until a future disk-aware BASIC update.

**`RND(1)` vs `RND(0)` quirk**: In EhBASIC, `RND(1)` sets the random seed (doesn't return a random number) while `RND(0)` returns one — the reverse of Microsoft BASIC. Classic BASIC listings need this one-line fix. See [[known-issues]].

### Toolchain split: cc65 vs. llvm-mos (Ep18)

[[yt-ep18-llvm-mos]] (Ep18) formalized the two-toolchain story. Both [[cc65]] and [[llvm-mos]] have official Picocomputer support:
- **[[cc65]]** (since 1998): stable, complete stdlib, 6502-idiomatic — best for most projects.
- **[[llvm-mos]]**: stronger optimization, C++/floats/64-bit — future-preferred once stdlib matures.
- Mandelbrot benchmark showed LLVM-MOS delivering significantly better performance from the same portable C source without extra optimization effort.

### PSG audio (v0.6, ~2024)

The **Programmable Sound Generator** (PSG) was added to the RIA firmware in v0.6 — no hardware change, just flash new firmware. 8 channels, 5 waveforms (sine, square, sawtooth, triangle, noise), variable duty cycle, ADSR envelope, stereo pan, PWM physical layer. See [[programmable-sound-generator]].

### OPL2 FM synthesis (v0.16, Dec 2025)

The **OPL2 FM synthesizer** was added to the RIA firmware in v0.16, after a community member demonstrated an FPGA OPL2 experiment connected to the PIX bus and mentioned writing a music tracker.

> *"He mentioned something about writing a tracker, which got me thinking."* — The FPGA requirement meant almost nobody would use the tracker. Adding OPL2 natively (firmware only) removed that barrier.

The author had tried FM synthesis when the system used the Pi Pico 1: "multiple things were in the way." The Pi Pico 2 unblocked the technical constraints; the FPGA experiment unblocked the motivation.

OPL2 = Yamaha YM3812-compatible (AdLib / Sound Blaster 8-bit era). Firmware-emulated via `emu8950`. No hardware change required — just flash new UF2. Coexists with PSG. See [[opl2-fm-synth]].

A community music tracker with both PSG and OPL2 support was released, featuring: arpeggio, portamento, vibrato, echo, tremolo, microtonal folds (20-page documentation).

### Community software flowering (Ep22)

[[yt-ep22-graphics-sound-demos]] (Ep22) showcased the maturation of the platform through community software:

| Demo | Notable feature |
|---|---|
| Tetris | Baseline — runs on a potato |
| Star Swarms | Sprites with affine transforms (rotate, scale, translate, occlude) |
| Game of Life | 640×480 monochrome bitmap |
| Sliding blocks | Custom puzzle definitions from data files |
| Darts | Novel controls; "surprisingly fun" |
| 3D Falling Blocks | 3D variant of Tetris |
| Raycast engine | Wolfenstein-style; "8-bit adder doing all the math" |
| Space Invaders | Best 6502 port seen; first game with sound |
| Asteroids | Vector display emulation using fast line drawing |
| Sega Genesis port | Start of the OPL2 FM story |

---

## Related pages

- [[version-history]] — parallel release-based history
- [[pio-architecture]] — the PIO+DMA bus interface that Era A designed
- [[rp6502-abi]] — `RIA_SPIN` stub: current form of the Era A fast-load pattern
- [[ria-registers]] — register map including the fast-load stub at `$FFF0–$FFF7`
- [[known-issues]] — AC chips required for 8 MHz
- [[rp6502-board]] — the production PCB that emerged from Era D
- [[youtube-playlist]] — all 22 episode source pages
