param(
    [string]$CsvPath = "work\exports\SLUS_213.55.ghidra.csv",
    [string]$GeneratedDir = "work\generated\ghidra",
    [string]$IndexDir = "work\index",
    [string]$DocsIndexPath = "docs\FUNCTION_INDEX.md",
    [string]$BatchDir = "work\batches\ghidra",
    [int]$BatchSize = 250
)

$ErrorActionPreference = "Stop"

function Convert-HexToUInt32([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return [uint32]0
    }

    $clean = $Value.Trim()
    if ($clean.StartsWith("0x", [StringComparison]::OrdinalIgnoreCase)) {
        $clean = $clean.Substring(2)
    }
    return [uint32]::Parse($clean, [Globalization.NumberStyles]::HexNumber)
}

function Get-RelativePathSafe([string]$BasePath, [string]$TargetPath) {
    $baseUri = [Uri]((Resolve-Path $BasePath).Path.TrimEnd('\') + '\')
    $targetUri = [Uri]((Resolve-Path $TargetPath).Path)
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('/', '\')
}

if (!(Test-Path $CsvPath)) {
    throw "CSV not found: $CsvPath"
}
if (!(Test-Path $GeneratedDir)) {
    throw "Generated directory not found: $GeneratedDir"
}

New-Item -ItemType Directory -Force -Path $IndexDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $DocsIndexPath -Parent) | Out-Null
New-Item -ItemType Directory -Force -Path $BatchDir | Out-Null

$cppByAddress = @{}
Get-ChildItem -Path $GeneratedDir -Filter "*.cpp" -File | ForEach-Object {
    if ($_.Name -match "_0x([0-9a-fA-F]+)\.cpp$") {
        $cppByAddress[$Matches[1].ToLowerInvariant()] = $_.FullName
    }
}

$rows = Import-Csv $CsvPath | ForEach-Object {
    $start = Convert-HexToUInt32 $_.Start
    $end = Convert-HexToUInt32 $_.End
    $addressKey = $start.ToString("x")
    $cppPath = $null
    if ($cppByAddress.ContainsKey($addressKey)) {
        $cppPath = $cppByAddress[$addressKey]
    }

    [pscustomobject]@{
        Name = $_.Name
        Start = ("0x{0:X8}" -f $start)
        End = ("0x{0:X8}" -f $end)
        Size = [int]$_.Size
        CppFile = if ($cppPath) { Get-RelativePathSafe "." $cppPath } else { "" }
        Batch = ""
    }
} | Sort-Object { Convert-HexToUInt32 $_.Start }

$batchCount = [Math]::Ceiling($rows.Count / [double]$BatchSize)
for ($i = 0; $i -lt $batchCount; $i++) {
    $batchName = "batch_{0:D4}" -f ($i + 1)
    $startIndex = $i * $BatchSize
    $slice = $rows | Select-Object -Skip $startIndex -First $BatchSize
    foreach ($row in $slice) {
        $row.Batch = $batchName
    }

    $slice | Export-Csv -Path (Join-Path $BatchDir "$batchName.csv") -NoTypeInformation
    $rspPath = Join-Path $BatchDir "$batchName.rsp"
    $slice |
        Where-Object { $_.CppFile -ne "" } |
        ForEach-Object { '"' + (Join-Path (Resolve-Path ".").Path $_.CppFile) + '"' } |
        Set-Content -Path $rspPath -Encoding ASCII
}

$indexCsv = Join-Path $IndexDir "functions_index.csv"
$rows | Export-Csv -Path $indexCsv -NoTypeInformation

$largest = $rows | Sort-Object Size -Descending | Select-Object -First 20
$named = $rows | Where-Object { $_.Name -notmatch "^(FUN_|sub_)" } | Select-Object -First 80
$missingCpp = @($rows | Where-Object { $_.CppFile -eq "" })

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# MC3 Function Index")
$md.Add("")
$md.Add("Generated from `work\exports\SLUS_213.55.ghidra.csv` and `work\generated\ghidra`.")
$md.Add("")
$md.Add("## Summary")
$md.Add("")
$md.Add("- Functions/labels in CSV: $($rows.Count)")
$md.Add("- Generated .cpp files matched by address: $($rows.Count - $missingCpp.Count)")
$md.Add("- Missing generated .cpp matches: $($missingCpp.Count)")
$md.Add("- Batch size: $BatchSize")
$md.Add("- Batch count: $batchCount")
$md.Add("- Full machine-readable index: work\index\functions_index.csv")
$md.Add("- Batch manifests: work\batches\ghidra\batch_####.csv and .rsp")
$md.Add("")
$md.Add("## Largest Functions")
$md.Add("")
$md.Add("| Name | Start | End | Size | Batch | C++ |")
$md.Add("|---|---:|---:|---:|---|---|")
foreach ($row in $largest) {
    $md.Add("| $($row.Name) | $($row.Start) | $($row.End) | $($row.Size) | $($row.Batch) | $($row.CppFile) |")
}
$md.Add("")
$md.Add("## First Named Runtime/API-Like Symbols")
$md.Add("")
$md.Add("| Name | Start | End | Size | Batch | C++ |")
$md.Add("|---|---:|---:|---:|---|---|")
foreach ($row in $named) {
    $md.Add("| $($row.Name) | $($row.Start) | $($row.End) | $($row.Size) | $($row.Batch) | $($row.CppFile) |")
}

if ($missingCpp.Count -gt 0) {
    $md.Add("")
    $md.Add("## Missing Generated C++ Matches")
    $md.Add("")
    $md.Add("These CSV rows did not map to a generated `.cpp` by start address.")
    $md.Add("")
    $md.Add("| Name | Start | End | Size |")
    $md.Add("|---|---:|---:|---:|")
    foreach ($row in ($missingCpp | Select-Object -First 50)) {
        $md.Add("| $($row.Name) | $($row.Start) | $($row.End) | $($row.Size) |")
    }
}

$md | Set-Content -Path $DocsIndexPath -Encoding ASCII

Write-Host "[OK] Function index: $indexCsv"
Write-Host "[OK] Docs summary: $DocsIndexPath"
Write-Host "[OK] Batches: $BatchDir ($batchCount batches of up to $BatchSize)"
