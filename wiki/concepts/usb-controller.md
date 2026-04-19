---
type: concept
tags: [rp2040, usb, hid, cdc, tinyusb, ria, keyboard, gamepad]
related:
  - "[[rp6502-ria]]"
  - "[[gpio-pinout]]"
  - "[[dual-core-sio]]"
  - "[[ria-registers]]"
sources:
  - "[[quadros-rp2040]]"
  - "[[rp2350-datasheet]]"
  - "[[pico-c-sdk]]"
created: 2026-04-16
updated: 2026-04-17
---

# USB Controller

**Summary**: The RP2040/RP2350 integrate a USB 1.1 controller that can operate as a host or device, supporting full-speed (12 Mbps) and low-speed (1.5 Mbps) modes. The RP6502-RIA uses it exclusively in **host mode** to drive keyboards, mice, gamepads, and VCP serial adapters.

---

## Hardware

- Integrated **USB 1.1 PHY** using **DP (D+)** and **DM (D−)** pins of the chip
- Operates at full speed (12 Mbps) as a device, or at low speed + full speed as a host
- USB 2.0 controller handles low-level protocol: packet encode/decode, CRC generation and checking
- **4 KB internal RAM** stores configuration descriptors and data buffers
- Mapped at `0x50000000` (AHB-Lite peripherals range)
- Interrupt line: `USBCTRL_IRQ` (IRQ 5; see [[dual-core-sio]] interrupt table)
- Pi Pico / Pico 2 exposes the USB pins via a Micro-A or USB-C connector; host mode requires a **USB OTG adapter**

---

## Protocol Basics

### Topology and addressing

- Star topology: host port → up to 127 devices across up to 5 tiers via **hubs**
- All communication initiated by the **host**; bandwidth is shared (it is a bus)
- A device is assigned a **device address** at enumeration
- A device may be a **composite device** (one address, multiple logical functions) or a **compound device** (internal hub + multiple addresses)
- Up to **32 endpoints** per device (16 IN + 16 OUT); endpoint 0 always used for configuration

### Transfer types

| Type | Use case | Packet size |
|---|---|---|
| **Control** | Initial enumeration, device-specific commands | Up to 64 bytes |
| **Interrupt** | Periodic small data (HID: keyboard, mouse) | Up to 8 bytes (low speed), 64 bytes (full speed) |
| **Bulk** | Large error-free transfers (mass storage) | Up to 64 bytes (full speed) |
| **Isochronous** | Time-sensitive, errors tolerated (audio, video) | Variable |

A transfer consists of **transactions** (token → data → handshake packets). Handshakes are omitted for isochronous transfers.

### Enumeration

When a device connects, the host:
1. Determines device characteristics
2. Assigns a device address
3. Reads **descriptors**: Device → Configuration → Interface → Endpoint (tree hierarchy)
4. Selects a configuration

Descriptors also carry **string descriptors** (human-readable) and a **VID/PID** pair identifying the device.

---

## Device Classes

USB-IF defines standard **device classes** so OSes can load drivers without per-device INF files:

| Class | Use | Notes |
|---|---|---|
| **HID** | Keyboard, mouse, joystick, gamepad | Interrupt + control transfers; data in *reports*. Most OSes have built-in drivers. |
| **CDC** | RS232 serial replacement (VCP adapters) | Linux + Windows 10 have generic drivers; older Windows needs INF by VID/PID |
| **MSC** | Mass storage (USB drives, SD cards) | Bulk transfers |
| **MIDI** | Musical instruments | — |

---

## TinyUSB

TinyUSB is the **official USB stack for the RP2040**, referenced by the Pico C SDK.

- Open-source, cross-platform, supports host and device roles
- Callback-driven: firmware implements named callbacks; TinyUSB invokes them on events
- No OS required: firmware must call `tud_task()` (device) or `tuh_task()` (host) **periodically in the main loop**
- Supports: Device classes — HID, CDC, MSC, MIDI; Host classes — HID, CDC, MSC

### Initialization pattern

```c
board_init();   // board BSP init
tusb_init();    // USB stack init
while (1) {
    tud_task();  // device — or tuh_task() for host
    app_task();
}
```

### Key configuration files

- `tusb_config.h` — `CFG_TUD_*` / `CFG_TUH_*` defines select enabled device classes and buffer sizes
- `usb_descriptors.c` — declares Device, Configuration, Interface, Endpoint, and String descriptors; implements descriptor callbacks (`tud_descriptor_device_cb`, etc.)

---

## HID Device Class

HID data is exchanged as **reports** described by **report descriptors**. The host polls periodically via interrupt transfers.

### Keyboard boot protocol

A simplified fixed-format report for compatibility with BIOS-level access:

| Byte | Content |
|---|---|
| 0 | Modifier bitmap: left/right Shift, Ctrl, Alt, GUI/Windows |
| 1 | Reserved (always 0) |
| 2–7 | Keycodes of up to 6 currently pressed non-modifier keys (zeros = empty slots) |

- Maximum **6-key rollover** for non-modifier keys
- Auto-repeat must be implemented by the **host**
- **Output report** (host → device) controls keyboard LEDs (Caps Lock, Num Lock, etc.)
- TinyUSB HID host code selects boot protocol and zero idle rate when a HID device mounts

### Keycode-to-ASCII

TinyUSB includes `HID_KEYCODE_TO_ASCII` — a table mapping keycodes to ASCII for the **US QWERTY** layout. Other layouts require custom tables.

---

## USB in Host Mode (RP2040 acting as host)

### TinyUSB host API (key callbacks)

