# Seven missing entries restored - 2026-09-06

## Scope and original evidence

No scheduler/network changes, no generic missing-call returns. Previous runtime
dd3008d, root719af85. Four exact `jr ra; nop` entries (03e00008/00000000):
5b94f0,5b94f8,5b9990,5b9998. A template helper accepts ONLY those addresses,
preserves guest registers and updates branch metadata/return PC. Opt-in
MC3_WAIT_PROFILE counts each entry separately from the existing host snapshot.

Three other missing entries already have complete generated instruction bodies,
but lacked dispatch cases and labels. This lot adds access to those bodies only:

| Entries | Generated owner | Object batch |
| --- | --- | --- |
| 5b94f0,5b94f8 | FUN_005b9500_0x5b9500 | 0060 |
| 5b9990,5b9998 | FUN_005b9908_0x5b9908 | 0060 |
| 501268,5012c0 | sub_00501088_0x501088 | 0049 |
| 42bf00 | sub_0042BE50_0x42be50 | 0036 |

501268/5012c0 are circle predicates (squared XY distance vs squared radius),
respectively inside-or-boundary and outside. ELF table references file494a04 and
494a08. They must return a computed boolean, not a stale method address.
42bf00 has real stack setup and nested branches/calls; table reference file4923bc.
Its high-level subsystem purpose is not claimed. First words27bdffe0/ffb00000.

Verify-EntryBatch.js checks all annotated instruction words in the four owners
against mapped ELF bytes (20+30+289+163=502 annotations), all seven dispatch
hooks, exact four NOP leaves, and optionally actual partial registrations.
Annotation agreement is not a full interpreter-equivalence proof.

## Validation before boot

- Runtime suite: **322/322 passed**.
- Separate executable links the SAME four generated owner objects used by the
  runner: **11/11 cases passed** (six circle tests: inside, boundary, outside for
  both entries;42bf00 zero-count branch with RA/SP/callee-saved restoration;
  four NOP entry dispatch cases with all GPRs unchanged).
- Unexercised neighboring direct callees have TEST-ONLY abort sentinels. An
  accidental jump there fails the test. These definitions are not linked into
  the game. The initial standalone test link exposed these dependencies; after
  adding fail-fast sentinels it linked and all cases passed. No guessed return
  stubs were added to the runtime.
- Nonzero-count/nested-call branches of42bf00 are not isolated-test coverage.
- Registration regenerated:15831 top-level functions,168393 internal aliases,
  all seven new bindings verified. These counts are NOT gameplay coverage.
- Older2300d0/5c3a48 owners rebuilt after shared header changed.

## Reproduce ignored generated-source changes

All owners are under work/generated/ghidra and remain ignored by git. Preserve
existing bodies and all old aliases. For each entry add to initial ctx->pc switch:
`case 0xENTRYu: goto label_ENTRY;` (lowercase address).

For501268,5012c0,42bf00, add `label_ENTRY:` immediately before the matching
instruction comment. No arithmetic, memory or branch instructions are changed.

For the two NOP owners include `runtime/mc3_verified_leaf.h` after ps2_runtime.h.
After their original last ctx->pc assignment, insert a `return;` to preserve old
fallthrough, followed by both corresponding blocks:

```cpp
label_ENTRY:
    mc3VerifiedNopLeaf<0xENTRYu>(ctx);
    return;
```

Expected source SHA256 values (manifest updated after successful compilation):

- FUN_005b9500:7d5d6a34a91419f2e4f1fc6cde3839dab85cacd25b1bfc02cf8eba80a088089c
- FUN_005b9908:13860ee457bee8f631866e06115def7a5913c752901294e50c1228bab905d439
- sub_00501088:e4cb3c94e09714c7213e5488b66c812d388a3308679d012d85b991b797a63062
- sub_0042BE50:abcc4d5c9a6d3bb639d57bdc2a1ed06ff5e495df1e76d58b59c6f8beb3895f72

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Test-EntryBatch.ps1
rtk proxy node tools/Generate-PartialRegister.js
rtk proxy node tools/Verify-EntryBatch.js --register
rtk proxy cmd /c E:\Games\Emuladores\Sony\mc3recomp\10_link_partial_runner.bat fast
```

## Boot probe

Probe entry_batch_astra_20260906 started05:47:25,600s, quiet+wait+callback,
headless. Same probe settings as zero_return_astra_20260906; no competing
builds/tests while measuring. This is not a repeated performance A/B.

Exe mtime05:46:44 is newer than registry object05:46:26, four owner objects
05:45:13..17, and runtime lib05:42:07. Exact provenance captured by the harness:

- Exe:3ddf8c923ea6da4728fa460fe10b6ee7889a8b5a93b3ff0b5a4af7d455271c56
- Lib:0d4f6a8e72cdce5e85dd18e42a51cac8ee5625c1afbd300f841022dfb3c95620

Read-only review found no concrete defect in the seven bindings, branch hooks,
restricted helpers or isolation of test-only sentinels.
Completed05:57:26: wall601.2495s,CPU287.765625s (user200.15625,kernel87.609375).
No early exit; harness stopped its process at the limit. No MC3 remained running.

- All seven patched targets: zero missing-target records in completed stderr.
- Each of the four NOP leaves executed **12 times** by the final sample.
  Previous zero-return5c3a48 executed2372 times.
- First new missing target **42b150**, RA42bf30. Trace explicitly passes through
  42bf00 before42b150: the restored entry is reached in the actual game, and its
  nonzero branch calls another omitted function. This nested branch was NOT
  included in the isolated zero-count test.
- Exactly256 `[dispatch:recover-pc]` records, at the diagnostic print cap.
  Across all bad-containing records (including the separate first-bad report),
  42b150 appears252 times,5bb268 three times,5bb238 twice. These are printed
  records, not total event counts. Do not claim the chain is now complete.
- Frontend:28 complete writes,13 animation updates, final16 to17 at322e94,
  timer0.428999931. Previous run ended18; neither difference is performance
  evidence. No visual menu/FPS acceptance or current screenshot in quiet mode.
- Initial WaitSema SID9 reached332928ms in the last waiting sample then returned.
  Semaphore IDs vary between runs. That early wait is still not explained by
  the restored late calls.

Evidence: work/logs/probe_entry_batch_astra_20260906.log.stderr, .stdout, .meta
and .result.json. Analyze-FrontendBoot.ps1 was run only after log completion.

After the measured run, Test-EntryBatch.ps1 was rerun to validate its final hidden
launch/30s-timeout wrapper:11 cases passed again; no tests competed with boot.
Its recompilation was followed by a successful final relink at06:01:31 so the
executable is newer than the objects. Final exe size278534032, SHA256:
fd6895c54f4894ed1f8ac22bee3159c76bf66ee4f691f9dbb95a4dd505fb0a9e.
This final relink used unchanged source/object build inputs; the600s evidence
above belongs to the explicitly recorded earlier exe hash, not this new file.
No additional runtime acceptance is inferred from the final relink.

## Next bounded target

Prioritize **42bf00 ->42b150**: inspect real42b150 body and dependencies, restore
the entry and add a nonzero-count42bf00 integration test. Separately audit
5bb238/5bb268 before deciding their semantics. Do not stub them out. The seven
fixes remove confirmed execution gaps but do not by themselves unlock the menu.
