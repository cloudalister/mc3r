param([Parameter(Mandatory=$true)][string]$CaptureLog,
      [Parameter(Mandatory=$true)][string]$Prefix,
      [Parameter(Mandatory=$true)][string]$Label)
$ErrorActionPreference = 'Stop'
if($Label -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Invalid label'}
$root = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $root 'PS2Recomp\out\build\ps2xTest\ps2x_tests.exe'
Get-ChildItem Env:MC3_* | Remove-Item
$env:PATH = 'C:\msys64\ucrt64\bin;' + $env:PATH
$seen = @{}
foreach($line in (Select-String -LiteralPath $CaptureLog -Pattern '\[vif1-input-before\]')) {
    $m = [regex]::Match($line.Line, '\[vif1-input-before\] idx=(\d+) top=(\d+) tops=(\d+) itop=(\d+) itops=(\d+) base=(\d+) ofst=(\d+) dbf=(\d+)')
    if(!$m.Success){continue}
    $index=[int]$m.Groups[1].Value
    if($index -ge 8 -or $seen.ContainsKey($index)){throw 'Duplicate/out-of-range capture index'}
    $seen[$index]=$true
    $top=[int]$m.Groups[3].Value
    if($top -gt 1023){throw 'Invalid TOPS'}
    $env:MC3_VU1_REPLAY_PREFIX = "${Prefix}_$index"
    $env:MC3_VU1_REPLAY_TOP = "$top"
    $env:MC3_VU1_REPLAY_EXPECT_END = '1'
    $out=Join-Path $root "work\logs\replay_${Label}_$index.stdout"
    $err=Join-Path $root "work\logs\replay_${Label}_$index.stderr"
    if((Test-Path $out) -or (Test-Path $err)){throw 'Existing replay log'}
    $p=Start-Process -FilePath $exe -WorkingDirectory (Join-Path $root 'PS2Recomp') -WindowStyle Hidden -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
    $processHandle = $p.Handle # Cache handle so Windows PowerShell retains ExitCode.
    if(!$p.WaitForExit(30000)){Stop-Process -InputObject $p -Force; throw 'Replay timed out'}
    $p.WaitForExit() # Complete asynchronous redirected-output handlers as well.
    $result=@(Select-String -LiteralPath $err -Pattern '\[vu1-replay\]')
    if($p.ExitCode -ne 0 -or $result.Count -ne 1){throw "Replay $index failed: exit=$($p.ExitCode) records=$($result.Count); inspect $out and $err"}
    $result[0].Line
}
if($seen.Count -eq 0){throw 'No complete input captures found'}
"PASS: $($seen.Count) input snapshots terminate; full test suite passed on each replay"
