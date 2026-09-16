# Depth probe - 2026-09-13

## Current outcome

No clear visible improvement yet. The previous ADC queue correction is retained;
white bands and deformed geometry still require correction. This change only
observes depth state of source triangles; it does not change rendering.

## Verified implementation

- Default OFF `MC3_DEPTH_PROBE`, bounded to surface-owner events. Samples at
  (256,84), (256,85), (256,86) before and after a whole draw; no per-pixel hooks.
- Records ZBUF, TEST, ALPHA, FBMASK, estimated interpolated Z, raw stored Z,
  format validity and comparison result against the current raw value.
- Supports Z32/Z24/Z16/Z16S reads. Z32/Z24 page addressing applies block XOR
  0x18 (byte XOR 0x1800), consistent with the primary
  [PCSX2 GS local memory reference](https://raw.githubusercontent.com/PCSX2/pcsx2/master/pcsx2/GS/GSLocalMemory.h).
  No external renderer or code dependency was imported.
- No GS object layout change and no depth test/write added to the rasterizer.

## Tests

Artifacts: `<scratch-dir>/mc3-depth-20260913/tests`.
`PASS_depth.json` completed 05:30:21: 331/331 suite OFF and ON, 44 ADC cases,
copy fixture unchanged; fixture outputs identical with diagnostics OFF/ON.
Analyzer regression passed independently.

Synthetic triangle Z=100 over stored Z=200, with GEQUAL requested, still writes
color and leaves depth unchanged. All three observed comparisons reject it.
This confirms missing depth behavior in the current rasterizer, not a new fix.

## Real run (closed)

`depth_source_20260913_a`, headless, started05:32:35, PID55264, hardlimit900s.
Same bridge/STQ/Start settings as preceding ADC run; source watch FBP64/CT24,
threshold2M primitives. Logs/captures under artifact root `run`.

Deliberately stopped05:43:50 after third presented capture, with PID/path/start
verified and recorded in `.stop.json`. Harness ended05:43:52, wall676.8217038s,
CPU624.875s, exit-1 (intentional stop). No runner remains active.

`depth_analysis_final.json`: 9 states, 27 samples, zero rejected records. All
nine request GEQUAL and use Z16S/ZBP176. Five permit depth writes (ZMSK=0).
Stored Z stays zero before/after in all27 samples. Addresses at y84/85/86 are
1544320/1544328/1544384. No usable estimated rejection against current raw zero.
18 estimates exceed the 16-bit storage range and are excluded from that count.

At prim2225038, estimated Z at (256,85) is5985958.6743, beyond16-bit range;
at prim2225044 it is4680.3521, in range. Both see stored zero. These observations
cannot determine the result with correct prior depth history and hardware
conversion. Do not introduce a Q-sign filter or infer that high Z is invalid
geometry from this diagnostic alone.

`adc_analysis_final.json`:24 ADC records, zero rejected, queues bounded,
highest observed suppressed4194304;9 source writers and2 copy captures.
Presented PNG3 at660.028s/prim4984963 was inspected: white bands and deformed
scene persist. This is not visible acceptance or an FPS comparison.

Latest image:
`<scratch-dir>/mc3-depth-20260913/run/captures/present_depth_source_20260913_a_3.png`

Executable SHA256:
`0c6585b3726798ec2be9e2f73c5a5bf1e19f9ab256c0efc8dab0f4aa26fb9b2d`

Runtime library SHA256:
`0586269c90ffd11f50bf58e1f0a98fa9ae36c64f6b30de328faf6b51a1b55bf5`

## Interpretation limits

Existing vertices already store Z as float. Interpolation is an estimate; values
outside the format range are flagged and excluded from usable-rejection counts.
Hardware clamp/wrap behavior has not been established by this experiment.
Because earlier rasterization never writes Z, current raw VRAM does not contain
the depth history a complete renderer would have produced. Passing against
current zero cannot prove a triangle would pass with correct depth rendering.
This probe alone cannot establish that missing depth causes the white bands.

## Reversibility

Original E executable and immutable prior ADC executable/library preserved.
Pre-change snapshots in `baseline/verified.csv`. Disable MC3_DEPTH_PROBE to
disable this observer; retain the separately verified ADC queue correction.

## Next discriminating change

Depth is absent from the `writePixel` interface itself: callers supply XY/RGBA
but no fragment Z. A complete correction needs point/line/triangle/sprite Z,
format-correct reads and writes, TEST modes and ZMSK, and alpha-test AFAIL
interaction (including depth-only writes). Merely adding a comparison against
current VRAM would not restore the missing history and is not a sufficient fix.
Start with an overlapping-primitive fixture that fails on the current renderer,
including both draw orders, masked Z and alpha failure, before a real-scene run.
