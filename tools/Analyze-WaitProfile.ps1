param([string]$LogPath, [string[]]$Lines, [long]$StartSequence = 0)
$ErrorActionPreference = 'Stop'
if ($LogPath) { $Lines = @(Select-String -LiteralPath $LogPath -Pattern '\[wait-profile\]' | ForEach-Object { $_.Line }) }
$last = @{}; $baseline = @{}; $records = 0
foreach ($line in $Lines) {
    $m = [regex]::Match($line, '\[wait-profile\] seq=(\d+) tid=(-?\d+) initialNs=(\d+) reacquireNs=(\d+) holdNs=(\d+) blocksMainNs=(\d+) holds=(\d+)')
    if (!$m.Success) { continue }
    $r = [ordered]@{ seq=[long]$m.Groups[1].Value; tid=[int]$m.Groups[2].Value }
    $fields = @('initialNs','reacquireNs','holdNs','blocksMainNs','holds')
    for ($i=0; $i -lt $fields.Count; $i++) { $r[$fields[$i]] = [long]$m.Groups[$i+3].Value }
    $key = [string]$r.tid
    if ($last.ContainsKey($key)) {
        foreach ($field in $fields) { if ($r[$field] -lt $last[$key][$field]) { throw "Counter regression for tid $key" } }
    }
    if ($r.blocksMainNs -gt $r.holdNs) { throw 'Attributed overlap exceeds hold time' }
    $last[$key] = $r
    if ($r.seq -le $StartSequence) { $baseline[$key] = $r }
    $records++
}
if (!$records) { throw 'No complete wait-profile records; absent is not zero' }
$rows = foreach ($key in $last.Keys) {
    $r = $last[$key]; $b = $baseline[$key]
    $o = [ordered]@{ tid=$r.tid; endSequence=$r.seq; baselineSequence=if($b){$b.seq}else{0} }
    foreach ($field in @('initialNs','reacquireNs','holdNs','blocksMainNs','holds')) {
        $value = $r[$field] - $(if($b){$b[$field]}else{0})
        if ($field -eq 'holds') { $o.holds=$value } else { $o[$field.Replace('Ns','Seconds')]=$value/1e9 }
    }
    [pscustomobject]$o
}
[ordered]@{
    completeRecords=$records
    rows=@($rows | Sort-Object blocksMainSeconds -Descending)
    limits='Single runtime, normal scheduler, main tid1. Completed holds only; concurrent snapshots and missing/interleaved lines can leave unequal boundaries. Overlap is a subset of wait, not extra time. Hold is wall time, not CPU. A sampled owner does not identify its internal operation.'
} | ConvertTo-Json -Depth 5
