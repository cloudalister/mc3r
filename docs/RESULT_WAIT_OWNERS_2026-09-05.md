# Token wait attribution - 2026-09-05

## Implemented experiment

Runtime54a3c97 adds opt-in `MC3_WAIT_PROFILE=1`, without changing lock order,
yield decisions, timers or scheduling. Single active runtime, normal scheduler
only. Main tid1 confirmed in Helpers/State.h and Lifecycle.cpp. Deterministic
mode bypasses these hooks; absent records must not be read as zero waits.

Per tid: initial acquisition wait, reacquisition wait, completed outermost token
holds, and the intersection of each hold with a main-thread wait interval.
The latter is a SUBSET of wait, not additional wall time. Nested holds do not
restart the timer. ReleaseScope closes a hold before unlocking; reacquisition
opens a new one. Atomic counters, steady clock and TLS only in hooks. The host
thread emits snapshots every >=5s, outside the guest token, with no live guest
context reads. The helper is process-local; multiple runtimes are unsupported.

Snapshots are concurrent and contain completed holds/waits only. An ongoing main
wait may have completed blocking holds already counted, so a snapshot need not
close exactly. No function-level or CPU attribution follows from owner totals.

`tools/Analyze-WaitProfile.ps1` rejects incomplete records/counter regressions and
reports per-owner deltas (`-StartSequence` optional). It preserves actual sampled
boundaries. `tools/Test-AnalyzeWaitProfile.ps1` passed synthetic delta, ordering,
corrupt-line, absent and impossible-overlap tests. Suite **317/317** passed,
including six interval-intersection assertions. First invocation used the wrong
test cwd and failed; the successful run used PS2Recomp as cwd, separate v2 logs.
Read-only economic review found no new lock ordering and confirmed interval logic.

## Binary/run provenance

Exe2026-09-05 23:46:40 newer than library23:45:36, `[wait-profile]` verified inside.
Exe SHA256 `c166123ebba90ae5a0ff8038f46c6742dfbe7e6a5ae331f1be5a42c8f2dfefbb`.
Lib SHA256 `09b21fa81e4ec0f627e1c5c6e005d2f4be995b3a874445769e624b586809c6f9`.
Probe `wait_owner_astra_20260905`, started23:47:05 metadata; owned PID6248.
900s limit, default scheduler, headless, phase/FE/boot trace, automatic START,
wait profile; image threshold900000. No concurrent build/test workload during run.
Performance overhead of the instrumentation has NOT been benchmarked; no speed
claim is intended. The run is for attribution under its recorded configuration.

## Early observations (not final result)

Sequence34: main initial72.8324s +reacquire0.0068s. Holds overlapping its wait:
tid7 46.2927s, tid5 26.4105s, remaining owners below0.074s combined.
These are early-boot totals, not a statement about the later frontend.

Actual startup records map tid5 to entry42b668, tid7 to1aab60. Existing generated
code and local symbol export connect the former to42b868 and calls to
`datStreamer::GetBaseSector` (432598, hash mapping) and `ipcWaitSema` (398b18).
The latter's1aab90 wrapper calls1aad28/1ac2a0, an object-update path. This describes
the workers, not proof that IO or drawing is the expensive operation inside them.
Do not infer the held operation from a sampled dispatch PC alone.

## Completion

First run exited early at460.7338539s. CPU198.328125s (112.640625user,
85.6875kernel). Last complete sequence91: main initial85.8430404s and
reacquire0.0067821s; overlapping holds tid7=50.6542191s, tid5=35.0311601s,
others0.0735859s. These are early-boot findings only. Animation0,343 complete
VU counter records all zero caps; no900000-primitive capture was produced.

### Existing diagnostic crash found and repaired

The Windows Application Error event identifies the same PID6248 (hex1868),
path and binary: exceptionC0000005, module RVA0b49e8e6, report
618bffcd-0266-4909-8e82-cf0ac46a61b2. ImageBase140000000 was verified with
objdump; addr2line of14b49e8e6 resolves to `LiveGuestPcOf`, ps2_runtime.cpp1142.
The last log interleaves thread7 exit and a waiter reporting owner7. This is
consistent with the diagnostic dereferencing that worker's expired context.
Atomic publication of a pointer did not protect its pointee's lifetime; even
before exit, unsynchronized live register reads were a C++ data race.

Runtime478fb98 removes the raw context-pointer publication. The owner copies
RA/SP at dispatch into atomic storage; diagnostics read copied registers and the
existing atomic dispatch PC, explicitly labeled `sample=dispatch` /
`ownerDispatchPc`. This deliberately gives up instruction-level live PC precision.
No guest instructions or synchronization decisions changed. Read-only review
confirmed no remaining g_ctxByTid/live-context readers in this file; suite317/317
passed again (`wait_profile_safe_tests_20260905.stdout`). No sanitizer reproduction
was run; attribution rests on the OS fault address, symbols, exit trace and code.

