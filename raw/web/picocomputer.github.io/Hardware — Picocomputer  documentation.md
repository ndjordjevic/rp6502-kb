---
title: "Hardware — Picocomputer  documentation"
source: "https://picocomputer.github.io/hardware.html"
author:
published:
created: 2026-04-15
description:
tags:
  - "clippings"
---
## Hardware

The Picocomputer 6502 is a homebrew computer you build yourself. You don’t need to understand the electronics, you don’t need to solder, but you will need to plug the eight ICs into their sockets.

All parts are currently in production. The Raspberry Pi Pico 2 will remain in production until at least [January 2040](https://www.raspberrypi.com/products/raspberry-pi-pico-2/). The hardware design has already survived the Pico 1 to Pico 2 transition. The manufacturing lifetime of this project should extend into an era of democratized hobbyist ASICs.

## Schematic

[Picocomputer 6502](https://picocomputer.github.io/_static/2026-01-26-rp6502.pdf) (pdf)

## Buying a Picocomputer

You will need to place two orders. First, for the Printed Circuit Board (PCB). Second, for the electronic components. Some PCB factories will do the soldering for you, but you’ll still need to order the ICs and plug them into sockets.

I have circuit boards in a [Ko-fi store](https://ko-fi.com/rumbledethumps) that ships only to the United States. International shipping is either too slow or too expensive when compared to getting boards made locally or in China.

USA import tariffs are not an issue with this project. Orders to my store and Mouser ship from the USA, so you won’t get a surprise bill from the courier.

## Step 0. Read This

Rev. A and Rev. B circuit boards are identical except for the debug connectors under the RIA. These do nothing even when connected. They were removed so folks would stop asking about them.

Most VGA-to-HDMI cables can get power from the Picocomputer. Some will need external power applied. All are zero lag. All VGA video output uses only HDMI-compatible timings, so these cables are an ideal solution.

The boot message does not say COLOR anymore. Do not assume your device will behave exactly the same as an old YouTube video.

## Step 1. Watch the Videos

To solder, or not to solder, that is the question. We’re living in the future. You can homebrew a 6502 without a soldering iron. Choose your path:

[Here’s the video where I build one without soldering.](https://youtu.be/4CjouKoCMUw)

[Here’s the video where I solder one myself.](https://youtu.be/bwgLXEQdq20)

## Step 2. Order Printed Circuit Boards

Order from the project page at [PCBWay](https://www.pcbway.com/project/shareproject/Picocomputer_6502_RP6502_Rev_B_1f41cb0b.html) or download [the gerbers](https://picocomputer.github.io/_static/rp6502-revb-gerbers.zip) to have the boards made anywhere you prefer.

Gerbers are like PDFs for circuit boards. You’ll be asked to upload these; simply upload the zip file from above. The PCB manufacturer’s website should detect that this is a two-layer 150x100mm board.

PCB manufacturers that welcome hobbyists have optimized their basic services for production in multiples of five. You won’t be able to order only one board.

There are a ton of options you can change if you like. The defaults will get you a classic green and white board with lead (Pb) HASL. Consider getting the lead-free HASL upgrade if the other four boards will be kicking around in a drawer for the next 20 years.

## Step 3. Order Assembly

Skip this step if you want to solder it yourself.

PCBWay has a minimum quantity of one for assembly. They will use the boards from step 2. The result is a “board of sockets” - you install the ICs yourself later. Parts availability should never be a constraint; every component has multiple vendors.

Download [the BOM, notes, and photos](https://picocomputer.github.io/_static/rp6502-revb-assembly.zip).

Request assembly with your PCB order and send the [BOM, notes, and photos](https://picocomputer.github.io/_static/rp6502-revb-assembly.zip). There is no centroid file because there are no surface mount parts. The default options will work. Let them source the parts. Let them make substitutions.

Expect a short delay while they quote the bill of materials. Then pay and wait. They estimated four weeks; mine arrived in three.

If they have a question, make sure both you and your sales rep read the notes you sent them. If you have a question about options on their website, ask your sales rep before asking on the forums. They help people all day long with projects far more complex than this. Even if you don’t understand what you are doing, they can figure it out by looking at the zip files. Really, they do this all day long, and will probably enjoy the easy win.

## Step 5. Pi Pico Firmware

Download the [UF2 files](https://github.com/picocomputer/rp6502/releases).

To load firmware on a Pi Pico 2, hold its BOOTSEL button down while plugging it into a computer. The Pi Pico 2 will appear as a storage device. Copy the RIA W UF2 file to make a [RP6502-RIA-W](https://picocomputer.github.io/ria_w.html) and the VGA UF2 file to make a [RP6502-VGA](https://picocomputer.github.io/vga.html). It should take less than 30 seconds to copy. The LED turns on when done.

## Acrylic Sandwich Case

The circuit board is 150 x 100mm (4x6 inches). I regularly see vendors on Amazon and eBay selling 150 x 100 x 3mm acrylic sheets. You’ll need to drill 3mm holes for M3 standoffs. Use standoffs of at least 16 mm for the top and 3.5 mm for the bottom.

## Full Parts List (All Components)

[All Parts CSV](https://picocomputer.github.io/_static/rp6502-revb-full.csv)

| Qty | Reference | Description | Mfr Name | Mfr Part Number | Mouser Part Number |
| --- | --- | --- | --- | --- | --- |
| 10 | C1-C9, C11 | 0.1μF Ceramic Capacitor | Vishay | A104M15X7RF5TAA | 594-A104M15X7RF5TAA |
| 2 | C10, C12 | 47μF Ceramic Capacitor | TDK | FG22X5R1A476MNT06 | 810-FG22X5R1A476MNT6 |
| 4 | R1, R6, R11, R18 | 8.06k resistor 1% | YAGEO | MFR-25FBF52-8K06 | 603-MFR-25FBF52-8K06 |
| 3 | R2, R7, R12 | 4.02k resistor 1% | YAGEO | MFR-25FBF52-4K02 | 603-MFR-25FBF52-4K02 |
| 3 | R3, R8, R13 | 2k resistor 1% | YAGEO | MFR-25FBF52-2K | 603-MFR-25FBF52-2K |
| 2 | R21, R24 | 1.8k resistor 1% | YAGEO | MFR-25FBF52-1K8 | 603-MFR-25FBF52-1K8 |
| 3 | R4, R9, R14 | 1k resistor 1% | YAGEO | MFR-25FBF52-1K | 603-MFR-25FBF52-1K |
| 3 | R5, R10, R15 | 499 ohm resistor 1% | YAGEO | MFR-25FBF52-499R | 603-MFR-25FBF52-499R |
| 2 | R19, R22 | 220 ohm resistor 1% | YAGEO | MFR-25FBF52-220R | 603-MFR-25FBF52-220R |
| 2 | R20, R23 | 100 ohm resistor 1% | YAGEO | MFR-25FBF52-100R | 603-MFR-25FBF52-100R |
| 2 | R16, R17 | 47 ohm resistor 1% | YAGEO | MFR-25FBF52-47R | 603-MFR-25FBF52-47R |
| 1 | U2 | Raspberry Pi Pico 2 W with headers | Raspberry Pi | SC1634 | 358-SC1634 |
| 1 | U4 | Raspberry Pi Pico 2 with headers | Raspberry Pi | SC1632 | 358-SC1632 |
| 1 | U1 | WDC W65C02S | WDC | W65C02S6TPG-14 | 955-W65C02S6TPG-14 |
| 1 | U5 | WDC W65C22S | WDC | W65C22S6TPG-14 | 955-W65C22S6TPG-14 |
| 1 | U3 | 128k RAM AS6C1008 | Alliance | AS6C1008-55PCN | 913-AS6C1008-55PCN |
| 1 | U6 | 74AC00 Quad NAND | TI | CD74AC00E | 595-CD74AC00E |
| 1 | U7 | 74AC02 Quad NOR | TI | CD74AC02E | 595-CD74AC02E |
| 1 | U8 | 74HC30 8-input NAND | TI | CD74HC30E | 595-CD74HC30E |
| 1 | J1 | GPIO 2x12 Pin Header | Amp | 10129381-924001BLF | 649-1012938192401BLF |
| 1 | J2 | PIX 2x6 Pin Header | Amp | 10129381-912001BLF | 649-1012938191201BLF |
| 4 | U2, U4 | Pico 20 Pin Socket | Wurth | 61302011821 | 710-61302011821 |
| 1 | J3 | VGA Jack | Amp | L77HDE15SD1CH4FVGA | 523-7HDE15SD1CH4FVGA |
| 1 | J4 | Audio Jack | CUI | SJ1-3525NG-GR | 490-SJ1-3525NG-GR |
| 1 | SW1 | Reset Button | CUI | TS11-674-43-BK-160-RA-D | 179-TS1167443160RAD |
| 3 | U6, U7, U8 | 14-pin IC Socket | TE | 1-2199298-3 | 571-1-2199298-3 |
| 1 | U3 | 32-pin IC Socket | TE | 1-2199300-2 | 571-1-2199300-2 |
| 2 | U1, U5 | 40-pin IC Socket | TE | 1-2199299-5 | 571-1-2199299-5 |
| 4 | PCB | Stick-on Bumper Feet | Essentra | ASPR-8-125 | 144-ASPR-8-125 |

## Active Parts List (ICs Only)

[Active Parts CSV](https://picocomputer.github.io/_static/rp6502-revb-active.csv)

| Qty | Reference | Description | Mfr Name | Mfr Part Number | Mouser Part Number |
| --- | --- | --- | --- | --- | --- |
| 1 | U2 | Raspberry Pi Pico 2 W with headers | Raspberry Pi | SC1634 | 358-SC1634 |
| 1 | U4 | Raspberry Pi Pico 2 with headers | Raspberry Pi | SC1632 | 358-SC1632 |
| 1 | U1 | WDC W65C02S | WDC | W65C02S6TPG-14 | 955-W65C02S6TPG-14 |
| 1 | U5 | WDC W65C22S | WDC | W65C22S6TPG-14 | 955-W65C22S6TPG-14 |
| 1 | U3 | 128k RAM AS6C1008 | Alliance | AS6C1008-55PCN | 913-AS6C1008-55PCN |
| 1 | U6 | 74AC00 Quad NAND | TI | CD74AC00E | 595-CD74AC00E |
| 1 | U7 | 74AC02 Quad NOR | TI | CD74AC02E | 595-CD74AC02E |
| 1 | U8 | 74HC30 8-input NAND | TI | CD74HC30E | 595-CD74HC30E |
| 4 | PCB | Stick-on Bumper Feet | Essentra | ASPR-8-125 | 144-ASPR-8-125 |

## Pi Picos Parts List

Alternative part numbers for the Pi Picos.

| Qty | Reference | Description | Mfr Name | Mfr Part Number | Mouser Part Number |
| --- | --- | --- | --- | --- | --- |
| 1 | U2 | Raspberry Pi Pico 2 W no headers | Raspberry Pi | SC1633 | 358-SC1633 |
| 1 | U4 | Raspberry Pi Pico 2 no headers | Raspberry Pi | SC1631 | 358-SC1631 |
| 4 | U2, U4 | Pico 20 Pin Header (2 per Pico) | Amp | 10129378-920001BLF | 649-1012937892001BLF |

## Parts Substitution

All resistors are <= 1% tolerance. Any power rating. Leads must fit 0.8mm plated holes spaced 10mm apart. Recommended size is approximately 0.1” x 0.25” (2.4-2.6mm x 6-8mm).

0.1 μF ceramic capacitors are available in axial packaging (like resistors) but you may use classic radial (disc) capacitors if you prefer. Leads must fit 0.8mm plated holes spaced 10mm apart. Only a voltage of >=10V is required. Tolerance and temperature coefficient do not matter.

Yes, 47 μF ceramic capacitors are expensive, but you only need two and they never leak. Leads must fit 0.8mm plated holes spaced 5mm apart. Only a voltage of >=10V is required. Tolerance and temperature coefficient do not matter.

The CUI audio jack is available in many colors and with optional switches. The switches are unused, but the board accepts the extra leads.

The REBOOT switch is available from multiple manufacturers in various lengths, colors, and activation forces. Nothing matters except that it’s “momentary on”.

The VGA jack is available from multiple manufacturers. This style has been around since the beginning, so if it looks like it’ll fit then it probably will. Newer VGA jacks are designed to use less PCB space or be oven soldered and will be visibly different enough to avoid.

The 74xx ICs must be true CMOS. Use AC or HC, do not use ACT or HCT. Two out of three must be AC for 8MHz. You may use 74HC00 and 74HC02 instead of AC, but 8MHz will not be achievable. I’ve never seen a DIP 74AC30, but if you find one then it would be preferred over the 74HC30.

The RAM IC is 128k because 2x32k is more expensive. Speed must be <=70ns for 8MHz.

The WDC W65C02S and W65C22S must not be substituted. Do not attempt to use NMOS chips (without the C in the number). Some older CMOS designs may work but there are no plans to support out-of-production ICs.

Only the Raspberry Pi design of the Pi Pico 2 has been tested. Both original and “H” (header) versions work great. Pin-compatible alternatives usually work, check the forums. The 3-pin SWD connection on the Pi Pico RIA is no longer used and may be ignored when looking for alternatives.