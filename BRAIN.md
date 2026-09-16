# MC3 Recomp Brain

This is the root entrypoint for the Midnight Club 3 PS2 recomp workspace.

## Current State

- ISO extracted: `extracted_iso\SLUS_213.55`
- Ghidra 12.1 installed: `ghidra_12.1_PUBLIC`
- Emotion Engine extension installed for Ghidra 12.1.
- PS2Recomp builds successfully under `PS2Recomp\out\build`.
- Ghidra export exists:
  - `work\exports\SLUS_213.55.ghidra.toml`
  - `work\exports\SLUS_213.55.ghidra.csv`
- Auxiliary ran-j/live TOML exists:
  - `work\exports\SLUS_213.55.ranj_live.toml`
  - explicit launcher: `19_run_ranj_live_recomp.bat`
  - output isolated at `work\generated\ranj_live`
- Recompiled C++ generated from the Ghidra export:
  - `work\generated\ghidra`
  - last verified count: `15814` files, about `393.76 MB`
- Function index and incremental batch manifests exist:
  - `work\index\functions_index.csv`
  - `docs\FUNCTION_INDEX.md`
  - `work\batches\ghidra\batch_####.csv`
  - `work\batches\ghidra\batch_####.rsp`

## Boot Probe Status - 2026-06-29

- `15_auto_boot_probe.bat` exists and runs the boot probe/status parser.
- `15_auto_boot_probe.bat 10 probe` confirms the baseline blocker:
  - PC `0x246740`
  - function `FUN_002466e0_0x2466e0`
  - classification `sif-reg-poll`
  - condition `sceSifGetReg(4) & 0x00040000`
- `10_link_partial_runner.bat fast` relinks the partial runner without regenerating the large alias manifests.
- Current partial runner timestamp after fast relink: `2026-06-29 20:01:57`.
- `15_auto_boot_probe.bat 5 compare` result:
  - baseline: `0x246740`, `sif-reg-poll`
  - `MC3_SIF_EXPERIMENT_LATCH_REG4=1`: `0x246a80`, `FUN_00246880_0x246880`, `semaphore`
  - `MC3_SIF_EXPERIMENT_STAGE2=1`: `0x246a80`, `FUN_00246880_0x246880`, `semaphore`
  - render counters remain `dma=0 gif=0 gsw=0 vif=0`
- Interpretation: the SIF reg4 stage2 bit is a valid gate to the next phase, but not enough for render. The next blocker is the post-latch file/IOP request path around `sub_00246660_0x246660` -> `sub_0054BE68_0x54be68` -> `sub_0054BC40_0x54bc40`.

## Working Rule

Use incremental batches. Do not attempt a full monolithic compile until small batches expose and resolve the first runtime/header/stub blockers.

Default batch size is `250` functions:

```bat
08_index_generated_functions.bat 250
```

## Primary Docs

- `docs\BRAIN.md`: detailed state and evidence.
- `docs\PIPELINE.md`: command pipeline.
- `docs\FUNCTION_INDEX.md`: generated function inventory summary.
- `docs\FUNCTION_DOC_TEMPLATE.md`: template for documenting individual functions.

## Launchers

- `00_status.bat`: pipeline status.
- `01_extract_iso.bat`: extract disc image.
- `02_open_ghidra.bat`: open Ghidra.
- `03_build_ps2recomp.bat`: build PS2Recomp.
- `04_run_recomp.bat`: run the recompiler with newest TOML.
- `05_native_analyzer_fallback.bat`: analyzer fallback without Ghidra.
- `06_open_ps2x_studio.bat`: open PS2Recomp Studio helper.
- `07_export_ghidra_headless.bat`: export Ghidra TOML/CSV headlessly.
- `08_index_generated_functions.bat`: generate index and batch manifests.
- `09_compile_generated_batch.bat`: compile generated C++ incrementally by batch.
- `10_link_partial_runner.bat`: link a partial native runner from compiled objects plus temporary missing-function stubs.
- `11_run_partial_runner.bat`: run the partial native runner with `extracted_iso\SLUS_213.55`.
- `12_trace_driven_compile.bat`: automatically choose next batches from the latest runner trace, compile a small quota, relink, smoke, and update trace status docs.

## Next Goal

Prepare the native runtime build in small batches:

1. Validate includes for one tiny generated `.cpp`.
2. Compile a small batch syntactically or as objects.
3. Fix missing runtime/stub contracts.
4. Repeat in batches, recording blockers in `docs\BRAIN.md`.

Verified smoke tests:

```bat
09_compile_generated_batch.bat batch_0001 10 syntax
09_compile_generated_batch.bat batch_0001 5 object
09_compile_generated_batch.bat batch_0054 25 syntax
09_compile_generated_batch.bat batch_0001 60 syntax
09_compile_generated_batch.bat batch_0001 60 object
09_compile_generated_batch.bat batch_0001 100 syntax
09_compile_generated_batch.bat batch_0001 100 object
09_compile_generated_batch.bat batch_0001 250 syntax
09_compile_generated_batch.bat batch_0001 250 object
09_compile_generated_batch.bat batch_0002 250 syntax
09_compile_generated_batch.bat batch_0002 250 object
09_compile_generated_batch.bat batch_0003 250 syntax
09_compile_generated_batch.bat batch_0003 250 object 120
```

All passed on 2026-06-01.

- `batch_0001 250 object`: `250` objects, about `10.57 MB`.
- `batch_0002 250 object`: `250` objects, about `16.28 MB`.
- `batch_0003 250 object`: `250` objects, about `13.91 MB`.
- `batch_0037 250 object`: `250` objects, about `8.62 MB`.
- `batch_0053 250 object`: `250` objects, about `8.96 MB`.
- `batch_0054 250 object`: `250` objects, about `7.45 MB`.
- Total compiled object batches: `1500` objects, about `65.79 MB`.

Compile blocker discovered and fixed:

- Generated VU/SIMD code uses `_mm_blendv_ps`, which requires SSE4.1.
- `tools\Compile-GeneratedBatch.ps1` now passes `-msse4.1`.
- The batch compiler also has per-file timeout support and kills the compiler process tree on timeout.

Partial runner:

- `10_link_partial_runner.bat` produced `work\link\partial\mc3_partial.exe`.
- Current size: about `62.23 MB`.
- It registers `1500` real compiled functions and defines `14311` temporary missing-function stubs.
- It also registers internal resumable PC aliases parsed from generated `case 0x... goto label_...` switches. This fixed repeated `Warning: Function at address 0x1a0138 not found`.
- This is not a complete game exe yet. It is a fast incremental link target for runtime smoke tests without recompiling every generated source.
- Reaching a temporary missing-function stub at runtime logs `[partial-runner:missing-function]`, sets `ctx->pc = 0`, and requests runtime stop.

Runtime smoke discoveries:

- First partial run exposed missing internal PC alias registration at `0x1a0138`; fixed in `tools\Generate-PartialRegister.ps1`.
- Next missing boot dependency was `sub_0054C3C0_0x54c3c0`, solved by compiling `batch_0054`.
- Next missing dependency was `FUN_004329b0_0x4329b0`, solved by compiling `batch_0037`.
- Next missing dependency was `AddIntcHandler_0x546690`, solved by compiling `batch_0053`.

## Checkpoint 2026-06-01 23:37 -03:00

Latest linked partial runner:

- `work\link\partial\mc3_partial.exe`
- Registered real compiled functions: `5500`
- Temporary missing-function stubs: `10311`
- Internal PC aliases registered: `475143`
- Object batches compiled: `22` batches / `5500` functions

Object batches currently compiled:

```text
batch_0001 batch_0002 batch_0003 batch_0005
batch_0027 batch_0028 batch_0029
batch_0035 batch_0036 batch_0037
batch_0043 batch_0044 batch_0045
batch_0051 batch_0052 batch_0053 batch_0054 batch_0055
batch_0057 batch_0058 batch_0059 batch_0060
```

Runtime smoke progression after the earlier 1500-function checkpoint:

- `FUN_00398370_0x398370` -> solved by `batch_0027`.
- `sub_0042D2B8_0x42d2b8` -> solved by `batch_0036`.
- `sub_001F66A8_0x1f66a8` -> solved by `batch_0005`.
- `sub_004BEC28_0x4bec28` -> solved by `batch_0045`.
- `FUN_003afbf0_0x3afbf0` -> solved by `batch_0029`.
- `sub_003A2DE0_0x3a2de0` -> solved by `batch_0028`.
- `FUN_004b6b00_0x4b6b00` -> solved by `batch_0044`.
- `FUN_004adc10_0x4adc10` -> solved by `batch_0043`.
- `sub_00528060_0x528060` -> solved by `batch_0051`.
- `sub_0052D4C8_0x52d4c8` -> solved by `batch_0052`.
- Compiling `batch_0060` exposed a real call to `sub_0041C900_0x41c900`; solved by `batch_0035`.
- Compiling `batch_0059` moved the first bad PC to `0x59b000`; solved by `batch_0058`.
- Compiling `batch_0058` moved the first bad PC to `0x57e8d0`; solved by `batch_0057`.
- Compiling `batch_0057` moved the first bad PC to `0x56a8a0`; solved by `batch_0055`.

Latest smoke result:

- No `[partial-runner:missing-function]` hard stop in the final log.
- Runner initializes raylib/audio/window, runs the ELF path, then exits with `Exit code: 0`.
- Final signal is recoverable missing PCs followed by `StartThread id=2/id=3 exception: PS2 Thread Exit`.
- Current first bad PC is `0x514590`.
- Next trace-driven batches are recorded in `docs\TRACE_DRIVEN_STATUS.md`; current first targets are `batch_0050`, `batch_0049`, `batch_0048`, `batch_0047`, and `batch_0046`.
- New automation: `12_trace_driven_compile.bat 2 250 120` reads the latest runner log, maps missing PCs to batches, compiles up to two uncompiled trace-selected batches, relinks, runs smoke, and updates `work\trace_driven\latest_status.md` plus `docs\TRACE_DRIVEN_STATUS.md`.
- Desktop shortcut: `<user-home>\Desktop\MC3 Trace Driven Compile.lnk`.

## Checkpoint 2026-06-17 Resume

The project was idle, but the desktop trace-driven launcher was run several times after the previous checkpoint.

Latest verified trace-driven status:

- Updated: `2026-06-11 09:38:34 -03:00`
- Registered real compiled functions: `8000`
- Temporary missing-function stubs: `7811`
- Internal PC aliases registered: `636042`
- Object batches compiled: `32` batches / `8000` functions
- Latest compiled batch in the trace-driven log: `batch_0038`

Compiled object batches:

```text
batch_0001 batch_0002 batch_0003 batch_0005
batch_0027 batch_0028 batch_0029
batch_0035 batch_0036 batch_0037 batch_0038 batch_0039 batch_0040 batch_0041 batch_0042
batch_0043 batch_0044 batch_0045 batch_0046 batch_0047 batch_0048 batch_0049 batch_0050
batch_0051 batch_0052 batch_0053 batch_0054 batch_0055
batch_0057 batch_0058 batch_0059 batch_0060
```

Current trace state:

- Latest first bad PC in `work\logs\11_run_partial_runner.log`: `0x42eb90`.
- `0x42eb90` is not a function start in `work\index\functions_index.csv`; it is confirmed inside `work\generated\ghidra\sub_0042EB08_0x42eb08.cpp`.
- The Ghidra CSV/batch index says `FUN_0042eb08` ends at `0x0042EB48`, but the generated C++ comment says `Address: 0x42eb08 - 0x42ebd8` and includes instructions through `0x42ebd4`.
- This means the current blocker is likely not "compile another batch" first; it is likely "register internal instruction PCs / fix alias generation from generated C++" so `0x42eb90` dispatches to `sub_0042EB08_0x42eb08`.
- Next indexed trace targets from `docs\TRACE_DRIVEN_STATUS.md`: `batch_0034`, `batch_0033`, `batch_0032`, `batch_0031`, `batch_0030`, then `batch_0026`, `batch_0025`, `batch_0024`, `batch_0021`, `batch_0020`.
- Gemini handoff created: `docs\GEMINI_HANDOFF_2026-06-17.md`.
- Gemini launcher created: `13_gemini_resume_review.bat`; it runs Gemini in plan/read-only mode and logs to `work\logs\13_gemini_resume_review.log`.

## Checkpoint 2026-06-17 23:16 -03:00

Resolved the `0x42eb90` blocker.

