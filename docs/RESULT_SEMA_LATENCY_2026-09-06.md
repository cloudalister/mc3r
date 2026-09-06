# Semaphore resume latency - 2026-09-06

## Question and scope

Separate the prior observed 0..477ms signal-return-to-wake delay into CV return,
guest execution-token reacquisition, semaphore mutex reacquisition and suspension
handling. The separate initial ~348s wait must not be attributed to those nine
timer waits (which previously totaled only3.302s).

Passive diagnostic only: no signal injection, scheduler policy, lock order,
guest register/memory or timer behavior changes. Same MC3_TIMER_WAIT_TRACE=1
switch enables the new header ps2_sema_latency_probe.h and Sync.cpp hooks.

## Measurement semantics

- accepted SignalSema and runtime-compat signals capture the first notification
  under the existing semaphore mutex; no printing there;
- BeforeWait/AfterWait delimit the predicate CV wait;
- AfterWait/TokenReacquired delimit semaphore unlock and reacquisition of guest
  execution permission through GuestExecutionReleaseScope destruction;
- TokenReacquired/LockRetaken delimit semaphore mutex reacquisition;
- logging occurs after semaphore unlock and waitWhileSuspended, only for TLS1;
- totalNs/cvNs/tokenNs/mutexNs/postNs/suspendNs are durations;
- notifyNs/cvOutNs/tokenAtNs are absolute monotonic timestamps. For one attempt,
  cvOutNs-notifyNs estimates accepted-notification-to-CV-return latency;
- retries preserve first notification/CV/token timestamps and accumulate CV,
  token and mutex durations. Do not apply single-attempt subtraction to retries;
- notifyNs=0 is not evidence of a lost signal. Immediate-count waits need no
  notification; exceptional exits do not print a completion;
- postNs measures final post-lock work, not all retry bookkeeping. These phases
  are not an exhaustive additive partition. Diagnostic overhead is unmeasured,
  including logging of immediate-count completions; this is not an FPS A/B.

## Validation and provenance

323/323 runtime tests passed, including synthetic two-attempt interval accounting.
Read-only peer review found no concrete behavior/lock-order regression.
Relink completed, sema-latency string verified inside the actual executable.
Exe mtime07:18:04.241 is newer than library07:16:46.028.

- exe SHA256: d119ddf1db4ef45c81525e7f3b9b36f3a9bb3169e38c7fb0dbc8e213e6c36184
- lib SHA256: 6726f4f51ba857ab6127c2c366b9b556d42fe5f5fdda5c2199c7e7651fa853e6
- probe start: 2026-09-06T07:19:19.1571978-03:00
- label: sema_latency_astra_20260906; requested600s
- evidence prefix: work/logs/probe_sema_latency_astra_20260906.log

Reproduce with RTK:

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Probe-FrontendWrites.ps1 -Seconds 600 -Label sema_latency_astra_20260906 -QuietBootTrace -TraceWait -TraceNetCallback -TraceTimerWait
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Analyze-SemaLatency.ps1 -LogPath work/logs/probe_sema_latency_astra_20260906.log.stderr
```

## Result

Completed07:29:20.6235; wall601.027926s, CPU360.796875s (user219.40625,
kernel141.390625). Harness stopped its owned process at the limit; no MC3
process remained. No early exit. This is not a performance comparison.

3888 completed TLS1 waits,35 entered CV wait.34 completed waits returned to
005476b0 (33 blocked, one immediate); their total9.1471183s includes8.0698051s
reacquiring guest execution permission and1.0767732s in CV. Semaphore mutex
reacquisition totaled only0.0116ms. Normal execution mode confirmed: harness
clears MC3 variables and does not enable MC3_DETERMINISTIC, whose default is off.
Here reacquireGuestExecution uses m_guestExecutionMutex.lock().

### Three distinct observations

1. **Short timer resume contention is confirmed.** SID254 spent791.5268ms in
   WaitSema:22.2958ms CV,769.2108ms token,0.0004ms mutex. Its accepted notification
   reached CV return in0.0152ms. Across the completed blocked timer waits,
   notification-to-CV-return was0.0085..0.0446ms. Token contention, not semaphore
   mutex reacquisition, explains the large post-signal delay in these samples.
   The total8.07s does NOT explain the entire601s run or identify the token owner
   responsible for each delay; there is no scheduler-policy fix justified yet.

2. **Initial wait is different.** SID220,RA00398b28,dispatch001a5fc0 took
   272.0927257s, of which272.0925054s were in CV. First accepted notification was
   only0.0173ms before CV returned; token acquisition took0.2059ms. Almost all
   the wait preceded that notification, not token recovery. This does not yet
   explain what delayed the producer. Earlier ~348s was a different run.

3. **Long timer stall reproduced before callback entry.** Final SID22 was
   prepared at tMs48875676, armed at48875685 with alarm0703e019. No matching
   callback, signal-return, woke or completed sema-latency record exists before
   shutdown. Last main-wait sample:RA005476b0,dispatch00322ffc,cv-wait,
   age122503ms,tokenWaitMs0,owner8. This bounds the observed gap to BEFORE the
   focused callback entry, not after its signal. It does NOT distinguish alarm
   queue/deadline handling, worker scheduling, or guest-token admission before
   callback entry. Owner8 is a snapshot, not proof it held the token continuously.

Only two initialization FE writes, no animation updates;42b150Calls0. No
recover-pc/first-bad records, but unexercised missing-call paths are NOT accepted.
No menu or FPS acceptance claimed. Different trajectory and logging overhead
mean the faster initial-wait sample is not a claimed improvement.

## Recommended next diagnostic

Trace this specific alarm from registration through due-queue selection, worker
entry, guest-token wait/acquisition and actual callback dispatch. Capture IDs
before filtering, match alarm/semaphore rather than TLS identity, avoid printing
under locks. This distinguishes an undelivered alarm from a worker blocked before
callback entry. Separately trace the initial producer leading to SignalSema.
Do not inject a signal, change scheduling fairness, or disable networking based
on the current observations. The new probes are opt-in, not a behavioral fix.
