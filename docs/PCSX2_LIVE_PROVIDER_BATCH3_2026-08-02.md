# PCSX2 live provider batch 3

Timestamp: `2026-08-02 04:32 BRT` (`America/Sao_Paulo`)

## Capture

The next package-open stage was reached in the real PCSX2 session at
`0x004FB4B0`, called from `0x004FB0D8` after the package-open result.

Live EE arguments:

```text
a0 = 0x006F3B10   slot/finalizer object area
a1 = 0xFFFFFFF1   callback/control value (-15)
a2 = 0x0066D811   request/result buffer
a3 = 0x00000048   buffer size
v0 = 0x000000A6   preceding package-open result
ra = 0x004FB190
```

The finalizer is therefore not the provider constructor. It validates the
returned request buffer and prepares the slot's callback fields, including
indirect calls later in `0x4FB4B0`.

## Slot mutation observed

The slot area changed between the previous capture and this invocation:

```text
0x006F3B00 before: 0x0071A930, 0x00000000, ...
0x006F3B00 now:    0x0071A930, 0x007340F0, ...
```

So `0x006F3B04` is now populated with `0x007340F0`. This is the first
concrete live slot-state transition in the current PCSX2 investigation. No
guest memory or register was written by MCP; the change came from the game.

## Next target

Capture the callback-indirect target and the return from `0x4FB4B0`. The
important fields are the slot words around `0x006F3B10`, the buffer at
`0x0066D811`, and the function pointer loaded from the slot's `+0x28`/`+0x2C`
fields. Do not replace the indirect target or inject a handle.

The emulator is paused at `0x004FB4B0` with the finalizer breakpoint active.
