param(
    # Quantas vezes repetir o probe (minimo estatistico sugerido: 5)
    [int]$Runs = 5,
    # Modo do 15_auto_boot_probe.bat (ex.: 595, req4)
    [string]$Mode = "595",
    [int]$Seconds = 8,
    # Rotulo do experimento, usado no nome do relatorio
    [string]$Label = "baseline",
    # Env vars a setar durante as corridas, formato "NOME=VALOR"
    [string[]]$Env = @(),
    # Test-only: analyze this existing status file instead of launching the runner.
    [string]$AnalyzeStatusPath = "",
    # Test-only: do not write a repeat report while using AnalyzeStatusPath.
    [switch]$NoWriteReport
)

# Roda o boot probe N vezes e agrega o resultado.
# Existe porque uma unica corrida do probe NAO e evidencia: o Stable PC varia
# entre execucoes identicas. Comparar "PC antes vs depois" com n=1 produz
# conclusoes falsas. Use a distribuicao, nao a amostra.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outDir = Join-Path $root "work\boot_probe"
$report = Join-Path $outDir "repeat_${Label}_${stamp}.md"

function Get-RenderMeasurement {
    param([string]$Classification, [int]$Gif, [int]$Gsw)

    $hasVisualTraffic = ($Gif -gt 0 -or $Gsw -gt 0)
    $claimsRender = ($Classification -eq "render-started")
    $trueRender = ($claimsRender -and $hasVisualTraffic)
    $contradiction = ($claimsRender -ne $hasVisualTraffic)
    $detail = ""
    if ($claimsRender -and -not $hasVisualTraffic) {
        $detail = "render-started without gif/gsw visual traffic"
    }
    elseif (-not $claimsRender -and $hasVisualTraffic) {
        $detail = "classification=$Classification with gif/gsw visual traffic"
    }

    return [pscustomobject]@{
        TrueRender = $trueRender
        Contradiction = $contradiction
        Detail = $detail
    }
}

function Get-StatusField {
    param([string]$Text, [string]$Field, [string]$Default = "?")

    $pattern = "(?m)^\|\s*{0}\s*\|\s*([^|]+?)\s*\|\s*$" -f [Regex]::Escape($Field)
    if ($Text -match $pattern) {
        return $Matches[1].Trim()
    }
    return $Default
}

$saved = @{}
foreach ($pair in $Env) {
    $k, $v = $pair -split '=', 2
    $saved[$k] = [Environment]::GetEnvironmentVariable($k)
    [Environment]::SetEnvironmentVariable($k, $v)
    Write-Output "[env] $k=$v"
}

$rows = New-Object System.Collections.Generic.List[object]
try {
    for ($i = 1; $i -le $Runs; $i++) {
        Write-Output "[run $i/$Runs] mode=$Mode seconds=$Seconds"
        if ([string]::IsNullOrWhiteSpace($AnalyzeStatusPath)) {
            & (Join-Path $root "15_auto_boot_probe.bat") $Seconds $Mode | Out-Null
            $status = Join-Path $outDir "latest_status.md"
        }
        else {
            $status = $AnalyzeStatusPath
            if (-not (Test-Path -LiteralPath $status)) {
                throw "AnalyzeStatusPath not found: $status"
            }
        }
        $txt = Get-Content -LiteralPath $status -Raw
        $cls = Get-StatusField -Text $txt -Field "Classification"
        $pc = (Get-StatusField -Text $txt -Field "Stable PC").ToLowerInvariant()
        $ctr = Get-StatusField -Text $txt -Field "Render counters"
        $deterministic = (Get-StatusField -Text $txt -Field "Deterministic" -Default "no").ToLowerInvariant()
        $dispatchBudget = Get-StatusField -Text $txt -Field "Dispatch budget" -Default "n/a"
        $budgetMarker = (Get-StatusField -Text $txt -Field "Dispatch budget marker" -Default "no").ToLowerInvariant()
        $timeoutReached = (Get-StatusField -Text $txt -Field "Timeout reached" -Default "no").ToLowerInvariant()

        $bad = "-"
        $traceLog = Join-Path $root "work\logs\14_run_boot_trace.log"
        if ([string]::IsNullOrWhiteSpace($AnalyzeStatusPath) -and (Test-Path $traceLog)) {
            $m = Select-String -LiteralPath $traceLog -Pattern 'bad=(0x[0-9a-f]+)' | Select-Object -First 1
            if ($m) { $bad = $m.Matches[0].Groups[1].Value }
        }

        $gif = if ($ctr -match 'gif=(\d+)') { [int]$Matches[1] } else { -1 }
        $gsw = if ($ctr -match 'gsw=(\d+)') { [int]$Matches[1] } else { -1 }

        $measurement = Get-RenderMeasurement -Classification $cls -Gif $gif -Gsw $gsw
        $deterministicFailure = ($deterministic -eq "yes") -and (($budgetMarker -ne "yes") -or ($timeoutReached -eq "yes"))
        $deterministicDetail = if ($deterministicFailure) { "deterministic evidence requires dispatch-budget marker=yes and timeout=no" } else { "" }
        $rows.Add([pscustomobject]@{
            Run = $i; Classification = $cls; StablePC = $pc; Counters = $ctr; FirstBadPC = $bad
            Rendered = $measurement.TrueRender; Contradiction = $measurement.Contradiction; ContradictionDetail = $measurement.Detail
            Deterministic = $deterministic; DispatchBudget = $dispatchBudget; BudgetMarker = $budgetMarker; TimeoutReached = $timeoutReached
            DeterministicFailure = $deterministicFailure; DeterministicDetail = $deterministicDetail
        }) | Out-Null
        $honesty = if ($measurement.Contradiction) { " INCONSISTENT: $($measurement.Detail)" } else { "" }
        $deterministicHonesty = if ($deterministicFailure) { " DETERMINISTIC-FAIL: $deterministicDetail" } else { "" }
        Write-Output "         -> $cls pc=$pc bad=$bad ($ctr) deterministic=$deterministic budget=$dispatchBudget marker=$budgetMarker timeout=$timeoutReached$honesty$deterministicHonesty"
    }
} finally {
    foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) }
}

