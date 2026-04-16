---
title: "RP6502-OS — Picocomputer  documentation"
source: "https://picocomputer.github.io/os.html"
author:
published:
created: 2026-04-15
description:
tags:
  - "clippings"
---
## RP6502-OS

RP6502 - Operating System

## Introduction

The [RP6502-RIA](https://picocomputer.github.io/ria.html) runs a 32-bit protected operating system that you can call from the 6502. The OS does not use any 6502 system RAM and will not interfere with developing a native 6502 OS.

The OS loosely follows POSIX with an Application Binary Interface (ABI) similar to [cc65’s fastcall](https://cc65.github.io/doc/cc65-intern.html). It provides `stdio.h` and `unistd.h` services to both [cc65](https://cc65.github.io/) and [llvm-mos](https://llvm-mos.org/) compilers. There are also calls to access RP6502 features and manage FAT32 filesystems.

> [!note] Note
> ExFAT is ready to go and will be enabled when the patents expire.

## Memory Map

There is no ROM. Nothing in zero page is used or reserved. The Picocomputer starts as a clean slate for every project. VGA, audio, storage, keyboards, mice, gamepads, RTC, and networking are all accessed using only the 32 registers of the RIA.

| Address | Description |
| --- | --- |
| $0000-$FEFF | RAM, 63.75K |
| $FF00-$FFCF | Unassigned |
| $FFD0-$FFDF | VIA, see the [WDC datasheet](https://www.westerndesigncenter.com/wdc/w65c22-chip.php) |
| $FFE0-$FFFF | RIA, see the [RP6502-RIA datasheet](https://picocomputer.github.io/ria.html) |
| $10000-$1FFFF | XRAM, 64K for [RP6502-RIA](https://picocomputer.github.io/ria.html) and [RP6502-VGA](https://picocomputer.github.io/vga.html) |

The unassigned space is available for hardware experimenters. Design your own chip select hardware to use this address space. Add additional VIAs downward and other hardware upward. For example: VIA0 at $FFD0, VIA1 at $FFC0, SID0 at $FF00, and SID1 at $FF20.

## Application Binary Interface

> [!note] See also
> [RP6502-RIA](https://picocomputer.github.io/ria.html) — the hardware register map referenced throughout this section.

The ABI for calling the operating system is based on fastcall from the [cc65 internals](https://cc65.github.io/doc/cc65-intern.html). The OS does not use or require anything from cc65 and is easy for assembly programmers to use. At its core, the OS ABI is four simple rules.

- Stack arguments are pushed left to right.
- Last argument passed by register A, AX, or AXSREG.
- Return value in register AX or AXSREG.
- May return data on the stack.

A and X are the 6502 registers. The pseudo register AX combines them for 16 bits. AXSREG allows 32 bits with the 16 additional SREG bits. Let’s look at how to make an OS call through the RIA registers. All OS calls are specified as a C declaration like so:

int doit(int arg0, int arg1);[¶](#c.doit "Link to this definition")  

The RIA has registers called `RIA_A`, `RIA_X`, and `RIA_SREG`. An int is 16 bits, so we set the `RIA_A` and `RIA_X` registers with arg1. I’ll use “A” for the 6502 register and “RIA\_A” for the RIA register in this explanation.

We use the XSTACK for arg0. Reading `RIA_XSTACK` pops bytes; writing pushes bytes. It’s a top-down stack, so push each argument left to right and maintain little-endian byte order.

To execute the call, store the operation ID in `RIA_OP`. The operation begins immediately. You can keep doing 6502 things, like running a loading animation, by polling `RIA_BUSY`. Alternatively, JSR to `RIA_SPIN` to block.

`JSR RIA_SPIN` can unblock within 3 clock cycles and immediately loads A and X. Sequential operations run fastest with this technique. Under the hood, you’re jumping into a self-modifying program that runs on the RIA registers.

```
BRA #$??      ; RIA_BUSY {-2 or 0}
LDA #$??      ; RIA_A
LDX #$??      ; RIA_X
RTS
```

Polling is simply snooping on the above program. The `RIA_BUSY` register is the -2 or 0 in the BRA above. The RIA datasheet specifies bit 7 indicates busy, which the 6502 can check quickly by using the BIT operator to set flag N. Once clear, we read `RIA_A` and `RIA_X` with absolute instructions.

```
wait:
BIT RIA_BUSY
BMI wait
LDA RIA_A
LDX RIA_X
```

All operations returning `RIA_A` will also return `RIA_X` to assist with C integer promotion. `RIA_SREG` is only updated for 32-bit returns. `RIA_ERRNO` is only updated if there is an error.

Some operations return strings or structures on the stack. You must pull the entire stack before the next call. However, tail call optimizations are possible. For example, you can chain [read\_xstack()](https://picocomputer.github.io/READ_XSTACK) and [write\_xstack()](https://picocomputer.github.io/WRITE_XSTACK) to copy a file without using any RAM or XRAM.

### Short Stacking

In the pursuit of saving every cycle, you can save a few on the stack push when you don’t need the full range. This only applies to the first stack argument pushed. For example, in:

```c
long f_lseek(long offset, char whence, int fildes)
```

Here we need to push a 32 bit value. Not coincidentally, it’s in the right position for short stacking. If, for example, the offset always fits in 16 bits, push only two bytes instead of four.

### Shorter AX

Many operations can save a few cycles by ignoring REG\_X. All returned integers are always available as at least 16 bits to assist with C integer promotion. However, many operations will ignore REG\_X in the register parameter and limit their return to fit in REG\_A. These will be documented below as “A regs”.

### Bulk Data

Functions that move bulk data come in two flavors, depending on where the data lives. A RAM pointer is meaningless to the RIA because it cannot change 6502 RAM. Instead, use the XSTACK or XRAM to move data.

#### Bulk XSTACK Operations

These only work if the size is 512 bytes or less. Bulk data is passed on the XSTACK, which is 512 bytes. A pointer appears in the C prototype to indicate the type and direction (to or from the OS) of this data. Let’s look at some examples.

```c
int open(const char *path, int oflag);
```

Send `oflag` in `RIA_A`. `RIA_X` doesn’t need to be set according to the docs. Send the path on XSTACK by pushing the string starting with the last character. You may omit pushing the terminating zero, but strings are limited to a length of 255. Calling this from the C SDK will “just work” because there’s an implementation that pushes the string for you.

```c
int read_xstack(void *buf, unsigned count, int fildes)
```

Send `count` as a short stack and `fildes` in `RIA_A`. `RIA_X` doesn’t need to be set according to the docs. The returned value in AX indicates how many values must be pulled from the stack. If you call this from the C SDK then it will copy XSTACK to buf\[\] for you.

```c
int write_xstack(const void *buf, unsigned count, int fildes)
```

Send `fildes` in `RIA_A`. `RIA_X` doesn’t need to be set according to the docs. Push the buf data to XSTACK. Do not send `count`, the OS knows this from its internal stack pointer. If you call this from the C SDK then it will copy count bytes of buf\[\] to XSTACK for you.

Note that read() and write() are part of the C SDK, not an OS operation. C requires these to support a count larger than the XSTACK can return so the implementation makes multiple OS calls as necessary.

#### Bulk XRAM Operations

These load and save XRAM directly via and. You can directly load assets without going through 6502 RAM.

```c
int read_xram(xram_addr buf, unsigned count, int fildes)
int write_xram(xram_addr buf, unsigned count, int fildes)
```

The OS expects `buf` and `count` on the XSTACK as integers with `fildes` in `RIA_A`. The OS has direct access to XRAM so internally it will use something like `&XRAM[buf]`. You will need to use `RIA_RW0` or `RIA_RW1` to access this memory from the 6502.

These operations stand out for their high performance and ability to run in the background while the 6502 does other work. Expect close to 512 KB/sec, meaning a full 64KB of XRAM can load or save in under 150ms.

Bulk XRAM operations are why the Picocomputer 6502 doesn’t have paged memory. It’s not necessary when “disk” access has no seek time and can move data as fast or faster then the CPU.

## Application Programmer Interface

> [!note] See also
> [FatFs documentation](https://elm-chan.org/fsw/ff/) — many of the filesystem functions below are thin wrappers around FatFs.

Much of this API is based on POSIX and FatFs. In particular, filesystem and console access should feel extremely familiar. However, some operations will have a different argument order or data structures than what you’re used to. The reason for this becomes apparent when you start to work in assembly and fine tune short stacking and integer demotions. You might not notice the differences if you only work in C because the standard library has wrapper functions and familiar prototypes. For example, the `f_lseek()` described below has reordered arguments that are optimized for short stacking the long argument. But you don’t have to call `f_lseek()` from C, you can call the usual `lseek()` which has the traditional argument order.

The OS is built around FAT filesystems, the de facto standard for unsecured USB storage devices. POSIX filesystems are not fully compatible with FAT but there is a solid intersection of basic IO that is 100% compatible. You will see some familiar POSIX functions like `open()` and others like `f_stat()` which are similar to the POSIX function but tailored to FAT. Should it ever become necessary to have a POSIX `stat()`, it can be implemented in the C standard library or in an application by translating `f_stat()` data.

### ZXSTACK

void zxstack(void);[¶](#c.zxstack "Link to this definition")  

Abandon the xstack by resetting the xstack pointer. This is the only operation that doesn’t require waiting for completion. You do not need to call this for failed operations. It can be useful if you want to quickly ignore part of a returned structure.

Op code:

RIA\_OP\_ZXSTACK 0x00

C proto:

rp6502.h

### XREG

int xreg(char device, char channel, unsigned char address,...);[¶](#c.xreg "Link to this definition")  

int xregn(char device, char channel, unsigned char address, unsigned count,...);[¶](#c.xregn "Link to this definition")  

Using xreg() from C is preferred to avoid making a counting error. Count doesn’t need to be sent in the ABI so both prototypes are correct.

The variadic argument is a list of ints to be stored in extended registers starting at address on the specified device and channel. See the [RP6502-RIA](https://picocomputer.github.io/ria.html) and [RP6502-VGA](https://picocomputer.github.io/vga.html) documentation for what each register does. Setting extended registers can fail, which you can use for feature detection. EINVAL means the device responded with a negative acknowledgement. EIO means there was a timeout waiting for ack/nak.

This is how you add virtual hardware to extended RAM. Both the [RP6502-RIA](https://picocomputer.github.io/ria.html) and [RP6502-VGA](https://picocomputer.github.io/vga.html) have a selection of virtual devices you can install. You can also make your own hardware for the PIX bus and configure it with this call.

Op code:

RIA\_OP\_XREG 0x01

C proto:

rp6502.h

Parameters:

- **device** – PIX device ID. 0:RIA, 1:VGA, 2-6:unassigned
- **channel** – PIX channel. 0-15
- **address** – PIX address. 0-255
- **...** – 16 bit integers to set starting at address.

A regs:

return

Errno:

EINVAL, EIO

### ARGV

int \_argv(char \*argv, int size) [¶](#c._argv "Link to this definition")  

The virtual \_argv is called by C initialization to provide argc and argv for main(). It returns an array of zero terminated string indexes followed by the strings. e.g. \[“ABC”, “DEF”\] is 06 00 0A 00 00 00 41 42 43 00 44 45 46 00 The returned data is guaranteed to be valid.

Because this can use up to 512 bytes of RAM you must opt-in by providing storage for the argv data. You may use static memory, or dynamically allocated memory which can be freed after use. You may also reject an oversized argv by returning NULL.

```c
void *argv_mem(size_t size) { return malloc(size); }
```

Op code:

RIA\_OP\_ARGV 0x08

C proto:

(none)

Returns:

Size of argv data

Errno:

will not fail

### EXEC

int ria\_execl(const char \*path,...) [¶](#c.ria_execl "Link to this definition")  

int ria\_execv(const char \*path, char \*const argv\[\]) [¶](#c.ria_execv "Link to this definition")  

int \_exec(const char \*argv, int size) [¶](#c._exec "Link to this definition")  

The virtual \_exec is called by ria\_execl() and ria\_execv(). Be aware of the one difference from the execl() and execv() you may be used to. Because RAM is precious, the path is only supplied once, not again in argv\[0\]. The launched ROM will see argv\[0\] as the filename.

The data sent by \_exec() will be checked for pointer safety and sanity, but will assume the path points to a loadable ROM file. If EINVAL is returned, the argv buffer is cleared so further attempts to \_argv() will return an empty set. If the ROM is invalid, the user will be left on the console with an error message.

Op code:

RIA\_OP\_EXEC 0x09

C proto:

rp6502.h

Returns:

Does not return on success — the new ROM begins executing. -1 on error.

Errno:

EINVAL

### ATTR\_GET

long ria\_attr\_get(unsigned char id) [¶](#c.ria_attr_get "Link to this definition")  

Returns the current value of a RIA attribute. See for attribute IDs and descriptions.

Op code:

RIA\_OP\_ATTR\_GET 0x0A

C proto:

rp6502.h

Parameters:

- **id** – Attribute ID. One of the `RIA_ATTR_*` constants.

A regs:

id

Returns:

The attribute value as a 31-bit integer. -1 on error.

Errno:

EINVAL

### ATTR\_SET

int ria\_attr\_set(long val, unsigned char id) [¶](#c.ria_attr_set "Link to this definition")  

Sets the value of a RIA attribute. See for attribute IDs and descriptions.

Op code:

RIA\_OP\_ATTR\_SET 0x0B

C proto:

rp6502.h

Parameters:

- **id** – Attribute ID. One of the `RIA_ATTR_*` constants.
- **val** – New value.

A regs:

id

Returns:

0 on success

Errno:

EINVAL

### CLOCK

unsigned long clock(void) [¶](#c.clock "Link to this definition")  

Obtain the value of a monotonic clock that updates 100 times per second. Wraps approximately every 497 days.

Op code:

RIA\_OP\_CLOCK 0x0F

C proto:

time.h

Returns:

1/100 second monotonic clock

Errno:

will not fail

### CLOCK\_GETRES

int clock\_getres(clockid\_t clock\_id, struct timespec \*res) [¶](#c.clock_getres "Link to this definition")  

```c
struct timespec {
   uint32_t tv_sec; /* seconds */
   int32_t tv_nsec; /* nanoseconds */
};
```

Obtains the clock resolution.

Op code:

RIA\_OP\_CLOCK\_GETRES 0x10

C proto:

time.h

Parameters:

- **clock\_id** – 0 for CLOCK\_REALTIME.

Returns:

0 on success. -1 on error.

A regs:

return, clock\_id

Errno:

EINVAL

### TZSET

void tzset(void);[¶](#c.tzset "Link to this definition")  

int \_tzset(struct \*tz) [¶](#c._tzset "Link to this definition")  

```c
struct _tzset
{
   int8_t daylight;  /* non 0 if daylight savings time active */
   int32_t timezone; /* Number of seconds behind UTC */
   char tzname[5];   /* Name of timezone, e.g. CET */
   char dstname[5];  /* Name when daylight true, e.g. CEST */
};
```

The virtual \_tzset() is called internally by tzset(). Use help set tz on the console monitor to learn about configuring your time zone.

Op code:

RIA\_OP\_TZSET 0x0D

C proto:

time.h

Returns:

0 on success. -1 on error.

Errno:

EINVAL

### TZQUERY

struct tm \*localtime(const time\_t \*timep);[¶](#c.localtime "Link to this definition")  

int \_tzquery(uint32\_t time, struct \*dst) [¶](#c._tzquery "Link to this definition")  

```c
struct _tzquery
{
   int8_t daylight;  /* non 0 if daylight savings time active */
};
```

The virtual \_tzquery() is called internally by localtime().

Op code:

RIA\_OP\_TZQUERY 0x0E

C proto:

time.h

Returns:

Seconds to add to UTC for localtime.

Errno:

will not fail

### CLOCK\_GETTIME

int clock\_gettime(clockid\_t clock\_id, struct timespec \*tp) [¶](#c.clock_gettime "Link to this definition")  

Obtains the current time.

Op code:

RIA\_OP\_CLOCK\_GETTIME 0x11

C proto:

time.h

Parameters:

- **clock\_id** – 0 for CLOCK\_REALTIME.

Returns:

0 on success. -1 on error.

A regs:

return, clock\_id

Errno:

EINVAL, EUNKNOWN

### CLOCK\_SETTIME

int clock\_settime(clockid\_t clock\_id, const struct timespec \*tp) [¶](#c.clock_settime "Link to this definition")  

Sets the current time.

Op code:

RIA\_OP\_CLOCK\_SETTIME 0x12

C proto:

time.h

Parameters:

- **clock\_id** – 0 for CLOCK\_REALTIME.

Returns:

0 on success. -1 on error.

A regs:

return, clock\_id

Errno:

EINVAL, EUNKNOWN

### OPEN

int open(const char \*path, int oflag) [¶](#c.open "Link to this definition")  

Create a connection between a file and a file descriptor. Up to 8 files may be open at once.

Op code:

RIA\_OP\_OPEN 0x14

C proto:

fcntl.h

Parameters:

- **path** – Pathname to a file.
- **oflag** – Bitfield of options.

Returns:

File descriptor. -1 on error.

A regs:

return, oflag

Errno:

EINVAL, EMFILE, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_NO\_FILE, FR\_NO\_PATH, FR\_INVALID\_NAME, FR\_DENIED, FR\_EXIST, FR\_INVALID\_OBJECT, FR\_WRITE\_PROTECTED, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT, FR\_LOCKED, FR\_NOT\_ENOUGH\_CORE, FR\_TOO\_MANY\_OPEN\_FILES

Options:

O\_RDONLY 0x01

Open for reading only.

O\_WRONLY 0x02

Open for writing only.

O\_RDWR 0x03

Open for reading and writing.

O\_CREAT 0x10

Create the file if it does not exist.

O\_TRUNC 0x20

Truncate the file length to 0 after opening.

O\_APPEND 0x40

Read/write pointer is set end of the file.

O\_EXCL 0x80

If O\_CREAT and O\_EXCL are set, fail if the file exists.

### CLOSE

int close(int fildes) [¶](#c.close "Link to this definition")  

Finish pending writes and release the file descriptor. File descriptor will rejoin the pool available for use by open().

Op code:

RIA\_OP\_CLOSE 0x15

C proto:

fcntl.h

Parameters:

- **fildes** – File descriptor from open().

Returns:

0 on success. -1 on error.

A regs:

return, fildes

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_INVALID\_OBJECT, FR\_TIMEOUT

### READ

int read(int fildes, void \*buf, unsigned count) [¶](#c.read "Link to this definition")  

Read count bytes from a file to a buffer. This is implemented in the compiler library as a series of calls to.

Op code:

None

C proto:

unistd.h

Parameters:

- **buf** – Destination for the returned data.
- **count** – Quantity of bytes to read. 0x7FFF max.
- **fildes** – File descriptor from open().

Returns:

On success, number of bytes read is returned. On error, -1 is returned.

A regs:

fildes

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_DENIED, FR\_INVALID\_OBJECT, FR\_TIMEOUT

### READ\_XSTACK

int read\_xstack(void \*buf, unsigned count, int fildes) [¶](#c.read_xstack "Link to this definition")  

Read count bytes from a file to xstack.

Op code:

RIA\_OP\_READ\_XSTACK 0x16

C proto:

rp6502.h

Parameters:

- **buf** – Destination for the returned data.
- **count** – Quantity of bytes to read. 0x100 max.
- **fildes** – File descriptor from open().

Returns:

On success, number of bytes read is returned. On error, -1 is returned.

A regs:

fildes

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_DENIED, FR\_INVALID\_OBJECT, FR\_TIMEOUT

### READ\_XRAM

int read\_xram(unsigned buf, unsigned count, int fildes) [¶](#c.read_xram "Link to this definition")  

Read count bytes from a file to xram.

Op code:

RIA\_OP\_READ\_XRAM 0x17

C proto:

rp6502.h

Parameters:

- **buf** – Destination for the returned data.
- **count** – Quantity of bytes to read. 0x7FFF max.
- **fildes** – File descriptor from open().

Returns:

On success, number of bytes read is returned. On error, -1 is returned.

A regs:

fildes

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_DENIED, FR\_INVALID\_OBJECT, FR\_TIMEOUT

### WRITE

int write(int fildes, const void \*buf, unsigned count) [¶](#c.write "Link to this definition")  

Write count bytes from buffer to a file. This is implemented in the compiler library as a series of calls to.

Op code:

None

C proto:

unistd.h

Parameters:

- **buf** – Location of the data.
- **count** – Quantity of bytes to write. 0x7FFF max.
- **fildes** – File descriptor from open().

Returns:

On success, number of bytes written is returned. On error, -1 is returned.

A regs:

fildes

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_DENIED, FR\_INVALID\_OBJECT, FR\_TIMEOUT

### WRITE\_XSTACK

int write\_xstack(const void \*buf, unsigned count, int fildes) [¶](#c.write_xstack "Link to this definition")  

Write count bytes from xstack to a file.

Op code:

RIA\_OP\_WRITE\_XSTACK 0x18

C proto:

rp6502.h

Parameters:

- **buf** – Location of the data.
- **count** – Quantity of bytes to write. 0x100 max.
- **fildes** – File descriptor from open().

Returns:

On success, number of bytes written is returned. On error, -1 is returned.

A regs:

fildes

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_DENIED, FR\_INVALID\_OBJECT, FR\_TIMEOUT

### WRITE\_XRAM

int write\_xram(unsigned buf, unsigned count, int fildes) [¶](#c.write_xram "Link to this definition")  

Write count bytes from xram to a file.

Op code:

RIA\_OP\_WRITE\_XRAM 0x19

C proto:

rp6502.h

Parameters:

- **buf** – Location of the data.
- **count** – Quantity of bytes to write. 0x7FFF max.
- **fildes** – File descriptor from open().

Returns:

On success, number of bytes written is returned. On error, -1 is returned.

A regs:

fildes

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_DENIED, FR\_INVALID\_OBJECT, FR\_TIMEOUT

### LSEEK

static long f\_lseek(long offset, char whence, int fildes) [¶](#c.f_lseek "Link to this definition")  

off\_t lseek(int fildes, off\_t offset, int whence) [¶](#c.lseek "Link to this definition")  

Move the read/write pointer. The OS uses the ABI format of f\_seek(). An lseek() compatible wrapper is provided with the compiler library.

This can also be used to obtain the current read/write position with `f_lseek(0, SEEK_CUR, fd)`.

Op code:

See table below.

C proto:

f\_lseek: rp6502.h, lseek: unistd.h

Parameters:

- **offset** – How far you wish to seek.
- **whence** – From whence you wish to seek. See table below.
- **fildes** – File descriptor from open().

Returns:

Read/write position. -1 on error. If this value would be too large for a long, the returned value will be 0x7FFFFFFF.

A regs:

fildes

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_INVALID\_OBJECT, FR\_TIMEOUT

|  | RIA\_OP\_LSEEK\_LLVM | RIA\_OP\_LSEEK\_CC65 |
| --- | --- | --- |
| RIA\_OP\_LSEEK | 0x1D | 0x1A |
| SEEK\_SET | 0 | 2 |
| SEEK\_CUR | 1 | 0 |
| SEEK\_END | 2 | 1 |

### UNLINK

int unlink(const char \*name) [¶](#c.unlink "Link to this definition")  

Removes a file or directory from the volume.

Op code:

RIA\_OP\_UNLINK 0x1B

C proto:

unistd.h

Parameters:

- **name** – File or directory name to unlink (remove).

Returns:

0 on success. -1 on error.

Errno:

FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_NO\_FILE, FR\_NO\_PATH, FR\_INVALID\_NAME, FR\_DENIED, FR\_WRITE\_PROTECTED, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT, FR\_LOCKED, FR\_NOT\_ENOUGH\_CORE

### RENAME

int rename(const char \*oldname, const char \*newname) [¶](#c.rename "Link to this definition")  

Renames and/or moves a file or directory.

Op code:

RIA\_OP\_RENAME 0x1C

C proto:

stdio.h

Parameters:

- **oldname** – Existing file or directory name to rename.
- **newname** – New object name.

Returns:

0 on success. -1 on error.

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_NO\_FILE, FR\_NO\_PATH, FR\_INVALID\_NAME, FR\_EXIST, FR\_WRITE\_PROTECTED, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT, FR\_LOCKED, FR\_NOT\_ENOUGH\_CORE

### SYNCFS

int syncfs(int fildes) [¶](#c.syncfs "Link to this definition")  

Finish pending writes for the file descriptor.

Op code:

RIA\_OP\_SYNCFS 0x1E

C proto:

unistd.h

Parameters:

- **fildes** – File descriptor from open().

Returns:

0 on success. -1 on error.

A regs:

return, fildes

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_INVALID\_OBJECT, FR\_TIMEOUT

### STAT

int f\_stat(const char \*path, f\_stat\_t \*dirent) [¶](#c.f_stat "Link to this definition")  

```c
typedef struct {
   unsigned long fsize;
   unsigned fdate;
   unsigned ftime;
   unsigned crdate;
   unsigned crtime;
   unsigned char fattrib;
   char altname[12 + 1];
   char fname[255 + 1];
} f_stat_t;
```

Returns file or directory info for requested path. See the [FatFs documentation](https://elm-chan.org/fsw/ff/doc/sfileinfo.html) for details about the data structure.

Op code:

RIA\_OP\_STAT 0x1F

C proto:

rp6502.h

Parameters:

- **path** – Pathname to a directory entry.
- **dirent** – Returned f\_stat\_t data.

Returns:

0 on success. -1 on error.

A regs:

return, dirent

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_NO\_FILE, FR\_NO\_PATH, FR\_INVALID\_NAME, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT, FR\_NOT\_ENOUGH\_CORE

### OPENDIR

int f\_opendir(const char \*name) [¶](#c.f_opendir "Link to this definition")  

Create a connection between a directory and a directory descriptor. Up to 8 directories may be open at once.

Op code:

RIA\_OP\_OPENDIR 0x20

C proto:

rp6502.h

Parameters:

- **name** – Pathname to a directory.

Returns:

Directory descriptor. -1 on error.

A regs:

return

Errno:

EINVAL, EMFILE, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_NO\_PATH, FR\_INVALID\_NAME, FR\_INVALID\_OBJECT, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT, FR\_NOT\_ENOUGH\_CORE, FR\_TOO\_MANY\_OPEN\_FILES

### READDIR

int f\_readdir(f\_stat\_t \*dirent, int dirdes) [¶](#c.f_readdir "Link to this definition")  

Returns directory entry info for the current read position of a directory descriptor, then advances the read position.

Op code:

RIA\_OP\_READDIR 0x21

C proto:

rp6502.h

Parameters:

- **dirdes** – Directory descriptor from f\_opendir().
- **dirent** – Returned f\_stat\_t data.

Returns:

0 on success. -1 on error.

A regs:

return, dirent

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_INVALID\_OBJECT, FR\_TIMEOUT, FR\_NOT\_ENOUGH\_CORE

### CLOSEDIR

int f\_closedir(int dirdes) [¶](#c.f_closedir "Link to this definition")  

Release the directory descriptor. Directory descriptor will rejoin the pool available for use by f\_opendir().

Op code:

RIA\_OP\_CLOSEDIR 0x22

C proto:

rp6502.h

Parameters:

- **dirdes** – Directory descriptor from f\_opendir().

Returns:

0 on success. -1 on error.

A regs:

return, dirdes

Errno:

EINVAL, FR\_INT\_ERR, FR\_INVALID\_OBJECT, FR\_TIMEOUT

### TELLDIR

long f\_telldir(int dirdes) [¶](#c.f_telldir "Link to this definition")  

Returns the read position of the directory descriptor.

Op code:

RIA\_OP\_TELLDIR 0x23

C proto:

rp6502.h

Parameters:

- **dirdes** – Directory descriptor from f\_opendir().

Returns:

Read position. -1 on error.

A regs:

dirdes

Errno:

EINVAL, EBADF

### SEEKDIR

int f\_seekdir(long offs, int dirdes) [¶](#c.f_seekdir "Link to this definition")  

Set the read position for the directory descriptor. Internally, the FatFs directory read position can only move forward by one, so use this for convenience, not performance.

Op code:

RIA\_OP\_SEEKDIR 0x24

C proto:

rp6502.h

Parameters:

- **dirdes** – Directory descriptor from f\_opendir().

Returns:

Read position. -1 on error.

A regs:

return, dirdes

Errno:

EINVAL, EBADF, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_INVALID\_OBJECT, FR\_TIMEOUT, FR\_NOT\_ENOUGH\_CORE

### REWINDDIR

int f\_rewinddir(int dirdes) [¶](#c.f_rewinddir "Link to this definition")  

Rewind the read position of the directory descriptor.

Op code:

RIA\_OP\_REWINDDIR 0x25

C proto:

rp6502.h

Parameters:

- **dirdes** – Directory descriptor from f\_opendir().

Returns:

0 on success. -1 on error.

A regs:

dirdes

Errno:

EINVAL, EBADF, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_INVALID\_OBJECT, FR\_TIMEOUT, FR\_NOT\_ENOUGH\_CORE

### CHMOD

int f\_chmod(const char \*path, unsigned char attr, unsigned char mask) [¶](#c.f_chmod "Link to this definition")  

Change the attributes of a file or directory.

Op code:

RIA\_OP\_CHMOD 0x26

C proto:

rp6502.h

Parameters:

- **path** – Pathname to a file or directory.
- **attr** – New bitfield of attributes. See table.
- **mask** – Only attributes with bits set here will be changed.

Returns:

0 on success. -1 on error.

A regs:

return, mask

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_NO\_FILE, FR\_NO\_PATH, FR\_INVALID\_NAME, FR\_WRITE\_PROTECTED, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT, FR\_NOT\_ENOUGH\_CORE

| Attribute | Bit |
| --- | --- |
| Read Only | 0x01 |
| Hidden | 0x02 |
| System | 0x04 |
| Directory | 0x10 |
| Archive | 0x20 |

### UTIME

int f\_utime(const char \*path, unsigned fdate, unsigned ftime, unsigned crdate, unsigned crtime) [¶](#c.f_utime "Link to this definition")  

Update the date and time stamps of a file or directory. A date of 0 (invalid) leaves the date and time unchanged.

Op code:

RIA\_OP\_UTIME 0x27

C proto:

rp6502.h

Parameters:

- **path** – Pathname to a file or directory.
- **fdate** – Modification date.
- **ftime** – Modification time.
- **crdate** – Creation date.
- **crtime** – Creation time.

Returns:

0 on success. -1 on error.

A regs:

return, mask

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_NO\_FILE, FR\_NO\_PATH, FR\_INVALID\_NAME, FR\_WRITE\_PROTECTED, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT, FR\_NOT\_ENOUGH\_CORE

| bit15:9 | Years since 1980 (0..127) |
| --- | --- |
| bit8:5 | Month (1..12) |
| bit4:0 | Day (1..31) |

| bit15:11 | Hour (0..23) |
| --- | --- |
| bit10:5 | Minute (0..59) |
| bit4:0 | Second / 2 (0..29) |

### MKDIR

int f\_mkdir(const char \*name) [¶](#c.f_mkdir "Link to this definition")  

Make a new directory entry.

Op code:

RIA\_OP\_MKDIR 0x28

C proto:

rp6502.h

Parameters:

- **name** – Pathname of the directory to create.

Returns:

0 on success. -1 on error.

A regs:

return

Errno:

FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_NO\_PATH, FR\_INVALID\_NAME, FR\_DENIED, FR\_EXIST, FR\_WRITE\_PROTECTED, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT, FR\_NOT\_ENOUGH\_CORE

### CHDIR

int chdir(const char \*name) [¶](#c.chdir "Link to this definition")  

Change to a directory entry.

Op code:

RIA\_OP\_CHDIR 0x29

C proto:

unistd.h

Parameters:

- **name** – Pathname of the directory to make current.

Returns:

0 on success. -1 on error.

A regs:

return

Errno:

FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_NO\_PATH, FR\_INVALID\_NAME, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT, FR\_NOT\_ENOUGH\_CORE

### CHDRIVE

int f\_chdrive(const char \*name) [¶](#c.f_chdrive "Link to this definition")  

Change the current drive. Valid names are `USB0:`– `USB9:` with shortcuts `0:`– `9:`.

Op code:

RIA\_OP\_CHDRIVE 0x2A

C proto:

rp6502.h

Parameters:

- **name** – Drive name to change to.

Returns:

0 on success. -1 on error.

A regs:

return

Errno:

FR\_INVALID\_DRIVE

### GETCWD

int f\_getcwd(char \*name, int size) [¶](#c.f_getcwd "Link to this definition")  

Get the current working directory. Size is ignored by the OS but the C wrapper will use it.

Op code:

RIA\_OP\_GETCWD 0x2B

C proto:

rp6502.h

Parameters:

- **name** – The returned directory.

Returns:

Size of returned name. -1 on error.

Errno:

ENOMEM, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT, FR\_NOT\_ENOUGH\_CORE

### SETLABEL

int f\_setlabel(const char \*name) [¶](#c.f_setlabel "Link to this definition")  

Change the volume label. Max 11 characters.

Op code:

RIA\_OP\_SETLABEL 0x2C

C proto:

rp6502.h

Parameters:

- **name** – Label with optional volume name.

Returns:

0 on success. -1 on error.

A regs:

return

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_INVALID\_NAME, FR\_WRITE\_PROTECTED, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT

### GETLABEL

int f\_getlabel(const char \*path, char \*label) [¶](#c.f_getlabel "Link to this definition")  

Get the volume label. Label must have room for (22+1) bytes.

Op code:

RIA\_OP\_GETLABEL 0x2D

C proto:

rp6502.h

Parameters:

- **name** – Volume name.
- **label** – Storage for returned label.

Returns:

Size of returned label. -1 on error.

A regs:

return

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT

### GETFREE

int f\_getfree(const char \*name, unsigned long \*free, unsigned long \*total) [¶](#c.f_getfree "Link to this definition")  

```c
struct {
   unsigned long free;
   unsigned long total;
};
```

Get the volume free and total space in number of 512 bytes blocks.

Op code:

RIA\_OP\_GETFREE 0x2E

C proto:

rp6502.h

Parameters:

- **name** – Volume name.
- **free** – Storage for returned value.
- **total** – Storage for returned value.

Returns:

0 on success. -1 on error.

A regs:

return

Errno:

EINVAL, FR\_DISK\_ERR, FR\_INT\_ERR, FR\_NOT\_READY, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM, FR\_TIMEOUT

### EXIT

void exit(int status) [¶](#c.exit "Link to this definition")  

Halt the 6502 and return the console to RP6502 monitor control. This is the only operation that does not return. The OS pulls RESB low before the next instruction can execute. The status argument is currently unused but reserved for future use.

In general, dropping the user back to the monitor is discouraged. But calling exit() or falling off main() is preferred to locking up.

Op code:

RIA\_OP\_EXIT 0xFF

C proto:

stdlib.h

A regs:

status

Parameters:

- **status** – 0 is success, 1-255 for error.

## Launcher

The launcher is a mechanism in the RP6502 process manager that lets one ROM serve as a persistent host for all others. A ROM registers itself as the launcher by setting `RIA_ATTR_LAUNCHER` to 1 via. Once registered, the process manager automatically re-executes the launcher ROM whenever any subsequently launched ROM stops. When the launcher ROM itself stops, the chain ends, the registration is cleared, and control returns to the console monitor.

The launcher ROM decides what to run next by calling and may pass arguments to the new ROM via argv. The launched ROM retrieves those arguments with.

There are two keystrokes to stop a running ROM. A Ctrl-Alt-Del break will stop the running ROM and clears the launcher registration at any time. Pressing Alt-F4 will stop the running ROM and return to the launcher. If the ROM was run from the monitor, Alt-F4 will return to the monitor. Pressing Alt-F4 while the registered laucher ROM is itself running will do nothing, it won’t stop the ROM. This makes Alt-F4 the best keystroke to terminate a ROM and stay within your preferred launcher framework, while Ctrl-Alt-Del always returns you to the monitor for when you need to do system maintenance.

### Native OS Boot Sequence

A more powerful use is as the foundation for a native 6502 operating system. A small launcher ROM is installed to the RIA as the boot ROM using the `set boot` command in the monitor. When the Picocomputer powers on or reboots, the process manager loads this launcher ROM automatically.

The launcher ROM reads its own argv — supplied by any arguments appended to the `set boot` command — then searches the mounted drive for the OS ROM and calls to launch it, forwarding any relevant arguments. By design, the OS cannot alter the launcher ROM; OS launchers are meant to stay simple and trustworthy. This indirection provides important capabilities:

- **Fault recovery** — If the OS kernel encounters a fatal error it cannot handle internally, it calls rather than locking up. The process manager re-executes the launcher, which can choose to relaunch the kernel or take some other action.
- **Self-update** — An OS can prepare its own ROM update and call. The launcher detects the pending update, applies it, and boots the new OS ROM — achieving an in-place update without requiring a manual reset.

## RIA Attributes

RIA attributes are 31-bit values identified by an 8-bit ID. They are accessed with and. Both functions succeed for any valid attribute ID. Attempting to get or set an unknown ID returns -1 with `errno` set to `EINVAL`. Attempting to set a get-only attribute also returns -1 with `EINVAL`.

| ID / Name | Description |
| --- | --- |
| 0x00  `RIA_ATTR_ERRNO_OPT` | Errno mapping option. Selects which set of errno constants the OS uses. Both cc65 and llvm-mos set this automatically at C runtime startup; assembly programs must set it before making OS calls that can fail. See for option values. |
| 0x01  `RIA_ATTR_PHI2_KHZ` | CPU clock speed in kHz. Range 100–8000. Changes take effect immediately and revert to the system setting when the ROM stops. |
| 0x02  `RIA_ATTR_CODE_PAGE` | Active OEM code page used by the filesystem, console, and default [VGA](https://picocomputer.github.io/vga.html) font. Reverts to the system setting when the ROM stops. If the requested page is unavailable, the system setting is selected; follow a set with a get to confirm the result. One of: 437, 720, 737, 771, 775, 850, 852, 855, 857, 860, 861, 862, 863, 864, 865, 866, 869, 932, 936, 949, 950. |
| 0x03  `RIA_ATTR_RLN_LENGTH` | Maximum input line length for the stdin line editor. 1–255, default 254. |
| 0x04  `RIA_ATTR_LRAND` | 31-bit hardware random number seeded with entropy from the RIA. Returns a value in the range 0x0 to 0x7FFFFFFF. Suitable for seeding a PRNG or direct use. The 16-bit `rand()` in the cc65 library can be seeded with this by calling `_randomize()`. |
| 0x05  `RIA_ATTR_BEL` | BEL (`\a`) output enable on the console UART. 0 silences the alert; 1 (default) enables it. |
| 0x06  `RIA_ATTR_LAUNCHER` | Launcher flag. Set to 1 to register the current ROM as the launcher; set to 0 to deregister. See the section for full details and usage patterns. |
| 0x07  `RIA_ATTR_EXIT_CODE` | **experimental** The exit code of the last ROM to exit. |

## ERRNO\_OPT Compiler Constants

OS calls will set `RIA_ERRNO` when an error occurs. The errno option selects which numeric values to use because cc65 and llvm-mos each define their own errno constants. Both compilers set this automatically in their C runtime. Assembly programs must set `RIA_ATTR_ERRNO_OPT` before any OS call that can fail. `errno` in C maps directly to `RIA_ERRNO`.

The OS maps FatFs errors onto errno. RP6502 emulation and simulation software is expected to map their native errors as well. The table below shows the FatFs mappings. Because FatFs is so integral to the OS, calls are documented here with their native FatFs errors to assist when cross referencing the [FatFs documentation](https://elm-chan.org/fsw/ff/).

|  | cc65 | llvm\_mos | FatFs |
| --- | --- | --- | --- |
| option | 1 | 2 |  |
| ENOENT | 1 | 2 | FR\_NO\_FILE, FR\_NO\_PATH |
| ENOMEM | 2 | 12 | FR\_NOT\_ENOUGH\_CORE |
| EACCES | 3 | 23 | FR\_DENIED, FR\_WRITE\_PROTECTED |
| ENODEV | 4 | 19 | FR\_NOT\_READY, FR\_INVALID\_DRIVE, FR\_NOT\_ENABLED, FR\_NO\_FILESYSTEM |
| EMFILE | 5 | 24 | FR\_TOO\_MANY\_OPEN\_FILES |
| EBUSY | 6 | 16 | FR\_LOCKED |
| EINVAL | 7 | 22 | FR\_INVALID\_NAME, FR\_INVALID\_PARAMETER |
| ENOSPC | 8 | 28 |  |
| EEXIST | 9 | 17 | FR\_EXIST |
| EAGAIN | 10 | 11 | FR\_TIMEOUT |
| EIO | 11 | 5 | FR\_DISK\_ERR, FR\_INT\_ERR, FR\_MKFS\_ABORTED |
| EINTR | 12 | 4 |  |
| ENOSYS | 13 | 38 |  |
| ESPIPE | 14 | 29 |  |
| ERANGE | 15 | 34 |  |
| EBADF | 16 | 9 | FR\_INVALID\_OBJECT |
| ENOEXEC | 17 | 8 |  |
| EDOM | 18 | 33 |  |
| EILSEQ | 18 | 84 |  |
| EUNKNOWN | 18 | 85 |  |