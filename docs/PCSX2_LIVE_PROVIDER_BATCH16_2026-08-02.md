# PCSX2 live provider batch 16

Timestamp: `2026-08-02 05:38 BRT` (`America/Sao_Paulo`)

## DAT parser and stream reader

Static inspection identified `0x004FAA10` as the container-header parser. It
constructs and checks the headers `Dave`/`DAVE` and branches at `0x004FAA78`.
The live run did not re-enter that initializer during this window, so no new
header bytes were promoted as a live parser result.

The live stream reader was reached at:

```text
0x004FBD80
  caller: 0x004FCA50 -> 0x004FB440 -> 0x004FBD28
```

At the captured entry:

```text
slot base: 0x006F3B10
slot+0x28: 0x004FBB28
slot+0x2C: 0x004FBB60
```

The instruction at `0x004FBD80` loads `a0` from `slot+0x04`; this is the exact
handoff point from the provider slot to the stream-reader callback. The
following window did not reach `0x004FD340` and was paused in the system loop,
so this instance did not produce a confirmed nonzero stream pointer.

## Conclusion

The parser and reader boundaries are now known, but the live initializer and
the exact `.DAT` index record still need to be captured in the same request.
No direct physical offset claim is made for `0xDB000`.

PCSX2 is paused. No MCP memory, register, provider pointer, handle, semaphore,
ISO, or runtime-code write was made.

## Next target

Re-enter `0x004FAA10` during container initialization, capture its source
path/header and output object, then follow that same object into
`0x004FBD80` and `0x004FD340`.
