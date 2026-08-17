# US-003 - Provider lifecycle flags

Static audit scope: the four generated functions requested by the story. As
established by `PROVIDER_GLOBAL_REFERENCE_INVENTORY.md`, the guest instructions
load base `0x00620000` and apply signed `0x9Fxx` offsets; therefore the effective
flag addresses are `0x00619F40` and `0x00619F41`, despite the original
`0x629F40/41` labels used by the investigation plan.

## Lifecycle order

1. `sub_004F9A68_0x4f9a68` initializes a caller-provided fallback node and
   inserts it at the head of global `0x619F4C`.
2. Package/list setup calls `FUN_004faa10_0x4faa10`. For the recognized
   `evaD` format, it writes both flags to `1`. Its later path may call
   `FUN_004fa7a8_0x4fa7a8`, which independently writes `0x619F41 = 1` and,
   before returning, `0x619F40 = 1`.
3. `sub_004FAED8_0x4faed8` reads `0x619F40` first. Only when it is nonzero does
   it read `0x619F41`; the two values select how the local package-open request
   is built before the common call to `0x431B80`.

This proves ordering among fallback-list construction, flag publication, and
flag consumption. It does not prove that any of these functions initializes
the separate primary provider global `0x619F44`.

## Function map

### `0x4F9A68` - fallback-node insertion

- `0x4F9A68` clears node byte `+0x20`.
- `0x4F9A70` prepares `v0 = 0xFFFFFFFF`, then `0x4F9A78` stores it at node
  field `+0x04`.
- `0x4F9A74` reads the old head from `0x619F4C`; `0x4F9A84` stores that value
  at node field `+0x00`, and `0x4F9A8C` writes the new node address back to
  `0x619F4C`.
- `0x4F9A7C`, `0x4F9A88`, `0x4F9A90`, and the return delay slot at `0x4F9A98`
  clear fields `+0x14`, `+0x1C`, `+0x0C`, and `+0x10`.
- There is no conditional branch. `0x4F9A80` sets the return value to the input
  node pointer, which remains in `v0` through `jr ra` at `0x4F9A94`.
- It neither reads nor writes `0x619F40/41`; its lifecycle role is limited to
  the fallback chain at `0x619F4C`.

### `0x4FAA10` - conditional flag publication

- After parsing four bytes through `0x3993A8`, `0x4FAA68` recognizes `DAEV`
  directly; otherwise `0x4FAA78` requires `Dave` or skips to `0x4FAB80`.
- For the recognized `Dave` form, `0x4FAA8C` sets `s6 = 1`. The branch at
  `0x4FAA90` skips the writes when `s6 == 0`; its delay slot prepares value `1`.
- When `s6 != 0`, `0x4FAAA0` writes `0x619F41 = 1` and `0x4FAAA4` writes
  `0x619F40 = 1`. These writes publish the flags but do not create or assign a
  provider pointer.
- Later, `0x4FAE48` skips `0x4FA7A8` when `s6 != 0`; when `s6 == 0`,
  `0x4FAE58` calls `0x4FA7A8` and `0x4FAE60` stores its return value in the
  current record at `+0x0C`.
- `0x4FAE6C` and `0x4FAE74` select failure/empty cleanup after backend call
  `0x398400`; `0x4FAE88` selects whether to clear field `+0x18` or mark byte
  `+0x20 = 1` at `0x4FAE9C`.
- All normal exits converge on `0x4FAEA4`, which returns `v0 = 1` via
  `jr ra` at `0x4FAED0`.

### `0x4FA7A8` - builder and unconditional flag publication

- The function builds/normalizes a local data block through its parsing loops.
  At `0x4FA934` it loads value `1` for the flag write.
- `0x4FA93C` branches on input count `s5 <= 0`, but `0x4FA940` is its delay
  slot: `0x619F41 = 1` is therefore written on both branch outcomes.
- The remaining builder path produces result `s4`; `0x4FA9D0` moves `s4` to
  `v0`, so the return value is the built pointer/result (zero is possible when
  construction produced none).
- `0x4FAA04` unconditionally writes `0x619F40 = 1` immediately before
  `jr ra` at `0x4FAA08`. Thus both flags are published before the result is
  returned, even when the input count took the early branch.

### `0x4FAED8` - ordered flag consumption and request selection

- `0x4FAEE8` reads `0x619F40`. Branch `0x4FAEF0` sends zero directly to the
  builder at `0x4FAF4C`, selecting descriptor `0x4F9FA0`.
- Only when `0x619F40 != 0`, `0x4FAEFC` reads `0x619F41`. Branch `0x4FAF00`
  sends zero through local canonicalizer `0x4FA5B8`, then selects descriptor
  `0x4F9FC0`; when nonzero it selects descriptor `0x4FA280` directly.
- All three paths converge at `0x4FAF68`, call request builder `0x431B80`, and
  preserve its result in `a2` at `0x4FAF70`.
- Branch `0x4FAF74` returns immediately when that result is null. Branch
  `0x4FAF80` also returns it directly when the caller record has no range at
  `+0x1C`. Otherwise the remaining range scan may replace it with the selected
  table entry at `0x4FB054`.
- The single exit at `0x4FB05C` moves `a2` into `v0`; the return value is
  therefore null, the `0x431B80` result, or a selected table entry.

## Negative case

The write `0x4FA940 -> 0x619F41 = 1` occurs inside the data builder
`0x4FA7A8`; by itself it is not evidence of provider initialization. Likewise,
the two writes in `0x4FAA10` publish package-layout state but never write the
primary provider pointer `0x619F44`. This report therefore does not label any
flag write as construction of the primary provider.

Existing host-side `MC3_TRACE_PROVIDER` reads are diagnostics and are also not
guest lifecycle transitions.

## Reproduction

```powershell
rg -n -C 3 '0x4fa940|0x4faa04|0x4faaa0|0x4faaa4|0x4faee8|0x4faef0|0x4faefc|0x4faf00|0x4f9a74|0x4f9a8c|0x4fb05c' work/generated/ghidra/FUN_004fa7a8_0x4fa7a8.cpp work/generated/ghidra/FUN_004faa10_0x4faa10.cpp work/generated/ghidra/sub_004FAED8_0x4faed8.cpp work/generated/ghidra/sub_004F9A68_0x4f9a68.cpp
```

No generated source or runtime behavior was changed; this document is the sole
US-003 implementation artifact.
