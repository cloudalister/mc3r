# PCSX2 live provider batch 2

Timestamp: `2026-08-02 04:28 BRT` (`America/Sao_Paulo`)

## Capture

Continued from the batch-1 pause without writing guest memory or registers.
The same real-game package path was observed:

```text
fonts/texture/minidub_00.pal
```

At `0x4FB0F0`, immediately after `sub_004FAED8`, the EE return register was:

```text
v0 = 0x000000A6
```

The caller path continued through `0x4FB13C`/`0x4FB1A0` and reached
`0x4F97D4`. At that return point:

```text
v0 = 0x000000A6
s0 = 0x00000001
a0 = 0x00000000
```

This is live evidence that the package-open helper returned a nonzero result
accepted by the dispatcher. It is not evidence of a host pointer: `0xA6` is a
guest-side result/handle value.

## Slot comparison

The package-open area was read before and after the return:

```text
0x006F3B00 (before): 30a9710000000000c0060000b60300000000000000000000b603000000000000c09b700000000000c00600000000000000000000000000000028bb4f0060bb4f...
0x006F3B00 (after):  30a9710000000000c0060000b60300000000000000000000b603000000000000c09b700000000000c00600000000000000000000000000000028bb4f0060bb4f...
```

No new slot write was visible in this capture. The lifecycle bytes also stayed
unchanged:

```text
0x619F40 = 01 01 00 00
0x619F4C = 0x0071A960
0x619F54 = 0x00617F88
0x619F58 = 0x004F9760
```

## Conclusion and next target

The live path reaches the package helper and returns a nonzero guest result,
so the next blocker is not simply the null primary provider. The next target
is the post-open slot/finalization routine `0x4FB4B0`, called by
`0x4FB0D8` after the slot candidate is selected. Capture its return and the
exact slot address it receives before changing any runtime code.

The emulator is paused at `0x4F97D4` with the caller-result breakpoint active.
