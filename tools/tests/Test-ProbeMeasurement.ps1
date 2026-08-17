param()

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$bootProbe = Join-Path $root "tools\Boot-Probe.ps1"
$verifyBoot = Join-Path $root "tools\Verify-BootState.ps1"
$probeRepeat = Join-Path $root "tools\Probe-Repeat.ps1"
$latestStatus = Join-Path $root "work\boot_probe\latest_status.md"
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("mc3_probe_measurement_{0}" -f [guid]::NewGuid().ToString("N"))

function Assert-That {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw "ASSERT FAILED: $Message"
    }
}

function Get-RunnerProcessIds {
    return @(
        Get-Process -Name "mc3_partial" -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Id |
            Sort-Object
    )
}

function Write-SyntheticTrace {
    param([string]$Name, [string[]]$Lines)
    $path = Join-Path $tempDir ("{0}.log" -f $Name)
    Set-Content -LiteralPath $path -Value $Lines -Encoding ASCII
    return $path
}

function New-CompleteFrameLine {
    param(
        [string]$Pc,
        [int]$Dma = 0,
        [int]$Gif = 0,
        [int]$Gsw = 0,
        [int]$Vif = 0
    )

    return "[boot-trace:frame] tick=1 activeThreads=1 pc=$Pc ra=0x0 sp=0x0 gp=0x0 dispfb1=0x1400 display1=0x1bf27f00000000 dma=$Dma gif=$Gif gsw=$Gsw vif=$Vif"
}

function Get-SyntheticAnalysis {
    param([string]$TracePath)
    $output = @(& $bootProbe -Mode analyze -AnalyzeTracePath $TracePath -NoWriteStatus 2>&1)
    $classificationLine = $output | Where-Object { $_ -match '^Classification: ' } | Select-Object -Last 1
    Assert-That ($null -ne $classificationLine) "Boot-Probe did not emit a classification for $TracePath. Output: $($output -join ' | ')"
    $detailLine = $output | Where-Object { $_ -match '^Detail: ' } | Select-Object -Last 1
    Assert-That ($null -ne $detailLine) "Boot-Probe did not emit a detail for $TracePath. Output: $($output -join ' | ')"
    return [pscustomobject]@{
        Classification = ($classificationLine -replace '^Classification: ', '').Trim()
        Detail = ($detailLine -replace '^Detail: ', '').Trim()
    }
}

function Get-SyntheticClassification {
    param([string]$TracePath)
    return (Get-SyntheticAnalysis -TracePath $TracePath).Classification
}

function Write-SyntheticStatus {
    param(
        [string]$Name,
        [string]$Classification,
        [int]$Gif,
        [int]$Gsw,
        [int]$Dma = 0,
        [int]$Vif = 0,
        [string]$Deterministic = "no",
        [string]$DispatchBudget = "n/a",
        [string]$DispatchBudgetMarker = "no",
        [string]$TimeoutReached = "no"
    )
    $path = Join-Path $tempDir ("{0}.md" -f $Name)
    @"
# Synthetic MC3 Boot Probe Status

| Field | Value |
|---|---|
| Classification | $Classification |
| Stable PC | 0x1a0008 |
| Render counters | dma=$Dma gif=$Gif gsw=$Gsw vif=$Vif |
| Deterministic | $Deterministic |
| Dispatch budget | $DispatchBudget |
| Dispatch budget marker | $DispatchBudgetMarker |
| Timeout reached | $TimeoutReached |
"@ | Set-Content -LiteralPath $path -Encoding ASCII
    return $path
}

function Invoke-StatusVerifier {
    param([string]$StatusPath)
    $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $verifyBoot -StatusPath $StatusPath 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
}

function Invoke-RepeatAnalysis {
    param([string]$StatusPath)
    $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $probeRepeat -Runs 1 -AnalyzeStatusPath $StatusPath -NoWriteReport 2>&1)
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
}

