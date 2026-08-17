# US-008 - Minimal provider compatibility experiment

## Selection

Rank 1 is one response-value experiment for the already observed SIF request
`request=0xFF`, `payload=0x700DC0`, `size=8`. No runtime change is implemented
by this story.

### Hypothesis and expected value

The native runner leaves the `0xFF -> 0x700DC0` response unmodelled. The
minimal next experiment is to change only the first 32-bit response word at
`0x700DC0` from its current zero/default value to `1` when request `0xFF`
completes. Hypothesis: value `1` is the missing success/ready response that
allows the existing provider setup path
`FUN_00447928 -> FUN_003c8cf8 -> FUN_004faa10` to run.

The positive result is not merely a later Stable PC. It requires the existing
trace to show entry into `FUN_004faa10_0x4faa10.cpp`, publication of
`0x619F40=1`, and eventual selection of
`0x618020 -> 0x619F58 -> 0x4F9760`. If those observations do not occur, the
hypothesis is rejected and the value is not retained.

This value is deliberately an experiment, not a claimed PCSX2 fact: the live
PCSX2 contents for this response have not been captured. The experiment is
ranked first because it changes one response word on one observed request,
whereas the existing `req4` mode changes several unrelated behaviours and
still leaves `0x619F40=0`.

### Exact implementation target for the next story

- Gate: `MC3_EXPERIMENT_PROVIDER_INIT_RESPONSE=1`.
- Request interception: the SIF response handling for the envelope created by
  `work/generated/ghidra/sub_00549488_0x549488.cpp`, limited to
  `request == 0xFF`, `payload == 0x700DC0`, and `size == 8`.
- Single changed value: `WRITE32(0x700DC0, 1)` in the response-completion path.
- Observation points (unchanged):
  `work/generated/ghidra/FUN_00447928_0x447928.cpp`,
  `work/generated/ghidra/FUN_003c8cf8_0x3c8cf8.cpp`, and
  `work/generated/ghidra/FUN_004faa10_0x4faa10.cpp`.

The next implementation story must first locate the existing response switch
in the runtime and place the condition there; it must not edit the original
guest request construction merely to manufacture the response.

### Rollback and default behaviour

Rollback is removing or unsetting `MC3_EXPERIMENT_PROVIDER_INIT_RESPONSE`.
With the gate absent, the response word and all request handling must remain
byte-for-byte behaviourally unchanged. If the hypothesis fails, remove the
gated branch and rebuild the edited object; no guest global or asset needs
restoration.

## Rejected alternatives

- Do not write a pointer directly to `0x619F44`/`0x629F44` and do not return a
  fake file handle. Either would hide whether provider population really ran.
- Do not inject `SignalSema(17)`, `SignalSema(46)`, or any other semaphore.
  The captured evidence does not identify a missing signal as the provider
  initializer.
- Do not promote `req4`: it combines multiple experiments and did not publish
  `0x619F40` or reach `0x4F9760` in the controlled matrix.
- Do not install the diagnostic `0x711D40 -> 0x3988F8` callback override as a
  fix; its earlier probe did not produce GIF/GS rendering.
- Do not use replace-all or a permanent compatibility patch.

## Static verification

```powershell
rg -n "request=0xFF payload=0x700DC0 size=8|0x711D40|4FAA10" docs/SESSION_2026-08-01_BATCH_CONTINUATION.md
rg -n "req4|0x619F40=0|0x4F9760" docs/PROVIDER_TRACE_MATRIX.md
rg -n "0x618020|0x619F58|0x4F9760|0x629F44" docs/PCSX2_PROVIDER_SNAPSHOT_COMPARISON.md
rg -n "MC3_EXPERIMENT_PROVIDER_INIT_RESPONSE|WRITE32\(0x700DC0, 1\)|fake file handle|SignalSema|replace-all" docs/US008_MINIMAL_PROVIDER_COMPAT_EXPERIMENT.md
```

Compilation, relink, and boot probes are not applicable to US-008 because it
adds selection documentation only and intentionally changes no code.
