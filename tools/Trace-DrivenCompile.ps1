param(
    [int]$MaxBatches = 2,
    [int]$Limit = 250,
    [int]$TimeoutSeconds = 120,
    [switch]$SkipSmoke
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Write-Host $line
    Add-Content -Path $script:DriverLog -Value $line -Encoding ASCII
}

function Convert-HexToInt64([string]$Hex) {
    $clean = $Hex.Trim()
    if ($clean.StartsWith("0x", [StringComparison]::OrdinalIgnoreCase)) {
        $clean = $clean.Substring(2)
    }
    return [Convert]::ToInt64($clean, 16)
}

function Format-Hex32([int64]$Value) {
    return "0x{0:x8}" -f $Value
}

function Get-CompiledBatchSet([string]$CompileRoot) {
    $set = New-Object "System.Collections.Generic.HashSet[string]"
    if (!(Test-Path $CompileRoot)) {
        return $set
    }

    Get-ChildItem -Path $CompileRoot -Directory | ForEach-Object {
        $summary = Join-Path $_.FullName ("{0}.object.summary.csv" -f $_.Name)
        if (Test-Path $summary) {
            [void]$set.Add($_.Name)
        }
    }
    return $set
}

function Get-TraceAddresses([string]$RunLog) {
    $items = New-Object System.Collections.Generic.List[object]
    if (!(Test-Path $RunLog)) {
        return $items
    }

    $lineNo = 0
    foreach ($line in Get-Content $RunLog) {
        $lineNo++

        if ($line -match '\[partial-runner:missing-function\].* @ (0x[0-9a-fA-F]+)') {
            $items.Add([pscustomobject]@{ Address = $matches[1]; Kind = "missing-function"; Line = $lineNo }) | Out-Null
            continue
        }
        if ($line -match '\[dispatch:first-bad-pc\] bad=(0x[0-9a-fA-F]+)') {
            $items.Add([pscustomobject]@{ Address = $matches[1]; Kind = "first-bad-pc"; Line = $lineNo }) | Out-Null
            continue
        }
        if ($line -match 'Warning: Function at address (0x[0-9a-fA-F]+) not found') {
            $items.Add([pscustomobject]@{ Address = $matches[1]; Kind = "warning"; Line = $lineNo }) | Out-Null
            continue
        }
    }

    return $items
}

function Resolve-AddressToFunction($AddressItem, $FunctionRows) {
    $addr = Convert-HexToInt64 $AddressItem.Address
    foreach ($row in $FunctionRows) {
        if ($addr -ge $row.StartInt -and $addr -lt $row.EndInt) {
            return [pscustomobject]@{
                Address = Format-Hex32 $addr
                Kind = $AddressItem.Kind
                Line = $AddressItem.Line
                Name = $row.Name
                Start = $row.Start
                End = $row.End
                Batch = $row.Batch
                CppFile = $row.CppFile
            }
        }
    }
    return $null
}

function Invoke-BatchCompile([string]$Root, [string]$Batch, [int]$Limit, [int]$TimeoutSeconds, [string]$Mode) {
    $bat = Join-Path $Root "09_compile_generated_batch.bat"
    $args = @("/c", $bat, $Batch, $Limit.ToString(), $Mode, $TimeoutSeconds.ToString())
    Write-Step "Compiling $Batch mode=$Mode limit=$Limit timeout=$TimeoutSeconds"
    & cmd.exe $args 2>&1 | Tee-Object -FilePath $script:DriverLog -Append
    if ($LASTEXITCODE -ne 0) {
        throw "Compile failed for $Batch mode=$Mode. See $script:DriverLog"
    }
}

function Invoke-BatStep([string]$Root, [string]$BatName, [string]$Label) {
    $bat = Join-Path $Root $BatName
    Write-Step $Label
    & cmd.exe /c $bat 2>&1 | Tee-Object -FilePath $script:DriverLog -Append
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed. See $script:DriverLog"
    }
}

$root = (Resolve-Path ".").Path
$logRoot = Join-Path $root "work\logs"
$stateRoot = Join-Path $root "work\trace_driven"
$compileRoot = Join-Path $root "work\compile\ghidra"
$indexPath = Join-Path $root "work\index\functions_index.csv"
$runLog = Join-Path $root "work\logs\11_run_partial_runner.log"
$docsPath = Join-Path $root "docs\TRACE_DRIVEN_STATUS.md"

New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
New-Item -ItemType Directory -Force -Path $stateRoot | Out-Null

