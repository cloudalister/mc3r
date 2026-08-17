param(
    [string]$Batch = "batch_0001",
    [int]$Limit = 25,
    [ValidateSet("syntax", "object")]
    [string]$Mode = "syntax",
    [string]$Compiler = "C:\msys64\ucrt64\bin\g++.exe",
    [int]$TimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"

function ConvertTo-CommandLineArg([string]$Value) {
    if ($null -eq $Value) {
        return '""'
    }
    if ($Value -notmatch '[\s"]') {
        return $Value
    }
    return '"' + $Value.Replace('\', '\\').Replace('"', '\"') + '"'
}

if ($Batch -match '^\d+$') {
    $Batch = "batch_{0:D4}" -f [int]$Batch
}

$root = (Resolve-Path ".").Path
$batchCsv = Join-Path $root "work\batches\ghidra\$Batch.csv"
$outRoot = Join-Path $root "work\compile\ghidra\$Batch"
$objRoot = Join-Path $outRoot "obj"
$summaryPath = Join-Path $outRoot "$Batch.$Mode.summary.csv"

if (!(Test-Path $Compiler)) {
    throw "Compiler not found: $Compiler"
}
if (!(Test-Path $batchCsv)) {
    throw "Batch manifest not found: $batchCsv"
}

New-Item -ItemType Directory -Force -Path $outRoot | Out-Null
New-Item -ItemType Directory -Force -Path $objRoot | Out-Null

$includeArgs = @(
    "-I", (Join-Path $root "work\generated\ghidra"),
    "-I", (Join-Path $root "PS2Recomp\ps2xRuntime\include"),
    "-I", (Join-Path $root "PS2Recomp\ps2xRuntime\src\lib\Kernel")
)

$rows = Import-Csv $batchCsv | Where-Object { $_.CppFile -ne "" }
if ($Limit -gt 0) {
    $rows = $rows | Select-Object -First $Limit
}

$summary = New-Object System.Collections.Generic.List[object]
$failures = 0
$compiled = 0

foreach ($row in $rows) {
    $cppPath = Join-Path $root $row.CppFile
    if (!(Test-Path $cppPath)) {
        $failures++
        $summary.Add([pscustomobject]@{
            Name = $row.Name
            Start = $row.Start
            CppFile = $row.CppFile
            Mode = $Mode
            ExitCode = 9001
            Log = "missing source file"
        })
        continue
    }

    $baseName = [IO.Path]::GetFileNameWithoutExtension($cppPath)
    $logPath = Join-Path $outRoot "$baseName.$Mode.log"
    $args = @("-std=c++20", "-msse4.1", "-Wall", "-Wno-unused-variable", "-Wno-unused-label", "-Wno-comment")
    $args += $includeArgs

    if ($Mode -eq "syntax") {
        $args += @("-fsyntax-only", $cppPath)
    }
    else {
        $objPath = Join-Path $objRoot "$baseName.o"
        $args += @("-c", $cppPath, "-o", $objPath)
    }

    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName = $Compiler
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.Arguments = ($args | ForEach-Object { ConvertTo-CommandLineArg $_ }) -join " "

    $process = [Diagnostics.Process]::Start($psi)
    if (!$process.WaitForExit($TimeoutSeconds * 1000)) {
        try {
            & taskkill.exe /PID $process.Id /T /F | Out-Null
        }
        catch {
            try {
                $process.Kill()
            }
            catch {
            }
        }
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $exitCode = 9002
        $stderr = "$stderr`n[TIMEOUT] Compiler exceeded $TimeoutSeconds seconds for $cppPath"
    }
    else {
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $exitCode = $process.ExitCode
    }
    @($stdout, $stderr) | Set-Content -Path $logPath -Encoding ASCII

    if ($exitCode -ne 0) {
        $failures++
    }
    else {
        $compiled++
    }

    $summary.Add([pscustomobject]@{
        Name = $row.Name
        Start = $row.Start
        CppFile = $row.CppFile
        Mode = $Mode
        ExitCode = $exitCode
        Log = $logPath
    })
}

$summary | Export-Csv -Path $summaryPath -NoTypeInformation

Write-Host "[OK] Batch: $Batch"
Write-Host "[OK] Mode: $Mode"
Write-Host "[OK] Files attempted: $($summary.Count)"
Write-Host "[OK] Passed: $compiled"
Write-Host "[OK] Failed: $failures"
Write-Host "[OK] Summary: $summaryPath"

if ($failures -gt 0) {
    Write-Host "[ERROR] One or more files failed. Check per-file logs in $outRoot"
    exit 1
}
