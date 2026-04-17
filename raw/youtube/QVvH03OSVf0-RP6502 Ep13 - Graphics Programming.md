---
type: source
source_kind: youtube
video_id: QVvH03OSVf0
title: RP6502 Ep13 - Graphics Programming
url: https://www.youtube.com/watch?v=QVvH03OSVf0
captions_file: QVvH03OSVf0-RP6502 Ep13 - Graphics Programming.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep13 - Graphics Programming

**Source**: [https://www.youtube.com/watch?v=QVvH03OSVf0](https://www.youtube.com/watch?v=QVvH03OSVf0)
**Video ID**: `QVvH03OSVf0`

---

This video is an introduction to graphics programming on the Picocomputer 6502.

I'll bring you through the process of getting the VGA system into bitmap graphics mode, and then we'll combine modes with the programmable scanline system.

Alright, let's get started.

I already have the tools set up and a copy of the template project loaded.

You can watch my C programming setup video to learn how to get to this point.

The template starts you off with a classic hello world.

I'll press control shift B to send it to the Picocomputer.

Before we start programming, there's one hardware setting to look at.

Here on the console if you type HELP SET VGA you'll see there are three supported display types.

If widescreen graphics aren't filling up your 16x9 display, or the pixels aren't square on any display, check this setting before adjusting the settings on your display.

What you're changing here is the output of the Picocomputer scaler, not the internal resolution your application will use.

With that done we can begin programming.

That's right, it's time to look at the documentation.

I'll skip over this stuff that you can read on your own.

The first thing of interest are these key registers, canvas and mode.

Extended register $1:0:00 selects a canvas.

This is the resolution your application will work with.

Canvas 0 is a special canvas containing only the console terminal.

That's the default so you'll probably never set it manually.

Since most people watch YouTube on 16x9 displays, I'll use canvas number two, 320 by 180.

This selection combines with the display setting to determine the output of the VGA port.

For example, if you selected the 16x9 display option then you'll get a 720P HD signal with pixel quadrupling.

For other displays you'll get letterboxing.

So the images I'm showing will be 720p from an HDMI capture card.

Keep in mind the compressed video on YouTube never looks as good as a raw feed and my capture card drops an occasional frame.

Now for the mode.

Only mode zero and three are complete right now, so let's start with some mode 3 bitmap graphics.

We can have some fun looking at images and drawing boxes.

It says there's another section about bitmap graphics.

Okay, here are the registers for bitmap mode. $1:0:01 gets set to three and then $1:0:02 is the options for bit depth.

I'll show the code for this soon.

Right now we're just making decisions.

The note at the top says we can have 256 colors at this resolution.

So let's do that.

Multiplying 320 by 180 tells us a 1 byte per pixel image will use 56k of our 64k of extended RAM, so that'll work.

This next register is the config.

This will need some explaining.

It says it's the address of a config structure in extended RAM.

That config structure is shown right here after the registers.

So what is extended RAM?

First, we have the 64k of system RAM connected to the 6502.

Well, almost.

The last page is reserved for hardware expansion so there's 64k minus 256 bytes, if we're being precise.

But that's not important since extended RAM is a different 64k that the 6502 can read and write, but not execute code from.

The Pi Picos don't have access to 6502 system RAM while the 6502 is running, so everything on the VGA system has to be done in extended RAM.

These extended registers I've been talking about are a mechanism to program systems that use extended RAM.

What the documentation is telling us is that we need to put this config structure in extended RAM.

We can put it anywhere we like, and it points to other data structures, which we can also put anywhere we like, as long as it's extended memory, not the system memory.

The entire 64k of extended memory is completely free for you to partition any way you want.

Not even a single bite is reserved.

It's all for you.

To keep things simple, I will put the bitmap data at extended address 0 and I'll put the config structure at $ff00.

We'll look at the X and Y parts of this config structure in a bit.

Let's start with the width and and height.

This does not need to match the canvas size, but it does have to fit in extended RAM.

I want to use the entire screen so this will be set to match the canvas size.

Next is the data pointer, which I already said would be at zero.

And finally is a palette pointer.

A magic value of $ffff will use the built-in ANSI color palette, which I'll be using because it's easy.

I suppose now is a good time to show off the new ANSI terminal, also known as mode zero.

It used to be 16 colors but now it's 16 bit color.

The 256 color palette at the top is what we'll be using.

Now that we have a plan, let's look at the code that makes it happen.

Setting extended registers is an operating system call which can return failures.

Make sure you check the return value and the error number if you run into problems.

Setting extended registers is pretty straightforward.

Give it the address and a data value.

Earlier I said that we need to set address $1:0:00 to value two for the canvas.

So it's xreg 1 0 0 2.

This selects the 320 by 180 resolution.

The next thing we do is prepare a config structure.

I'll use a macro and the typedeps from the SDK to do this.

Make sure all the fields get initialized.

If there's bad information in this structure, nothing will be rendered to the canvas.

Now we can program up mode three to use this config structure.

Looking at the documentation, there's plane, begin, and end registers too.

We'll get to those in a bit.

For now, they can be ignored.

We only need to set mode, options, and config.

The xreg call is variadic and can set multiple registers at once.

This is handy here because we need to set three registers in a row.

The first register is $1:0:01 followed by $1:0:02 and $1:0:03.

The values we want to set are three for the mode, two for the options, and $ff00 for the config structure.

So the xreg looks like this.

The 1 0 1 is the starting address and the 3 2 and $ff00 are the register values to be set beginning there.

So that's everything to get graphics working.

It should give us random garbage from uninitialized memory if we run it, and it does.

It's bad form to blast your users with garbage video so let's clear the extended memory before we bring up mode 3.

Extended memory is access by setting the registers on the Pi Pico RIA.

These are ordinary registers, not extended registers.

Looking at the documentation, we see two sets of address, step, and read write registers.

Both sets work the same on the same 64k of extended memory.

We'll only be using set zero for our program.

So let's drop in this clear function.

We have 57,600 bytes of memory to clear start starting at address 0.

So RIA.addr0 is how we set the starting address.

We also set the step value to one so the address will increment every time we access the data.

Sequential access to extended memory is faster than system memory because of this.

Now we loop over the 57,600 bytes and set them to zero, which is black in the ANSI palette.

When we run the program, it's a black screen.

So now we should draw something in the data area.

We selected two for the options, which is 8bit color, so the data is a simple array of bytes without any bit packing.

Our 320 x 180 canvas has its data in 180 rows of 320 bytes.

One bite per pixel is as simple as it gets.

So let's draw some boxes.

I wrote this function which draws a number of random boxes in random colors.

There's nothing special in here.

We gather some random numbers from the C standard library, shuffle them around so the loops only need to increment, and then loop over the rows and columns to set the color.

I'll ask for 10,000 boxes so we can watch it run.

This is real-time without any co-processing, but the 6502 is running at 8 MHz so it's probably a bit faster than your childhood computer.

Now let's go back and look at those X and Y options.

Let's change X to 100 and see what happens.

Okay, it shifted the entire image to the right 100 pixels.

Let's try Y pixels at negative 100.

Okay that shifted the image up.

We can change config data at any time to move the screen around.

For example, shaking the screen when the player gets hit or a scrolling playfield for a schmup or platformer.

Let's go back to the code and add a function that scrolls the bitmap after drawing 10 boxes.

This is an infinite loop that increments X and Y every time it goes around.

Okay let's run it.

Oh right, uh that's that's a bit fast.

In my last video I talked about how I got vsync working.

We should use that.

The vsync register increments every time the screen is drawn, so 60 times a second.

All we have to do is wait for the register to increment then proceed with the X and Y updates.

The vsync register will increment at the best time for these updates.

This is at the start of the vertical blanking interval.

You have a bit more than 500 microseconds to do updates before the screen starts drawing again.

If you don't update fast enough, artifacts like tearing can occur.

So not only do we get a stable timer that can be used for video game physics, we can do our updates precisely between frames to make animations perfectly smooth.

With that hooked up, let's go.

Looks great.

But wait, there's more.

Instead of a single image we can enable tiling.

This will make the image repeat in either or both directions.

The effect here is an infinitely repeating pattern.

Now that we've covered the fundamentals of the config structure, let's go back to those plane and scanline settings.

If you've used photo editing software then you're familiar with layers.

Planes are a different word for the same idea.

The Picocomputer has three planes.

Plane zero is drawn first, plane one is drawn over that, then plane two.

If you've ever wondered why 16-bit video systems often have only 32,000 colors instead of 64,000, it's because the 16th bit is used for transparency, sometimes called the alpha channel.

Just like in photo editing software, this is what lets us see through to lower planes.

If you're thinking planes will make parallax scrolling super easy, then you got it.

You know exactly where this is going.

That's right, we're going to put text on top of the bitmap.

Looking at the documentation, there's not a lot of options for mode zero, but there is a plane option.

So let's put the console up on plane one since our bit map is on plane zero by default.

Starting at register $1:0:01 we need to store a zero then a one.

So xreg 1 0 1 0 1 will do the trick.

Now everything we send to standard out can be seen over the graphics.

Since I didn't clear the console, some of the remnants are still shown.

Being able to easily print is incredibly useful for debugging, or you can use this for something like a graphical text adventure.

The scanline options are an easy way to do this.

Let's say I want five lines of text on the bottom and the rest of the screen will be for bitmap graphics.

There's 180 scanlines on our canvas so I'll make the first 140 for graphics and the last 40 for text.

All we have to do is add the plane and scanline registers to the xreg calls.

A setup like this could also be useful for a visual novel, an RPG, a SCUMM game, and lots more.

There's other ways to do this, like not drawing to part of the plane.

But rendering a blank line still takes time and there's a limit to the fill rate.

We'll look at these limits in a future video with sprites and tile graphics.

There's only one more thing I want to show this time.

I have some photos that have been converted to 8bit color with custom pallets.

This pushes the limits of 64k.

It also demonstrates how fast you can load images.

There's no editing magic here.

The entire 56k for each image is loaded in under a second while the screen is blank.

Think about this in the context of loading game levels.

You should be able to do so fast enough that putting up a loading screen would feel awkward.

In addition, loading to XRAM doesn't use the 6502, so you could stream in new assets while your game is running.

The newest NVMe SSDs and x86 processors can do something similar in Windows 11 called DirectStorage.

I didn't give it a fancy name on the Picocomputer because this ability is intrinsic to all operating system calls, but that's a topic for another time.

That's all I have for this video.

I'll be adding tile and sprite modes so watch for future updates.

Thanks to everyone who supports me on Patreon and Thank You for watching to the end.
