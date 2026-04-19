---
type: entity
tags: [rp6502, ria, wireless, wifi, bluetooth, pico2w]
related:
  - "[[rp6502-ria]]"
  - "[[rp6502-board]]"
  - "[[dual-core-sio]]"
sources:
  - "[[rp6502-ria-w-docs]]"
  - "[[release-notes]]"
  - "[[fairhead-pico-c]]"
  - "[[youtube-playlist]]"
created: 2026-04-15
updated: 2026-04-18
---

# RP6502-RIA-W

**Summary**: A **strict superset of [[rp6502-ria]]**: same firmware family, flashed onto a Raspberry Pi Pico 2 **W**, adds WiFi, BLE, NTP, and Hayes modem emulation.

---

## Hardware role

- Occupies slot **U2** on the [[rp6502-board]] (Raspberry Pi Pico 2 W — the only difference from slot U4 is that U2 has the wireless radio).
- All RIA features from [[rp6502-ria]] are present; this page only covers the wireless additions.

## WiFi (Wi-Fi 4 / 802.11n)

Configured from the monitor:

| Command | Effect |
| --- | --- |
| `SET RF 0`/`1` | Disable / enable all radios without touching settings |
| `SET RFCC <cc>` or `-` | Country code (e.g. `US`, `GB`); `-` = worldwide default |
| `SET SSID <name>` or `-` | Network SSID |
| `SET PASS <pw>` or `-` | Network password |
| `status` | Show current WiFi state |

Once associated, NTP runs automatically. Set time zone with `SET TZ`; DST handled automatically. See [[rp6502-os]] for the programmatic clock API.

## Telnet Console

Remote network access to the RP6502 monitor (or running 6502 app stdio) over TCP.

| Command | Effect |
| --- | --- |
| `SET PORT <port>` or `0` | TCP listening port (`0` disables; standard telnet = 23) |
| `SET KEY <key>` or `-` | Passkey required to connect; `-` clears |

Both PORT and KEY must be configured to enable the telnet console. Connections are **unencrypted** in transit.

## Hayes modem emulation

Lets 6502 apps dial into BBSs over raw TCP or telnet. Supports up to **four simultaneous modem devices**.

**Device names:** `AT:` (transient, factory defaults, no storage) or `AT0:`–`AT9:` (10 persistent profiles with flash-backed settings and 4-slot phonebook).

| AT command | Effect |
| --- | --- |
| `ATA` | Answer incoming call |
| `ATD<host>:<port>` | Dial host:port |
| `ATDS=<0-3>` | Dial saved phonebook entry |
| `+++` | Escape to command mode |
| `ATH` | Hang up |
| `ATO` | Return to active call |
| `ATE1`, `ATQ0`, `ATV1`, `ATX0` | Echo / quiet / verbosity / progress messaging |
| `ATSxxx?` / `ATSxxx=yyy` | Register query / set |
| `AT&F` / `ATZ` / `AT&W` | Factory / reload / save profile |
| `AT&V` | View profile, phonebook, and network settings |
| `AT&Z<0-3>=<host>:<port>` | Save phonebook entry |
| `AT\L=<port>` / `AT\L?` | Modem listen port for incoming calls |
| `AT\N0`/`AT\N1` / `AT\N?` | Network mode: 0 = raw TCP, 1 = telnet |
| `AT\T=<type>` / `AT\T?` | Telnet terminal type advertisement |
| `AT+RF=`, `AT+RFCC=`, `AT+SSID=`, `AT+PASS=` | Expose same-named RIA settings via AT |

Connections are **unencrypted** in transit.

## Bluetooth

- **BLE only**. Bluetooth Classic (BR/EDR) is **not** supported.
- `set ble 2` → pairing mode (LED blinks). Put the peripheral into its own pairing mode; bond is remembered.
- Pairs with BLE keyboards, mice, gamepads. BLE has been ubiquitous since BT 4.0 (2010).

---

## WiFi SDK internals

*Based on [[fairhead-pico-c]] Ch.16. Explains the stack the RIA-W firmware uses.*

### CYW43439 hardware wiring

The CYW43439 WiFi chip connects to the RP2350 via SD 1-bit SPI (single bidirectional data line) using GPIO23–29. This conflicts with several Pico pin functions:

| GPIO | Pico function (Pico 1/2) | Pico W / RIA-W function |
|---|---|---|
| GPIO23 | SMPS power save | Wireless power-on signal |
| GPIO24 | VBUS sense | IRQ to CYW43439 |
| GPIO25 | Onboard LED | (unavailable — driven by WiFi chip) |
| GPIO29 | ADC3 / VSYS monitor | ADC3 / VSYS during non-SPI time |

The LED is now a CYW43439 GPIO line, controlled only through the driver — **not via GPIO25**:
```c
cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 1);  // LED on
cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 0);  // LED off
```

CYW43439 WL GPIO lines:
- `WL_GPIO0` → connected to user LED
- `WL_GPIO1` → controls onboard SMPS power save
- `WL_GPIO2` → VBUS sense (high if VBUS/USB power is present)

### WiFi stack layers

```
cyw43_driver          ← low-level SPI driver; ignore except for AP scan and power mgmt
pico_cyw43_arch       ← initialization, connection, mode selection, WL_GPIO
pico_lwip             ← LwIP TCP/IP stack wrappers
```

### Operating modes

The operating mode is selected by which library is linked in `CMakeLists.txt`:

