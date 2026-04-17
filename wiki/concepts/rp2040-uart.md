---
type: concept
tags: [rp2040, rp2350, uart, serial, rp6502-ria]
related: [[gpio-pinout]], [[rp6502-ria]], [[rp2040-clocks]], [[dma-controller]]
sources: [[quadros-rp2040]], [[fairhead-pico-c]], [[pico-c-sdk]], [[rp2350-datasheet]]
created: 2026-04-16
updated: 2026-04-18
---

# RP2040 UARTs

**Summary**: The RP2040 has two UARTs (UART0, UART1) based on the ARM PL011 design; UART1 on GPIO 4–5 is the RIA's console at 115200 8N1, driven by `clk_peri`.

---

## Overview

The RP2040 has two UARTs with these features:
- 32-entry TX FIFO + 32-entry RX FIFO
- Programmable baud rate generator (fractional divider from `clk_peri`)
- 5, 6, 7, or 8 data bits; 1 or 2 stop bits; parity none/even/odd
- Break detection and generation
- Hardware flow control (RTS + CTS)
- Interrupt and DMA support

Base addresses: **UART0** = `0x40034000`; **UART1** = `0x40038000`.
IRQs: **UART0_IRQ** = IRQ 20; **UART1_IRQ** = IRQ 21.

---

## Frame Format

The signal idles at HIGH. Each word is transmitted as a *frame*:

1. **Start bit**: signal goes LOW for one bit-time; marks frame start and synchronizes the receiver.
2. **Data bits**: 5–8 bits, LSB first, MSB last.
3. **Parity bit** (optional): even parity = total "1" bits (data + parity) is even; odd = total is odd.
4. **Stop bit(s)**: signal goes HIGH for 1 or 2 bit-times.

A **break** condition is the line held LOW for at least one full frame.

---

## FIFOs

**TX FIFO**: 32 × 8-bit. Data written here is consumed by the transmitter. Can be disabled to act as a single-byte shift register.

**RX FIFO**: 32 × 12-bit. Lower 8 bits = received data; upper 4 bits = error flags set at receive time:

| Bit | Flag | Meaning |
|---|---|---|
| 11 | **OE** (Overrun Error) | Data received when FIFO was full — word lost. Clears only when a new word arrives and space exists. |
| 10 | **BE** (Break Error) | Break condition detected; data byte = 0x00. Clears when line returns HIGH. |
| 9 | **PE** (Parity Error) | Received word has wrong parity. |
| 8 | **FE** (Framing Error) | No valid stop bit detected — likely baud rate mismatch. |

Both FIFOs are enabled or disabled together; there is no independent control.

---

## Baud Rate Generation

The baud rate is derived from `clk_peri` (FUARTCLK) using a **22-bit fractional divisor** (16-bit integer + 6-bit fraction in units of 1/64). An internal Baud16 clock at 16× the baud rate is generated internally.

**Constraints**:
- `clk_peri` ≥ 16 × baud rate
- `clk_peri` ≤ 16 × 65535 × baud rate
- `clk_peri` ≤ 5/3 × `clk_sys`

**Example** (125 MHz `clk_peri`, 9600 bps):
- Divisor = 125,000,000 / (16 × 9600) = 813.802
- Integer part = 813; fractional = round(0.802 × 64) = 51
- Actual baud = 125,000,000 / (16 × 813.796875) = 9600.06 bps (< 0.001% error)

The SDK function `uart_set_baudrate()` performs this calculation automatically and returns the actual programmed baud rate.

---

## Hardware Flow Control

The RP2040 supports RTS and CTS signals, but implements them in a **non-standard** way compared to classic RS-232:

- **RTS flow control**: RIA holds RTS HIGH while there is configurable space in the RX FIFO; goes LOW when the FIFO fills up, telling the sender to stop.
- **CTS flow control**: each TX word is only sent when CTS is HIGH (the sender waits for the remote side to be ready).

In a typical two-device setup, cross the RTS and CTS lines between the devices. Enable both options with `uart_set_hw_flow(uart, cts=true, rts=true)`.

---

## Interrupts

A single combined IRQ per UART with five independently maskable sources:

