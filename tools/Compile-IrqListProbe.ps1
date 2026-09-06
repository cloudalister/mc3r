$ErrorActionPreference='Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
if(Get-Process mc3_partial -ErrorAction SilentlyContinue) { throw 'MC3 is running' }
$env:PATH='C:\msys64\ucrt64\bin;'+$env:PATH
$owner='FUN_0054cb58_0x54cb58'
$source="work/generated/ghidra/$owner.cpp"
if(!([IO.File]::ReadAllText((Join-Path (Get-Location) $source))).Contains('ps2_irq_list_probe::observe')) { throw 'Missing generated probe hook; see RESULT_IRQ_LIST_2026-09-06.md' }
& rtk proxy C:/msys64/ucrt64/bin/g++.exe '-std=c++20' '-O2' '-fno-strict-aliasing' '-msse4.1' '-Wno-comment' -I work/generated/ghidra -I PS2Recomp/ps2xRuntime/include -I PS2Recomp/ps2xRuntime/src/lib/Kernel -c $source -o "work/compile/ghidra/batch_0054/obj/$owner.o"
if($LASTEXITCODE -ne 0) { throw "Compile failed: $owner" }
