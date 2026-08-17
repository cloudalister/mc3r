# US-005 - Instrumented runner checkpoint

Verified: 2026-08-02 00:04 BRT

## Intent

Prove that the US-004 provider telemetry is present in a freshly linked partial
runner, produces reproducible live output only when `MC3_TRACE_PROVIDER=1`, and
does not let stale build evidence pass validation.

## Build evidence

Only the four affected objects were rebuilt:

- `batch_0027`: `sub_003991F0_0x3991f0.o`
- `batch_0049`: `FUN_004f9760_0x4f9760.o`,
  `sub_004F9A68_0x4f9a68.o`, and `sub_004FAED8_0x4faed8.o`

`10_link_partial_runner.bat fast` passed. The final
`work/link/partial/mc3_partial.exe` timestamp is `2026-08-02 00:03:38 BRT`.

## Probe evidence

Command: `$env:MC3_TRACE_PROVIDER='1'; .\15_auto_boot_probe.bat 8 595`

Trace: `work/boot_probe/boot_trace_pollsid59c595_20260802_000403.log`

| Field | Observed value |
|---|---|
| Classification | `render-started` |
| Stable PC | `0x5a8908` |
| Render counters | `dma=2 gif=0 gsw=0 vif=3` |
| Backend slot 0 | `0x00617f88` |
| Backend slot 1 | `0x00617f88` |
| `0x3991F0` first return | `0x00000001` |
| `0x3991F0` later return | `0x00000000` |
| Fallback before `0x4F9A68` | `0x00000000` |
| Fallback after `0x4F9A68` | `0x00715d90` |
| Provider flag `0x619F40` | `0x00` (existing adjacent provider trace) |
| Primary `0x619F44` | not reached by the 8/595 path; no value claimed |
| Last wait | `tid=3 sid=5 count=0 waiters=0 pc=0x5469e0 ra=0x398b28` |

The required provider lines were captured at live points `0x3991F0` and
`0x4F9A68`. The path did not reach `0x4FAED8` or `0x4F9760`, so this checkpoint
does not infer their live values.

## Negative and regression evidence

- A timestamp-only stale-EXE simulation made `Verify-BootState.ps1` report
  `[FAIL] exe-not-stale` and exit `1`; the original timestamp was restored.
  Evidence: `work/logs/US005_stale_executable_negative.log`.
- A final `15_auto_boot_probe.bat 8 595` with `MC3_TRACE_PROVIDER` absent wrote
  `work/boot_probe/boot_trace_pollsid59c595_20260802_000412.log`, contained zero
  `[MC3_PROVIDER]` lines, and retained Stable PC `0x5a8908`.
- Final `Verify-BootState.ps1 -ExpectedStablePC 0x5a8908` passed freshness,
  executable, zero-missing-stub, classification, and Stable-PC checks.

No provider global, handle, semaphore, guest branch, or compatibility behavior
was changed during US-005.
