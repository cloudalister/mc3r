# Timer route - user-approved30-minute diagnostic batch

## Starting point

Root4c10693/runtime2af51f7, clean tree. Previous pending SID116/alarm0703e02b
had no callback for36.317s while IRQ worker ticks continued. This does not prove
Timer2 COUNT/MODE/COMP or the guest alarm deadline was correct. This lot observes
those separate stages. No scheduler, timer rate, guest-state or signal changes.

## Instrumentation

runtime/ps2_timer_route_probe.h, existing MC3_TIMER_WAIT_TRACE=1:

- hardware bank: advances,due,inactive,MODE,post-advance COUNT,COMP,reason,time.
  reason1 disabled,2 unsupported clock,0 normal advance. Uses values already
  loaded by the emulator; disabled paths additionally read atomic timer fields.
- cause11 dispatch requests, masked requests and enumerated handler counts.
  Handlers count includes candidates before hasFunction, not completed calls.
- registration bank: only guest TLS1 with active mainSema and handler54d640,
  captures internal entry base,s2 delay,s3 wrapper pointer after54d4a0's store.
  This is configuration, not a claim the alarm has already been inserted/armed.
- selection bank: IRQ-worker-only, just before54ce80's unsigned comparison,
  captures candidate s0, guest time s1, threshold s2 and early=(s1<s2).
  Covers FUN54cda8 and overlapping sub54CD70 owners. No new guest memory reads.
- watchedEntry is a correlation aid; matchedCalls is cumulative across watches,
  not per-alarm. A reused entry can match a stale watch after wake. Correlate
  current mainSema/registration time and existing timer-wait lifecycle records.
- each bank has a single writer in measured normal mode and bounded revision
  reads. Separate banks/counters are NOT one coherent whole-runtime snapshot.
- all printing occurs in the existing five-second reporting path. No printing
  in guest routines or inside the interrupt-handler mutex. No class-layout/ABI
  changes, guest context pointers or cross-thread guest memory snapshots.
- disabled probe leaves game semantics unchanged; overhead is unmeasured.

## Source provenance/reproduction

Generated sources are ignored by Git; preserve them locally. Added only include
runtime/ps2_timer_route_probe.h and these hooks:

- sub_0054D3F8_0x54d3f8: after WRITE32 at54d4a0,
  `configured(g_currentThreadId,GPR_U32(ctx,16),GPR_U64(ctx,18),GPR_U32(ctx,17),GPR_U32(ctx,19))`.
- FUN_0054cda8_0x54cda8 and sub_0054CD70_0x54cd70: immediately before54ce80,
  `compared(GPR_U32(ctx,16),GPR_U64(ctx,17),GPR_U64(ctx,18))`.
  Both calls use namespace ps2_timer_route_probe; no instruction replaced.

Owner SHA256:

- sub54D3F8:73a5aa1d2946d509a0341d037ec06284c9d581e3f5708fc2e0f2b6d884f7bf5a
- FUN54cda8:e06e5db506cebe2ee89bdb413e7604f8862eeff91b016d4b88020e853ab1dec6
- sub54CD70:df29e70f6a708e5e815d7eab3c0a385d78e6760e91001a6de28ce0bf651ec9ae

Verify-IrqList.js extended to accept explicit owners.60/163/177 annotated words
respectively match ELF. Opcode provenance is NOT a complete semantic oracle.
Compile-TimerRouteProbe.ps1 rebuilds those exact batch0054 objects.

326/326 runtime tests passed after build. New test preserves64-bit values in
snapshot bank and rejects an odd publication revision without spinning.

## Measurement

Recovered and analyzed on 2026-09-08. The run completed on 2026-09-06; the
previous turn was interrupted before this report was closed.

Evidence: work/logs/probe_timer_route_astra_20260906.log.{meta,result.json,stderr}.
Wall 601.0235608s, CPU 205.46875s, exitedBeforeLimit=false. Recorded binary
SHA256 60bbabf5691b31a6e57d7b30943480d22f3e9945dae9591a2c49338c5c6d5b00;
library 88ea5f5d755e31633b853fddbe3b9a94868f576aeb01b60ca3584cecb93ff181.
These identify the historical run, not a newly validated current executable.

Read-only reproduction:
`rtk proxy node tools/Analyze-TimerRoute.js work/logs/probe_timer_route_astra_20260906.log.stderr`

Complete standalone records only: 119 hardware, 119 registration,119 selection,
5 armed,4 callbacks,4 wakes. Last alarm SID214/0703e0d3 armed at tMs7827807,
entry00701e00, wrapper00703e00, delay1474560. No subsequent matching callback or
SID214 wake in captured log. Last complete main-wait line9179: cv-wait65023ms.

During that final wait, sampled hardware due/dispatch/handler-candidates grow
14832 ->18659; masked stays0, mode0782, reason0. Timer2 dispatch requests keep
arriving. This is not evidence of a globally stopped timer or masked INTC cause.
It does not establish accurate clock rate or every handler's completion.

Most selection samples concern different entry00701e80 while watched00701e00.
Final complete selection line9184 matches entry00701e00, now88009113600,
threshold88008130560, early0, tMs7895010. matched rises6->270 but is cumulative
across watches, NOT a per-alarm count. Pointer reuse and separate snapshot-bank
timing prevent treating this as conclusive identity of the pending alarm.

## Next bounded causal boundary

Static path: comparison54ce80 -> unlink helper54cd70 via54ce8c -> callback target
loaded at54cec4 from entry+0x28 -> indirect call54ced0 -> return54ced8 -> callback
wrapper54d640 -> existing timer-wait callback/signal records. Both generated
FUN54cda8 and overlapping sub54CD70 owners contain this path.

Next probe should correlate the actual alarm identity, loaded callback target
and arguments immediately before54ced0, plus helper/callback return PCs, with
the existing armed/callback/signal records. Use already-loaded scalar registers,
bounded event history and passive gates. Compare source semantics with the ELF
and exercise return paths in a focused native test before any behavioral fix.

No forced signal, guessed callback, timer-speed change or scheduler-policy fix.
No new runtime edit/build/game launch on 2026-09-08 during recovery. No visual,
FPS, menu or behavioral-fix claim. Log ends with a partial record, excluded.
