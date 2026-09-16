# PS2 Project State: Midnight Club 3 Recomp

## Current 2026-09-15 07:29 - last two missing entries, zero missing lookups

5BA440 (virtual call wrapper, corpus JALR pattern) and 37E4D0 built by
tools/Build-MenuLast2Entries.ps1; 288 cases OFF/ON PASS.
Exe <scratch-dir>/mc3-menu-last2-20260915/bin/mc3_partial.exe SHA dc0375b7...
Probe menu_last2_20260915_a 1202s: zero not-found, zero recover-pc.
Captures same as leaf4 (next panel, no items). Menu NOT accepted.
See docs/RESULT_MENU_LAST2_2026-09-15.md.

## Current 2026-09-15 06:25 - leaf4 entries and 20-minute probe

5CC940/5BA3D8 (jr ra;nop), 5BA338 (OR2 this+6C), 5BB228 (float obj+270) built
by tools/Build-MenuLeaf4Entries.ps1; 240 cases OFF/ON PASS.
Exe <scratch-dir>/mc3-menu-leaf4-20260915/bin/mc3_partial.exe SHA c2ffba61...
Probe menu_leaf4_20260915_a 1202s: missing only 5BA440 x7, 37E4D0 x1.
Captures 3/4 changed from PRESS START to next panel layout (empty, static).
Menu NOT accepted. See docs/RESULT_MENU_LEAF4_2026-09-15.md.

## Current 2026-09-15 05:48 - pair exe 20-minute probe

menu_pair_20260915_a with SHA783551ac..., same settings as 13/09 21:39 probe.
1202s, stopped by limit; 207 snapshots/188 post-activation, states 1/41/40/37/40.
5BB260/5CD768 lookup lines ~4300 -> 0. Captures unchanged: PRESS START, white bands.
Menu NOT accepted. Remaining: 5CC940 178 (RA42630C), 5BB228 9, 5BA3D8 9, 5BA338 6,
5BA440 5, 37E4D0 1. Next recover 5CC940/5BA3D8/5BA338. No runner active.
See docs/RESULT_PROBE_MENU_PAIR_2026-09-15.md.

## Current 2026-09-13 22:39 - pair5BB260/5CD768 tested

New executable <scratch-dir>/mc3-menu-pair-20260913/bin/mc3_partial.exe.
SHA783551ac50f250c10c088eebf09683f6cd8a30796c164376fef71c7906bcb4b6.
Eight ELF opcodes verified;252 full-registry reference cases PASS (126 OFF/ON).
Prior four entries retained, prior binary preserved. No live rerun yet.
See docs/RESULT_MENU_PAIR_ENTRIES_2026-09-13.md. Next comparable20min probe;
visual gain/menu acceptance remains unverified. No runner active.

## Current 2026-09-13 21:59 - 20-minute probe completed

menu_missing_20260913_a completed1202s, stopped by harness deadline; no early exit.
PID25204 gone; reader exited0. No Called unimplemented recorded.
Four captures,252 snapshots/218 post-activation; final state40, PRESS START
legible but white bands remain. Full menu NOT accepted, no visual gain claim.
Eight lookup targets remain:5CD768,5BB260,5BB228,5CC940,5BA338,5BA440,5BA3D8,37E4D0.
Counts/ELF mapping and exact provenance in docs/RESULT_PROBE_MENU_MISSING_2026-09-13.md.
Artifact directory <scratch-dir>/mc3-menu-missing-20260913/run.
Next recover/trace remaining entries, prioritizing5BB260/5CD768; no game active.

## Current 2026-09-13 19:26 - three missing entries recovered

New isolated executable <scratch-dir>/mc3-menu-missing-20260913/bin/mc3_partial.exe.
SHA719502b45720a33d3e1299359d55db4ea439e77aa3c0cb70af25b4102573ec4e.
Adds exact ELF entries5BB238/5CD780/5CD790; retains5BB268.
96 full-registry opcode-reference cases PASS, entry gate OFF/ON, full context/RAM.
Prior executable unchanged. No new live game validation or visual success claim.
Next: bounded20-minute probe with entry/host-clock/bridge/STQ ON, depth OFF,
capture presented frames and inspect missing functions regardless of exit code.
Details docs/INVESTIGACAO_MANUAL_2026-09-13_TARDE.md.
Earlier sleep/shutdown block is historical and does not authorize another shutdown.

## Closed work 2026-09-13 10:38 - tested leaf fix, authorized shutdown next

Plan docs/PLANO_1H_ENQUANTO_CLOUD_DORME_2026-09-13.md. User explicitly authorized
PowerShell shutdown after preserving work; reserve10:39 onward for closure.
Combined entry-fix + host-clock probe menu_combined_20260913_a CLOSED10:11:55,
PID47664/reader41528 deliberately stopped.118 snapshots,95 post-activation.
Third presented capture has legible logo/PRESS START, still white bands and defects.
Diagnostic menu_vertex_20260913_a CLOSED10:28:39 after896.5s, PID61328 gone.
Exit0 HID missing function5BB268 atRA22524C; see stderr/audit-final.json.
178 snapshots,155 post-activation;750 valid vertices, no affine/pointer mismatch.
Reader ended on Read failed after runner exit. No active game probe.
Copied2101A0 observer exe e9411f39e3eeb67e1a7bed5aa4498cd8e3e8ad48f050f9fb0ce71d016a6d5d70;
depth OFF, entry/host-clock/bridge/STQ ON.32 full-state equivalence cases PASS.
Artifacts <scratch-dir>/mc3-menu-combined-20260913/run; read-only watcher.
Combined sequence reaches D8=40 then37 and title inactive; next menu not accepted.
UI wrapper16D6710 +9 naturally changes0->1; movie177F230 accumulator advances,
header fps256=3840 (15fps). Actual20ACD0 timing fixture passed four cases.
Actual visual path found2102A8 ->530208 setup ->2101A0 affine vertex writer;
callback70F1BC=3203B8 emits texture DMA. MenuOptionScreen property setters are
not themselves renderers. Observer artifacts mc3-menu-vertex-20260913 in C:.
VIF fixture real530208+2101A0 PASSED positions/UV/colors/Q1, MSCAL2 then0;
VU/GS not executed. Live UI tree76 nodes contains Press START/OK/Back despiteD8=40.
Build-Leaf5BB268.ps1 COMPLETED10:35:47, exact retail leaf return2
(ELF03E00008,24020002), base menu-entry without observer. Full registry3 cases
OFF and ON passed. New exe <scratch-dir>/mc3-leaf-5bb268-20260913/bin/mc3_partial.exe
SHA a6f93b7e4305d67cd98a5086dcea1d2d13ea6ded3dbe881f4a72d2d890b0ed7a.
Long game rerun beyond15min NOT done; first next action is that bounded validation.
Prior generated sources/registry/objects unchanged. Details RESULT_1H_ENQUANTO_CLOUD_DORME_2026-09-13.md.
Automation mc3-concluir-1h-e-desligar already PAUSED via tool, verified file.
No new probe this block; next15-minute probe would exceed deadline.
Final audit confirms original registry/exe preserved, one new leaf binding,
OFF/ON fixture passed; no owned runner/reader/compiler active.
Preservation sources/manifest:mc3-sleep-block-20260913 in C:.
Authorized shutdown.exe /s /t 0 without /f follows preservation; request record there.
Do not start a new work loop if resumed after this block's deadline10:49:30.

## Current 2026-09-13 09:11 - post-activation collection confirmed

Continuous reader captured40 samples,21 after D8=40 AND panel1725D50 active.
Child1725EA0 flags647 opens gate; final member17788B0 flags591 also open.
State37 observed then return40 under periodic START; no usable visible menu.
Resources now identified from correct signed ADDIU addresses:65ACEC MemCard,
65AE24 MenuOptionScreen (prior66... resource address interpretation was wrong).
No renderer patch; next target actual visual emitter for these resources -> GS.
Do not repeat parent/child gate investigation: observed open in live game.
Reader56660/runner60308 deliberately stopped, sessions completed, no runner active.
Details docs/RESULT_MENU_TRANSITIONS_2026-09-13.md; artifacts mc3-menu-transition-20260913/run.

## Closed 2026-09-13 08:58 - continuous transition reader

menu_transition_20260913_a headless immutable menu-entry exe, cap960s, PID60308.
Harness session24828; reader session39571 watches900s with2s sampling/change-only saves.
Receipt verifies PID/path/start ticks/SHA once, read-only handle and ELF signatures.
No runtime rebuild/relink. Entry/bridge/STQ ON, host clock/depth OFF.
<scratch-dir>/mc3-menu-transition-20260913/run/transitions holds snapshots.
Stop only verified owned process after enough post-activation evidence or cap.
Correction:340994 compares42D with immediate10;364 is only loaded in taken delay slot,
not a second comparison requirement. Need actual D8=40 AND panel active, not E0 alone.

## Current 2026-09-13 08:54 - live draw collection closed

Headless menu_draw_20260913_a capped720s/elapsed721s, immutable menu-entry exe.
Final intact frame confirms title inactive974; last live read still D8=41,E0=40.
Post-activation child sample NOT obtained. No usable visible menu; no active runner.
Title child1726350/group631C40 has gate open, one member177ABD0/render5CC940.
Next panel inactive462: child1725EA0 flags135, one member17788B0 flags78.
Do not call pre-activation closed flags a bug. Group render422698 traverses+48 list.
Reader now supports exact receipt identity and bounded child-list observation.
Next: targeted shared Render3404D0 state transitions and post-activation group collection.
See docs/RESULT_MENU_DRAW_LIVE_2026-09-13.md and <scratch-dir>/mc3-menu-draw-20260913/run.

## Current 2026-09-13 - post-title draw route isolated

No new visual probe: usable menu still unconfirmed; title-exit evidence below remains latest.
Panel62BDE0 Render41F980 forwards child+48 through4262D8; child flags require bits0+9.
Actual compiled registry/retail forwarding fixture passed15/15 with entry fix OFF and ON.
Common slots of62BDE0/62BCF8 show no unsupported final entry alias in source audit.
Read-only reader now prepared to collect draw child flags/vtable/render; syntax PASS,
live fields untested. Adapt verified probe identity before next run; no active game launched.
Next: observe draw child afterD8=40, then follow gate producer or child's GS draw route.
Details: docs/RESULT_MENU_DRAW_ROUTE_2026-09-13.md. Artifacts <scratch-dir>/mc3-menu-draw-20260913.

## Current 2026-09-13 07:33 - title exit unlocked, visual UI still corrupt

Confirmed in game: single33FEB0 registration repair advances node42D0->10; node368 reaches0.
Titleflags975->974 (inactive), actual panel+D8=40 in two read-only samples.
The old JSON panelState reads+E0 (requested field), not current+D8. Do not confuse them.
No usable visible menu accepted: capture3 still has white bands and corrupt scene.
Entry probe closed deliberately after746.407s/CPU652.766s; all MC3 probes stopped.
331/331 tests OFF/ON and compiled-registration counter fixture passed.
Reproduce with MC3_MENU_ENTRY_FIX=1; frame host clock and depth OFF. Fix remains opt-in.
Original E executable/objects preserved; <scratch-dir>/mc3-menu-entry-20260913/CLOSURE.json verifies artifacts.
Next: identify/draw active panel1725d50,vtable62BDE0,Update37EC18 and resolve white bands.
Details: docs/RESULT_MENU_ENTRY_2026-09-13.md; clock investigation: docs/RESULT_MENU_CLOCK_2026-09-13.md.


## Closed 2026-09-13 07:20 - menu entry registration repair

Clock-only probe closed deliberately after405.730s: timer advances but node368=5 remains.
Compiled-registry fixture proves Update33FEB0 overwritten by unsupported sub33FD80 alias.
One default-OFF registration fix tested: real counter0 before,1 after;331/331 OFF/ON.
Headless menu_entry_20260913_a started07:20:51,PID7880,session77935,900s cap.
MENU_ENTRY_FIX ON; FRAME_HOST_CLOCK and DEPTH OFF. Do not rebuild/relink while active.
Artifact <scratch-dir>/mc3-menu-entry-20260913. Original E binary/objects untouched.
See docs/RESULT_MENU_ENTRY_2026-09-13.md. Usable menu not yet confirmed.


## Closed 2026-09-13 07:09 - isolated frame-clock experiment

Menu B closed deliberately after716.526s; three captures, no usable menu.
Direct read-only samples confirm raw frame delta0/saved Count0 and title node368=5.
Actual retail433490 fixture reproduces observed delta0.000106813 from frozen Count.
New default-OFF MC3_FRAME_HOST_CLOCK changes only two frame timer Count readers.
Fixture OFF/ON and331/331 suite OFF/ON passed. Original E objects/exe intact.
Headless frame_clock_20260913_a started07:09:36,PID47864,session24961,900s cap.
Do not rebuild/relink or start another runner while active. No visible menu accepted.
Artifact <scratch-dir>/mc3-frame-clock-20260913; see docs/RESULT_MENU_CLOCK_2026-09-13.md.


## Superseded 2026-09-13 06:54 - corrected title observation, menu investigation

Cloud clarified that the scene is an in-game animation with moving cameras and
buildings, and asked to prioritize reaching the menu. Do not compare unrelated
animation frames as an A/B. White-band persistence remains observed separately.
Run a stopped deliberately after320s: locator searched62AA70 but retail ctor
362F60 stores62AA68; Update is slot24, not1C. titleObj=0 was invalid evidence
of a missing title. At final intact tick16920,titleUpdate25,inputUpdate25,
StartPublishes473; UI was running, queue sampledcount0. No menu accepted.
Read-only locator corrected and titleFlags/titleMessageCalls added; retail ELF
check and331/331 suite OFF/ON passed. Parser rejects interleaved snapshots.
Headless menu_frontend_20260913_b started06:54:32,PID52252,session53530,1200s cap.
Uses new verified observer executable with MC3_GS_DEPTH_TEST absent/OFF; bridge
and STQ ON, Start held30s/released30s after45s. BOOT_TRACE ON to observe title,
frontend command queue and input; graphics probes OFF; presentation captures ON.
Artifact root <scratch-dir>/mc3-menu-20260913/run_b (run_a retained in run).
Exe32be831f6a6eef95e7327f45c2f8a756a16b8228d186ae599c01613de5c0a75d.
Lib1241189183ddd1191a395bb1743b8a192616b0162eb1de21408a316ae7cc13a3.
No intro skip, forced guest state, memory-card edit, new build or visible window.
Pending: distinguish title animation, accepted Start, menu state and visible UI.

## Closed 2026-09-13 06:40 - depth experiment does not fix white bands

Cloud requested continued investigation. Added MC3_GS_DEPTH_TEST, default OFF:
fragment Z for all primitives, format-aware test/write, ZMSK and alpha AFAIL.
340/340 depth contracts and43/43 limits pass ON; OFF matches immutable baseline
(96pass244fail).331/331 full suite OFF/ON,ADC44 andcopy100128pixels pass.
Three copy fixtures now set the depth-write mask omitted from their old setup.
Depth plane uses double; vertex Z remains float, so full32-bit precision is not
claimed. This is experimental, not full GS parity or visual acceptance.
Headless depth_render_20260913_a started06:29:09,PID53464; deliberately stopped
06:40:25 after thirdcapture. Harness ended06:40:30,wall681.241s,CPU662.125s,
exit-1intentional. No runner remains. PNG3 at660.024s/prim4192788 retainswhite
bands and is darker than previous capture. No visible improvement accepted.
5 sourceowners/15 depth samples,0 rejected; storedZ nowffff instead of prior0.
All15 estimates exceed16-bit range: the real saturating path passes GEQUAL at
ffff, while old observer mask-based passAgainstCurrent=0 is NOT actual rejection.
Matched copyprim2227445 remains allnearwhite in source. Four previouscolor
owners no longer appear; no claim that every missingowner was depth-rejected.
Keep MC3_GS_DEPTH_TEST OFF by default. Next trace the first writer setting the
watched Z16S location toffff before2M, then inspect its XYZ/clip provenance.
Same Start/bridge/STQ and source/present captures as previous passive depth run.
Artifact root <scratch-dir>/mc3-depth-render-20260913.
Exe a3bf2785a35d92601ab0b4997007efe480845b897f97ab3c6ef68f3cf2cf9271.
Lib d0b4582aef59d553c69e8249f97f140646ba1ca1d38e45fb89699a3633b49294.
Original and previous binaries preserved. Depth is implemented experimentally,
but visual acceptance failed. Details docs/RESULT_DEPTH_RENDER_2026-09-13.md.

## Closed 2026-09-13 05:43 - depth absent, visual failure remains

No clear visual improvement accepted: ADC correction is confirmed, bands remain.
Read-only depth observer built and tested: 331 suite cases OFF and ON, 44 ADC
cases, copy fixture unchanged. Synthetic Z=100 against stored Z=200 confirms
the current rasterizer ignores requested GEQUAL depth and leaves Z unchanged.
This does not yet establish which real-game fragments should be occluded.
Headless run depth_source_20260913_a, PID55264, started05:32:35, deliberately
stopped05:43:50 after third capture; harness ended05:43:52,wall676.822s,CPU624.875s.
Exit-1 is intentional stop, not an observed crash. No runner remains active.
9 source triangles/27 depth samples,0 rejected: all Z16S,ZBP176,GEQUAL enabled;
5 request depth writes. Raw Z stays zero in all27.18 estimates exceed16-bit
range; no usable rejection against current raw zero. This cannot reconstruct
missing depth history or prove that depth alone causes the bands.
Third PNG660.028s/prim4984963 still shows white bands/deformed scene.
24 ADC records remain bounded; two source copies still captured. Next build
an overlapping-primitive depth regression before implementing full Z behavior.
Artifact root <scratch-dir>/mc3-depth-20260913.
Executable SHA256 0c6585b3726798ec2be9e2f73c5a5bf1e19f9ab256c0efc8dab0f4aa26fb9b2d.
Original executable and previous ADC artifact preserved. Depth rendering has
not been enabled; observer uses estimated interpolated Z and raw current VRAM.
Missing historical Z writes and float/range limitations constrain inference.
Follow-up evidence: docs/RESULT_DEPTH_PROBE_2026-09-13.md.

## Closed 2026-09-13 04:57 — ADC queue corrected, white bands remain

Queue correction confirmed on the SAME real prim2225038: previous verticesABC
becameBCD;24 ADC records,0 rejected,highest observed4194304,all observed counts
bounded.9 source draw events,0 rejected,0 capped at last5.5Mprim snapshot.
Two source captures remain white beforecopy at2175494/2227445;6 pipeline samples
match.Third presentedPNG at660.055s/prim5372283 still shows white bands and
deformed scene. No full graphics/gameplay acceptance claimed.
Run adc_queue_20260913_0446 deliberately stopped04:57:50 after criterion met;
harness ended04:57:55,wall712.326s,CPU694.469s,exit-1(intentional stop).
PID59840/path/start verified;stop.json records intent.No runner active.
Keep the proven queue fix. Next inspect packets/flags/depth of remaining source
producers, especially2225038/2225467;do not assume Q-sign filtering is a fix.
OriginalE/previousC executable preserved. Detailed evidence/rollback:
docs/RESULT_ADC_QUEUE_2026-09-13.md;<scratch-dir>/mc3-adc-20260913.

### Implementation and historical launch record 04:46 (now closed)

Cloud authorized the next step with "go". A minimal ADC/XYZ3 fixture reproduced
36 failures/44 cases against previous immutable library;8 no-skip/incomplete
controls passed. GS::vertexKick returned before queue advancement on !drawing,
so A,B,C(skip),D drew staleABC instead ofBCD. Corrected complete-primitive queue
advancement for strips/fans/lists while keeping rasterization/metrics conditional
on drawing. No class layout change, clipping rule or Q-sign filter added.
44/44 fixed cases PASS (directXYZ/XYZF,packedXYZ/XYZF,all primitive types,long skips).
331/331 full suite OFF and ON PASS; copy100128pixel fixture and five writer fixture
remain byte-identical OFF/ON. ADC trace10records, results identical OFF/ON.
Headless run adc_queue_20260913_0446 started04:46:02,PID59840,session63612,900s.
Artifacts <scratch-dir>/mc3-adc-20260913. Same Start30/30delay45,bridge/STQ,
sourcewatchFBP64/CT24 threshold2M,copy/presentation captures;ADCtraceON.
Exe51d5f876dbcdb474e647346c66a4fc9b72b87b81ba2e5e2bceaf6382662dbf19.
Libef6f14c88506e1bde829b795478b4b8f1d38daa1bef76727e512d5042635f2f1.
Previous C/E executables and baseline4files preserved/hashed. Queue bug fixed
in tests and verified in real vertex records; remaining visual failure described
in closure above. See docs/RESULT_ADC_QUEUE_2026-09-13.md.

## Closed 2026-09-13 04:33 — bands already present before the final copy

Two real source snapshots atprim2227445/2407292 show the white/cyan bands before
the CT24->CT16 copy. Six samples at256,84..86 match source/TEXA/shading/blending/
CT16 storage; second source RGB4,255,255 correctly quantizes to CT16cyan.
Third presented PNG at660.024s/prim2743953 reproduces bands. Graphics still broken;
no functional rendering fix or visual acceptance claimed.
Source watch FBP64/FBW8/CT24 tracks physicaladdr690312;32 selected writers are
draw/GIFpath1 triangle strips intoFRAME64/FBW8/CT32. Firstwhiteproducer2225038,
firstcyanproducer2404667; extreme screen coordinates and mixed/negativeQ logged.
The32-eventcap was reached; these are selected events, not all writes.
Run copy_source_20260913_0423 deliberately stopped04:33:17 after two source and
three presented captures; harness ended04:33:20,wall686.219s,CPU638.297s,exit-1.
PID6376/path/start verified; stop.json records intent. No runner active.
331/331OFF/ON plus100128 fixture pixels and immutable evidence tests passed.
Exe63bff17189f7e5d5d77fd2eba72800ae304b323dcb2dc6e73682ab5d7c3066c7.
Artifacts <scratch-dir>/mc3-copy-source-20260913, originalE and priorC
executables preserved. See docs/RESULT_COPY_SOURCE_2026-09-13.md for exact samples.
Next validate ADC/kick queue progression with a minimal sequence, then trace
actual GIFpath1 packets of identified producers. PackedADC is decoded; fabsQ
preserves sign. Do not infer either is discarded from their names alone.

### Historical launch record 2026-09-13 04:21

Cloud authorized this follow-up with "gogo". Headless run copy_source_20260913_0423
started04:21:54 Brasilia, PID6376, harness session93991, limit900s (now closed).
Artifacts <scratch-dir>/mc3-copy-source-20260913; baseline source/lib/tests
hash-verified; previous C runner and original E runner preserved.
New copy probe OFF by default, max4 source PPMs (512x64 rows72..135), input samples,
shaded color and destination CT16 before/after at256,84..86 for the exact observed
sprite. No GS layout change or pixel-loop hook.331/331 OFF and ON passed; fixture
100128 pixels, clean/striped inputs, source preservation, OFF/ON VRAM digests and
exclusive PPM creation passed. New exe63bff17189f7e5d5d77fd2eba72800ae304b323dcb2dc6e73682ab5d7c3066c7.
Same quiet/bridge/STQ/Start30/30delay45. Source watch now FBP64,FBW8,CT24 at256,85
(TBP2048), threshold2M; this watches the producer while copy probe watches output.
Actual source/producer evidence is recorded in the closure above.

## Closed 2026-09-13 03:54 — surface blind spot identified, graphics still malformed

Cloud approved the 180-minute diagnostic batch; session began03:22:56 Brasilia.
Verified backup:16202 files/SHA256 under <scratch-dir>/mc3-surface-20260913/baseline_v2.
Original E exe/lib preserved. New C build:331/331 OFF and ON; five real writer
fixtures produce identical VRAM/presentation hashes OFF/ON. New watch defaultOFF
covers CT16 and draw/IMAGE/HWREG/local-copy/clear at one physical address.
Old probe rejected CT16; previous logs already show FRAME CT16. New presentation
logs confirm DISPFB0/FBW8/CT16 with CRT origins0,0 and0,1; field mode active.
Run surface_owner_20260913_0345 started03:42:04; deliberately stopped03:54:11
after726.863s with criterion met. PID56912/path/start verified before stop;
stop.json records intent. exit=-1 is deliberate termination, not a crash.
Exe d0c66999cfbf652d82f2725270d69a33ceacd7149ee8351599eb16000b0d638f.
Headless quiet/bridge/STQ, Start30/30 delay45, both probesON, threshold2M.
Two actual draw changes at prim2227445/2407292: black->white/cyan in CT16,
GIFpath2, CT24/TBP2048 textured copy, regular32px-wide sprite geometry.
Both precede old3M gate; old probe also rejectedCT16. ThirdPNG reproducesbands.
Three presentedPNGsOK;331/331 OFF/ON; oldprobe0,newowners2,rejected0.
No runner active; no gameplay/graphics correction accepted. Next inspect source
texture plus two presentation rows and full blend/Z state, not VU1 by appearance.
Atlas connector returns404 for existing site and empty site list; no replacement
site/access change. Local atlas text updated; remote publication not completed.
See docs/RESULT_SURFACE_OWNER_2026-09-13.md for provenance, limits and rollback.

## Planning audit 2026-09-13 — previous surface run completed, no active runner

Read-only audit reconciled the stale Active entry below: surface_band_20260910_0955
ended 10/09 at10:19:45 by harness timeout, wall1502.3739775s. Five presented PNGs
ok=1; PNG5 still malformed (inspected13/09), prims4257869. Surface probe enabled
in meta but zero intact/rejected surface events. No observed missing-function error.
No new runtime evidence found for11–13/09 in inspected docs/logs/captures.
No mc3_partial process found. DiskE only296329216bytes free; gate new builds on
adequate temporary/rollback space. No build/run or functional edits in this audit.
Plan for NEW session: docs/PLANO_GRAFICOS_NOVA_SESSAO_2026-09-13.md (180min proposal).
Next: explain surface probe blind spot before attributing defect to vertices/VU1.


## Active 2026-09-10 09:55 — bounded surface attribution probe

Cloud authorized a new batch with "go" after overnight closure; old automation stays PAUSED.
Read-only pixel probe added (OFF by default): pixel256,85 in FBP0, after3M primitives,
max32 white/cyan RGB changes. Records actual pre/post framebuffer and draw state.
331/331 tests passed OFF and ON+STQ; two integration records; log parser tests PASS.
New exe 1d3bf49bbdc88f23b178978d6ea0797827848581d5e88fd2d6b35acbfca9ac0b.
Run surface_band_20260910_0955, session89383,1500s, headless/quiet, bridge+STQ ON,
entry trace/presented capture ON, Start30/30 delay45. Do not duplicate/build/relink.
No new graphics correction or in-game conclusion yet. See RESULT_SURFACE_PROBE_2026-09-10.md.


## Closure 2026-09-10 09:46 — overnight automation PAUSED

First heartbeat after the 09:30 deadline paused mc3-investiga-o-at-6h.
No mc3_partial process found; no experiment or manual window was terminated.
No new build/run, shutdown, restart, or game-state mutation after the deadline.
Results and private atlas remain those documented below; no new visual gain.
Next authorized work should isolate one malformed surface across GS input and
raster output, as planned in docs/RESUMO_MADRUGADA_2026-09-10.md.


