# MC3 PS2Recomp Brain

## Goal

Rebuild this workspace from a clean, documented pipeline for Midnight Club 3:

1. Extract the PS2 ISO.
2. Identify and preserve the boot ELF.
3. Analyze the ELF in Ghidra with R5900 / Emotion Engine support.
4. Export PS2Recomp TOML/CSV.
5. Generate C++ with PS2Recomp.
6. Document functions and variables from the Ghidra/recomp evidence, not guesswork.

## Known Truth

- Workspace root: `D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp`
- ISO: `Midnight Club 3 - DUB Edition Remix.iso`
- Boot ELF from `SYSTEM.CNF`: `SLUS_213.55`
- PS2Recomp source: `PS2Recomp`
- Ghidra executable: `ghidra_12.1_PUBLIC\ghidraRun.bat`
- Ghidra Emotion Engine extension: `ghidra_12.1_PUBLIC\Ghidra\Extensions\ghidra-emotionengine-reloaded`

## Current First Milestone

The first milestone is pipeline proof, not full function documentation:

## Boot Probe Status - 2026-06-29

- `15_auto_boot_probe.bat 10 probe` confirms baseline PC `0x246740` in `FUN_002466e0_0x2466e0`.
- Cause classification: `sif-reg-poll`; the game waits for `sceSifGetReg(4) & 0x00040000`.
- `10_link_partial_runner.bat fast` now skips full alias regeneration and relinks from existing register/stub manifests.
- `15_auto_boot_probe.bat 5 compare` shows:
  - baseline: `0x246740`, no render traffic;
  - latch reg4 experiment: advances to `0x246a80`, `FUN_00246880_0x246880`;
  - stage2 experiment: also advances to `0x246a80`;
  - render counters remain zero.
- New blocker: `0x246a80` loops through `sub_00246660_0x246660`, which returns the result of `sub_0054BE68_0x54be68` -> `sub_0054BC40_0x54bc40`. This now looks like a file/IOP request response gap, not a batch compile gap.

- Done: `extracted_iso\SLUS_213.55` exists.
- Done: PS2Recomp builds.
- Done: native analyzer fallback generated TOML.
- Done: `ps2_recomp` generated C++ from the fallback TOML.
- Done: Ghidra 12.1 is extracted and detected by `00_status.bat`.
- Done: compatible `ghidra-emotionengine-reloaded` 12.1 is installed.
- Done: `ExportPS2Functions.java` TOML/CSV from the real Ghidra project.
- Done: `ps2_recomp` generated C++ from the Ghidra TOML.
- Done: function index and 250-function batch manifests exist.
- Current: prepare native runtime compilation in small batches.

## Latest Evidence

