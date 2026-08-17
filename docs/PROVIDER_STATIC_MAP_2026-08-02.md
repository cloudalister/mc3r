# Provider static map without PCSX2

Timestamp: `2026-08-02 00:51 BRT` (`America/Sao_Paulo`)

## Current chain

```text
boot/title paths
  -> sub_005A8898 / sub_001A0DB0
  -> sub_004F9A68       fallback-node construction
  -> FUN_004FAA10       package/list setup and writes 0x619F40/0x619F41
  -> sub_004FAED8        consumes lifecycle flags and builds package-open request
  -> sub_004FB0D8        allocates package-open slot
  -> FUN_004F9760        provider open dispatcher
  -> sub_003991F0        backend/provider dispatch
```

Static references confirm the important edges:

- `sub_001A0DB0`, `FUN_00447928`, `FUN_003C8CF8`, `FUN_004FA488`,
  `FUN_004F97E8`, and `sub_004FB0D8` call into the provider setup functions.
- `FUN_003C8CF8` calls `sub_004F9A68` and later `FUN_004FAA10`.
- `FUN_004FA488` also calls `FUN_004FAA10`.
- `FUN_004F9760` reads primary provider state `0x619F44` and fallback state
  `0x619F4C`; it is not itself the producer of the primary node.
- `0x619F40` is written by `FUN_004FAA10` and read by
  `sub_004FAED8`; `0x619F41` follows the same lifecycle pattern.
- `sub_004FAED8` eventually calls `FUN_00431B80`, which is the next static
  boundary to map for the package-open request.

## SIF relation

The observed `request=0xFF`, `payload=0x700DC0`, `size=8` is submitted by
`sub_00549488` and completes through the generic SIF DMA response path. The
gated value-`1` experiment was applied and rejected: it did not enter
`FUN_004FAA10`, did not publish `0x619F40=1`, and did not reach
`FUN_004F9760`. Therefore this response is upstream context, not a proven
provider initializer.

The other unresolved package/file-driver responses remain:

- `request 0x0/0x9 -> payload 0x701B40`
- `request 0x1 -> payload 0x6F9000`
- `request 0x1 -> payload 0x6FC780`

No response value is being guessed for these paths.

## Next static target

Map `FUN_00431B80` callers and its request/object fields, then trace backward
to the first writer of the object consumed by `sub_004FAED8`. This is the most
direct offline route to the provider population path while the matching
`SLUS-21355` PCSX2 session is unavailable.

Evidence commands:

```powershell
rg -n "sub_004F9A68|FUN_004faa10|sub_004FAED8|FUN_00431b80|0x619f40|0x619f44|0x619f4c" work/generated/ghidra docs
```