$distinctPc  = ($rows | Select-Object -ExpandProperty StablePC -Unique)
$distinctCls = ($rows | Select-Object -ExpandProperty Classification -Unique)
$distinctBad = ($rows | Select-Object -ExpandProperty FirstBadPC -Unique)
$renderCount = ($rows | Where-Object { $_.Rendered }).Count
$contradictionRows = @($rows | Where-Object { $_.Contradiction })
$deterministicFailureRows = @($rows | Where-Object { $_.DeterministicFailure })

$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine("# Probe repeat - $Label")
[void]$md.AppendLine("")
[void]$md.AppendLine("Runs: $Runs | Mode: ``$Mode`` | Seconds: $Seconds | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
if ($Env.Count -gt 0) { [void]$md.AppendLine("Env: ``$($Env -join ' ')``") }
[void]$md.AppendLine("")
[void]$md.AppendLine("| Run | Classification | Stable PC | First bad PC | Counters | Deterministic | Budget | Budget marker | Timeout | True render | Measurement |")
[void]$md.AppendLine("|---:|---|---|---|---|---|---|---|---|---|---|")
foreach ($r in $rows) {
    $trueRenderText = if ($r.Rendered) { "yes (gif/gsw)" } else { "no" }
    $measurementText = if ($r.Contradiction) { "INCONSISTENT: $($r.ContradictionDetail)" } else { "consistent" }
    $deterministicText = if ($r.Deterministic -eq "yes") { "yes" } else { "no" }
    $deterministicMeasurement = if ($r.DeterministicFailure) { " DETERMINISTIC-FAIL: $($r.DeterministicDetail)" } else { "" }
    [void]$md.AppendLine("| $($r.Run) | $($r.Classification) | ``$($r.StablePC)`` | ``$($r.FirstBadPC)`` | $($r.Counters) | $deterministicText | ``$($r.DispatchBudget)`` | $($r.BudgetMarker) | $($r.TimeoutReached) | $trueRenderText | $measurementText$deterministicMeasurement |")
}
[void]$md.AppendLine("")
[void]$md.AppendLine("## Agregado")
[void]$md.AppendLine("")
[void]$md.AppendLine("- Stable PCs distintos: **$($distinctPc.Count)** ($($distinctPc -join ', '))")
[void]$md.AppendLine("- Classificacoes distintas: **$($distinctCls.Count)** ($($distinctCls -join ', '))")
[void]$md.AppendLine("- First bad PC distintos: **$($distinctBad.Count)** ($($distinctBad -join ', '))")
[void]$md.AppendLine("- Corridas com render real (classification=render-started e gif>0 ou gsw>0): **$renderCount / $Runs**")
[void]$md.AppendLine("- Linhas inconsistentes (classificacao e GIF/GSW divergem): **$($contradictionRows.Count)**")
[void]$md.AppendLine("- Falhas de evidencia deterministica (marker ausente ou timeout): **$($deterministicFailureRows.Count)**")
if ($contradictionRows.Count -gt 0) {
    [void]$md.AppendLine("")
    [void]$md.AppendLine("> **INCONSISTENCIA DA MEDICAO:** $($contradictionRows.Count) linha(s) divergem entre classificacao e GIF/GSW. Nao tratar como render.")
}
if ($deterministicFailureRows.Count -gt 0) {
    [void]$md.AppendLine("")
    [void]$md.AppendLine("> **EVIDENCIA DETERMINISTICA INVALIDA:** $($deterministicFailureRows.Count) linha(s) deterministica(s) sem marcador de budget ou com timeout. Nao agregar como evidencia A2.")
}
[void]$md.AppendLine("")
if ($distinctPc.Count -gt 1) {
    [void]$md.AppendLine("> **Stable PC NAO e deterministico neste modo.** Nao use ``Stable PC`` isolado como criterio")
    [void]$md.AppendLine("> de sucesso/fracasso de experimento. Compare distribuicoes de N corridas.")
} else {
    [void]$md.AppendLine("> Stable PC estavel nas $Runs corridas. Comparacao antes/depois e utilizavel neste modo.")
}

if (-not $NoWriteReport) {
    Set-Content -LiteralPath $report -Value $md.ToString() -Encoding UTF8
}
Write-Output ""
if (-not $NoWriteReport) {
    Write-Output "Relatorio: $report"
}
Write-Output "Stable PCs distintos: $($distinctPc.Count) | render real: $renderCount/$Runs | classificacoes inconsistentes: $($contradictionRows.Count)"
Write-Output "Falhas de evidencia deterministica: $($deterministicFailureRows.Count)"

# Any classification/counter disagreement is a measurement failure, not success.
if ($contradictionRows.Count -gt 0) { exit 3 }
# Deterministic runs require the runtime budget marker and no driver timeout.
if ($deterministicFailureRows.Count -gt 0) { exit 4 }
# Falha se nada renderizou E o PC oscilou (estado atual do projeto = esperado falhar)
if ($renderCount -eq 0 -and $distinctPc.Count -gt 1) { exit 2 }
exit 0