- `03_build_ps2recomp.bat` completed successfully after pinning ELFIO to `Release_3.12`.
- `05_native_analyzer_fallback.bat` created `work\exports\SLUS_213.55.native_analyzer.toml`.
- `04_run_recomp.bat` generated `12099` files, about `311.8 MB`, under `work\generated\native_analyzer`.
- `PS2Recomp\out\build\ps2xTest\ps2x_tests.exe` passes from the `PS2Recomp` working directory: `263` passed, `0` failed.
- `ghidra_12.1_PUBLIC_20260513.zip` was extracted locally.
- `ghidra_12.1_PUBLIC_20260522_ghidra-emotionengine-reloaded.zip` was downloaded from the upstream release and extracted into Ghidra.
- Ghidra CodeBrowser launch error on 2026-06-01 was caused by missing temp directory `<user-home>\AppData\Local\Temp\ghidra`; `02_open_ghidra.bat` now creates it before launch.
- After creating the temp directory, Ghidra 12.1 reopened `work\mc2recomp` without new `RuntimeIOException` / `Failed to Launch Tool` entries.
- `ExportPS2Functions.java` now accepts optional headless args: `toml_path csv_path`.
- `07_export_ghidra_headless.bat` exports TOML/CSV from the analyzed `work\mc2recomp` project without using the Script Manager picker.
- Manual Ghidra export on 2026-06-01 produced `exportado1.txt` and `exportado2.txt`; these were identified as TOML and CSV, renamed to `work\exports\SLUS_213.55.ghidra.toml` and `work\exports\SLUS_213.55.ghidra.csv`, and the TOML paths were normalized.
- `04_run_recomp.bat` completed successfully from `SLUS_213.55.ghidra.toml`.
- Ghidra-based generated output exists under `work\generated\ghidra`: `15814` files, about `393.76 MB`.
- `08_index_generated_functions.bat 250` generated `work\index\functions_index.csv`, `docs\FUNCTION_INDEX.md`, and `64` batch manifests under `work\batches\ghidra`.
- `09_compile_generated_batch.bat batch_0001 10 syntax` passed.
- `09_compile_generated_batch.bat batch_0001 5 object` passed and wrote objects under `work\compile\ghidra\batch_0001\obj`.
- `09_compile_generated_batch.bat batch_0054 25 syntax` passed.
- `09_compile_generated_batch.bat batch_0001 60 syntax` passed.
- `09_compile_generated_batch.bat batch_0001 60 object` passed and produced `60` object files, about `2.66 MB`.
- `09_compile_generated_batch.bat batch_0001 100 syntax` passed.
- `09_compile_generated_batch.bat batch_0001 100 object` passed and produced `100` object files, about `4.55 MB`.
- `09_compile_generated_batch.bat batch_0001 250 syntax` passed.
- `09_compile_generated_batch.bat batch_0001 250 object` passed and produced `250` object files, about `10.57 MB`.
- `09_compile_generated_batch.bat batch_0002 250 syntax` passed.
- `09_compile_generated_batch.bat batch_0002 250 object` passed and produced `250` object files, about `16.28 MB`.
- `09_compile_generated_batch.bat batch_0003 250 syntax` passed.
- `09_compile_generated_batch.bat batch_0003 250 object 120` passed and produced `250` object files, about `13.91 MB`.
- Total through `batch_0003`: `750` object files, about `40.76 MB`.
- First real object compile blocker found in `batch_0003`: generated VU/SIMD code calls `_mm_blendv_ps`, which requires SSE4.1. Fixed by adding `-msse4.1` to `tools\Compile-GeneratedBatch.ps1`.
- `tools\Compile-GeneratedBatch.ps1` now supports per-file timeout and kills the compiler process tree on timeout.
- `PS2-Programming-Docs` contains local EE/VU/GS/SPU2/pad/calling-convention references. Indexed in `docs\PS2_PROGRAMMING_DOCS_INDEX.md`.
- `ps2EntryRunner.exe` from `PS2Recomp\out\build` exists, but its source runner has an empty `registerAllFunctions`; it is a tool/runtime executable, not the MC3 linked recomp build.
- `10_link_partial_runner.bat` created `work\link\partial\mc3_partial.exe`: `750` real compiled functions plus `15061` temporary missing-function stubs.
- The partial exe is for fast runtime smoke tests and avoids relinking from generated source every time. It is not yet the final complete game exe.
- Runtime smoke exposed missing internal PC aliases (`0x1a0138`) because generated functions can resume at internal `case 0x...` labels. `tools\Generate-PartialRegister.ps1` now registers those aliases to their owner function.
- `batch_0054` was compiled after the first real missing boot dependency: `sub_0054C3C0_0x54c3c0`.
- `batch_0037` was compiled after the next missing boot dependency: `FUN_004329b0_0x4329b0`.
- `batch_0053` was compiled after the next missing dependency: `AddIntcHandler_0x546690`.
- Current partial exe state: `1500` real compiled functions, `14311` missing-function stubs, about `62.23 MB`.
- First compile blocker found and solved: generated files need include paths for `work\generated\ghidra`, `PS2Recomp\ps2xRuntime\include`, and `PS2Recomp\ps2xRuntime\src\lib\Kernel` because `ps2_stubs.h` includes `Stubs/Unimplemented.h`.
- Function index has one CSV row without generated `.cpp`: `FUN_006357d8` at `0x006357D8`, size `1`, in `batch_0064`.

