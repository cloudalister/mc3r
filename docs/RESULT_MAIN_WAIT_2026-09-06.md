# Main wait snapshot — 2026-09-06

## Question

The previous600s callback probe stopped advancing frontend animation while main
completed-token counters stopped growing. Is main waiting on a semaphore, asleep,
waiting for an event, or outside these covered paths?

## Instrumentation

`MC3_WAIT_PROFILE=1` now also emits `[main-wait]` every5s from the host run loop,
independently of BOOT_TRACE. Scope entry in WaitSema, SleepThread and WaitEventFlag
copies the main thread's own PC/RA and argument. A bounded atomic snapshot avoids
reading guest context pointers across threads; nested scopes restore prior state.
No changes to locks, predicates, token release or scheduler behavior.

Fields: kind, argument (semaphore/event ID), entryPc, entryRa, ageMs (open syscall,
NOT exclusive blocking), tokenWaitMs (current unfinished token wait), owner,
dispatchPc (last sampled dispatch, NOT current guest PC), semaPhase.
The syscall payload is version-consistent; owner/token/phase are independent
snapshots and must not be treated as one globally atomic state. `none-covered`
means no covered scope, not proof that main is running. SleepThread scope does
not distinguish its object mutex, CV wait and token reacquisition by itself.

WaitSema's existing fine-grained phase publication is enabled with WAIT_PROFILE
as well as BOOT_TRACE; its verbose logs remain under their original gate.
DelayThread has no standalone local syscall body found in this audit; inspect
its actual guest chain if SleepThread appears. Suspend/terminate and other host
waits are not covered by a dedicated scope here.

## Validation

Runtime/test build passed;319/319 tests passed using tools/Test-NetCallbackRuntime.ps1.
New deterministic test covers stable payload, incomplete publication rejection
and clearing. Economic read-only review found no scheduler mutation or unsafe
context access. No sanitizer or exhaustive multithread stress was run.

## Runtime result

Absolute relink succeeded02:09:27; exe newer than library02:06:23. Main-wait format
verified in executable before launch. Probe `main_wait_astra_20260906` started
02:10:02,600s, quiet+wait+callback profiles. No concurrent build/tests during probe.
Exe SHA256 `e8f4361d331abfd65d2f968ce586d0c37eb816c98c9e01aa1b662ca88513578a`.
Lib SHA256 `4856b5bed701479ef029dbc9f78392cacf983fd422d9987f8161eb6dfdd3a0be`.
Synthetic parser checks pass: complete, partial and absent records.

Early long wait: WaitSema argument13, entryPc5469e0, entryRa398b28,
dispatchPc1a5fc0, phasecv-wait, tokenWaitMs0. At02:15:11 its observed open age
reached251682ms, with owner7 or-1 in different samples. This is resource waiting,
not main trying to acquire the guest token in those samples.

Static compiled Ghidra chain:1a5fd0 calls1aab08 (global006144bc), then1aa9b8,
then1aaee0 reads object+4005 and1aae80 handles completion when needed.
1aae80 marks object+4004 and calls1ab078, then waits/deletes the semaphore handles
from object+4000 and object+400c. This is consistent with waiting for worker
completion during legal-screen cleanup. We have NOT sampled which field holds
SID13; entryRa398b28 is shared by multiple callers. Never map a dynamic SID using
an unrelated historical run, and never inject its completion signal.

## Completed result

Ended02:20:04 by harness after601.297s; no early exit. CPU322.0625s,
user214.078125s,kernel108s. No game process remains. FE has20 complete writes,
9 animation updates, last10->11. No image expected with BOOT_TRACE0.
Callback target1b84e8:319starts/318ends,139.638s completed inclusive wall,
max1756.199ms,oneactive,zeroabandoned/overflow/unmatched. Not an FPS benchmark.

SID13 had73 complete snapshots and reached361874ms of open syscall age, in
cv-wait without a pending token acquisition. It subsequently returned and the
principal advanced: this run does NOT demonstrate a permanent deadlock there.
Other sampled waits: SID147/entryRa5476b0 (timer delay path), SID44/entryRa529690.
The earlier callback-only run's failure to advance did not reproduce identically.

Producer found statically in compiled Ghidra:1aab90 reads object+4000 or+400c
and calls398b40 -> SignalSema5469c0. This pairs with the wait/delete path above.
Mapping SID13 to a specific object field remains unobserved. The producer's
internal cost is not measured, so don't treat the long age as pure computation.

## Missing-entry evidence changes the next priority

The run has256 lines containing dispatch:recover-pc, reaching the diagnostic's
256-print cap; this is NOT a total count of recoveries. The existing fallback
selects a registered RA/stack/history destination and changes ctx->pc, rather
than executing the unregistered target. No changes to this fallback in this lot.

Read-only comparison: quiet control wait_owner_quiet_astra_20260906 also has256
such lines with the same first case; net_callback_quiet_astra_20260906 has0.
Thus the condition predates this new probe; it's not proved caused by it.

First record: bad2300d0,RA24aa94,a0=1666710,v1=624f78,v0=2300d0.
Compiled caller FUN_0024a860 at24aa8c makes a virtual call via object+18,
table+10. Target2300d0 is absent from register_functions.partial.cpp and the
Ghidra function catalog (previous function ends2300d0, next begins2300d8).
ELF32 program-header mapping of extracted_iso/SLUS_213.55 gives:

```
002300d0: 03e00008  # jr ra
002300d4: 00000000  # nop (delay slot)
002300d8: 27bdfff0  # next function prologue
```

This first target is a legitimate empty function, not an invalid guest address.
Fallback-to-RA may happen to reproduce its no-op behavior; do NOT claim this
particular omission causes the later recoveries or slow boot. Later unregistered
targets include5b9990,5b9998,5b94f0,5b94f8 and5c3a48 and need their own audit.

Next bounded implementation: recover the exact missing function entries from
ELF evidence and registration, then repeat a comparable run and check whether
fallbacks disappear. Do not add blanket return stubs for unknown destinations.
Main-wait/worker profiling remains useful, but runtime-path integrity is now a
gate for menu acceptance. No menu accepted and no speedup claimed in this lot.
