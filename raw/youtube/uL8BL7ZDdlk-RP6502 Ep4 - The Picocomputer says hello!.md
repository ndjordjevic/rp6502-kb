---
type: source
source_kind: youtube
video_id: uL8BL7ZDdlk
title: RP6502 Ep4 - The Picocomputer says hello!
url: https://www.youtube.com/watch?v=uL8BL7ZDdlk
captions_file: uL8BL7ZDdlk-RP6502 Ep4 - The Picocomputer says hello!.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep4 - The Picocomputer says hello!

**Source**: [https://www.youtube.com/watch?v=uL8BL7ZDdlk](https://www.youtube.com/watch?v=uL8BL7ZDdlk)
**Video ID**: `uL8BL7ZDdlk`

---

Hello, World!

It's demo time.

Not only that, I've released a schematic for the 8-Bit Expeditionary Force.

You can have your own Picocomputer today if you're comfortable building on a breadboard from only a schematic.

Since last time, I've connected the RAM and the 6522.

Chips like the 6522 are how I/O is traditionally done on the 6502.

Couldn't help myself and made a happy blinking light.

Actually, I leave this running to test for stability.

Everything is wired up now except the Pi Pico interconnects for VGA.

That'll give us 16-bit color, sprites, scrolling, and all that fun stuff.

But today we're going to look at using the Picocomputer from a serial terminal.

I'm going to be using minicom, a terminal emulator for Linux, but keep in mind this will function the same way with a USB keyboard and VGA or HDMI display.

The Pico computer has a built-in color ANSI terminal which will be active unless a program switches to a graphics mode.

Okay, so this is the monitor.

Over the years the term monitor has become synonymous with CRTs and LCDs.

When someone talks about the monitor for a 6502, they are probably referring to a bit of software that lets you prepare memory and launch programs.

You can type in an address and it shows you the memory contents.

You can also type in an address and some data to set the memory contents.

Definitely easier than entering programs from a panel of switches, but essentially doing the same thing.

Let's get a program in there.

Good old hello world.

The three languages I'm going to use in my videos are assembly, C, and eventually BASIC.

Let's do assembly today.

Don't panic if this is your first time.

I'll explain the eight opcodes needed to follow along.

A quick look at the memory map before we make code though.

There's no ROM attached to the 6502, so the full 64k is filled with RAM.

Anything you might have had in ROM back in the day can just as easily be loaded into RAM.

Easier perhaps, since you don't need to pull a chip and buy programming hardware.

You can put your program anywhere.

I'm not going to use zero page or the stack today, so I could install the program at zero.

But it's easier if you don't fight the expectations of the 6502.

We'll install our program at $200 hex.

The other thing to notice is the I/O space at $FF00.

This is where I put all the devices that are not RAM, including the Pi Pico.

Hello world is pretty small.

It'd probably take longer to install the tools and set up the project than to write the program.

So let's use this webpage for instant gratification.

Line one is the start address: $200 hex.

This doesn't make any machine code, it's just a directive for the assembler.

The next line makes machine code.

I read this as load X with zero.

The dollar symbol means hex.

No dollar symbol means base 10.

Remember this is from well before C became popular.

Even ASCII wasn't pervasive at the time.

Newer assemblers do accept C formatted numbers, but I'll stick with tradition here.

The pound symbol means immediate mode.

Don't sweat the language.

There are 13 addressing modes.

You can forget all their names and still write first class assembly language.

Just remember that the pound symbol means this is a value, not a memory address from which to retrieve the value.

So we've set X to zero.

It's my intention to use this as a loop counter.

What do we do in the loop?

We read some ASCII and send it to a serial port.

We need some ASCII now.

We also need a carriage return, line feed, and I'm terminating with a zero.

We use a label here which can be used in place of an address because we won't know the address until the code is assembled.

Let's make some room.

Our next instruction will read one character of text into the A register.

No pound sign means this is an address from which to fetch a value.

The comma X makes this absolute mode with an X index.

In higher level languages, this would be X in brackets, so like A equals text[X].

On the first pass through the loop, X is zero, so this will load the letter H from hello into register A.

When X is 1, the letter E is loaded, and so on.

Now we want to send register A out the serial port.

To do this, all we have to do is write it to the Pi Pico.

Anything you write to the address $FFEE is sent out the serial port.

And by serial port, I mean the USB port connected to your computer.

This is also how you power the Picocomputer.

So store A at $FFEE is the instruction we want.

We're almost done.

Just need to loop back for the next character.

We'll need to add one to X before we go again.

Increment X does that.

But before we go again we should make sure we're not at the end of the text.

Remember that zero at the end?

If A is zero then we're at the end.

The compare instruction will test A against some value.

It doesn't restart the loop though.

All it does is set a status flag.

This next instruction, branch if not equal, looks at the status flag to determine if it should jump or not.

Where to jump?

Let's put a label at the start of the loop.

That's it.

That's hello world.

But wait, there's one more thing.

We have to end the program.

The 6502 has no halt instruction but we can send the processor into an infinite loop that does nothing.

That's kind of ugly and it doesn't return control to the monitor.

Instead, let's ask the pi Pico to shut down the 6502.

I made it so this happens when we write to $FFEF.

Now we're really done.

Let's hit assemble.

Success.

I'll just copy this text here and paste it in the terminal.

Okay, now we can run it.

Hello, World!

Since we stopped the 6502, control has returned to the monitor.

Let's kick it up to eight megahertz.

Yep, still works.

What about one kilohertz?

Oh, that's slow.

Very slow.

If you've used a monitor on a 6502 before then you may be wondering how it's working when the processor is shut down.

Or you may have guessed that it's running on the Pi Pico.

But the Pi Pico is only connected to five address lines.

There's no way to address all 64K.

Yet this monitor can read and write all 64K.

What happens is the Pi Pico will start up the 6502 and run a 10 byte program that copies memory.

In fact, it's actually faster to copy across this barrier than it is for the 6502 to copy its own local memory.

The complexity is a bit comical though.

For the monitor to write a single byte, it uses three CPUs, two PIOs, and a bunch of DMA in parallel.

It's totally seamless in its execution though.

Let's look under the hood.

In the previous two videos, I showed how the 6502 can read and write the Pi Pico with PIO.

A third PIO program has been added to trigger actions when certain addresses are accessed.

That PIO sends its messages here.

This loop consumes an entire ARM CPU to meet the hard real-time requirements.

Here we perform the actions for registers that write to the serial port or shut down the 6502 and other things I haven't added yet.

We can also use these messages to support reading and writing the 6502 RAM.

Here's the setup for writing.

The interesting bit here is the self-modifying fast load program.

Now that you know some assembly language, you can follow along.

The two new instructions are no-op and branch.

No-op does nothing.

I'm using it for alignment.

Branch is an unconditional jump back to the start of the loop.

So this program stores the value 0 in memory location 0, over and over, forever and ever.

But this program is just a template.

Those zeros are replaced with useful values as you can see here.

But it still writes one value to one location, forever and ever, unless we intervene.

Since the 6502 is running this program from the Pi Pico's registers, we can trigger an action when the 6502 reads the last byte of the program loop.

What we do is update the value and the address, and on the last iteration we short-circuit the branch instruction.

This has to start happening in less than about 200 nanoseconds at eight megahertz.

Not milliseconds, not microseconds, nanoseconds.

Turns out the timing isn't really that hard.

That part worked as expected.

The problem I ran into was the 6502 startup sequence.

What they don't tell you in the datasheet is that for those first seven clock cycles after a reset, the 6502 will spew garbage on the address bus.

The solution to that was to make sure the 6502 is shut down in a deterministic way.

Remember that no-op for alignment?

It makes sure the program counter is in a known location before shutdown.

Being an intermittent problem buried under a mountain of parallelism, it took a while.

You can't step through a problem like this and there's only enough time to instrument one or two things for every test run.

And I missed a volatile so the compiler was optimizing away some of the instrumentation.

Then there was noise on the ground of my breadboard.

It took a while to find that first clue.

Now that the Picocomputer is mostly working, I'm starting to think about how to package it.

I know how to design parts for 3D printing, but a fully printed case is a last resort.

Something like an extrusion I could print end caps for would be a prime candidate though.

Everything I found that's nice will cost more than the electronics.

So I'm asking you, dear viewer, do you know of any inexpensive cases for a circuit board this big?

Would you even want a case?

Let me know in the comments.

That's all for this time.

I should have VGA working for the next video.

Be sure to subscribe so you don't miss it.

Thanks for watching.
