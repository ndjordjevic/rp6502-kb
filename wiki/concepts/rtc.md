---
type: concept
tags: [rp6502, rtc, time, posix, clock]
related:
  - "[[rp6502-ria]]"
  - "[[rp6502-ria-w]]"
  - "[[examples]]"
sources:
  - "[[rp6502-ria-docs]]"
  - "[[examples]]"
created: 2026-04-18
updated: 2026-04-18
---

# Real-Time Clock (RTC)

**Summary**: The RP6502-OS provides standard POSIX time APIs (`time()`, `gmtime()`, `localtime()`, `strftime()`) backed by the RIA's hardware RTC — no RP6502-specific calls needed.

---

## Usage

```c
#include <time.h>

time_t now = time(NULL);           // seconds since Unix epoch

struct tm *utc   = gmtime(&now);   // UTC struct
struct tm *local = localtime(&now); // local time (applies timezone + DST)

char buf[64];
strftime(buf, sizeof(buf), "UTC  : %c", utc);
puts(buf);
strftime(buf, sizeof(buf), "Local: %c %Z", local);
puts(buf);
```

From `rtc.c` — this is the complete example. No hardware-specific setup required.

---

## Notes

- **Timezone and DST**: `localtime()` respects the timezone configured on the RIA (set via the monitor or `ria_attr_set`).
- **NTP sync** (RIA-W only): When connected to WiFi, the RP6502-RIA-W synchronizes the RTC via NTP. See [[rp6502-ria-w]].
- `clock_t` and `clock()`: the `bench.c` example uses `clock()` / `CLOCKS_PER_SEC` for timing I/O throughput; works as expected.
- **Fixed-time testing**: pass a literal `time_t` value to `gmtime()`/`localtime()` to test timezone and DST handling without waiting for wall clock.

---

## Related pages

- [[rp6502-ria]] — hardware RTC is part of the RIA firmware
- [[rp6502-ria-w]] — NTP time sync over WiFi
- [[performance]] — `clock()` usage in storage benchmarking
