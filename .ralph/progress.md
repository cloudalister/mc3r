# Progress Log

## [2026-08-02 00:27 BRT] - US-010: Write end-of-batch handoff
- Added `docs/HANDOFF_2026-08-02_PROVIDER_BATCH.md` from the verified US-007, US-008, and US-009 evidence.
- Recorded changes, verification, unknowns, Stable PCs, provider values, exact logs, next commands, worktree/artifact state, and the missing visual gameplay acceptance.
- Static link/path checks passed; no runtime/generated code or artifacts were changed, deleted, launched, or committed.

---
Started: sáb,  1 de ago de 2026 23:30:24

## Codebase Patterns
- (add reusable patterns here)

---

## [2026-08-02 00:08 BRT] - US-006: Run controlled probe matrix
Thread: 
Run: 20260801-235839-448 (iteration 2)
Run log: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-235839-448-iter-2.log
Run summary: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-235839-448-iter-2.md
- Guardrails reviewed: yes
- No-commit run: true
- Commit: none - No-commit run; repository metadata is an empty `.git` directory
- Post-commit status: unavailable - Git reports `not a git repository`; run outputs remain in docs, work/boot_probe, work/logs, .ralph/activity.log, and this progress log
- Verification:
  - Command: `$env:MC3_TRACE_PROVIDER='1'; .\15_auto_boot_probe.bat 8 595` -> PASS (`render-started`, Stable PC `0x5a8908`; provider trace and timestamped logs captured)
  - Command: `$env:MC3_TRACE_PROVIDER='1'; .\15_auto_boot_probe.bat 8 req4` -> PASS (`render-started`, Stable PC `0x2455f0`; provider trace and timestamped logs captured)
  - Command: `Remove-Item Env:MC3_TRACE_PROVIDER -ErrorAction SilentlyContinue; .\15_auto_boot_probe.bat 8 595` -> PASS (`render-started`, Stable PC `0x5a8908`; latest status read; zero `[MC3_PROVIDER]` lines)
  - Command: `rg -n "0x5A8908|0x2455F0|0x619F44|0x619F4C|0x618020|0x618024|Negative case|not promoted" docs/PROVIDER_TRACE_MATRIX.md` -> PASS
  - Command: `rg -n "\[MC3_PROVIDER\].*(slot0=0x00617f88|fallback=0x00000000|fallback=0x00715d90|fallback=0x00715dc0)" work/boot_probe/boot_trace_pollsid59c595_20260802_000620.log work/boot_probe/boot_trace_pollsid59c595ret2mode9payload1m3skip5areq4_20260802_000632.log` -> PASS
  - Command: generated object compilation -> NOT APPLICABLE (no generated function/source edited)
  - Command: `10_link_partial_runner.bat` -> NOT APPLICABLE (no code edited; partial runner timestamp remained `2026-08-02 00:03:38`)
- Files changed:
  - docs/PROVIDER_TRACE_MATRIX.md
  - docs/BOOT_PROBE_STATUS.md (final gate-off probe output)
  - work/boot_probe/latest_status.md (final gate-off probe output)
  - work/boot_probe/boot_trace_pollsid59c595_20260802_000620.log
  - work/boot_probe/boot_trace_pollsid59c595ret2mode9payload1m3skip5areq4_20260802_000632.log
  - work/boot_probe/boot_trace_pollsid59c595_20260802_000704.log
  - work/logs/15_auto_boot_probe_20260802_000612.log
  - work/logs/15_auto_boot_probe_20260802_000624.log
  - work/logs/15_auto_boot_probe_20260802_000656.log
  - work/logs/14_run_boot_trace.log (final gate-off probe output)
  - work/logs/14_run_boot_trace.log.stdout (final gate-off probe output)
  - work/logs/14_run_boot_trace.log.stderr (final gate-off probe output)
  - .ralph/activity.log
  - .ralph/progress.md
