# IRQ list edge observations - resumed2026-09-06 evening

## Scope

Resume from068afa4, clean root/submodule tree. Previous tick25856/54cc08 stall
was run-specific; historical correction in RESULT_BRANCH_STALL_0x54CB58_2026-08-31.md
still applies. Do not assume this loop explains all boot failures.

Probe the actual edge already read at54cc08, only on the normal IRQ worker.
No extra guest-memory reads, no writes, no scheduler/lock/signal/rate changes.
One read-only investigation peer checked traversal and false-positive risks.

Static head provenance:54cb58 constructs006228b0, and54cb80 loads a2 from
base+18, hence global006228c8. Do NOT call this heap or conflate it with the
separate704200 node pool from54d6a0. Writers of the walked nodes' +10/+18/+20
fields have not yet been proven. The edge probe adds no global-head read.

## Implementation and limitations

runtime/ps2_irq_list_probe.h records from/next plus s0,RA,SP scalar copies.
256-entry direct-mapped TLS history, O(1) per observed edge. A hash collision
evicts history (can miss a repeat, cannot manufacture one). Same source with
different destination increments changed; same edge increments repeated.
This is observed repetition, NOT proof of a stable cyclic list under concurrency.
Reset on actual54cb58 entry or a new IRQ tick; preserve across54cc08 resumptions.
First16, first repeat, then every4096 edges publish an atomic revision snapshot;
existing five-second reporter prints it. No logging inside the traversal.
Counter is sampled and can lag; walk identifies the most recently started walk,
not cumulative coverage across earlier walks. No record/steps0 can mean that
this particular walk never reached54cc08. s0 is sampled before following next;
other node fields are NOT captured and changing arithmetic cannot be fully
explained from this probe. Diagnostic overhead is unmeasured.

### Generated owner reproduction

Owner:work/generated/ghidra/FUN_0054cb58_0x54cb58.cpp (ignored by Git).
Add include runtime/ps2_irq_list_probe.h. Before the entry switch, add:

```cpp
if (ctx->pc == 0x54cb58u) ps2_irq_list_probe::begin();
```

Only at label54cc08, replace the existing SET_GPR_S32 load with this block:

```cpp
{
    const uint32_t probeFrom = GPR_U32(ctx, 6);
    SET_GPR_S32(ctx, 6, (int32_t)READ32(ADD32(GPR_U32(ctx, 6), 0)));
    ps2_irq_list_probe::observe(probeFrom,GPR_U32(ctx,6),GPR_U64(ctx,16),GPR_U32(ctx,31),GPR_U32(ctx,29));
}
```

No other guest instructions change. Preserve earlier comments/dispatch cases.
Owner SHA256 cf6fa1947e946962697716f57ee441f4060854c7588cd69f7955cc4b0cd33335.
tools/Compile-IrqListProbe.ps1 compiles exact owner into batch0054 existing object.
tools/Verify-IrqList.js verifies all100 instruction annotations against ELF and
coverage of54cb58..54cce4. This proves opcode provenance, NOT complete semantic
equivalence of all generated expressions; no such blanket claim is made.

## Validation

325/325 runtime tests passed after completed build, before runner relink. New
history test covers two-node repeat, changed destination, reset and self edge.
Generated owner compiled successfully. No game was running at compilation.

## Runtime result

Run irq_list_astra_20260906 started2026-09-06T18:42:48.6831045-03:00, requested600s.
Actual exe [irq-list] marker verified after completed relink.
Exe SHA2569c3a333383b245f078ae0b2407d794c14f45a8882fdfe2b73309d5f6d81bbb01.
Lib SHA25645657ffc7f71e477f30761f45f55068941d7c81f5be5ac42ce39df3a8ecb9b8a.
Evidence prefix work/logs/probe_irq_list_astra_20260906.log.

```powershell
rtk proxy node tools/Verify-IrqList.js
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Compile-IrqListProbe.ps1
rtk proxy cmd /c work\scratch\build_vu_budget_tests.bat
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Test-NetCallbackRuntime.ps1
rtk proxy cmd /c <project-root>\10_link_partial_runner.bat fast
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Probe-FrontendWrites.ps1 -Seconds 600 -Label irq_list_astra_20260906 -QuietBootTrace -TraceWait -TraceNetCallback -TraceTimerWait
```

Await each build/link/test completion before the next command.

### Completed result

Finished18:52:50.9838; wall601.0087923s, CPU234.546875s (user152.90625,
kernel81.640625). No early exit; owned process stopped and no MC3 remained.
Exe mtime18:42:36 newer than library18:38:42. No performance A/B claimed.

Initial SID205,RA398b28 wait322.3255073s, CV322.3253169s, token0.1788ms,
accepted notification-to-CV-return0.013ms.57 focused timer WaitSema completions
followed; final SID116 was prepared tMs5463686, armed5463698,alarm0703e02b,
without matching callback/signal-return/woke before shutdown. Last main sample
RA5476b0,dispatch322ffc,cv-wait age36317ms,tokenWaitMs0,owner8.

During that final stall IRQ snapshots advance from tick33686 through35787,
with tick-done and lastLookup5280b8. Thus the NORMAL WORKER IS NOT STUCK in
54cc08 in this run. This proves worker ticks continue, NOT that Timer2 COUNT,
MODE, COMP or guest deadline arithmetic is correct (not sampled here).

No sampled irq-list steps>0. Last sample walk16041,tick35785,steps0. Since each
new walk resets the snapshot, brief earlier traversals may be missed; do not
claim the loop was never reached, nor call the detector a runtime cycle test
pass. Its history was unit tested, but no cyclic guest traversal was captured.

Only2 initial frontend writes;42b150Calls0,no animation progress. No recoveries
as coverage acceptance. No menu/FPS/visual acceptance.

### What changes in the next investigation

Two distinct observed outcomes: prior IRQ tick25856 stuck in54cc08; current
pending alarm with IRQ worker continuing normally. The list-stall cannot be the
universal explanation for delayed callbacks. Preserve its probe for recurrence,
but next prioritize Timer2 MODE/COUNT/COMP and guest alarm registration/selection:
capture the pending alarm's deadline and list identity, then actual cause11
dispatch and selection decisions on the executing thread. No inferred queue
ownership, forced signals, list cutting or scheduler edits. Need distinguish
disabled/non-triggering timer from guest queue/deadline rejection even though
the surrounding VBlank worker is alive.
