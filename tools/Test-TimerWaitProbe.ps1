$ErrorActionPreference='Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
$env:PATH='C:\msys64\ucrt64\bin;'+$env:PATH
& rtk proxy C:/msys64/ucrt64/bin/g++.exe '-std=c++20' '-O2' -I PS2Recomp/ps2xRuntime/include tools/timer_wait_probe_tests.cpp -o work/scratch/timer_wait_probe_tests.exe
if($LASTEXITCODE -ne 0) { throw 'Probe test compile failed' }
$env:MC3_TIMER_WAIT_TRACE='1'
& rtk proxy work/scratch/timer_wait_probe_tests.exe
if($LASTEXITCODE -ne 0) { throw 'Probe test failed' }