- Ran the minimum controlled matrix and recorded exact run windows, logs, Stable PCs, backend slots, provider lifecycle state, fallback values, and the unobserved primary value in a standalone report.
- Security review: no source, provider global, handle, semaphore, guest branch, secret, or compatibility behavior was changed.
- Performance review: no runtime code changed; the three bounded eight-second probes add no persistent cost.
- Regression review: the final gate-off default probe remained `render-started` at Stable PC `0x5a8908`, with the existing runner timestamp and no provider telemetry.
- **Learnings for future iterations:**
  - Both modes selected backend pointer `0x617F88`, left flag `0x619F40` zero, and did not reach `0x4F9760`; neither proves a primary provider at `0x619F44`.
  - Req4 moved Stable PC to `0x2455F0` and extended fallback to `0x00715DC0`, but it bundles multiple SIF and control-flow experiments, so it must remain a comparison mode rather than a provider fix.
  - The default mode stopped at `0x5A8908`; the req4 mode stopped at `0x2455F0`; both retained `dma=2 gif=0 gsw=0 vif=3` and the same final `WaitSema(5)` observation.
---

## [2026-08-02 00:05 BRT] - US-005: Validate instrumented runner
Thread: 
Run: 20260801-235839-448 (iteration 1)
Run log: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-235839-448-iter-1.log
Run summary: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-235839-448-iter-1.md
- Guardrails reviewed: yes
- No-commit run: true
- Commit: none - No-commit run; repository metadata is an empty `.git` directory
- Post-commit status: unavailable - Git reports `not a git repository`; scoped objects, runner, probe evidence, checkpoint, and Ralph logs remain in the workspace
- Verification:
  - Command: direct `C:\msys64\ucrt64\bin\g++.exe -std=c++20 -msse4.1 ... -c <source> -o <object>` for the four affected functions in batches 0027 and 0049 -> PASS
  - Command: `.\10_link_partial_runner.bat fast` -> PASS (`mc3_partial.exe` timestamp `2026-08-02 00:03:38 BRT`)
  - Command: `$env:MC3_TRACE_PROVIDER='1'; .\15_auto_boot_probe.bat 8 595` -> PASS (provider lines captured; `render-started`, Stable PC `0x5a8908`)
  - Command: timestamp-only stale-EXE simulation plus `tools/Verify-BootState.ps1 -ExpectedStablePC 0x5a8908` -> PASS (expected verifier exit `1` with `[FAIL] exe-not-stale`; timestamp restored)
  - Command: `Remove-Item Env:MC3_TRACE_PROVIDER -ErrorAction SilentlyContinue; .\15_auto_boot_probe.bat 8 595` -> PASS (zero `[MC3_PROVIDER]` lines; Stable PC unchanged)
  - Command: `tools/Verify-BootState.ps1 -ExpectedStablePC 0x5a8908` -> PASS
  - Command: `rg -n "Stable PC|Backend slot|Fallback|Primary|Last wait|exe-not-stale|MC3_PROVIDER" docs/US005_INSTRUMENTED_RUNNER_CHECKPOINT.md work/logs/US005_stale_executable_negative.log work/boot_probe/boot_trace_pollsid59c595_20260802_000403.log` -> PASS
- Files changed:
  - work/compile/ghidra/batch_0027/obj/sub_003991F0_0x3991f0.o
  - work/compile/ghidra/batch_0049/obj/FUN_004f9760_0x4f9760.o
  - work/compile/ghidra/batch_0049/obj/sub_004F9A68_0x4f9a68.o
  - work/compile/ghidra/batch_0049/obj/sub_004FAED8_0x4faed8.o
  - work/link/partial/mc3_partial.exe
  - work/boot_probe/boot_trace_pollsid59c595_20260802_000403.log
  - work/boot_probe/boot_trace_pollsid59c595_20260802_000412.log
  - work/boot_probe/latest_status.md
  - work/logs/US005_stale_executable_negative.log
  - docs/BOOT_PROBE_STATUS.md
  - docs/US005_INSTRUMENTED_RUNNER_CHECKPOINT.md
  - .ralph/activity.log
  - .ralph/progress.md
