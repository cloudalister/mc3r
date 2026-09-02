# Captura a fase interna do WaitSema quando o token guest fica retido.
param(
    [int]$MaxRuns = 5,
    [int]$Seconds = 1200,
    [int]$ConfirmHeldMs = 30000,
    [int]$SampleSeconds = 5,
    [string]$Label = 'waitphase'
)

$ErrorActionPreference = 'Stop'
$root = 'E:\Games\Emuladores\Sony\mc3recomp'
$exe = Join-Path $root 'work\link\partial\mc3_partial.exe'
$elf = Join-Path $root 'extracted_iso\SLUS_213.55'
$lib = Join-Path $root 'PS2Recomp\out\build\ps2xRuntime\libps2_runtime.a'

if (-not (Test-Path -LiteralPath $exe)) {
    throw "executavel ausente: $exe"
}
if (-not (Test-Path -LiteralPath $lib)) {
    throw "biblioteca ausente: $lib"
}
if ((Get-Item -LiteralPath $exe).LastWriteTime -lt (Get-Item -LiteralPath $lib).LastWriteTime) {
    throw 'exe mais velho que a lib - relinke antes'
}

$existing = Get-Process mc3_partial -ErrorAction SilentlyContinue
if ($existing) {
    throw "mc3_partial ja esta rodando (PID $($existing.Id -join ', ')); nao vou interromper processo existente"
}

$env:MC3_BOOT_TRACE = '1'
$env:MC3_HEADLESS = '1'
Remove-Item Env:MC3_DETERMINISTIC -ErrorAction SilentlyContinue
Remove-Item Env:MC3_DISPATCH_BUDGET -ErrorAction SilentlyContinue

$pattern = '\[boot-trace:guestexec-stuck\].*owner=(\d+).*heldMs=(\d+).*waitPhase=([a-z-]+).*waitSid=(-?\d+)'
$captured = $false

for ($run = 1; $run -le $MaxRuns -and -not $captured; $run++) {
    $log = Join-Path $root ("work\logs\stall_{0}_r{1}.log" -f $Label, $run)
    $stdout = "$log.stdout"
    $stderr = "$log.stderr"
    $process = Start-Process -FilePath $exe -ArgumentList @("`"$elf`"") `
        -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr

    "run $run/$MaxRuns iniciado: PID=$($process.Id) limite=${Seconds}s"

    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $lastStatusSecond = -30
    $lastSignature = ''
    $lastHeldMs = 0
    $streak = 0

    try {
        while (-not $process.HasExited -and $watch.Elapsed.TotalSeconds -lt $Seconds) {
            Start-Sleep -Seconds $SampleSeconds
            $process.Refresh()

            $match = $null
            if (Test-Path -LiteralPath $stderr) {
                $tail = Get-Content -LiteralPath $stderr -Tail 300 -ErrorAction SilentlyContinue
                $matches = [regex]::Matches(($tail -join "`n"), $pattern)
                if ($matches.Count -gt 0) {
                    $match = $matches[$matches.Count - 1]
                }
            }

            if ($match) {
                $owner = [int]$match.Groups[1].Value
                $heldMs = [int64]$match.Groups[2].Value
                $phase = $match.Groups[3].Value
                $sid = [int]$match.Groups[4].Value
                $signature = "$owner/$phase/$sid"

                if ($phase -ne 'none' -and $signature -eq $lastSignature -and $heldMs -gt $lastHeldMs) {
                    $streak++
                } elseif ($phase -ne 'none') {
                    $streak = 1
                } else {
                    $streak = 0
                }

                $lastSignature = $signature
                $lastHeldMs = $heldMs

                if ($heldMs -ge $ConfirmHeldMs -and $streak -ge 3) {
                    "CAPTURA run=$run owner=$owner heldMs=$heldMs waitPhase=$phase waitSid=$sid streak=$streak"
                    "log=$stderr"
                    $captured = $true
                    break
                }
            }

            $elapsedSecond = [int]$watch.Elapsed.TotalSeconds
            if ($elapsedSecond - $lastStatusSecond -ge 30) {
                if ($match) {
                    "status run=$run elapsed=${elapsedSecond}s owner=$owner heldMs=$heldMs waitPhase=$phase waitSid=$sid streak=$streak"
                } else {
                    "status run=$run elapsed=${elapsedSecond}s aguardando watchdog"
                }
                $lastStatusSecond = $elapsedSecond
            }
        }
    } finally {
        if (-not $process.HasExited) {
            Stop-Process -Id $process.Id -Force
            $process.WaitForExit()
        }
    }

    if (-not $captured) {
        "run $run terminou sem captura: $stderr"
    }
}

if (-not $captured) {
    "SEM_CAPTURA depois de $MaxRuns corrida(s)"
    exit 2
}
