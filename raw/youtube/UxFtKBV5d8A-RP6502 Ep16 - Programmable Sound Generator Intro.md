---
type: source
source_kind: youtube
video_id: UxFtKBV5d8A
title: RP6502 Ep16 - Programmable Sound Generator Intro
url: https://www.youtube.com/watch?v=UxFtKBV5d8A
captions_file: UxFtKBV5d8A-RP6502 Ep16 - Programmable Sound Generator Intro.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep16 - Programmable Sound Generator Intro

**Source**: [https://www.youtube.com/watch?v=UxFtKBV5d8A](https://www.youtube.com/watch?v=UxFtKBV5d8A)
**Video ID**: `UxFtKBV5d8A`

---

In this video we'll make some noise.

I put a programmable sound generator in the Picocomputer so now it can make sound effects and play music.

If you already have a Picocomputer, all you need to do is load the new firmware to get the new audio features.

Let's begin with a quick refresher about how we produce analog signals from a digital device.

The most common method for doing this is directly with a digital to analog converter chip.

This technique is often called pulse code modulation.

PCM is great.

It lets us turn a numeric value directly into in analog voltage.

But we don't have PCM Hardware on the Picocomputer.

The second most common method is pulse width modulation or PWM.

With this technique we turn a numeric value into a time period which can then be turned into a voltage.

This is what the Picocomputer does so I'll go into a bit more detail.

Let's say we're looking to make a sine wave.

We need the voltage to gradually move up and down over time.

With PCM, the numbers we send to the digital to analog converter are directly proportional to the output voltage.

We raise and lower the number to raise and lower the voltage.

PCM is nice and easy if you have it, but like I said, we don't have PCM.

We have PWM.

All we can do do is turn a digital signal on and off with different timings.

In other words, square waves not sine waves.

Some of you engineers will remember that a square wave is the sum of a series of sine waves.

That means we can apply filters or use other techniques to turn these square waves into something else.

The Picocomputer uses a simple filter to turn high frequency square waves into an analog signal.

And now you know why PWM is sometimes used - price.

There's other use cases which aren't price, but the Picocomputer is using PWM to manage cost and complexity.

Now this physical layer is just an implementation detail.

Knowing this detail is only important if you're working on the hardware, such as when troubleshooting.

A good PWM implementation should have no effect on the sounds you can make, so let's move on.

What a musician or programmer is interested in is the parameters for making sounds.

Things like the frequency of a musical note and its duration.

This workload is split between the sound generator and the CPU.

For example, the sound generator will produce the musical note while the CPU controls its duration.

To help you get started and to help me make these videos, I wrote a music tracker to handle the work the CPU needs to do.

But before we start having fun in the tracker, Let's look at the documentation for the programmable sound generator.

The PSG is part of the RIA so that's where our documentation is.

Let's check out the bullet points.

It says we have eight channels.

The venerable SID has three channels, which leads to a lot of songs with arpeggio.

The extra channels we have should let us do proper chords instead.

There are five basic waveforms.

Let's try them.

If we scroll down a bit we can see the register which controls the waveform.

I can use this information to set up the tracker to play a sine wave.

You can see the sine wave on the oscilloscope.

The trigger on my scope is broken but I think it conveys the information well enough.

Let's try a square wave next.

I'll set the duty cycle to 50% so we'll see some classic square waves. [Music] Yes, we're making square waves from square waves here so let's move on to the sawtooth. [Music] That's not quite what I was expecting.

I forgot to change the duty cycle back to 100%. [Music] There we go.

That's a sawtooth.

All the waveforms, not just the square waves, can have a duty cycle.

This adds some harmonics and gives us some variety.

Let's move on to a triangle waveform with a 50% duty cycle. [Music] You can see the top of the waveform is a triangle and the bottom of the waveform is a square wave.

The final waveform is noise.

You can get some pretty funky sounds by adjusting the frequency and duty cycle of noise. [Music] That's all the wave forms.

The next thing on the list of bullet points is ADSR.

Attack, Decay, Sustain, Release.

In the physical world, volume changes are rarely instant.

For example, when blowing a note on a trumpet there's a small delay at the start of the note while the instrument builds up a standing wave.

We call this the attack.

Instruments that are struck have fast attacks while wind instruments tend to have slow attacks.

Let's listen to some fast and slow attacks.

I'll add a second instrument to the tracker so you can hear the difference. [Music] The decay is what happens after the attack.

Some instruments, like a piano, will slowly lose volume after the note is played.

Other instruments, like an organ, won't decay but instead sustain the note indefinitely.

Here I combined the attack, decay and sustain so we can hear the difference between a piano and an organ.

The release happens after the sustain.

Some instruments stop playing immediately, like a saxophone.

While others ring like a bell... like a bell.

We call call this group of attack, decay, sustain and release the ADSR envelope.

Combining a waveform with an envelope is how we can simulate different instruments.

We just heard a piano and an organ.

Here's some parameters that could be used for a drum hihat. [Music] And here's some parameters for a funky bass drum.

The best way to learn how to make new sounds is practice.

Teach your ear what changing each parameter does then listen to real instruments to find the same parameters.

You'll be making synthetic instruments in no time.

I want to play you a song now.

I want to but I can't.

I programmed up some Beethoven but someone else is claiming copyright to my performance.

This doesn't seem to be a problem on Patreon so I posted the full song there on the free tier.

There's a link in the description.

Thanks for watching and I hope you enjoy the song.
