---
type: source
source_kind: youtube
video_id: s6BZ5MKbLEk
title: RP6502 Ep15 - Asset Management and More Graphics
url: https://www.youtube.com/watch?v=s6BZ5MKbLEk
captions_file: s6BZ5MKbLEk-RP6502 Ep15 - Asset Management and More Graphics.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep15 - Asset Management and More Graphics

**Source**: [https://www.youtube.com/watch?v=s6BZ5MKbLEk](https://www.youtube.com/watch?v=s6BZ5MKbLEk)
**Video ID**: `s6BZ5MKbLEk`

---

Let's talk about asset management.

Sounds exciting, right?

Okay, I hear you.

Let's start with some new demos.

First up is this case by Tony VR.

He shared three different versions.

I printed the one that integrates a USB hub.

For comparison, here's the mess I use for primary development.

Simple acrylic sheets are highly functional, but this custom case certainly looks a lot better.

I put a link in the description for the files.

But that's not all.

He also made Hunter Adams' Graphics Library work on all bit depths of the bitmap mode.

I'll let it play through.

I've been busy too.

The graphics system is complete.

There are new modes for characters, tiles, and sprites.

This classic demo is only one quarter of the screen, but it looks infinitely random when tiled with a little bit of motion.

Sprites are working well too.

Here we see 24 sprites bouncing around.

These are 128x128px in size.

You can have more sprites if they're smaller.

One of the interesting features of this sprite system is the ability to apply affine transformations.

This means scaling and rotation effects are very easy.

Here's an example of 10 Sprites bouncing around while changing size.

With all the graphics modes complete, I was able to move on to building systems to help bring graphics assets into your applications.

I'm going to show you the workflow I use.

Let's start by reviewing the memory layout. the reference design Picocomputer has 64k of system RAM and 64k of extended RAM.

Everything for video has to be in extended RAM.

There's no ROM in the traditional sense. this is all RAM.

To run a 6502 program it has to be in system RAM because there's no ROM attached to the 6502.

Well, there's no ROM hardware, but there are virtual ROMs which we can load and run.

These virtual ROMs are files that need to be created.

That's what we're going to explore.

Let's begin with a blank project.

When you stamp out a copy of the template project, you get a Hello World program like this.

To run the program, we connect the Picocomputer to our development machine with a USB cable and press control-shift-B in Visual Studio Code.

Looking at the Picocomputer display, we see a series of binary commands have been sent.

This is your development system sending data directly to the Picocomputer's RAM.

What happened is the program was compiled, packaged into a ROM file, then sent to the Picocomputer over USB, and a reset issued to start the program.

Think of ROM files as data to be copied to RAM when the system boots.

I've seen several people having trouble loading random files they've copied off their development system.

That doesn't work.

You can only load correctly formatted ROM files.

By default, they have an RP6502 extension, but that's not required.

Let's look at how we create a ROM file.

This is already set up for you in the template project.

Looking in CMakeLists.txt we see rp6502_executable().

This tells the build system We want to create a Picocomputer ROM file for the target.

Here in the build folder we can find the generated ROM as hello.rp6502.

Anytime the target is built, this ROM file is also built as the final step.

Remember before when I pressed control-shift-B to run hello world?

Let me show you where that happens.

Here in the VSCode .tasks file for the project, we have a build task that runs a script called rp6502.py.

This is a python script that does everything with ROMs including creating uploading and running them.

Advanced programmers, or someone using a different compiler, can run this script directly.

For those of us taking the path of least resistance, everything can be done from cmake.

At the very beginning I said this video would be about asset management.

So what's an asset?

Well, everything that goes in your application is an asset.

The code, the graphics, sounds, level design, and any other data.

We've seen how code gets packaged into a ROM file.

That was done by the aforementioned rp6502_executable in cmake.

But what about other assets like sprites and fonts?

One option is to make them an array in your program code and copy it to extended memory.

This is fine for very small amounts of data, but it uses system memory that could be better spent on application logic.

Another option is to load assets from disk.

This is an excellent option for anything that won't fit into 128k.

Disk access is fast and efficient, but you'll have to build your own tools for this.

If you can fit everything into 128k, the best option is to package your assets into a single ROM file.

Let's look at how to do this by starting work on a game.

I found these assets for flappy bird on GitHub.

I then used the Picocomputer documentation to get them converted into a suitable binary format.

The assets I started with were pixel doubled and compressed, so I scaled them down and decompressed them with this python script.

This part of the workflow is bespoke.

You'll have to figure it out for yourself.

Graphics conversion is an unavoidable yet key element in game development.

The Picocomputer graphics system supports dozens of data formats, so you'll have to decide which ones are appropriate and do some converting.

If you're not comfortable with python, you can, of course, use whatever image conversion tools you like.

Once you have your images converted, things get a lot easier because the tools I built for asset management are controlled with simple cmake commands.

Let's start with the sprite I picked.

First we need to package it up as its own ROM.

The rp6502_asset command does this.

It needs a target name, address, and filename.

The five-digit address should stand out here.

That leading one indicates extended RAM.

We're making a ROM file that loads into extended Ram because that's where data needs to be for the graphics system to use it.

After building, we can see this ROM file show up in the build folder.

But it's not part of the executable yet.

We still have to add it to the executable in cmake.

To do this, add additional ROMs to the rp6502_executable command.

I'll add the sprite.

Now, let's send this this to the Picocomputer.

You can see in the binary commands that we're now loading something into extended RAM.

What's that?

You want more proof?

Okay, let's change our hello world program to show the sprite instead of a greeting.

We start with canvas 1, which is 320 by 240.

This part is the sprite's config.

It defines the sprites location in memory and on the canvas.

Here we program the VGA to show the sprite.

And finally, an infinite loop.

The program will immediately exit and turn off graphics mode if we don't have this.

Let's go.

All righty.

It's a birdie.

The thing to note is that there's no code to copy the Sprite data.

It's already where it needs to be when the program starts.

Now let's add another asset.

I picked out a background image which needs a custom pallet.

That means there's two asset files for this.

The pallete and the image data.

We follow the same pattern in CMakeLists.txt.

Create ROMs from these assets with rp6502_asset.

Then add those ROMs to the main executable ROM with rp6502executable.

The C code is just like the sprite code except we use bitmap mode.

This is looking a lot better.

Let's give it a bit of motion.

Okay, now we're flying.

There's one more type of asset we can package into ROMs.

Help information.

Begin by creating a new text file.

This first line has to be shebang #!RP6502 After that, you can include lines of ASCII help text.

Each line must begin with a hash and a space.

Let's write up a little blurb about our program.

Okay what we've made here is literally the ROM format. it does not need to be packaged with the RP 6502 asset command.

The only thing we need to do is link it to the executable ROM.

We can head over to CMakeLists.txt and stick it directly in the rp6502_executable section.

Because this isn't in the build folder, we need to prefix it with CMAKE_CURRENT_LIST_DIR.

Now let's build this and copy the ROM file to the Picocomputer's USB drive.

We can use the RP6502 python tool to do this without unplugging anything.

This upload command is a great way to upload file assets too.

It will upload any file of any kind.

Now that the file is on the Picocomputer, we can ask it for its info.

There it is.

That's everything you can put in a ROM file and that's everything for this video.

I'm sure someone else will write a full flappy bird.

I need to work on adding the next features.

Thanks for watching.

Be sure to like And subscribe so you don't miss the next exciting episode.

Goodbye.
