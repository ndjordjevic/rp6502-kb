---
type: source
source_kind: youtube
video_id: wxV6x5BUMH4
title: RP6502 Ep3 - Writing to the Raspberry Pi Pico - More PIO and DMA
url: https://www.youtube.com/watch?v=wxV6x5BUMH4
captions_file: wxV6x5BUMH4-RP6502 Ep3 - Writing to the Raspberry Pi Pico - More PIO and DMA.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep3 - Writing to the Raspberry Pi Pico - More PIO and DMA

**Source**: [https://www.youtube.com/watch?v=wxV6x5BUMH4](https://www.youtube.com/watch?v=wxV6x5BUMH4)
**Video ID**: `wxV6x5BUMH4`

---

In this video we'll finish the work that lets the 6502 write to the Pi Pico.

We're also going to look at the glue logic and troubleshoot a hardware problem.

Today's tale begins with a tour of the breadboard.

This Pi Pico is for video but it's only running the debugger right now.

This one is what we're working on.

It does pretty much everything except video.

The Pi Pico connects to the 6502 like other interface adapters chips like the PIA, CIA, TIA, or VIA.

I needed a file name and RIA wasn't taken, so that's what I'm calling this connection.

The eight blue wires are the data bus and five white wires for the address bus.

There's four signal lines between the 6502 and Pi Pico: reset, clock, write enable, and chip select.

We got reset and clock working last time.

Write enable is just another direct connection, but chip select is something we have to compute.

The gray wires generate the chip select signals.

We're looking at that in the simulator later.

Let's talk about the 6522 first.

This is a Versatile Interface Adapter or VIA.

The 6502 is a microprocessor not a microcontroller.

The difference I want to emphasize is that it doesn't have general purpose IOs.

It also doesn't have any timers.

A lot of 6502 software expects timers that can trigger interrupts, so the Picocomputer will allow for an optional 6522.

In a vintage computer, the GPIO pins of a 6522 would be used for things like keyboards or disk drives, but since we get all that from the Pi Pico, all these pins will be available for your projects.

Those of you who experiment more with the hardware side are probably anxious to see what the logic chips do.

The Picocomputer will use clocks and power from the Pi Pico boards, but it still needs a few traditional gates.

The first NAND here is needed to synchronize RAM writes.

The 6502 updates the address bus at the same moment the read-write signal switches.

This circuit prevents write corruption during that transition.

The second NAND combines interrupt signals.

Both the Pi Pico RIA and 6522 VIA will generate interrupts.

You may have seen this as open collector logic on other systems, but the 6522 I'm using needs to be ORed.

The rest of the logic is address decoding.

Adding more than one device to the 6502 requires logic to select the right device at the right time.

The idea is simple.

Decode the 16-bit address lines into chip select lines.

I used this tool because it helped me visualize the chips needed.

You can work through this stuff in your head, but it's pretty easy to make a mistake.

The right side of the screen is a test harness designed to avoid those mistakes.

It lets me set an address to see which of three devices are selected.

Before I start testing addresses, let's talk about where everything is supposed to be and why I put it there.

The 6502 can address no more than 64 kilobytes of RAM.

If a full 64k was practical, that's what I'd do, but the 6522 VIA needs address space.

So does the Pi Pico.

And let's leave some room for expansion.

Turns out we don't need much of the 64k for interface chips.

Most require between 4 and 32 addresses, so reserving a full page of 256 bytes feels about right.

Deciding which page is easy.

The highest six addresses contain the 6502 interrupt and reset vectors.

We want the Pi Pico there so it can bootstrap the 6502.

Detecting that last page couldn't be easier.

The 7430 is an eight input NAND.

It decodes the eight highest address lines into an I/O request.

And yes, I picked that name because it works just like the I/O request of a Z80.

When there's no I/O request, RAM should be used.

So this is what we use to select RAM too.

Now we're only concerned with decoding the lower eight bits.

The Pi Pico RIA gets its 32 bytes located all the way up at $FFE0.

This is easy to do with just four gates.

We're using three chips for this logic.

The design was four chips for a while.

The last bit of optimization was to incorporate the address decoding logic built into the 6522.

Devices with multiple select lines have internal logic to combine them which we can take advantage of.

It'll be easier to see in the simulation.

This is on GitHub if you want to run it yourself.

I'll run through all the boundaries now.

I won't talk through the gates so pause and rewind if you want to study the logic on the left.

I'll describe the test on the right.

RAM starts at address $0000. $FE00 is the last page of RAM.

The Pi Pico Ria starts at $FFE0.

It continues up to $FFFF.

Now we can see how $FF00 selects the 6522 VIA.

Its two chip selects require this low and high state.

Sometimes you only use one, selecting whichever saves you an inverter, but using both is how we steal the extra gate that will decode a third state from the two chip selects.

You might be wondering why I wanted chip select logic working before making the Pi Pico writable.

To understand that, we need to look closer at the data bus.

If the 6502 is writing, it'll be driving the data bus with CMOS logic.

If it's reading, the data bus will be in a high impedance state so something else can drive the bus.

Only one chip at a time can drive the bus.

Knowing if you should drive the bus requires looking at both a chip select and the write enable signal.

If we build a truth table for the Pi Pico RIA, it looks like this.

These three states affect how I need to write the next PIO program.

While chip select isn't technically needed yet, I didn't want to rewrite the Pio program later to add it.

Up until now the Pi Pico always drove the bus.

We used PIO and DMA to move a value from Pi Pico RAM to the data bus.

Writing is exactly the same except it moves data the other direction, from the data bus to Pi Pico RAM.

This needs to be synchronized with control of the direction of the Pi Pico data bus based on the chip select and write enable signals.

Here's a Pio program that does all that.

This is on GitHub if you want to study it in detail.

Quite often the testing and instrumentation used when bringing up new hardware is more interesting than the programming, so let's look at that instead.

Here's what we're loading into the Pi Pico's 32 bytes of RAM.

It writes a single value then locks up the processor.

I have some debug code that lets me press F1 to reset the 6502.

If all goes well, we'll get a single write upon first boot and a write every time I press a reset.

To verify this, instead of hooking up the DMA I can temporarily intercept the FIFO and print it to the terminal.

Here's what it looks like when everything works.

This is much easier than using the logic analyzer.

I started at 4 MHz and didn't have any interesting problems so I programmed up the ability to fully adjust the 6502 clock.

The range ended up being from one kilohertz up to wherever it fails.

I then built a test to automatically run through a list of frequencies.

I hadn't yet tried for more than eight megahertz and this would make overclocking easy.

Nothing is ever easy. 7.7 MHz.

Are you kidding me?

The PIO program was certainly a lot more complex now, but it wasn't lacking resources and I was sure it wasn't broken.

Stopping so close to the target with 100 kHz Precision made me think it was hardware.

Of course, the newest hardware was the most suspect.

Troubleshooting was fast because bypassing the new chip select logic eliminated the problem.

Let's look at it on the oscilloscope.

The yellow trace is the 6502 clock.

The blue Trace is the chip select for the Pi Pico RIA.

It looks like chip select is ready before the clock.

For a moment, in my mind at least, time travel was possible.

Then I saw it's taking half a clock cycle for address changes to propagate through the glue logic.

Let's switch to measuring the glue logic directly.

I just moved the clock probe to an address line.

Yes that's 50 nanoseconds.

Looking at the logic we can see this signal path is four gates deep.

The logic chips I bought said they were about 15 nanoseconds.

Times four.

Yep, that checks out.

There's a couple ways to fix this.

Either you figure out how to deal with the speed you have or you make it faster.

Half a clock cycle is unreasonably slow so let's consider making it faster first.

We could speed things up with programmable logic.

Everything I know about requires programming hardware and we don't want that.

It also seems a bit extreme.

Going at this head-on would simply be buying faster chips.

Another way of saying this is we need to switch to a different logic family.

Manufacturers jam some letters between the numbers to indicate different logic families.

For example, 74LS00 is TTL and 74HC00 is CMOS.

The Picocomputer is CMOS so I bought HC chips.

I also bought some AC chips.

These are CMOS too, but faster.

Unfortunately, a faster 7430 is only available for surface mounting.

Still, we can upgrade 75 percent of the signal path.

After a simple swap of two chips we're running at eight megahertz just fine.

You can see on the scope that the 50 nanosecond delay from before is down to 35 nanoseconds.

In fact we're hitting 9 MHz.

I'm very happy with this outcome.

Requiring AC chips for 8 MHz is reasonable and support for slower HC chips is easy enough by defaulting to 4 MHz.

The Picocomputer can self-test and let 6502 software know if faster speeds are available.

There's two more things to nail down before I make a circuit board.

The RAM chip will be running code next time and VGA after that.

If this is your kind of thing, hit the subscribe button.

Thanks for watching.
