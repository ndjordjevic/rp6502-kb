---
type: source
source_kind: youtube
video_id: xkolkC1RgOY
title: RP6502 Ep18 - Are you keeping up with LLVM-MOS?
url: https://www.youtube.com/watch?v=xkolkC1RgOY
captions_file: xkolkC1RgOY-RP6502 Ep18 - Are you keeping up with LLVM-MOS？.en-US.vtt
retrieved: 2026-04-17
---

# RP6502 Ep18 - Are you keeping up with LLVM-MOS?

**Source**: [https://www.youtube.com/watch?v=xkolkC1RgOY](https://www.youtube.com/watch?v=xkolkC1RgOY)
**Video ID**: `xkolkC1RgOY`

---

Someone once asked me why I used cc65 instead of LLVM-MOS for the Picocomputer.

In this video, I'll talk about what those are and why you'd pick one over the other.

I should also mention that both cc65 and LLVM-MOS have support for the Picocomputer so you can use either one for your projects.

But what are they?

Both of them are C compilers for the 6502 and friends.

C is a fantastic language for small processors.

Even though the 6502 doesn't have a stack that's well suited for C, it's still a great language when you want high performance without the tedious work of writing everything in assembly. cc65 has been around since 1998 and is stable with a good standard Library.

LLVM-MOS has commits going back to 2001, but isn't stable and has very little in its standard library.

But it's not as simple as all that.

LLVM-MOS supports a lot of things that cc65 does not.

For example, floating point math and 64-bit integers.

And here's the big one.

LLVM-MOS supports C++ and the latest C dialects.

Rust too, but I haven't looked at that.

Now what about code generation?

In my testing the code size seems like a wash.

There's a big difference in how the code works, which you'd think would make a significant difference in the code size, but it seems to even out once your application is sufficiently large enough.

However, performance testing did show a significant difference.

Here's my naive implementation of a Mandelbrot set.

It's possible to get cc65 running faster, but it takes a serious effort to craft the code in a specific way that only cc65 can take advantage of.

I didn't do that.

Instead I leaned on the compilers to optimize portably written code.

You can see from the result here that LLVM-MOS gave quite a boost to performance without me doing any extra work to feed hints to the compiler.

So which should you use for your next 6502 project?

If you need a good standard library then cc65 is your only choice.

If you want to use C++ or need floats or 64-bit integers then LLVM-MOS is your only choice.

But not for long.

Once that standard Library catches up, LLVM-MOS is going to be awesome.

I hope that happens this year.

That's all for this video.

Thanks for watching.
