# PCSX2 live provider — batch 18 — 2026-08-02

Timestamp: 2026-08-02 06:04:45 -03:00

## Resultado principal

The physical index evidence moved from `STREAMS.DAT` to `ASSETS.DAT`.
Read-only scanning found a 16-byte record table at file offset `0x13EB0`:

```text
file+0x13EB0: FF 41 02 00 00 B0 0D 00 70 CB 03 00 67 D9 00 00
file+0x13EC0: FF 41 02 00 00 D0 18 00 70 CB 03 00 67 D9 00 00
file+0x13ED0: FF 41 02 00 00 48 B6 24 70 CB 03 00 67 D9 00 00
file+0x13EE0: FF 41 02 00 00 40 5C 25 70 CB 03 00 67 D9 00 00
file+0x13EF0: FF 41 02 00 00 90 8C 4E 70 CB 03 00 67 D9 00 00
```

Decoded little-endian fields:

```text
offsets: 0x000DB000, 0x0018D000, 0x24B64800, 0x255C4000, 0x4E8C9000
size:    0x0003CB70 on all five records
aux:     0x0000D967 on all five records
```

This is the first direct physical evidence for the runtime fields observed in
the earlier `mcloadstrings` slot. `0x017244B0` remains a RAM/object value: it
does not occur as an integer in the four DAT files or the main ELF files.

## Live path captures

### Failed string-table attempt

At `0x004FB0D8`, PCSX2 captured the exact request:

```text
a0 = 0x0071A960
a1 = 0x0019F810
a2 = 0x00000100
path = fonts/mcloadstrings.strtbl
```

The same call returned through `0x004FB0F0` with `v0 = 0`, so this particular
attempt did not produce a reader object. It was recorded as a failure, not
silently promoted to a successful stream.

### Successful palette reader

A later request reached `0x004FBD80` with the path captured immediately before
it as `texture/network_friendinvitation.pal`.

The reader source object was `0x01789560`; executing the load at `0x004FBD80`
resolved `source+0x04` to the stream object `0x0177E8E0`.

The live stream object contained:

```text
object+0x00 = 0x00000001
object+0x08 = 0x0061A020
object+0x0C = 0x00000009
object+0x10 = 0x00000509
object+0x14 = 0x0061A020
object+0x18 = 0x0061B020
object+0x20 = 0x00200020
object+0x24 = 0x01060010
object+0x2C = 0x017942E0
object+0x30 = 0x01724F70
object+0x34 = 0x00000001
```

The dispatcher at `0x004FD340` received:

```text
a0 = 0x0177E8E0   ; stream object
a1 = 0x006F3B10   ; provider slot
slot+0x2C = 0x004FBB60
```

The callback then received `a1 = 0x0177E8E0`, proving that the callback sees
the loaded runtime object, not a raw physical DAT offset.

## Static confirmation

The callback audit confirms:

```text
0x004FBB28: fallback/error formatter; uses a1 and a2 as a product
0x004FBB60: key/handle wrapper; forwards a1 to 0x003B16E8
0x004FBD80: loads source+0x04, then calls 0x004FD340
0x004FD340: loads slot+0x2C and passes the source object as a1
```

Therefore the corrected chain is:

```text
requested path
  -> ASSETS.DAT index record
  -> loaded source+0x04 runtime object
  -> 0x004FD340
  -> slot+0x2C callback
```

## Conclusão

The project now has a concrete `.DAT` index location and five physical block
offset candidates. The old `STREAMS.DAT` offset hypothesis is rejected for
these records. The remaining mapping task is to identify which of the five
`ASSETS.DAT` offsets belongs to `fonts/mcloadstrings.strtbl`, then compare its
decompressed bytes with the live object tables.

No ISO, emulator memory, register, or runtime-code write was made. PCSX2 was
left paused at `0x004FBD80`.

## Próximo lote

Keep one path breakpoint and one reader breakpoint serially armed. Capture
`fonts/mcloadstrings.strtbl` through a successful `0x004FBD80` path, then
compare the five `ASSETS.DAT` blocks using the live decoded size and bytes.
