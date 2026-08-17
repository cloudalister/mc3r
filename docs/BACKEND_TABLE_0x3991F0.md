# US-002 - Backend table and indirect calls at `0x3991F0`

## Scope and terminology

This result maps the two provider-pointer slots selected by
`sub_003991F0_0x3991f0.cpp` and every guest `jalr` in that function. The
addresses requested by the story, `0x618020` and `0x618024`, are pointer slots,
not the provider method tables themselves. The selected slot contains a
provider/table pointer; the indirect calls then read methods from that target.

## Slot selection

| Condition at `0x39920C` | Selected slot | Evidence |
|---|---:|---|
| input `$a1 != 0` | `0x618020` | `0x399214..0x39921C` forms `0x00618020` in `$s3` |
| input `$a1 == 0` | `0x618024` | `0x399220..0x399224` forms `0x00618024` in `$s3` |

Both paths converge at `0x399228`, which loads `provider = *selected_slot`.
The generated function does not guard that pointer against zero before reading
its method slots.

Existing env-gated runner evidence proves two values observed in `0x618020`:

- `provider=0x617F88`, with slot 0 method `0x398830`, for `T:/mc3/assets/...`.
- `provider=0x619F58`, with slot 0 method `0x4F9760`, for package/texture paths.

The available trace does not contain an execution selecting `0x618024`, so its
runtime pointee and concrete methods remain unknown. Static control flow proves
that it uses the same offsets below, but it does not justify copying the
`0x618020` targets onto that slot.

## Every indirect call in `0x3991F0`

| Call instruction | Target source | Slot/role | Arguments at call | Proven concrete target |
|---:|---|---|---|---|
| `0x399234` | `*(*selected_slot + 0x00)` | provider method slot `+0x00` (open/lookup dispatch) | `$a0` = original input `$a0`; `$a1` = original input `$a1` | For observed `0x618020`: `0x398830` when provider is `0x617F88`; `0x4F9760` when provider is `0x619F58` |
| `0x399254` | `*(uint32_t*)0x711D40` | optional global callback | `$a0` = original input `$a0`; `$a1` = original input `$a1` | Unknown; current traces report `callback=0x0`, so the call is skipped |
| `0x39926C` | `*(*selected_slot + 0x14)` | provider method slot `+0x14` (cleanup/close after callback failure) | `$a0` = handle returned by slot `+0x00` | Unknown for the observed provider states; no trace line records this slot's value or a taken call |

The `jal 0x399098` at `0x399288` is direct, not indirect. It runs only when the
provider method returned a non-negative handle and either the callback is absent
or it returned nonzero. It receives the original `$a0`, the returned handle,
and the selected provider/table pointer, and records that open in the fixed
tracking pool beginning at `0x7093B0`.

## Concrete path after backend lookup

The requested positive example is therefore concrete at the first virtual
slot: `0x618020 -> 0x619F58 -> [slot +0x00] 0x4F9760`. The called function
`FUN_004f9760_0x4f9760.cpp` reads primary provider state `0x619F44` and then
walks fallback state at `0x619F4C` through `sub_004FB0D8_0x4fb0d8`.

A second observed `0x618020` state is
`0x618020 -> 0x617F88 -> [slot +0x00] 0x398830`. The low-level table used by
that path has the live entries `0x617FC0=0x3984C0` (open),
`0x617FC4=0x398610` (close), `0x617FC8=0x3986D8` (read),
`0x617FCC=0x398730` (seek), `0x617FD0=0x398788` (stat), and
`0x617FD4=0x3987E0` (extra). This supports calling `0x398830` a dispatcher; it
does not make either unknown `jalr` target a provider constructor.

## Negative case and limits

- `0x711D40` is a nullable callback address. No static or runtime evidence here
  identifies its target, so it is not labeled a constructor.
- Provider slot `+0x14` is invoked only as failure cleanup after a successful
  open and a callback returning zero. Its concrete target is not captured, so it
  is not assigned a name or constructor role.
- `0x618024` is mapped as a selectable provider pointer slot, but no captured
  run proves its pointee. The known `0x618020` values are not projected onto it.
- No code, provider global, callback, handle, or semaphore was modified.

## Reproduction

Static control-flow evidence (must exit zero and names the exact source and
instruction addresses):

```powershell
rg -n "0x39920[cC]|0x39921[cC]|0x399224|0x399228|0x399230|0x399234|0x399248|0x399254|0x399268|0x39926[cC]|0x399288" work/generated/ghidra/sub_003991F0_0x3991f0.cpp
```

Captured target evidence:

```powershell
rg -n -m 6 "provider_slot=0x618020 provider=(0x617f88|0x619f58).*method=(0x398830|0x4f9760)" work/boot_probe/boot_trace_pollsid59c595ret2mode9payload1m3skip5a_20260710_111442.log
```

The captured lines also report the six `0x617FC0..0x617FD4` backend entries and
show `callback=0x0`, establishing both the positive mapping and the unknown
callback negative case without changing runtime behavior.
