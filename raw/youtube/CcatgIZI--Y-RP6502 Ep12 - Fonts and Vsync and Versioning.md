---
type: source
source_kind: youtube
video_id: CcatgIZI--Y
title: RP6502 Ep12 - Fonts and Vsync and Versioning
url: https://www.youtube.com/watch?v=CcatgIZI--Y
captions_file: CcatgIZI--Y-RP6502 Ep12 - Fonts and Vsync and Versioning.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep12 - Fonts and Vsync and Versioning

**Source**: [https://www.youtube.com/watch?v=CcatgIZI--Y](https://www.youtube.com/watch?v=CcatgIZI--Y)
**Video ID**: `CcatgIZI--Y`

---

We're getting close.

The very next thing I'm working on is more graphics rendering modes.

But there were some other things that had to be done first, like fonts and vsync, which I'll cover in this video.

I also have some updates on some more mundane things like version numbers, so let's start with that.

There wasn't any reason to do release versioning before the hardware was fully validated, but now there's more than a dozen working devices out there and people are starting to explore writing software.

So I've released version 0.1 of the firmware with all the features I'll talk about in this video.

The first feature is an improvement to the SDK and documentation.

Unless I'm writing software specifically for Windows or Mac, I use Linux.

So I've been writing the documentation for Linux users.

This is pretty normal for someone who works on Linux back-end services, but I understand not everyone is used to developing remotely or in a virtual machine.

So the tools I picked for the Picocomputer SDK will run on Windows and Mac OS.

But I've never installed them on Windows, and MacOS wants to be different by not supporting UART breaks.

There's good news for both operating systems.

I have implemented a workaround for MacOS, and Lee Smith has released a video for Windows.

There's a link in the description.

You can also watch him build one in the same video.

Now let's talk about video modes.

I wrote specs for the video system about a month ago.

Doing something flashy like porting an emulator doesn't require a mountain of decisions and documentation because that's already been done decades ago.

Making something new and useful is a lot more work, and not all of it is glamorous.

Let's look at two of the features that have been added which were required for me to move forward.

First, are the fonts.

The traditional 8-bit solution was to provide a minimal glyph set in an affordable ROM because RAM and ROM used to be very expensive.

This meant that there wasn't room to support alphabets from multiple languages.

The most popular 8-bit systems supported only the English alphabet, which lacks diacritics of romance languages.

In other words, most of Europe.

Diacritics, sometimes called accents, are those extra marks above or below a letter.

The modern solution is Unicode, which specifies almost 150_000 glyphs.

Of course, that's not practical for 8-bit computers.

However, we can look at the evolution of Unicode to find a point in time that works for the Picocomputer.

The IBM personal computer, and I mean the actual first PC, the 5150, not a PC in the general sense, had 256 glyphs that provided some diacritics.

The selection of glyphs came from Wang word processors, according to a story told by Bill Gates and published in Fortune magazine.

The low 128 glyphs supported ASCII, and the high 128 were graphics and accented characters that would eventually be called code page 437.

Code page 437 had all the glyphs for English, German, and Swedish.

That's right, three whole languages.

The PC's original MDA and CGA video cards couldn't use a font from RAM, so some manufacturers and end users began swapping ROMs to support their locale.

With the next generation of video cards, you can load a font into RAM.

Pretty soon there were more than a dozen code pages in use around the world.

These were standardized and eventually evolved to Unicode.

Code pages are what I built into the Picocomputer.

This system works quite well with the limitations of 8-bit computing.

The Picocomputer defaults to code page 850, sometimes called Latin-1.

Selecting a code page does two things.

It swaps in a new set of glyphs and tells the file system that you're using a different character set.

Here's where it gets interesting.

The Picocomputer uses a FAT file system, like the PC, which you might remember only allowed for eight character file names with three letter extensions.

These short file names only work with 8-bit character sets.

As computers grew more powerful and storage became bigger and cheaper, support for long file names of Unicode was added.

Technically it's UCS-2, not Unicode, but the difference doesn't matter for this discussion.

The key point is that modern FAT file systems can have both a short and a long file name for every file in order to maintain backwards compatibility.

I said earlier that Unicode wasn't practical for 8-bit systems.

Fortunately, the Picocomputer file system runs on a 32-bit processor which can easily work with Unicode and all the modern versions of FAT.

But when you're programming the 6502 you'll only see the code page you configured.

You'll write programs with 8-bit characters just like you would for a traditional 8-bit computer.

The compatibility layers aren't there to bring Unicode to the 6502, it's so you can easily move USB drives between your modern system and the Picocomputer.

Let's look at this USB drive I've prepared with some Unicode file names.

If we look at it with code page 850, the French word looks fine but this other file is falling back to the short 8.3 file name.

The tilde-one on the file name is how the file system keeps short versions of long file names unique.

You can still use the file, but the name is a mystery if the code page doesn't have the necessary glyphs.

If we change to code page 855, we can see that the mystery file name is revealed but the French file name falls back to its short version.

Of course, applications will be able to use custom fonts, this setting just changes the equivalent of the ROM font.

But you can't type these characters yet.

There's still work that needs to be done on the keyboard driver to support non-US keyboards.

I don't have any non-US keyboards and I don't want people sending me a new collection of e-waste, so send a pull request instead.

Now the last feature I want to talk about is vsync.

Graphics applications often need to know when it's safe to update the screen for the next frame.

If you update moving images while the screen is being drawn, you can get an effect called tearing.

There's a small window of time between frames called the vertical blanking interval.

Applications typically update the graphics during that interval.

Normally, this is an easy problem to solve, but I ran out of pins on the Pi Picos.

So let's look at how I solved it.

Here we see a minimal Picocomputer.

It's one Pi Pico and a 6502 system.

It doesn't matter what the 6502 side of things looks, like you can have fun changing that all you like, as long as the 32 registers get mapped into the Pi Pico RIA.

In this minimal configuration, you'd connect something to the RIA UART to control the 6502.

This will always be a supported configuration for hardware hackers.

The reference design adds a second Pi Pico.

This is mostly used for VGA but also handles the USB connection to a development system.

It will connect to the RIA UART and convert it to USB.

It doesn't use this serial connection for graphics, only standard IO.

Instead, a much faster custom PIX bus is used for graphics.

I covered this in a previous video.

In short, it's much faster than a UART and doesn't exceed the electrical requirements of the 6502 side of the system.

That keeps the circuit board design extremely simple.

Now looking at this diagram, think about how the vsync signal could get from the VGA system to the RIA.

We need it on the RIA since the 6502 doesn't talk directly to the VGA system.

If your instinct is to use the UART receive line, then consider you'll lose bandwidth to a framing protocol or you'll have to sacrifice a control code.

But there's a better way that doesn't put a kink in the hose.

The PIX bus has a framing protocol that supports multiple devices, multiple channels per device, and multiple registers per channel.

It's fast enough that the UART data disappears into the noise.

So I move the UART transmit data to the PIX bus and reverse the direction of the UART transmit pin.

Let's call this the backchannel.

We can send anything we want on the backchannel, like vsync and version information, without adulterating the standard IO path.

This only happens if the RIA detects a VGA device on the PIX bus.

Remember the VGA is optional so hardware experimenters can make their own video system or go headless.

So the first challenge was a handshake to coordinate the pin reversal.

But you can't just switch it and forget it, the RIA and VGA devices might reboot independently during development.

So you have to detect a lost signal or risk blowing out your GPIOs.

And then you have to restart the backchannel when both devices return to normal.

But wait, there's more.

Switching the direction of a pin that's actively moving data without losing any data isn't always trivial.

Here's all the buffers I need for the standard out system on the RIA.

You'll have to consider all of them, even the shift registers on the physical layer.

Both paths having different sized hardware FIFOs means they're always out of sync, so you have to fully flush both sides all the way past the hardware layer before you can do the switch.

And this problem carries over to the different size FIFOs for the CDC driver in the Pi Pico VGA, which I'm not going to draw.

Once you get past all that, the higher speed of the PIX bus means you have flow control to consider.

UART speeds of 115 kilobits are easy to deal with in real time, but the PIX bus can send up to 64 megabits per second.

The solution for that was to synchronize the PIX bus with a phantom UART that's not hooked up to any GPIO pins.

Okay, that's a lot to take in, but if you're writing 6502 programs you don't need to know how the sausage is made.

Just read the vsync register and get on with the fun stuff.

The use of microcontrollers to bridge the historic 6502 to modern hardware lets us bury a lot of complexity and forget about it.

Well, you can forget about it.

I'll always be scarred from a week of work on a state machine that increments a counter.

Let's end this video by looking at a test program I use to validate vsync.

This code is in the examples repository right now.

It will likely become part of a diagnostics program or functional test in the future.

All it does is monitor vsync for five seconds and prints a pass or fail message.

So all that complexity I just talked about was to send the VGA version to the RIA and get this test to print PASS.

But now I can move on to the glamorous stuff.

But that's all I have for this video.

Thanks for watching.
