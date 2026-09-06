# Focused timer-wait correlation - 2026-09-06

## Why the old probe was insufficient

Previous boot list_entry_astra_20260906 stopped before invoking restored42b150,
with main waiting in5476a8/return5476b0 (SID21,218843ms at final sample).

First diagnostic timer_wait_astra_20260906 used the SAME exe
fcdf01cd2cfb85b6949550cc712088d874f2dc1d532cb62c7e847698fec3147f,
same library90d768bde32a49a65c0ab03643399b40322fc617a9719032999503c7a19279dd,
and enabled existing MC3_TIMER2_TRACE. It showed early alarm/callback/wake
cycles, but global caps16/24 were exhausted before main's later wait. It was
intentionally stopped after95s by terminating only its path/start-time-verified
owned process. Exit-1 reflects that diagnostic interruption, NOT a game crash.
No performance or missing-call conclusions from this aborted trace.

The existing callback trace is in FUN_005476d0, not just the timer IRQ logger.
Timer2 guest INTC and the host SetAlarm worker are distinct dispatch paths:
do not assume a generic SetAlarm callback proves Timer2 IRQ delivery.

## New opt-in observation, no guest behavior change

Header runtime/ps2_timer_wait_probe.h, MC3_TIMER_WAIT_TRACE=1:

-begin records main-wrapper usec/RA/status and host monotonic milliseconds;
-prepared publishes semaphore immediately after CreateSema, BEFORE alarm setup;
-armed records returned alarm ID;
-callback matches the watched semaphore and captures its ID/alarm in TLS;
-signal-return records iSignalSema's return value;
-woke records WaitSema's return and clears the watched semaphore.

Only begin/prepared/armed/woke use guest TLS tid1 filtering. Callback matching is
by semaphore, not thread ID. A host alarm worker can have default guest TLS1:
its log says tlsTid, NOT physical main-thread identity. The callback is FOR the
watched wait, not necessarily running ON main. The specific5476d0 callback only
signals and returns; it does not call the timer-wait wrapper.

No cross-thread guest context pointers, no new locks, no guest register/memory,
timer, scheduler, token or signal behavior changes. Logging is main-wait scoped,
not exhausted by background callbacks. Overhead is not a performance A/B.
Semaphore reuse after wake is excluded by clearing the watch; callback return
can still be logged after wake via its captured TLS identity. A callback before
arm returns is permitted and visible because prepared was published first.

## Validation and ignored source reproduction

322/322 existing runtime tests passed. New standalone probe test passed main
filtering, wrong semaphore exclusion, callback identity, wake-before-signal-return
and a worker with default TLS1. It does NOT execute a real alarm worker.
Read-only review checked hook positions and flagged the TLS labeling caveat.

Both ignored batch0054 owners include runtime/ps2_timer_wait_probe.h:

-sub_00547608_0x547608: begin at entry547608; prepared after s0 assignment at
  547658; armed after s1 assignment at54768c; woke at label5476b0.
-FUN_005476d0_0x5476d0: callback at entry using a3=semaphore,a0=alarm,a2=guestNow;
  signaled at label5476e0 using v0 result. No original instructions changed.

Source SHA256/manifest entries:
-sub_00547608:f9647e6237109d2c9fe7305a65248bc48e6fde6dd9134b44f6d00395ae7a6c80
-FUN_005476d0:ff54ca332bac10a0dcd580704f8f47e8eacd9d19847c1b8d9b609fe41fc42399

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Test-TimerWaitProbe.ps1
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Compile-TimerWaitProbe.ps1
rtk proxy cmd /c E:\Games\Emuladores\Sony\mc3recomp\10_link_partial_runner.bat fast
```

No new aliases; existing partial registry is reused.

## Focused probe

timer_focus_astra_20260906 started06:54:02,600s,quiet+wait+callback+TraceTimerWait.
Legacy TraceTimer2 is OFF here to avoid its irrelevant capped background output.
No builds/tests compete with this run. Exe06:53:28 is newer than both owner
objects06:52:37/39. New probe strings verified inside the linked executable.

-Exe SHA256:870171e55bc0f1c08f6b4a2fcc9eaa848d11c37142c1bc0c4ea92a4477393266
-Lib SHA256:90d768bde32a49a65c0ab03643399b40322fc617a9719032999503c7a19279dd

Completed07:04:04:wall600.9092s,CPU315.625s (user213.34375,kernel102.28125).
No early exit; harness stopped its process at limit. No MC3 remains running.

## Measured result

All9 main timer waits (callerRA398c74,requested10000us each) have matching
prepared/armed/callback/signal-return/woke events. No missing signal or long
218s timer wait reproduced in this run. Callback tlsTid=-1 was observed here;
it is a guest TLS label, not physical host-thread identity.

| Semaphore | Begin to wake ms | Armed to callback ms | Signal-return to wake ms |
| --- | ---: | ---: | ---: |
| 116 | 739 | 7 | 477 |
| 127 | 152 | 7 | 93 |
| 132 | 364 | 1 | 304 |
| 139 | 59 | 11 | 0 |
| 145 | 452 | 9 | 390 |
| 152 | 498 | 5 | 431 |
| 162 | 472 | 15 | 303 |
| 170 | 57 | 2 | 0 |
| 176 | 509 | 10 | 454 |

Total3.302s across these9 waits,2.452s AFTER the callback had reported returning
from iSignalSema. This locates a measurable resumption delay, but does not
separate guest-token reacquisition, host scheduling or other wrapper work.
Nor does3.302s explain the full600.9s run. First wait remains a separate issue:
SID12 at dispatch1a5fc0/RA398b28 reached347552ms then returned, before the timer
waits above. Do NOT claim the timer or scheduler explains all boot slowness.

Other runtime evidence:

-Restored42b150 executed85 times (previous lot could not reach it); no bad42b150.
-5 recover-pc records, plus the first-bad report. Remaining target records:
  5bb268 four including first-bad,5bb238 two. No print-cap hit. This is runtime
  coverage for this path, not proof that every missing entry has been found.
-24 complete frontend writes,11 animation updates, last13->14 at322e94,
  timer0.362999946. Quiet mode provides no current visual/menu/FPS acceptance.
-No production behavior fix in this lot: only opt-in diagnostics and harness.

Evidence: work/logs/probe_timer_focus_astra_20260906.log.stderr/.stdout/.meta/
.result.json, analyzed after completion. Current exe is the measured hash above.

## Next

Measure the handoff from semaphore notification to main's guest-token
reacquisition, while retaining the separate347.6s initial-wait investigation.
Do not change scheduler fairness or force signals based on this sample alone.
5bb238/5bb268 remain independently verified missing-body candidates (see prior
RESULT_LIST_ENTRY report); their restoration is not a timer fix.
