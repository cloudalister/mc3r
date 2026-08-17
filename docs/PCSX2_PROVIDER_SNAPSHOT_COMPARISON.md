# US-007 - PCSX2 provider snapshot comparison

## Scope and evidence boundary

This comparison uses the preserved live PCSX2 snapshot in
`docs/SESSION_2026-07-10_PCXS2_MCP_SID44.md`, the native runner provider trace
in
`work/boot_probe/boot_trace_pollsid59c595ret2mode9payload1m3skip5a_20260710_111442.log`,
and the current controlled matrix in `docs/PROVIDER_TRACE_MATRIX.md`.

The PCSX2 session paused at guest PC `0x4F9760` while opening
`fonts/mcloadstrings.strtbl`. The DebugServer disconnected before a complete
return trace, so the snapshot proves live state at that pause, not the open
result or gameplay equivalence.

## Matching provider and backend points

| Point | Existing PCSX2 snapshot | Native runner evidence | Comparison |
|---|---|---|---|
| Caller/dispatcher | PC `0x4F9760`, called by `0x3991F0` | `0x3991F0` dispatches method `0x4F9760` | Exact control-flow match |
| Selected provider slot | `0x618020` | `provider_slot=0x618020` | Exact slot match |
| Provider/table pointer | `0x619F58` | `provider=0x619F58` | Exact pointer match |
| Provider method `+0x00` | `0x4F9760` | `method=0x4F9760` | Exact method match |
| Low-level backend table | `0x617FC0`: open `0x3984C0`, close `0x398610`, read `0x3986D8`, seek `0x398730`, stat `0x398788`, extra `0x3987E0` | Same six addresses in the runner trace | Exact backend registration match |
| Primary package state | PCSX2 live global `0x629F44=0x5C0C40` | Current `595`/`req4` traces do not reach `0x4F9760`, so they do not claim a primary value | Not comparable yet |
| Fallback package state | PCSX2 live global `0x629F4C=0x41F9B0` | Current `595`: effective fallback `0x619F4C` becomes `0x715D90`; `req4` becomes `0x715D90`, then `0x715DC0` | Both are non-null after setup, but node contents and validity are unproven |
| Open outcome | Not captured before `ECONNRESET` | Older runner trace repeatedly returns `0xFFFFFFFF` for `texture.zip` and texture paths | No outcome equivalence can be claimed |

The `0x629Fxx` labels above preserve the PCSX2 session's guest-global notation.
The generated runner trace names the effective decoded globals as `0x619Fxx`,
as documented in `docs/PROVIDER_ENTRY_TRACE.md`. Pointer values such as
`0x619F58` and slot `0x618020` are unchanged and directly comparable.

## Result

The provider selection and registered low-level backend are already aligned:
both environments can reach `0x618020 -> 0x619F58 -> 0x4F9760`, and both expose
the same six `0x617FC0` backend functions. The evidenced difference is further
inside package state: PCSX2 has a non-null primary (`0x5C0C40`) and fallback
(`0x41F9B0`) at the live pause, while the controlled native matrix only proves
fallback allocation and never reaches `0x4F9760` to capture the primary.

This narrows the next investigation to package-provider population/content,
not backend registration. It does not justify writing a provider pointer,
fabricating a handle, signaling a semaphore, or applying a compatibility
patch.

## Negative case

File timestamps and hashes can prove which executable, log, or snapshot was
used. They cannot prove equal guest memory, equal open results, rendered
frames, title-screen arrival, or gameplay equivalence. Likewise, matching
addresses alone prove structural alignment only; the PCSX2 open return and the
contents of its provider nodes were not captured.

## Values still requiring live PCSX2 capture

- `*(uint32_t*)0x618020` immediately before and after the first package open,
  plus `*(uint32_t*)0x618024` on any path that selects it.
- Primary and fallback globals immediately before and after `0x4F9760`, using
  both the PCSX2 address spelling and decoded effective address to resolve the
  `0x629Fxx` versus `0x619Fxx` notation conclusively.
- The fields/content reachable from PCSX2 primary `0x5C0C40` and fallback
  `0x41F9B0`, including the fallback next pointer and state used by
  `0x4FB0D8`/`0x4FAED8`.
- Lifecycle flags corresponding to `0x619F40` and `0x619F41` at the same pause.
- `0x4F9760` return value/handle for the captured
  `fonts/mcloadstrings.strtbl` request and, for a like-for-like comparison,
  `texture.zip`.
- Provider method slot `+0x14` and callback `0x711D40` if the failure-cleanup
  branch is taken.
- A gameplay-visible checkpoint (at minimum a confirmed rendered/menu frame)
  tied to the same capture; logs, timestamps, counters, and hashes are not a
  substitute.

## Reproduction

Static comparison (exits successfully and names the exact files/addresses):

```powershell
Select-String -Path docs/SESSION_2026-07-10_PCXS2_MCP_SID44.md,docs/PROVIDER_TRACE_MATRIX.md,work/boot_probe/boot_trace_pollsid59c595ret2mode9payload1m3skip5a_20260710_111442.log -Pattern '0x618020|0x619f58|0x4f9760|0x629f44|0x629f4c|backend_open=0x3984c0'
```
