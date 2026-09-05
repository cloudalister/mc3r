# Mede custo de render com ORCAMENTO DE TRABALHO FIXO, nao tempo fixo.
#
# Por que existe: em 2026-09-05 tres corridas de tempo fixo, com codigo que deveria ser
# neutro ou melhor entre si, deram 59,0 / 68,3 / 75,2 ns por pixel -- 27% de dispersao sem
# causa no codigo. Corridas de tempo fixo param em pontos de trabalho diferentes e nao sao
# comparaveis. Ver docs/RESULT_M3_TITLE_EXIT_2026-09-04.md secao 17.
#
# Orcamento fixo tambem NAO bastou: tres corridas do mesmo binario com
# MC3_DISPATCH_BUDGET=1500000 deram 78,1 / 99,7 / 94,7 ns por pixel e 28,4 / 63,3 / 63,4 us por
# primitiva -- 23% e 55% de dispersao. O motivo: o orcamento fixa despachos do laco principal,
# nao trabalho de render, e cada corrida alcanca uma CENA diferente (256 M, 510 M e 548 M pixels
# nas tres). Cena diferente, custo por pixel diferente, sem nada a ver com o codigo.
#
# Por isso a medicao aqui e por JANELA DE TRABALHO: os contadores do trace sao cumulativos,
# entao tomamos a diferenca entre dois marcos de gsPrims. Isso reduz a variacao de trabalho,
# mas NAO prova identidade de cena. Reportamos as bordas efetivas e pixels por primitiva.
# Uma corrida que nao alcanca o marco alto simplesmente nao produz linha.
#
# Uso tipico (dispersao do binario atual, para saber o que e ruido):
#   powershell -File tools\Measure-RenderCost.ps1 -Label base -Reps 3
#
# Para A/B honesto: rode no binario A, relinke o B, rode de novo, e compare as MEDIANAS --
# aceitando so o que exceder a dispersao medida dentro de cada binario.

param(
    [Parameter(Mandatory = $true)][string]$Label,
    [int]$Reps = 3,
    [uint64]$Budget = 0,
    [uint64]$MarcoBaixo = 300000,
    [uint64]$MarcoAlto = 600000,
    [int]$TimeoutSeconds = 1800,
    # Analisa evidencia existente sem iniciar o jogo nem exigir o binario atual.
    [string[]]$LogPaths = @()
)

$ErrorActionPreference = 'Stop'
$root = 'E:\Games\Emuladores\Sony\mc3recomp'
$exe = Join-Path $root 'work\link\partial\mc3_partial.exe'
$elf = Join-Path $root 'extracted_iso\SLUS_213.55'
$lib = Join-Path $root 'PS2Recomp\out\build\ps2xRuntime\libps2_runtime.a'

if ($MarcoAlto -le $MarcoBaixo -or $Reps -lt 1 -or $TimeoutSeconds -lt 1) {
    throw 'marcos, repeticoes ou timeout invalidos'
}
if ($LogPaths.Count -eq 0) {
if (-not (Test-Path -LiteralPath $exe)) { throw "executavel ausente: $exe" }
if ((Get-Item -LiteralPath $exe).LastWriteTime -lt (Get-Item -LiteralPath $lib).LastWriteTime) {
    throw 'exe mais velho que a lib - relinke antes de medir'
}
$running = Get-Process mc3_partial -ErrorAction SilentlyContinue
if ($running) { throw "mc3_partial ja esta rodando (PID $($running.Id -join ', '))" }

$env:MC3_BOOT_TRACE = '1'
$env:MC3_HEADLESS = '1'
$env:MC3_PHASE_TIMING = '1'
if ($Budget -gt 0) { $env:MC3_DISPATCH_BUDGET = "$Budget" }
else { Remove-Item Env:MC3_DISPATCH_BUDGET -ErrorAction SilentlyContinue }
}

# As linhas do trace se misturam entre threads, entao uma linha so vale se TODOS os campos
# necessarios estiverem nela. As garbled sao descartadas em silencio.
function Get-Amostras {
    param([string]$Path)
    $amostras = @()
    foreach ($linha in [System.IO.File]::ReadLines($Path)) {
        if ($linha -notmatch 'boot-trace:frame') { continue }
        $m = [regex]::Match($linha,
            'gsPrims=(\d+) gsPixels=(\d+) rasterMs=(\d+) rasterCalls=(\d+) guestMs=(\d+)')
        if (-not $m.Success) { continue }
        $mv = [regex]::Match($linha, 'vu1Ms=(\d+) vifMs=(\d+)')
        if (-not $mv.Success) { continue }
        $mk = [regex]::Match($linha, 'gifPk1=(\d+)')
        if (-not $mk.Success) { continue }
        $amostras += [pscustomobject]@{
            prims  = [uint64]$m.Groups[1].Value
            pixels = [uint64]$m.Groups[2].Value
            raster = [uint64]$m.Groups[3].Value
            vu1    = [uint64]$mv.Groups[1].Value
            vif    = [uint64]$mv.Groups[2].Value
            pk1    = [uint64]$mk.Groups[1].Value
        }
    }
    return $amostras
}

# Ultima amostra com prims <= marco: define a borda da janela.
function Get-Borda {
    param($Amostras, [uint64]$Marco)
    $candidatas = $Amostras | Where-Object { $_.prims -le $Marco }
    if (-not $candidatas) { return $null }
    return $candidatas[-1]
}

