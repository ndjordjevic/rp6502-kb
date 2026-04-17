---
type: source
source_kind: youtube
video_id: yh26kSxFnvY
title: RP6502 Ep8 - VGA Graphics and the PIX bus
url: https://www.youtube.com/watch?v=yh26kSxFnvY
captions_file: yh26kSxFnvY-RP6502 Ep8 - VGA Graphics and the PIX bus.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep8 - VGA Graphics and the PIX bus

**Source**: [https://www.youtube.com/watch?v=yh26kSxFnvY](https://www.youtube.com/watch?v=yh26kSxFnvY)
**Video ID**: `yh26kSxFnvY`

---

Welcome back.

This time we're talking about graphics on the Picocomputer.

I'm going to explain the bus I created to make this possible and then there's a demo.

So stick around for some 8-bit fun.

But first, let's look at a viewer build.

This one comes from Sweden.

Ulf is using the VGA resistor network on that Pimoroni demo board, which makes it possible to build a Picocomputer on two breadboards.

I wouldn't buy the demo board just for the resistors, but if you already have one, this is a great idea.

Now bitmap graphics is certainly a big milestone, but there's another one I need to mention too.

I know every one of you has been anxiously awaiting documentation.

Not to read, of course, but for the satisfaction of tearing the tractor feed off your printouts.

While you're banging out that print job, we can talk about video and graphics.

If you've seen Doom running on the Raspberry Pi Pico you might be wondering why I need two Pi Picos to support one little old 6502.

After all, one Pi Pico can obviously do everything needed to play video games, right?

Well, that Doom demo isn't talking to a real 6502.

There aren't enough GPIO pins for both VGA and the 6502 bus.

I did start this project thinking I'd use one Pi Pico, but after making too many compromises I decided the second one I was already using for debugging would just become the video card.

The first Pi Pico would give up most of its GPIO to talk to the CPU.

The second Pi Pico would use most of its IO for 16-bit VGA.

Whatever IO I had left over could be used to make them talk to each other.

So that's the focus of this video.

How do we make these Pi Picos talk to each other and what will they say?

Since I control all sides of this, I get to make whatever I want.

The thing I want most is raw speed.

Video memory needs to read and write as fast as system memory.

I'm running the 6502 at a leisurely eight megahertz, so that's not an unreasonable ask.

A SPI bus should be able to handle this.

So let's add in my next requirements and see how SPI holds up.

I want multiple video cards.

No problem.

Each additional VGA card needs only one additional GPIO.

Which I've already said we don't have enough of.

And we'll have to look into impedance controls for extending the bus off the main board.

SPI is zero effort when it's just a couple of chips on the same board, but sending 50 or 100 megahertz down a ribbon cable to multiple devices will need some consideration.

Let's call that plan B and look for something else because I want the same electrical characteristics as the 6502.

Or less.

So nothing faster than the 6502 clock.

Let's look into making a custom bus.

I'll call it the Pico Information eXchange bus or the PIX bus.

If you've seen my other videos you've probably guessed I'll use programmable IO and DMA for this.

My second video explains the technique.

This time I'm going to talk about the design process because I have a lot more freedom to do things other than comply with a datasheet that's almost as old as me.

Since speed is paramount, let's figure out the bandwidth requirements.

Storing a register in an absolute memory location takes four clock cycles.

That's the fastest a 6502 can write any memory that isn't zero page or stack.

It's the fastest writes we'll ever need to deal with in a video system.

That's great because the problem is four times easier when dealing with one-fourth the bandwidth.

The more things we can eliminate or reduce like this, the easier it becomes to see a good solution.

Let's keep looking for more.

The 6502 is limited to eight megahertz at 3.3 volts.

So one byte every four clock cycles is 16 megabits per second.

We'll never sustain that, but we definitely need to handle bursts in case of unrolled loops.

For example, this loop to clear the screen runs several times faster if we unroll it to burst out eight bytes at a time.

That's just the data though.

We need to associate each byte with an address somehow.

I've run out of resources to do anything clever, so let's send a full 16-bit address with every 8-bit data value.

What was an 8-bit problem is now 24 bits.

That's the wrong direction, but we need it.

If we use the 6502 clock we can do a parallel bus of six wires.

Six bits times four clock cycles is the 24 bits we need.

Okay, that's a good start, but we still need framing.

And addressing multiple video cards.

We really have a use for a seventh wire.

That will give us everything.

Except I don't have seven GPIO pins to work with.

I don't even have six.

I have four.

I got hung up on this for a bit then I realized using both transitions of the clock doesn't change the electrical requirements.

I'm not sure why this needed a second thought.

It was some kind of brain fart.

Like forgetting your sunglasses are tipped up on your head.

Okay, so now we're using four wires to send 32 bits every four clock cycles using DDR.

Double Data Rate.

That I can work with.

We'll break the protocol down in a bit, but first I want to compare this solution to some other computers.

I'm familiar with Commodore, Apple and Atari computers.

All of these used shared memory.

The CPU and video chip use the same physical RAM.

These computers can update a value in video memory as fast as the 6502 can write.

So one byte every four cycles.

This is where my performance requirement came from.

Believe it or not, there's another 8-bit computer with a video bus to a 32-bit microcontroller.

The Agon Light connects its CPU to the video system over an extremely fast UART.

It would be irresponsible not to investigate something that's working in another design.

The Agon Light has their UART running at one megabit.

One megabit could be okay with some cleverness.

Since the CPU has to get involved with flow control, a few more clock cycles can be spent on making more efficient messages.

In some ways, that's how modern graphics cards work.

Okay, hold up.

Those classic 8-bit machines didn't work like this at all.

Flow control?

For graphics?

Look, I paid top dollar ($4) for these Raspberry Pis and I'm not going to let that money go to waste on a bunch of compromises.

PIX bus it is.

We're looking at four wires and a clock signal so far.

There's no need to send data back from the VGA system. 8-bit video systems never did that.

So this is pretty simple in that we don't need chip selects or read write signals or any other connection.

Now, how does this work on the wire?

We need to start by detecting which is the first clock cycle where we should begin capturing our bits.

Dedicating one of the four wires to framing would leave us with the 24 bits we need.

That seems like we're throwing away seven bits that I'd really like to use if possible.

Another approach takes advantage of the fact that the PIX bus will have plenty of idle time.

If we send a known pattern while idle, the framing can be detected.

Once the framing is in sync, it'll stay in sync.

A simple sync pattern is a one followed by seven zeros.

We can see that on all four PIX lines here.

However, only PIX0 is used for framing.

PIX1 to PIX3 of this first set of bits is the channel ID.

Sync is done on channel 7 because it's easy to see on test equipment.

The remaining 28 bits can be anything.

So 28 bits of payload and 4 bits for the media layer.

We've got everything I've asked for plus four extra bits.

You can see the framing clearly in this capture from a logic analyzer.

This shows idle frames on either side of a write.

This ten dollar logic analyzer has no problem decoding the data.

We can see the sync here.

This message is for channel 0, which is a write to shared RAM.

The next four bits aren't used on this channel.

These next eight bits are hex $FF, which is two white pixels.

The remaining 16 bits are the address.

So this message means write $FF to location $1D35.

Collecting up these 32 bits is done with a shift register.

The Pi Pico PIO system is fundamentally a bunch of programmable shift registers, so it's pretty easy to implement this protocol.

Unless the other PIO programs are larger than you remember and you have two instructions too many.

I eventually did figure it out.

Here's the transmitting program.

It pulls from a FIFO and loops over waiting for a clock change and shifting out the next four bits.

A very concise five instructions.

The receiving program does the same thing, but shifts the bits in of course.

There's two blocks of extra logic here though.

This part checks the channel ID and discards the channels we don't want.

And this part does the frame synchronization.

That's 14 instructions.

The PIO this runs on will use all 32 instructions and all four state machines.

The other PIO on this chip is also full.

If you gave me more PIO, I'd find a use for it too.

In addition to running out of PIO program space, there is some noise that took a while to track down.

About one in a thousand writes would fail.

I had no visibility into this problem for a while.

The solution was to raise the DMA priority above the CPU and make the PIX DMA channels higher priority than the video DMA.

That sounds pretty fragile, but it's really not unusual.

These features exist in microcontrollers because real-time applications really do need them.

We have a hard limit of 500 nanoseconds to process these PIX messages.

The VGA output is competing with the PIX bus resources because it also has real-time requirements.

That's a lot of moving parts needing sub- microsecond real-time.

Okay, so the rest of the PIX bus is a bunch of details like what each bit is for and channel assignments.

Header stuff you could read about in the documentation.

There's a link to the project in the description.

Let's do the demo now.

I quickly hacked in a 16 color full screen bitmap mode.

This is 320 by 180, which the Pico- computer can output at 720p to fill up a 16x9 monitor with square pixels.

It's only 16 colors because I'm going to plot a Mandelbrot set. 256 colors would take way too long.

Even 16 colors is slow so I'm going to speed it up.

This is a ton of 32-bit multiplication.

I wrote the program in C.

It didn't take very long.

Sure, I can make assembly code that runs a little faster, but it's exhausting when every little thing needs your full attention.

I just wanted a test program.

Being able to start exploring a problem in C and dropping to assembly only when you need to is exactly what you do with the latest x86 and Arm processors.

We didn't do this back in the day because it's not practical to compile on an 8-bit machine.

Even waiting for an assembly is painful.

But these days we can cross compile using a 64-bit machine running thousands of times faster.

That's the essence of the Picocomputer.

Not having to visit a thrift store for peripherals is nice, but being able to program like it's the 21st century is better.

So next time we're going to look at the C SDK and the binary interface.

We'll call kernel operations, poke video memory, and learn some tricks for working on very small CPUs.

Hit the subscribe button to make sure you don't miss it.

Tell your friends.

And for even more Picocomputer, you can join these excellent people supporting the project on Patreon.

Thanks for watching.