## Checkpoint 2026-06-01 23:37 -03:00

- Latest partial runner: `work\link\partial\mc3_partial.exe`.
- Latest link registered `5500` real compiled functions.
- Latest link generated `10311` temporary missing-function stubs.
- Latest link registered `475143` internal PC aliases.
- Current compiled object coverage is `22` batches / `5500` generated functions.
- Compiled object batches: `batch_0001`, `batch_0002`, `batch_0003`, `batch_0005`, `batch_0027`, `batch_0028`, `batch_0029`, `batch_0035`, `batch_0036`, `batch_0037`, `batch_0043`, `batch_0044`, `batch_0045`, `batch_0051`, `batch_0052`, `batch_0053`, `batch_0054`, `batch_0055`, `batch_0057`, `batch_0058`, `batch_0059`, `batch_0060`.
- Additional runtime-driven batches solved after the earlier `1500`-function checkpoint: `batch_0027`, `batch_0036`, `batch_0005`, `batch_0045`, `batch_0029`, `batch_0028`, `batch_0044`, `batch_0043`, `batch_0051`, `batch_0052`, `batch_0060`, `batch_0035`, `batch_0059`, `batch_0058`, `batch_0057`, `batch_0055`.
- Missing/hard-stop sequence solved in this round: `FUN_00398370_0x398370`, `sub_0042D2B8_0x42d2b8`, `sub_001F66A8_0x1f66a8`, `sub_004BEC28_0x4bec28`, `FUN_003afbf0_0x3afbf0`, `sub_003A2DE0_0x3a2de0`, `FUN_004b6b00_0x4b6b00`, `FUN_004adc10_0x4adc10`, `sub_00528060_0x528060`, `sub_0052D4C8_0x52d4c8`, `sub_0041C900_0x41c900`.
- Latest smoke no longer ended with `[partial-runner:missing-function]`; it ended with recoverable missing PCs, `StartThread id=2/id=3 exception: PS2 Thread Exit`, and `Exit code: 0`.
- Current first bad PC in `work\logs\11_run_partial_runner.log` is `0x514590`.
- New trace-driven automation exists: `12_trace_driven_compile.bat 2 250 120`.
- The automation reads `work\logs\11_run_partial_runner.log`, maps missing PCs to `work\index\functions_index.csv`, skips already compiled object batches, compiles up to the requested number of batches, relinks, smokes, and updates `work\trace_driven\latest_status.md` plus `docs\TRACE_DRIVEN_STATUS.md`.
- Desktop shortcut: `<user-home>\Desktop\MC3 Trace Driven Compile.lnk`.
- Next runtime-driven compile targets are in `docs\TRACE_DRIVEN_STATUS.md`; current first targets are `batch_0050`, `batch_0049`, `batch_0048`, `batch_0047`, and `batch_0046`.

## Working Directories

