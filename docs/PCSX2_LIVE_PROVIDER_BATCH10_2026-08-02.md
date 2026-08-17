# PCSX2 live provider batch 10

Timestamp: `2026-08-02 04:55 BRT` (`America/Sao_Paulo`)

## Callback context

The secondary stream callback path was captured live:

```text
0x4FD340
  -> slot+0x2C = 0x4FBB60
  -> a0/context = 0x0085C760
  -> 0x3B16E8
```

At `0x003B16E8`, the context contained:

```text
0x0085C760 +0x00 = 0x00000008
0x0085C760 +0x08 = 0x0000000D
0x0085C760 +0x0C = 0x000052FC
0x0085C760 +0x10 = 0x00000609
0x0085C760 +0x14 = 0x00865370
0x0085C760 +0x18 = 0x008665A0
0x0085C760 +0x1C = 0x0000001C
0x0085C760 +0x20 = 0x00060000
0x0085C760 +0x24 = 0x0062DEA8
```

This is a concrete state/allocator callback context, not the compressed
payload itself. The primary package path still reports zlib errors before the
normal stream reader; this callback handles the secondary state transition.

## Debug state

PCSX2 is paused at `0x003B16E8`. No MCP memory, register, provider pointer,
handle, or semaphore write was made.

## Next target

Capture the return from `0x003B16E8` and the next instruction at `0x4FD35C`.
Then compare the context's `+0x0C/+0x10` values with the stream record
`0x0078C5FF / 0x0003CB70 / 0x0000D967`.