- Root cause: `0x42eb90` lives inside `work\generated\ghidra\sub_0042EB08_0x42eb08.cpp`, but the generated function did not expose a resume label for dispatching directly to that internal PC.
- Unsafe attempt rejected: registering every `ctx->pc = 0x...u` as an alias made the runner crash with exit code `-1073741571`, because arbitrary internal PCs re-enter functions without a matching generated label.
- Stable fix: added targeted resume labels/switch cases for `0x42eb48` and `0x42eb90` inside `sub_0042EB08_0x42eb08.cpp`.
- Recompiled `batch_0036` in `syntax` and `object` mode: both passed `250/250`.
- Relinked partial runner successfully.
- Latest partial runner state: `8000` real functions, `7811` stubs, `76784` deduplicated internal aliases.
- Smoke result: `Exit code: 0`; `0x42eb90` no longer appears as missing.
- Current first bad PC: `0x407a40`.
- Next trace-driven target: `batch_0034`.

## Checkpoint 2026-06-28 Boot Trace Instrumentation

Runtime boot/menu investigation started after trace-driven compile stopped finding new uncompiled targets.

- Current partial state from `docs\TRACE_DRIVEN_STATUS.md`: `56` object batches, `14000` real registered functions, `1811` missing stubs, `147772` internal PC aliases.
- Added env-gated boot tracing with `MC3_BOOT_TRACE=1` in:
  - `PS2Recomp\ps2xRuntime\src\lib\ps2_runtime.cpp`
  - `PS2Recomp\ps2xRuntime\src\lib\Kernel\Syscalls\Thread.cpp`
- Added launcher: `14_run_boot_trace.bat [seconds]`.
- Test command used: `14_run_boot_trace.bat 5`.
- Boot trace log: `work\logs\14_run_boot_trace.log`.
- New runtime finding: the runner no longer exits immediately when traced; it stays alive with `activeThreads=3`.
- Stable stuck PC: `0x548dd0`, inside `work\generated\ghidra\sub_00548C78_0x548c78.cpp`.
- `0x548dd0` is a polling loop:
  - calls `sub_00548520_0x548520`
  - reads `0x006FE880 + index*4`
  - with `index=0`, waits for `mem[0x006FE880] != 0`
- While stuck: `dma=0`, `gif=0`, `gsw=0`, `vif=0`; so no real GS/render traffic is happening yet.
- Nearby SIF signal:
  - `sceSifGetReg(0x80000002)` returns `0`
  - `sceSifSetReg(0x80000001)` stores `0x6fe6d8`
- Current hypothesis: boot is blocked waiting for an IOP/SIF command/status callback that the runtime stubs do not yet simulate. This is before menu/render, so the pink screen is still just fallback/empty framebuffer.
- Next likely work: instrument or emulate the SIF/IOP command completion path that should set `0x6FE880`, rather than compiling more batches blindly.

## Checkpoint 2026-06-29 SIF Compat And Semaphore Blocker

The previous `0x548dd0` boot blocker is resolved.

- Added MC3-specific SIF boot compatibility in `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp` and `PS2Recomp\ps2xRuntime\src\lib\game_overrides.cpp`.

## Checkpoint 2026-07-12 21:59 -03:00 - Live blocker pivoted to `0x2B4488`

Baseline revalidated with:

```bat
cmd /c 15_auto_boot_probe.bat 6 payload1m3skip5a
```

Current live state:

- Classification: `render-started`
- Stable PC: `0x2B4488`
- Function: `sub_002B4438_0x2b4438`
- RA: `0x2B4478`
- Render counters moved: `dma=2 gif=0 gsw=0 vif=3`

What `sub_002B4438_0x2b4438` does:

- It loads a global interface/object from `0x6D557C`.
- It calls a virtual method at `[obj->vtable + 0x24]` with:
  - `a0 = *(0x6D557C)`
  - `a1 = caller-provided label/string`
  - `a2 = 0x647A8B`
  - `a3 = 0`
- Return value is copied to `s2`.
- If `s2 == 0`, execution falls into the tight spin loop at `0x2B4488`.
- If `s2 != 0`, it proceeds through allocation/setup:
  - `FUN_00435bc0_0x435bc0`
  - `sub_00433B48_0x433b48`
  - per-slot storage under `0x71FB60 + index*4`
  - `FUN_00433330_0x433330`
  - `FUN_002b4cb8_0x2b4cb8`
  - `FUN_00399748_0x399748`

Confirmed callers:

- `FUN_003b34c0_0x3b34c0` repeatedly calls `sub_002B4438_0x2b4438` for indices `0..8`, each with a different string pointer around `0x66D330`.
- `FUN_002b43c0_0x2b43c0` scans `0x71FB60[0..31]` and returns the first free slot or `-1`.

Current causal interpretation:

- The live blocker is no longer the older worker wait itself.
- The immediate failure at `0x2B4488` is: the virtual provider behind `0x6D557C` returns `0`, so `sub_002B4438` spins forever before object creation completes.
- In the current boot probe, the last clearly relevant SIF request before this state is:
  - `request=0x4`
  - `aux=0x621700`
  - payload pointer `0x620d80`
  - payload size `0x4`
- This is structurally a closer lead for the live blocker than the older `0x701B40` file-driver debt.

Historical debt still present but not yet proven causal to the live blocker:

- Last observed blocked worker wait remains:
  - `WaitSema sid=48`
  - `pc=0x5469e0`
  - `ra=0x1f7150`
- `sub_001F72A0_0x1f72a0` still registers callback `0x1f70c0`, and that callback is still structurally the wake shim for sid 48 via `iSignalSema`.
- That path is now tracked as prior async debt, not the primary live blocker, until a direct dependency on the `0x2B4488` provider is shown.

Next investigation target:

- Identify which concrete virtual function sits at `[*(0x6D557C)->vtable + 0x24]`.
- Determine what state/value it expects in order to return non-zero.
- Correlate that expected state with the `request=0x4 aux=0x621700 payload=0x620d80 size=0x4` completion path before touching any `0x701B40` experiment.
- For `SLUS_213.55`, when `sceSifSetReg(0x80000001, 0x006FE6D8)` happens, the runtime writes `1` to guest address `0x006FE880`.
- Verified by `14_run_boot_trace.bat 12`:
  - `[mc3-sif-compat] command ready flag addr=0x6fe880 value=0x1 subAddr=0x6fe6d8`
  - the old stable PC `0x548dd0` no longer holds the boot.
- Current runner state after relink:
  - `14000` registered real functions
  - `1811` temporary missing stubs
  - `147772` internal PC aliases
  - `work\link\partial\mc3_partial.exe` updated on `2026-06-29 03:29`
- Added `MC3_BOOT_TRACE` dispatch/semaphore diagnostics in:
  - `PS2Recomp\ps2xRuntime\src\lib\ps2_runtime.cpp`
  - `PS2Recomp\ps2xRuntime\src\lib\Kernel\Syscalls\Sync.cpp`
  - `PS2Recomp\ps2xRuntime\src\lib\Kernel\Syscalls\Common.h`
- New stable boot blocker:
  - visible frame PC: `0x54a0ac`, inside `work\generated\ghidra\sub_0054A080_0x54a080.cpp`
  - no DMA/GIF/GS/VIF traffic yet: `dma=0 gif=0 gsw=0 vif=0`
  - active guest threads: `3`
- Semaphore evidence from `work\logs\14_run_boot_trace.log`:
  - `sid=3` created at RA `0x5474c0`, then thread `2` blocks at RA `0x547400`
  - `sid=5` created at RA `0x398a98`, then thread `3` blocks at RA `0x398b28`
  - `sid=9` created by `sub_005492B8_0x5492b8` at RA `0x549330`, then main thread blocks at RA `0x549390`
  - `sid=9` has `init=0 max=1`, and no `SignalSema` for it appears in the 12s trace.
- The `sid=9` path is in `work\generated\ghidra\sub_005492B8_0x5492b8.cpp`:
  - `0x549328` calls `CreateSema`
  - `0x549360` calls `sub_00548A00_0x548a00`
  - `0x549388` calls `WaitSema`
  - `0x549390` would delete the semaphore after wake
- Current hypothesis: the boot is now blocked waiting for an async event/callback completion from the `0x548A00` path. This is still before real render/menu; pink screen remains expected fallback.
- Next likely work:
  - inspect/instrument `sub_00548A00_0x548a00`, `sub_00548EE8_0x548ee8`, and the callback/event path using the `0x80000009` command value passed at `0x549350`
  - identify who should signal `sid=9`
  - only add a compat shim after proving the producer event, not by blindly signaling all semaphores.
## Checkpoint 2026-06-29 SIF Request Completion Progress

- Added SIF command completion compatibility in `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp`.
- For SIF command envelope `0x80000009`, the runtime now:
  - reads the actual request id from packet offset `0x20`
  - writes completion status `1` to the request struct at `aux + 0x24`
  - signals the request semaphore from `aux + 0x08`
- Extended the same semaphore wake path to command envelope `0x8000000A`.
- Verified by `14_run_boot_trace.bat 10` after relink:
  - `cmd=0x80000009 request=0x80000001 aux=0x701880 sema=9 signaled=1`
  - `cmd=0x8000000a request=0xff aux=0x701880 sema=12 signaled=1`
  - `cmd=0x80000009 request=0x80000592 aux=0x6faea8 sema=13 signaled=1`
  - `cmd=0x8000000a request=0x0 aux=0x6faea8 sema=14 signaled=1`
- This moved boot past the previous stable loops at `0x54a0ac`, `0x54a188`, and `0x541cf0`.
- Current relinked runner remains `14000` real functions, `1811` stubs, `147772` aliases.
- Current stable boot PC: `0x246740`, inside `work\generated\ghidra\FUN_002466e0_0x2466e0.cpp`.
- `0x246740` polls `FUN_0054c000_0x54c000`, which checks `sceSifGetReg(4) & 0x00040000`.
- Current SIF boot reg `4` only provides the earlier ready bit `0x00020000`, so `FUN_0054c000` returns `0` and the game keeps polling.
- Still no real render traffic in trace: `dma=0 gif=0 gsw=0 vif=0`.
- Next target: decide whether MC3 needs SIF reg `4` to expose `0x00040000` after the `0x80000592` request completes, or whether another producer should set that bit.

## Checkpoint 2026-07-01 Boot Probe To Early Render Traffic

Current boot probe moved beyond the old `0x246740`/`0x246a80` blockers.

- Runtime mode used: `15_auto_boot_probe.bat 8 callback`
- Probe mode expands to:
  - `MC3_BOOT_TRACE=1`
  - `MC3_SIF_EXPERIMENT_LATCH_REG4=1`
  - `MC3_SIF_EXPERIMENT_IOP_QUEUE=1`
  - `MC3_GS_EXPERIMENT_FIELD_BIT=1`
  - `MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL=1`
- Current partial runner timestamp after fast relink: `2026-07-01 04:50:07`
- Latest status: `work\boot_probe\latest_status.md`
- Latest boot trace: `work\logs\14_run_boot_trace.log`

Validated progress:

- The `sceSifGetReg(4) & 0x00040000` gate is no longer the active blocker under the env-gated latch/queue experiment.
- `sub_00545648_0x545648` was stuck reading GS CSR at `0x12001000`; generated code uses `READ64`, so the GS private register path now routes both `read32()` and `read64()` through `readIORegister()`.
- With `MC3_GS_EXPERIMENT_FIELD_BIT=1`, GS CSR field bit is exposed and the old `0x528fa0` loop exits.
- The next blocker at `0x234614` was a callback-style SIF completion:
  - SIF envelope: `cmd=0x8000000a request=0x1 aux=0x6f8f60 sema=0xffffffff callback=0x5407c0`
  - `0x5407c0` is a tiny callback in `sub_00540720_0x540720.cpp` that calls `iSignalSema` using global sid at `0x0061fb58`.
  - `MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL=1` now mirrors this callback by reading `0x0061fb58` and signaling the sid.
  - Trace evidence: `[boot-trace:mc3-sif-callback-signal-experiment] callback=0x5407c0 global=0x61fb58 sid=29 signaled=1`.
- A generated dispatch hole was also fixed in `work\generated\ghidra\sub_005407D0_0x5407d0.cpp`:
  - trace had `[dispatch:first-bad-pc] bad=0x540838`
  - `0x540838` is inside `sub_005407D0`, but the generated switch lacked a resume case/label
  - added targeted `case 0x540838` and `label_540838`
  - recompiled `batch_0053` object mode: `250/250`, `0` failures
  - after relink, `0x540838` no longer appears as bad PC.

