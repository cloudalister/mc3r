# VIF/VU input contract - Astra, 2026-09-05

## Starting point

Root e1cd8ec / runtime721a97b. FSAND already fixed. Last901s boot still black,
82 budget hits; first8 hits at VU entry0x60, codeFNV a57d6e03, ITOP338.
Final data header0x1520 was zero; final data alone did not prove entry contents.

## Primary reference and contract

[PCSX2 Vif_Codes.cpp](https://github.com/PCSX2/pcsx2/blob/master/pcsx2/Vif_Codes.cpp#L67-L103),
consulted2026-09-05: a kick latches ITOPS into ITOP and TOPS into TOP **before**
changing DBF/next TOPS. The ITOP command writes ITOPS; BASE writes only BASE;
OFFSET preserves BASE, clears DBF and resets TOPS to BASE.
[XTOP/XITOP](https://github.com/PCSX2/pcsx2/blob/master/pcsx2/VUops.cpp#L1798-L1806)
read different latched values. No PCSX2 implementation code was imported.

Existing local tests encoded the reverse ITOP latch and wrong BASE/OFFSET behavior.
They were corrected against the reference, not weakened to hide failures.

## Passive input capture

`MC3_VU1_INPUT_TRACE=1` filters entry0x60 with lower word4000002c, bounded8 events.
VIF logs TOP/TOPS/ITOP/ITOPS/BASE/OFST/DBF before the kick. VU logs the post-kick
values and supplied ITOP, then optionally saves full code/data/initialVUstate/VIF.
`MC3_VU1_INPUT_DUMP=<unique-prefix>` uses exclusive creation, no overwrite.
These are native-layout, local snapshots, not portable save states.

`tools/Probe-FrontendWrites.ps1 -TraceVuInput -TraceVuBudget` enables both captures.
Baseline `vif_input_before_astra_20260905` started20:39:14, old semantics unchanged.
Its metadata records binary hashes. Tests/builds ran concurrently early in this
diagnostic capture; this is not a timing benchmark.

## Red/green plan and implementation

Before correction: **315 tests,311 passed,4 failed**, log
`work/logs/vif_inputs_red_20260905.log`. Failures are the two corrected VIF contract
tests, separate XTOP/XITOP on execute/resume, and real UNPACK->MSCAL->XTOP->ILW
header selection. The old test executable is preserved locally as
`work/scratch/ps2x_tests_vif_before.exe`.

Changes are limited to VIF register semantics and VU's latched TOP source.
VU1State's unused uint32 xitop was renamed top without changing layout/size.
TOP is snapshotted through the existing PS2Memory parameter on execute/resume;
the callback ABI remains unchanged. Scheduler, budget and GS are untouched.

An optional test reads local snapshots via `MC3_VU1_REPLAY_PREFIX` (prefix ending
in `_0`, without extension). `MC3_VU1_REPLAY_TOP` selects an explicitly observed
TOP for a counterfactual replay; `MC3_VU1_REPLAY_EXPECT_END=1` requires E-bit and
cycles<65536. Otherwise it requires the capped baseline. Only PATH1 packet counts
are collected; missing GS state means this validates VU control flow, not graphics
or a whole-system deterministic replay. The saved TOP slot is refreshed on
execute, so old captures can be compared using their recorded VIF/input values.

Green suite after correction: **316/316**, `work/logs/vif_inputs_green_20260905.log`.
That count includes the optional replay case, which had no snapshot selected yet.
The four discriminating cases now pass. The read-only economic reviewer checked
the diff against the primary reference; no scheduler or layout change was found.

## Real input proof

All eight input snapshots saved successfully (code16384, data16384, state640, vif92
bytes each). Case0 BEFORE kick: TOP0, TOPS48, ITOP338, ITOPS338, BASE48, OFST429,
DBF0. AFTER the old kick: TOP0, TOPS477, ITOP338; the VU was supplied338.
Initial header at qword48/byte0x300 is14 in every lane. Header at qword338/0x1520
is zero. Thus the zero read was the wrong address, not a missing intended header.

Old test executable replay, exact initial snapshot: **65536 cycles, E-bit0,
finalPC0398, VI4=0x152, VI5=0xfffffd76,1974 PATH1 packets**. It reproduces the
runtime final state. The old suite intentionally has four red contract tests;
the replay itself passes its budget-exhaustion assertion (312/316 overall).

Corrected replay of the SAME snapshot, with TOP48 observed before the original
kick: **934 cycles, E-bit1, finalPC0420, VI4=VI5=48,28 packets**, **316/316**.
Only the input TOP selection was changed for this counterfactual replay, not RAM,
guest instructions, budget, or a forced exit. This establishes the mechanism.

`tools/Replay-VuInputs.ps1` derives each TOP from the complete before-kick record.
All eight snapshots ended before budget; full **316/316** suite passed for each.
Cycles in order:934,1660,1198,2056,76,142,934,1726. Logs:
`work/logs/replay_vif_top_fixed_v3_20260905_*.stdout/.stderr`.
Two preliminary wrapper runs falsely reported failure before asynchronous output
was drained; logs show316/316. The wrapper now calls parameterless WaitForExit
after the bounded wait so redirected output is complete before validation.

Baseline was stopped deliberately after all captures, own PID23912 identity checked,
20:50:42.702. Live CPU396.015625s (211.84375user,184.171875kernel). Harness wall692s,
27 caps,75.505.404 VU cycles, animation max8. Its exit flag reflects this external
experimental stop, not a spontaneous crash; post-exit CPU is unavailable there.

## Corrected boot

Relink completed; exe20:51:49 newer than lib20:43:27. New input/budget strings
verified in executable. `vif_top_fixed_astra_20260905` ran with a900s limit and the same
headless/default-scheduler/START settings; metadata records hashes.

Completed at21:08:14, wall901.5107757s, stopped by the harness at its configured
limit (not a spontaneous exit). No MC3 process remained. Runtime commit031f584.

| Observed total | Previous FSAND-fixed run | This TOP-fixed run |
|---|---:|---:|
| Wall time | 901s | 901.51s |
| VU budget hits | 82 | **0** |
| VU cycles | 89,339,312 | 84,058,184 |
| Animation last/max | 18 | 18 |
| Complete frontend write events / Updates | 30 /14 | 30 /14 |
| GS primitives | 1,099,186 | 940,100 |
| GS pixels | 851,848,298 | 416,127,888 |
| Process CPU seconds | 450.40625 | 426.359375 |

The corrected run has540 complete counter blocks, none with a nonzero budget-hit
count;534 complete position blocks, zero observed regressions. Last animation
write: object16d5ec0, slot10, position18, timer0.461999923, length119. CPU splits:
218.78125s user,207.578125s kernel. No tests or compilation competed with this run.

These are sampled totals, not an exclusive wall-time partition or an FPS A/B.
The same animation progress does **not** establish a speed improvement. Lower
primitive/pixel totals can follow removal of invalid extra packets: the isolated
case went from1974 packets to28. Do not equate less rendered work with faster
correct frames or claim that this explains all remaining time.

Executable SHA256:
`98e5f0bfcc591d4118c9614597f178fffc0e58949172901bebc602b1090c9008`.
Runtime library SHA256:
`4ec7728d7d6cf7e789fa74628765c70977af85a9131f389ab1574676bec87f5c`.
Raw evidence: `work/logs/probe_vif_top_fixed_astra_20260905.log.stderr`, `.meta`,
`.result.json`. Full input snapshots: `work/captures/vuinput_vif_top_fixed_astra_20260905_*`.

At21:03, all eight matching input calls had also been captured by the corrected
full runner. Each post-kick TOP equals the corresponding pre-kick TOPS (48,
except case3 at477), while ITOP stays338. This verifies that the relinked runner
actually uses the corrected latch, not merely the isolated test executable.
The presentation and context0 one-shot PNGs at700000 primitives were inspected
and are black. That early snapshot does not establish the later frame contents.

The probe now accepts `-FrameDumpMinPrims` (default unchanged700000) so a future
labeled run can inspect later work. PowerShell syntax and rejection of zero and
negative thresholds passed; a later-threshold boot has not been run in this lot.

## Conclusion and next bounded experiment

**Functional correction verified; boot/menu and visual acceptance remain open.**
The input-selection defect is reproduced with old semantics, eliminated with the
correct semantics, and the actual runner now performs all eight observed latches
correctly without hitting its VU budget in the completed run. Scheduler, guest
instructions, VU budget and GS rendering semantics were not changed.

Next: a separate headless probe with `-FrameDumpMinPrims 900000` and a unique
label, keeping the same settings and a900s limit. This run reached940100, making
900000 a plausible later capture point, not a guaranteed deadline. If the
threshold is not reached, report no capture instead of interpreting it as black.
Compare the presentation and both GS contexts, then measure actual frontend
update intervals before choosing another performance target. Do not reopen the
fixed FSAND/TOP bugs or change scheduling without new evidence.

## Reproduce locally

Run from the repository root, with no MC3 process running. Captures are ignored
local game data, not included in the source commit. A different machine needs
its own matching snapshots; the native state layout must match the test binary.

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Replay-VuInputs.ps1 -CaptureLog work/logs/probe_vif_input_before_astra_20260905.log.stderr -Prefix <project-root>/work/captures/vuinput_vif_input_before_astra_20260905 -Label <unique-replay-label>
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Probe-FrontendWrites.ps1 -Seconds 900 -Label <unique-boot-label> -TraceVuBudget -TraceVuInput
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Analyze-FrontendBoot.ps1 -LogPath work/logs/probe_<unique-boot-label>.log.stderr
```

Replay first, then the full boot, so test-suite activity does not compete with
the boot run. The boot harness rejects a stale executable or existing label.
No performance claim follows from the cycle reduction in an incorrect loop.
