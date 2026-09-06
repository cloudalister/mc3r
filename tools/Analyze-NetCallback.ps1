param([string]$LogPath, [string[]]$Lines)
$ErrorActionPreference = 'Stop'
if ($LogPath) { $Lines = @(Select-String -LiteralPath $LogPath -Pattern '\[net-callback\]' | ForEach-Object { $_.Line }) }
$last = @{}; $records = 0
foreach ($line in $Lines) {
    $m = [regex]::Match($line, '\[net-callback\] seq=(\d+) object=([0-9a-f]+) target=([0-9a-f]+) starts=(\d+) ends=(\d+) wallNs=(\d+) maxNs=(\d+) active=(\d+) abandoned=(\d+) overflow=(\d+) unmatched=(\d+)')
    if (!$m.Success) { continue }
    $r = [ordered]@{ sequence=[long]$m.Groups[1].Value; object=$m.Groups[2].Value; target=$m.Groups[3].Value }
    $fields = @('starts','ends','wallNs','maxNs','active','abandoned','overflow','unmatched')
    for ($i=0; $i -lt $fields.Count; $i++) { $r[$fields[$i]] = [long]$m.Groups[$i+4].Value }
    $key = "$($r.object):$($r.target)"
    if ($last.ContainsKey($key)) {
        foreach ($field in @('starts','ends','wallNs','maxNs','abandoned','overflow','unmatched')) {
            if ($r[$field] -lt $last[$key][$field]) { throw "Counter regression: $key $field" }
        }
    }
    # Host snapshots are not atomic across counters; don't reject temporary
    # starts/ends or max/total inconsistencies while a callback completes.
    $last[$key] = $r; $records++
}
if (!$records) { throw 'No complete callback records; absent is not zero' }
$rows = foreach ($r in $last.Values) {
    [pscustomobject]@{ object=$r.object; target=$r.target; sequence=$r.sequence;
        starts=$r.starts; ends=$r.ends; wallSeconds=$r.wallNs/1e9;
        meanMilliseconds=if($r.ends){$r.wallNs/1e6/$r.ends}else{$null};
        maxMilliseconds=$r.maxNs/1e6; active=$r.active; abandoned=$r.abandoned;
        overflow=$r.overflow; unmatched=$r.unmatched }
}
[ordered]@{ completeRecords=$records; rows=@($rows | Sort-Object wallSeconds -Descending);
    limits='Completed callback wall time includes yields and waits, not CPU or exclusive hold. Host snapshots are concurrent. active/loss counters are global, repeated per row; do not sum them.' } | ConvertTo-Json -Depth 5