Current state after verification:

- Classification: `render-started`
- Stable PC: `0x245718`
- Function: `sub_00245680_0x245680`
- Render counters now moved: `dma=2 gif=0 gsw=0 vif=3`
- Stable loop:
  - `0x245718` calls `sub_005420C0_0x5420c0`
  - `0x24572c` calls `FUN_005422c8_0x5422c8`
  - `0x245734` branches back while `$v0 != 1`

Next target:

- Instrument/inspect the return values and state inputs of `sub_005420C0_0x5420c0` and `FUN_005422c8_0x5422c8`.
- Determine what state makes the loop at `0x245734` accept `$v0 == 1`.
- Do not promote GS field bit or callback signal permanently yet; both remain env-gated experiments until real semantics are better proven.

## Checkpoint 2026-07-02 Queue Gate At 0x245718

- Recompiled `batch_0053` after targeted instrumentation: `250/250`, `0` failures.
- Fast relink passed; current partial runner timestamp: `2026-07-02 22:26:17`.
- Verified probe command: `15_auto_boot_probe.bat 8 callback`.
- Current status remains:
  - classification: `render-started`
  - stable PC: `0x245718`
  - function: `sub_00245680_0x245680`
  - counters: `dma=2 gif=0 gsw=0 vif=3`
- Instrumentation proved the active loop:
  - `sub_005420C0_0x5420c0` returns with `fb90=0`, `fbb0=0x11`, `fbc8=0xffffffff`, `v0=0x6`.
  - `FUN_005422c8_0x5422c8` calls `FUN_00541760_0x541760` with `a0=2` and `a0=4`.
  - `FUN_00541760_0x541760` sees `fb90=0`, `fb9c=0`, `fbbc=0xffffffff`, returns `v0=0`, and the caller goes through the fail path.
- Only direct writer found for `0x0061FB90` is `FUN_00541be8_0x541be8` at the `0x541de4` store.
- `FUN_00541be8_0x541be8` is called twice with `a0=0`, initializes/keeps `fba8=0xf`, returns `v0=2`, but does not hit `write-fb90`.
- Current interpretation: the runner has reached an async queue gate. The consumer is waiting for `fb90 > 0`, but the producer path is only initializing the queue and never enqueuing a completion/event under current SIF/IOP emulation.
- Next target:
  - inspect the branch path inside `FUN_00541be8_0x541be8` that would reach `write-fb90`;
  - identify what IOP/SIF response should feed this queue;
  - add the next env-gated experiment only after proving whether `fb90` should be produced by a SIF callback, file I/O completion, or a render/video-side event.

## Checkpoint 2026-07-04 SIF Queue Experiments At 0x245720

- Verified build and fast relink:
  - `03_build_ps2recomp.bat` passed with `[OK] PS2Recomp build finished`.
  - `10_link_partial_runner.bat fast` passed and linked `work\link\partial\mc3_partial.exe`.
- Current verified probe command: `15_auto_boot_probe.bat 8 595`.
- Current status:
  - classification: `render-started`;
  - stable PC: `0x245720`;
  - function: `sub_00245680_0x245680`;
  - counters: `dma=2 gif=0 gsw=0 vif=3`;
  - runner timestamp: `2026-07-04 17:18:58`.
- New env-gated experiments added:
  - `MC3_SIF_EXPERIMENT_592_PAYLOAD=1`: handles `request=0x0 payload=0x620d80 size=0x10` by writing slot word `+0xC = 0xFE`; this makes `FUN_00541be8` hit `write-fb90` and set `fb90=1`.
  - `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID=1`: makes successful `PollSema` return the semaphore id; this matches wrappers that compare `PollSema(...) == semaId`.
  - `MC3_SIF_EXPERIMENT_59C_RESULT=1`: handles `request=0x0 payload=0x621600 size=0x4` by writing `1`; this makes early `sub_005420C0` returns become `v0=1`.
  - `MC3_SIF_EXPERIMENT_595_COMPLETE=1`: handles `request=0xE payload=0x61fc00 size=0x4` by marking `(*(0x620d50) + 0x10) |= 1`.
- Results:
  - `payload592` advanced from the old producer gate and proved the `0x80000592` response shape enough to set `fb90`.
  - `pollsid` proved the game expects these sema wrappers to compare success against the sema id, not `0`.
  - `59c` made `sub_005420C0` return `v0=1` in the early loop, but the outer boot loop still did not exit.
  - `595` applied successfully (`kind=request-595-complete`) and briefly reached frames inside `sub_005420C0` such as `pc=0x542100`, but the stable frame still returns to `0x245720`.
- Current interpretation:
  - This is no longer a missing-function blocker and not the old `fb90=0` gate.
  - The remaining blocker is that `FUN_005422c8_0x5422c8` still returns `v0=0`, even while `sub_005420C0` can now return `1`.
- Next target:
  - instrument `FUN_005422c8_0x5422c8` around the branch after `FUN_00541760(a0=4)` and around the state globals `fbb4/fbb8/fbd8/fc80`;
  - inspect why `FUN_00541760(a0=4)` still returns `0` after the `595` completion path;
  - do not promote any of the above SIF changes permanently; keep them env-gated until real IOP semantics are confirmed.

## Checkpoint 2026-07-04 PCSX2-MCP Live Trace Integration

- Added an additive PCSX2-MCP/Gemini integration layer. It does not launch PCSX2 and does not alter the recomp runtime.
- New local config: `work\config\pcsx2_mcp.local.json`.
- External tool drop locations:
  - `external\PCSX2-MCP`
  - `external\ps2-recomp-Agent-SKILL`
- New project-state bridge for the agent skill: `PS2_PROJECT_STATE.md`.
- New status wrapper:
  - `16_pcsx2_mcp_status.bat`
  - validates Node, expected PCSX2-MCP paths, skill path, ISO/ELF/runner, ports `21512`/`28011`, and running PCSX2 process.
- New handoff wrapper:
  - `17_live_trace_handoff.bat current`
  - writes `docs\GEMINI_PCSX2_MCP_HANDOFF.md`
  - writes `work\live_compare\latest_status.md`
- New live evidence compare wrapper:
  - `18_compare_live_trace.bat [evidence-file]`
  - classifies pasted Gemini/PCSX2-MCP evidence as `pending-live-trace`, `runtime-stub`, `missing-function`, `bad-return`, `memory-init`, `render-traffic`, or `unknown`.
- Validation result:
  - Node OK: `v24.13.0`.
  - ISO/ELF/partial runner paths OK.
  - `17_live_trace_handoff.bat current` generated valid Markdown.
  - `18_compare_live_trace.bat` generated `pending-live-trace` status without live evidence.
  - PCSX2-MCP and ps2-recomp-Agent-SKILL are currently pending until their releases/repos are placed in `external`.
  - DebugServer/PINE ports are expected to remain pending until PCSX2-MCP is running with the game loaded.
- Live trace target:
  - compare real PCSX2 behavior at `0x245720`, `0x5422c8`, `0x5420c0`, `0x541760`, `0x541968`, `0x549680`;
  - inspect memory `0x0061FC00`, `0x00620D50`, `0x00620D80`, `0x00621600`;
  - Gemini must return only hypothesis, evidence, next minimal experiment, and expected trace change.

## Checkpoint 2026-07-05 PCSX2-MCP Installed In Codex

- PCSX2-MCP release found at:
  - `external\PCSX2-MCP\PCSX2-MCP-v1.0.0-win64\PCSX2-MCP-v1.0.0-win64`
- Updated `work\config\pcsx2_mcp.local.json` to use the nested release root.
- Codex MCP server `pcsx2` is registered and enabled:
  - command: `node`
  - args: release `pcsx2-mcp-server\dist\index.js`
  - env: `PS2RECOMP_ROOT=D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp\PS2Recomp`
- Direct MCP stdio smoke passed:
  - `initialize` OK
  - `tools/list` returned the PCSX2 toolset
  - `pcsx2_connect` tool callable
  - server reports the correct PS2Recomp root after env fix.
- Current PCSX2 process:
  - `pcsx2-qt.exe` is running from the PCSX2-MCP release path.
- Current blocker:
  - TCP `127.0.0.1:21512` is not listening.
  - TCP `127.0.0.1:28011` is not listening.
  - `pcsx2_connect` returns `ECONNREFUSED` for both DebugServer and Pine.
- Applied host config fix:
  - backed up `<user-home>\Documents\PCSX2\inis\PCSX2.ini`
  - set `EnablePINE = true`
  - kept `PINESlot = 28011`
- Next action:
  - restart the PCSX2-MCP `pcsx2-qt.exe`, load the MC3 ISO, then rerun `16_pcsx2_mcp_status.bat`.
  - after restart, at least Pine `28011` should open; DebugServer `21512` should also open if the bundled build is working as intended.

## Checkpoint 2026-07-08 Gate 0x54232c Confirmed Insufficient; New Blocker = Command Queue 0x704200

- Report: `work\boot_probe\visual_regression_20260708.md`. Goal reframed: recover the old visual milestone (flickering UI/text), not just pass gates.
- New env-gated experiment `MC3_EXPERIMENT_5422C8_PASS_541760=1` forces `$v0=1` at branch `0x54232c` after `FUN_00541760(4)`. Result: `FUN_005422c8` returns 1, fail-path count drops 32 -> 0, globals move (`fbb4=1 fbd8=1 fc80=0x10`), stable PC `0x245734` — but counters stay `dma=2 gif=0 gsw=0 vif=3`. Gate confirmed real but NOT sufficient. Stop investing in 0x54232c.
- New blocker: `WaitSema sid=43 pc=0x5469e0 ra=0x5476b0`. Static analysis: `ra` is the WaitSema return inside `sub_00547608` (batch_0054), a synchronous "enqueue command + wait" wrapper. Its callback `0x5476D0` (same generated file) does `iSignalSema(a3)+sync+ei`. `sub_0054D6A0` enqueues the node into a global linked queue at guest `0x00704200`. The semaphore producer is the CONSUMER of that queue (async IOP/CDVD-style dispatcher) which the runtime does not run. Blindly signaling sid=43 just moves to the next queued command.
- Next: map the queue consumer (who reads `0x704200`; check threads, `sub_0054C160`, INTC/DMA handlers), then env-gated queue-drain experiment invoking each node's callback with a3=sid; validate live via PCSX2-MCP (breakpoint `0x547608`, watch `0x704200`).
- Pipeline gotcha discovered (cost hours): `10_link_partial_runner.bat` only relinks existing objects; edited generated .cpp needs `tools\Compile-GeneratedBatch.ps1 -Batch <batch> -Limit 0 -Mode object` first (default Limit=25 can skip the target, e.g. FUN_005422c8 = batch_0053 line 167). Always verify the experiment string exists in the exe before probing. Planned automation: `20_rebuild_target_and_probe.bat`.
- Plan updated: `docs\MASTER_PLAN_TITLE_SCREEN.md` rev 2 (section 2b).
- If old Gemini material that reached the flicker milestone exists (patch/log/exe/screenshot with date), it takes priority as evidence; none located yet.

## Checkpoint 2026-07-08 Queue Drain Implemented; Runner Broken By Loader Error 0xC0000139

- Codex implemented the drain experiment: `drainMc3Queue704200ForWaitSema()` in `PS2Recomp\ps2xRuntime\src\lib\Kernel\Syscalls\Sync.cpp` (called from WaitSema, env-gated `MC3_EXPERIMENT_704200_QUEUE_DRAIN=1`), plus env plumbing in `tools\Boot-Probe.ps1` (mode `595` now also sets the drain flag).
- After rebuild + relink (runner timestamp `2026-07-08 01:59:24`), the runner FAILS TO START: exits in ~227ms with `EXIT=-1073741511` (`0xC0000139` = STATUS_ENTRYPOINT_NOT_FOUND), no stdout/stderr. Probe status shows `unknown-loop`, empty trace, counters all 0 — that is a loader failure, NOT a new game blocker.
- Likely cause family: stale/mismatched DLLs next to `work\link\partial\mc3_partial.exe` vs freshly rebuilt runtime (e.g. raylib/runtime DLL rebuilt with different exports), or partial relink mixing old objects with the new runtime lib. Diagnose with a dependency walk (`dumpbin /dependents`, or run under loader snaps) and/or full `10_link_partial_runner.bat` (non-fast) after `03_build_ps2recomp.bat`.
- The drain experiment is therefore UNTESTED. Do not conclude anything about the queue hypothesis until the runner boots again and `15_auto_boot_probe.bat 8 595` produces a real trace.

