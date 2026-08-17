# Gemini Handoff: MC3 Boot Probe After Early Render Traffic

Mode: read-only investigation. Do not edit files.

Workspace:

`D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp`

## Current Facts

- Goal now is to advance from early render traffic toward visible menu/render.
- Current probe command: `15_auto_boot_probe.bat 8 595`.
- Current status file: `work\boot_probe\latest_status.md`.
- Current trace log: `work\logs\14_run_boot_trace.log`.
- Current partial runner: `work\link\partial\mc3_partial.exe`.
- Current runner timestamp: `2026-07-04 17:18:58`.
- Current classification: `render-started`.
- Current stable PC: `0x245720`.
- Current function: `sub_00245680_0x245680`.
- Current counters: `dma=2 gif=0 gsw=0 vif=3`.

## What Is Already Proven

- The old `0x246740` SIF reg4 blocker is not the current end state under the env-gated probe.
- The old `0x528fa0` GS CSR loop was passed after routing GS private-register `read64()` through `readIORegister()` and enabling `MC3_GS_EXPERIMENT_FIELD_BIT=1`.
- The old `0x234614` blocker was a callback-style SIF completion:
  - packet: `cmd=0x8000000a request=0x1 aux=0x6f8f60 sema=0xffffffff callback=0x5407c0`;
  - callback `0x5407c0` signals the global semaphore stored at `0x0061fb58`;
  - env-gated `MC3_SIF_EXPERIMENT_CALLBACK_SIGNAL=1` now mirrors that;
  - trace evidence includes `[boot-trace:mc3-sif-callback-signal-experiment] callback=0x5407c0 global=0x61fb58 sid=29 signaled=1`.
- The generated dispatch hole at `0x540838` was fixed:
  - `0x540838` is inside `sub_005407D0_0x5407d0.cpp`;
  - targeted `case 0x540838` and `label_540838` were added;
  - `batch_0053` recompilation passed `250/250`;
  - latest trace no longer reports `first-bad-pc 0x540838`.

## Current Loop Shape

In `work\generated\ghidra\sub_00245680_0x245680.cpp`:

- `0x245718` calls `sub_005420C0_0x5420c0`.
- `0x24572c` calls `FUN_005422c8_0x5422c8`.
- `0x245734` branches back to `0x245718` while `$v0 != 1`.

This means the next useful question is not "what batch is missing?", but what state makes `FUN_005422c8_0x5422c8` return `1`.

## Latest Codex Evidence

- `batch_0053` was recompiled after instrumentation: `250/250`, `0` failures.
- `FUN_005422c8_0x5422c8` calls `FUN_00541760_0x541760` with `a0=2` and `a0=4`.
- `FUN_00541760_0x541760` repeatedly sees `fb90=0`, `fb9c=0`, `fbbc=0xffffffff`, returns `v0=0`, and makes `FUN_005422c8` fail.
- Direct writer search found only one writer to `0x0061FB90`: `FUN_00541be8_0x541be8`, store at `0x541de4`.
- Latest trace shows `FUN_00541be8_0x541be8` is called twice with `a0=0`, returns `v0=2`, and does not hit `write-fb90`.
- Current hypothesis: this is an async queue/event gate. The queue is initialized, but no emulated IOP/SIF/file completion is producing an entry into `fb90`.

## 2026-07-04 Update

Codex added and verified these env-gated probes:

- `MC3_SIF_EXPERIMENT_592_PAYLOAD=1`
  - handles `request=0x0 payload=0x620d80 size=0x10`;
  - writes `0xFE` at `0x620d80+0xC`;
  - trace proves this reaches `FUN_00541be8:write-fb90` and sets `fb90=1`.
- `MC3_SEMA_EXPERIMENT_POLL_RETURNS_SID=1`
  - successful `PollSema` returns the semaphore id instead of `0`;
  - trace proves wrappers compare `PollSema(...) == semaId`.
- `MC3_SIF_EXPERIMENT_59C_RESULT=1`
  - handles `request=0x0 payload=0x621600 size=0x4`;
  - writes `1`;
  - early `sub_005420C0` returns become `v0=1`.
- `MC3_SIF_EXPERIMENT_595_COMPLETE=1`
  - handles `request=0xE payload=0x61fc00 size=0x4`;
  - marks `(*(0x620d50) + 0x10) |= 1`;
  - trace shows `kind=request-595-complete`.

Even with all of these enabled through `15_auto_boot_probe.bat 8 595`, the stable PC remains `0x245720`. The next blocker is now more specific: `sub_005420C0` can return `1`, but `FUN_005422c8_0x5422c8` still returns `0` and keeps the outer loop alive.

## Files To Read First

- `work\boot_probe\latest_status.md`
- `work\logs\14_run_boot_trace.log`
- `work\generated\ghidra\sub_00245680_0x245680.cpp`
- `work\generated\ghidra\sub_005420C0_0x5420c0.cpp`
- `work\generated\ghidra\FUN_005422c8_0x5422c8.cpp`
- `work\generated\ghidra\FUN_00541760_0x541760.cpp`
- `work\generated\ghidra\FUN_00541968_0x541968.cpp`
- `work\generated\ghidra\sub_00549680_0x549680.cpp`
- `work\generated\ghidra\FUN_00541be8_0x541be8.cpp`
- `work\generated\ghidra\FUN_00541ec8_0x541ec8.cpp`
- `PS2Recomp\ps2xRuntime\src\lib\Kernel\Stubs\SIF.cpp`
- `PS2Recomp\ps2xRuntime\src\lib\ps2_memory.cpp`

## Question

Determine why `FUN_005422c8_0x5422c8` still returns `0` after `sub_005420C0` can return `1`.

Focus on:

- the branch after `FUN_00541760(a0=4)` inside `FUN_005422c8_0x5422c8`;
- globals `fbb4`, `fbb8`, `fbd8`, `fc80`, `fb9c`, `fbbc`;
- why `FUN_00541760(a0=4)` still returns `0` under the `595` probe;
- the next single env-gated experiment or targeted instrumentation point.

## Output Contract

Return only:

- hypothesis,
- exact evidence paths/lines,
- next minimal experiment,
- expected trace change if correct.

Do not edit files. Do not suggest broad rewrites.
