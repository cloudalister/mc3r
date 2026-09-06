$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Get-ChildItem Env:MC3_* | Remove-Item
$env:PATH = 'C:\msys64\ucrt64\bin;' + $env:PATH
$log = Join-Path $root ('work\logs\net_callback_tests_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
$p = Start-Process -FilePath "$root\PS2Recomp\out\build\ps2xTest\ps2x_tests.exe" -WorkingDirectory "$root\PS2Recomp" -WindowStyle Hidden -PassThru -RedirectStandardOutput "$log.stdout" -RedirectStandardError "$log.stderr"
$handle = $p.Handle
if (!$p.WaitForExit(30000)) { Stop-Process -Id $p.Id; throw 'Test timeout' }
$p.WaitForExit()
Get-Content "$log.stdout" -Tail 8
if ($p.ExitCode -ne 0) { Get-Content "$log.stderr" -Tail 20; throw "Tests failed: $($p.ExitCode)" }