## Checkpoint 2026-07-08 Loader Error Fixed; 595 Probe Boots Again

- Root cause of `0xC0000139` was loader/runtime DLL resolution, not a game/runtime trace blocker:
  - `mc3_partial.exe` imports MinGW/UCRT runtime DLLs such as `libgcc_s_seh-1.dll`, `libstdc++-6.dll`, and `libwinpthread-1.dll`.
  - No runtime DLLs were beside `work\link\partial\mc3_partial.exe`.
  - `where.exe` resolved Git's `C:\Program Files\Git\mingw64\bin` DLLs before `C:\msys64\ucrt64\bin`.
  - Running with `C:\msys64\ucrt64\bin` first in `PATH` made the runner initialize raylib/audio/window instead of exiting with `-1073741511`.
- Build pipeline fix:
  - `03_build_ps2recomp.bat` now configures with `-DFETCHCONTENT_UPDATES_DISCONNECTED=ON`, avoiding the previous blocked network update of `toml11`.
  - `tools\Link-PartialRunner.ps1` now copies `libgcc_s_seh-1.dll`, `libstdc++-6.dll`, and `libwinpthread-1.dll` from the compiler directory beside `mc3_partial.exe` after linking.
- Verified sequence:
  - `03_build_ps2recomp.bat`: passed.
  - `10_link_partial_runner.bat` without `fast`: passed; regenerated `14000` real registered functions, `1811` missing stubs, `147773` internal PC aliases.
  - Runtime DLLs now exist beside the runner:
    - `work\link\partial\libgcc_s_seh-1.dll`
    - `work\link\partial\libstdc++-6.dll`
    - `work\link\partial\libwinpthread-1.dll`
  - `15_auto_boot_probe.bat 8 595`: passed and produced a real trace again.
- Current probe result:
  - classification: `render-started`
  - stable PC: `0x245720`
  - function: `sub_00245680_0x245680`
  - counters: `dma=2 gif=0 gsw=0 vif=3`
  - runner timestamp: `2026-07-08 02:08:24`
  - latest status: `work\boot_probe\latest_status.md`
  - latest trace: `work\logs\14_run_boot_trace.log`
- `WaitSema sid=43` is no longer a blocking wait in this verified run:
  - `sid=43` is created at RA `0x549330`.
  - SIF compat sees `cmd=0x80000009 request=0x8000059c aux=0x6faed0 sema=43 signaled=1`.
  - Trace then shows `WaitSema:wake tid=1 sid=43 ret=0 pc=0x5469e0 ra=0x549390`.
- Important correction to the previous checkpoint:
  - `tools\Boot-Probe.ps1` sets `MC3_EXPERIMENT_704200_QUEUE_DRAIN=1` for mode `595`.
  - Current `PS2Recomp\ps2xRuntime\src\lib\Kernel\Syscalls\Sync.cpp` does NOT contain `drainMc3Queue704200ForWaitSema()` or any active `704200` drain implementation.
  - Therefore this run proves the loader is fixed and `sid=43` no longer blocks under the current SIF compat path, but it does NOT validate an actual queue-drain implementation.
- Current blocker remains the older render-started loop at `0x245720` with no GIF/GSW traffic yet. Last persistent non-main thread wait remains `WaitSema sid=5` at RA `0x398b28`.
- Follow-up read of the same trace:
  - `MC3_SIF_EXPERIMENT_595_COMPLETE` is firing: `kind=request-595-complete request=0xe payload=0x61fc00 size=0x4 value=0x1`.
  - `FUN_00541760` reaches `after-wait-ready` with `v0=0x1`, `fb90=0x1`, `fbbc=0x0`, and queue pointer `q0=0x206fef40`.
  - Despite that, the final `FUN_00541760:return` still logs `v0=0x0` for both `a0=2` and `a0=4`.
  - `FUN_005422c8` therefore still returns `v0=0`, with `fbb4=0 fbb8=0 fbd8=0 fc80=0`.
- Updated interpretation: the old "write 595 completion / make fbbc=0" hypothesis is not sufficient in this current build. The next real blocker is inside the post-ready path of `FUN_00541760_0x541760`, after the trace point `fun_00541760:after-wait-ready` and before the final return, not the loader and not `WaitSema sid=43`.

## Checkpoint 2026-07-08 Queue 0x704200 Static Map Before Drain Experiment

- Mapped the queue around `work\generated\ghidra\sub_0054D5F0_0x54d5f0.cpp`, `FUN_0054d640_0x54d640.cpp`, `sub_0054D6A0_0x54d6a0.cpp`, and `sub_00547608_0x547608.cpp`.
- `sub_0054D5F0` initializes a 64-node free/list arena from guest `0x00703E00` through `0x007041F0`, with global head at `0x00704200`; each node is 0x10 bytes.
- Node layout observed from the generated code:
  - `+0x00`: next pointer for the linked list.
  - `+0x04`: token/status/id returned by the low-level request path.
  - `+0x08`: callback function pointer.
  - `+0x0C`: callback argument, which is the sema id for the `sub_00547608` synchronous wrapper.
- `sub_0054D6A0` is both allocator/enqueuer and opportunistic processor: it pops the current head from `0x704200`, calls low-level functions (`0x54D188`/`0x54D3F8`/`0x54D4F0` family), then writes callback `0x54D640` and callback arg into the selected node. If the low-level path cannot complete it immediately, it pushes the node back onto `0x704200`.
- `FUN_0054d640` is the trampoline/consumer for queued nodes: it reads callback from `node+8`, callback arg from `node+0xC`, calls the callback with encoded node token in `a0` and arg in `a3`, and only requeues the node if the callback returns `0`.
- For the active blocker, `sub_00547608` installs callback `0x005476D0`, whose body calls `iSignalSema(a3)`. Therefore the minimum runtime experiment can mirror the real callback effect by draining nodes with callback `0x5476D0` and signaling only the sid stored at `node+0xC`; this is scoped to queue nodes and is not blind semaphore signaling.

## Checkpoint 2026-07-07 Master Plan + 595 Offset Bug Found

- Static analysis of `FUN_005422c8_0x5422c8.cpp` and `FUN_00541760_0x541760.cpp` mapped the exact gate keeping `FUN_005422c8` returning `0`.
- `FUN_00541760` returns `1` when `fbbc (0x61FBBC) >= 0`, or after the 595 loop: `sub_005492B8(0x620D50, 0x80000595, 0)` then reading `mem[0x620D50 + 0x24]` (= `0x00620D74`) nonzero, which writes `fbbc = 0`.
- Confirmed bug: `MC3_SIF_EXPERIMENT_595_COMPLETE` in `SIF.cpp` writes `deref(0x620D50) + 0x10`, but the game reads the struct at `0x620D50` directly, offset `+0x24`. Wrong address; the 595 loop can never exit.
- Next experiment (E1): make the 595 handler write `1` to `0x00620D74`, keep env-gated, rebuild, fast relink, `15_auto_boot_probe.bat 8 595`, expect `fun_00541760:return v0=0x1`.
- Full ordered plan + anti-hallucination rules + globals dictionary: `docs\MASTER_PLAN_TITLE_SCREEN.md`.

## Checkpoint 2026-07-05 PCSX2-MCP Live Connection Confirmed

- User restarted/opened the bundled PCSX2-MCP and loaded MC3 to the title screen.
- `16_pcsx2_mcp_status.bat` now passes the important live checks:
  - DebugServer TCP `127.0.0.1:21512`: OK
  - Pine TCP `127.0.0.1:28011`: OK
  - PCSX2 process: `pcsx2-qt`
- Direct MCP stdio `pcsx2_connect` smoke passed:
  - DebugServer connected.
  - Example reported PC values while running: `0x003a29dc`, then `0x800031c8`.
- Remaining caveat:
  - Pine port is listening, but direct MCP `pcsx2_connect` reported `Pine response timeout`; DebugServer is the useful path for now.
  - Some advanced direct smoke calls need careful sequencing/paused state; `pcsx2_disassemble` returned an internal tool error in the harness and `read_registers` did not return before timeout.
- Next action:
  - Open a fresh Codex session so the `pcsx2_*` MCP tools are loaded into the active tool list.
  - Start with `pcsx2_connect` in `debug` mode and then use pause/status/threads before disassembly/register dumps.

## Checkpoint 2026-07-08 FUN_00541760 Post-Ready Return Path Mapped

- Task source: `docs\CODEX_TASK_2026-07-08_QUEUE_0x704200.md`; latest prior checkpoint was `Loader Error Fixed; 595 Probe Boots Again`.
- Static read of `work\generated\ghidra\FUN_00541760_0x541760.cpp` identified the exact `v0` zero path after `fun_00541760:after-wait-ready`:
  - At `0x5417e4`, `beqz v0` decides between the two post-ready paths.
  - If `after-wait-ready v0=1`, the branch is NOT taken; execution calls `SignalSema` at `0x5417f0`, returns to `label_5417f8`, logs `empty-return`, then the branch delay slot at `0x5417fc` executes `daddu v0, zero, zero`. That is the observed zero before `fun_00541760:return`.
  - Therefore `after-wait-ready v0=1` is the release/empty return path, not the final success path.
- Conditions that return `1` from `FUN_00541760`:
  - `after-wait-ready v0=0` takes the branch at `0x5417e4` to `label_541800`; then `sub_00548C78()` runs, `fbbc` is read at `0x541808`, and if `fbbc >= 0`, the delay slot at `0x541810` sets `v0=1` before returning.
  - If `fbbc < 0`, the 595 loop calls `sub_005492B8(0x620D50, 0x80000595, 0)`, reads `0x620D74`, and when that completion word becomes nonzero it stores `fbbc=0` at `0x5418b4`; the next return carries `v0=1`.
- Latest trace confirms the map: one `a0=2` call has `after-wait-ready v0=0` and returns `1` after setting `fbbc=0`; the later `a0=4` call has `after-wait-ready v0=1`, hits `empty-return`, and returns `0`.
- Minimal hypothesis: for the `a0=4` call, the runtime/probe state is making `FUN_00541968(1)` return "ready/already released" (`v0=1`), which sends `FUN_00541760` down the release path. To test the current gate at the right layer, use the existing env-gated generated-code experiment `MC3_EXPERIMENT_541760_RET1_FOR_MODE4=1`, not the caller-side `MC3_EXPERIMENT_5422C8_PASS_541760`.
- Cleanup decision for queue drain:
  - `tools\Boot-Probe.ps1` still referenced `MC3_EXPERIMENT_704200_QUEUE_DRAIN`, but `PS2Recomp\ps2xRuntime\src\lib\Kernel\Syscalls\Sync.cpp` no longer contains `drainMc3Queue704200ForWaitSema()` or any 0x704200 drain implementation.
  - Because `sid=43` is already unblocked and the current blocker is the post-ready return path in `FUN_00541760`, Codex removed the dead `MC3_EXPERIMENT_704200_QUEUE_DRAIN` plumbing from `tools\Boot-Probe.ps1` instead of reimplementing the drain.
  - Mode `595` now sets `MC3_EXPERIMENT_541760_RET1_FOR_MODE4=1` and no longer sets the caller-side `MC3_EXPERIMENT_5422C8_PASS_541760=1`.
- No generated `.cpp` was edited in this checkpoint, so the batch `-Limit 0` rebuild gotcha was not triggered. If a future change edits `FUN_00541760_0x541760.cpp`, recompile its generated batch with `tools\Compile-GeneratedBatch.ps1 -Limit 0 -Mode object` before relinking.

## Checkpoint 2026-07-08 Queue 0x704200 Callback-Complete Verified; New Blocker = FUN_00541968

- Corrected the bad intermediate state left by the prior headless run: mode `595` must activate the working stack `MC3_EXPERIMENT_5422C8_PASS_541760=1` plus `MC3_EXPERIMENT_704200_QUEUE_DRAIN=1`. The attempted switch to only `MC3_EXPERIMENT_541760_RET1_FOR_MODE4=1` regressed to stable PC `0x245734` and left `WaitSema sid=43` blocked.
- Current launcher state in `tools\Boot-Probe.ps1`:
  - clears stale `MC3_EXPERIMENT_704200_QUEUE_DRAIN` before each probe run;
  - `pollsid59c595` sets the SIF stack, `MC3_SIF_EXPERIMENT_595_COMPLETE=1`, `MC3_EXPERIMENT_5422C8_PASS_541760=1`, and `MC3_EXPERIMENT_704200_QUEUE_DRAIN=1`.