```c
// Invoked when a HID device with matching interface is mounted
void tuh_hid_mount_cb(uint8_t dev_addr, uint8_t instance,
                       uint8_t const *desc_report, uint16_t desc_len);

// Invoked when a report is received via interrupt endpoint
void tuh_hid_report_received_cb(uint8_t dev_addr, uint8_t instance,
                                  uint8_t const *report, uint16_t len);

// Invoked when a HID interface is unmounted
void tuh_hid_umount_cb(uint8_t dev_addr, uint8_t instance);
```

- After mounting, call `tuh_hid_receive_report(dev_addr, instance)` to request reports; re-call at the end of each received callback to continue polling
- `tuh_hid_parse_report_descriptor()` parses report descriptors into `tuh_hid_report_info_t` arrays
- To set keyboard LEDs (host → device): `tuh_hid_set_report(dev_addr, instance, 0, HID_REPORT_TYPE_OUTPUT, &leds, sizeof(leds))`

### tusb_config.h for host

```c
#define CFG_TUH_HUB        1       // hub support (up to 4 downstream ports)
#define CFG_TUH_HID        4       // up to 4 HID interfaces (keyboard + mouse)
#define CFG_TUSB_HOST_DEVICE_MAX  (CFG_TUH_HUB ? 5 : 1)
#define CFG_TUH_HID_EP_BUFSIZE    64
```

---

## CDC (Serial USB Adapter) as Device

The RP2040 can present itself as a CDC device, bridging a UART to a PC's virtual COM port:

```c
// In main loop (device side):
tud_task();
cdc_task();

// cdc_task() moves data between UART and USB:
if (tud_cdc_connected()) {
    // UART → USB
    while (uart_is_readable(UART_ID) && tud_cdc_write_available() > 0)
        tud_cdc_write_char(uart_getc(UART_ID));
    tud_cdc_write_flush();
    // USB → UART
    while (uart_is_writable(UART_ID) && tud_cdc_available() > 0)
        uart_putc_raw(UART_ID, tud_cdc_read_char());
}
```

Key callbacks:
- `tud_cdc_line_state_cb(itf, dtr, rts)` — called when PC connects/disconnects (DTR = connected)
- `tud_cdc_line_coding_cb(itf, coding)` — called when PC changes baud rate / format; firmware reconfigures UART

For multiple CDC ports: `tud_cdc_n_*()` functions take an `itf` parameter; `tud_cdc_*()` assumes `itf = 0`.

---

## RP6502-RIA USB Usage

The [[rp6502-ria]] runs as a **USB host** (Pi Pico / Pico 2 requires a USB OTG adapter). TinyUSB host stack is managed by Core 0's task loop alongside the OS call dispatcher.

| USB device connected | RIA behaviour | XRAM mapping |
|---|---|---|
| HID keyboard | Keycode → 32-byte bit array | XREG `$0:0:00` |
| HID mouse | Button + delta struct | XREG `$0:0:01` |
| HID gamepad | Up to 4× 10-byte controller state | XREG `$0:0:02` |
| CDC VCP (FTDI, CP210X, CH34X, PL2303, CDC ACM) | Opens as `"VCP0:baud,format"` device node | n/a |
| PN532 NFC reader (over USB) | Tap-to-launch ROMs; `open("NFC:")` for app use | n/a |

The 32-byte keyboard bit array maps directly to HID keycodes: bit N is set if keycode N is currently pressed, cleared on release. This is read by 6502 programs via standard XRAM access.

### RIA-W BLE HID

The [[rp6502-ria-w]] additionally supports Bluetooth HID pairing (`ble pair` command), allowing wireless keyboards and mice without a USB OTG adapter.

---

## RP2350 Changes

> **Critical startup difference**: On RP2350, `MAIN_CTRL.PHY_ISO` resets to 1 (PHY isolated). You **must** clear this bit before using USB, including after power-down events. RP2040 software that goes directly to `usb_hw->main_ctrl = CONTROLLER_EN_BITS` will hang on RP2350. Add `usb_hw_clear->muxing = USB_USB_MUXING_SOFTCON_BITS` and clear PHY_ISO first.

**Clock requirement (RP2350-E12)**: `clk_sys` must be > 48 MHz when USB is in use (not just `clk_usb = 48 MHz`).

**DPSRAM base address**: `0x50100000` (`USBCTRL_DPRAM_BASE`) — 4 KB of dual-port SRAM for endpoint control and data buffers. USB controller registers begin at `0x50110000` (`USBCTRL_REGS_BASE`).

**Errata fixed in RP2350** (all RP2040 USB errata resolved):
- **RP2040-E2**: USB device endpoint abort not cleared
- **RP2040-E3**: Host interrupt endpoint buffer done flag set with incorrect buffer select
- **RP2040-E4**: USB host writes to upper half of buffer status in single buffered mode
- **RP2040-E5**: USB device fails to exit RESET state on busy USB bus
- **RP2040-E15**: Device controller hangs on certain bus errors during IN transfer

**New RP2350 features**: USB DP/DM pins can now be used as regular GPIOs (see GPIO function table); NAK-stop feature for bulk host endpoints (stops bulk transaction on NAK in hardware, preventing dropped data); enhanced hub inter-packet timeouts.

---

## Related pages

- [[rp6502-ria]] — RIA firmware; uses USB host for HID + VCP + NFC
- [[gpio-pinout]] — DP/DM pin assignments on the Pico 2
- [[dual-core-sio]] — interrupt table (USBCTRL_IRQ = IRQ 5)
- [[xram]] — where HID device state is written for 6502 programs
- [[pico-c-sdk]] — TinyUSB and hardware_usb SDK documentation
- [[xreg]] — how to configure keyboard/mouse/gamepad XRAM addresses