## Current 2026-09-10 08:58 — final runtime result; graphics still broken

09:02 artifact close: private atlas v6 deployed successfully; 344-file hashed
source/capture backup at <scratch-dir>/mc3recomp-backups-20260910_0750/closing_sources_0901.
No new long experiment planned. Existing heartbeat must pause at/after09:30.

Latest run stq_correct_capture_20260910_0756 ended 08:31:22 by harness timeout:
2103.3388474 s wall, 1533.75 s CPU, exitedBeforeLimit=false, exitCode=null.
No active mc3_partial observed at the closing audit. No new long run planned.
5cd758: 16 intact markers through call 16384; 5e89f8: no observed marker.
STQ varying-Q: 24 intact markers through 4194304. No observed unimplemented error.
Six presented PNGs succeeded; PNG6 still has white/cyan bands and damaged scene.
STQ contract fix is exercised, NOT a full visual fix. Both experimental gates
remain default OFF. No FPS/menu/profile/race acceptance.
See docs/RESUMO_MADRUGADA_2026-09-10.md for next bounded diagnostic and backups.
Older Live/Active entries below are historical and superseded by this entry.


## Live 2026-09-10 08:19 - STQ code exercised, bands persist

PID18688 stillactive until~08:31.23STQvariableQmarkers through2097152,
5cd758through4096,no unimplemented. PNG4/5 inspected: scene texture appearance
differs butwhite/cyanbands remain. PNG5prims3994037 matches priorOFFPNG5,
but entiregame state not proven identical; no broadvisualsuccess/FPSclaim.
STQcontractbug corrected in gatedpath, not solecause ofgraphicsproblem.
Wait finalresult/PNG6; defaultOFF remains. Finalmorningreport/site dueby09:30.


## Active 2026-09-10 07:57 - STQ contract red/green; experimental visual run ACTIVE

0651run endedtimeout07:25,no unimplemented,5cd758through16384,5e89f8unseen.
PNGs4-6 confirm malformedlater scene, not acceptedmenu/gameplay.
Found triangle STQ interpolationbug vs PCS X2reference and discriminating
publicGS test. ProperCLUTfixture: gateOFF/requirecorrect328/329(red),
OFFlegacy329/329,ONcorrect329/329. Initialfixturefailure was NOTvalidproof.
NewMC3_GS_STQ_INTERPOLATION1 defaultOFF changesonlytriangleSTQ interpolation,
sparsevariableQmarker. No XYOFFSET/geometry/scheduler changes.

Run stq_correct_capture_20260910_0756 session15082,2100s expected~08:31,
quietheadless,GSbridge1,STQ1,leaftrace1,sixcapture,Start30/30s-delay45.
Exe f76cd5f0ecbd4af7b4f2dc7a441b75d1049d3f29f358d0dcb871a5f4041a0f57;
lib0377ebdf5b1788e2d9f5d04e563ca78062f3cc8d21414b7b187affe7769b7d7b.
Relink/markers/mtimesPASS. Do notbuild/relink/duplicate whileactive.
Next audit markers+sixPNGs and outcome. FullreportRESULT_STQ_INTERPOLATION.
E diskpressure: failedbackup074832 INCOMPLETE. Only064330binarybackups
movedwithverifiedhashes to <scratch-dir>/mc3recomp-backups-20260910_0750;
thatdir also hascurrentpreSTQexe/lib/sources/diff. Otherbackupsunchanged.
No save/assetdeletion. Sitev5 remains live; aggregateupdateaftervisualoutcome.
Userasleep,deadline09:30; leaveexperimentaldefaultsOFF.


## Active 2026-09-10 07:15 - 5cd758 runtime coverage confirmed; graphics still broken

Same run/PID51672 active, expected07:25 end. Compact live audit:14intact
5cd758 markers throughn4096, zero observedunimplemented,5e89f8 still0markers.
Specific missing-accessor barrier traversed; not globalgameplay acceptance.
Presented PNG4(960032ms) and5(1260036ms) inspected: darkstar/smoke-like scene
and stretchedsurfaces, then white/cyanhorizontalbands matching manual-type
corruption. This is later visual scene vs legal/title, NOT mainmenu confirmed,
nor geometry fix. Keep run alive for finalPNG6/result; no newbuild/instance.
Atlasv5 current; next substantive site update after finalrun outcome.


## Active 2026-09-10 06:53 - second exact leaf restored; presented capture run ACTIVE

Quiet ended06:22:12 early1702.443s EXIT0 with7unimplemented5cd758/RA4ff924,
then orderly cleanup. Internal requestStop path, not OS crash.5e89f8 unvisited.
5cd758 verified ELF jrra/addiu v0,a0,ec (rs4 NOT v0); restored separateowner
case/label and exactpartialregistration.7actualowner tests PASS;64earlierleaf
tests remain prior result. Bounded presented capture hook reuses UploadFrame
scratch, no extra latch; independentBOOT_TRACE, defaultOFF,max6attempts,
60s initial then300s. Capture scheduler/boundsPASS. Runtime328/328OFF andON
PASS today, build/relinkmarkers/mtimesPASS. Backup064330 plus restored copies.

Run recovered_leaves_capture_20260910_0651 began06:50:22, PID51672,
session81214,2100s expectedend07:25:22. Quiet/headless,GSbridge1,leaftrace1,
CapturePresented,Start30s/30s/delay45s. Newexe5f66cb623b7efc3d2e1ba7c64cba20b367641af1cee385b881d68b36fbacb0d4;
lib1fd5e0ac904f58cdcc17e2d1b1426a72c366756c7474363c986af8f3a995552f.
FirstPNG captured60s and inspected:MC3legal, not new visual progress.
Do not build/relink/duplicate while running. Next compare both leafmarkers,
newerrors, actualexit, and up to6present_* PNGs using Analyze-EntryCoverage.js.
Full evidence docs/RESULT_LATE_CAPTURE_5CD758_2026-09-10.md.
Atlasv5 private deploymentSUCCEEDED06:53:17,
appgdep_6aa27df2153c8191bd7e356ba6ce0111. User asleep, deadline09:30.


## Active 2026-09-10 05:54 - pulse run no leaf coverage; quiet control RUNNING

Pulse1800s ended05:32:21 timeout1802.926s, CPU838.9375s, no natural close,
no intact leaf marker/unimplemented error. Capture at3.5Mprims still MC3
title/loading art; final fields4.609Mprims,66title/frontendTicks,198UIupdates,
2722guestPadReads. Counters are last intact observations, not one record.
Changing Start alone did not produce observed leaf coverage; do not claim
runtime fix validated or headless broken. Subagent traced headless: only
FLAG_WINDOW_HIDDEN, normal emulation/audio/presentation and autoStart remain.

Quiet control entry_5e89f8_quiet_20260910_0555 started actually05:53:49,
PID25788/session51904,1800s expected end06:23:49. Same exe/lib/settings as
pulse except BOOT_TRACE0; leaf sparse marker staysON independent of it.
NO PNG EXPECTED: current frame-dump implementation is inside boot trace.
This isolates trace-sensitive coverage vs pulse (not proof of FPS gain).
Do not build/relink while active. After06:24 analyze result and errors/leaf;
if still uncovered, implement bounded periodic displayed-frame capture
independent of boot trace for next run, not another blind duration change.
Subagent boot_next_audit currently readonly planning that insertion point.
Remaining authorization until09:30, no shutdown; sitev4 retains known facts.


## Active 2026-09-10 05:03 - first probe no leaf coverage; input-interval probe RUNNING

0426 probe ended04:40:33 by harness timeout901.5s, not natural close; no intact
5e89f8 markers or unimplemented errors. Does NOT validate restored leaf in-game.
Display PNG inspected: MC3 title/loading art legible, not gameplay/profile.
Context0 alternativeFB image distorted; differentFB cannot alone prove bug.
Analyzer tools/Analyze-EntryCoverage.js: 16frontend-edge markers,45UIupdates,
2750guestPadReads,15title/frontendTicks,~3.97Mprims. Last fields need not share
one intact line. bootPhase=mc3intro stale classification not definitive stage.
Cannot claim no input because padReads0 or because long Start hold.

New probe entry_5e89f8_pulse_20260910_0504 started actually05:02:18,
PID42852/session43420,1800s expected end05:32:18. Same verified exe/lib,
GSbridge/entrytrace/boottrace1, headless. Harness now parameterizes existing
Start knobs, defaults preserved; this run hold30000/period30000/delay45000ms.
Dump threshold3500000prims, not a promised wall time. Repeated Start only,
no X/navigation/save bypass. No builds while running. Next heartbeat05:20
should only compact-check active state; after05:32 analyze closed result and
view capture, decide whether leaf remains unvisited or new blocker emerges.
User asleep; authorization until09:30. Sitev4 unchanged: no confirmed new
in-game fix yet. Update site at next substantive confirmed outcome.


## Active 2026-09-10 04:26 - NEW exe verified; 900s coverage probe RUNNING

Cloud explicitly went to sleep and reconfirmed continue. Deadline09:30 local,
no shutdown. Existing20min heartbeat remains the continuation mechanism.
Relink-Entry5e89f8 session26932 EXIT0: registry, stubs, relink, identity/new
leaf marker, mtimes all PASS. Newexe SHA256:
15b7251765cc562fe194d942a01db272397367b22209317e37cca8497d174c37.
Runtime lib unchanged a21022d6fd98ab73480dd70851ffa949fd83431ef3a5ee66eacdf6cb7671527f.
Probe session51516 RUNNING label entry_5e89f8_bridge_20260910_0426,
900sec, headless, BOOT_TRACE1, GS_IRQ_BRIDGE1, ENTRY_COPY_TRACE1,
FrameDumpMinPrims1500000, existing Start harness. No other game instance.
Expected end about04:41; do NOT relaunch/build while it runs. Inspect result
JSON/stdout/stderr in work/logs/probe_<label>.log.* after completion.
Need positive leaf coverage, closure reason/realexit, next missing address,
and image inspection; no runtime or geometry improvement claimed yet.
Sitev4 already private-published04:13, update next after confirmed outcome.


## Active 2026-09-10 04:22 - registration verified, compiling registry; stop path found

Generate-PartialRegister completed: 15831 functions,168845 aliases,0 missing
stubs. Verify-Entry5e89f8 --register PASS. Registry compilation session32812
RUNNING with UCRT64 PATH; first attempt without that PATH failed immediately.
Exe still OLD: do not run until compile/relink/marker verification completes.
Source default unimplemented handler ps2_runtime.cpp:2207-2222 logs the exact
error seen five times for5e89f8, then requestStop(). This supplies a concrete
internal stop path matching the manual close, not proof of OS crash or click
causality. Economical subagent independently traced stop/main-loop/cleanup.
Next: relink, verify new marker/hash, bounded headless coverage probe.


## Active 2026-09-10 04:16 - real5e89f8 leaf restored/tested, partial generation running

OwnerFUN005e8980 now dispatches SEPARATE5e89f8 body: LQ/SQ,LQ,JR/SQ;
two16byte copies, v0/v1 changed, a1ignored.64compiled-owner cases PASS,
ELF bytes/source guard PASS. Source in generated ignoredtree: preserve it.
Optional MC3_ENTRY_COPY_TRACE and harness TraceEntryCopy for coverage.
Generate-PartialRegister session14069 RUNNING; wait completion before compile
partialregister/relink. Ownerobject rebuilt, exe still OLD until relink verified.
Do NOT start run now. Backup040727. Full details docs/RESULT_ENTRY_5E89F8_2026-09-10.md.
Atlas version4 published private04:13 with manual visual milestones, not
leaffix/gameplay claims. User authorized start now; deadline09:30 unchanged.

## Manual run closed 2026-09-10 03:57 - cleanup seen, crash unconfirmed

Cloud reports close after click; PID36624 gone03:57:39. stdout ends normal
resource unload and Window closed successfully. PS2 Thread Exit messages
are not crash proof; runtime uses them for termination. Windows Application
1000/1001/1002 last1h matchingmc3 query viawevtutil empty. Actual game
exitcode unavailable: helper92321 exit0 is NOT runner exitcode. Improve
next controlled harness exit/motive evidence, no claim click caused crash.
Concrete independent lead: unimplemented5e89f8,RA340250,a0016ddf40. Source
neighbor5e8980 exists; register has aliases through5e89e0,not5e89f8 in search.
First cheap audit: realbytes/function boundary/caller/expected result, not
blind alias or stub. Then targeted render/UI-state evidence. Read latest
RESULT_TESTE_VISUAL_CLOUD and PLANO_PRIORIDADES. Manual test ended; after04h
night work authorized until09:30. No saves/card destruction or PC shutdown.

## User screen 2026-09-10 03:52 - CREATE PRO... faint, possible profile UI

New screenshot08 after memory-card check shows faint CREATE PRO... prefix.
Saved work/captures/manual_20260910_cloud_08_possible_profile.png.
Possible create-profile UI, not confirmed full title, selected option or
completed card/save action. Remaining on it may be waiting for input, not
execution limit. Identify active UI/selection before treating as hang;
don't blindly confirm or modify persistent cards/saves. Bounded log tail
has no direct profile/card marker. ManualPID36624 active; no interruption.
Read latest RESULT_TESTE_VISUAL_CLOUD_2026-09-10.md. Deadline09:30 remains.

## Confirmed visual milestone 2026-09-10 03:47 - checking memory card screen

Cloud pressed Enter repeatedly and screenshot07 now shows readable CHECKING
MEMORY CARD over still-broken background. Saved work/captures/
manual_20260910_cloud_07_memory_card.png. Same manual PID36624 active.
This confirms a new visual flow, NOT completed card check/save operation,
nor previous screen identity as main menu. stdout confirms guestPad read731
start1 and uiinput-pad sample209 buttons0800/start1: input delivery proven,
causality for this screen not isolated. Let manual check finish; do not interrupt while user
tests. Never format/delete/recreate cards or saves to bypass it. Read latest
RESULT_TESTE_VISUAL_CLOUD_2026-09-10.md. Deadline09:30 remains unchanged.

## User hypothesis 2026-09-10 03:46 - possible main menu, not confirmed

Cloud suspects current distorted scene is already main menu. PNG06 saved:
work/captures/manual_20260910_cloud_06_possible_menu.png. Treat subjective75%
as user hypothesis, not measured confidence. No legible options or confirmed
selection response. Next discriminate frontend/menu active vs rendering-only
progress using actual state/input, not image resemblance or old entry counts.
Manual PID36624 still active, no interruption authorized while he tests.

## User visual evidence 2026-09-10 03:39 - progression after black, deformed output

Same manual run still active PID36624. Cloud confirms visible progression
after previous black interval; three more PNGs preserved as
work/captures/manual_20260910_cloud_03.png through05. Large stretched
surfaces/triangles/cyan-white bands, not accepted menu/gameplay. Therefore
black was not proven terminal/global hang. Enter pressed several times,
effect inconclusive due to slowness. Don't infer input success/failure.
Read latest RESULT_TESTE_VISUAL_CLOUD_2026-09-10.md. Night priority: locate
first invalid frame/data/state, distinguish geometry/texture/render/present
causes; not a speculative fix. Don't interrupt manual game. Deadline09:30.

## User visual evidence 2026-09-10 03:33 - credits exit, fragmented output then black

Cloud reports~23s first screen,>=~3min credits, then triangular/fragmented
output, blue point, glitches and persistent black. Two user PNGs preserved
work/captures/manual_20260910_cloud_01.png and02. This is beyond the old
one-shot legal capture; NOT confirmed menu3D/gameplay. Read
docs/RESULT_TESTE_VISUAL_CLOUD_2026-09-10.md before next experiment.
Prioritize first invalid frame around transition: production/rendering/
presentation or stopped production; do not assume cause from artifacts.
Manual PID36624 still active at03:33; Windows Responding is not guest progress.
Do not interrupt user's test. Enter response not yet reported. Deadline09:30.

## Active 2026-09-10 - manual playtest then authorized night until09:30

Cloud authorized visible manual launch now, autonomous work after~04h until
09:30 America/Sao_Paulo. Same exe/lib hashes confirmed this session.
Manual gateON,HEADLESS0,BOOT_TRACE0,PHASE_TIMING1,no automatic Start;
PID36624,label manual_gs_bridge_20260910_0328. New helper Launch-ManualGsBridge.
Preserve user's playtest; no duplicate instance or auto-close while active.
Heartbeat mc3-investiga-o-at-6h reused ACTIVE,20min, deadline09:30; before04h
read-only/light only, after04h wait for manual test end or user's sleeping notice.
No shutdown/restart permission today. Plan docs/PLANO_PRIORIDADES_2026-09-10.md.
Last old visual frame22140 interleaved; prior intact22080 has frontend entry
counts and guestPadReadCalls1640 despite padReads0. Do not infer input failure
or no transition from that zero/bootPhase label. Next: reconcile progression
and late visual frame, then only a targeted, causal correction.

## Closed 2026-09-09 07:46 - user requested shutdown after run

Visual run ended07:39:28, controlled600.988s,CPU205.266s; no early exit.
No mc3_partial process at07:45. Analyzer:820completed,707matched allnormal
5282bc;CV4.917s/token110.259s. One invalid log row61867; noisy trace means
do not compare aggregate performance with quiet A/B. Capture remains legal/logo.
User asked to shut down PC after completion, superseding work-until08h.
Pause heartbeat and request Windows shutdown after this checkpoint. No new runs.
Next session: inspect boot progression beyond one-shot capture; remaining
token/work costs, not another watchdog change. Experimental bridge defaultOFF.

## Active 2026-09-09 07:33 - same-binary OFF confirms targeted wait; visual ON running

07:36: Atlas version3 published private, deployment succeeded; exact IDs in
RESULT_GS_IRQ_BRIDGE. New capture exists and inspected: legal/logo already
seen historically, no new visual stage. Dump is one-shot, not final-state proof.
Runtime baseline preserved073444 with explicit new GS headers. Visual34602
still running until~07:39. Next wake: analyze CLOSED visual log/result first;
do not repeat run or rebuild blindly. Last live sample pc4f94b4 is inside
FUN004f93a8, historical label zipHandle::Read; sample alone is not a hang.
Next narrow question: bootPhase/file-read progression and remaining token/work
cost after corrected wait. Maintain defaultOFF, stop new work at08h.

OFF completed07:18:48:86waits/85matched allwatchdog5295dc, medianCV866.7722ms.
ON779waits/682matched allnormal5282bc, medianCV8.625ms. Same hashes/settings
except gate/dump names; not FPS or boot acceptance. Experimental defaultOFF.
VisualON gs_irq_bridge_visual_r1_20260909 started07:29,session34602,600s,
BOOT_TRACE1 and dump threshold100000. Wait before another run. Site next
update must distinguish targeted wait fix from unconfirmed visual progress.
Deadline08h. Details docs/RESULT_GS_IRQ_BRIDGE_2026-09-09.md.

## Active 2026-09-09 07:12 - bridge ON succeeded at wait target; OFF control running

ON gs_irq_bridge_r1 closed06:57:779waits,682matched notifications allnormal
5282bc;CV7.723s median8.625ms vs prior868.15ms. IRQsample780finish/dispatch.
Not100xgame/FPS and no visual yet. Worker779iterations completed,errors0.
OFF SAME EXE control gs_irq_bridge_off_r1 started07:09,harness94285,600s.
Check result before next run. After control, visualON run WITHOUT QuietBootTrace
(it disables LogBootTraceFrame entirely, explaining missing captures).
Do not compare noisy visual run timing toquietA/B. No more builds needed now.
Details docs/RESULT_GS_IRQ_BRIDGE_2026-09-09.md. Deadline08h unchanged.

## Active 2026-09-09 06:47 - GS IRQ bridge first trial

Experimental MC3_GS_IRQ_BRIDGE implemented,defaultoff. Per-memory atomic
sidecar (ABI layout unchanged), realFINISH pending/mask, CSRread/ack/reset,
IMRsyscall/MMIO and existing IRQtick cause0 dispatch. No forced semaphore.
New tests328/328 OFF and328/328 ON in sequential reruns after initial failures;
full details docs/RESULT_GS_IRQ_BRIDGE_2026-09-09.md. Relink99323 PASS,
gate string verified in exe. Started600s gs_irq_bridge_r1_20260909 with gateon
and FrameDumpMinPrims100000. Deadline08h/heartbeat active remains.

## Active 2026-09-09 06:27 until08h - correction and atlas

Cloud extended autonomous work until08:00; heartbeat sameid active with
new deadline/prompt. Headless bounded runs allowed without repeated go.
Next priority GS FINISH cause0 opt-in delivery fix with synchronized state,
CSR/IMR including syscalls/ack/reset, tests and10min comparison; no forced
semaphore or shortened watchdog. No new runtime change in atlas update.
No recent visual capture exists; historical legal/Dolby/transitions only.
Atlas recollected counts unchanged; status section added,version2 published
privately, deployment succeeded06:27:22. Existing tab preserved.
Full continuation:docs/LOTE_ATE_08H_2026-09-09.md. Stop/pause at08h.

## Checkpoint 2026-09-09 06:21 - IMR coverage run completed

gs_imr_r1 ended06:20:22 controlled601.029s;216.531sCPU;0MC3afterward.
56valid GS records,0invalid. FINISH n256 with dispatch0/entry0; IRQ sample
tick32768 enabledMaskffffffff/onehandler. IMR syscall changedff00→fc00
before first FINISH and sampled later old/new low bits stayedfc00.
Coverage caveat: sampled events are not continuous mask history.
258waits,257matched notifications allwatchdog005295dc:1;CV223.069s,
token21.801s. No normal5282bc producer, no behavior fix/FPS claim.
Next: opt-in real GS cause0 delivery with synchronized per-instance state,
CSR/IMR/ack/reset coverage and tests, then bounded comparison. Never direct
SignalSema/shortened alarm. Old heartbeat stays PAUSED. Full report and
binary hashes:docs/RESULT_GS_IMR_2026-09-09.md.

## Resumed by user go 2026-09-09 06:08 - IMR syscall coverage

New bounded lot authorized after prior deadline. Old heartbeat stays PAUSED.
Baseline work/patches/legal_phase_baseline_20260909_060851 plus explicit
gs_finish_probe.before.h and Analyze-GsFinish.before.js. Added passive
ImrSyscall(kind8:new,old) and Reset(kind9) events, no behavior changes.
Build completed; gate0/1 and parser tests PASS; runtime326/326 PASS;
relink35062 PASS timestamps/identity. Started600s headless gs_imr_r1_20260909.
Check result file and analyze closed stderr; no second run implied.

## Closed 2026-09-09 06:04 America/Sao_Paulo

Deadline reached. Heartbeat mc3-investiga-o-at-6h PAUSED, confirmed by app.
No MC3/cc1plus found at closure; no process termination required, no new
experiment after deadline. Diagnostic result and bounded next lot:
docs/RESULT_GS_FINISH_WATCHDOG_2026-09-09.md. No validated behavioral fix.
Resume only with new user direction; first cover direct GsPutIMR mask writes.

## Closing check 2026-09-09 05:53

No MC3/cc1plus found. Latest result and next step verified in
docs/RESULT_GS_FINISH_WATCHDOG_2026-09-09.md. No new experiment this wake.
Heartbeat still ACTIVE until deadline; next wake at/after06:00 must only
pause mc3-investiga-o-at-6h and record closure, not resume diagnostics.

## Checkpoint 2026-09-09 05:43 - GS FINISH observed, no cause0 delivery

gs_finish_r1 completed05:30:32,601.083s controlled,214.094sCPU; no MC3 at05:41.
IRQ snapshot32768:206FINISH,0cause0 dispatch/entry,enabledMaskffffffff,
one enabled cause0 handler.251completed waits,250notifications allwatchdog
005295dc:1;CV217.079s/token8.361s. Not a performance comparison.
Parser recovered8 prefixed interleaved events:37valid now,testsPASS.
IMPORTANT missing coverage: GsPutIMR/iGsPutIMR in System.cpp directly write
gs().imr, bypassing MMIO hooks. No ImrWrite does NOT prove GS unmasked.
Next complete syscall mask probe before opt-in delivery fix/validation.
No behavioral fix, no further build/run authorized. Under20min to deadline:
close/document only; pause heartbeat at06:00. Full evidence/provenance in
docs/RESULT_GS_FINISH_WATCHDOG_2026-09-09.md.

## Active 2026-09-09 05:20 - authorized GS FINISH passive run

User go authorized new headless10min probe. Baseline preserved in
work/patches/legal_phase_baseline_20260909_051614 (runtime binary diff,
old exe/lib and prior sources). New gate MC3_GS_FINISH_TRACE records real
FINISH events, CSR low reads/writes, IMR low writes, IRQ mask/handler count
under existing mutex and cause0 dispatch/handler steps. No delivery fix.
Samples first8/powers-of-two, process counters; snapshots not coherent and
not final totals. Does not instrument unsupported8/16-bit GS MMIO paths.
Standalone gate0/1 PASS; runtime build12946 completed;326/326 tests PASS;
relink99342 PASS timestamps/old markers; new marker/gate verified in exe.
Parser tests PASS. Started gs_finish_r1_20260909 at05:20 for600s headless.
Read work/logs/probe_gs_finish_r1_20260909.log.result.json before next action;
analyze closed stderr with tools/Analyze-GsFinish.js and Analyze-LegalSema.js.
No new run authorized beyond this one. Deadline06:00 remains.

## Checkpoint 2026-09-09 05:13 - GS FINISH delivery candidate, offline audit

legal_notify_r1 completed at04:41: 258completed waits,257blocked; all257
matched first notifications producerRA005295dc (watchdog), runtimeTID1.
Offline analyzer rerun and parser tests PASS; invalidLines0. CV223.058s,
token6.398s. Alarm13440 H-SYNC ticks at64us gives860.16ms, not a proven
clock conversion defect. Normal completion handler528260 checks/acks GS
CSR FINISH and signals same sema atRA5282bc; absent from matched authors.
Init52904c registers this handler for INTC cause0, NOT cause2 (previous
registration is5280b8). GS FINISH sets CSR but inspected IRQ dispatcher
calls only causes11/2/3. Missing GS IRQ delivery is a candidate, not yet a
validated behavior fix; actual FINISH arrival/mask during waits unmeasured.
No new build/run/runtime edits in this offline audit. Headless execution
requires a new user question per current heartbeat. Preserve baseline and
measure FINISH arrival, mask and cause0 delivery before claiming causality.
Details:docs/RESULT_GS_FINISH_WATCHDOG_2026-09-09.md.
Deadline06:00 remains; pause heartbeat then. No game/compiler active at05:10.

## Active 2026-09-09 until06:00 America/Sao_Paulo - legal phase timing