- Current implementation is NOT a blind WaitSema drain in `Sync.cpp`. `Sync.cpp` contains no `drainMc3Queue704200ForWaitSema()`. The env-gated experiment lives in `work\generated\ghidra\sub_0054D6A0_0x54d6a0.cpp` and mirrors the real callback-completion effect only when the active node callback is `0x005476D0`, signaling the sid stored at `node+0x0C`.
- Verified command: `15_auto_boot_probe.bat 8 595`.
  - latest status: `work\boot_probe\latest_status.md`
  - driver log: `work\logs\15_auto_boot_probe_20260708_021551.log`
  - trace: `work\logs\14_run_boot_trace.log`
- Key trace evidence:
  - `fun_005422c8:force-pass-541760` then `fun_005422c8:return v0=0x1`.
  - `mc3-704200-callback-complete node=0x703e00 token=0x701e005 callback=0x5476d0 arg=0x2b signaled=1`.
  - `WaitSema:wake tid=1 sid=43 ret=0 pc=0x5469e0 ra=0x5476b0`.
  - Stable frames at PC `0x5419a0`, RA `0x5419a8`.
- Result: progress is real and reproducible. The old blocker `WaitSema sid=43` is no longer the active stop under mode `595`.
- Remaining blocker:
  - classification: `render-started`
  - stable PC: `0x5419a0`
  - function: `FUN_00541968_0x541968`
  - counters: `dma=2 gif=0 gsw=0 vif=3`
  - last persistent wait is non-main thread `WaitSema sid=5` at RA `0x398b28`.
- Static read of `FUN_00541968_0x541968.cpp` shows the active loop:
  - `0x5419a0` calls `sub_00547608(0xFA0)`;
  - `0x5419a8` reads global `0x0061FBB4`;
  - `0x5419ac` loops back while `0x0061FBB4 != 0`;
  - if `0x0061FBB4` clears, execution reaches `sub_00549680(0x00620D50)` at `0x5419b4`.
- Next step: map who clears `0x0061FBB4` and whether the `sub_00547608(0xFA0)` callback or `sub_00549680(0x00620D50)` should transition it. If static evidence is inconclusive, capture PCSX2 live around `0x5419a0/0x5419a8/0x5419b4` and watch globals `0x0061FBB4`, `0x0061FBD8`, `0x0061FC80`, and `0x00620D50`.
- Probe run after the cleanup/experiment switch:
  - Command: `.\15_auto_boot_probe.bat 8 595`.
  - Result: passed as a probe run and updated `work\boot_probe\latest_status.md`, but did NOT hit `gif>0` or `gsw>0`.
  - Status: `classification=render-started`, stable PC `0x245734`, counters `dma=2 gif=0 gsw=0 vif=3`.
  - Trace evidence: `FUN_00541760(a0=4)` now logs `return v0=0x1`, and `FUN_005422c8` logs `return v0=0x1` without relying on caller-side `MC3_EXPERIMENT_5422C8_PASS_541760`.
  - New/remaining blocker after passing the 541760 gate: the trace reaches `sceSifSetDma` for `cmd=0x8000000a request=0x1 aux=0x620d50 callback=0x5413f0 sema=0xffffffff`, then creates `sid=43` and blocks at `WaitSema pc=0x5469e0 ra=0x5476b0`.
  - Interpretation: the `FUN_00541760` post-ready return question is resolved; the next blocker is again the queued async SIF/callback path, not the 541760 return value. This likely needs either a real queue/callback drain implementation or PCSX2 live trace around callback `0x5413f0` / queue `0x704200` before another shim is promoted.

## Checkpoint 2026-07-08 Callback 0x5413F0 Mirrored; New Blocker = 59C Playback State

- Static callback map:
  - `work\index\functions_index.csv` points the owner range at `FUN_005412d0` / `work\generated\ghidra\sub_005412D0_0x5412d0.cpp`.
  - The entry at `0x5413f0` copies reply data, then tail-jumps into the `0x541348` commit path.
  - The commit path writes `0x0061FBD8` / `0x0061FBDC`, signals the wait sema at `0x0061FBA8` when appropriate, may signal pending sema `0x0061FBA0`, clears `0x0061FBB4` when no pending work remains, and clears `0x0061FBD8`.
- Runtime experiment:
  - `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp` now has `MC3_SIF_EXPERIMENT_CALLBACK_5413F0`.
  - The helper mirrors the guest callback effect for `cmd=0x8000000a request=0x1 aux=0x620d50 callback=0x5413f0 sema=0xffffffff`.
  - It is not a blind sema signal: it applies the reply globals, clears `0x61FBB4` through the same no-pending path, and clears the active queue node like `sub_00548EE8` (`node+0x18=0`, `node+0x10 &= ~1`) when the active `0x620d50` node is still marked busy.
- Probe stack:
  - `tools\Boot-Probe.ps1` mode `595` sets `MC3_SIF_EXPERIMENT_CALLBACK_5413F0=1`.
  - Rebuilt runtime with `03_build_ps2recomp.bat`.
  - Relinked with `10_link_partial_runner.bat` without fast mode.
  - Verified with `15_auto_boot_probe.bat 8 595`.
- Latest evidence:
  - Status file: `work\boot_probe\latest_status.md`.
  - Driver log: `work\logs\15_auto_boot_probe_20260708_023051.log`.
  - Trace: `work\logs\14_run_boot_trace.log`.
  - Trace line evidence: `mc3-sif-callback-5413f0-experiment ... queueNode=0x206fef80 queueFlags=0x1a0005 queueCleared=1`.
  - The old `WaitSema sid=43` blocker after `callback=0x5413f0` no longer persists.
- New blocker:
  - Classification remains `render-started`, counters `dma=2 gif=0 gsw=0 vif=3`.
  - Stable PC is now `0x2455f0`, function `sub_00245568_0x245568`.
  - `sub_00245568` calls `sub_005420C0(1)` and loops at `0x2455f0` until the return value equals `2`.
  - Current `MC3_SIF_EXPERIMENT_59C_RESULT` writes `request=0x0 payload=0x621600 size=0x4 value=0x1`; trace shows `sub_005420C0` returning `1` early, then `6`, but never `2`.
- Stop condition:
  - Do not blindly force `0x621600=2`. That likely represents a real IOP/movie playback state transition and may skip the path needed to reach GIF/GS.
  - Updated `docs\GEMINI_PCSX2_MCP_HANDOFF.md` for PCSX2-MCP live comparison at `0x2455f0`, `0x5420C0`, request `0x59c`, and globals `0x00621600`, `0x0061FB90`, `0x0061FBB0`, `0x0061FBC8`, `0x0070AED0`, `0x0070AF10`.

## Checkpoint 2026-07-08 FUN_00541968 / 0x0061FBB4 Loop Mapped And Advanced

- Task: map the new loop in `FUN_00541968`, especially who should clear `0x0061FBB4`.
- Static mapping:
  - `0x0061FBB4` is set to `1` by `sub_005424A8_0x5424a8.cpp` at `0x542518` when the async movie/request path is started.
  - `0x0061FBB4` is cleared by the callback body in `sub_005412D0_0x5412d0.cpp`: at `0x541384` for reply/status `0x0B`, and at `0x5413D0` on the normal callback-complete path after signaling/checking pending state.
  - The failure path in `sub_005424A8` also clears it at `0x54254C` if `sub_00549488` fails.
  - `FUN_00541968` itself does not clear `0x0061FBB4`; it only polls it at `0x5419A8` and loops at `0x5419AC` while it is nonzero.
- Runtime mapping:
  - The active SIF request uses callback `0x5413f0` with queue/request global `0x00620D50`.
  - Existing env-gated runtime helper `MC3_SIF_EXPERIMENT_CALLBACK_5413F0` in `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp` now mirrors the callback clear of `0x0061FBB4`.
  - First probe after that showed `0x0061FBB4` did clear, but `FUN_00541968` still looped after `sub_00549680(0x00620D50)` returned `1`; trace showed `node=0x206fef80`, `nodeSeq=0x16`, `flags=0x1a0005`.
- Queue-node cleanup mapping:
  - `sub_00549680_0x549680.cpp` returns ready/nonzero when the active node seq matches and `node+0x10` bit 0 is set.
  - `sub_00548EE8_0x548ee8.cpp` is the real cleanup path for that node: it clears `node+0x18` and clears bit 0 in `node+0x10`.
  - `MC3_SIF_EXPERIMENT_CALLBACK_5413F0` was extended, env-gated, to mirror that cleanup for the active `0x00620D50` node after callback `0x5413f0`.
- Verified commands:
  - `cmake --build "PS2Recomp\out\build" --config Debug`
  - `10_link_partial_runner.bat`
  - `15_auto_boot_probe.bat 8 595`
- Latest verified result:
  - classification: `render-started`
  - stable PC moved from `0x5419a0` to `0x2455f0`
  - function: `sub_00245568_0x245568`
  - counters still `dma=2 gif=0 gsw=0 vif=3`
  - trace evidence: `mc3-sif-callback-5413f0-experiment ... queueNode=0x206fef80 queueFlags=0x1a0005 queueCleared=1`, then `sub_00549680:return v0=0x0 reason=not-ready`.
- Conclusion: the `FUN_00541968` / `0x0061FBB4` blocker is advanced. `0x0061FBB4` is callback-owned, not locally owned by `FUN_00541968`; the missing runtime behavior was callback completion plus active queue-node cleanup.
- New blocker:
  - stable PC `0x2455f0` is inside `sub_00245568_0x245568`.
  - The local loop is `0x2455e0 -> FUN_00398c60(1) -> 0x2455e8 -> sub_005420C0(1) -> 0x2455f0`.
  - `0x2455f0` branches back while `sub_005420C0(1)` return `v0` is not equal to `s0 == 2`.
  - Next step: map `sub_005420C0_0x5420c0` for `a0=1` and why it does not return `2`; if that is state-driven, compare its globals with PCSX2 live or the older flicker trace.

## Checkpoint 2026-07-08 59C Ret2 + Callback 0x541348 Experiment

- Goal: continue after the `sub_00245568` loop at `0x2455f0` and then the `sub_005424A8` loop at `0x245608/0x245610`.
- Runtime/gated changes:
  - `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp` now lets `MC3_SIF_EXPERIMENT_59C_RESULT_VALUE` choose the synthetic 59C result instead of hardcoding `1`.
  - New probe mode `pollsid59c595ret2` / alias `595ret2` sets the 59C result to `2`.
  - New probe mode `pollsid59c595ret2mode9` / alias `595ret2m9` layers on `MC3_EXPERIMENT_541760_RET1_FOR_MODE9=1` and `MC3_SIF_EXPERIMENT_CALLBACK_541348=1`.
  - `MC3_SIF_EXPERIMENT_CALLBACK_541348` mirrors the generated callback body at `0x541348` for the movie/request path and clears the active queue node like the `0x5413f0` helper.
