# Experimental depth rendering - 2026-09-13

## Outcome: no visual improvement accepted

White bands remain with depth enabled. The final scene is darker, with much of
the previously visible background absent. Keep the feature OFF by default.
This experiment confirms a working depth path in controlled fixtures, but does
not establish a visually correct GS pipeline for the game.

Added default-OFF `MC3_GS_DEPTH_TEST`. The previous passive experiment proved
that requested depth behavior was missing. This implementation now supplies
fragment Z for point, line, triangle and sprite (including strips/fans), tests
NEVER/ALWAYS/GEQUAL/GREATER, and writes Z unless masked. ZTE=0 retains the old
color path without writing Z. AFAIL selects color and Z writes independently.

Z32/Z24/Z16/Z16S addressing and sized writes preserve unused Z24 bytes; 16-bit
neighbor pixels remain independently addressed. Triangle Z uses a double plane,
line Z is interpolated, sprite Z uses its second vertex. Class layout unchanged.

## Reference and conversion

The primary [PCSX2 software renderer](https://raw.githubusercontent.com/PCSX2/pcsx2/master/pcsx2/GS/Renderers/SW/GSRendererSW.cpp)
clamps sprite Z at conversion and selects clamping when primitive Z exceeds the
format maximum. It also masks Z writes when ZTE is disabled.
The [scanline implementation](https://raw.githubusercontent.com/PCSX2/pcsx2/master/pcsx2/GS/Renderers/SW/GSDrawScanline.cpp)
clamps interpolated Z before comparing, and handles AFAIL color/depth masks
separately. Our small scalar implementation uses these behaviors as reference;
it does not import external renderer code or add a dependency.

## Tests and reproducibility

Baseline artifact `<scratch-dir>/mc3-depth-contract-20260913-v2` links
immutable pre-depth library SHA256
`0586269c90ffd11f50bf58e1f0a98fa9ae36c64f6b30de328faf6b51a1b55bf5`.
340 desired-behavior cases:96pass244fail. These are expected baseline failures,
not a successful depth implementation. New runtime OFF reproduces that output.

Authoritative passing run: `<scratch-dir>/mc3-depth-render-20260913/tests_v3`.

- 340/340 depth cases ON: both overlap orders, all seven primitive types,
  four depth formats, comparison modes/equality, ZMSK, AFAIL, FBMSK and varying Z.
- 43/43 limits: saturation, equality at limit, nonfinite conversion rejection,
  and distinct Z16/Z16S physical addresses.
- 331/331 full suite OFF and ON;44/44 ADC cases both modes.
- Copy fixture checks100128pixels and source preservation, identical OFF/ON.

Early fixture v1 incorrectly used the Z16S address for Z16 and treated the next
Z16 pixel as an unused guard byte for broad geometry. Fixed in v2, recompiled
against the immutable baseline; older failed development logs are preserved.
Initial triangle interpolation rounded expected166 down to165 via float
barycentric weights; the independent double depth plane fixed that case.

Copy fixtures previously set TEST.ZTE but omitted ZBUF, so enabling real depth
writes legitimately overwrote source memory. They now explicitly mask writes
with ZBUF0x1320000b0, observed in prior real copy logs. Assertions were retained.
Two affected full-suite presentation tests received the same explicit state.

## Limits

This is not complete GS parity. GSVertex.z still stores float; exact32-bit
vertex precision is not restored. Existing destination-alpha testing and other
unimplemented pixel pipeline behavior are not added by this change. Addresses
outside allocated VRAM are rejected, following the current renderer boundary.
The passive observer still reports an estimated Z/masked candidate; overflow
comparisons are excluded from usable inference, and are not a replay of this
new saturating depth pipeline. Its mask-based passAgainstCurrent must not be
read as an actual fragment rejection in this experiment.

## Real run

Headless `depth_render_20260913_a`, PID53464, started06:29:09, hardlimit900s.
Same bridge/STQ/Start30s-hold30s-delay45s, source watch FBP64/CT24 threshold2M,
copy/source/present/depth diagnostics. Only depth rendering is newly enabled.
Artifact root `<scratch-dir>/mc3-depth-render-20260913`.

Exe SHA256 `a3bf2785a35d92601ab0b4997007efe480845b897f97ab3c6ef68f3cf2cf9271`.
Library SHA256 `d0b4582aef59d553c69e8249f97f140646ba1ca1d38e45fb89699a3633b49294`.

Deliberately stopped06:40:25 after thirdcapture, PID/path/start verified in
stop.json. Harness ended06:40:30,wall681.2412958s,CPU662.125s,exit-1intentional;
no runner remains. PNG3:660.024s,prim4192788. Previous PNG3 wasprim4984963,
so the two presented images are not a frame-exact A/B or an FPS benchmark.

Five source-owner states/15 depth samples, zero rejected records. All use
Z16S/ZBP176 and GEQUAL. Three permit depth writes. Raw stored depth isffff in
all samples, compared with0 in the preceding passive run. All estimates exceed
16-bit range; the actual path saturates toffff and passes equality. The old
observer reports masked candidates belowffff, hence passAgainstCurrent=0:
those are hypothetical masked comparisons, NOT actual rejection by the new code.

Observed remaining producer primitives:2224978,2225038,2225041,2225467,2225685.
The previous low-Z owner2225044 is absent, but the observer only records color
changes, so absence alone is not proof of a particular rejection.

One copy snapshot atprim2227445; match it to previous source capture2, not
previous source capture1(which wasprim2175494). The correctly paired JSON is
`run/source_prim2227445_visual.json`. Both regions have32768nearwhite pixels
outof32768. The preliminary `source1_visual.json` pairs different primitives
and must not be used for a causal A/B. This diagnostic region stays white.

Presented nearwhite counts13074before/13062after are not a quality score; both
images retain broad white rows, and scene phases differ.24ADC records remain
bounded, zero rejected. Detailed analysis: `run/depth_analysis_final.json`,
`run/adc_analysis_final.json`, `run/present3_visual.json`.

Latest capture:
`<scratch-dir>/mc3-depth-render-20260913/run/captures/present_depth_render_20260913_a_3.png`

## Next investigation

Find the first writer setting watched Z16S address1544328 toffff, starting
before2Mprimitives. Distinguish a depth clear, triangle/sprite depth write and
transfer/alias before attributing it to VU clipping. Then inspect that producer's
XYZ/clip history; do not introduce a negative-Q filter or discard high-Z
triangles merely because this experiment made the scene darker.

## Rollback

Unset MC3_GS_DEPTH_TEST to retain previous rendering. Original E executable and
previous immutable C executables/libraries remain untouched. Changed source
baselines are preserved under the artifact root. No saves/assets were edited.