Cloud authorized continued work until06h. Heartbeat mc3-investiga-o-at-6h
active in this task; pause at deadline. legal_phase_r1 completed:258paired
iterations,check3.229s/work437.057s of442.498s worker;errors0,duplicates0.
Initial wait275.490s is shorter than worker lifetime; do not equate intervals.
New detail hooks split work1aad28 into eight calls; tests/compile/opcodesPASS.
legal_detail_r1 completed:5295f0=248.385s,1ac2a0=189.109s ofwork444.484s;
258paired calls,errors0. No MC3 at03:29. New leaf hooks measure two waits
inside5295f0 and320b38/320fd0 inside1ac2a0. Tests/4ownercompilePASS;
relink61831PASS,leaf marker verified. legal_leaf_r1_20260909 headless600s
completed,harness61846done:WaitSema529690=244.868s/258calls of5295f0=262.287s;
320b38=152.152s,320fd0=80.838s. No MC3 at03:53. New independent legal-sema
lane splits CV/token using existing Sync hooks;tests326/326PASS,build52297done.
legal_sema_r1 completed30363:258waits total234.683s,CV223.136s/token11.546s.
257blocked CV860.8..876.9ms;notify->CV0.005..0.1325ms. No MC3 at04:17.
New first-notification producerRa/Tid probe in Sync/header;unitPASS;
build82202done. Test17218 couldn't launch(file busy); rerun44682PASS326/326.
Analyzer/testPASS. Relink2807done,legal-notify marker verified. At04:31 started
headless600s legal_notify_r1_20260909,harness66162;check result before next run.
Full continuation:docs/LOTE_ATE_06H_2026-09-09.md. No behavior fix yet.

## Checkpoint 2026-09-09 - initial wait producer correlated offline

Existing r1/r2 logs identify legal worker signal SID200/79, state01ea1ff0,
followed by matching worker0 return. Initial270s/326s waits precede accepted
notification; CV return after notification0.0079/0.0464ms. Producer1aab90
signals state+4000 through398b40. Next measure loop1aabe0->1aac70->1aad28,
repeat at1aabf4 while saved return is zero. No new runtime/build/run or fix.
EndOfTransition snapshots precede signal but are fixed-global probes, not
per-script causal timing. Existing script probe scans up to16KiB before
milestone filtering: active overhead unknown. Offline analyzer/tests added,
PASS. Full evidence:docs/RESULT_INITIAL_WAIT_PRODUCER_2026-09-09.md.

## Checkpoint 2026-09-09 - identity/deadline diagnostic completed, no behavior fix

Supersedes the callback-first direction below. Offline historical clock slope
is near nominal globally and in final70s; old log has no now-at-arm and cannot
prove65s unexpired. New passive identity/base/threshold/call probe,326/326 tests,
standalone gate-off/on tests, five owners compiled and relink markers verified.
Two bounded601s headless runs:20/20 observed alarms configured1474560ticks,
first calls matched internal ID/target/wrapper,20 callbacks and20 wakes.
Historical long timer stall did NOT reproduce; root cause remains unresolved.
Six extra calls reused watched addresses with different IDs: confirms ambiguity
of address-only snapshots, NOT causation of old SID214. No semantic fix or FPS/menu
acceptance. Initial separate RA398b28 wait lasted270s/326s; recommended next lot
maps its producer/signal conditions without forcing wake. No third run or MC3
process remaining. About40min used from3h ceiling. Existing dirty work preserved:
work/patches/timer_route_baseline_20260909_014537 and
work/patches/timer_identity_sources_20260909_015409. Full evidence and limits:
docs/RESULT_LOTE_3H_ALARME_BOOT_2026-09-09.md.

## Checkpoint 2026-09-08 - timer-route result recovered, callback boundary next

Recovered the completed 601.024s run from Sep06 (report was still pending).
Five complete armed records, four callbacks/wakes; final SID214/alarm0703e0d3
remains cv-wait65023ms. Timer2 due/dispatch grow14832->18659 with masked0.
Final selection sample matches watched entry00701e00 and early0, but pointer
reuse and separate snapshot banks do not prove alarm identity. Next: correlate
loaded callback target/arguments and return PCs across54ce8c/54cd70/54ced0,
then wrapper54d640. Not a stopped-clock diagnosis; no forced wake or scheduler
fix. New read-only tools/Analyze-TimerRoute.js; full evidence and limitations in
docs/RESULT_TIMER_ROUTE_2026-09-06.md. Runtime unmodified in this recovery turn;
prior uncommitted probe changes preserved. Dashboard is separate progress/ repo.

## Checkpoint2026-09-06 18:53 - resumed, alarm stall with live IRQ worker

User resumed.325/325 tests,100 owner opcode annotations matched ELF; bounded
IRQ-only edge-history probe in generated54cb58, using already-loaded next and
register scalar copies. No guest behavior change.601.0087923s run: no sampled
positive traversal steps; no runtime cycle claim. Pending SID116/alarm0703e02b
for36.317s, no callback, while IRQ tick33686->35787 continues. Different from
prior frozen54cc08 tick. Next: Timer2 control/count/compare + guest alarm
deadline/selection, not forced signals or scheduler fixes. Initial322.326s,
57 timer WaitSema completions,42b150Calls0,only2initialFEwrites. No process
remaining or menu/FPS acceptance. Full hashes/source reproduction and limits:
docs/RESULT_IRQ_LIST_2026-09-06.md.

## Paused by user - 2026-09-06 08:09

Session closed; no MC3 process running. Resume only on user request.
Full session index, exact binary, remaining questions and next bounded task:
docs/CHECKPOINT_FIM_DO_DIA_2026-09-06.md.

## Checkpoint 2026-09-06 08:04 - IRQ worker stuck in Timer2 traversal

324/324 tests after link completed. Passive normal-worker tick/stage/lookup
snapshots; no behavior change.601.3939244s probe: tick25856 frozen at least153.882s,
cause11/54cc08 repeated with age0 (resumed traversal, not fixed lock-wait age).
List cycle/corruption NOT proven. Historical54cc08 hypothesis was already limited
to some runs; do not generalize. Initial257.446s wait had clock advancing. Both
focused timer waits completed; final wait DIFFERENT SID43/RA529790.42b150Calls67,
animation2,no menu/FPS acceptance, no process remaining. Next: bounded node-value
observation + ELF check inside54cc08, no forced return or timer/scheduler changes.
Evidence/provenance:docs/RESULT_IRQ_PROGRESS_2026-09-06.md.

## Checkpoint 2026-09-06 07:29 - separate semaphore latency stages

Passive Sync.cpp/header hooks,323/323 tests. Probe601.027926s completed and
owned process stopped.34 completed timer waits total9.147s:8.070s token,
1.077s CV; worst token769.211ms. Initial SID220 wait272.093s preceded signal,
token only0.206ms. Final SID22/alarm0703e019 armed but no callback/signal/wake
observed, last cv-wait age122503ms. Need queue/worker/token-before-callback
diagnosis, not a forced signal or scheduler policy change.2 initial FE writes,
42b150Calls0, no menu/FPS acceptance. Reproduce/hashes/limitations:
docs/RESULT_SEMA_LATENCY_2026-09-06.md; tools/Analyze-SemaLatency.ps1.

## Checkpoint 2026-09-06 07:04 - timer correlation, no behavior change

Legacy timer trace aborted intentionally after95s because global caps16/24
were exhausted early. New MC3_TIMER_WAIT_TRACE filters main wrapper and matches
callbacks by semaphore; no guest-context pointers or new locks.322 general
tests and standalone probe lifecycle/TLS tests passed. timer_focus_astra_20260906
completed600.909s.9/9 requested10ms waits signaled/woke;57..739ms total each,
0..477ms after signal-return.3.302s total does NOT explain entire run. Initial
SID12 wait reached347552ms separately. Previous218s timer stall not reproduced.
42b150 now invoked85times;5 recovery records remain, targets5bb238/5bb268.
FE14,11updates,no visual/menu/FPS acceptance. No game running. Next: correlate
semaphore notification with guest-token reacquisition, retaining initial-wait
investigation; no scheduler change or forced signals. Full evidence/reproduce:
docs/RESULT_TIMER_WAIT_2026-09-06.md.

## Checkpoint 2026-09-06 06:23 -42b150 restored, timer wait blocks runtime coverage

Runtime3fb78c5 implements exact29-word42b150 body through owner42b140 alias.
322/322 general tests,37 native cases (24 ELF-opcode oracle +2 nested caller
paths added) passed. list_entry_astra_20260906 completed600.8718s,no early exit.
entry42b150Calls=0: corrected body was NOT exercised during boot. Only2 initial
FE writes,no animation. No bad records is NOT missing-call acceptance.
After initial333193ms SID256 wait, main remained in SID21cv-wait at RA5476b0,
dispatch322ffc,age218843ms. Static chain arms alarm then waits. Next: existing
MC3_TIMER2_TRACE (wait-enter/alarm-armed/wait-woke), correlate alarm/callback/
SignalSema without bypass. No game running; no menu/FPS acceptance. Current
exe remains the exact probe hash; reproduction and result:
docs/RESULT_LIST_ENTRY_2026-09-06.md.

## Checkpoint 2026-09-06 05:57 - seven-entry batch

Restored5b94f0/5b94f8/5b9990/5b9998 exact jr-ra/nop and dispatch hooks into
existing501268/5012c0/42bf00 bodies.322/322 runtime tests and11 generated-object
cases passed.600s entry_batch_astra_20260906 completed601.2495s,no early exit.
No missing warnings for seven targets; four NOP counters12 each. FE17,13updates.
256 recover-pc records hit print cap; first new42b150 RA42bf30 confirms actual
42bf00 invocation. Also5bb238/5bb268. No menu/FPS acceptance; no MC3 running.
Next: exact42b150 implementation and nonzero-count42bf00 integration test.
Ignored source reproduction, binary hashes and limitations:
docs/RESULT_ENTRY_BATCH_2026-09-06.md; tools/Verify-EntryBatch.js and
tools/Test-EntryBatch.ps1. No scheduler/network behavior changes.

## Checkpoint 2026-09-06 04:50 - zero-return restored

Exact5c3a48 jr-ra/daddu-zero implemented via owner5c3a68 and regenerated alias.
321/321 tests; zero_return_astra_20260906 completed601.078s without early exit.
Corrected leaf executed2372 times by final sample; zero bad5c3a48 warnings.
FE18 (14 animation updates);256 recovery-containing lines hit the print cap.
First missing target5b9990;501268/5012c0 also observed. No menu/FPS acceptance.
No MC3 remains running. Next: bounded remaining-entry audit and faithful fixes,
not generic returns or scheduler/network changes. Generated owner is ignored;
reproduction, hashes and full result: docs/RESULT_ZERO_RETURN_2026-09-06.md.

## Checkpoint 2026-09-06 03:21 - verified leaf restored

Exact2300d0 jr-ra/nop implemented via compiled owner2300d8 and regenerated alias.
320/320 tests;601.002s probeverified_leaf_astra_20260906 endednormally bytimeout.
No bad2300d0 record; nextfirstbad5b9990. FE13,256recovery-containinglines(cap),
no menu/FPS acceptance. No MC3 remains running. ELF5c3a48 has0000102d in delay
slot: returnszero, NOTnop; faithful remaining-entry repair is next priority.
Tracked build guard/reproduction:tools/Compile-VerifiedLeaf.ps1 and
docs/RESULT_VERIFIED_LEAF_2026-09-06.md. Generated owner remains ignored.

## Checkpoint 2026-09-06 02:20 - main wait / registration gap

319/319 tests; main_wait_astra_20260906 completed601.297s,no early exit.
Main SID13cv-wait reached361874ms then returned; FE advanced to11. No deadlock
or FPS acceptance.256 recovery-containing lines (print cap), also in previous
quiet control. First target2300d0 is ELF jr-ra/nop absent from catalog/register;
later targets require independent audit. Next: faithful missing-entry repair,
not generic return stubs. No game running. Full evidence:
`docs/RESULT_MAIN_WAIT_2026-09-06.md`.

## Checkpoint 2026-09-06 00:46 - Astra

Current workspace: `<project-root>`.
Quiet same-binary control900s completed; network overlap422/429s late token wait.
New callback profiler runtime1fc7b08,318/318 tests;600s probe observed target001b84e8,
468completed callbacks,411ms mean inclusive wall. Main token counters stopped
growing and no animation updates in this probe: do not treat it as performance
acceptance or reuse the previous run's attribution. Both runs stopped by harness.
Next: main wait-kind/dispatch-PC snapshot and separate nested child-call timing.
Reproduction and limitations: `docs/RESULT_WAIT_QUIET_2026-09-06.md`.

Workspace: `D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp`

Game: Midnight Club 3 - DUB Edition Remix  
Serial: `SLUS_213.55`  
ELF: `extracted_iso\SLUS_213.55`  
Partial runner: `work\link\partial\mc3_partial.exe`

## Checkpoint 2026-08-01 06:20:19-06:21:20

- Lote grande de 60s estavel em `0x5419a0`; `render-started`, `dma=2 gif=0 gsw=0 vif=3`.
- Verificacao estrutural passou; trace focalizado preparado para o proximo lote.

## Checkpoint 2026-08-01 06:28-06:31

- Trace confirmou `FUN_005422c8` gravando `0x61fbb4=1`; sem isso o fluxo para em `0x5419a8`.
- Experimento env-gated `MC3_EXPERIMENT_5422C8_SKIP_LATCH=1` foi testado por 20s: continuou em `0x5419a8`, `gif=0 gsw=0`; bypass rejeitado.

## Checkpoint 2026-08-01 06:34-06:40

- Gates experimentais chegaram a `0x2b4488`; trace do provider mostrou objeto `0x6772f0`, vtable `0x6321e0`, metodo `0x429fc0`.
- O metodo retorna `v0=0` com `0x619f40=0`; provider nao inicializado. `gif=0 gsw=0`.
- Proximo alvo documentado: `FUN_00447928 -> FUN_003c8cf8 -> FUN_004faa10`, produtor da flag `0x619f40`.

## Correção de evidência 2026-08-01

- `texture.zip` não existe na ISO/pasta atualmente inspecionada. Menções antigas são hipótese/string live não confirmada, não causa provada.
- Registro completo: `docs\ASSET_EVIDENCE_CORRECTION_2026-08-01.md`.

## Checkpoint 2026-08-01 07:10

- A ISO local possui `ASSETS.DAT`, `STREAMS.DAT`, `TEXTURE.DAT` e `BANKS.DAT`; tamanhos e cabecalhos foram confirmados diretamente.
- O ELF referencia esses quatro conteineres via `cdrom0:`; o runtime resolve `cdrom0:` para `extracted_iso`, onde eles existem.
- Trace em `FUN_00447928` nao apareceu no probe: a rota que deveria marcar `0x619f40` ainda nao e alcancada. Relink passou; sem GIF/GS (`gif=0 gsw=0`).
- Proximo alvo: achar o chamador/registro indireto de `FUN_00447928` ou a inicializacao equivalente, mantendo todos os experimentos env-gated.

## Master Plan

Ordered execution plan, gate anatomy, and anti-hallucination rules: `docs\MASTER_PLAN_TITLE_SCREEN.md` (2026-07-07). Start there.

## Current Objective

Reach visible render/menu in the native partial runner by comparing the recomp boot probe against live PCSX2 behavior.

## Current Recomp Probe

Command:

```bat
15_auto_boot_probe.bat 8 595
```

Latest known status:

- classification: `render-started`
- stable PC: `0x245720`
- function: `sub_00245680_0x245680`
- counters: `dma=2 gif=0 gsw=0 vif=3`
- current blocker: outer loop still waits because `FUN_005422c8_0x5422c8` returns `0`

## Live PCSX2-MCP Plan

Use PCSX2-MCP to observe the real game at the same boot stage, then compare return values, memory writes, and SIF/IOP completion behavior against the recomp trace.

Primary live targets:

- stable recomp PC: `0x245720`
- suspect functions: `0x5422c8`, `0x5420c0`, `0x541760`, `0x541968`, `0x549680`
- suspect memory: `0x0061FC00`, `0x00620D50`, `0x00620D80`, `0x00621600`
- registers: `pc`, `ra`, `sp`, `gp`, `v0`, `a0`, `a1`, `a2`, `a3`, `s0`, `s1`, `s2`, `s3`

## Guardrails

- Gemini/PCSX2-MCP performs read-only live inspection.
- Codex edits runtime/recomp only after live evidence points to a minimal experiment.
- SIF/IOP changes stay env-gated until proven against live PCSX2 behavior.
- Do not launch PCSX2 fullscreen from automation.

## Checkpoint 2026-07-11 05:42 (pausa / registro)

- Objetivo parcial: manter recompilation pronta, com avanço de debug sem correr mais etapas automáticas nesta sessão.
- Status atual do runner: `classification=missing-function`, `Stable PC=0x246740` em `FUN_002466e0_0x2466e0`, render counters `dma=0 gif=0 gsw=0 vif=0`.
- Evidência do travamento: `[dispatch:first-bad-pc] bad=0x42eb90`.
- Mapeamento ativo de stubs faltantes: `work\link\partial\missing_functions.partial.manifest.csv` ainda traz 9 endereços em `batch_0015`:
  - 0x002A4AE0, 0x002A4B98, 0x002A4C18, 0x002A4C68, 0x002A4D68, 0x002A4D78, 0x002A4DC0, 0x002A4E08, 0x002A4F40
- Estado dos objetos: esses símbolos ainda não têm `.o` compilado em `work\compile\ghidra\batch_0015\obj`.
- Registrado por solicitação do usuário: parada momentânea para descanso.
- Próximo passo ao retomar: compilar `batch_0015` (syntax + object), relinkar (`10_link_partial_runner`), rerodar `11_run_partial_runner` + `14_run_boot_trace` + `15_auto_boot_probe`.

## Checkpoint 2026-07-14 10:00 (Investigação Gemini)

- **Status:** Auditoria de retomada e diagnóstico do pipeline de linkagem concluídos com sucesso.
- **Descobertas:** O runner travou no PC `0x2b4488` devido a problemas de package/texturas. O build do `batch_0015` está pendente de 9 objetos, o que impede a linkagem do runner parcial.
- **Documentação:** Nova auditoria detalhada criada em `docs\GEMINI_RECOMP_STATUS_2026-07-14.md`.
- **Ações Imediatas Recomendadas:**
  1. Compilar stubs: `09_compile_generated_batch.bat batch_0015 250 object`
  2. Relincar runner: `10_link_partial_runner.bat`
  3. Rodar boot probe: `15_auto_boot_probe.bat 6 payload1m3skip5a`

## Checkpoint 2026-07-22 07:35 (pausa / pendente)

- Objetivo parcial: testar o menor passo seguro antes de continuar rumo ao render funcional.
- Teste feito: compilacao direta de 1 funcao faltante do `batch_0015`.
- Achado de ambiente: `g++`/`cc1plus` falhava sem mensagem quando `C:\msys64\ucrt64\bin` nao estava no `PATH`.
- Correcao usada no teste: prefixar o comando com `$env:PATH='C:\msys64\ucrt64\bin;' + $env:PATH`.
- Resultado OK: gerado `work\compile\ghidra\batch_0015\obj\sub_002A4AE0_0x2a4ae0.o`.
- Ainda pendente: 8 objetos do `batch_0015`:
  - `sub_002A4B98_0x2a4b98.o`
  - `sub_002A4C18_0x2a4c18.o`
  - `sub_002A4C68_0x2a4c68.o`
  - `FUN_002a4d68_0x2a4d68.o`
  - `FUN_002a4d78_0x2a4d78.o`
  - `sub_002A4DC0_0x2a4dc0.o`
  - `FUN_002a4e08_0x2a4e08.o`
  - `FUN_002a4f40_0x2a4f40.o`
- Proximo passo ao retomar: compilar os 8 objetos restantes com o `PATH` ajustado, relinkar (`10_link_partial_runner.bat`) e depois tentar avancar o boot probe/render.

## Checkpoint 2026-07-28 (auditoria Claude + handoff Gemini)

- **Achado:** os 8 objetos pendentes do `batch_0015` (listados no checkpoint anterior) **já foram compilados** — timestamp `2026-07-28 00:17`, summary CSV com 250/250 linhas, exit code 0. O checkpoint anterior está desatualizado nesse ponto.
- **Achado:** já houve uma tentativa de relink hoje às 00:17 que **não completou** — `work\logs\10_link_partial_runner_driver.log` só tem a linha de início, `work\logs\10_link_partial_runner.log` está vazio, e `mc3_partial.exe` continua com timestamp de 11/07. Causa ainda não diagnosticada (script pode ter sido interrompido antes de logar).
- Gemini recebeu um novo plano hoje (`docs\RECOMP_PLAN_2026-07-28.md`), auditado em `docs\AUDIT_RECOMP_PLAN_2026-07-28.md` (score 6.5/10 — diagnóstico do vtable+0x24/texture.zip é bom, mas a etapa de recompilar `batch_0015` estava obsoleta).
- Handoff ativo para Gemini: `docs\GEMINI_HANDOFF_2026-07-28.md` — 3 tarefas: (1) destravar o relink (não recompilar batch_0015 de novo), (2) causa-raiz do `texture.zip` handle inválido, (3) **pedido novo do usuário**: investigar e mapear a função de reprodução de vídeo/FMV do jogo para poder pular todos os vídeos (logos/cutscenes) — só investigação por enquanto, sem patch cego.
- Próximo passo ao retomar: ler o handoff de 28/07, confirmar se o relink terminou e qual o novo Stable PC do boot probe.

## Checkpoint 2026-07-28 01:54 (relink confirmado, gate não mudou)

- **Gemini executou a Tarefa 1 do handoff e teve sucesso real** (verificado por mim, não só relatado): `mc3_partial.exe` relinkado às 01:05, `missing stub functions = 0` (antes eram 9), `15811` funções registradas, `168089` aliases de PC. Gemini ficou sem quota (`Individual quota reached`) logo depois, no meio do teste do `11_run_partial_runner.bat`.
- **Eu retomei e rodei o boot probe** (`15_auto_boot_probe.bat 8 payload1m3skip5a`) contra o exe novo. Resultado: **Stable PC continua `0x2b4488`** em `sub_002B4438_0x2b4438`, counters idênticos (`dma=2 gif=0 gsw=0 vif=3`). **O relink do batch_0015 não moveu o gate** — essas 8 funções não estavam no caminho crítico do boot atual, mas o relink ainda era necessário (mantinha o manifest/exe desatualizados).
- **Nota (corrigida):** não encontrei `handle=0xffffffff`/`texture.zip` no `work\logs\14_run_boot_trace.log` de hoje, mas confirmei a origem: veio de inspeção **live via PCSX2-MCP** no jogo real, registrada em `docs\SESSION_2026-07-10_PCXS2_MCP_SID44.md` (linhas 105-112) — não é alucinação nem doc-drift, é evidência real só que não aparece no trace do recomp porque o runner nativo trava em `0x2b4488` antes de alcançar esse ponto do fluxo. Válido para orientar a Tarefa 2, mas o vínculo causal entre `0x2b4488` (recomp) e a falha de `texture.zip` (live) ainda não foi provado — só ambos aparecem "perto" na linha do tempo do boot.
- Próximo passo ao retomar: Tarefa 2 do `docs\GEMINI_HANDOFF_2026-07-28.md` — investigar estaticamente `sub_004FAED8_0x4faed8`/`sub_004F9A68_0x4f9a68` e as flags `0x629f40/41/4c` no código gerado do recomp, e comparar com o provider real via PCSX2-MCP (`0x619f58`, `0x4f9760`, backend table `0x617fc0`) para confirmar se é o mesmo caminho. Tarefa 3 (skip de vídeo) segue pendente, ainda não investigada.

## Checkpoint 2026-07-29 (gate moveu; plano de 10 etapas + guarda de regressão)

