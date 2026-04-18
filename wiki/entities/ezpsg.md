---
type: entity
tags: [rp6502, audio, psg, library, tracker, ezpsg]
related: [[programmable-sound-generator]], [[xram]], [[xreg]]
sources: [[examples]]
created: 2026-04-18
updated: 2026-04-18
---

# ezpsg

**Summary**: A small C library for the RP6502 RIA PSG — provides a music tracker, polyphonic note scheduling, and instrument callback system on top of the 8-channel hardware PSG.

---

## What it is

`ezpsg.h` / `ezpsg.c` in `picocomputer/examples/src/` is a self-contained library. Users include it in their projects alongside `furelise.c` or `poprock.c` for inspiration.

- Manages all 8 PSG channels (free/playing/releasing state machine)
- Tracks per-channel duration and release countdowns
- Drives the hardware via `xreg(0, 1, 0x00, xaddr)` and direct XRAM writes
- No dynamic allocation — channel tracking uses a statically-allocated linked-list

---

## API

### Initialization

```c
ezpsg_init(uint16_t xaddr);
```

- Clears the 64-byte PSG block in XRAM at `xaddr`
- Enables the RIA PSG via `xreg(0, 1, 0x00, xaddr)`
- Initializes the free/playing/releasing channel queues
- Requires **64 bytes** of XRAM

### Per-frame tick

```c
bool ezpsg_tick(uint16_t tempo);
```

- Call 60–100 times per second (tie to `RIA.vsync` or a 6522 timer)
- `tempo+1` ticks = 1 duration unit
- Returns `true` when work was done (twice per duration unit)
- Advances song pointer, releases finished notes

### Play a note

```c
uint16_t ezpsg_play_note(
    uint8_t note,        // enum ezpsg_notes (a0=0 … c8=87)
    uint8_t duration,    // duration units to hold
    uint8_t release,     // release countdown after gate off
    uint8_t duty,        // duty cycle
    uint8_t vol_attack,  // ADSR attack
    uint8_t vol_decay,   // ADSR decay
    uint8_t wave_release,// waveform / release shape
    int8_t pan           // -126 (left) to +126 (right)
);
```

Returns XRAM address of allocated channel, or `0xFFFF` if all 8 channels are busy.

### Songs

```c
void ezpsg_play_song(const uint8_t *song);
bool ezpsg_playing(void);
```

Song data is a byte stream. Positive bytes = duration. Negative bytes = `ezpsg_instruments()` callback. Zero = end of song.

### Instrument callback

```c
void ezpsg_instruments(const uint8_t **data);
```

User-supplied. Called once per beat with a pointer into the song stream. The callback reads instrument/note bytes and calls `ezpsg_play_note()` for each. See `furelise.c` and `poprock.c` for implementations.

---

## Note enum

Full piano range from `a0` (0, 83 Hz) to `c8` (87, ~12558 Hz). Sharps and flats both named:

```c
enum ezpsg_notes { a0=0, as0=1, bb0=1, b0=2, c1=3, ... c8=87 };
```

Frequency table macro `EZPSG_NOTE_FREQS` provides the 88 values in Hz.

---

## Hardware PSG register layout

Each channel occupies 8 bytes at `xaddr + channel * 8`:

| Offset | Field | Description |
|--------|-------|-------------|
| 0–1 | `freq` | Frequency in Hz (uint16, little-endian) |
| 2 | `duty` | Duty cycle |
| 3 | `vol_attack` | Volume + attack |
| 4 | `vol_decay` | Volume + decay |
| 5 | `wave_release` | Waveform type + release |
| 6 | `pan_gate` | Pan [7:1] + gate [0] |
| 7 | (unused) | |

Gate bit: 1 = note active; clearing to 0 starts the release phase.

---

## Related pages

- [[programmable-sound-generator]] — hardware PSG reference (8 channels, 5 waveforms, ADSR)
- [[xram]] — XRAM addressing
- [[xreg]] — `xreg(0, 1, 0x00, xaddr)` call to enable PSG
