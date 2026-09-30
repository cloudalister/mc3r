# Open problems

Three open problems, with the evidence gathered so far. Each block can be
copied into a GitHub
issue body as-is.

---

## Issue 1: Menu quad renders cut diagonally in half (GS software rasterizer)

**Labels suggestion:** `bug`, `rendering`, `needs-repro`

### Summary

The panel behind the title screen renders with roughly half a quad missing,
cut along the diagonal, both in the live window and in probe-captured PNGs
(with somewhat different symptoms between the two — see below).

### What's been ruled out (by code reading, `PS2Recomp/ps2xRuntime/src/lib`)

- **Vertex kick / XYZ2 vs XYZ3 confusion**: traced all four paths that can
  trigger a draw (`ps2_gs_gpu.cpp`, direct register writes to
  `GS_REG_XYZ2`/`GS_REG_XYZ3`/`GS_REG_XYZF2`/`GS_REG_XYZF3`, and packed-GIF
  formats `0x04/0x05/0x0C/0x0D`). All four correctly gate the draw call on
  XYZ2 (or the ADC bit for XYZF2/XYZ2 packed), never on XYZ3. No bug found
  here.
- **Backface culling / winding**: `GSRasterizer::drawTriangle`
  (`ps2_gs_rasterizer.cpp:1288-1292`) normalizes the sign of the barycentric
  determinant before use — there is no winding-dependent culling in this
  rasterizer at all, so a CW/CCW mismatch cannot be the cause.
- **Per-triangle scissor/alpha/Z test divergence**: `writeFragment`/
  `writePixel` (`ps2_gs_rasterizer.cpp:675-780`) apply the same scissor,
  alpha test, and Z test logic regardless of which triangle of a strip/list
  is being drawn.

### Remaining hypothesis (not yet tested)

`CapturePresentedFrame` (`ps2_runtime.cpp:1274-1297`) was confirmed to read
the *same* `pixels` buffer that `UploadFrame` uploads for the live window —
so "probe reads a different buffer than the screen" is weakened, but not
eliminated, because the latch happens once per `currentTick` and a capture
mid-latch could still see a different instant than the live window at the
"same" timestamp.

### What would move this forward

Capture the actual quad's vertex list (there is existing boot-trace
instrumentation at `ps2_gs_gpu.cpp:2102-2137`, env var
`PS2_IF_AGRESSIVE_LOGS`) at the exact moment the diagonal cut is visible
live, and compare it against what the probe/present-capture records for the
same frame. No fixture with real captured vertex data has been built yet.

### Environment

- Runtime: `PS2Recomp` fork, software GS rasterizer path.
- Reference build referenced in the investigation:
  `mc3-menu-last2-20260915` (SHA `dc0375b7...`), no code changes applied.

---

## Issue 2: Frame rate ~44.7 Hz vs 60 Hz target — software rasterizer is the largest graphics cost

**Labels suggestion:** `performance`, `rendering`

> Correction (2026-09-30): the original version of this issue said the VIF1
> interpreter was the largest cost. That was wrong. The `vifMs`/`vu1Ms`/
> `rasterMs` timers are **nested** (VIF1 calls VU1, which reaches the
> rasterizer), so the VIF1 figure included the other two.

### Measurement (exclusive time, one ~400 s run, tick=18060)

| Phase | inclusive ms | exclusive ms |
| --- | ---: | ---: |
| GS software rasterizer | 64,583 | **64,472** |
| VU1 | 77,782 | 26,605 |
| VIF1 | 114,048 | 22,967 |

22,967 + 26,605 + 64,472 = 114,044, i.e. the old VIF1 figure. Method: a
per-thread child-time stack subtracts nested scopes (instrumented build,
runtime sources copied, no change to the shipped runtime). Single run; the
historical spread between runs is 12–23%, so the *order* is reliable, the
absolute values are not.

### Inside the rasterizer (PC sampling, ~19k samples)

~45% bilinear texture sampling (4 texel reads, 4 channel lerps, 2 floors per
pixel), 11% triangle pixel loop, 7% PSMCT32 swizzle address, 6% pixel write.
About 19% of samples fall in unresolved library code, most likely
`lround`/`floor` called as functions. Candidate bit-exact optimizations:
inline exact replacements for `lround`/`floor`, hoist texture-format dispatch
out of the per-pixel path.

### Scope caveat

Graphics total ~114 s of ~404 s wall (28%); the rasterizer alone is 16%.
Doubling its speed would gain ~8% overall and would **not** fix the menu
delay (see Issue 3): the main thread spends ~224 s waiting for its execution
turn vs ~98 s executing.

---

## Issue 3: Menu list appears ~11 minutes after boot — thread scheduling, not a missing function

**Labels suggestion:** `bug`, `blocker`, `scheduler`

> Supersedes the earlier "readyformenu stays 0" / missing-variable write-up,
> which was a short-run artifact: in runs of 20–30 minutes the recomp creates
> all 47 script variables and registers the menu list properties (the
> condition at `0x33F7E0`/`0x34177C` passes). The variable is set — just very
> late.

### Timeline (30-minute timestamped run)

21 variables at 0.4 s; transition at 96 s; title ready at 172 s (another run:
534 s); `ready` + menu list at 669 s; `MenuOptionScreen` at 684 s. On the PS2
the list is built immediately after START.

### What was measured

- The main thread waits ~210–224 s for its turn and holds it for ~445 s per
  720 s. Its own work includes the graphics pipeline (Issue 2).
- The network worker (`netManagerThread::MainLoop`, priority 7) loops with a
  10 ms `DelayThread`, but each turn costs 2–3 ms of execution and it blocked
  the main thread ~146 s over 12 min (45,632 turn takeovers).
- Experiment: making that worker sleep 100 ms per loop brought the menu list
  forward from 669 s to 416 s.
- The loader thread (entry `0x1AAB60`, priority 2) does only ~7 s of real work.
- The runtime hands execution turns over with an OS mutex with no priority.
  A priority-ordered deterministic mode made things ~7x slower.
- After a semaphore signal, a waiting thread can take up to ~477 ms to resume
  (re-acquiring the execution turn) for a 10 ms requested delay.

### PC sampling of the network worker (2026-09-30)

Sampling the worker's host thread (~62k samples, one run) found **0% of
samples inside recompiled guest code**: it is blocked in the OS ~100% of the
time, mostly queueing for the execution turn (`reacquireGuestExecution` /
`enterGuestExecution`, ~35%) or inside `WaitSema`/`SignalSema` (~24%); the
rest could not be attributed reliably. So the worker is not a CPU hog; the
cost comes from many turn handoffs per loop through a non-fair
`std::recursive_mutex` while the main thread holds the turn for long stretches.

### What would close this issue

Count turn handoffs per `netManagerThread` iteration and the wait per handoff,
and/or make the turn handoff honour priorities without the 7x slowdown (a
scheduler change).

