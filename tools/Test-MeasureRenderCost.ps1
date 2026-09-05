# Regressao offline: nao inicia mc3_partial.
$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'Measure-RenderCost.ps1'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('mc3-cost-' + [guid]::NewGuid() + '.log')
function Frame([int]$n) {
    "[boot-trace:frame] gsPrims=$n gsPixels=$($n * 10) rasterMs=$n rasterCalls=$n guestMs=$n vu1Ms=$($n * 2) vifMs=$($n * 3) gifPk1=$n"
}
try {
    @((Frame 100), (Frame 200), (Frame 300), (Frame 400)) | Set-Content -LiteralPath $fixture
    $result = (& $script -Label test -MarcoBaixo 100 -MarcoAlto 300 -LogPaths $fixture | Out-String)
    if ($result -notmatch 'mediana=' -or $result -notmatch 'INSUFICIENTE') { throw 'janela completa nao analisada' }
    @((Frame 100), (Frame 200)) | Set-Content -LiteralPath $fixture
    $rejected = $false
    try { & $script -Label test -MarcoBaixo 100 -MarcoAlto 300 -LogPaths $fixture | Out-Null }
    catch { $rejected = $_.Exception.Message -eq 'nenhuma corrida produziu numeros' }
    if (-not $rejected) { throw 'janela incompleta foi aceita' }
    @('garbled boot-trace:frame gsPrims=400', (Frame 200), (Frame 300)) | Set-Content -LiteralPath $fixture
    $rejected = $false
    try { & $script -Label test -MarcoBaixo 100 -MarcoAlto 300 -LogPaths $fixture | Out-Null }
    catch { $rejected = $_.Exception.Message -eq 'nenhuma corrida produziu numeros' }
    if (-not $rejected) { throw 'janela sem borda inicial foi aceita' }
    'PASS: janela completa, rejeicao de janela parcial, rejeicao de borda ausente/linha corrompida.'
} finally {
    Remove-Item -LiteralPath $fixture -ErrorAction SilentlyContinue
}
