---
type: concept
tags: [rp6502, audio, psg, sound, pwm, adsr, waveforms]
related: [[rp6502-ria]], [[opl2-fm-synth]], [[xreg]], [[xram]]
sources: [[yt-ep16-psg-intro]], [[yt-ep22-graphics-sound-demos]], [[release-notes]]
created: 2026-04-17
updated: 2026-04-17
---

# Programmable Sound Generator (PSG)

**Summary**: The PSG is an 8-channel software synthesizer built into the [[rp6502-ria]] firmware, offering 5 waveforms with variable duty cycle and ADSR envelopes — first available in v0.6.

---

## Overview

The PSG runs entirely inside the RP2350 on the RIA — no external audio hardware required. It produces analog audio via PWM → RC low-pass filter → audio jack. All sound parameters are controlled by writing to a 64-byte register block in [[xram]] via the [[xreg]] mechanism.

> **History note**: The PSG was introduced in **v0.6** (Feb 2024). It requires only a firmware update to existing hardware. See [[version-history]] Era 2.

## Channels

- **8 independent channels** (oscillators). Each channel has its own waveform, frequency, duty cycle, ADSR envelope, and stereo pan.
- Compare: the classic SID chip (Commodore 64) had 3 channels. 8 channels allow proper chords without the arpeggio workarounds common on 3-channel systems.

## Waveforms

| # | Waveform | Notes |
|---|---|---|
| 0 | Sine | Smooth, fundamental |
| 1 | Square | Classic 8-bit tone; duty cycle controls harmonic content |
| 2 | Sawtooth | Rich harmonics; good for brass/strings simulation |
| 3 | Triangle | Softer than square; duty cycle creates hybrid triangle/square |
| 4 | Noise | Adjustable frequency + duty cycle for percussion and effects |

**Variable duty cycle**: applies to all 5 waveforms (not just square). Adjusting duty cycle changes the harmonic balance and gives additional timbral variety.

## ADSR Envelope

Each channel has a 4-stage amplitude envelope:

| Stage | Meaning | Example instruments |
|---|---|---|
| **Attack** | Time to reach peak volume | Slow = organ; fast = percussion |
| **Decay** | Drop from peak to sustain level | Piano has fast decay |
| **Sustain** | Ongoing volume while note is held | Organ = full sustain; piano = decays to 0 |
| **Release** | Tail after note off | Bell-like = long release; sax = abrupt |

## Stereo pan

Each channel has an independent stereo pan setting, allowing positioning of instruments in the stereo field.

## Physical layer

Audio output uses **PWM** (Pulse Width Modulation):
- Numeric value → time period → analog voltage via RC filter.
- Upgraded to **10-bit DAC** resolution in v0.17 (from original 8-bit).
- Cost-effective: no external DAC chip required.

## Register map

| XREG address | Content |
|---|---|
| `$0:1:00` | PSG config block start address in XRAM |

The PSG config block is **64 bytes** (8 channels × 8 bytes each). Each 8-byte channel block holds frequency, waveform, duty cycle, ADSR parameters, and pan. Set the XRAM block address via `$0:1:00` xreg; writing `0xFFFF` disables the PSG.

## Coexistence with OPL2

The PSG and [[opl2-fm-synth]] are both available simultaneously in the RIA firmware. They use separate register blocks and can be used together in the same program.

## Community usage

A community member wrote a full music tracker for the Picocomputer that uses both the PSG and OPL2. The tracker supports arpeggio, portamento, vibrato, echo, tremolo, and microtonal folds. See [[yt-ep22-graphics-sound-demos]].

## ezpsg — high-level library

The [[ezpsg]] entity page documents `ezpsg.h`/`ezpsg.c` from `picocomputer/examples` — a self-contained tracker and polyphonic scheduler on top of the PSG hardware:

- `ezpsg_init(xaddr)` — clears XRAM block and calls `xreg(0, 1, 0x00, xaddr)` to start the PSG
- `ezpsg_tick(tempo)` — call 60 Hz per frame; advances song, handles note durations/releases
- `ezpsg_play_note(note, duration, release, duty, vol_attack, vol_decay, wave_release, pan)` — allocates a free channel
- `ezpsg_play_song(song*)` — starts a byte-stream song; `ezpsg_instruments()` callback defines instruments
- Note range: `a0` (83 Hz) to `c8` (~12558 Hz) — full piano range (88 notes)

## Related pages

- [[rp6502-ria]] — firmware that contains the PSG
- [[opl2-fm-synth]] — the FM synthesizer that coexists with the PSG
- [[xreg]] — how to set the PSG register block address
- [[xram]] — where the 64-byte PSG config block lives
- [[ezpsg]] — the ezpsg high-level library