$rows = @()
if ($LogPaths.Count -gt 0) { $Reps = $LogPaths.Count }
for ($rep = 1; $rep -le $Reps; $rep++) {
    $elapsedSeconds = $null
    if ($LogPaths.Count -gt 0) {
        $stderrPath = $LogPaths[$rep - 1]
    } else {
    $log = Join-Path $root ("work\logs\cost_{0}_r{1}.log" -f $Label, $rep)
    foreach ($suffix in @('.stdout', '.stderr')) {
        if (Test-Path -LiteralPath "$log$suffix") {
            throw "log ja existe; escolha outro Label para preservar a evidencia: $log$suffix"
        }
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $p = Start-Process -FilePath $exe -ArgumentList @("`"$elf`"") -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput "$log.stdout" -RedirectStandardError "$log.stderr"
    if (-not $p.WaitForExit($TimeoutSeconds * 1000)) {
        Stop-Process -Id $p.Id -Force
        $p.WaitForExit()
        "rep ${rep}: TIMEOUT em ${TimeoutSeconds}s - analisando trabalho ja concluido"
    }
    $sw.Stop()
    $elapsedSeconds = [math]::Round($sw.Elapsed.TotalSeconds, 1)
    $stderrPath = "$log.stderr"
    }

    $amostras = @(Get-Amostras $stderrPath)
    if ($amostras.Count -eq 0) { "rep ${rep}: nenhuma linha de frame completa no log"; continue }
    if (-not ($amostras | Where-Object { $_.prims -ge $MarcoAlto } | Select-Object -First 1)) {
        "rep ${rep}: nao alcancou marco alto $MarcoAlto; janela incompleta descartada"
        continue
    }

    $a = Get-Borda $amostras $MarcoBaixo
    $b = Get-Borda $amostras $MarcoAlto
    if (-not $a -or -not $b -or $b.prims -le $a.prims) {
        "rep ${rep}: nao alcancou a janela {0}..{1} primitivas (chegou a {2})" -f `
            $MarcoBaixo, $MarcoAlto, $amostras[-1].prims
        continue
    }

    $dPrims = $b.prims - $a.prims
    $dPixels = $b.pixels - $a.pixels
    $dRaster = $b.raster - $a.raster
    $dVif = $b.vif - $a.vif
    $dVu1 = $b.vu1 - $a.vu1
    $dPk1 = $b.pk1 - $a.pk1
    if ($dPixels -lt 0 -or $dRaster -lt 0 -or $dVif -lt 0 -or $dVu1 -lt 0 -or $dPk1 -lt 0) {
        "rep ${rep}: contadores regressivos; janela descartada"
        continue
    }
    if ($dPixels -eq 0 -or $dPrims -eq 0) { "rep ${rep}: janela sem trabalho"; continue }

    $rows += [pscustomobject]@{
        rep        = $rep
        segundos   = $elapsedSeconds
        inicioPrim = $a.prims
        fimPrim    = $b.prims
        dPrims     = $dPrims
        dPixels    = $dPixels
        pixelsPrim = [math]::Round($dPixels / $dPrims, 2)
        nsPorPixel = [math]::Round(($dRaster * 1e6) / $dPixels, 2)
        usPorPrim  = [math]::Round(($dRaster * 1e3) / $dPrims, 2)
        vifUsPrim  = [math]::Round(($dVif * 1e3) / $dPrims, 2)
        # Residuo aproximado: raster inclui outros PATHs, e VU1 inclui interpretacao.
        # Nao chamar de custo exclusivo GIF/GS.
        residuoUsPk1 = if ($dPk1 -gt 0) { [math]::Round((($dVu1 - $dRaster) * 1e3) / $dPk1, 2) } else { 0 }
    }
}

if ($LogPaths.Count -eq 0) {
    Remove-Item Env:MC3_DISPATCH_BUDGET -ErrorAction SilentlyContinue
    Remove-Item Env:MC3_PHASE_TIMING -ErrorAction SilentlyContinue
}

if ($rows.Count -eq 0) { throw 'nenhuma corrida produziu numeros' }

$rows | Format-Table -AutoSize | Out-String | Write-Output

function Show-Stat {
    param([string]$Name, [double[]]$Values)
    $sorted = $Values | Sort-Object
    $mid = [int][math]::Floor($sorted.Count / 2)
    $median = if ($sorted.Count % 2) { $sorted[$mid] } else { ($sorted[$mid - 1] + $sorted[$mid]) / 2 }
    $spread = if ($median -ne 0) { [math]::Round(100.0 * ($sorted[-1] - $sorted[0]) / $median, 1) } else { 0 }
    "{0,-12} mediana={1,10}  min={2,10}  max={3,10}  dispersao={4}%" -f `
        $Name, $median, $sorted[0], $sorted[-1], $spread
}

"--- resumo (janela {0}..{1} primitivas, {2} corridas) ---" -f $MarcoBaixo, $MarcoAlto, $rows.Count
Show-Stat 'ns/pixel'  ($rows.nsPorPixel)
Show-Stat 'us/prim'   ($rows.usPorPrim)
Show-Stat 'vif us/pr' ($rows.vifUsPrim)
Show-Stat 'residuo/pk' ($rows.residuoUsPk1)
if ($LogPaths.Count -eq 0) { Show-Stat 'segundos' ($rows.segundos) }
''
if ($rows.Count -lt 3) { 'INSUFICIENTE para aceitar otimizacao: menos de tres corridas validas.' }
'Regra: comparar cenas/bordas e pelo menos tres corridas por binario; exceder a dispersao e necessario, nao prova isolada de ganho.'
