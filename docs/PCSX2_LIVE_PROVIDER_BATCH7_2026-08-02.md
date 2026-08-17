# PCSX2 live provider batch 7

Timestamp: `2026-08-02 04:44 BRT` (`America/Sao_Paulo`)

## Live window

Four observation points were armed together:

```text
0x4FB0D8  package-open entry
0x4FB4B0  package finalizer
0x4FB538  indirect callback dispatch
0x4FBB28  package error callback
0x3B1630  error helper
```

The emulator was allowed to run for 15 seconds. None of these points was
re-entered; PCSX2 advanced through the system/game loop and was paused again
at `0x800039A4`. No MCP memory/register/provider/handle/semaphore write was
made.

## Static correlation of the captured object

The finalizer's object layout is now clear from the generated code:

```text
object +0x24 -> result/state object
object +0x28 -> callback used by 0x4FB4B0
object +0x2C -> alternate callback
object +0x30 -> callback context
```

The live slot had pointed at `0x007340F0`, whose contents form repeated
pointer/offset/size records, for example:

```text
0x0078C35F, 0x00100800, 0x0000440E, 0x00000BD4
0x0078C359, 0x00101800, 0x0000204E, 0x00000C0A
0x0078C353, 0x00102800, 0x0000440E, 0x00000DF2
```

The bytes at `0x0078C35F` are nonzero binary data, but no live re-entry
correlated them to `minidub_00.pal`. It remains a candidate stream/table, not
an identified asset payload.

## Next batch

The useful next capture is not another long blind wait. Re-enter the package
path, break at `0x4FB0D8`, and read the object/result fields before allowing
`0x4FB4B0` to run. Then compare the selected pointer and size record with the
ISO/package bytes. Keep the runtime untouched until that correlation exists.
