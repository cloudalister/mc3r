param([int]$Seconds = 900, [string]$Label = ('fe_writes_' + (Get-Date -Format 'yyyyMMdd_HHmmss')), [switch]$QuietBootTrace, [switch]$TraceVuBudget, [switch]$TraceVuInput,
      [ValidateRange(1, [long]::MaxValue)][long]$FrameDumpMinPrims = 700000, [switch]$TraceWait, [switch]$TraceNetCallback)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $root 'work\link\partial\mc3_partial.exe'
$lib = Join-Path $root 'PS2Recomp\out\build\ps2xRuntime\libps2_runtime.a'
$elf = Join-Path $root 'extracted_iso\SLUS_213.55'
$log = Join-Path $root "work\logs\probe_$Label.log"
function Get-Sha256([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $hasher = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($hasher.ComputeHash($stream))).Replace('-', '').ToLowerInvariant() }
    finally { $hasher.Dispose(); $stream.Dispose() }
}
if ($Seconds -lt 1 -or $Label -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Invalid duration or label' }
if (Get-Process mc3_partial -ErrorAction SilentlyContinue) { throw 'MC3 already running' }
if ((Get-Item $exe).LastWriteTimeUtc -lt (Get-Item $lib).LastWriteTimeUtc) { throw 'Relink required' }
foreach ($suffix in @('.stdout', '.stderr', '.meta', '.result.json')) {
    if (Test-Path -LiteralPath "$log$suffix") { throw "Existing log: $log$suffix" }
}
# Run in a child PowerShell so these settings do not escape the probe.
Get-ChildItem Env:MC3_* | Remove-Item
$env:MC3_BOOT_TRACE = if ($QuietBootTrace) { '0' } else { '1' }
$env:MC3_HEADLESS = '1'
$env:MC3_FE_WRITE_TRACE = '1'
$env:MC3_PHASE_TIMING = '1'
if ($TraceWait) { $env:MC3_WAIT_PROFILE = '1' }
if ($TraceNetCallback) { $env:MC3_NET_CALLBACK_PROFILE = '1' }
if ($TraceVuInput) {
    $env:MC3_VU1_INPUT_TRACE = '1'
    $env:MC3_VU1_INPUT_DUMP = Join-Path $root "work\captures\vuinput_$Label"
    if (Get-ChildItem -Path "$($env:MC3_VU1_INPUT_DUMP)_*.bin" -ErrorAction SilentlyContinue) { throw 'Existing VU1 input capture' }
}
if ($TraceVuBudget) {
    $env:MC3_VU1_BUDGET_TRACE = '1'
    $env:MC3_VU1_BUDGET_DUMP = Join-Path $root "work\captures\vu1_$Label"
    if (Get-ChildItem -Path "$($env:MC3_VU1_BUDGET_DUMP)_*.bin" -ErrorAction SilentlyContinue) { throw 'Existing VU1 capture' }
}
$env:MC3_PAD_AUTOSTART = '1500'
$env:MC3_PAD_AUTOSTART_DELAY_MS = '45000'
$env:MC3_PAD_AUTOSTART_HOLD_MS = '600000'
$env:MC3_FRAME_DUMP = Join-Path $root "work\captures\frame_$Label.png"
$env:MC3_FRAME_DUMP_MIN_PRIMS = $FrameDumpMinPrims.ToString([Globalization.CultureInfo]::InvariantCulture)
if (Test-Path -LiteralPath $env:MC3_FRAME_DUMP) { throw 'Existing frame capture' }
$meta = [ordered]@{
    started = (Get-Date).ToString('o'); seconds = $Seconds
    exeSha256 = Get-Sha256 $exe
    libSha256 = Get-Sha256 $lib
    settings = @(Get-ChildItem Env:MC3_* | Select-Object Name,Value)
}
$meta | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$log.meta" -Encoding UTF8
$p = Start-Process -FilePath $exe -WorkingDirectory $root -ArgumentList @("`"$elf`"") -WindowStyle Hidden -PassThru -RedirectStandardOutput "$log.stdout" -RedirectStandardError "$log.stderr"
$processHandle = $p.Handle # Preserve the exit code if the runner exits before timeout.
$watch = [Diagnostics.Stopwatch]::StartNew()
try {
    while (-not $p.HasExited -and $watch.Elapsed.TotalSeconds -lt $Seconds) {
        Start-Sleep -Seconds 5
        $p.Refresh()
    }
    if ($p.HasExited) { "exit=$($p.ExitCode)" } else { 'timeout reached' }
} finally {
    try {
        $p.Refresh()
        $result = [ordered]@{
            ended = (Get-Date).ToString('o')
            wallSeconds = $watch.Elapsed.TotalSeconds
            cpuSeconds = $p.TotalProcessorTime.TotalSeconds
            userSeconds = $p.UserProcessorTime.TotalSeconds
            kernelSeconds = $p.PrivilegedProcessorTime.TotalSeconds
            exitedBeforeLimit = $p.HasExited
            exitCode = if ($p.HasExited) { $p.ExitCode } else { $null }
        }
        $result | ConvertTo-Json | Set-Content -LiteralPath "$log.result.json" -Encoding UTF8
    } finally {
        if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force; $p.WaitForExit() }
    }
}
"complete log=$log elapsed=$([int]$watch.Elapsed.TotalSeconds)s"
