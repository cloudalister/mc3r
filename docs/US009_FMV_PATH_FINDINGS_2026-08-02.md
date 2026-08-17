# US-009 — FMV path findings

Timestamp: `2026-08-02 00:23:10 BRT` (`America/Sao_Paulo`)

## Result

The two addresses are callbacks for separate SIF package requests. The available static and trace evidence does **not** identify either callback as an FMV player or video-decision function.

| Callback | Request builder | `sub_00549488` arguments | Observed envelope | Callback behavior |
| --- | --- | --- | --- | --- |
| `0x541348` | `sub_005424A8`, callback loaded at `0x542520`, submitted at `0x542534` | queue `0x620D50`, request `5`, mode `1`, payload `0x61FC80`, size `4`, callback `0x541348` | command `0x8000000A`, request `5`, size `4` | Copies the reply word to `0x61FBD8` and `0x61FBDC`; reply `11` clears `0x61FBD8` and latch `0x61FBB4`; otherwise it signals `0x61FBA8` when needed and clears the pending/latch state. |
| `0x5413F0` | `FUN_005422c8`, callback loaded at `0x54242C`, submitted at `0x542440` | queue `0x620D50`, request `1`, mode `1`, caller payload, size `24`, callback `0x5413F0` | command `0x8000000A`, request `1`, size `24` | Parses two counted byte regions from the reply through the uncached `0x20000000` alias, mirrors them into two destinations, then tail-calls `0x541348` with `0x61FBD8`; it is package-response handling, not a proven decoder/player. |

`sub_00549488_0x549488` stores the request, mode, payload, size and callback in its queue node and submits a 64-byte command through `sub_00548A00`. This establishes package-request ownership without assigning media semantics.

## Order relative to `0x5A8908`

The callbacks/requests are on a boot-initialization path that appears **before** the stable `0x5A8908` loop:

- The generated builders submit `0x5413F0` or `0x541348` through `sub_00549488` before returning to their callers.
- Existing traces record the callback-bearing queue submission and SIF command before later runs settle at the provider loop.
- In the default `595` probe, the final stable state is `0x5A8908` in `sub_005A8898`; once stable, dispatch windows contain only `0x5A8908`.
- Therefore the observed callback-bearing package traffic is earlier initialization traffic, not activity after entry into the stable loop. This is an ordering result, not proof that either request is FMV-related.

Trace examples:

- `work/boot_probe/boot_trace_pollsid5422c8pass_20260708_010711.log:359-360`: request `1`, callback `0x5413F0`.
- `work/boot_probe/boot_trace_pollsid59c595ret2mode9payload1m3skip5areq4ret2ret1a8_20260801_201711.log:577`: request `5`, callback `0x541348`, with exact `sub_00549488` arguments.
- `work/boot_probe/boot_trace_pollsid59c595_20260802_000704.log:502-549`: stable `0x5A8908`, followed by single-PC dispatch windows.

The callback-specific traces above include existing compatibility experiments. They prove the queue/request/callback relationship and relative execution order, but they do not prove original IOP reply contents, media playback, or gameplay equivalence.

## Unknowns and negative finding

- No concrete FMV player, decoder loop, filename/package identifier, or “play versus skip” decision function was identified.
- Request IDs `1` and `5` are known, but their package-level semantic names remain unknown.
- The exact original IOP reply payloads still require a clean PCSX2 capture or equivalent evidence.
- No evidence connects either callback to a loose `.pss`, `.str`, `.mpg`, or `.bik` asset.
- `MC3_SKIP_VIDEO` is not justified and was not added. No runtime or generated source was changed.
- Hashes, counters and logs do not establish visual gameplay acceptance; none is claimed.

## Commands used

```powershell
rg --files work/generated/ghidra | rg -i '541348|5413f0|5412|5413|542578|546d|5489'
rg -n --glob '*.cpp' '0x541348|0x5413f0|541348|5413f0' work/generated/ghidra
rg -n --glob '*.cpp' '13f0.*addiu|1348.*addiu|addiu.*0x13F0|addiu.*0x1348' work/generated/ghidra
rg -n 'func_549488|addiu.*0x1348|addiu.*0x13F0|620d50' work/generated/ghidra/FUN_005422c8_0x5422c8.cpp work/generated/ghidra/sub_005424A8_0x5424a8.cpp
rg -l '0x5413f0|0x541348' work/boot_probe work/logs
rg -n '0x5413f0|0x541348|pc=0x5a8908|Stable PC|MC3_TRACE_SIF_REQUEST' <selected trace logs>
```

No new headless probe was needed: existing source plus preserved traces directly cover both request mappings and the required ordering check, while a fresh default probe would not add callback telemetry without modifying instrumentation or using compatibility gates.

## Ralph handoff

US-009 findings are complete in this report. `.ralph/progress.md` and `.ralph/activity.log` were intentionally not edited because this story's explicit allowed paths are only `work/generated/ghidra` and `docs`. US-010 can consume this report when its `.ralph` path becomes allowed.
