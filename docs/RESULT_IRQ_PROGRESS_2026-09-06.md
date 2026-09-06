# Timer delivery route and IRQ progress - 2026-09-06

## Correct route, before adding probes

The outstanding alarm0703e019 is NOT evidence about the host SetAlarm worker.
Generated547608 calls54d570 then54d6a0, with callback5476d0 and the semaphore
argument. These are the PS2SDK guest Timer2 service. The runtime's separate
Sync.cpp SetAlarm/Helpers Runtime.h g_alarms worker is not this route.

Interrupt.cpp runOneVBlankTick runs GS sync callback FIRST, advances emulated
Timer2 SECOND, dispatches cause11 when due, then VBlank start/end handlers.
The standard interrupt worker runs these serially. A blocked callback anywhere
in a tick can prevent later ticks and thus Timer2 progress. This is a code-path
possibility, not yet proof of the particular stall. No changes to timer rate,
queue semantics, lock order, networking, guest functions or scheduler policy.

## Passive observation

New runtime/ps2_irq_progress_probe.h, using existing MC3_TIMER_WAIT_TRACE flag:

- TLS scope activates publication ONLY inside the normal interrupt worker's
  runOneVBlankTick invocation. Deterministic inline ticks are not measured.
- atomic, revision-checked snapshots carry tick ordinal, stage, stage-start
  host ms, cause and dispatch entry PC; bounded three-attempt read, no spin;
- stages bracket GS callback, timer advance/dispatch, VBlank handlers and
  INTC handler lookup/call/return;
- lastLookup is a separate atomic breadcrumb updated only by this worker's
  lookupFunction calls; NOT the current instruction or an atomic pair with stage;
- existing five-second main-wait reporting prints snapshots. Hooks themselves
  do not print, acquire locks, or read guest memory/context from other threads;
- a stable tick and growing handler-call age locates an invocation not returned,
  but cannot alone distinguish guest computation, lock wait or host descheduling;
- tick-done means that tick returned; its age can include normal host pacing.

Diagnostic overhead not measured. Sampling can miss short stages; absence of
an observed callback is not proof of a lost signal. No visual/FPS acceptance.

## Validation and provenance

Initial test compile used the wrong test assertion method, corrected to IsTrue.
Build then passed. First test launch conflicted with its still-linking executable;
second timed out during unrelated GS tests while runner link was active. After
link completed, clean rerun passed324/324 including snapshot payload and bounded
odd-revision rejection. Do not count the two unsuccessful runs as passes.

Relink completed and [irq-progress] string verified in actual runner.
No generated source owners changed in this lot.

- probe: irq_progress_astra_20260906,600s, headless/owned-process lifecycle
- start:2026-09-06T07:53:55.3368184-03:00
- exe:4ac3c3408afe9aa05d9a222e29b4f052c7c73f30f803fa7480f790759f8290d1
- lib:0b95748db0dcb0d7170a0ef1887d95cdd824b5ae73e44e7a20f78d3bb3ee67e6
- evidence prefix:work/logs/probe_irq_progress_astra_20260906.log

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Probe-FrontendWrites.ps1 -Seconds 600 -Label irq_progress_astra_20260906 -QuietBootTrace -TraceWait -TraceNetCallback -TraceTimerWait
```

## Result

Completed08:03:57.0711; wall601.3939244s, CPU366.328125s (user276.515625,
kernel89.8125). No early exit. Harness stopped its owned process; none remained.

### Initial wait: clock continues

SID174,RA00398b28 took257.4457291s, CV257.4455478s, token0.1693ms,
notification-to-CV-return0.0091ms. IRQ tick snapshots advance throughout this
initial wait (e.g.24132->24433 while wait age reached236634ms). Thus a totally
stopped interrupt worker does not explain this initial wait in this run.

### Later stall: tick25856 does not finish

24 valid IRQ snapshots repeat tick25856, stage handler-call, cause11,
pc0054cc08,lastLookup0054cc08,ageMs0. Some snapshots are omitted by the bounded
revision reader while the worker is publishing. The same tick is observed before
main enters its final wait and still at final main-wait age153882ms: at least
153.882s without completing that tick. This is NOT a single blocked function
invocation of that age: ageMs0 is continually refreshed, consistent with repeated
dispatch/preemption/resumption at54cc08. We did not add a dispatch counter or
capture list nodes, so this does not prove a cyclic list.

The registration maps54cc08 to FUN_0054cb58; owner switch explicitly resumes
label54cc08. Code there walks `a2=READ32(a2)` and exits on null or comparison.
The backedge54cc34 sets pc54cc08 and may return for shouldPreemptGuestExecution;
INTC's outer dispatch loop resumes it. No new Timer2 advancement is reached
while this tick remains inside the handler loop. This is a concrete location
for the observed clock stall, not yet its underlying state-corruption cause.

Final main wait is SID43,RA00529790,dispatch001a2728,cv-wait,tokenWaitMs0,
owner-1. It is NOT the preceding run's SID22/RA5476b0. This run completed both
focused timer waits (SID72 and80), with49.8266/85.6239ms WaitSema durations,
34.9973/67.5122ms token portions. Do not claim the prior outstanding alarm was
reproduced or that54cc08 explains every slow boot.

6 frontend writes,2 animation updates,last1->2 at322e94,timer0.0659999996.
Verified42b150Calls67; leaf5c3a48Calls290; four NOP leaves1each. No recover-pc or
first-bad records observed, not blanket coverage acceptance. No menu/FPS/visual
acceptance. Output contains model-draw activity; still not a playable-game claim.

### Historical caution

Read docs/RESULT_BRANCH_STALL_0x54CB58_2026-08-31.md before interpreting this.
It already recorded54cc08 in one long run, then explicitly retracted the claim
that it explained all bad outcomes: four other bad runs never reached it.
Current evidence adds independent normal IRQ-worker attribution and frozen tick
in THIS run. It does not overturn that correction or establish heap corruption.

## Next bounded diagnostic

Observe a2 and next-node values inside this worker's54cc08 traversal, with a
bounded repetition detector and copied local scalar records. Compare exact ELF
instructions and delay slots before proposing changes; identify actual list and
writers rather than assuming heap or timer queue. Do not treat704200 as the
active pending queue just from enqueue code:54d6a0 also pops/recycles nodes.
Inspect whether the list changes during traversal; do not traverse guest memory
from the reporting thread, force a return, skip nodes, or cap the handler to
pretend success. Retain separate initial-producer and final SID43 investigations.
