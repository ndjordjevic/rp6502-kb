---
type: source
tags: [rp6502, youtube, audio, psg, sound, pwm, adsr, waveforms]
related: [[programmable-sound-generator]], [[rp6502-ria]], [[development-history]]
sources: [[youtube-playlist]]
created: 2026-04-17
updated: 2026-04-17
---

# yt-ep16 — Programmable Sound Generator Intro

**Summary**: Introduces the PSG added to the RIA firmware: 8 channels, 5 waveforms, variable duty cycle, ADSR envelope; demonstrates using a music tracker; explains the PWM physical layer.

---

## Key topics

- **PSG added via firmware**: no hardware change needed — just flash new RIA firmware.
- **Physical layer**: PWM → RC filter → analog output. Simple RC low-pass filter turns high-frequency square waves into other waveforms.
- **8 channels** (vs SID's 3): allows proper chords instead of arpeggio workarounds.
- **5 waveforms**: sine, square, sawtooth, triangle, noise. All waveforms support variable duty cycle (adds harmonics, variety).
- **ADSR envelope**: attack (build-up time), decay (post-peak drop), sustain (ongoing level), release (tail after note ends). Demonstrated with piano vs. organ vs. hihat vs. bass drum examples.
- **Music tracker**: written to help demonstrate and drive the CPU-side note timing work.
- **Registers**: PSG is in the RIA (`$0:1:00` XREG address, 64-byte config block).
- **Historical note**: Beethoven demo recorded but copyright claimed on YouTube; posted to Patreon (free tier).

## Related pages

- [[programmable-sound-generator]] — full technical reference
- [[rp6502-ria]] — RIA firmware that contains the PSG
- [[development-history]] — Era E: PSG introduction
