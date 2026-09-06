$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (Get-Process mc3_partial -ErrorAction SilentlyContinue) { throw 'Stop MC3 before rebuilding' }
$env:PATH = 'C:\msys64\ucrt64\bin;' + $env:PATH
$source = 'work/generated/ghidra/sub_001F95C0_0x1f95c0.cpp'
$object = 'work/compile/ghidra/batch_0005/obj/sub_001F95C0_0x1f95c0.o'
$content = [IO.File]::ReadAllText((Join-Path $root $source))
foreach ($hook in @('ps2_net_probe::onBegin(ctx, GPR_U32(ctx, 16), jumpTarget);', 'ps2_net_probe::onEnd(ctx);')) {
    if (!$content.Contains($hook)) { throw "Missing generated hook: $hook. See docs/RESULT_WAIT_QUIET_2026-09-06.md" }
}
# Always rebuild: the generated-source manifest does not track header hashes.
& rtk proxy 'C:\msys64\ucrt64\bin\g++.exe' '-std=c++20' '-O2' '-fno-strict-aliasing' '-msse4.1' '-Wall' '-Wno-unused-variable' '-Wno-unused-label' '-Wno-comment' -I work/generated/ghidra -I PS2Recomp/ps2xRuntime/include -I PS2Recomp/ps2xRuntime/src/lib/Kernel -c $source -o $object
if ($LASTEXITCODE -ne 0) { throw "Compile failed: $LASTEXITCODE" }
Get-Item $object | Select-Object FullName, Length, LastWriteTimeUtc
