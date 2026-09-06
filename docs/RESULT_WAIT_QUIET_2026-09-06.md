# Wait attribution with reduced boot logging - 2026-09-06

## Controlled change

Root a63dcad / runtime478fb98, no source/build changes for this run. No other MC3
process active at start. `wait_owner_quiet_astra_20260906`,900s, started00:16:53,
PID40008. Against `wait_owner_safe_astra_20260905`, metadata comparison confirms
identical exe/lib hashes and all MC3 settings except BOOT_TRACE1->0 and the unique
image output filename. Executable SHA256:
`3c2f31b157f598cbbeec6bdb2301064f615800fb2083ab6bb76fe26127260650`.
Library SHA256:
`2f7aabb54b94614a1a23268d93d112ded017b18eb448542710b4f027ef1e9aec`.

This is REDUCED logging, not a log-free binary. Bounded generated diagnostic
traces remain; MC3_WAIT_PROFILE, PHASE_TIMING and FE_WRITE_TRACE remain enabled.
No build/tests competed with the run. No synchronization, guest or math code changed.

## Coverage correction

The general per-host-frame counter block and one-shot image dump are gated by
BOOT_TRACE and absent in quiet mode. The **FE write probe is independent**:
`tools/diagnostics/mc3_fe_write_probe.h` gates only on FE_WRITE_TRACE, and complete
writer records are present in the quiet log. It can establish actual animation
updates, even though the sampled fe6AC/GS/VU totals and PNG are absent. Earlier
notes describing all FE evidence as unavailable were too broad.

## Early observations (not the completed result)

The same frontend constructor write (321390) appears after nearest wait snapshot6
in quiet vs33 with boot logging. Snapshot sequence is not an exact wall timestamp;
do not turn it into a precise FPS or speedup claim.

At quiet sequence67: main token wait10.4462s; data worker5 totalhold0.5983s;
object-update worker7 totalhold121.8660s. Reduced token wait does not imply boot
has completed: main can be waiting inside a released-token syscall.

By sequence81, worker8 has started, contributing33.7755s of overlapping hold;
main token wait44.5909s across the whole run. Constructor/initializer writes to
the same FE object16d5ec0 are present. Thus the network wait has not disappeared
merely by reducing general boot logs. Need a matched-phase window and final
animation update evidence before interpreting its magnitude.

## Completion

Completed at00:31:55:901.621s wall,447.094s CPU (283.094user,164kernel), no early
exit. Last complete FE write n25 advances14->15. No PNG expected in this mode.
Late window seq81->180, after network startup and worker7 completion:
main token wait428.767s; network overlap422.457s (98.5% of TOKEN WAIT), data worker
6.129s. The earlier verbose window88->179 gave352.673/381.300s (92.5%). These
are corresponding lifecycle phases but unequal windows, not a speedup benchmark.
Network ownership remains dominant with reduced boot logging. A single control
is not a repeated performance A/B and does not establish visual acceptance.

## Callback probe (next binary)

`MC3_NET_CALLBACK_PROFILE=1` records actual virtual callback destination and
completed invocation wall time. It includes yields, waits and reacquisition;
do not equate callback wall time to CPU or exclusive token retention. Bounded
16 object/target slots, explicit overflow/abandoned/unmatched counts, host-only
emission. Context pointers are identity values only, never dereferenced.

Generated sources are ignored. To reproduce the hook in the compiled owner
`work/generated/ghidra/sub_001F95C0_0x1f95c0.cpp`:

- Include `runtime/ps2_net_callback_probe.h` after `ps2_runtime.h`.
- At jalr PC1f9608, after `uint32_t jumpTarget = GPR_U32(ctx, 3);`, add
  `ps2_net_probe::onBegin(ctx, GPR_U32(ctx, 16), jumpTarget);`.
- Immediately after `label_1f9610:`, add `ps2_net_probe::onEnd(ctx);`.
- Run `tools/Compile-NetCallbackProbe.ps1` via RTK. It always rebuilds this owner,
  including header-only changes. Rebuild runtime/tests and absolute fast relink.

The rsp and batch0005 summary confirm the ghidra owner object, not the alternate
native_analyzer copy. nm confirms probe TLS/counter references in that object.
318/318 tests passed, including yield-spanning and mismatched completion cases.
Relink00:35:23; executable newer than runtime lib and owner object. Executable
contains both profile env and emitter format. Actual callback records remain
the decisive check that the begin/end hooks execute.

Run `net_callback_quiet_astra_20260906`:600s, started00:35:48, same quiet settings
plus callback profile. Exe SHA256
`f436b58c52309ae07158c6fb658258a962cf5feec5667b2ac5c0ae3360c64e6e`, lib
`a37b3460340a3b1d53a50443db36c3e38d60bf7c390087bac0a140a9b55831d8`.
Completed00:45:49,601.051s wall,339.203s CPU, no early exit; no MC3 left running.
Runtime commit1fc7b08. No scheduling or guest behavior change intended.

40 complete callback records, firstseq81,lastseq120, one object00852c40 and
actual target001b84e8:469starts,468ends,192.3587s completed wall,411.023ms mean,
1299.775ms maximum. One active at final snapshot, zero abandoned/overflow/unmatched.
The open invocation is not included in completed wall. This confirms actual
generated begin/end hooks execute, not merely that the emitter string exists.
Source SHA25668a2c331eccc7ba4fca072296e8a45834c41adadd5e79b615cdbab641b5db86f
was updated in the ignored compile manifest after successful single-owner build.
Parser synthetic checks passed (partial/missing records and regression).

## Important differing progress / limits

This600s probe is NOT an equivalent performance A/B to the900s controls. Only two
complete FE initialization writes appeared; no322e94 animation updates. Main
completed-token counters were unchanged fromseq90 through120 (initial14.3794s,
reacquire0.0440s,hold26.7280s), while network completedhold grew to189.0783s.
Network overlap with main token wait was only1.9018s. Thus the previous control's
422/429 attribution must NOT be transplanted into this run. Main may be inside a
released-token wait, or an unfinished interval; these counters cannot distinguish
the precise syscall/PC. No live-context dereference should be added to resolve it.
Instrumentation/boot scheduling variability or a different blocked state remains
open. No FPS gain, no boot/menu acceptance, and no proof of a unique cause.

## Proven call path and next bounded investigation

Observed virtual target001b84e8 is a wrapper, not the assumed base001f9e20.
Generated source at1b8558 directly calls4428c8, whose local retail symbol has a
hash match to netEngineManagerThread::Update. At4428e4 that function calls1f9e20
(base netManagerThread::Update, weaker callgraph symbol match). The wrapper also
calls1ffae8, conditionally1e16b8, and ipcCriticalSection ctor/dtor398e90/398ec0.
The destructor is not a measured hotspot; do not choose it just from its position.

Next: safely publish the main thread's wait kind/guest dispatch PC and measure
the wrapper's child calls, especially4428c8, with separate nested accounting.
Do not reuse the single pending callback slot for nested calls: that would
abandon the outer sample. Keep math substitutions/network bypass/scheduler changes
out of this diagnosis. Existing math trace names are not proof of rendering cost.
