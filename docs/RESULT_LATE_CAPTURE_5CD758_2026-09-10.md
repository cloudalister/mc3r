# 10/09 06:53 - second missing leaf and bounded presented captures

## Live update07:15

PID51672 active.14intact5cd758markers,highestcompletedcall4096; no observed
unimplementederrors. This validates reaching/executing recoveredaccessor
without its previousmissing-handler stop.5e89f8 remainsunobserved, no claim.
Independent economical audit: all14intactmarkers haveRA004ff924 and
v0==(a0+0xec) modulo32, confirming returncontract in actual execution.
PNG4elapsed960032ms/2.107778Mprims andPNG5elapsed1260036ms/3.994037Mprims
inspected: darkscene/lightpoints/smokelikefloor with geometrywarping, then
horizontalwhite/cyanbands. Scene advancedbeyondlegal, matchingmanualtype
corruption. Not identified asmainmenu/profile, not acceptedgraphics.
Wait final2100s/result andPNG6 before next experiment orsiteprogress update.

## Evidence and decision

Quiet control entry_5e89f8_quiet_20260910_0555 ended06:22:12,1702.443s,
CPU1157.125s, exitedBeforeLimit=true, actual exitCode0. Seven final
Called unimplemented function errors at5cd758,RA4ff924, then thread cleanup
and Window closed successfully. Default missing handler calls requestStop.
This is an internal stop path, not evidence of Windows crash or click cause.
No5e89f8 marker: that earlier leaf is still not runtime-validated.

TraceON pulse control timed out1800s without that error. Trace setting can
affect observed coverage/timing; no FPS improvement quantified, no visual
progress can be inferred from this quiet run (old dump gate was trace-only).

## Exact recovered accessor

ELF PT_LOAD off80/VA1a0000 maps5cd758 to file42d7d8:

    5cd758 03e00008 jr ra
    5cd75c 248200ec addiu v0,a0,0xec [delay slot]

Subagent initially decoded source as v0; principal independently decoded
rs=(word>>21)&31=4 (a0),rt=2. Correct implementation uses a0, not old v0.
Prior owner returns at5cd74c/delay5cd750;5cd754padding; this is separate leaf.
Caller4ff91c jalr v0 returns4ff924, adds24 to returned pointer before4fee30.
No claim that accessor fixes geometry; its absence invokes runtime stop.

Owner FUN_005cd738 has separate case/label5cd758 with exactADD32/SET_GPR_S32
semantics, signed32 result inlow64 preservingupper64, branch/delay return.
No RAM access or invented fallback. Registry gets exactentry inpartial and
generatedregister; future generator scansowner case and preserves it.
Optional MC3_ENTRY_COPY_TRACE logs first4/powers2 successful calls of both
recovered leaves. Verify-Entry5e89f8 now also guards5cd758 ELF/rs/rt/boundary.
Seven actual-owner tests PASS: distincta0/v0, sign boundary, wrapping,
upper64/otherGPRpreservation and return. Firsttestcompile failed because
existing GPR_U64 macro requires parenthesized &c; fixed test, not macro.

## Presented capture (diagnostic only)

MC3_PRESENT_CAPTURE_PREFIX absent/empty = disabled. Hook in UploadFrame after
successful copyLatchedHostPresentationFrame, using same scratch dimensions
and FBs as texture upload. No extra latch, GS copy, contextFB, guest change,
or ABI fields. Onhostthread, steadyclock60s then300s between attempts,max6.
Late frames never cause catch-up burst; failed/existing-file attempts consume
slot; existing PNG never overwritten. RGBA buffer/dimensions checked.
Standalone scheduler/bounds tests PASS; runtime328/328OFF and328/328ON PASS.
Build-LateCapture succeeded; Relink-Entry verifies markers/objects/libmtime.
Bootstrap helper and capture gate are not claimed to improve game execution.

Backup before edits: work/patches/legal_phase_baseline_20260910_064330.
Includes prior exe/lib/diffs; explicit5cd738source/object/registries copied.
New header/source under nestedPS2Recomp; preserve untracked header explicitly.

## Active run

recovered_leaves_capture_20260910_0651 actually began06:50:22,
PID51672/session81214,2100s expected end07:25:22. HEADLESS1,BOOT_TRACE0,
GS_IRQ_BRIDGE1,ENTRY_COPY_TRACE1,CapturePresented,Start30s/30s/delay45s.
Exe5f66cb623b7efc3d2e1ba7c64cba20b367641af1cee385b881d68b36fbacb0d4;
lib1fd5e0ac904f58cdcc17e2d1b1426a72c366756c7474363c986af8f3a995552f.
Firstcapture n1elapsed60009ms,231795prims,512x448,FB0/0,ok1.
Inspected: legible MC3/legal notice. Capture works withoutBOOT_TRACE;
not a new visual milestone, not geometry fixed. Remaining run pending.

## Atlas

Source479ca151269db10541b8fbd318c89bcc734e5ab1,version5 saved.
Owner-only policy reverified. Content distinguishes source/tests from gameplay;
catalog counts unchanged. Existing npm run build and catalogue check PASS.
Supplied mjs wrappers fail local npm/bash resolution; underlying provided
packager with MSYS PATH succeeded, no plugin/dependency modifications.
Private deployment SUCCEEDED06:53:17,appgdep_6aa27df2153c8191bd7e356ba6ce0111.
No browser reopening because this is background work while Cloud sleeps.