$script:DriverLog = Join-Path $logRoot ("12_trace_driven_compile_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
Set-Content -Path $script:DriverLog -Value "Trace-driven compile run - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')" -Encoding ASCII

if (!(Test-Path $indexPath)) {
    throw "Function index not found: $indexPath. Run 08_index_generated_functions.bat first."
}

if ($MaxBatches -lt 0) {
    $MaxBatches = 0
}

Write-Step "Root: $root"
Write-Step "MaxBatches: $MaxBatches"

$functionRows = Import-Csv $indexPath | Where-Object { $_.CppFile -ne "" } | ForEach-Object {
    $_ | Add-Member -NotePropertyName StartInt -NotePropertyValue (Convert-HexToInt64 $_.Start) -PassThru |
        Add-Member -NotePropertyName EndInt -NotePropertyValue (Convert-HexToInt64 $_.End) -PassThru
}

$compiled = Get-CompiledBatchSet $compileRoot
$addresses = Get-TraceAddresses $runLog

if ($addresses.Count -eq 0) {
    Write-Step "No trace addresses found in $runLog. Running smoke first."
    Invoke-BatStep $root "11_run_partial_runner.bat" "Run partial runner smoke"
    $addresses = Get-TraceAddresses $runLog
}

$candidates = New-Object System.Collections.Generic.List[object]
$seenBatches = New-Object "System.Collections.Generic.HashSet[string]"

foreach ($item in $addresses) {
    if ($MaxBatches -eq 0) {
        break
    }
    $resolved = Resolve-AddressToFunction $item $functionRows
    if ($null -eq $resolved) {
        continue
    }
    if ($compiled.Contains($resolved.Batch)) {
        continue
    }
    if ($seenBatches.Add($resolved.Batch)) {
        $candidates.Add($resolved) | Out-Null
    }
    if ($candidates.Count -ge $MaxBatches) {
        break
    }
}

$selected = @($candidates.ToArray())
if ($selected.Count -eq 0) {
    if ($SkipSmoke) {
        Write-Step "No uncompiled trace-driven batches selected. Relinking and updating status only."
    }
    else {
        Write-Step "No uncompiled trace-driven batches selected. Relinking and smoking only."
    }
}
else {
    Write-Step ("Selected batches: " + (($selected | ForEach-Object { "{0}({1} {2})" -f $_.Batch, $_.Address, $_.Name }) -join ", "))
}

foreach ($candidate in $selected) {
    Invoke-BatchCompile $root $candidate.Batch $Limit $TimeoutSeconds "syntax"
    Invoke-BatchCompile $root $candidate.Batch $Limit $TimeoutSeconds "object"
}

Invoke-BatStep $root "10_link_partial_runner.bat" "Relink partial runner"

if (!$SkipSmoke) {
    Invoke-BatStep $root "11_run_partial_runner.bat" "Run partial runner smoke"
}

$compiledAfter = Get-CompiledBatchSet $compileRoot
$nextAddresses = Get-TraceAddresses $runLog
$nextItems = New-Object System.Collections.Generic.List[object]
$seenNext = New-Object "System.Collections.Generic.HashSet[string]"

foreach ($item in $nextAddresses) {
    $resolved = Resolve-AddressToFunction $item $functionRows
    if ($null -eq $resolved) {
        continue
    }
    if ($compiledAfter.Contains($resolved.Batch)) {
        continue
    }
    $key = $resolved.Batch
    if ($seenNext.Add($key)) {
        $nextItems.Add($resolved) | Out-Null
    }
    if ($nextItems.Count -ge 10) {
        break
    }
}

$linkLog = Join-Path $logRoot "10_link_partial_runner.log"
if (!(Test-Path $linkLog) -or ((Get-Item $linkLog).Length -eq 0)) {
    $linkLog = Join-Path $logRoot "10_link_partial_runner_driver.log"
}
$registered = ""
$stubs = ""
$aliases = ""
if (Test-Path $linkLog) {
    $linkText = Get-Content $linkLog
    $registeredMatch = $linkText | Select-String -Pattern 'Registered functions: (\d+)' | Select-Object -Last 1
    $stubsMatch = $linkText | Select-String -Pattern 'Missing stub functions: (\d+)' | Select-Object -Last 1
    $aliasesMatch = $linkText | Select-String -Pattern 'Internal PC aliases: (\d+)' | Select-Object -Last 1
    if ($registeredMatch) { $registered = $registeredMatch.Matches.Groups[1].Value }
    if ($stubsMatch) { $stubs = $stubsMatch.Matches.Groups[1].Value }
    if ($aliasesMatch) { $aliases = $aliasesMatch.Matches.Groups[1].Value }
}

$statusLines = New-Object System.Collections.Generic.List[string]
$statusLines.Add("# Trace-Driven Compile Status")
$statusLines.Add("")
$updatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$selectedText = "none"
if ($selected.Count -gt 0) {
    $selectedText = $selected.Batch -join ", "
}
$statusLines.Add("- Updated: $updatedAt")
$statusLines.Add("- Driver log: " + $script:DriverLog)
$statusLines.Add("- Batches compiled this run: $selectedText")
$statusLines.Add("- Compiled object batches total: $($compiledAfter.Count)")
if ($registered) { $statusLines.Add("- Registered real functions: $registered") }
if ($stubs) { $statusLines.Add("- Missing-function stubs: $stubs") }
if ($aliases) { $statusLines.Add("- Internal PC aliases: $aliases") }
$statusLines.Add("")
$statusLines.Add("## Next Trace Targets")
$statusLines.Add("")
if ($nextItems.Count -eq 0) {
    $statusLines.Add("- No uncompiled trace target found in the latest run log.")
}
else {
    foreach ($next in $nextItems) {
        $nextLine = '- `{0}` -> `{1}` / `{2}` from `{3}` at log line `{4}`' -f $next.Batch, $next.Address, $next.Name, $next.Kind, $next.Line
        $statusLines.Add($nextLine)
    }
}
$statusLines.Add("")
$statusLines.Add("## Recommended Next Command")
$statusLines.Add("")
$recommendedMaxBatches = $MaxBatches
if ($recommendedMaxBatches -lt 1) {
    $recommendedMaxBatches = 2
}
$statusLines.Add('```bat')
$statusLines.Add("12_trace_driven_compile.bat $recommendedMaxBatches $Limit $TimeoutSeconds")
$statusLines.Add('```')

$latestStatus = Join-Path $stateRoot "latest_status.md"
$statusLines | Set-Content -Path $latestStatus -Encoding ASCII
$statusLines | Set-Content -Path $docsPath -Encoding ASCII

Write-Step "Status written: $latestStatus"
Write-Step "Docs written: $docsPath"
Write-Step "Done."