| Source | When triggered | Cleared by |
|---|---|---|
| **UARTRXINTR** | RX FIFO reaches programmable level | Reading data below lower threshold, or writing UARTICR |
| **UARTTXINTR** | TX FIFO at or below programmable level | Sending data above upper threshold, or writing UARTICR |
| **UARTRTINTR** (RX timeout) | No new data for 32 bit-times while FIFO non-empty | Draining FIFO, or writing UARTICR |
| **UARTEINTR** | Error: OE, BE, PE, or FE | Writing UARTICR |
| **UARTMSINTR** | Modem status change (CTS) | Writing UARTICR |

> **RP2350 note**: Only the combined interrupt output **UARTINTR** (OR of all individual masked sources) is connected to the processor interrupt controller. Individual interrupt lines are still visible in status registers but only the combined IRQ fires.

The **RX timeout** interrupt is used alongside UARTRXINTR: set UARTRXINTR threshold > 1 so it only fires on batches, but UARTRTINTR ensures the last few bytes don't stay in the FIFO unprocessed.

TX interrupt pattern: start with TX interrupt disabled → fill FIFO directly; if FIFO full, buffer locally and enable TX interrupt → in interrupt, drain local buffer into FIFO; when empty, disable TX interrupt.

---

## GPIO Pin Options

| Function | UART0 GPIOs | UART1 GPIOs |
|---|---|---|
| Tx | 0, 12, 16, 28 | **4**, 8, 20, 24 |
| Rx | 1, 13, 17, 29 | **5**, 9, 21, 25 |
| CTS | 2, 14, 18 | 6, 10, 22, 26 |
| RTS | 3, 15, 19 | 7, 11, 23, 27 |

**Bold** = RIA console pins. GPIO function select: `GPIO_FUNC_UART`.

---

## SDK (`hardware_uart`)

`uart_init` always enables FIFOs and configures the default format 8N1. Set GPIO function **before** calling `uart_init` using `UART_FUNCSEL_NUM(uart, gpio)` to avoid losing early characters.

```c
gpio_set_function(0, UART_FUNCSEL_NUM(uart0, 0));  // TX
gpio_set_function(1, UART_FUNCSEL_NUM(uart0, 1));  // RX
uart_init(uart0, 115200);
```

### Compile-time macros (`hardware_uart`)

| Macro | Description |
|---|---|
| `UART_NUM(uart)` | Returns UART instance number (0 or 1); resolves at compile time |
| `UART_INSTANCE(num)` | Returns `uart_inst_t *` for a given UART number; resolves at compile time |
| `UART_DREQ_NUM(uart, is_tx)` | Returns `dreq_num_t` for DMA pacing; compile-time |
| `UART_CLOCK_NUM(uart)` | Returns `clock_num_t` of the clock feeding the given UART; compile-time |
| `UART_FUNCSEL_NUM(uart, gpio)` | Returns `gpio_function_t` to select UART on the given GPIO; compile-time |
| `UART_IRQ_NUM(uart)` | Returns `irq_num_t` for processor interrupts from UART; compile-time |
| `UART_RESET_NUM(uart)` | Returns `reset_num_t` to reset the UART; compile-time |

### Function reference

| Function | Description |
|---|---|
| `uart_init(uart, baudrate)` | Initialize UART; always enables FIFOs, 8N1 default; returns actual baud set |
| `uart_deinit(uart)` | Disable UART; must call `uart_init` again before reuse |
| `uart_set_baudrate(uart, baud)` | Change baud rate; UART paused ~2 char periods; returns actual value |
| `uart_set_format(uart, data_bits, stop_bits, parity)` | Frame format; UART paused ~2 char periods; parity: `UART_PARITY_NONE/EVEN/ODD` |
| `uart_set_hw_flow(uart, cts, rts)` | Enable/disable hardware flow control |
| `uart_set_fifo_enabled(uart, en)` | Enable FIFOs (both TX and RX together); UART paused ~2 char periods |
| `uart_set_irqs_enabled(uart, rx_has_data, tx_needs_data)` | Enable RX / TX interrupts (enabling RX also enables RX timeout) |
| `uart_is_enabled(uart)` | True if UART is enabled |
| `uart_is_readable(uart)` | True if RX FIFO has data |
| `uart_is_readable_within_us(uart, us)` | Wait up to `us` µs for data; returns bool |
| `uart_is_writable(uart)` | True if TX FIFO has space |
| `uart_tx_wait_blocking(uart)` | Block until TX FIFO and shift register empty |
| `uart_default_tx_wait_blocking()` | Same for the default UART instance |
| `uart_putc_raw(uart, c)` | Write char — no CR/LF translation; blocks until in FIFO |
| `uart_putc(uart, c)` | Write char — translates LF→CR+LF if enabled; blocks until in FIFO |
| `uart_puts(uart, s)` | Write null-terminated string; blocks until all chars in FIFO |
| `uart_write_blocking(uart, src, len)` | Write `len` bytes — no CR/LF translation |
| `uart_getc(uart)` | Blocking read of one char |
| `uart_read_blocking(uart, dst, len)` | Read `len` bytes blocking |
| `uart_set_break(uart, en)` | Assert/de-assert break condition |
| `uart_set_translate_crlf(uart, translate)` | LF → CR+LF in `putc`/`puts` |
| `uart_get_dreq_num(uart, is_tx)` | Return `dreq_num_t` for DMA TX (`is_tx=true`) or RX |
| `uart_get_reset_num(uart)` | Return `reset_num_t` for resetting the UART |
| `uart_get_index(uart)` | Returns UART instance number (0 or 1) |
| `uart_get_instance(num)` | Returns `uart_inst_t *` for a given UART number |
| `uart_get_hw(uart)` | Returns `uart_hw_t *` to the raw hardware registers |

