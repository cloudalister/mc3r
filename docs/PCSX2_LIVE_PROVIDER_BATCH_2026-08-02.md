# PCSX2 live provider batch 1

Timestamp: `2026-08-02 04:03 BRT` (`America/Sao_Paulo`)

## Capture

The MCP connected through DebugServer and paused the real game at these
provider points without writing memory or registers:

```text
0x4FAED8 <- 0x4FB0D8 <- 0x4F9760 <- 0x3991F0 <- 0x429FC0
```

At `0x4FAED8`:

- `0x619F40 = 1`
- `0x619F41 = 1`
- `0x619F44 = 0` at that exact setup moment
- `0x619F4C = 0x0071A960`
- `0x619F54 = 0x00617F88`
- `0x619F58 = 0x004F9760`
- `v1 = 0x00619F58`
- caller `ra = 0x004FB0F0`

At `0x4F9760`, the live primary provider was already valid:

```text
0x629F44 = 0x005C0C40
0x629F4C = 0x0041F9B0
```

The package-open object at `0x4FB0D8` carried the string:

```text
fonts/texture/minidub_00.pal
```

This is the first concrete live package path captured from the real game. The
older `texture.zip` observation is therefore not the first package-open in
this path and must not be used as the sole target.

## Debug state

The emulator was left paused at `0x4FB0D8` after capture. Active observation
points are the package-open breakpoint at `0x4FB0D8`, the setup breakpoint at
`0x4FAA10`, and write/log watchpoints covering `0x619F40`, `0x619F41`, and
`0x619F44`.

## Next batch

Continue from the paused `0x4FB0D8` object and capture the return of
`0x4FAED8`, the slot written under `0x006F3B00`, and the backend open result.
Then compare the exact `minidub_00.pal` package path and return/handle against
the native runner. Do not write a fake handle or provider pointer.
