param([string]$LogPath, [string[]]$Lines)
$ErrorActionPreference = 'Stop'
if ($LogPath) { $Lines = @(Select-String -LiteralPath $LogPath -Pattern '\[main-wait\]' | ForEach-Object { $_.Line }) }
$rows = @()
foreach ($line in $Lines) {
    $m = [regex]::Match($line, '\[main-wait\] kind=([\w-]+) argument=(\d+) entryPc=([0-9a-f]+) entryRa=([0-9a-f]+) ageMs=(\d+) tokenWaitMs=(\d+) owner=(-?\d+) dispatchPc=([0-9a-f]+) semaPhase=([\w-]+)')
    if (!$m.Success) { continue }
    $rows += [pscustomobject]@{kind=$m.Groups[1].Value; argument=[long]$m.Groups[2].Value;
        entryPc=$m.Groups[3].Value; entryRa=$m.Groups[4].Value; ageMs=[long]$m.Groups[5].Value;
        tokenWaitMs=[long]$m.Groups[6].Value; owner=[int]$m.Groups[7].Value;
        dispatchPc=$m.Groups[8].Value; semaPhase=$m.Groups[9].Value}
}
if (!$rows.Count) { throw 'No complete main-wait records; absent is not zero' }
$groups = foreach ($g in ($rows | Group-Object kind,argument,entryRa)) {
    $maximum = $g.Group | Sort-Object ageMs -Descending | Select-Object -First 1
    [pscustomobject]@{ kind=$maximum.kind; argument=$maximum.argument; entryRa=$maximum.entryRa;
        samples=$g.Count; maxObservedAgeMs=$maximum.ageMs; dispatchAtMax=$maximum.dispatchPc;
        phaseAtMax=$maximum.semaPhase }
}
[ordered]@{ completeRecords=$rows.Count; last=$rows[-1]; groups=@($groups | Sort-Object maxObservedAgeMs -Descending);
    limits='Snapshots, not transitions. Reused resource IDs may span different lifetimes. Age is open syscall time, not pure CV blocking. Do not sum ages. none-covered is not proof of execution.' } | ConvertTo-Json -Depth 5
