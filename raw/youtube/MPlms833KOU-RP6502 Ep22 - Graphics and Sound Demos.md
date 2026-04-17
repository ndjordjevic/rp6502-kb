---
type: source
source_kind: youtube
video_id: MPlms833KOU
title: RP6502 Ep22 - Graphics and Sound Demos
url: https://www.youtube.com/watch?v=MPlms833KOU
captions_file: MPlms833KOU-RP6502 Ep22 - Graphics and Sound Demos.en.vtt
retrieved: 2026-04-17
---

# RP6502 Ep22 - Graphics and Sound Demos

**Source**: [https://www.youtube.com/watch?v=MPlms833KOU](https://www.youtube.com/watch?v=MPlms833KOU)
**Video ID**: `MPlms833KOU`

---

First, a couple of announcements and then some demos.

The Vintage Computer Festival is returning to the Pacific Northwest for 2026.

Registration is open and my exhibitor table has been confirmed.

So, if you can get to the Seattle area on May 2nd and 3rd, stop by for some anacronistic computing.

The other announcement is a new feature for the Pico Computer 6502.

You may have noticed a music tracker in the thumbnail.

I'll show that in the demos.

To support the new tracker, I added an OPL2 FM synthesizer to the RIA.

All you have to do is flash new firmware.

This is the same FM synthesizer used in the 8-bit AdLib and Sound Blaster cards.

All right, now on to the demos.

None of this software was written by me.

I want to tell a story of how the platform and developers have advanced over the past few years.

So, if you made something cool that I didn't include here, it's only because it doesn't fit the narrative for this particular video.

Let's begin the story with a Falling Blocks game.

The video system was completed before the audio system was started, so we'll be showing the silent apps first.

Tetris will run on a potato, which makes it good for getting your bearings, but it won't push the hardware.

Here we have star swarms.

The rotating enemies are sprites with a fine transforms that allow for rotation, scaling, translation, and occlusion.

It was uncommon to use linear algebra on 8-bit computers, but that's all we use in modern game development.

The game of life is built on a 640x480 monochrome bit map.

The monochrome graphics give me Macintosh vibes.

This is the first collaboration between two Pico computer users.

Here we have a sliding blocks puzzle.

Pretty boring, right?

Well, look at this one with all the irregular shapes and this other one with a picture.

Not so easy now, huh?

The puzzles are defined in data files, so you can make your own, too.

I used to play darts back in the 90s.

I still have the set of bottles and hammerheads.

The controls on this game are something you have to try.

If I describe them, it'll sound silly and simple, but they are surprisingly fun.

Here's another Falling Blocks game, but in three dimensions.

The original came out after the world had moved on to 16 and 32 bits, but the Commodore 64 got a version, and now we have one, too.

This is a Raycast demo.

It's the same technology used to make Wolfenstein 3D.

Keep in mind, all the math on a 6502 is done with an 8-bit adder.

Imagine a dungeon crawler that looked like this.

So much potential.

This is the first game with sound.

This is also the best port of Space Invaders I've seen on any 8-bit platform.

This Asteroids game is emulating a vector display.

Traditional 8-bit ports of this game would use sprites, but a really fast processor puts line drawing into reach.

This is a port of a Sega Genesis game or Mega Drive in other parts of the world.

It's also the start of the FM story.

This game, the next two games, and the music tracker were all written by one person.

What you're hearing is the programmable sound generator, not the FM synth.

Again, another game with the programmable sound generator.

But it was around this time that the author strapped on an FPGA to the Pix Bus so he could experiment with OPL2 sound.

And he mentioned something about writing a tracker, which got me thinking.

Before we look at the tracker, here's the first game that uses the OPL2 FM synthesizer.

What you're hearing is coming from the RIA, not the FPGA project.

I tried to get FM working back when the system used the PI Pico 1, but there were multiple things in the way.

The Pico2 unblocked everything except my motivation.

And this is what unblocked my motivation.

If folks needed to add FPGA hardware, then almost nobody would use this tracker.

Now, everybody can use it.

The documentation is 20 pages long, and I'm not qualified to teach music.

So here's a few of the special effects built into the tracker.

Arpeggio, portimento, vibrto, echo, termolo, and even pitch adjustments for the microonal folds.

That's all I want to show for this video.

Thanks for watching, and thank you to the community who write software for this platform.

Like and subscribe.
