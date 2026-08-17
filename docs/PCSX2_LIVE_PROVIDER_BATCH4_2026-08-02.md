# PCSX2 live provider batch 4

Timestamp: `2026-08-02 04:34 BRT` (`America/Sao_Paulo`)

## Capture

The finalizer reached an indirect call at `0x004FB538` with target
`0x004FBB28`.

```text
callback target = 0x004FBB28
a0 = 0x00000000
a1 = 0x00000001
a2 = 0x00000028
a3 = 0x00000048
```

Static mapping shows `0x004FBB28` is an error-formatting helper. It calls
`0x003B1630` and then `0x004329B0`; it is not the provider constructor or the
actual package decompressor.

The live buffer at `0x0066D811` contains the game's zlib error table:

```text
unknown compression method
invalid window size
incorrect header check
need dictionary
incorrect data check
```

The active request is therefore reaching the package/decompression error path.
The evidence now points to an invalid or mismatched compressed stream/content
for the requested `fonts/texture/minidub_00.pal`, rather than a missing
provider pointer or a semaphore-only problem.

## Debug state

The emulator is paused at `0x003B1630`, the error formatter's helper, with no
guest memory or register writes made by MCP.

## Next target

Trace backward from the decompression/error call to capture the source buffer,
compressed-size fields, and package entry metadata. Compare those bytes with
the corresponding asset inside the loaded ISO or package. Do not inject a
fake decompression result or bypass the error branch.
