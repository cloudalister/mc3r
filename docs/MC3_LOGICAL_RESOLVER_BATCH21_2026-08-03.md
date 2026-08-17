# MC3 logical resolver trace - batch 21

Timestamp: `2026-08-03 16:48:38 BRT`

## Outcome

The MC3-only runtime now has a reversible trace wrapper around guest function `0x004FB0D8`. The wrapper is enabled only by `MC3_TRACE_LOGICAL_RESOLVER=1`, logs bounded guest data, and always calls the original guest function exactly once.

The real boot trace corrected the previous interpretation of this address. `0x4FB0D8` is receiving provider extension strings, not the full `fonts/mcloadstrings.strtbl` request.

Observed direct strings across 40 calls:

- `.tex`
- `.xtex`
- `.tga`
- `.bmp`
- `.ipu`
- `.spr`

No trace entry contained `mcloadstrings`, `smallspace`, `fonts/`, `strtbl`, or `0x3CB70`.

## Safety and scope

- Registered only for `SLUS_213.55`.
- Trace output requires exact value `MC3_TRACE_LOGICAL_RESOLVER=1`.
- Reads at most `0x40` bytes from `a0` and `a1`.
- Checks only direct strings and aligned pointer candidates inside that bounded window.
- String reads are printable ASCII, NUL-terminated, and limited to 127 bytes.
- Does not recurse, scan all RDRAM, change guest memory, connect the DAT loader, create providers, or signal semaphores.
- Original function is called exactly once whether tracing is enabled or disabled.

## Verification

- PowerShell parser for `tools/Boot-Probe.ps1`: pass.
- Runtime/test build: pass.
- Primary-session test retry from `PS2Recomp/ps2xTest`, with `C:\msys64\ucrt64\bin` on PATH: `269/269`.
- One preceding run had the existing timing flake `Semaphore poll/signal remains stable under host-thread contention`; every MC3 test passed in both runs.
- Fast relink: pass.
- Final runner: `work/link/partial/mc3_partial.exe`, timestamp `2026-08-03 16:45:43 BRT`, size `463827301` bytes.
- Missing-function manifest: zero rows.
- Runner contains `MC3_TRACE_LOGICAL_RESOLVER` and all `[MC3_LOGICAL_RESOLVER]` format markers.

Test evidence: `work/logs/logical_resolver_parent_tests_retry.log`.

## Eight-second probes

| Probe | Stable PC | Counters | Resolver entries | Exact asset name |
|---|---:|---:|---:|---:|
| baseline | `0x429C78` | `dma=2 gif=0 gsw=0 vif=3` | disabled | no |
| resolver trace | `0x4FAED8` | `dma=0 gif=0 gsw=0 vif=0` | 40 | no |

Evidence:

- `work/boot_probe/logical_resolver_baseline_20260803.md`
- `work/boot_probe/logical_resolver_baseline_20260803.log`
- `work/boot_probe/logical_resolver_trace_20260803.md`
- `work/boot_probe/logical_resolver_trace_20260803.log`

The baseline `render-started` classification means only DMA/VIF counters moved. `gif=0` and `gsw=0`, so this is not a visual win and no frame exists yet.

## Architecture correction

`0x4F9760 -> 0x4FB0D8` is provider-extension registration/selection, not the logical filename request itself. Each traced call exits with `v0=0xFFFFFFFF`, and the trace-mode stable PC is `0x4FAED8`, the helper called at the start of `0x4FB0D8`.

The next exact batch should trace `0x4FAED8` and the legitimate state writer `0x4FA7A8` to prove why provider activation remains unavailable. Do not connect `ASSETS.DAT` until the real filename request is observed after provider setup succeeds.

## Files changed

- `PS2Recomp/ps2xRuntime/src/lib/game_overrides.cpp`
- `PS2Recomp/ps2xTest/src/ps2_runtime_io_tests.cpp`
- `tools/Boot-Probe.ps1`

Rollback checkpoint: `work/checkpoints/logical_resolver_20260803_1630`.
