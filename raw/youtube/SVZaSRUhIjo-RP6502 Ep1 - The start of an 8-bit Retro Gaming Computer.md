---
type: source
source_kind: youtube
video_id: SVZaSRUhIjo
title: RP6502 Ep1 - The start of an 8-bit Retro Gaming Computer
url: https://www.youtube.com/watch?v=SVZaSRUhIjo
captions_file: SVZaSRUhIjo-RP6502 Ep1 - The start of an 8-bit Retro Gaming Computer.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep1 - The start of an 8-bit Retro Gaming Computer

**Source**: [https://www.youtube.com/watch?v=SVZaSRUhIjo](https://www.youtube.com/watch?v=SVZaSRUhIjo)
**Video ID**: `SVZaSRUhIjo`

---

This is a Raspberry Pi Pico.

It's not like the other Raspberry Pis.

It doesn't run Linux or any desktop operating system, but it does have OTG USB and can generate a clean VGA signal.

So this $4 dollar microcontroller board is only a few parts away from being a full computer comparable with something from the 1980s.

All you do is plug a USB hub in here and wire up a VGA connector with some resistor dividers to the GPIOs.

I thought, what if you attach this to a retro processor like the 6502.

With the Pi Pico in the design we no longer need a clock generator, reset timers, address logic, gpio chips, or roms.

We don't need any chip programmers either.

The Pi Pico is programmed with UF2 which is simply copying a file over a USB cable.

You don't even need special software, just the copy command from your operating system.

I suppose a case could be made that we don't need the 6502 either, but then we wouldn't have a 6502 expansion bus.

I eventually got the design down to a Pi Pico, 6502, 64K of RAM and 12 glue chips.

This is for a retro computer with VGA video, PWM audio, expansion slots, and support for USB keyboards, mice, joysticks, and mass storage devices.

You can see everything on the breadboard here.

These are all through-hole parts but available in surface mount packaging as well.

There's two Pi Picos here.

The second one is acting as a debug probe and console port but isn't strictly necessary.

It's connected to my development system over USB, which also powers everything.

The VGA cable is actually the end of a VGA to HDMI converter.

The Pi Pico is able to provide accurate VGA timings so HDMI output is perfect with no added frame buffer lag, even on cheap adapters.

But the real gem here is the USB host controller.

No more grungy PS/2 keyboards and clumsy SD cards, just plug ordinary USB devices straight into this hub.

There's nothing special about the hub but you might need an adapter cable to fit it to the Pi Pico.

With USB and VGA wired up I can write a lot of the Pi Pico software, so i did.

Computers of this era typically had software called a monitor, not to be confused with the monitor of your terminal which was a cathode ray tube.

Monitors replaced panels of blinking lights and switches as minicomputers transitioned from core memory to the RAM and ROM we used today.

Typically, the monitor runs on the main CPU, but the Picocomputer has its monitor on the DMA controller.

The serial port on the Pi Pico gives us access to the monitor at all times.

Here it is in Minicom.

The primary function of a monitor is to inspect and modify memory so having it functional while bringing up the DMA controller should be handy.

Typing in an address will show the memory contents.

Well, it will later.

Right now let's test some USB devices.

Here my keyboard is recognized.

For some reason it indicates it can send mouse reports too, but i've never seen it do so.

Anyhow...

Typing on the keyboard works just fine.

Okay.

Mouse.

For some reason this mouse indicates it can send keyboard reports, but i've never seen it do so.

I'm just putting events to standard out for testing.

Left click, right click, and movement events.

Looks good.

Here's a PlayStation 4 controller.

Yep, looks great.

The analog data is all 8-bit so looks like the mouse reports are going to be very easy for the 6502 to work with.

This is a USB flash drive.

I was able to see an SD card in a card reader too.

I haven't tried reading files yet but I'm confident it will work.

Now, let's look at VGA output.

What you're looking at here is a terminal emulator running on the Pi Pico.

So there's two ways to access the monitor.

Over the serial port or with the USB keyboard and VGA display.

I think this is the first color ANSI terminal emulator for the Pi Pico.

This isn't the primary input and output for the main computer though.

It's just a conveniently built in terminal.

Pressing scroll lock on the keyboard switches the terminal on and off.

Turning it off we can see a mock-up of the low-res 40 column mode with the Commodore PETSCII font.

Of course, the final video system will have graphics, sprites, and parallax scrolling.

But a character mode is sufficient to keep things visually interesting during this part of development.

You've seen both graphics resolutions, a hi-res 640x480 and the lo-res 320x240.

Either of these can be letterboxed to 16x9 and output 720p.

It doesn't matter if you have an IBM 8513 from 1987 or modern widescreen LCD, the Picocomputer output is very easy to work with.

However, it does not and will not support old televisions.

To be clear, it could, but that's a lot of work I won't be doing because there's already plenty of retro video hardware for the 6502 that supports televisions.

That's what the expansion slots are for.

Let's bring up the monitor and graphics system simultaneously for the next bit.

This is easy enough since the monitor is always available on the serial port.

Video memory has its own 64K separate from the 6502 64K of memory.

The DMA controller will be able to move data between USB storage, video memory, and 6502 memory.

Although DMA is not working yet, we can manually modify video memory with the monitor.

I've worked out an address and data for a short message.

Hello world.

Now imagine using the same technique to load a 6502 program into RAM.

That's all for now.

Some of my design notes are included in the github repository, link in the description.

I'll make videos explaining each section as I bring it up.

If you want to learn about the design and operation or see how I deal with the unexpected, hit that subscribe button.

Thanks for watching!
