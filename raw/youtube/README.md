# YouTube Transcripts — RP6502

Auto-caption transcripts of the official Picocomputer 6502 YouTube series, fetched via `yt-dlp` and converted from VTT to markdown.

## Naming convention

```
<video-id>-<sanitized-title>.md
```

Example: `GOEI2OpMncY-RP6502 Ep2 - 6502 reads Raspberry Pi Pico @ 8 MHz - PIO and DMA.md`

## Files

Source playlist: **[Picocomputer 6502](https://www.youtube.com/playlist?list=PLvCRDUYedILfHDoD57Yj8BAXNmNJLVM2r)** (rumbledethumps / Rumbledethumps).

Retrieved: 2026-04-17.

| # | Title | Video ID | URL | Transcript |
| --- | --- | --- | --- | --- |
| 1 | The start of an 8-bit Retro Gaming Computer | `SVZaSRUhIjo` | https://www.youtube.com/watch?v=SVZaSRUhIjo | ✅ |
| 2 | 6502 reads Raspberry Pi Pico @ 8 MHz - PIO and DMA | `GOEI2OpMncY` | https://www.youtube.com/watch?v=GOEI2OpMncY | ✅ |
| 3 | Writing to the Raspberry Pi Pico - More PIO and DMA | `wxV6x5BUMH4` | https://www.youtube.com/watch?v=wxV6x5BUMH4 | ✅ |
| 4 | The Picocomputer says hello! | `uL8BL7ZDdlk` | https://www.youtube.com/watch?v=uL8BL7ZDdlk | ✅ |
| 5 | A short BASIC demo | `szCiDvR06ws` | https://www.youtube.com/watch?v=szCiDvR06ws | ⏭ no captions available |
| 6 | ROMs and the filesystem - TinyUSB and FatFs | `9u82Uy_458E` | https://www.youtube.com/watch?v=9u82Uy_458E | ✅ |
| 7 | The Operating System - featuring Colossal Cave Adventure | `kf-mvyL70bc` | https://www.youtube.com/watch?v=kf-mvyL70bc | ✅ |
| 8 | VGA Graphics and the PIX bus | `yh26kSxFnvY` | https://www.youtube.com/watch?v=yh26kSxFnvY | ✅ |
| 9 | C Programming Setup | `YP90d0YI9Qc` | https://www.youtube.com/watch?v=YP90d0YI9Qc | ✅ |
| 10 | DIY build with soldering | `bwgLXEQdq20` | https://www.youtube.com/watch?v=bwgLXEQdq20 | ✅ |
| 11 | No soldering and no breadboard | `4CjouKoCMUw` | https://www.youtube.com/watch?v=4CjouKoCMUw | ✅ |
| 12 | Fonts and Vsync and Versioning | `CcatgIZI--Y` | https://www.youtube.com/watch?v=CcatgIZI--Y | ✅ |
| 13 | Graphics Programming | `QVvH03OSVf0` | https://www.youtube.com/watch?v=QVvH03OSVf0 | ✅ |
| 14 | USB Mouse on a 6502 | `e1c91LBn-b8` | https://www.youtube.com/watch?v=e1c91LBn-b8 | ✅ |
| 15 | Asset Management and More Graphics | `s6BZ5MKbLEk` | https://www.youtube.com/watch?v=s6BZ5MKbLEk | ✅ |
| 16 | Programmable Sound Generator Intro | `UxFtKBV5d8A` | https://www.youtube.com/watch?v=UxFtKBV5d8A | ✅ |
| 17 | The basics of BASIC | `Y3_pkzlLjtk` | https://www.youtube.com/watch?v=Y3_pkzlLjtk | ✅ |
| 18 | Are you keeping up with LLVM-MOS? | `xkolkC1RgOY` | https://www.youtube.com/watch?v=xkolkC1RgOY | ✅ |
| 19 | Programming the Game of Life on a 6502 | `ZsH-SggoK_Y` | https://www.youtube.com/watch?v=ZsH-SggoK_Y | ✅ |
| 20 | The 6502 calls a BBS | `7U__9tsimOA` | https://www.youtube.com/watch?v=7U__9tsimOA | ✅ |
| 21 | Programming a 6502 with AI | `tZmbrMx5vy8` | https://www.youtube.com/watch?v=tZmbrMx5vy8 | ✅ |
| 22 | Graphics and Sound Demos | `MPlms833KOU` | https://www.youtube.com/watch?v=MPlms833KOU | ✅ |

**Coverage**: 21/22 transcripts retrieved. Ep5 has no captions (silent demo — no narration).

## Refresh procedure

To fetch transcripts for new episodes:

```bash
cd raw/youtube
~/.local/bin/yt-dlp --skip-download --write-subs --write-auto-subs \
    --sub-langs "en.*,en" --sub-format "vtt" --convert-subs "vtt" \
    -o "%(id)s-%(title)s.%(ext)s" \
    "https://www.youtube.com/playlist?list=PLvCRDUYedILfHDoD57Yj8BAXNmNJLVM2r"
python3 /tmp/vtt_to_md.py   # cleans VTT -> markdown, removes .vtt files
```

Preference order for caption language variant: `en-US` (manual) > `en` > `en-orig` > `en-en` > `en-en-US`.

After fetching, add new rows to the ## Files table above and update `raw/README.md`.
