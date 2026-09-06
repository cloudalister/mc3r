# Exact zero-return entry 5c3a48 — 2026-09-06

## Correction

ELF32-mapped bytes at5c3a48 are03e00008/0000102d: `jr ra` followed by
`daddu v0,zero,zero` in the delay slot. The previous missing-target fallback
returned without this write. This lot restores the actual instruction semantics,
not a generic stub or a guess at the high-level function's meaning.

`runtime/mc3_verified_leaf.h` now has mc3VerifiedLeaf5c3a48: capture RA, zero the
low64 bits of v0 while preserving upper64, set branch metadata and return PC.
The implementation matches SET_GPR_U64/Ps2SetGprLow64 behavior. Other GPRs,
including SP/RA, remain unchanged. The earlier2300d0 leaf remains unchanged.

Ignored generated owner `work/generated/ghidra/FUN_005c3a68_0x5c3a68.cpp`:

- Include `runtime/mc3_verified_leaf.h` after ps2_runtime.h.
- Entry switch: `case 0x5c3a48u: goto label_5c3a48;`.
- After final `ctx->pc = 0x5C3AB8u;`, append:

```cpp
    return;
label_5c3a48:
    mc3VerifiedLeaf5c3a48(ctx);
    return;
```

The first return preserves the neighboring function's old fallthrough behavior.
Compile-VerifiedLeaf.ps1 now allows ONLY2300d0 or5c3a48 and checks each exact
delay instruction in the real ELF before compiling its owner. Both owners were
rebuilt because their shared header changed. Manifest hash for5c3a68 source:
aa047d34ddb56d7d20c0bc322fea469f73b67d19c047269b70a59148ad11ea12.
Generate-PartialRegister.js regenerated168386 aliases; actual line195336 maps
5c3a48 to FUN_005c3a68. No other missing targets were implemented.

## Validation and observability

321/321 tests passed after successful build. New test seeds a nonzero128-bit
v0 and verifies low64 zero, upper64 unchanged, other GPRs and RA/SP preserved,
correct return PC and delay-slot completion. Initial test compile caught the
existing GPR_U64 macro's argument-parenthesization requirement; fixed the test
call and rebuilt before counting any test result.

Opt-in MC3_WAIT_PROFILE adds a relaxed atomic entry count, emitted from the
existing host main-wait snapshot as leaf5c3a48Calls. No guest-path printing, new
locks, token or scheduler changes. The counter proves entry execution rather
than relying solely on absence of a missing-target warning. This is diagnostics,
not a performance A/B. High-level purpose/table ownership is not inferred here.

Read-only review confirmed both partial-register bindings, the preserved old
entry paths and scalar upper64 semantics. No extra concurrent tests were run.

Relink04:40:20, newer than registry object04:39:53, owner04:39:14 and
runtime library04:39:10. objdump confirms5c3a48 branch in the actual owner object.
Probe `zero_return_astra_20260906`,600s, started04:40:42, quiet+wait+callback.
Exe SHA256 `dae4c506b5bd036c4bce977c258ec74a73b9cb0f12364c01ca9bdece02455fcb`.
Lib SHA256 `c1bda68225543266df6ed6a3030b7ab9b419ca002ab4dc736c076372d4f6d261`.
No builds/tests competed with this run. Completed results follow below.
No menu/FPS acceptance.

## Consumer explains the semantic impact

Compiled `FUN_0038cf40_0x38cf40.cpp`:38cfb8 loads v0 from object-table+4c,
38cfbc calls it, return38cfc4;38cfc8 tests v0 for zero. If nonzero,38cfd0
reads from v0+0xc as an object pointer. The prior recovery with bad5c3a48,
RA38cfc4 leaves the method address in v0, so that path can read code bytes as
object data. Returning the original zero instead takes the null branch and
avoids that read. This is a concrete contract correction; it does not by itself
prove faster boot or that other missing calls are harmless.

## Completed runtime probe

Ended 04:50:44 after 601.078 seconds of wall time; CPU 272.219 seconds
(user 195.688, kernel 76.531). No early exit; harness stopped the process at
the configured limit. No MC3 process remained after completion.

- Last sampled leaf5c3a48Calls: **2372**. The corrected entry really executed.
- Zero `bad=0x5c3a48` occurrences in the completed stderr.
- 256 recovery-containing lines hit the print cap; this is NOT the total
  number of recoveries. First missing target remains 5b9990 (RA24aa6c).
  Other observed unresolved targets include 5012c0 (RA21be5c) and
  501268 (RA21bea0). They were not patched in this lot.
- Frontend analyzer: 30 complete writes, including 14 animation updates;
  last position 17 to18, writer322e94, timer0.461999923.
- Quiet mode has no position samples/cap samples or visual acceptance.
  No menu or FPS improvement is demonstrated. Comparing position18 here
  with13 in the previous single run is not a controlled speed measurement.

Evidence: work/logs/probe_zero_return_astra_20260906.log.stderr and
the matching .stdout, .meta and .result.json files. Reproduce with:

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools\Probe-FrontendWrites.ps1 -Seconds 600 -Label zero_return_astra_20260906_repeat -QuietBootTrace -TraceWait -TraceNetCallback
```

Next: audit a bounded batch of remaining missing entries, including 501268,
5012c0 and previously observed 42bf00; inspect real instructions and callers
before implementation. Batch only independently verified semantics, never
blanket return stubs. Preserve scheduler/network behavior while fixing these
execution-contract gaps.
