$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
if (Get-Process mc3_partial -ErrorAction SilentlyContinue) { throw 'MC3 is running' }
$env:PATH = 'C:\msys64\ucrt64\bin;' + $env:PATH
& rtk proxy node tools/Verify-EntryBatch.js
if ($LASTEXITCODE -ne 0) { throw 'ELF verification failed' }
$compiler = 'C:\msys64\ucrt64\bin\g++.exe'
$flags = @('-std=c++20','-O2','-fno-strict-aliasing','-msse4.1','-Wno-comment','-I','work/generated/ghidra','-I','PS2Recomp/ps2xRuntime/include','-I','PS2Recomp/ps2xRuntime/src/lib/Kernel')
$owners = @(
    @('FUN_005b9500_0x5b9500','batch_0060'),
    @('FUN_005b9908_0x5b9908','batch_0060'),
    @('sub_00501088_0x501088','batch_0049'),
    @('sub_0042BE50_0x42be50','batch_0036')
)
$objects = @()
foreach ($pair in $owners) {
    $owner,$batch = $pair
    $obj = "work/compile/ghidra/$batch/obj/$owner.o"
    & rtk proxy $compiler @flags -c "work/generated/ghidra/$owner.cpp" -o $obj
    if ($LASTEXITCODE -ne 0) { throw "Owner compile failed: $owner" }
    $objects += $obj
}
$exe = 'work/scratch/entry_batch_tests.exe'
& rtk proxy $compiler @flags tools/entry_batch_tests.cpp @objects PS2Recomp/out/build/ps2xRuntime/libps2_runtime.a C:/msys64/ucrt64/lib/libz.dll.a PS2Recomp/out/build/_deps/raylib-build/raylib/libraylib.a -lopengl32 -lglu32 -lwinmm -lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32 -o $exe
if ($LASTEXITCODE -ne 0) { throw 'Entry test link failed' }
Get-ChildItem Env:MC3_* | Remove-Item
$log = Join-Path (Get-Location) ('work/logs/entry_batch_tests_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
$p = Start-Process -FilePath (Join-Path (Get-Location) $exe) -WindowStyle Hidden -PassThru -RedirectStandardOutput "$log.stdout" -RedirectStandardError "$log.stderr"
$handle = $p.Handle
if (!$p.WaitForExit(30000)) { Stop-Process -Id $p.Id; throw 'Entry test timeout' }
$p.WaitForExit()
Get-Content "$log.stdout"
if ($p.ExitCode -ne 0) { Get-Content "$log.stderr"; throw "Entry tests failed: $($p.ExitCode)" }
