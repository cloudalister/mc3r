# PCSX2 live provider batch 15

Timestamp: `2026-08-02 05:35 BRT` (`America/Sao_Paulo`)

## STREAMS.DAT cross-check

The extracted container was scanned read-only with a block-based binary
scanner for the live record:

```text
offset      0x000DB000
size        0x0003CB70
aux size    0x0000D967
```

Neither the full little-endian triple nor the offset/size pair occurs in
`extracted_iso/STREAMS.DAT`.

The container begins with:

```text
Hash A5 08 00 00 B4 2F 23 00 00 F8 42 03 00 CC 00 00 35 ...
```

Its early table is binary and uses a different record layout; the live values
are therefore not proven physical file offsets. They are offsets/sizes inside
the already loaded proprietary stream/container representation in PS2 RAM.

## Consequence

The correct next correlation is:

```text
live path -> loaded container index/record -> RAM stream pointer
```

not a direct search for the RAM numbers in the `.DAT` byte stream. No asset,
ISO, emulator memory, provider pointer, handle, or semaphore was changed.

PCSX2 remains paused at the node-processing return boundary. Ralph's latest
no-commit iteration reported no remaining stories.

## Next target

Capture the container/index lookup immediately before the RAM stream object is
created, or identify the table parser from the static functions around the
package provider. Keep `STREAMS.DAT` read-only until that index format is
proven.