> **Note:** `uart_set_baudrate`, `uart_set_format`, and `uart_set_fifo_enabled` pause the UART for ~2 character periods. Data received during this pause may be dropped. Call `uart_tx_wait_blocking()` first to drain the TX buffer, and do not call these from an interrupt context.

Note: `uart_putc` / `uart_puts` return when the character enters the FIFO, not when it is actually transmitted. If flow control is in use, the call may block waiting for CTS.

---

## stdio Layer (Fairhead)

The Pico SDK includes a `stdio` layer that routes `printf` to UART or USB. It sits above the raw `hardware_uart` API.

```c
stdio_init_all();                                     // init all configured stdio devices (UART + USB)
stdio_uart_init();                                    // init default UART as stdin + stdout
stdout_uart_init();                                   // stdout only
stdin_uart_init();                                    // stdin only
stdio_uart_init_full(uart1, 115200, 4, 5);            // custom UART, baud, TX pin, RX pin
stdio_flush();                                        // flush all stdio output buffers
```

Default UART configuration (defined in SDK headers, overridable):
```c
#define PICO_DEFAULT_UART            0
#define PICO_DEFAULT_UART_TX_PIN     0
#define PICO_DEFAULT_UART_RX_PIN     1
```

`printf` in the SDK is a simplified implementation — safe for embedded use. `sprintf`/`snprintf`/`vsnprintf` are also available. Prefer `snprintf` over `sprintf` to avoid buffer overflows.

**Default UART conflict**: `stdio_init_all()` routes `printf` to UART0 (GPIO0/1). If UART1 is used for application data (e.g. RIA console), ensure application code does not inadvertently call `printf` on the same UART.

---

## Small Buffer Warning (Fairhead)

The UART FIFO is only 32 elements. Sending `printf` output while simultaneously receiving on another UART can cause data loss:

**Problematic pattern**: collect characters into a buffer, then call `printf` → the `printf` stalls waiting for TX FIFO space; during the stall, incoming RX data fills and overflows the 32-entry RX FIFO.

**Safe pattern** for relay/echo: send each received character immediately before buffering the next:
```c
while (true) {
    buf[count] = uart_getc(uart1);        // receive one char
    uart_putc(uart0, buf[count++]);       // forward immediately
}
```

Rule: keep transactions smaller than the 32-element FIFO capacity, or use interrupts to decouple RX and TX.

---

## RIA Firmware Usage

| UART | Pin | Role |
|---|---|---|
| UART1 TX | GPIO 4 | Serial console output to host (115200 8N1) |
| UART1 RX | GPIO 5 | Serial console input from host (115200 8N1) |

`COM_UART = uart1` — UART0 is intentionally left free. UART1 is initialized at 115200 bps. See [[gpio-pinout]] for confirmed pin assignments and [[rp2040-clocks]] for `clk_peri` details.

---

## Related pages

- [[gpio-pinout]]
- [[rp6502-ria]]
- [[rp2040-clocks]]
- [[dma-controller]]
- [[usb-controller]]
- [[quadros-rp2040]]
