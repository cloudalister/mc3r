# Gemini Handoff - MC3 Recomp Resume - 2026-06-17

## Role

You are a read-only analysis agent helping resume the Midnight Club 3 PS2 recomp project.

Do not edit files. Do not run long compiles. Do not delete or move anything. Your job is to inspect current evidence, identify the next high-value steps, and return a concise report for Codex/user.

## Workspace

Root:

```text
D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp
```

Important files:

```text
BRAIN.md
docs\BRAIN.md
docs\PIPELINE.md
docs\TRACE_DRIVEN_STATUS.md
work\trace_driven\latest_status.md
work\logs\11_run_partial_runner.log
work\logs\12_trace_driven_compile_20260611_092429.log
work\index\functions_index.csv
work\link\partial\register_functions.partial.manifest.csv
work\link\partial\register_functions.partial.aliases.csv
work\link\partial\missing_functions.partial.manifest.csv
```

## Known Current State

As of the last verified trace-driven status:

- `32` object batches compiled.
- `8000` real generated functions registered in `work\link\partial\mc3_partial.exe`.
- `7811` missing-function stubs remain.
- `636042` internal PC aliases registered.
- Latest trace-driven status was updated on `2026-06-11 09:38:34 -03:00`.
- Latest visible next trace targets:
  - `batch_0034` -> `0x00407a40`
  - `batch_0033` -> `0x00401c30`
  - `batch_0032` -> `0x003f1b58`
  - `batch_0031` -> `0x003d1090`
  - `batch_0030` -> `0x003c8720`
  - then `batch_0026`, `batch_0025`, `batch_0024`, `batch_0021`, `batch_0020`

Resolved nuance:

- The current first bad PC in `work\logs\11_run_partial_runner.log` is `0x42eb90`.
- A direct search in `work\index\functions_index.csv` does not show `0x42eb90` as a function start.
- Confirmed local evidence: `0x42eb90` exists inside `work\generated\ghidra\sub_0042EB08_0x42eb08.cpp`.
- Important mismatch: `work\exports\SLUS_213.55.ghidra.csv` and `work\batches\ghidra\batch_0036.csv` list `FUN_0042eb08` as `0x0042EB08..0x0042EB48`, but the generated C++ comment says `Address: 0x42eb08 - 0x42ebd8` and includes instructions through `0x42ebd4`.
- Broad aliasing of every `ctx->pc = 0x...u` was tested and rejected because it crashed the runner; arbitrary internal PCs need matching generated labels.
- A targeted patch was applied to `sub_0042EB08_0x42eb08.cpp` to add resume labels/switch cases for `0x42eb48` and `0x42eb90`.
- `batch_0036` was recompiled, relink passed, and smoke passed.
- `0x42eb90` no longer appears as missing.
- The next indexed external bad PC from the log/status is `0x407a40`, in `batch_0034`.

## What To Inspect

1. Confirm exact compiled batch set from `work\compile\ghidra\batch_*\*.object.summary.csv`.
2. Inspect whether more generated functions have Ghidra CSV range mismatches like `sub_0042EB08`.
   - Do not propose broad `ctx->pc` aliasing unless the generated function has matching labels.
   - Prefer targeted resume-label patches or generator improvements that add labels before aliasing.
3. Inspect `tools\Trace-DrivenCompile.ps1`:
   - Does it correctly handle bad PCs that are internal labels?
   - Does it skip duplicated batches correctly?
   - Should it consult `register_functions.partial.aliases.csv` before `functions_index.csv`?
4. Decide whether the next Codex action should be:
   - Compile `batch_0034` with current script, or
   - Design a safer generator-level fix for internal resume labels, or
   - Integrate a PCSX2-MCP/live emulator trace plan before compiling more.
5. Check whether `BRAIN.md` and `docs\BRAIN.md` are stale versus `docs\TRACE_DRIVEN_STATUS.md`.

## Output Format

Return:

1. Current factual state in 5-8 bullets.
2. Diagnosis of `0x42eb90`.
3. Recommended next 3 actions for Codex.
4. Any risk/blocker.
5. Exact commands Codex should run next, if applicable.

Do not make code changes.