- `extracted_iso\`: extracted disc contents.
- `work\ghidra\`: intended Ghidra project storage.
- `work\exports\`: TOML/CSV exported from Ghidra.
- `work\generated\`: generated C++ output.
- `work\logs\`: logs from batch scripts.
- `work\index\`: machine-readable generated function indexes.
- `work\batches\`: incremental batch manifests for compile/analyze loops.
- `docs\`: living documentation and handoff notes.

## Launchers

- `00_status.bat`: checks tools and pipeline state.
- `01_extract_iso.bat`: extracts the disc image.
- `02_open_ghidra.bat`: opens Ghidra when `ghidraRun.bat` is available.
- `03_build_ps2recomp.bat`: configures and builds PS2Recomp.
- `04_run_recomp.bat`: runs the newest TOML in `work\exports`.
- `05_native_analyzer_fallback.bat`: creates a preliminary TOML without Ghidra.
- `06_open_ps2x_studio.bat`: opens the built visual Studio helper.
- `07_export_ghidra_headless.bat`: exports Ghidra TOML/CSV after GUI analysis.
- `08_index_generated_functions.bat`: indexes Ghidra CSV and creates incremental batch manifests.
- `09_compile_generated_batch.bat`: compiles a selected generated batch in `syntax` or `object` mode with a file limit.
- `10_link_partial_runner.bat`: generates a partial register file, missing-function stubs, and links `work\link\partial\mc3_partial.exe`.
- `11_run_partial_runner.bat`: runs the partial exe with `extracted_iso\SLUS_213.55`.
- `12_trace_driven_compile.bat`: compiles the next runtime-trace-selected batches, relinks, runs smoke, and updates `docs\TRACE_DRIVEN_STATUS.md`.

## Checkpoint 2026-06-17 Resume

- The project was resumed after several manual runs of the desktop trace-driven launcher.
- Latest verified trace-driven status was updated at `2026-06-11 09:38:34 -03:00`.
- Current partial runner state: `8000` real compiled functions, `7811` missing-function stubs, `636042` internal PC aliases.
- Current compiled object coverage: `32` batches / `8000` generated functions.
- Current compiled object batches: `batch_0001`, `batch_0002`, `batch_0003`, `batch_0005`, `batch_0027`, `batch_0028`, `batch_0029`, `batch_0035`, `batch_0036`, `batch_0037`, `batch_0038`, `batch_0039`, `batch_0040`, `batch_0041`, `batch_0042`, `batch_0043`, `batch_0044`, `batch_0045`, `batch_0046`, `batch_0047`, `batch_0048`, `batch_0049`, `batch_0050`, `batch_0051`, `batch_0052`, `batch_0053`, `batch_0054`, `batch_0055`, `batch_0057`, `batch_0058`, `batch_0059`, `batch_0060`.
- Latest first bad PC in `work\logs\11_run_partial_runner.log`: `0x42eb90`.
- `0x42eb90` was not found as a function start in `work\index\functions_index.csv`; it is confirmed inside `work\generated\ghidra\sub_0042EB08_0x42eb08.cpp`.
- Ghidra CSV/index range mismatch: `FUN_0042eb08` is indexed as `0x0042EB08..0x0042EB48`, but the generated C++ comment says `Address: 0x42eb08 - 0x42ebd8` and contains instructions through `0x42ebd4`.
- The next technical fix should likely update alias generation / trace resolution to use generated C++ internal PCs, so `0x42eb90` dispatches to `sub_0042EB08_0x42eb08` instead of being treated as missing.
- Next indexed trace targets from `docs\TRACE_DRIVEN_STATUS.md`: `batch_0034`, `batch_0033`, `batch_0032`, `batch_0031`, `batch_0030`, `batch_0026`, `batch_0025`, `batch_0024`, `batch_0021`, `batch_0020`.
- Gemini handoff: `docs\GEMINI_HANDOFF_2026-06-17.md`.
- Gemini launcher: `13_gemini_resume_review.bat`, read-only/plan mode, logging to `work\logs\13_gemini_resume_review.log`.

## Checkpoint 2026-06-17 23:16 -03:00

- `0x42eb90` blocker was resolved.
- Diagnosis: `0x42eb90` is inside `work\generated\ghidra\sub_0042EB08_0x42eb08.cpp`, but direct dispatch needed a generated resume label.
- A broad alias strategy that registered every `ctx->pc = 0x...u` was tested and rejected because the runner crashed with exit code `-1073741571`.
- Final fix: patch `sub_0042EB08_0x42eb08.cpp` with targeted `switch (ctx->pc)` cases and labels for `0x42eb48` and `0x42eb90`.
- `09_compile_generated_batch.bat batch_0036 250 syntax 120` passed.
- `09_compile_generated_batch.bat batch_0036 250 object 120` passed.
- `10_link_partial_runner.bat` passed.
- Latest link: `8000` real functions, `7811` missing stubs, `76784` deduplicated aliases.
- `11_run_partial_runner.bat` passed with `Exit code: 0`.
- `0x42eb90` no longer appears in the latest missing-function trace.
- Current first bad PC: `0x407a40`.
- Next trace-driven compile target: `batch_0034`.

## Incremental Compile Strategy

- Do not start with a monolithic build of all generated C++.
- Use `work\batches\ghidra\batch_####.csv` and `.rsp` to work in chunks.
- Default chunk size is `250` functions.
- First compile target is a tiny object/syntax smoke test against `PS2Recomp\ps2xRuntime\include`.
- Record each blocker before broadening the batch size.
- Current verified command shape:

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

