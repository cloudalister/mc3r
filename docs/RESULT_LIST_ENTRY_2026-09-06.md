# Restore42b150 and exercise42bf00 nonempty paths - 2026-09-06

## Scope

Previous rootc474611/runtimef4c0f40. Missing42b150 was the first failure after
reconnecting42bf00. It is a real29-instruction body, not a no-op or zero stub.
New tracked header runtime/mc3_verified_list.h implements each instruction with
guest register/memory semantics, exact branch destinations and delay slots.
No scheduler/token/network changes; no math-library changes.

The routine reads global618d04, walks the chain starting at [argument+0],
decrements [argument+18] as entries are consumed, advances the head, and returns
a selected node or zero. A nonzero node+10 forces the skip comparison to zero;
otherwise it compares the unsigned scalar result of global minus node+0c with2.
Do not replace this with an assumed high-level timestamp policy: subtraction
wrap/sign extension and unsigned comparison are part of the actual contract.

Critical raw words/targets independently checked:

- 42b15c=8c468d04: a2 loads from v0-72fc, not a0.
- 42b184=14400004: target42b198, not42b19c.
- 42b188=0060202d: a0=v1 (delay slot).
- 42b194=00c21023: v0=a2-v0, scalar32 result sign-extended.
- 42b1a0=5440ffef: BNEL target42b160, taken slot loads v0=[a1+18].
- 42b1bc returns RA while its delay slot stores the new head.

The initial read-only prose decoding contained register/branch errors; it was
not used as implementation authority. Raw ELF field decoding and the separate
test interpreter below were used to verify the implementation.

## Reproduction and provenance

Ignored owner work/generated/ghidra/FUN_0042b140_0x42b140.cpp now includes
runtime/mc3_verified_list.h, has initial switch case
`case 0x42b150u: goto label_42b150;`, and after the original final pc assignment:

```cpp
    return;
label_42b150:
    mc3Verified42b150(rdram,ctx,runtime);
    return;
```

Original42b140 body remains unchanged. New owner source SHA256:
06a175a21099da582270618a2450b4ee970714aacf6f4f6125f0ef573b82c4d4.
Manifest updated after successful compilation. Owner object is in batch0036.
Partial register regenerated and verified:42b150 ->FUN_0042b140_0x42b140.
168394 internal aliases,15831 top-level registrations (NOT gameplay coverage).

## Tests

-322/322 runtime tests passed after library rebuild.
-37 native generated-entry cases passed: previous11, plus24 independent
  comparisons against a small opcode interpreter reading the retail ELF, plus
  two actual nested42bf00 -> registered42b150 paths (null/non-null return).
-Reference cases cover status0/1/2/ffffffff, deltas0/1/2/100/ffffffff/80000000,
  mixed chains, all128 bits of every GPR, all RAM writes, PC and final branch
  state. The oracle uses decoded instruction fields, not the helper formulas.
-Nested tests verify count/head updates and restored SP/RA/callee saves. Node
  flags are zero in the pointer-return case; other42bf00 cleanup paths are not
  newly covered. Fail-fast sentinels remain test-only, never game-linked.
-Verify-EntryBatch.js requires all29 annotations and matches them to ELF bytes,
  checks source dispatch hooks and actual generated registration.
-The first compile-script attempt caught a missing array separator before any
  game relink; corrected and rerun successfully. No failed build was measured.

Opt-in MC3_WAIT_PROFILE emits entry42b150Calls from the existing host snapshot.
The counter counts invocations only, not time or returned items.

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Test-EntryBatch.ps1
rtk proxy node tools/Generate-PartialRegister.js
rtk proxy node tools/Verify-EntryBatch.js --register
rtk proxy cmd /c <project-root>\10_link_partial_runner.bat fast
```

## Boot probe

list_entry_astra_20260906 started06:13:35,600s, headless, quiet+wait+callback.
No builds/tests compete with the run. Same probe settings as the previous lot;
not a repeated performance A/B.

Exe06:12:59, newer than registration object06:12:45, owner06:12:05 and
library06:11:41. The running binary emits the new entry42b150Calls field.

-Exe SHA256:fcdf01cd2cfb85b6949550cc712088d874f2dc1d532cb62c7e847698fec3147f
-Lib SHA256:90d768bde32a49a65c0ab03643399b40322fc617a9719032999503c7a19279dd

Completed06:23:37,wall600.8718s,CPU291.609375s (user200.59375,kernel91.015625).
No early exit; harness stopped its process at the limit. No MC3 remains running.

-Final entry42b150Calls=0, as are previous verified-leaf counters. **The boot
  probe did NOT exercise the new body.** Do not report runtime repair acceptance.
-Zero bad-target records, but this is NOT proof the missing-call chain is fixed:
  execution stopped earlier than that workload.
-Only2 frontend initialization writes, last0->0 at322428,timer0. No animation
  update, screenshot/menu/FPS acceptance. This run is not performance A/B.
-Initial SID256 wait (dispatch1a5fc0/RA398b28) reached333193ms then returned.
-Later SID21 wait remained at the final sample:218843ms, WaitSema entry5469e0,
  RA5476b0, dispatch322ffc, phasecv-wait, tokenWaitMs0, owner8. The owner sample
  alone does not prove that thread8 causes the missing wake.
-Static source sub_00547608 shows alarm setup through54d6a0, then WaitSema at
  5476a8, return5476b0 and DeleteSema afterward. Existing MC3_TIMER2_TRACE emits
  wait-enter/usec, alarm-armed and wait-woke. It was NOT enabled in this run.

Evidence: work/logs/probe_list_entry_astra_20260906.log.stderr, .stdout, .meta
and .result.json. Closed log analyzed with Analyze-FrontendBoot.ps1.
Runtime implementation commit3fb78c5. No post-probe rebuild/relink: the recorded
exe hash above is the current tested binary.

## Next step

Enable/use the existing MC3_TIMER2_TRACE diagnostics for the wait at5476b0 and
correlate alarm creation, callback delivery and semaphore signaling. Prefer a
bounded diagnostic run over another blind missing-entry repair: the current
boot run never reached those entries. Do not inject a signal or alter scheduler.
The37 native cases validate the implementation in isolation, not boot acceptance.

## Read-only preparation of previously missing neighbors

No changes to these entries in this lot:

-5bb238..5bb258 raw words:
  8c820144 c4400264 e4a00000 8c820144 c4400268 e4a00004
  8c820144 03e00008 c4400270.
  It reloads [a0+144], copies two float words from +264/+268 into [a1]/[a1+4],
  and loads f0 from +270 in the return delay slot. Do NOT invent a third store.
-5bb268:03e00008/24020002, exact return with scalar v0=2 in the delay slot.
-Nearby sub_005BB220 is already a hand-written accessor for220..228 only;
  neither missing entry is implemented by that existing body. Additional
  dispatch hooks alone would not restore their behavior.
