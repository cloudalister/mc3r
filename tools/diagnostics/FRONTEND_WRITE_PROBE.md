# Passive frontend writer probe

The neutral helper `mc3_fe_write_probe.h` observes stores to retail `mc3FeView+0x6AC`.
It does not set the field, return early, alter registers, or modify scheduling.
`MC3_FE_WRITE_TRACE=1` enables at most 512 complete stderr records per process.

The four local generated owners include the helper after `ps2_runtime.h`, using
`../../../tools/diagnostics/mc3_fe_write_probe.h`. Immediately before each original
store they call `mc3TraceFeWrite(rdram, ctx, objectRegister, valueRegister, storePC)`.
The original store remains intact. Generated game code remains local and ignored.

| Owner | Store PC | Object GPR | Value GPR |
|---|---|---:|---:|
| sub_00321220_0x321220 | 0x321390 | 22 | 0 |
| sub_003223A0_0x3223a0 | 0x322428 | 16 | 0 |
| sub_00322668_0x322668 | 0x3226d8 | 17 | 2 |
| sub_00322668_0x322668 | 0x322ca4 | 17 | 3 |
| sub_00322668_0x322668 | 0x322dd0 | 17 | 4 |
| sub_00322668_0x322668 | 0x322de8 | 17 | 3 |
| sub_00322668_0x322668 | 0x322e94 | 17 | 2 |
| sub_00322ED0_0x322ed0 | 0x322fb0 | 16 | 4 |

The record includes object identity, old/new signed values, clip slot and pointer,
clip length (`u16 clip+4`), flags +0x38/+0x49/+0x4A, globals 0x617988 and 0x617990,
f20, PC, and RA. These are pre-store snapshots. Constructor fields may still contain
allocator fill; that is not evidence of corruption. Slot values outside 0..10 are
reported without dereferencing the table.

## Build and run

All four objects belong to `work/compile/ghidra/batch_0021/obj`. Compile using the
same flags as `tools/parallel_compile.py` (`-O2 -fno-strict-aliasing -msse4.1`), then
relink through the absolute `10_link_partial_runner.bat fast` entry point. Confirm
`[mc3-fe-write]` in the executable and exe newer than lib before running.

The source hash manifest was updated for the four successfully compiled owners.
The manifest does not hash included headers: **recompile all four owners whenever
the helper changes**, and relink. Regenerating the corpus removes these local calls;
the site table above is the installation/rollback inventory.

Run from a separate PowerShell process:

```powershell
rtk proxy powershell -NoProfile -ExecutionPolicy Bypass -File tools/Probe-FrontendWrites.ps1 -Seconds 900 -Label unique_label
```

The runner records binary hashes and explicit MC3 settings, protects existing logs,
refuses a competing MC3 process, and closes only its own headless process. It uses
the standard scheduler; STATUS.md supersedes the old deterministic requirement in
WORKFLOW.md. It attempts a framebuffer dump at 700,000 primitives.

`-QuietBootTrace` disables the general boot trace while keeping writer events enabled.
The framebuffer dump and frame counters depend on the general trace and are absent in
this mode. The runner stores a `.result.json` with elapsed wall time and aggregate
process CPU/user/kernel times. Missing counters must never be interpreted as zero.

`tools/Analyze-FrontendBoot.ps1 -LogPath <closed-log>` reads existing evidence without
launching the game. It reports ordered complete samples, regressions, writer PCs, and
VU1 budget counters. Use a closed log; it does not request shared access to live writers.

## Limits

This watches the eight identified field stores, not every possible aliasing write
in guest memory. A missing event is not proof that no unknown writer exists.
A phase/profile total is not an exclusive wall-clock frame cost. This experiment
does not establish a performance improvement or visual gameplay acceptance.