- Rebuilt only the four instrumented provider objects, relinked the runner, captured live gated telemetry, proved stale executable detection, verified the default gate-off behavior, and recorded Stable PC, provider/backend values, and the last wait in a standalone checkpoint.
- Security review: no new input surface, secret, direct provider write, fake handle, semaphore injection, or compatibility patch was introduced.
- Performance review: US-005 adds no runtime code; the default probe confirmed the trace gate adds no output when absent.
- Regression review: final default 8/595 behavior remained `render-started` at Stable PC `0x5a8908`, and the final freshness/missing-stub verifier passed.
- **Learnings for future iterations:**
  - The 8/595 path reaches `0x3991F0` and `0x4F9A68`, but not `0x4FAED8` or `0x4F9760`; do not claim the primary provider value from this path.
  - A final probe must follow the final relink, otherwise the freshness gate correctly rejects the older status.
  - `Verify-BootState.ps1` reports a stale executable independently of probe success, providing a safe timestamp-only negative test without deleting objects.
---

## [2026-08-01 23:57 BRT] - US-004: Add provider entry trace
Thread: 
Run: 20260801-235225-1535 (iteration 1)
Run log: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-235225-1535-iter-1.log
Run summary: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-235225-1535-iter-1.md
- Guardrails reviewed: yes
- No-commit run: true
- Commit: none - No-commit run; repository metadata is an empty `.git` directory
- Post-commit status: unavailable - Git reports `not a git repository`; scoped source, documentation, objects, runner, probe outputs, and Ralph logs remain in the workspace
- Verification:
  - Command: `rg -n "MC3_TRACE_PROVIDER|enter=0x(3991f0|4faed8|4f9a68|4f9760)|exit=0x(3991f0|4faed8|4f9a68|4f9760)" work/generated/ghidra/sub_003991F0_0x3991f0.cpp work/generated/ghidra/sub_004FAED8_0x4faed8.cpp work/generated/ghidra/sub_004F9A68_0x4f9a68.cpp work/generated/ghidra/FUN_004f9760_0x4f9760.cpp` -> PASS
  - Command: direct `C:\msys64\ucrt64\bin\g++.exe -std=c++20 -msse4.1 ... -c <source> -o <object>` for each of `0x3991F0`, `0x4F9760`, `0x4F9A68`, and `0x4FAED8` -> PASS (all four objects timestamped 2026-08-01 23:54:24-27 BRT)
  - Command: `.\10_link_partial_runner.bat` -> FAIL (`node` absent from PATH during unnecessary register regeneration; no source failure)
  - Command: `.\10_link_partial_runner.bat fast` -> PASS (`mc3_partial.exe` timestamp advanced from 23:51:19 to 23:55:25 BRT)
  - Command: `Remove-Item Env:MC3_TRACE_PROVIDER -ErrorAction SilentlyContinue; .\15_auto_boot_probe.bat 8 595` -> PASS (`render-started`, Stable PC `0x5a8908`; latest status read; no `[MC3_PROVIDER]` output)
  - Command: `$env:MC3_TRACE_PROVIDER='1'; .\15_auto_boot_probe.bat 8 595` -> PASS (`[MC3_PROVIDER]` live entry/exit lines observed at reached provider points `0x3991F0` and `0x4F9A68`; Stable PC remained `0x5a8908`)
  - Command: `rg -n "WRITE(8|16|32|64)\\([^\\n]*(0x629f44|0x619f44)|MC3_EXPERIMENT|SignalSema" <four edited sources>` -> PASS (no forbidden mutation or compatibility experiment)
