# US-006 - Controlled provider probe matrix

Verified: 2026-08-02 00:07 BRT

## Intent

Compare the existing default `595` probe with the previously validated `req4`
mode without treating a mode-specific SIF response as a provider fix. Provider
telemetry used the existing `MC3_TRACE_PROVIDER=1` gate; no runtime code or
experiment definition changed.

## Matrix

| Mode | Run window (BRT) | Classification | Stable PC | Provider observations |
|---|---|---|---|---|
| `595` | `00:06:12`-`00:06:20` | `render-started` | `0x5A8908` in `sub_005A8898_0x5a8898` | slots `0x618020/0x618024` both held `0x617F88`; flag `0x619F40=0`; fallback `0x619F4C` changed `0x00000000 -> 0x00715D90`; `0x4F9760` was not reached, so primary `0x619F44` is not claimed |
| `req4` | `00:06:24`-`00:06:33` | `render-started` | `0x2455F0` in `sub_00245568_0x245568` | slots `0x618020/0x618024` both held `0x617F88`; flag `0x619F40=0`; fallback changed `0x00000000 -> 0x00715D90 -> 0x00715DC0`; `0x4F9760` was not reached, so primary `0x619F44` is not claimed |

Both modes retained `dma=2 gif=0 gsw=0 vif=3` and the last observed wait
`tid=3 sid=5 count=0 waiters=0 pc=0x5469E0 ra=0x398B28`.

## Preserved evidence

- Default driver log: `work/logs/15_auto_boot_probe_20260802_000612.log`
- Default trace: `work/boot_probe/boot_trace_pollsid59c595_20260802_000620.log`
- Req4 driver log: `work/logs/15_auto_boot_probe_20260802_000624.log`
- Req4 trace: `work/boot_probe/boot_trace_pollsid59c595ret2mode9payload1m3skip5areq4_20260802_000632.log`
- Final gate-off regression driver log: `work/logs/15_auto_boot_probe_20260802_000656.log`
- Final gate-off regression trace: `work/boot_probe/boot_trace_pollsid59c595_20260802_000704.log`

## Interpretation and negative case

Req4 changes Stable PC, but it does not establish a primary provider: the
trace never reaches `0x4F9760`, `0x619F40` remains zero, and both selected
backend slots remain `0x617F88`. It also enables a chain of unrelated existing
experiments (`ret2`, mode 9, payload 1, m3, skip5a, request-595 completion, and
request-4 status injection). Therefore `req4` is retained only as a comparison
mode and is not promoted as a provider fix.

The final gate-off `595` run remained `render-started` at Stable PC `0x5A8908`
and contained no `[MC3_PROVIDER]` lines. No direct write to `0x619F44`, fake
handle, semaphore injection, or permanent compatibility patch was added.

## Reproduction

```powershell
$env:MC3_TRACE_PROVIDER='1'; .\15_auto_boot_probe.bat 8 595
$env:MC3_TRACE_PROVIDER='1'; .\15_auto_boot_probe.bat 8 req4
Remove-Item Env:MC3_TRACE_PROVIDER -ErrorAction SilentlyContinue; .\15_auto_boot_probe.bat 8 595
rg -n "\[MC3_PROVIDER\]|mc3-iop-response-experiment|WaitSema:block" work/boot_probe/boot_trace_pollsid59c595_20260802_000620.log work/boot_probe/boot_trace_pollsid59c595ret2mode9payload1m3skip5areq4_20260802_000632.log
```
