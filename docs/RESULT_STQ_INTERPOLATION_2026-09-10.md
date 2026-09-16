# STQ perspective diagnostic - 10/09/2026 07:57

## Final result — audited 08:58

Run stq_correct_capture_20260910_0756 completed at 08:31:22.721 by harness
timeout: wall 2103.3388474 s, CPU 1533.75 s, exitedBeforeLimit=false,
exitCode=null. Not a spontaneous crash or natural exit.
16 intact 5cd758 markers through 16384; no 5e89f8 marker observed.
24 STQ varying-Q markers through 4194304; no unimplemented error observed.
All six presented captures succeeded. PNG6 at elapsedMs=1560052,
prims=6204807 still shows damaged scene and white/cyan horizontal bands.
Conclusion: corrected texture contract is exercised but does not resolve
the overall visual defect. Keep gate default OFF; do not claim FPS gains,
usable menu, profile creation, or gameplay. Prior Live sections are historical.


## Live08:19

RunactivePID18688.23variableQmarkers,highest2097152, proves correctedpath
is exercised on varyingQ;5cd758through4096/no unimplementedobserved.
PNG4/5 inspected. Some appearance changes, buthorizontalwhite/cyanbands
and damagedscene remain. PNG5has3,994,037prims, samecounter aspriorOFFPNG5;
this is a useful matchingmilestone, not proofidenticalentiregueststate.
Do not claim geometryfixed orquantifyFPS. Await finalrun/PNG6.

## Completed prior run

recovered_leaves_capture_20260910_0651 stopped by2100s harness at07:25:25,
wall2103.279s,CPU1513.15625s, no naturalclose or unimplementederrors.
5cd758 markers through16384; previous audit verifieda0+ec/RA4ff924.
5e89f8 not observed. Six displayed captures succeeded; PNG4-6 show later
scene with stretched shapes and white/cyanbands. PNG6 at1560045ms,6.210305M
prims still malformed. This is not a confirmed usablemenu or gameplay.

## Specific bug and primary contract

GS triangle path calculated weighted S/Q and1/Q, reconstructed a pair then
sampleTexture divided again. The reconstruction cancels; final texture
coordinate is affine weighted(S/Q), not weighted(S)/weighted(Q).

Primary reference consulted10/09, no code imported:
- [PCSX2 vertex shader](https://raw.githubusercontent.com/PCSX2/pcsx2/master/bin/resources/shaders/opengl/tfx_vgs.glsl): positions usew1 and ST/Q are separate interpolants (load_vertex157-179).
- [PCSX2 fragment shader](https://raw.githubusercontent.com/PCSX2/pcsx2/master/bin/resources/shaders/opengl/tfx_fs.glsl): ps_color817-826 divides interpolatedST by interpolatedQ whenFST0.

Subagent initially regarded affine(S/Q) as correct generic perspective;
principal resolved against actualGS contract above. Another candidate was
XYOFFSET fractional truncation, but that does not explain largebands by itself;
no XYOFFSET changes made. VertexXYZ decode/assembly had no provenbug in audit.

## Discriminating public-GS test

Triangle(0,0),(4,0),(0,4),S=(0,2,0),Q=(1,2,4); pixelcenter(1.5,1.5)
hasweights(.25,.375,.375). CorrectS=.75,Q=2.5,texturewidth8 =>u2.4,texel2.
Old affineS/Q givesu3,texel3. Reversewinding same. Controls Qall1→texel6,
Qall2→texel3. ActualGS registers/VRAM output used, not math-only helper.

Initial fixture wrote8palette entries linearly, which is wrong forCLUT;
all four checks failed, so preliminary328/329 WAS NOT sufficientbugproof.
Fixedfixture uses existing independentwriteReferencePSMCT32Pixel layout.
The assertions/expectedtextureindices were not weakened to match output.

Valid same testbinary proof:
-075541, fixOFF + RequireCorrectStq:328/329, only STQcontract case fails.
  pixels33,33,66,33 (lowcolorbyte); bothconstantQ controls match.
-075545, fixOFF + historicalexpectation:329/329,legacybehaviorpreserved.
-075550, fixON + RequireCorrectStq:329/329,pixels22,22,66,33.
Logs work/logs/net_callback_tests_20260910_<time>.stdout/.stderr.

## Small experimental change

MC3_GS_STQ_INTERPOLATION=1 enables linearinterpolation ofS,T,Q before the
existing texture sampler division, only triangle STQ path. DefaultOFF.
FST, sprite/linepaths, geometryposition, scheduler, budgets, alpha and saves
unchanged. Legacybranch preserved. Sparse mc3-stq-variable-q marker reports
first4/powers2 triangles actually usingvaryingQ underenabledgate.
No gamevisual improvement claimed before observing newcapturesequence.

## Disk safety / backup relocation

Preserve-LegalPhase074832 failed before exe copy due lack ofE space;
that directory is an INCOMPLETE backup, not rollbackbaseline.
Moved only two own064330backup files to:
<scratch-dir>/mc3recomp-backups-20260910_0750/
-baseline064330_mc3_partial.exe SHA15b7251765cc562fe194d942a01db272397367b22209317e37cca8497d174c37
-baseline064330_libps2_runtime.a SHAa21022d6fd98ab73480dd70851ffa949fd83431ef3a5ee66eacdf6cb7671527f
Hashes aftermove matchknownbefore. RecoverableatC; no saves or gameassets removed.
Also copied CURRENT preSTQexe/lib,rasterizer,testsource,captureheader and
runtime-before-stq.patch into sameCdirectory. Those currentfiles use original
basenames and hashes5f66cb.../1fd5e0... frompreviouscheckpoint.

## Validation run active

Relink66492 completed0, then marker/timestamp/hashverificationPASS.
Testsfailed during initialfixture development, but no game ran until fixed
fixture and ON/OFF validation completed. Test-only lateredit needs no gamerelink.
Exe f76cd5f0ecbd4af7b4f2dc7a441b75d1049d3f29f358d0dcb871a5f4041a0f57;
lib0377ebdf5b1788e2d9f5d04e563ca78062f3cc8d21414b7b187affe7769b7d7b.
Run stq_correct_capture_20260910_0756,2100s,session15082,quietheadless,
GSbridge1,STQ1,leaftrace1,sixpresentedcaptures,Start30/30s-delay45s.
Expected endaround08:31. Compare actualscene/coverage, not exactwallframe/FPS;
priorOFFcapture usespreviousbinary with mathematicallyidenticallegacybranch.
SamebinaryOFFrepeat only iftime/evidence justify; harddeadline09:30.
