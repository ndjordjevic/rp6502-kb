---
type: source
source_kind: youtube
video_id: Y3_pkzlLjtk
title: RP6502 Ep17 - The basics of BASIC
url: https://www.youtube.com/watch?v=Y3_pkzlLjtk
captions_file: Y3_pkzlLjtk-RP6502 Ep17 - The basics of BASIC.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep17 - The basics of BASIC

**Source**: [https://www.youtube.com/watch?v=Y3_pkzlLjtk](https://www.youtube.com/watch?v=Y3_pkzlLjtk)
**Video ID**: `Y3_pkzlLjtk`

---

In this video, we'll get nostalgic with BASIC.

For people of a certain age, BASIC will have been the first programming language you learned.

Even if all you did was play games on an 8-bit machine, you probably typed a BASIC command to load the games.

That's because the first home computers all had one thing in common.

They turned on and immediately dropped you into BASIC.

And it wasn't after an operating system booted, a login, some patch notes, checking your emails, and so on.

No, you were dropped into BASIC as fast as you could move your hand away from the power switch.

It was a simpler time when you could be instantly transported to a new frontier without distractions.

A time when computers were creative tools instead of marketing machines competing for your attention.

One of the goals for the Picocomputer is this instant on experience.

By default, the Picocomputer boots to the monitor.

I wanted this default configuration to feel like an Altair or Apple 1.

The idea is that you to add ROMs later and have the Picocomputer boot into a different type of machine.

For example, it could boot a game as if you had a cartridge plugged in.

Or it could boot directly to BASIC, which we're going to set up now.

Let's begin by grabbing the BASIC ROM from GitHub.

The BASIC we're using is Lee Davison's enhanced BASIC.

There are other BASICs, most notably Microsoft BASIC and BBC BASIC, but these are not free and open source.

The releases section has a downloadable binary.

The file we need is called basic.rp6502.

If it's zipped or otherwise packaged, you'll need to unzip it before using it.

Put that file on a USB drive and plug it into the Picocomputer.

Now on the Picocomputer monitor we can LS and see the file.

We can load the file with the LOAD command.

It works.

So now we know it's okay to proceed with the rest of the setup.

I'll press control alt delete to return to the monitor.

Back at the monitor, we can install the BASIC ROM on the Picocomputer hardware.

Type install basic.rp6502.

Now, when I type HELP, you can see at the bottom it says there's an installed ROM called BASIC.

You can remove the USB drive if you want.

The installed BASIC ROM is now part of the Pi Pico.

It's even integrated into the help system.

Typing HELP BASIC gives us a little bit of info and has links to the documentation.

Now let's reboot the Picocomputer.

There's a reboot button on the hardware you can use.

I'll be using the reboot command which does exactly the same thing.

Note that this isn't a reset of the 6502.

A reboot has the same effect as a power cycle causing the Pi Pico RIA to reboot.

But a reset resets only the 6502.

This distinction will become important in a bit.

Okay.

We have our boot message about the Picocomputer versions.

Here I can type BASIC to immediately get into BASIC even without a USB drive.

We're closer, but not quite.

I'll press control alt delete to get back to the monitor.

Now let's look at the settings.

The boot setting is how we select a ROM to load at boot.

Let's SET BOOT BASIC and reboot.

Now this is what I want.

Every time the Picocomputer boots, it'll go right into BASIC.

This is fantastic.

It's just like the Commodore computers I grew up with.

Except it's open source and uses modern peripherals.

Let's type in an obligatory BASIC program real quick.

Let's look at some more BASIC programs.

These three books of BASIC games were a prized possession of my teenage self.

The first one was the first book about computers to sell a million copies.

We can run most of these games now and thanks to the internet we don't have to type them in.

I downloaded some and put them on a USB drive.

Let's load one and run it.

We can use the load command in BASIC to do this.

Make sure you do this from BASIC and not the monitor and don't forget that BASIC needs quotes while the monitor does not.

Then the RUN command to run it.

This program makes a 3D plot.

It's cool, I guess, but it's not a game is it?

Let's try something else I downloaded.

A maze generator.

But I can't remember the file name.

One of the limitations of this BASIC is that it doesn't know about disk drives.

Most early BASIC didn't.

This BASIC came from a time of mechanical teletypes and punched tape readers.

So how do I get a list of files from the USB drive?

Well, we've seen the monitor can do this, but that means we have to exit BASIC.

I need that file name so I'll press control alt delete to get back to the monitor.

Now I can LS and see the file is called amazing.bas.

Stopping BASIC and rebooting is fine when you want to load something, but what if I needed to check a directory before saving.

Rebooting would clear any BASIC program out of memory so it would be lost before it could be saved.

Earlier I said there was a distinction between reboot and reset.

This is where it becomes important.

The BASIC ROM and BASIC programs are still loaded in RAM.

If I issue a RESET command, the BASIC interpreter starts back up and we can see that our 3D plot program is still in memory.

So that means you can stop BASIC at any time use the monitor to manage disc access and return to BASIC at any time without losing work.

Perhaps the future will bring disk access into BASIC, but this workaround will do for now.

Let's load the amazing program and run it.

I happen to know 26 by 10 fills the screen.

Well that's a terrible maze.

Looks like we have some troubleshooting to do.

This maze has no randomness to it at all.

In fact, I'll tell you that's the problem.

The random function isn't returning random data.

That's because every implementation of BASIC is just a little bit different from all the others.

There was no standards committee or anything like that back in the day.

Fixing programs to run on your specific dialect of BASIC was a normal thing for a programmer to do.

Let's bring up the program in a modern text editor and fix it.

The RND(1) you see everywhere is supposed to return a random number.

It does on Microsoft BASIC, but on Lee Davison's BASIC it sets the random seed.

All we have to do is change RND(1) to RND(0) and it should work.

If you're wondering how I know to do this, it's because I read the documentation.

All of it.

So far, this is the only thing I found that needs to be changed for the games in these books to work.

Let's give it a try.

A global search and replace should do the trick.

Back on the Picocomputer I'll load the modified version.

That's much better.

That looks like a maze.

Let's try another program because there's one more tip I want to share.

Most games will prompt you for input.

Some versions of BASIC will repeat the prompt if you press enter without entering anything.

However, Lee Davidson BASIC stops the program.

If this happens, and was unintended, use the continue statement to return to the prompt and continue running your program.

That's everything I have to share about BASIC.

I put links to these games on the wiki.

If you know of any other BASIC programs worth looking at, please let let me know in the comments or update the wiki.

Thanks for watching.

And thanks to the patrons who make these videos possible.
