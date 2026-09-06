$ErrorActionPreference='Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
if(Get-Process mc3_partial -ErrorAction SilentlyContinue) { throw 'MC3 is running' }
$env:PATH='C:\msys64\ucrt64\bin;'+$env:PATH
$owners=@('sub_00547608_0x547608','FUN_005476d0_0x5476d0')
foreach($owner in $owners) {
    $source="work/generated/ghidra/$owner.cpp"
    if(!([IO.File]::ReadAllText((Join-Path (Get-Location) $source))).Contains('runtime/ps2_timer_wait_probe.h')) { throw 'Missing generated probe hook' }
    & rtk proxy C:/msys64/ucrt64/bin/g++.exe '-std=c++20' '-O2' '-fno-strict-aliasing' '-msse4.1' '-Wno-comment' -I work/generated/ghidra -I PS2Recomp/ps2xRuntime/include -I PS2Recomp/ps2xRuntime/src/lib/Kernel -c $source -o "work/compile/ghidra/batch_0054/obj/$owner.o"
    if($LASTEXITCODE -ne 0) { throw "Compile failed: $owner" }
}
