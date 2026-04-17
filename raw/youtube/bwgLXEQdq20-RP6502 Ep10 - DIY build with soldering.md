---
type: source
source_kind: youtube
video_id: bwgLXEQdq20
title: RP6502 Ep10 - DIY build with soldering
url: https://www.youtube.com/watch?v=bwgLXEQdq20
captions_file: bwgLXEQdq20-RP6502 Ep10 - DIY build with soldering.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep10 - DIY build with soldering

**Source**: [https://www.youtube.com/watch?v=bwgLXEQdq20](https://www.youtube.com/watch?v=bwgLXEQdq20)
**Video ID**: `bwgLXEQdq20`

---

Hello, retro computer enthusiasts.

Welcome to your expensive hobby.

I remember paying $50 a few years ago for some classic Commodore computers and now they sell for hundreds.

I also remember the Commander X16 was supposed to be $50 and now it's 500 dollars.

It could be worse.

There could be a monthly service charge.

But seriously, I wanted to see what would happen if different choices were made so I spent the past year designing my own 6502 computer.

Many of you have seen the Picocomputer in prototype form.

One of the best features is that you don't lose any functionality on a breadboard.

It'll even run at the full eight megahertz without bypass capacitors.

The video and audio is a bit noisy without the caps, but it works.

Four other people have built Picocomputers as well.

These are photos from the forums.

But I'm guessing you clicked on the thumbnail to see the circuit board, so let me show you how easy it is to assemble the project on a circuit board.

The first thing we need to do is order the parts.

Go to the documentation and grab the latest CSV file.

Now go to mouser.com and upload it to a shopping cart.

Along the way it'll ask you what each column means.

The quantity and Mouser part number is all that's required.

If the heading row is interpreted as data, just delete it.

Now we have everything in a shopping cart.

Today it's $59.51 plus shipping for all the parts except the circuit board.

I've got my order unpacked and organized here.

You'll need basic tools like eye protection, a soldering iron, wire cutters, and a multimeter.

I'm not using magnification, extra flux, or work holder, but normally I would.

I wanted to show that you don't need any fancy tools.

You can solder the parts in any order you like, but doing things in order of height is easiest for most people.

The axial parts are the shortest, so I start with those.

These are 0.1 microfarad axial capacitors.

If you look on the back of the board, the value of every part is silkscreened.

There's no step-by-step or checklist, just solder everything to the board according to the silkscreen.

If there's still holes when you're done, then you missed a part.

You've probably noticed the board is marked Founders Edition.

This was a surprise for my patrons.

Those are the folks who sponsored this video.

Thank You.

Next up are the resistors.

This longer row is the video circuit, the shorter row is the audio circuit.

I do this in stages since loading too many resistors at once makes it difficult to navigate the iron around the leads.

The next thing I do is the sockets.

Pay attention to the orientation.

The notch on the socket must match the notch on the silkscreen.

Don't install the ICs yet, just the sockets.

The sockets and ICs are the only parts you can accidentally install backwards, so be careful.

See, that one's backwards.

The Pi Pico sockets are a little different.

They come in two parts instead of one.

To make sure they're perpendicular to the board, I solder one pin and straighten it by eye before doing the other pins.

I couldn't find three pin sockets at Mouser, so take the extra 20 pin socket and cut it down with your wire cutters.

Don't forget eye protection.

Next, I do the connectors and button.

And finally, the 47 microfarad capacitors.

These are not electrolytic and not polarized.

I do them last so they don't get bent over while I'm working on everything else.

The Pi Picos need header pins.

I push them into the sockets for alignment and quickly solder a few pins on each side.

You have to be quick here or you'll melt the sockets.

I have a sacrificial breadboard I normally use, but I'm showing this technique so you don't have to buy anything extra.

Once a few pins are secure, you can remove the Pi Pico and finish soldering the remaining pins.

Now we'll check for obvious problems.

Make sure none of the ICs or Pi Picos are installed.

Set your multimeter to ohms and test that none of the capacitors are shorted.

C9 to C12 are part of the audio circuit, so it's normal for those to have low resistance.

But, they must not be shorted.

If you find a short, clean the flux and go find it.

Now, test all of the resistors.

All of them will measure what the silkscreen says.

Once this is done, it's time to bring up the board.

We're doing this in three parts, so don't install the ICs yet.

Part one is the Pi Pico we're using for VGA.

Make sure the firmware is loaded before you install it in the socket.

Installing the firmware on the Pi Pico is literally pushing a button and copying a file.

Hold this boot select button while plugging it into any computer.

The Pi Pico will look like a disk drive to the computer.

Copy the VGA version of the UF2 file you downloaded to the Pi Pico and you're done when the LED comes on.

Now, unplug it from your computer and install it on the main board.

If you want a power switch, you can get one that looks like this.

The Picocomputer uses about half a watt, so it can be powered from just about anything.

Use a USB power supply for a standalone Picocomputer or plug it into your big computer if you want access to the serial console over USB.

VGA can be converted to HDMI with one of these inexpensive adapters.

The VGA Jack will deliver power to the adapter.

This one uses a quarter watt, so we're still well under one watt in total.

At this point you should have working video.

A blinking cursor means success.

If not, you might have a bad Pi Pico or bad soldering.

Now on to part two.

The other Pi Pico is the interface adapter to the 6502.

Load its firmware the same as you did with the Pi Pico VGA, but make sure you use the file named RIA instead.

And stick it on the board.

The USB on this Pi Pico is programmed to accept a hub.

You'll need an OTG adapter cable to use a normal hub, or a hub built specifically for OTG.

Of course, you should turn it off when you install the parts.

Get yourself an ordinary USB keyboard and plug that in too.

Power up the Picocomputer and it should give you a startup message.

There it is.

The keyboard should work too.

You can browse around the help if you like.

Trying to access 6502 memory will fail with a timeout so there isn't much you can do without the rest of the parts.

Part three is the rest of the parts.

You'll need to straighten the pins on the ICs before they fit in the sockets.

A lot of people just push them against a table surface, but I have this pin straightener gizmo that's a lot less stressful for those of us with sausages at the ends of our arms.

Make sure you don't install them backwards.

There's a notch that will match the sockets which will match the silkscreen on the board.

I'm going to remember to turn it off this time.

Now let's power it up.

Reading RAM works.

Yay.

Let's write to RAM.

Excellent.

If you get a timeout or verify error, then you have bad soldering or a bad chip.

That's everything.

Clean the board and stick rubber feet on the bottom, or stick it in a case.

It's up to you.

The Pi Pico defaults to running the 6502 at four megahertz.

If you bought the correct parts, it'll run at eight megahertz.

The command SET PHI2 8000 is what we want.

This is saved to the Pi Pico EEPROM, so there's no dip switches on a Picocomputer.

Now that we're running at full speed, let's try a program from disk.

There's no SD card slot because we have USB.

Okay, the status command shows I have a drive mounted.

We can see the files.

Okay, LOAD ADVENT4.

There we go.

This program was written on a minicomputer, then ported to run on microcomputers, and now it's running on a Picocomputer.

For more information, there's links in the description, including a playlist going back to the beginning of development.

I don't have any way of selling things right now, but if there's enough interest I can make something happen.

Sign up on Patreon or Twitter for announcements.

Thank you for watching.