- Files changed:
  - work/generated/ghidra/sub_003991F0_0x3991f0.cpp
  - work/generated/ghidra/sub_004FAED8_0x4faed8.cpp
  - work/generated/ghidra/sub_004F9A68_0x4f9a68.cpp
  - work/generated/ghidra/FUN_004f9760_0x4f9760.cpp
  - docs/PROVIDER_ENTRY_TRACE.md
  - docs/BOOT_PROBE_STATUS.md
  - work/compile/ghidra/batch_0027/obj/sub_003991F0_0x3991f0.o
  - work/compile/ghidra/batch_0049/obj/FUN_004f9760_0x4f9760.o
  - work/compile/ghidra/batch_0049/obj/sub_004F9A68_0x4f9a68.o
  - work/compile/ghidra/batch_0049/obj/sub_004FAED8_0x4faed8.o
  - work/link/partial/mc3_partial.exe
  - work/boot_probe/latest_status.md
  - work/boot_probe/boot_trace_pollsid59c595_20260801_235542.log
  - work/boot_probe/boot_trace_pollsid59c595_20260801_235600.log
  - work/logs/14_run_boot_trace.log
  - work/logs/15_auto_boot_probe_20260801_235533.log
  - work/logs/15_auto_boot_probe_20260801_235551.log
  - .ralph/activity.log
  - .ralph/progress.md
- Implemented `MC3_TRACE_PROVIDER`-gated entry/exit telemetry for all four requested provider-chain functions. `0x4F9760` logs primary, fallback, both lifecycle flags, and arguments `a0-a3`; `0x3991F0` logs both backend slots; lifecycle functions log their relevant flags/fallback. The documentation records intent, use, effective addresses, continuation-PC semantics, and the no-behavior-change negative case.
- Security review: trace input is only an environment-presence gate; no guest pointer is dereferenced for string output, no secret is read, and no direct provider write, fake handle, semaphore injection, or compatibility patch was added.
- Performance review: with the gate absent, each invocation adds one environment lookup and a false branch only; formatting and I/O occur only when explicitly enabled.
- Regression review: the default 8/595 probe produced no new trace output and retained `render-started` at Stable PC `0x5a8908`; the gated probe retained the same Stable PC.
- **Learnings for future iterations:**
  - The generated coroutine-style functions can resume at internal PCs, so each trace includes `pc` to distinguish a fresh guest entry from a continuation invocation.
  - The default 8-second path reached `0x3991F0` and `0x4F9A68`, but not `0x4FAED8` or `0x4F9760`; driving those latter live points is US-005 validation work, while their instrumentation and individual compilation are complete here.
  - `10_link_partial_runner.bat fast` is appropriate when replacing objects for symbols already present in existing register/stub manifests; normal regeneration additionally requires `node` on PATH.
---

## [2026-08-01 23:35 BRT] - US-001: Inventory provider global references
Thread: 
Run: 20260801-233210-569 (iteration 1)
Run log: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-233210-569-iter-1.log
Run summary: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-233210-569-iter-1.md
- Guardrails reviewed: yes
- No-commit run: true
- Commit: none - No-commit run; repository metadata is also an empty `.git` directory
- Post-commit status: unavailable - Git reports `not a git repository`; run outputs remain in docs, work/boot_probe, work/logs, .ralph/activity.log, and this progress log
- Verification:
  - Command: `rg -n --glob '*.cpp' '(0x[0-9a-fA-F]{4}(9[fF]40|9[fF]41|9[fF]44|9[fF]4[cC]|9[fF]50)|429494(2528|2529|2532|2540|2544))' work/generated/ghidra` -> PASS
  - Command: `rg -n -i '0x4f9f44' work/generated/ghidra` -> PASS (negative hit is instruction address only and excluded)
  - Command: `cmd.exe /d /c "15_auto_boot_probe.bat 8 595"` -> PASS (`render-started`, Stable PC `0x5a8908`; `latest_status.md` read)
  - Command: generated object compilation -> NOT APPLICABLE (no function/source edited)
  - Command: `10_link_partial_runner.bat` -> NOT APPLICABLE (no code edited)