- For broadening, increase the limit first (`25`, `50`, `100`, `250`) before moving to all batches.

## Rules

- Do not document a function as known until it is backed by Ghidra, generated C++, or runtime evidence.
- Keep generated outputs under `work\` unless a later build step requires a specific source folder.
- Treat `SLUS_213.55` as build-specific; addresses and labels are not portable to another region/version.
- Prefer small, repeatable `.bat` launchers over one-off manual command history.

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

- `0x548dd0` is resolved by MC3 SIF boot compatibility.
- Runtime now writes `1` to guest address `0x006FE880` when MC3 calls `sceSifSetReg(0x80000001, 0x006FE6D8)`.
- Verified log: `[mc3-sif-compat] command ready flag addr=0x6fe880 value=0x1 subAddr=0x6fe6d8`.
- Current relinked runner: `14000` real functions, `1811` stubs, `147772` aliases.
- Current stable boot PC is `0x54a0ac`, inside `work\generated\ghidra\sub_0054A080_0x54a080.cpp`.
- There is still no render traffic: `dma=0 gif=0 gsw=0 vif=0`.
- New blocker is semaphore based:
  - `sid=9` created at RA `0x549330` by `work\generated\ghidra\sub_005492B8_0x5492b8.cpp`
  - `sid=9` has `init=0 max=1`
  - main thread blocks at `WaitSema`, RA `0x549390`
  - no `SignalSema` for `sid=9` appears in the 12s boot trace.
- The relevant path:
  - `0x549328` -> `CreateSema`
  - `0x549360` -> `sub_00548A00_0x548a00`
  - `0x549388` -> `WaitSema`
  - `0x549390` -> cleanup after wake
- Next target: inspect/instrument `sub_00548A00_0x548a00`, `sub_00548EE8_0x548ee8`, and the event/callback producer for command `0x80000009`; find who should signal `sid=9`.
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

- Current verified probe command: `15_auto_boot_probe.bat 8 callback`.
- This mode is env-gated and enables latch reg4, MC3 IOP queue completion, GS CSR field-bit experiment, and SIF callback signaling.
- Current partial runner timestamp: `2026-07-01 04:50:07`.
- Current status file: `work\boot_probe\latest_status.md`.
- Current trace file: `work\logs\14_run_boot_trace.log`.

Progress proved today:

- Old blockers `0x246740`, `0x246a80`, `0x528fa0`, and `0x234614` are no longer the active end state under the callback probe.
- `PS2Recomp\ps2xRuntime\src\lib\ps2_memory.cpp` now routes GS private-register `read32()` and `read64()` through `readIORegister()`. This matters because `sub_00545648_0x545648` reads GS CSR `0x12001000` via `READ64`.
- `MC3_GS_EXPERIMENT_FIELD_BIT=1` lets the `0x528fa0` loop see the GS CSR field bit and return `$v0=1`.
- `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp` now has env-gated `MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL=1`.
  - The trace showed `cmd=0x8000000a request=0x1 aux=0x6f8f60 sema=0xffffffff callback=0x5407c0`.
  - `0x5407c0` is a callback inside `sub_00540720_0x540720.cpp` that signals the global semaphore stored at `0x0061fb58`.
  - The experiment mirrors that by signaling the sid from `0x0061fb58`.
  - Trace evidence: `[boot-trace:mc3-sif-callback-signal-experiment] callback=0x5407c0 global=0x61fb58 sid=29 signaled=1`.
- `work\generated\ghidra\sub_005407D0_0x5407d0.cpp` had a targeted generated-label gap:
  - trace showed `[dispatch:first-bad-pc] bad=0x540838`;
  - `0x540838` is inside the same function, but the generated switch did not expose that internal jump target;
  - added targeted `case 0x540838` and `label_540838`;
  - recompiled `batch_0053` object mode: `250/250`, `0` failures;
  - fast relink passed, and the latest trace no longer reports `0x540838` as bad PC.

Current state after latest probe:

- Classification: `render-started`.
- Stable PC: `0x245718`.
- Function: `sub_00245680_0x245680`.
- Render counters: `dma=2 gif=0 gsw=0 vif=3`.
- Loop shape:
  - `0x245718` calls `sub_005420C0_0x5420c0`;
  - `0x24572c` calls `FUN_005422c8_0x5422c8`;
  - `0x245734` branches back while `$v0 != 1`.

Next target:

- Instrument or inspect `sub_005420C0_0x5420c0` and `FUN_005422c8_0x5422c8` to discover which state should make the loop return `$v0 == 1`.
- Keep all compatibility changes env-gated until the trace proves they match expected SIF/GS semantics.

## Checkpoint 2026-07-02 Queue Gate At 0x245718

- Recompiled `batch_0053` after targeted instrumentation: `250/250`, `0` failures.
- Fast relink passed; current partial runner timestamp: `2026-07-02 22:26:17`.
- Verified probe command: `15_auto_boot_probe.bat 8 callback`.
- Current status remains `render-started` at stable PC `0x245718`, with counters `dma=2 gif=0 gsw=0 vif=3`.
- Trace now proves the loop reason:
  - `FUN_005422c8_0x5422c8` calls `FUN_00541760_0x541760`;
  - `FUN_00541760_0x541760` sees `fb90=0`, `fb9c=0`, `fbbc=0xffffffff`;
  - it returns `v0=0`, so `FUN_005422c8` takes the fail path and the caller loops.
- Direct writer search found only one writer for global `0x0061FB90`: `FUN_00541be8_0x541be8` at the `0x541de4` store.
- `FUN_00541be8_0x541be8` is invoked twice with `a0=0`; it sets/keeps queue semaphore `fba8=0xf`, returns `v0=2`, but never reaches `write-fb90`.
- Current interpretation: this is an async queue gate, not missing compiled code. The consumer waits for `fb90 > 0`, but the producer only initialized the queue and no emulated IOP/SIF/file completion has enqueued an event yet.
- Next target: inspect the branch path inside `FUN_00541be8_0x541be8` that reaches `write-fb90`, then map the real producer event before adding any env-gated compat.

## Checkpoint 2026-07-04 SIF Queue Experiments At 0x245720

- Verified `03_build_ps2recomp.bat`, `10_link_partial_runner.bat fast`, then `15_auto_boot_probe.bat 8 595`.
- Current status is `render-started` at stable PC `0x245720`, function `sub_00245680_0x245680`, counters `dma=2 gif=0 gsw=0 vif=3`.
- Added env-gated probes:
  - `MC3_SIF_EXPERIMENT_592_PAYLOAD=1` makes `0x80000592` feed `0x620d80+0xC = 0xFE`, proving the path that sets `fb90=1`.
  - `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID=1` matches wrappers that compare `PollSema(...)` with the semaphore id.
  - `MC3_SIF_EXPERIMENT_59C_RESULT=1` writes `1` to `0x621600`, making early `sub_005420C0` returns become `v0=1`.
  - `MC3_SIF_EXPERIMENT_595_COMPLETE=1` marks the request object referenced by `0x620d50` complete for `request=0xE/payload=0x61fc00`.
- Result: the new probes apply and move inner state, but the stable PC still returns to `0x245720`.
- Current blocker: `FUN_005422c8_0x5422c8` still returns `v0=0`; next target is instrumenting its branch after `FUN_00541760(a0=4)` and state globals `fbb4/fbb8/fbd8/fc80`.

## Checkpoint 2026-07-04 PCSX2-MCP Live Trace Integration

- Added PCSX2-MCP/Gemini integration without launching PCSX2 or changing runtime behavior.
- New files:
  - `work\config\pcsx2_mcp.local.json`
  - `PS2_PROJECT_STATE.md`
  - `tools\PCSX2-MCP-Status.ps1`
  - `tools\New-LiveTraceHandoff.ps1`
  - `16_pcsx2_mcp_status.bat`
  - `17_live_trace_handoff.bat`
  - `18_compare_live_trace.bat`
  - `docs\GEMINI_PCSX2_MCP_HANDOFF.md`
  - `work\live_compare\latest_status.md`
- `16_pcsx2_mcp_status.bat` validation:
  - Node OK: `v24.13.0`
  - ISO OK
  - ELF OK
  - partial runner OK
  - PCSX2-MCP and `ps2-recomp-Agent-SKILL` pending until placed in `external`
  - DebugServer/PINE pending until PCSX2-MCP is running
- `17_live_trace_handoff.bat current` validation:
  - generated a Gemini handoff focused on live read-only PCSX2-MCP evidence;
  - generated live compare status with classification `pending-live-trace`.
- `18_compare_live_trace.bat` validation:
  - without a live evidence file, regenerates `work\live_compare\latest_status.md` as `pending-live-trace`;
  - with an evidence file, classifies the live delta into `runtime-stub`, `missing-function`, `bad-return`, `memory-init`, `render-traffic`, or `unknown`.
- Next live target: prove on real PCSX2 what state makes `FUN_005422c8_0x5422c8` return `1`, then mirror only the minimal proven runtime behavior in env-gated recomp experiments.

## Checkpoint 2026-07-05 PCSX2-MCP Installed In Codex

- PCSX2-MCP release path:
  - `external\PCSX2-MCP\PCSX2-MCP-v1.0.0-win64\PCSX2-MCP-v1.0.0-win64`
- `work\config\pcsx2_mcp.local.json` now points at that nested release root.
- Codex MCP server `pcsx2` is registered and enabled with `PS2RECOMP_ROOT` pointing to this workspace's `PS2Recomp`.
- Direct MCP stdio smoke passed:
  - `initialize` OK
  - tool list OK
  - `pcsx2_connect` callable
  - server reports correct PS2Recomp root.
- PCSX2-MCP `pcsx2-qt.exe` process is running from the correct path, but emulator TCP access is not open yet:
  - `127.0.0.1:21512` closed
  - `127.0.0.1:28011` closed
- Host PCSX2 config was adjusted:
  - `EnablePINE = true`
  - `PINESlot = 28011`
  - backup created beside `<user-home>\Documents\PCSX2\inis\PCSX2.ini`
- Next action: restart PCSX2-MCP, load MC3, rerun `16_pcsx2_mcp_status.bat`, then open a new Codex session so the `pcsx2_*` MCP tools are loaded into the active tool list.

## Checkpoint 2026-07-05 PCSX2-MCP Live Connection Confirmed

- User opened the bundled PCSX2-MCP and loaded MC3 to the title screen.
- `16_pcsx2_mcp_status.bat` confirms:
  - DebugServer `127.0.0.1:21512` OK
  - Pine `127.0.0.1:28011` OK
  - `pcsx2-qt` process OK
- Direct MCP stdio smoke confirms `pcsx2_connect` can connect to DebugServer.
- Caveat: Pine listens but the MCP server reported Pine response timeout; use DebugServer first.
- Caveat: advanced tools should be called after connect/pause/status sequencing in a fresh Codex session; direct harness saw an internal disassembly error while the game was running.