- **Progresso real:** Stable PC saiu de `0x2b4488` e agora estabiliza em **`0x5a8908`** (`sub_005A8898_0x5a8898`, caller único `sub_004BD488`). O loop novo chama `func_398400` (backend open), `sub_003B14D0`, `sub_004F9A68` (provider) — confirma que o bloqueio atual É a frente provider/package. Counters seguem `dma=2 gif=0 gsw=0 vif=3`.
- Gemini produziu: `SEMA_17_INVESTIGATION_2026-07-28.md` (concluído: não injetar SignalSema(17), produtor é a própria `sub_005420C0`), `PLAN_PHASE_PROVIDER_2026-07-28.md` (gates A-D), `INVESTIGATION_BATCH_PLAN_2026-07-29.md` (PRD Ralph em `.agents\tasks\` — **ainda não executado**, `.ralph\progress.md` não existe).
- **Novo plano mestre operacional: `docs\PLAN_10_STEPS_2026-07-29.md`** — 10 etapas com teste de aceite cada, integrando os planos da Gemini + lane FMV + critério de vitória (`gif/gsw > 0`).
- **Nova automação:** `20_verify_boot_state.bat` + `tools\Verify-BootState.ps1` — guarda de regressão (exe não-stale, 0 stubs, classificação, PC esperado/progrediu, string de experimento no exe, check `real-render-traffic`). Baseline atual: `20_verify_boot_state.bat 0x5a8908` → PASS.
- Próximo passo ao retomar: etapas 2 e 3 do plano de 10 etapas (anatomia do loop `0x5a8908` + mapa de produtores de `0x629F44`) — só leitura, paralelizáveis via Gemini/Ralph.

## Checkpoint 2026-08-07 (AUDITORIA CRÍTICA — o probe não mede)

**Leia `docs\STATUS_2026-08-07_AUDIT.md` antes de qualquer coisa.**

- **Achado que muda tudo: o boot probe não é determinístico.** 5 corridas do mesmo binário, mesmo modo (`595`), mesma duração deram **5 Stable PCs distintos e 4 classificações distintas** (`unknown-loop`, `missing-function` x2, `render-started` x2). Uma corrida devolveu Stable PC `0x3` (endereço inválido) e ainda assim foi classificada `render-started`. Evidência: `work\boot_probe\repeat_baseline_20260807_20260807_013345.md`.
- **Consequência:** o critério "Stable PC mudou = progresso", usado como base de decisão dos lotes 13→21, estava medindo ruído. O estado `0x5a8908 / dma=2 vif=3` que os relatórios de 28/07 a 03/08 tratam como "o estado do projeto" é apenas **um dos cinco resultados possíveis** — reproduzi ele na run 5 de 5.
- **Não há vitória visual.** `gif=0 gsw=0` em 100% das corridas de hoje (11 no total). Nada foi renderizado.
- Gap de dispatch `0x42eb48` confirmado: `sub_0042EB08_0x42eb08.cpp` (regenerado 01/08) tem casos para `0x42EB24/28/2C/84/90/CC` mas **não** para `0x42EB48`. O patch manual de 17/06 cobria `0x42eb48` e `0x42eb90`; a regeneração apagou metade. Aparece como `first-bad-pc` em 100% das corridas. **Não é a causa da não-determinância** — é dívida separada.
- **Nova automação:** `21_probe_repeat.bat N modo label [ENV=V]` + `tools\Probe-Repeat.ps1` — roda N probes, agrega e declara se o Stable PC é utilizável como métrica. Use N≥5 em todo experimento a partir de agora.
- `20_verify_boot_state.bat` retorna **FAIL** hoje (classification=missing-function) — a guarda está funcionando corretamente.
- **Handoffs criados:**
  - `docs\HANDOFF_2026-08-07_A_DETERMINISM.md` — **bloqueador de tudo**, achar e eliminar a fonte de variação + corrigir o classificador.
  - `docs\HANDOFF_2026-08-07_B_DISPATCH_0x42EB48.md` — fechar o gap e impedir que regeneração apague patches manuais (paralelizável).
  - `docs\HANDOFF_2026-08-07_C_PROVIDER.md` — frente provider **travada** até A entregar; tarefas de leitura C1/C2 liberadas.
- Próximo passo ao retomar: Handoff A. Não abrir frente nova antes de fechar a medição.

## Checkpoint 2026-07-28 ~06:04 (Gemini — gate desbloqueado)

- **GATE MOVEU:** Stable PC saiu de `0x2b4488` → `0x2455f0` em `sub_00245568_0x245568`.
- **Causa-raiz confirmada (Tarefa 2):** O experimento `MC3_SIF_EXPERIMENT_REQ4_620D80_STATUS=1` **já existia** no modo `req4` do probe mas o último probe registrado tinha sido rodado com `payload1m3skip5a` (sem o `req4`). Ao rodar `15_auto_boot_probe.bat 8 595` com o modo `pollsid59c595ret2mode9payload1m3skip5areq4`, o request `0x4→0x620d80` passou a retornar `value=1` e o gate `0x2b4488` foi desbloqueado.
- **Análise da flag `0x619F40`:** Confirmado que é a flag de inicialização do provider de pacotes. Escrita por `FUN_004fa7a8_0x4fa7a8` (`sb $a0, -0x60C0($v1)`). Lida por `sub_004FAED8_0x4faed8` no boot do provider.
- **Tarefa 3 (vídeo/FMV):** Nenhum arquivo `.pss/.str/.mpg/.bik` visível no código gerado — confirma que vídeos estão dentro dos pacotes. `kMc3MovieCommitCallback = 0x00541348` e `kMc3MovieReplyCallback = 0x005413F0` são os callbacks de vídeo no `SIF.cpp`. Investigação mais detalhada pendente.
- **Novo gate:** `sub_00245568_0x245568` @ `0x2455f0` — loop `bne $v0, $s0` onde `$s0=2`, chamando `FUN_005420C0(1)` repetidamente. `FUN_005420C0` precisa retornar 2. Loop interno depois em `label_245608` chama `func_5424A8` esperando retorno == 1.
- **Próximo passo ao retomar:** Investigar `FUN_005420C0_0x5420c0` — o que ela verifica para retornar 2? É um estado de inicialização de sistema de áudio/render/subsistema? Comparar com PCSX2-MCP live. Depois olhar `func_5424A8` que é o segundo wait do mesmo boot step.

## Checkpoint 2026-08-01 (Investigação Etapas 2 e 3 Concluída)

### Continuidade do lote — 2026-08-01 06:09

- `sub_005420C0` observado retornando `0x6` no loop `0x2455f0`, que exige `0x2`.
- Experimentos env-gated `req4ret2` e `req4ret2ret1` avançaram pelos gates `0x245734` e `0x546d60`.
- Corrigido o dispatcher interno de `sub_0042EB08` para o retorno `0x42eb90`; batch `0036` e relink passaram com `0` stubs.
- Probe de `06:09:14–06:09:27` chegou a `0x5424c8` (`sub_005424A8`); verificação passou, mas `gif=0 gsw=0`.
- Detalhes e próximo comando: `docs\SESSION_2026-08-01_BATCH_CONTINUATION.md`.
- `06:10:15–06:10:28`: novo probe chegou a `0x238924` (`sub_002388F8`); verificação passou, `gif=0 gsw=0`.
- `06:12:58–06:13:18`: lote de 20s chegou a `0x5494e0` (`sub_00549488`); verificação passou. Trace mostra ciclo de `WaitSema` em `0x549640`, sem tráfego GIF/GS.
- `06:14:16–06:14:46`: repetição de 30s regressou a `0x245734`; verificação passou, mas os hacks env-gated ainda não são estáveis por timing.
- `06:18:59–06:19:13`: experimento `req4ret2ret1a8` avançou para `0x5419a0` (`FUN_00541968`); verificação passou. Gate agora aguarda `0x61fbb4` zerar.

- **Investigação da Etapa 2 (Anatomia do Loop `0x5a8908`):**
  - O spin-wait ocorre entre `0x5a8908` e `0x5a891c` (`b 0x5a8908`).
  - **Instrução/Branch decisivo de saída:** `0x5A88F0`: `beqz $v0, 0x5a8908`.
  - **Condição:** Exige que `func_4FA398` (`0x4FA398`) retorne `$v0 != 0`. Se retornar `0`, o fluxo entra em spin-wait perpétuo.
- **Investigação da Etapa 3 (Mapa de Globais do Provider):**
  - Mapeado o endereçamento MIPS real: base `0x00620000 - 0x60C0 = 0x00619F40` (e não `0x629F44`).
  - **Leitura:** `sub_004FAED8_0x4faed8` em `0x4faee8` (`lbu $v1, -0x60C0($v0)`). Aborta se `0x00619F40 == 0`.
  - **Escrita:** `FUN_004fa7a8_0x4fa7a8` em `0x4fa7b8` (`sb $a0, -0x60C0($v1)`).
- **Documentação gerada:** [LOOP_0x5A8908_ANATOMY.md](<project-root>/docs/LOOP_0x5A8908_ANATOMY.md)

## Checkpoint 2026-08-02 07:46 BRT - ASSETS.DAT bridge batch 20

- The real `ASSETS.DAT` loader is linked into the final partial runner.
- Final runner: `work/link/partial/mc3_partial.exe`, timestamp `2026-08-02 07:45:55`, size `463806014` bytes.
- `libz.dll.a` is included at link time; `zlib1.dll` is beside the runner and imported by the executable.
- The missing-function manifest has only its header: zero missing stubs.
- The virtual adapter is restricted to `SLUS_213.55`, `MC3_ASSET_BRIDGE=1`, exact path `fonts/mcloadstrings.strtbl`, and DAT record type `0x000241FF`.
- Physical ABI corrected to `0x3984C0` open, `0x398610` close, `0x3986D8` seek, `0x398730` write, and `0x398788` read.
- Synthetic DAT, real DAT, virtual-handle, corrected-ABI, and fallback tests pass. Final full-suite retries exposed only existing VBlank/preemption timing flakes (`267/268`, `267/268`, `266/268`).
- Final 8-second baseline: stable PC `0x4F9760`, no asset markers, `dma=0 gif=0 gsw=0 vif=0`.
- Final 8-second bridge probe: stable PC `0x39923C`, no asset markers, `dma=0 gif=0 gsw=0 vif=0`.
- Retention and visual gates did not pass. The bridge remains disabled by default.
- Architecture correction: logical asset resolution is at `0x4F9760 -> 0x4FB0D8`; the physical file ABI is too low to observe the logical asset request first.
- Next exact step: instrument `0x4FB0D8`, capture bounded guest request data, and route only a proven exact `mcloadstrings` request into the existing loader.
- Full evidence: `docs/MC3_ASSET_BRIDGE_BATCH20_2026-08-02.md`.
- Rollback source snapshot: `work/checkpoints/assets_loader_20260802_072651`.

## Checkpoint 2026-08-03 16:48 BRT - logical resolver trace batch 21

- Added an MC3-only, env-gated, bounded trace wrapper for guest function `0x004FB0D8`.
- The wrapper preserves execution and calls the original exactly once; it does not connect DAT data or alter provider/semaphore state.
- Primary verification: `269/269` tests after one unrelated semaphore timing flake.
- Relinked runner: `work/link/partial/mc3_partial.exe`, timestamp `2026-08-03 16:45:43`, size `463827301` bytes, zero missing stubs.
- Baseline 8-second probe: stable PC `0x429C78`, `dma=2 gif=0 gsw=0 vif=3`.
- Trace 8-second probe: stable PC `0x4FAED8`, `dma=0 gif=0 gsw=0 vif=0`, 40 resolver entries.
- Real direct strings were provider extensions: `.tex`, `.xtex`, `.tga`, `.bmp`, `.ipu`, `.spr`.
- No `mcloadstrings`, `smallspace`, `fonts/`, `strtbl`, or `0x3CB70` appeared.
- Architecture correction: `0x4FB0D8` handles provider extension registration/selection, not the full logical asset filename.
- No visual victory: `gif=0` and `gsw=0`; no recomp frame yet.
- Next exact step: trace `0x4FAED8` plus the legitimate writer `0x4FA7A8` and prove why provider activation is unavailable before connecting any DAT asset.
- Full evidence: `docs/MC3_LOGICAL_RESOLVER_BATCH21_2026-08-03.md`.
- Rollback checkpoint: `work/checkpoints/logical_resolver_20260803_1630`.

## Checkpoint 2026-08-09 - encerramento do dia

- O experimento `opcode2B/host0:` foi rejeitado: ligado, deu `0/5` frames e travou mais cedo em `0x54A3xx/0x54A4xx`.
- O código e os testes experimentais foram removidos; build oficial e suíte `ps2x_tests` passaram.
- Um probe curto revelou que `work/link/partial/mc3_partial.exe` ainda é o binário antigo (`2026-08-09 02:18`, `463856802` bytes) e ainda contém o experimento.
- A tentativa de relink excedeu 120 segundos e não atualizou o executável. O runner foi encerrado; nenhum PCSX2 ficou aberto.
- Resultado visual honesto permanece: `gif=0`, `gsw=0`, nenhuma imagem do recomp.
- Próximo passo exato: concluir `10_link_partial_runner.bat fast`, confirmar novo timestamp e ausência de `MC3_EXPERIMENT_OPCODE2B_HOST0_RESPONSE` no binário, então rodar apenas um probe baseline curto com o gate ausente.
- O fluxo confiável de abertura/captura no PCSX2 está em `docs/PCSX2_MCP_LAUNCH_AND_CAPTURE_2026-08-09.md`.


## Checkpoint 2026-08-13 03:10 (binário limpo; bloqueio determinístico identificado)

**Mudança de ambiente:** o checkout mudou de `<old-project-root>` para `<project-root>`. Docs e logs antigos (inclusive `latest_status.md` gerado antes de hoje) ainda citam o caminho velho. `cmake` NÃO está no PATH nem em Program Files/msys64 — bloqueia rebuild de runtime (não bloqueou hoje: a lib já estava limpa).

### 1. Binário stale purgado (bloqueio de 09/08 resolvido)

- O exe de `09/08 02:18` ainda continha o experimento rejeitado `MC3_EXPERIMENT_OPCODE2B_HOST0_RESPONSE` (2 ocorrências), enquanto `libps2_runtime.a` de `09/08 02:23` já estava limpa. O exe era **5 min mais antigo que a lib**.
- **Todo probe rodado entre 09/08 e hoje testou código experimental rejeitado. Essas medições não valem.**
- Relink concluído hoje: exe `13/08 03:01`, `463854922` bytes, experimento = **0 ocorrências**, `MC3_DISPATCH_BUDGET` presente.
- Causa do fracasso anterior: o link leva ~3 min (02:58→03:01) e a tentativa de 09/08 morreu num timeout de 120s.

### 2. Gate A2 (budget determinístico): calibrado, mas NÃO entrega determinismo

Aceite N=10 rodado pela primeira vez. Resultados:

| Budget | Falhas de evidência (marker=no/timeout) | Stable PCs distintos | Render |
|---|---|---|---|
| 100.000 | 5/10 | 7 | 0/10 |
| **25.000** | **0/10** | **4** | 0/10 |

- Budget **25.000 é o valor calibrado**: 10/10 corridas atingem o marcador sem timeout.
- **O budget resolve só a fronteira de amostragem, não o interleaving.** Ainda há 4 PCs distintos em 10 corridas. Menos divergência a 25k (4) que a 100k (7) confirma que a variação vem do racing acumulado entre threads reais do host, não da amostragem.
- Conclusão: determinismo real exige serializar a execução das threads guest — mudança arquitetural no runtime, não um ajuste de script. **A2 permanece FAIL.**
- Ganho real: o classificador novo pegou um `invalid-pc` (o antigo chamaria de `render-started`).

### 3. Bloqueio determinístico atual: semáforo de I/O de arquivo nunca sinalizado

Com binário limpo e budget 25k, 9/10 corridas param na mesma região e **todas** classificam `semaphore`:

- PC modal `0x54a0ac` (5/10) em `sub_0054A080_0x54a080`; demais: `0x54a188` (2), `0x54a3c4` (2), `0x3985d8` (1).
- Bloqueio: `WaitSema tid=3 sid=5`, emitido de `ra=0x398b28` → `sub_00398B18_0x398b18`.
- `sid=5` é criado em `ra=0x398a98` com `init=0 max=16` — semáforo de **completion**, criado pelo próprio módulo de I/O físico de arquivo (mesma vizinhança do ABI documentado: open `0x3984C0`, close `0x398610`, read `0x3986D8`, seek `0x398730`, stat `0x398788`).
- **`SignalSema` nunca ocorre para sid=5.** O trace registra 19 SignalSema, para sids 7, 8, 10, 16, 29, 37 e 40 — nenhum é o 5.

Leitura: o módulo de arquivo cria o semáforo de conclusão, emite a operação e espera. A conclusão nunca chega. Isso conecta a frente provider a um mecanismo concreto — não é "ponteiro global vazio", é **completion de I/O que o runtime não produz**.

**NÃO injetar `SignalSema(5)`.** Vale a regra estabelecida na investigação do sema 17: achar o produtor legítimo primeiro.

- Handoff: `docs\HANDOFF_2026-08-13_IO_COMPLETION_SID5.md`
- Próximo passo exato: identificar o produtor legítimo da conclusão de `sid=5` (ver handoff).

## Checkpoint 2026-08-17 (alpha 102404 com símbolos completos; novo plano mestre)

- **Achado que muda a estratégia:** o ISO do alpha de out/2004 (`MIDNIGHT CLUB 3 DUB PS2 ALPHA BUILD 102404\`) contém `MC.MAP` (linker map completo, ~19.250 símbolos C++ demanglados com endereço+tamanho+objeto de origem) e `MC.SYM`. Já extraídos junto com o ELF `SLUS_123.45`. Engine identificado: AGE (Angel Game Engine).
- Símbolos que batem direto nos bloqueios atuais: `coreFileWaitCreateSema`/`coreFileSignalSema` (o par do sid=5), `coreFileMethods` (o ABI físico 0x3984C0…), `datAssetManager*`/`zipFile` (a frente provider), `mcAudioRpcMgr`/`sndRpcManager` (lado cliente do RPC → SCREAM.IRX).
- **Decisão registrada: NÃO recomeçar o recomp do zero.** Os bloqueios provados são do runtime/processo (SIF hardcoded, scheduler não-determinístico, sem caminho até frame), não do código gerado.
- **Novo plano mestre: `docs\PLANO_2026-08-17_ALPHA_SYMBOLS.md`** — Fase 0: importar MC.MAP no Ghidra e diffar alpha→retail para nomear o boot path (fecha a Tarefa 1 do handoff sid=5 sem chute); Fase 1: reescrever a camada SIF como protocolo genérico (proibido novo `else if` por payloadAddr); Fase 2: scheduler cooperativo (determinismo); Fase 3: primeiro frame. Contingência: se o diffing casar mal, trocar o alvo do recomp para o ELF do alpha (símbolos completos).
- **Higiene urgente:** `.git\` está VAZIO — não há repositório nem versionamento. `git init` + `.gitignore` + commit inicial é o primeiro passo prático. `cmake` segue fora do PATH.
- Próximo passo ao retomar: Fase 0 do plano de 17/08 (script de import do MC.MAP + Version Tracking no Ghidra).

## Checkpoint 2026-08-17 (noite) — Fase 0 executada: 8.815 funções do retail nomeadas

- Repo público no ar: `github.com/cloudalister/mc3r` (docs+pipeline+tools, sem conteúdo do jogo) + fork `github.com/cloudalister/PS2Recomp` branch `mc3` (28 arquivos de runtime commitados). Roadmap de automação em `ROADMAP.md`.
- **`tools/port_symbols.py` (Python puro) casou alpha→retail: 8.815 pares (55,7% do retail)** — 6.695 por hash de bytes mascarados + 2.120 por propagação de callgraph. Saída: `work\exports\retail_symbol_port.csv`. Relatório: `docs\SYMBOL_PORT_REPORT.md`.
- **Todos os gates históricos têm nome agora.** O bloqueio do boot é a pilha SCE CDVD/FS sobre SIF RPC: `0x5422C8`=sceCdRead, `0x541968`=sceCdSync, `0x5424A8`=sceCdSeek, `0x5420C0`≈sceCdDiskReady (o "retorno 2" = SCECdComplete), `0x54A080`=sceFsInit (onde o boot para hoje), `0x549680`=sceSifCheckStatRpc. Protocolo público (ps2sdk/PCSX2), não proprietário.
- **Handoff sid=5 respondido:** `0x398A60`=ipcCreateSemaEx cria, `0x398B18`=ipcWaitSema espera, e o produtor legítimo é **`coreFileSignalSema` = retail `0x398450`**, acionado pela completion `coreRaw*` que o runtime nunca produz. Provider = `zipFile::` (`0x4F9760`=zipOpen, `0x4FB0D8`=Open, `0x4FAED8`=Locate).
- Consequência para a Fase 1: implementar semântica cdvdfsv/fileio padrão no runtime (referência: fonte do PCSX2 + ps2sdk), não reverse de protocolo. Os requests descartados (0x1/0xFF/0x9/0x22) são comandos cdvd padrão a confirmar contra o PCSX2.
- **Fase 0 completa no mesmo dia:** JDK 21 portátil em `jdk-21.0.12+8\` (JAVA_HOME para headless; owner do projeto Ghidra corrigido de "Cloud" para "SAS" no `project.prp`). Alpha importado no projeto `work\mc2recomp` com **19.158 labels do MC.MAP** (`22_alpha_symbols.bat` + `tools\ghidra\ImportMc3Map.java`).
- **Fase 1 já com evidência dura:** `tools\ghidra\ExportSceDecomp.java` decompilou 179 funções sce*/ipc*/coreFile* nomeadas → `work\exports\alpha_decomp_sce.txt`. Confirmado: `sceCdRead` = fno 1, send 0x18, resposta 0x90 (`_sceCd_rd_intr_data`) — é o `request=0x1 size=0x90` que o runtime descarta. Binds do boot: 0x80000592 cdvd, 0x80000001 fileio, 0x80000400 pad, 0x80000100/101 mc, 0x80000701 usbkb, 0x80000211 (?). LGDEVW.IRX = driver Logitech, descartado como file server. Spec vivo: `docs\SIF_PROTOCOL.md`.
- Próximo passo ao retomar: implementar no `SIF.cpp` (fork, branch mc3) o dispatcher por (servidor, fno) começando pelo cdvd (init fno=0 e read fno=1), usando `alpha_decomp_sce.txt` como referência e PCSX2 para bytes ambíguos. Antes: resolver cmake (rebuild do runtime). Melhorias de matcher (MC.SYM/globais, vizinhança) ficam para depois do primeiro handler.

## Checkpoint 2026-08-17 (baseline re-medido — não-determinância pior que o registrado em 13/08)

- `21_probe_repeat.bat 10 595 baseline_20260817` (exe limpo de 13/08, env calibrado `MC3_DETERMINISTIC=1`/`BUDGET=25000`): **9 Stable PCs distintos em 10 corridas, nenhum na região `0x54a0xx`**, classificações `semaphore`(6)/`counters-moved`(4), `dma=0` em todas (13/08 registrava `dma=2`), 3/10 corridas com falha de evidência (timeout interno/sem marker). `gif=0 gsw=0` em 10/10, como sempre. Relatório: `work\boot_probe\repeat_baseline_20260817_181511.md`. `20_verify_boot_state.bat 0x54a0ac` → FAIL (3 checks), guarda funcionando.
- Leitura: a convergência "9/10 em 0x54a0xx" de 13/08 **não reproduz** — era um dos modos da distribuição, não um estado estável. Isso não muda o alvo da Fase 1 (o boot continua morrendo na frente CDVD/FS, os PCs `0x54xxxx` são todos dessa vizinhança SIF/sema), mas **promove a Fase 2 (scheduler determinístico)**: sem ela, nenhum experimento da Fase 1 é mensurável com confiança. Ordem revista: implementar o handler cdvd mínimo (fno 0/1) e ir para a Fase 2 antes de refinar o resto.

## Checkpoint 2026-08-17 (noite 2) — Fase 1 passos 1-2 + FASE 2 ACEITA: boot determinístico

- **Fase 1 passo 1** (fork `e85cf73`): dispatcher `handleCdvdRpc` por (sid, fno) — sid capturado no `sceSifBindRpc`, nunca por payloadAddr. Init do cdvd (fno 0) respondido 10/10; read (fno 1) implementado, ainda não alcançado pelo boot. Distribuição de PCs mudou por completo vs baseline (efeito causal). `docs\RESULT_CDVD_DISPATCH_V1.md`.
- **Fase 1 passo 2** (fork `5487a4e`): servidor `0x80000211` identificado = **sceUsbKb** (bind em `sceUsbKbInit` no decomp). O `request=0x1 size=0x90` descartado era `sceUsbKbGetInfo`. Handler "0 teclados" atendeu 20/20 no boot. Suíte 269/269. `docs\RESULT_USBKB_V1.md`.
- **Higiene** (fork `f2fc530`): log `mc3-iop-response-unhandled` não dispara mais para eventos atendidos pelos dispatchers novos — a métrica da Fase 1 ficou limpa.
- **FASE 2 ACEITA** (fork `b9b40d2`): scheduler cooperativo determinístico atrás de `MC3_DETERMINISTIC=1` — "baton" determinístico sobre std::thread (arbitragem explícita por prioridade EE + ordem de criação; VBlank por idle, não relógio; watchdog por contagem de handoffs). **`21_probe_repeat 10 595 sched_v1`: 10/10 corridas no MESMO Stable PC `0x5a8908`, evidência válida em todas, zero stalls.** Modo padrão intacto (suíte 268/269, falha pré-existente). Design: `docs\FASE2_SCHEDULER_DESIGN.md`; resultado: `docs\RESULT_FASE2_SCHED_V1.md` (inclui a ressalva honesta da seção 5 sobre o `sched_off_regression` ter dado 1 PC também nesta sessão).
- **O boot agora para SEMPRE em `0x5a8908`** — região `memHeap::Begin` (symbol port), o spin de 29/07: `beqz $v0` esperando `func_4FA398` (provider/zipFile) retornar !=0. Com determinismo, esse é O gate único do projeto, e cada experimento da Fase 1 vira prova de uma corrida.
- Próximo passo ao retomar: voltar à Fase 1 com medição determinística — frente fileio/cdvd-completion (sid=5/`coreFileSignalSema`) e a cadeia `zipFile::zipOpen`→provider que o gate `0x5a8908` espera. Tudo pushado: mc3r `be9f323`, fork `b9b40d2`.

## Checkpoint 2026-08-23 — Passo 30 MCMAN

- Runtime commit local: 4d64045. Projeto commit local: 23f6b73. Sem push.
- O trace separou PADMAN (0x80000100/101, mensagem libpad mismatch) de MCMAN (0x80000400).
- Implementado dispatcher MCMAN sid=0x80000400, fno=0xfe, resposta 0x0c: resultado 0, versões 0x20a/0x20e, derivados do decomp de sceMcInit.
- A corrida determinística de 500k confirmou mc3-memcard-rpc, saiu do PC 0x1b15xx e terminou em game-thread-return, PC 0x1a2408.
- Validação: runtime OK, stale Missing=0/Stale=0, relink OK, suíte retry 278/278, probe 3x sem render.
- Próxima fronteira: MCMAN fnos 0x14, 0x1 e 0xd ainda no fallback neutro; casar com sceMc* antes de implementar.
- Sem imagem: gifPk*=0, gsPrims=0, gsPixels=0; M4 não atingido.
- Artefatos: docs/RESULT_MEMCARD_30_V1.md, work/exports/longrun_timeline.md, tools/analyze_longrun.py.

## Checkpoint 2026-08-25 — primeiro framebuffer técnico

- O plateau `lowPsxGfx` em `0x5268a0` foi resolvido pelo contrato real de MFIFO: `VIF1.TADR` (`0x10009030`) é o consumidor e `fromSPR.MADR` (`0x1000D010`) é o produtor.
- O runtime agora implementa `fromSPR`, wrap `D_RBOR/D_RBSR`, retenção/reinício do drain VIF1 e não apaga mais `CHCR.STR` artificialmente em leitura.
- Gate visual atingido: `gifPk1=14`, `gifPk2=75`, `gsPrims=754`, `gsPixels=2240388`.
- Evidência: `work/evidence/mc3_first_frame.png` (`640x448`). O frame ainda está quebrado — preto com linhas/triângulos esparsos — então não há menu/logo legível.
- Validação: suíte `281/281`, `Missing=0`, `Stale=0`, fast relink OK.
- Relatório completo: `docs/RESULT_MFIFO_FIRST_FRAME_2026-08-25.md`.
- Próxima fronteira: PATH1/VU1/XGKICK/GIF framing; os pacotes continuam crescendo, mas as primitivas estacionam em 754.

## Checkpoint 2026-08-25 - VU1 SPECIAL2/XGKICK causal

- Causa do plateau de PATH1 provada: o decoder tratava todo lower `funct=0x3D` como XGKICK, fabricando pacotes de 4.648.448 bytes a partir de `addr=0`, sem EOP e sem vertices.
- Corrigido o despacho das quatro tabelas SPECIAL2 (`0x3C..0x3F`) pela operacao composta; XGKICK agora e somente `0x6C`.
- PATH1 real confirmado: `addr=0x1530`, pacotes de 208 bytes, EOP presente, quatro registros desenhaveis e `+2` primitivas por pacote.
- Boot 1.200.000: `gifPk1=117986`, `gifPk2=14659`, `gsPrims=262815`, `gsPixels=10372487`.
- Nova evidencia visual: `work/evidence/mc3_vu1_20k_prims.png` (`512x448`, SHA-256 `cd9372134cfd4da0f249c6138948f4af31313deceb94274af1afa1566dc2bcc0`). Ainda quebrada: grande poligono roxo, sem logo/menu.
- Suite final em retry limpo `282/282`; fast relink OK.
- Relatorio: `docs/RESULT_VU1_SPECIAL2_XGKICK_2026-08-25.md`.
- Proxima fronteira: provar a origem da primeira escrita invalida em `DISPFB1` (`0x11000` -> `0x5fbdbdbd00070707`), sem clamp/filtro.

## Checkpoint 2026-08-25 - GS reservado e display estavel

- Causa da corrupcao de `DISPFB1` fechada: `GS::writeRegister` aceitava os enderecos GIF A+D reservados `0x59..0x5f` como aliases de registradores privilegiados de display.
- `sceGsResetGraph` tambem fabricava um pacote A+D invalido para PMODE/SMODE2/DISPFB/DISPLAY/BGCOLOR; agora usa MMIO privilegiado real.
- Os aliases reservados foram removidos e receberam regressao explicita. Sem clamp, filtro, SignalSema injetado ou alteracao do scheduler.
- Suite final: retry limpo `282/282`; fast relink OK.
- Boot invisivel de 800000 dispatches manteve `DISPFB1=0x11000` ate `gsPrims=104588` (antes corrompia perto de 36 mil).
- Nova evidencia: `work/evidence/mc3_reserved_gs_fix_50k.png` (`512x448`, SHA-256 `f2ef9fb3154562cbebe67e242974e217a07540729327e04907ed569fc7f10e65`). Ainda quebrada: fundo vermelho e grandes faixas diagonais, sem logo/menu.
- O harness ganhou `MC3_HEADLESS=1` para esconder apenas a janela host durante probes longos, sem alterar a emulacao.
- Relatorio: `docs/RESULT_GS_RESERVED_DISPLAY_2026-08-25.md`.
- Proxima fronteira: provar o primeiro triangulo de tela inteira incorreto e correlacionar PRIM/XYZ/XYOFFSET/SCISSOR/FRAME no PATH1.

## Checkpoint 2026-08-25 - VIF1 TTE/REF e PATH2 corrigido

- Causa dos triangulos gigantes provada: com `CHCR.TTE=1`, o montador DMA omitia os 8 bytes superiores das tags `REF/REFE`; assim o `DIRECT` era perdido e o payload GIF era interpretado como VIFcodes.
- Assinatura causal removida: o falso `DIRECT cmd=0xd0001d00 declaredQw=0x1d00 truncated=1` caiu para zero.
- Correcao: tag-transfer VIF1 agora ocorre para todo ID quando TTE esta ativo, separada da origem local/externa do payload.
- Regressao nova: `REFE + TTE + DIRECT + payload externo`. Suite completa `283/283`.
- Boot headless de 1.200.000 dispatches: `gifPk1=78052`, `gifPk2=42804`, `gsPrims=162356`, `gsPixels=16973824`, `DISPFB1=0x11000` estavel.
- Evidencia tardia: `work/evidence/mc3_vif1_tte_ref_fix_late.png`, SHA-256 `1149f7dd8ec4a08ce910b061dd4d961bb27286ba353d646277d9d05390241c86`.
- Visual ainda nao aceito: quadro cinza uniforme, sem logo/menu/carro.
- Relatorio: `docs/RESULT_VIF1_TTE_REF_PATH2_2026-08-25.md`.
- Proxima fronteira: instrumentar quem escreve `VU1[0x1530..0x1600]`; o PATH1 e formalmente valido, mas repete vertices sentinela/degenerados.

## Checkpoint 2026-08-25 - VU1 I-bit/FTOI finito

- Metrica de mapeamento confirmada: 8.815 / 15.812 funcoes retail nomeadas pelo alpha, **55,7%**; nao equivale a percentual do jogo pronto.
- Corrigidos delay slot de branch VU1, despacho upper SPECIAL composto, contrato real do I-bit e destino FT de ITOF/FTOI/ABS.
- Prova causal: `VF20.w` passou de zero para `1.0`; os DIVs de projecao passaram de `Q=0x7f7fffff` para `Q=1.0`, removendo zero/infinito da etapa MULq.
- Tres regressoes novas do lote; suite final limpa **288/288**; fast relink OK.
- Boot headless 600000: `gifPk1=3168`, `gifPk2=1734`, `gsPrims=6582`, `gsPixels=145383438`, `DISPFB1=0x11000`.
- Evidencia final: `work/evidence/mc3_vu1_ft_fix.png`, SHA-256 `218f5a4cefe9777a32369ac0dab4f468b38f57f19af887c307873f5f79980773`.
- Visual ainda nao aceito: cinza uniforme, sem logo/menu/carro.
- Relatorio: `docs/RESULT_VU1_IBIT_FTOI_2026-08-25.md`.
- Proxima fronteira: rastrear bits/escala do resultado FTOI -> SQ -> XYZ2 -> XYOFFSET; ainda nao e a fase de enderecos/modelos de carros.

## Checkpoint 2026-08-25 - RSQRT, heap e framebuffer offscreen

- Causa do heap profundo fechada: o gerador implementava `RSQRT.S fd,fs,ft` como
  `1/sqrt(fs)`; o contrato correto e `fs/sqrt(ft)`.
- No caminho `0x4FEC4C`, isso deixava um vetor sem normalizacao e inflava o buffer de
  `144x128 / 73.728 bytes` para `5742x5086 / 116.815.248 bytes`.
- Gerador raiz, funcao ativa e regressao corrigidos. Suite completa **290/290**.
- Boot headless de 1.200.000: zero heap overrun, zero funcao ausente,
  `gsPrims=146998`, `gsPixels=67574456`.
- Dump read-only provou desenho em `FBP=64`: faixas cinzas/vermelhas nos dois contextos,
  byte a byte identicos. A apresentacao em `FBP=0` continua cinza.
- A rotina `0x52A1B0` roda continuamente; somente a segunda chamada aplica o ambiente
  `0x715A40`. Depois `page>=2` pula `PutDispEnv`, mantendo `DISPFB1=0x11000`.
- Pendencia: o corpus gerado ainda possui 450 emissoes RSQRT antigas fora do caminho
  ativo; regenerar/corrigir antes de declarar o opcode globalmente saneado.
- Evidencia: `work/evidence/mc3_rsqrt_ctx_800k_ctx0.png`, SHA-256
  `f3756120ec30784eee39c3663c07c009089f68d5b8f2e41c06b46a3de7e8af71`.
- Relatorio: `docs/RESULT_RSQRT_HEAP_OFFSCREEN_2026-08-25.md`.
- Cruzamento estatico: `0x61C39D` e lido por `GetFBP`, `BeginFrame`, `SubmitFrame` e
  `SetRenderTarget`; a unica escrita direta encontrada e a inicializacao `sb $zero` em
  `_SetRes@0x528048`. O ELF retail nasce com `0x61C39D=1` e `0x61C380=2`; `_SetRes`
  usa esse word nao zero para zerar o flag. Logo o modo zero observado e intencional.
- `GetFBP(true)` nesse modo retorna o FBP fixo em `0x70FBF8`, coerente com `FBP=64`
  visto no dump. O caller configura `gfxPipeline::SetCopyToFront(type=2)` antes de
  `_SetRes`; o gate de `PutDispEnv` deixa de ser o suspeito principal.
- `0x52C360` e `gfxTexture::UpdateAllStaticAddresses`, nao callback de flip: percorre
  texturas e atualiza enderecos estaticos.
- `BeginFrame@0x52997C` executa o callback CopyToFront de `0x715C78`; o default instalado
  por `gfxPipeline::Begin` e a funcao hidden `0x5282E8`, que chama `SetRenderTarget` em
  `0x52833C` com a textura de `0x715C70`.
- Proxima fronteira: instrumentar `0x5282E8` e seguir seus pacotes ate provar onde a
  copia `FBP=64 -> FBP=0` falha, depois sanear as 450 traducoes RSQRT restantes.

## Checkpoint 2026-08-25 - CopyToFront fechado ate SendBuffer

- `0x5282E8` foi identificado como `gfxPipeline::SimpleBackToFrontBlit` e confirmado
  em runtime no ramo retail `type=2`.
- Destino medido: textura `0x792140`, `BP=0`, `BW=8`, `PSM=CT16`; origem:
  `0x7922C0`, `TBP0=2048` (`FBP64`), `TBW=8`, `PSM=CT24`.
- O passe executa blits em tiras de 32 px para `512x448` e gera `+2 DMA` por callback.
- `lowPsxGfx::SendBuffer`, caller `0x526C30`, recebeu lote de 6.080 bytes em
  `0x70002800..0x70003FC0` contendo tanto `FRAME FBP0` quanto a tag `REF` para
  `sourceTexture+0x10`.
- Marcador no rasterizador ficou em zero por mais de 30 callbacks mesmo ampliado para
  qualquer sprite texturizado que escrevesse `FBP0` **ou** lesse `TBP0=2048`.
- Conclusao: o callback e o buffer de origem estao estruturalmente corretos; o blocker
  atual esta depois de `SendBuffer` e antes do rasterizador, no corredor
  `fromSPR -> MFIFO -> VIF1 REF/TTE -> DIRECT -> GIF Path2`.
- Validacao deste lote: dois objetos compilados, `ps2_runtime` incremental OK e fast
  relink OK. A suite 290/290 anterior nao foi repetida porque so entraram diagnosticos.
- Relatorio: `docs/RESULT_COPY_TO_FRONT_PIPELINE_2026-08-25.md`.
- Proximo passo: seguir a tag `REF` especifica nos tres checkpoints do runtime sem
  injecao, filtro, flip forcado ou alteracao do scheduler.

## Checkpoint 2026-08-25 - REF fechado e IMAGE continuation corrigido

- A tag externa passou inteira por `fromSPR/MFIFO -> REF id3 qwc6/TTE -> VIF DIRECT ->
  GifArbiter submit/drain -> GS`.
- O GS aplicou os valores exatos do passe: `FRAME_1/2=0x02080000` e
  `TEX0_1=0x2A8120800`; transporte e escrita de estado nao sao mais o blocker.
- Foi provado e corrigido um bug geral do VIF1: a tag IMAGE final de um DIRECT com setup
  A+D nao era detectada, e o DIRECT seguinte de pixels virava uma IMAGE falsa de 32.767
  QWs. Agora o parser percorre todas as tags e continua apenas pelo payload do proximo
  DIRECT, preservando comandos VIF/NOP entre eles.
- Regressao adicionada; suite final **291/291**. Build incremental e fast relink OK.
- Probe real: falso `pending=32764` e alternancia de chain cru sumiram. O chain CopyToFront
  fecha em `size=19256/end=19256`, `220 comandos`, `87 DIRECT`, `11 UNPACK`, `0 kicks`,
  `pendingImage=0`.
- Nova fronteira: inventariar registradores/primitivas dos 87 DIRECTs e a relacao com os
  11 UNPACKs. Ainda nao nasce sprite do CopyToFront e ainda nao ha imagem reconhecivel.
- Relatorio atualizado: `docs/RESULT_COPY_TO_FRONT_PIPELINE_2026-08-25.md`.

## Checkpoint 2026-08-25 - PRMODECONT e primeira imagem reconhecivel

- Auditoria estatica confirmou que `gfxPipeline::Blit2D@0x52AFB8` emite GIF direto;
  `kicks=0` e correto para esse corredor e nao indica VU1 ausente.
- Os 87 DIRECTs foram inventariados: 103 GIFtags, 32 PRE, 32 RGBAQ, 32 UV,
  32 XYZF2 e 32 XYZ2, todos consumidos sem truncamento. As 16 tiras existiam.
- Causa visual provada: com `PRMODECONT.AC=0`, o jogo grava atributos em PRMODE
  (`0x158`: TME/FST ativos) e usa PRIM `0x006` apenas para o tipo SPRITE. O runtime
  aplicava PRMODE e depois apagava seus atributos ao escrever PRIM.
- Correcao geral: GS agora armazena PRIM/PRMODE crus e seleciona atributos conforme
  PRMODECONT, inclusive quando AC muda. Regressao de sprite texturizado adicionada.
- Validacao: suite completa **292/292**, fast relink OK. Probe real atingiu
  `gifPk1=2702`, `gifPk2=1055`, `gsPrims=5454`, `gsPixels=1722560`; CopyToFront
  confirmou `TME=1/FST=1` e kicks GS reais.
- Primeira imagem reconhecivel: `work/evidence/mc3_prmode_frame.png` (`512x448`,
  SHA-256 `57153e099948829d5189bf274d17738af4cc28576593c553589e21a5f9b2f7c9`).
  Mostra o logo Midnight Club 3 DUB Edition Remix e a tela de aviso/EULA. Ainda
  escura, mas visualmente aceita.
- Relatorio: `docs/RESULT_COPY_TO_FRONT_PIPELINE_2026-08-25.md`.
- Proxima fronteira: diagnosticar a luminancia/apresentacao escura e acompanhar a
  transicao ate o menu sem hacks de frame, scheduler ou sincronizacao.

## Checkpoint 2026-08-26 - onde nasce a tela inicial

- Correcao causal: a string em `0x00619B14 + 0xE8` e o nome da transicao carregada e
  pode permanecer em `mc3intro`; ela nao representa o estado atual do jogo.
- O ciclo dos filmes esta saudavel e completo: `rockstar`, `sdlogo` e `mc3intro`
  produziram 3 chamadas de `mcLayerMovie::Load`, 3 construcoes e 3 limpezas. O ponteiro
  `0x617BCC` apareceu como `0x8598C0` durante cada ciclo e foi limpo no unload esperado.
- A entrada real no frontend foi provada em runtime: `mcGameState::EnterStateMC3Frontend`
  foi chamada 1 vez, `SetFrameModeFrontend` 2 vezes e `frameMode@0x619B00` passou a `3`
  por volta do tick 6540. O logo MC3 + aviso legal ja pertence ao frontend; e a primeira
  tela de titulo/legal, nao ainda o menu principal interativo.
- Correcao estatica: `0x398C80` e `ipcTime(void)` e `0x614444` recebe um timestamp; nao
  sao construtor nem ponteiro do frontend.
- Um probe longo de 300 s permaneceu em `frameMode=3` redesenhando ativamente
  (`gsPrims=313605`, `gsPixels=114093303`); portanto nao ha travamento de render nessa fase.
- A rota real de input foi localizada. No probe deterministico de 600k:
  `ioPad::UpdateAll=6`, `ioPad::Update=12`, `ioPad::Attach=12`, `scePadGetState=12`,
  mas `ioPad` ficou em estados `5,5,0,0`, `ioPad` poll/read ficou em `0` e
  `scePadRead@0x543ED8` ficou em `0`.
- `scePadPortOpen@0x543C90` foi chamado 2 vezes, mas as entradas de padlib dos ports 0/1
  continuaram zeradas (`padSlot0Ptrs=0,0`, `padSlot0Open=0,0`). O decomp prova que esses
  ponteiros so sao publicados depois de `sceSifCallRpc@0x549488` retornar sem erro.
- Bloqueio atual comprovado: frontend e render estao vivos, mas a abertura PADMAN nao
  completa; por isso `ioPad::Attach` nunca chega ao estado `7` e nao chama `scePadRead`.
- Telemetria somente leitura; scheduler e input intactos. Build, fast relink e suite no
  cwd correto passaram (**292/292**).
- Proximo passo: rastrear `scePadInit`/`sceSifBindRpc` dos servidores PADMAN
  `0x80000100/0x80000101` e o retorno de `sceSifCallRpc@0x549488`, fechando por que
  `scePadPortOpen` nao executa o commit dos buffers.

## Checkpoint 2026-08-26 - corredor PADMAN fechado ate scePadRead

- Correcao da medicao anterior: a base retail da tabela padlib e `0x006FC590`, nao
  `0x0070C590`. Os dois `scePadPortOpen` ja completavam e publicavam `0x6BB440` e
  `0x6BB600`, com `open=1` e clientes ligados aos servidores PADMAN.
- O PCSX2-MCP foi religado ao checkout atual em `<project-root>`.
  A captura live confirmou `SLUS-21355`, DebugServer + PINE, fase interna `7` no pad 0,
  pacote DualShock `0x79` em `0x006BB440` e o ultimo comando PADMAN `0x08`.
- O primeiro bloqueio real era o comando `GET_MODVER 0x12`: o fallback generico zerava
  a resposta e o guest registrava `padman.irx = 0.0`. O dispatcher dedicado agora
  devolve `0x0400`, seguido de `INIT 0x10` e `OPEN 0x01` comprovados no trace.
- O segundo bloqueio era o offset da resposta assíncrona: `SET_MMODE 0x06` retorna em
  `+0x14`, nao em `+0x0C`. O runtime agora modela os offsets de `0x06/0x08/0x09/0x0A`
  conforme libpad e conclui a atualizacao DMA antes da proxima observacao de
  `ioPad::Attach`, sem alterar scheduler ou injetar SignalSema.
- Prova deterministica de 600k: `ioPadAttachPhases=7,7,0,0`, `ioPadPollCalls=10`,
  `guestPadReadCalls=10`, `gsPrims=13848`, `gsPixels=5335404`. O gate estrutural
  `PADMAN -> ioPad::Attach -> ioPad::Poll -> scePadRead` esta fechado.
- Build incremental, fast relink e suite completa passaram: **292/292**.
- Relatorio: `docs/RESULT_PADMAN_CORRIDOR_2026-08-26.md`.
- Proxima fronteira: ligar o estado do controle host ao pacote DMA guest e provar uma
  transicao de frontend causada por START, ainda sem alterar artificialmente o input.

## Checkpoint 2026-08-26 - input host ligado ao DMA PADMAN

- O produtor host existente (`backend`/gamepad/teclado) agora publica seus 32 bytes no
  bloco mais antigo do `pad_data_new`, incrementando o frame antes da leitura guest.
- Enter e o Start do gamepad preservam a semantica active-low do bit `1 << 3`.
- Telemetria passiva nova: `padmanPublishes` e `padmanStartPublishes`; START tambem gera
  `[boot-trace:mc3-padman-input]` sob o trace ja existente.
- Regressao ponta a ponta host -> double-buffer DMA passou, incluindo frame 1/2 -> 3,
  `length=32`, `state=6` e contador START. Suite limpa **293/293**, build incremental e
  fast relink OK.
- O PCSX2 retail foi pausado e retomado via MCP somente para liberar CPU durante os
  testes; a sessao `SLUS-21355` permaneceu aberta.
- Limite honesto: o probe de refresh atual nao voltou a atingir `ioPad::Attach`; a
  tentativa visivel chegou ao tick 10320 ainda com `frameMode=0`, `ioPadAttachCalls=0`,
  `gifPkTotal=0` e `gsPrims=0`. Portanto o Enter ainda nao tinha consumidor guest e a
  transicao visual causada por START nao esta comprovada.
- Relatorio: `docs/RESULT_PADMAN_HOST_INPUT_2026-08-26.md`.

- Proximo gate: runner nativo visivel + um START manual, exigindo no mesmo trace
  `padmanStartPublishes>0`, `guestPadReadCalls>0` e mudanca posterior de estado/frontend.

## Checkpoint 2026-08-26 - A/B da ponte host antes do Attach

- A/B deterministico executado com budget 600000, 45 s e PCSX2 pausado.
- A removeu somente `resetPadInputPorts`/`openPadInputPort` antes do Attach; B restaurou
  a ponte host completa.
- A e B terminaram identicos no tick 2580: dois OPENs, `ioPadAttachCalls=0`,
  `ioPadPollCalls=0`, `guestPadReadCalls=0`, `padmanPublishes=0`, `frameMode=0`,
  `gifPk1/2/3=0` e `gsPrims=0`.
- Conclusao causal: o registro/reset host nao produz o bloqueio atual. O runner para
  depois dos OPENs e antes do primeiro `ioPad::Attach`, portanto antes do publisher
  dinamico poder interferir.
- A fonte foi restaurada para a variante B oficial; build, fast relink e suite completa
  passaram novamente: **293/293**.
- Evidencias: `work/logs/padman_ab_A_no_host_registration.log`,
  `work/logs/padman_ab_B_host_bridge.log` e
  `docs/RESULT_PADMAN_HOST_INPUT_2026-08-26.md`.
- Proxima investigacao: estreitar o corredor de boot entre o retorno dos OPENs PADMAN e
  o primeiro update/Attach, preservando scheduler e sem SignalSema artificial.

## Checkpoint 2026-08-26 - primeira tela nativa reconhecivel

- O aparente bloqueio pos-OPEN era o timeout de 45 s: o processo era morto no tick 2580
  antes de consumir o budget deterministico de 600000.
- Telemetria passiva bounded identificou `0x432AA0` como laco normal de `memset`, chamado
  por `0x526744` para zerar 0x80000 bytes em 0x00100000; nao era espera PADMAN.
- Com timeout suficiente, o budget terminou no tick 7172 com `ioPadAttachCalls=10`,
  `ioPadPollCalls=8`, `guestPadReadCalls=8`, `padmanPublishes=20` e fases `7,7,0,0`.
- Render nativo comprovado: `gifPk1=6642`, `gifPk2=2601`, `gsPrims=13427` e
  `gsPixels=4443861`. O gate `gifPkTotal>0 && gsPrims>0` esta fechado.
- Frame dump `ok=1` em 512x448 mostra o logo Midnight Club 3 DUB Edition Remix e aviso
  ESRB, ainda com luminancia muito baixa: `work/frames/mc3_native_600k.png`.
- Build e fast relink OK; retry da suite apos os flakes temporais conhecidos passou
  **293/293**.
- Relatorio: `docs/RESULT_NATIVE_FRAME_2026-08-26.md`.
- Proxima fronteira: corrigir luminancia/alpha da apresentacao e depois fechar a transicao
  de frontend causada por START no runner visivel.

## Checkpoint 2026-08-26 - fade fechado e START curto isolado

- Dump tardio em `gsPrims=10908` elevou o maximo RGB da apresentacao de 16 para 70;
  contexto 1 chegou a 118. Arte e texto permaneceram integros.
- Runner nativo visivel com budget 900000 mostrou a tela legal clara, colorida e animada.
  O ultimo frame telemetrado tinha `gsPrims=177255` e `gsPixels=64014311`.
- Conclusao causal: a primeira imagem escura era o fade de abertura. PMODE e compositor
  nao foram alterados.
- A rota normal de START foi confirmada: Enter/gamepad -> bit 3 active-low -> publisher
  PADMAN -> leitura guest.
- Um tap Enter real, enviado com a tela visivel e PADMAN ativo, nao coincidiu com a
  amostragem: `padmanPublishes=260`, `guestPadReadCalls=128`, mas
  `padmanStartPublishes=0`; nao houve transicao atribuivel ao input.
- O PCSX2 retail foi retomado com `pcsx2_continue` depois do probe.
- Relatorios: `docs/RESULT_NATIVE_FRAME_2026-08-26.md` e
  `docs/RESULT_PADMAN_HOST_INPUT_2026-08-26.md`.
- Proximo patch: latchar um evento host curto ate a proxima amostragem PADMAN real, sem
  alterar scheduler, SignalSema ou estado guest artificial.

## Checkpoint 2026-08-26 - START chegou ao estado interno do ioPad

- A fila de borda host foi compilada e relinkada; Cloud pressionou Enter duas vezes no
  runner nativo visivel com budget 900000.
- Cadeia end-to-end comprovada no `work/logs/14_run_boot_trace.log`: PADMAN publicou
  START cinco vezes e `scePadRead@0x543ED8` leu `data2=0xF7` nas chamadas 69, 73 e 74.
- `ioPad::Poll@0x238368` armazena os bytes em `+0x142/+0x143`, inverte o word active-low
  e produz o bit ativo `0x0800` em `ioPad+0x17C`.
- Nao houve transicao depois dos apertos: `frameMode=3`, `enterFrontendCalls=1`,
  `setFrontendCalls=2` e `layerTransitionCalls=3` ficaram constantes.
- Render continuou valido: `gsPrims=182696`, `gsPixels=65940218` e
  `padmanStartPublishes=5`. Teclado, fila host, PADMAN, DMA, `scePadRead` e conversao
  basica do `ioPad` nao sao mais o bloqueio.
- O PCSX2 nao estava aberto/conectado ao final; `pcsx2_continue` retornou connection
  refused, portanto nao restou sessao pausada para retomar.
- Proxima fronteira: mapear quem consome `ioPad+0x17C & 0x0800` na primeira tela legal
  do frontend e instrumentar somente esse consumidor real.

## Checkpoint 2026-08-26 - consumidor direto de START instrumentado

- O corredor estatico do frontend foi fechado ate o primeiro leitor direto:
  `uiInput::Update@0x420F38` chama
  `uiInput::CheckKeysAndPadsForBasicNavigation@0x4215A0`, que le
  `ioPad+0x17C`. `uiInput::IsKeyPressedRaw@0x421278` e o helper interno
  `0x421458` ficam depois, sobre o estado filtrado de `uiInput`.
- A contagem do teste visivel anterior registrou `uiInputUpdateCalls=0`. Portanto o
  proximo A/B deve primeiro distinguir pipeline de UI ausente de filtragem interna;
  ainda nao ha evidencia para alterar uma condicao do frontend.
- Telemetria estritamente passiva foi adicionada em tres limites comprovados:
  `[boot-trace:mc3-iopad-state]` na producao de `ioPad+0x17C`,
  `[boot-trace:mc3-uiinput-update]` na entrada de `uiInput::Update` e
  `[boot-trace:mc3-uiinput-pad]` logo depois da leitura de `ioPad+0x17C` por
  `0x4215A0`.
- Compilacao incremental recompilou exatamente tres objetos, com
  `Missing=0` e `Stale=0`; fast relink concluiu e a suite oficial passou
  **293/293** com o PATH do MSYS2 e o cwd do PS2Recomp.
- Nenhum runner ou janela foi aberto neste lote. O proximo teste e manual e exige que
  Cloud pressione Enter quando solicitado.
- Interpretacao do proximo trace:
  - `mc3-iopad-state start=1` sem `mc3-uiinput-update`: a tela nao executa o pipeline
    `uiInput` nesse momento;
  - `mc3-uiinput-update` presente sem `mc3-uiinput-pad start=1`: a execucao e filtrada
    ou desviada antes da leitura do pad;
  - `mc3-uiinput-pad start=1` sem transicao: o bloqueio esta no consumidor
    raw/filtrado posterior ou em um gate legitimo de estado do frontend.

## Checkpoint 2026-08-26 - START reconhecido como borda do frontend

- O PCSX2 retail provou o primeiro leitor pos-filme: `sub_00234D58@0x234D58`, chamado
  por `sub_0020BA88@0x20BA88`; o watchpoint em `ioPad+0x17C` parou em `0x234F68`.
- O objeto de acao possui a mascara START `0x0800` no binding offset `0x18`. O resultado
  e publicado em `0x2356BC`; `0x20BBDC` compara atual/anterior e `0x20BBF4` publica a
  borda no estado `frontend+0x0C`, indice 6.
- Um unico Enter no runner nativo fechou a cadeia em runtime: PADMAN `0xFFF7`,
  `ioPad=0x0800`, binding `mask=0x0800`, output `0 -> 255` e borda frontend
  `current=255/previous=0`.
- O render permaneceu valido (`gsPrims=171801`, `gsPixels=62003494`) e a suite oficial
  passou **293/293**. Fast relink OK; telemetria passiva somente.
- Nao houve transicao no runner: `frameMode=3`, `layerTransitionCalls=3` e
  `uiInputUpdateCalls=0`. PADMAN, `ioPad` e o tradutor de acoes estao eliminados como
  bloqueio; a proxima fronteira e o consumidor de `frontend+0x0C` na tela legal/titulo.
- Relatorio: `docs/RESULT_PADMAN_HOST_INPUT_2026-08-26.md`.

## Checkpoint 2026-08-26 - gate automatico da tela legal isolado

- Correcao de modelo: a tela legal vem antes da tela `PRESS START BUTTON`; START ja
  chega ao frontend, mas nao e o evento que deve retirar a tela legal.
- Strings e watchpoints retail fecharam o corredor
  `0x1AAB90 -> 0x1AAC70 -> 0x1AC238 -> 0x320848/0x320A88`, usando
  `StartOfTransitionOut` e `EndOfTransitionOut`.
- Comparacao no mesmo gate, slot e objeto: retail entra em `0x1AC238` com
  `startRequested=1`; nativo entra com `startRequested=0` e retorna antes de gravar ou
  consultar os eventos de transicao.
- O loader nativo termina legitimamente em `FUN_001aadb8@0x1AADB8`, com workers
  `0xD5/0xD4` e screen `0x01EA6040`, e publica `loadPending` em `state+0x4005`.
- A rota automatica retail foi fechada com retorno salvo em pilha:
  `FUN_001a5b08@0x1A5FD0 -> sub_001AAB08 -> sub_001AA9B8 -> FUN_001AAE80`.
  `sub_001AA9B8` viu `startRequested=0/loadPending=1`; `FUN_001AAE80` entao publicou
  `startRequested=1`. `sub_001AAE28` existe como rota alternativa, mas nao participou
  desta passagem.
- No nativo longo, o loader publicou `loadPending`, mas nao houve entrada em
  `sub_001AA9B8`, `FUN_001AAE80` ou `sub_001AAE28`; 64 amostras do gate permaneceram
  em `startRequested=0`.
- Nova fronteira: provar por que o lifecycle nativo nao alcanca o cleanup
  `0x1A5FC0/0x1A5FD0` de `FUN_001a5b08`. Telemetria continua passiva e limitada; sem
  SignalSema, sem env-gate e scheduler intacto.
- Probe interno fechou o prefixo executado:
  `0x1A5E18 -> 0x1A5E4C -> FUN_001AAA38 -> 0x1A5E54 -> 0x1A5E6C -> 0x1A5E74 -> 0x1A5E88`.
  O loader legal termina nesse intervalo, mas o nativo nao alcanca `0x1A5ECC`,
  `0x1A5F08` nem `0x1A5FC0`.
- Fronteira seguinte reduzida a `0x1A5E88..0x1A5ECC`: comparar retorno/target dos
  metodos virtuais e dos helpers `sub_001A97D0`, `FUN_001A97C0` e `FUN_001A9828`
  retail versus nativo. Nenhum retorno deve ser forcado sem essa prova.
- Relatorio atualizado: `docs/RESULT_PADMAN_HOST_INPUT_2026-08-26.md`.
- Fechamento validado: suite oficial **293/293**; **15.827** objetos/funcoes,
  `Missing: 0`, `Stale: 0`; ultimo run longo com `gsPrims=177255` e
  `gsPixels=64014311`. PCSX2 retail pausado em `0x001AAE80`, sem breakpoints ou
  watchpoints ativos.

## Checkpoint 2026-08-26 11:30 - lifecycle reduzido ao allocator alinhado

- Correcao: retail e nativo retornam `0` em `0x5B9080`; ambos percorrem o ramo
  alternativo e chamam o mesmo slot virtual `0x1A8EC0` da vtable `0x006238F8`.
- O retail percorreu 42 continuations internas de `0x1A8EC0` e retornou a
  `0x1A5EBC`. O nativo coincide ate `0x1A9010`, entra em
  `0x42E810 -> 0x430CF8`, alcanca `0x430D74` e nao retorna da chamada
  `0x430D98 -> 0x42E668`.
- `0x42E668` seleciona o allocator: callback global `0x006D59CC` ou fallback
  `0x3B1630`. Proximo probe deve ser condicionado ao caller `ra=0x430DA0` para
  provar qual caminho nao retorna; ainda nao ha base para forcar resultado.
- Telemetria passiva recompilada, fast relink OK, **15.827 objetos**,
  `Missing: 0`, `Stale: 0`; probe 600k com `gsPrims=11797` e
  `gsPixels=4435515`.
- Nova captura nativa: `work/captures/native_legal_2026-08-26_1130.jpg`.

## Checkpoint 2026-08-26 - allocator retornou e entradas indiretas 0x5C fechadas

- O callback global `0x006D59CC` foi confirmado nulo; o caminho legal usa o
  fallback `0x3B1630`.
- `0x3AFE40` nao estava travado. A passagem executa um preenchimento grande de
  `0x0087C6F0` bytes com `0xCDCDCDCD` por `0x42E6F0`; o probe anterior de 600k
  terminava apenas no meio desse trabalho.
- Um probe headless de 2.000.000 despachos provou o retorno completo:
  `0x42E6F0 -> 0x3B01D8 -> 0x3B0244 -> 0x3B027C -> 0x3B16B4 ->`
  `0x42E68C -> 0x42E6AC -> 0x430DA0`. Alocacoes legais posteriores tambem
  retornaram.
- As entradas indiretas `0x5C3A40` e `0x5C5720` ja eram instrucoes reais dentro
  de `sub_005C2880`, mas nao estavam expostas no switch/registro parcial. Foram
  adicionados somente os aliases reais e o registro parcial foi regenerado.
- No probe de validacao de 2.000.000 despachos nao houve warning/erro para
  `0x5C3A40`, `0x5C5720` ou `0xCDCDCDCD`. O render chegou a
  `gifPk1=349909`, `gifPk2=137141`, `gifPkTotal=487050`, `gsPrims=706326` e
  `gsPixels=256961446`.
- A nova fronteira observada e `PC=0x322FFC`, continuation direta apos a chamada
  a `0x3451E8` em `FUN_00322fd8`. O snapshot repetido ainda nao prova travamento;
  o proximo passo e telemetria esparsa e condicionada em `0x322FD8/0x322FFC` e
  nas entradas/retornos de `0x3451E8`, sem forcar retorno.
- Validacao: fast relink OK; `find_stale.py` com **15.827 objetos**,
  `Missing: 0`, `Stale: 0`; suite oficial **293/293**.
- Este lote foi inteiramente headless: nenhum uso de desktop, PCSX2 ou runner
  visivel.

## Checkpoint 2026-08-26 - 0x322FFC descartado e 22 aliases reais fechados

- A telemetria passiva provou o corredor completo
  `0x322FD8 -> 0x3451E8 -> 0x3454C4 -> 0x322FFC -> 0x323010`.
  Portanto `0x3451E8` retorna normalmente e `0x322FFC` nao e um travamento;
  o snapshot repetido nesse PC era insuficiente para essa conclusao.
- Os alvos virtuais observados em `0x3451E8` foram `0x33A5A0` no callsite
  `0x345210`, `0x41F550` em `0x345488` e `0x33A4B0` em `0x3454A0`.
- O lote revelou **22** entradas reais que ja existiam dentro de owners gerados,
  mas ainda nao estavam expostas pelo switch/registro parcial: primeiro
  `0x5CCC98`; depois mais 12 (`0x2B9908`, `0x31EDE0`, `0x4D92E0`, `0x519528`,
  `0x5B9380`, `0x5B9390`, `0x5BEF98`, `0x5CC948`, `0x5CC958`, `0x5CC968`,
  `0x5E5BF8`, `0x5E9080`); e finalmente mais 9 (`0x209008`, `0x33A4B0`,
  `0x383C88`, `0x586218`, `0x5BA5C0`, `0x5CC950`, `0x5CCE58`, `0x5CCE70`,
  `0x5E8850`). Foram adicionados somente cases/labels reais, levando o registro
  de **168.333** para **168.355 aliases**, sem stub novo.
- Na validacao consolidada pedida para 2.000.000 despachos, o wrapper encerrou o
  processo pelo timeout de 600 s antes de concluir o budget. Ate esse ponto houve
  **zero** `first-bad-pc`, `recover-pc` ou alvo ausente. Nao confundir esse timeout
  externo com conclusao dos 2 milhoes de despachos.
- O render permaneceu forte: `gifPk1=348558`, `gifPk2=136612`,
  `gifPkTotal=485170`, `gsPrims=703599`, `gsPixels=256036663`; o gate
  `gifPkTotal>0 && gsPrims>0` continua satisfeito.
- Suite oficial **293/293**, fast relink OK, `Missing: 0`, `Stale: 0` e
  `git diff --check` sem erro. Nenhum desktop, PCSX2 ou runner visivel foi usado.
- Proxima fronteira exata: a chamada `0x323024 -> 0x320B38`, cujo retorno esperado
  e `0x32302C`. Contadores passivos ja foram compilados em `0x32302C`, `0x32306C`,
  `0x323084`, `0x323094`, `0x3230CC` e `0x3230E8`, mas ainda nao foram exercitados
  em novo probe longo. Scheduler e semantica permanecem intactos; nenhum retorno
  foi forcado.

## Checkpoint 2026-08-26 - fronteira movida para dentro de 0x320B38

- Novo probe headless com `MC3_DETERMINISTIC=1`, budget solicitado de 2.000.000 e
  timeout de 600 s repetiu o corredor ate `0x323010`, mas nao registrou nenhuma
  continuation em `0x32302C` ou posterior. O wrapper atingiu o timeout; o budget
  nao foi concluido.
- Nao houve `first-bad-pc`, `recover-pc` ou alvo ausente. O ultimo frame completo
  manteve `gifPk1=348558`, `gifPk2=136612`, `gifPkTotal=485170`,
  `gsPrims=703599` e `gsPixels=256036663`.
- A evidencia combinada move a fronteira causal para dentro da chamada direta
  `0x323024 -> 0x320B38`. O retorno normal esperado continua sendo `0x32302C`;
  o snapshot em `0x322FFC` nao deve mais ser tratado como bloqueio.
- Auditoria estatica: `0x320B38` chama primeiro `0x320C60`; depois pode passar por
  `0x320968`, `0x20ACD0`, `0x20B290`, `0x339278` e `0x20B258`. Dentro de
  `0x320C60`, a primeira cadeia relevante e `0x42CC80 -> 0x42CA90 -> 0x42AAF8`,
  seguida por continuations diretas ate o retorno.
- Telemetria passiva foi adicionada nos cinco owners dessa cadeia:
  `FUN_00320b38`, `FUN_00320c60`, `FUN_0042cc80`, `FUN_0042ca90` e
  `sub_0042AAF8`. Ela registra entradas e continuations reais de chamadas, com
  amostragem limitada; ainda nao foi exercitada por outro probe longo.
- Os cinco objetos compilaram, o fast relink fechou com **15.827 funcoes**,
  **168.355 aliases** e **0 stubs ausentes**. Suite oficial **293/293** e
  `git diff --check` sem erro.
- Lote inteiramente headless, sem controlar desktop, PCSX2, teclado ou mouse.
  Nao houve SignalSema injetado, retorno forcado, gate semantico ou mudanca no
  scheduler.

## Checkpoint 2026-08-26 - espera temporizada do allocator isolada

- O corredor seguinte foi fechado sem alterar a semantica:
  `0x323024 -> 0x320B38 -> 0x320C60 -> 0x42E8A0 -> 0x430C90 -> 0x4323E8`.
- Em `0x430C90`, `PollSema(0x2E8)` retornou, `DeleteSema(0x2E8)` retornou com
  sucesso e o campo do objeto foi zerado. Portanto o semaforo do objeto nao e o
  bloqueio atual.
- `0x4323E8` resolveu o bloco `1` no pool iniciado em `0x006771E0`; a entrada
  `0x006771F0` tinha uma unica pendencia (`+0x0C = 1`). A rotina entao chamou
  `0x398C60(10)`, o helper legitimo de espera de 10 ms.
- Esse helper entrou em `0x547608`, criou o semaforo temporario `0x2EB`, armou o
  callback `0x5476D0` e bloqueou em `WaitSema`. O callback deveria executar
  `iSignalSema`, mas nao apareceu durante todo o restante do probe; tambem nao
  houve retorno a `0x432458`. Outra thread entrou na mesma familia de espera com
  o semaforo `0x2ED`, reforcando que a fronteira e o servico de timer/despertar,
  nao uma chamada de video, GS, audio ou input.
- O probe headless de 720 s terminou pelo timeout externo, nao pelo budget de
  2.000.000 despachos. Render permaneceu valido em `gifPkTotal=485170`,
  `gsPrims=703599` e `gsPixels=256036663`; nao houve nova transicao de filme
  (`enterMovieCalls=3`, `setMovieCalls=3`, `introActive=0`).
- Proxima fronteira: provar por que o gerenciador interno de alarmes
  `0x54D6A0` nao entrega o callback `0x5476D0`. Nao substituir a espera por
  retorno forcado nem sinalizar o semaforo manualmente; comparar o agendamento,
  o tick/interrupt e a entrega do callback.
- Execucao em `BelowNormal`, sem janela, PCSX2, teclado ou mouse.

## Checkpoint 2026-08-26 - Timer2/SIF liberados, imagem nativa e transicao isolada

- O bloqueio da espera de 10 ms era de temporizacao da EE/CPU, nao de video:
  Timer2 agora modela COUNT/MODE/COMP no clock BUSCLK/256 e despacha
  `INTC_TIM2` (cause 11). Threads guest novas tambem herdam o bit EIE do COP0,
  permitindo que o handler entregue o callback `0x5476D0`.
- A cadeia causal foi observada completa, sem injecao:
  `wait-enter -> alarm-armed -> Timer2 IRQ -> callback -> iSignalSema -> wait-woke`.
  O semaforo aqui e o bilhete de sincronizacao do kernel da EE que liga o callback
  assincrono a thread guest adormecida; nao pertence a GS, audio ou input.
- Um segundo defeito apareceu depois: `CreateSema` crescia sem limite e chegou ao
  ID `87077`, enquanto o PS2 dispoe de 256 objetos. A resposta SIF tentava acordar
  esse ID e falhava. O allocator agora permanece em `1..256` e recicla holes de
  `DeleteSema`; um teste faz 1.024 ciclos de create/delete e confirma o reuso.
- Com isso, a request SIF 4 passou de `signaled=0` para `signaled=1`, o jogo abriu
  5/7 threads, alimentou DMA/VIF e produziu render real. Captura preservada em
  `work/captures/mc3_timer2_sema_render_20260826.png`, com o frame capturado em
  `gifPk1=16212`, `gifPk2=6345`, `gsPrims=32724`, `gsPixels=11351546`.
- O lifecycle legal agora atravessa todo `FUN_001A9828`, chega a `0x1A5FB4` e
  executa o cleanup em `0x1A5FC0`. `StartOfTransitionOut` retorna `3`, mas
  `EndOfTransitionOut` continua retornando `0`. A nova fronteira e o produtor que
  deveria avancar/publicar o estado final da transicao, nao o helper de consulta
  `0x320A88` e nao o GS.
- O menor corredor seguinte e passivo: correlacionar objeto/slot e
  `startRequested` em `0x1AC238`, retorno de `0x320848/0x320A88` e o valor
  produzido por `0x20B1D0`; depois identificar o updater por frame que deveria
  mudar esse objeto. Nenhum retorno deve ser forcado.
- Validacao final: suite oficial **297/297 em 5 execucoes consecutivas**, fast
  relink OK, **15.827 objetos**, `Missing: 0`, `Stale: 0`. O teste de SyncV foi
  corrigido para aceitar o campo exato que acordou a chamada quando o worker de
  VBlank avanca mais de um tick por atraso do host; a espera agora captura o tick
  de entrada antes de iniciar um worker novo.
- Logs principais: `work/logs/14_run_boot_trace_timer2_chain_20260826.log`,
  `work/logs/14_run_boot_trace_timer2_sema_capture_20260826.log` e
  `work/logs/14_run_boot_trace_legal_transition_20260826.log`.
- Sem `SignalSema` injetado, sem retorno forcado, sem gate semantico e com o
  scheduler intacto.

## Checkpoint 2026-08-26 - diferenca retail reduzida a EndOfTransitionOut

- O probe de leitura confirmou que `EndOfTransitionOut` existe no nativo como
  registro `type=3` em `0x01ECB164`; o valor bruto e convertido permaneceu `0`
  durante centenas de frames, enquanto DMA, pad e GS continuaram avancando.
- O rastreio de todos os setters no mesmo objeto `0x01EBB660` observou somente
  `StartOfTransitionOut` (`name=0x006394C8`) sendo regravado como `1` no registro
  `0x01ECB154`. Nenhum setter publicou `EndOfTransitionOut`.
- O savestate retail de 2026-08-26 foi carregado via PCSX2/Pine somente para
  leitura. Ele preserva o mesmo slot `0x01EA6040 -> 0x01EA6310`, a mesma area de
  propriedades e mostra `StartOfTransitionOut=1/type=3` em `0x01ECB154` e
  `EndOfTransitionOut=1/type=3` em `0x01ECB164`.
- A diferenca causal ficou reduzida a um unico estado: o retail publica End=1 e o
  recomp nao. O helper de consulta, o nome, o registro, o tipo e o layout estao
  corretos. A proxima busca deve localizar o update/script por frame que escreve
  diretamente esse registro ou chama o setter correspondente no retail.
- O PCSX2 local oferece Pine, mas nao o DebugServer 21512; por isso ainda nao foi
  capturado o PC exato do writer retail. Nenhuma memoria retail foi escrita e o
  emulador foi fechado apos a leitura.
- Logs preservados:
  `work/logs/14_run_boot_trace_transition_property_read_20260826.log` e
  `work/logs/14_run_boot_trace_transition_setters_20260826.log`. O segundo run
  manteve render forte ate `gsPrims=278154`, `gsPixels=101075598`.

## Checkpoint 2026-08-26 - owner indireto reduzido ao update de UI/script

- A auditoria de callers confirmou que nao existe outro `jal 0x20B198` visivel:
  o unico setter recompilado do objeto continua sendo `0x320848`, usado para
  `StartOfTransitionOut`. Isso descarta um segundo setter direto escondido no
  corredor conhecido; `EndOfTransitionOut` deve vir de callback/VM ou escrita
  indireta da tabela.
- O dump passivo de `0x20B1D0` provou que os registros sao nos encadeados de 16
  bytes: Start ocupa `0x01ECB154` (`raw=1`, `type=3`) e End ocupa
  `0x01ECB164` (`raw=0`, `type=3`). Os links seguintes sao `0x01ECB150` e o nome
  em `0x01EA6717`; portanto End esta registrado e ligado corretamente na tabela.
- O cabecalho do contexto `0x01EBB660` permanece vivo entre frames. O primeiro
  campo variou de `0x3C82F4E7` a `0x3C82F2CB` enquanto ponteiros internos ficaram
  estaveis, evidenciando estado temporal ativo no contexto de UI/script. O
  problema nao e congelamento geral do objeto: e a acao especifica que deveria
  publicar End.
- O probe do caminho virtual `FUN_001AB130` foi compilado e ligado, mas nao teve
  nenhuma entrada no mesmo intervalo em que `FUN_001AAE80` armou a transicao e
  `0x1AC238` passou a consultar End. Isso reduz o proximo alvo ao outro ramo de
  update, `state+0x4008 -> 0x1AC348` (incluindo `0x3A1400` e o `jalr` em
  `0x1AC384`), ou a uma continuation perdida antes de `0x1AB130`.
- Run headless em prioridade `BelowNormal`: gate de render permaneceu positivo
  (`gifPk1=60795`, `gifPk2=23802`, `gsPrims=122715` no ultimo frame amostrado),
  sem PCSX2, janela, input sintetico ou mudanca de semantica. Evidencia em
  `work/logs/14_run_boot_trace_transition_layout_20260826.log`.

## Checkpoint 2026-08-26 - armamento bloqueia em WaitSema do worker0

- O ramo `state+0x4008 -> 0x1AC348` foi descartado como produtor de End nessa
  tela: o campo permanece nulo, mas isso e intencional. A construcao em
  `FUN_001AAEE8` recebeu `mode=4`, e a propria logica de `0x1AAF30..0x1AAF64`
  define `create=0` para os modos 3/4/5. Nao ha objeto ausente a ser inventado.
- A tela/script real continua em `state+0x4014 = 0x01EA6040`, que aponta para
  `0x01EA6310`. Ela deveria ser atualizada por `FUN_001AB130` depois que o
  armamento retorna a `FUN_001AA9B8`.
- Telemetria das quatro continuations de `FUN_001AAE80` mostrou que
  `sub_001AB078` retorna normalmente a `0x1AAEA0`, mas a chamada seguinte
  `0x1AAEA0 -> 0x398B18(worker0)` nao retorna a `0x1AAEA8`. As continuations
  `0x1AAEA8`, `0x1AAEB0` e `0x1AAED0` nao foram observadas.
- `0x398B18` e somente um wrapper legitimo de `WaitSema(0x5469E0)`. O worker0
  observado era o semaforo `0xE0`; ele foi criado em `FUN_001AADB8` e pertence a
  thread guest iniciada em `0x1AAB60`. Essa thread deveria executar
  `FUN_001AAB90` e, ao final, chamar `0x398B40 -> SignalSema(0x5469C0)` em
  `0x1AAC54`.
- A nova fronteira causal e, portanto, a thread loader `0x1AAB60/0x1AAB90`: ela
  nao alcanca o SignalSema final. O proximo probe deve marcar as continuations
  `0x1AABA8`, `0x1AABC4`, `0x1AABE8`, `0x1AABF4`, `0x1AAC04`, `0x1AAC0C`,
  `0x1AAC14`, `0x1AAC1C`, `0x1AAC24`, `0x1AAC40`, `0x1AAC54` e `0x1AAC5C`,
  com atencao especial ao loop `0x1AABE0..0x1AABF4`.
- Evidencias: `work/logs/14_run_boot_trace_transition_pair_null_20260826.log`,
  `work/logs/14_run_boot_trace_transition_mode4_20260826.log` e
  `work/logs/14_run_boot_trace_transition_worker0_wait_20260826.log`. Tudo
  headless e em prioridade `BelowNormal`; sem sinal manual, retorno forcado,
  gate semantico ou mudanca de scheduler.

## Checkpoint 2026-08-26 - timeline legal reduzida as acoes logicas

- O worker `FUN_001AAB90` nao esta morto: ele chama repetidamente
  `0x1AAC70`, atualiza/desenha a tela por `0x1AAD28` e so nao alcanca
  `0x1AAC54 -> SignalSema` porque `EndOfTransitionOut` continua zero.
- A arvore real de update foi separada da arvore de draw. O caminho ativo e
  `1AAD28 -> 1AC2A0 -> 320B38 -> 20ACD0 -> 20B538 -> 20D260 -> 20FA18 ->
  20D3A8 -> 20C248`. Os 26 nos sao visitados; 11 containers estao ativos e
  chamam o relogio `0x20C248`. O callback especial de draw `0x210870` foi
  descartado como produtor de End.
- Todos os 11 containers ativos tem `frame=0`, `frameCount=1`, vtable
  `0x00624878` e setter `0x20C190`. Portanto a timeline nao esta congelada:
  sao animacoes validas de um unico quadro, que naturalmente permanecem em
  `0/1`. Por isso a troca de frame `20C190 -> 20FA88 -> 211660` nao roda.
- As acoes do quadro unico executam pela rota correta de inicio
  `20FA18 -> 211610`. Foram observadas 109 chamadas de start e 112 de stop.
  Os alvos ativos ficaram restritos a `0x212D70`, `0x212F60`, `0x213058` e ao
  no-op retail `0x5BA3D0`; nenhuma dessas rotas chama `0x20B198/0x20B258` ou
  escreve `0x01ECB164`. As listas atuais contem acoes visuais, mas nao a acao
  logica que publica o fim da transicao.
- O menor proximo corredor e descobrir onde a acao logica da raiz
  `0x01EBB660` deveria ser montada/avaliada. Pistas concretas: `0x320B38`
  sempre atualiza a arvore, mas o worker usa `a2=0` e pula o processamento
  `0x20B290` que os callers de foreground executam com `a2=1`. Isso e uma
  diferenca comprovada de modo, ainda nao uma causa autorizada para alteracao.
- Evidencias preservadas em
  `work/logs/14_run_boot_trace_transition_update_tree_20260826.log`,
  `work/logs/14_run_boot_trace_transition_animation_state_20260826.log`,
  `work/logs/14_run_boot_trace_transition_timeline_20260826.log` e
  `work/logs/14_run_boot_trace_transition_action_routes_20260826.log`.
  O render continuou forte (`gifPk1=62146`, `gifPk2=24418`,
  `gsPrims=125474`) e End permaneceu zero. Toda instrumentacao foi passiva.

## Checkpoint 2026-08-27 - lista visual igual ao retail; produtor de End ainda nao executa

- O ramo `a2=0` versus `a2=1` foi fechado: `0x20B290` apenas consulta a
  propriedade `readyformenu` (`0x20AF60 -> 0x20DDB8`) e converte seu valor para
  booleano em `0x20E628`. Ele e consumidor/controle de UI, nao produtor de
  `EndOfTransitionOut`.
- Os savestates PCSX2 foram lidos offline. No `resume` retail, Start=0/End=0;
  em `.01` e `.02`, Start=1/End=1. O layout e os enderecos batem com o nativo.
- A lista de acoes pre-transicao tambem bate exatamente. Retail `resume` e
  nativo contem as mesmas 8 acoes de vtable `0x00624B08`, 14 de
  `0x00624B28` e 3 de `0x00624B68`; ambos tem zero objetos `0x00624B48`
  (`InitAction`) e zero `0x00624B88`. Portanto nao falta asset/acao visual no
  carregamento nativo.
- Um scanner das instrucoes do ELF encontrou todas as referencias literais aos
  nomes Start/End somente em `0x1AC25C..0x1AC274`, dentro de `0x1AC238`.
  Start e escrito pelo setter conhecido; End e apenas lido. Isso comprova que
  a publicacao final ocorre por escrita indireta/script, nao por um segundo
  setter literal escondido.
- A vigia passiva de memoria cobriu `0x01ECB164..0x01ECB167` durante 165 s e
  registrou zero escritas, enquanto a transicao foi consultada repetidamente e
  o render chegou a `gifPk1=59444`, `gifPk2=23360` e `gsPrims=120020` antes de
  continuar crescendo. Logo o produtor de End nao executou; ele nao executou
  com um valor errado.
- A fronteira agora esta fora do renderer e das listas visuais: localizar o
  callback/VM de ciclo de vida que, no retail, reage a Start, conclui a
  transicao e so entao reorganiza/destroi a arvore. O proximo probe deve mirar
  o primeiro desvio de estado anterior ao teardown retail, sem escrever End.
- Evidencias: `work/captures/mc3_legal_native_heap_20260827.bin`,
  `work/logs/14_run_boot_trace_transition_native_heap_20260827.log` e
  `work/logs/14_run_boot_trace_end_watch_20260827.log`. Nenhum jogo/emulador foi
  aberto; sem SignalSema injetado, retorno forcado, gate semantico ou mudanca
  de scheduler.

## Checkpoint 2026-08-27 - transicao legal concluida naturalmente; proximo bloco em 0x5B92E0

- `0x211770` foi identificado como o interpretador AVM1/ActionScript usado
  pelos eventos de frame da tela. Os scripts relevantes estao no `ASSETS.DAT`
  e executam por `0x213058/0x212CD0 -> 0x211770`.
- O script em `0x01EBAA24` incrementa `n`, move o texto por
  `_global.increment` e publica `_global.scrollstatus=1` quando
  `increment * (n - 3) > siseoftext - 115`. Com os valores reais
  `increment=1.1` e `siseoftext=650`, o limiar fica perto de `n=490`.
- O script em `0x01EBAB7C` observa simultaneamente
  `scrollstatus=1` e `StartOfTransitionOut=1`, conta 27 ciclos de fade e entao
  publica `EndOfTransitionOut=1`.
- A execucao longa confirmou toda a cadeia sem escrita artificial: `n` passou
  pelos marcos 50, 100, 150, 200, 250, 300, 350, 400 e 450;
  `scrollstatus` virou 1 e, 27 ciclos depois, `EndOfTransitionOut` virou 1.
  Portanto a tela nao estava travada: o runner parcial apenas executa esta
  animacao muito mais devagar que o console/emulador.
- Depois de End=1 o fluxo deixou a transicao e alcancou um novo bloqueio
  concreto: funcao ausente `0x5B92E0`, chamada por `0x201120` com
  `ra=0x442CB4`. Este e o novo menor corredor para a etapa seguinte do
  frontend/menu.
- Evidencias: `work/logs/targeted_transition_probe_20260827.log`,
  `work/scratch/disasm_avm1_transition.py` e
  `work/scratch/find_script_variable_nodes.py`. A instrumentacao foi somente
  passiva; sem SignalSema injetado, retorno forcado, gate semantico ou mudanca
  de scheduler.

## Checkpoint 2026-08-27 - alias 0x5B92E0 recompilado; retail usado como oracle visual

- O PCSX2 retail foi aberto com autorizacao e os savestates `.01/.02` foram
  inspecionados. Eles mostram quadros do video de abertura com carros/rodas,
  nao comprovam geometria 3D de veiculo. A tela `Press Start`, por outro lado,
  ja confirma geometria 3D da cidade no retail.
- `0x5B92E0` foi fechado estaticamente como continuation de
  `sub_005B90D8`: e um accessor `table[index]`, nao loader de carro. O owner ja
  estava compilado, mas essa entrada interna faltava no dispatcher.
- Foi adicionado o resume entry `case 0x5B92E0 -> label_5b92e0`, o objeto do
  `batch_0060` foi recompilado e o gerador passou a registrar o alias
  `runtime.registerFunction(0x5B92E0, sub_005B90D8_0x5b90d8)`.
- O partial runner foi relinkado com sucesso. O proximo boot deve atravessar o
  accessor e revelar o primeiro bloqueio posterior. Para geometria, os probes
  concretos sao `gfxGetModel=0x1E6B40`, `gfxModel::Draw=0x1E5198`,
  `gfxGeometry::Draw=0x1E7158` e `gfxGeometry::LoadMod=0x1E8478`.

## Checkpoint 2026-08-28 - 0x5B92E0 atravessado; cinco continuations fechadas em lote

- Um boot headless de 20 minutos com o alias novo concluiu novamente a tela
  legal e atravessou `0x5B92E0`. O runner permaneceu vivo ate o timeout; nao
  houve novo crash fatal.
- Depois da transicao foram observadas 27 continuations ainda nao registradas.
  As cinco mais frequentes/ativas foram fechadas no mesmo lote:
  `0x2B8768`, `0x38C558`, `0x222C08`, `0x5BA578` e `0x2A6448`.
- Cada endereco foi adicionado como resume entry no owner que ja continha as
  instrucoes correspondentes. Os objetos dos batches `0008`, `0016`, `0017`,
  `0026` e `0060` compilaram; o gerador passou de 168356 para 168361 aliases
  internos e o partial runner foi relinkado com sucesso.
- Os PCs de geometria conhecidos sao continuations internas, nao entradas
  isoladas. Os owners corretos para probes futuros sao `0x1E66E8`
  (gfxGetModel), `0x1E8448` (LoadMod), `0x1E7118` (preparacao de geometria) e
  `0x1E50E0` (draw do modelo). Ainda nao ha caller virtual de veiculo
  comprovado, portanto nenhum desses owners foi forcado.
- Evidencia principal: `work/logs/targeted_transition_probe_20260827.log`.
  Sem SignalSema injetado, retorno forcado, gate semantico ou alteracao do
  scheduler.

## Checkpoint 2026-08-28 - todas as 27 continuations do lote fechadas; geometria espera frontend

- As 22 continuations restantes do boot anterior foram auditadas e adicionadas
  aos owners corretos, preservando a execucao dos delay slots nos helpers de
  retorno. Com as cinco anteriores, todas as 27 ausencias observadas foram
  fechadas.
- Dez owners compilaram em paralelo. O registro passou de 168361 para 168383
  aliases internos e o partial runner foi relinkado com sucesso.
- Um boot de validacao concluiu novamente a tela legal. Depois de End=1, nenhum
  dos 27 warnings antigos reapareceu e nenhum novo `Function at address ... not
  found` foi observado no intervalo validado.
- Foram instalados probes passivos nos owners `0x1E66E8` (gfxGetModel),
  `0x1E8448` (LoadMod), `0x1E7118` (preparacao de geometria) e `0x1E50E0`
  (draw). Nenhum deles executou antes ou imediatamente depois da transicao.
  Isso comprova que a tela legal e seu video nao carregam geometria 3D de
  veiculo por essa rota.
- A proxima acao causal e input real do frontend apos a tela/title, usando o
  mapeamento confirmado `Enter=Start` e `Numpad5=X`, para provocar selecao e
  carregamento de modelo. Nao ha justificativa para forcar um owner de
  geometria diretamente.

## Checkpoint 2026-08-28 - 0x5B92E0 atravessado; novo bloqueio em datStreamer::Close

- Correcao de endereco importante: os quatro alvos de geometria anotados no
  checkpoint anterior (`0x1E6B40`, `0x1E5198`, `0x1E7158`, `0x1E8478`) sao
  enderecos do **alpha build**, nao do retail. Em `work/exports/retail_symbol_port.csv`
  eles aparecem na coluna `alpha_addr`. Os enderecos validos para o recompilado
  de `SLUS_213.55` sao `gfxModel::Draw=0x001EB998`, `gfxGetModel=0x001ED340`,
  `gfxGeometry::Draw=0x001ED930` e `gfxGeometry::LoadMod=0x001EEC50`. Os quatro
  ja existem como entradas de funcao, ja estao compilados (batches 0004/0005) e
  ja estao ligados; nao faltava nada.
- Os quatro receberam trace passivo de entrada (contador + `fprintf`, sem mudanca
  de fluxo). Patch idempotente em `work/scratch/patch_gfx_traces.py`.
- Corrida headless de 1800 s (`work/logs/gfx_probe_20260828_gfx1.log.stderr`,
  tick final `100380`): **zero funcoes ausentes, zero `first-bad-pc`, zero
  `unimplemented`**. `0x5B92E0` esta comprovadamente atravessado; o alias
  `runtime.registerFunction(0x5B92E0, sub_005B90D8_0x5b90d8)` esta no manifesto
  ligado e o manifesto de stubs continua so com cabecalho.
- A transicao legal terminou naturalmente de novo: os scripts AVM1 chegaram a
  `endRaw=1 scrollRaw=1` com `n` passando de 518. Em seguida o fluxo avancou de
  verdade: `mc3-legal-worker-signal sid=83`, `thread-exit id=7`,
  `start-thread-request/enter id=8 entry=0x1f9668`, e chamadas novas em
  `0x3451E8`, `0x42E8A0`, `0x430C90`, `0x4323E8`, alem de
  `uiGroup::SetActiveState(bool)` (`0x0041F550`).
- **Novo bloqueio, e ele nao e funcao ausente: `datStreamer::Close(unsigned int)`
  em `0x004323E8`.** O PC estavel final e `0x432450` com `ra=0x432458`, dentro do
  laco de espera `0x432450 -> 0x432458 -> 0x43245C`, que chama
  `func_398C60(10)` (`= func_547608(10*1000)`, DelayThread de 10 ms) enquanto
  `[entry+0xC] != 0`.
- Anatomia confirmada estaticamente:
  - `datStreamer::InitClass(n)` (`0x004324D8`) aloca o pool com `n*16` bytes,
    guarda a base em `0x006D5C58`, o tamanho em `0x006D5C54`, a flag de streamer
    ativo em `0x006D5C5C`, e cria a thread worker com
    `ipcCreateThread(0x00431E00, 0, 0x006D5C80, 0x1000, prio=6)` (`0x00398B88`).
  - `datStreamer::Read(handle, dest, size, offset, ipcSemaTag*)` (`0x004320E0`)
    incrementa `[0x006D5C64]` (total pendente) e `[entry+0xC]` (pendente do
    handle), enfileira no anel `0x006D5B00` (`+0x140` head, `+0x144` tail,
    `+0x148` count, capacidade `0x10`, item de `0x14` bytes) e sinaliza
    `+0x150` (trabalho) e `+0x14C` (mutex).
  - A worker `0x00431E00` estaciona em `WaitSema([0x006D5B00+0x150])` em
    `0x432020`, desenfileira, le, e so entao decrementa `[entry+0xC]` em
    `0x431FFC..0x432004` e `[0x006D5C64]` em `0x43200C..0x432014`.
- Estado observado no bloqueio: `poolBase=0x006771E0`, `poolEntry=0x006771F0`
  (indice 1), `[entry+0xC] = 1` estavel por mais de 20 minutos, ou seja
  **exatamente uma leitura pendente**; `[0x006D5C60] = 2` (cabeca da free-list),
  `[0x006D5C54] = 0x10` (16 handles) e flag `0x006D5C5C = 1`. Leitura dos campos
  conferida contra a definicao do trace `mc3-4323e8-progress` em
  `sub_004323E8_0x4323e8.cpp`: `busy` e `[entry+0xC]`, `current` e a free-list e
  `mask` e o numero de handles. A thread worker `id=3 entry=0x431e00` **entrou** (linha 72 do
  log), logo ela existe e rodou. A ultima atividade real antes do laco foi uma
  leitura de CD concluida: `kind=read lsn=0x197e2f sectors=0x41 buf=0x1d28700
  readOk=1` com `endCallbackInvoked=1`. Depois disso, so o laco de espera.
- Portanto a fronteira causal e: **uma leitura pendente no handle 1 que a
  worker nunca conclui**. Falta provar se a worker esta estacionada no
  `WaitSema` de trabalho (fila vazia, contador vazado) ou presa dentro do
  caminho de leitura.
- Instrumentacao passiva adicionada para responder exatamente isso
  (`work/scratch/patch_streamer_traces.py`): `mc3-datstreamer-read` na entrada de
  `0x4320E0`, `mc3-streamer-worker-dequeue` em `0x431E30`,
  `mc3-streamer-worker-done` apos o decremento em `0x432004` e
  `mc3-streamer-worker-park` antes do `WaitSema` em `0x43201C`.
- Render segue forte e crescente durante todo o bloqueio: `gifPk1=348558`,
  `gifPk2=136612`, `gsPrims=703599`, `gsPixels=256036663`. Nenhum trace
  `mc3-gfx-*` disparou ainda, o que e coerente: o frontend ainda nao chegou a
  carregar/desenhar modelo.
- Limitacao conhecida do modo headless: `MC3_HEADLESS=1` cria a janela com
  `FLAG_WINDOW_HIDDEN` (`ps2_runtime.cpp:1001`) e o pad e lido por `IsKeyDown`
  (`Kernel/Stubs/Pad.cpp:160`). Janela oculta nunca recebe foco, entao `Start`
  nunca pode ser pressionado nessa modalidade. Para passar de `Press Start` sera
  preciso uma corrida com janela visivel e a tecla `Enter` pressionada de fato.
- Ancoras ja mapeadas para a etapa do carro (todas compiladas e registradas):
  `rmcCarModel::rmcCarModel=0x002F6410` (batch_0019),
  `rmcCarModel::GetCar=0x002F6BB0`, `rmcCarModelClass::SetRenderStates=0x00307248`,
  `vehModel::vehModel=0x00560E08`.
- Toda a instrumentacao desta sessao foi passiva: sem `SignalSema` injetado, sem
  retorno forcado, sem gate semantico, sem mudanca de scheduler e sem env-gate novo.

## Checkpoint 2026-08-28 - streamer atravessado; bloqueio real e o canal DMA VIF0

Corrida `work/logs/gfx_probe_20260828_stream1.log.stderr` (1200 s headless, tick
final `66360`), com a instrumentacao passiva do corredor `datStreamer`.

- **Correcao do checkpoint anterior: `datStreamer::Close` nao e deadlock.** Os
  traces novos mostram o ciclo completo e correto:
  `mc3-datstreamer-read call=2 handle=0x1 dest=0x01d28700 tamanho=0x00170800 sema=0xaa ra=0x00430c54`
  -> `mc3-streamer-worker-dequeue call=2` -> `mc3-streamer-worker-done call=2
  entry=0x006771f0 pendingAfter=0x00000000` -> `mc3-streamer-worker-park call=3
  head=2 tail=2 count=0 outstanding=0`. E o proprio `Close` saiu do laco:
  `stage=0x00432464 busy=0x00000000` e depois `stage=0x004324b8 busy=0x00000002`
  (o `+0xC` sendo reescrito como elo da free-list) com `[0x006D5C60] = 1`.
  A corrida de 1800 s anterior ficou 65 mil ticks nesse mesmo ponto com
  `busy=1`; a diferenca entre as duas corridas e de tempo/agendamento, nao de
  semantica. Por que a primeira corrida nao recebeu a conclusao continua **em
  aberto**, nao explicado.
- Nomes dos argumentos do meu proprio trace `mc3-datstreamer-read` estao
  trocados: os valores provam `Read(handle, dest, offset, size, ipcSemaTag*)`.
  O worker usa `sp[8]>>11` como setor inicial e `sp[0xC]>>11` como contagem
  (`0x170800 >> 11 = 0x2E1` = 737 setores, em blocos de `0x41`).
- **Novo PC estavel: `0x3A01C8`** (`sub_003A0130_0x3a0130`, batch_0028), estavel
  do tick ~36300 ate 66360. Ele e um laco de espera de DMA, nao de semaforo:
  - `0x3A0184`: escreve o endereco fonte em `0x10008010` (D0_MADR)
  - `0x3A0194`: escreve a contagem em `0x10008020` (D0_QWC)
  - `0x3A01A8`: escreve `0x100` em `0x10008000` (D0_CHCR, bit STR)
  - `0x3A01C8`: `lw $v0, 0($v1)` com `$v1 = 0x10008000`
  - `0x3A01DC`: `bnez $v0, 0x3A01C8` apos `andi $v0, 0x100`
  Ou seja: `while (D0_CHCR & STR)`.
- **Causa provada no runtime:** `PS2Memory::writeIORegister` trata o start de DMA
  em `ps2_memory.cpp:915` para a faixa `0x10008000..0x1000F000`, mas so tem
  caminho de conclusao para `0x1000D000` (fromSPR, limpa STR em
  `ps2_memory.cpp:982`), `0x1000A000` (GIF) e `0x10009000` (VIF1) - estes dois
  limpos em `ps2_memory.cpp:1500` e `ps2_memory.cpp:1506`. **O canal 0
  (VIF0, `0x10008000`) nao tem nenhum caminho de conclusao**, entao o STR
  escrito pelo jogo nunca e limpo. Nao ha `VIF0_CHANNEL` no arquivo.
  Atencao: limpar STR sem executar a transferencia VIF0 seria gate semantico e
  esta fora das regras do projeto; a correcao precisa implementar o canal.
- **Lacunas de recompilacao encontradas (classe diferente de `0x5B92E0`):** oito
  PCs ausentes, todos em **vaos entre funcoes recompiladas**, ou seja, regioes
  que o Ghidra nunca transformou em funcao. Nao existe nem `label_` nem `case`
  para eles, logo o conserto usado em `0x5B92E0` (adicionar resume entry) nao se
  aplica; e preciso criar e gerar as funcoes.

  | PC ausente | ocorrencias | funcao anterior (fim) | proxima funcao |
  |---|---|---|---|
  | `0x501208` | 184 | `FUN_00501168` (`0x501194`) | `0x501318` |
  | `0x5C5718` | 45 | `FUN_005c56e8` (`0x5c5704`) | `0x5C57C8` |
  | `0x5CCCA8` | 8 | `FUN_005ccbb0` (`0x5ccbcc`) | `0x5CCCC0` |
  | `0x5CCD28/30/38` | 7/2/8 | `FUN_005cccc0` (`0x5ccd24`) | `0x5CCD58` |
  | `0x5CCE60/68` | 2/1 | `FUN_005ccd58` (`0x5ccdbc`) | `0x5CD0C8` |

  O primeiro `first-bad-pc` mostra que sao corpos de metodo virtual:
  `bad=0x5cce60 ra=0x44a2b4 v0=0x5cce60 v1=0x6327f8 a0=0x7d9e60`, com
  `v0 == bad` (chamada `jalr $v0`) e cadeia
  `0x20bf10 -> 0x4328a0 -> 0x20e140 -> 0x20ddb8 -> 0x20bf10` (sistema de
  propriedades da UI). Mesma forma de `0x5B92E0`, mas em area nao analisada.
- **Nenhum trace `mc3-gfx-*` disparou em nenhuma das duas corridas.** A cadeia
  `gfxGetModel/LoadMod/Draw` esta instrumentada e ligada, mas nada a chamou
  ainda. Portanto **continua sem prova de modelo 3D de carro no recompilado**.
- Contadores finais congelados desde o teardown da tela legal: `gifPk1=348558`,
  `gifPk2=136612`, `gsPrims=703599`, `gsPixels=256036663`, `dma=29419`.
  `uiInputUpdateCalls` saiu de 0 para 3 pela primeira vez.
- Instrumentacao 100% passiva; sem `SignalSema` injetado, sem retorno forcado,
  sem gate semantico, sem mudanca de scheduler, sem env-gate novo.

## Checkpoint 2026-08-28 - VIF0 normal implementado; nova fronteira e source-chain

- O canal DMA 0 agora consome de verdade as QWC quadwords da RDRAM/SPR em um
  FIFO VIF0 explicito, avanca MADR, zera QWC, limpa STR somente apos a copia e
  levanta `D_STAT.CIS0`. O FIFO ficou fora do layout da classe para preservar a
  ABI dos objetos gerados do partial runner.
- Build do runtime verde, suite reproduzida em 299/299 e relink fast concluido;
  `mc3_partial.exe` ficou mais novo que `libps2_runtime.a`, com manifesto de
  stubs somente no cabecalho.
- Probe headless de 900 s capturou a transferencia normal
  `madr=0x005F29D0 qwc=0x34 chcr=0x100`; o PC nao reapareceu em `0x3A01C8` e
  estabilizou em `0x3A0460`. Portanto o aceite do modo normal foi satisfeito.
- A transferencia seguinte e source-chain: `tadr=0x006CCCE0 chcr=0x144`. Como
  chain estava fora do minimo obrigatorio, ela permaneceu ativa e foi marcada
  por `boot-trace:dmac-vif0-chain-todo`; nenhum fim falso foi injetado.
- Render ficou congelado em `gifPk1=348558`, `gifPk2=136612`, `gsPrims=703599`
  e `gsPixels=256036663`; zero `mc3-gfx-*`, logo ainda nao ha evidencia nova de
  modelo 3D. O `first-bad-pc=0x5CCE60` pertence as regioes Ghidra excluidas.
- Evidencia completa: `docs/RESULT_VIF0_DMA_2026-08-28.md` e
  `work/logs/gfx_probe_20260828_vif0.log.stderr`.
- Proximo lote: implementar VIF0 source-chain sem fingir conclusao; depois
  interpretar o pacote VIF0/VU0 e tratar os vaos Ghidra separadamente.

## Checkpoint 2026-08-28 - VIF0 source-chain atravessado; render voltou a crescer

- O canal DMA 0 agora interpreta a source-chain e transporta os dados reais
  para o FIFO VIF0. TTE injeta os 8 bytes superiores do DMAtag antes do
  payload; REFE/CNT/NEXT/REF/REFS/CALL/RET/END, TIE/IRQ e a pilha ASR/ASP sao
  tratados. STR e D_STAT so concluem depois de uma chain terminal valida.
- Suite completa verde em **300/300**, build oficial verde e fast relink
  concluido. O partial runner foi renovado sem stub novo.
- O probe real capturou duas chains `CHCR=0x144`, em `TADR=0x006CCCE0` e
  `0x006CCD00`; cada uma processou um tag, entregou 1032 bytes e terminou com
  `completed=1`. O antigo gate VIF0 foi atravessado.
- Logo depois, render saiu do plateau anterior: `gifPk1 348558->348560`,
  `gifPk2 136612->136981`, `gsPrims 703599->703668`, `gsPixels
  256036663->257216311` e `dma 29420->29435`. Conforme o contrato, o runner foi
  parado e o log preservado. Os contadores ficaram nesse novo plateau ate a
  parada.
- Zero `mc3-gfx-*`: ha evidencia nova de atividade grafica, mas ainda nao de
  modelo 3D carregado/desenhado. O PC amostrado depois ficou em `0x41D188`.
- Interpretacao de VIFcode/VU0 permanece TODO declarado. As regioes Ghidra
  excluidas nao foram tocadas; houve `first-bad-pc=0x5CCE60` e warnings nas
  lacunas ja conhecidas.
- Evidencia completa: `docs/RESULT_VIF0_SOURCE_CHAIN_2026-08-28.md` e
  `work/logs/gfx_probe_20260828_vif0_chain_final.log.stderr`.

## Checkpoint 2026-08-28 - Start real confirmado no runner nativo

- A janela nativa chegou visualmente ao logo/aviso legal de MC3 Remix.
- Um `Enter` real foi enviado ao runner. O trace confirmou a mudanca de
  `startRequested=0` para `startRequested=1` e a entrada na transicao legal;
  portanto o input do host, o pad virtual e o frontend estao conectados.
- A tela continuou rolando o aviso legal por varios minutos. Um segundo Enter
  nao pulou a animacao; o bloqueio observado e lentidao da sequencia, nao uma
  funcao ausente nova.
- Os probes `mc3-gfx-*` ainda nao dispararam neste intervalo. O teste foi
  encerrado de forma controlada antes do menu; ainda nao ha prova de geometria
  de carro.
- No runner nativo, `Enter = Start` e `X = Cruz`. `Numpad 5 = Cruz` e apenas o
  mapeamento do perfil PCSX2 informado pelo usuario.
- Proximo lote: acelerar ou instrumentar o criterio de termino da transicao
  legal sem alterar sua semantica; depois repetir o Start ate o primeiro frame
  do menu e observar `gfxGetModel/LoadMod/Draw`.

## Checkpoint 2026-08-29 - traces gfx em endereco alpha removidos

- O Codex entregou VIF0 normal (`8e5d233`) e VIF0 source-chain (`9d5c405`), com
  suite 299/299 e 300/300. Verifiquei os dois RESULT contra os logs: os numeros
  batem. O PC saiu de `0x3A01C8` -> `0x3A0460` -> `0x41D188`.
- **Os contadores de render voltaram a crescer** pela primeira vez desde o
  teardown da tela legal, confirmado no frame final de
  `work/logs/gfx_probe_20260828_vif0_chain_final.log.stderr`:
  `gifPk2` 136612 -> 136981, `gsPrims` 703599 -> 703668,
  `gsPixels` 256036663 -> 257216311. Isso e atividade grafica nova e real, mas
  **nao prova modelo 3D**; zero traces `mc3-gfx-*`.
- As 5 regioes nao analisadas foram fechadas (nao documentado em RESULT): os 7
  PCs ausentes ganharam resume case em `sub_00501088`, `sub_005C2880` e
  `sub_005CC8C8`.
- **Defeito corrigido nesta sessao:** em 28/08 16:02 foram instrumentados os
  owners dos enderecos do **alpha build** (`0x1E5198`, `0x1E6B40`, `0x1E7158`,
  `0x1E8478`). O runner e retail `SLUS_213.55`, onde esses enderecos sao funcoes
  sem nome e sem relacao com gfx. Um disparo ali imprimiria
  `mc3-gfx-model-draw` para funcao errada, criando falsa evidencia de carro.
  Removido por `work/scratch/remove_alpha_gfx_traces.py`; a instrumentacao
  retail (`0x1EB998`, `0x1ED340`, `0x1ED930`, `0x1EEC50`) foi preservada.
- **Achado colateral grave:** `find_stale.py` reportou `Stale: 0` logo apos a
  edicao dos 4 arquivos. Os objetos tinham sido compilados em 16:02 sem
  atualizar `compile_manifest.json`, entao o hash do `.cpp` original ainda
  casava enquanto o `.o` continha o trace alpha. Corrigido removendo as 4
  entradas do manifesto e recompilando. **Risco em aberto:** o manifesto pode
  estar dessincronizado em outros objetos; auditoria de hash completa pendente.
- Relink `fast` OK. `mc3_partial.exe` 2026-08-29 02:27, mais novo que a lib,
  zero stubs ausentes, cada string `mc3-gfx-*` agora com contagem 1 (era 2).
- Detalhes: `docs/RESULT_ALPHA_GFX_TRACE_REMOVAL_2026-08-29.md`.

## Checkpoint 2026-08-29 - build otimizado; -O0 nao era o gargalo

- O projeto **nunca havia sido compilado com otimizacao**. O codigo gerado
  (`tools/parallel_compile.py`) nao passava nenhuma flag `-O` e o CMake estava em
  `Debug`. Corrigido para `-O2 -fno-strict-aliasing` e `RelWithDebInfo`, com
  bump de `COMPILE_KEY` nas duas ferramentas para invalidar o manifesto.
- Bug latente que o `-O0` escondia: `_mm_extract_epi32` (SSE4.1, `always_inline`)
  usado para ler os registradores guest `__m128i` em `ps2_runtime.h:185`. O
  `CMakeLists.txt` so tinha branch ARM64/NEON; faltava branch x86-64 com
  `-msse4.1`. Qualquer build otimizado falhava com "target specific option
  mismatch". Corrigido.
- Recompilacao completa: 15.512 objetos, `failures=0`, 2378 s. Suite 300/300 sob
  `-O2`. `libps2_runtime.a` 115 MB -> 67 MB; `mc3_partial.exe` 521 MB -> 284 MB.
- **Equivalencia semantica confirmada**: o estado final do `-O2` e identico ao do
  `-O0` — mesmo PC `0x41D188`, contadores identicos (`gifPk1=348988`,
  `gifPk2=138800`, `gsPrims=704397`, `gsPixels=257216311`), mesmos PCs ausentes e
  mesmas transferencias VIF0.
- **Correcao de diagnostico:** eu havia afirmado que a lentidao era "em primeira
  ordem `-O0`". Errado. Medindo o tick do `End=1`: `-O0` = 35.040 e 30.180;
  `-O2` = 25.680. Ganho de **~20%**, nao de ordem de magnitude. O subagente
  provou que o `-O0` existia; ninguem provou que ele dominava o tempo.
- `ticks/s` foi descartado como metrica de velocidade do guest: o loop tem
  `SetTargetFPS(60)` (`ps2_runtime.cpp:1009`), entao o tick e frame do host no
  vsync. `-O0` = 55,8 e `-O2` = 54,0 ticks/s, ambos no teto.
- **Gargalo real, ainda nao resolvido:** a tela legal precisa de 490 iteracoes de
  script (490 frames = ~8 s no PS2 real) e consome 25.680 frames de host, ou seja
  **~52 frames de host por frame de guest**, com o host sempre a 54-60 fps. O
  problema e quanto trabalho de guest roda por frame. `MC3_DISPATCH_BUDGET` e so
  condicao de parada, nao throttle. Hipotese nao provada: o guest cede controle
  cedo demais por frame, em espera de VBlank/semaforo no scheduler.
- Detalhes: `docs/RESULT_O2_BUILD_2026-08-29.md`.

## Checkpoint 2026-08-29 - boot args retail pelo crt0

- O override real do crt0 foi implementado: `mc3_partial.exe <elf> -skipintro -garage`
  chega a `datArgParser::Init` retail `0x00428AC0` como `argc=3`, com
  `argv[1]="-skipintro"` e `argv[2]="-garage"`. Nenhuma global `PARAM_*` e
  escrita diretamente.
- Layout provado do bloco apontado por `0x614400`: `+0` ID de semaforo do loader,
  `+4` argc, `+8` vetor de ponteiros de 32 bits, seguido por strings referenciadas
  e terminadas em NUL. Nao foi inventado sentinela `argv[argc]`.
- Achado decisivo: `_start` zera `0x614400` na primeira instrucao. O runtime monta
  o bloco antes do entry, mas publica o ponteiro durante o syscall `SetupThread`
  `0x3C`, depois do clear de BSS.
- Guarda sem argumentos intacta: parser recebeu `argc=0`,
  `argv=0x00677084`; stdout das corridas deterministicas foi identico (53/53
  linhas, zero diferencas).
- Suite completa **303/303**. Fast relink OK, exe posterior a
  `libps2_runtime.a`, manifesto parcial somente com cabecalho.
- Nenhum `mc3-gfx-*` disparou. Os valores finais das globais `PARAM_skipintro` e
  `PARAM_garage` nao foram instrumentados; esta provada a entrega exata ao parser,
  nao o salto visual para garagem.
- Commit local do submodulo: `3367091`. Sem push.
- Evidencia completa:
  `docs/RESULT_BOOT_ARGS_SKIPINTRO_GARAGE_2026-08-29.md`.

## Checkpoint 2026-08-29 - boot args entregues ao crt0 retail

- O jogo tem atalho proprio: `datArgParser::Init` (retail `0x00428AC0`, batch_0036)
  sobreviveu no binario e le `PARAM_skipintro`, `PARAM_garage`, `PARAM_qload`,
  `PARAM_raceed`. O `main.cpp` so usava `argv[1]` como caminho do ELF; nada
  repassava argv extra ao guest.
- **Layout do bloco de boot args provado no disassembly** (`entry_0x1a0008.cpp`),
  conferido de forma independente. `0x614400` e um slot de ponteiro, nao o bloco:

  ```
  0x1a01b8: lui   $v0, 0x61
  0x1a01bc: addiu $v0, $v0, 0x4400    ; $v0 = 0x614400
  0x1a01c0: lw    $v1, 0x0($v0)       ; v1 = *(0x614400)
  0x1a01c4: beqz  $v1, fallback       ; zero -> bloco do ELF
  0x1a01cc: addiu $v0, $v1, 0x4       ; override: v0 = ptr + 4
  ...
  0x1a01d8: lui   $v0, 0x67
  0x1a01dc: addiu $v0, $v0, 0x7080    ; fallback = 0x677080
  0x1a01e0: lw    $a0, 0x0($v0)       ; a0 = argc
  0x1a01e8: addiu $a1, $v0, 0x4       ; a1 = argv
  ```

- Os dois caminhos **convergem no mesmo codigo** (`a0 = *(v0)`, `a1 = v0+4`), com
  `v0` normalizado como "ponteiro para argc". Por isso os blocos tem formatos
  diferentes: no fallback `0x677080` argc fica em `+0` e argv em `+4`; no override
  `+0` e o id de semaforo do loader, argc em `+4` e argv em `+8`.
- **Achado nao previsto:** `_start` toca `0x614400` logo na primeira instrucao
  (`0x1a0008: lui $v0, 0x61; addiu $v0, $v0, 0x4400`). Montar o bloco antes do
  entry e publicar o ponteiro nao funciona - o crt0 zera. A publicacao foi movida
  para o syscall retail `SetupThread` (`0x3C`), depois do clear de BSS e antes do
  crt0 consumir os argumentos. Isso nao estava em `RESULT_BOOT_ARGS_V1.md`.
- Implementado por Codex em `installCrt0BootArguments` com bound check,
  `translateAddress` protegido, rejeicao de argumento com `NUL` embutido e checagem
  de overflow. Lista vazia grava `0` no slot, preservando o caminho retail.
- Provas: `argc=3` (ELF, `-skipintro`, `-garage`) na entrada de `0x00428AC0`; sem
  argumentos `argc=0` com fallback `argv=0x00677084` e stdout identico (53/53
  linhas). Suite 303/303. Commits `3367091` (submodulo) e `add2e12` (externo).
- **Nao provado:** os valores finais de `PARAM_skipintro`/`PARAM_garage` e o salto
  visual para a garagem. Foi provada a entrega ao parser, nao o efeito.
- Detalhes: `docs/RESULT_BOOT_ARGS_SKIPINTRO_GARAGE_2026-08-29.md`.

## Checkpoint 2026-08-29 - corrida com -skipintro -garage diverge, mas nao avanca

- Argumentos entregues: `argc=3 argv=0x01ffff98` no trace. O mecanismo do crt0
  funciona de ponta a ponta.
- **Os argumentos mudam o comportamento**, mas a corrida trava MAIS CEDO que a
  corrida sem argumentos. Nao e avanco.

  | | sem args | com `-skipintro -garage` |
  |---|---|---|
  | PC final | `0x41D188` | `0x322FFC` |
  | Funcoes ausentes | 5 distintas | zero |
  | `gifPk1` | 348.988 | 348.558 |
  | `gsPrims` | 704.397 | 703.599 |
  | `gsPixels` | 257.216.311 | 256.036.663 |

- Os contadores da corrida com argumentos sao exatamente o plato do teardown da
  tela legal: ela para antes das transferencias VIF0 que a outra executa.
- `-skipintro` nao pulou a tela legal; `End=1` continua acontecendo.
- Trava em `0x322FFC`, o branch logo apos `jal func_3451E8` em
  `FUN_00322fd8_0x322fd8`. O tempo esta dentro de `0x3451E8`, que nas corridas
  anteriores retornava normalmente.
- **Nao provado:** que `PARAM_skipintro`/`PARAM_garage` ficaram verdadeiros (os
  valores finais nao foram lidos); que o jogo tentou entrar na garagem
  (`0x001A7150` nao esta instrumentado); que o travamento e causado pelo modo
  garagem. A divergencia e evidencia indireta de consumo pelo parser, nao prova
  das flags.
- Zero traces `mc3-gfx-*`. **Continua sem prova de modelo 3D de carro.**
- Proximos passos: ler os valores finais das globais `PARAM_*`; instrumentar
  `SetFrameModeGarage` (`0x001A7150`) e `SetFrameModeFrontend` (`0x001A71C8`);
  investigar `0x3451E8`; testar `-skipintro` e `-garage` isoladamente.
- Detalhes: `docs/RESULT_GARAGE_RUN_2026-08-29.md`.

## Checkpoint 2026-08-29 - 0x24A368 consertado; baseline anterior era artefato

- `0x24A368` nao era endereco no meio de bloco: e **prologo de funcao**
  (`nop` em `0x24a364`, `addiu $sp,$sp,-0x10` em `0x24a368`). O Ghidra fundiu duas
  funcoes na faixa `0x24a2a8-0x24a3e0`. Consertado com `case`+`label`, mesma
  classe do `0x5B92E0`; o `Generate-PartialRegister.ps1` emitiu o alias sozinho.
- **Efeito:** `recover-pc` do dispatcher caiu de **71 para zero**, e as cinco
  funcoes ausentes viraram zero — sem tocar nas outras quatro
  (`0x5BB170/78`, `0x5BB220`, `0x5BD030`), que so eram alcancaveis pelo caminho
  quebrado.
- **CORRECAO DE BASELINE:** `gifPk1=348988` / `gsPrims=704397`, registrados antes
  como plato de referencia, vinham de execucao com **71 chamadas de funcao
  puladas**. Nao sao baseline valido. O honesto e `gifPk1=348558` /
  `gsPrims=703599`, com execucao integra. Contador menor aqui significa MAIS
  correcao, nao menos progresso.
- Licao: nao caçar PC ausente isoladamente. Um conserto pode eliminar varios, e
  um "ausente" pode ser sintoma de caminho errado, nao de trabalho a fazer.
- `0x3451E8` **nao trava**: chega a `stage=0x003454c4` (fim da faixa) e retorna;
  apenas 4 chamadas na corrida. Cadeia `FUN_001a32b0 -> FUN_00322fd8 -> 0x3451E8`,
  que chama `uiGroup::SetActiveState` (`0x0041F550`). O `pc=0x322FFC` repetido e o
  quadro externo amostrado enquanto a thread guest esta parada mais abaixo.
- **Frente de boot args encerrada.** No ELF retail: `skipintro`/`PARAM_` = zero
  ocorrencias; as 71 de `garage` sao nomes de layer numa tabela de assets;
  `*(0x617F84)="cdrom0:\"` e constante compilada (nao vem de argv); o bloco
  fallback `0x677080` esta em BSS, logo `argc` e sempre 0 no retail. O mecanismo
  do Codex esta correto e sem regressao, mas nao ha uso retail para ele.
- **Regra:** o MC.MAP do alpha e fonte de pistas, nunca de fatos sobre o retail.
  Segunda vez que induz erro nesta semana.
- Primeira corrida com janela visivel: mesmo estado final, ~33 ticks/s (contra 55
  headless). `padmanStartPublishes=0` — o caminho de input segue nao exercitado.
- Detalhes: `docs/RESULT_24A368_DISPATCHER_TRUTH_2026-08-29.md`.

## Checkpoint 2026-08-29 - PRIMEIRA IMAGEM DO JOGO

- **A tela legal do Midnight Club 3 foi exportada em PNG a partir do
  recompilado**, com logo, kanji, texto legal e Dolby legiveis
  (`work/captures/frame_20260829_dump.png`). O motor grafico funciona ponta a
  ponta: GIF -> VIF -> GS -> rasterizador -> framebuffer. `gsPrims`/`gifPk*` nao
  eram trafego abstrato; sao a imagem correta.
- Obtido com `MC3_FRAME_DUMP`, facilidade que **ja existia** no runtime
  (`ps2_runtime.cpp:252`) e nao vinha sendo usada. Driver:
  `work/scratch/Run-FrameDump.ps1`.
- Os dumps por contexto (`_ctx0`/`_ctx1`) mostram o mesmo conteudo repetido ~4x
  na horizontal e entrelacado: stride errado na leitura por contexto. Defeito
  separado, nao afeta o frame de apresentacao.
- **Cinco funcoes ausentes consertadas**, `recover-pc` de 71 -> 0, zero PCs
  ausentes. `0x24A368` era prologo fundido pelo Ghidra; `0x5BB170`, `0x5BB178`,
  `0x5BB220` e `0x5BD030` sao acessores-folha de 2-3 instrucoes, decodificados do
  ELF e escritos a mao, com entradas em `functions_index.csv` e
  `boundary_port.csv`.
- **Input funciona.** Com janela visivel, `Enter` chega ao pad do guest
  (`buttons=0x00000840 start=1`), ate 11 publicacoes numa corrida. Com Start o
  jogo sai de `0x322FFC` e avanca ate `0x41D188`. Torna desnecessario o plano B
  do `setPadOverrideState`.
- **Apresentacao — em aberto.** O trace novo mostra a apresentacao recebendo
  conteudo (`nonZeroPx` de 0 ate 142.556 de 286.720), entao a hipotese de "buffer
  preto na origem" esta REFUTADA. Permanece sem explicacao: `displayFbp=0x0` em
  toda a corrida enquanto `dispfb1` do GS chega a `0x11000`. Nao esta
  estabelecido se a janela ainda fica preta no binario atual.
- **Cinco diagnosticos meus foram derrubados nesta sessao**, todos por tratar
  evidencia parcial como conclusao: `-O0` como gargalo, `-skipintro/-garage` como
  atalho, `gsPrims=704397` como baseline, a correcao desse baseline, e a
  apresentacao com buffer preto. Regras que ficam: o MC.MAP do alpha e pista e
  nunca fato sobre o retail; antes de afirmar causa, ir a fonte primaria; nao
  extrapolar de amostra de boot inicial.
- Detalhes: `docs/RESULT_FIRST_IMAGE_2026-08-29.md`.

## Checkpoint 2026-08-29 - camada rmc instrumentada; gargalo e o rasterizador

- **Observacao direta do usuario na janela** (dado que nenhum trace fornecia):
  a tela dá boot com quadradinhos verdes aparecendo, mostra a logo do jogo, e
  entao o fade-out fica parado muito tempo sem completar o fade-in nem entrar no
  menu. ~3 fps.
- Isso REFUTA o "bug de apresentacao" que eu vinha perseguindo: a janela mostra
  imagem. E reenquadra o travamento: **o fade nao esta travado, esta lento**. A
  transicao precisa de 490 iteracoes de script + 27 ciclos de fade; a 3 fps isso
  leva minutos. `End=1` de fato acontece (cinco vezes por corrida).
- **Sete pontos da camada `rmc*` instrumentados** (todos retail_addr exatos e
  registrados): `rmcModel::Draw` `0x2A9918`, `DrawCpv` `0x2A9A88`,
  `DrawSkinned` `0x2A9BC0`, `rmcCarModel::rmcCarModel` `0x2F6410`,
  `Init` `0x2F6C48`, `GetCar` `0x2F6BB0`, `vehModel::vehModel` `0x560E08`.
  Traces colocados apos o switch de resume, para nao contar reentrada de
  continuation.
- **A corrida do lote rmc nao respondeu a pergunta dele**: terminou com
  `padmanStartPublishes=0`, ou seja sem input, parada em `0x322FFC`. Zero traces
  era o resultado esperado nessa condicao e NAO testa se o jogo carrega carro.
  Repetir com Start pressionado.
- **Gargalo quantificado:** `gsPixels` / tempo ate `End=1` =
  **509.019 pixels/s**. Um rasterizador por software ingenuo em C++ faz 50-100M
  px/s, entao estamos ~196x abaixo. A carga do jogo e modesta: 1,8 overdraws de
  tela cheia por frame de guest. A ~522k pixels por frame isso da ~1 s por frame
  de guest, batendo com os 3 fps observados.
- Cadeia causal unificada: **rasterizador lento -> fade leva minutos -> nunca
  entra no menu -> nunca carrega carro**. Nao sao tres frentes, e uma.
- **Otimizacao aplicada** em `ps2_gs_rasterizer.cpp`: tres divisoes de ponto
  flutuante (`1.0f/fabsQ(v0.q)`, `v1.q`, `v2.q`) eram recalculadas POR PIXEL
  dentro dos lacos y/x, apesar de dependerem so dos vertices do triangulo.
  Hoistadas para o setup do triangulo, junto com os seis produtos `v.s*invQ` e
  `v.t*invQ`. De quatro divisoes por pixel para uma. Hoisting puro: mesma conta,
  mesmo resultado. Suite 303/303.
- Expectativa declarada antes de medir: isso NAO resolve os 196x. Tres divisoes
  a ~25 ciclos sao ~75 ciclos, e a 500k px/s gastamos ~6.000 ciclos por pixel.
  O valor do lote e calibrar a regua px/s para escolher o proximo alvo com
  numero. Suspeitos na fila: `sampleTexture` por pixel, `fetch_add` atomico por
  pixel em `writePixel`, e recalculo de endereco com swizzling a cada pixel.

## Checkpoint 2026-08-30 - diagnóstico saturado removido do hot path VIF1/VU1

- Subperfil interno de 3x300 s mostrou que os tempos publicados eram
  **inclusivos e sobrepostos**: VIF inclui callbacks VU e DIRECT/GS; VU inclui
  XGKICK/GS. Nao somar `vifUs + vu1Us` como fases exclusivas.
- VIF classificado: 80,9% MSCAL/MSCNT downstream, 16,6% DIRECT downstream,
  2,4% UNPACK e 0,1% controle. VU classificado: 42,0% helpers de diagnostico,
  41,8% XGKICK/downstream, 5,1% upper Q/I, 4,5% memoria e 4,1% math/EFU.
- Otimizacao semantica-neutra: copias/getenv/atomics/scans param apenas depois
  dos tetos de trace (VU 256/192/128; VIF/GIF 16/24). Os mesmos tetos completos
  apareceram nas tres corridas finais.
- Medianas 3x300 s: VU1 `186,24 -> 60,39 us/prim` (-67,6%, dispersao final
  3,1%); VIF1 `227,48 -> 92,66 us/prim` (-59,3%, dispersao final 1,7%). O
  efeito supera a dispersao anterior de 12,8%/12,6%.
- Suite completa `303/303`, build e fast relink verdes; exe posterior a lib e
  strings de instrumentacao confirmadas dentro do exe.
- Scheduler, rasterizador e os tres arquivos proibidos de logf/powf/expf nao
  foram tocados neste lote. Sem push.
- Commit local do submodulo: `27faf89` (`mc3`).
- Evidencia: `docs/RESULT_VIF1_VU1_PERF_2026-08-30.md` e logs
  `work/logs/measure_vif1_vu1_profile_r*.log.stderr` /
  `work/logs/measure_vif1_vu1_diag_gate_after_r*.log.stderr`.

## Checkpoint 2026-08-30 - BUG DO SQRT: operando lido de fs em vez de ft

- **Uma palavra errada no gerador quebrava todas as raizes quadradas do jogo.**
  `code_generator.cpp:2074` emitia `FPU_SQRT_S(ctx->f[fs])`; o R5900 poe o
  operando de `SQRT.S` em **ft**. A `RSQRT.S` da linha seguinte ja usava ft.
- **Prova empirica:** em 131 codificacoes distintas de `sqrt.s` no corpus,
  `fs = 0` em 100% delas e `ft` assume 18 valores. Se o operando fosse fs, o
  jogo tiraria raiz do mesmo registrador nas 585 ocorrencias.
- **Cadeia do congelamento**, cada elo com trace:
  `mcLight::GetColor` (`0x00259D60`) calculava `sqrt(dx)` em vez de
  `sqrt(dx²+dy²+dz²)`; com `dx` negativo isso da NaN -> `powf(NaN,1.0)` ->
  `logf(NaN)` -> serie de Taylor cuja saida e `soma == soma_anterior`, que pelo
  IEEE 754 nunca fecha com NaN -> **4.294.967.296 iteracoes** ate o contador
  estourar.
- **Isso explica o nao-determinismo desde agosto.** `dx = pos.x - luz.x` depende
  de onde a camera esta quando a luz e avaliada: as vezes positivo, as vezes
  negativo. Mesmo binario congelando em enderecos diferentes nunca foi ruido de
  medicao, como `STATUS_2026-08-07_AUDIT.md` concluiu na epoca. Era a raiz.
- Conserto: gerador corrigido + propagacao para arquivos ja gerados por
  `work/scratch/fix_sqrt_operand.py` (le a codificacao no comentario e reescreve
  o operando a partir dela). **221 arquivos, 323 instrucoes, 0 anomalias.** Nao
  se re-rodou `04_run_recomp.bat` para nao apagar a instrumentacao acumulada.
- **Efeito medido:**

  | | antes | depois |
  |---|---:|---:|
  | NaN em powf/logf | presente | nenhum |
  | `gsPrims` | 704.397 | **1.004.584** |
  | `gsPixels` | 257.216.311 | **1.088.137.517** |
  | `DrawSkinned` | nunca | **18 chamadas** |
  | PC estavel | `0x41D188` (logf) | `0x1D3990` |

- `0x1D3990` e `mcParticleFogMgr::DrawAllParticles` — particulas e nevoa, muito
  mais adiante. `rmcModel::DrawSkinned` (modelos com esqueleto) nunca havia sido
  alcancado.
- **Nao provado:** que o jogo alcanca o menu; efeito em performance (os ~3 fps
  tem outra causa ja medida); se outras instrucoes COP1 tem o mesmo problema de
  campo. O dump de frame saiu preto por gatilho cedo demais (700k primitivas,
  logo apos o teardown da tela legal) — nao e evidencia de cena preta.
- **Licao de metodo:** o bug foi achado instrumentando pelo SINTOMA ("avise em
  qualquer NaN"), nao seguindo a cadeia suposta. Horas foram gastas em
  `FUN_001FADC0 -> powf` (camera), que estava saudavel com 2.203 chamadas
  validas. Perseguir a corrida certa por sorte tambem custou 8 tentativas
  falhas; instrumentar pelo sintoma tornou a reproducao desnecessaria.
- Detalhes: `docs/RESULT_SQRT_OPERAND_BUG_2026-08-30.md`.

## Checkpoint 2026-09-05 - escritas frontend e limites VU1 (Astra)

- Revisado STATUS atual e progresso desde a sonda WaitSema: a inversao de locks ja estava
  corrigida; nao foi reaberta. Um investigador economico conferiu o caminho da animacao.
- O suposto ciclo `fe6AC 39 -> 0` nao aparece nas 887 amostras completas ordenadas do log
  longcook: zero regressoes, ultimo/maximo40. Corrigida essa conclusao no STATUS.
- Oito stores em quatro owners receberam sonda passiva. Compilados e relinkados; exe/lib
  identificados por SHA. Corrida901s: 34 eventos,16 Updates, clipe119, timer0.528, campo21,
  sem reinicio. Dump pontual preto; menu jogavel nao confirmado.
- Achado prioritario: VU1 atingiu orcamento65536 em15.852 chamadas (94,3% dos ciclos
  emulados). O log longo anterior ja continha30.169 (96,8%). Contagem corroborada em
  centenas de blocos completos. Capturar PC/E-bit antes de afirmar loop infinito.
- Controle quiet301s: somente construtor; insuficiente para medir ganho. Nenhum MC3
  permaneceu rodando. Resultado: `docs/RESULT_FRONTEND_WRITES_2026-09-05.md`.
- Ferramentas: `tools/Probe-FrontendWrites.ps1`, `tools/Analyze-FrontendBoot.ps1` e
  `tools/diagnostics/FRONTEND_WRITE_PROBE.md`. Nenhuma instrucao guest alterada, sem push.

## Checkpoint 2026-09-05 - VU1 FSAND corrigido (Astra)

- Captura limitada a8 casos identificou entrada0x30/FNV0a669b31 repetindo0x2820..0x2868.
  FSAND0x2c070002 escreviaVI1 em vez deVI7, apagando o contador do loop.
- Corrigido somente FSAND (destino, VI0 e imediato12). Testes novos falharam antes
  (311/313), passaram depois (313/313); loop reduzido encerra em10 ciclos, antes65536.
  Runtime compilado/relinkado e strings/mtime/hashes conferidos. Commit721a97b.
- Rodada corrigida901s:82 caps/89.339.312 ciclos, contra15.852 caps na corrida anterior901s.
  Animacao18 vs21 anteriormente: NAO ha ganho deFPS provado. Frame700k ectx0 pretos.
- Proximos8 caps sao outro codigo: entrada0x60/FNVa57d6e03, ITOP338, header0x1520
  final zerado. XTOP eXITOP atualmente leemITOP; callback nao entregaTOP e MSCAL
  nao faz latchTOP. Prioridade: capturarTOP/TOPS/ITOP/ITOPS/header na entrada e
  testar esse contrato antes de alterar o fluxo VIF1->VU1. Nao pular trabalhozero.
- Nenhum MC3 permaneceu rodando; sem push. Relatorio/reproducao/fontes/hashes em
  `docs/RESULT_VU1_BUDGET_2026-09-05.md`. Parser efixture emtools/Analyze-VuBudget.ps1
  e tools/Test-AnalyzeVuBudget.ps1. FSEQ/FSOR/FSSET nao alterados neste lote.

## Checkpoint 2026-09-05 - contrato VIF TOP/XTOP corrigido (Astra)

- Capturados oito inputs completos antes do VU. O header correto estava no bloco48
  (valor14), mas XTOP liaITOP338 e encontrava zero. Confirmado contra referencia
  primaria: ITOP escreveITOPS; kick fazITOP=ITOPS eTOP=TOPS antes de alternarDBF;
  OFFSET preservaBASE; XTOP eXITOP leem valores distintos.
- Runtime031f584 corrige o contrato, sem mudar layout/ABI, scheduler, instrucoes
  guest, GS ou orcamento. Quatro testes discriminantes falharam antes;316/316
  passaram depois. Mesmo snapshot:65536 ciclos/Ebit0/1974 pacotes antes,
  934 ciclos/Ebit1/28 pacotes depois. Oito replays encerraram; suite316/316 em cada.
- Runner relinkado, strings/mtime/SHA conferidos. Probevif_top_fixed_astra_20260905
  terminou por limite em901.5107757s,21:08:14. Zero caps em540 blocos completos,
  84.058.184 ciclos, animacao18,30 escritas/14 Updates, zero regressoes observadas.
  GS940.100 primitivas/416.127.888 pixels; CPU426.359375s. Todos os oito latches
  capturados pelo runner passaramTOPS anterior paraTOP, independentemente deITOP.
- Animacao18 igual a rodada anterior: NAO ha ganho deFPS provado. Imagens700k
  de apresentacao/contexto0 pretas. Nao demonstra que todos os frames sao pretos.
  Nenhum MC3 permaneceu rodando; sem push. Boot/menu continuam sem aceitacao.
- Proximo lote: probe comFrameDumpMinPrims900000 e rotulo novo, para observar
  uma imagem posterior; depois medir intervalos reais do frontend. Parametro
  implementado e validado sintaticamente/limites; essa rodada posterior ainda NAO
  foi executada. Relatorio:docs/RESULT_VIF_INPUTS_2026-09-05.md.

## Checkpoint 2026-09-06 - espera atribuida por dono (Astra)

- Runtime54a3c97 adiciona MC3_WAIT_PROFILE: waits iniciais/reaquisicoes, holds
  externos completos e intersecao com espera da principal tid1. Normal scheduler,
  instancia unica, opt-in; nenhum novo lock/decisao de escalonamento. Suite317/317.
- Primeira rodada caiu460,73s. WER PID6248 C0000005 RVA0b49e8e6, addr2line
  LiveGuestPcOf:1142; log mostra thread7 terminando. O diagnostico antigo lia um
  contexto sem proteger sua vida. Runtime478fb98 remove ponteirocru, copiaRA/SP
  atomicos na propria thread e usa ultimoPC de dispatch, com rotulos honestos.
- Repeticao wait_owner_safe_astra_20260905 completou901,67s,00:13:41, sem repetir
  a falha. Janela snapshots88->179 apos worker7exit: mainwait381,299654s,
  overlaprede8=352,673244s (92,5%), dados5=27,944445s, outros0,479710s.
  E atribuicao da ESPERA PELO TOKEN, nao de todo tempo/CPU, nem causa interna.
- Zero caps em658 registros, animacao21,34 escritas/16 Updates; GS964321prims.
  Imagem900k quasepreta com marcas fracas; contexto0preto, contexto1semcaptura.
  Menu/ganhoFPS nao aceitos. NenhumMC3 ficou rodando. Sem push.
- Ferramentas Probe-FrontendWrites -TraceWait, Analyze-WaitProfile e testes
  sinteticos passaram. Proximo: controle quiet e callback1f9608 (vtable+0x7c),
  separando CPU/hold/espera sem mudar scheduler ou funcoes matematicas congeladas.
  Evidencias/hashes/limites:docs/RESULT_WAIT_OWNERS_2026-09-05.md.