- Files changed:
  - docs/PROVIDER_GLOBAL_REFERENCE_INVENTORY.md
  - docs/BOOT_PROBE_STATUS.md (boot probe output)
  - work/boot_probe/latest_status.md (boot probe output)
  - work/logs/14_run_boot_trace.log (boot probe output)
  - work/logs/15_auto_boot_probe_20260801_233440.log (boot probe output)
  - .ralph/activity.log
  - .ralph/progress.md
- Implemented a complete static read/write inventory for the five requested globals, with exact guest instruction addresses, generated files, duplicate-rendering classification, host diagnostic reads, and the required false-positive exclusion.
- Security review: documentation-only work introduced no executable input handling, direct global write, fake handle, semaphore injection, secret, or compatibility patch.
- Performance review: no runtime code changed; probe behavior and runtime cost are unchanged.
- Regression review: mandatory default env-gate behavior remains untouched; the 8/595 probe passed with Stable PC `0x5a8908`.
- **Learnings for future iterations:**
  - The requested `0x629Fxx` spelling comes from opcode text; effective addresses are `0x619Fxx` because `lui 0x62` plus signed `0x9Fxx` offsets crosses below `0x620000`.
  - `0x619F44` has one guest read and one address-forming reference, but no guest load/store writer in the generated corpus.
  - Combined and split generated files duplicate some instruction addresses; count unique guest PCs, not file hits.
  - `0x4F9F44` exists as an instruction PC for `xori` and is the required negative case, not a provider-global reference.
---

## [2026-08-01 23:40 BRT] - US-002: Map backend table and indirect calls
Thread: 
Run: 20260801-233615-1390 (iteration 1)
Run log: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-233615-1390-iter-1.log
Run summary: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-233615-1390-iter-1.md
- Guardrails reviewed: yes
- No-commit run: true
- Commit: none - No-commit run; repository metadata is not usable by Git
- Post-commit status: unavailable - Git reports `not a git repository`; run outputs remain in docs, work/boot_probe, work/logs, .ralph/activity.log, and this progress log
- Verification:
  - Command: `rg -n "0x39920[cC]|0x39921[cC]|0x399224|0x399228|0x399230|0x399234|0x399248|0x399254|0x399268|0x39926[cC]|0x399288" work/generated/ghidra/sub_003991F0_0x3991f0.cpp` -> PASS
  - Command: `rg -n -m 6 "provider_slot=0x618020 provider=(0x617f88|0x619f58).*method=(0x398830|0x4f9760)" work/boot_probe/boot_trace_pollsid59c595ret2mode9payload1m3skip5a_20260710_111442.log` -> PASS
  - Command: `Test-Path` for every generated evidence file named by the report -> PASS
  - Command: `.\15_auto_boot_probe.bat 8 595` -> PASS (`render-started`, Stable PC `0x5a8908`; `work/boot_probe/latest_status.md` read)
  - Command: generated object compilation -> NOT APPLICABLE (no generated function/source edited)
  - Command: `10_link_partial_runner.bat` -> NOT APPLICABLE (no code edited; partial runner timestamp remained `2026-08-01 23:27:42`)
- Files changed:
  - docs/BACKEND_TABLE_0x3991F0.md
  - docs/BOOT_PROBE_STATUS.md (boot probe output)
  - work/boot_probe/latest_status.md (boot probe output)
  - work/logs/14_run_boot_trace.log (boot probe output)
  - work/logs/15_auto_boot_probe_20260801_233930.log (boot probe output)
  - .ralph/activity.log
  - .ralph/progress.md
- Implemented a standalone map of both selectable pointer slots (`0x618020` and `0x618024`), all three indirect calls in `0x3991F0`, the direct post-lookup tracking call, and the two runtime-proven slot-zero targets without assigning unsupported constructor semantics.
- Security review: documentation-only work introduced no executable input handling, direct write to `0x619F44`/requested `0x629F44`, fake handle, semaphore injection, secret, or compatibility patch.
- Performance review: no runtime code changed; the report adds no runtime cost.
- Regression review: default probe behavior and all env-gates are unchanged; the required 8/595 probe passed at Stable PC `0x5a8908`.
- **Learnings for future iterations:**
  - `0x618020` and `0x618024` are selectable provider-pointer slots; method offsets are read from the selected pointee.
  - `0x618020` has runtime-proven slot-zero targets `0x398830` through `0x617F88` and `0x4F9760` through `0x619F58`.
  - The other `jalr` targets (`0x711D40` callback and provider slot `+0x14`) remain unknown; current trace has a null callback, and no captured run selects `0x618024`.
  - `0x399098` is a direct tracking-pool call after a successful lookup, not another indirect backend target.
