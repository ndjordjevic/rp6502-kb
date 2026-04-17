---
type: source
source_kind: youtube
video_id: kf-mvyL70bc
title: RP6502 Ep7 - The Operating System - featuring Colossal Cave Adventure
url: https://www.youtube.com/watch?v=kf-mvyL70bc
captions_file: kf-mvyL70bc-RP6502 Ep7 - The Operating System - featuring Colossal Cave Adventure.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep7 - The Operating System - featuring Colossal Cave Adventure

**Source**: [https://www.youtube.com/watch?v=kf-mvyL70bc](https://www.youtube.com/watch?v=kf-mvyL70bc)
**Video ID**: `kf-mvyL70bc`

---

I know what you're thinking.

How much hyperbole is there in that thumbnail.

So let's get right into it.

Let's look at the features of my operating system.

We have a protected mode kernel, multi-processing, a USB stack, device drivers, and a FAT file system.

But none of that's new.

You've seen all that in my previous videos.

What's new is that userland now has access to everything.

Most importantly, applications can now access the file system.

That's not necessarily the definition of an operating system.

If, for example, you're building a microwave oven, you might not have a file system at all.

Then again, everything's connected to the internet and needs security patches twice a day, so maybe microwave ovens do need file systems.

I don't know.

The difference between a bundle of software and an operating system isn't what it contains, but how it's put together.

Once you start to make some rules you'll immediately find there's things you know are operating systems but still break the rules.

Even Wikipedia editors can't decide what's in an operating system kernel.

Right here at the top. "This article's factual accuracy is disputed." They're talking about the opening paragraph.

Even so, this first image is pretty useful.

We can see the application has to go through the kernel to talk to managed hardware.

That seems to work for microwave ovens as well as personal computers.

Keeping those concerns separate and the interface between them consistent will cause an operating system to emerge.

Still, the details will vary based on what the system needs to fulfill its purpose.

I'm making a personal computer.

I wanted a device to explore retro Computing and game developments by removing the barrier between genuine 8-bit hardware and modern hardware.

You'll find the details of my operating system to be similar to other personal computers.

I never set a goal of making an operating system.

Didn't really give it much thought.

I just knew what kind of software I wanted to run.

Turns out if you want to run posix-like software you'll eventually find yourself writing the kernel for a posix-like operating system.

For this video, I took a program intended for Linux, compiled it, put it on this USB stick, and we're going to run it on a 6502.

On this Picocomputer.

The program is called Colossal Cave Adventure.

The Crowther and Woods version ported to C.

Nothing was removed or simplified.

It's the full program.

Before we play games though, let's look at the operating system some more.

We'll begin with userland.

This is a real 6502 computer.

A 1980s processor, I/O chip, and RAM.

It has no ROM though.

Instead, there's a mechanism in the kernel that can load RAM while the processor is in reset.

This way we easily get the whole 64k except for the last 256 bytes which are reserved for I/O hardware like the 6522 here.

If 64k isn't enough, keep in mind there's another 64k we'll talk about in a bit.

And if you want even more, you can change the design.

The only thing you can't change is the very last 32 bytes of memory.

These contain special memory locations for the 6502, like the startup address, and will need to be mapped into the RIA.

What's a RIA you ask?

It's an interface adapter to the Raspberry Pi Pico.

A Raspberry Pi Pico contains two Arm Cortex M0+ processors.

We use one of them to run the RIA.

This spins a hot Loop that can't tolerate even a single interrupt.

It works with a programmable I/O system to manage the connection from userland to the kernel.

The kernel runs on the other processor.

Now these processors are the very smallest of the Arm processors.

There's no memory manager, program isolation, or floating point support.

You can't run Linux or Android on these.

You may remember I mentioned the kernel is protected though.

This is a side effect of using the RIA for kernel calls.

No matter how hard your 6502 program fails, the kernel keeps running.

Another side effect is that the kernel doesn't use any of the 6502s 64k of RAM.

Except those 32 bytes needed by the RIA.

Plus you have another 64k of VRAM.

This is memory shared between userland, the kernel, video, and audio.

You can't run 6502 code directly out of that, but you also don't need to put graphics data in your program memory.

Let's look at the device drivers and file systems.

We have human interface devices, which are your USB keyboard mouse and joysticks.

Mass storage controllers are another name for USB flash drives.

LittleFS for managing the internal Flash.

FatFS for the USB flash drives.

A communications driver for the UART.

Configuration management so we don't need dip switches.

The real-time clock and networking haven't been started yet, but everything else is nearly complete.

Now let's talk about the use of 32-bit microcontrollers in 8-bit projects.

Is that cheating?

You bet it's cheating.

The operating system is over one megabyte with the networking libraries and code pages linked in.

But here's the thing.

You don't have to use any of it.

It's there for when you want easy mode and it completely vanishes when you want some 8-bit challenges. if you want to create your own purely 8-bit operating system, the Picocomputer makes great scaffolding.

If you want to write a game and focus only on graphics and sound, you can (soon).

If hunting down keyboards and mice that still work with the PS/2 protocol is your idea of a good time, wire in a socket and have at it.

What I've done with the Picocomputer is made it so you can skip the annoying parts and focus only on what you think is fun.

All I ask for is 32 bytes.

Now there's one more massive advantage to using a 32-bit microcontroller for this.

I can build the kernel with other people's code.

I didn't write the file system.

I didn't write the USB stack.

I wrote some device drivers and brought everything together into a kernel.

There's other people who have more code in the Picocomputer than me and they probably don't even know.

Let's look at the ports on the Pi Pico.

The USB port runs in host mode so you can plug in a hub and all your devices.

The audio port doesn't have software yet.

The UART is fully functional.

This is stdin and stdout.

There's two other ports on this side.

SWD is the Arm debugger and PIX is a high-speed graphics bus.

These three ports are designed to connect with a second Pi Pico for VGA output and connection to a development system.

This VGA Pi Pico is optional, but keep in mind a Pi Pico will cost less than a single eight kilobyte eprom these days.

Just the eprom itself, not including the programmer you still need to buy.

Here's a fun fact.

This project was developed without any eproms or programmers for the 6502.

I don't own any and haven't used them since the 1980s.

And I have no regrets.

That process is awful and I don't need that kind of nostalgia.

Getting the PIX bus working is the next priority.

This is why VGA is limited to ANSI terminal emulation at the moment.

Once PIX is up, the 6502 will have direct access to video graphics memory.

Okay, enough of that.

Let's play the game now.

Colossal Cave Adventure is a text Adventure inspired by the author's exploration of Mammoth Cave in Kentucky.

I was actually inside Mammoth Cave back in the 8-Bit days.

How cool is that?

Let me switch to VGA capture.

I have the program on this USB drive.

It's just a plain FAT file system.

No need for disk images or any other shenanigans.

I can plug it into the Picocomputer and we can list the files.

This USB drive has an activity light so I put the camera on it for you.

There's 90k of files here.

The data files could have been put in VRAM, but the program was designed to read them from disk.

Since I want to test calling into the kernel, I left it as is.

The program makes no attempt at being efficient either.

Every single character of text requires a read call into the kernel.

But that's still faster than a Commodore floppy drive, so it's all good.

Okay, let's load the adventure.

That delay was half disk access and half initialization.

The whole 45k executable is loaded now.

Any further disc activity you see is the data files.

I'm not going very far in the game, so don't worry about spoilers.

We're outside the building right now.

You always start here.

Let's go inside Okay there's a pile of stuff here.

I'm going to grab the food.

It's in my inventory now.

Let's say I've been playing for a while and Mom calls me for dinner.

I want to keep playing computer games so I tell her I already have some food, but she's not buying it.

No problem, I can save the game.

Thought this was a bug at first but the game really does exit after you save.

If we look at the file system, there's a game save on there now.

By the way, you can load this save anywhere else you've compiled the game.

As long as it's a little-endian system, which pretty much everything is.

Let's start the game again and see if the save loads.

Okay, we're in the building with our food.

Looks like it worked.

I'm guessing you could play through the whole thing without issue.

This version is supposed to be pretty authentic.

I've never played through, but I've heard it's difficult and unfair.

I think a lot of the fun comes from sharing discoveries with other players at a user group meeting or computer lab.

These days you'll be stuck playing alone and consulting the internet.

Still, it's an important piece of history, so there's new types of fun that we can have with it.

Now is this an operating system?

It has no name since it wasn't a goal of the project.

The computer it's for doesn't have a circuit board yet.

Its creation is mostly a retrospective declaration.

I'm going to go with yes since it makes a good thumbnail.

This video is part of a series to document every milestone of developing the Picocomputer.

If you'd like more technical details about this particular milestone, like a tour of the binary interface, give me some encouragement in the comments.

There's a playlist in the description for the other videos and you can join me on Patreon for smaller and more frequent updates.

That's all for now.

Thanks for watching.
