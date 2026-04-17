---
type: source
source_kind: youtube
video_id: 9u82Uy_458E
title: RP6502 Ep6 - ROMs and the filesystem - TinyUSB and FatFs
url: https://www.youtube.com/watch?v=9u82Uy_458E
captions_file: 9u82Uy_458E-RP6502 Ep6 - ROMs and the filesystem - TinyUSB and FatFs.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep6 - ROMs and the filesystem - TinyUSB and FatFs

**Source**: [https://www.youtube.com/watch?v=9u82Uy_458E](https://www.youtube.com/watch?v=9u82Uy_458E)
**Video ID**: `9u82Uy_458E`

---

Hello YouTube.

In this video we're going to look at some options for mass storage in your microcontroller projects.

We'll look at two different file systems and three different types of flash storage.

I'll show you a little bit about how to get the libraries working then we'll take a tour of the new storage features in the Picocomputer.

Now there's a lot of file systems to pick from.

If you need to exchange data in the most compatible way, a FAT file system is the best option.

If you buy a new SD card or USB drive, it will almost certainly be formatted for FAT.

There are different versions of FAT: FAT12, FAT16, FAT32, and ExFAT.

Your operating system will pick one based on capacity when you format the drive.

The only thing to watch out for is ExFAT since some devices and libraries won't support it.

ExFAT also uses a patented algorithm from Microsoft, so you'll want to look into that before releasing your project.

The FAT Library we'll look at is called FatFs.

There's another one by the same author called Petite FatFs, which is lighter weight but doesn't support ExFAT.

I have plenty of room so I use the big one.

The other file system is called littlefs.

This was developed at Arm for use directly on flash memory chips.

So what's the divide here?

Why did I need two file systems for one project?

Well, I wanted to keep configuration settings on the same flash chip that the microcontroller uses.

I could have just made a FAT file system directly on the flash chip.

That would work for a while.

But there's no wear leveling with FAT.

The individual blocks on a flash device have a limited number of erase cycles which fat doesn't account for because it was designed for spinning rust.

USB drives and SD cards have built-in controllers that manage the wear leveling, so it doesn't matter what file system you use there.

A naked flash chip does not do this.

That's why I used FAT for the USB drives and littlefs for the internal flash chip.

Now FAT can be used on both USB drives and SD cards.

USB drives, of course, need a microcontroller that supports USB.

SD cards can use SPI and can even be bit banged if SPI Hardware isn't available.

I will not be exploring SD cards over SPI in this video.

First, SD cards can be used over USB with an inexpensive adapter.

Second, my application is an 8-bit personal computer, so I want removable media slots accessible from the front.

Modern retro 8-bit computers are only allowed to have one SD card slot and it cannot be on the front.

Fortunately, USB solves all these problems.

Extension cables and hubs are inexpensive and easy to use.

My project uses a Pi Pico, which is supported by TinyUSB, which includes an example for FatFs.

All the heavy lifting has been done by the library authors.

Making a device driver needs only three connections between the libraries.

First, the file system needs to know how many sectors there are and their size.

Second is mounting and unmounting drives and third is the read and write commands.

I know that sounds too easy.

The documentation certainly doesn't make it sound that easy, but once you see it hooked up for the first time the problem becomes a lot smaller.

So let's begin by looking at a USB Mass Storage driver.

I'll be moving through the code pretty fast.

I want to share my experience with these libraries, not put you to sleep by reading code.

First, you implement an IOCTL, which is just relaying information about how big the disk is.

Second, TinyUSB weil call these mount and unmount functions when a USB drive is plugged or unplugged.

You just pass that along to the FatFs functions for mounting and unmounting.

And third, read and write calls from FatFs get passed along to TinyUSB.

This has one thing that's not obvious at first.

Everything in TinyUSB is non-blocking.

Events are collected during interrupts and handled in a task function.

You'll need to block reads and writes until this task function executes the callback.

How you do this will vary depending on your concurrency model.

The wait_for_disk_io here calls the USB worker task repeatedly until the callback clears a flag.

It's slightly easier if you have an RTOS, but I don't for this project.

Once all this is in place you can call f_open, f_read, f_write, f_close and a bunch of other things just like you would on a posix system.

I spent more time adding these libraries to the build script than I did getting the driver to work.

Just study the example in the TinyUSB library and you should be able to work out any unique details specific to your application. littlefs is slightly more complicated because there's no example and you need to know how your flash system works.

You'll start with setting up this config structure.

It consists of four callbacks, some configuration about the capacity and block size of your flash chip, and some memory buffers.

The Pi Pico's flash is memory mapped so reads are implemented with a memory copy.

You'll want to use the base address that doesn't do caching, if that's an option, which it is here.

Writes happen in two stages.

First, a block is erased, then it can be programmed.

Only whole blocks can be erased, that's the flash part of flash memory, but individual bytes can be written.

So this is split into two calls.

Both are simply relayed to the Pi Pico SDK.

Once this is all set up you can mount the volume.

But that won't work on the first boot since the volume isn't formatted.

So I did what the readme said.

If the mount fails, just format it and go again.

I don't unmount since the chip can't be removed and I don't need to recover the memory buffers.

Once the drive is mounted you can lfsopen, lfsread, lfswrite, you get the idea.

Just like with TinyUSB and FatFs, the heavy lifting was done by the library authors.

You just need to connect littlefs with the Pi Pico SDK using a small dab of glue.

Now let's look at the new features in the Picocomputer.

If you're new here, the Picocomputer connects a genuine 6502 processor with a Pi Pico to support modern devices like USB flash drives.

Here's what it looks like on my desk.

That Commodore keyboard has been converted to USB and is what I've been using for the past month.

I made a video about it which you can find in the description.

Notice how the USB hub is front and center so I can easily swap media.

I'll switch to the capture card so everything is nice and crisp.

There we go.

I put a hello world program on this USB drive.

Let's plug it in and run it.

LS will show the files on the drive.

The LOAD command will load and run the program.

Okay.

That was easy.

Wait.

Has this ever been done before?

I just loaded and ran a 6502 program from a USB flash drive.

Not an SD card, a USB drive.

I think this might be a first.

I've seen it done on an FPGA but never on a computer with a real 6502.

Okay, but there's more, so let's not dwell on that.

I have a build script on my Linux install that compiles BASIC.

The Picocomputer is plugged into a USB port of my Linux machine for both power and debugging.

Let me run that build script.

As the final step in the build process the binary is uploaded to the flash drive.

We can LS and see the file.

And load BASIC.

This feature greatly speeds up how fast we can iterate during development.

You can upload binaries and any other assets without swapping drives between computers.

Okay, but there's more.

My Commodore 64 used to boot directly into BASIC.

It didn't load BASIC from a drive, it was just there.

Always and forever in ROM.

It'd be great if we could install this BASIC image to be like a ROM.

Like put it directly on the Pi Pico's flash so it's always there and always runs when I power up.

This is not an editing trick.

This stuff really works as smooth and fast as it appears to be.

But you know, I really like my Hello World program.

So much so that I want to be greeted with hello world every time I turn on my computer.

Let's call the things we install on the Pi Pico: ROMs, and let's install hello world as a ROM.

Now we have two ROMs.

You can see all the installed ROMs at the bottom of the help.

You can ask for help on them too, as long as the author included help.

Aand you can run them like commands.

And choose a different one to boot with.

Okay, but there's more.

STATUS shows us all the settings.

Oh!

I've been demoing everything at one megahertz.

We can go faster, of course.

Better get out that manual and change those DIP switches.

Of course not.

Just change what you want right here it takes effect immediately and is saved automatically.

If you're not sure about something, ask the help system.

Do you remember when you got your first floppy disk?

I was sure glad to stop using cassette tapes, but I also immediately started saving money from my paper route to buy a second drive.

It's easy to forget these things in a time when a hamburger costs more than adding a second drive.

I think that's everything I want to show this time.

I ordered some floppy disks to see if I can get removable media working.

You can still buy new three and a half inch USB disk drives for 20 bucks and there's plenty of media available as new old stock.

If I get that working I'll post a short demo on Patreon.

That's all for this time.

Thanks for watching.