---

## [2026-08-01 23:45 BRT] - US-003: Map provider lifecycle flags
Thread: 
Run: 20260801-233615-1390 (iteration 2)
Run log: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-233615-1390-iter-2.log
Run summary: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260801-233615-1390-iter-2.md
- Guardrails reviewed: yes
- No-commit run: true
- Commit: none - No-commit run; repository metadata is an empty `.git` directory
- Post-commit status: unavailable - Git reports `not a git repository`; run outputs remain in docs, work/boot_probe, work/logs, .ralph/activity.log, and this progress log
- Verification:
  - Command: `rg -n -C 3 '0x4fa940|0x4faa04|0x4faaa0|0x4faaa4|0x4faee8|0x4faef0|0x4faefc|0x4faf00|0x4f9a74|0x4f9a8c|0x4fb05c' work/generated/ghidra/FUN_004fa7a8_0x4fa7a8.cpp work/generated/ghidra/FUN_004faa10_0x4faa10.cpp work/generated/ghidra/sub_004FAED8_0x4faed8.cpp work/generated/ghidra/sub_004F9A68_0x4f9a68.cpp` -> PASS
  - Command: `rg -n '0x4F9A68|0x4FAA10|0x4FA7A8|0x4FAED8|Negative case|No generated source' docs/PROVIDER_LIFECYCLE_FLAGS.md` -> PASS
  - Command: `.\15_auto_boot_probe.bat 8 595` -> PASS (`render-started`, Stable PC `0x5a8908`; `work/boot_probe/latest_status.md` read)
  - Command: generated object compilation -> NOT APPLICABLE (no generated function/source edited)
  - Command: `10_link_partial_runner.bat` -> NOT APPLICABLE (no code edited; partial runner timestamp remained `2026-08-01 23:27:42`)
- Files changed:
  - docs/PROVIDER_LIFECYCLE_FLAGS.md
  - docs/BOOT_PROBE_STATUS.md (boot probe output)
  - work/boot_probe/latest_status.md (boot probe output)
  - work/boot_probe/boot_trace_pollsid59c595_20260801_234427.log (timed wrapper attempt output)
  - work/boot_probe/boot_trace_pollsid59c595_20260801_234437.log (successful boot probe output)
  - work/logs/14_run_boot_trace.log (boot probe output)
  - work/logs/14_run_boot_trace.log.stdout (boot probe output)
  - work/logs/14_run_boot_trace.log.stderr (boot probe output)
  - work/logs/15_auto_boot_probe_20260801_234418.log (timed wrapper attempt output)
  - work/logs/15_auto_boot_probe_20260801_234428.log (successful boot probe output)
  - .ralph/activity.log
  - .ralph/progress.md
- Implemented an exact lifecycle map for `0x4F9A68`, `0x4FAA10`, `0x4FA7A8`, and `0x4FAED8`, covering flag reads/writes, controlling branches, return values, initialization order, effective `0x619Fxx` addresses, and the required negative case.
- Security review: documentation-only work introduced no executable input handling, direct write to `0x619F44`/requested `0x629F44`, fake handle, semaphore injection, secret, or compatibility patch.
- Performance review: no runtime code changed; the report adds no runtime cost.
- Regression review: generated sources and env-gates are unchanged; the required 8/595 probe passed at Stable PC `0x5a8908` with the existing partial runner timestamp.
- **Learnings for future iterations:**
  - `0x4FAED8` reads `0x619F40` first and reads `0x619F41` only when the first flag is nonzero; the pair selects among three local request-building paths.
  - `0x4FA7A8` writes `0x619F41 = 1` in a branch delay slot and always writes `0x619F40 = 1` before returning its built result.
  - `0x4FAA10` writes both flags only on its recognized-format path and returns `1`; those writes publish package-layout state, not the primary provider pointer.
  - `0x4F9A68` returns the inserted node pointer and only updates the fallback chain at `0x619F4C`.
