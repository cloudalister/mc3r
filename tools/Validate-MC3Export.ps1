[CmdletBinding()]
param(
    [switch]$RepairTomlMetadata
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$exports = Join-Path $root 'work\exports'
$tomlPath = Join-Path $exports 'SLUS_213.55.ghidra.toml'
$csvPath = Join-Path $exports 'SLUS_213.55.ghidra.csv'
$elfPath = Join-Path $root 'extracted_iso\SLUS_213.55'
$generatedPath = Join-Path $root 'work\generated\ghidra'
$manifestPath = Join-Path $root 'work\link\partial\missing_functions.partial.manifest.csv'
$logDir = Join-Path $root 'work\logs'

New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logPath = Join-Path $logDir ("validate_mc3_export_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

function Write-Report([string]$Message) {
    $Message | Tee-Object -FilePath $logPath -Append
}

function Get-TomlValue([string[]]$Lines, [string]$Name) {
    $line = $Lines | Where-Object { $_ -match ("^\s*{0}\s*=" -f [regex]::Escape($Name)) } | Select-Object -First 1
    if (-not $line) { return $null }
    if ($line -match '=\s*"(?<value>.*)"\s*$') { return $Matches.value }
    return $null
}

function Resolve-ReportedPath([string]$Value) {
    if (-not $Value) { return $null }
    $normalized = $Value -replace '/', '\'
    try { return (Resolve-Path -LiteralPath $normalized -ErrorAction Stop).Path } catch { return $null }
}

Write-Report "MC3 export validation"
Write-Report ("Root: {0}" -f $root)
Write-Report ("Time: {0}" -f (Get-Date -Format o))

foreach ($required in @($elfPath, $tomlPath, $csvPath)) {
    Write-Report ((if (Test-Path -LiteralPath $required) { '[OK]' } else { '[MISS]' }) + " " + $required)
}

if (-not (Test-Path -LiteralPath $tomlPath)) {
    throw "TOML not found: $tomlPath"
}

$tomlLines = Get-Content -LiteralPath $tomlPath
$reportedInput = Get-TomlValue $tomlLines 'input'
$reportedOutput = Get-TomlValue $tomlLines 'output'
$reportedCsv = Get-TomlValue $tomlLines 'ghidra_output'

Write-Report "TOML input: $reportedInput"
Write-Report "TOML output: $reportedOutput"
Write-Report "TOML ghidra_output: $reportedCsv"

$resolvedInput = Resolve-ReportedPath $reportedInput
$resolvedOutput = Resolve-ReportedPath $reportedOutput
$resolvedCsv = Resolve-ReportedPath $reportedCsv
Write-Report ((if ($resolvedInput) { '[OK]' } else { '[STALE/MISSING]' }) + " TOML input")
Write-Report ((if ($resolvedOutput) { '[OK]' } else { '[STALE/MISSING]' }) + " TOML output")
Write-Report ((if ($resolvedCsv) { '[OK]' } else { '[STALE/MISSING]' }) + " TOML ghidra_output")

if (Test-Path -LiteralPath $elfPath) {
    $currentHash = Get-FileHash -LiteralPath $elfPath -Algorithm SHA256
    Write-Report "Current ELF: $($currentHash.Hash) ($((Get-Item -LiteralPath $elfPath).Length) bytes)"
    if ($resolvedInput) {
        $reportedHash = Get-FileHash -LiteralPath $resolvedInput -Algorithm SHA256
        Write-Report "TOML ELF:     $($reportedHash.Hash) ($((Get-Item -LiteralPath $resolvedInput).Length) bytes)"
        Write-Report ((if ($currentHash.Hash -eq $reportedHash.Hash) { '[MATCH]' } else { '[MISMATCH]' }) + ' ELF hash comparison')
    }
}

if (Test-Path -LiteralPath $csvPath) {
    $records = @(Import-Csv -LiteralPath $csvPath)
    $starts = @($records | ForEach-Object { $_.Start })
    $duplicates = @($starts | Group-Object | Where-Object Count -gt 1)
    Write-Report "CSV records: $($records.Count)"
    Write-Report "CSV duplicate Start addresses: $($duplicates.Count)"
    if ($records.Count -gt 0) {
        Write-Report "CSV first: $($records[0].Name) $($records[0].Start)"
        Write-Report "CSV last:  $($records[-1].Name) $($records[-1].Start)"
    }
}

if (Test-Path -LiteralPath $generatedPath) {
    $generatedCount = @(Get-ChildItem -LiteralPath $generatedPath -Filter '*.cpp' -File).Count
    Write-Report "Generated C++ files: $generatedCount"
}

if (Test-Path -LiteralPath $manifestPath) {
    $missing = @(Import-Csv -LiteralPath $manifestPath | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_.Object)) })
    Write-Report "Partial manifest missing objects: $($missing.Count)"
    foreach ($item in $missing) { Write-Report "  MISSING $($item.Address) $($item.Object)" }
}

if ($RepairTomlMetadata) {
    $backup = "$tomlPath.bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item -LiteralPath $tomlPath -Destination $backup
    $currentOutput = (Join-Path $root 'work\generated\ghidra')
    $currentCsv = (Join-Path $root 'work\exports\SLUS_213.55.ghidra.csv')
    $updated = foreach ($line in $tomlLines) {
        if ($line -match '^\s*input\s*=') { 'input = "' + ($elfPath -replace '\\', '/') + '"'; continue }
        if ($line -match '^\s*output\s*=') { 'output = "' + ($currentOutput -replace '\\', '\\') + '"'; continue }
        if ($line -match '^\s*ghidra_output\s*=') { 'ghidra_output = "' + ($currentCsv -replace '\\', '\\') + '"'; continue }
        $line
    }
    Set-Content -LiteralPath $tomlPath -Value $updated -Encoding UTF8
    Write-Report "[REPAIRED] TOML metadata paths; backup: $backup"
    Write-Report "WARNING: metadata repair does not prove the CSV/generated C++ came from this ELF. Re-export from current Ghidra for provenance proof."
}

Write-Report "Report: $logPath"
