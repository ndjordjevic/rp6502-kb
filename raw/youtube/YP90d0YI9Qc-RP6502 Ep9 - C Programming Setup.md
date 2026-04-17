---
type: source
source_kind: youtube
video_id: YP90d0YI9Qc
title: RP6502 Ep9 - C Programming Setup
url: https://www.youtube.com/watch?v=YP90d0YI9Qc
captions_file: YP90d0YI9Qc-RP6502 Ep9 - C Programming Setup.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep9 - C Programming Setup

**Source**: [https://www.youtube.com/watch?v=YP90d0YI9Qc](https://www.youtube.com/watch?v=YP90d0YI9Qc)
**Video ID**: `YP90d0YI9Qc`

---

When I started developing the Picocomputer, I had two things in mind above all else.

How will people build it, and how will it be programmed?

I think the hardware design is an overwhelming success since a breadboard build is fully functional.

Now it's time to talk about how to program a Picocomputer.

Being a 6502 system, there's a lot of options.

I don't have infinite time, so I focused on one: the C programming language.

Specifically, the CC65 compiler, which includes a macro assembler.

In this video I'll show you how to get started with the development environment.

We'll write a simple program in C and take a look at the SDK.

Let's get started with this Picocomputer on a breadboard.

You'll want a USB hub on the Pi Pico RIA here.

That's for your keyboard and flash drive and so on.

The other USB port on the Pi Pico VGA can be used for power if you want a standalone Picocomputer.

But it's also a USB device that can be connected to a development system.

That's how it'll be used for this demonstration.

I'll also have the VGA output being captured so I can show you what would normally be on a monitor.

New projects should begin with this scaffolding on GitHub.

From the name, you can guess it requires Visual Studio Code.

It also requires several tools that are trivial to install on Linux, but not so much on Windows and MacOS.

Until someone documents the procedures for other operating systems, it's going to be easiest to get it running on Linux.

But you don't need a Linux desktop.

VSCode remote development and USB IP forwarding provide a lot of flexibility for how you work.

I'm not covering those details in this video.

There's too many combinations.

But now that you know it exists you should be able to find the resources you need.

There's no shortage of documentation since millions of developers use VSCode this way.

After you have VSCode installed to your liking, we can focus on the things unique to the Picocomputer.

This template repository on GitHub is where you begin new projects.

The readme has two commands for Linux which installs all the software.

Just copy pasta and you should be good to go.

Next, you need to download the scaffolding for your new project.

Don't clone or fork this repository, select use this template then create a new repository.

Give it a name then you'll have a nice clean repository of your own with a single commit.

This new repository is what you should clone to your development system.

Going back to the README, you'll see a reminder about the SDK being in a submodule.

Just run these three commands, substituting the name you picked earlier.

Everything you need to do from the command line is done now.

Picocomputer development is fully integrated into VSCode so let's go there now.

VSCode is going to offer up some questions the first time you open a new project.

Exactly what questions it asks depends on how it's been used in the past.

The readme will guide you if you need it, but there's really only one thing you need to know.

Say yes or choose the obvious default to everything except questions about IntelliSense.

Choose don't allow, no, or don't ask again for any prompt about IntelliSense.

The scaffolding has hacks to make CC65 work with IntelliSense and we don't want to overwrite those.

Now, if you run the build task with CTRL SHIFT B, VSCode will build the example, upload it to the Picocomputer, and execute it.

Sure, there's faster ways to hello world, but those extra steps we did brought up a fully integrated development environment with revision control.

Now let's go exploring.

Things are pretty simple in the root folder.

The git files and readme hopefully don't need explaining.

The CMake file might be new to some, so let's look inside.

CMake complains if this first line is not there, so I put in a version that's five years old.

I have no idea what the minimum version is or how to determine that in a reasonable amount of time.

I just wanted to clear the warning.

The project line sets a name and the languages to use.

Change the name if you want.

Add subdirectory is here to include the SDK.

We'll look in that folder later.

You can have multiple executables per project.

Here we have one called hello.

When you add more source files, they need to be listed here.

And finally, the rp6502 SDK needs to be included as a library.

This library comes from the subdirectory added on line five.

Since VSCode knows how to work with CMake, all you need to do is keep the list of source files updated.

The rest can be ignored unless you want to learn more about CMake.

It occurs to me that we haven't actually looked at hello.c.

Here it is.

A print statement.

Okay, moving on.

The VSCode folder is a bunch of configuration to bring everything together.

IntelliSense CMake and VSCode don't support CC65 without hacks, most of these are here.

The build folder has a lot of goodies that you can explore.

One thing you'll find useful is the intermediate assembly for your C files.

And finally, we get to the SDK folder.

This could have been built into CC65 and Perhaps someday it will.

I don't want new features to be delayed by upstream projects, so I built the SDK as a git submodule.

It also gives me a good place to put a couple of things that wouldn't be appropriate to distribute with CC65.

Like this CMake toolchain file.

A lot of this stuff is considered internals and not documented.

Most of it was figured out by trial and error.

I'm surprised it works as well as it does.

Just don't ask me how.

This python script is something you'll want to get familiar with.

This is a tool for remotely controlling a Picocomputer.

You can include it from another python script or run it from the command line.

The VSCode configuration uses it to run programs, but you can also use it to create ROM files.

This config file controls how 6502 memory is used by the CC65 compiler.

It's unlikely you'll need to change it unless you change the hardware significantly.

Everything else in the SDK is C and assembly files.

Some are for the C standard library and the rest is for kernel calls.

Both CC65 and the Picocomputer have documentation which can help you navigate these files if you're interested.

I'd rather show you what you can do with them instead.

So let's write some code that's definitely not pro.

I'm going to skip error checking for the sake of keeping this video short and interesting.

Don't do that in your real projects.

Let's go back to hello.c in the source folder.

I'm not even going to rename it.

We're just having fun here.

I wrote a program that keeps track of how many times it's been run.

The Picocomputer uses FAT formatted USB drives for storage.

We'll use a file there to track the count.

Cue the montage of me typing.

Just kidding.

I'll paste it in and explain it.

We start with an int for the counter and a file pointer.

This opens a file for reading and writing.

This creates the file if it doesn't exist.

Now we read the counter integer.

Print and increment the counter.

Fseek will rewind the read write position so we can write the incremented counter back to the file.

And finally we close the file.

I'll run it a few times so you can see it work.

Looking on the USB drive we can see the file.

Hopefully you're thinking this is nothing special.

Like why am I showing you boring C that will run anywhere.

Well, that's the point.

Boring is good.

Simple tasks like writing a file shouldn't be complicated.

It's still a 6502 though, so there's plenty of challenges waiting for you.

I'll make another video about getting started with assembly language programming so be sure to subscribe if you don't want to miss it.

Thanks for watching.
