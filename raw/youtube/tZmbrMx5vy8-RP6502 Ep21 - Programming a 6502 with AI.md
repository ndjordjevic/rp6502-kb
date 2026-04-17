---
type: source
source_kind: youtube
video_id: tZmbrMx5vy8
title: RP6502 Ep21 - Programming a 6502 with AI
url: https://www.youtube.com/watch?v=tZmbrMx5vy8
captions_file: tZmbrMx5vy8-RP6502 Ep21 - Programming a 6502 with AI.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep21 - Programming a 6502 with AI

**Source**: [https://www.youtube.com/watch?v=tZmbrMx5vy8](https://www.youtube.com/watch?v=tZmbrMx5vy8)
**Video ID**: `tZmbrMx5vy8`

---

This is a single board computer based on&nbsp; the venerable 6502.

You can set it up like&nbsp;&nbsp; a desktop computer with a keyboard, mouse,&nbsp; gamepad, storage, display, and speakers,&nbsp;&nbsp; but we're not doing all that today.

Let's&nbsp; start with the basics and use only the&nbsp;&nbsp; serial port.

All you need is an ordinary USB&nbsp; cable.

Just connect this port to a Windows,&nbsp;&nbsp; Mac, or Linux system.

No drivers are needed.&nbsp; Everything we'll do starts with this project&nbsp;&nbsp; template.

I'll be using the CC65 compiler,&nbsp; but there's also a template for LLVM MOS.

The template simply prints hello world.&nbsp; Pressing F5 will build the program,&nbsp;&nbsp; upload it to the hardware, and execute it.

You can&nbsp; see the output here.

I've attached the VGA output&nbsp;&nbsp; to a capture card.

So, you can see the output is&nbsp; also shown there.

Now, let's write some code or&nbsp;&nbsp; not.

Let's have AI write some programs for us.&nbsp; Might as well have some fun before Skynet goes&nbsp;&nbsp; online.

I have some prompts prepared which we'll&nbsp; work through in real time.

We'll look at the good&nbsp;&nbsp; and the bad.

And there will be some silent parts&nbsp; which I won't edit out.

I'm using Anthropic's&nbsp;&nbsp; models in GitHub Copilot.

These are considered&nbsp; premium requests, but you get 50 free requests&nbsp;&nbsp; every month.

And because GitHub Copilot is built&nbsp; into VS Code, the only thing you need to do is&nbsp;&nbsp; log in when it asks.

To get started, all you do&nbsp; is open the panel and tell it to do something, Like print the first 10 numbers&nbsp; of the Fibonacci sequence.

It's going to tell me what I just&nbsp; asked it and make the program for us.

Let's run it.

Okay.

Excellent.

It tells me&nbsp; here that this is the output I&nbsp;&nbsp; should expect.

And if we look on the&nbsp; screen, that is the correct output.

Let's try something a little bit more challenging.&nbsp;&nbsp; Print Mandelbrot using code page 437&nbsp; extended characters with ANSI color.

Okay, it's telling me that the CC65&nbsp; compiler doesn't support floating&nbsp;&nbsp; point and it's going to use fixed&nbsp; point arithmetic in 16.16 format.&nbsp;&nbsp; Okay, I don't know why it decided to do that,&nbsp; but that's going to be very difficult because the&nbsp;&nbsp; CC65 compiler doesn't have 64-bit ints.

So, this&nbsp; this fixed point math is going to be impossible.

So, we'll tell it ints are 16 bits.

Yes, I'm right.

Of course, I'm&nbsp; right.

I'm a human.

You're an AI.

So now it's going to switch&nbsp; to 8.8 fixed point format&nbsp;&nbsp; and that that we can do in a 32-bit integer.

Okay, let's build it and see if there's&nbsp; errors.

No errors. and we'll send it.

Okay, this looks good.

It's certainly not&nbsp; high resolution, but it is what we expect.

Let's try making a game&nbsp; with some user interaction.

I've asked it to make a game where I have&nbsp; to guess what number between 1 and 99 the&nbsp;&nbsp; computer picked.

It should tell me too high&nbsp; or too low and count the number of tries.

Okay, it's thinking about it for a bit.

Okay, it says I can build it&nbsp; and run it using that command,&nbsp;&nbsp; which I cannot do.

I don't know why it keeps&nbsp; wanting to run it like it's a local program.

Okay, I'm thinking of a number between 1 and 99.&nbsp; Too low, too high, too high. 63, 62.

Correct.&nbsp;&nbsp; The number is 62.

I guessed it in six tries.&nbsp; Let's run it again and and try it one more time.

Enter your guess. 62.

Correct.

I&nbsp; guessed it in one try.

Okay.

Well,&nbsp;&nbsp; this is because AI didn't seed my random number&nbsp; generator.

So, every time the program runs,&nbsp;&nbsp; it's going to come up with the same sequence of&nbsp; random numbers.

And we we can see here at the&nbsp;&nbsp; very beginning of the program, the first thing&nbsp; it does is generate the secret, but it hasn't&nbsp;&nbsp; seeded the random number generator.

So, I'm going&nbsp; to tell it to seed the random number generator.

I'm also going to tell it to read the docs&nbsp; because I happen to know that the AI just&nbsp;&nbsp; loves ignoring the documentation.

But it&nbsp; absolutely must read the documentation&nbsp;&nbsp; here in order to get to the the hardware&nbsp; random number generator on this board.

Oh, very good.

It actually went and&nbsp; used the CC65 randomize function,&nbsp;&nbsp; which is a custom function built into&nbsp; that compiler and that will use the&nbsp;&nbsp; hardware entropy and generate random numbers&nbsp; every time.

So, let's give it another try. 62.

Okay, it is it is now picking&nbsp; a different number. 10.

Correct.&nbsp;&nbsp; I guessed it in four tries.&nbsp; That's better than average.

Let's try something with graphics.

You'll&nbsp;&nbsp; need something plugged into the&nbsp; VGA connector to see graphics.

I asked it to make a dragon fly across the&nbsp; screen using sprites and make it repeat.

It's going to look through the program to&nbsp; see if it can find any established patterns,&nbsp;&nbsp; which there aren't.

And so it moves&nbsp; on to reading the documentation.

I'm always encouraged whenever&nbsp; it reads the documentation first&nbsp;&nbsp; because whenever it doesn't,&nbsp; it usually fails.

Imagine that.

All right, it says it's done reading the&nbsp; documentation.

Now it's going to write the code.

Sometimes things take a bit.

Not long&nbsp; enough to go make a cup of coffee,&nbsp;&nbsp; but certainly enough to have a few sips.

There we are.

It wants to check for the header&nbsp; file.

Okay, it's going to be spending an&nbsp;&nbsp; indefinite amount of time searching my file&nbsp; system and it won't find it even though the&nbsp;&nbsp; IDE here knows exactly where the header is.&nbsp; So, what we can do is select the header,&nbsp;&nbsp; which I've already brought up, and anchor&nbsp; it down here and say, here's the header.

It's going to make some adjustments&nbsp; to how it accesses the registers.

All right, it wants to build it and see if there's&nbsp; any errors.

There's no errors.

Let's send it.

All right, this is the best&nbsp; dragon I've seen so far.

Let's see if AI can play music.

Of course, you'll&nbsp; need something plugged into the audio jack to hear&nbsp;&nbsp; sound.

This time I'm explicitly asking to read&nbsp; the docs because it won't by default usually and&nbsp;&nbsp; it won't get very far if it doesn't.

I've asked&nbsp; it to play a song, not scales.

And I'm using&nbsp;&nbsp; VSYNC for timing.

That way it'll be easier to&nbsp; integrate into a video game that also uses VSYNC.

We can see it went and fetched the documentation.

It's going to look for some examples.

And it says it thinks it's thinks&nbsp; it understands what it needs to do.

Should only take a moment longer.

And there we go.

It's got some code.

Mary had a little lamb.

It builds&nbsp; without errors.

Let's send it.

Well, that was fast.

Let's see if it can correct the speed on its own.

Okay.

The problem there is it&nbsp; wasn't separating the notes.

So,&nbsp;&nbsp; let me give it a hint to&nbsp; what for what it needs to do.

I'm going to tell it the notes run together.&nbsp; And then I'm going to tell it you need to&nbsp;&nbsp; stop the note and let it release while&nbsp; beginning a new one on the next channel.

All right, let's see what happens.

Okay, let's see.

I would call that a success.

It played a song.&nbsp; It was a recognizable song.

All the notes&nbsp;&nbsp; sounded correct to me and we only had to give&nbsp; it a couple hints here.

I think that's enough&nbsp;&nbsp; for now.

I'm going to end the video.

Thanks&nbsp; for watching.

Links are in the description.