---

## [2026-08-02 00:13 BRT] - US-007: Compare PCSX2 provider snapshot
Thread: 
Run: 20260802-000955-1401 (iteration 1)
Run log: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260802-000955-1401-iter-1.log
Run summary: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260802-000955-1401-iter-1.md
- Guardrails reviewed: yes
- No-commit run: true
- Commit: none - No-commit run; Git reports the repo root is not a repository
- Post-commit status: unavailable - Git reports `not a git repository`; remaining run files are listed below
- Verification:
  - Command: `Select-String -Path docs/SESSION_2026-07-10_PCXS2_MCP_SID44.md,docs/PROVIDER_TRACE_MATRIX.md,work/boot_probe/boot_trace_pollsid59c595ret2mode9payload1m3skip5a_20260710_111442.log -Pattern '0x618020|0x619f58|0x4f9760|0x629f44|0x629f4c|backend_open=0x3984c0'` -> PASS
  - Command: `Select-String -Path docs/PCSX2_PROVIDER_SNAPSHOT_COMPARISON.md -Pattern '0x618020','0x619F58','0x619F44','0x619F4C','timestamps and hashes','Values still requiring live PCSX2 capture'` -> PASS
  - Command: `cmd.exe /d /c "call 15_auto_boot_probe.bat 8 595"` -> PASS (`render-started`, Stable PC `0x5a8908`; `work/boot_probe/latest_status.md` read)
  - Command: `Select-String` newest default trace for `\[MC3_PROVIDER\]` -> PASS (no matches with `MC3_TRACE_PROVIDER` absent)
  - Command: generated object compilation -> NOT APPLICABLE (no generated function/source edited)
  - Command: `10_link_partial_runner.bat` -> NOT APPLICABLE (no code edited; partial runner timestamp remained `2026-08-02 00:03:38`)
- Files changed:
  - docs/PCSX2_PROVIDER_SNAPSHOT_COMPARISON.md
  - docs/BOOT_PROBE_STATUS.md (boot probe output)
  - work/boot_probe/latest_status.md (boot probe output)
  - work/boot_probe/boot_trace_pollsid59c595_20260802_001205.log (boot probe output)
  - work/logs/14_run_boot_trace.log (boot probe output)
  - work/logs/14_run_boot_trace.log.stdout (boot probe output)
  - work/logs/14_run_boot_trace.log.stderr (boot probe output)
  - work/logs/15_auto_boot_probe_20260802_001157.log (boot probe output)
  - .ralph/activity.log
  - .ralph/progress.md
- Implemented a standalone comparison proving that PCSX2 and the native runner share `0x618020 -> 0x619F58 -> 0x4F9760` and the six low-level backend entries, while separating the unproven primary/fallback contents and open outcome.
- Security review: documentation-only work introduced no secret, executable input path, direct provider write, fake handle, semaphore injection, or compatibility patch.
- Performance review: no runtime code changed; the report adds no runtime cost.
- Regression review: the default 8/595 probe remained `render-started` at Stable PC `0x5a8908`, and the gate-off trace contained no provider telemetry.
- **Learnings for future iterations:**
  - Backend registration already matches the live PCSX2 snapshot; the evidence gap is package-provider population/content.
  - PCSX2 captured non-null primary `0x629F44=0x5C0C40` and fallback `0x629F4C=0x41F9B0`, but lost the connection before the open return and node-content capture.
  - Current native `595`/`req4` traces prove fallback allocation but do not reach `0x4F9760`, so they cannot claim a primary value.
  - Timestamps, hashes, counters, and matching addresses are provenance/structural evidence, not gameplay equivalence.