| Library | Mode | Notes |
|---|---|---|
| `pico_cyw43_arch_lwip_poll` | Polling | Call `cyw43_arch_poll()` every ~1 ms; fully synchronous; NOT multicore or interrupt safe |
| `pico_cyw43_arch_lwip_threadsafe_background` | Background interrupt | Multi-core and interrupt safe; all LwIP calls must be bracketed |
| `pico_cyw43_arch_none` | No WiFi | LED access only |
| `pico_cyw43_arch_lwip_sys_freertos` | FreeRTOS | See [[dual-core-sio]] FreeRTOS section |

**RIA-W uses background mode** — it runs two cores and must be multi-core safe. Any LwIP call outside a LwIP callback must be bracketed:
```c
cyw43_arch_lwip_begin();
// ... LwIP calls here ...
cyw43_arch_lwip_end();
// OR:
async_context_acquire_lock_blocking(cyw43_arch_async_context());
async_context_release_lock(cyw43_arch_async_context());
```

### cyw43_arch connection API

```c
// Initialize (set country code for allowed channels/power)
cyw43_arch_init_with_country(CYW43_COUNTRY_WORLDWIDE);  // or specific country
cyw43_arch_enable_sta_mode();             // client mode

// Connect (blocking — simple; async — allows LED feedback during connect)
cyw43_arch_wifi_connect_blocking(ssid, pass, CYW43_AUTH_WPA2_MIXED_PSK);
cyw43_arch_wifi_connect_async(ssid, pass, auth);

// Check status (async only)
int s = cyw43_tcpip_link_status(&cyw43_state, CYW43_ITF_STA);
// s < 0 = error; s == CYW43_LINK_UP = connected
```

Auth constants: `CYW43_AUTH_OPEN`, `CYW43_AUTH_WPA_TKIP_PSK`, `CYW43_AUTH_WPA2_AES_PSK`, **`CYW43_AUTH_WPA2_MIXED_PSK`** (recommended).

### LwIP NETIF — reading connection details

After connection, `netif_default` struct is populated:
```c
ip4addr_ntoa(netif_ip_addr4(netif_default))     // IP address string
ip4addr_ntoa(netif_ip_netmask4(netif_default))  // subnet mask
ip4addr_ntoa(netif_ip_gw4(netif_default))       // gateway
netif_get_hostname(netif_default)               // hostname ("PicoW" default)
```

Set hostname before connecting; set static IP after connection completes:
```c
cyw43_arch_enable_sta_mode();
netif_set_hostname(netif_default, "MyRIA-W");
cyw43_arch_wifi_connect_async(ssid, pass, auth);
// ... wait for CYW43_LINK_UP ...
ip_addr_t ip; IP4_ADDR(&ip, 192, 168, 1, 42);
netif_set_ipaddr(netif_default, &ip);
```

### LwIP HTTP client

```c
#include "lwip/apps/http_client.h"

// By hostname (handles virtual hosting via Host: header)
httpc_get_file_dns("example.com", 80, "/index.html", &settings, body_cb, NULL, NULL);
// By IP address
httpc_get_file(&server_ip, 80, "/index.html", &settings, body_cb, NULL, NULL);
```

Requires three callbacks set in `httpc_connection_t settings`:
- `settings.result_fn` — called when transfer finishes (status codes)
- `settings.headers_done_fn` — called with HTTP headers as `pbuf`
- `recv_fn` argument (body callback) — called with body as `pbuf`

Copy `pbuf` data to a char buffer: `pbuf_copy_partial(p, myBuf, p->tot_len, 0)`.

CMake: add `pico_lwip_http` to `target_link_libraries`.

### LwIP HTTP server

```c
#include "lwip/apps/httpd.h"
httpd_init();  // starts server; web content served from compiled-in fsdata.c
```

Web content preparation: run `htmlgen` utility on an `fs/` directory → generates `fsdata.c`; add `#define HTTPD_FSDATA_FILE "myfs.c"` to `lwipopts.h`.

Dynamic content via SSI tags in `.shtml`/`.ssi`/`.xml` files:
```html
The Temperature is: <!--#temp--><br/>
```
Register handler before `httpd_init()`:
```c
http_set_ssi_handler(mySSIHandler, ssitags, num_tags);
// Handler: u16_t mySSIHandler(int iIndex, char *pcInsert, int iInsertLen)
```
Enable: `#define LWIP_HTTPD_SSI 1` in `lwipopts.h`.

---

## BBS demo (from [[yt-ep20-bbs]])

> **Source**: [[yt-ep20-bbs]] (Ep20, 2025). The BBS demo was announced alongside the Pi Pico 1 → Pi Pico 2 upgrade path.

The Pico 2 W's WiFi radio enables the 6502 to reach the internet. The first showcase was connecting to **BBS (Bulletin Board Systems)**:

- **Hayes modem `ATD` command**: dial a BBS by hostname/IP — same interface as 1980s/90s modem usage.
- **ANSI + CP437 rendering**: BBS systems typically use ANSI escape sequences and CP437 box-drawing / art characters. Both were already in the Picocomputer's console stack (see [[code-pages]]) — the system was an effective BBS terminal "as if it always knew."
- **NTP with DST**: fetch current time from the internet and adjust automatically for daylight saving time.

**Hardware upgrade path** from this episode: swap Pi Pico 1 for Pi Pico 2 (plain Pico 2 for VGA, Pico 2 W for RIA). This is the migration that corresponds to v0.10 in [[version-history]].

As of v0.24, full telnet support is implemented (`AT\N1`) alongside raw TCP (`AT\N0`).

## Related pages

- [[rp6502-ria]] — everything else the RIA does
- [[rp6502-board]]
- [[dual-core-sio]] — multicore context and FreeRTOS+WiFi integration
- [[fairhead-pico-c]] — SDK patterns for cyw43 and LwIP
- [[known-issues]] — BLE-only limitations, TinyUSB history
- [[yt-ep20-bbs]] — BBS demo episode
