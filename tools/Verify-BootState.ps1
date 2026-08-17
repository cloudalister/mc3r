param(
    [string]$ExpectedStablePC = "",
    [string]$ExpectExeString = "",
    [string]$FailIfStablePC = "",
    [string]$StatusPath = "",
    [int]$MaxStatusAgeMinutes = 30,
    [switch]$EmitJson
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$fail = 0
if ([string]::IsNullOrWhiteSpace($StatusPath)) {
    $StatusPath = Join-Path $root "work\boot_probe\latest_status.md"
}

$results = New-Object System.Collections.Generic.List[object]

function Normalize-HexPc([string]$value) {
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    $trimmed = $value.Trim()
    if ($trimmed -match '^0x[0-9a-fA-F]+$') {
        return $trimmed.ToLowerInvariant()
    }

    if ($trimmed -match '^[0-9a-fA-F]+$') {
        return ("0x$trimmed").ToLowerInvariant()
    }

    return $null
}

function Find-AsciiNeedle([byte[]]$Bytes, [byte[]]$Needle) {
    if ($Needle.Length -eq 0) {
        return $true
    }

    for ($i = 0; $i -le $Bytes.Length - $Needle.Length; $i++) {
        $match = $true
        for ($j = 0; $j -lt $Needle.Length; $j++) {
            if ($Bytes[$i + $j] -ne $Needle[$j]) {
                $match = $false
                break
            }
        }
        if ($match) {
            return $true
        }
    }

    return $false
}

function Check($name, $ok, $detail, $kind = "check") {
    $tag = if ($ok) { "[PASS]" } else { $script:fail++; "[FAIL]" }
    Write-Output "$tag $name :: $detail"
    $script:results.Add([pscustomobject]@{
        name   = $name
        ok     = [bool]$ok
        kind   = $kind
        detail = [string]$detail
    }) | Out-Null
}

$exe = Join-Path $root "work\link\partial\mc3_partial.exe"
$exeOk = Test-Path $exe
$exeTime = $null
Check "exe-exists" $exeOk $exe
if ($exeOk) {
    $exeTime = (Get-Item -LiteralPath $exe).LastWriteTime
    $linkDir = Join-Path $root "work\link\partial"
    $inputs = @()
    if (Test-Path $linkDir) {
        $inputs = Get-ChildItem -LiteralPath $linkDir -File | Where-Object {
            $_.Name -ne "mc3_partial.exe" -and (
                $_.Extension -in @(".o", ".obj", ".lib", ".cpp", ".c", ".cc", ".h", ".hpp", ".def", ".res", ".rc", ".txt") -or
                $_.Name -eq "register_functions.partial.cpp" -or
                $_.Name -eq "missing_functions.partial.manifest.csv"
            )
        }
    }

    if ($inputs.Count -gt 0) {
        $latestInput = $inputs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Check "exe-not-stale" ($exeTime -ge $latestInput.LastWriteTime) "exe=$exeTime latest_input=$($latestInput.Name)@$($latestInput.LastWriteTime)"
    } else {
        Check "exe-not-stale" $false "nenhum input de link encontrado em $linkDir"
    }
}

$manifest = Join-Path $root "work\link\partial\missing_functions.partial.manifest.csv"
if (Test-Path $manifest) {
    try {
        $manifestRows = @(Import-Csv -LiteralPath $manifest -ErrorAction Stop)
        Check "missing-stubs-zero" ($manifestRows.Count -eq 0) "missing=$($manifestRows.Count)"
    } catch {
        Check "missing-stubs-zero" $false "manifest invalido: $($_.Exception.Message)"
    }
} else {
    Check "missing-stubs-zero" $false "manifest ausente"
}

$status = $StatusPath
$statusOk = Test-Path $status
Check "probe-status-exists" $statusOk $status
if ($statusOk) {
    $statusItem = Get-Item -LiteralPath $status
    $txt = Get-Content -LiteralPath $status -Raw
    $cls = if ($txt -match '\| Classification \| ([^\|]+) \|') { $Matches[1].Trim() } else { "?" }
    $pc  = if ($txt -match '\| Stable PC \| ([^\|]+) \|') { $Matches[1].Trim() } else { "?" }
    $ctr = if ($txt -match '\| Render counters \| ([^\|]+) \|') { $Matches[1].Trim() } else { "?" }
    $pcNorm = Normalize-HexPc $pc
    $expectedNorm = Normalize-HexPc $ExpectedStablePC
    $failIfNorm = Normalize-HexPc $FailIfStablePC
    $needFreshStatus = (-not [string]::IsNullOrWhiteSpace($ExpectedStablePC)) -or (-not [string]::IsNullOrWhiteSpace($FailIfStablePC)) -or (-not [string]::IsNullOrWhiteSpace($ExpectExeString))
    if ($needFreshStatus -and $exeOk) {
        $ageMinutes = [math]::Round(((Get-Date) - $statusItem.LastWriteTime).TotalMinutes, 2)
        Check "probe-status-fresh" ($statusItem.LastWriteTime -ge $exeTime -and $ageMinutes -le $MaxStatusAgeMinutes) "status=$($statusItem.LastWriteTime) exe=$exeTime age_minutes=$ageMinutes max=$MaxStatusAgeMinutes"
    }
    # A stable-PC change or any non-visual classification is never a boot PASS.
    Check "probe-classification" ($cls -eq "render-started") "classification=$cls"
    Write-Output "[INFO] stable-pc=$pc counters=$ctr"
    if (-not [string]::IsNullOrWhiteSpace($ExpectedStablePC)) {
        if ($null -eq $expectedNorm) {
            Check "stable-pc-expected" $false "expected-pc-invalido=$ExpectedStablePC"
        } elseif ($null -eq $pcNorm) {
            Check "stable-pc-expected" $false "got=$pc want=$expectedNorm"
        } else {
            Check "stable-pc-expected" ($pcNorm -eq $expectedNorm) "got=$pcNorm want=$expectedNorm"
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($FailIfStablePC)) {
        if ($null -eq $failIfNorm) {
            Check "stable-pc-progressed" $false "failif-pc-invalido=$FailIfStablePC"
        } elseif ($null -eq $pcNorm) {
            Check "stable-pc-progressed" $false "got=$pc still-at=$failIfNorm"
        } else {
            Check "stable-pc-progressed" ($pcNorm -ne $failIfNorm) "still-at=$pcNorm"
        }
    }
    $gif = if ($ctr -match 'gif=(\d+)') { [int]$Matches[1] } else { -1 }
    $gsw = if ($ctr -match 'gsw=(\d+)') { [int]$Matches[1] } else { -1 }
    $renderOk = ($gif -gt 0 -or $gsw -gt 0)
    Check "real-render-traffic" $renderOk "gif=$gif gsw=$gsw"
}

if (-not [string]::IsNullOrWhiteSpace($ExpectExeString) -and $exeOk) {
    $bytes = [System.IO.File]::ReadAllBytes($exe)
    $needle = [System.Text.Encoding]::ASCII.GetBytes($ExpectExeString)
    $found = Find-AsciiNeedle $bytes $needle
    Check "exe-contains-string" $found "'$ExpectExeString'"
}

if ($EmitJson) {
    $summary = [pscustomobject]@{
        result = if ($fail -gt 0) { "fail" } else { "pass" }
        fail_count = $fail
        checks = $results
    }
    Write-Output ($summary | ConvertTo-Json -Depth 6)
}

Write-Output ""
if ($fail -gt 0) {
    Write-Output "RESULT: FAIL ($fail checks)"
    exit 1
}
Write-Output "RESULT: PASS"
exit 0