Get-WinEvent was unavailable because its module failed to load; native wevtutil
provided the event evidence. Harness exitCode was blank in the first run, so it
now retains the process handle and records exitCode for early exits as well.

### Repeat with safe snapshots

`wait_owner_safe_astra_20260905` completed with the same900s configuration.
Exe23:58:10 newer than lib23:56:50; all probe/safe-snapshot strings verified.
Ended2026-09-06 00:13:41 at901.6661875s, alive until harness timeout, no repeat of
the diagnostic crash. CPU369.734375s (205.3125user,164.421875kernel). No MC3 left.
Exe SHA256 `3c2f31b157f598cbbeec6bdb2301064f615800fb2083ab6bb76fe26127260650`.
Lib SHA256 `2f7aabb54b94614a1a23268d93d112ded017b18eb448542710b4f027ef1e9aec`.

Last complete owner snapshot sequence179:

| Metric | Seconds |
|---|---:|
| Main initial token wait | 457.786565 |
| Main token reacquisition wait | 8.665920 |
| Main completed token holds | 167.476161 |
| Network tid8 hold overlapping main wait | 358.941523 |
| Data worker tid5 overlap | 56.175801 |
| Early object-update worker tid7 overlap | 49.283426 |
| Other owners overlap | 1.932318 |

The later window is **sequence88->179**, after thread7 exit and thread8 startup;
it is not a fixed wall-time window or a completed-frame benchmark:

| Later-window metric | Seconds |
|---|---:|
| Main initial +reacquisition wait | 381.299654 |
| Network tid8 overlap | **352.673244** |
| Data worker tid5 overlap | 27.944445 |
| Other owners overlap | 0.479710 |
| Main completed token holds | 62.934758 |

Thus about**92.5% of this window's sampled main token wait** overlaps the network
worker holding the token. This is an owner attribution, not proof of its internal
expensive function, unnecessary work, a scheduler bug, or92.5% of wall time.
Some waits inside a guest function release the token and are outside these wait
counters. Do not use hold+tokenWait to assert complete main-thread accounting.

Frontend:652 complete position samples, last/max21, no observed regressions;
34 write events/16 Updates. VU:658 complete samples, zero caps,86,387,188 cycles.
GS964321 primitives/445951370 pixels. A one-shot presentation PNG at900000
primitives is nearly black with faint markings; context0 PNG is black. No context1
PNG exists for this capture (not evidence that context1 is black). Both available
images were visually inspected. No menu/gameplay acceptance. Animation21 vs18 in
the earlier TOP-fixed run is not a validated FPS gain: configurations/instrumentation
differ and no comparable repeated performance experiment was performed.

The repeat passed the thread7 exit/worker0 wait-return milestone and started
thread8 at1f9668. Generated owner1f95c0 covers that entry and calls1f95c0 from
1f9670; the local retail symbol port identifies1f95c0 as
`netManagerThread::MainLoop` (hash match). Its statistics routine1fadc0 is also a
hash match. This is an internal guest network worker, not evidence of external
network traffic. At sequence88 it already accounted for6.2683s of overlapping
holds. Later samples are needed before ranking the frontend period.

Sequence88->123: main waits139.7346022+2.8870486=142.6216508s;
overlap tid8=131.9925295s, tid5=10.4752228s, tid3=0.4797095s. This is roughly92%
of the sampled main wait overlapping the network worker; the small accounting
mismatch is permitted by in-flight waits/concurrent snapshots. This is NOT92%
of total elapsed time or all guest work. Animation reached8 by sequence123.

Next discrimination: first repeat with `-QuietBootTrace -TraceWait`, whose wait
profile remains active independently of the verbose boot logs. Compare the same
phase, not aggregate boot time; image/FE counters are unavailable in quiet mode
under the current general trace gate. Do not assume logging overhead is negligible.
Then measure the callback at guest PC1f9608: it reads the vtable from object+0,
then the function pointer from vtable+0x7c (NOT object+0x7c), with guest return
1f9610. Capture the actual target and measure completed guest returns rather than
assuming every C++ function return completes the callback. Distinguish token hold,
CPU and internal waits. Do not disable the worker or change scheduler/math functions.

Reproduce (unique label required):

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Probe-FrontendWrites.ps1 -Seconds 900 -Label wait_owner_next -TraceWait -FrameDumpMinPrims 900000
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Analyze-WaitProfile.ps1 -LogPath work/logs/probe_wait_owner_next.log.stderr
```
