[CmdletBinding()]
param([switch]$RepairTomlMetadata)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$tomlPath = Join-Path $root 'work\exports\SLUS_213.55.ghidra.toml'
$csvPath = Join-Path $root 'work\exports\SLUS_213.55.ghidra.csv'
$elfPath = Join-Path $root 'extracted_iso\SLUS_213.55'
$logDir = Join-Path $root 'work\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logPath = Join-Path $logDir ("validate_mc3_export_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
function Report([string]$Message) { $Message | Tee-Object -FilePath $logPath -Append }
function Mark([bool]$Condition, [string]$Good, [string]$Bad) { if ($Condition) { $Good } else { $Bad } }
function TomlValue([string[]]$Lines, [string]$Name) { $line = $Lines | Where-Object { $_ -match ("^\s*{0}\s*=" -f [regex]::Escape($Name)) } | Select-Object -First 1; if ($line -and $line -match '=\s*"(?<value>.*)"\s*$') { $Matches.value } }
function ExistingPath([string]$Value) { if (-not $Value) { return $null }; try { (Resolve-Path -LiteralPath ($Value -replace '/', '\') -ErrorAction Stop).Path } catch { $null } }
Report 'MC3 export validation'
Report ("Root: {0}" -f $root)
foreach ($path in @($elfPath, $tomlPath, $csvPath)) { Report ((Mark (Test-Path -LiteralPath $path) '[OK]' '[MISS]') + " $path") }
if (-not (Test-Path -LiteralPath $tomlPath)) { throw "TOML not found: $tomlPath" }
$tomlLines = Get-Content -LiteralPath $tomlPath
$reportedInput = TomlValue $tomlLines 'input'
$reportedOutput = TomlValue $tomlLines 'output'
$reportedCsv = TomlValue $tomlLines 'ghidra_output'
Report "TOML input: $reportedInput"
Report "TOML output: $reportedOutput"
Report "TOML ghidra_output: $reportedCsv"
$resolvedInput = ExistingPath $reportedInput
$resolvedOutput = ExistingPath $reportedOutput
$resolvedCsv = ExistingPath $reportedCsv
Report ((Mark ([bool]$resolvedInput) '[OK]' '[STALE/MISSING]') + ' TOML input')
Report ((Mark ([bool]$resolvedOutput) '[OK]' '[STALE/MISSING]') + ' TOML output')
Report ((Mark ([bool]$resolvedCsv) '[OK]' '[STALE/MISSING]') + ' TOML ghidra_output')
if (Test-Path -LiteralPath $elfPath) { $currentHash = Get-FileHash -LiteralPath $elfPath -Algorithm SHA256; Report "Current ELF: $($currentHash.Hash)"; if ($resolvedInput) { $reportedHash = Get-FileHash -LiteralPath $resolvedInput -Algorithm SHA256; Report ((Mark ($currentHash.Hash -eq $reportedHash.Hash) '[MATCH]' '[MISMATCH]') + ' ELF hash comparison') } }
if (Test-Path -LiteralPath $csvPath) { $records = @(Import-Csv -LiteralPath $csvPath); $duplicates = @($records.Start | Group-Object | Where-Object Count -gt 1); Report "CSV records: $($records.Count)"; Report "CSV duplicate Start addresses: $($duplicates.Count)" }
Report "Report: $logPath"
