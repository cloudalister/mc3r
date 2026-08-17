# MC3 ASSETS.DAT bridge - batch 20

Timestamp: `2026-08-02 07:46:53 BRT`

## Outcome

The real `ASSETS.DAT` loader is now linked into `mc3_partial.exe`. The runner imports `zlib1.dll`, and the DLL is copied beside the executable. A game-only, environment-gated virtual file adapter was added for `SLUS_213.55` and accepts only `fonts/mcloadstrings.strtbl`.

The adapter passed its targeted tests, but it did not activate in the final boot probes. The game reaches the logical package provider before the physical file ABI receives the requested asset name. No asset marker was emitted and the render counters remained zero. The bridge therefore remains disabled by default.

## ABI correction

| Address | Operation |
|---|---|
| `0x3984C0` | open |
| `0x398610` | close |
| `0x3986D8` | seek |
| `0x398730` | write |
| `0x398788` | read |

The previous interpretation of `0x398788` as `stat` was incorrect. Provider-table wrappers above these methods are `0x398830` open, `0x398858` close, `0x3988D0` read, `0x3988A8` write, and `0x398880` seek.

## Bridge limits

- Enabled only with `MC3_ASSET_BRIDGE=1` and for `SLUS_213.55`.
- Accepts only normalized `fonts/mcloadstrings.strtbl`.
- Expands only record type `0x000241FF` from `extracted_iso/ASSETS.DAT`.
- Implements independent cursor, partial read, seek, EOF, close, and size/stat behavior.
- Unknown paths and handles remain on the original backend.
- It does not fabricate providers, signal semaphores, or alias other asset names.

## Build and link evidence

- Runner: `work/link/partial/mc3_partial.exe`
- Timestamp: `2026-08-02 07:45:55 BRT`
- Size: `463806014` bytes
- `zlib1.dll` is beside the runner and appears in its PE import table.
- `missing_functions.partial.manifest.csv` contains only its header: zero missing stubs.
- Real DAT expansion is `0x3CB70` bytes and contains `smallspace`.

## Tests

- Synthetic and real DAT tests pass.
- Virtual open, partial read, seek SET/CUR/END, EOF, close, size/stat, and unknown-path tests pass.
- MC3 override binding and original-backend fallback tests pass for all five corrected ABI methods.
- A clean pre-correction suite reached `268/268`.
- After the final ABI correction, all MC3-specific tests passed. Full-suite retries ended at `267/268`, `267/268`, and `266/268` because of existing VBlank/preemption timing flakes, not asset-loader assertions.

Logs: `work/logs/assets_bridge_tests_20260802.log`, `work/logs/assets_bridge_tests_retry_20260802.log`, and `work/logs/assets_bridge_tests_retry3_20260802.stdout.log`.

## Final 8-second probes

| Probe | Bridge | Stable PC | Asset markers | Render counters |
|---|---:|---:|---:|---:|
| baseline | off | `0x4F9760` | 0 | `dma=0 gif=0 gsw=0 vif=0` |
| bridge | on | `0x39923C` | 0 | `dma=0 gif=0 gsw=0 vif=0` |

Evidence: `work/boot_probe/assets_bridge_final_baseline_20260802.md` and `work/boot_probe/assets_bridge_final_enabled_20260802.md`.

Neither trace contains `mcloadstrings`, `[MC3_ASSET_ABI]`, `0x3CB70`, or `smallspace`. The retention gate and visual-victory gate did not pass.

## Files changed

- `tools/Link-PartialRunner.ps1`
- `PS2Recomp/ps2xRuntime/CMakeLists.txt`
- `PS2Recomp/ps2xRuntime/include/mc3_virtual_file.h`
- `PS2Recomp/ps2xRuntime/include/ps2_syscalls.h`
- `PS2Recomp/ps2xRuntime/src/lib/mc3_virtual_file.cpp`
- `PS2Recomp/ps2xRuntime/src/lib/game_overrides.cpp`
- `PS2Recomp/ps2xRuntime/src/lib/ps2_runtime.cpp`
- `PS2Recomp/ps2xRuntime/src/lib/Kernel/Syscalls/FileIO.cpp`
- `PS2Recomp/ps2xRuntime/src/lib/Kernel/Syscalls/FileIO.h`
- `PS2Recomp/ps2xRuntime/src/lib/Kernel/Syscalls/Helpers/State.h`
- `PS2Recomp/ps2xTest/src/mc3_asset_archive_tests.cpp`
- `PS2Recomp/ps2xTest/src/ps2_runtime_io_tests.cpp`

Rollback source snapshot: `work/checkpoints/assets_loader_20260802_072651`.

## Next exact batch

Instrument logical package resolution at `0x4FB0D8`, called from `0x4F9760`, and capture the bounded guest string plus request metadata. Route only a proven exact `mcloadstrings` request into the existing loader. Do not broaden the matcher and do not synthesize completion or semaphore state.
