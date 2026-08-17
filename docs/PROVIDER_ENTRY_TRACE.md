# US-004 - Provider chain entry/exit trace

## Intent

`MC3_TRACE_PROVIDER=1` enables read-only telemetry for the provider chain at
guest addresses `0x3991F0`, `0x4FAED8`, `0x4F9A68`, and `0x4F9760`. The trace
exists to compare live provider state with the static maps in
`BACKEND_TABLE_0x3991F0.md` and `PROVIDER_LIFECYCLE_FLAGS.md`; it does not create
a provider, replace a handle, write lifecycle flags, or change a branch.

Each C++ invocation logs its entry PC and relevant arguments, then its exit PC
and `$v0`. Because generated functions can yield and resume around guest calls,
the PC identifies whether an invocation is a fresh guest entry or a resumed
continuation.

`0x4F9760` additionally logs the effective primary and fallback globals
(`0x619F44` and `0x619F4C`) plus lifecycle flags `0x619F40/0x619F41`. The
requested `0x629Fxx` spelling is the opcode base before its signed offset is
applied; the effective addresses are `0x619Fxx`.

## Use

```powershell
$env:MC3_TRACE_PROVIDER = '1'
.\15_auto_boot_probe.bat 8 595
Remove-Item Env:MC3_TRACE_PROVIDER
```

Trace lines use the prefix `[MC3_PROVIDER]`. With `MC3_TRACE_PROVIDER` absent,
the added code performs no logging and does not alter guest state or control
flow.

## Static evidence

```powershell
rg -n "MC3_TRACE_PROVIDER|enter=0x(3991f0|4faed8|4f9a68|4f9760)|exit=0x(3991f0|4faed8|4f9a68|4f9760)" work/generated/ghidra/sub_003991F0_0x3991f0.cpp work/generated/ghidra/sub_004FAED8_0x4faed8.cpp work/generated/ghidra/sub_004F9A68_0x4f9a68.cpp work/generated/ghidra/FUN_004f9760_0x4f9760.cpp
```

