# PCSX2 live provider batch 9

Timestamp: `2026-08-02 04:54 BRT` (`America/Sao_Paulo`)

## Second real asset correlation

The live package path captured at `0x4FB0D8` was:

```text
fonts/mcloadstrings.strtbl
```

At the package finalizer, the slot changed to:

```text
slot       = 0x006F3B10
slot+0x04  = 0x00733A30
```

The object at `0x00733A30` contains repeated stream records. The first live
record is:

```text
stream pointer = 0x0078C5FF
offset/size    = 0x000DB000 / 0x0003CB70
aux size       = 0x0000D967
```

The bytes at `0x0078C5FF` are real nonzero binary data beginning:

```text
3e185ee05861276a76e2761e276aa21608003ef865ad3556267...
```

This is stronger evidence than the earlier uncorrelated `0x0078C35F` sample:
the path, slot pointer, stream table, and callback chain were observed in the
same live request.

## Callback chain

At `0x004FD340`:

```text
a0 = 0x0085C760
a1 = 0x006F3B10
slot+0x2C = 0x004FBB60
```

`0x004FBB60` then receives the context `0x0085C760` and calls `0x003B16E8`.
The primary callback path still resolves to `0x004FBB28`, whose live buffer
contains the zlib error strings. The `0x004FBD80` stream-reader point was not
reached on this failed request; it remains a success/alternate-path target.

## State

The emulator is paused at `0x004FD340`. No MCP memory/register/provider/
handle/semaphore write was made.

## Next target

Capture `0x003B16E8` with the `0x0085C760` context and capture the return from
`0x004FD340`. Then compare the stream header at `0x0078C5FF` against the ISO
entry for `mcloadstrings.strtbl`. Do not bypass the zlib error or substitute a
different stream.