---

## [2026-08-02 00:19 BRT] - US-008: Select one minimal compatibility experiment
Thread: 
Run: 20260802-001534-925 (iteration 1)
Run log: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260802-001534-925-iter-1.log
Run summary: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260802-001534-925-iter-1.md
- Guardrails reviewed: yes
- No-commit run: true
- Commit: none - No-commit run; repository metadata is an empty `.git` directory
- Post-commit status: unavailable - Git reports `not a git repository`; remaining run files are listed below
- Verification:
  - Command: `rg -n "request=0xFF payload=0x700DC0 size=8|0x711D40|4FAA10" docs/SESSION_2026-08-01_BATCH_CONTINUATION.md` -> PASS
  - Command: `rg -n "req4|0x619F40=0|0x4F9760" docs/PROVIDER_TRACE_MATRIX.md` -> PASS
  - Command: `rg -n "0x618020|0x619F58|0x4F9760|0x629F44" docs/PCSX2_PROVIDER_SNAPSHOT_COMPARISON.md` -> PASS
  - Command: `rg -n "MC3_EXPERIMENT_PROVIDER_INIT_RESPONSE|WRITE32\(0x700DC0, 1\)|fake file handle|SignalSema|replace-all" docs/US008_MINIMAL_PROVIDER_COMPAT_EXPERIMENT.md` -> PASS
  - Command: `cmd.exe /d /c "call 15_auto_boot_probe.bat 8 595"` -> PASS (`render-started`, Stable PC `0x5a8908`; `work/boot_probe/latest_status.md` read)
  - Command: generated object compilation -> NOT APPLICABLE (no generated function/source edited)
  - Command: `10_link_partial_runner.bat` -> NOT APPLICABLE (no code edited; partial runner timestamp remained `2026-08-02 00:03:38`)
- Files changed:
  - docs/US008_MINIMAL_PROVIDER_COMPAT_EXPERIMENT.md
  - docs/BOOT_PROBE_STATUS.md (boot probe output)
  - work/boot_probe/latest_status.md (boot probe output)
  - work/boot_probe/boot_trace_pollsid59c595_20260802_001921.log (boot probe output)
  - work/logs/14_run_boot_trace.log (boot probe output)
  - work/logs/14_run_boot_trace.log.stdout (boot probe output)
  - work/logs/14_run_boot_trace.log.stderr (boot probe output)
  - work/logs/15_auto_boot_probe_20260802_001913.log (boot probe output)
  - .ralph/activity.log
  - .ralph/progress.md
- Selected one ranked, reversible experiment: under `MC3_EXPERIMENT_PROVIDER_INIT_RESPONSE=1`, change only the first response word for observed request `0xFF`, payload `0x700DC0`, size `8`, from zero/default to `1`; require the existing trace to prove `0x4FAA10`, `0x619F40=1`, and `0x618020 -> 0x619F58 -> 0x4F9760` before retaining it.
- No experiment was implemented. Rollback, gate-off default behavior, exact target functions/files, expected evidence, and rejection of fake handles, semaphore injection, broad `req4`, callback override, and replace-all changes are documented.
- Security review: documentation-only selection introduced no executable input handling, secret, provider-pointer write, fake handle, semaphore injection, or permanent compatibility patch.
- Performance review: no runtime code changed; the report adds no runtime cost.
- Regression review: default gate-off 8/595 behavior remained `render-started` at Stable PC `0x5a8908`; the runner timestamp did not change.
- **Learnings for future iterations:**
  - Request `0xFF`, payload `0x700DC0`, size `8` is the narrowest observed unmodelled response tied to the provider setup investigation.
  - Response value `1` remains an explicitly falsifiable compatibility hypothesis, not a captured PCSX2 value.
  - A later Stable PC alone is insufficient; the experiment must reach `0x4FAA10`, publish `0x619F40`, and select the package provider chain.
---
