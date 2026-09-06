# Verified missing leaf 2300d0 — 2026-09-06

## Scope and evidence

Prior `main_wait_astra_20260906` first recovery:2300d0,RA24aa94.
ELF32 program-header mapping confirms03e00008/00000000 (`jr ra; nop`) at2300d0.
Catalog ends previous function at2300d0 and starts next at2300d8; no2300d0
registration existed. This is an omitted function entry, not an unknown body
for which a generic return stub would be appropriate.

## Change

`runtime/mc3_verified_leaf.h` implements only this verified entry's return.
No register, memory, result or stack modifications. Branch metadata matches the
existing generated jr implementation. Normal next-function entry remains intact.

Ignored generated owner `work/generated/ghidra/FUN_002300d8_0x2300d8.cpp` now:

1. Includes `runtime/mc3_verified_leaf.h` after `ps2_runtime.h`.
2. Adds `case 0x2300d0u: goto label_2300d0;` to its entry switch.
3. After final `ctx->pc = 0x2300F4u;`, adds:

```cpp
    return;
label_2300d0:
    mc3VerifiedLeaf2300d0(ctx);
    return;
```

The leading return preserves the old fallthrough ending for other paths.
`tools/Compile-VerifiedLeaf.ps1` validates actual ELF bytes before always compiling
batch0009/obj/FUN_002300d8_0x2300d8.o. Refuses wrong/missing bytes or missing hooks.
The compile manifest source hash was updated to
4010348649507b2f3a4603c42de122a3a0828ada8c74fd45981dd133cedc89a6.
Header changes require this compile tool; the source manifest alone misses them.

Ran Generate-PartialRegister.js (the current batch launcher uses JS, not the older
PowerShell generator). New register line53449 maps2300d0 to the compiled owner;
aliases manifest records the same binding.15831 top-level registrations,
168385 internal aliases,zero missing object stubs. These counts are NOT gameplay
coverage. Then absolute fast link uses the freshly regenerated registration.

## Validation

New runtime test verifies return PC, preserved GPR/FPU/SP/RA, branch metadata and
completed delay slot. Build completed and320/320 tests passed. An earlier test
launch raced the still-running test linker and was rejected as file in use;
it was not counted as a test result. Retried only after build exit0.

## Remaining entries (read-only investigation)

Other recovery targets were NOT patched. Main-agent ELF32 byte verification
corrects the initial investigator's decoding (addresses below are guest VAs):

| Entry | Words | Semantics |
|---|---|---|
| 5b94f0 | 03e00008 00000000 | jr ra; nop |
| 5b94f8 | 03e00008 00000000 | jr ra; nop; NOT a prologue |
| 5b9500 | 27bdffe0 3c020062 | next prologue starts HERE |
| 5b9990 | 03e00008 00000000 | jr ra; nop |
| 5b9998 | 03e00008 00000000 | jr ra; nop |
| 5c3a48 | 03e00008 0000102d | jr ra; daddu v0,zero,zero IN DELAY SLOT |

The last entry returns ZERO; it is NOT a no-op. Fallback-to-RA omits this result
write, so it is a concrete semantic discrepancy to investigate next (not yet
proof of boot causality). Do not implement it using the unchanged-register helper.
Static references also verified:623fc8 contains5b94f8;6241ec/6241f0 contain
5b9990/5b9998. They are referenced table entries, not just an opcode pattern.
Remaining table ownership/call context and faithfully registering these entries
are the next bounded lot; no blanket aliases or generic return stubs.

The old fallback-to-RA already resembles the empty2300d0 function's behavior.
Do not claim fixing this one entry should speed up boot or cure downstream jumps.
The gain sought here is faithful registration and an auditable first remaining
failure, not FPS.

Relink succeeded03:11:11, newer than owner03:09:04 and registry object03:10:20.
objdump confirms the owner tests2300d0 and branches to the return implementation.
Probe `verified_leaf_astra_20260906`,600s, started03:11:40, same quiet/wait/callback
settings as previous run. Exe SHA256
`ce8992858a964cb5513a11efdd570cb14b545ebf1809d714b99dc28f8eede32e`;
runtime lib unchanged SHA256
`4856b5bed701479ef029dbc9f78392cacf983fd422d9987f8161eb6dfdd3a0be`.
No competing builds/tests during the probe.

## Completed followup

Ended03:21:42 by harness after601.002s, no early exit. CPU304.516s,
user213.25s,kernel91.266s. No MC3 remains running.320/320 tests passed earlier.
22 complete FE writes,10 animation updates,last12->13,timer0.330. Previous
main-wait probe had9 updates,last11; single runs with different scheduling and
unfinished boot do NOT establish a speedup. No image expected in quiet mode.

No `bad=0x2300d0` record in the completed log. First bad target is now5b9990,
RA24aa6c,v1=6241e0 (its table+0xc is the static6241ec reference verified above).
First recoveries:5b9990,5b9998,5b94f0,5b94f8,42bf00.256 recovery-containing
lines still reach the diagnostic cap; NOT a count of all recovery executions.
The first-missing-entry repair is supported by exact ELF bytes, unit test,
compiled owner disassembly, generated registration and changed first-failure
record. Absence of a diagnostic alone is not a call-hit counter.

Next recommended lot: exact implementations/registrations for verified remaining
leaf entries, prioritizing5c3a48's zero-return delay slot. Preserve actual R5900
register-width semantics, not merely set a host return value. Audit additional
targets independently, especially42bf00, and repeat with first-bad/FE evidence.
Do not accept menu/gameplay while the runner silently recovers missing targets.
