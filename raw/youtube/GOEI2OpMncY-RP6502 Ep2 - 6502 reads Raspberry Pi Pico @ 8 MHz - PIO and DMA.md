---
type: source
source_kind: youtube
video_id: GOEI2OpMncY
title: RP6502 Ep2 - 6502 reads Raspberry Pi Pico @ 8 MHz - PIO and DMA
url: https://www.youtube.com/watch?v=GOEI2OpMncY
captions_file: GOEI2OpMncY-RP6502 Ep2 - 6502 reads Raspberry Pi Pico @ 8 MHz - PIO and DMA.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep2 - 6502 reads Raspberry Pi Pico @ 8 MHz - PIO and DMA

**Source**: [https://www.youtube.com/watch?v=GOEI2OpMncY](https://www.youtube.com/watch?v=GOEI2OpMncY)
**Video ID**: `GOEI2OpMncY`

---

Welcome to the second video in the Picocomputer R&amp;D series.

We're hooking up the 6502 this time.

For some historical context, Commodore and Apple ran their 6502s around 1 MHz, the BBC Micro ran at 2 MHz and the old NMOS chips peaked around 3 MHz.

I'm using new CMOS stock which is specced at 8 MHz in this design.

Stick around to see how I configured the Pi Pico for an 8 MHz 6502 bus.

In the previous video, I had a design that allowed the Pi Pico direct access to 6502 RAM.

This is what the parts for that look like on a breadboard.

The USB port on the main Pi Pico is in host mode so it can support keyboards and storage devices.

The other pi pico is in usb device mode so it can plug into my development system for debugging.

It was never my intention to have two Pi Picos in the final design, but this configuration proved so useful that I wanted to see what would happen if I went all in on a dual Pi Pico design.

Here it is.

Less parts, more RAM, cheaper, faster, and with better video and sound.

I'd also like to point out there are still no hidden costs here.

No PS/2 keyboards or other things you can only buy on a volatile used market.

No programming hardware you'll use only once and retire.

Not even an RS-232 serial cable.

Let's begin exploring the design by looking at the memory map.

The 6502 doesn't have a separate bus for I/O devices, so we only need to talk about one address space.

There's also no memory manager, which is why we spend so much more time talking about where everything is compared to modern systems.

These memory locations are special for the 6502.

We can ignore the two interrupt vectors, but the reset vector is required if you want a program to run after the 6502 is initialized.

Usually there's ROM up there because doing anything else would be complicated.

Here's the memory map for the Picocomputer.

No ROM.

It's all RAM with the last page of 256 bytes allocated for the Pi Pico and other hardware.

The Pi Pico occupies the address space which includes the reset and interrupt vectors.

The Pi Pico will simply look like 32 bytes of RAM.

The vectors take up six bytes leaving us with 26 bytes for I/O operations.

Here's how we break from the traditional ROM design.

Imagine immediately after reset a small program runs in those 26 bytes.

I worked it out and only 10 are needed for a bootloader.

We can use that to load the entire 64K of RAM and continue execution there.

We're not hooking up RAM yet so the goal right now is only to run code in these 32 bytes.

Now that we have a plan for our test program, let's see how to get the processor started.

The datasheet section about the reset pin describes the startup sequence.

It says the RESB signal must be held low for at least two clock cycles.

OK, easy enough with the GPIO pin from the Pi Pico.

This leads us to the next requirement, the clock.

The clock pin is labeled PHI2.

Phase 2 input.

Again, GPIO from the Pi Pico makes this easy.

The 6502 reset will not be a physical button on this design, however I'd like it to be one for this test.

Also, the 6502 can single step its clock, so I want another button there too.

These buttons really should be debounced.

Fortunately, we already have a whole tray of debounced buttons ready to go - a USB keyboard.

I set it up so pressing F1 will call a function to perform a reset sequence with the two required clock pulses and pressing F2 cycles the clock once.

This isn't production code, so blocking with sleeps is fine here.

Let's upload this to the board and scope it to make sure my buttons work as expected.

The software delays are one millisecond, so I'll use the same time division on the scope.

Pressing the clock button shows a clock pulse.

Pressing reset gives us the expected output as well.

Now the fun part; the data and address buses.

You've probably seen someone bitbang the 6502.

That's a good experiment to teach software developers about hardware signals but you rarely see this outside the classroom.

The reason is that many microcontrollers let you program the GPIOs, so instead of using 100% of a cpu to meet a hard real-time requirement, I was able to use a fraction of the DMA and PIO systems and none of the CPU.

Some devices from other vendors even come with programmable logic you can configure with a hardware definition language.

But there's a cost.

The bitbang solution is like 10 lines of easy code.

That's because high-level languages for general purpose CPUs keep the problem towards the human side.

The DMA and PIO we're about to program will perform operations similar to a single step of microcode, which is one level lower than CPU machine code.

If I skip over something you find interesting, a link to the GitHub project is in the description.

The first thing to look at is the 32 bytes assigned for the registers.

I forced it into an unused block of RAM that it wouldn't have to share with anything else.

We need to look at another file now.

This file contains a PIO program for the data and address pins.

The IN and OUT instructions read the address bus and write the data bus.

The wrap directives are a loop.

The data moves over FIFOs, which we'll get back to in a bit.

What requires a little explanation is the PULL and MOV instructions.

When initialized, we're going to be sent the base address of the registers.

We save that and use it to construct a full 32-bit address with the lower five bits coming from the GPIO pins.

We'll have to do this assembly eventually, but here it happens on the same clock cycle that we read the 6502 address bus.

Now back to the C file.

Those PIO programs are compiled into headers by the make system.

They still need to be loaded and run by the Pi Pico CPU.

That's what all this is.

If you look at the function names, it's mostly pin assignments.

The one interesting bit is this PUT at the bottom where we pass it the base address of the registers.

So that's how you start a pio program.

At this point it will be running.

Even if both CPUs halted, the PIOs would keep running.

But they are only one side of the FIFOs.

The other side connects to DMA.

This is where the magic happens.

Here I begin by grabbing two DMA channels.

Because DMA doesn't have an instruction language, making a loop is done by having one channel trigger another then back again.

This DMA channel listed first is for the data, but it'll make more sense if we look at the address DMA first.

Like the PIO setup, it's mostly boilerplate.

The two most important values are these here, the destination and source address.

The source is the PIO FIFO.

Remember from earlier that the PIO program was building a complete RAM address from the base register address and the GPIO pins.

The destination is the data DMA's source address.

So we're changing the data dma registers before we trigger it to run.

Going back to the data DMA we can see its destination is the PIO FIFO, which is how we get output to the data bus, and the source is register zero.

But since the address DMA is changing this, it will be updated to the actual register requested by the 6502.

The circle is complete now.

Everything is running.

Even if both CPUs halt, all this keeps running.

Let's recap. 1: the pio builds a register address from the in pins. 2: the PIO pushes this address to the FIFO. 3: the address DMA will pull the address from the FIFO. 4: the address DMA writes this address to the data DMA. 5: the data DMA reads the value for this register's address. 6: the data DMA pushes that value to the FIFO. 7: the PIO will pull the data from the FIFO. 8: it will write the data to the output pins and then we repeat.

Now that we have something that acts like an asynchronous ROM, let's put a program on it.

First, we fill memory with NOPs.

Then we build the smallest possible program that's useful for testing, a loop.

At location FFFB, I put an instruction to jump to location FFFB.

This is useful because any glitch will cause the loop to exit and NOPs to execute.

I'll show you this later.

Remember the reset vector at FFFC and D?

A side effect of having the JMP at this particular location is that it also sets the reset vector.

Before connecting the 6502, let's measure access time.

Hooking the clock up to an address line simulates a request from the address bus.

Now we can use an oscilloscope to measure the time between that address change and the data output change.

Time divisions here are 50 nanoseconds so we're well under the 500 nanoseconds needed to run at 1 MHz.

I spent quite a bit of time with the setup like this.

I felt like I could improve the performance before I hooked up the 6502.

It turns out I couldn't, so let's hook it up now.

The data sheet has a list of pins that need to be high when unused.

After that, the only connections needed are the things we have implemented on the Pi Pico: reset, clock, address, and data.

This next bit of testing is where I use the reset and clock buttons along with an address bus watcher that I built into the Pi Pico.

This is viewed with the serial monitor.

I began with a reset.

Now seven clock pulses.

Ah-ha, there's FC.

That's the reset vector.

Now we're two clock cycles away from knowing if the read worked.

Here's FD and FD.

Now every three presses of the clock button will execute one iteration of the infinite jump loop, like so.

This tool was short-lived because I was now ready to let the 6502 clock go astable.

The console output would not be able to keep up.

For the remainder of development, I added a logic analyzer.

A third scope channel would have been useful since I ended up moving the leads around a dozen times.

Two will get the job done eventually though.

Let's look at how I used the logic analyzer.

The three bytes of the JMP loop only change three address lines.

Any glitch will cause the CPU to leave this loop, which will easily be seen on the other address lines.

Here's the system reset at 1 MHZ.

Along the bottom you can see the address decoded.

Once the loop is entered at FB FC and FD, only the lowest three address lines are changing, exactly as expected.

Capturing several seconds looks like this.

The software won't lose the signal in zoom.

Any glitch will be seen.

For example, I can introduce an intermittent defect.

Usually the failure is far more dramatic.

You can see here we're not fast enough for 4 MHz yet.

But now with a functioning 6502 I can experiment with an idea I had for improving performance.

Right now, the Pi Pico isn't synchronized with the 6502.

What if it was?

The 6502 sends a new address every time the clock goes low.

We can wait for that in the PIO program.

But that won't quite work.

Looking on the scope we can see the 6502 address bus lags slightly behind the clock generated by the Pi Pico.

This is expected.

I tried to find the timing in the datasheet.

Address setup time seems like what we're looking for except the values are complete nonsense for a static CMOS device.

Sometimes you have to use experience instead of the datasheet.

A few tests later I have the timing data I needed from the oscilloscope.

Here we add a PIO instruction to wait until the clock goes low.

The 2 in brackets is a delay of 2 PIO clock cycles.

Experiments with changing this delay gave predictable results.

Now I had it running at 4 MHz.

Access time is well under the required 145 nanoseconds but it's nowhere near the 70 nanoseconds needed for 8 MHz.

Now, if only I could double the clock speed of the Pi Pico.

Which I did.

Here's the 6502 running at 8 MHz.

All of the Picocomputer's major systems have now been tested.

Now, we just need to bring it all together.

But not today.

Making these 32 bytes writable will be in the next video.

Hit that subscribe button and I'll see you then.

Thanks for watching.
