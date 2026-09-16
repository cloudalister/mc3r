# Proposed GitHub issues (paste-ready, not yet uploaded)

Three issues, drafted from `docs/RESULT_RENDER_FPS_2026-09-15.md` and
`docs/RESULT_MENU_ITEMS_2026-09-15.md`. Copy each block into a new GitHub
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

## Issue 2: Frame rate ~44.7 Hz vs 60 Hz target — VIF1 interpreter is the largest measured cost

**Labels suggestion:** `performance`, `rendering`

### Summary

A live 460-second probe (`MC3_PHASE_TIMING=1`, exe `mc3-menu-last2-20260915`,
unmodified) measured a `tick` (vblank) counter reaching ~20580, giving
**≈44.7 Hz effective**, about 25% below the PS2's native 60 Hz. This is a
direct measurement (tick count / wall time), not an estimate.

### Where the time goes (cumulative counters at `tick=20580`)

```
vifMs        = 137053   ms  (VIF1 interpreter)
vu1Ms        =  87803   ms  (VU1 emulation)
rasterMs     =  61025   ms  (GS software rasterizer), rasterCalls=3092418
guestExecMs  = 127646   ms  (R5900 CPU interpreter, main thread)
guestWaitMs  = 273876   ms  (sync/wait time, not work)
gsPrims      = 3092418
gsPixels     = 1115955855
```

**Ordering found: `vifMs` > `vu1Ms` > `rasterMs`** — the VIF1 interpreter is
the single largest instrumented render-adjacent cost, ahead of VU1 emulation
and the software GS rasterizer.

### Important caveat

`rasterMs`/`vu1Ms`/`vifMs`/`guestExecMs` are independent timers that can
overlap across threads (`activeThreads=7` in this run) — they should **not**
be summed as if exclusive. Only the *relative* ordering (vif > vu1 > raster)
is treated as reliable from this single measurement; per-frame wall-clock
attribution has not been done.

### What would move this forward

Profile inside the VIF1 interpreter itself (which opcode/unpack format
dominates) before attempting any optimization — the investigation
deliberately avoided a blind optimization attempt without an internal
profile, per this project's rule against unverified claims of improvement.

### How to reproduce the measurement

Run the reference exe with `MC3_PHASE_TIMING=1` set (same flags as
`23_jogar_com_console.bat`) and diff two `[run:tick] ... rasterMs=...
vu1Ms=... vifMs=...` lines from stdout/stderr log (`ps2_runtime.cpp:606-619`
emits these periodically) to get the cost per elapsed tick range.

---

## Issue 3: Menu never opens — script variable "readyformenu" stays 0, so the panel swap that should activate the options screen never runs

**Labels suggestion:** `bug`, `blocker`, `confirmed-root-cause`

### Summary

After pressing START, the internal menu state advances (gate flags open,
confirmed via live instrumentation) but the game never switches from the
title panel to the options panel. This is a **proven root cause**,
confirmed by directly comparing our recomp against **retail PS2 behavior**
over PINE (PCSX2's debug/memory protocol), not just by reading our own
code — an earlier working hypothesis in this same investigation (a supposed
missing write to a menu-item list pointer at object offset `+0x74`) was
**falsified** by that same retail comparison and is superseded by this
finding.

### What retail does vs. what the recomp does

Live PINE comparison (`docs/RESULT_MENU_ITEMS_2026-09-15.md`, appendix 6):
in `front+0x40..0x130` (the active-panel slot table), retail activates a
panel at vtable `0x629B88` (slot `0x58`, flags bit0 set = active) and
deactivates the previously-active panel at vtable `0x62BDE0` (slot `0xb0`,
flags bit0 cleared) once START is pressed. **In our recomp, `0x62BDE0` stays
active and `0x629B88` is never activated** — the panel swap simply never
happens.

A PCSX2 DebugServer watchpoint on retail (appendix 10) traced the real
activation call chain:

```
322FD8 -> 320B38 -> 339278 -> 353CA0 -> 380068 -> 41F550 -> 427BD0 (SetActive, a1=1)
```

`427BD0`/`427C14` is confirmed as the setter that writes the "active" flag
bit (`sw v1, 0x44(s0)`) into the `0x629B88` panel object.

### Root cause (appendix 11, verified against the ELF)

Function `0x320B38` — verified opcode-identical between the ELF and our
generated corpus (`FUN_00320b38`) — contains the decisive branch:

```
320BF8  jal 20B290(a0=*(s0+4), a1="readyformenu" @0x64C9CF, a2=s0)
320C00  lbu v1, 0(s0)
320C04  beqz v1 -> 320C2C   ; skips the call below when v1 == 0
320C0C..320C24  ; check *(*(*(0x617ADC)+0xC)+0xC)+0xE0; if != 1 -> jal 339278
                ; (the path that reaches 41F550 -> 427BD0 SetActive(629B88) on retail)
```

`20B290` reads a named script/data variable ("read variable by name",
`readyformenu`) via lookup helper `20AF60`. **In our recomp, the trace of
`320B38` shows the branch at `320C04` is taken with `readyformenu == 0`**,
so `339278` (and therefore the whole chain down to `427BD0`) never runs and
the `0x629B88` panel is never activated. The only code sites that touch this
named variable are `320BF0` (read, this branch) and `320E64`/`320F8C` (which
zero it out after use via `20B258`) — the value `1` that should arm this
branch comes from outside the code path itself (script/disc data setting the
named variable), and that write is not happening (or not reaching the same
storage) in the recompiled build.

### Why the earlier `instance+0x74` hypothesis is wrong (do not re-open it)

A prior appendix in the same investigation (appendices 1-4) suspected a
missing write to `member+0x74` (a child-list pointer on a `0x631ba8`-vtable
object) as the blocker. Appendix 5 read the **same fields live from a
retail VM via PINE** in the equivalent menu state and found retail has the
**exact same** empty `+0x74` on the exact same object (`ownChildCount=0` on
both sides) — i.e., retail doesn't populate that pointer either at this
point, so it was never the mechanism that draws menu items. That hypothesis
is closed; do not restart investigation there.

### What would close this issue

Find what is supposed to write `1` into the `readyformenu` named variable
(script bytecode or disc data, not `.text` per appendix 11 — the only code
references to the name itself read or clear it, never set it to 1), confirm
whether that write happens at all in the recompiled runtime, and if not,
find why (script/data not loaded, script interpreter not reaching that
opcode, or a state check earlier in the chain diverging from retail).

### Evidence

`docs/RESULT_MENU_ITEMS_2026-09-15.md`, appendices 6, 8, 10 and 11 (full
PINE comparison method, retail watchpoint backtraces, and the ELF/corpus
opcode verification of `320B38`).
