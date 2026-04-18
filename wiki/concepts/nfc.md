---
type: concept
tags: [rp6502, nfc, ndef, device, filesystem, ria]
related: [[rp6502-ria]], [[rp6502-ria-w]], [[fatfs]], [[examples]]
sources: [[rp6502-ria-docs]], [[examples]]
created: 2026-04-18
updated: 2026-04-18
---

# NFC

**Summary**: The RP6502-RIA exposes an NFC reader as a POSIX device path `NFC:`, accessed via standard `open()`/`read()`/`write()` — a binary command/response protocol over the file descriptor.

---

## Opening the device

```c
int fd = open("NFC:", O_RDWR);
if (fd < 0)
    puts("NFC: device not found");   // reader not attached or not configured
```

---

## Protocol overview

Communication is asynchronous. Write command bytes to `fd`; read response bytes from `fd`.

### Commands (write to fd)

| Constant | Value | Meaning |
|----------|-------|---------|
| `NFC_CMD_WRITE` | 0x01 | Arm a write: followed by start_page(1) + data_len(2) + data |
| `NFC_CMD_CANCEL` | 0x02 | Cancel pending operation |
| `NFC_CMD_READ` | 0x03 | Request card data |
| `NFC_CMD_SUCCESS1` | 0x04 | Acknowledge success (first byte) |
| `NFC_CMD_SUCCESS2` | 0x05 | Acknowledge success (second byte) |
| `NFC_CMD_ERROR` | 0x06 | Signal error |

### Responses (read from fd)

| Constant | Value | Meaning |
|----------|-------|---------|
| `NFC_RESP_READ` | 0x01 | Card data follows: len(2) + raw_bytes |
| `NFC_RESP_WRITE` | 0x02 | Write complete |
| `NFC_RESP_NO_READER` | 0x03 | NFC reader hardware not present |
| `NFC_RESP_NO_CARD` | 0x04 | No card in field |
| `NFC_RESP_CARD_INSERTED` | 0x05 | Card detected (not yet read) |
| `NFC_RESP_CARD_READY` | 0x06 | Card ready for command |

---

## Reading a card

```c
// State machine:
resp = read(fd, &resp_byte, 1);
switch (resp_byte) {
    case NFC_RESP_CARD_READY:
        send_cmd(fd, NFC_CMD_READ);
        break;
    case NFC_RESP_READ:
        // Read 2-byte length, then raw tag data
        read_exact(fd, hdr, 2);
        len = hdr[0] | ((unsigned)hdr[1] << 8);
        read_exact(fd, nfcbuf, len);
        // User data starts at page 4 (offset 16 bytes from start)
        decode_tlv(nfcbuf + 16, len - 16);
        send_cmd(fd, NFC_CMD_SUCCESS1);
        send_cmd(fd, NFC_CMD_SUCCESS2);
        break;
}
```

### Card data layout (MIFARE Ultralight / NTAG)

| Page | Offset | Content |
|------|--------|---------|
| 0–2 | 0–11 | UID / lock bytes |
| 3 | 12–15 | Capability Container |
| 4+ | 16+ | User data (NDEF TLV blocks) |

---

## NDEF TLV encoding

User data uses the TLV (Tag-Length-Value) format. Well-known NDEF record types supported by `nfc.c`:

- **Text record** (`T`): payload = `status(1)` + `language(n)` + text
- **URI record** (`U`): payload = `prefix_code(1)` + URI suffix

URI prefix codes (0x00=none, 0x01=`http://www.`, 0x02=`https://www.`, 0x03=`http://`, 0x04=`https://`, 0x05=`tel:`, 0x06=`mailto:`).

---

## Writing a card

```c
// Build NDEF TLV buffer then:
// Write command: NFC_CMD_WRITE + start_page(1) + data_len(2) + data
unsigned char whdr[4] = { NFC_CMD_WRITE, 4, len & 0xFF, len >> 8 };
write(fd, whdr, 4);
write(fd, nfcbuf, nfcbuf_len);
// Wait for NFC_RESP_WRITE response
```

Start page 4 = first user-data page.

---

## TTY: raw key input alongside NFC

```c
int tty = open("TTY:", O_RDONLY);   // raw keyboard, non-buffered
// Check for Ctrl+C exit:
if (read(tty, &key, 1) == 1 && key == 3) { ... }
```

`TTY:` provides raw unbuffered keyboard access without going through the line-editor. Useful in event-loop programs.

---

## Help text from ROM

```c
fd = open("ROM:help", O_RDONLY);    // read embedded help text asset
```

See [[rom-file-format]] for how ROM assets are bundled.

---

## Related pages

- [[rp6502-ria]] — NFC support is part of the RIA firmware
- [[rp6502-ria-w]] — extended wireless/NFC capabilities
- [[fatfs]] — other device paths (`NFC:`, `TTY:`, `AT:` alongside FatFS)
- [[rom-file-format]] — `ROM:help` asset path