function Invoke-DeterministicBudgetValidation {
    param(
        [AllowNull()]
        [string]$Budget,
        [AllowNull()]
        [string]$Deterministic = "1"
    )

    $savedDeterministic = [Environment]::GetEnvironmentVariable("MC3_DETERMINISTIC")
    $savedBudget = [Environment]::GetEnvironmentVariable("MC3_DISPATCH_BUDGET")
    try {
        [Environment]::SetEnvironmentVariable("MC3_DETERMINISTIC", $Deterministic)
        [Environment]::SetEnvironmentVariable("MC3_DISPATCH_BUDGET", $Budget)
        $output = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootProbe -ValidateDeterministicBudget 2>&1)
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Text = ($output -join "`n") }
    }
    finally {
        [Environment]::SetEnvironmentVariable("MC3_DETERMINISTIC", $savedDeterministic)
        [Environment]::SetEnvironmentVariable("MC3_DISPATCH_BUDGET", $savedBudget)
    }
}

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$latestStatusHashBefore = if (Test-Path -LiteralPath $latestStatus) { (Get-FileHash -LiteralPath $latestStatus -Algorithm SHA256).Hash } else { $null }
$runnerProcessIdsBefore = @(Get-RunnerProcessIds)
try {
    $invalidTrace = Write-SyntheticTrace -Name "invalid_pc" -Lines @(
        $(New-CompleteFrameLine -Pc "0x3" -Vif 2)
    )
    $invalidClassification = Get-SyntheticClassification -TracePath $invalidTrace
    Assert-That ($invalidClassification -eq "invalid-pc") "PC 0x3 with VIF-only activity must be invalid-pc, got $invalidClassification"

    $invalidMissingTrace = Write-SyntheticTrace -Name "invalid_pc_missing" -Lines @(
        "[boot-trace:dispatch-window] first-bad-pc=0x42eb48",
        $(New-CompleteFrameLine -Pc "0x3" -Vif 2)
    )
    $invalidMissingAnalysis = Get-SyntheticAnalysis -TracePath $invalidMissingTrace
    Assert-That ($invalidMissingAnalysis.Classification -eq "invalid-pc") "Invalid PC must keep precedence over missing-function, got $($invalidMissingAnalysis.Classification)"
    Assert-That ($invalidMissingAnalysis.Detail -match 'first-bad-pc=0x42eb48') "Invalid-PC detail must preserve missing-function evidence"

    $counterTrace = Write-SyntheticTrace -Name "counters_only" -Lines @(
        $(New-CompleteFrameLine -Pc "0x1a0008" -Dma 2 -Vif 3)
    )
    $counterClassification = Get-SyntheticClassification -TracePath $counterTrace
    Assert-That ($counterClassification -eq "counters-moved") "Known PC with DMA/VIF-only activity must be counters-moved, got $counterClassification"

    $gifTrace = Write-SyntheticTrace -Name "gif_render" -Lines @(
        $(New-CompleteFrameLine -Pc "0x1a0008" -Gif 1)
    )
    Assert-That ((Get-SyntheticClassification -TracePath $gifTrace) -eq "render-started") "gif>0 must be render-started"

    $gswTrace = Write-SyntheticTrace -Name "gsw_render" -Lines @(
        $(New-CompleteFrameLine -Pc "0x1a0008" -Gsw 1)
    )
    Assert-That ((Get-SyntheticClassification -TracePath $gswTrace) -eq "render-started") "gsw>0 must be render-started"

    $missingTrace = Write-SyntheticTrace -Name "missing_not_masked" -Lines @(
        "[boot-trace:dispatch-window] first-bad-pc=0x42eb48",
        $(New-CompleteFrameLine -Pc "0x1a0008" -Dma 2 -Vif 1)
    )
    Assert-That ((Get-SyntheticClassification -TracePath $missingTrace) -eq "missing-function") "Missing-function evidence must not be masked by DMA/VIF-only activity"

    $validGswTrace = Write-SyntheticTrace -Name "valid_gsw_700" -Lines @(
        $(New-CompleteFrameLine -Pc "0x1a0008" -Gsw 700)
    )
    Assert-That ((Get-SyntheticClassification -TracePath $validGswTrace) -eq "render-started") "Complete gsw=700 frame must be render-started"

    $corruptFrameTrace = Write-SyntheticTrace -Name "corrupt_frame_counters" -Lines @(
        "[boot-trace:frame] tick=7 activeThreads=1 pc=0x1a0008 ra=0x0 sp=0x0 gp=0x0 dispfb1=0x1400 display1=0x1bf27f00000000 dma=0 gif=0 gsw=700e00 vif=0",
        "[boot-trace:frame] tick=8 activeThreads=1 pc=0x1a0008 ra=0x0 sp=0x0 gp=0x0 dispfb1=0x1400 display1=0x1bf27f00000000 dma=0 gif=0 gsw=700 [boot-trace:CreateSema] tid=1 vif=0",
        "[boot-trace:frame] tick=9 activeThreads=1 pc=0x1a0008 ra=0x0 sp=0x0 gp=0x0 dispfb1=0x1400 display1=0x1bf27f00000000 dma=0 gif=0 gsw=700",
        "prefix [boot-trace:frame] tick=10 activeThreads=1 pc=0x1a0008 ra=0x0 sp=0x0 gp=0x0 dispfb1=0x1400 display1=0x1bf27f00000000 dma=0 gif=0 gsw=700 vif=0",
        "[boot-trace:dispatch-window] pc=0x1a0008"
    )
    Assert-That ((Get-SyntheticClassification -TracePath $corruptFrameTrace) -eq "unknown-loop") "Corrupt, truncated, interleaved, or embedded frames must retain fallback PC only and never render counters"

    $invalidVerify = Invoke-StatusVerifier -StatusPath (Write-SyntheticStatus -Name "invalid_status" -Classification "invalid-pc" -Gif 0 -Gsw 0 -Vif 2)
    Assert-That ($invalidVerify.ExitCode -ne 0) "Verify-BootState must fail invalid-pc with gif=0 and gsw=0"
    Assert-That ($invalidVerify.Text -match '\[FAIL\] real-render-traffic :: gif=0 gsw=0') "Verify-BootState did not fail missing visual traffic for invalid-pc"

    $counterVerify = Invoke-StatusVerifier -StatusPath (Write-SyntheticStatus -Name "counters_status" -Classification "counters-moved" -Gif 0 -Gsw 0 -Dma 2 -Vif 3)
    Assert-That ($counterVerify.ExitCode -ne 0) "Verify-BootState must fail counters-moved with gif=0 and gsw=0"
    Assert-That ($counterVerify.Text -match '\[FAIL\] probe-classification :: classification=counters-moved') "Verify-BootState did not reject counters-moved"

    $renderVerify = Invoke-StatusVerifier -StatusPath (Write-SyntheticStatus -Name "render_status" -Classification "render-started" -Gif 1 -Gsw 0)
    Assert-That ($renderVerify.Text -match '\[PASS\] probe-classification :: classification=render-started') "Verify-BootState did not accept render-started classification"
    Assert-That ($renderVerify.Text -match '\[PASS\] real-render-traffic :: gif=1 gsw=0') "Verify-BootState did not recognize gif traffic"

    $invalidVisualRepeat = Invoke-RepeatAnalysis -StatusPath (Write-SyntheticStatus -Name "invalid_visual_repeat" -Classification "invalid-pc" -Gif 1 -Gsw 0)
    Assert-That ($invalidVisualRepeat.ExitCode -ne 0) "Probe-Repeat must fail invalid-pc with GIF traffic"
    Assert-That ($invalidVisualRepeat.Text -match 'render real: 0/1') "Invalid-pc with GIF traffic must not increment true render count"
    Assert-That ($invalidVisualRepeat.Text -match 'classification=invalid-pc with gif/gsw visual traffic') "Probe-Repeat must flag invalid-pc plus GIF traffic as contradictory"

    $renderWithoutVisualRepeat = Invoke-RepeatAnalysis -StatusPath (Write-SyntheticStatus -Name "render_without_visual_repeat" -Classification "render-started" -Gif 0 -Gsw 0)
    Assert-That ($renderWithoutVisualRepeat.ExitCode -ne 0) "Probe-Repeat must fail render-started without GIF/GSW"
    Assert-That ($renderWithoutVisualRepeat.Text -match 'render-started without gif/gsw visual traffic') "Probe-Repeat must flag render-started without GIF/GSW as contradictory"

    $gateOffRepeat = Invoke-RepeatAnalysis -StatusPath (Write-SyntheticStatus -Name "gate_off_compatible" -Classification "render-started" -Gif 1 -Gsw 0)
    Assert-That ($gateOffRepeat.ExitCode -eq 0) "Gate-off synthetic evidence must preserve the existing successful aggregate result"
    Assert-That ($gateOffRepeat.Text -match 'Falhas de evidencia deterministica: 0') "Gate-off synthetic evidence must not require a budget marker"

    foreach ($gateOffDeterministic in @($null, "0")) {
        $gateOff = Invoke-DeterministicBudgetValidation -Budget "0" -Deterministic $gateOffDeterministic
        Assert-That ($gateOff.ExitCode -eq 0) "Gate-off deterministic budget validation must preserve legacy behavior"
        Assert-That ($gateOff.Text -match 'budget gate inactive') "Gate-off deterministic budget validation did not report the inactive gate"
    }

    foreach ($invalidBudget in @($null, "", "abc", "0")) {
        $validation = Invoke-DeterministicBudgetValidation -Budget $invalidBudget
        Assert-That ($validation.ExitCode -eq 2) "Deterministic budget '$invalidBudget' must exit 2 before any runner launch"
        Assert-That ($validation.Text -match 'MC3_DISPATCH_BUDGET must be a positive decimal integer') "Invalid deterministic budget '$invalidBudget' did not report the gate"
    }

    $validBudget = Invoke-DeterministicBudgetValidation -Budget "100000"
    Assert-That ($validBudget.ExitCode -eq 0) "Positive deterministic budget must be accepted"

    $validDeterministicRepeat = Invoke-RepeatAnalysis -StatusPath (Write-SyntheticStatus -Name "deterministic_marker" -Classification "render-started" -Gif 1 -Gsw 0 -Deterministic "yes" -DispatchBudget "100000" -DispatchBudgetMarker "yes" -TimeoutReached "no")
    Assert-That ($validDeterministicRepeat.ExitCode -eq 0) "Deterministic evidence with a budget marker and no timeout must be accepted"
    Assert-That ($validDeterministicRepeat.Text -match 'Falhas de evidencia deterministica: 0') "Valid deterministic evidence must have no deterministic failures"

    $missingMarkerRepeat = Invoke-RepeatAnalysis -StatusPath (Write-SyntheticStatus -Name "deterministic_missing_marker" -Classification "render-started" -Gif 1 -Gsw 0 -Deterministic "yes" -DispatchBudget "100000" -DispatchBudgetMarker "no" -TimeoutReached "no")
    Assert-That ($missingMarkerRepeat.ExitCode -eq 4) "Deterministic evidence without a budget marker must be rejected"
    Assert-That ($missingMarkerRepeat.Text -match 'marker=yes and timeout=no') "Missing deterministic marker did not report the evidence gate"

    $timeoutRepeat = Invoke-RepeatAnalysis -StatusPath (Write-SyntheticStatus -Name "deterministic_timeout" -Classification "render-started" -Gif 1 -Gsw 0 -Deterministic "yes" -DispatchBudget "100000" -DispatchBudgetMarker "yes" -TimeoutReached "yes")
    Assert-That ($timeoutRepeat.ExitCode -eq 4) "Deterministic evidence with a timeout must be rejected"
    Assert-That ($timeoutRepeat.Text -match 'marker=yes and timeout=no') "Timed-out deterministic evidence did not report the evidence gate"

    $latestStatusHashAfter = if (Test-Path -LiteralPath $latestStatus) { (Get-FileHash -LiteralPath $latestStatus -Algorithm SHA256).Hash } else { $null }
    Assert-That ($latestStatusHashAfter -eq $latestStatusHashBefore) "Synthetic tests must not alter work\\boot_probe\\latest_status.md"
    $runnerProcessIdsAfter = @(Get-RunnerProcessIds)
    $normalizedRunnerProcessIdsBefore = if ($runnerProcessIdsBefore.Count -gt 0) { $runnerProcessIdsBefore } else { @("__no_mc3_partial_process__") }
    $normalizedRunnerProcessIdsAfter = if ($runnerProcessIdsAfter.Count -gt 0) { $runnerProcessIdsAfter } else { @("__no_mc3_partial_process__") }
    Assert-That ((Compare-Object -ReferenceObject $normalizedRunnerProcessIdsBefore -DifferenceObject $normalizedRunnerProcessIdsAfter).Count -eq 0) "Synthetic tests must not launch mc3_partial.exe"

    Write-Output "PASS: invalid-pc, counters-moved, gif/gsw render, and missing-function precedence verified."
    Write-Output "PASS: complete gsw=700 frame accepted; corrupt gsw=700e00, truncated, interleaved, and embedded frames rejected."
    Write-Output "PASS: Verify-BootState rejects non-render synthetic statuses; true-render status passes its status checks."
    Write-Output "PASS: Probe-Repeat rejects both classification/counter contradiction directions without running the runner."
    Write-Output "PASS: deterministic budget validation, marker acceptance, missing-marker rejection, timeout rejection, and gate-off compatibility verified without running the runner."
}
finally {
    if (Test-Path -LiteralPath $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
}
