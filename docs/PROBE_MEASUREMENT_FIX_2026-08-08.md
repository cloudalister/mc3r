# MC3 Probe Measurement Fix - 2026-08-08

## Scope

This A3 slice makes the measurement and its verifier honest. It does not make the
boot deterministic and does not modify runtime C++, generated code, executables,
providers, FMV logic, or wrappers.

## Classification contract

1. A stable PC that does not resolve to a known generated/runtime function is
   `invalid-pc`, before any counter can be considered.
2. `render-started` requires `gif > 0` or `gsw > 0`.
3. DMA/VIF-only activity is `counters-moved`, not visual render.
4. Missing-function evidence wins over DMA/VIF-only activity, so the dispatch
   blocker remains visible.

`Verify-BootState.ps1` now makes lack of GIF/GSW traffic a failing check. A status
with `counters-moved`, `invalid-pc`, or zero GIF and GSW cannot produce RESULT: PASS.
`Probe-Repeat.ps1` counts true render only when classification is `render-started`
and GIF or GSW moved. It flags either contradiction direction as an inconsistency
(exit 3): `render-started` without GIF/GSW, or GIF/GSW with any other classification.

## Actual validation evidence

All commands below ran from `<old-project-root>` without launching the
runner or PCSX2.

```powershell
powershell -NoProfile -Command "[void][scriptblock]::Create((Get-Content -Raw 'tools\Boot-Probe.ps1')); [void][scriptblock]::Create((Get-Content -Raw 'tools\Verify-BootState.ps1')); [void][scriptblock]::Create((Get-Content -Raw 'tools\Probe-Repeat.ps1')); [void][scriptblock]::Create((Get-Content -Raw 'tools\tests\Test-ProbeMeasurement.ps1')); Write-Output 'PARSE: all four scripts have zero parser errors'"
```

Output: `PARSE: all four scripts have zero parser errors`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\tests\Test-ProbeMeasurement.ps1
```

Output:

```text
PASS: invalid-pc, counters-moved, gif/gsw render, and missing-function precedence verified.
PASS: Verify-BootState rejects non-render synthetic statuses; true-render status passes its status checks.
PASS: Probe-Repeat rejects both classification/counter contradiction directions without running the runner.
```

The test uses temporary synthetic traces and temporary status files. It invokes
`Verify-BootState.ps1` through its existing `-StatusPath` parameter, asserts a
nonzero exit for invalid-pc and counters-moved, and checks the true-render status
checks separately because unrelated executable/manifest preconditions are outside
this measurement slice. It does not run the runner or PCSX2 and does not write
`latest_status.md`.

The synthetic cases prove:

- `0x3` plus VIF-only activity is `invalid-pc` and verifier failure.
- Registered PC `0x1a0008` plus DMA/VIF-only activity is `counters-moved` and verifier failure.
- GIF or GSW activity is `render-started` and passes the verifier's two status checks.
- Missing-function evidence with DMA/VIF-only counters remains `missing-function`.
- Invalid PC plus missing-function evidence remains `invalid-pc` and retains the
  missing evidence in its detail.
- `invalid-pc` plus GIF/GSW and `render-started` without GIF/GSW both fail repeat
  aggregation, and neither increments the true-render count.

The correction adds `-AnalyzeStatusPath` and `-NoWriteReport` to Probe-Repeat only
as a synthetic-analysis seam. Existing wrapper parameter names and default live
behavior are unchanged; the test uses this seam with temporary status files and
never invokes `15_auto_boot_probe.bat`.

A read-only analysis of the existing trace also returned:

```text
Classification: missing-function
Stable PC: 0x5a8908
Function: sub_005A8898_0x5a8898
```

This confirms that the current trace is not promoted to visual success by this
change.

## File evidence

Repository Git metadata could not provide a diff: `git -C <old-project-root>
status --short` returned `fatal: not a git repository (or any of the parent
directories): .git`. The inspected owned-file SHA256 values after validation were:

```text
Boot-Probe.ps1                     38E28E9427F12A86561299F84CD61676785198E2EFDF797BA8F8DCE1A1924E4D
Verify-BootState.ps1               8FB5A8C49ABE31A02C97782E14C8E0B975FED18C30C5AAB7927F79728381E78B
Probe-Repeat.ps1                   BA35AAD0479DE11EB620AC4F85BE1C8558610D83703B04A91E751927F1705440
Test-ProbeMeasurement.ps1          FE4F37B5B2B6151204E206D0124893B3D6AF78AB8E62661F52186702D9188862
```

This report's final SHA256 is recorded by the handoff command because embedding its
own hash here would change it. Only the four scripts above and this owned report
were edited by this slice.

## Still open

This does not satisfy A1 or A2. The source of nondeterminism, deterministic or
reproducible probe mode, and the required N=10 acceptance evidence remain open.
No visual render is claimed by this change.