- Verified commands:
  - `cmake --build "PS2Recomp\out\build" --config Debug`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools\Compile-GeneratedBatch.ps1 -Batch 53 -Limit 0 -Mode object`
  - `10_link_partial_runner.bat`
  - `15_auto_boot_probe.bat 8 595ret2m9`
- Results:
  - `595ret2` moved stable PC from `0x2455f0` to `0x245608`; trace shows `sub_005420c0:return v0=0x2`.
  - Forcing `FUN_00541760(9)` without callback `0x541348` regressed to `0x5419a0` because the new async SIF request used `callback=0x541348` and was not handled.
  - After adding callback `0x541348`, stable PC moved back forward to `0x245610`.
  - Latest status: `work\boot_probe\latest_status.md`, mode `pollsid59c595ret2mode9`, classification `render-started`, stable PC `0x245610`, counters still `dma=2 gif=0 gsw=0 vif=3`.
- Evidence:
  - `work\logs\14_run_boot_trace.log` shows `mc3-sif-callback-541348-experiment ... callback=0x541348 request=0x5 ... queueNode=0x206ff040 queueFlags=0x1d0005 queueCleared=1`.
  - `sub_005424A8` now logs one successful return: `sub_005424a8:return v0=0x1 ... d50=0x206ff040 q10=0x1d0004 q18=0x0`.
  - It then loops with `sub_005424a8:return v0=0x0 ... d50=0x206ff0c0 q10=0x1f0005 q18=0x1e`.
- Current blocker:
  - `0x245610` is the branch after `sub_005424A8(s1)`; caller expects `v0 == 1`.
  - The first `sub_005424A8` completion works, but subsequent iterations leave active queue node `0x206ff0c0` busy (`node+0x10=0x1f0005`, `node+0x18=0x1e`), so `sub_005424A8` returns `0`.
  - Next step: map the SIF command/callback associated with queue node `0x206ff0c0` / seq `0x1e` and determine whether another callback completion is missing or whether `FUN_00541760(2)` needs a real non-empty reply instead of the current empty-return path.

## Checkpoint 2026-07-08 595 Queue Clear Batch

- Goal: advance the current `0x245610` blocker without touching `sub_005424A8`, `FUN_00541760`, `sub_00549680`, or the render path first.
- Implemented runtime/env-gated changes:
  - `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp` now has a shared helper that clears the active movie queue node like `sub_00548EE8`: `node+0x18 = 0`, `node+0x10 &= ~1`.
  - Existing callback experiments `MC3_SIF_EXPERIMENT_CALLBACK_5413F0` and `MC3_SIF_EXPERIMENT_CALLBACK_541348` now reuse that helper instead of duplicating queue clear logic.
  - New `MC3_SIF_EXPERIMENT_595_CLEAR_QUEUE` clears the active `0x00620D50` queue node when completing request `0xE` with payload `0x0061FC00`.
  - `tools\Boot-Probe.ps1` mode `pollsid59c595ret2mode9` / alias `595ret2m9` enables `MC3_SIF_EXPERIMENT_595_CLEAR_QUEUE`.
- Verified commands:
  - `cmake --build "PS2Recomp\out\build" --config Debug`
  - `10_link_partial_runner.bat`
  - `15_auto_boot_probe.bat 8 595ret2m9`
- Latest verified result after disabling the bad 59C clear:
  - status: `work\boot_probe\latest_status.md`, updated `2026-07-08 15:16:08`
  - classification: `render-started`
  - stable PC: `0x245610`
  - function: `sub_00245568_0x245568`
  - counters: `dma=2 gif=0 gsw=0 vif=3`
  - 59C result remains synthetic value `2`, but `queueCleared=0` for `request-59c-result`.
  - 595 completion logs show `queueCleared=1` for nodes through `0x206ff0c0`.
- Evidence:
  - `work\logs\14_run_boot_trace.log` shows early `sub_005424a8:return v0=0x1` for nodes `0x206fefc0`, `0x206ff000`, `0x206ff040`, `0x206ff080`, and `0x206ff0c0` after the queue clear.
  - The loop still falls back to `sub_005424a8:return v0=0x0` on node `0x206ff0c0`, now with `q10=0x1f0005` and `q18=0x31`.
- Negative result:
  - `MC3_SIF_EXPERIMENT_59C_CLEAR_QUEUE` was added as an env-gated capability for testing but must not be enabled in `595ret2m9`.
  - Enabling it regressed the run to classification `sif-request`, stable PC `0x2455f0`, and counters `dma=0 gif=0 gsw=0 vif=0`.
  - `tools\Boot-Probe.ps1` now clears the env var at run start but does not set it for the default `595ret2m9` mode.
- Conclusion:
  - The planned 595 queue clear is a real incremental advance because it turns several `sub_005424A8` iterations from `v0=0` into `v0=1`.
  - It is not sufficient to pass `0x245610`; the next blocker is the later re-busy state on the same active node `0x206ff0c0`, now with sequence/state `q18=0x31`.
  - Next step: map the later request sequence around `q18=0x31` and compare against PCSX2 live if possible. Avoid blind 59C queue clear.

## Checkpoint 2026-07-08 Queue Seq Sync + Delayed Req5 Completion

- Goal: advance the current `0x245610` blocker and confirm whether the follow-up `FUN_00541968` loop was caused by `0x0061FBB4` staying set or by `sub_00549680(0x00620D50)` returning ready.
- Implemented env-gated experiments/instrumentation:
  - `MC3_SIF_EXPERIMENT_59C_SYNC_ACTIVE_QUEUE_SEQ`: for request `59C` result, syncs `0x00620D54` from `node+0x18` only when the active queue node matches and `nodeSeq == queueSeq + 1`.
  - `MC3_EXPERIMENT_549488_ACCEPT_REQ5_BUSY`: in `sub_00549488`, accepts the exact busy request `request=5`, `mode=1`, `callback=0x541348` when the return would be `-1`.
  - `FUN_00541968` now logs `fbb4/fbd8/fc80` and active queue state at its poll and ready-check points.
  - `MC3_EXPERIMENT_5424A8_DELAYED_REQ5_COMPLETE`: after `sub_005424A8` accepts request 5 and sets `fbb4=1/fbd8=4`, clear `fbb4/fbd8` and clear the active queue node like delayed callback completion.
  - `tools\Boot-Probe.ps1` enables these only for `pollsid59c595ret2mode9` / alias `595ret2m9`.
- Verified commands:
  - manual object compile for `sub_00549488_0x549488.cpp`, `FUN_00541968_0x541968.cpp`, and `sub_005424A8_0x5424a8.cpp`
  - `10_link_partial_runner.bat`
  - `15_auto_boot_probe.bat 5 595ret2m9`
- Evidence:
  - Before delayed completion: `request-59c-result ... queueSeqSynced=1` made `sub_00549680:return v0=0x1 reason=ready`, and `queue-submit-force-accept` made `sub_005424a8:return v0=0x1`, but `FUN_00541968` then polled forever with `fbb4=1 fbd8=4`.
  - This proves callback `0x541348` was mirrored too early: runtime handled it before `sub_005424A8` set `0x0061FBB4`.
  - With delayed completion, trace shows repeated `sub_005424a8:delayed-req5-complete ... q10After=0x1f0004 q18After=0x0`.
- Latest result:
  - classification changed from `render-started`/stable `0x245610` or `0x5419a0` to `sif-request`.
  - `latest_status.md` mis-parsed the interleaved frame line as `0x2455b80`, but the real PC token is `0x2455b8`, registered to `sub_00245568_0x245568`.
  - counters are still effectively `dma=2 gif=0 gsw=0 vif=3`; no GIF/GSW advance yet.
- Current blocker:
  - `sub_00245568` is now looping/working around `0x2455b8`/`0x5494e0` with repeated SIF request sequence on active node `0x206ff0c0`.
  - Next step: instrument `sub_00245568` around `0x2455b8`, `0x2455e8`, and `0x2455f0`, plus `sub_005420C0(1)`, to determine why the request sequence keeps cycling and whether it needs a real payload/reply instead of more queue clearing.

## Checkpoint 2026-07-09 245568 Instrumentation + 595 Payload Ret1

- Goal: move past the apparent `0x245610` blocker using evidence from `sub_00245568`, not another blind queue clear.
- Implemented instrumentation/experiment:
  - `work\generated\ghidra\sub_00245568_0x245568.cpp` logs the local loop state at `post-setup`, before/after `sub_005420C0(1)`, after `sub_005424A8(s1)`, and return.
  - `work\generated\ghidra\FUN_005418d0_0x5418d0.cpp` logs request `0xE` success/fail state, including `0x0061FC00`.
  - `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp` adds env-gated `MC3_SIF_EXPERIMENT_595_PAYLOAD_RET1`, which writes `1` to payload `0x0061FC00` for request `0xE` only when enabled.
  - `tools\Boot-Probe.ps1` adds mode `pollsid59c595ret2mode9payload1`; `15_auto_boot_probe.bat` aliases it as `595ret2m9p1`, `mode9p1`, and `payload1`.
- Verified commands:
  - manual object compile for `sub_00245568_0x245568.cpp`
  - manual object compile for `FUN_005418d0_0x5418d0.cpp`
  - `cmd /c 03_build_ps2recomp.bat`
  - `cmd /c 10_link_partial_runner.bat`
  - `cmd /c 15_auto_boot_probe.bat 8 595ret2m9`
  - `cmd /c 15_auto_boot_probe.bat 8 595ret2m9p1`
- Baseline evidence (`595ret2m9`):
  - `sub_00245568` now reaches `after-5420c0-pass`, `after-5424a8-pass`, and `return`, so the old `0x245610` blocker is no longer the first hard stop.
  - `FUN_005418d0` reached request `0xE` success path, but `0x0061FC00` stayed `0`, so it returned `0`.
- Payload1 evidence (`595ret2m9p1`):
  - `FUN_005418d0` now logs `after-549488-reqe ... fc00=0x1`, `return-success ... s0=0x1`, and `return ... v0=0x1`.
  - `sub_005420C0` returns `v0=0x2`, `sub_005424A8` returns `v0=0x1`, and `fun_005422c8` returns `v0=0x1` repeatedly.
  - `sub_00245568` returns repeatedly with `v0=0xffffffffffffffff` because its final return is `$s2`, loaded from `sub_00542578`.
  - Latest status: mode `pollsid59c595ret2mode9payload1`, stable PC `0x2455b8`, counters still `dma=2 gif=0 gsw=0 vif=3`.
- Current conclusion:
  - The 595 payload value was a real blocker and is now cleared under the new env-gate.
  - The next blocker is not `FUN_005418d0` or the `0x245610` branch; it is the outer `sub_00245568`/caller cycle. Map `sub_00542578` and the caller of `sub_00245568` to understand why `$s2 == -1` is returned and whether that is expected retry, menu/movie wait, or a missing render-state transition.
  - Status parser still overstates `render-started`; `gif=0` and `gsw=0` remain the visual gate.

## Checkpoint 2026-07-09 Mode3 + 5A8898 Fatal Loop Experiments

- Goal: push past the post-`payload1` blocker in `sub_00542578` and find the next hard stop without touching PCSX2 memory.
- Implemented env-gated experiments/instrumentation:
  - `work\generated\ghidra\sub_00542578_0x542578.cpp` now logs before/after `FUN_00541A78(3)`, request `4`, and return state.
  - `work\generated\ghidra\FUN_00541a78_0x541a78.cpp` adds `MC3_EXPERIMENT_541A78_RET1_FOR_MODE3`, forcing only mode `3` zero-return to `1`.
  - `tools\Boot-Probe.ps1` adds `pollsid59c595ret2mode9payload1m3`; `15_auto_boot_probe.bat` aliases it as `595ret2m9p1m3`, `mode9p1m3`, and `payload1m3`.
  - `work\generated\ghidra\sub_005A8898_0x5a8898.cpp` adds `MC3_EXPERIMENT_5A8898_SKIP_FATAL_LOOP`, forcing the local fatal loop condition at `0x5A88F0` to continue once `sub_004FA398` returned `0`.
  - `tools\Boot-Probe.ps1` adds `pollsid59c595ret2mode9payload1m3skip5a`; `15_auto_boot_probe.bat` aliases it as `595ret2m9p1m3skip5a`, `mode9p1m3skip5a`, and `payload1m3skip5a`.
- Verified commands:
  - manual object compile for `sub_00542578_0x542578.cpp`
  - manual object compile for `FUN_00541a78_0x541a78.cpp`
  - manual object compile for `sub_005A8898_0x5a8898.cpp`
  - `cmd /c 10_link_partial_runner.bat`
  - `cmd /c 15_auto_boot_probe.bat 6 595ret2m9p1m3`
  - `cmd /c 15_auto_boot_probe.bat 6 payload1m3skip5a`
- Evidence:
  - Without the mode3 force, `sub_00542578` fails before request `4`: `FUN_00541A78(3)` returns `0`, with `d80=0 d84=0 d88=0 d8c=0xfe`.
  - With `payload1m3`, trace logs `fun_00541a78:force-ret1-mode3`, `sub_00542578:after-541a78-mode3 v0=0x1`, reaches request `4`, then `sub_00542578:return v0=0x0`.
  - `payload1m3` moves stable PC from the caller loop around `0x24574c` to `0x5A8908` in `sub_005A8898`, proving the mode3 gate was a real blocker.
  - `0x5A8908` is an intentional infinite loop reached when `sub_004FA398` returns `0` inside `sub_005A8898`; caller is `sub_004BD488`.
  - With `payload1m3skip5a`, trace logs `sub_005a8898:skip-fatal-loop ... stack0=0x6f726463 stack4=0x5c3a306d`, and stable PC moves to `sceSifSetDma_0x546d60`.
- Latest result:
  - mode: `pollsid59c595ret2mode9payload1m3skip5a`
  - status: `work\boot_probe\latest_status.md`, updated `2026-07-09 08:25:01`
  - classification: `render-started` by parser, but still no visual traffic
  - stable PC: `0x546d60`
  - function: `sceSifSetDma_0x546d60`
  - counters: `dma=0 gif=0 gsw=0 vif=2`
  - last wait block: `tid=4 sid=44 pc=0x5469e0 ra=0x1f7150`
- Current conclusion:
  - Today produced real forward motion: old `0x245610`/`0x24574c` blocker is bypassed under env gates, request `4` path is reached, and the next blocker is SIF/I/O around sid `44` / RA `0x1f7150`.
  - Still no `gif>0` or `gsw>0`; parser's `render-started` remains too optimistic.
  - Next step: map caller around `0x1f7150` and the SIF request sequence after `sub_005A8898` skip. Focus on why sid `44` is never signaled and whether the unhandled request around `0x6f9000` or the later file-driver requests need a real stub response. Do not promote these env gates as permanent behavior yet.

## Checkpoint 2026-07-09 Req4 620D80 Status + Seq+1 Delayed Completion

- Input from Codex CLI/Ralph side analysis:
  - `ra=0x1f7150` is inside `FUN_001f70e0_0x1f70e0`; that worker starts with `arg=0x2c`, creates/uses `sid=44`, then immediately waits.
  - Do not signal `sid=44` blindly. The closer candidate is incomplete SIF/I/O response before that worker, especially `request=0x4 payload=0x620d80 size=0x4`.
- Implemented env-gated runtime experiment:
  - `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp` adds `MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS`.
  - New mode `pollsid59c595ret2mode9payload1m3skip5areq4` / alias `req4` writes `1` to payload `0x00620D80` for request `0x4`, with trace kind `request-4-620d80-status`.
  - `tools\Boot-Probe.ps1` and `15_auto_boot_probe.bat` expose the mode.
- Implemented generated-code adjustment under existing env gate:
  - `work\generated\ghidra\sub_005424A8_0x5424a8.cpp` delayed completion now allows `nodeSeq == queueSeq + 1`, syncs `0x00620D54` to `nodeSeq`, then clears `0x0061FBB4`, `0x0061FBD8`, `node+0x18`, and busy bit.
- Verified commands:
  - `cmd /c 03_build_ps2recomp.bat`
  - `cmd /c 10_link_partial_runner.bat`
  - `cmd /c 15_auto_boot_probe.bat 6 req4`
  - manual compile of `sub_005424A8_0x5424a8.cpp`, then `10_link_partial_runner.bat`
  - `cmd /c 15_auto_boot_probe.bat 6 req4`
- Evidence:
  - First `req4` run before seq+1 delayed completion:
    - `request-4-620d80-status ... value=0x1`
    - `sub_00542578:return v0=0x1`, proving the request `4` payload was a real blocker.
    - Stable PC moved to `0x5419a0` in `FUN_00541968`, with `fbb4=1 fbd8=4 d50=0x206ff080 qseq=0x23 q18=0x24`.
- After allowing delayed completion for `nodeSeq == queueSeq + 1`:
    - Stable PC moved again to `0x54bcb0` in `sub_0054BC40_0x54bc40`.
    - Latest status: mode `pollsid59c595ret2mode9payload1m3skip5areq4`, updated `2026-07-09 09:03:06`.
    - Counters still `gif=0 gsw=0`, `vif=2`; no visual traffic yet.

## Checkpoint 2026-07-10 PCSX2-MCP Read-Only Comparison

- Scope and guardrails:
  - PCSX2 was used only as a read-only runtime oracle.
  - No PCSX2 memory/register writes, patches, or broad recomp refactor were performed.
  - The bundled PCSX2-MCP session was started with the MC3 ISO from `work\config\pcsx2_mcp.local.json`.
- Live connection confirmed:
  - Title `Midnight Club 3 - DUB Edition Remix`, ID `SLUS-21355`, game `1.00`.
  - PCSX2 DebugServer connected on `127.0.0.1:21512`; Pine was intermittent and later timed out.
- Strongest live evidence:
  - PC `0x004f9760` paused inside `FUN_004f9760_0x4f9760`, reached from `sub_003991F0_0x3991f0`.
  - Its input string was `fonts/mcloadstrings.strtbl`.
  - `0x00629f44..0x00629f50` contained `0x005c0c40, 0x005c0c50, 0x0041f9b0, 0x00357328`.
  - `0x006218fc` was `1` in the real game.
  - The function at `0x4f9760` is the package/list provider dispatcher. It is not the low-level backend-open itself; the backend table begins at `0x00617fc0`, with open entry `0x003984c0`.
- Interpretation for the partial runner:
  - The existing partial trace showing provider `0x619f58`, method `0x4f9760`, and failed opens for `texture.zip`/`shaderlib/city.zip` is consistent with missing or uninitialized package/list state, not just the `0x6218fc` readiness flag.
  - The earlier `request=0x4 payload=0x620d80` remains the immediate SIF predecessor to worker `sid=44`; the PCSX2 comparison strengthens the hypothesis that the response must initialize the package/file-provider path before the worker can progress.
  - Do not signal `sid=44` blindly and do not promote the current env gates to permanent behavior.
- Capture limitation:
  - Setting multiple DebugServer breakpoints and stepping caused `ECONNRESET`; the PCSX2 process then exited. The memory snapshot above is valid, but no complete live call/return trace was captured.
- Pending tasks:
  - Add `MC3_TRACE_54A350_FILEOPEN` as an env-gated trace around `sub_0054A350_0x54a350`, logging arguments, path/object identity, provider state, and return value without changing behavior.
  - Rebuild/relink the partial runner and run `cmd /c 10_link_partial_runner.bat` plus `cmd /c 15_auto_boot_probe.bat 6 payload1m3skip5a` with the trace enabled.
  - Compare the first package/file requests against the PCSX2 snapshot, especially globals `0x629f44`, `0x629f48`, `0x629f4c`, backend table `0x617fc0`, and requests around `0x6f9000`, `0x620d80`, and `0x701b40`.
  - Only after that comparison decide whether the smallest fix is a real env-gated provider initialization/response or a missing file-driver stub; keep PCSX2 untouched.
- Current blocker:
  - `0x54bcb0` is inside `sub_0054BC40_0x54bc40`, reached from file-driver path; final SIF envelopes show `request=0x0 payload=0x701b40 size=0x8` and nearby file-driver requests.
  - Next step: use existing `sub_0054BC40` instrumentation to map why it parks at `0x54bcb0`, then decide whether request `0x0/0x9` for `0x701b40` needs a more realistic file-driver response. Do not add another blind semaphore signal.

## Checkpoint 2026-07-10 PC 0x2B4488 Pivot

- The previous `0x54bcb0` blocker is no longer the live target. The current baseline now stabilizes at `0x2b4488` inside `sub_002B4438_0x2b4438`.
- Baseline reproduced with:
  - `cmd /c 15_auto_boot_probe.bat 6 payload1m3skip5a`
  - Result: `Classification=render-started`, `Stable PC=0x2b4488`, `RA=0x2b4478`, `dma=2 gif=0 gsw=0 vif=3`.
- Exact condition at `0x2b4488`:
  - `sub_002B4438` loads global object `0x006d557c`.
  - Reads vtable entry at `+0x24`.
  - Calls that virtual method with `a2=0x00647a8b`, `a3=0`, and delay-slot `t0=1`.
  - If the method returns `0`, execution falls into an explicit local spin loop at `0x2b4488`.
  - If the method returns non-zero, the function continues through allocation/setup and returns normally.
- Caller chain now relevant:
  - `FUN_003b34c0_0x3b34c0` calls `sub_002B4438` repeatedly for indexes `0..8` with string pointers around `0x0066d330`.
  - The stable `RA=0x2b4478` is the internal return point immediately after the virtual `jalr`; the outer caller remains `FUN_003b34c0`.
- Relationship with older SIF/file-driver evidence:
  - The latest baseline still logs unhandled file-driver requests before the spin:
    - `request=0x0 payload=0x701b40 size=0x8`
    - `request=0x9 payload=0x701b40 size=0x4`
  - `sid=44` still appears blocked on thread `tid=4` with `pc=0x5469e0 ra=0x1f7150`, but `0x2b4488` itself is not waiting on `WaitSema`; it is spinning on a null return from the object method.
  - `request=0x4 payload=0x620d80 size=0x4` is still present in the same baseline, but it is no longer sufficient to explain the live stop by itself.
- Current question:
  - Determine what state the object behind `0x006d557c` expects, who should populate it, and whether that state causally depends on the still-unhandled `0x701b40` file-driver requests.
- Next step:
  - Map initialization/writers of global `0x006d557c` and the concrete function behind its vtable slot `+0x24`.
  - Only if that producer depends on `0x701b40`, add a small env-gated file-driver experiment. Otherwise archive `sid=44/0x54BCB0/0x701B40` as historical debt and continue on the new pipeline.

## Checkpoint 2026-07-12 Re-Pivot To 0x42EB90 / WaitSema sid=48

- Reproduced the current baseline with:
  - `cmd /c 15_auto_boot_probe.bat 6 payload1m3skip5a`
  - Timestamp: `2026-07-12 18:25:18`
- Result no longer stabilizes at `0x2b4488`. Current output is:
  - `Classification=missing-function`
  - first bad dispatch target `bad=0x42eb90`
  - `RA=0x42ee40`
  - stable wait frame `PC=0x5469e0` (`WaitSema_0x5469e0`)
  - last block `tid=4 sid=48 count=0 waiters=0 pc=0x5469e0 ra=0x1f7150`
- SIF/request context from the same baseline:
  - `request=0x0 aux=0x701880 sema=44` still appears
  - `request=0x4 aux=0x621700 payload=0x620d80 size=0x4 sema=47` still appears
  - `request=0xe payload=0x61fc00 size=0x4 value=0x1` is handled by the current experiment path
- Practical consequence:
  - `0x2B4488` remains structurally mapped, but it is no longer the confirmed live baseline on `2026-07-12`.
  - The operational blocker is now the missing-function path around `0x42eb90 / 0x42ee40`, with the observed runtime settling on `WaitSema sid=48`.
  - Treat `0x6d557c / vtable[0x24]` as a sidecar structural track until the new baseline is explained or eliminated.
- Known structural context kept from the previous pivot:
  - `sub_00429410_0x429410` publishes global `0x6d557c`.
  - `sub_00429A90_0x429a90` appears to build the main derived object (`vtable 0x6321e0`) used by the higher-level pipeline.
  - `sub_002B4438_0x2b4438` still spins at `0x2b4488` when `0x6d557c->vtable[0x24]` returns `0`.
- Next step:
  - Map `0x42eb90` and caller `0x42ee40`, then identify what should signal or satisfy `sid=48`.
  - In parallel, keep resolving the concrete `0x6d557c->vtable[0x24]` implementation and its state fields, but do not promote it back to primary target unless the new baseline falls through it again.

## Checkpoint 2026-07-12 0x42EB90 + vtable[0x24] Resolution

- `0x42eb90` is not a function entry. It is an internal label inside `sub_0042EB08_0x42eb08`.
- Immediate caller chain around the current missing-function path:
  - `sub_0042FAE0_0x42fae0`
  - `sub_0042F558_0x42f558`
  - `sub_0042ED48_0x42ed48`
  - `jalr $s3` into the internal callback/parser label `0x42eb90`
  - returns through `ra=0x42ee40`
- Current runtime stop is still the wait frame:
  - `WaitSema_0x5469e0`
  - `tid=4 sid=48`
  - `ra=0x1f7150`
- Practical reading:
  - the live blocker is no longer best described as “bad pc 0x42eb90” by itself;
  - `0x42eb90` is part of the upstream callback/parser path, while the observable stall is the later async wait on `sid=48`.
- Best current causal suspicion:
  - `sid=48` should be released by completion of the async SIF/IO callback/commit chain after the `request=0x4 aux=0x621700 payload=0x620d80 size=0x4` envelope.
  - This is still a structural suspicion, not yet a fully proven producer/consumer pair.

- The concrete method behind `0x6d557c->vtable[0x24]` is now identified:
  - derived type built by `sub_00429A90_0x429a90` uses vtable `0x6321e0`
  - slot `+0x24` resolves to `sub_00429FC0_0x429fc0`
- `sub_00429FC0_0x429fc0` return gates:
  - first calls same-object virtual slot `+0x0c` to materialize a path/id buffer
  - if `sub_003991F0_0x3991f0` already resolves a handle, returns it
  - if caller flag `t0/s0 == 0`, returns `0`
  - if global `0x628d00 == 0`, returns `0`
  - otherwise builds alternate path and calls `FUN_00429E18_0x429e18`
- Relationship to `obj+0x404`:
  - indirect only
  - `sub_00429FC0` does not read `obj+0x404` directly
  - it depends on virtual slot `+0x0c`, which in the `0x6321e0` type is `FUN_00429AC8_0x429ac8`
  - `FUN_00429AC8` does consult `obj+0x404`
- Negative result:
  - no direct static dependency was found from `429fc0 / 429e18 / 429ac8` to `0x701B40` or `0x620d80`
  - current explicit gate in that slice is global `0x628d00`, plus local path/lookup helpers
- Consequence:
  - `0x6d557c->vtable[0x24]` is now structurally understood enough to demote `0x701B40` further
  - the new high-value unknowns are:
    - who writes or flips `0x628d00`
    - who ultimately signals the worker blocked on `sid=48`

## Checkpoint 2026-07-12 sid=48 Ownership Narrowed To 0x549488 Async Request Path

- Reproduced current baseline again with:
  - `cmd /c 15_auto_boot_probe.bat 6 payload1m3skip5a`
- Current summary now reports:
  - `Classification=render-started`
  - `Stable PC=0x3b3504`
  - but the relevant block still remains:
    - `Last WaitSema Block: tid=4 sid=48 pc=0x5469e0 ra=0x1f7150`
  - current SIF envelope still includes:
    - `request=0x4 aux=0x621700 payload=0x620d80 size=0x4 sema=47`
- `sub_00542578_0x542578` is the direct caller that dispatches:
  - `a0=0x621700`
  - `a1=0x4`
  - `t1/s0=0x620d80`
  - `t2=0x4`
  - into `sub_00549488_0x549488`
  - then signals global sema `0x62fbac` on both error and completion paths
- `sub_00549488_0x549488` now owns the concrete lifecycle of `sid=48`:
  - creates a fresh sema at `0x5495d4` via `CreateSema_0x5469a0`
  - stores returned sid in `s1+0x8` at `0x5495e0`
  - issues async worker/request via `sub_00548A00_0x548a00` at `0x549610`
  - if submit returns non-zero, enters `WaitSema_0x5469e0` at `0x549638`
  - on wake, returns through `0x549640` and immediately `DeleteSema_0x5469b0`
- This closes an earlier ambiguity:
  - the `sid=48` block observed at `WaitSema_0x5469e0 ra=0x1f7150` is not an unrelated dormant legacy wait
  - it belongs to the same async request family driven through `0x549488`
  - older traces already showed successful wake at:
    - `WaitSema:wake sid=48 ret=0 pc=0x5469e0 ra=0x549640`
- Current causal read:
  - `0x701B40` still has no direct structural consumer in the `429fc0 / 429e18 / 429ac8` provider gate slice
  - the live blocker has shifted to: what completion path should signal the sema created by `0x549488` after the `request=0x4 aux=0x621700 payload=0x620d80 size=0x4` envelope
  - older validated traces used `request=0x22` on the same `0x621700 / 0x620d80` family and did wake `sid=48`; current probe shows `request=0x4`
- Best current unknowns:
  - which callback/worker path from `sub_00548A00_0x548a00` should signal `s1+0x8`
  - why older runs reached wake with `request=0x22` while current path reaches a persistent block after `request=0x4`
  - who writes `0x628d00`, which still gates the fallback `.zip` path in `sub_00429FC0_0x429fc0`

## Checkpoint 2026-07-12 Bootstrap Semaphores Split From Worker sid=48

- Two previously conflated sema families are now separated structurally:
  - worker sema `sid=48`, observed blocked at `WaitSema_0x5469e0 ra=0x1f7150`
  - bootstrap semas stored in globals `0x62174c` and `0x621750`
- `sub_00542968_0x542968` now explains the bootstrap pair:
  - creates global sema `0x62174c`
  - creates global sema `0x621750`
  - waits on `0x62174c` at `0x5429e0`
  - later signals `0x62174c` at `0x542aa8`
  - has a tail path that `iSignalSema(0x621750)` at `0x542b44`
- The same function then drives `sub_00549488_0x549488` with:
  - `t0 = 0x30`
  - `t2 = 0x0c`
  - and the existing async request setup path
- `sid=48` itself is not carried by the SIF request node:
  - `FUN_00398b88_0x398b88` creates and starts thread `entry=0x1f70e0`
  - the thread argument comes from caller register `a1 = s4`
  - in the observed live path that argument is `0x30`
  - trace evidence already confirms:
    - `start-thread-request ... entry=0x1f70e0 arg=0x30`
- Consequence:
  - the live worker block is now best modeled as:
    - bootstrap path sets up thread `0x1f70e0(arg=0x30)`
    - worker waits on sema `48`
    - some later producer should call `SignalSema(48)` / `sub_00398B40_0x398b40`
  - this is distinct from the local ack sema created inside `sub_00549488_0x549488`
  - and also distinct from bootstrap globals `0x62174c/0x621750`
- `0x42eb90` / `sub_0042ED48_0x42ed48` was also rechecked:
  - it remains in the callback/parser formatting loop
  - no structural evidence was found there for thread creation, sema creation, or direct wake production for `sid=48`
- Updated priority after this split:
  - primary: callers of `FUN_00398b88_0x398b88` plus concrete producers of `SignalSema(48)`
  - secondary: request-family completion logic around `sub_00548A00_0x548a00`
  - archived unless re-proven: direct causal role of `0x42eb90`

## Checkpoint 2026-07-10 Reanchor After Boot-Probe Fix

- Fixed a wrapper bug in `tools\Boot-Probe.ps1`: `Invoke-ProbeRun` was piping `Invoke-BatStep` into `Out-Host`, which caused `Write-Step -> Add-Content` to receive a non-readable stream object and abort the probe early. The fix only removed that pipe.
- After the wrapper fix, `cmd /c 15_auto_boot_probe.bat 6 payload1m3skip5a` completes again. The current status summary now reports:
  - `Classification=render-started`
  - `Stable PC=0x5469c0` (`SignalSema_0x5469c0`)
  - `dma=2 gif=0 gsw=0 vif=0`
- Important nuance: the raw trace still contains the old worker frame `pc=0x2b4488 ra=0x2b4478`. So `0x5469c0` is the hottest visible loop chosen by the summarizer, not proof that `0x2B4488` disappeared from the live path.
- With `MC3_TRACE_3991F0_OPEN=1`, the file/package open path is confirmed live:
  - `sub_003991F0_0x3991f0` selects provider slot `0x618020`
  - provider object `0x619f58`
  - method `0x4f9760`
  - backend table remains initialized at `0x617fc0` (`open=0x3984c0`, `close=0x398610`, `read=0x3986d8`, `seek=0x398730`, `stat=0x398788`, `extra=0x3987e0`)
  - repeated returns are `handle=0xffffffff` for `texture.zip` and `texture/...` assets
- Additional structure mapped:
  - `sub_004F9AA0_0x4f9aa0` updates `0x00629f4c`
  - `sub_004F9B38_0x4f9b38` loops while `0x00629f4c != 0`, repeatedly driving `sub_004F9AA0`
  - `sub_004FB0D8_0x4fb0d8` allocates/tracks package-open slots in the `0x006f3b00` area before `0x4f9760`
- Causal reading at this point:
  - Immediate failure is now better explained as package/provider state or package contents lookup returning miss, not a null low-level file backend.
  - `0x701B40` requests still appear unhandled in the same run (`request=0x0 size=0x8`, `request=0x9 size=0x4`), but they remain upstream correlation only. They are not yet proven to be the direct reason for the `0x4f9760 -> -1` returns.
- Current practical question:
  - Who should produce valid package/provider state so `FUN_004f9760_0x4f9760` stops returning `-1` for `texture.zip` lookups, and does that producer depend on the unhandled `0x701B40` requests.

## Checkpoint 2026-07-10 Package Provider State Chain

- The package/provider state behind `0x4f9760` is now structurally mapped enough to separate local provider setup from the upstream file-driver hypothesis.
- Concrete chain:
  - `sub_003991F0_0x3991f0` selects provider slot `0x618020`.
  - That slot points to provider object `0x619f58`, whose entry method is `FUN_004f9760_0x4f9760`.
  - `FUN_004f9760` first tries global primary provider `0x629f44`; if absent or failing, it walks fallback chain `0x629f4c`.
  - Each open attempt allocates/tracks a package-open slot through `sub_004FB0D8_0x4fb0d8`, which itself calls `sub_004FAED8_0x4faed8`.
- `sub_004FAED8_0x4faed8` is not a file-driver response path; it is a local package-open builder:
  - reads mode flags `0x629f40` / `0x629f41`
  - normalizes the incoming path via `sub_004FA5B8_0x4fa5b8`
  - chooses one of three local layouts/templates
  - allocates/builds a node via `FUN_00431b80_0x431b80`
- `sub_004FA5B8_0x4fa5b8` is a path canonicalizer/filter, not a backend open:
  - rewrites case and selected characters
  - handles separators and extension-ish characters
  - feeds the normalized name to the package-open builder
- `sub_004F9A68_0x4f9a68` is the local fallback-node constructor:
  - links the new node to previous `0x629f4c`
  - writes `0x629f4c = newNode`
  - initializes handle/state fields to empty/default values
- `FUN_004faa10_0x4faa10` is a higher-level package/list initializer:
  - may set `0x629f40 = 1` and `0x629f41 = 1`
  - is called right after `sub_004F9A68` in package setup flows such as `FUN_003c8cf8_0x3c8cf8`
- Current conclusion:
  - The producer of fallback provider state (`0x629f4c` plus flags `0x629f40/41`) is a local package/list setup chain, not the `0x701B40` request handler itself.
- The unhandled `0x701B40` requests still correlate with the same run, but there is still no direct structural evidence that they are what creates `0x629f4c` or flips `0x629f40/41`.
- So `0x701B40` remains upstream debt/hypothesis, not a proven immediate cause of the package-provider miss.

## Checkpoint 2026-07-12 sid=48 Worker Bootstrap + Callback Slot Narrowed

- `sub_001F72A0_0x1f72a0` is now the concrete bootstrap immediately upstream of the blocked worker:
  - stores the global sema/control id returned by `sub_00398B40_0x398b40` into `0x611000`
  - clears `0x614d7e`
  - starts thread entry `FUN_001f70e0_0x1f70e0` through `FUN_00398b88_0x398b88`
  - passes thread arg from `0x60?+0xa80`; in the live trace this is `0x30`, matching blocked `sid=48`
  - installs callback/context through `sub_00541600_0x541600(0x1f70c0, [s0+0xa80])`
  - sets `0x644b64 = 1`
- Immediate callers of `sub_001F72A0` confirmed so far:
  - `sub_001A0DB0_0x1a0db0` calls it with `a0=0`
  - `sub_001F73D0_0x1f73d0` calls it with `a0=1` on an alternate bootstrap branch
- `sub_00541600_0x541600` does not signal `sid=48` directly:
  - it enters a critical section via `sub_0054C160_0x54c160` / `FUN_0054c1b8_0x54c1b8`
  - initializes one-shot guard globals `0x62fba4` / `0x62fbc0` through `sub_005416D8_0x5416d8`
  - stores callback state in globals:
    - `0x70ac88 = callback fn`
    - `0x70ac8c = gp`
    - `0x70ac90 = callback arg/context`
- `FUN_00541680_0x541680` is the actual callback invoker:
  - if `0x70ac88 != 0` and `0x62fba4 == 0`, it restores `gp` from `0x70ac8c` and `jalr`s into `0x70ac88(a0 = [0x70ac90])`
  - so the missing wake for `sid=48` is now best modeled as:
    - callback slot not installed correctly, or
    - callback invoker not reached, or
    - callback branch returns without producing the expected event
- `FUN_001f70e0_0x1f70e0` semantics around the live block are now clearer:
  - `0x1f7148` waits on `WaitSema(a0 = s2)` where thread arg `s2` is the live `0x30`
  - `pc=0x1f7150` is just the post-wake continuation point, not the root cause by itself
  - after wake, if `0x614d7e != 0`, the worker signals the global sema/control id at `0x6b1000/0x611000` via `sub_00398B40_0x398b40` and exits through `sub_00398C20_0x398c20`
  - if `0x614d7e == 0`, it enters the normal worker path through `FUN_00398c60_0x398c60` and the subsequent `0x1f7180+` logic
- Consequence:
  - `0x614d7e` is a shutdown/flush gate after wake, not the producer of the missing wake
  - the highest-value unknown is now the producer path that should eventually wake `sid=48`, most likely downstream of the callback slot installed at `0x70ac88/0x70ac90`
