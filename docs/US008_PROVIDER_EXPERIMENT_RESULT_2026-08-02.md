# US-008 provider-init experiment result

Timestamp: `2026-08-02 00:47 BRT` (`America/Sao_Paulo`)

## Result

Rejected. The experiment was implemented only behind
`MC3_EXPERIMENT_PROVIDER_INIT_RESPONSE=1`, compiled into the runtime library,
archived, and tested. It wrote the observed response word:

```text
request=0xff payload=0x700dc0 size=0x8 value=0x1
```

The ordinary gated probe remained `render-started` at Stable PC `0x5a8908`
with `dma=2 gif=0 gsw=0 vif=3`. The provider trace probe reached only
`0x3991f0`; it did not reach `0x4faa10`, `0x4f9a68`, or `0x4f9760`, and no
`0x619f40=1` publication was observed.

The trace probe classified as `semaphore` at `0x39923c`, which is a timing/
instrumentation observation, not graphics acceptance.

## Rollback

The experiment branch and its environment helper were removed from
`PS2Recomp/ps2xRuntime/src/lib/Kernel/Stubs/SIF.cpp`. The runtime object and
`libps2_runtime.a` were rebuilt, and `mc3_partial.exe` was relinked at
`2026-08-02 00:46 BRT`.

No provider pointer, fake handle, semaphore injection, FMV skip, asset, or ISO
was changed. The hypothesis is rejected and must not be retained as a fix.

Evidence:

- `work/boot_probe/boot_trace_pollsid59c595_20260802_004050.log` — gated probe
  before provider trace.
- `work/boot_probe/boot_trace_pollsid59c595_20260802_004436.log` — gated
  provider trace and rejection evidence.
- `work/logs/provider_experiment_baseline.out.log` — baseline comparison.
- `work/logs/build_ps2_runtime_provider_experiment.log` — build attempt and
  the subsequent direct MSYS2 compile path.
- `work/logs/provider_experiment_rollback_baseline2.out.log` — post-rollback
  confirmation: `render-started`, Stable PC `0x5a8908`.

The first post-rollback 8-second probe briefly classified as
`missing-function` at `0x246758`; the immediate repeat returned to the normal
`render-started`/`0x5a8908` baseline, so it is recorded as runner
nondeterminism rather than an experiment regression.

Next investigation: capture the original response contents or the provider
node population path from a real PCSX2 session; do not promote another guessed
response value.
