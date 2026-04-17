---
type: source
source_kind: youtube
video_id: e1c91LBn-b8
title: RP6502 Ep14 - USB Mouse on a 6502
url: https://www.youtube.com/watch?v=e1c91LBn-b8
captions_file: e1c91LBn-b8-RP6502 Ep14 - USB Mouse on a 6502.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep14 - USB Mouse on a 6502

**Source**: [https://www.youtube.com/watch?v=e1c91LBn-b8](https://www.youtube.com/watch?v=e1c91LBn-b8)
**Video ID**: `e1c91LBn-b8`

---

In this video I'll introduce some enhancements to the input system and show a demo I made that uses the mouse.

Let's look at someone else's demo first.

In the previous video I showed a new graphics system that I suggested would enable parallax scrolling.

On a classic 8-bit system, this would normally require intricate knowledge garnered over much time, and hackery like scan line interrupts or pallet cycling.

Well, I must have done something right in the design because it took less than a week for demos to show up in the forums.

Not just one, but three.

This one is from Brent Ward.

The familiar blue man looks like he's having a mega good time, if you know what I mean.

To see more demos, head over to the forums.

Start with the "clear pixels" thread.

Be sure to click the hearts and thumbs up for your favorites.

Now, I had some fun too.

Let's look at the changes to the input system.

I'll start at the beginning so you can see how everything evolved over the course of development.

This is a development vlog after all.

In this diagram we see the first method of interacting with the user.

The 6502 talks to a UART which connects to a terminal.

This is the primary terminal, so it's sometimes called the console.

If you have a USB keyboard and VGA display connected to the Picocomputer you can use that as the console, or connect to a PC over USB and use a terminal emulator.

Your choice.

Both even work at the same time.

Let's look at some code that uses the UART.

Here we loop over a string we want to print.

Inside the loop we first wait for the UART to become ready.

Then we send a byte.

This loops until the whole string is sent.

Input is basically the same.

Check for ready, then read the character.

That's all there is to it for a hardware UART.

It only gets complicated when you're bit banging GPIOs, but we have a proper UART so let's move on to something more pragmatic.

The Picocomputer has a POSIX- like operating system so you can access the UART as standard in and standard out devices.

All you need to do is printf() from C and something will print.

You can also call fgets() to use the line editor built into the operating system. fgets() is actually a new feature added for this latest release.

This makes the standard IO system fully complete now.

Here's a small program that asks the user for their name and prints a greeting.

There's only four lines of C code.

Let's run it.

The problem with standard IO is that it's not good for games unless it's a text game, but even then it may not be appropriate.

The Picocomputer has always been billed as a retro gaming computer.

To that end, what we need is a way to directly read the keyboard and mouse.

Specifically, what we need to know is when keys are being held and when they are released, not just the key down event.

So a third input mode is what I added for this release.

It's very straightforward to use.

There's no matrix decoding or anything complicated like that.

Keys or buttons will toggle bits and mouse movement changes integers.

The documentation covers everything in detail.

In short, the keyboard becomes a bit array of HID key codes where one bit equals one key.

Here's some code that waits for a key to be pressed.

We start by setting the location for a 256 bit array in extended RAM.

Then we check the bits we're interested in.

Really, that's it.

In this case we're waiting for bit zero to clear.

Bit zero is a special bit that indicates no keys are being pressed.

Perfect for a true "any key" because even the shift key and other modifiers are detected by this method.

The mouse is similar but includes integer counters that change as the mouse is moved.

For example, if the user moves the mouse three units to the right then the X counter increases by three.

All you do is subtract the previous value from the current value and you'll know how much the mouse has moved since the last time you checked.

This code is in the example paint program.

Because every operating system needs a paint program.

I may circle back to this example one day and make a whole video about it, but for this time let's just run it.

The color picker at the top lets me select a color for each mouse button.

The movement feels as good as any modern system, probably because I'm using a modern optical wireless USB mouse.

That's right, USB.

We're not savages.

No PS2 mouses here.

The paint program is an example program for folks to get started programming with the mouse, so the feature set is pretty limited.

But I did spend time making sure the code breaks out a good set of events.

For example, we can drag the toolbar around.

The colors have little dog ears to indicate which button they are assigned to.

And the square will erase the canvas.

I need to say this again.

The mouse movement feels fantastic.

Moving the toolbar around has no lag because the graphics system does all the heavy lifting.

This is also the first program I wrote that goes a bit beyond a functional test, and it was a lot of fun to work on.

I need to get back to finishing the remaining graphics modes, so that's all for this video.

The paint program is in the examples and I'll be shipping it as the example binary with the Pico images.

Thanks to my patrons, thanks for watching, and hope to see you next time.
